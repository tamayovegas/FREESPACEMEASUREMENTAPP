function comparison=QuasiOpticalComparePolarizations(primary,second,specification,channelMode)
%QUASIOPTICALCOMPAREPOLARIZATIONS Strict same-grid TE/TM consistency check.
% Each input represents one fixed incidence, thickness and polarization.
% No interpolation or automatic anisotropy diagnosis is performed.
    if nargin<4, channelMode='pair'; end
    if ~isstruct(specification)||~all(isfield(specification,{'thicknessM','angleDeg','polarization'}))
        error('QuasiOptical:ComparisonSetup','Specify the second spectrum thickness, fixed incidence and polarization.');
    end
    pol=validatestring(specification.polarization,{'TE','TM'});
    if strcmpi(pol,primary.options.polarization)
        error('QuasiOptical:ComparisonPolarization','Comparison requires opposite TE and TM polarizations.');
    end
    if ~isequal(specification.thicknessM,primary.thicknessM)
        error('QuasiOptical:ComparisonThickness','TE/TM comparison requires matching normal thicknesses.');
    end
    if ~isequal(specification.angleDeg,primary.options.angleDeg)
        error('QuasiOptical:ComparisonAngle','TE/TM comparison requires the same fixed incidence angle.');
    end
    if ~isfield(second,'fHz')||~isequal(second.fHz(:),primary.frequencyHz(:))
        error('QuasiOptical:ComparisonGrid','TE/TM comparison requires exactly matching frequency grids; no interpolation is applied.');
    end
    options=primary.options; options.polarization=pol;
    secondary=QuasiOpticalRetrieveData(second,specification.thicknessM,options,channelMode);
    comparison=struct('primary',primary,'secondary',secondary,'frequencyHz',primary.frequencyHz(:));
    if strcmpi(primary.options.polarization,'TE'), comparison.TE=primary; comparison.TM=secondary;
    else, comparison.TE=secondary; comparison.TM=primary; end
    comparison.valid=primary.valid(:)&secondary.valid(:);
    comparison.deltaEpsilon=comparison.TE.epsilon-comparison.TM.epsilon;
    comparison.deltaMu=comparison.TE.mu-comparison.TM.mu;
    comparison.notes={'TE minus TM is a consistency check for the homogeneous isotropic plane-wave slab model.'; ...
        'Disagreement can indicate model or measurement inconsistency. It does not automatically establish anisotropy.'; ...
        'The thickness, fixed incidence angle and frequency grid match exactly; no interpolation was performed.'};
end
