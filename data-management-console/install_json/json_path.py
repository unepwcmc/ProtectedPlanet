import os


class JsonPath:

    @staticmethod
    def make_json_path(filename: str) -> str:
        return os.getcwd() + "/../install_json/" + filename + '.json'
