from typing import Literal, Annotated

from pydantic import Field, TypeAdapter

from intertypes import SafeInt, InterTypeBase


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


