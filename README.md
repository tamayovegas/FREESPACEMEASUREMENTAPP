# Quasi-Optical 3D

Plan free-space electromagnetic measurements in MATLAB and use calibrated reflection and transmission data to retrieve the material properties of a slab.

[**Open in MATLAB Online**](https://matlab.mathworks.com/open/github/v1?repo=tamayovegas/QuasiOpticalBistatic3D&file=QuasiOpticalBistatic3D.m) · [**Download ZIP**](https://github.com/tamayovegas/QuasiOpticalBistatic3D/archive/refs/heads/main.zip) · [**View setup gallery**](https://tamayovegas.github.io/QuasiOpticalBistatic3D/#setups)

![MATLAB simulation of straight-through transmission with Tx and Rx on opposite sides of a lossy slab. The app shows the beam footprint and radius with and without ideal focusing lenses.](docs/assets/transmission-with-lenses.png)

*Straight-through transmission with ideal Tx/Rx focusing lenses. Simulated lossy slab at 10 GHz and 30° incidence.*

## Quick start

Open in MATLAB Online and sign in, or unzip the source and open the extracted folder in desktop MATLAB. From the project folder, run:

```matlab
QuasiOpticalBistatic3D
```

Select **Simulation** to choose a geometry. In straight-through transmission, the receiving horn sits beyond the sample. In bistatic reflection, separate transmitting and receiving horns sit on the incident side. Toggle **Ideal Tx/Rx focusing lenses** in **Geometry** and compare the beam footprint and radius.

## What you can do

- **Plan the setup.** Compare sample illumination with and without ideal lenses. Inspect beam radius, footprint, and receiver alignment before measuring.
- **Simulate the response.** Set the sample thickness, material properties, frequency band, angle, and polarization. Explore reflected, transmitted, and absorbed power.
- **Retrieve material properties.** Open **S-parameters to epsilon / mu**. Start with the built-in synthetic example or import calibrated complex sample-face data in CSV or Touchstone format. Review the retrieved scalar properties and reconstructed channels.

The numerical retrieval assumes a homogeneous, isotropic slab in air with known thickness and calibrated complex reflection and transmission at the sample faces. The examples are synthetic. Experimental accuracy and MATLAB Online Basic compatibility are still unverified. The desktop app targets MATLAB R2021a or later.

## Documentation

[Retrieval guide](https://tamayovegas.github.io/QuasiOpticalBistatic3D/Retrieval_method.html) · [Variables and equations](https://tamayovegas.github.io/QuasiOpticalBistatic3D/Variables_and_equations.html) · [Symbolic acquisition planner](https://tamayovegas.github.io/QuasiOpticalBistatic3D/SymbolicTensors.html) · [CSV input template](SParameter_input_template.csv) · [Technical guide and version notes](docs/TECHNICAL_GUIDE.md) · [Validation record](V10_validation.md)
