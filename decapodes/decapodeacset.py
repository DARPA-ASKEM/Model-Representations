from typing import Literal, Annotated, Any

from pydantic import Field, TypeAdapter

from intertypes import SafeInt, InterTypeBase

from acsets import Ob, Hom, Attr, AttrType, Schema, ACSet


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



class SymNamedDecapode(AbstractNamedDecapode):

    def __init__(self, name="SymNamedDecapode", schema=SchNamedDecapode.schema):
        super(SymNamedDecapode, self).__init__(name, schema)

    @classmethod
    def read_json(cls, s: str):
        return super(SymNamedDecapode, cls).read_json("SymNamedDecapode", SchNamedDecapode.schema, s)



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



class SymSummationDecapode(AbstractNamedDecapode):

    def __init__(self, name="SymSummationDecapode", schema=SchSummationDecapode.schema):
        super(SymSummationDecapode, self).__init__(name, schema)

    @classmethod
    def read_json(cls, s: str):
        return super(SymSummationDecapode, cls).read_json("SymSummationDecapode", SchSummationDecapode.schema, s)



