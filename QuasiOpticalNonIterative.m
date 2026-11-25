function r=QuasiOpticalNonIterative(fHz,s11,s21,thicknessM,options)
%QUASIOPTICALNONITERATIVE Free-space nonmagnetic non-iterative retrieval.
% r = QuasiOpticalNonIterative(fHz,s11,s21,thicknessM,options)
% R&S, Measurement of Dielectric Material Properties, Annex 5, pp.27-28:
% equation (3.10), exponent n=1, at zero cutoff gives epsilon_r=N^2.
% N is the propagation index, not the exponent called n in that equation.
% mu_r=1 is ASSUMED, not fitted or measured. The inputs must be complex,
% calibrated sample-surface S11/S21 of an isotropic air/slab/air sample.
% The exp(+i*omega*t) convention gives passive epsilon with Im(epsilon)<=0.
%
% Options match QuasiOpticalRetrieve, with method='New non-iterative'. An
% integer propagation branch is still required; no initial epsilon guess
% is needed. Propagation follows the transfer-matrix eigenvalue relation
% P+1/P=(1-S11^2+S21^2)/S21. This avoids dividing by S11 at half-wave points.
% Measured interface information chooses the forward eigenvalue away from
% degeneracies; it is NOT used as a retrieved magnetic constitutive value.
% Every result is checked by reconstructing BOTH channels with mu_r=1.

    if nargin<5, options=struct(); end
    validateattributes(fHz,{'numeric'},{'vector','real','finite','positive','nonempty'},mfilename,'fHz');
    validateattributes(s11,{'numeric'},{'vector','finite','nonempty'},mfilename,'s11');
    validateattributes(s21,{'numeric'},{'vector','finite','nonempty'},mfilename,'s21');
    validateattributes(thicknessM,{'numeric'},{'scalar','real','finite','positive'},mfilename,'thicknessM');
    if ~isstruct(options)||~isscalar(options), error('QuasiOptical:RetrievalOptions','Options must be a scalar struct.'); end
    defaults=struct('method','New non-iterative','angleDeg',0,'polarization','TE','branch',0, ...
        'unwrapPhase',true,'minTransmission',1e-8,'singularTolerance',1e-10, ...
        'passivityTolerance',1e-6,'reconstructionTolerance',1e-6,'cutoffHz',0);
    names=fieldnames(options);
    for k=1:numel(names)
        if ~isfield(defaults,names{k}), error('QuasiOptical:RetrievalOptions','Unknown option: %s.',names{k}); end
        defaults.(names{k})=options.(names{k});
    end
    o=defaults;
    if ~strcmpi(o.method,'New non-iterative'), error('QuasiOptical:RetrievalMethod','This function implements the New non-iterative method only.'); end
    validateattributes(o.angleDeg,{'numeric'},{'scalar','real','finite'});
    validateattributes(o.cutoffHz,{'numeric'},{'scalar','real','finite','nonnegative'});
    if abs(o.angleDeg)>1e-10||o.cutoffHz~=0
        error('QuasiOptical:RetrievalGeometry','This calculation requires normal-incidence free space (angle = 0 deg; cutoff = 0 Hz).');
    end
    if ~any(strcmpi(o.polarization,{'TE','TM'})), error('QuasiOptical:RetrievalPolarization','Polarization must be TE or TM. They are equivalent at normal incidence.'); end
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
        'epsilon',blank,'mu',blank,'n',blank,'impedance',blank,'gamma',blank, ...
        'propagation',blank,'reconstructedS11',blank,'reconstructedS21',blank, ...
        'residual',nan(count,1),'branch',nan(count,1),'valid',false(count,1), ...
        'status',{repmat({'Not evaluated'},count,1)},'selectedBranch',o.branch, ...
        'thicknessM',thicknessM,'options',o,'method','Normal-incidence free-space New non-iterative');
    r.notes={'Scalar epsilon of a homogeneous isotropic nonmagnetic slab; mu_r=1 is an assumption, not a retrieved result.'; ...
        'R&S Annex 5 pp.27-28 equation (3.10), exponent n=1 and zero cutoff: epsilon_r=(lambda_0/Lambda)^2=N^2.'; ...
        'No initial epsilon guess is required. The integer logarithm branch remains an assumption selected by the user.'; ...
        'Input S11/S21 must be complex and calibrated/de-embedded to the two sample surfaces in air.'; ...
        'The complex time convention is exp(+i*omega*t); passive dielectric loss has negative imaginary part.'; ...
        'Both channels are reconstructed with mu_r=1. A failed fit can indicate magnetic behavior, calibration errors or an incorrect branch.'; ...
        'At exact half-wave transparency, interface impedance is unobservable; propagation can remain finite but sensitivity to noise is high.'; ...
        'Unwrapping assumes closely spaced frequency samples; phase is restarted after excluded data, and coarse sampling can miss turns.'; ...
        'Transmission at/below the selected amplitude floor is excluded. Dielectric and conduction losses cannot be separated at one frequency.'};

    algebraOK=false(count,1); halfWave=false(count,1); rootUnresolved=false(count,1);
    for k=1:count
        a=s11(k); b=s21(k);
        if abs(b)<=o.minTransmission
            r.status{k}='Transmission at/below amplitude floor: non-iterative retrieval unavailable'; continue
        end
        halfTrace=(1-a^2+b^2)/(2*b);
        discriminant=sqrt(halfTrace^2-1);
        pair=[halfTrace+discriminant halfTrace-discriminant];
        % Recompute the small root from the reciprocal of the large root,
        % avoiding catastrophic subtraction for highly attenuating slabs.
        [~,large]=max(abs(pair)); small=3-large;
        if abs(pair(large))>realmin, pair(small)=1/pair(large); end
        if any(~isfinite(pair))||any(abs(pair)<=realmin)
            r.status{k}='Propagation eigenvalue is zero/nonfinite'; continue
        end
        scale=max([1 abs((1+a)^2) abs((1-a)^2) abs(b^2)]);
        numerator=(1+a)^2-b^2; denominator=(1-a)^2-b^2;
        halfWave(k)=min(abs([numerator denominator]))<=o.singularTolerance*scale;
        reference=NaN;
        if ~halfWave(k)
            % A passive positive-real interface fixes forward versus inverse
            % propagation, including lossless cases with |P|=|1/P|=1.
            z=sqrt(numerator/denominator);
            if real(z)<0, z=-z; end
            if abs(z+1)>o.singularTolerance
                g=(z-1)/(z+1); den=1-a*g;
                if abs(den)>o.singularTolerance, reference=b/den; end
                % Purely reactive impedance has no positive-real sign; the
                % decaying evanescent eigenvalue selects its physical sign.
                if abs(real(z))<=o.singularTolerance*max(1,abs(z))&&abs(reference)>1
                    z=-z;
                    if abs(z+1)>o.singularTolerance
                        g=(z-1)/(z+1); den=1-a*g;
                        if abs(den)>o.singularTolerance, reference=b/den; end
                    end
                end
            end
        end
        if isfinite(reference)
            [~,pick]=min(abs(pair-reference));
        elseif abs(abs(pair(1))-abs(pair(2)))>o.passivityTolerance
            [~,pick]=min(abs(pair));
        elseif k>1&&algebraOK(k-1)
            [~,pick]=min(abs(pair-r.propagation(k-1)));
        elseif abs(a)<=sqrt(o.singularTolerance)&&abs(abs(b)-1)<=sqrt(o.singularTolerance)
            % At transparency the two eigenvalues coalesce at +/-1.
            [~,pick]=min(abs(pair-b));
        else
            rootUnresolved(k)=true;
            r.status{k}='Forward propagation root unresolved: selected assumptions do not determine a unique result'; continue
        end
        r.propagation(k)=pair(pick); algebraOK(k)=true;
    end

    edges=diff([false;algebraOK;false]); starts=find(edges==1); stops=find(edges==-1)-1;
    for segment=1:numel(starts)
        indices=starts(segment):stops(segment); principal=angle(r.propagation(indices));
        % Use [-pi,pi) at an isolated exact half-wave boundary. This fixes
        % only the representation of -1, not the unknown absolute branch.
        atNegativeAxis=halfWave(indices)&abs(imag(r.propagation(indices)))<=sqrt(eps)&real(r.propagation(indices))<0;
        principal(atNegativeAxis)=-pi;
        phase=principal;
        if o.unwrapPhase, phase=unwrap(phase); end
        k0=2*pi*fHz(indices)/299792458;
        r.n(indices)=(-phase+2*pi*o.branch+1i*log(abs(r.propagation(indices))))./(k0*thicknessM);
        r.branch(indices)=round((principal-phase)/(2*pi))+o.branch;
        r.epsilon(indices)=r.n(indices).^2; r.mu(indices)=1;
        r.impedance(indices)=1./r.n(indices);
        r.gamma(indices)=(1-r.n(indices))./(1+r.n(indices));
        for k=indices
            % Entire-function slab form is finite at N=0 and does not
            % create a singular interface Gamma at an index degeneracy.
            delta=2*pi*fHz(k)/299792458*r.n(k)*thicknessM;
            prop=exp(-1i*delta);
            if abs(delta)<1e-6
                differenceOverN=2i*2*pi*fHz(k)/299792458*thicknessM*(1-1i*delta-2*delta^2/3);
            else
                differenceOverN=-expm1(-2i*delta)/r.n(k);
            end
            aa=r.epsilon(k)*differenceOverN; bb=differenceOverN;
            den=1+prop^2+(aa+bb)/2;
            r.reconstructedS11(k)=(bb-aa)/(2*den);
            r.reconstructedS21(k)=2*prop/den;
            r.residual(k)=sqrt(abs(r.reconstructedS11(k)-s11(k))^2+abs(r.reconstructedS21(k)-s21(k))^2);
            materialScale=max(1,abs(r.epsilon(k)));
            if ~all(isfinite([r.epsilon(k) r.n(k) r.residual(k)]))
                r.status{k}='Nonfinite non-iterative result';
            elseif abs(s11(k))^2+abs(s21(k))^2>1+o.passivityTolerance|| ...
                    abs(r.propagation(k))>1+o.passivityTolerance|| ...
                    imag(r.epsilon(k))>o.passivityTolerance*materialScale|| ...
                    real(r.n(k))<-o.passivityTolerance*max(1,abs(r.n(k)))
                r.status{k}='Non-passive/outgoing result under selected branch / calibration';
            elseif r.residual(k)>o.reconstructionTolerance
                r.status{k}='Reconstructed channels exceed tolerance under mu_r=1 / selected branch';
            else
                r.valid(k)=true;
                r.status{k}='Finite passive non-iterative result; mu_r=1 assumed; absolute branch remains assumed';
            end
            if halfWave(k)
                r.status{k}=[r.status{k} '; half-wave transparency: impedance unobservable and noise sensitivity high'];
            end
            if segment>1
                r.status{k}=[r.status{k} '; phase restarted after excluded data'];
            end
        end
    end
    if any(rootUnresolved)
        r.notes{end+1}='One or more forward-root choices were unresolved and have been excluded rather than silently selected.';
    end
end
