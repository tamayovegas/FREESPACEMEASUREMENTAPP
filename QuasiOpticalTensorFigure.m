function fig=QuasiOpticalTensorFigure(symmetry,frame,plan)
%QUASIOPTICALTENSORFIGURE Exportable symbolic matrices and acquisition plan.
%   FIG is an invisible standard figure. Matrix entries remain letters;
%   numeric labels describe only the acquisition plan, not material values.
if nargin<1 || isempty(symmetry), symmetry='reciprocal'; end
if nargin<2 || isempty(frame), frame='material'; end
if nargin<3 || isempty(plan), plan=QuasiOpticalSweepPlan; end
symmetry=validatestring(symmetry,{'general','reciprocal','principal','isotropic'});
frame=validatestring(frame,{'material','laboratory'});
fig=figure('Visible','off','Color','w','Name','Symbolic material tensors', ...
    'NumberTitle','off','Position',[80 80 1600 1040],'Tag','QuasiOpticalTensorExport');
ax=axes('Parent',fig,'Position',[0 0 1 1],'XLim',[0 1],'YLim',[0 1], ...
    'Visible','off');hold(ax,'on');
text(ax,.04,.955,'SYMBOLIC MATERIAL TENSORS AND MEASUREMENT PLAN', ...
    'FontSize',22,'FontWeight','bold','Color',[.08 .25 .36],'Interpreter','none');
text(ax,.04,.92,sprintf('%s assumption | %s frame | letters are unassigned material properties', ...
    symmetry,frame),'FontSize',14,'Interpreter','none','Color',[.3 .4 .46]);
centers=[.19 .5 .81];symbols={'\epsilon','\mu','\sigma'};
titles={'Relative permittivity','Relative permeability','Conductivity (S/m)'};
letters='xyz';
for k=1:3
    x=centers(k); y=.69;
    text(ax,x,.855,titles{k},'FontSize',18,'HorizontalAlignment','center', ...
        'FontWeight','bold','Interpreter','none');
    for row=1:3
        for col=1:3
            symbol=symbols{k}; suffix='';
            if k<3, suffix='r,'; end
            if strcmp(symmetry,'isotropic')
                if row~=col, label='0'; elseif k<3, label=[symbol '_r']; else, label=symbol; end
            elseif strcmp(symmetry,'principal') && strcmp(frame,'material')
                if row~=col, label='0'; else
                    label=[symbol '_{' suffix letters(row) '}^{m}'];
                end
            else
                r=row;c=col;
                if (strcmp(symmetry,'reciprocal') || (strcmp(symmetry,'principal') && strcmp(frame,'laboratory'))) && r>c, r=col;c=row; end
                superscript='m';if strcmp(frame,'laboratory'),superscript='L';end
                label=[symbol '_{' suffix letters(r) letters(c) '}^{' superscript '}'];
            end
            text(ax,x+(col-2)*.077,y+(2-row)*.075,label, ...
                'Interpreter','tex','FontSize',23,'HorizontalAlignment','center');
        end
    end
    plot(ax,[x-.13 x-.14 x-.14 x-.13],[y+.13 y+.13 y-.12 y-.12], ...
        'Color',[.1 .25 .35],'LineWidth',2);
    plot(ax,[x+.13 x+.14 x+.14 x+.13],[y+.13 y+.13 y-.12 y-.12], ...
        'Color',[.1 .25 .35],'LineWidth',2);
end
text(ax,.5,.505,'D = \epsilon_0 \epsilon_r E     B = \mu_0 \mu_r H     J = \sigma E', ...
    'HorizontalAlignment','center','FontSize',18,'Interpreter','tex');
text(ax,.5,.465,'T^L = Q T^m Q^T,    Q = R_z(\gamma) R_y(\beta) R_x(\rho)', ...
    'HorizontalAlignment','center','FontSize',17,'Interpreter','tex');
plot(ax,[.04 .96],[.425 .425],'Color',[.75 .82 .86]);
c=plan.config;
text(ax,.04,.39,[c.geometry ' | ' c.scanKind],'FontSize',17, ...
    'FontWeight','bold','Interpreter','none');
rows={sprintf('Angle settings: %d (%g to %g deg); azimuth settings: %d (%g to %g deg)', ...
    c.angleCount,c.angleStartDeg,c.angleStopDeg,c.azimuthCount,c.azimuthStartDeg,c.azimuthStopDeg); ...
    sprintf('Known sample orientations: %d | frequency points per trace: %d',c.orientationCount,c.frequencyCount); ...
    sprintf('Scheduled geometric configurations: %d | polarization channels per block: %d', ...
    plan.nConfigurations,plan.nPolarizationChannels); ...
    sprintf('Sample scattering blocks per configuration: %d | complex trace acquisitions: %d', ...
    plan.nBlocks,plan.nTraceAcquisitions); ...
    sprintf('Complex frequency samples: %d | matched S11/S21 channel-pair samples: %d', ...
    plan.nComplexSamples,plan.nSParameterPairs); ...
    'Each epsilon/mu tensor has 9 general, 6 reciprocal, 3 diagonal or 1 isotropic unknown complex entries.'; ...
    'The same data constrain epsilon and mu jointly; counts do not prove unique tensor recovery.'};
for k=1:numel(rows)
    text(ax,.04,.352-(k-1)*.034,rows{k},'FontSize',13,'Interpreter','none', ...
        'Color',[.15 .28 .36]);
end
if strcmp(c.scanKind,'Rx observation arc')
    limitation='Rx observation arc is a scattering scan: off-specular data are excluded from Fresnel/NRW retrieval.';
elseif ~plan.scalarRetrievalEligible
    limitation='Only one scattering block is scheduled. Matched calibrated reflection and transmission are required for scalar NRW.';
else
    limitation='Scalar NRW: calibrated isotropic slab, known thickness, fixed TE/TM angle per spectrum. Cross-polarization needs a tensor model.';
end
text(ax,.04,.075,limitation,'FontSize',12,'FontWeight','bold','Color',[.62 .30 .06], ...
    'Interpreter','none');
text(ax,.04,.037,'Separate Tx/Rx reflection is typically instrument S21; convert to calibrated sample reflection S11 before retrieval.', ...
    'FontSize',12,'Interpreter','none','Color',[.3 .4 .46]);
end
