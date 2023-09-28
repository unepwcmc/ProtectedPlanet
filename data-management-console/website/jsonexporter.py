# Small helper class for API endpoints
import json
import time


class JsonExporter:

    @staticmethod
    def export(chain_of_objects: dict) -> str:
        start_time = time.time()
        output_json = json.dumps(chain_of_objects)
        print(f"Length of output JSON is {len(output_json)}")
        # pprint.pprint(chain_of_objects)
        duration = time.time() - start_time
        print(f"Took {duration} seconds for JSON coversion")
        return output_json
