function tests=testQuasiOpticalExports
    tests=functiontests(localfunctions);
end

function testMetadataUsesActualConfigurationAndSI(t)
    [p,~,d,~]=configuration();
    p.fLowGHz=1.3; p.fGHz=13.7; p.fHighGHz=36.8;
    p.theta=42; p.yaw=17; d.thicknessMM=7.25;
    m=QuasiOpticalModel(p); s=QuasiOpticalMaterial(p,m,d);
    records=QuasiOpticalParameters(p,m,d,s,'Rotated sample');
    verifyEqual(t,records.Properties.VariableNames,{'Parameter','Symbol','Value','Unit','Description'});
    verifyEqual(t,lookup(records,'Frequency'),"13700000000");
    verifyEqual(t,lookup(records,'Low frequency'),"1300000000");
    verifyEqual(t,lookup(records,'High frequency'),"36800000000");
    verifyEqual(t,lookup(records,'Field sweep frequency start'),"1300000000");
    verifyEqual(t,lookup(records,'Field sweep frequency end'),"36800000000");
    verifyEqual(t,lookup(records,'Normal sample thickness'),"0.00725");
    verifyEqual(t,str2double(lookup(records,'Actual incidence angle')),deg2rad(m.incidence),'RelTol',1e-10);
    verifyEqual(t,str2double(lookup(records,'Horn layout angle')),deg2rad(p.theta),'RelTol',1e-10);
    verifyEqual(t,str2double(lookup(records,'Power intercepted at sample')),m.sampleFraction,'RelTol',1e-10);
    verifyEqual(t,lookup(records,'Exported graphic'),"Rotated sample");
    verifyEqual(t,records.Unit(records.Parameter=="Horn layout angle"),"rad");
    verifyEqual(t,records.Unit(records.Parameter=="Normal sample thickness"),"m");
    verifyTrue(t,all(strlength(records.Description)>0));
end

function testBundleProducesMatchingNamesAndPreservesTable(t)
    folder=tempname; mkdir(folder); cleanFolder=onCleanup(@() rmdir(folder,'s'));
    [p,m,d,s]=configuration(); records=QuasiOpticalParameters(p,m,d,s,'Geometry snapshot');
    f=figure('Visible','off'); cleanFigure=onCleanup(@() close(f));
    ax=axes(f); plot(ax,[0 1],[2 3]); title(ax,'Geometry snapshot');
    paths=QuasiOpticalExportBundle(ax,fullfile(folder,'angle_snapshot.png'),records,'Geometry snapshot');
    verifyEqual(t,paths.image,fullfile(folder,'angle_snapshot.png'));
    verifyEqual(t,paths.csv,fullfile(folder,'angle_snapshot.csv'));
    verifyEqual(t,paths.parametersImage,fullfile(folder,'angle_snapshot_parameters.png'));
    verifyTrue(t,isfile(paths.image)); verifyTrue(t,isfile(paths.csv)); verifyTrue(t,isfile(paths.parametersImage));
    recovered=readExport(paths.csv);
    verifyEqual(t,height(recovered),height(records));
    verifyEqual(t,recovered.Parameter,records.Parameter);
    verifyEqual(t,lookup(recovered,'Frequency'),lookup(records,'Frequency'));
    info=imfinfo(paths.parametersImage);
    verifyGreaterThan(t,info.Width,1000); verifyGreaterThan(t,info.Height,1000);
    verifyReadableImage(t,paths.image,false);
    verifyReadableImage(t,paths.parametersImage,true);
    verifyEqual(t,numel(dir(fullfile(folder,'*.png'))),2);
end

function testCurrentSnapshotOverwritesPreviousSnapshot(t)
    folder=tempname; mkdir(folder); cleanFolder=onCleanup(@() rmdir(folder,'s'));
    [p,m,d,s]=configuration(); before=QuasiOpticalParameters(p,m,d,s,'Before');
    before=before(1:12,:);
    f=figure('Visible','off'); cleanFigure=onCleanup(@() close(f));
    ax=axes(f); plot(ax,[0 1],[0 1]);
    paths=QuasiOpticalExportBundle(ax,fullfile(folder,'replaced.csv'),before,'Before');
    p.fGHz=22; m=QuasiOpticalModel(p); s=QuasiOpticalMaterial(p,m,d);
    after=QuasiOpticalParameters(p,m,d,s,'After'); after=after(1:12,:);
    QuasiOpticalExportBundle(ax,fullfile(folder,'replaced.csv'),after,'After');
    recovered=readExport(paths.csv);
    verifyEqual(t,lookup(recovered,'Frequency'),"22000000000");
    verifyEqual(t,lookup(recovered,'Exported graphic'),"After");
    items=dir(folder); verifyEqual(t,sum(~[items.isdir]),3);
end

