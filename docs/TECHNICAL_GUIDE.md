# Technical guide and version notes

See the [quick start](../README.md) for installation and the measurement workflow.

## v10: oblique NRW, synthetic examples and illumination diagnostics

**S-parameters to epsilon / mu** now supports **NRW at one fixed incidence angle with explicit TE or TM polarization**. Normal thickness and calibrated complex sample-face reflection/transmission are required. NRW retrieves normal propagation `q = kz/k0` and impedance `z = Zslab/Zair,polarization`, then converts to complex scalar permittivity and permeability. `n` remains the bulk refractive index; it is distinct from `q` at oblique incidence. NIST iterative and New non-iterative retain their normal-incidence restriction and `mu=1` assumption. Grazing incidence is excluded. Receiver observation-arc samples are not incidence sweeps and cannot be inverted with this slab model.

**Load synthetic example** provides the supplied oblique note's benchmark (6 GHz, 10 mm, 45 degrees, `epsilon=4-j0.08`, `mu=1`) and a broadband spectrum from the Simulation band/material. Generated inputs are explicitly marked **synthetic**, with their known properties and provenance. The example loader seeds the editable initial propagation branch from its known generation truth; this does not resolve branches for measured data. An optional second spectrum uses the existing CSV/Touchstone formats and its own fixed angle, normal thickness and opposite polarization. Comparison requires exactly matching frequency grids, angle and thickness; it does not interpolate. Plots show both recovered properties, complex TE-minus-TM differences and input/reconstructed complex R/T. Disagreement indicates possible measurement or model inconsistency; it does not establish anisotropy. Changing retrieval inputs clears affected results and disables export until recalculation.

In **Simulation → Illumination diagnostics**, inspect bare-horn far-field onset, Gaussian wavefront curvature, maximum curvature phase relative to the central tangent plane over the rotated rectangle, strongest boundary electric field, paraxial divergence and receiver alignment. These are estimates for the app's assumed Gaussian beam, with the beam cross-section frozen at the sample center. The **22.5-degree phase** and **-20 dB boundary-field** values are labeled engineering guidance, not accuracy guarantees or standards compliance. Near grazing, specimen phase/edge estimates remain unavailable; zero distance is an idealized launch plane. Illumination warnings do not change numerical retrieval validity.

Plot and retrieval export bundles include the diagnostic values, assumptions and setup snapshot. Retrieval exports also include incidence, polarization, `q`, `kz`, polarization-normalized impedance, synthetic provenance and any TE/TM comparison. The setup snapshot is captured when calculating; it is separate from the measurement's entered angle and does not assert that imported data were acquired with the displayed setup.

