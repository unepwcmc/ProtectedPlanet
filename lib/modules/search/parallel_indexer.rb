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
    batch_threads = start_batch_threads
    index_threads = start_indexing_threads

    ThreadsWait.all_waits(*batch_threads)
    @batchers_running = false
    ThreadsWait.all_waits(*index_threads)
  end

  private

  def start_batch_threads
    objects_count = @model_enumerable.model.count
    batch_size = [1, objects_count/concurrent_threads].max

    @batchers_running = true
    threads = (0...concurrent_threads).map do |slice|
      offset = slice * batch_size
      Thread.new {
        batch = @model_enumerable.limit(batch_size).offset(offset).all
        batches_queue << batch
      }
    end

    threads
  end

  def indexing_loop
    while batches_queue.length > 0 || @batchers_running do
      batch = batches_queue.pop
      next if batch.length == 0
      Search::Index.index batch
    end
  end

  def start_indexing_threads
    (0...concurrent_threads).map do
      Thread.new(&method(:indexing_loop))
    end
  end

  def batches_queue
    @queue ||= Queue.new
  end

  def concurrent_threads
    concurrency_level * System::CPU.count
  end

  def concurrency_level
    Rails.application.secrets.elasticsearch['indexing']['concurrency_level']
  end
end