function testLongDescriptionsAndManyRowsRemainInCSV(t)
    folder=tempname; mkdir(folder); cleanFolder=onCleanup(@() rmdir(folder,'s'));
    names="Parameter "+string((1:80).');
    description=repmat("A deliberately long description explains this parameter with words, equations, units, and the assumption that it is retained in full. ",80,1);
    description(47)=description(47)+join(repmat("More detail must wrap without truncation. ",1,15),"");
    records=table(names,repmat("alpha",80,1),string((1:80).'),repmat("m",80,1),description, ...
        'VariableNames',{'Parameter','Symbol','Value','Unit','Description'});
    f=figure('Visible','off'); cleanFigure=onCleanup(@() close(f));
    ax=axes(f); plot(ax,[0 1],[0 1]);
    paths=QuasiOpticalExportBundle(ax,fullfile(folder,'long_metadata'),records,'Long parameter record');
    recovered=readExport(paths.csv);
    verifyEqual(t,recovered.Description,records.Description);
    verifyEqual(t,recovered.Parameter(end),"Parameter 80");
    verifyTrue(t,isfile(paths.parametersImage));
    verifyReadableImage(t,paths.parametersImage,true);
end

function testLongSnapshotUsesReadableContinuationTiles(t)
    folder=tempname; mkdir(folder); cleanFolder=onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
    snapshot=string(jsonencode(struct('configuration',repmat('0123456789abcdef',1,220))));
    records=table(["Setup snapshot";"Final retained parameter"],["setup";"omega"],[snapshot;"62831853071.8"], ...
        ["JSON";"rad/s"],["Complete reproducible setup with a long unbroken JSON value.";"Last source record must remain visible after continuation panels."], ...
        'VariableNames',{'Parameter','Symbol','Value','Unit','Description'});
    f=figure('Visible','off'); cleanFigure=onCleanup(@() close(f)); %#ok<NASGU>
    ax=axes(f); plot(ax,[0 1],[0 1]);
    paths=QuasiOpticalExportBundle(ax,fullfile(folder,'continuation'),records,'Long JSON snapshot');
    recovered=readExport(paths.csv);
    verifyEqual(t,recovered.Value(1),snapshot);
    verifyEqual(t,recovered.Parameter(end),"Final retained parameter");
    verifyReadableImage(t,paths.parametersImage,true);
    pixels=imread(paths.parametersImage);
    verifyGreaterThan(t,size(pixels,1),2000);
    % The final tile is populated, rather than losing rows after stitching.
    finalPanel=pixels(floor(size(pixels,1)/2):end,:,:);
    verifyGreaterThan(t,nnz(any(finalPanel<180,3))/size(finalPanel,1)/size(finalPanel,2),.001);
end

function testHiddenUITabAxesExportRestoresSelection(t)
    folder=tempname; mkdir(folder); cleanFolder=onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
    f=uifigure('Visible','off','Position',[50 50 800 600]); cleanFigure=onCleanup(@() close(f)); %#ok<NASGU>
    group=uitabgroup(f,'Position',[0 0 800 600]); first=uitab(group,'Title','Selected'); second=uitab(group,'Title','Exported');
    ax=uiaxes(second,'Position',[50 50 650 450]); plot(ax,1:4,[2 5 3 7]); title(ax,'Hidden-tab export');
    group.SelectedTab=first;
    records=table("Plot","value","example","1","A hidden-tab axes must export its plotted content.", ...
        'VariableNames',{'Parameter','Symbol','Value','Unit','Description'});
    paths=QuasiOpticalExportBundle(ax,fullfile(folder,'hidden_tab'),records,'Hidden-tab plot');
    verifyEqual(t,group.SelectedTab,first);
    verifyReadableImage(t,paths.image,false);
end

function verifyReadableImage(t,path,isTable)
    pixels=imread(path);
    row=round(linspace(1,size(pixels,1),min(size(pixels,1),500)));
    col=round(linspace(1,size(pixels,2),min(size(pixels,2),500)));
    pixels=pixels(row,col,:);
    white=all(pixels>240,3); ink=any(pixels<180,3);
    requiredWhite=.01; if isTable, requiredWhite=.30; end
    verifyGreaterThan(t,mean(white(:)),requiredWhite);
    verifyGreaterThan(t,mean(ink(:)),.0001);
end

function records=readExport(path)
    names={'Parameter','Symbol','Value','Unit','Description'};
    options=delimitedTextImportOptions('NumVariables',5,'Delimiter',',', ...
        'DataLines',[2 Inf],'VariableNames',names,'VariableTypes',repmat({'string'},1,5));
    records=readtable(path,options);
end

function value=lookup(records,name)
    value=records.Value(records.Parameter==string(name));
end

function [p,m,d,s]=configuration()
    p=struct('fGHz',10,'D',.12,'R',1.2,'theta',30,'width',.5,'height',.5, ...
        'psi',0,'lensPosition',.2,'focal',.35,'useLens',false,'yaw',0,'pitch',0,'roll',0,'mode','Reflection');
    m=QuasiOpticalModel(p); d=QuasiOpticalMaterialPreset('Lossy absorber (example)');
    s=QuasiOpticalMaterial(p,m,d);
end
