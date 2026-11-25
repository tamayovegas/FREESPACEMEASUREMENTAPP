function data=QuasiOpticalReadSParameters(path)
%QUASIOPTICALREADSPARAMETERS Read phase-resolved two-port CSV or Touchstone 1.
% CSV requires an explicitly unit-labelled frequency column, for example:
% frequency_Hz,S11_real,S11_imag,S21_real,S21_imag
% Also accepts complete S11_mag/S11_phase_deg or S11_dB/S11_phase_deg pairs
% (and the corresponding S21 pairs). Optional S12/S22 use the same formats.
% .s2p supports RI, MA or DB and Hz/kHz/MHz/GHz. Touchstone 2 is rejected.
% No calibration, reference-plane shift, channel reassignment or tensor
% retrieval is performed. Rows are sorted by frequency; duplicates rejected.
    if ~(ischar(path)||(isstring(path)&&isscalar(path)))
        error('QuasiOptical:SParameterPath','Input path must be text.');
    end
    path=char(path);
    if ~isfile(path), error('QuasiOptical:SParameterPath','S-parameter file does not exist: %s',path); end
    [~,~,extension]=fileparts(path);
    switch lower(extension)
        case '.csv', data=readCSV(path);
        case '.s2p', data=readTouchstone(path);
        otherwise
            error('QuasiOptical:SParameterFormat','Select a CSV or Touchstone 1 .s2p file.');
    end
    if isempty(data.fHz)||any(~isfinite(data.fHz))||any(data.fHz<=0)
        error('QuasiOptical:SParameterFrequency','Frequencies must be finite, positive and nonempty.');
    end
    channelNames={'s11','s21','s12','s22'};
    [data.fHz,order]=sort(data.fHz(:));
    if any(diff(data.fHz)==0)
        error('QuasiOptical:SParameterFrequency','Duplicate frequencies are not supported. Supply one angle/polarization sweep per file.');
    end
    for k=1:numel(channelNames)
        name=channelNames{k};
        if ~isfield(data,name), continue; end
        channel=data.(name)(:);
        if numel(channel)~=numel(order)||any(~isfinite(channel))
            error('QuasiOptical:SParameterData','%s must have a finite complex value at every frequency.',upper(name));
        end
        data.(name)=channel(order);
    end
    data.frequencyHz=data.fHz;
    data.sourcePath=path;
    data.notes={'Phase-resolved file import only; calibration and sample-plane de-embedding must already be complete.'; ...
        'S11/S21 labels denote the file channels. A two-horn arc reflection transfer is commonly raw VNA S21 and must be calibrated/relabelled as sample reflection before retrieval.'; ...
        'Use a separate file for each angle and polarization. Raw antenna-port measurements do not directly equal slab coefficients.'};
end

function data=readCSV(path)
    try
        raw=readtable(path,'VariableNamingRule','preserve');
    catch problem
        error('QuasiOptical:SParameterCSV','Could not read CSV: %s',problem.message);
    end
    names=regexprep(lower(raw.Properties.VariableNames),'[^a-z0-9]','');
    if numel(unique(names))~=numel(names)
        error('QuasiOptical:SParameterCSV','CSV contains ambiguous or duplicate normalized column names.');
    end
    unitNames={{'frequencyhz','freqhz','fhz'}, {'frequencykhz','freqkhz','fkhz'}, ...
        {'frequencymhz','freqmhz','fmhz'}, {'frequencyghz','freqghz','fghz'}};
    scales=[1 1e3 1e6 1e9]; frequencyIndex=[]; scale=NaN;
    for k=1:4
        index=find(ismember(names,unitNames{k}));
        if ~isempty(index)
            if ~isempty(frequencyIndex)||numel(index)>1
                error('QuasiOptical:SParameterCSV','Use exactly one unit-labelled frequency column.');
            end
            frequencyIndex=index; scale=scales(k);
        end
    end
    if isempty(frequencyIndex)
        error('QuasiOptical:SParameterCSV','CSV needs frequency_Hz (or frequency_kHz/MHz/GHz); frequency units must be explicit.');
    end
    data=struct('fHz',numericColumn(raw,frequencyIndex)*scale,'format','CSV','referenceOhms',NaN);
    data.s11=channel(raw,names,'s11',true);
    data.s21=channel(raw,names,'s21',true);
    for name={'s12','s22'}
        values=channel(raw,names,name{1},false);
        if ~isempty(values), data.(name{1})=values; end
    end
end

