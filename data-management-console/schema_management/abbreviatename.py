class AbbreviateName:
    MAX_PERMITTED_LENGTH = 60

    @classmethod
    def abbreviate_name(cls, names: list[str]):
        combined_name = "_".join(names)
        return combined_name[0:cls.MAX_PERMITTED_LENGTH]

