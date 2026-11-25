function tests=testQuasiOpticalOblique
    tests=functiontests(localfunctions);
end

function testDielectricAndMagneticAcrossAngles(t)
    f=linspace(1e9,15e9,41).'; thickness=.002;
    for material=[4-.08i 3.2-.3i;1 1.6-.12i]
        for theta=[0 15 30 45 60]
            for pol={'TE','TM'}
                s=QuasiOpticalSlabRT(f,thickness,material(1),material(2),theta,pol{1});
                r=QuasiOpticalRetrieve(f,s.r,s.t,thickness,struct('angleDeg',theta,'polarization',pol{1}));
                verifyTrue(t,all(r.valid),strjoin(r.status));
                verifyLessThan(t,max(abs(r.epsilon-material(1))),1e-8);
                verifyLessThan(t,max(abs(r.mu-material(2))),1e-8);
                verifyLessThan(t,max(r.residual),1e-10);
                verifyEqual(t,r.q,s.q,'AbsTol',1e-10);
                verifyEqual(t,r.kz,s.kz,'AbsTol',1e-8);
                verifyEqual(t,r.z,s.z,'AbsTol',1e-10);
                verifyEqual(t,r.n.^2,r.epsilon.*r.mu,'AbsTol',1e-10);
                verifyGreaterThanOrEqual(t,min(real(r.n.*conj(r.q))),0);
            end
        end
    end
end

function testPaperFortyFiveDegreeBenchmark(t)
    f=6e9; d=.010; epsilon=4-.08i; mu=1; theta=45;
    expectedMagnitudeR=[.614 .282]; expectedPhaseR=[147.1 137.8]; expectedMagnitudeT=[.763 .934];
    for j=1:2
        pol={'TE','TM'}; pol=pol{j};
        s=QuasiOpticalSlabRT(f,d,epsilon,mu,theta,pol);
        verifyEqual(t,abs(s.r),expectedMagnitudeR(j),'AbsTol',.0005);
        verifyEqual(t,angle(s.r)*180/pi,expectedPhaseR(j),'AbsTol',.05);
        verifyEqual(t,abs(s.t),expectedMagnitudeT(j),'AbsTol',.0005);
        r=QuasiOpticalRetrieve(f,s.r,s.t,d,struct('angleDeg',theta,'polarization',pol));
        verifyTrue(t,r.valid); verifyEqual(t,r.epsilon,epsilon,'AbsTol',1e-10);
        verifyEqual(t,r.mu,mu,'AbsTol',1e-10); verifyLessThan(t,r.residual,1e-10);
        wrong=QuasiOpticalRetrieve(f,s.r,s.t,d,struct('angleDeg',0,'polarization',pol));
        if j==1
            expectedMu=mu*cosd(theta); expectedEpsilon=(epsilon*mu-sind(theta)^2)/expectedMu;
        else
            expectedEpsilon=epsilon*cosd(theta); expectedMu=(epsilon*mu-sind(theta)^2)/expectedEpsilon;
        end
        verifyEqual(t,wrong.epsilon,expectedEpsilon,'AbsTol',1e-10);
        verifyEqual(t,wrong.mu,expectedMu,'AbsTol',1e-10);
        verifyGreaterThan(t,abs(wrong.epsilon-epsilon),.9);
    end
end

function testBrewsterMatchedReflection(t)
    f=6e9; theta=atand(2); d=.003;
    s=QuasiOpticalSlabRT(f,d,4,1,theta,'TM');
    verifyLessThan(t,abs(s.r),1e-14);
    r=QuasiOpticalRetrieve(f,s.r,s.t,d,struct('angleDeg',theta,'polarization','TM'));
    verifyTrue(t,r.valid); verifyEqual(t,r.epsilon,4,'AbsTol',1e-10);
    verifyEqual(t,r.mu,1,'AbsTol',1e-10);
end

