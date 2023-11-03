from typing import Literal, Annotated

from pydantic import Field, TypeAdapter

from intertypes import SafeInt, InterTypeBase


class Dimensionality(InterTypeBase):
    surface: SafeInt
    embedding: SafeInt


class Equation(InterTypeBase):
    tag: Literal["Equation"] = Field(default="Equation", alias="_type", repr=False)
    equation: str


Region = Annotated[Equation, Field(discriminator="tag")]
region_adapter: TypeAdapter[Region] = TypeAdapter(Region)


class SubmeshRelation(InterTypeBase):
    parent: str
    child: str


class Mesh(InterTypeBase):
    id: str
    description: str
    file: str
    checksum: str
    submesh_relation: list["SubmeshRelation"]
    dimensionality: "Dimensionality"
    vertex_count: SafeInt
    regions: list["Region"]


class Configuration(InterTypeBase):
    meshes: list["Mesh"]
    dimensionality: SafeInt
    boundary_mesh: str


class Header(InterTypeBase):
    id: str
    description: str
    name: str
    parent: str


class ASKEMDecapodeConfig(InterTypeBase):
    header: "Header"
    configuration: "Configuration"


