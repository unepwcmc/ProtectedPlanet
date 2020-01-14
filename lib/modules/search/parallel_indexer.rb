require 'thwait'

class Search::ParallelIndexer
  def self.index model_enumerable
    parallel_indexer = self.new model_enumerable
    parallel_indexer.index
  end

  def initialize model_enumerable
    @model_enumerable = model_enumerable
    @batchers_running = false
  end

  def index
    batch_threads = start_batch_threads(create_lazy_batches)
    index_threads = start_indexing_threads

    ThreadsWait.all_waits(*batch_threads)
    @batchers_running = false
    ThreadsWait.all_waits(*index_threads)
  end

  private

  def start_batch_threads lazy_batches
    threads_loop = -> {
      while batch = lazy_batches.pop
        batches_queue << batch
      end
    }

    @batchers_running = true
    (0...concurrent_threads).map { Thread.new(&threads_loop) }
  end

  def create_lazy_batches
    objects_count = @model_enumerable.model.count

    (0..objects_count/batch_size).map do |slice|
      offset = slice * batch_size
      @model_enumerable.limit(batch_size).offset(offset)
    end
  end

  def start_indexing_threads
    threads_loop = -> {
      while batches_queue.length > 0 || @batchers_running do
        batch = batches_queue.pop
        next if batch.length == 0
        Search::Index.index batch
      end
    }

    (0...concurrent_threads).map { Thread.new(&threads_loop) }
  end

  def batches_queue
    @queue ||= Queue.new
  end

  def concurrent_threads
    concurrency_level * System::CPU.count
  end

  def concurrency_level
    Rails.application.secrets.elasticsearch[:indexing][:concurrency_level] || 1
  end

  def batch_size
    Rails.application.secrets.elasticsearch[:indexing][:batch_size] || 500
  end
end
