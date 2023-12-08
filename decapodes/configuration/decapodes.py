from typing import Literal, Annotated

from pydantic import Field, TypeAdapter

from intertypes import SafeInt, InterTypeBase


class File(InterTypeBase):
    tag: Literal["File"] = Field(default="File", alias="_type", repr=False)
    uri: str
    checksum: str
    format: str
    shape: list[SafeInt]


class Values(InterTypeBase):
    tag: Literal["Values"] = Field(default="Values", alias="_type", repr=False)
    values: list[SafeInt]


MeshValue = Annotated[File | Values, Field(discriminator="tag")]
meshvalue_adapter: TypeAdapter[MeshValue] = TypeAdapter(MeshValue)


class Constants(InterTypeBase):
    name: str
    global_ref: str


class Header(InterTypeBase):
    id: str
    description: str
    name: str
    parent: str


class ASKEMDecapodeParameterization(InterTypeBase):
    header: "Header"
    parameters: list[float]
    constants: list["Constants"]


