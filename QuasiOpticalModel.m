function m = QuasiOpticalModel(p)
%QUASIOPTICALMODEL Geometry and approximate Gaussian illumination, SI units.
% p: fGHz,D,R,theta,width,height,psi,lensPosition,focal,useLens,yaw,pitch,roll.
% fGHz is the center/reference frequency. Optional fLowGHz and fHighGHz
% set the sweep limits; the legacy default band is 2–25 GHz.
% D is the manual aperture size (m). If p.hornGainDBi is nonempty, D is
% estimated at the center frequency as the diagonal of an equivalent
% square aperture with 50% efficiency, and held fixed across the sweep.
% Angles are degrees. Sample rotation Q = Rz(yaw)*Ry(pitch)*Rx(roll).
% The horns remain fixed. Plane basis and material fibers rotate with Q.
% Field-region limits describe the BARE HORN, even when a lens is enabled.
    if ~isfield(p,'mode'), p.mode='Reflection'; end
    validateattributes(p.R,{'numeric'},{'scalar','real','finite','nonnegative'});
    validateattributes(p.fGHz,{'numeric'},{'scalar','real','finite','positive'});
    if ~isfield(p,'fLowGHz'), p.fLowGHz=min(2,p.fGHz); end
    if ~isfield(p,'fHighGHz'), p.fHighGHz=max(25,p.fGHz); end
    validateattributes(p.fLowGHz,{'numeric'},{'scalar','real','finite','positive'});
    validateattributes(p.fHighGHz,{'numeric'},{'scalar','real','finite','positive'});
    if p.fLowGHz>=p.fHighGHz || p.fGHz<p.fLowGHz || p.fGHz>p.fHighGHz || ~isfinite(2*pi*1e9*p.fHighGHz)
        error('QuasiOptical:FrequencyBand','Use positive frequencies with low < high and low <= center <= high.');
    end
    m.mode=p.mode;
    m.lambda = 299792458/(p.fGHz*1e9);
    m.hornApertureEstimated=isfield(p,'hornGainDBi') && ~isempty(p.hornGainDBi);
    m.hornGainDBi=NaN;
    m.hornApertureEfficiency=NaN;
    if m.hornApertureEstimated
        validateattributes(p.hornGainDBi,{'numeric'},{'scalar','real','finite'},mfilename,'hornGainDBi');
        m.hornGainDBi=double(p.hornGainDBi);
        m.hornApertureEfficiency=0.50;
        gain=10^(m.hornGainDBi/10);
        % Effective area G*lambda^2/(4*pi) equals efficiency*D^2/2.
        m.D=m.lambda*sqrt(gain/(2*pi*m.hornApertureEfficiency));
    else
        m.D=p.D;
    end
    validateattributes(m.D,{'numeric'},{'scalar','real','finite','positive'},mfilename,'effective aperture D');
    m.D=double(m.D);
    m.reactiveEnd = 0.62*sqrt(m.D^3/m.lambda);
    m.farStart = 2*m.D^2/m.lambda;
    m.region = regionName(p.R,m.reactiveEnd,m.farStart);
    m.smallAperture = m.D/m.lambda < 3;
    m.useLens = p.useLens && p.lensPosition < p.R;
    m.invalidLens = p.useLens && ~m.useLens;
    m.w0 = 0.425*m.D;
    m.radius = @(s) beamRadius(s,m.w0,m.lambda,p.lensPosition,p.focal,m.useLens);
    m.noLensRadius = @(s) beamRadius(s,m.w0,m.lambda,p.lensPosition,p.focal,false);
    m.withLensRadius = @(s) beamRadius(s,m.w0,m.lambda,p.lensPosition,p.focal,true);
    q = 1/(1/(p.lensPosition+1i*pi*m.w0^2/m.lambda)-1/p.focal);
    m.focus = p.lensPosition-real(q);
    m.waist = sqrt(m.lambda*imag(q)/pi);
    % Use the nominal horn orientations even when the aperture centers
    % coincide with the sample at R=0 and position vectors have no direction.
    m.ki = [cosd(p.theta),sind(p.theta),0];
    m.toRx = [-cosd(p.theta),sind(p.theta),0];
    if strcmp(p.mode,'Transmission')
        m.toRx=m.ki; % Tx -> sample -> Rx on one straight line
    end
    m.tx = -p.R*m.ki;
    m.rx = p.R*m.toRx;
    rz = [cosd(p.yaw) -sind(p.yaw) 0; sind(p.yaw) cosd(p.yaw) 0; 0 0 1];
    ry = [cosd(p.pitch) 0 sind(p.pitch); 0 1 0; -sind(p.pitch) 0 cosd(p.pitch)];
    rx = [1 0 0; 0 cosd(p.roll) -sind(p.roll); 0 sind(p.roll) cosd(p.roll)];
    m.rotation = rz*ry*rx;
    m.normal = (m.rotation*[-1;0;0]).';
    m.u = (m.rotation*[0;1;0]).';
    m.v = (m.rotation*[0;0;1]).';
    m.incidence = acosd(clamp(abs(dot(m.ki,m.normal))));
    m.backFace = dot(m.ki,m.normal)>0;
    m.reflected = m.ki-2*dot(m.ki,m.normal)*m.normal;
    m.specularMismatch = acosd(clamp(dot(m.reflected,m.toRx)));
    m.pathDirection=m.reflected;
    m.pathLabel='Specular reflection';
    if strcmp(p.mode,'Transmission')
        m.pathDirection=m.ki;
        m.pathLabel='Straight-through path';
    end
    m.rxMismatch = acosd(clamp(dot(m.pathDirection,m.toRx)));
    te = cross(m.ki,m.normal);
    if norm(te)<1e-10
        te = m.v; % normal incidence: use material fiber axis as TE reference
    end
    te = te/norm(te);
    tm = cross(te,m.ki);
    m.electric = cosd(p.psi)*te+sind(p.psi)*tm;
    m.vertices = [-p.width/2 -p.height/2; p.width/2 -p.height/2; ...
                   p.width/2 p.height/2; -p.width/2 p.height/2]*[m.u;m.v];
    basis = [m.u;m.v];
    m.metric = basis*(eye(3)-m.ki.'*m.ki)*basis.';
    m.cosIncidence = abs(dot(m.ki,m.normal));
    % Frozen cross-section approximation on a tilted plane. Suppress nearly
    % edge-on estimates instead of displaying an enormous, singular ellipse.
    m.grazing = m.cosIncidence < 0.05;
    m.wSample = m.radius(p.R);
    m.wFar = m.radius(m.farStart);
    m.sampleFraction = NaN; m.farFraction = NaN;
    m.sampleEllipse = zeros(0,2); m.farEllipse = zeros(0,2);
    if ~m.grazing
        m.sampleFraction = intercepted(m.metric,m.cosIncidence,m.wSample,p.width,p.height);
        m.farFraction = intercepted(m.metric,m.cosIncidence,m.wFar,p.width,p.height);
        m.sampleEllipse = ellipse(m.metric,m.wSample);
        m.farEllipse = ellipse(m.metric,m.wFar);
    end
    m.sweepGHz = linspace(p.fLowGHz,p.fHighGHz,240);
    m.materialSweepGHz = linspace(p.fLowGHz,p.fHighGHz,180);
    wavelengths = 299792458./(m.sweepGHz*1e9);
    % One physical aperture is used throughout the frequency sweep.
    m.reactiveSweep = 0.62*sqrt(m.D^3./wavelengths);
    m.farSweep = 2*m.D^2./wavelengths;
    m.diagnostics = illuminationDiagnostics(p,m);
end

function d = illuminationDiagnostics(p,m)
% Local Gaussian estimates, separate from plane-wave material validity.
% The existing footprint freezes the transverse profile at the sample
% center. Use the same approximation for both edge field and phase.
    rayleigh = pi*m.w0^2/m.lambda;
    d.qSample = p.R+1i*rayleigh;
    d.activeWaistRadius = m.w0;
    if m.useLens
        qLens = 1/(1/(p.lensPosition+1i*rayleigh)-1/p.focal);
        d.qSample = qLens+p.R-p.lensPosition;
        d.activeWaistRadius = sqrt(m.lambda*imag(qLens)/pi);
    end
    d.inverseCurvature = real(1/d.qSample);
    % Floating-point cancellation at an ideal focused waist is not a
    % physical curvature. Resolve the waist on the scale of its q value.
    if abs(real(d.qSample)) <= 32*eps(max(abs(d.qSample),realmin))
        d.inverseCurvature = 0;
    end
    d.curvatureRadius = Inf;
    if d.inverseCurvature~=0
        d.curvatureRadius = 1/d.inverseCurvature;
    end
    d.divergenceDeg = rad2deg(m.lambda/(pi*d.activeWaistRadius));
    d.receiverMismatchDeg = m.rxMismatch;
    d.phaseGuidanceDeg = 22.5;
    d.boundaryGuidanceDB = -20;
    d.available = ~m.grazing;
    d.idealizedLaunchPlane = p.R==0;
    d.phaseVariationDeg = NaN;
    d.sphericalPhaseVariationDeg = NaN;
    d.boundaryField = NaN;
    d.boundaryFieldDB = NaN;
    d.maxTransverseRadius = NaN;
    d.minBoundaryTransverseRadius = NaN;
    d.phaseGuidanceExceeded = false;
    d.boundaryGuidanceExceeded = false;
    d.assumptions = ['Estimated fundamental paraxial Gaussian beam with w_0=0.425D and an ideal thin lens. ' ...
        'The profile and curvature are frozen at the specimen center; the rotated sample is projected onto the beam transverse plane. ' ...
        'Gaussian curvature phase excludes the linear plane-wave incidence phase and uses k_0*r_perp^2/(2*R_wave). ' ...
        'Boundary field is the largest E/E_axis on the rectangle perimeter, not a power fraction. ' ...
        'These illumination estimates do not change numerical retrieval validity and do not include antenna coupling or edge diffraction.'];
    d.guidance = '22.5 deg curvature phase and -20 dB boundary field are engineering guidance only, not accuracy guarantees or standards compliance.';
    d.notes = {d.guidance};
    if d.available
        corners = [-p.width/2 -p.height/2; p.width/2 -p.height/2; ...
                   p.width/2 p.height/2; -p.width/2 p.height/2];
        rhoSquared = sum((corners*m.metric).*corners,2);
        maximumRhoSquared = max(max(rhoSquared),0);
        minimumRhoSquared = boundaryMinimum(m.metric,p.width/2,p.height/2);
        d.maxTransverseRadius = sqrt(maximumRhoSquared);
        d.minBoundaryTransverseRadius = sqrt(minimumRhoSquared);
        d.phaseVariationDeg = rad2deg(pi/m.lambda*abs(d.inverseCurvature)*maximumRhoSquared);
        % An exact spherical sag is also retained as a geometry benchmark;
        % it is not substituted for the Gaussian quadratic phase model.
        d.sphericalPhaseVariationDeg = QuasiOpticalSphericalPhase(299792458/m.lambda, ...
            d.curvatureRadius,d.maxTransverseRadius);
        d.boundaryField = exp(-minimumRhoSquared/m.wSample^2);
        d.boundaryFieldDB = -20/log(10)*minimumRhoSquared/m.wSample^2;
        d.phaseGuidanceExceeded = d.phaseVariationDeg>d.phaseGuidanceDeg;
        d.boundaryGuidanceExceeded = d.boundaryFieldDB>d.boundaryGuidanceDB;
        if d.phaseGuidanceExceeded
            d.notes{end+1} = 'Estimated Gaussian curvature phase exceeds the 22.5 deg engineering guide.';
        end
        if d.boundaryGuidanceExceeded
            d.notes{end+1} = 'Strongest estimated Gaussian boundary field exceeds the -20 dB engineering guide.';
        end
    else
        d.notes{end+1} = 'Specimen phase and boundary illumination are unavailable near grazing incidence (abs(cos(alpha)) < 0.05).';
    end
    if d.idealizedLaunchPlane
        d.notes{end+1} = 'At zero distance these are idealized Gaussian launch-plane estimates; physical horn/sample contact coupling is not modeled.';
    end
    if m.invalidLens
        d.notes{end+1} = 'The requested lens is not before the specimen and is excluded from the active beam estimate.';
    end
    d.setup = p;
    d.setup.D = m.D;
    d.setup.frequencyHz = p.fGHz*1e9;
    d.setup.lowFrequencyHz = p.fLowGHz*1e9;
    d.setup.highFrequencyHz = p.fHighGHz*1e9;
    d.setup.activeLens = m.useLens;
    d.setup.actualIncidenceDeg = m.incidence;
    d.setup.rotation = m.rotation;
    d.setup.incidentDirection = m.ki;
    d.setup.projectedMetric = m.metric;
    d.setup.units = 'Lengths m; angles deg; fGHz/fLowGHz/fHighGHz GHz; explicit frequencyHz fields Hz; hornGainDBi dBi.';
end

function value = boundaryMinimum(g,a,b)
% Exact minimum of the positive quadratic rho^2 over four line segments.
    candidates=zeros(4,2);
    for k=1:2
        u=(2*k-3)*a;
        v=max(-b,min(b,-g(1,2)*u/g(2,2)));
        candidates(k,:)=[u v];
        v=(2*k-3)*b;
        u=max(-a,min(a,-g(1,2)*v/g(1,1)));
        candidates(k+2,:)=[u v];
    end
    value=max(0,min(sum((candidates*g).*candidates,2)));
end

function name = regionName(r,reactive,far)
    if r<reactive
        name = 'Reactive near field';
    elseif r<far
        name = 'Radiating near field (Fresnel)';
    else
        name = 'Far field (Fraunhofer)';
    end
end

function w = beamRadius(s,w0,lambda,lensPosition,focal,useLens)
    zr = pi*w0^2/lambda;
    w = w0*sqrt(1+(s/zr).^2);
    if useLens
        q = 1/(1/(lensPosition+1i*zr)-1/focal);
        after = s>lensPosition;
        z = s(after)-lensPosition+real(q);
        w(after) = sqrt(lambda*imag(q)/pi)*sqrt(1+(z/imag(q)).^2);
    end
end

function fraction = intercepted(g,c,w,width,height)
% Integrate the projected, unit-total-power Gaussian over the rectangle.
% Analytic integration in v + adaptive quadrature in u avoids grid aliasing
% of a small focused spot. At zero rotation this equals the erf product.
    if g(1,1)>g(2,2)
        g = g([2 1],[2 1]);
        temp = width; width = height; height = temp;
    end
    a = g(1,1); b = g(1,2); d = g(2,2);
    rootD = sqrt(d);
    integrand = @(u) c/(sqrt(2*pi)*w*rootD).* ...
        exp(-2*(a-b^2/d)*u.^2/w^2).* ...
        (erf(sqrt(2)/w*(rootD*height/2+b*u/rootD))- ...
         erf(sqrt(2)/w*(-rootD*height/2+b*u/rootD)));
    % Breakpoints resolve narrow profiles even for very large samples.
    scale = w/sqrt(max(a-b^2/d,eps));
    points = [-4 -1 0 1 4]*scale;
    points = points(abs(points)<width/2);
    fraction = integral(integrand,-width/2,width/2,'Waypoints',points, ...
        'AbsTol',1e-9,'RelTol',1e-7);
    fraction = min(1,max(0,fraction));
end

function xy = ellipse(g,w)
    [v,d] = eig(g);
    t = linspace(0,2*pi,241);
    xy = (v*diag(w./sqrt(diag(d)))*[cos(t);sin(t)]).';
end

function y = clamp(x)
    y = max(-1,min(1,x));
end
