from typing import Literal, Annotated, Any

from pydantic import Field, TypeAdapter

from intertypes import SafeInt, InterTypeBase

from acsets import Ob, Hom, Attr, AttrType, Schema, ACSet


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


class SymDecapode(AbstractDecapode):

    def __init__(self, name="SymDecapode", schema=SchDecapode.schema):
        super(SymDecapode, self).__init__(name, schema)

    @classmethod
    def read_json(cls, s: str):
        return super(SymDecapode, cls).read_json("SymDecapode", SchDecapode.schema, s)



class NamedSymDecapode(AbstractNamedDecapode):

    def __init__(self, name="NamedSymDecapode", schema=SchNamedDecapode.schema):
        super(NamedSymDecapode, self).__init__(name, schema)

    @classmethod
    def read_json(cls, s: str):
        return super(NamedSymDecapode, cls).read_json("NamedSymDecapode", SchNamedDecapode.schema, s)



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



class SummationSymDecapode(AbstractNamedDecapode):

    def __init__(self, name="SummationSymDecapode", schema=SchSummationDecapode.schema):
        super(SummationSymDecapode, self).__init__(name, schema)

    @classmethod
    def read_json(cls, s: str):
        return super(SummationSymDecapode, cls).read_json("SummationSymDecapode", SchSummationDecapode.schema, s)



