from typing import Literal, Annotated, Any

from pydantic import Field, TypeAdapter

from intertypes import SafeInt, InterTypeBase

from acsets import Ob, Hom, Attr, AttrType, Schema, ACSet
import amr
import decapodes
import decapodeacset


class ASKEMDecaExpr(InterTypeBase):
    tag: Literal["ASKEMDecaExpr"] = Field(default="ASKEMDecaExpr", alias="_type", repr=False)
    header: "amr.Header"
    model: "decapodes.DecaExpr"
    annotations: list["amr.Annotation"]


class ASKEMDecapode(InterTypeBase):
    tag: Literal["ASKEMDecapode"] = Field(default="ASKEMDecapode", alias="_type", repr=False)
    header: "amr.Header"
    model: "decapodeacset.SymSummationDecapode"
    annotations: list["amr.Annotation"]


ASKEMDeca = Annotated[ASKEMDecaExpr | ASKEMDecapode, Field(discriminator="tag")]
askemdeca_adapter: TypeAdapter[ASKEMDeca] = TypeAdapter(ASKEMDeca)


