function smokeQuasiOpticalV7
% Exercise Geometry frequency controls and their plotted and exported values.
    fig=QuasiOpticalBistatic3D;
    cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
    simulation=findobj(fig,'Tag','simulationTab'); simulation.Parent.SelectedTab=simulation;
    simulation.Parent.SelectionChangedFcn(simulation.Parent,[]);
    geometry=findall(fig,'Type','uitab','Title','Geometry'); geometry.Parent.SelectedTab=geometry;
    readout=findall(fig,'Type','uitab','Title','Geometry readout'); readout.Parent.SelectedTab=readout;
    low=findobj(fig,'Tag','input_fLowGHz'); center=findobj(fig,'Tag','input_fGHz'); high=findobj(fig,'Tag','input_fHighGHz');
    slider=findobj(fig,'Tag','slider_fGHz'); status=findobj(fig,'Tag','frequencyBandStatus');
    assert(isequal([low.Value center.Value high.Value],[2 10 25]));
    edit(high,42); edit(low,28);
    assert(center.Value==28 && slider.Value==28 && isequal(slider.Limits,[28 42]));
    edit(center,35); edit(high,34);
    assert(center.Value==34 && slider.Value==34);
    edit(low,38); % Invalid: reject without changing the last valid plots.
    assert(low.Value==28 && high.Value==34 && contains(status.Text,'Low below High'));
    edit(high,42); edit(slider,33.5);
    assert(center.Value==33.5 && isequal(center.Limits,[28 42]));
    state=fig.UserData; p=state.parameters;
    assert(isequal([p.fLowGHz p.fGHz p.fHighGHz],[28 33.5 42]));
    assert(abs(state.model.lambda-299792458/33.5e9)<1e-12);
    regions=findobj(fig,'Tag','regionsAxes'); spectrum=findobj(fig,'Tag','fourthAxes');
    for ax=[regions spectrum]
        assert(isequal(ax.XLim,[28 42]));
        marker=findall(ax,'Tag','centerFrequencyMarker');
        assert(isscalar(marker) && marker.Value==33.5);
    end
    curve=findobj(spectrum,'DisplayName','Reflected R');
    assert(isequal(curve.XData([1 end]),[28 42]));
    html=findobj(fig,'Tag','symbolicTensorHTML'); linked=html.Data.setup;
    assert(isequal([linked.frequencyLowGHz linked.frequencyGHz linked.frequencyHighGHz],[28 33.5 42]));
    drawnow; pause(3); exportapp(fig,fullfile(pwd,'preview-v7-frequency-band.png'));
    fprintf('V7 UI passed: independent bounds/center, clamping and invalid limits, both sweeps, linked setup.\n');
end

function edit(control,value)
    control.Value=value;
    control.ValueChangedFcn(control,[]);
end
