function smokeQuasiOpticalV5
% Integration test: linked setup, acquisition counts, export bundle and NRW UI.
    fig=QuasiOpticalBistatic3D; cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
    html=findobj(fig,'Tag','symbolicTensorHTML');
    assert(strcmp(html.Data.action,'sync'));
    assert(abs(html.Data.setup.incidenceDeg-fig.UserData.model.incidence)<1e-12);
    simulation=findobj(fig,'Tag','simulationTab'); simulation.Parent.SelectedTab=simulation;
    simulation.Parent.SelectionChangedFcn(simulation.Parent,[]);
    edit=findobj(fig,'Tag','input_yaw'); edit.Value=15; edit.ValueChangedFcn(edit,[]);
    edit=findobj(fig,'Tag','input_fGHz'); edit.Value=9; edit.ValueChangedFcn(edit,[]);
    assert(html.Data.setup.yawDeg==15 && html.Data.setup.frequencyGHz==9);
    assert(abs(html.Data.setup.incidenceDeg-fig.UserData.model.incidence)<1e-12);
    assert(numel(findobj(fig,'Tag','exportPlotBundle'))==1);
    folder=fullfile(tempdir,'quasioptical_v5_ui'); if ~isfolder(folder), mkdir(folder); end
    state=fig.UserData;
    params=QuasiOpticalParameters(state.parameters,state.model,state.materialInput,state.material,'3D geometry');
    paths=QuasiOpticalExportBundle(findobj(fig,'Tag','geometryAxes'),fullfile(folder,'geometry.png'),params,'3D geometry');
    assert(isfile(paths.image)&&isfile(paths.csv)&&isfile(paths.parametersImage));
    config=struct('geometry','Reflection + transmission','scanKind','Incidence sweep', ...
        'angleStartDeg',0,'angleStopDeg',60,'angleCount',7,'azimuthStartDeg',0,'azimuthStopDeg',90, ...
        'azimuthCount',2,'orientationCount',3,'frequencyCount',11,'polarizationChannels',4);
    plan=QuasiOpticalSweepPlan(config);
    assert(plan.nGeometricConfigurations==42 && plan.nTraceAcquisitions==336 && plan.nComplexSamples==3696);
    matrixFigure=QuasiOpticalTensorFigure('reciprocal','material',plan);
    matrixCleanup=onCleanup(@() close(matrixFigure)); %#ok<NASGU>
    matrixPaths=QuasiOpticalExportBundle(matrixFigure,fullfile(folder,'matrices'),params,'Symbolic matrices');
    assert(isfile(matrixPaths.image));
    retrieval=findobj(fig,'Tag','retrievalTab'); retrieval.Parent.SelectedTab=retrieval;
    retrieval.Parent.SelectionChangedFcn(retrieval.Parent,[]);
    panel=findobj(fig,'Tag','retrievalPanel'); api=panel.UserData;
    use=findobj(fig,'Tag','retrievalUseSetup'); use.ButtonPushedFcn(use,[]);
    assert(abs(findobj(fig,'Tag','retrievalAngleDeg').Value-state.model.incidence)<1e-12);
    p=state.parameters; p.yaw=0; p.pitch=0; p.roll=0; p.theta=0;
    d=QuasiOpticalMaterialPreset('Custom material'); d.epsReal=4; d.epsLoss=.2; d.muReal=1.3; d.muLoss=.05; d.conductivity=0; d.thicknessMM=2;
    f=linspace(5e9,12e9,13).'; r=zeros(size(f)); tr=r;
    for k=1:numel(f)
        p.fGHz=f(k)/1e9; s=QuasiOpticalMaterial(p,QuasiOpticalModel(p),d); r(k)=s.r(1); tr(k)=s.t(1);
    end
    api.loadData(struct('fHz',f,'s11',r,'s21',tr,'sourcePath','Synthetic round-trip TEST data; not a measurement'));
    setField(fig,'retrievalThicknessMM',d.thicknessMM);
    setField(fig,'retrievalAngleDeg',0);
    setField(fig,'retrievalCalibrated',true);
    api.calculate(); result=api.getResult();
    assert(~isempty(result) && all(result.valid));
    assert(max(abs(result.epsilon-(d.epsReal-1i*d.epsLoss)))<1e-9);
    assert(max(abs(result.mu-(d.muReal-1i*d.muLoss)))<1e-9);
    thicknessField=findobj(fig,'Tag','retrievalThicknessMM'); thicknessField.Value=3;
    thicknessField.ValueChangedFcn(thicknessField,[]);
    assert(isempty(api.getResult()) && strcmp(findobj(fig,'Tag','exportRetrieval').Enable,'off'));
    thicknessField.Value=d.thicknessMM; api.calculate(); result=api.getResult();
    assert(~isempty(result) && all(result.valid));
    drawnow; pause(3); exportapp(fig,fullfile(pwd,'preview-v5-retrieval.png'));
    setField(fig,'retrievalAngleDeg',90); api.calculate(); assert(isempty(api.getResult()));
    assert(isempty(findobj(fig,'Tag','retrievalResults').Data));
    setField(fig,'retrievalAngleDeg',0); setField(fig,'retrievalCalibrated',false);
    api.calculate(); assert(isempty(api.getResult()));
    guideButton=findobj(fig,'Tag','openRetrievalGuide'); guideButton.ButtonPushedFcn(guideButton,[]);
    guideFigure=findall(groot,'Type','figure','Tag','QuasiOpticalRetrievalGuide');
    drawnow; pause(3); exportapp(guideFigure,fullfile(pwd,'preview-v5-method.png')); close(guideFigure);
    tensors=findobj(fig,'Tag','symbolicTensorTab'); tensors.Parent.SelectedTab=tensors;
    tensors.Parent.SelectionChangedFcn(tensors.Parent,[]);
    drawnow; pause(3); exportapp(fig,fullfile(pwd,'preview-v5-tensors.png'));
    renderPlannerPreview(html);
    fprintf('V5 UI integration passed: setup sync, live angles, graph bundles, sweep counts, matrix export, scalar NRW UI and invalid-input guards.\n');
end

function setField(fig,tag,value)
    field=findobj(fig,'Tag',tag); field.Value=value;
end

function renderPlannerPreview(linkedHTML)
    source=fileread(linkedHTML.HTMLSource);
    source=strrep(source,'id="tensors" class="section"','id="tensors" class="section" hidden');
    source=strrep(source,'id="plan" class="section" hidden','id="plan" class="section"');
    source=strrep(source,'class="active" data-page="tensors"','data-page="tensors"');
    source=strrep(source,'data-page="plan"','class="active" data-page="plan"');
    temporary=[tempname '.html']; fid=fopen(temporary,'w','n','UTF-8'); fprintf(fid,'%s',source); fclose(fid);
    cleanupFile=onCleanup(@() delete(temporary)); %#ok<NASGU>
    preview=uifigure('Position',[70 40 1380 1050]); cleanupFigure=onCleanup(@() close(preview)); %#ok<NASGU>
    grid=uigridlayout(preview,[1 1]); grid.Padding=[0 0 0 0];
    html=uihtml(grid,'HTMLSource',temporary); html.Data=linkedHTML.Data;
    drawnow; pause(4); exportapp(preview,fullfile(pwd,'preview-v5-planner.png'));
end
