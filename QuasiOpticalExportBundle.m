function paths = QuasiOpticalExportBundle(graphicsObject,basePath,parameterTable,plotTitle)
%QUASIOPTICALEXPORTBUNDLE Save a plot and matching human-readable metadata.
% paths = QuasiOpticalExportBundle(axOrFigure,basePath,parameterTable,title)
% produces basePath.png, basePath.csv and basePath_parameters.png. A known
% image/CSV/PDF extension is removed from basePath before adding the suffixes.
% parameterTable has Parameter, Symbol, Value, Unit and Description columns.
% The helper has no dialogs. Generate every file before replacing a bundle.
    if nargin<4, plotTitle='Quasi-optical export'; end
    if ~isscalar(graphicsObject) || ~isgraphics(graphicsObject)
        error('QuasiOptical:ExportGraphics','Supply a valid axes or figure handle.');
    end
    required={'Parameter','Symbol','Value','Unit','Description'};
    if ~istable(parameterTable) || ~all(ismember(required,parameterTable.Properties.VariableNames))
        error('QuasiOptical:ExportTable','Parameter table must contain Parameter, Symbol, Value, Unit and Description.');
    end
    if height(parameterTable)==0
        error('QuasiOptical:ExportTable','Parameter table must contain at least one row.');
    end
    parameterTable=parameterTable(:,required);
    for k=1:numel(required)
        name=required{k}; parameterTable.(name)=string(parameterTable.(name));
        if size(parameterTable.(name),2)~=1
            error('QuasiOptical:ExportTable','Each metadata column must contain one value per row.');
        end
        parameterTable.(name)(ismissing(parameterTable.(name)))="";
    end
    basePath=char(string(basePath)); plotTitle=char(string(plotTitle));
    if isempty(strtrim(basePath))
        error('QuasiOptical:ExportPath','Supply a nonempty output file name.');
    end
    [folder,stem,extension]=fileparts(basePath);
    known={'.png','.jpg','.jpeg','.tif','.tiff','.csv','.pdf','.svg','.fig'};
    if ~ismember(lower(extension),known), stem=[stem extension]; end
    if isempty(stem), error('QuasiOptical:ExportPath','Output file name has no stem.'); end
    if isempty(folder), folder=pwd; end
    if ~isfolder(folder)
        [ok,message]=mkdir(folder);
        if ~ok, error('QuasiOptical:ExportPath','Cannot create output folder: %s',message); end
    end
    basePath=fullfile(folder,stem);
    paths=struct('image',[basePath '.png'],'csv',[basePath '.csv'], ...
        'parametersImage',[basePath '_parameters.png']);
    temporaryStem=tempname(folder);
    temporaryFiles={[temporaryStem '.png'],[temporaryStem '.csv'],[temporaryStem '_parameters.png']};
    cleaner=onCleanup(@() removeTemporary(temporaryFiles));
    tabCleanup=revealContainingTabs(graphicsObject); %#ok<NASGU>
    drawnow;
    try
        exportgraphics(graphicsObject,temporaryFiles{1},'Resolution',300,'BackgroundColor','white');
    catch exportError
        if isa(graphicsObject,'matlab.ui.Figure')
            try
                exportapp(graphicsObject,temporaryFiles{1});
            catch
                rethrow(exportError);
            end
        else
            rethrow(exportError);
        end
    end
    assertRenderedImage(temporaryFiles{1},false);
    writetable(parameterTable,temporaryFiles{2},'Encoding','UTF-8');
    renderParameterTable(parameterTable,plotTitle,temporaryFiles{3});
    outputs={paths.image,paths.csv,paths.parametersImage};
    for k=1:numel(outputs)
        [ok,message]=movefile(temporaryFiles{k},outputs{k},'f');
        if ~ok, error('QuasiOptical:ExportWrite','Cannot save %s: %s',outputs{k},message); end
    end
end

