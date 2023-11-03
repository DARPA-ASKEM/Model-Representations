from typing import Annotated

from pydantic import BaseModel, PlainSerializer

SafeInt = Annotated[
    int, PlainSerializer(lambda x: str(x), return_type=str, when_used="json")
]


class InterTypeBase(BaseModel):
    def model_dump_json(self, *args, **kwargs):
        return super().model_dump_json(*args, **kwargs, by_alias=True)
