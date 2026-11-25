function smokeQuasiOpticalDiagnostics
% Verify the Simulation diagnostic view, unavailable states and export values.
    fig=QuasiOpticalBistatic3D;
    cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
    tab=findobj(fig,'Tag','simulationTab'); tab.Parent.SelectedTab=tab;
    tab.Parent.SelectionChangedFcn(tab.Parent,[]);
    geometry=findall(fig,'Type','uitab','Title','Geometry'); geometry.Parent.SelectedTab=geometry;
    diagnosticTab=findobj(fig,'Tag','diagnosticsTab'); diagnosticTab.Parent.SelectedTab=diagnosticTab;
    values=findobj(fig,'Tag','diagnosticsTable'); note=findobj(fig,'Tag','diagnosticsNote');
    assert(size(values.Data,1)==7 && contains(note.Text,'engineering guidance'));
    change(fig,'input_R',0);
    assert(fig.UserData.model.diagnostics.phaseVariationDeg==0);
    assert(contains(note.Text,'idealized launch-plane'));
    change(fig,'input_R',1); change(fig,'input_theta',65); change(fig,'input_yaw',-25);
    assert(~fig.UserData.model.diagnostics.available);
    assert(contains(values.Data{3,2},'Unavailable') && contains(values.Data{4,2},'Unavailable'));
    change(fig,'input_theta',45); change(fig,'input_yaw',0);
    assert(fig.UserData.model.diagnostics.available);
    state=fig.UserData;
    params=QuasiOpticalParameters(state.parameters,state.model,state.materialInput,state.material,'Diagnostic smoke snapshot');
    assert(any(params.Parameter=="Illumination setup snapshot"));
    assert(any(params.Parameter=="Estimated specimen curvature phase variation"));
    snapshot=jsondecode(params.Value(params.Parameter=="Illumination setup snapshot"));
    assert(snapshot.actualIncidenceDeg==state.model.incidence && snapshot.D==state.model.D);
    drawnow; pause(3); exportapp(fig,fullfile(pwd,'preview-v10-diagnostics.png'));
    fprintf('V10 diagnostic UI passed: values, guidance, launch plane, grazing unavailable, and exact setup metadata.\n');
end

function change(fig,tag,value)
    control=findobj(fig,'Tag',tag); control.Value=value; control.ValueChangedFcn(control,[]);
end
