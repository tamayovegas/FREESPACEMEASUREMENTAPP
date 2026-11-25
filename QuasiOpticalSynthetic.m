function [data,opposite,settings]=QuasiOpticalSynthetic(example,setup,polarization)
%QUASIOPTICALSYNTHETIC Generate labelled sample-face slab spectra, not measurements.
% The broadband example uses the current simulation band and material inputs.
    if nargin<2, setup=[]; end
    if nargin<3, polarization='TE'; end
    polarization=validatestring(polarization,{'TE','TM'});
    example=validatestring(example,{'Paper benchmark','Current simulation band + material'});
    if strcmp(example,'Paper benchmark')
        f=6e9; d=.010; angle=45; epsilon=4-.08i; mu=1;
        label='SYNTHETIC paper benchmark: 6 GHz, d=10 mm, alpha=45 deg, epsilon=4-j0.08, mu=1';
    else
        if ~isstruct(setup)||~all(isfield(setup,{'parameters','model','materialInput'}))
            error('QuasiOptical:SyntheticSetup','Current simulation setup is unavailable.');
        end
        material=setup.materialInput;
        if strcmp(material.preset,'Perfect conductor (PEC)')
            error('QuasiOptical:SyntheticPEC','PEC has zero transmission; choose a finite constitutive material for a retrievable synthetic example.');
        end
        f=setup.model.materialSweepGHz(:)*1e9;
        d=material.thicknessMM/1000; angle=setup.model.incidence;
        if d<=0, error('QuasiOptical:SyntheticThickness','A positive normal thickness is required for synthetic retrieval.'); end
        epsilon=material.epsReal-1i*(material.epsLoss+material.conductivity./(2*pi*f*8.8541878128e-12));
        mu=material.muReal-1i*material.muLoss;
        label=sprintf('SYNTHETIC current setup: %s; epsilon=%.6g-j(%.6g+sigma/(omega*epsilon0)), mu=%.6g-j%.6g, sigma=%.6g S/m, d=%.6g mm, alpha=%.6g deg', ...
            material.preset,material.epsReal,material.epsLoss,material.muReal,material.muLoss,material.conductivity,d*1000,angle);
    end
    settings=struct('thicknessM',d,'angleDeg',angle,'polarization',polarization,'epsilon',epsilon,'mu',mu,'description',label);
    data=make(polarization); other='TM'; if strcmp(polarization,'TM'), other='TE'; end
    opposite=make(other); settings.branch=data.synthetic.initialBranch;
    function spectrum=make(pol)
        forward=QuasiOpticalSlabRT(f,d,epsilon,mu,angle,pol);
        if ~all(forward.valid), error('QuasiOptical:SyntheticForward','Synthetic slab response is unavailable for this setup.'); end
        spectrum=struct('fHz',f(:),'s11',forward.r,'s21',forward.t,'s12',forward.t,'s22',forward.r, ...
            'sourcePath',label,'angleDeg',angle,'polarization',pol,'thicknessM',d);
        k0=2*pi*f(1)/299792458; propagation=exp(-1i*k0*forward.q(1)*d);
        phase=atan2(imag(propagation),real(propagation));
        knownBranch=round((k0*d*real(forward.q(1))+phase)/(2*pi));
        spectrum.synthetic=struct('generated',true,'isMeasurement',false,'example',example,'description',label, ...
            'epsilon',epsilon,'mu',mu,'angleDeg',angle,'polarization',pol,'thicknessM',d, ...
            'initialBranch',knownBranch,'model','Homogeneous isotropic air/slab/air; calibrated complex sample-face tangential electric R/T; exp(+j omega t)');
    end
end
