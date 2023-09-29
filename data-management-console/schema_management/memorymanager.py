# Utility class to let us know how much memory is being used
import os
import psutil


class MemoryManager:

    @classmethod
    def output_memory(cls, prefix):
        print(prefix + ": " + str(psutil.Process(os.getpid()).memory_info().rss / 1024 ** 2))

    @classmethod
    def memory_as_str(cls, prefix):
        return prefix + ": " + str(psutil.Process(os.getpid()).memory_info().rss / 1024 ** 2)