function values=channel(raw,names,name,required)
    realIndex=findAliases(names,{[name 'real'],['real' name],[name 're']});
    imagIndex=findAliases(names,{[name 'imag'],[name 'imaginary'],['imag' name],[name 'im']});
    magIndex=findAliases(names,{[name 'mag'],[name 'magnitude'],[name 'abs']});
    dbIndex=findAliases(names,{[name 'db'],[name 'magnitudedb'],[name 'magdb']});
    phaseIndex=findAliases(names,{[name 'phasedeg'],[name 'angledeg'],[name 'angdeg'],[name 'degrees']});
    phaseRadIndex=findAliases(names,{[name 'phaserad'],[name 'anglerad']});
    present=[realIndex imagIndex magIndex dbIndex phaseIndex phaseRadIndex];
    if isempty(present)&&~required, values=[]; return; end
    if ~isempty(realIndex)&&~isempty(imagIndex)&&isempty([magIndex dbIndex phaseIndex phaseRadIndex])
        values=numericColumn(raw,realIndex)+1i*numericColumn(raw,imagIndex); return
    end
    if isempty([realIndex imagIndex])&&isscalar([magIndex dbIndex])&&isscalar([phaseIndex phaseRadIndex])
        phaseColumn=[phaseIndex phaseRadIndex]; phase=numericColumn(raw,phaseColumn);
        if ~isempty(phaseIndex), phase=phase*pi/180; end
        if ~isempty(magIndex)
            magnitude=numericColumn(raw,magIndex);
            if any(magnitude<0), error('QuasiOptical:SParameterCSV','%s magnitude must be nonnegative.',upper(name)); end
        else
            magnitude=10.^(numericColumn(raw,dbIndex)/20);
        end
        values=magnitude.*exp(1i*phase); return
    end
    error('QuasiOptical:SParameterCSV','%s needs one complete real/imaginary or magnitude/phase pair with explicit phase units. Magnitude-only data cannot retrieve complex material properties.',upper(name));
end

function index=findAliases(names,aliases)
    index=find(ismember(names,aliases));
    if numel(index)>1, error('QuasiOptical:SParameterCSV','Multiple columns describe the same S-parameter component.'); end
end

function values=numericColumn(raw,index)
    values=raw{:,index};
    if ~isnumeric(values), values=str2double(string(values)); end
    values=double(values(:));
    if ~isreal(values)||any(~isfinite(values))
        error('QuasiOptical:SParameterCSV','Column %s must contain finite real numbers.',raw.Properties.VariableNames{index});
    end
end

function data=readTouchstone(path)
    lines=regexp(fileread(path),'\r\n|\n|\r','split');
    units='ghz'; representation='ma'; reference=50; parameter='s';
    numbers=[]; pending=[]; seenHeader=false; seenData=false;
    for row=1:numel(lines)
        line=regexprep(lines{row},'!.*$',''); line=strtrim(line);
        if isempty(line), continue; end
        if line(1)=='['
            error('QuasiOptical:SParameterTouchstone','Touchstone 2 keyword blocks are not supported. Export a Touchstone 1 .s2p file.');
        end
        if line(1)=='#'
            if seenHeader||seenData, error('QuasiOptical:SParameterTouchstone','Touchstone must have one option line before its data.'); end
            seenHeader=true; words=regexp(lower(strtrim(line(2:end))),'\s+','split');
            k=1;
            while k<=numel(words)
                word=words{k};
                if any(strcmp(word,{'hz','khz','mhz','ghz'})), units=word;
                elseif any(strcmp(word,{'ri','ma','db'})), representation=word;
                elseif any(strcmp(word,{'s','y','z','h','g'})), parameter=word;
                elseif strcmp(word,'r')&&k<numel(words)
                    k=k+1; reference=str2double(words{k});
                    if ~isfinite(reference)||reference<=0, error('QuasiOptical:SParameterTouchstone','Reference impedance must be finite and positive.'); end
                else
                    error('QuasiOptical:SParameterTouchstone','Unsupported Touchstone option: %s.',word);
                end
                k=k+1;
            end
            if ~strcmp(parameter,'s'), error('QuasiOptical:SParameterTouchstone','Only S-parameters are supported, not %s.',upper(parameter)); end
        else
            seenData=true; words=regexp(line,'\s+','split');
            values=str2double(regexprep(words,'[dD]','E'));
            if any(~isfinite(values)), error('QuasiOptical:SParameterTouchstone','Invalid numeric data at line %d.',row); end
            pending=[pending values]; %#ok<AGROW>
            if numel(pending)>9
                error('QuasiOptical:SParameterTouchstone','Data record exceeds 9 values at line %d. Noise blocks and mixed record formats are unsupported.',row);
            elseif numel(pending)==9
                numbers=[numbers pending]; pending=[]; %#ok<AGROW>
            end
        end
    end
    if isempty(numbers)||~isempty(pending)
        error('QuasiOptical:SParameterTouchstone','Two-port data need frequency and four complex pairs per sample (9 values). Noise blocks are unsupported.');
    end
    rows=reshape(numbers,9,[]).';
    switch units
        case 'hz', scale=1;
        case 'khz', scale=1e3;
        case 'mhz', scale=1e6;
        case 'ghz', scale=1e9;
    end
    data=struct('fHz',rows(:,1)*scale,'format',['Touchstone 1 S ' upper(representation)],'referenceOhms',reference);
    names={'s11','s21','s12','s22'};
    for k=1:4
        a=rows(:,2*k); b=rows(:,2*k+1);
        switch representation
            case 'ri', data.(names{k})=a+1i*b;
            case 'ma'
                if any(a<0), error('QuasiOptical:SParameterTouchstone','MA magnitudes must be nonnegative.'); end
                data.(names{k})=a.*exp(1i*pi*b/180);
            case 'db', data.(names{k})=10.^(a/20).*exp(1i*pi*b/180);
        end
    end
end
