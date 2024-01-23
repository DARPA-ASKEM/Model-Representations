from typing import Literal, Annotated, Any

from pydantic import Field, TypeAdapter

from intertypes import SafeInt, InterTypeBase

from acsets import Ob, Hom, Attr, AttrType, Schema, ACSet


class ModelHeader(InterTypeBase):
    id: str | None
    description: str
    name: str
    model_version: str
    schema: str
    schema_name: str


class ContextHeader(InterTypeBase):
    id: str | None
    name: str
    description: str
    parent_model: str


class ConfigurationHeader(InterTypeBase):
    id: str | None
    description: str
    name: str
    parent_context: str


class File(InterTypeBase):
    uri: str
    format: str


class LiteralParameter(InterTypeBase):
    tag: Literal["LiteralParameter"] = Field(default="LiteralParameter", alias="_type", repr=False)
    type: str
    value: float


class ConstantParameter(InterTypeBase):
    tag: Literal["ConstantParameter"] = Field(default="ConstantParameter", alias="_type", repr=False)
    type: str
    value: str


Parameter = Annotated[LiteralParameter | ConstantParameter, Field(discriminator="tag")]
parameter_adapter: TypeAdapter[Parameter] = TypeAdapter(Parameter)


class Condition(InterTypeBase):
    type: str
    value: str
    domain_mesh: str


class NetCDF(InterTypeBase):
    tag: Literal["NetCDF"] = Field(default="NetCDF", alias="_type", repr=False)


class CSV(InterTypeBase):
    tag: Literal["CSV"] = Field(default="CSV", alias="_type", repr=False)


DatasetFormat = Annotated[NetCDF | CSV, Field(discriminator="tag")]
datasetformat_adapter: TypeAdapter[DatasetFormat] = TypeAdapter(DatasetFormat)


class DatasetFile(InterTypeBase):
    uri: str
    format: "DatasetFormat"
    shape: list[SafeInt]


class Dataset(InterTypeBase):
    type: str
    name: str
    description: str
    file: "DatasetFile"


class DecapodeConfiguration(InterTypeBase):
    parameters: dict[str, "Parameter"]
    initial_conditions: dict[str, "Condition"]
    boundary_conditions: dict[str, "Condition"]
    datasets: dict[str, "Dataset"]


class ASKEMDecapodeConfiguration(InterTypeBase):
    header: "ConfigurationHeader"
    configuration: "DecapodeConfiguration"


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


class ASKEMDecapodeContext(InterTypeBase):
    header: "ContextHeader"
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


class SchDecapode:
    Var = Ob(name="Var")
    TVar = Ob(name="TVar")
    Op1 = Ob(name="Op1")
    Op2 = Ob(name="Op2")
    src = Hom(name="src", dom=Op1, codom=Var)
    tgt = Hom(name="tgt", dom=Op1, codom=Var)
    proj1 = Hom(name="proj1", dom=Op2, codom=Var)
    proj2 = Hom(name="proj2", dom=Op2, codom=Var)
    res = Hom(name="res", dom=Op2, codom=Var)
    incl = Hom(name="incl", dom=TVar, codom=Var)
    Type = AttrType(name="Type", ty=str)
    Operator = AttrType(name="Operator", ty=str)
    op1 = Attr(name="op1", dom=Op1, codom=Operator)
    op2 = Attr(name="op2", dom=Op2, codom=Operator)
    type = Attr(name="type", dom=Var, codom=Type)
    schema = Schema(
        name="SchDecapode",
        obs=[Var, TVar, Op1, Op2],
        homs=[src, tgt, proj1, proj2, res, incl],
        attrtypes=[Type, Operator],
        attrs=[op1, op2, type]
    )



