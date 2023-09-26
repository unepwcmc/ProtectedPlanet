import multiprocessing
import os
import queue
import time

PROCESSES_PER_PARTITION = 7


class WorkBucket:
    def __init__(self, item_number, function, args_to_fn):
        self.item_number = item_number
        self.function = function
        self.args_to_fn = args_to_fn
        self.result = {}
        self.timings = {}


class ProgressIndicator:
    def __init__(self, queue_pairs, generator):
        self.answers = None
        self.completed = None
        self.queue_pairs = queue_pairs
        self.generator = generator

    def run_jobs(self, jobs_to_run, partition_size, resubmit_period=60):
        print(f'There are {len(jobs_to_run)} buckets to process with partition size {partition_size}')
        # calculate the minimum of twice the number of processes per queue and number of jobs that each queue should eventually get, assuming even distribution
        # if it's a tiny number of submitted jobs, make sure we send at least 1
        priming_batch_size = min(int(len(jobs_to_run) / len(self.queue_pairs)), 2000)
        print(f'Priming size is {priming_batch_size}')
        cursor = 0
        for queue_in, queue_out in self.queue_pairs:
            jobs_in_this_batch = min(priming_batch_size, len(jobs_to_run) - cursor)
            print(f'Jobs in this batch is {jobs_in_this_batch}')
            for i in range(0, jobs_in_this_batch):
                queue_in.put(jobs_to_run[cursor + i])
            cursor += jobs_in_this_batch
        print('First batch of jobs queued for all queues')

        self.completed = []
        self.answers = []
        requested = [item.item_number for item in jobs_to_run]

        print(f'Pool generator received {len(jobs_to_run)} jobs')
        last_progress_report_time = time.time()
        last_process_start_time = time.time()
        start_gap = 0
        processes_started = 0
        while len(self.answers) < len(jobs_to_run):
            if (time.time() - last_process_start_time) >= start_gap:
                if processes_started < len(self.generator.procs):
                    self.generator.procs[processes_started].start()
                    print(f'Starting process {self.generator.procs[processes_started].pid}')
                    processes_started += 1
                    last_process_start_time = time.time()
            queue_index = 0
            for queue_in, queue_out in self.queue_pairs:
                while not queue_out.empty():
                    try:
                        item = queue_out.get(False,0.1)
                        # item is a WorkBucket or an error string
                        if isinstance(item, str):
                            print(f'[INFO]: {item}')
                        else:
                            if isinstance(item, WorkBucket):
                                item_no = item.item_number
                                timings = item.timings
#                                print(f'Queue: {queue_index} -> {timings}')
                                self.answers.append(item)
                                requested.remove(item_no)
                                self.completed.append(item_no)
                                if cursor < len(jobs_to_run):
                                    queue_in.put(jobs_to_run[cursor])
                                    cursor += 1
                                else:
                                    queue_in.put(None)
                            else:
                                print(item)
                    except queue.empty:
                        break
                queue_index += 1
            time.sleep(0.02)
            if (time.time() - last_progress_report_time) >= resubmit_period:
                print(f"{len(self.answers)} results received : {len(requested)} remain")
                last_progress_report_time = time.time()
        print("All answers completed - closing down")
        for proc in self.generator.procs:
            proc.join()
        return self.answers


# the main daemon within the remote process
def worker_main(qin, qout, name_str):
    print(f'Worker {name_str} started')
    time_since_last_item = time.time()
    while True:
        try:
            item = qin.get(False, 60)
            if item is None:  # detect sentinel
                qin.task_done()
                qout.put(f"{name_str} received notice to terminate")
                return
            # item is a WorkBucket
            start_time = time.time()
            fn = item.function
            args_to_fn = item.args_to_fn
            time_since_last_item = time.time()
            try:
                res, timings = fn(*args_to_fn)  # note – this requires the args to be sent as a list
                item.result["Success"] = res
                timings["Job #"] = item.item_number
                timings["Processed by"] = name_str
                item.timings = timings
            except Exception as e:
                item.result["Error"] = str(e)
                item.timings = {"No timings available as error": str(e)}
            finally:
                qin.task_done()
            # add in some operational data e.g. how long this ran on the remote side
            # as this goes back to the calling process, we can compile a histogram of
            # durations by frequency
            item.result["Duration"] = time.time() - start_time
            qout.put(item)
        except queue.Empty:
            time.sleep(0.1)
            if time.time() - time_since_last_item >= 60:
                return
        except Exception as e:
            qout.put({"Error in worker_main": str(e)})
            qin.task_done()
            return


class PoolGenerator:
    def __init__(self, total_processes):
        self.progress_indicator = None
        self.total_processes = total_processes
        self.queue_pairs = []
        self.procs = []
        for i in range(int((total_processes + PROCESSES_PER_PARTITION - 1) / PROCESSES_PER_PARTITION)):
            main_queue = multiprocessing.JoinableQueue()
            answer_queue = multiprocessing.JoinableQueue()
            self.queue_pairs.append((main_queue, answer_queue))
        for i in range(total_processes):
            nameStr = 'Worker_' + str(i)
            queue_pair = self.queue_pairs[int(i / PROCESSES_PER_PARTITION)]
            p = multiprocessing.Process(target=worker_main, args=(queue_pair[0], queue_pair[1], nameStr))
            print(f'Process {p.name} prepared with pid {p.pid}')
            self.procs.append(p)

    def run_jobs(self, buckets_to_run, partition_size):
        self.progress_indicator = ProgressIndicator(self.queue_pairs, self)
        self.progress_indicator.run_jobs(buckets_to_run, partition_size)

    def completed(self):
        return self.progress_indicator.completed

    def answers(self):
        return self.progress_indicator.answers


def get_processed_ids(path):
    processed_files = [f.replace('.csv', '').replace('TI_', '') for f in os.listdir(path) if f.endswith('.csv')]
    return [int(id_no) for id_no in processed_files]


def start_main(buckets_to_run):
    try:
        multiprocessing.set_start_method('spawn')
        print(f"Starting the start_main function for {len(buckets_to_run)} submitted buckets")
        TOTAL_PROCESSES = 15
        p = PoolGenerator(TOTAL_PROCESSES)

        # run the jobs
        p.run_jobs(buckets, PROCESSES_PER_PARTITION)
        # print out a stat to show how closely-packed we have made the processes
        # the time for which we have blocked the pool (duration*number_of_cores) should be close to the sum
        # of all the work pieces
        print(p.completed())
        print(f'Received {len(p.answers())} answers')
    except Exception as e:
        print(str(e))


def worker(count_to):
    start = time.time()
    x = 0
    for i in range(0, count_to):
        x += i
    return True, {"timings": time.time() - start}


if __name__ == '__main__':
    # sample job creation and run
    buckets = [WorkBucket(f'Job_{i}', worker, [100000000]) for i in range(0, 500)]
    start_main(buckets)
