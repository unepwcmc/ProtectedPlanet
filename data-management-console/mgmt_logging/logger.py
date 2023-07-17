import logging.handlers

class MyStream():

    output = []

    @classmethod
    def write(cls, log_msg):
        cls.output.append(log_msg)

    @classmethod
    def flush(cls):
        pass

    @classmethod
    def get_output(cls):
        return_value = cls.output
        cls.output = []
        return return_value

class Logger():

    _logger = None
    _mystream = None

    @classmethod
    def get_logger(cls):
        if cls._logger is None:
            cls._logger = cls.create_logger()

        return cls._logger

    @classmethod
    def create_logger(cls):
        cls._mystream = MyStream()
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        streamhandler = logging.StreamHandler(cls._mystream)
        streamhandler.setLevel(logging.FATAL)
        streamhandler.setFormatter(formatter)
        memoryhandler = logging.handlers.MemoryHandler(1024*100000, logging.NOTSET, streamhandler)

        logger = logging.getLogger()
        logger.setLevel(logging.NOTSET)
        logger.addHandler(memoryhandler)
        return logger

    @classmethod
    def get_output(cls):
        str = cls._mystream.get_output()
        try:
            cls._mystream.flush()
        except Exception as e:
            print(str(e))
        return str

