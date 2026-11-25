function r=QuasiOpticalNIST(fHz,s11,s21,thicknessM,options)
%QUASIOPTICALNIST Free-space NIST iterative, nonmagnetic scalar retrieval.
% r=QuasiOpticalNIST(fHz,s11,s21,thicknessM,options)
% Implements the complex determinant equation in R&S, Measurement of
% Dielectric Material Properties, Annex 4 pp.24-26, equation (2.8), using
% finite-difference Newton iteration in real(epsilon),imag(epsilon).
% Free space: cutoff=0. Sample-face planes: L_air=L. For a reciprocal,
% symmetric air/slab/air specimen, S22=S11 and S12=S21, hence
%   F = S11^2-S21^2 - (Gamma^2-P^2)/(1-Gamma^2*P^2),
%   Gamma=(1-sqrt(epsilon))/(1+sqrt(epsilon)),
%   P=exp(-1i*k0*sqrt(epsilon)*L).
% Mu_r=1 is an ASSUMPTION and is never retrieved by this method.
% options.initialEpsilon is mandatory: a finite complex scalar initial
% guess. The root depends on this guess; frequency continuation uses the
% last accepted solution. The NRW integer branch option must be zero.
% No Optimization Toolbox is required. exp(+i*omega*t) convention.
    if nargin<5, options=struct(); end
    validateattributes(fHz,{'numeric'},{'vector','real','finite','positive','nonempty'},mfilename,'fHz');
    validateattributes(s11,{'numeric'},{'vector','finite','nonempty'},mfilename,'s11');
    validateattributes(s21,{'numeric'},{'vector','finite','nonempty'},mfilename,'s21');
    validateattributes(thicknessM,{'numeric'},{'scalar','real','finite','positive'},mfilename,'thicknessM');
    if ~isstruct(options)||~isscalar(options), error('QuasiOptical:RetrievalOptions','Options must be a scalar struct.'); end
    if ~isfield(options,'initialEpsilon')
        error('QuasiOptical:RetrievalInitialGuess','NIST iterative requires options.initialEpsilon; the selected root depends on this complex initial guess.');
    end
    defaults=struct('method','NIST iterative','angleDeg',0,'polarization','TE', ...
        'branch',0,'unwrapPhase',true,'minTransmission',1e-8,'singularTolerance',1e-10, ...
        'passivityTolerance',1e-6,'reconstructionTolerance',1e-6,'cutoffHz',0, ...
        'initialEpsilon',options.initialEpsilon,'maxIterations',80,'tolerance',1e-9);
    names=fieldnames(options);
    for k=1:numel(names)
        if ~isfield(defaults,names{k}), error('QuasiOptical:RetrievalOptions','Unknown option: %s.',names{k}); end
        defaults.(names{k})=options.(names{k});
    end
    o=defaults;
    if ~strcmpi(o.method,'NIST iterative'), error('QuasiOptical:RetrievalMethod','This function implements NIST iterative only.'); end
    o.method='NIST iterative';
    validateattributes(o.angleDeg,{'numeric'},{'scalar','real','finite'});
    validateattributes(o.cutoffHz,{'numeric'},{'scalar','real','finite','nonnegative'});
    if abs(o.angleDeg)>1e-10 || o.cutoffHz~=0
        error('QuasiOptical:RetrievalGeometry','NIST iterative here requires normal-incidence free space, zero cutoff and sample-face reference planes.');
    end
    if ~any(strcmpi(o.polarization,{'TE','TM'})), error('QuasiOptical:RetrievalPolarization','Polarization must be TE or TM; they are equivalent at normal incidence.'); end
    validateattributes(o.branch,{'numeric'},{'scalar','real','finite','integer'});
    if o.branch~=0, error('QuasiOptical:RetrievalBranch','NIST iterative uses initialEpsilon and frequency continuation, not the NRW integer branch; set branch=0.'); end
    validateattributes(o.unwrapPhase,{'logical','numeric'},{'scalar','real','finite'});
    if ~any(o.unwrapPhase==[0 1]), error('QuasiOptical:RetrievalOptions','unwrapPhase must be true or false.'); end
    validateattributes(o.initialEpsilon,{'numeric'},{'scalar','finite'});
    validateattributes(o.maxIterations,{'numeric'},{'scalar','real','finite','positive','integer'});
    for field={'minTransmission','singularTolerance','passivityTolerance','reconstructionTolerance','tolerance'}
        validateattributes(o.(field{1}),{'numeric'},{'scalar','real','finite','positive'});
    end
    fHz=fHz(:); s11=s11(:); s21=s21(:); count=numel(fHz);
    if numel(s11)~=count||numel(s21)~=count
        error('QuasiOptical:RetrievalSize','Frequency, S11 and S21 must contain the same number of samples.');
    end
    if any(diff(fHz)<=0), error('QuasiOptical:RetrievalFrequency','Frequencies must be strictly increasing with no duplicates.'); end
    blank=complex(nan(count,1),nan(count,1));
    r=struct('frequencyHz',fHz,'fHz',fHz,'s11',s11,'s21',s21, ...
        'epsilon',blank,'mu',ones(count,1),'n',blank,'impedance',blank,'gamma',blank, ...
        'propagation',blank,'reconstructedS11',blank,'reconstructedS21',blank, ...
        'residual',nan(count,1),'branch',nan(count,1),'valid',false(count,1), ...
        'status',{repmat({'Not evaluated'},count,1)},'selectedBranch',NaN, ...
        'thicknessM',thicknessM,'options',o,'method','Normal-incidence free-space NIST iterative', ...
        'iterations',zeros(count,1),'converged',false(count,1),'objectiveResidual',nan(count,1));
    r.notes={'Scalar relative permittivity of a homogeneous isotropic nonmagnetic slab; mu_r=1 is assumed, not measured.'; ...
        'R&S Annex 4 pp.24-26 equation (2.8), specialized to cutoff=0 and L_air=L (reference planes at the two sample faces).'; ...
        'Reciprocity and slab symmetry imply S12=S21 and S22=S11. The objective is S11^2-S21^2, not a generic least-squares S-parameter fit.'; ...
        'Complex Newton iteration uses a central finite-difference 2-by-2 Jacobian, with damping to reduce the determinant residual.'; ...
        'The initial complex permittivity guess selects a local root. Continuation uses the most recent accepted frequency result; uniqueness is not guaranteed.'; ...
        'The reported branch is a diagnostic of the solved propagation phase. NRW branch and phase-unwrapping settings do not select the NIST root.'; ...
        'Both individual measured S channels must also reconstruct within tolerance; a determinant root alone is insufficient for acceptance.'; ...
        'Input must be phase-resolved sample-plane free-space data. Antenna mismatch, fixture phase, diffraction and calibration are not fitted.'; ...
        'The exp(+i*omega*t) convention gives passive epsilon with negative imaginary part. Effective dielectric loss includes conduction.'};
    previousAccepted=o.initialEpsilon;
    for k=1:count
        if abs(s21(k))<=o.minTransmission
            r.status{k}='Transmission at/below amplitude floor: NIST iterative unavailable'; continue
        end
        measured=s11(k)^2-s21(k)^2;
        k0d=2*pi*fHz(k)/299792458*thicknessM;
        [epsilon,converged,iterations,objective,reason]=solveDeterminant(previousAccepted,k0d,measured,o);
        r.iterations(k)=iterations; r.converged(k)=converged; r.objectiveResidual(k)=objective;
        r.epsilon(k)=epsilon;
        [~,n,g,p,a,b]=forward(epsilon,k0d,o.singularTolerance);
        r.n(k)=n; r.impedance(k)=1/n; r.gamma(k)=g; r.propagation(k)=p;
        r.reconstructedS11(k)=a; r.reconstructedS21(k)=b;
        r.residual(k)=sqrt(abs(a-s11(k))^2+abs(b-s21(k))^2);
        if isfinite(n)&&isfinite(p)
            r.branch(k)=round((angle(p)+k0d*real(n))/(2*pi));
        end
        constitutiveScale=max(1,abs(epsilon));
        if ~converged
            r.status{k}=['NIST Newton did not converge: ' reason];
        elseif ~all(isfinite([epsilon n g p a b r.residual(k)]))
            r.status{k}='Nonfinite NIST model result';
        elseif r.residual(k)>o.reconstructionTolerance
            r.status{k}='Determinant root conflicts with individual S channels / nonmagnetic model';
        elseif abs(s11(k))^2+abs(s21(k))^2>1+o.passivityTolerance || ...
                abs(p)>1+o.passivityTolerance || imag(epsilon)>o.passivityTolerance*constitutiveScale
            r.status{k}='Non-passive result under initial guess / calibration';
        else
            r.valid(k)=true;
            r.status{k}='Converged passive NIST result; mu_r=1 assumed; root depends on initial guess';
            previousAccepted=epsilon;
        end
    end
