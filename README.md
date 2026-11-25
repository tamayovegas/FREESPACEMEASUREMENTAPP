# Free Space Measurements

Plan microwave measurements of flat samples and retrieve material properties from calibrated reflection and transmission data in MATLAB.

[**Open in MATLAB Online**](https://matlab.mathworks.com/open/github/v1?repo=tamayovegas/QuasiOpticalBistatic3D&file=QuasiOpticalBistatic3D.m) · [**Download ZIP**](https://github.com/tamayovegas/QuasiOpticalBistatic3D/archive/refs/heads/main.zip) · [**Website**](https://tamayovegas.github.io/QuasiOpticalBistatic3D/)

![Free Space Measurements MATLAB app showing straight-through transmission, the sample footprint, and modeled beam radius.](docs/assets/transmission-with-lenses.png)

*Simulated straight-through transmission with ideal focusing lenses at 10 GHz and 30° incidence.*

## What it measures

A vector network analyzer (VNA) records how a microwave signal changes in amplitude and phase when it reflects from or passes through a sample. The app simulates the setup and uses imported, calibrated data to estimate the complex relative permittivity and, with NRW, permeability of a homogeneous, isotropic slab in air.

## Quick start

1. Sign in using **Open in MATLAB Online**, or extract the ZIP and open its project folder in desktop MATLAB.
2. Run `QuasiOpticalBistatic3D`. Open **Simulation** to compare straight-through transmission and bistatic reflection with and without ideal lenses.
3. Open **S-parameters to epsilon / mu**, select **NRW** and **Paper benchmark**, then choose **Load synthetic example (TE + TM)** and **Calculate**. Compare the recovered values and reconstructed channels with the known synthetic inputs.

## How it works

Impedance differences at the slab boundaries cause reflections. Propagation through the slab changes phase and amplitude. Permittivity describes the electric response, permeability describes the magnetic response, and the dielectric loss tangent is the ratio of the electric loss term to the real permittivity.

Import complex sample-face reflection and transmission with known normal thickness, incidence angle, and polarization. NRW supports fixed oblique TE or TM incidence. NIST iterative and the new non-iterative method require normal incidence and assume relative permeability is one. Experimental accuracy and MATLAB Online Basic compatibility remain unverified.

[Measurement physics](https://tamayovegas.github.io/QuasiOpticalBistatic3D/#science) · [Retrieval guide](https://tamayovegas.github.io/QuasiOpticalBistatic3D/Retrieval_method.html) · [CSV template](SParameter_input_template.csv) · [Technical guide](docs/TECHNICAL_GUIDE.md) · [Validation](V10_validation.md)

## References

- **Ghodgaonkar, Varadan, and Varadan (1989).** The original IEEE paper used focused horns, thru-reflect-line (TRL) calibration, and time gating. It extracted dielectric properties from metal-backed reflection. The app uses paired reflection and transmission from a slab in air. [Original paper](https://doi.org/10.1109/19.32194)
- **Baker-Jarvis et al. (2005).** NIST Technical Note 1536, §6.5 describes free-space measurements. The report also covers calibration and measurement uncertainty. [NIST Technical Note 1536](https://nvlpubs.nist.gov/nistpubs/Legacy/TN/nbstechnicalnote1536.pdf)
