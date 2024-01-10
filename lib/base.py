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


