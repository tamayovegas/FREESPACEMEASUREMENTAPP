function fig = QuasiOpticalBistatic3D
%QUASIOPTICALBISTATIC3D Interactive horn/sample field-region demonstrator.
% Keep all delivered M-files and HTML guides together.
% MATLAB R2021a+; no additional toolboxes. See README.md for assumptions.
    blue = [0.12 0.40 0.76]; red = [0.82 0.20 0.17];
    dark = [0.14 0.24 0.34]; green = [0.08 0.55 0.38];
    fig = uifigure('Name','Quasi-Optical 3D | Reflection, transmission and material response', ...
        'Position',[40 40 1580 980],'Color','white','Tag','QuasiOpticalBistatic3D');
    root = uigridlayout(fig,[2 2]);
    root.RowHeight = {38,'1x'}; root.ColumnWidth = {350,'1x'};
    root.Padding = [10 8 10 8]; root.RowSpacing = 5;
    header = uilabel(root,'Text','QUASI-OPTICAL 3D | Reflection / transmission | Material response & tensors', ...
        'FontWeight','bold','FontSize',18,'FontColor',dark);
    header.Layout.Column = [1 2];
    panel = uipanel(root,'Title','Simulation configuration','Scrollable','on','Tag','simulationControls');
    panel.Layout.Row = 2; panel.Layout.Column = 1;
    side=uigridlayout(panel,[2 1]); side.RowHeight={30,'1x'}; side.Padding=[0 0 0 0];
    modeChoice=uidropdown(side,'Items',{'Reflection','Transmission'},'Tag','measurementMode', ...
        'Tooltip','Reflection: both horns in front. Transmission: Rx behind sample, collinear with Tx.', ...
        'ValueChangedFcn',@(~,~) modeChanged());
    sideTabs=uitabgroup(side);
    geometryTab=uitab(sideTabs,'Title','Geometry');
    materialTab=uitab(sideTabs,'Title','Material');
    ctrl = uigridlayout(geometryTab,[31 1]);
    ctrl.RowHeight = [{114,100},repmat({21,24},1,10),{26,27,22,28,22,28,30,82,30}];
    ctrl.Padding = [10 6 10 8]; ctrl.RowSpacing = 3; ctrl.Scrollable = 'on';
    descriptions = {'Center frequency (GHz)','Horn maximum aperture D (cm)', ...
        'Tx/Rx distance to sample center R (m)','Horn layout angle (deg)', ...
        'Sample width (cm)','Sample height / fibers (cm)', ...
        'E angle from local TE (deg)','Lens position from horn (m)', ...
        'Lens focal length (m)','Sample yaw about z (deg)', ...
        'Sample pitch about y (deg)','Sample roll about x (deg)'};
    fields = {'fGHz','D','R','theta','width','height','psi', ...
        'lensPosition','focal','yaw','pitch','roll'};
    frequencyBand = [2 25];
    ranges = [frequencyBand;5 30;0 5;0 65;1 110;1 110;0 90;.05 .6;.12 1.2; ...
        -80 80;-80 80;-180 180];
    initial = [10 12 1.2 30 50 50 0 .2 .35 0 0 0];
    slid = cell(12,1); labels = cell(12,1); edits = cell(12,1);
    bandGrid = uigridlayout(ctrl,[5 3]); bandGrid.Layout.Row = 1;
    bandGrid.RowHeight={17,16,24,22,27}; bandGrid.RowSpacing=2;
    bandGrid.Padding=[0 0 0 0]; bandGrid.ColumnWidth={'1x','1x','1x'};
    bandTitle=uilabel(bandGrid,'Text','Frequency band (GHz)','FontWeight','bold','FontSize',11);
    bandTitle.Layout.Row=1; bandTitle.Layout.Column=[1 3];
    bandLabels={'Low','Center','High'};
    for k=1:3
        label=uilabel(bandGrid,'Text',bandLabels{k},'FontSize',10,'FontWeight','bold');
        label.Layout.Row=2; label.Layout.Column=k;
    end
    lowFrequency=uieditfield(bandGrid,'numeric','Value',frequencyBand(1),'Limits',[0 Inf], ...
        'LowerLimitInclusive','off','UpperLimitInclusive','off','ValueDisplayFormat','%.10g', ...
        'Tag','input_fLowGHz','Tooltip','Lower endpoint of both frequency sweeps (GHz).', ...
        'ValueChangedFcn',@(source,~) setFrequencyBound(1,source.Value));
    lowFrequency.Layout.Row=3; lowFrequency.Layout.Column=1;
    edits{1}=uieditfield(bandGrid,'numeric','Value',initial(1),'Limits',frequencyBand, ...
        'ValueDisplayFormat','%.10g','Tag','input_fGHz', ...
        'Tooltip','Operating frequency for point results; must lie within the sweep band.', ...
        'ValueChangedFcn',@(source,~) setValue(1,source.Value));
    edits{1}.Layout.Row=3; edits{1}.Layout.Column=2;
    highFrequency=uieditfield(bandGrid,'numeric','Value',frequencyBand(2),'Limits',[0 Inf], ...
        'LowerLimitInclusive','off','UpperLimitInclusive','off','ValueDisplayFormat','%.10g', ...
        'Tag','input_fHighGHz','Tooltip','Upper endpoint of both frequency sweeps (GHz).', ...
        'ValueChangedFcn',@(source,~) setFrequencyBound(2,source.Value));
    highFrequency.Layout.Row=3; highFrequency.Layout.Column=3;
    slid{1}=uislider(bandGrid,'Limits',frequencyBand,'Value',initial(1),'MajorTicks',[], ...
        'Tag','slider_fGHz','ValueChangedFcn',@(source,~) setValue(1,source.Value));
    slid{1}.Layout.Row=4; slid{1}.Layout.Column=[1 3];
    bandHint='Center drives point results. Low and high set both sweeps.';
    bandStatus=uilabel(bandGrid,'Text',bandHint,'WordWrap','on','FontSize',10, ...
        'FontColor',dark,'Tag','frequencyBandStatus');
    bandStatus.Layout.Row=5; bandStatus.Layout.Column=[1 3];
    hornGrid=uigridlayout(ctrl,[4 2]); hornGrid.Layout.Row=2;
    hornGrid.Padding=[0 0 0 0];
    hornGrid.RowSpacing=2; hornGrid.ColumnWidth={'1x',65};
    hornTitle=uilabel(hornGrid,'Text','Horn aperture model','FontSize',11,'FontWeight','bold');
    hornTitle.Layout.Row=1; hornTitle.Layout.Column=[1 2];
    hornChoice=uidropdown(hornGrid,'Items',{'Known aperture (manual)', ...
        'Unknown - standard horn (15 dBi)','Unknown - standard horn (20 dBi)', ...
        'Unknown - standard horn (25 dBi)'},'ItemsData',[0 15 20 25],'Value',0, ...
        'Tag','hornApertureMode','ValueChangedFcn',@(~,~) configurationChanged());
    hornChoice.Layout.Row=2; hornChoice.Layout.Column=[1 2];
    manualHornLabel=uilabel(hornGrid,'Text',descriptions{2},'FontSize',10,'FontWeight','bold');
    manualHornLabel.Layout.Row=3; manualHornLabel.Layout.Column=1;
    edits{2}=uieditfield(hornGrid,'numeric','Value',initial(2),'Limits',ranges(2,:), ...
        'Tag','input_D','ValueDisplayFormat','%.2f', ...
        'Tooltip','Largest span across the aperture opening; use the diagonal for a rectangular aperture.', ...
        'ValueChangedFcn',@(source,~) setValue(2,source.Value));
    edits{2}.Layout.Row=3; edits{2}.Layout.Column=2;
    slid{2}=uislider(hornGrid,'Limits',ranges(2,:),'Value',initial(2),'MajorTicks',[], ...
        'Tag','slider_D','ValueChangedFcn',@(source,~) setValue(2,source.Value));
    slid{2}.Layout.Row=4; slid{2}.Layout.Column=[1 2];
    hornEstimate=uilabel(hornGrid,'Text','','FontSize',11,'FontWeight','bold', ...
        'FontColor',dark,'Visible','off','Tag','hornApertureEstimate');
    hornEstimate.Layout.Row=3; hornEstimate.Layout.Column=[1 2];
    hornAssumptions=uilabel(hornGrid,'Text','50% efficiency; aperture held fixed during the sweep.', ...
        'FontSize',10,'FontColor',dark,'Visible','off');
    hornAssumptions.Layout.Row=4; hornAssumptions.Layout.Column=[1 2];
    hornGrid.RowHeight={19,26,24,25};
    for k=3:12
        row = uigridlayout(ctrl,[1 2]); row.Layout.Row = 2*k-3;
        row.ColumnWidth = {'1x',65}; row.Padding = [0 0 0 0];
        labels{k} = uilabel(row,'Text',descriptions{k},'FontSize',10,'FontWeight','bold');
        edits{k} = uieditfield(row,'numeric','Limits',ranges(k,:), ...
            'Value',initial(k),'ValueDisplayFormat','%.2f','Tag',['input_' fields{k}], ...
            'ValueChangedFcn',@(source,~) setValue(k,source.Value));
        if strcmp(fields{k},'R')
            edits{k}.ValueDisplayFormat='%.6g';
            edits{k}.Tooltip='Distance from each horn aperture center to the sample center. At 0 m these centers coincide.';
        end
        slid{k} = uislider(ctrl,'Limits',ranges(k,:),'Value',initial(k), ...
            'MajorTicks',[],'Tag',['slider_' fields{k}], ...
            'ValueChangedFcn',@(source,~) setValue(k,source.Value));
        slid{k}.Layout.Row = 2*k-2;
    end
    lensCheck = uicheckbox(ctrl,'Text','Ideal Tx/Rx focusing lenses','Value',false, ...
        'Tag','lensCheck','ValueChangedFcn',@(~,~) configurationChanged());
    lensCheck.Layout.Row = 23;
    resetBtn = uibutton(ctrl,'Text','Reset sample rotation','ButtonPushedFcn',@(~,~) resetRotation());
    resetBtn.Layout.Row = 24;
    plotLabel = uilabel(ctrl,'Text','Fourth plot / fourth export option:','FontWeight','bold');
    plotLabel.Layout.Row = 25;
    fourth = uidropdown(ctrl,'Items',{'Material R / T / A vs frequency','Far-field main lobe vs sample','Beam radius vs distance'}, ...
        'Value','Material R / T / A vs frequency','Tag','fourthPlot', ...
        'ValueChangedFcn',@(~,~) redraw());
    fourth.Layout.Row = 26;
    exportLabel = uilabel(ctrl,'Text','Select a plot to export:'); exportLabel.Layout.Row = 27;
    exportChoice = uidropdown(ctrl,'Items',{'3D geometry','Sample footprint', ...
        'Field regions vs frequency','Fourth plot (current view)'},'Tag','exportChoice');
    exportChoice.Layout.Row = 28;
    exportBtn = uibutton(ctrl,'Text','Export plot + CSV + parameter table PNG', ...
        'Tag','exportPlotBundle', ...
        'ButtonPushedFcn',@(~,~) exportPlot()); exportBtn.Layout.Row = 29;
    note = uitextarea(ctrl,'Editable','off','FontSize',10,'Value', ...
        {'Material tab controls simulated reflection, transmission and absorption.'; ...
        'Contours: 1/e^2 intensity, enclosing 86.5% of Gaussian power.'; ...
        'Region boundaries use the bare horn aperture, including with a lens.'; ...
        'Rotation: Q = Rz(yaw) Ry(pitch) Rx(roll). Horns stay fixed.'});
    note.Layout.Row = 30;
    hint = uilabel(ctrl,'Text','Enter exact values or release sliders to update.', ...
        'FontSize',10); hint.Layout.Row = 31;
    materialGrid=uigridlayout(materialTab,[11 1]);
    materialGrid.RowHeight=[{58,32},repmat({51},1,6),{32,100,'1x'}];
    materialGrid.Padding=[8 8 8 8]; materialGrid.RowSpacing=6; materialGrid.Scrollable='on';
    uilabel(materialGrid,'Text','Choose a material, then vary its properties. Reflection, transmission and absorption update automatically.', ...
        'WordWrap','on','FontSize',11);
    presetChoice=uidropdown(materialGrid,'Items',{'Perfect conductor (PEC)', ...
        'Metal (finite conductivity)','Lossy absorber (example)','Lossless dielectric','Air / vacuum','Custom material'}, ...
        'Value','Lossy absorber (example)','Tag','materialPreset','ValueChangedFcn',@(~,~) presetChanged());
    materialNames={'epsReal','epsLoss','muReal','muLoss','conductivity','thicknessMM'};
    materialLabels={'Relative permittivity epsilon_r (real)', ...
        'Dielectric loss epsilon_r (positive)','Relative permeability mu_r (real)', ...
        'Magnetic loss mu_r (positive)','Electrical conductivity sigma (S/m)','Sample thickness d (mm)'};
    materialLimits=[.001 1e4;0 1e4;.001 1e4;0 1e4;0 1e9;0 1000];
    materialEdits=cell(6,1);
    startingMaterial=QuasiOpticalMaterialPreset(presetChoice.Value);
    for materialIndex=1:6
        materialRow=uigridlayout(materialGrid,[2 1]); materialRow.RowHeight={21,25};
        materialRow.Padding=[0 0 0 0]; materialRow.RowSpacing=2;
        uilabel(materialRow,'Text',materialLabels{materialIndex},'FontSize',11);
        materialEdits{materialIndex}=uieditfield(materialRow,'numeric', ...
            'Value',startingMaterial.(materialNames{materialIndex}),'Limits',materialLimits(materialIndex,:), ...
            'ValueDisplayFormat','%.6g','Tag',['material_' materialNames{materialIndex}], ...
            'Tooltip',materialLabels{materialIndex},'ValueChangedFcn',@(~,~) materialEdited());
    end
    uibutton(materialGrid,'Text','Export simulated result (CSV)','ButtonPushedFcn',@(~,~) exportMaterial());
    uilabel(materialGrid,'Text',['Passive isotropic slab in air. Loss inputs are positive; do not count the same electrical loss in both epsilon loss and conductivity. ' ...
        'PEC is an ideal opaque boundary; choose finite metal or Custom to edit its properties. Presets are illustrative.'], ...
        'WordWrap','on','FontSize',11);
    workspaceTabs=uitabgroup(root,'Tag','workspaceTabs');
    workspaceTabs.Layout.Row=2; workspaceTabs.Layout.Column=2;
    simulationTab=uitab(workspaceTabs,'Title','Simulation','Tag','simulationTab');
    tensorTab=uitab(workspaceTabs,'Title','Symbolic tensors & S-parameters','Tag','symbolicTensorTab');
    retrievalTab=uitab(workspaceTabs,'Title','S-parameters to epsilon / mu','Tag','retrievalTab');
    QuasiOpticalRetrievalPanel(retrievalTab,@() fig.UserData);
    tensorPath=fullfile(fileparts(mfilename('fullpath')),'SymbolicTensors.html');
    tensorLayout=uigridlayout(tensorTab,[2 1]);
    tensorLayout.RowHeight={30,'1x'}; tensorLayout.Padding=[0 0 0 0];
    uibutton(tensorLayout,'Text','Open symbolic tensors and angle equations in a larger window', ...
        'Tag','openTensors','ButtonPushedFcn',@(~,~) openTensors());
    symbolicHTML=uihtml(tensorLayout,'HTMLSource',tensorPath,'Tag','symbolicTensorHTML', ...
        'DataChangedFcn',@tensorDataChanged);
    tensorViews={symbolicHTML}; syncNumber=0;
    display = uigridlayout(simulationTab,[3 2]);
    display.RowHeight = {'1.15x','1x',215}; display.ColumnWidth = {'1x','1x'};
    display.Padding = [0 0 0 0];
    geoAx = uiaxes(display,'Tag','geometryAxes'); geoAx.Layout.Row=1; geoAx.Layout.Column=1;
    spotAx = uiaxes(display,'Tag','sampleAxes'); spotAx.Layout.Row=1; spotAx.Layout.Column=2;
    ffAx = uiaxes(display,'Tag','regionsAxes'); ffAx.Layout.Row=2; ffAx.Layout.Column=1;
    beamAx = uiaxes(display,'Tag','fourthAxes'); beamAx.Layout.Row=2; beamAx.Layout.Column=2;
    for axisHandle=[geoAx spotAx ffAx beamAx]
        axisHandle.FontSize=10; axisHandle.Box='on';
    end
    infoTabs=uitabgroup(display); infoTabs.Layout.Row=3; infoTabs.Layout.Column=[1 2];
    readoutTab=uitab(infoTabs,'Title','Geometry readout');
    diagnosticTab=uitab(infoTabs,'Title','Illumination diagnostics','Tag','diagnosticsTab');
    resultTab=uitab(infoTabs,'Title','Material response');
    helpTab=uitab(infoTabs,'Title','Variables & equations');
    readoutLayout=uigridlayout(readoutTab,[1 1]); readoutLayout.Padding=[2 2 2 2];
    stats = uitextarea(readoutLayout,'Editable','off','FontSize',11, ...
        'FontName','Consolas','Tag','statistics','BackgroundColor',[.965 .976 .988]);
    diagnosticLayout=uigridlayout(diagnosticTab,[2 1]);
    diagnosticLayout.RowHeight={'1x',38}; diagnosticLayout.Padding=[2 2 2 2];
    diagnosticTable=uitable(diagnosticLayout,'Tag','diagnosticsTable', ...
        'ColumnName',{'Diagnostic (Gaussian estimate)','Value','Engineering guidance / meaning'}, ...
        'ColumnWidth',{265,155,'auto'},'RowName',{});
    diagnosticNote=uilabel(diagnosticLayout,'Tag','diagnosticsNote','FontSize',10, ...
        'WordWrap','on','Text','Illumination guidance is separate from numerical retrieval validity.');
    resultLayout=uigridlayout(resultTab,[1 1]); resultLayout.Padding=[2 2 2 2];
    materialText=uitextarea(resultLayout,'Editable','off','FontSize',12, ...
        'FontName','Consolas','Tag','materialResult','Value', ...
        {'Calculating material response...'});
    guidePath=fullfile(fileparts(mfilename('fullpath')),'Variables_and_equations.html');
    helpLayout=uigridlayout(helpTab,[2 1]); helpLayout.RowHeight={28,'1x'}; helpLayout.Padding=[0 0 0 0];
    uibutton(helpLayout,'Text','Open variables and equations in a larger window','Tag','openGuide', ...
        'ButtonPushedFcn',@(~,~) openGuide());
    uihtml(helpLayout,'HTMLSource',guidePath);
    firstDraw = true;
    sideTabs.SelectedTab=materialTab; infoTabs.SelectedTab=resultTab;
    drawnow; % settle grid sizes before equal-aspect images and colorbars
    redraw();
    workspaceTabs.SelectedTab=tensorTab;
    workspaceTabs.SelectionChangedFcn=@(~,~) workspaceChanged();
    workspaceChanged();

    function workspaceChanged()
        if workspaceTabs.SelectedTab==simulationTab
            panel.Visible='on'; root.ColumnWidth={350,'1x'};
            drawnow; redraw();
        else
            panel.Visible='off'; root.ColumnWidth={0,'1x'};
        end
    end

    function openTensors()
        tensorFigure=uifigure('Name','Symbolic material tensors and angle-dependent S-parameters', ...
            'Position',[80 50 1220 900],'Tag','QuasiOpticalTensors');
        tensorGrid=uigridlayout(tensorFigure,[1 1]); tensorGrid.Padding=[0 0 0 0];
        newView=uihtml(tensorGrid,'HTMLSource',tensorPath,'Tag','symbolicTensorHTML', ...
            'DataChangedFcn',@tensorDataChanged);
        tensorViews{end+1}=newView;
        syncTensorSetup();
    end

    function syncTensorSetup()
        if isempty(fig.UserData), return; end
        p=fig.UserData.parameters; m=fig.UserData.model; d=fig.UserData.materialInput;
        tangential=[dot(m.ki,m.u),dot(m.ki,m.v)];
        azimuthDefined=norm(tangential)>1e-10;
        azimuthDeg=0;
        if azimuthDefined, azimuthDeg=atan2d(tangential(2),tangential(1)); end
        linked=struct('frequencyGHz',p.fGHz,'frequencyLowGHz',p.fLowGHz, ...
            'frequencyHighGHz',p.fHighGHz,'thetaDeg',p.theta,'incidenceDeg',m.incidence, ...
            'azimuthDeg',azimuthDeg,'azimuthDefined',azimuthDefined, ...
            'yawDeg',p.yaw,'pitchDeg',p.pitch,'rollDeg',p.roll,'mode',p.mode, ...
            'thicknessMM',d.thicknessMM,'distanceM',p.R,'widthM',p.width,'heightM',p.height, ...
            'rxMismatchDeg',m.rxMismatch,'backFace',m.backFace);
        syncNumber=syncNumber+1;
        tensorViews=tensorViews(cellfun(@isvalid,tensorViews));
        for viewIndex=1:numel(tensorViews)
            tensorViews{viewIndex}.Data=struct('action','sync','setup',linked,'requestId',syncNumber);
        end
    end

    function tensorDataChanged(source,~)
        message=source.Data;
        if ~isstruct(message) || ~isfield(message,'action'), return; end
        if ~strcmp(message.action,'exportMatrices'), return; end
        try
            plan=QuasiOpticalSweepPlan(message.planConfig);
            [file,folder]=uiputfile('*.png','Export symbolic matrices, CSV and parameter table','SymbolicTensors.png');
            if isequal(file,0), return; end
            matrixFigure=QuasiOpticalTensorFigure(message.symmetry,message.frame,plan);
            cleanup=onCleanup(@() close(matrixFigure)); %#ok<NASGU>
            parameters=symbolicParameters(plan,message.symmetry,message.frame);
            paths=QuasiOpticalExportBundle(matrixFigure,fullfile(folder,file),parameters,'Symbolic material tensors and measurement plan');
            uialert(ancestor(source,'figure'),sprintf('Saved matrix image, matching CSV and parameter-table PNG.\n%s',paths.image), ...
                'Tensor export completed','Icon','success');
        catch err
            uialert(ancestor(source,'figure'),err.message,'Tensor export failed','Icon','error');
        end
    end

    function parameters=symbolicParameters(plan,symmetry,frame)
        p=fig.UserData.parameters; m=fig.UserData.model; d=fig.UserData.materialInput;
        names=["Tensor assumption";"Tensor frame";"Plan geometry";"Scan kind";"Angle start";"Angle stop";"Angle positions"; ...
            "Azimuth start";"Azimuth stop";"Azimuth positions";"Sample orientations";"Frequency points";"Polarization channels"; ...
            "Geometric configurations";"Trace acquisitions";"Complex frequency samples";"Matched S11/S21 channel pairs"; ...
            "Linked setup mode";"Linked center frequency";"Linked incidence";"Linked yaw";"Linked pitch";"Linked roll"; ...
            "Sample thickness";"Sample width";"Sample height";"Tx / Rx distance";"Receiver mismatch";"Matrix content"];
        c=plan.config;
        values=[string(symmetry);string(frame);string(c.geometry);string(c.scanKind);string(c.angleStartDeg);string(c.angleStopDeg);string(c.angleCount); ...
            string(c.azimuthStartDeg);string(c.azimuthStopDeg);string(c.azimuthCount);string(c.orientationCount);string(c.frequencyCount);string(c.polarizationChannels); ...
            string(plan.nGeometricConfigurations);string(plan.nTraceAcquisitions);string(plan.nComplexSamples);string(plan.nSParameterPairs); ...
            string(p.mode);string(p.fGHz*1e9);string(m.incidence);string(p.yaw);string(p.pitch);string(p.roll); ...
            string(d.thicknessMM/1000);string(p.width);string(p.height);string(p.R);string(m.rxMismatch);"Unassigned symbols, not fitted tensor values"];
        symbols=["symmetry";"frame";"geometry";"scan";"alpha_start";"alpha_stop";"N_angle";"phi_start";"phi_stop";"N_azimuth";"N_Q";"N_f";"N_pol"; ...
            "N_geom";"N_trace";"N_complex";"N_pair";"mode";"f";"alpha";"gamma";"beta";"rho";"d";"W";"H";"R";"delta";"epsilon,mu,sigma"];
        units=repmat("",numel(names),1); units([5 6 8 9 20 21 22 23 28])="deg"; units(19)="Hz"; units(24:27)="m";
        units([7 10:17])="count";
        descriptions=repmat("Sweep planning metadata; counts are not independent recovered tensor coefficients",numel(names),1);
        descriptions(4)="Rx observation arcs are off-specular scattering measurements, not incidence sweeps for slab NRW";
        descriptions(15)="Each frequency sweep per polarization channel and measured block counts as one trace";
        descriptions(16)="Complex scalar channel samples = trace acquisitions times frequency points";
        descriptions(17)="Matched reflection/transmission channels only when both blocks and compatible incidence geometry are planned";
        descriptions(18:28)="Current app setup at the time of export; does not assign tensor entries";
        descriptions(29)="Full tensor fitting is not inferred from acquisition counts";
        parameters=table(names,symbols,values,units,descriptions,'VariableNames',{'Parameter','Symbol','Value','Unit','Description'});
        tangential=[dot(m.ki,m.u),dot(m.ki,m.v)];
        azimuth="Undefined at normal incidence";
        if norm(tangential)>1e-10, azimuth=string(atan2d(tangential(2),tangential(1))); end
        parameters=[parameters;table("Linked incidence azimuth","phi",azimuth,"deg", ...
            "Tangential incidence direction in the rotated sample y-z axes", ...
            'VariableNames',parameters.Properties.VariableNames)];
        parameters=[parameters;table(["Linked low frequency";"Linked high frequency"], ...
            ["f_low";"f_high"],string(1e9*[p.fLowGHz;p.fHighGHz]),["Hz";"Hz"], ...
            ["Lower endpoint of the simulation band";"Upper endpoint of the simulation band"], ...
            'VariableNames',parameters.Properties.VariableNames)];
    end

    function openGuide()
        guideFigure=uifigure('Name','Quasi-Optical 3D: variables and equations', ...
            'Position',[120 80 1050 800],'Tag','QuasiOpticalGuide');
        guideGrid=uigridlayout(guideFigure,[1 1]); guideGrid.Padding=[0 0 0 0];
        uihtml(guideGrid,'HTMLSource',guidePath);
    end

    function setValue(index,value)
        slid{index}.Value = value; edits{index}.Value = value;
        if index==1, bandStatus.Text=bandHint; bandStatus.FontColor=dark; end
        configurationChanged();
    end

    function setFrequencyBound(index,value)
        proposed=frequencyBand; proposed(index)=value;
        if ~isfinite(2*pi*1e9*value) || value<=0 || proposed(1)>=proposed(2)
            lowFrequency.Value=frequencyBand(1); highFrequency.Value=frequencyBand(2);
            bandStatus.Text='Enter positive limits with Low below High.';
            bandStatus.FontColor=red;
            return
        end
        oldCenter=slid{1}.Value;
        center=max(proposed(1),min(oldCenter,proposed(2)));
        % Expand first so both old and new center values are legal during the update.
        transition=[min(frequencyBand(1),proposed(1)),max(frequencyBand(2),proposed(2))];
        slid{1}.Limits=transition; edits{1}.Limits=transition;
        slid{1}.Value=center; edits{1}.Value=center;
        slid{1}.Limits=proposed; edits{1}.Limits=proposed;
        frequencyBand=proposed;
        bandStatus.Text=bandHint; bandStatus.FontColor=dark;
        if center~=oldCenter
            bandStatus.Text=sprintf('Center moved to %.10g GHz to stay within the band.',center);
        end
        configurationChanged();
    end

    function resetRotation()
        for index=10:12
            slid{index}.Value=0; edits{index}.Value=0;
        end
        configurationChanged();
    end

    function configurationChanged()
        redraw();
    end

    function modeChanged()
        redraw();
    end

    function presetChanged()
        d=QuasiOpticalMaterialPreset(presetChoice.Value);
        for index=1:6
            materialEdits{index}.Value=d.(materialNames{index});
            if strcmp(d.preset,'Perfect conductor (PEC)')
                materialEdits{index}.Enable='off';
            else
                materialEdits{index}.Enable='on';
            end
        end
        redraw(); infoTabs.SelectedTab=resultTab;
    end

    function materialEdited()
        presetChoice.Value='Custom material';
        redraw(); infoTabs.SelectedTab=resultTab;
    end

    function exportMaterial()
        record=fig.UserData.parameters; d=fig.UserData.materialInput; response=fig.UserData.material;
        m=fig.UserData.model;
        record.hornApertureEstimated=m.hornApertureEstimated;
        record.hornGainDBi=m.hornGainDBi;
        record.hornApertureEfficiency=m.hornApertureEfficiency;
        for index=1:6, record.(materialNames{index})=d.(materialNames{index}); end
        record.preset=d.preset; record.resultType='Simulated isotropic air-slab-air response';
        record.reflectance=response.R; record.transmittance=response.T; record.absorptance=response.A;
        record.R_TE=response.Rpol(1); record.R_TM=response.Rpol(2);
        record.T_TE=response.Tpol(1); record.T_TM=response.Tpol(2);
        record.A_TE=response.Apol(1); record.A_TM=response.Apol(2);
        record.phaseR_TE_deg=response.phaseR(1); record.phaseR_TM_deg=response.phaseR(2);
        record.phaseT_TE_deg=response.phaseT(1); record.phaseT_TM_deg=response.phaseT(2);
        record.specularRCS_m2=response.specularRCS; record.specularRCS_dBsm=response.specularRCSDBsm;
        record.notes=strjoin(response.notes,' | ');
        [file,folder]=uiputfile('*.csv','Save simulated material response','MaterialResponse.csv');
        if isequal(file,0), return; end
        try
            writetable(struct2table(record),fullfile(folder,file));
        catch err
            uialert(fig,err.message,'Export failed','Icon','error');
        end
    end

    function updateMaterial(p,m,d,response)
        lines={sprintf('SIMULATED material: %s | f = %.3f GHz | incidence = %.2f deg | thickness = %.6g mm', ...
            d.preset,p.fGHz,m.incidence,d.thicknessMM); ...
            sprintf('Reflected R = %.4f%% | transmitted T = %.4f%% | absorbed A = %.4f%% | sum = %.6f', ...
                100*response.R,100*response.T,100*response.A,response.R+response.T+response.A); ...
            sprintf('TE: R %.4f%%, T %.4f%%, A %.4f%% | TM: R %.4f%%, T %.4f%%, A %.4f%%', ...
                100*response.Rpol(1),100*response.Tpol(1),100*response.Apol(1), ...
                100*response.Rpol(2),100*response.Tpol(2),100*response.Apol(2)); ...
            sprintf('Polarization mixing: cos(psi)^2 TE + sin(psi)^2 TM | psi = %.2f deg',p.psi)};
        if strcmp(d.preset,'Perfect conductor (PEC)')
            lines{end+1}='PEC ideal boundary: epsilon, mu, conductivity and thickness controls are ignored.';
        else
            lines{end+1}=sprintf('epsilon_r,eff = %.6g - j %.6g | mu_r = %.6g - j %.6g | conductivity = %.6g S/m', ...
                real(response.epsComplex),-imag(response.epsComplex),real(response.muComplex),-imag(response.muComplex),d.conductivity);
        end
        lines{end+1}=sprintf('Reflection phase TE/TM = %.2f / %.2f deg | transmission phase TE/TM = %.2f / %.2f deg', ...
            response.phaseR(1),response.phaseR(2),response.phaseT(1),response.phaseT(2));
        lines{end+1}=sprintf('Transmission insertion loss = %.3f dB | reflection return loss = %.3f dB', ...
            -10*log10(response.T),-10*log10(response.R));
        if isfinite(m.sampleFraction)
            lines{end+1}=sprintf('Approx. whole-beam budget: reflected %.3f%%, transmitted THROUGH SAMPLE %.3f%%, absorbed %.3f%%, misses sample %.3f%%', ...
                100*m.sampleFraction*response.R,100*m.sampleFraction*response.T, ...
                100*m.sampleFraction*response.A,100*(1-m.sampleFraction));
        end
        if strcmp(p.mode,'Reflection')
            lines{end+1}=sprintf('Approx. SPECULAR plate RCS scale = %.6g m^2 (%.3f dBsm); current Rx offset %.2f deg', ...
                response.specularRCS,response.specularRCSDBsm,m.rxMismatch);
        else
            lines{end+1}='Transmission mode: R/T/A are slab power fractions; no forward-scatter RCS is inferred.';
        end
        materialText.Value=[lines;response.notes(:)];
    end

    function drawMaterialSpectrum(p,m,d)
        clearAxes(beamAx); colorbar(beamAx,'off'); axis(beamAx,'normal'); hold(beamAx,'on');
        f=m.materialSweepGHz; values=NaN(numel(f),3);
        for index=1:numel(f)
            sp=p; sm=m; sp.fGHz=f(index); sm.lambda=299792458/(f(index)*1e9);
            response=QuasiOpticalMaterial(sp,sm,d);
            values(index,:)=[response.R,response.T,response.A];
        end
        plot(beamAx,f,100*values(:,1),'Color',red,'LineWidth',2,'DisplayName','Reflected R');
        plot(beamAx,f,100*values(:,2),'Color',blue,'LineWidth',2,'DisplayName','Transmitted T');
        plot(beamAx,f,100*values(:,3),'Color',green,'LineWidth',2,'DisplayName','Absorbed A');
        xline(beamAx,p.fGHz,':','Color',dark,'HandleVisibility','off','Tag','centerFrequencyMarker');
        title(beamAx,'Simulated material response | fixed constitutive inputs','FontSize',11);
        xlabel(beamAx,'Frequency (GHz)'); ylabel(beamAx,'Fraction of power incident on slab (%)');
        xlim(beamAx,f([1 end])); ylim(beamAx,[-2 102]); grid(beamAx,'on');
        legend(beamAx,'Location','best','FontSize',8); hold(beamAx,'off');
    end

    function redraw()
        for index=1:12
            p.(fields{index})=slid{index}.Value;
        end
        p.fLowGHz=frequencyBand(1); p.fHighGHz=frequencyBand(2);
        p.D=p.D/100; p.width=p.width/100; p.height=p.height/100;
        if hornChoice.Value~=0, p.hornGainDBi=hornChoice.Value; end
        p.useLens=lensCheck.Value;
        p.mode=modeChoice.Value;
        m=QuasiOpticalModel(p);
        p.D=m.D; % Record the aperture actually used for plotting and export.
        updateHornControls(p,m);
        d.preset=presetChoice.Value;
        for index=1:6, d.(materialNames{index})=materialEdits{index}.Value; end
        response=QuasiOpticalMaterial(p,m,d);
        fig.UserData=struct('parameters',p,'model',m,'materialInput',d,'material',response);
        syncTensorSetup();
        drawGeometry(p,m,response);
        drawFootprint(spotAx,p,m,m.wSample,m.sampleEllipse, ...
            sprintf('At sample: R = %.3f m | intercepted %.1f%%',p.R,100*m.sampleFraction));
        drawRegions(p,m);
        if strcmp(fourth.Value,'Far-field main lobe vs sample')
            drawFootprint(beamAx,p,m,m.wFar,m.farEllipse, ...
                sprintf('At R_{FF} = %.3f m | intercepted %.1f%%',m.farStart,100*m.farFraction));
            if ~m.grazing
                hold(beamAx,'on');
                plot(beamAx,m.sampleEllipse(:,1),m.sampleEllipse(:,2),'--', ...
                    'Color',red,'LineWidth',1.5,'DisplayName','Footprint at actual R');
                legend(beamAx,'Location','best','FontSize',8); hold(beamAx,'off');
            end
        elseif strcmp(fourth.Value,'Beam radius vs distance')
            drawBeam(p,m);
        else
            drawMaterialSpectrum(p,m,d);
        end
        updateStats(p,m);
        updateMaterial(p,m,d,response);
        firstDraw=false;
    end

    function updateHornControls(p,m)
        manual='on'; estimated='off';
        if m.hornApertureEstimated
            manual='off'; estimated='on';
            hornEstimate.Text=sprintf('Estimated D = %.4g cm at %.6g GHz',100*m.D,p.fGHz);
        end
        manualHornLabel.Visible=manual; edits{2}.Visible=manual; slid{2}.Visible=manual;
        hornEstimate.Visible=estimated; hornAssumptions.Visible=estimated;
    end

    function drawGeometry(p,m,response)
        oldView=geoAx.View;
        clearAxes(geoAx); hold(geoAx,'on');
        drawHorn(geoAx,m.tx,m.ki,p.D,[.42 .58 .72]);
        drawHorn(geoAx,m.rx,-m.toRx,p.D,[.71 .48 .46]);
        if p.R>0
            drawEnvelope(geoAx,m.tx,m.ki,p.R,m.radius,blue,.12);
            drawEnvelope(geoAx,m.rx,-m.toRx,p.R,m.radius,red,.07);
            plot3(geoAx,[m.tx(1) 0],[m.tx(2) 0],[0 0],'-','Color',blue,'LineWidth',2);
            plot3(geoAx,[0 m.rx(1)],[0 m.rx(2)],[0 0],'--','Color',red,'LineWidth',1.5);
        end
        patch(geoAx,'Vertices',m.vertices,'Faces',[1 2 3 4], ...
            'FaceColor',[.27 .45 .40],'FaceAlpha',.75,'EdgeColor',dark);
        for offset=linspace(-.44*p.width,.44*p.width,11)
            ends=offset*m.u+[-.46;.46]*p.height*m.v+.002*m.normal;
            plot3(geoAx,ends(:,1),ends(:,2),ends(:,3),'Color',[.82 .90 .77]);
        end
        arrow(geoAx,[0 0 0],.24*m.normal,dark);
        arrow(geoAx,m.tx+.4*p.R*m.ki,.20*m.electric,[.63 .17 .65]);
        if p.R>0
            arrow(geoAx,[0 0 0],.55*p.R*m.pathDirection,green);
            tip=.55*p.R*m.pathDirection;
            if strcmp(p.mode,'Reflection'), fraction=response.R; symbol='R'; else, fraction=response.T; symbol='T'; end
            text(geoAx,tip(1),tip(2),tip(3),sprintf('  %s | %s = %.1f%%',m.pathLabel,symbol,100*fraction),'Color',green,'FontSize',9);
            text(geoAx,m.tx(1),m.tx(2),p.D,'Tx','Color',blue,'FontWeight','bold');
            text(geoAx,m.rx(1),m.rx(2),p.D,'Rx acceptance','Color',red,'FontSize',9);
        else
            scatter3(geoAx,0,0,0,36,dark,'filled','Tag','zeroDistanceMarker');
            text(geoAx,0,0,p.D,'R = 0 m: shared aperture and sample center', ...
                'Color',dark,'FontSize',9,'FontWeight','bold','Tag','zeroDistanceLabel');
        end
        if ~m.grazing
            ring=m.sampleEllipse*[m.u;m.v]+.003*m.normal;
            plot3(geoAx,ring(:,1),ring(:,2),ring(:,3),'Color',blue,'LineWidth',1.8);
        end
        [a,b]=transverse(m.ki); [ar,br]=transverse(-m.toRx);
        if m.useLens
            drawDisk(geoAx,m.tx+p.lensPosition*m.ki,a,b,.65*p.D,[.3 .8 .89],.3);
            drawDisk(geoAx,m.rx-p.lensPosition*m.toRx,ar,br,.65*p.D,[.3 .8 .89],.3);
        end
        bounds=[m.reactiveEnd m.farStart]; names={'Reactive end','Far-field start'};
        colours={[.84 .53 .12],green};
        for j=1:2
            if bounds(j)<=p.R
                center=m.tx+bounds(j)*m.ki;
                drawDisk(geoAx,center,a,b,m.radius(bounds(j)),colours{j},.14);
                text(geoAx,center(1),center(2),center(3)+m.radius(bounds(j)), ...
                    names{j},'Color',colours{j},'FontSize',8);
            end
        end
        title(geoAx,sprintf('%s | incidence %.1f deg | Rx offset %.1f deg', ...
            p.mode,m.incidence,m.rxMismatch),'FontSize',11);
        xlabel(geoAx,'x (m)'); ylabel(geoAx,'y (m)'); zlabel(geoAx,'z (m)');
        axis(geoAx,'tight'); daspect(geoAx,[1 1 1]); grid(geoAx,'on');
        if firstDraw, view(geoAx,[-42 23]); else, view(geoAx,oldView); end
        hold(geoAx,'off');
    end

    function drawFootprint(ax,p,m,w,ring,heading)
        clearAxes(ax); legend(ax,'off'); colorbar(ax,'off'); hold(ax,'on');
        if m.grazing
            text(ax,.5,.5,{'Near edge-on sample (|cos incidence| < 0.05).', ...
                'Footprint estimate suppressed; rotate the sample.'}, ...
                'Units','normalized','HorizontalAlignment','center','FontSize',10);
            xlim(ax,[0 1]); ylim(ax,[0 1]); title(ax,'Footprint unavailable near grazing');
            hold(ax,'off'); return
        end
        % Include the rectangle and the complete 1/e^2 ellipse. In the fourth
        % plot also include the actual-distance contour for a fair comparison.
        extents=abs(ring);
        if ax==beamAx, extents=[extents;abs(m.sampleEllipse)]; end
        uMax=1.12*max([p.width/2;extents(:,1)]);
        vMax=1.12*max([p.height/2;extents(:,2)]);
        [u,v]=meshgrid(linspace(-uMax,uMax,241),linspace(-vMax,vMax,241));
        g=m.metric;
        intensity=exp(-2*(g(1,1)*u.^2+2*g(1,2)*u.*v+g(2,2)*v.^2)/w^2);
        h=imagesc(ax,[-uMax uMax],[-vMax vMax],intensity); h.HandleVisibility='off';
        plot(ax,ring(:,1),ring(:,2),'-','Color',[1 .7 .1],'LineWidth',2, ...
            'DisplayName','1/e^2 contour (86.5% power)');
        plot(ax,p.width/2*[-1 1 1 -1 -1],p.height/2*[-1 -1 1 1 -1], ...
            '-','Color',[.95 .12 .70],'LineWidth',2.5,'DisplayName','Sample outline');
        set(ax,'YDir','normal'); axis(ax,'equal');
        xlim(ax,[-uMax uMax]); ylim(ax,[-vMax vMax]);
        colormap(ax,parula(256)); caxis(ax,[0 1]);
        cb=colorbar(ax); cb.Label.String='Intensity / on-axis intensity';
        xlabel(ax,'Sample-local width u (m)'); ylabel(ax,'Sample-local height / fibers v (m)');
        title(ax,heading,'FontSize',11);
        legend(ax,'Location','best','FontSize',8); hold(ax,'off');
    end

    function drawRegions(p,m)
        clearAxes(ffAx); hold(ffAx,'on');
        f=m.sweepGHz; top=1.12*max([m.farSweep p.R]);
        fill(ffAx,[f fliplr(f)],[zeros(size(f)) fliplr(m.reactiveSweep)], ...
            [.99 .85 .69],'EdgeColor','none','DisplayName','Reactive near field');
        fill(ffAx,[f fliplr(f)],[m.reactiveSweep fliplr(m.farSweep)], ...
            [1 .97 .74],'EdgeColor','none','DisplayName','Radiating near field');
        fill(ffAx,[f fliplr(f)],[m.farSweep top*ones(size(f))], ...
            [.84 .94 .88],'EdgeColor','none','DisplayName','Far field');
        plot(ffAx,f,m.reactiveSweep,'-','Color',[.8 .4 .1],'LineWidth',1.5,'HandleVisibility','off');
        plot(ffAx,f,m.farSweep,'-','Color',green,'LineWidth',1.8,'HandleVisibility','off');
        yline(ffAx,p.R,'--','Color',red,'LineWidth',1.5,'DisplayName','Sample center R');
        xline(ffAx,p.fGHz,':','Color',dark,'HandleVisibility','off','Tag','centerFrequencyMarker');
        scatter(ffAx,[p.fGHz p.fGHz],[m.reactiveEnd m.farStart],35,dark,'filled', ...
            'HandleVisibility','off');
        title(ffAx,sprintf('%.2f GHz: reactive end %.3f m | FF starts %.3f m', ...
            p.fGHz,m.reactiveEnd,m.farStart),'FontSize',11);
        xlabel(ffAx,'Frequency (GHz)'); ylabel(ffAx,'Distance from horn aperture (m)');
        xlim(ffAx,f([1 end])); ylim(ffAx,[0 top]); grid(ffAx,'on');
        legend(ffAx,'Location','northwest','FontSize',8); hold(ffAx,'off');
    end

    function drawBeam(p,m)
        clearAxes(beamAx); colorbar(beamAx,'off'); hold(beamAx,'on');
        axis(beamAx,'normal');
        stop=1.15*max([p.R,m.farStart,p.lensPosition+1.6*p.focal]);
        s=unique([linspace(0,stop,500) p.R m.farStart p.lensPosition]);
        plot(beamAx,s,100*m.radius(s),'Color',blue,'LineWidth',2,'DisplayName','Active Gaussian beam');
        if m.useLens
            other=m.noLensRadius(s); caption='Comparison: no lens';
        else
            other=m.withLensRadius(s); caption='Comparison: ideal lens';
        end
        plot(beamAx,s,100*other,'--','Color',[.5 .5 .5],'DisplayName',caption);
        xline(beamAx,m.reactiveEnd,':','Color',[.8 .4 .1],'DisplayName','Reactive end');
        xline(beamAx,m.farStart,'-','Color',green,'DisplayName','Far-field starts');
        xline(beamAx,p.R,'--','Color',red,'DisplayName','Actual sample R');
        scatter(beamAx,m.farStart,100*m.wFar,40,green,'filled','HandleVisibility','off');
        if m.useLens && m.focus>p.lensPosition && m.focus<stop
            scatter(beamAx,m.focus,100*m.waist,40,blue,'filled','DisplayName','Lens waist');
        end
        title(beamAx,'Beam radius and field-region boundaries','FontSize',11);
        xlabel(beamAx,'Distance from Tx (m)'); ylabel(beamAx,'1/e^2 intensity radius w (cm)');
        xlim(beamAx,[0 stop]); ylim(beamAx,'auto'); grid(beamAx,'on');
        legend(beamAx,'Location','northwest','FontSize',8); hold(beamAx,'off');
    end

    function updateStats(p,m)
        if m.useLens, mode='ideal lens ON'; else, mode='no lens'; end
        apertureText=sprintf('Horn aperture D = %.4g cm (manual)',100*m.D);
        if m.hornApertureEstimated
            apertureText=sprintf('Horn aperture D = %.4g cm (estimated, %.0f dBi, %.0f%% efficiency)', ...
                100*m.D,m.hornGainDBi,100*m.hornApertureEfficiency);
        end
        lines={sprintf('Center %.6g GHz | wavelength %.2f mm | D/lambda = %.2f | %s', ...
            p.fGHz,1000*m.lambda,p.D/m.lambda,mode); ...
            sprintf('Frequency sweep: %.6g to %.6g GHz',p.fLowGHz,p.fHighGHz); ...
            apertureText; ...
            sprintf('Reactive near field: 0 <= r < %.4f m',m.reactiveEnd); ...
            sprintf('Radiating near field (Fresnel): %.4f <= r < %.4f m',m.reactiveEnd,m.farStart); ...
            sprintf('Far field (Fraunhofer): r >= %.4f m | sample center R = %.3f m: %s', ...
                m.farStart,p.R,m.region); ...
            sprintf('%s | incidence alpha = %.2f deg | %s to Rx offset delta = %.2f deg', ...
                p.mode,m.incidence,m.pathLabel,m.rxMismatch); ...
            sprintf('At actual R: w = %.2f cm, intercepted %.2f%% | at R_FF: w = %.2f cm, intercepted %.2f%%', ...
                100*m.wSample,100*m.sampleFraction,100*m.wFar,100*m.farFraction); ...
            'FF comparison: same size/orientation sample, hypothetically centered at R_FF on the Tx axis.'; ...
            'Percentages are fractions of total Gaussian power; color maps are normalized separately.'};
        if p.R==0
            lines{end+1}='R = 0: horn aperture centers coincide with the sample center. No contact coupling is modeled.';
        end
        if m.invalidLens
            lines{end+1}='Lens at/after sample: disabled. Move lens before the sample to enable it.';
        end
        if m.useLens
            lines{end+1}=sprintf('Lens waist at %.3f m from Tx, radius %.2f cm. R_FF remains a bare-horn reference.',m.focus,100*m.waist);
        end
        if m.smallAperture
            lines{end+1}='D < 3 wavelengths: aperture field-region estimates and paraxial beam model are only indicative.';
        end
        if m.grazing
            lines{end+1}='Near grazing incidence: footprint and intercepted-power estimates unavailable.';
        elseif m.incidence>70
            lines{end+1}='Large tilt: frozen beam cross-section footprint is a rough approximation.';
        end
        if m.backFace, lines{end+1}='The reverse face of the sample is illuminated.'; end
        lines{end+1}='Material response: isotropic plane-wave slab model; geometry uses a frozen Gaussian cross-section. See Variables & equations.';
        if strcmp(p.mode,'Transmission')
            lines{end+1}='Rx is behind the sample: Tx -> sample -> Rx. Slab transmission includes interface refraction/interference; lateral beam displacement is not drawn.';
        end
        stats.Value=lines;
        updateDiagnostics(p,m);
    end

    function updateDiagnostics(p,m)
        d=m.diagnostics;
        phase='Unavailable near grazing'; boundary=phase;
        if d.available
            phase=sprintf('%.5g deg',d.phaseVariationDeg);
            boundary=sprintf('%.5g dB',d.boundaryFieldDB);
        end
        phaseAdvice='22.5 deg guidance'; edgeAdvice='-20 dB field guidance';
        if d.phaseGuidanceExceeded, phaseAdvice=[phaseAdvice ' exceeded']; end
        if d.boundaryGuidanceExceeded, edgeAdvice=[edgeAdvice ' exceeded']; end
        diagnosticTable.Data={ ...
            'Bare-horn far-field onset',sprintf('%.5g m',m.farStart),'Aperture-based; does not ensure a flat specimen wavefront'; ...
            'Wavefront curvature radius',sprintf('%.5g m',d.curvatureRadius),'Signed radius; Inf at the modeled waist'; ...
            'Maximum curvature phase vs center tangent',phase,phaseAdvice; ...
            'Strongest sample-boundary electric field',boundary,edgeAdvice; ...
            'Paraxial divergence half-angle',sprintf('%.5g deg',d.divergenceDeg),'lambda / (pi times active waist radius), in radians'; ...
            [m.pathLabel ' receiver offset'],sprintf('%.5g deg',d.receiverMismatchDeg),'Compare receiving direction with the modeled outgoing ray'; ...
            'Active Gaussian waist radius',sprintf('%.5g cm',100*d.activeWaistRadius),'Assumed fundamental Gaussian mode; not a measured antenna pattern'};
        diagnosticNote.Text=['Assumed Gaussian beam; frozen center cross-section on the rotated sample. ' ...
            '22.5 deg and -20 dB are engineering guidance, not accuracy guarantees. Values and setup are included in plot exports.'];
        if p.R==0
            diagnosticNote.Text=[diagnosticNote.Text ' R=0: idealized launch-plane estimates.'];
        elseif ~d.available
            diagnosticNote.Text=[diagnosticNote.Text ' Sample phase and edge estimates unavailable near grazing.'];
        end
    end

    function exportPlot()
        switch exportChoice.Value
            case '3D geometry', ax=geoAx; name='Geometry.png';
            case 'Sample footprint', ax=spotAx; name='SampleFootprint.png';
            case 'Field regions vs frequency', ax=ffAx; name='FieldRegions.png';
            otherwise
                ax=beamAx;
                if strcmp(fourth.Value,'Far-field main lobe vs sample')
                    name='FarFieldMainLobe.png';
                elseif strcmp(fourth.Value,'Beam radius vs distance')
                    name='BeamRadius.png';
                else
                    name='MaterialResponse.png';
                end
        end
        [file,folder]=uiputfile('*.png','Export plot and matching parameter tables',name);
        if isequal(file,0), return; end
        try
            state=fig.UserData;
            plotName=exportChoice.Value;
            if ax==beamAx, plotName=[plotName ': ' fourth.Value]; end
            parameters=QuasiOpticalParameters(state.parameters,state.model,state.materialInput,state.material,plotName);
            parameters=[parameters;table(["Graph view azimuth";"Graph view elevation"], ...
                ["view_az";"view_el"],string(ax.View(:)),["deg";"deg"], ...
                ["MATLAB axes camera azimuth at export";"MATLAB axes camera elevation at export"], ...
                'VariableNames',parameters.Properties.VariableNames)];
            paths=QuasiOpticalExportBundle(ax,fullfile(folder,file),parameters,plotName);
            uialert(fig,sprintf('Saved graph, matching parameter CSV and parameter-table PNG.\n%s',paths.image), ...
                'Export completed','Icon','success');
        catch err
            uialert(fig,err.message,'Export failed','Icon','error');
        end
    end
