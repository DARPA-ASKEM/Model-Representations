from __future__ import annotations

from typing import Any, Dict, List, Optional

from pydantic import AnyUrl, BaseModel, RootModel, Extra, Field

from .base import AMR
from .exceptions import IncompleteModelError, InputNotAlignedError


class Rate(BaseModel):
    target: Optional[str] = None
    expression: Optional[str] = None
    expression_mathml: Optional[str] = None


class Initial(BaseModel):
    target: Optional[str] = None
    expression: Optional[str] = None
    expression_mathml: Optional[str] = None


class Distribution(BaseModel):
    class Config:
        extra = Extra.allow

    type: str
    parameters: Dict[str, Any]


class Grounding(BaseModel):
    class Config:
        extra = Extra.forbid

    identifiers: Dict[str, Any]
    modifiers: Optional[Dict[str, Any]] = None


class Properties(BaseModel):
    class Config:
        extra = Extra.allow

    name: str
    description: Optional[str] = None
    grounding: Optional[Grounding] = None


class Unit(BaseModel):
    class Config:
        extra = Extra.allow

    expression: Optional[str] = None
    expression_mathml: Optional[str] = None


class Parameter(BaseModel):
    id: str
    name: Optional[str] = None
    description: Optional[str] = None
    value: Optional[float] = None
    grounding: Optional[Grounding] = None
    distribution: Optional[Distribution] = None
    units: Optional[Unit] = None


class Time(BaseModel):
    id: str
    units: Optional[Unit] = None


class OdeSemantics(BaseModel):
    rates: Optional[List[Rate]] = None
    initials: Optional[List[Initial]] = None
    parameters: Optional[List[Parameter]] = None
    time: Optional[Time] = None


class State(BaseModel):
    id: str
    name: Optional[str] = None
    description: Optional[str] = None
    grounding: Optional[Grounding] = None
    units: Optional[Unit] = None


class Transition(BaseModel):
    id: str
    input: List[str]
    output: List[str]
    grounding: Optional[Grounding] = None
    properties: Optional[Properties] = None


class Model(BaseModel):
    class Config:
        extra = Extra.forbid

    states: List[State]
    transitions: List[Transition]


class Semantics(BaseModel):
    ode: Optional[OdeSemantics] = None
    typing: Optional[TypingSemantics] = Field(
        None,
        description='(Optional) Information for aligning models for stratification',
    )
    span: Optional[List[TypingSemantics]] = Field(
        None,
        description='(Optional) Legs of a span, each of which are a full ASKEM Petri Net',
    )


class TypingSemantics(BaseModel):
    system: Model = Field(
        ...,
        description="A Petri net representing the 'type system' that is necessary to align states and transitions across different models during stratification.",
    )
    map: List[List[str]] = Field(
        ...,
        description='A map between the (state and transition) nodes of the model and the (state and transition) nodes of the type system',
    )


Semantics.update_forward_refs()


class Selection(BaseModel):
    id: str
    value: float


class PetrinetConfig(BaseModel):
    parameters: List[Selection] = []


class Petrinet(AMR):
    model: Model
    semantics: Optional[Semantics] = Field(
        None,
        description='Information specific to a given semantics (e.g., ODEs) associated with a model.',
    )


    @property
    def config(self) -> Optional[PetrinetConfig]:
        if not self.is_executable:
            return None
        parameters = self.semantics.ode.parameters
        return PetrinetConfig(
            parameters = [Selection(id=param.id, value=param.value) for param in parameters],
        )

    
    def reconfigure(self, config):
        if not isinstance(config, PetrinetConfig):
            raise TypeError("Config is not a PetrinetConfig'")
        if not self.is_executable:
            raise IncompleteModelError("Cannot configure petrinet that isn't executable")
        mappings = {selection.id: selection.value for selection in config.parameters}
        for param_index in range(len(self.semantics.ode.parameters)):
            param_id = self.semantics.ode.parameters[param_index].id
            if param_id in mappings:
                self.semantics.ode.parameters[param_index].value = mappings.pop(param_id)
            # TODO?: Should we fail this case?
            # else:
            #     raise InputNotAlignedError("Parameter not modified")
        if len(mappings) != 0:
            raise InputNotAlignedError(f"Selection made of nonexistent parameters: {list(mappings.keys())}")

    
    @property
    def is_executable(self):
        missing_semantics = self.semantics is None or self.semantics.ode is None
        return not missing_semantics