function renderParameterTable(records,plotTitle,path)
% Wrap every column and paginate into two columns of repeated-header panels.
% Render bounded tiles before CPU stitching. A very tall offscreen figure
% can exceed a graphics framebuffer limit and silently produce a black PNG.
% The final single PNG contains every row, without a giant render target.
    widths=[230 120 205 85 460]; panelWidth=sum(widths); gutter=28;
    fontSize=10; lineHeight=19; rowPadding=15; bodyBudget=1120;
    characterWidths=[29 15 25 10 60];
    count=height(records); wrapped=cell(count,5); heights=zeros(count,1);
    for row=1:count
        for column=1:5
            wrapped{row,column}=wrapText(records{row,column},characterWidths(column));
        end
        lineCounts=cellfun(@numel,wrapped(row,:));
        heights(row)=max(36,max(lineCounts)*lineHeight+rowPadding);
    end
    % Split exceptionally long cells across continuation rows so even one
    % large JSON snapshot cannot make an unbounded graphics render target.
    maxLines=floor((bodyBudget-rowPadding)/lineHeight)-1;
    visibleRows=cell(0,5); visibleHeights=zeros(0,1); sourceRows=zeros(0,1);
    for row=1:count
        numberLines=max(cellfun(@numel,wrapped(row,:)));
        for firstLine=1:maxLines:numberLines
            chunk=cell(1,5);
            for column=1:5
                lines=wrapped{row,column}; lastLine=min(firstLine+maxLines-1,numel(lines));
                if firstLine<=numel(lines), chunk{column}=lines(firstLine:lastLine); else, chunk{column}={''}; end
            end
            if firstLine>1
                chunk{1}=[{sprintf('(record %d continued)',row)} chunk{1}];
            end
            visibleRows(end+1,:)=chunk; %#ok<AGROW>
            visibleHeights(end+1,1)=max(36,max(cellfun(@numel,chunk))*lineHeight+rowPadding); %#ok<AGROW>
            sourceRows(end+1,1)=row; %#ok<AGROW>
        end
    end
    wrapped=visibleRows; heights=visibleHeights;
    groups={}; first=1; used=0;
    for row=1:numel(heights)
        if used+heights(row)>bodyBudget && row>first
            groups{end+1}=first:row-1; %#ok<AGROW>
            first=row; used=0;
        end
        used=used+heights(row);
    end
    groups{end+1}=first:numel(heights);
    numberPanels=numel(groups); columns=min(2,numberPanels); panelRows=ceil(numberPanels/columns);
    panelHeight=bodyBudget+70; titleHeight=100; margin=30;
    tileWidth=panelWidth+2*margin;
    tileHeight=titleHeight+panelHeight+margin;
    outputFigure=figure('Visible','off','Color','white','Units','pixels', ...
        'Position',[0 0 tileWidth tileHeight],'MenuBar','none','ToolBar','none', ...
        'NumberTitle','off','Name','Export parameters');
    cleaner=onCleanup(@() close(outputFigure));
    temporaryTile=[tempname '.png'];
    tileCleanup=onCleanup(@() removeTemporary({temporaryTile})); %#ok<NASGU>
    set(outputFigure,'PaperUnits','inches','PaperPosition',[0 0 tileWidth/100 tileHeight/100], ...
        'PaperSize',[tileWidth/100 tileHeight/100]);
    headings=records.Properties.VariableNames;
    canvas=[];
    for panel=1:numberPanels
        clf(outputFigure);
        ax=axes(outputFigure,'Units','normalized','Position',[0 0 1 1], ...
            'XLim',[0 tileWidth],'YLim',[0 tileHeight],'YDir','reverse','Visible','off');
        hold(ax,'on');
        titleLines=wrapText(string(plotTitle),floor(tileWidth/15));
        text(ax,margin,20,strjoin(titleLines,newline),'Interpreter','none','FontName','Helvetica', ...
            'FontSize',16,'FontWeight','bold','Color',[.10 .22 .34],'VerticalAlignment','top');
        text(ax,margin,65,sprintf('Configuration and result parameters | %d rows | SI units unless marked',count), ...
            'Interpreter','none','FontName','Helvetica','FontSize',11,'Color',[.30 .39 .48], ...
            'VerticalAlignment','top');
        left=margin; top=titleHeight;
        text(ax,left,top,sprintf('Parameters %d-%d of %d | panel %d of %d', ...
            sourceRows(groups{panel}(1)),sourceRows(groups{panel}(end)),count,panel,numberPanels), ...
            'Interpreter','none','FontName','Helvetica','FontSize',10,'FontWeight','bold', ...
            'Color',[.2 .3 .4],'VerticalAlignment','top');
        y=top+26; headerHeight=33;
        rectangle(ax,'Position',[left y panelWidth headerHeight],'FaceColor',[.12 .27 .42],'EdgeColor','none');
        x=left;
        for column=1:5
            text(ax,x+9,y+8,headings{column},'Interpreter','none','FontName','Helvetica', ...
                'FontSize',fontSize,'FontWeight','bold','Color','white','VerticalAlignment','top');
            x=x+widths(column);
        end
        y=y+headerHeight;
        for row=groups{panel}
            if mod(sourceRows(row),2)==0, background=[.946 .962 .977]; else, background=[1 1 1]; end
            rectangle(ax,'Position',[left y panelWidth heights(row)],'FaceColor',background,'EdgeColor',[.83 .88 .92]);
            x=left;
            for column=1:5
                text(ax,x+9,y+7,strjoin(wrapped{row,column},newline),'Interpreter','none', ...
                    'FontName','Helvetica','FontSize',fontSize,'Color',[.13 .20 .27], ...
                    'VerticalAlignment','top','Clipping','off');
                x=x+widths(column);
            end
            y=y+heights(row);
        end
        % PRINT uses a bounded paper-sized target with predictable pixels;
        % stitching this RGB result needs no Image Processing Toolbox.
        drawnow;
        print(outputFigure,temporaryTile,'-dpng','-r150');
        assertRenderedImage(temporaryTile,true);
        pixels=imread(temporaryTile);
        if isempty(canvas)
            [tilePixelHeight,tilePixelWidth,~]=size(pixels);
            gutterPixels=round(gutter*1.5);
            canvas=repmat(uint8(255),[panelRows*tilePixelHeight+(panelRows-1)*gutterPixels, ...
                columns*tilePixelWidth+(columns-1)*gutterPixels,3]);
        end
        firstY=floor((panel-1)/columns)*(tilePixelHeight+gutterPixels)+1;
        firstX=mod(panel-1,columns)*(tilePixelWidth+gutterPixels)+1;
        canvas(firstY:firstY+tilePixelHeight-1,firstX:firstX+tilePixelWidth-1,:)=pixels;
    end
    imwrite(canvas,path,'png');
    assertRenderedImage(path,true);
