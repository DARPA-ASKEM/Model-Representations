# ASKEM Model Representations

This repository contains schema representations for modeling frameworks supported by the ASKEM project. It includes a base schema (`base_schema.json`) which defines the most basic template required for the addition of a new framework.a

To add a framework, create a directory at the top-level of this repository using the framework name. You must include the `frameworkname_schema.json` as well as at least one example. See example directory structure below:

```
├── README.md
├── base_schema.json
├── abm
│   ├── abm_schema.json
│   └── examples
│       └── sample_abm.json
├── petrinet
│   ├── petrinet_schema.json
│   └── examples
│       └── simple_sir.json
└── regulatorynet
    ├── regulatorynet_schema.json
    └── examples
        └── sample_regulatoryynet.json
```

## Versioning
When schema updates are merged to the `main` branch, the commit should be tagged with the framework(s) that have been updated. For example, if the Petri Net framework has been updated from `v0.1` to `v0.2` the commit should be tagged `petrinet_v0.2`. A single commit may include updates to multiple frameworks; in that case more than one tag should be applied.