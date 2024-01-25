from typing import Literal, Annotated, Any

from pydantic import Field, TypeAdapter

from intertypes import SafeInt, InterTypeBase

from acsets import Ob, Hom, Attr, AttrType, Schema, ACSet


class File(InterTypeBase):
    uri: str
    format: str


class FileConstant(InterTypeBase):
    tag: Literal["FileConstant"] = Field(default="FileConstant", alias="_type", repr=False)
    value: "File"


class RawConstant(InterTypeBase):
    tag: Literal["RawConstant"] = Field(default="RawConstant", alias="_type", repr=False)
    value: float


Constant = Annotated[FileConstant | RawConstant, Field(discriminator="tag")]
constant_adapter: TypeAdapter[Constant] = TypeAdapter(Constant)


class UnitValue(InterTypeBase):
    tag: Literal["UnitValue"] = Field(default="UnitValue", alias="_type", repr=False)
    value: float
    unit: str


class Datetime(InterTypeBase):
    tag: Literal["Datetime"] = Field(default="Datetime", alias="_type", repr=False)
    timestamp: str


ConstraintValue = Annotated[UnitValue | Datetime, Field(discriminator="tag")]
constraintvalue_adapter: TypeAdapter[ConstraintValue] = TypeAdapter(ConstraintValue)


class Dimensionality(InterTypeBase):
    manifold: SafeInt
    embedding: SafeInt


class RegionEquation(InterTypeBase):
    tag: Literal["RegionEquation"] = Field(default="RegionEquation", alias="_type", repr=False)
    equations: list[str]


Region = Annotated[RegionEquation, Field(discriminator="tag")]
region_adapter: TypeAdapter[Region] = TypeAdapter(Region)


class Barycenter(InterTypeBase):
    tag: Literal["Barycenter"] = Field(default="Barycenter", alias="_type", repr=False)


class Circumcenter(InterTypeBase):
    tag: Literal["Circumcenter"] = Field(default="Circumcenter", alias="_type", repr=False)


MethodType = Annotated[Barycenter | Circumcenter, Field(discriminator="tag")]
methodtype_adapter: TypeAdapter[MethodType] = TypeAdapter(MethodType)


class PrimalDualRelation(InterTypeBase):
    primal: str
    dual: str
    method: "MethodType"


class Perimeter(InterTypeBase):
    tag: Literal["Perimeter"] = Field(default="Perimeter", alias="_type", repr=False)


RelationType = Annotated[Perimeter, Field(discriminator="tag")]
relationtype_adapter: TypeAdapter[RelationType] = TypeAdapter(RelationType)


class SubmeshRelation(InterTypeBase):
    relation: "RelationType"
    mesh: str
    submesh: str


class Mesh(InterTypeBase):
    id: str
    description: str
    dimensionality: "Dimensionality"
    vertex_count: SafeInt
    edge_count: SafeInt
    face_count: SafeInt
    volume_count: SafeInt
    regions: list["Region"]
    checksum: str
    file: "File"


class DecapodeContext(InterTypeBase):
    constants: dict[str, "Constant"]
    spatial_constraints: dict[str, "ConstraintValue"]
    temporal_constraints: dict[str, "ConstraintValue"]
    primal_dual_relations: list["PrimalDualRelation"]
    mesh_submesh_relations: list["SubmeshRelation"]
    meshes: list["Mesh"]


