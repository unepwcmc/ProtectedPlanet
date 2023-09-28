# The ChainTable knows how to link to prior and subsequent chaintables within the executionchain.
# It also carries the results from the query executed at that level
# the algorithm in executionchain.py knows how to stitch together the results of a ChainTable with its
# predecessor in the order of execution

from collections import defaultdict


class ChainTable:
    def __init__(self, name: str, backward_keys: dict, translated_fields: dict, forward_results: dict,
                 backward_results: defaultdict, row_number_to_upper_level: dict, max_rows_retrievable):
        self._name = name
        self._backward_keys = backward_keys
        self._translated_fields = translated_fields
        self._forward_results = forward_results
        self._backward_results = backward_results
        self._max_rows_retrievable = max_rows_retrievable
        self._row_number_to_upper_level = row_number_to_upper_level

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
        for forward_key, constituents in self._forward_results.items():
            for backward_key, constituent_content in constituents.items():
                if constituent_content.get(lower_level_key) is not None:
                    if filtered_res.get(forward_key) is None:
                        filtered_res[forward_key] = {}
                    filtered_res[forward_key][backward_key] = constituent_content
        self._forward_results = filtered_res

    def max_rows_retrievable(self):
        return self._max_rows_retrievable

    def replace_backwards(self, backward_keys, backward_results, backward_name):
        self._backward_keys = backward_keys
        self._backward_results = backward_results
        self._name = backward_name
        return self

    def row_number_to_upper_level(self):
        return self._row_number_to_upper_level

    def compress_forward_results_one_level(self):
        res = {}
        for k, v in self._forward_results.items():
            res[k] = defaultdict(list)
            for k1, v1 in v.items():
                for k2, v2 in v1.items():
                    res[k][k2].append(v2)
        self._forward_results = res
