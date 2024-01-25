from typing import Literal, Annotated, Any

from pydantic import Field, TypeAdapter

from intertypes import SafeInt, InterTypeBase

from acsets import Ob, Hom, Attr, AttrType, Schema, ACSet


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


