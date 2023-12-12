from typing import Literal, Annotated, Any

from pydantic import Field, TypeAdapter

from intertypes import SafeInt, InterTypeBase

from acsets import Ob, Hom, Attr, AttrType, Schema, ACSet
import base as AMRBase


class Parameter(InterTypeBase):
    type: str
    value: float


class Condition(InterTypeBase):
    type: str
    value: float
    domain_mesh: str


class DatasetFile(InterTypeBase):
    uri: str
    format: str
    shape: list[SafeInt]


class Dataset(InterTypeBase):
    type: str
    name: str
    description: str
    file: "DatasetFile"


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


class DecapodeConfiguration(InterTypeBase):
    parameters: list["Parameter"]
    initial_conditions: list["Condition"]
    boundary_condition: list["Condition"]
    dataset: "Dataset"


class ASKEMDecapodeConfiguration(InterTypeBase):
    header: "AMRBase.ConfigurationHeader"
    configuration: "DecapodeConfiguration"


class Constant(InterTypeBase):
    type: str
    value: "AMRBase.File"


class UnitValue(InterTypeBase):
    tag: Literal["UnitValue"] = Field(default="UnitValue", alias="_type", repr=False)
    value: float
    unit: float


class Datetime(InterTypeBase):
    tag: Literal["Datetime"] = Field(default="Datetime", alias="_type", repr=False)
    timestamp: str


ConstraintValue = Annotated[UnitValue | Datetime, Field(discriminator="tag")]
constraintvalue_adapter: TypeAdapter[ConstraintValue] = TypeAdapter(ConstraintValue)


class Dimensionality(InterTypeBase):
    manifold: SafeInt
    embedding_space: SafeInt


class RegionEquation(InterTypeBase):
    tag: Literal["RegionEquation"] = Field(default="RegionEquation", alias="_type", repr=False)
    equation: str


Region = Annotated[RegionEquation, Field(discriminator="tag")]
region_adapter: TypeAdapter[Region] = TypeAdapter(Region)


class PrimalDualRelation(InterTypeBase):
    primal: str
    dual: str
    method: str


class SubmeshRelation(InterTypeBase):
    relation: str
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
    file: "AMRBase.File"


class DecapodeContext(InterTypeBase):
    constants: list["Constant"]
    spatial_constraints: list["ConstraintValue"]
    temporal_constraints: list["ConstraintValue"]
    primal_dual_relations: list["PrimalDualRelation"]
    mesh_submesh_relations: list["SubmeshRelation"]
    meshes: list["Mesh"]
    dimensionality: SafeInt
    boundary_mesh: str


class ASKEMDecapodeContext(InterTypeBase):
    header: "AMRBase.ContextHeader"
    context: "DecapodeContext"


class Var(InterTypeBase):
    tag: Literal["Var"] = Field(default="Var", alias="_type", repr=False)
    name: str


class Lit(InterTypeBase):
    tag: Literal["Lit"] = Field(default="Lit", alias="_type", repr=False)
    name: str


class AppCirc1(InterTypeBase):
    tag: Literal["AppCirc1"] = Field(default="AppCirc1", alias="_type", repr=False)
    fs: list[str]
    arg: "Term"


class App1(InterTypeBase):
    tag: Literal["App1"] = Field(default="App1", alias="_type", repr=False)
    f: str
    arg: "Term"


class App2(InterTypeBase):
    tag: Literal["App2"] = Field(default="App2", alias="_type", repr=False)
    f: str
    arg1: "Term"
    arg2: "Term"


class Plus(InterTypeBase):
    tag: Literal["Plus"] = Field(default="Plus", alias="_type", repr=False)
    args: list["Term"]


class Mult(InterTypeBase):
    tag: Literal["Mult"] = Field(default="Mult", alias="_type", repr=False)
    args: list["Term"]


class Tan(InterTypeBase):
    tag: Literal["Tan"] = Field(default="Tan", alias="_type", repr=False)
    var: "Term"


Term = Annotated[Var | Lit | AppCirc1 | App1 | App2 | Plus | Mult | Tan, Field(discriminator="tag")]
term_adapter: TypeAdapter[Term] = TypeAdapter(Term)


class Judgement(InterTypeBase):
    var: str
    dim: str
    space: str


class Eq(InterTypeBase):
    tag: Literal["Eq"] = Field(default="Eq", alias="_type", repr=False)
    lhs: "Term"
    rhs: "Term"


Equation = Annotated[Eq, Field(discriminator="tag")]
equation_adapter: TypeAdapter[Equation] = TypeAdapter(Equation)


class DecaExpr(InterTypeBase):
    context: list["Judgement"]
    equations: list["Equation"]


class ASKEMDecapodeModel(InterTypeBase):
    header: "AMRBase.ModelHeader"
    model: "DecaExpr"


class ASKEMDecapodeSimulationPlan(InterTypeBase):
    header: "AMRBase.ModelHeader"
    model: "DecaExpr"
    context: "DecapodeContext"
    configuration: "DecapodeConfiguration"


