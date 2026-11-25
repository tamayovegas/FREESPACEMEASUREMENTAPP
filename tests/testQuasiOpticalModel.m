function tests = testQuasiOpticalModel
    tests = functiontests(localfunctions);
end

function testDefaultBoundariesAndPower(t)
    p=defaults(); m=QuasiOpticalModel(p);
    verifyEqual(t,m.D,p.D);
    verifyFalse(t,m.hornApertureEstimated);
    verifyTrue(t,isnan(m.hornGainDBi)&&isnan(m.hornApertureEfficiency));
    verifyEqual(t,m.farStart,0.960664594170678,'AbsTol',1e-12);
    verifyEqual(t,m.reactiveEnd,0.148851497137088,'AbsTol',1e-12);
    expected=erf(p.width*cosd(p.theta)/(sqrt(2)*m.wSample))* ...
        erf(p.height/(sqrt(2)*m.wSample));
    verifyEqual(t,m.sampleFraction,expected,'AbsTol',1e-8);
    verifyEqual(t,m.rxMismatch,0,'AbsTol',1e-6);
end

function testAllThreeRegionsAndEdges(t)
    p=defaults(); m=QuasiOpticalModel(p);
    p.R=m.reactiveEnd/2; a=QuasiOpticalModel(p);
    verifyEqual(t,a.region,'Reactive near field');
    p.R=m.reactiveEnd; a=QuasiOpticalModel(p);
    verifyEqual(t,a.region,'Radiating near field (Fresnel)');
    p.R=m.farStart; a=QuasiOpticalModel(p);
    verifyEqual(t,a.region,'Far field (Fraunhofer)');
end

function testZeroDistancePreservesNominalGeometry(t)
    for mode={'Reflection','Transmission'}
        p=defaults(); p.mode=mode{1}; p.useLens=true;
        p.theta=37; p.yaw=12; p.pitch=-18; p.roll=21; p.psi=31;
        p.width=.11; p.height=.17;
        positiveDistance=QuasiOpticalModel(p);
        verifyTrue(t,positiveDistance.useLens);
        p.R=0; atOrigin=QuasiOpticalModel(p);

        verifyEqual(t,atOrigin.tx,zeros(1,3));
        verifyEqual(t,atOrigin.rx,zeros(1,3));
        verifyEqual(t,atOrigin.ki,[cosd(p.theta) sind(p.theta) 0],'AbsTol',1e-12);
        if strcmp(p.mode,'Reflection')
            expectedRx=[-cosd(p.theta) sind(p.theta) 0];
        else
            expectedRx=atOrigin.ki;
        end
        verifyEqual(t,atOrigin.toRx,expectedRx,'AbsTol',1e-12);
        for field={'rotation','normal','electric','reflected','pathDirection','metric'}
            verifyEqual(t,atOrigin.(field{1}),positiveDistance.(field{1}),'AbsTol',1e-12);
        end
        verifyEqual(t,atOrigin.incidence,positiveDistance.incidence,'AbsTol',1e-10);
        verifyEqual(t,atOrigin.rxMismatch,positiveDistance.rxMismatch,'AbsTol',1e-5);

        verifyEqual(t,atOrigin.region,'Reactive near field');
        verifyFalse(t,atOrigin.useLens);
        verifyTrue(t,atOrigin.invalidLens);
        verifyEqual(t,atOrigin.wSample,atOrigin.w0,'AbsTol',1e-12);
        verifyGreaterThan(t,atOrigin.sampleFraction,0);
        verifyLessThan(t,atOrigin.sampleFraction,1);
        verifyNotEmpty(t,atOrigin.sampleEllipse);
        rho=sum((atOrigin.sampleEllipse*atOrigin.metric).*atOrigin.sampleEllipse,2);
        verifyEqual(t,rho,atOrigin.w0^2*ones(size(rho)),'AbsTol',1e-12);
    end
end

