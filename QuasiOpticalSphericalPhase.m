function phaseDeg = QuasiOpticalSphericalPhase(frequencyHz,curvatureRadius,transverseRadius)
%QUASIOPTICALSPHERICALPHASE Exact spherical phase departure from a tangent.
% Magnitude in degrees for a transverse radius rho at sphere radius |R|:
% 360*f/c * (sqrt(R^2+rho^2)-|R|). Infinite curvature radius is a plane.
% This geometric benchmark differs from the Gaussian paraxial phase
% 180*f/c * rho^2/|R|. It does not simulate horn/receiver coupling.
    validateattributes(frequencyHz,{'numeric'},{'scalar','real','finite','positive'});
    validateattributes(curvatureRadius,{'numeric'},{'scalar','real','nonnan'});
    validateattributes(transverseRadius,{'numeric'},{'real','finite','nonnegative'});
    if curvatureRadius==0
        error('QuasiOptical:ZeroCurvatureRadius','A spherical wavefront radius must be nonzero. Use Inf for a plane.');
    end
    if isinf(curvatureRadius)
        phaseDeg=zeros(size(transverseRadius));
        return
    end
    r=abs(curvatureRadius);
    % Rationalized sag avoids cancellation for a nearly planar wavefront.
    sag=transverseRadius.^2./(hypot(r,transverseRadius)+r);
    phaseDeg=360*frequencyHz/299792458*sag;
end