The [retrieval guide](../Retrieval_method.html) includes the oblique equations and benchmark. Source: the supplied *Oblique-Incidence Material Extraction in NRL-Arch and Free-Space Electromagnetic Measurements*, pp. 6-9 and 13. [Fenner and Rothwell (2015)](https://doi.org/10.1155/2015/657254) study curved-wave effects in a specific conductor-backed reflection-only method; their results are model-dependent, so no universal error bound is inferred here. Reference-plane correction, time gating, multilayers, reflection-only fitting, uncertainty propagation, Gaussian receiver coupling and full tensor retrieval remain later extensions. Experimental accuracy has not yet been validated against reference measurements.

See [the v10 verification record](../V10_validation.md) for the 104-test regression result, UI/export checks and model limits. Large parameter tables remain one complete PNG with continuation panels; exports are checked for blank/black image output.

## v9: smaller samples and horn aperture estimates

In **Simulation → Geometry**, set the sample width and height independently from **1 to 110 cm**. If you know the horn aperture, select **Known aperture (manual)** and enter the maximum linear dimension of the horn opening. If it is unknown, choose the nominal **15, 20, or 25 dBi** standard-horn option. These are generic options; actual standard gain horns are specified for particular bands, as shown in the [RFspin manufacturer catalog](https://www.rfspin.com/wp-content/uploads/2022/03/catalog_RFspin.pdf).

The app estimates an equivalent square aperture diagonal from the selected gain at the center frequency, using `D = lambda_center * sqrt(10^(gain_dBi/10)/(2*pi*0.50))`. The estimate uses the gain–aperture relation described in the [SARA conference proceedings, p. 10](https://radiojove.gsfc.nasa.gov/library/pubs/docs/SARA-2014_RJ/2014%20SARA%20Proceedings%20PDF.pdf#page=11), with aperture efficiency assumed to be 0.50. The app holds this size fixed over the low-to-high sweep and recomputes it when you change the center frequency. Plot exports include the aperture used, its source, and the nominal gain and assumed efficiency where applicable. For a real measurement setup, use the measured horn aperture or the manufacturer's dimensions in **Known aperture (manual)**; the generic estimate does not represent a specific calibrated horn or verify that the band is supported.

## v8: zero horn-to-sample distance

In **Simulation → Geometry**, set **Tx/Rx distance to sample center** from **0 to 5 m** (default **1.2 m**). At **0 m**, both horn aperture reference centers coincide with the sample center. Horn orientations still define the beam directions and angles. The footprint at zero distance is the illustrative Gaussian launch-plane footprint; the app does not model electromagnetic contact coupling. The ideal lenses are inactive whenever their position is at or beyond the sample distance.

## v7: adjustable frequency band

In **Simulation → Geometry**, enter **Low frequency** and **High frequency** in GHz and set **Center frequency** with its numeric input or slider. The defaults are **2 / 10 / 25 GHz** (low / center / high). The bounds must be positive, with low below high. The center is selected independently within the band; it does not have to be the midpoint. Narrowing the band keeps the center if it still fits, or moves it to the nearest endpoint.

Both the field-region and material R/T/A frequency plots use the low and high endpoints, with 240 and 180 uniformly spaced samples respectively. The dotted line in each plot marks the selected center, which drives the 3D geometry, footprints, beam radius and single-frequency material calculations. Plot exports include all three frequencies in Hz. The simulation band does not change the frequencies in imported S-parameter data.

## v6: free-space conversion methods

The calculation tab provides three implemented methods and a **Free-space method tables** tab matching the supplied note's conversion/material comparisons. A selected-method summary shows short advantage and disadvantage bullets beside the calculations. All methods require calibrated complex sample-face channels, known thickness and a homogeneous isotropic slab in air. NRW now supports normal/oblique TE/TM; NIST and New non-iterative remain normal-only.

| Free-space method | Retrieved quantity | Permeability | Additional setting |
|---|---|---|---|
| NRW | Complex scalar epsilon and mu | Retrieved | Integer propagation branch |
| NIST iterative | Complex scalar epsilon | Assumed mu = 1 | Initial complex epsilon, Newton tolerance and iteration limit |
| New non-iterative | Complex scalar epsilon | Assumed mu = 1 | Integer propagation branch; no initial epsilon guess |

NRW uses the existing direct inverse. NIST solves the Annex 4 determinant equation with damped finite-difference Newton iteration and frequency continuation, then checks the individual S11/S21 channels. New non-iterative implements Annex 5 equation (3.10) at method order 1 and zero cutoff, giving `epsilon=N^2`; its propagation-eigenvalue formulation avoids dividing by a separately retrieved impedance. A converged determinant root or a finite algebraic result is accepted only if reconstruction and passive-model checks also pass.

**SCL is excluded from selectable calculations.** In the supplied note it requires a short-circuited coaxial/waveguide fixture. Metal-backed free-space reflection would need a separately calibrated forward/inverse model. Resonant, coaxial-probe and guided-fixture methods are outside this app's free-space method comparison. Source labels such as Fast/Slow and Good/Medium are qualitative comparisons, not accuracy guarantees or measured software benchmarks. Listing high-temperature materials does not provide temperature compensation.

Choose **S11 + S21** or import all **S11, S21, S12, S22**. The all-four option explicitly projects the data onto the assumed reciprocal symmetric slab, using `(S11+S22)/2` for reflection and `(S21+S12)/2` for transmission. It checks the reconstructed result against all four raw channels and flags mismatches above the selected model-residual tolerance. Raw power-normalized two-port passivity is checked separately using the largest squared singular value, so loose reconstruction tolerance cannot hide active input data. The raw inputs and symmetry discrepancy remain in exported result data. Manual entry supports a pair; all-four mode requires imported channels.

The plots, result table and CSV explicitly distinguish **retrieved mu** from **mu=1 assumed**. Exports retain the selected method, channel mode, residual tolerance, magnetic assumption and any Newton initial/convergence settings. Change the maximum model residual to a threshold justified by your calibrated measurement uncertainty; it is not a license to ignore model mismatch. Use **Export method comparison** to save its PNG, matching CSV and parameter-table PNG. The catalog export includes both tables and all advantage/disadvantage bullets. See [the method guide](../Retrieval_method.html) for the free-space equations. An empty [four-channel CSV template](../SParameter_four_channel_template.csv) is included.

## Export bundles, acquisition planning and scalar retrieval

**Every simulation-plot export saves a matching set:** `name.png` (300 dpi), `name.csv` (all parameters, units and definitions), and `name_parameters.png` (a readable table image). All use the same chosen stem and folder. The metadata captures the current configuration and graph view, including material assumptions and derived results. The table image uses repeated headers and wrapped text to retain the complete parameter list.

**Symbolic tensors connect to the setup.** The linked summary updates as frequency, sample rotation, thickness or geometry changes. In the symbolic workspace choose **Use current setup**, then edit the acquisition plan. Select Reflection arc, Transmission line, or Reflection + transmission; choose incidence sweep or Rx observation arc; specify angle/azimuth endpoints and counts, known sample-orientation count, polarization channels and frequency points. The schematic and counts update together.

The planner reports:

```
N_geometry = N_angle * N_azimuth * N_orientation
N_trace = N_geometry * N_polarization * N_scattering_blocks
N_complex_samples = N_trace * N_frequency
```

One trace means one frequency sweep for one scalar polarization channel and one sample scattering block. Two co-polarized channels are TE<-TE and TM<-TM; four channels also include both cross-polarizations. Reflection + transmission has two blocks. Only compatible paired reflection/transmission plans supply matched sample S11/S21 pairs. Epsilon and mu use the same data; measurements are not doubled for the two tensors. Repeated settings do not create new independent projections, and the counts do not prove tensor identifiability.

An incidence sweep changes illumination relative to the normal and requires receiver tracking of the specular/emerging beam. An Rx observation arc changes receiver direction at fixed illumination: its off-specular scattering samples cannot be entered into a plane-wave Fresnel/NRW inverse. Orientation count represents known, separately recorded rotations; the planner does not invent those rotations.

**Export matrix PNG + tables** saves the current symbolic epsilon, mu and conductivity matrices, selected symmetry/frame and plan counts through MATLAB's matching export bundle. In a standalone browser, PNG/SVG downloads include the matching parameter CSV. All matrix material entries remain letters.

**S-parameters to epsilon / mu** includes a numerical scalar Nicolson-Ross-Weir (NRW) inverse based on the supplied Rohde & Schwarz note, *Measurement of Dielectric Material Properties*, Annex 2 pp.19-21, extended in v10 with polarization-specific oblique propagation and impedance. Import complex calibrated CSV or Touchstone 1 `.s2p`, or enter one complex S11/S21 pair manually. Set known thickness, incidence and TE/TM polarization, the initial integer phase branch and the minimum trustworthy transmission amplitude. Confirm sample-face calibration, then calculate. The GUI plots epsilon and mu and lists validity, selected phase branch and reconstruction residual per frequency.

Use [SParameter_input_template.csv](../SParameter_input_template.csv) as an empty input header. Supported RI columns are `frequency_Hz,S11_real,S11_imag,S21_real,S21_imag`; amplitudes are linear complex wave coefficients, not power fractions. The importer also supports magnitude/phase-degrees or dB/phase-degrees pairs with documented headers in [the method guide](../Retrieval_method.html), and RI/MA/DB Touchstone. Frequencies/channels are sorted together; missing phase, duplicates, malformed rows and unsupported formats are rejected.

**Export results** saves permittivity and permeability graph bundles plus `name_data.csv` with the complex input channels, retrieved values, branch, residual and status. These exports capture the inputs from the completed calculation. Editing a retrieval input clears its previous result and disables export until it is calculated again. A copy-setup button transfers current thickness/incidence; imported measurement data are never changed by that action.

NRW requires a homogeneous isotropic slab in air with one fixed incidence angle/polarization and calibrated/de-embedded sample-face reflection and transmission, including phase. The branch must be justified independently; a small reconstruction residual does not resolve it. Half-wave singularities, transmission below the chosen calibrated floor and nonphysical cases are flagged rather than silently interpolated. Receiver observation arcs, waveguide cutoff and full tensor inversion are outside this numerical inverse. Intrinsic dielectric loss and conductivity remain inseparable without further information. The PDF-based [method guide](../Retrieval_method.html) provides the equations, limitations and source-page mapping.

## Symbolic tensor workspace

The app opens on **Symbolic tensors & S-parameters**, with numerical simulation inputs hidden. Use **Simulation** to return to the existing controls and plots. The symbolic workspace can also open in a larger window or independently as [SymbolicTensors.html](../SymbolicTensors.html), offline in a browser.

- Click entries in the permittivity, permeability and conductivity matrices to see their field-component meaning.
- Select general, reciprocal, diagonal-material-axis or isotropic assumptions, and material or laboratory coordinates. Unknown properties remain letters; structural zeros are assumptions.
- Explore sample yaw/pitch/roll, tensor rotation `T_lab = Q T_material Q^T`, incidence, azimuth and polarization, plus a reflection/transmission schematic and receiver pointing equations.
- Read the polarized S11/S21 blocks, principal-plane anisotropic slab equations, general Maxwell boundary formulation, constrained inverse problem and scalar normal-incidence retrieval special case.
- Use the measurement-plan page to distinguish the information provided by angles, polarizations, rotations and frequency sweeps.

This workspace is a symbolic mathematical specification. Its matrices do not contain measured or fitted tensor values. The separate numerical simulator and all three retrieval methods use isotropic scalar models. A single complex scalar S11/S21 pair does not determine three full tensors. Conductivity and intrinsic dielectric loss are not independently identifiable from arbitrary single-frequency effective permittivity. The guide explains these limitations and the required calibration, phase, thickness and physical assumptions.

**Instrument versus sample channels:** with separate Tx/Rx horns, the bistatic reflection signal is usually instrument S21. The sample-face S11 used in the material equations means calibrated/de-embedded reflection. Raw antenna-feed S11 is not automatically sample reflection.

## New material workflow

The former **Measured data** inputs have been removed. **Material** now provides:

- Perfect conductor (PEC).
- Metal with finite conductivity.
- Illustrative lossy absorber.
- Lossless dielectric.
- Air/vacuum.
- Custom material.

Edit relative permittivity (real part and positive dielectric loss), relative permeability (real part and positive magnetic loss), conductivity in S/m, and normal sample thickness in mm. Any edit changes a non-PEC preset to Custom and updates the simulation automatically. PEC uses the ideal opaque boundary and disables those fields; choose finite metal or Custom to vary properties.

Both **Reflection** and **Transmission** modes show reflected, transmitted and absorbed fractions, separate TE/TM responses, polarization-weighted results, phases, insertion/return loss, and an approximate whole-Gaussian-beam power budget. The geometry mode moves Rx; it does not change the material's constitutive properties. Transmission places Rx behind the sample on the Tx–sample line.

The fourth plot defaults to **Material R / T / A vs frequency**. The previous far-field footprint and beam-radius plots are still selectable. The sample outline remains magenta. Three field regions, sample rotation, lenses, exact numeric inputs and PNG exports are retained.

**Export simulated result (CSV)** records the geometry, frequency settings, material properties, fractions and model notes. These are simulated values at the selected center frequency, not acquired measurements.

## Physics and limits

The solver models a coherent, passive, homogeneous, isotropic air/slab/air layer at the center incidence angle. It includes finite thickness, oblique incidence, TE/TM interface response, internal interference, dielectric/conduction loss and magnetic loss. Stable exponential formulas handle thick conductors and the critical-angle limit.

The time convention is `exp(+j omega t)`:

```
epsilon_r,eff = epsilon_real - j (epsilon_loss + sigma/(omega epsilon0))
mu_r = mu_real - j mu_loss
R = |r|^2; T = |t|^2; A = 1 - R - T
mixed fraction = cos(psi)^2 * TE fraction + sin(psi)^2 * TM fraction
```

Do not count the same loss in both dielectric loss and conductivity. Presets are illustrative constant-property inputs, not a measured dispersive-material database. A lossy absorber is not automatically impedance-matched and can reflect power. For PEC, `R=1, T=0, A=0`. For air or a zero-thickness finite slab, `R=0, T=1, A=0`.

The slab fractions describe power incident on the material, not received horn power. The whole-beam estimate multiplies each fraction by Gaussian interception and reports spillover separately. No finite-sample diffraction, anisotropy, lateral beam displacement or receiver-mode overlap is solved. The geometry uses the original frozen-cross-section Gaussian approximation. Bare-horn field-region boundaries remain reference estimates when lenses are enabled.

Reflection mode retains only an **approximate specular flat-plate RCS scale**, `4*pi*(W*H)^2*cos(alpha)^2*R/lambda^2`, under uniform far-field illumination. It is not a general bistatic RCS calculation, and does not predict RCS toward an off-specular Rx. The readout explicitly flags this and near-field/focused setups. Transmission does not equate transmitted power with forward-scatter RCS.

## Definitions and equations

Use **Variables & equations** below the plots, with its expanded-window button, or open [the standalone guide](../Variables_and_equations.html). It defines every control/readout and includes the Gaussian, rotation, slab, polarization, power-budget and approximate RCS equations, units and references.

## Validation

From the repository root, run the following in MATLAB. Smoke checks write previews to temporary folders. After adding the tests folder to the path, run `captureMeasurementViews` to regenerate the four setup views and `captureScienceViews` to reproduce the illumination, retrieval, and planner figures. To redraw the measurement paths and TRL diagrams, run `python3 docs/generate_measurement_diagrams.py` with Pillow and the fonts named in the script.

```matlab
addpath(fullfile(pwd,'tests'));
results = runtests('tests');
assertSuccess(results);
smokeQuasiOpticalUI
smokeQuasiOpticalV5
smokeQuasiOpticalV6
smokeQuasiOpticalV7
smokeQuasiOpticalV8
smokeQuasiOpticalV9
smokeQuasiOpticalV10
smokeQuasiOpticalDiagnostics
```

The original 27 numerical tests cover geometry, field regions, Gaussian interception, PEC/vacuum limits, zero thickness, quarter/half-wave interference, matched magnetic absorption, equivalent conduction/dielectric losses, thick-metal stability, Brewster/critical angles, polarization mixing and passive energy conservation. The symbolic identity checks use internal numerical substitutions to verify tensor rotation, the anisotropic modal Maxwell equations, the isotropic limit against the existing solver, scalar retrieval reconstruction and specular angle geometry. They do not assign values to the symbolic UI. The UI smoke test exercises the new symbolic workspace and expanded window, plus all presets, all material inputs, both geometries, plot switching, sample rotation, lenses, exports and the guide.

The optional `node tests/testSymbolicTensors.cjs` check runs the actual HTML controller in an isolated DOM stub, covering the 27 matrix entries, symmetry/frame choices, component selection, topic switching and offline dependencies. The [setup gallery](https://tamayovegas.github.io/FREESPACEMEASUREMENTAPP/#setups) shows native MATLAB exports. Only this developer check requires Node.

The v5 tests add export naming/completeness/metadata checks, acquisition-count and eligibility checks, and 14 retrieval/import checks, including independent synthetic forward/inverse round trips, magnetic/lossy/matched slabs, branch continuity, singular/opaque/nonpassive cases, RI/MA/DB CSV/Touchstone and malformed inputs. `smokeQuasiOpticalV5` checks setup synchronization, graph and matrix bundles, the GUI retrieval round trip and invalid-input handling. Synthetic test data are explicitly labeled and never presented as measured data.

The v6 checks cover each new method independently against synthetic forward scattering, low-loss half-wave points, Newton continuation and wrong determinant roots, branch controls, magnetic-model incompatibility, two/four-channel projection and full-channel reconstruction. The v6 UI smoke test exercises all method choices, explicit mu assumptions, Newton-only controls, comparison tables, method metadata and stale-result invalidation.

The v10 suite adds normal/oblique TE/TM dielectric and magnetic round trips at 0, 15, 30, 45 and 60 degrees, with material errors below 1e-8 and complex reconstruction residuals below 1e-10 on the well-conditioned noiseless benchmarks. It covers the supplied 45-degree example and wrong-normal interpretation, Brewster reflection, half-wave/critical singularities, transmission floors, phase gaps, invalid angles, nonpassive and asymmetric inputs, exact-grid comparison and synthetic provenance. Geometry checks cover waist/lens curvature, rotated boundary field, grazing, zero distance and the exact spherical 59.892-degree benchmark. The v10 UI checks exercise comparison, reconstruction, parameter/data exports, snapshot metadata, method restrictions and stale-result invalidation. Synthetic recovery does not establish experimental accuracy.
