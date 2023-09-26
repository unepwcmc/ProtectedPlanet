import multiprocessing
import time
from functools import reduce
from random import randint


class WorkBucket:
    def __init__(self, item_number, function, args_to_fn):
        self.item_number = item_number
        self.function = function
        self.args_to_fn = args_to_fn
        self.result = {}

    def computation_cost(self):
        return self.args_to_fn[0]

class ProgressIndicator:
    def __init__(self, queue_in, queue_out):
        self.queue_in = queue_in
        self.queue_out = queue_out

    def run_jobs(self, jobs_to_run, resubmit_period):
        for item in buckets:
            self.queue_in.put(item)

        self.completed = []
        self.answers = []
        requested = [i for i in range(len(jobs_to_run))]

        last_progress_report_time = time.time()
        while len(self.answers) < total_jobs:
            if not self.queue_out.empty():
                item = self.queue_out.get()
                # item is a WorkBucket
                item_no = item.item_number
                self.answers.append(item)
                requested.remove(item_no)
                self.completed.append(item_no)
            else:
                time.sleep(0.1)
            # periodically print out progress statistics
            if (time.time() - last_progress_report_time) >= resubmit_period:
                print(f"{len(self.answers)} results received")
                last_progress_report_time = time.time()

        return self.answers


# the main daemon within the remote process
def worker_main(qin, qout, name_str):
    print(f'Worker {name_str} started')
    while True:
        item = qin.get()
        if item is None:  # detect sentinel
            break
        # item is a WorkBucket
        start_time = time.time()
        fn = item.function
        args_to_fn = item.args_to_fn
        res = fn(*args_to_fn)
        item.result["Success"] = res

        # add in some operational data e.g. how long this ran on the remote side
        # as this goes back to the calling process, we can compile a histogram of
        # durations by frequency
        item.result["Duration"] = time.time() - start_time
        qout.put(item)
        qin.task_done()
    qin.task_done()


# remotely executed function - keep this light so we can test with lots of processes on a single machine
def worker(delay):
    time.sleep(delay)
    return f'Waited for {delay} seconds'


class PoolGenerator:
    def __init__(self, total_processes):
        self.total_processes = total_processes
        self.main_queue = multiprocessing.JoinableQueue()
        self.answer_queue = multiprocessing.JoinableQueue()
        procs = []
        for i in range(total_processes):
            nameStr = 'Worker_' + str(i)
            p = multiprocessing.Process(target=worker_main, args=(self.main_queue, self.answer_queue, nameStr))
            p.start()
            procs.append(p)

    def run_jobs(self, buckets):
        self.progress_indicator = ProgressIndicator(self.main_queue, self.answer_queue)
        self.progress_indicator.run_jobs(buckets, 10)

    def cleanup(self):
        for i in range(self.total_processes):
            self.main_queue.put(None)  # send termination sentinel, one for each process

    def completed(self):
        return self.progress_indicator.completed

    def answers(self):
        return self.progress_indicator.answers


if __name__ == '__main__':
    # create the pool of processes
    TOTAL_PROCESSES = 3
    p = PoolGenerator(TOTAL_PROCESSES)

    # create the work units and send out the heaviest first
    total_jobs = 30
    buckets = [WorkBucket(i, worker, [randint(0, 30)]) for i in range(total_jobs)]
    buckets.sort(key=lambda x: x.computation_cost(), reverse=True)
    delay_time_total = reduce(lambda x, y: x + y, [0] + [bucket.args_to_fn[0] for bucket in buckets])

    # do it twice to show we really can use the workers repeatedly
    for i in range(0, 2):
        # run the jobs
        start = time.time()
        p.run_jobs(buckets)
        duration = time.time() - start

        # print out a stat to show how closely-packed we have made the processes
        # the time for which we have blocked the pool (duration*number_of_cores) should be close to the sum
        # of all the work pieces
        print(f"Actual computation time was {duration * TOTAL_PROCESSES}; expected delay was {delay_time_total}")
        print(p.completed())
        print(p.answers())

    # Process Cleanup
    p.cleanup()
