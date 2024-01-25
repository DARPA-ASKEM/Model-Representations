from typing import Literal, Annotated, Any

from pydantic import Field, TypeAdapter

from intertypes import SafeInt, InterTypeBase

from acsets import Ob, Hom, Attr, AttrType, Schema, ACSet
import configuration as DecapodeConfigurations
import context as DecapodeContexts
import model as DecapodeModels


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


class ASKEMDecapodeConfiguration(InterTypeBase):
    header: "ConfigurationHeader"
    configuration: "DecapodeConfigurations.DecapodeConfiguration"


class ASKEMDecapodeContext(InterTypeBase):
    header: "ContextHeader"
    context: "DecapodeContexts.DecapodeContext"


class ASKEMDecapodeModel(InterTypeBase):
    header: "ModelHeader"
    model: "DecapodeModels.DecaExpr"


class ASKEMDecapodeSimulationPlan(InterTypeBase):
    header: "ModelHeader"
    model: "DecapodeModels.DecaExpr"
    context: "DecapodeContexts.DecapodeContext"
    configuration: "DecapodeConfigurations.DecapodeConfiguration"


