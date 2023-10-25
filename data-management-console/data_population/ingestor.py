# Each ingestion needs to request an id and then store the outcomes (IngestionStats)
class Ingestor:

    _next = None

    @classmethod
    def get_next_ingestion_id(cls, executor):
        if cls._next is None:
            _next = executor.get_next_ingestion_id()
            return _next
        cls._next += 1
        return cls._next

    @classmethod
    def add_ingestion(cls, executor, ingestion_provider_ids, ingestion_id, time_of_creation, data_group, stats):
        try:
            executor.add_ingestion(ingestion_provider_ids, ingestion_id, time_of_creation, data_group, stats)
        except Exception as e:
            print(str(e))
