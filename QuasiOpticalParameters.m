function parameters = QuasiOpticalParameters(p,m,d,response,plotName)
%QUASIOPTICALPARAMETERS Snapshot the exact simulated configuration and result.
% p is the SI geometry passed to QuasiOpticalModel (angles remain degrees).
% d is the material input to QuasiOpticalMaterial (thickness input is mm).
% Dimensional export values use SI units; angle controls are converted to rad.
% This metadata is a simulation snapshot, never a measured-material retrieval.
    if nargin<5, plotName='Quasi-optical simulation'; end
    rows=cell(0,5);
    add('Exported graphic','',plotName,'','Selected plot associated with this configuration.');
    add('Result type','','Simulated isotropic air/slab/air response','','No measured scattering parameters or fitted anisotropic material tensor is implied.');
    add('Measurement geometry','',p.mode,'','Reflection has both horns in front; transmission puts Rx behind the sample on the Tx axis.');
    add('Frequency','f_center',p.fGHz*1e9,'Hz','Selected center/reference frequency for the geometry and single-frequency response; control is displayed in GHz.');
    add('Low frequency','f_low',m.sweepGHz(1)*1e9,'Hz','Lower endpoint of both simulation frequency sweeps; control is displayed in GHz.');
    add('High frequency','f_high',m.sweepGHz(end)*1e9,'Hz','Upper endpoint of both simulation frequency sweeps; control is displayed in GHz.');
    add('Angular frequency','omega',2*pi*p.fGHz*1e9,'rad/s','omega = 2*pi*f_center at the selected reference frequency.');
    add('Free-space wavelength','lambda_0',m.lambda,'m','lambda_0 = c_0/f_center at the selected reference frequency.');
    add('Horn aperture','D',m.D,'m','Maximum horn aperture used by the model. In estimate mode this is an equivalent square diagonal, fixed across the current sweep.');
    if m.hornApertureEstimated
        apertureMethod='Estimated from nominal horn gain';
    else
        apertureMethod='Known aperture (manual)';
    end
    add('Horn aperture method','',apertureMethod,'','Manual aperture dimension or a generic equivalent aperture estimated at the selected center frequency.');
    add('Nominal horn gain','G_dBi',m.hornGainDBi,'dBi','Selected nominal gain relative to an isotropic radiator. Used only in aperture estimate mode.');
    add('Assumed horn aperture efficiency','eta_ap',m.hornApertureEfficiency,'1','Aperture efficiency in the gain-to-aperture estimate. Used only in aperture estimate mode.');
    add('Distance to sample','R',p.R,'m','Distance from each horn aperture reference center to the sample center. At R = 0 the centers coincide; contact coupling is not modeled.');
    angle('Horn layout angle','theta',p.theta,'Symmetric horn layout angle in the laboratory xy plane.');
    add('Sample width','W',p.width,'m','Rectangle extent along the rotated material y axis; GUI control is in cm.');
    add('Sample height','H',p.height,'m','Rectangle extent along the rotated material z/fiber axis; GUI control is in cm.');
    add('Sample face area','A_sample',p.width*p.height,'m^2','Geometric rectangular area W*H, before projection.');
    angle('Polarization angle','psi',p.psi,'Incident electric-field angle from local TE toward local TM.');
    add('Lens requested','',p.useLens,'logical','Ideal Tx/Rx focusing lenses checkbox.');
    add('Lens active','',m.useLens,'logical','A requested lens is active only when its position is before the sample.');
    add('Lens position','L',p.lensPosition,'m','Distance from each horn reference point to its ideal thin lens.');
    add('Lens focal length','F',p.focal,'m','Ideal paraxial thin-lens focal length.');
    angle('Sample yaw','gamma',p.yaw,'Rotation about laboratory z; rightmost rotation is applied first.');
    angle('Sample pitch','beta',p.pitch,'Rotation about y within Q = Rz(gamma)*Ry(beta)*Rx(rho).');
    angle('Sample roll','rho',p.roll,'Rotation about original sample normal x within the defined Euler product.');
    add('Sample rotation matrix','Q',m.rotation,'1','Maps vectors in the original material axes into laboratory axes; Q = Rz(yaw)*Ry(pitch)*Rx(roll).');
    add('Sample outward normal','n',m.normal,'1','Unit normal; n = Q*[-1;0;0], expressed in laboratory coordinates.');
    add('Sample width direction','u',m.u,'1','Unit direction of the sample width / material y axis in laboratory coordinates.');
    add('Sample fiber direction','v',m.v,'1','Unit direction of the sample height / material z axis in laboratory coordinates.');
    add('Tx position','r_Tx',m.tx,'m','Laboratory coordinates [x y z], sample centered at the origin.');
    add('Rx position','r_Rx',m.rx,'m','Laboratory coordinates [x y z], sample centered at the origin.');
    add('Incident direction','k_i_hat',m.ki,'1','Unit propagation direction from Tx toward the sample.');
    add('Receiver direction','k_Rx_hat',m.toRx,'1','Unit direction from the sample center toward Rx.');
    add('Incident electric direction','e_hat',m.electric,'1','Unit polarization direction formed from local TE/TM and psi.');
    angle('Actual incidence angle','alpha',m.incidence,'acos(abs(k_i_hat dot n)); changes when the sample rotates.');
    add('Cosine of incidence','cos(alpha)',m.cosIncidence,'1','Absolute projection of incident direction onto the sample normal.');
    add('Illuminated reverse face','',m.backFace,'logical','True when the original reverse face is illuminated.');
    add('Expected receive path','',m.pathLabel,'','Specular reflection direction in reflection mode, straight-through direction in transmission mode.');
    add('Expected path direction','k_path_hat',m.pathDirection,'1','Unit direction of the ideal outgoing path from the sample.');
    angle('Rx path mismatch','delta_Rx',m.rxMismatch,'Angle from the expected outgoing path to the fixed Rx axis.');
    angle('Rx specular mismatch','delta_specular',m.specularMismatch,'Angle between specular reflection and the direction from sample to Rx.');
    add('Reactive near-field end','R_reactive',m.reactiveEnd,'m','Conventional bare-horn estimate 0.62*sqrt(D^3/lambda_0).');
    add('Far-field start','R_FF',m.farStart,'m','Conventional bare-horn Fraunhofer estimate 2*D^2/lambda_0; not a lens-output field boundary.');
    add('Region at sample','',m.region,'','Region classified using the bare horn aperture and distance R.');
    add('Electrically small aperture','D/lambda_0 < 3',m.smallAperture,'logical','True when the usual aperture-region boundaries are only indicative.');
    add('Aperture electrical size','D/lambda_0',m.D/m.lambda,'1','Modeled maximum aperture in free-space wavelengths at the selected center frequency.');
    add('Gaussian launch radius','w_0',m.w0,'m','Assumed 1/e^2 intensity radius w_0 = 0.425*D at the horn reference plane.');
    add('Gaussian radius at sample','w(R)',m.wSample,'m','1/e^2 intensity radius in a plane normal to the incident beam at distance R.');
    add('Gaussian radius at far-field start','w(R_FF)',m.wFar,'m','Active Gaussian beam radius evaluated at the bare-horn far-field reference distance.');
    add('Power intercepted at sample','eta_sample',m.sampleFraction,'1','Projected Gaussian power integrated over the sample rectangle; unavailable near grazing.');
    add('Power intercepted at far-field reference','eta_FF',m.farFraction,'1','Same sample dimensions and orientation compared with the Gaussian profile at R_FF.');
    add('Gaussian waist after lens','w_focus',m.waist,'m','Predicted waist from the ideal lens q parameter; physically used only when the lens is active.');
    add('Waist distance from horn','z_focus',m.focus,'m','Predicted waist position from the ideal lens q parameter; physically used only when the lens is active.');
    add('Grazing footprint limit','',m.grazing,'logical','Gaussian interception suppressed when abs(cos(alpha)) < 0.05.');
    illumination=m.diagnostics;
    add('Illumination diagnostics available','',illumination.available,'logical','Specimen phase and boundary estimates are unavailable near grazing incidence; this status is separate from numerical retrieval validity.');
    add('Gaussian complex beam parameter at specimen','q_beam',illumination.qSample,'m','The active beam q parameter, with 1/q_beam = 1/R_wave - j*lambda_0/(pi*w(R)^2); includes the ideal thin lens when active.');
    add('Gaussian wavefront inverse curvature','1/R_wave',illumination.inverseCurvature,'1/m','Re(1/q_beam); zero at a Gaussian waist. Positive for a diverging and negative for a converging wavefront.');
    add('Gaussian wavefront curvature radius','R_wave',illumination.curvatureRadius,'m','1/Re(1/q_beam); Inf denotes a locally planar wavefront at a waist. This is an assumed Gaussian estimate.');
    add('Active Gaussian waist radius','w_active',illumination.activeWaistRadius,'m','Launch waist without an active lens, or waist calculated from the lens-transformed q parameter.');
    angle('Estimated Gaussian beam divergence half-angle','theta_div',illumination.divergenceDeg,'Paraxial far-field half-angle lambda_0/(pi*w_active), based on the assumed Gaussian beam.');
    angle('Estimated specimen curvature phase variation','Delta_phi_Gaussian',illumination.phaseVariationDeg,'Maximum absolute Gaussian phase departure from the central tangent plane: (k_0/2)*abs(1/R_wave)*max(r_perp^2). Excludes linear oblique-incidence phase.');
    angle('Spherical sag phase companion estimate','Delta_phi_spherical',illumination.sphericalPhaseVariationDeg,'Geometric companion check: (2*pi/lambda_0)*(sqrt(R_wave^2+rho_max^2)-abs(R_wave)). Gaussian diagnostics use the quadratic phase, not this exact spherical sag.');
    add('Largest projected specimen radius','rho_max',illumination.maxTransverseRadius,'m','Maximum transverse distance from the beam axis over the rotated specimen; reached at a rectangle corner.');
    add('Closest projected boundary radius','rho_boundary_min',illumination.minBoundaryTransverseRadius,'m','Minimum transverse distance from the beam axis on the rotated specimen perimeter.');
    add('Strongest estimated Gaussian boundary field','E_boundary/E_axis',illumination.boundaryField,'1','Maximum exp(-r_perp^2/w(R)^2) over the rectangle boundary, normalized to the on-axis electric field in the frozen central cross-section.');
    add('Strongest estimated Gaussian boundary field level','L_boundary',illumination.boundaryFieldDB,'dB','20*log10(E_boundary/E_axis); a field-amplitude ratio, not an intercepted power fraction.');
    angle('Curvature phase engineering guide','Delta_phi_guide',illumination.phaseGuidanceDeg,'Engineering guidance of 22.5 degrees; no accuracy guarantee or standards-compliance claim.');
    add('Boundary field engineering guide','L_boundary_guide',illumination.boundaryGuidanceDB,'dB','Engineering guidance of -20 dB relative to the on-axis field; no accuracy guarantee or standards-compliance claim.');
    add('Curvature phase guide exceeded','',illumination.phaseGuidanceExceeded,'logical','Compare only when illumination diagnostics are available. An illumination warning does not invalidate a numerical plane-wave inversion.');
    add('Boundary field guide exceeded','',illumination.boundaryGuidanceExceeded,'logical','Compare only when illumination diagnostics are available. An illumination warning does not invalidate a numerical plane-wave inversion.');
    add('Idealized Gaussian launch plane','',illumination.idealizedLaunchPlane,'logical','True at zero sample distance. Launch-plane Gaussian estimates exclude horn/sample contact coupling.');
    add('Illumination diagnostic assumptions','',illumination.assumptions,'','Assumptions used for this exact setup snapshot.');
    add('Illumination engineering guidance','',illumination.guidance,'','Guidance is separate from numerical material-retrieval validity.');
    add('Illumination setup snapshot','',jsonencode(illumination.setup),'JSON','Exact configuration used for these diagnostics: lengths in m, angles in degrees, original GHz frequency inputs plus explicit Hz fields, actual aperture, active lens, rotated sample and projected metric.');
    for k=1:numel(illumination.notes)
        add(sprintf('Illumination note %d',k),'',illumination.notes{k},'','Assumption or engineering-guidance note for this setup; not a retrieval validity test.');
    end
    add('Field sweep frequency start','f_min',m.sweepGHz(1)*1e9,'Hz','Lower endpoint used by the field-region frequency plot.');
    add('Field sweep frequency end','f_max',m.sweepGHz(end)*1e9,'Hz','Upper endpoint used by the field-region frequency plot.');
    add('Field sweep sample count','N_f',numel(m.sweepGHz),'count','Number of uniformly spaced frequency samples in the field-region graph, including both endpoints.');
    add('Material spectrum sample count','N_f_material',numel(m.materialSweepGHz),'count','Number of uniformly spaced frequency samples in the material R/T/A spectrum, including both endpoints.');
    add('Material preset','',d.preset,'','Illustrative material category or custom user input.');
    add('Relative permittivity real input','epsilon_r_prime',d.epsReal,'1','Real relative permittivity; used for a homogeneous isotropic slab.');
    add('Dielectric loss input','epsilon_r_loss',d.epsLoss,'1','Positive dielectric-loss contribution under exp(+j*omega*t); do not double-count conductivity loss.');
    add('Relative permeability real input','mu_r_prime',d.muReal,'1','Real relative permeability; used for a homogeneous isotropic slab.');
    add('Magnetic loss input','mu_r_loss',d.muLoss,'1','Positive magnetic-loss contribution under exp(+j*omega*t).');
    add('Electrical conductivity input','sigma',d.conductivity,'S/m','Conductivity adds sigma/(omega*epsilon_0) to the positive relative electric-loss magnitude.');
    add('Normal sample thickness','d',d.thicknessMM/1000,'m','Slab thickness along its normal; thickness control is displayed in mm.');
    add('Effective relative permittivity','epsilon_r_eff',response.epsComplex,'1','epsilon_r_prime - j*(epsilon_r_loss + sigma/(omega*epsilon_0)); PEC ignores constitutive inputs.');
    add('Effective relative permeability','mu_r',response.muComplex,'1','mu_r_prime - j*mu_r_loss; PEC ignores constitutive inputs.');
    add('Material response available','',response.valid,'logical','False at exactly grazing incidence where normal incident power vanishes.');
    add('Complex TE reflection','r_TE',response.r(1),'1','Tangential electric-field reflection amplitude for TE at the slab reference plane.');
    add('Complex TM reflection','r_TM',response.r(2),'1','Tangential electric-field reflection amplitude for TM at the slab reference plane.');
    add('Complex TE transmission','t_TE',response.t(1),'1','Tangential electric-field transmission amplitude through the slab between reference planes.');
    add('Complex TM transmission','t_TM',response.t(2),'1','Tangential electric-field transmission amplitude through the slab between reference planes.');
    for k=1:2
        polarization={'TE','TM'}; label=polarization{k};
        add(['Reflectance ' label],['R_' label],response.Rpol(k),'1','Slab reflected power fraction; identical air media on both sides.');
        add(['Transmittance ' label],['T_' label],response.Tpol(k),'1','Slab transmitted power fraction; identical air media on both sides.');
        add(['Absorptance ' label],['A_' label],response.Apol(k),'1','Slab absorbed power fraction, 1 - R - T.');
        angle(['Reflection phase ' label],['arg(r_' label ')'],response.phaseR(k),'Phase undefined when the reflection amplitude is zero.');
        angle(['Transmission phase ' label],['arg(t_' label ')'],response.phaseT(k),'Phase undefined when the transmission amplitude is zero.');
    end
    add('Polarization-weighted reflectance','R',response.R,'1','cos(psi)^2*R_TE + sin(psi)^2*R_TM, normalized to slab incident power.');
    add('Polarization-weighted transmittance','T',response.T,'1','cos(psi)^2*T_TE + sin(psi)^2*T_TM, normalized to slab incident power.');
    add('Polarization-weighted absorptance','A',response.A,'1','cos(psi)^2*A_TE + sin(psi)^2*A_TM, normalized to slab incident power.');
    add('Incident beam power reflected','eta_sample*R',m.sampleFraction*response.R,'1','Approximate intercepted Gaussian fraction multiplied by slab reflectance; not fixed-Rx received power.');
    add('Incident beam power transmitted','eta_sample*T',m.sampleFraction*response.T,'1','Approximate intercepted Gaussian fraction multiplied by slab transmittance; not fixed-Rx received power.');
    add('Incident beam power absorbed','eta_sample*A',m.sampleFraction*response.A,'1','Approximate intercepted Gaussian fraction multiplied by slab absorptance.');
    add('Specular plate RCS scale','sigma_RCS',response.specularRCS,'m^2','4*pi*(W*H)^2*cos(alpha)^2*R/lambda_0^2; large uniform far-field plate approximation, not off-specular Rx RCS.');
    add('Specular plate RCS level','sigma_RCS_dBsm',response.specularRCSDBsm,'dBsm','10*log10(sigma_RCS / 1 m^2); unavailable in transmission mode.');
    add('Gaussian contour definition','','1/e^2 intensity','','The contour encloses 1 - exp(-2), approximately 86.5 percent of an untruncated circular Gaussian beam.');
    add('Phasor convention','','exp(+j*omega*t)','','Passive propagation is exp(-j*k*d); passive constitutive loss has nonpositive imaginary part.');
    add('Numerical material model','','Isotropic homogeneous air/slab/air','','Includes internal slab reflections and electric/magnetic loss; excludes roughness, diffraction, finite-sample scattering and tensor retrieval.');
    add('Geometric illumination model','','Paraxial Gaussian approximation','','An ideal thin lens is represented with Gaussian q propagation; near-field horn currents and full-wave scattering are not solved.');
    for k=1:numel(response.notes)
        add(sprintf('Calculation note %d',k),'',response.notes{k},'','Assumption or applicability note for this exact configuration.');
    end
    parameters=cell2table(rows,'VariableNames',{'Parameter','Symbol','Value','Unit','Description'});
    for k=1:width(parameters)
        name=parameters.Properties.VariableNames{k}; parameters.(name)=string(parameters.(name));
    end

    function angle(name,symbol,value,description)
        add(name,symbol,value*pi/180,'rad',[description ' GUI/readout angle is in degrees; export converts it to radians.']);
    end

    function add(name,symbol,value,unit,description)
        if islogical(value)
            if value, value='true'; else, value='false'; end
        elseif isnumeric(value)
            if isscalar(value)
                if isnan(value), value='Unavailable (NaN)';
                elseif isreal(value), value=sprintf('%.12g',value);
                else, value=sprintf('%.12g %+.12gj',real(value),imag(value));
                end
            else
                value=mat2str(value,12);
            end
        else
            value=char(string(value));
        end
        rows(end+1,:)={name,symbol,value,unit,description};
    end
end
