# QuasiOptical v10 verification

Verified on 2026-11-08 with MATLAB R2026b, using the workspace-root source files and no additional MATLAB toolboxes.

- Full MATLAB regression suite: **104 passed, 0 failed, 0 incomplete**.
- Eight UI checks passed: the original smoke test, v5 through v9 smoke tests, the new illumination diagnostic check and the v10 retrieval/comparison/export check.
- After the final planner and layout cleanup, the six acquisition-planner tests and diagnostic UI check passed again in a fresh MATLAB process.
- The standalone symbolic HTML controller check passed, including acquisition counts and oblique NRW eligibility.

The oblique tests recover dielectric and magnetic samples at 0, 15, 30, 45 and 60 degrees for TE and TM. The well-conditioned noiseless benchmarks require complex material errors below 1e-8 and complex R/T reconstruction residuals below 1e-10. Tests also reproduce the supplied 6 GHz, 10 mm, 45-degree benchmark and its deliberately incorrect normal-incidence interpretation.

Additional checks cover Brewster reflection, half-wave and critical-propagation singularities, transmission floors, phase gaps, branch settings, invalid angles, nonpassive inputs and asymmetric four-channel data. TE/TM comparison rejects mismatched frequency grids, angles, thicknesses and same-polarization inputs. Synthetic generation records its known material values and truth-based initial branch seed separately from editable retrieval assumptions.

Illumination checks cover launch and lens waists, signed curvature, rotated rectangular boundaries, divergence, receiver offset, grazing unavailability, zero-distance idealization and the exact spherical benchmark of 59.892179 degrees. The Gaussian quadratic phase and exact spherical reference are explicitly distinguished.

Every PNG from the v10 retrieval export smoke test was checked for visible image content. Native MATLAB previews and representative plot/table exports were visually inspected. Large parameter tables use bounded rendering tiles and continuation rows, then combine into one complete PNG; this resolves the black-image failure found during visual QA. Metadata and CSV readback checks verify propagation quantities, provenance, comparison data and the frozen illumination/setup snapshot.

This verifies synthetic recovery and software behavior. Experimental accuracy remains unvalidated until calibrated reference measurements are available. The model remains a homogeneous isotropic slab in air with known normal thickness and calibrated complex sample-face reflection/transmission; general tensor inversion and the deferred corrections listed in the [technical guide](docs/TECHNICAL_GUIDE.md) are outside v10.
