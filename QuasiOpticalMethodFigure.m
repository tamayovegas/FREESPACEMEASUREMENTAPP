function fig = QuasiOpticalMethodFigure
%QUASIOPTICALMETHODFIGURE Exportable free-space method tables and tradeoffs.
% Standard invisible figure for QuasiOpticalExportBundle; caller closes it.
% Qualitative comparison only. Source tables are paraphrased, free-space only.
W=1600; H=1360;
fig=figure('Visible','off','Color','white','Units','pixels', ...
    'Position',[0 0 W H],'MenuBar','none','ToolBar','none', ...
    'NumberTitle','off','Name','Free-space conversion methods');
ax=axes(fig,'Units','normalized','Position',[0 0 1 1], ...
    'XLim',[0 W],'YLim',[0 H],'YDir','reverse','Visible','off');
hold(ax,'on');
% Keep an explicit white canvas so tight exports retain the page margins.
rectangle(ax,'Position',[0 0 W H],'FaceColor','white','EdgeColor','white');
ink=[.08 .18 .29]; blue=[.10 .36 .58]; muted=[.31 .39 .47];
label(ax,40,26,'FREE-SPACE MATERIAL CHARACTERIZATION',12,blue,true);
label(ax,40,55,'S-parameter conversion methods',27,ink,true);
label(ax,40,104,'NRW: normal / oblique TE or TM | NIST and new non-iterative: normal only | calibrated complex channels',14,muted,false);
label(ax,40,137,'Conversion techniques and material properties',17,ink,true);
rows={ ...
    'Conversion technique','Complex S-parameters','Material properties'; ...
    'NRW',sprintf('S11, S21\nor S11, S21, S12, S22'),sprintf('εᵣ and μᵣ retrieved'); ...
    'NIST iterative',sprintf('S11, S21\nor S11, S21, S12, S22'),sprintf('εᵣ retrieved\nμᵣ = 1 assumed'); ...
    'New non-iterative',sprintf('S11, S21\nor S11, S21, S12, S22'),sprintf('εᵣ retrieved\nμᵣ = 1 assumed')};
drawTable(ax,40,169,[345 595 580],rows,[48 63 63 63],15);
label(ax,40,421,'Material / setup comparison - free-space rows from source Table 4',17,ink,true);
rows={ ...
    sprintf('Source material / geometry'),'Setup','Conversion method','Speed',sprintf('Qualitative\naccuracy'); ...
    sprintf('High-temperature solids\nLarge, flat; nonmagnetic'),'Free space','NIST iterative','Slow','Good'; ...
    sprintf('High-temperature solids\nLarge, flat; nonmagnetic'),'Free space','New non-iterative','Fast','Good'; ...
    sprintf('High-temperature solids\nLarge, flat; nonmagnetic'),'Free space','NRW','Fast','Medium'};
drawTable(ax,40,454,[460 190 370 180 320],rows,[62 70 70 70],14);
label(ax,40,742,sprintf(['Speed and accuracy are qualitative labels from the source, not uncertainty bounds or guarantees. Actual uncertainty depends on\n' ...
    'calibration, thickness, sample properties, beam coverage and model validity. The app applies no temperature compensation.']),12,muted,false);
rectangle(ax,'Position',[40 805 1520 58],'FaceColor',[1 .97 .91],'EdgeColor',[.87 .76 .54],'LineWidth',1);
label(ax,54,817,sprintf(['SCL excluded: the source uses a short-circuited coaxial / waveguide fixture, not an unbacked free-space slab.\n' ...
    'A metal-backed free-space reflection inversion requires a separate model. Resonator, probe and guided-fixture methods are excluded.']),12,[.42 .31 .15],false);
