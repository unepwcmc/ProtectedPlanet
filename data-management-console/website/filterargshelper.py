from flask import request
from schema_mgmt.filterargs import FilterArgs


class FilterArgsHelper:

    @staticmethod
    def gather(req: request):
        return FilterArgs(req.args)