end

function clearAxes(ax)
% A plain cla leaves HandleVisibility='off' images and reference lines behind.
% Remove hidden plot objects explicitly without resetting axes layout.
    cla(ax);
    hiddenTypes={'image','line','scatter','constantline'};
    for index=1:numel(hiddenTypes)
        delete(findall(ax,'Type',hiddenTypes{index}));
    end
    ax.FontSize=10; ax.Box='on';
end

function [a,b]=transverse(direction)
    a=cross(direction,[0 0 1]); a=a/norm(a);
    b=cross(direction,a); b=b/norm(b);
end

function arrow(ax,origin,direction,colour)
    quiver3(ax,origin(1),origin(2),origin(3),direction(1),direction(2),direction(3), ...
        0,'Color',colour,'LineWidth',2,'MaxHeadSize',.3);
end

function drawEnvelope(ax,origin,direction,distance,radius,colour,alpha)
    [a,b]=transverse(direction);
    [s,t]=ndgrid(linspace(0,distance,65),linspace(0,2*pi,36));
    w=radius(s);
    x=origin(1)+direction(1)*s+w.*(a(1)*cos(t)+b(1)*sin(t));
    y=origin(2)+direction(2)*s+w.*(a(2)*cos(t)+b(2)*sin(t));
    z=origin(3)+direction(3)*s+w.*(a(3)*cos(t)+b(3)*sin(t));
    surf(ax,x,y,z,'FaceColor',colour,'FaceAlpha',alpha,'EdgeColor','none');
end

function drawDisk(ax,center,a,b,radius,colour,alpha)
    t=linspace(0,2*pi,65).'; points=center+radius*(cos(t)*a+sin(t)*b);
    patch(ax,'Vertices',points,'Faces',1:numel(t),'FaceColor',colour, ...
        'FaceAlpha',alpha,'EdgeColor',colour);
end

function drawHorn(ax,center,direction,D,colour)
    [a,b]=transverse(direction);
    % Square aperture icon has diagonal D (the maximum aperture dimension).
    half=D/(2*sqrt(2)); throat=.28*half;
    signs=[-1 -1;1 -1;1 1;-1 1];
    near=center-1.1*D*direction+throat*signs*[a;b];
    far=center+half*signs*[a;b];
    patch(ax,'Vertices',[near;far],'Faces',[1 2 6 5;2 3 7 6;3 4 8 7;4 1 5 8], ...
        'FaceColor',colour,'FaceAlpha',.85,'EdgeColor',[.16 .23 .29]);
    patch(ax,'Vertices',far,'Faces',[1 2 3 4],'FaceColor',[.83 .73 .48], ...
        'FaceAlpha',.3,'EdgeColor',[.16 .23 .29]);
end