end

function [epsilon,converged,iterations,objective,reason]=solveDeterminant(initial,k0d,measured,o)
    x=[real(initial);imag(initial)]; converged=false; iterations=0; reason='maximum iterations reached';
    scale=max(1,abs(measured));
    for iteration=0:o.maxIterations
        [prediction,~,~,~,~,~]=forward(complex(x(1),x(2)),k0d,o.singularTolerance);
        residual=prediction-measured; objective=abs(residual);
        if ~isfinite(objective), reason='singular/nonfinite forward equation'; break; end
        if objective<=o.tolerance*scale, converged=true; reason='determinant tolerance reached'; break; end
        if iteration==o.maxIterations, break; end
        jacobian=zeros(2);
        for coordinate=1:2
            h=eps^(1/3)*max(1,abs(x(coordinate)));
            xp=x; xm=x; xp(coordinate)=xp(coordinate)+h; xm(coordinate)=xm(coordinate)-h;
            fp=forward(complex(xp(1),xp(2)),k0d,o.singularTolerance);
            fm=forward(complex(xm(1),xm(2)),k0d,o.singularTolerance);
            derivative=(fp-fm)/(2*h);
            jacobian(:,coordinate)=[real(derivative);imag(derivative)];
        end
        if any(~isfinite(jacobian(:)))||rcond(jacobian)<=o.singularTolerance
            reason='singular finite-difference Jacobian'; break
        end
        correction=-jacobian\[real(residual);imag(residual)];
        if any(~isfinite(correction)), reason='nonfinite Newton correction'; break; end
        % Limit very large steps before damping; this does not select a root.
        stepLimit=10*max(1,norm(x));
        if norm(correction)>stepLimit, correction=correction*stepLimit/norm(correction); end
        damping=1; accepted=false;
        for trial=1:25
            candidate=x+damping*correction;
            candidatePrediction=forward(complex(candidate(1),candidate(2)),k0d,o.singularTolerance);
            if isfinite(candidatePrediction)&&abs(candidatePrediction-measured)<objective
                x=candidate; accepted=true; break
            end
            damping=damping/2;
        end
        iterations=iteration+1;
        if ~accepted, reason='damped Newton step did not reduce determinant residual'; break; end
    end
    epsilon=complex(x(1),x(2));
end

function [determinant,n,g,p,s11,s21]=forward(epsilon,k0d,singularTolerance)
    n=sqrt(epsilon);
    % Select the decaying lossless evanescent solution when epsilon<0.
    if real(n)==0&&imag(n)>0, n=-n; end
    g=(1-n)/(1+n); p=exp(-1i*k0d*n); denominator=1-g^2*p^2;
    if ~all(isfinite([n g p denominator])) || abs(denominator)<=singularTolerance
        determinant=complex(NaN,NaN); s11=determinant; s21=determinant; return
    end
    determinant=(g^2-p^2)/denominator;
    s11=g*(1-p^2)/denominator;
    s21=(1-g^2)*p/denominator;
end
