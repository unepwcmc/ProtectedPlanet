from collections import defaultdict


class ChainTable:
    def __init__(self, name: str, backward_keys: dict, translated_fields: dict, forward_results: dict, backward_results:defaultdict, max_rows_retrievable):
        self._name = name
        self._backward_keys = backward_keys
        self._translated_fields = translated_fields
        self._forward_results = forward_results
        self._backward_results = backward_results
        self._max_rows_retrievable = max_rows_retrievable

    def name(self) -> str:
        return self._name

    def backward_keys(self) -> dict:
        return self._backward_keys

    def translated_fields(self) -> dict:
        return self._translated_fields

    def forward_results(self) -> dict:
        return self._forward_results

    def backward_results(self) -> defaultdict:
        return self._backward_results

    def filter_results(self, lower_level_key):
        filtered_res = {}
        for k,v in self._backward_results.items():
            if len(v) > 0 and lower_level_key in v[0]:
                filtered_res[k] = v
        self._backward_results = filtered_res
        filtered_res = {}
        for k,v in self._forward_results.items():
            filtered_res[k] = [val for val in v if lower_level_key in val]
        self._forward_results = filtered_res

    def max_rows_retrievable(self):
        return self._max_rows_retrievable