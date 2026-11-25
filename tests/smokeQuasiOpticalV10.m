function smokeQuasiOpticalV10
% Integrated synthetic loading, TE/TM strict matching, exports and invalidation.
    previewFolder = tempname;
    mkdir(previewFolder);
    fig=QuasiOpticalBistatic3D; cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
    tab=findobj(fig,'Tag','retrievalTab'); tab.Parent.SelectedTab=tab; tab.Parent.SelectionChangedFcn(tab.Parent,[]);
    panel=findobj(fig,'Tag','retrievalPanel'); api=panel.UserData;
    api.loadSynthetic('Paper benchmark'); api.calculate();
    r=api.getResult(); c=api.getComparison(); assert(~isempty(r)&&all(r.valid)&&~isempty(c)&&all(c.valid));
    assert(abs(r.epsilon-(4-.08i))<1e-8 && abs(r.mu-1)<1e-8);
    assert(max(abs(c.deltaEpsilon))<1e-8 && max(abs(c.deltaMu))<1e-8);
    assert(strcmp(findobj(fig,'Tag','exportRetrieval').Enable,'on'));
    params=api.getParameters(); assert(any(params.Parameter=="Known synthetic epsilon"));
    assert(any(startsWith(params.Parameter,"Setup snapshot - ")));
    assert(params.Value(params.Parameter=="Incidence")=="45");
    assert(contains(findobj(fig,'Tag','retrievalSourceLabel').Text,'SYNTHETIC'));
    tabs=findobj(fig,'Tag','retrievalDetailTabs'); tabs.SelectedTab=findobj(fig,'Tag','retrievalConsistencyTab');
    drawnow; pause(2); exportapp(fig,fullfile(previewFolder,'preview-v10-consistency.png'));
    tabs.SelectedTab=findobj(fig,'Tag','retrievalReconstructionTab');
    drawnow; pause(2); exportapp(fig,fullfile(previewFolder,'preview-v10-reconstruction.png'));
    folder=tempname; mkdir(folder); folderCleanup=onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
    exported=api.exportTo(fullfile(folder,'ObliqueBenchmark.png'));
    copyfile(exported.parametersImage,fullfile(previewFolder,'quasi-v10-export_parameters.png'));
    copyfile(exported.image,fullfile(previewFolder,'quasi-v10-export_epsilon.png'));
    images=dir(fullfile(folder,'*.png'));
    for imageIndex=1:numel(images), assertReadableImage(fullfile(folder,images(imageIndex).name)); end
    data=readtable(exported.data,'VariableNamingRule','preserve');
    assert(all(ismember({'q_real','kz_real_per_m','z_real','incidence_deg','polarization','synthetic','delta_epsilon_real','known_epsilon_real'},data.Properties.VariableNames)));
    assert(data.synthetic && data.incidence_deg==45 && abs(data.known_epsilon_real-4)<1e-12);
    assert(isfile(fullfile(folder,'ObliqueBenchmark_TE_TM_epsilon.png')) && isfile(fullfile(folder,'ObliqueBenchmark_reflection_parameters.png')));
    assert(isfile(fullfile(folder,'ObliqueBenchmark_second_polarization_data.csv')));
    change(fig,'retrievalSecondAngleDeg',30); assert(isempty(api.getResult())&&isempty(api.getComparison()));
    assert(strcmp(findobj(fig,'Tag','exportRetrieval').Enable,'off'));
    api.calculate(); assert(isempty(api.getResult()));
    assert(contains(strjoin(findobj(fig,'Tag','retrievalStatus').Value),'same fixed incidence'));
    api.loadSynthetic('Paper benchmark'); change(fig,'retrievalMethod','NIST iterative'); api.calculate();
    assert(isempty(api.getResult())); assert(contains(strrep(strjoin(findobj(fig,'Tag','retrievalStatus').Value),'-',' '),'normal incidence'));
    assert(contains(findobj(fig,'Tag','retrievalMethodHeadline').Text,'normal incidence only'));
    api.loadSynthetic('Paper benchmark'); api.calculate();
    change(fig,'retrievalPolarization','TM'); assert(isempty(api.getResult()));
    api.loadSynthetic('Paper benchmark'); api.calculate(); finalResult=api.getResult(); assert(all(finalResult.valid));
    api.loadSynthetic('Current simulation band + material'); api.calculate(); broad=api.getResult();
    assert(~isempty(broad)&&numel(broad.valid)==180&&all(broad.valid));
    assert(isequal(broad.frequencyHz(:),fig.UserData.model.materialSweepGHz(:)*1e9));
    broadComparison=api.getComparison(); assert(max(abs(broadComparison.deltaEpsilon))<1e-8);
    tabs.SelectedTab=findobj(fig,'Tag','retrievalConsistencyTab');
    drawnow; pause(2); exportapp(fig,fullfile(previewFolder,'preview-v10-broadband.png'));
    api.loadData(struct('fHz',6e9,'s11',.1,'s21',.5,'sourcePath','changed TEST data')); assert(isempty(api.getResult()));
    assert(strcmp(findobj(fig,'Tag','exportRetrieval').Enable,'off'));
    fprintf('V10 UI passed: synthetic truth, TE/TM consistency, R/T reconstruction, metadata and exports, strict matching, method restrictions and stale-result invalidation.\n');
end
function change(fig,tag,value)
    control=findobj(fig,'Tag',tag); control.Value=value; control.ValueChangedFcn(control,[]);
end

function assertReadableImage(path)
    pixels=imread(path); scale=1;
    if isa(pixels,'uint8'), scale=255; elseif isa(pixels,'uint16'), scale=65535; end
    pixels=double(pixels)/scale;
    assert(nnz(pixels>.8)/numel(pixels)>.05 && nnz(pixels<.6)/numel(pixels)>.0001, ...
        'Exported graphic is blank, black or unreadable: %s',path);
end
