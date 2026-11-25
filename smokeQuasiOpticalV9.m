function smokeQuasiOpticalV9
% Verify the 1 cm limits and horn selector through their Geometry callbacks.
    fig=QuasiOpticalBistatic3D;
    cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
    simulation=findobj(fig,'Tag','simulationTab'); simulation.Parent.SelectedTab=simulation;
    simulation.Parent.SelectionChangedFcn(simulation.Parent,[]);
    geometry=findall(fig,'Type','uitab','Title','Geometry'); geometry.Parent.SelectedTab=geometry;
    readout=findall(fig,'Type','uitab','Title','Geometry readout'); readout.Parent.SelectedTab=readout;
    width=findobj(fig,'Tag','input_width'); height=findobj(fig,'Tag','slider_height');
    assert(isequal(width.Limits,[1 110]) && isequal(height.Limits,[1 110]));
    change(width,1); change(height,1);
    p=fig.UserData.parameters; assert(isequal([p.width p.height],[.01 .01]));
    horn=findobj(fig,'Tag','hornApertureMode'); aperture=findobj(fig,'Tag','input_D');
    estimate=findobj(fig,'Tag','hornApertureEstimate'); center=findobj(fig,'Tag','input_fGHz');
    assert(horn.Value==0 && strcmp(aperture.Visible,'on'));
    change(aperture,16.5); assert(abs(fig.UserData.model.D-.165)<1e-12);
    change(horn,15); a=fig.UserData.model;
    assert(a.hornApertureEstimated && a.hornGainDBi==15);
    assert(strcmp(aperture.Visible,'off') && strcmp(estimate.Visible,'on'));
    change(center,20); b=fig.UserData.model;
    assert(abs(b.D-a.D/2)<1e-12 && contains(estimate.Text,'20 GHz'));
    assert(100*b.D<aperture.Limits(1)); % Estimate is independent of the manual field limits.
    change(horn,25); assert(abs(fig.UserData.model.D/b.D-sqrt(10))<1e-10);
    change(horn,0);
    assert(~fig.UserData.model.hornApertureEstimated && abs(fig.UserData.parameters.D-.165)<1e-12);
    assert(aperture.Value==16.5 && strcmp(aperture.Visible,'on') && strcmp(estimate.Visible,'off'));
    change(horn,20); s=fig.UserData;
    assert(s.model.hornGainDBi==20 && s.parameters.D==s.model.D && s.material.valid);
    footprint=findobj(fig,'Tag','sampleAxes'); assert(isscalar(findall(footprint,'Type','image')));
    params=QuasiOpticalParameters(s.parameters,s.model,s.materialInput,s.material,'3D geometry');
    assert(abs(str2double(params.Value(params.Parameter=="Horn aperture"))-s.model.D)<1e-10);
    assert(params.Value(params.Parameter=="Nominal horn gain")=="20");
    drawnow; pause(3); exportapp(fig,fullfile(pwd,'preview-v9-horn-estimate.png'));
    fprintf('V9 UI passed: 1 cm sample, manual and all standard horn options, frequency scaling and export metadata.\n');
end

function change(control,value)
    control.Value=value;
    control.ValueChangedFcn(control,[]);
end