class SchNamedDecapode:
    Var = Ob(name="Var")
    TVar = Ob(name="TVar")
    Op1 = Ob(name="Op1")
    Op2 = Ob(name="Op2")
    src = Hom(name="src", dom=Op1, codom=Var)
    tgt = Hom(name="tgt", dom=Op1, codom=Var)
    proj1 = Hom(name="proj1", dom=Op2, codom=Var)
    proj2 = Hom(name="proj2", dom=Op2, codom=Var)
    res = Hom(name="res", dom=Op2, codom=Var)
    incl = Hom(name="incl", dom=TVar, codom=Var)
    Type = AttrType(name="Type", ty=str)
    Operator = AttrType(name="Operator", ty=str)
    Name = AttrType(name="Name", ty=str)
    op1 = Attr(name="op1", dom=Op1, codom=Operator)
    op2 = Attr(name="op2", dom=Op2, codom=Operator)
    type = Attr(name="type", dom=Var, codom=Type)
    name = Attr(name="name", dom=Var, codom=Name)
    schema = Schema(
        name="SchNamedDecapode",
        obs=[Var, TVar, Op1, Op2],
        homs=[src, tgt, proj1, proj2, res, incl],
        attrtypes=[Type, Operator, Name],
        attrs=[op1, op2, type, name]
    )



class AbstractDecapode(ACSet):
    pass


class AbstractNamedDecapode(AbstractDecapode):
    pass


class DecapodeSym(AbstractDecapode):

    def __init__(self, name="DecapodeSym", schema=SchDecapode.schema):
        super(DecapodeSym, self).__init__(name, schema)

    @classmethod
    def read_json(cls, s: str):
        return super(DecapodeSym, cls).read_json("DecapodeSym", SchDecapode.schema, s)



class NamedDecapodeSym(AbstractNamedDecapode):

    def __init__(self, name="NamedDecapodeSym", schema=SchNamedDecapode.schema):
        super(NamedDecapodeSym, self).__init__(name, schema)

    @classmethod
    def read_json(cls, s: str):
        return super(NamedDecapodeSym, cls).read_json("NamedDecapodeSym", SchNamedDecapode.schema, s)



class SchSummationDecapode:
    Var = Ob(name="Var")
    TVar = Ob(name="TVar")
    Op1 = Ob(name="Op1")
    Op2 = Ob(name="Op2")
    Σ = Ob(name="Σ")
    Summand = Ob(name="Summand")
    src = Hom(name="src", dom=Op1, codom=Var)
    tgt = Hom(name="tgt", dom=Op1, codom=Var)
    proj1 = Hom(name="proj1", dom=Op2, codom=Var)
    proj2 = Hom(name="proj2", dom=Op2, codom=Var)
    res = Hom(name="res", dom=Op2, codom=Var)
    incl = Hom(name="incl", dom=TVar, codom=Var)
    summand = Hom(name="summand", dom=Summand, codom=Var)
    summation = Hom(name="summation", dom=Summand, codom=Σ)
    sum = Hom(name="sum", dom=Σ, codom=Var)
    Type = AttrType(name="Type", ty=str)
    Operator = AttrType(name="Operator", ty=str)
    Name = AttrType(name="Name", ty=str)
    op1 = Attr(name="op1", dom=Op1, codom=Operator)
    op2 = Attr(name="op2", dom=Op2, codom=Operator)
    type = Attr(name="type", dom=Var, codom=Type)
    name = Attr(name="name", dom=Var, codom=Name)
    schema = Schema(
        name="SchSummationDecapode",
        obs=[Var, TVar, Op1, Op2, Σ, Summand],
        homs=[src, tgt, proj1, proj2, res, incl, summand, summation, sum],
        attrtypes=[Type, Operator, Name],
        attrs=[op1, op2, type, name]
    )



class SummationDecapodeSym(AbstractNamedDecapode):

    def __init__(self, name="SummationDecapodeSym", schema=SchSummationDecapode.schema):
        super(SummationDecapodeSym, self).__init__(name, schema)

    @classmethod
    def read_json(cls, s: str):
        return super(SummationDecapodeSym, cls).read_json("SummationDecapodeSym", SchSummationDecapode.schema, s)



class ASKEMDecapodeModel(InterTypeBase):
    header: "ModelHeader"
    model: "DecaExpr"


class ASKEMDecapodeSimulationPlan(InterTypeBase):
    header: "ModelHeader"
    model: "DecaExpr"
    context: "DecapodeContext"
    configuration: "DecapodeConfiguration"


