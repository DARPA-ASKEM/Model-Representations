from __future__ import annotations

from typing import Any, Dict, List, Optional, Type

from pydantic import AnyUrl, BaseModel, Extra, Field


class Header(BaseModel):
    name: str
    schema_: AnyUrl = Field(..., alias='schema')
    schema_name: Optional[str] = None
    description: str
    model_version: Optional[str] = None


class AMR(BaseModel):
    class Config:
        extra = Extra.allow

    header: Header
    properties: Optional[Dict[str, Any]] = None
    metadata: Optional[Dict[str, Any]] = Field(
        None,
        description="(Optional) Information not useful for execution of the model, but that may be useful to some consumer in the future. E.g. creation timestamp or source paper's author.",
    )


    @property
    def config(self) -> Optional[Type[BaseModel]]:
        raise NotImplementedError

    def reconfigure(self, config):
        raise NotImplementedError


    @property
    def is_executable(self):
        return False
