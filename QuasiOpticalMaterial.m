function s=QuasiOpticalMaterial(p,m,d)
%QUASIOPTICALMATERIAL Passive isotropic air/slab/air plane-wave response.
% exp(+i*omega*t) convention: epsilon_r = epsReal - i*epsLoss
% - i*sigma/(omega*eps0), mu_r = muReal - i*muLoss. Thickness is normal
% to the slab. TE/TM amplitudes refer to tangential electric fields.
    validateattributes(d.epsReal,{'numeric'},{'scalar','real','finite','positive'});
    validateattributes(d.muReal,{'numeric'},{'scalar','real','finite','positive'});
    for name={'epsLoss','muLoss','conductivity','thicknessMM'}
        validateattributes(d.(name{1}),{'numeric'},{'scalar','real','finite','nonnegative'});
    end
    eps0=8.8541878128e-12;
    omega=2*pi*p.fGHz*1e9; k0=2*pi/m.lambda;
    s.epsComplex=d.epsReal-1i*(d.epsLoss+d.conductivity/(omega*eps0));
    s.muComplex=d.muReal-1i*d.muLoss;
    s.r=[NaN NaN]; s.t=[NaN NaN]; s.Rpol=[NaN NaN]; s.Tpol=[NaN NaN]; s.Apol=[NaN NaN];
    s.R=NaN; s.T=NaN; s.A=NaN; s.phaseR=[NaN NaN]; s.phaseT=[NaN NaN];
    s.specularRCS=NaN; s.specularRCSDBsm=NaN;
    s.valid=m.cosIncidence>=1e-6;
    s.notes={'Simulated homogeneous isotropic air/slab/air response; not measured S-parameters.'; ...
        'R, T and A describe power incident on the slab, not power captured by the fixed Rx.'};
    if ~s.valid
        s.notes{end+1}='Exactly grazing incidence: normal incident power vanishes; normalized slab response is unavailable.';
        return
    end
    c=m.cosIncidence;
    if strcmp(d.preset,'Perfect conductor (PEC)')
        s.r=[-1 -1]; s.t=[0 0];
        s.notes{end+1}='PEC is an opaque ideal boundary: R = 1, T = 0, A = 0. Constitutive inputs and thickness are ignored.';
    else
        q=sqrt(s.epsComplex*s.muComplex-(1-c^2));
        if imag(q)>0 || (imag(q)==0 && real(q)<0), q=-q; end
        delta=k0*q*d.thicknessMM/1000;
        propagation=exp(-1i*delta); % passive branch never grows
        % Stable evaluation at q=0 (critical angle) and for thick metals.
        if abs(delta)<1e-6
            differenceOverQ=2i*k0*d.thicknessMM/1000*(1-1i*delta-2*delta^2/3);
        else
            differenceOverQ=-expm1(-2i*delta)/q;
        end
        a=[q^2/(s.muComplex*c), s.epsComplex*c]*differenceOverQ;
        b=[s.muComplex*c, q^2/(s.epsComplex*c)]*differenceOverQ;
        denominator=1+propagation^2+(a+b)/2;
        s.r=(b-a)./(2*denominator);
        s.t=2*propagation./denominator;
        s.notes{end+1}='Multiple internal reflections, electric/conduction loss and magnetic loss are included.';
    end
    s.Rpol=abs(s.r).^2; s.Tpol=abs(s.t).^2;
    absorption=1-s.Rpol-s.Tpol;
    if any(absorption < -1e-8) || any(~isfinite(absorption))
        error('QuasiOptical:PassiveBalance','Material calculation failed passive power balance.');
    end
    s.Apol=max(0,absorption); % suppress floating-point negative zero only
    weights=[cosd(p.psi)^2 sind(p.psi)^2];
    s.R=sum(weights.*s.Rpol); s.T=sum(weights.*s.Tpol); s.A=sum(weights.*s.Apol);
    s.phaseR=angle(s.r)*180/pi; s.phaseT=angle(s.t)*180/pi;
    s.phaseR(abs(s.r)<1e-14)=NaN; s.phaseT(abs(s.t)<1e-14)=NaN;
    if strcmp(p.mode,'Reflection')
        s.specularRCS=4*pi*(p.width*p.height)^2*c^2*s.R/m.lambda^2;
        s.specularRCSDBsm=10*log10(s.specularRCS);
        s.notes{end+1}='RCS is a scalar large-plate SPECULAR scale under uniform far-field illumination, not a general bistatic solution.';
        if m.rxMismatch>1
            s.notes{end+1}='Rx is off the specular direction: the displayed specular RCS is NOT the RCS toward this Rx.';
        end
        if m.useLens || p.R<max(m.farStart,2*(p.width^2+p.height^2)/m.lambda)
            s.notes{end+1}='Current focused/near-field geometry does not establish the conditions for the specular far-field RCS estimate.';
        end
        if min(p.width,p.height)/m.lambda<3
            s.notes{end+1}='Sample dimension below 3 wavelengths: the large-plate RCS approximation is only indicative.';
        end
    end
    if m.grazing
        s.notes{end+1}='Slab plane-wave response remains available, but Gaussian footprint/interception is unavailable near grazing.';
    end
    s.notes{end+1}='Presets are illustrative, frequency-independent material inputs; conductivity contribution scales as 1/f.';
end
