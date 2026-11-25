function captureScienceViews
% Reproduce the MATLAB captures embedded in the measurement guide.
    root = fileparts(fileparts(mfilename('fullpath')));
    assets = fullfile(root,'docs','assets');
    app = QuasiOpticalBistatic3D;
    closeApp = onCleanup(@() close(app)); %#ok<NASGU>

    selectWorkspace(app,'simulationTab');
    mode = findobj(app,'Tag','measurementMode');
    mode.Value = 'Reflection';
    mode.ValueChangedFcn(mode,[]);
    lenses = findobj(app,'Tag','lensCheck');
    m = app.UserData.model;
    assert(abs(m.farStart - 0.96066) < 1e-4 && abs(m.wSample - .23025) < 1e-4);
    lenses.Value = true;
    lenses.ValueChangedFcn(lenses,[]);
    m = app.UserData.model;
    assert(m.useLens && abs(m.wSample - .15101) < 1e-4);
    assert(app.UserData.parameters.fGHz == 10 && app.UserData.parameters.R == 1.2);
    assert(abs(m.incidence - 30) < 1e-10 && m.rxMismatch < 1e-5);
    fprintf('10 GHz: far field %.5f m, bare radius %.2f cm, focused radius %.2f cm\n', ...
        m.farStart,100*m.noLensRadius(1.2),100*m.wSample);
    fourth = findobj(app,'Tag','fourthPlot');
    fourth.Value = 'Beam radius vs distance';
    fourth.ValueChangedFcn(fourth,[]);
    geometry = findall(app,'Type','uitab','Title','Geometry');
    geometry.Parent.SelectedTab = geometry;
    diagnostics = findobj(app,'Tag','diagnosticsTab');
    diagnostics.Parent.SelectedTab = diagnostics;
    drawnow;
    pause(2);
    exportapp(app,fullfile(assets,'illumination-diagnostics.png'));

    selectWorkspace(app,'retrievalTab');
    api = findobj(app,'Tag','retrievalPanel').UserData;
    api.loadSynthetic('Paper benchmark');
    api.calculate();
    point = api.getResult();
    assert(all(point.valid) && abs(point.epsilon - (4-.08i)) < 1e-8 && abs(point.mu-1) < 1e-8);
    api.loadSynthetic('Current simulation band + material');
    api.calculate();
    band = api.getResult();
    comparison = api.getComparison();
    assert(numel(band.valid)==180 && all(band.valid) && all(comparison.valid));
    assert(max(abs(comparison.deltaEpsilon)) < 1e-8 && max(abs(comparison.deltaMu)) < 1e-8);
    assert(max(band.residual) < 1e-8);
    fprintf('Synthetic NRW: 6 GHz benchmark recovered, %d broadband points valid, max residual %.3g\n', ...
        numel(band.valid),max(band.residual));
    reconstruction = findobj(app,'Tag','retrievalReconstructionTab');
    reconstruction.Parent.SelectedTab = reconstruction;
    drawnow;
    pause(2);
    exportapp(app,fullfile(assets,'synthetic-nrw-reconstruction.png'));

    % Open the existing embedded planner on its Measurement plan page.
    % The temporary HTML copy changes only which navigation tab starts open.
    selectWorkspace(app,'symbolicTensorTab');
    linked = findobj(app,'Tag','symbolicTensorHTML');
    source = fileread(linked.HTMLSource);
    source = strrep(source,'id="tensors" class="section"','id="tensors" class="section" hidden');
    source = strrep(source,'id="plan" class="section" hidden','id="plan" class="section"');
    source = strrep(source,'class="active" data-page="tensors"','data-page="tensors"');
    source = strrep(source,'data-page="plan"','class="active" data-page="plan"');
    temporary = [tempname '.html'];
    removePreview = onCleanup(@() delete(temporary)); %#ok<NASGU>
    file = fopen(temporary,'w','n','UTF-8');
    assert(file ~= -1,'Cannot create the temporary planner preview.');
    fprintf(file,'%s',source);
    fclose(file);
    setupData = linked.Data;
    linked.HTMLSource = temporary;
    linked.Data = setupData;
    drawnow;
    pause(4);
    exportapp(app,fullfile(assets,'symbolic-tensor-planner.png'));
    linked.HTMLSource = fullfile(root,'SymbolicTensors.html');
end

function selectWorkspace(app,tag)
    tab = findobj(app,'Tag',tag);
    tab.Parent.SelectedTab = tab;
    tab.Parent.SelectionChangedFcn(tab.Parent,[]);
end
