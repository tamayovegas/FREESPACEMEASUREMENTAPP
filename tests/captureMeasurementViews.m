function captureMeasurementViews
% Export comparable views of the Simulation tab for the project gallery.
    root = fileparts(fileparts(mfilename('fullpath')));
    destination = fullfile(root,'docs','assets');
    app = QuasiOpticalBistatic3D;
    cleanup = onCleanup(@() close(app)); %#ok<NASGU>

    tabs = findobj(app,'Tag','workspaceTabs');
    tabs.SelectedTab = findobj(app,'Tag','simulationTab');
    tabs.SelectionChangedFcn(tabs,[]);
    mode = findobj(app,'Tag','measurementMode');
    lenses = findobj(app,'Tag','lensCheck');
    fourthPlot = findobj(app,'Tag','fourthPlot');
    fourthPlot.Value = 'Beam radius vs distance';
    fourthPlot.ValueChangedFcn(fourthPlot,[]);
    readout = findobj(app,'Tag','statistics');
    readoutTab = ancestor(readout,'matlab.ui.container.Tab');
    readoutTab.Parent.SelectedTab = readoutTab;
    geometry = findobj(app,'Tag','geometryAxes');

    modes = {'Transmission','Reflection'};
    for index = 1:numel(modes)
        mode.Value = modes{index};
        mode.ValueChangedFcn(mode,[]);
        for enabled = [false true]
            lenses.Value = enabled;
            lenses.ValueChangedFcn(lenses,[]);
            view(geometry,[-42 23]);
            drawnow;
            pause(1);

            state = app.UserData;
            model = state.model;
            assert(strcmp(model.mode,modes{index}) && model.useLens == enabled);
            assert(strcmp(state.materialInput.preset,'Lossy absorber (example)'));
            assert(state.parameters.fGHz == 10 && state.parameters.R == 1.2);
            assert(abs(model.incidence - 30) < 1e-10 && model.rxMismatch < 1e-5);
            if strcmp(model.mode,'Transmission')
                assert(dot(model.tx,model.rx) < 0 && norm(model.tx + model.rx) < 1e-10);
            else
                assert(dot(model.tx,model.normal) > 0 && dot(model.rx,model.normal) > 0);
            end

            lensLabel = 'without-lenses';
            if enabled
                lensLabel = 'with-lenses';
            end
            filename = sprintf('%s-%s.png',lower(model.mode),lensLabel);
            exportapp(app,fullfile(destination,filename));
            fprintf('%s | %.0f GHz | %.0f deg | w(sample) %.3f cm\n', ...
                filename,state.parameters.fGHz,model.incidence,100*model.wSample);
        end
    end
end
