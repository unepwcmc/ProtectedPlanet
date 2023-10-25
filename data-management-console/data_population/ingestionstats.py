# Class to capture the statistics around how a dataset merges into history (how many added, updated, deleted, equal)
class IngestionStats:

    def __init__(self):
        self._added = 0
        self._updated = 0
        self._equal = 0
        self._deleted = 0
        self._already_deleted = 0

    def increment_add(self):
        self._added += 1

    def increment_update(self):
        self._updated += 1

    def increment_equal(self):
        self._equal += 1

    def increment_deleted(self):
        self._deleted += 1

    def increment_already_deleted(self):
        self._already_deleted += 1

    @property
    def added(self):
        return self._added

    @property
    def updated(self):
        return self._updated

    @property
    def equal(self):
        return self._equal

    @property
    def deleted(self):
        return self._deleted

    @property
    def already_deleted(self):
        return self._already_deleted