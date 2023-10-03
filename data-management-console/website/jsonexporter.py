# Small helper class for API endpoints
import json
import time
from datetime import datetime, date


class JsonExporter:

    @staticmethod
    def json_serialize(arg_to_encode):
        if isinstance(arg_to_encode, (datetime, date)):
            return arg_to_encode.isoformat()
        raise TypeError(f"Type {type(arg_to_encode)} is not serializable")

    @staticmethod
    def export(chain_of_objects: dict) -> str:
        start_time = time.time()
        output_json = json.dumps(chain_of_objects, default=JsonExporter.json_serialize)
        print(f"Length of output JSON is {len(output_json)}")
        # pprint.pprint(chain_of_objects)
        duration = time.time() - start_time
        print(f"Took {duration} seconds for JSON coversion")
        return output_json
