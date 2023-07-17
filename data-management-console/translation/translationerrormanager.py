from mgmt_logging.logger import Logger


class TranslationException(Exception):

    def __init__(self, key_errors, foreign_key_errors):
        super().__init__("Errors found")
        self.key_errors = key_errors
        self.foreign_key_errors = foreign_key_errors

    def log_errors(self):
        Logger.get_logger().info("Key Errors")
        for key_err in self.key_errors:
            Logger.get_logger().info(str(key_err))
        Logger.get_logger().info("Foreign Key Errors")
        for for_key_err in self.foreign_key_errors:
            Logger.get_logger().info(str(for_key_err))


class TranslationErrorManager:

    def __init__(self):
        self.key_errors = []
        self.foreign_key_errors = []

    def add_key_error(self, k):
        self.key_errors.append(k)

    def add_foreign_key_error(self, k):
        self.foreign_key_errors.append(k)

    def raise_any_errors(self):
        if self.key_errors or self.foreign_key_errors:
            raise TranslationException(self.key_errors, self.foreign_key_errors)