function testFrequencyScalingAndLensIndependentRegions(t)
    p=defaults(); a=QuasiOpticalModel(p);
    p.fGHz=20; b=QuasiOpticalModel(p);
    verifyEqual(t,b.farStart,2*a.farStart,'AbsTol',1e-12);
    verifyEqual(t,b.reactiveEnd,sqrt(2)*a.reactiveEnd,'AbsTol',1e-12);
    p.useLens=true; c=QuasiOpticalModel(p);
    verifyEqual(t,c.farStart,b.farStart);
    verifyEqual(t,c.reactiveEnd,b.reactiveEnd);
    verifyNotEqual(t,c.wSample,b.wSample);
end

function testGainEstimateDrivesRegionsAndOneCentimetreFootprint(t)
    p=defaults(); p.hornGainDBi=15; p.D=.01; p.width=.01; p.height=.01;
    m=QuasiOpticalModel(p);
    effectiveArea=10^(15/10)*m.lambda^2/(4*pi);
    equivalentDiagonal=sqrt(2*effectiveArea/.5);
    verifyTrue(t,m.hornApertureEstimated);
    verifyEqual(t,m.hornGainDBi,15);
    verifyEqual(t,m.hornApertureEfficiency,.50);
    verifyEqual(t,m.D,equivalentDiagonal,'RelTol',1e-12);
    verifyFalse(t,m.smallAperture);
    verifyGreaterThan(t,m.sampleFraction,0);
    verifyLessThan(t,m.sampleFraction,1);
    verifyNotEmpty(t,m.sampleEllipse);
    verifyTrue(t,all(isfinite(m.sampleEllipse(:))));

    manual=p; manual.D=equivalentDiagonal; manual.hornGainDBi=[];
    baseline=QuasiOpticalModel(manual);
    verifyFalse(t,baseline.hornApertureEstimated);
    for field={'reactiveEnd','farStart','w0','wSample','wFar','sampleFraction'}
        verifyEqual(t,m.(field{1}),baseline.(field{1}),'RelTol',1e-12);
    end
    higherGain=p; higherGain.hornGainDBi=p.hornGainDBi+20*log10(2);
    higherGainModel=QuasiOpticalModel(higherGain);
    verifyEqual(t,higherGainModel.D,2*m.D,'RelTol',1e-12);
    higherFrequency=p; higherFrequency.fGHz=2*p.fGHz;
    higherFrequencyModel=QuasiOpticalModel(higherFrequency);
    verifyEqual(t,higherFrequencyModel.D,m.D/2,'RelTol',1e-12);
end

function testGainEstimateHoldsPhysicalApertureFixedThroughSweep(t)
    p=defaults(); p.hornGainDBi=20; p.fLowGHz=8; p.fGHz=12; p.fHighGHz=18;
    m=QuasiOpticalModel(p);
    apertureFromSweep=sqrt(m.farSweep.*(299792458./(m.sweepGHz*1e9))/2);
    verifyEqual(t,apertureFromSweep,m.D*ones(size(m.sweepGHz)),'RelTol',1e-12);
    verifyEqual(t,m.reactiveSweep(end)/m.reactiveSweep(1),sqrt(p.fHighGHz/p.fLowGHz),'RelTol',1e-12);
    p.fLowGHz=3; p.fHighGHz=35;
    other=QuasiOpticalModel(p);
    verifyEqual(t,other.D,m.D);
    verifyEqual(t,other.w0,m.w0);
end

function testSweepLimitsAndCenterAreIndependent(t)
    p=defaults(); p.fLowGHz=27.5; p.fGHz=31.2; p.fHighGHz=42;
    m=QuasiOpticalModel(p);
    verifyEqual(t,m.sweepGHz([1 end]),[27.5 42]);
    verifyEqual(t,m.materialSweepGHz([1 end]),[27.5 42]);
    verifyNumElements(t,m.sweepGHz,240);
    verifyNumElements(t,m.materialSweepGHz,180);
    verifyEqual(t,m.lambda,299792458/(31.2e9),'RelTol',1e-12);
    verifyEqual(t,m.farSweep(end),2*p.D^2*42e9/299792458,'RelTol',1e-12);
    p.fGHz=36; other=QuasiOpticalModel(p);
    verifyEqual(t,other.sweepGHz,m.sweepGHz);
    verifyEqual(t,other.materialSweepGHz,m.materialSweepGHz);
    verifyNotEqual(t,other.farStart,m.farStart);
