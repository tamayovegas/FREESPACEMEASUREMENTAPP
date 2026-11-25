function plan = QuasiOpticalSweepPlan(config)
%QUASIOPTICALSWEEPPLAN Count scheduled angular/polarization acquisitions.
%   PLAN = QuasiOpticalSweepPlan(CONFIG) contains no tensor retrieval. A
%   configuration is one scheduled angle, azimuth and sample-orientation
%   setting. Each polarization channel and sample scattering block needs one
%   complex trace acquisition; each trace contains frequencyCount samples.
%   Acquisition counts do not imply independent material constraints.
if nargin==0, config=struct; end
if ~isstruct(config) || ~isscalar(config)
    error('QuasiOptical:SweepConfig','The sweep configuration must be a scalar struct.');
end
defaults=struct('geometry','Reflection + transmission','scanKind','Incidence sweep', ...
    'angleStartDeg',0,'angleStopDeg',60,'angleCount',7, ...
    'azimuthStartDeg',0,'azimuthStopDeg',90,'azimuthCount',2, ...
    'orientationCount',1,'frequencyCount',1,'polarizationChannels',2);
names=fieldnames(defaults);
for k=1:numel(names)
    if ~isfield(config,names{k}), config.(names{k})=defaults.(names{k}); end
end
config.geometry=validatestring(config.geometry, ...
    {'Reflection arc','Transmission line','Reflection + transmission'},mfilename,'geometry');
config.scanKind=validatestring(config.scanKind, ...
    {'Incidence sweep','Rx observation arc'},mfilename,'scanKind');
scalarFields={'angleStartDeg','angleStopDeg','azimuthStartDeg','azimuthStopDeg'};
for k=1:numel(scalarFields)
    validateattributes(config.(scalarFields{k}),{'numeric'},{'real','finite','scalar'},mfilename,scalarFields{k});
end
countFields={'angleCount','azimuthCount','orientationCount','frequencyCount'};
for k=1:numel(countFields)
    validateattributes(config.(countFields{k}),{'numeric'}, ...
        {'real','finite','scalar','integer','>=',1,'<=',1e6},mfilename,countFields{k});
end
% One scheduled position uses the start value; its unused stop is normalized.
if config.angleCount==1, config.angleStopDeg=config.angleStartDeg; end
if config.azimuthCount==1, config.azimuthStopDeg=config.azimuthStartDeg; end
validateattributes(config.polarizationChannels,{'numeric'}, ...
    {'real','finite','scalar','integer'},mfilename,'polarizationChannels');
if ~ismember(config.polarizationChannels,[2 4])
    error('QuasiOptical:SweepPolarization','Select two co-polarized or all four polarization channels.');
end
isIncidence=strcmp(config.scanKind,'Incidence sweep');
if isIncidence && any([config.angleStartDeg config.angleStopDeg]<0 | ...
        [config.angleStartDeg config.angleStopDeg]>=90)
    error('QuasiOptical:SweepIncidence','Incidence angles must lie in [0,90) degrees.');
end
if ~isIncidence && any(abs([config.angleStartDeg config.angleStopDeg])>180)
    error('QuasiOptical:SweepObservation','Rx observation offsets must lie in [-180,180] degrees.');
end
plan=struct;
plan.config=config;
plan.anglesDeg=linspace(config.angleStartDeg,config.angleStopDeg,config.angleCount);
plan.azimuthDeg=linspace(config.azimuthStartDeg,config.azimuthStopDeg,config.azimuthCount);
plan.nGeometricConfigurations=config.angleCount*config.azimuthCount*config.orientationCount;
plan.nConfigurations=plan.nGeometricConfigurations;
plan.nPolarizationChannels=config.polarizationChannels;
plan.nBlocks=1+double(strcmp(config.geometry,'Reflection + transmission'));
plan.nChannelsPerConfiguration=plan.nBlocks*plan.nPolarizationChannels;
plan.nTraceAcquisitions=plan.nGeometricConfigurations*plan.nChannelsPerConfiguration;
plan.nComplexSamples=plan.nTraceAcquisitions*config.frequencyCount;
if plan.nComplexSamples>flintmax
    error('QuasiOptical:SweepCount','The requested acquisition count exceeds exact integer precision.');
end
plan.hasReflection=~strcmp(config.geometry,'Transmission line');
plan.hasTransmission=~strcmp(config.geometry,'Reflection arc');
plan.scalarRetrievalEligible=isIncidence && plan.hasReflection && plan.hasTransmission;
plan.nrwEligible=plan.scalarRetrievalEligible && all(cosd(plan.anglesDeg)>=1e-6);
% Eligibility still assumes an isotropic calibrated slab of known thickness.
plan.nSParameterPairs=double(plan.scalarRetrievalEligible)* ...
    plan.nGeometricConfigurations*plan.nPolarizationChannels*config.frequencyCount;
% Only the two co-polarized channels may enter separate scalar TE/TM slab fits.
plan.nCoPolarizedPairs=double(plan.scalarRetrievalEligible)* ...
    plan.nGeometricConfigurations*2*config.frequencyCount;
plan.nCrossPolarizedPairs=plan.nSParameterPairs-plan.nCoPolarizedPairs;
if ~plan.scalarRetrievalEligible, plan.nCrossPolarizedPairs=0; end
plan.parameterCounts=struct('generalPerTensor',9,'reciprocalPerTensor',6, ...
    'principalPerTensor',3,'isotropicPerTensor',1);
plan.messages={['Counts are scheduled acquisitions, not independent tensor equations. ', ...
    'Each complex sample contains magnitude and phase.']; ...
    ['Epsilon and mu are fitted jointly from the same channels; acquisition counts ', ...
    'are not doubled for the two tensors.']; ...
    ['Orientation count assumes separately specified, known rotations; their values ', ...
    'must be recorded before acquiring data.']};
if ~isIncidence
    plan.messages{end+1}=['Rx observation arc changes the receiver direction at fixed ', ...
        'illumination. It is an angular scattering scan, not an incidence sweep; ', ...
        'off-specular samples cannot enter the Fresnel/NRW slab retrieval.'];
elseif ~plan.scalarRetrievalEligible
    plan.messages{end+1}=['This geometry records only one sample scattering block. ', ...
        'Matched calibrated sample S11 and S21 are both required for a ', ...
        'reflection/transmission scalar retrieval.'];
else
    plan.messages{end+1}=['Matched S11/S21 channel pairs are available in principle. ', ...
        'Scalar NRW requires a calibrated isotropic homogeneous slab and known thickness, ', ...
        'with one fixed TE/TM incidence angle per spectrum; grazing and cross-polarized pairs are excluded.'];
end
if config.angleCount>1 && config.angleStartDeg==config.angleStopDeg
    plan.messages{end+1}='Repeated angle settings increase acquisitions, but do not add new angular projections.';
end
if config.azimuthCount>1 && abs(mod(config.azimuthStopDeg-config.azimuthStartDeg,360))<1e-10
    plan.messages{end+1}='The azimuth endpoints are physically equivalent; counts include those scheduled repeats.';
end
end
