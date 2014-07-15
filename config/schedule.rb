every :hour, :roles => [:util] do
  runner 'S3PollingWorker.perform_async'
end