function testHalfWaveWeakTransmissionAndCriticalConversion(t)
    f=10e9; theta=45; q=sqrt(4-sind(theta)^2); d=299792458/(2*f*q);
    for pol={'TE','TM'}
        s=QuasiOpticalSlabRT(f,d,4,1,theta,pol{1});
        r=QuasiOpticalRetrieve(f,s.r,s.t,d,struct('angleDeg',theta,'polarization',pol{1}));
        verifyFalse(t,r.valid); verifyTrue(t,contains(r.status{1},'singular'));
        r=QuasiOpticalRetrieve(f,-.95,1e-12,.002,struct('angleDeg',theta,'polarization',pol{1}));
        verifyFalse(t,r.valid); verifyTrue(t,contains(r.status{1},'floor'));
        % Exact critical normal propagation is finite in the forward model,
        % but it makes the separated constitutive NRW conversion singular.
        s=QuasiOpticalSlabRT(f,.002,sind(theta)^2,1,theta,pol{1});
        verifyTrue(t,s.valid);
        r=QuasiOpticalRetrieve(f,s.r,s.t,.002,struct('angleDeg',theta,'polarization',pol{1}));
        verifyFalse(t,r.valid);
    end
end

function testInvalidAnglesAndPolarization(t)
    for theta=[-1 90 91 180 89.99999]
        verifyError(t,@()QuasiOpticalRetrieve(6e9,.1,.8,.01,struct('angleDeg',theta)), ...
            'QuasiOptical:RetrievalGeometry');
    end
    verifyError(t,@()QuasiOpticalRetrieve(6e9,.1,.8,.01,struct('polarization','mixed')), ...
        'QuasiOptical:RetrievalPolarization');
end

function testPhaseGapAndAbsoluteBranch(t)
    f=linspace(1e9,20e9,191).'; d=.012; theta=45;
    s=QuasiOpticalSlabRT(f,d,4-.12i,1-.03i,theta,'TE');
    r=QuasiOpticalRetrieve(f,s.r,s.t,d,struct('angleDeg',theta));
    verifyTrue(t,all(r.valid)); verifyEqual(t,r.epsilon,repmat(4-.12i,size(f)),'AbsTol',1e-8);
    s.t(81)=0; gap=QuasiOpticalRetrieve(f,s.r,s.t,d,struct('angleDeg',theta));
    verifyFalse(t,gap.valid(81)); verifyTrue(t,isnan(gap.q(81)));
    verifyTrue(t,any(contains(gap.status(82:end),'phase restarted')));
    single=QuasiOpticalRetrieve(f(end),s.r(end),s.t(end),d, ...
        struct('angleDeg',theta,'branch',r.branch(end),'unwrapPhase',false));
    verifyEqual(t,single.epsilon,4-.12i,'AbsTol',1e-8);
end

function testObliqueNonpassiveAndFourChannelChecks(t)
    r=QuasiOpticalRetrieve(6e9,0,1.2*exp(-.2i),.002,struct('angleDeg',45));
    verifyFalse(t,r.valid); verifyTrue(t,contains(r.status{1},'Non-passive'));
    f=(4:8)'*1e9; d=.002; s=QuasiOpticalSlabRT(f,d,4-.08i,1,45,'TM');
    data=struct('fHz',f,'s11',s.r,'s21',s.t,'s12',s.t,'s22',s.r);
    o=struct('angleDeg',45,'polarization','TM');
    r=QuasiOpticalRetrieveData(data,d,o,'four'); verifyTrue(t,all(r.valid));
    data.s11=data.s11+.02; data.s22=data.s22-.02;
    r=QuasiOpticalRetrieveData(data,d,o,'four');
    verifyFalse(t,any(r.valid)); verifyTrue(t,all(contains(r.status,'four raw channels')));
end

function testForwardMatchesExistingSimulation(t)
    p=struct('fGHz',6,'D',.12,'R',1.2,'theta',45,'width',.5,'height',.5, ...
        'psi',0,'lensPosition',.2,'focal',.35,'useLens',false,'yaw',0,'pitch',0,'roll',0,'mode','Transmission');
    d=QuasiOpticalMaterialPreset('Custom material');
    d.epsReal=4; d.epsLoss=.08; d.muReal=1.3; d.muLoss=.02; d.conductivity=0; d.thicknessMM=10;
    existing=QuasiOpticalMaterial(p,QuasiOpticalModel(p),d);
    for k=1:2
        pol={'TE','TM'}; s=QuasiOpticalSlabRT(6e9,.01,4-.08i,1.3-.02i,45,pol{k});
        verifyEqual(t,s.r,existing.r(k),'AbsTol',1e-13); verifyEqual(t,s.t,existing.t(k),'AbsTol',1e-13);
    end
end
