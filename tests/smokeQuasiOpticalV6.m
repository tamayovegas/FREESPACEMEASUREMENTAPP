function smokeQuasiOpticalV6
% GUI integration for selectable free-space methods and comparison tables.
    previewFolder = tempname;
    mkdir(previewFolder);
    fig=QuasiOpticalBistatic3D; cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
    tab=findobj(fig,'Tag','retrievalTab'); tab.Parent.SelectedTab=tab;
    tab.Parent.SelectionChangedFcn(tab.Parent,[]);
    panel=findobj(fig,'Tag','retrievalPanel'); api=panel.UserData;
    f=linspace(5e9,12e9,19).'; epsilon=4-.2i; d=.002; n=sqrt(epsilon); g=(1-n)/(1+n);
    P=exp(-1i*2*pi*f/299792458*n*d);
    r=g*(1-P.^2)./(1-g^2*P.^2); tr=(1-g^2)*P./(1-g^2*P.^2);
    api.loadData(struct('fHz',f,'s11',r,'s21',tr,'s12',tr,'s22',r,'sourcePath','Synthetic TEST data; not a measurement'));
    setValue(fig,'retrievalThicknessMM',d*1000); setValue(fig,'retrievalAngleDeg',0); setValue(fig,'retrievalCalibrated',true);
    method=findobj(fig,'Tag','retrievalMethod'); channels=findobj(fig,'Tag','retrievalChannels');
    for name={'NRW','NIST iterative','New non-iterative'}
        method.Value=name{1}; method.ValueChangedFcn(method,[]);
        if strcmp(name{1},'NIST iterative')
            assert(strcmp(findobj(fig,'Tag','retrievalBranch').Enable,'off'));
            setValue(fig,'retrievalInitialReal',4); setValue(fig,'retrievalInitialLoss',.2);
        end
        api.calculate(); result=api.getResult(); assert(~isempty(result)&&all(result.valid));
        assert(max(abs(result.epsilon-epsilon))<1e-7);
        parameters=api.getParameters(); assert(any(parameters.Parameter=="Method"));
        if ~strcmp(name{1},'NRW')
            assert(result.muAssumed && all(result.mu==1));
            assert(contains(findobj(fig,'Tag','retrievalMuAxes').Title.String,'ASSUMED'));
        end
        if strcmp(name{1},'NIST iterative')
            drawnow; pause(3); exportapp(fig,fullfile(previewFolder,'preview-v6-nist.png'));
        end
    end
    channels.Value='four'; channels.ValueChangedFcn(channels,[]); api.calculate(); result=api.getResult();
    assert(~isempty(result)&&all(result.valid)&&strcmp(result.channelMode,'four'));
    drawnow; pause(3); exportapp(fig,fullfile(previewFolder,'preview-v6-noniterative.png'));
    compare=findobj(fig,'Tag','compareRetrievalMethods'); compare.ButtonPushedFcn(compare,[]);
    assert(strcmp(findobj(fig,'Tag','retrievalDetailTabs').SelectedTab.Title,'Free-space method tables'));
    html=findobj(fig,'Tag','retrievalMethodComparison'); assert(strcmp(html.Data.section,'comparison'));
    drawnow; pause(4); exportapp(fig,fullfile(previewFolder,'preview-v6-comparison.png'));
    button=findobj(fig,'Tag','openRetrievalGuide'); button.ButtonPushedFcn(button,[]);
    guide=findall(groot,'Type','figure','Tag','QuasiOpticalRetrievalGuide'); drawnow; pause(4);
    exportapp(guide,fullfile(previewFolder,'preview-v6-guide.png')); close(guide);
    field=findobj(fig,'Tag','retrievalResidualTolerance'); field.Value=1e-4; field.ValueChangedFcn(field,[]);
    assert(isempty(api.getResult()));
    fprintf('V6 UI passed: three free-space methods, mu assumptions, Newton inputs, two/four channel selection, export parameters, comparison tables and tradeoff bullets.\n');
end
function setValue(fig,tag,value)
    field=findobj(fig,'Tag',tag); field.Value=value;
end