label(ax,40,887,'Advantages and disadvantages - summarized for free space',17,ink,true);
methodNames={'NRW','NIST iterative','New non-iterative'};
outputs={'εᵣ and μᵣ retrieved','εᵣ retrieved; μᵣ = 1 assumed','εᵣ retrieved; μᵣ = 1 assumed'};
pros={ ...
    {'Fast, direct, non-iterative.','Retrieves both εᵣ and μᵣ.','Allows a magnetic scalar response.'}, ...
    {'Fewer unknowns with μᵣ fixed.','Avoids separate NRW impedance division.','Supports low-loss / longer slabs.'}, ...
    {'Fast propagation-based calculation.','No iterative initial estimate needed.','Avoids final independent impedance division.'}};
cons={ ...
    {'Half-wave resonances can be ill-conditioned.','Phase branch needs justification.','Weak transmission and errors limit retrieval.'}, ...
    {'Requires a nonmagnetic assumption.','Needs an initial guess and convergence.','Wrong branches or convergence failure remain.'}, ...
    {'Requires a nonmagnetic assumption.','Logarithmic phase ambiguity remains.','Interface extraction can remain ill-conditioned.'}};
cardW=490; cardY=923; cardH=346;
for k=1:3
    x=40+(k-1)*515;
    rectangle(ax,'Position',[x cardY cardW cardH],'FaceColor',[.975 .984 .993],'EdgeColor',[.72 .81 .88],'LineWidth',1);
    rectangle(ax,'Position',[x cardY cardW 5],'FaceColor',blue,'EdgeColor','none');
    label(ax,x+16,cardY+18,methodNames{k},17,ink,true);
    label(ax,x+16,cardY+49,outputs{k},11,muted,false);
    label(ax,x+16,cardY+80,'Advantages',13,[.15 .39 .27],true);
    y=cardY+108;
    for b=1:3
        lines=wrapText(pros{k}{b},49);
        label(ax,x+18,y,['• ' strjoin(lines,newline)],11.5,ink,false);
        y=y+numel(lines)*17+9;
    end
    label(ax,x+16,cardY+201,'Disadvantages',13,[.52 .31 .10],true);
    y=cardY+229;
    for b=1:3
        lines=wrapText(cons{k}{b},49);
        label(ax,x+18,y,['• ' strjoin(lines,newline)],11.5,ink,false);
        y=y+numel(lines)*17+8;
    end
end
label(ax,40,1292,sprintf(['Source: Rohde & Schwarz, Measurement of Dielectric Material Properties (April 2012), Tables 3/4, pp. 11/16; method summaries pp. 12-15.\n' ...
    'The combined NIST / new non-iterative free-space row is separated above. NRW can also retrieve magnetic scalars under its model assumptions.']),11,muted,false);
drawnow;
end

function drawTable(ax,x,y,widths,rows,heights,fontSize)
ink=[.08 .18 .29]; edge=[.45 .58 .68];
for row=1:size(rows,1)
    if row==1, face=[.90 .95 .99]; else, face=[1 1 1]; end
    left=x;
    for col=1:numel(widths)
        rectangle(ax,'Position',[left y widths(col) heights(row)], ...
            'FaceColor',face,'EdgeColor',edge,'LineWidth',1);
        str=rows{row,col};
        isHeader=(row==1);
        label(ax,left+14,y+12,str,fontSize,ink,isHeader);
        left=left+widths(col);
    end
    y=y+heights(row);
end
end

function label(ax,x,y,str,fontSize,color,bold)
weight='normal'; if bold, weight='bold'; end
text(ax,x,y,str,'Interpreter','none','FontName','Helvetica','FontSize',fontSize, ...
    'FontWeight',weight,'Color',color,'VerticalAlignment','top','Clipping','off');
end

function lines=wrapText(str,maximum)
words=regexp(str,'\s+','split'); lines={}; current='';
for k=1:numel(words)
    if ~isempty(current) && numel(current)+numel(words{k})+1>maximum
        lines{end+1}=current; current=''; %#ok<AGROW>
    end
    if isempty(current),current=words{k};else,current=[current ' ' words{k}];end %#ok<AGROW>
end
if ~isempty(current),lines{end+1}=current;end
end
