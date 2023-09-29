# Class to ensure we don't generate names that are too long for our databases (Postgres has 64 character limit, for example)
class AbbreviateName:
    MAX_PERMITTED_LENGTH = 60

    @classmethod
    def abbreviate_name(cls, names: list[str]):
        combined_name = "_".join(names)
        return combined_name[0:cls.MAX_PERMITTED_LENGTH]
