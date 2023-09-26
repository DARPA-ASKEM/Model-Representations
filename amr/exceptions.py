class IncompleteModelError(Exception):
    "Alert for when a non-executable model is assumed to be runnable."


class InputNotAlignedError(Exception):
    "Exception for the case where a config does not match the inputs of the model"
