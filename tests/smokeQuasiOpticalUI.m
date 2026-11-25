function smokeQuasiOpticalUI
% Exercise symbolic workspace and material callbacks in both geometries.
    previewFolder = tempname;
    mkdir(previewFolder);
    fig=QuasiOpticalBistatic3D;
    cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
    tensorTab=findobj(fig,'Tag','symbolicTensorTab');
    assert(tensorTab.Parent.SelectedTab==tensorTab);
    assert(strcmp(findobj(fig,'Tag','simulationControls').Visible,'off'));
    html=findobj(fig,'Tag','symbolicTensorHTML');
    assert(isfile(html.HTMLSource) && endsWith(html.HTMLSource,'SymbolicTensors.html'));
    drawnow; pause(3); exportapp(fig,fullfile(previewFolder,'preview-tensors-app.png'));
    tensorButton=findobj(fig,'Tag','openTensors'); tensorButton.ButtonPushedFcn(tensorButton,[]);
    tensorFigure=findall(groot,'Type','figure','Tag','QuasiOpticalTensors');
    assert(isscalar(tensorFigure)); drawnow; pause(3);
    exportapp(tensorFigure,fullfile(previewFolder,'preview-tensors.png')); close(tensorFigure);
    simulationTab=findobj(fig,'Tag','simulationTab');
    simulationTab.Parent.SelectedTab=simulationTab;
    simulationTab.Parent.SelectionChangedFcn(simulationTab.Parent,[]);
    assert(strcmp(findobj(fig,'Tag','simulationControls').Visible,'on'));
    assert(isempty(findall(fig,'Type','uitab','Title','Measured data')));
    assert(isempty(findobj(fig,'Tag','measurementMethod')));
    materialTab=findall(fig,'Type','uitab','Title','Material');
    materialTab.Parent.SelectedTab=materialTab;
    responseTab=findall(fig,'Type','uitab','Title','Material response');
    responseTab.Parent.SelectedTab=responseTab;
    drawnow; pause(3); exportapp(fig,fullfile(previewFolder,'preview-material.png'));
    preset=findobj(fig,'Tag','materialPreset');
    for name={'Perfect conductor (PEC)','Metal (finite conductivity)','Lossless dielectric','Air / vacuum','Lossy absorber (example)'}
        preset.Value=name{1}; preset.ValueChangedFcn(preset,[]);
        response=fig.UserData.material;
        assert(abs(response.R+response.T+response.A-1)<1e-10);
        if strcmp(name{1},'Perfect conductor (PEC)')
            assert(response.R==1 && response.T==0 && response.A==0);
            assert(strcmp(findobj(fig,'Tag','material_conductivity').Enable,'off'));
        end
    end
    old=fig.UserData.material;
    property=findobj(fig,'Tag','material_conductivity'); property.Value=1.5;
    property.ValueChangedFcn(property,[]);
    assert(strcmp(preset.Value,'Custom material'));
    assert(abs(fig.UserData.material.T-old.T)>1e-6);
    for pair={'epsReal',6;'epsLoss',.6;'muReal',2;'muLoss',.3;'thicknessMM',15}.'
        field=findobj(fig,'Tag',['material_' pair{1}]); field.Value=pair{2}; field.ValueChangedFcn(field,[]);
        assert(abs(fig.UserData.material.R+fig.UserData.material.T+fig.UserData.material.A-1)<1e-10);
    end
    mode=findobj(fig,'Tag','measurementMode');
    reflection=[fig.UserData.material.R fig.UserData.material.T fig.UserData.material.A];
    mode.Value='Transmission'; mode.ValueChangedFcn(mode,[]);
    assert(norm(fig.UserData.model.rx+fig.UserData.model.tx)<1e-10);
    assert(max(abs(reflection-[fig.UserData.material.R fig.UserData.material.T fig.UserData.material.A]))<1e-12);
    drawnow; pause(2); exportapp(fig,fullfile(previewFolder,'preview-transmission.png'));
    preset.Value='Perfect conductor (PEC)'; preset.ValueChangedFcn(preset,[]);
    assert(fig.UserData.material.T==0);
    mode.Value='Reflection'; mode.ValueChangedFcn(mode,[]);
    assert(fig.UserData.material.R==1);
    preset.Value='Lossy absorber (example)'; preset.ValueChangedFcn(preset,[]);
    setInput(fig,'yaw',20); setInput(fig,'pitch',15); setInput(fig,'roll',45);
    assert(fig.UserData.model.rxMismatch>1);
    before=fig.UserData.material.R;
    lens=findobj(fig,'Tag','lensCheck'); lens.Value=true; lens.ValueChangedFcn(lens,[]);
    assert(fig.UserData.model.useLens && abs(before-fig.UserData.material.R)<1e-12);
    fourth=findobj(fig,'Tag','fourthPlot'); ax=findobj(fig,'Tag','fourthAxes');
    fourth.Value='Far-field main lobe vs sample'; fourth.ValueChangedFcn(fourth,[]);
    assert(numel(findall(ax,'Type','image'))==1);
    exportgraphics(ax,fullfile(previewFolder,'preview-far-field.png'),'Resolution',140);
    outline=findobj(ax,'DisplayName','Sample outline'); assert(~isequal(outline.Color,[1 1 1]));
    fourth.Value='Beam radius vs distance'; fourth.ValueChangedFcn(fourth,[]);
    assert(isempty(findall(ax,'Type','image')));
    exportgraphics(ax,fullfile(previewFolder,'preview-beam-radius.png'),'Resolution',140);
    fourth.Value='Material R / T / A vs frequency'; fourth.ValueChangedFcn(fourth,[]);
    assert(isempty(findall(ax,'Type','image')));
    exportgraphics(ax,fullfile(previewFolder,'preview-material-spectrum.png'),'Resolution',140);
    setInput(fig,'pitch',0); setInput(fig,'yaw',-60);
    assert(~fig.UserData.material.valid && fig.UserData.model.grazing);
    reset=findobj(fig,'Text','Reset sample rotation'); reset.ButtonPushedFcn(reset,[]);
    assert(fig.UserData.material.valid);
    geo=findobj(fig,'Tag','geometryAxes'); view(geo,[15 40]); setInput(fig,'fGHz',12);
    assert(max(abs(geo.View-[15 40]))<1e-8);
    guideButton=findobj(fig,'Tag','openGuide'); guideButton.ButtonPushedFcn(guideButton,[]);
    guideFigure=findall(groot,'Type','figure','Tag','QuasiOpticalGuide');
    assert(isscalar(guideFigure)); drawnow; pause(2);
    exportapp(guideFigure,fullfile(previewFolder,'preview-guide.png')); close(guideFigure);
    fprintf('UI smoke test passed: symbolic workspace/window, material presets/properties, both geometries, live response, plot modes, rotation and guide.\n');
end

function setInput(fig,name,value)
    edit=findobj(fig,'Tag',['input_' name]);
    edit.Value=value; edit.ValueChangedFcn(edit,[]); drawnow;
end
