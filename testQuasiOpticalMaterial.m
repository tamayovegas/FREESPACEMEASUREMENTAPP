function tests=testQuasiOpticalMaterial
    tests=functiontests(localfunctions);
end

function testPEC(t)
    p=parameters(); m=QuasiOpticalModel(p); d=QuasiOpticalMaterialPreset('Perfect conductor (PEC)');
    s=QuasiOpticalMaterial(p,m,d);
    verifyEqual(t,[s.R s.T s.A],[1 0 0],'AbsTol',1e-14);
    verifyEqual(t,s.specularRCS,4*pi*(p.width*p.height)^2*cosd(p.theta)^2/m.lambda^2,'RelTol',1e-12);
end

function testAirAtObliqueIncidence(t)
    p=parameters(); d=QuasiOpticalMaterialPreset('Air / vacuum');
    for angle=[0 30 80]
        p.theta=angle; m=QuasiOpticalModel(p); s=QuasiOpticalMaterial(p,m,d);
        verifyEqual(t,[s.R s.T s.A],[0 1 0],'AbsTol',1e-12);
        verifyEqual(t,s.t(1),exp(-1i*2*pi/m.lambda*cosd(angle)*d.thicknessMM/1000),'AbsTol',1e-12);
    end
end

function testZeroThickness(t)
    p=parameters(); d=QuasiOpticalMaterialPreset('Lossy absorber (example)'); d.thicknessMM=0;
    s=QuasiOpticalMaterial(p,QuasiOpticalModel(p),d);
    verifyEqual(t,[s.R s.T s.A],[0 1 0],'AbsTol',1e-12);
end

function testQuarterAndHalfWaveSlab(t)
    p=parameters(); p.theta=0; m=QuasiOpticalModel(p);
    d=QuasiOpticalMaterialPreset('Lossless dielectric'); d.thicknessMM=1000*m.lambda/8;
    s=QuasiOpticalMaterial(p,m,d);
    verifyEqual(t,[s.R s.T s.A],[.36 .64 0],'AbsTol',1e-12);
    d.thicknessMM=2*d.thicknessMM; s=QuasiOpticalMaterial(p,m,d);
    verifyEqual(t,[s.R s.T s.A],[0 1 0],'AbsTol',1e-12);
end

function testMatchedMagneticAbsorber(t)
    p=parameters(); p.theta=0; m=QuasiOpticalModel(p);
    d=QuasiOpticalMaterialPreset('Custom material');
    d.epsReal=2; d.muReal=2; d.epsLoss=.3; d.muLoss=.3; d.thicknessMM=10;
    s=QuasiOpticalMaterial(p,m,d); expectedT=exp(-2*(2*pi/m.lambda)*.3*.01);
    verifyEqual(t,[s.R s.T s.A],[0 expectedT 1-expectedT],'AbsTol',1e-12);
end

function testConductivityEquivalentToDielectricLoss(t)
    p=parameters(); m=QuasiOpticalModel(p); d=QuasiOpticalMaterialPreset('Lossless dielectric');
    d.epsLoss=.7; a=QuasiOpticalMaterial(p,m,d);
    d.epsLoss=0; d.conductivity=2*pi*p.fGHz*1e9*8.8541878128e-12*.7;
    b=QuasiOpticalMaterial(p,m,d);
    verifyEqual(t,[a.R a.T a.A],[b.R b.T b.A],'AbsTol',1e-12);
end

function testThickMetalNoOverflow(t)
    p=parameters(); d=QuasiOpticalMaterialPreset('Metal (finite conductivity)');
    d.thicknessMM=1000; s=QuasiOpticalMaterial(p,QuasiOpticalModel(p),d);
    verifyGreaterThan(t,s.R,.999); verifyEqual(t,s.T,0);
    verifyGreaterThan(t,s.A,0); verifyTrue(t,all(isfinite([s.R s.T s.A])));
end

function testBrewsterTM(t)
    p=parameters(); p.theta=atand(2); m=QuasiOpticalModel(p);
    d=QuasiOpticalMaterialPreset('Lossless dielectric'); d.thicknessMM=3;
    s=QuasiOpticalMaterial(p,m,d);
    verifyLessThan(t,s.Rpol(2),1e-24); verifyGreaterThan(t,s.Rpol(1),.01);
end

function testCriticalAngleLimit(t)
    p=parameters(); p.theta=30; m=QuasiOpticalModel(p);
    d=QuasiOpticalMaterialPreset('Lossless dielectric'); d.epsReal=.25;
    s=QuasiOpticalMaterial(p,m,d); c=cosd(p.theta); kd=2*pi/m.lambda*d.thicknessMM/1000;
    expected=[1i*kd*c/(2+1i*kd*c),-1i*kd*.25*c/(2+1i*kd*.25*c)];
    verifyEqual(t,s.r,expected,'AbsTol',1e-12);
    verifyEqual(t,s.Rpol+s.Tpol,[1 1],'AbsTol',1e-12);
end

function testPolarizationMixAndGeometryModes(t)
    p=parameters(); p.psi=45; d=QuasiOpticalMaterialPreset('Lossy absorber (example)');
    s=QuasiOpticalMaterial(p,QuasiOpticalModel(p),d);
    verifyEqual(t,s.R,mean(s.Rpol),'AbsTol',1e-12);
    p.mode='Transmission'; q=QuasiOpticalMaterial(p,QuasiOpticalModel(p),d);
    verifyEqual(t,[s.R s.T s.A],[q.R q.T q.A],'AbsTol',1e-12);
    verifyTrue(t,isnan(q.specularRCS));
end

function testPassivityAcrossExtremes(t)
    p=parameters();
    for name={'Lossy absorber (example)','Metal (finite conductivity)','Lossless dielectric'}
        d=QuasiOpticalMaterialPreset(name{1});
        for frequency=[2 10 25]
            for angle=[0 45 89.9]
                p.fGHz=frequency; p.theta=angle; s=QuasiOpticalMaterial(p,QuasiOpticalModel(p),d);
                verifyGreaterThanOrEqual(t,[s.Rpol s.Tpol s.Apol],zeros(1,6));
                verifyLessThanOrEqual(t,[s.Rpol s.Tpol s.Apol],ones(1,6)+1e-10);
                verifyEqual(t,s.Rpol+s.Tpol+s.Apol,[1 1],'AbsTol',1e-10);
            end
        end
    end
end

function testExactGrazingUnavailable(t)
    p=parameters(); p.yaw=-60; d=QuasiOpticalMaterialPreset('Lossless dielectric');
    s=QuasiOpticalMaterial(p,QuasiOpticalModel(p),d);
    verifyFalse(t,s.valid); verifyTrue(t,isnan(s.R));
end

function p=parameters()
    p=struct('fGHz',10,'D',.12,'R',1.2,'theta',30,'width',.5,'height',.5, ...
        'psi',0,'lensPosition',.2,'focal',.35,'useLens',false,'yaw',0,'pitch',0,'roll',0,'mode','Reflection');
end
