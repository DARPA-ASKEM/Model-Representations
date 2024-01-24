from typing import Literal, Annotated, Any

from pydantic import Field, TypeAdapter

from intertypes import SafeInt, InterTypeBase

from acsets import Ob, Hom, Attr, AttrType, Schema, ACSet


class Math(InterTypeBase):
    tag: Literal["Math"] = Field(default="Math", alias="_type", repr=False)
    str: str


class Presentation(InterTypeBase):
    tag: Literal["Presentation"] = Field(default="Presentation", alias="_type", repr=False)
    str: str


MathML = Annotated[Math | Presentation, Field(discriminator="tag")]
mathml_adapter: TypeAdapter[MathML] = TypeAdapter(MathML)


class ExpressionFormula(InterTypeBase):
    expression: str
    expression_mathml: "MathML"


class Unit(InterTypeBase):
    expression: str
    expression_mathml: "MathML"


class StandardUniform(InterTypeBase):
    tag: Literal["StandardUniform"] = Field(default="StandardUniform", alias="_type", repr=False)


class Uniform(InterTypeBase):
    tag: Literal["Uniform"] = Field(default="Uniform", alias="_type", repr=False)
    min: float
    max: float


class StandardNormal(InterTypeBase):
    tag: Literal["StandardNormal"] = Field(default="StandardNormal", alias="_type", repr=False)


class Normal(InterTypeBase):
    tag: Literal["Normal"] = Field(default="Normal", alias="_type", repr=False)
    mean: float
    variance: float


class PointMass(InterTypeBase):
    tag: Literal["PointMass"] = Field(default="PointMass", alias="_type", repr=False)
    value: float


class Undefined(InterTypeBase):
    tag: Literal["Undefined"] = Field(default="Undefined", alias="_type", repr=False)


Distribution = Annotated[StandardUniform | Uniform | StandardNormal | Normal | PointMass | Undefined, Field(discriminator="tag")]
distribution_adapter: TypeAdapter[Distribution] = TypeAdapter(Distribution)


class Observable(InterTypeBase):
    id: str
    name: str
    states: list[str]
    f: "ExpressionFormula"


class Rate(InterTypeBase):
    tag: Literal["Rate"] = Field(default="Rate", alias="_type", repr=False)
    target: str
    f: "ExpressionFormula"


class Initial(InterTypeBase):
    tag: Literal["Initial"] = Field(default="Initial", alias="_type", repr=False)
    target: str
    f: "ExpressionFormula"


class Parameter(InterTypeBase):
    tag: Literal["Parameter"] = Field(default="Parameter", alias="_type", repr=False)
    id: str
    name: str
    description: str
    units: "Unit"
    value: float
    distribution: "Distribution"


class Time(InterTypeBase):
    tag: Literal["Time"] = Field(default="Time", alias="_type", repr=False)
    id: str
    units: "Unit"


Expression = Annotated[Rate | Initial | Parameter | Time, Field(discriminator="tag")]
expression_adapter: TypeAdapter[Expression] = TypeAdapter(Expression)


class Name(InterTypeBase):
    tag: Literal["Name"] = Field(default="Name", alias="_type", repr=False)
    str: str


class Description(InterTypeBase):
    tag: Literal["Description"] = Field(default="Description", alias="_type", repr=False)
    str: str


class Grounding(InterTypeBase):
    tag: Literal["Grounding"] = Field(default="Grounding", alias="_type", repr=False)
    ontology: str
    identifier: str


class Units(InterTypeBase):
    tag: Literal["Units"] = Field(default="Units", alias="_type", repr=False)
    expression: str


Note = Annotated[Name | Description | Grounding | Units, Field(discriminator="tag")]
note_adapter: TypeAdapter[Note] = TypeAdapter(Note)


class Annotation(InterTypeBase):
    entity: str
    type: str
    note: "Note"


class Header(InterTypeBase):
    name: str
    schema: str
    description: str
    schema_name: str
    model_version: str


