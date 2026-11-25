function smokeQuasiOpticalV8
% Check the zero-distance endpoint through both Geometry controls and modes.
    previewFolder = tempname;
    mkdir(previewFolder);
    fig=QuasiOpticalBistatic3D;
    cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
    simulation=findobj(fig,'Tag','simulationTab'); simulation.Parent.SelectedTab=simulation;
    simulation.Parent.SelectionChangedFcn(simulation.Parent,[]);
    geometry=findall(fig,'Type','uitab','Title','Geometry'); geometry.Parent.SelectedTab=geometry;
    readout=findall(fig,'Type','uitab','Title','Geometry readout'); readout.Parent.SelectedTab=readout;
    distance=findobj(fig,'Tag','input_R'); slider=findobj(fig,'Tag','slider_R');
    assert(isequal(distance.Limits,[0 5]) && isequal(slider.Limits,[0 5]) && distance.Value==1.2);
    geo=findobj(fig,'Tag','geometryAxes'); footprint=findobj(fig,'Tag','sampleAxes');
    lens=findobj(fig,'Tag','lensCheck'); change(lens,true);
    change(distance,0);
    assert(slider.Value==0 && fig.UserData.model.invalidLens && ~fig.UserData.model.useLens);
    assert(isempty(findall(geo,'Type','surface')) && isscalar(findobj(geo,'Tag','zeroDistanceMarker')));
    assert(isscalar(findall(footprint,'Type','image')) && fig.UserData.material.valid);
    stats=findobj(fig,'Tag','statistics');
    assert(any(contains(stats.Value,'aperture centers coincide')));
    mode=findobj(fig,'Tag','measurementMode'); change(mode,'Transmission');
    assert(isequal(fig.UserData.model.toRx,fig.UserData.model.ki) && all(fig.UserData.model.rx==0));
    fourth=findobj(fig,'Tag','fourthPlot'); ax=findobj(fig,'Tag','fourthAxes');
    change(fourth,'Far-field main lobe vs sample'); assert(isscalar(findall(ax,'Type','image')));
    change(fourth,'Beam radius vs distance');
    curve=findobj(ax,'DisplayName','Active Gaussian beam');
    assert(curve.XData(1)==0 && all(isfinite(curve.YData)));
    change(slider,.015); assert(distance.Value==.015 && isempty(findobj(geo,'Tag','zeroDistanceMarker')));
    assert(numel(findall(geo,'Type','surface'))==2);
    change(slider,0); assert(distance.Value==0);
    change(fourth,'Material R / T / A vs frequency'); change(mode,'Reflection'); change(lens,false);
    s=fig.UserData; params=QuasiOpticalParameters(s.parameters,s.model,s.materialInput,s.material,'3D geometry');
    assert(params.Value(params.Parameter=="Distance to sample")=="0");
    drawnow; pause(3); exportapp(fig,fullfile(previewFolder,'preview-v8-zero-distance.png'));
    fprintf('V8 UI passed: zero and small positive distance, both modes, lens handling, plot modes and export metadata.\n');
end

function change(control,value)
    control.Value=value;
    control.ValueChangedFcn(control,[]);
end
