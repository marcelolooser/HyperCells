# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-03

### Added
- Add `TGQuotientSequencesStructure` for studying quotients of normal subgroups of the triangle group and their relationships, in particular for constructing sequences of supercels (@marcelolooser).
- Add additional method for simplifying words based on the Knuth-Bendix completion algorithm (@marcelolooser).
- Add `LiebModelGraph` for constructing models defined of hyperbolic Lieb lattices (@marcelolooser).
- Add `PGMatrix` and related functionality for constructing matrix representations of point-group actions on momenta (@marcelolooser).

### Changed
- Updated references, URLs etc. to reflect transfer of repository to HyperCells organization and new website https://www.hypercells.net.

### Fixed
- Fix wrong vertex references in edge specifications.
- Corrected various typos in the documentation and instructions.


## [0.9.1-beta] - 2024-03-05

### Added
- Allow for supercell models to be constructed from models defined on (smaller)
supercells using `TGSuperCellModelGraph`.
- Add a change log (this file).
- Add link to getting-started guide to README.md and to the website.

### Changed
- Update references: add published versions, DOIs etc.

### Fixed
- Fix return type given in the documentation of `AddOrientedNNNEdgesToTessellationModelGraph`.
- Fix edge tag format for nearest-neighbor edges construced using `TGCellModelGraph`,
`TessellationModelGraph`, and `KagomeModelGraph`. Note that this might introduce breaking
changes when explicitly referring to the edge tags.


## [0.9.0-beta] - 2023-11-29

Initial release.