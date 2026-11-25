function panel=QuasiOpticalRetrievalPanel(parent,setupProvider)
%QUASIOPTICALRETRIEVALPANEL Free-space scalar material conversion methods.
    catalog=QuasiOpticalMethodCatalog;
    panel=uigridlayout(parent,[1 2]); panel.ColumnWidth={370,'1x'};
    panel.Padding=[8 8 8 8]; panel.Tag='retrievalPanel';
    controls=uigridlayout(panel,[26 1]);
    controls.RowHeight={82,32,30,32,30,62,26,76,26,76,92,0,30,30,30,42,34,34,48,30,30,30,26,30,56,76};
    controls.Padding=[2 2 6 2]; controls.Scrollable='on'; controls.RowSpacing=5;
    uilabel(controls,'Text','FREE SPACE ONLY: homogeneous isotropic slab in air, known normal thickness, calibrated complex reflection/transmission. NRW supports TE/TM oblique incidence; the other methods require normal incidence.', ...
        'WordWrap','on','FontWeight','bold','FontSize',12);
    methodRow=uigridlayout(controls,[1 2]); methodRow.Padding=[0 0 0 0]; methodRow.ColumnWidth={'1x',78};
    methodChoice=uidropdown(methodRow,'Items',{'NRW: epsilon + mu','NIST iterative: mu = 1','New non-iterative: mu = 1'}, ...
        'ItemsData',{catalog.id},'Value','NRW','Tag','retrievalMethod','ValueChangedFcn',@(~,~) methodChanged());
    uibutton(methodRow,'Text','Compare','Tag','compareRetrievalMethods','ButtonPushedFcn',@(~,~) compareMethods());
    sourceChoice=uidropdown(controls,'Items',{'Manual complex pair','Imported spectrum'}, ...
        'Tag','retrievalSource','ValueChangedFcn',@(~,~) sourceChanged());
    channelChoice=uidropdown(controls,'Items',{'S11 + S21 (symmetric slab)','All four (reciprocal slab average)'}, ...
        'ItemsData',{'pair','four'},'Value','pair','Tag','retrievalChannels', ...
        'Tooltip','All-four requires imported S11,S21,S12,S22; averaged under symmetry and checked against all raw channels.', ...
        'ValueChangedFcn',@(~,~) invalidate());
    uibutton(controls,'Text','Import calibrated CSV or Touchstone .s2p', ...
        'Tag','importSParameters','ButtonPushedFcn',@(~,~) importData());
    sourceLabel=uilabel(controls,'Text','No measured file loaded. Enter complex coefficients or import a spectrum.', ...
        'WordWrap','on','FontSize',11,'Tag','retrievalSourceLabel');
    uilabel(controls,'Text','Frequency f (GHz) / complex amplitudes (not dB)','FontSize',11);
    pairGrid=uigridlayout(controls,[3 2]); pairGrid.RowHeight={22,22,22}; pairGrid.RowSpacing=2; pairGrid.Padding=[0 0 0 0];
    uilabel(pairGrid,'Text','f (GHz)'); frequency=uieditfield(pairGrid,'numeric','Value',10,'Limits',[eps Inf],'Tag','retrievalFrequencyGHz');
    uilabel(pairGrid,'Text','Re S11'); s11Real=uieditfield(pairGrid,'numeric','Tag','retrievalS11Real','Value',0);
    uilabel(pairGrid,'Text','Im S11'); s11Imag=uieditfield(pairGrid,'numeric','Tag','retrievalS11Imag','Value',0);
    uilabel(controls,'Text','Transmission at sample reference faces','FontSize',11);
    transmissionGrid=uigridlayout(controls,[3 2]); transmissionGrid.RowHeight={22,22,22}; transmissionGrid.RowSpacing=2; transmissionGrid.Padding=[0 0 0 0];
    uilabel(transmissionGrid,'Text','Re S21'); s21Real=uieditfield(transmissionGrid,'numeric','Tag','retrievalS21Real','Value',0);
    uilabel(transmissionGrid,'Text','Im S21'); s21Imag=uieditfield(transmissionGrid,'numeric','Tag','retrievalS21Imag','Value',0);
    uilabel(transmissionGrid,'Text','Normal thickness d (mm)'); thickness=uieditfield(transmissionGrid,'numeric','Value',10,'Limits',[eps Inf],'Tag','retrievalThicknessMM');
    geometryGrid=uigridlayout(controls,[4 2]); geometryGrid.RowHeight={20,20,20,20}; geometryGrid.RowSpacing=2; geometryGrid.Padding=[0 0 0 0];
    uilabel(geometryGrid,'Text','Incidence alpha (deg)'); incidence=uieditfield(geometryGrid,'numeric','Limits',[0 90],'Value',0,'Tag','retrievalAngleDeg');
    uilabel(geometryGrid,'Text','Initial log branch m'); branch=uieditfield(geometryGrid,'numeric','Value',0,'RoundFractionalValues','on','Tag','retrievalBranch');
    uilabel(geometryGrid,'Text','Min |S21| (noise floor)'); transmissionFloor=uieditfield(geometryGrid,'numeric','Value',1e-8,'Limits',[realmin 1], ...
        'Tag','retrievalTransmissionFloor','Tooltip','Minimum trustworthy calibrated transmission amplitude.');
    uilabel(geometryGrid,'Text','Max model residual'); residualTolerance=uieditfield(geometryGrid,'numeric','Value',1e-6,'Limits',[realmin Inf], ...
        'Tag','retrievalResidualTolerance','Tooltip','Maximum complex S-channel reconstruction residual accepted for this measurement.');
    guessGrid=uigridlayout(controls,[4 2]); guessGrid.RowHeight={20,20,20,20}; guessGrid.RowSpacing=2; guessGrid.Padding=[0 0 0 0];
    uilabel(guessGrid,'Text','Initial epsilon real'); initialReal=uieditfield(guessGrid,'numeric','Value',4,'Tag','retrievalInitialReal');
    uilabel(guessGrid,'Text','Initial epsilon loss'); initialLoss=uieditfield(guessGrid,'numeric','Value',.1,'Limits',[0 Inf],'Tag','retrievalInitialLoss');
    uilabel(guessGrid,'Text','Maximum iterations'); maxIterations=uieditfield(guessGrid,'numeric','Value',80,'Limits',[1 2000],'RoundFractionalValues','on','Tag','retrievalMaxIterations');
    uilabel(guessGrid,'Text','Newton tolerance'); convergenceTolerance=uieditfield(guessGrid,'numeric','Value',1e-9,'Limits',[realmin .1],'Tag','retrievalNewtonTolerance');
    polarization=uidropdown(controls,'Items',{'TE','TM'},'Tag','retrievalPolarization', ...
        'Tooltip','Polarization of this fixed-angle spectrum; TE and TM use different air/slab wave impedances at oblique incidence.');
    uibutton(controls,'Text','Copy thickness / incidence from current setup', ...
        'Tag','retrievalUseSetup','ButtonPushedFcn',@(~,~) useSetup());
    unwrap=uicheckbox(controls,'Text','Unwrap propagation phase (closed-form methods)','Value',true,'Tag','retrievalUnwrap');
    calibrated=uicheckbox(controls,'Text','Inputs are calibrated sample-face S11 / S21', ...
        'WordWrap','on','Value',false,'Tag','retrievalCalibrated');
    uibutton(controls,'Text','Calculate selected free-space method','FontWeight','bold', ...
        'Tag','calculateRetrievalSide','ButtonPushedFcn',@(~,~) calculate());
    exportButton=uibutton(controls,'Text','Export results + graph + parameter tables', ...
        'Tag','exportRetrieval','Enable','off','ButtonPushedFcn',@(~,~) exportResults());
    uilabel(controls,'Text','Rohde & Schwarz supplied note: NRW / NIST iterative / New non-iterative. Passive loss = -Im. SCL is excluded from this unbacked free-space fixture.', ...
        'WordWrap','on','FontSize',10);
    uibutton(controls,'Text','Open method tables, pros / cons and equations', ...
        'Tag','openRetrievalGuide','ButtonPushedFcn',@(~,~) openMethod());
    syntheticChoice=uidropdown(controls,'Items',{'Paper benchmark','Current simulation band + material'}, ...
        'Tag','retrievalSyntheticExample','Tooltip','Generated data with known constitutive values; never labelled as measurements.');
    uibutton(controls,'Text','Load synthetic example (TE + TM)','Tag','loadSyntheticExample','ButtonPushedFcn',@(~,~) loadSynthetic());
    comparePolarizations=uicheckbox(controls,'Text','Compare with opposite polarization spectrum','Tag','retrievalComparePolarizations', ...
        'Value',false,'ValueChangedFcn',@(~,~) invalidate());
    uibutton(controls,'Text','Import optional second polarization CSV / .s2p','Tag','importSecondPolarization','ButtonPushedFcn',@(~,~) importSecond());
    secondLabel=uilabel(controls,'Text','No second spectrum. Each file has one fixed incidence and polarization; matching grids are required.', ...
        'WordWrap','on','FontSize',10,'Tag','retrievalSecondSourceLabel');
    secondGrid=uigridlayout(controls,[3 2]); secondGrid.RowHeight={22,22,22}; secondGrid.RowSpacing=2; secondGrid.Padding=[0 0 0 0];
    uilabel(secondGrid,'Text','Second incidence (deg)'); secondAngle=uieditfield(secondGrid,'numeric','Value',0,'Limits',[0 90],'Tag','retrievalSecondAngleDeg');
    uilabel(secondGrid,'Text','Second normal d (mm)'); secondThickness=uieditfield(secondGrid,'numeric','Value',10,'Limits',[eps Inf],'Tag','retrievalSecondThicknessMM');
    uilabel(secondGrid,'Text','Second polarization'); secondPol=uidropdown(secondGrid,'Items',{'TE','TM'},'Value','TM','Tag','retrievalSecondPolarization');
    % Keep generated-data entry points visible near the primary source selector.
    rowOrder=[1 2 3 21 22 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 23 24 25 26 19 20];
    originalHeights=controls.RowHeight;
    for child=controls.Children.'
        oldRow=child.Layout.Row; child.Layout.Row=find(rowOrder==oldRow);
    end
    controls.RowHeight=originalHeights(rowOrder);
    right=uigridlayout(panel,[3 1]); right.RowHeight={44,'1x',178}; right.Padding=[0 0 0 0];
    toolbar=uigridlayout(right,[1 2]); toolbar.Padding=[0 0 0 0]; toolbar.ColumnWidth={'1x',110};
    methodHeadline=uilabel(toolbar,'WordWrap','on','FontWeight','bold','FontSize',12,'Tag','retrievalMethodHeadline');
    uibutton(toolbar,'Text','Calculate','Tag','calculateRetrieval','FontWeight','bold','ButtonPushedFcn',@(~,~) calculate());
    detailTabs=uitabgroup(right,'Tag','retrievalDetailTabs');
    resultsTab=uitab(detailTabs,'Title','Calculated results','Tag','retrievalCalculatedTab');
    consistencyTab=uitab(detailTabs,'Title','TE / TM consistency','Tag','retrievalConsistencyTab');
    reconstructionTab=uitab(detailTabs,'Title','R / T reconstruction','Tag','retrievalReconstructionTab');
    methodsTab=uitab(detailTabs,'Title','Free-space method tables','Tag','retrievalMethodsTab');
    methodPath=fullfile(fileparts(mfilename('fullpath')),'Retrieval_method.html');
    comparisonGrid=uigridlayout(methodsTab,[2 1]); comparisonGrid.RowHeight={30,'1x'}; comparisonGrid.Padding=[0 0 0 0];
    uibutton(comparisonGrid,'Text','Export method comparison PNG + CSV + parameter-table PNG', ...
        'Tag','exportMethodComparison','ButtonPushedFcn',@(~,~) exportComparison());
    comparisonHTML=uihtml(comparisonGrid,'HTMLSource',methodPath,'Tag','retrievalMethodComparison');
    prosCons=uitextarea(right,'Editable','off','FontSize',11,'Tag','retrievalMethodTradeoffs');
    resultsLayout=uigridlayout(resultsTab,[3 2]); resultsLayout.RowHeight={'1.1x','1x',90}; resultsLayout.ColumnWidth={'1x','1x'}; resultsLayout.Padding=[0 0 0 0];
    epsilonAx=uiaxes(resultsLayout,'Tag','retrievalEpsilonAxes'); epsilonAx.Layout.Row=1; epsilonAx.Layout.Column=1;
    muAx=uiaxes(resultsLayout,'Tag','retrievalMuAxes'); muAx.Layout.Row=1; muAx.Layout.Column=2;
    resultTable=uitable(resultsLayout,'Tag','retrievalResults','ColumnName', ...
        {'f (GHz)','eps real','eps loss','mu real','mu loss','n real','n loss','branch','residual','q real','q imag','kz real (/m)','kz imag (/m)','z real','z imag','valid','status'});
    resultTable.Layout.Row=2; resultTable.Layout.Column=[1 2];
    statusText=uitextarea(resultsLayout,'Editable','off','Tag','retrievalStatus'); statusText.Layout.Row=3; statusText.Layout.Column=[1 2];
    consistencyGrid=uigridlayout(consistencyTab,[3 2]); consistencyGrid.Padding=[2 2 2 2]; consistencyGrid.RowHeight={42,'1x','1x'};
    comparisonNotice=uilabel(consistencyGrid,'WordWrap','on','FontSize',11,'Text', ...
        'TE/TM disagreement can indicate model or measurement inconsistency; it does not automatically establish anisotropy. Thickness, fixed incidence and frequency grids must match.');
    comparisonNotice.Layout.Row=1; comparisonNotice.Layout.Column=[1 2];
    compareEpsilonAx=uiaxes(consistencyGrid,'Tag','retrievalCompareEpsilonAxes');
    compareMuAx=uiaxes(consistencyGrid,'Tag','retrievalCompareMuAxes');
    deltaEpsilonAx=uiaxes(consistencyGrid,'Tag','retrievalDeltaEpsilonAxes');
    deltaMuAx=uiaxes(consistencyGrid,'Tag','retrievalDeltaMuAxes');
    compareEpsilonAx.Layout.Row=2; compareEpsilonAx.Layout.Column=1; compareMuAx.Layout.Row=2; compareMuAx.Layout.Column=2;
    deltaEpsilonAx.Layout.Row=3; deltaEpsilonAx.Layout.Column=1; deltaMuAx.Layout.Row=3; deltaMuAx.Layout.Column=2;
    reconstructionGrid=uigridlayout(reconstructionTab,[2 1]); reconstructionGrid.Padding=[2 2 2 2];
    reflectionAx=uiaxes(reconstructionGrid,'Tag','retrievalReflectionAxes');
    transmissionAx=uiaxes(reconstructionGrid,'Tag','retrievalTransmissionAxes');
    measured=[]; secondMeasured=[]; result=[]; comparison=[]; lastInput=[]; lastOptions=[]; lastSetup=[]; comparisonRequest=0;
    for field=[frequency s11Real s11Imag s21Real s21Imag thickness incidence branch transmissionFloor residualTolerance initialReal initialLoss maxIterations convergenceTolerance secondAngle secondThickness]
        field.ValueChangedFcn=@(~,~) invalidate();
    end
    secondPol.ValueChangedFcn=@(~,~) invalidate();
    polarization.ValueChangedFcn=@(~,~) invalidate(); unwrap.ValueChangedFcn=@(~,~) invalidate(); calibrated.ValueChangedFcn=@(~,~) invalidate();
    panel.UserData=struct('loadData',@setData,'loadComparisonData',@setSecondData,'loadSynthetic',@loadSynthetic, ...
        'calculate',@calculate,'getResult',@getResult,'getComparison',@getComparison,'getParameters',@retrievalParameters,'exportTo',@exportTo);
    sourceChanged(); methodChanged();

    function value=getResult(), value=result; end
    function value=getComparison(), value=comparison; end
    function entry=selectedMethod(), entry=catalog(strcmp({catalog.id},methodChoice.Value)); end
    function invalidate()
        result=[]; comparison=[]; lastSetup=[]; resultTable.Data=cell(0,17); exportButton.Enable='off';
        for ax=[epsilonAx muAx compareEpsilonAx compareMuAx deltaEpsilonAx deltaMuAx reflectionAx transmissionAx], cla(ax); end
        headings={'f (GHz)','eps real','eps loss','mu real','mu loss','n real','n loss','branch','residual','q real','q imag','kz real (/m)','kz imag (/m)','z real','z imag','valid','status'};
        if ~strcmp(methodChoice.Value,'NRW'), headings{4}='mu=1*'; headings{5}='mu loss*'; end
        resultTable.ColumnName=headings;
        title(epsilonAx,'Relative permittivity'); xlabel(epsilonAx,'Frequency (GHz)'); grid(epsilonAx,'on');
        if strcmp(methodChoice.Value,'NRW'), title(muAx,'Relative permeability (retrieved)'); else, title(muAx,'mu_r = 1 ASSUMED, not measured'); end
        xlabel(muAx,'Frequency (GHz)'); grid(muAx,'on');
        statusText.Value={'Select a method, set its inputs and calculate. Editing an input clears the previous result.'};
    end
    function methodChanged()
        entry=selectedMethod(); iterative=strcmp(entry.id,'NIST iterative');
        if iterative
            guessGrid.Visible='on'; controls.RowHeight{14}=92; branch.Value=0; branch.Enable='off'; unwrap.Value=false; unwrap.Enable='off';
        else
            guessGrid.Visible='off'; controls.RowHeight{14}=0; branch.Enable='on'; unwrap.Enable='on'; unwrap.Value=true;
        end
        restriction='normal incidence only'; if strcmp(entry.id,'NRW'), restriction='TE / TM oblique incidence'; end
        methodHeadline.Text=[entry.name ' | ' restriction ' | ' entry.outputs];
        prosCons.Value=[{[upper(entry.name) ' — ' entry.muTreatment];'ADVANTAGES'}; ...
            cellfun(@(s)['• ' s],entry.advantages(:),'UniformOutput',false);{'DISADVANTAGES'}; ...
            cellfun(@(s)['• ' s],entry.disadvantages(:),'UniformOutput',false)];
        if ~strcmp(entry.id,'NRW')
            prosCons.Value=[{'Normal incidence only: implemented equations use q=n and intrinsic impedance. Use NRW for oblique TE/TM.'};prosCons.Value];
        end
        syncComparison();
        invalidate();
    end
    function compareMethods()
        detailTabs.SelectedTab=methodsTab; drawnow; syncComparison();
    end
    function syncComparison()
        comparisonRequest=comparisonRequest+1;
        comparisonHTML.Data=struct('method',methodChoice.Value,'section','comparison','requestId',comparisonRequest);
    end
    function exportComparison()
        [file,folder]=uiputfile('*.png','Export free-space method comparison and tables','FreeSpaceMethods.png');
        if isequal(file,0), return; end
        try
            comparisonFigure=QuasiOpticalMethodFigure(); cleaner=onCleanup(@() close(comparisonFigure)); %#ok<NASGU>
            QuasiOpticalExportBundle(comparisonFigure,fullfile(folder,file),QuasiOpticalMethodParameters(),'Free-space method comparison');
            uialert(ancestor(panel,'figure'),'Saved comparison image, matching CSV and parameter-table PNG.','Method comparison exported','Icon','success');
        catch err, uialert(ancestor(panel,'figure'),err.message,'Method comparison export failed'); end
    end
    function sourceChanged()
        manual=strcmp(sourceChoice.Value,'Manual complex pair');
        for h=[frequency s11Real s11Imag s21Real s21Imag]
            if manual, h.Enable='on'; else, h.Enable='off'; end
        end
        if manual, channelChoice.Value='pair'; channelChoice.Enable='off'; else, channelChoice.Enable='on'; end
        invalidate();
    end
    function useSetup()
        invalidate(); setup=setupProvider(); thickness.Value=max(eps,setup.materialInput.thicknessMM);
        incidence.Value=setup.model.incidence; frequency.Value=setup.parameters.fGHz;
        statusText.Value={'Copied thickness and incidence; imported channels are unchanged.';'NRW supports oblique TE/TM. NIST iterative and New non-iterative require normal incidence.'};
    end
    function importData()
        [file,folder]=uigetfile({'*.csv;*.s2p','Complex S-parameters (*.csv, *.s2p)'},'Import calibrated free-space S-parameters');
        if isequal(file,0), return; end
        try, setData(QuasiOpticalReadSParameters(fullfile(folder,file)));
        catch err, statusText.Value={err.message}; uialert(ancestor(panel,'figure'),err.message,'Import failed'); end
    end
    function setData(data)
        if ~isfield(data,'sourcePath'), data.sourcePath='Programmatically supplied calibrated channels'; end
        measured=data; sourceChoice.Value='Imported spectrum'; sourceChanged();
        frequency.Value=data.fHz(1)/1e9; s11Real.Value=real(data.s11(1)); s11Imag.Value=imag(data.s11(1));
        s21Real.Value=real(data.s21(1)); s21Imag.Value=imag(data.s21(1));
        sourceLabel.Text=sprintf('%s | %d frequency samples',data.sourcePath,numel(data.fHz)); sourceLabel.Tooltip=data.sourcePath;
        statusText.Value={'Loaded complex channels. Choose two or four inputs, confirm calibration and set the selected method controls.'};
    end
    function importSecond()
        [file,folder]=uigetfile({'*.csv;*.s2p','Complex S-parameters (*.csv, *.s2p)'},'Import opposite-polarization spectrum');
        if isequal(file,0), return; end
        try, setSecondData(QuasiOpticalReadSParameters(fullfile(folder,file)));
        catch err, invalidate(); statusText.Value={err.message}; end
    end
    function setSecondData(data,spec)
        if nargin<2
            spec=struct('thicknessM',thickness.Value/1000,'angleDeg',incidence.Value,'polarization','TM');
            if strcmp(polarization.Value,'TM'), spec.polarization='TE'; end
            for name={'thicknessM','angleDeg','polarization'}
                if isfield(data,name{1}), spec.(name{1})=data.(name{1}); end
            end
        end
        if ~isfield(data,'sourcePath'), data.sourcePath='Programmatically supplied opposite-polarization channels'; end
        secondMeasured=data; secondAngle.Value=spec.angleDeg; secondThickness.Value=spec.thicknessM*1000; secondPol.Value=spec.polarization;
        comparePolarizations.Value=true; invalidate();
        secondLabel.Text=sprintf('%s | %d samples | %s at %.6g deg, d=%.6g mm',data.sourcePath,numel(data.fHz),spec.polarization,spec.angleDeg,spec.thicknessM*1000);
        secondLabel.Tooltip=data.sourcePath;
    end
    function loadSynthetic(example)
        if nargin<1, example=syntheticChoice.Value; end
        try
            syntheticChoice.Value=validatestring(example,syntheticChoice.Items);
            [data,other,spec]=QuasiOpticalSynthetic(example,setupProvider(),polarization.Value);
            methodChoice.Value='NRW'; methodChanged();
            thickness.Value=spec.thicknessM*1000; incidence.Value=spec.angleDeg; branch.Value=spec.branch; calibrated.Value=true;
            setData(data); setSecondData(other); channelChoice.Value='pair';
            sourceLabel.Text=spec.description;
            statusText.Value={spec.description;'Generated TE and TM sample-face spectra are loaded; these are not experimental measurements.'; ...
                sprintf('Initial branch m=%d is seeded from the known synthetic material. Measured spectra require independent branch justification.',spec.branch)};
        catch err, invalidate(); statusText.Value={['Synthetic example unavailable: ' err.message]}; end
    end
    function calculate()
        invalidate();
        try
            if ~calibrated.Value, error('QuasiOptical:CalibrationRequired','Confirm calibrated sample-face reflection and transmission, including phase/reference planes.'); end
            if strcmp(sourceChoice.Value,'Imported spectrum')
                if isempty(measured), error('QuasiOptical:NoData','Import a complex spectrum first.'); end
                data=measured;
            else
                data=struct('fHz',frequency.Value*1e9,'s11',s11Real.Value+1i*s11Imag.Value, ...
                    's21',s21Real.Value+1i*s21Imag.Value,'sourcePath','Manual complex pair');
            end
            options=struct('method',methodChoice.Value,'angleDeg',incidence.Value,'polarization',polarization.Value, ...
                'branch',branch.Value,'unwrapPhase',unwrap.Value,'minTransmission',transmissionFloor.Value, ...
                'reconstructionTolerance',residualTolerance.Value);
            if strcmp(methodChoice.Value,'NIST iterative')
                options.initialEpsilon=initialReal.Value-1i*initialLoss.Value;
                options.maxIterations=maxIterations.Value; options.tolerance=convergenceTolerance.Value;
            end
            result=QuasiOpticalRetrieveData(data,thickness.Value/1000,options,channelChoice.Value);
            lastInput=data; lastOptions=result.options; lastSetup=setupProvider();
            if comparePolarizations.Value
                if isempty(secondMeasured), error('QuasiOptical:ComparisonData','Load the optional opposite-polarization spectrum before comparing.'); end
                spec=struct('thicknessM',secondThickness.Value/1000,'angleDeg',secondAngle.Value,'polarization',secondPol.Value);
                comparison=QuasiOpticalComparePolarizations(result,secondMeasured,spec,channelChoice.Value);
            end
            exportButton.Enable='on'; detailTabs.SelectedTab=resultsTab;
            resultTable.Data=[num2cell([result.frequencyHz(:)/1e9,real(result.epsilon(:)),-imag(result.epsilon(:)), ...
                real(result.mu(:)),-imag(result.mu(:)),real(result.n(:)),-imag(result.n(:)),result.branch(:),result.residual(:), ...
                real(result.q(:)),imag(result.q(:)),real(result.kz(:)),imag(result.kz(:)),real(result.z(:)),imag(result.z(:))]), ...
                num2cell(result.valid(:)),result.status(:)];
            headings={'f (GHz)','eps real','eps loss','mu real','mu loss','n real','n loss','branch','residual','q real','q imag','kz real (/m)','kz imag (/m)','z real','z imag','valid','status'};
            muHeading='Relative permeability (retrieved)';
            if result.muAssumed, headings{4}='mu=1*'; headings{5}='mu loss*'; muHeading='mu_r = 1 ASSUMED, not measured'; end
            resultTable.ColumnName=headings;
            drawProperty(epsilonAx,result.epsilon,'Relative permittivity epsilon_r'); drawProperty(muAx,result.mu,muHeading);
            drawReconstruction();
            if ~isempty(comparison), drawConsistency(); end
            statusText.Value=[{sprintf('%s: %d / %d valid | d = %.6g mm | channels = %s', ...
                lastOptions.method,nnz(result.valid),numel(result.valid),result.thicknessM*1000,result.channelMode)}; ...
                {sprintf('Fixed incidence %.6g deg | %s | Illumination guidance is separate from numerical retrieval validity.',lastOptions.angleDeg,lastOptions.polarization)};result.notes(:)];
            if ~isempty(comparison), statusText.Value=[statusText.Value;comparison.notes(:)]; end
            if isfield(data,'synthetic'), statusText.Value=[{data.synthetic.description;'SYNTHETIC data: generated model validation, not experimental measurement.'};statusText.Value]; end
        catch err
            invalidate(); statusText.Value={['Calculation unavailable: ' err.message]};
        end
    end
    function drawProperty(ax,values,heading)
        cla(ax); hold(ax,'on'); good=result.valid(:); x=result.frequencyHz(:)/1e9;
        rv=real(values(:)); lv=-imag(values(:)); rv(~good)=NaN; lv(~good)=NaN;
        plot(ax,x,rv,'-o','LineWidth',1.5,'MarkerSize',4,'DisplayName','Real part');
        plot(ax,x,lv,'-s','LineWidth',1.5,'MarkerSize',4,'DisplayName','Loss = -imaginary part');
        hold(ax,'off'); title(ax,heading,'FontSize',11); xlabel(ax,'Frequency (GHz)'); ylabel(ax,'Relative'); grid(ax,'on'); legend(ax,'Location','best');
    end
    function exportResults()
        if isempty(result), statusText.Value={'Calculate a result before exporting.'}; return; end
        [file,folder]=uiputfile('*.png','Export free-space results, graphs and parameter tables','RetrievedPermittivity.png');
        if isequal(file,0), return; end
        try, paths=exportTo(fullfile(folder,file)); statusText.Value={['Saved result bundle: ' paths.image];['Saved complex data: ' paths.data]};
        catch err, uialert(ancestor(panel,'figure'),err.message,'Retrieval export failed'); end
    end
    function paths=exportTo(path)
        if isempty(result), error('QuasiOptical:NoResult','Calculate a result before exporting.'); end
        [folder,stem]=fileparts(path); base=fullfile(folder,stem); params=retrievalParameters();
        paths=QuasiOpticalExportBundle(epsilonAx,base,params,[lastOptions.method ' permittivity']);
        QuasiOpticalExportBundle(muAx,[base '_permeability'],params,[lastOptions.method ' permeability / assumption']);
        QuasiOpticalExportBundle(reflectionAx,[base '_reflection'],params,'Complex input / reconstructed reflection');
        QuasiOpticalExportBundle(transmissionAx,[base '_transmission'],params,'Complex input / reconstructed transmission');
        values=resultValues(result,lastInput);
        if ~isempty(comparison)
            axesList=[compareEpsilonAx compareMuAx deltaEpsilonAx deltaMuAx]; suffixes={'_TE_TM_epsilon','_TE_TM_mu','_delta_epsilon','_delta_mu'};
            for k=1:4, QuasiOpticalExportBundle(axesList(k),[base suffixes{k}],params,'TE / TM model consistency'); end
            values.TE_epsilon_real=real(comparison.TE.epsilon); values.TE_epsilon_imag=imag(comparison.TE.epsilon);
            values.TM_epsilon_real=real(comparison.TM.epsilon); values.TM_epsilon_imag=imag(comparison.TM.epsilon);
            values.TE_mu_real=real(comparison.TE.mu); values.TE_mu_imag=imag(comparison.TE.mu);
            values.TM_mu_real=real(comparison.TM.mu); values.TM_mu_imag=imag(comparison.TM.mu);
            values.delta_epsilon_real=real(comparison.deltaEpsilon); values.delta_epsilon_imag=imag(comparison.deltaEpsilon);
            values.delta_mu_real=real(comparison.deltaMu); values.delta_mu_imag=imag(comparison.deltaMu); values.comparison_valid=comparison.valid;
            secondaryValues=resultValues(comparison.secondary,secondMeasured); writetable(secondaryValues,[base '_second_polarization_data.csv']);
        end
        paths.data=[base '_data.csv']; writetable(values,paths.data);
    end
    function values=resultValues(r,input)
        count=numel(r.valid);
        values=table(r.frequencyHz(:),real(input.s11(:)),imag(input.s11(:)),real(input.s21(:)),imag(input.s21(:)), ...
            real(r.reconstructedS11(:)),imag(r.reconstructedS11(:)),real(r.reconstructedS21(:)),imag(r.reconstructedS21(:)), ...
            real(r.epsilon(:)),imag(r.epsilon(:)),real(r.mu(:)),imag(r.mu(:)),real(r.n(:)),imag(r.n(:)), ...
            r.branch(:),r.residual(:),r.valid(:),string(r.status(:)), ...
            'VariableNames',{'frequency_Hz','S11_real','S11_imag','S21_real','S21_imag', ...
            'reconstructed_S11_real','reconstructed_S11_imag','reconstructed_S21_real','reconstructed_S21_imag', ...
            'epsilon_real','epsilon_imag','mu_real','mu_imag','n_real','n_imag','branch','reconstruction_residual','valid','status'});
        values.method=repmat(string(r.options.method),count,1); values.mu_assumed=repmat(r.muAssumed,count,1);
        values.channel_mode=repmat(string(r.channelMode),count,1);
        values.incidence_deg=repmat(r.options.angleDeg,count,1); values.polarization=repmat(string(r.options.polarization),count,1);
        values.thickness_m=repmat(r.thicknessM,count,1); values.synthetic=repmat(isfield(input,'synthetic'),count,1);
        values.source=repmat(string(input.sourcePath),count,1);
        if isfield(r,'q')
            values.q_real=real(r.q); values.q_imag=imag(r.q); values.kz_real_per_m=real(r.kz); values.kz_imag_per_m=imag(r.kz);
            values.z_real=real(r.z); values.z_imag=imag(r.z);
        end
        if isfield(input,'synthetic')
            knownEps=input.synthetic.epsilon+zeros(count,1); knownMu=input.synthetic.mu+zeros(count,1);
            values.known_epsilon_real=real(knownEps); values.known_epsilon_imag=imag(knownEps);
            values.known_mu_real=real(knownMu); values.known_mu_imag=imag(knownMu);
        end
        if strcmp(r.channelMode,'four')
            values.S12_real=real(r.rawS12); values.S12_imag=imag(r.rawS12); values.S22_real=real(r.rawS22); values.S22_imag=imag(r.rawS22);
            values.channel_asymmetry=r.inputAsymmetry; values.raw_maximum_power_gain=r.rawMaximumPowerGain;
        end
        if isfield(r,'iterations'), values.iterations=r.iterations; values.converged=r.converged; values.objective_residual=r.objectiveResidual; end
    end
    function drawConsistency()
        overlay(compareEpsilonAx,comparison.TE.epsilon,comparison.TM.epsilon,'Permittivity: TE and TM estimates');
        overlay(compareMuAx,comparison.TE.mu,comparison.TM.mu,'Permeability: TE and TM estimates');
        difference(deltaEpsilonAx,comparison.deltaEpsilon,'Complex epsilon_{TE} - epsilon_{TM}');
        difference(deltaMuAx,comparison.deltaMu,'Complex mu_{TE} - mu_{TM}');
    end
    function overlay(ax,te,tm,heading)
        cla(ax); hold(ax,'on'); x=comparison.frequencyHz/1e9; good=comparison.valid;
        te(~good)=NaN; tm(~good)=NaN;
        plot(ax,x,real(te),'-o',x,-imag(te),'--o',x,real(tm),'-s',x,-imag(tm),'--s','LineWidth',1.2,'MarkerSize',3);
        legend(ax,{'TE real','TE loss','TM real','TM loss'},'Location','best'); finish(ax,heading);
    end
    function difference(ax,value,heading)
        cla(ax); hold(ax,'on'); value(~comparison.valid)=NaN; x=comparison.frequencyHz/1e9;
        plot(ax,x,real(value),'-o',x,imag(value),'-s','LineWidth',1.2,'MarkerSize',3);
        legend(ax,{'Real difference','Imaginary difference'},'Location','best'); finish(ax,heading);
    end
    function drawReconstruction()
        cla(reflectionAx); cla(transmissionAx); hold(reflectionAx,'on'); hold(transmissionAx,'on');
        oneReconstruction(result,lastInput);
        if ~isempty(comparison), oneReconstruction(comparison.secondary,secondMeasured); end
        finish(reflectionAx,'Complex sample reflection: input versus reconstructed');
        finish(transmissionAx,'Complex sample transmission: input versus reconstructed');
        legend(reflectionAx,'Location','best','FontSize',8); legend(transmissionAx,'Location','best','FontSize',8);
    end
    function oneReconstruction(r,input)
        x=r.frequencyHz(:)/1e9; pol=r.options.polarization;
        channels={input.s11(:),r.reconstructedS11(:),input.s21(:),r.reconstructedS21(:)};
        for k=1:2
            ax=reflectionAx; if k==2, ax=transmissionAx; end
            actual=channels{2*k-1}; predicted=channels{2*k};
            plot(ax,x,real(actual),'-o','DisplayName',[pol ' input Re'],'MarkerSize',4);
            plot(ax,x,imag(actual),'-s','DisplayName',[pol ' input Im'],'MarkerSize',4);
            plot(ax,x,real(predicted),'--x','DisplayName',[pol ' model Re'],'MarkerSize',7);
            plot(ax,x,imag(predicted),'--+','DisplayName',[pol ' model Im'],'MarkerSize',7);
        end
    end
    function finish(ax,heading)
        hold(ax,'off'); title(ax,heading,'FontSize',11); xlabel(ax,'Frequency (GHz)'); grid(ax,'on');
    end
    function params=retrievalParameters()
        if isempty(result), error('QuasiOptical:NoResult','Calculate before requesting result parameters.'); end
        branchValue=string(lastOptions.branch); branchDescription="User-selected initial logarithm branch; continuity alone cannot establish its absolute value";
        unwrapValue=string(lastOptions.unwrapPhase);
        if strcmp(lastOptions.method,'NIST iterative'), branchValue="Not used"; unwrapValue="Newton frequency continuation"; branchDescription="Initial complex epsilon selects the local Newton root"; end
        muTreatment="Retrieved scalar permeability";
        if result.muAssumed, muTreatment="mu_r = 1 ASSUMED, not measured"; end
        names=["Method";"Measurement fixture";"Input source";"Input channels";"Sample thickness";"Incidence";"Polarization";"Initial log branch";"Phase tracking";"Frequency samples";"Valid samples";"Time convention";"Scope";"Permeability treatment";"Transmission amplitude floor";"Maximum model residual"];
        symbols=["method";"fixture";"S parameters";"channels";"d";"alpha";"p";"m";"phase";"N_f";"N_valid";"exp(+j omega t)";"epsilon,mu";"mu_r";"min_abs_S21";"max_r_S"];
        values=[string(lastOptions.method);"Free space / air-slab-air";string(lastInput.sourcePath);string(result.channelMode);string(result.thicknessM);string(lastOptions.angleDeg); ...
            string(lastOptions.polarization);branchValue;unwrapValue;string(numel(result.valid));string(nnz(result.valid));"Passive loss = -Im";"Scalar homogeneous isotropic slab";muTreatment;string(lastOptions.minTransmission);string(lastOptions.reconstructionTolerance)];
        units=["";"";"";"";"m";"deg";"";"";"";"count";"count";"";"relative";"relative";"amplitude";"amplitude"];
        descriptions=["Supplied R&S note: NRW Annex2, NIST Annex4, New non-iterative Annex5"; ...
            "NRW: oblique TE/TM air-slab-air; NIST and New non-iterative: normal incidence only";"Calibrated sample-face channels, including phase"; ...
            "Four-channel mode averages reciprocal/symmetric partners and checks all raw coefficients";"Known normal physical thickness"; ...
            "Fixed angle for this spectrum; normal physical thickness is independent of incidence";"Explicit tangential-electric TE or TM normalization; equivalent at normal incidence";branchDescription; ...
            "Phase branch or nonlinear root still requires justified independent information";"Complex measured frequency samples"; ...
            "Samples passing convergence, passivity and reconstruction checks";"Positive loss corresponds to negative imaginary constitutive values"; ...
            "Full tensor recovery and conduction/dielectric-loss separation require further information";"NRW retrieves mu; the two nonmagnetic methods fix it to unity"; ...
            "Samples at/below selected calibrated transmission floor are not retrieved";"Residual includes every selected raw scattering channel"];
        params=table(names,symbols,values,units,descriptions,'VariableNames',{'Parameter','Symbol','Value','Unit','Description'});
        if strcmp(lastOptions.method,'NIST iterative')
            extra=table(["Initial complex permittivity";"Maximum Newton iterations";"Newton convergence tolerance"], ...
                ["epsilon_initial";"N_iter_max";"tol_Newton"], ...
                [string(lastOptions.initialEpsilon);string(lastOptions.maxIterations);string(lastOptions.tolerance)], ...
                ["relative";"count";"amplitude"], ...
                ["User-supplied initial guess; last accepted frequency seeds continuation";"Iteration cap per frequency";"Determinant-equation convergence threshold"], ...
                'VariableNames',params.Properties.VariableNames);
            params=[params;extra];
        end
        extra=table(["Synthetic provenance";"Comparison enabled";"Propagation q";"Normal propagation constant";"Polarization-specific impedance";"Setup snapshot relation"], ...
            ["provenance";"TE/TM";"q";"k_z";"z_p";"setup"], ...
            [string(lastInput.sourcePath);string(~isempty(comparison));"k_z/k_0";"k_0*q";"Z_slab,p / Z_air,p";"Independent simulation setup captured at calculation"], ...
            ["";"logical";"1";"rad/m";"1";""], ...
            ["Synthetic sources are generated model data with known properties, not measurements"; ...
            "Comparison requires identical thickness, fixed angle and frequency grid; no interpolation"; ...
            "NRW normal propagation, distinct from bulk n at oblique incidence";"Complex normal propagation; exp(+j omega t)"; ...
            "TE: mu*cos(alpha)/q; TM: q/(epsilon*cos(alpha))";"Illumination diagnostics use the frozen simulation geometry, which may differ from fixed-angle measurement controls"], ...
            'VariableNames',params.Properties.VariableNames);
        params=[params;extra];
        if isfield(lastInput,'synthetic')
            provenance=lastInput.synthetic;
            extra=table(["Known synthetic epsilon";"Known synthetic mu";"Synthetic forward model";"Synthetic branch seed"], ...
                ["epsilon_known";"mu_known";"model";"m_known"],[truthSummary(provenance.epsilon);truthSummary(provenance.mu);string(provenance.model);string(provenance.initialBranch)], ...
                ["relative";"relative";"";"integer"],["Generation truth; may vary with frequency";"Generation truth";"Experimental accuracy has not been validated by this example";"Initial seed is calculated from known generation truth; actual selected branch is independently editable"], ...
                'VariableNames',params.Properties.VariableNames);
            params=[params;extra];
        end
        if ~isempty(comparison)
            extra=table(["Second polarization source";"Second polarization";"Comparison valid samples";"Comparison interpretation"], ...
                ["source_2";"p_2";"N_valid_both";"delta"], ...
                [string(secondMeasured.sourcePath);string(comparison.secondary.options.polarization);string(nnz(comparison.valid));"Possible model or measurement inconsistency"], ...
                ["";"";"count";""],["Independent fixed-angle spectrum; synthetic if explicitly labelled";"Opposite of primary polarization"; ...
                "Both numerical retrievals pass their checks";"Disagreement does not automatically establish anisotropy"], ...
                'VariableNames',params.Properties.VariableNames); params=[params;extra];
        end
        if ~isempty(lastSetup)&&all(isfield(lastSetup,{'parameters','model','materialInput','material'}))
            snapshot=QuasiOpticalParameters(lastSetup.parameters,lastSetup.model,lastSetup.materialInput,lastSetup.material,'Retrieval setup snapshot');
            snapshot.Parameter="Setup snapshot - "+snapshot.Parameter;
            params=[params;snapshot];
        end
    end
    function text=truthSummary(value)
        if isscalar(value), text=string(mat2str(value,12));
        else, text=sprintf('%d frequency-dependent values; first %s; last %s. Full truth is in the data CSV.',numel(value),mat2str(value(1),10),mat2str(value(end),10)); end
    end
    function openMethod()
        guide=uifigure('Name','Free-space conversion methods: tables, tradeoffs and equations','Position',[100 60 1100 850],'Tag','QuasiOpticalRetrievalGuide');
        layout=uigridlayout(guide,[1 1]); layout.Padding=[0 0 0 0];
        html=uihtml(layout,'HTMLSource',methodPath); html.Data=struct('method',methodChoice.Value,'section','comparison');
    end
end
