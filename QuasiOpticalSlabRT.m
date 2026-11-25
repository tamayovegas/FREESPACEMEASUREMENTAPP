function s=QuasiOpticalSlabRT(fHz,thicknessM,epsilon,mu,angleDeg,polarization)
%QUASIOPTICALSLABRT Independent oblique isotropic air/slab/air forward model.
% s=QuasiOpticalSlabRT(fHz,d,epsilon,mu,angleDeg,'TE'|'TM')
% Normal thickness d is in metres. Constitutive values are relative and may
% be scalars or contain one value per frequency. exp(+i*omega*t) is used.
% r,t are tangential electric-field amplitudes at the two sample faces;
% identical air ports make their squared magnitudes power coefficients.
% z=Zslab/Zair,polarization; q=kz/k0. No antenna or finite-sample model.
    validateattributes(fHz,{'numeric'},{'vector','real','finite','positive','nonempty'});
    validateattributes(thicknessM,{'numeric'},{'scalar','real','finite','positive'});
    validateattributes(epsilon,{'numeric'},{'vector','finite','nonempty'});
    validateattributes(mu,{'numeric'},{'vector','finite','nonempty'});
    validateattributes(angleDeg,{'numeric'},{'scalar','real','finite'});
    if angleDeg<0||angleDeg>=90||cosd(angleDeg)<1e-6
        error('QuasiOptical:RetrievalGeometry','Use an incidence angle from 0 to below 90 deg with cos(theta) >= 1e-6. Grazing normalization is singular.');
    end
    if ~any(strcmpi(polarization,{'TE','TM'}))
        error('QuasiOptical:RetrievalPolarization','Choose TE or TM polarization.');
    end
    polarization=upper(char(polarization)); fHz=fHz(:); count=numel(fHz);
    epsilon=expand(epsilon,count,'epsilon'); mu=expand(mu,count,'mu');
    c=cosd(angleDeg); transverse=sind(angleDeg)^2; k0=2*pi*fHz/299792458;
    q=sqrt(epsilon.*mu-transverse);
    reverse=imag(q)>0|(imag(q)==0&real(q)<0); q(reverse)=-q(reverse);
    n=sqrt(epsilon.*mu); reverse=real(n.*conj(q))<0; n(reverse)=-n(reverse);
    if strcmp(polarization,'TE')
        z=mu*c./q;
    else
        z=q./(epsilon*c);
    end
    % Characteristic-matrix evaluation, independent of the NRW interface
    % inversion. Scaled by exp(-i*delta) to avoid overflow in lossy slabs.
    delta=k0.*q*thicknessM; propagation=exp(-1i*delta);
    differenceOverQ=complex(zeros(count,1)); near=abs(delta)<1e-6;
    differenceOverQ(near)=2i*k0(near)*thicknessM.* ...
        (1-1i*delta(near)-2*delta(near).^2/3);
    differenceOverQ(~near)=-expm1(-2i*delta(~near))./q(~near);
    if strcmp(polarization,'TE')
        a=q.^2./(mu*c).*differenceOverQ;
        b=mu*c.*differenceOverQ;
    else
        a=epsilon*c.*differenceOverQ;
        b=q.^2./(epsilon*c).*differenceOverQ;
    end
    denominator=1+propagation.^2+(a+b)/2;
    reflection=(b-a)./(2*denominator); transmission=2*propagation./denominator;
    valid=isfinite(reflection)&isfinite(transmission);
    status=repmat({'Finite isotropic slab forward response'},count,1);
    status(~valid)={'Singular/nonfinite constitutive forward response'};
    s=struct('fHz',fHz,'frequencyHz',fHz,'r',reflection,'t',transmission, ...
        's11',reflection,'s21',transmission,'epsilon',epsilon,'mu',mu, ...
        'n',n,'q',q,'kz',k0.*q,'z',z,'impedance',z,'valid',valid, ...
        'status',{status},'angleDeg',angleDeg,'polarization',polarization, ...
        'thicknessM',thicknessM);
end

function value=expand(value,count,name)
    value=value(:);
    if isscalar(value), value=repmat(value,count,1); end
    if numel(value)~=count
        error('QuasiOptical:SlabSize','%s must be scalar or contain one value per frequency.',name);
    end
end
