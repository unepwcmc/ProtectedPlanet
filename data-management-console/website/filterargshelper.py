# Small helper class
from twisted.web.server import Request
from schema_management.filterargs import FilterArgs


class FilterArgsHelper:

    @staticmethod
    def gather(req: Request):
        return FilterArgs(req.args)
