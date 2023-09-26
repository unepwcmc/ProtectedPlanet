class FilterOnValue:

    def __init__(self, value):
        self.value = value


class FilterOnRange:

    def __init__(self, range_value: str):
        # remove the range keyword and split the lower and upper bounds
        range_bounds = range_value.lower().replace("range:", "").split(":")
        self.lower_value = range_bounds[0]
        self.upper_value = range_bounds[1]


class FilterArgs:

    def __init__(self, args_dict):
        self.elements = {}
        for k, v in args_dict.items():
            key = bytes.decode(k, "utf-8")
            value = bytes.decode(v[0], "utf-8")
            if "range:" in value.lower():
                self.elements[key] = FilterOnRange(value)
            else:
                self.elements[key] = FilterOnValue(value)

    def get_next_arg(self, to_ignore=None):
        for (key, value) in self.elements.items():
            if not to_ignore or key not in to_ignore:
                yield key, value

    def get_arg(self, arg_name):
        return self.elements[arg_name].value if self.elements.get(arg_name) else None

    def print_supplied_args(self):
        print("Supplied arguments are:")
        for arg, val in self.get_next_arg():
            print(f"\t{arg} has value {val.value}")
