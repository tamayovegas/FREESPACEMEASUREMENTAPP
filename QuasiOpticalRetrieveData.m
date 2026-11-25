function r=QuasiOpticalRetrieveData(data,thicknessM,options,channelMode)
%QUASIOPTICALRETRIEVEDATA Select two channels or a four-channel slab projection.
% Four channels are averaged under reciprocal symmetric air/slab/air
% assumptions. The reconstructed solution is checked against ALL raw
% channels, so asymmetric input is not silently accepted as a slab.
    if nargin<3, options=struct; end
    if nargin<4, channelMode='pair'; end
    channelMode=validatestring(channelMode,{'pair','four'});
    if ~isstruct(data)||~isscalar(data)||~all(isfield(data,{'fHz','s11','s21'}))
        error('QuasiOptical:RetrievalData','Supply frequency, complex S11 and S21 data.');
    end
    validateattributes(data.fHz,{'numeric'},{'vector','real','finite','positive','nonempty'});
    validateattributes(data.s11,{'numeric'},{'vector','finite','numel',numel(data.fHz)});
    validateattributes(data.s21,{'numeric'},{'vector','finite','numel',numel(data.fHz)});
    raw11=data.s11(:); raw21=data.s21(:);
    if strcmp(channelMode,'four')
        if ~all(isfield(data,{'s12','s22'}))
            error('QuasiOptical:FourChannels','The four-channel option requires imported S11, S21, S12 and S22. Manual entry supplies one S11/S21 pair.');
        end
        validateattributes(data.s12,{'numeric'},{'vector','finite','numel',numel(raw11)});
        validateattributes(data.s22,{'numeric'},{'vector','finite','numel',numel(raw11)});
        raw12=data.s12(:); raw22=data.s22(:);
        a=(raw11+raw22)/2; b=(raw21+raw12)/2;
    else
        a=raw11; b=raw21;
    end
    r=QuasiOpticalRetrieve(data.fHz,a,b,thicknessM,options);
    r.channelMode=channelMode; r.rawS11=raw11; r.rawS21=raw21;
    r.muAssumed=~strcmpi(r.options.method,'NRW');
    if strcmp(channelMode,'four')
        r.rawS12=raw12; r.rawS22=raw22;
        r.inputAsymmetry=sqrt(abs(raw11-raw22).^2+abs(raw21-raw12).^2);
        r.rawMaximumPowerGain=nan(numel(raw11),1);
        for k=1:numel(raw11)
            singularValues=svd([raw11(k),raw12(k);raw21(k),raw22(k)]);
            r.rawMaximumPowerGain(k)=max(singularValues)^2;
        end
        r.pairResidual=r.residual;
        r.residual=sqrt(abs(r.reconstructedS11-raw11).^2+abs(r.reconstructedS11-raw22).^2+ ...
            abs(r.reconstructedS21-raw21).^2+abs(r.reconstructedS21-raw12).^2);
        failed=~isfinite(r.residual)|r.residual>r.options.reconstructionTolerance;
        for k=find(failed).'
            r.status{k}=[r.status{k} '; four raw channels exceed slab reconstruction tolerance'];
        end
        r.valid=r.valid&~failed;
        nonpassive=r.rawMaximumPowerGain>1+r.options.passivityTolerance;
        for k=find(nonpassive).'
            r.status{k}=[r.status{k} '; raw two-port channels are non-passive'];
        end
        r.valid=r.valid&~nonpassive;
        r.notes=[{'All four channels are used through the reciprocal symmetric projection: r=(S11+S22)/2, t=(S21+S12)/2.'; ...
            'This projection assumes identical air media and sample-face reference conventions. Every reconstructed result is checked against all four raw channels.'; ...
            'Raw two-port passivity is checked using the largest squared singular value of the power-normalized measured scattering matrix.'};r.notes(:)];
    else
        r.inputAsymmetry=nan(numel(raw11),1);
        r.notes=[{'Two-channel input: calibrated sample S11 and S21; reciprocal symmetric slab assumptions supply the reverse channels.'};r.notes(:)];
    end
end