end

function testInvalidExplicitFrequencyBand(t)
    p=defaults(); p.fLowGHz=12; p.fHighGHz=25;
    verifyError(t,@() QuasiOpticalModel(p),'QuasiOptical:FrequencyBand');
    p.fLowGHz=25;
    verifyError(t,@() QuasiOpticalModel(p),'QuasiOptical:FrequencyBand');
end

function testRotationAndReflection(t)
    p=defaults(); p.yaw=21; p.pitch=-17; p.roll=33; m=QuasiOpticalModel(p);
    verifyEqual(t,m.rotation.'*m.rotation,eye(3),'AbsTol',1e-12);
    verifyEqual(t,norm(m.reflected),1,'AbsTol',1e-12);
    verifyEqual(t,dot(m.ki,m.normal),-dot(m.reflected,m.normal),'AbsTol',1e-12);
    verifyEqual(t,dot(m.electric,m.ki),0,'AbsTol',1e-12);
    verifyGreaterThan(t,m.rxMismatch,1);
    verifyGreaterThanOrEqual(t,m.sampleFraction,0);
    verifyLessThanOrEqual(t,m.sampleFraction,1);
    rho=sum((m.sampleEllipse*m.metric).*m.sampleEllipse,2);
    verifyEqual(t,rho,m.wSample^2*ones(size(rho)),'AbsTol',1e-12);
end

function testRollSwapsRectangularPanelAxes(t)
    p=defaults(); p.width=.25; p.height=.8; p.roll=90;
    m=QuasiOpticalModel(p);
    expected=erf(p.width/(sqrt(2)*m.wSample))* ...
        erf(p.height*cosd(p.theta)/(sqrt(2)*m.wSample));
    verifyEqual(t,m.sampleFraction,expected,'AbsTol',1e-8);
end

function testRotatedIntegralAgainstIndependentQuadrature(t)
    p=defaults(); p.width=.23; p.height=.41; p.yaw=-20; p.pitch=12; p.roll=37;
    m=QuasiOpticalModel(p); g=m.metric; w=m.wSample;
    density=@(u,v) 2*m.cosIncidence/(pi*w^2)* ...
        exp(-2*(g(1,1)*u.^2+2*g(1,2)*u.*v+g(2,2)*v.^2)/w^2);
    expected=integral2(density,-p.width/2,p.width/2,-p.height/2,p.height/2, ...
        'AbsTol',1e-10,'RelTol',1e-8);
    verifyEqual(t,m.sampleFraction,expected,'AbsTol',1e-8);
end

function testLensContinuityAndInvalidLens(t)
    p=defaults(); p.useLens=true; m=QuasiOpticalModel(p);
    verifyEqual(t,m.radius(p.lensPosition-1e-9),m.radius(p.lensPosition+1e-9),'AbsTol',1e-8);
    p.lensPosition=p.R; m=QuasiOpticalModel(p);
    verifyFalse(t,m.useLens); verifyTrue(t,m.invalidLens);
    verifyEqual(t,m.wSample,m.noLensRadius(p.R));
end

function testGrazingIsExplicitlyUnavailable(t)
    p=defaults(); p.yaw=-60; m=QuasiOpticalModel(p);
    verifyTrue(t,m.grazing); verifyTrue(t,isnan(m.sampleFraction));
    verifyEmpty(t,m.sampleEllipse);
end

function testSameDistanceMeansSameComparison(t)
    p=defaults(); m=QuasiOpticalModel(p); p.R=m.farStart;
    p.useLens=true; p.pitch=25; p.roll=40; m=QuasiOpticalModel(p);
    verifyEqual(t,m.sampleFraction,m.farFraction,'AbsTol',1e-12);
    verifyEqual(t,m.wSample,m.wFar,'AbsTol',1e-12);
end

function testExtremeConfigurationsStayFinite(t)
    p=defaults();
    for freq=[2 25]
        for aperture=[.05 .30]
            for rotation=[0 45 80]
                p.fGHz=freq; p.D=aperture; p.pitch=rotation; p.roll=rotation;
                p.R=.4; p.useLens=true; p.lensPosition=.2; p.focal=.12;
                m=QuasiOpticalModel(p);
                verifyTrue(t,isfinite(m.wSample)&&m.wSample>0);
                verifyTrue(t,isfinite(m.wFar)&&m.wFar>0);
                if ~m.grazing
                    verifyTrue(t,isfinite(m.sampleFraction)&&isfinite(m.farFraction));
                end
            end
        end
    end
end

function testGaussianCurvatureAndDivergenceAtLaunchWaist(t)
    p=defaults(); p.R=0;
    m=QuasiOpticalModel(p); d=m.diagnostics;
    verifyTrue(t,d.available);
    verifyTrue(t,d.idealizedLaunchPlane);
    verifyEqual(t,d.qSample,1i*pi*m.w0^2/m.lambda,'AbsTol',1e-12);
    verifyEqual(t,d.inverseCurvature,0);
    verifyEqual(t,d.curvatureRadius,Inf);
    verifyEqual(t,d.phaseVariationDeg,0);
    verifyEqual(t,d.sphericalPhaseVariationDeg,0);
    verifyEqual(t,d.divergenceDeg,rad2deg(m.lambda/(pi*m.w0)),'AbsTol',1e-12);
    verifyTrue(t,any(contains(string(d.notes),'launch-plane')));
    p.R=1e-8; nearby=QuasiOpticalModel(p);
    verifyLessThan(t,abs(nearby.diagnostics.inverseCurvature),1e-5);
end

function testGaussianLensCurvatureCrossesZeroAtWaist(t)
    p=defaults(); p.useLens=true; p.focal=.12;
    baseline=QuasiOpticalModel(p); p.R=baseline.focus;
    atWaist=QuasiOpticalModel(p);
    verifyTrue(t,atWaist.useLens);
    verifyEqual(t,atWaist.diagnostics.inverseCurvature,0);
    verifyEqual(t,atWaist.diagnostics.phaseVariationDeg,0);
    verifyEqual(t,atWaist.diagnostics.activeWaistRadius,atWaist.waist,'RelTol',1e-12);
    verifyEqual(t,atWaist.wSample,atWaist.waist,'RelTol',1e-12);
    p.R=baseline.focus-.001; before=QuasiOpticalModel(p);
    p.R=baseline.focus+.001; after=QuasiOpticalModel(p);
    verifyLessThan(t,before.diagnostics.inverseCurvature,0);
    verifyGreaterThan(t,after.diagnostics.inverseCurvature,0);
    verifyEqual(t,before.diagnostics.inverseCurvature,-after.diagnostics.inverseCurvature,'RelTol',1e-11);
end

function testRotatedBoundaryMaximumAndCurvaturePhase(t)
    p=defaults(); p.theta=41; p.yaw=17; p.pitch=-19; p.roll=33;
    p.width=.19; p.height=.43;
    m=QuasiOpticalModel(p); d=m.diagnostics;
    % Independently construct a dense physical perimeter in laboratory xyz.
    u=linspace(-p.width/2,p.width/2,10001).';
    v=linspace(-p.height/2,p.height/2,10001).';
    perimeter=[u repmat(-p.height/2,size(u));u repmat(p.height/2,size(u)); ...
        repmat(-p.width/2,size(v)) v;repmat(p.width/2,size(v)) v]*[m.u;m.v];
    transverse=perimeter-(perimeter*m.ki.')*m.ki;
    rhoSquared=sum(transverse.^2,2);
    verifyEqual(t,d.minBoundaryTransverseRadius^2,min(rhoSquared),'AbsTol',1e-9);
    verifyEqual(t,d.maxTransverseRadius^2,max(rhoSquared),'AbsTol',1e-12);
    verifyEqual(t,d.boundaryFieldDB,20*log10(max(exp(-rhoSquared/m.wSample^2))),'AbsTol',1e-7);
    rayleigh=pi*m.w0^2/m.lambda;
    radius=p.R*(1+(rayleigh/p.R)^2);
    verifyEqual(t,d.curvatureRadius,radius,'RelTol',1e-12);
    verifyEqual(t,d.phaseVariationDeg,180/m.lambda*max(rhoSquared)/radius,'RelTol',1e-12);
    verifyEqual(t,d.receiverMismatchDeg,m.rxMismatch);
    verifyEqual(t,d.setup.rotation,m.rotation);
    verifyEqual(t,d.setup.projectedMetric,m.metric);
end

function testIlluminationGuidanceAndUnavailableStates(t)
    p=defaults(); p.width=.01; p.height=.01;
    m=QuasiOpticalModel(p); d=m.diagnostics;
    verifyTrue(t,d.boundaryGuidanceExceeded);
    verifyFalse(t,d.phaseGuidanceExceeded);
    verifyEqual(t,d.boundaryGuidanceDB,-20);
    verifyEqual(t,d.phaseGuidanceDeg,22.5);
    verifyTrue(t,contains(d.guidance,'not accuracy guarantees'));
    p.width=1.1; p.height=1.1; m=QuasiOpticalModel(p);
    verifyTrue(t,m.diagnostics.phaseGuidanceExceeded);
    verifyFalse(t,m.diagnostics.boundaryGuidanceExceeded);
    p.yaw=-60; m=QuasiOpticalModel(p); d=m.diagnostics;
    verifyFalse(t,d.available);
    verifyTrue(t,isnan(d.phaseVariationDeg));
    verifyTrue(t,isnan(d.boundaryFieldDB));
    verifyTrue(t,isfinite(d.curvatureRadius));
    verifyTrue(t,isfinite(d.divergenceDeg));
end

function testExactSphericalPhaseBenchmarkAndParaxialDistinction(t)
    phase=QuasiOpticalSphericalPhase(10e9,1,.1);
    verifyEqual(t,phase,59.8921791538873,'AbsTol',1e-9);
    verifyEqual(t,phase,59.9,'AbsTol',.02);
    verifyEqual(t,QuasiOpticalSphericalPhase(10e9,-1,.1),phase);
    verifyEqual(t,QuasiOpticalSphericalPhase(10e9,Inf,[0 .1]),[0 0]);
    paraxial=180*10e9/299792458*.1^2;
    verifyGreaterThan(t,paraxial,phase);
    verifyLessThan(t,paraxial-phase,.2);
    verifyError(t,@() QuasiOpticalSphericalPhase(10e9,0,.1),'QuasiOptical:ZeroCurvatureRadius');
end

function testIlluminationMetadataAndActualApertureSnapshot(t)
    p=defaults(); p.mode='Reflection'; p.hornGainDBi=20; p.D=99;
    m=QuasiOpticalModel(p); material=QuasiOpticalMaterialPreset('Lossy absorber (example)');
    response=QuasiOpticalMaterial(p,m,material);
    records=QuasiOpticalParameters(p,m,material,response,'Diagnostic snapshot');
    value=@(name) records.Value(records.Parameter==string(name));
    verifyEqual(t,str2double(value('Gaussian wavefront inverse curvature')),m.diagnostics.inverseCurvature,'RelTol',1e-10);
    verifyEqual(t,str2double(value('Estimated specimen curvature phase variation')),deg2rad(m.diagnostics.phaseVariationDeg),'RelTol',1e-10);
    verifyEqual(t,str2double(value('Strongest estimated Gaussian boundary field level')),m.diagnostics.boundaryFieldDB,'RelTol',1e-10);
    snapshot=jsondecode(value('Illumination setup snapshot'));
    verifyEqual(t,snapshot.D,m.D,'RelTol',1e-12);
    verifyEqual(t,snapshot.R,p.R);
    verifyEqual(t,snapshot.actualIncidenceDeg,m.incidence,'AbsTol',1e-12);
    verifyTrue(t,contains(value('Illumination diagnostic assumptions'),'numerical retrieval validity'));
end

function p=defaults()
    p=struct('fGHz',10,'D',.12,'R',1.2,'theta',30,'width',.5,'height',.5, ...
        'psi',0,'lensPosition',.2,'focal',.35,'useLens',false,'yaw',0,'pitch',0,'roll',0);
end
