# Lotka-Volterra Semantics for Regnets

This file explains how to interperet Regnets with Lotka-Volterra Semantics. 
The key idea is that variables of the system are the vertices and interactions are edges.

A *Lotka-Volterra system* of equations has the form

\[
  \dot x_i = \rho_i\, x_i + \sum_{j=1}^n \beta_{i,j}\, x_i\, x_j,
  \qquad i = 1,\dots,n.
\]

or equivalently, has logarithmic derivatives that are affine functions of the
state variables:

\[
  \frac{d}{dt}[\log x_i(t)] = \rho_i + \sum_{j=1}^n \beta_{i,j}\, x_j(t),
  \qquad i = 1,\dots,n.
\]

The coefficients $\rho_i$ specify baseline rates of growth or decay, according
to their sign, and the coefficients $\beta_{i,j}$ rates of activation or
inhibition, according to their sign. We construct a functor that sends a signed
graph (regulatory network) to a Lotka-Volterra model that constrains the signs
of the rate coefficients By working with signed graphs, rather than merely
graphs, we ensure that scientific knowledge about whether interactions are
promoting or inhibiting is reflected in both the syntax and the quantitative
semantics.

In order to comprehend complex biological systems, we must decompose them into
small, readily understandable pieces and then compose them back together to
reproduce the behavior of the original system. This is the mantra of systems
biology, which stresses that compositionality is no less important than
reductionism in biology.

[link to motifs]

Signed Graphs are stored in Catlab using the following schemas:

```julia

@present SchGraph(FreeSchema)
  (V,E)::Ob
  src::Hom(E,V)
  tgt::Hom(E,V)
end

@present SchSignedGraph <: SchGraph begin
  Sign::AttrType
  sign::Attr(E,Sign)
end

# when you want rates to be stored in the model
@present SchRateSignedGraph <: SchSignedGraph begin
  A::AttrType
  vrate::Attr(V,A)
  erate::Attr(E,A)
end
```

These Catlab Schemas are equivalent to the following SQL

```SQL
CREATE TABLE "Vertices" (
	"id"	INTEGER,
	PRIMARY KEY("id")
);

CREATE TABLE "Edges" (
	"id"	INTEGER,
	"src"	INTEGER,
	"tgt"	INTEGER,
	"sign"	BOOL,
	PRIMARY KEY("id"),
	FOREIGN KEY("src") REFERENCES "Vertices"("id"),
	FOREIGN KEY("tgt") REFERENCES "Vertices"("vid")
);

-- or with rates

CREATE TABLE "Vertices" (
	"id"	INTEGER,
  "vrate" NUMBER,
	PRIMARY KEY("id")
);

CREATE TABLE "Edges" (
	"id"	INTEGER,
	"src"	INTEGER,
	"tgt"	INTEGER,
	"sign"	BOOL,
  "erate" Number,
	PRIMARY KEY("id"),
	FOREIGN KEY("src") REFERENCES "Vertices"("id"),
	FOREIGN KEY("tgt") REFERENCES "Vertices"("vid")
);
```

The dynamics are given by the following julia program, which iterates over the vertices of the graph and then the neighbors of that vertex (incident edges).

```julia
function vectorfield(sg::AbstractSignedGraph)
  (u, p, t) -> [
    p[:vrate][i]*u[i] + sum(
        (sg[e,:sign] ? 1 : -1)*p[:erate][e]*u[i]u[sg[e, :src]]
      for e in incident(sg, i, :tgt); init=0.0)
    for i in 1:nv(sg)
  ]
end
```

And they can be drawn using Graphviz using the following snippet that draws positive edges as arrows and negative edges as tees.

```julia
function Catlab.Graphics.to_graphviz_property_graph(sg::AbstractSignedGraph; kw...)
  get_attr_str(attr, i) = String(has_subpart(sg, attr) ? subpart(sg, i, attr) : Symbol(i))
  pg = PropertyGraph{Any}(;kw...)
  map(parts(sg, :V)) do v
    add_vertex!(pg, label=get_attr_str(:vname, v))
  end
  map(parts(sg, :E)) do e
    add_edge!(pg, sg[e, :src], sg[e, :tgt], label=get_attr_str(:ename, e), arrowhead=(sg[e,:sign] ? "normal" : "tee"))
  end
  pg
end
```
