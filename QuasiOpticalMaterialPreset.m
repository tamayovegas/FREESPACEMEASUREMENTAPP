function d=QuasiOpticalMaterialPreset(name)
% Illustrative passive materials, not measured material-database entries.
    d=struct('preset',name,'epsReal',4,'epsLoss',0,'muReal',1,'muLoss',0, ...
        'conductivity',0,'thicknessMM',5);
    switch name
        case 'Perfect conductor (PEC)'
            d.epsReal=1;
        case 'Metal (finite conductivity)'
            d.epsReal=1; d.conductivity=5.8e7; d.thicknessMM=1;
        case 'Lossy absorber (example)'
            d.epsReal=4; d.epsLoss=1.2; d.muReal=1.8; d.muLoss=.5;
            d.conductivity=.02; d.thicknessMM=10;
        case 'Lossless dielectric'
        case 'Air / vacuum'
            d.epsReal=1;
        case 'Custom material'
        otherwise
            error('QuasiOptical:Preset','Unknown material preset.');
    end
end