end

function cleanup=revealContainingTabs(object)
% A UIAxes can belong to a hidden tab when exporting a batch of results.
% Temporarily reveal its tab ancestry, then restore the user's selection.
    groups={}; selected={}; current=object;
    while isgraphics(current) && isprop(current,'Parent')
        if isa(current,'matlab.ui.container.Tab')
            group=current.Parent;
            groups{end+1}=group; selected{end+1}=group.SelectedTab; %#ok<AGROW>
            group.SelectedTab=current;
        end
        current=current.Parent;
        if isempty(current), break; end
    end
    cleanup=onCleanup(@restore);
    function restore()
        for k=numel(groups):-1:1
            if isvalid(groups{k}) && isvalid(selected{k}), groups{k}.SelectedTab=selected{k}; end
        end
    end
end

function assertRenderedImage(path,isTable)
% Reject a black framebuffer with a thin white border, as well as blank
% white images. Inspect image pixels, not just successful file creation.
    pixels=imread(path);
    if ndims(pixels)==2, pixels=repmat(pixels,1,1,3); end
    if isa(pixels,'uint16'), pixels=uint8(double(pixels)/257); end
    row=round(linspace(1,size(pixels,1),min(size(pixels,1),500)));
    column=round(linspace(1,size(pixels,2),min(size(pixels,2),500)));
    sample=double(pixels(row,column,1:3));
    white=all(sample>240,3); ink=any(sample<180,3);
    requiredWhite=.01;
    if isTable, requiredWhite=.30; end
    if mean(white(:))<requiredWhite || mean(ink(:))<.0001
        error('QuasiOptical:ExportBlank','Graphics rendering produced a blank or black image. The export was not saved: %s',path);
    end
end

function lines=wrapText(value,maximum)
    value=char(string(value));
    paragraphs=regexp(value,'\r\n|\n|\r','split'); lines={};
    for paragraph=1:numel(paragraphs)
        words=regexp(strtrim(paragraphs{paragraph}),'\s+','split'); current='';
        for k=1:numel(words)
            word=words{k};
            if isempty(word), continue; end
            if ~isempty(current) && numel(current)+numel(word)+1>maximum
                lines{end+1}=current; current=''; %#ok<AGROW>
            end
            while numel(word)>maximum
                if ~isempty(current), lines{end+1}=current; current=''; end %#ok<AGROW>
                lines{end+1}=word(1:maximum); word=word(maximum+1:end); %#ok<AGROW>
            end
            if isempty(current), current=word; else, current=[current ' ' word]; end %#ok<AGROW>
        end
        if ~isempty(current), lines{end+1}=current; elseif isempty(words) || isempty(words{1}), lines{end+1}=''; end %#ok<AGROW>
    end
    if isempty(lines), lines={''}; end
end

function removeTemporary(paths)
    for k=1:numel(paths)
        if isfile(paths{k}), delete(paths{k}); end
    end
end
