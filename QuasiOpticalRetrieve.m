function r=QuasiOpticalRetrieve(fHz,s11,s21,thicknessM,options)
%QUASIOPTICALRETRIEVE Free-space material conversion, oblique TE/TM NRW.
% r = QuasiOpticalRetrieve(fHz,s11,s21,thicknessM,options)
% options.method: NRW (epsilon and mu), NIST iterative (epsilon, assumed
% mu=1, initialEpsilon required), or New non-iterative (epsilon, assumed mu=1).
% The code below implements NRW; the other methods dispatch to their helpers.
% Inputs must be complex, calibrated sample-plane reflection/transmission
% amplitudes of a homogeneous, reciprocal, isotropic air/slab/air sample.
% The exp(+i*omega*t) convention gives passive epsilon/mu with negative
% imaginary parts. This is NOT a tensor retrieval or antenna calibration.
%
% options.branch: integer added to the continuous propagation phase branch
%                 (default 0). Data alone do not fix the absolute branch.
% options.unwrapPhase: unwrap propagation phase in ascending frequency
%                      (default true). Use a sufficiently fine frequency grid.
% options.angleDeg: incidence in [0,90), cos(theta)>=1e-6; fixed per spectrum.
% options.polarization: TE or TM. NIST/new non-iterative remain normal only.
% options.minTransmission: amplitude floor (default 1e-8, user must set to
%                          their actual calibrated measurement noise floor).
% options.singularTolerance: NRW conditioning threshold (default 1e-10).
% options.passivityTolerance: dimensionless tolerance (default 1e-6).
%
% Based on R&S, Measurement of Dielectric Material Properties, Apr 2012,
% Annex 2, pp. 19-21, eqs. (1.1)-(1.6), specialized to zero cutoff/free space.
% Equivalent impedance algebra avoids dividing by S11 for matched slabs.
% Ill-conditioned half-wave points and opaque transmission return NaNs.
    if nargin<5, options=struct(); end
    if ~isstruct(options)||~isscalar(options), error('QuasiOptical:RetrievalOptions','Options must be a scalar struct.'); end
    if isfield(options,'method')
        if strcmpi(options.method,'NIST iterative')
            r=normalPropagationFields(QuasiOpticalNIST(fHz,s11,s21,thicknessM,options)); return
        elseif strcmpi(options.method,'New non-iterative')
            r=normalPropagationFields(QuasiOpticalNonIterative(fHz,s11,s21,thicknessM,options)); return
        end
    end
    validateattributes(fHz,{'numeric'},{'vector','real','finite','positive','nonempty'},mfilename,'fHz');
    validateattributes(s11,{'numeric'},{'vector','finite','nonempty'},mfilename,'s11');
    validateattributes(s21,{'numeric'},{'vector','finite','nonempty'},mfilename,'s21');
    validateattributes(thicknessM,{'numeric'},{'scalar','real','finite','positive'},mfilename,'thicknessM');
    if ~isstruct(options)||~isscalar(options), error('QuasiOptical:RetrievalOptions','Options must be a scalar struct.'); end
    defaults=struct('method','NRW','angleDeg',0,'polarization','TE','branch',0, ...
        'unwrapPhase',true,'minTransmission',1e-8,'singularTolerance',1e-10, ...
        'passivityTolerance',1e-6,'reconstructionTolerance',1e-6,'cutoffHz',0);
    names=fieldnames(options);
    for k=1:numel(names)
        if ~isfield(defaults,names{k}), error('QuasiOptical:RetrievalOptions','Unknown option: %s.',names{k}); end
        defaults.(names{k})=options.(names{k});
    end
    o=defaults;
    if ~strcmpi(o.method,'NRW'), error('QuasiOptical:RetrievalMethod','Choose a free-space method: NRW, NIST iterative, or New non-iterative.'); end
    validateattributes(o.angleDeg,{'numeric'},{'scalar','real','finite'});
    validateattributes(o.cutoffHz,{'numeric'},{'scalar','real','finite','nonnegative'});
    if o.angleDeg<0||o.angleDeg>=90||cosd(o.angleDeg)<1e-6||o.cutoffHz~=0
        error('QuasiOptical:RetrievalGeometry','NRW requires free space (cutoff = 0 Hz), 0 <= incidence < 90 deg and cos(theta) >= 1e-6. Grazing normalization is singular.');
    end
    if ~any(strcmpi(o.polarization,{'TE','TM'})), error('QuasiOptical:RetrievalPolarization','Polarization must be TE or TM.'); end
    o.polarization=upper(char(o.polarization)); c=cosd(o.angleDeg); transverse=sind(o.angleDeg)^2;
    validateattributes(o.branch,{'numeric'},{'scalar','real','finite','integer'});
    validateattributes(o.unwrapPhase,{'logical','numeric'},{'scalar','real','finite'});
    if ~any(o.unwrapPhase==[0 1]), error('QuasiOptical:RetrievalOptions','unwrapPhase must be true or false.'); end
    for field={'minTransmission','singularTolerance','passivityTolerance','reconstructionTolerance'}
        validateattributes(o.(field{1}),{'numeric'},{'scalar','real','finite','positive'});
    end
    fHz=fHz(:); s11=s11(:); s21=s21(:); count=numel(fHz);
    if numel(s11)~=count||numel(s21)~=count
        error('QuasiOptical:RetrievalSize','Frequency, S11 and S21 must contain the same number of samples.');
    end
    if any(diff(fHz)<=0), error('QuasiOptical:RetrievalFrequency','Frequencies must be strictly increasing with no duplicates.'); end
    blank=complex(nan(count,1),nan(count,1));
    r=struct('frequencyHz',fHz,'fHz',fHz,'s11',s11,'s21',s21, ...
        'epsilon',blank,'mu',blank,'n',blank,'q',blank,'kz',blank,'z',blank, ...
        'impedance',blank,'gamma',blank,'angleDeg',o.angleDeg,'polarization',o.polarization, ...
        'propagation',blank,'reconstructedS11',blank,'reconstructedS21',blank, ...
        'residual',nan(count,1),'branch',nan(count,1),'valid',false(count,1), ...
        'status',{repmat({'Not evaluated'},count,1)},'selectedBranch',o.branch, ...
        'thicknessM',thicknessM,'options',o,'method','Oblique-capable free-space NRW');
    r.notes={'Scalar relative permittivity and permeability of a homogeneous isotropic slab; no tensor components are inferred.'; ...
        'Input channels must be phase-resolved and calibrated/de-embedded to the two sample surfaces in air.'; ...
        'The complex time convention is exp(+i*omega*t); passive constitutive loss has negative imaginary part.'; ...
        'The integer branch is a user-selected assumption. Reconstruction residual cannot resolve the absolute phase branch.'; ...
        'Phase unwrapping assumes sufficiently close frequency samples; missing or coarse data can hide whole phase turns.'; ...
        'Transmission below the chosen amplitude floor and half-wave NRW singularities are excluded, not interpolated.'; ...
        'Effective dielectric loss includes conduction; epsilon and conductivity cannot be separated at one frequency.'; ...
        'q=kz/k0 is the normal propagation index; n is the bulk refractive index, with n^2=epsilon*mu=q^2+sin(theta)^2.'; ...
        'z is the polarization-specific slab/air wave impedance ratio: TE z=mu*cos(theta)/q; TM z=q/(epsilon*cos(theta)).'; ...
        'NRW interface algebra follows R&S Annex 2 pp.19-21; the oblique constitutive conversion retains transverse wave number in air.'};
    algebraOK=false(count,1);
    for k=1:count
        a=s11(k); b=s21(k);
        if abs(b)<=o.minTransmission
            r.status{k}='Transmission at/below amplitude floor: NRW unavailable'; continue
        end
        numerator=(1+a)^2-b^2; denominator=(1-a)^2-b^2;
        scale=max([1 abs((1+a)^2) abs((1-a)^2) abs(b^2)]);
        if min(abs([numerator denominator]))<=o.singularTolerance*scale
            r.status{k}='Ill-conditioned impedance / half-wave NRW singularity'; continue
        end
        z=sqrt(numerator/denominator);
        % The passive interface has nonnegative real wave impedance.
        if real(z)<0, z=-z; end
        if abs(z+1)<=o.singularTolerance
            r.status{k}='Singular interface impedance'; continue
        end
        g=(z-1)/(z+1); propagationDenominator=1-a*g;
        if abs(propagationDenominator)<=o.singularTolerance
            r.status{k}='Singular propagation-factor denominator'; continue
        end
        propagation=b/propagationDenominator;
        % For a purely reactive impedance, Re(z)=0 cannot choose its sign.
        % The forward evanescent solution must decay rather than grow.
        if abs(real(z))<=o.singularTolerance*max(1,abs(z)) && abs(propagation)>1
            alternative=-z;
            if abs(alternative+1)>o.singularTolerance
                alternativeGamma=(alternative-1)/(alternative+1);
                alternativeDenominator=1-a*alternativeGamma;
                if abs(alternativeDenominator)>o.singularTolerance
                    alternativePropagation=b/alternativeDenominator;
                    if abs(alternativePropagation)<abs(propagation)
                        z=alternative; g=alternativeGamma; propagation=alternativePropagation;
                    end
                end
            end
        end
        if ~isfinite(z)||~isfinite(propagation)||abs(propagation)<=realmin
            r.status{k}='Propagation factor is zero/nonfinite'; continue
        end
        r.impedance(k)=z; r.z(k)=z; r.gamma(k)=g; r.propagation(k)=propagation;
        algebraOK(k)=true;
    end
    % Do not unwrap across excluded regions: their missing phase is unknown.
    edges=diff([false;algebraOK;false]); starts=find(edges==1); stops=find(edges==-1)-1;
    for segment=1:numel(starts)
        indices=starts(segment):stops(segment); principal=angle(r.propagation(indices));
        phase=principal;
        if o.unwrapPhase, phase=unwrap(phase); end
        k0=2*pi*fHz(indices)/299792458;
        r.q(indices)=(-phase+2*pi*o.branch+1i*log(abs(r.propagation(indices))))./(k0*thicknessM);
        r.kz(indices)=k0.*r.q(indices);
        r.branch(indices)=round((principal-phase)/(2*pi))+o.branch;
        for k=indices
            q=r.q(k); z=r.z(k);
            if strcmp(o.polarization,'TE')
                mu=z*q/c;
                if abs(mu)<=o.singularTolerance*max([1 abs(q) abs(z)])
                    r.status{k}='Singular TE constitutive conversion (mu near zero)'; continue
                end
                epsilon=(q^2+transverse)/mu;
            else
                epsilon=q/(z*c);
                if abs(epsilon)<=o.singularTolerance*max([1 abs(q) abs(z)])
                    r.status{k}='Singular TM constitutive conversion (epsilon near zero)'; continue
                end
                mu=(q^2+transverse)/epsilon;
            end
            r.epsilon(k)=epsilon; r.mu(k)=mu;
            if ~all(isfinite([epsilon mu]))
                r.status{k}='Nonfinite retrieved constitutive conversion'; continue
            end
            n=sqrt(epsilon*mu);
            if real(n*conj(q))<0, n=-n; end
            r.n(k)=n;
            reconstructed=QuasiOpticalSlabRT(fHz(k),thicknessM,epsilon,mu,o.angleDeg,o.polarization);
            r.reconstructedS11(k)=reconstructed.r;
            r.reconstructedS21(k)=reconstructed.t;
            r.residual(k)=sqrt(abs(r.reconstructedS11(k)-s11(k))^2+abs(r.reconstructedS21(k)-s21(k))^2);
            constitutiveScale=max([1 abs(r.epsilon(k)) abs(r.mu(k))]);
            if ~all(isfinite([r.epsilon(k) r.mu(k) r.residual(k)]))
                r.status{k}='Nonfinite retrieved result';
            elseif r.residual(k)>o.reconstructionTolerance
                r.status{k}='Reconstructed channels exceed residual tolerance';
            elseif abs(s11(k))^2+abs(s21(k))^2>1+o.passivityTolerance || ...
                    abs(r.propagation(k))>1+o.passivityTolerance || ...
                    imag(r.epsilon(k))>o.passivityTolerance*constitutiveScale || ...
                    imag(r.mu(k))>o.passivityTolerance*constitutiveScale
                r.status{k}='Non-passive result under selected branch / calibration';
            else
                r.valid(k)=true;
                r.status{k}='Finite passive NRW result; absolute branch remains assumed';
                if segment>1
                    r.status{k}=[r.status{k} '; phase restarted after excluded data'];
                end
            end
        end
    end
end

function r=normalPropagationFields(r)
    r.q=r.n; r.kz=2*pi*r.fHz/299792458.*r.q;
    r.z=r.impedance; r.angleDeg=r.options.angleDeg;
    r.polarization=upper(char(r.options.polarization));
end
