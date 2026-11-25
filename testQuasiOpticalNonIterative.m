function tests=testQuasiOpticalNonIterative
    tests=functiontests(localfunctions);
end

function testLossyNonmagneticRoundTrip(t)
    f=(1:.2:20)'*1e9; d=.012; epsilon=4-.25i;
    [a,b]=slab(f,d,epsilon,1); r=QuasiOpticalNonIterative(f,a,b,d);
    verifyTrue(t,all(r.valid));
    verifyEqual(t,r.epsilon,repmat(epsilon,size(f)),'AbsTol',1e-9);
    verifyEqual(t,r.mu,ones(size(f)),'AbsTol',0);
    verifyLessThan(t,max(r.residual),1e-10);
    verifyGreaterThan(t,max(r.branch),0);
end

function testLosslessAcrossHalfWavesAndPhaseWraps(t)
    % Includes exact half-wave degeneracies as well as both sides of each.
    d=.012; n=2; fundamental=299792458/(2*n*d);
    f=sort(unique([(1:.02:30)'*1e9;fundamental*(1:4)']));
    [a,b]=slab(f,d,n^2,1); r=QuasiOpticalNonIterative(f,a,b,d);
    verifyTrue(t,all(r.valid));
    verifyEqual(t,r.epsilon,repmat(n^2,size(f)),'AbsTol',1e-6);
    verifyLessThan(t,max(r.residual),1e-7);
    verifyTrue(t,any(contains(r.status,'half-wave')));
end

function testExactIsolatedHalfWaveFinite(t)
    f=10e9; d=299792458/(4*f);
    r=QuasiOpticalNonIterative(f,0,-1,d);
    verifyTrue(t,r.valid);
    verifyEqual(t,r.epsilon,4,'AbsTol',1e-12);
    verifyEqual(t,r.mu,1,'AbsTol',0);
    verifyEqual(t,r.impedance,.5,'AbsTol',1e-12);
    verifyTrue(t,contains(r.status{1},'unobservable'));
end

function testMatchedAir(t)
    f=(1:.05:20)'*1e9; d=.017;
    [a,b]=slab(f,d,1,1); r=QuasiOpticalNonIterative(f,a,b,d);
    verifyTrue(t,all(r.valid));
    verifyEqual(t,r.epsilon,ones(size(f)),'AbsTol',1e-8);
end

function testPermittivityBelowOne(t)
    f=(1:.1:20)'*1e9; d=.012; epsilon=.25;
    [a,b]=slab(f,d,epsilon,1); r=QuasiOpticalNonIterative(f,a,b,d);
    verifyTrue(t,all(r.valid));
    verifyEqual(t,r.epsilon,repmat(epsilon,size(f)),'AbsTol',1e-9);
end

function testEvanescentNonmagneticSlab(t)
    f=(1:.2:10)'*1e9; d=.005;
    [a,b]=slab(f,d,-4,1); r=QuasiOpticalNonIterative(f,a,b,d);
    verifyTrue(t,all(r.valid));
    verifyEqual(t,r.epsilon,-4*ones(size(f)),'AbsTol',1e-9);
    verifyLessThan(t,max(abs(r.propagation)),1);
end

function testAbsoluteBranchMustBeSelected(t)
    f=20e9; d=.012; epsilon=4-.12i;
    [a,b]=slab(f,d,epsilon,1);
    r=QuasiOpticalNonIterative(f,a,b,d,struct('branch',2,'unwrapPhase',false));
    verifyTrue(t,r.valid); verifyEqual(t,r.epsilon,epsilon,'AbsTol',1e-9);
    wrong=QuasiOpticalNonIterative(f,a,b,d,struct('branch',1,'unwrapPhase',false));
    verifyFalse(t,wrong.valid);
    verifyTrue(t,contains(wrong.status{1},'selected branch'));
    verifyTrue(t,any(contains(r.notes,'branch remains an assumption')));
end

function testMagneticDataDoNotSilentlyBecomeNonmagnetic(t)
    f=(1:.5:10)'*1e9; d=.003;
    [a,b]=slab(f,d,4-.1i,1.5-.05i);
    r=QuasiOpticalNonIterative(f,a,b,d);
    verifyFalse(t,any(r.valid));
    verifyGreaterThan(t,min(r.residual),1e-3);
    verifyTrue(t,all(contains(r.status,'mu_r=1')));
end

function testTransmissionFloorAndRestart(t)
    f=(1:5)'*1e9; d=.002;
    [a,b]=slab(f,d,4-.1i,1); b(3)=0;
    r=QuasiOpticalNonIterative(f,a,b,d);
    verifyEqual(t,r.valid,[true;true;false;true;true]);
    verifyTrue(t,isnan(r.epsilon(3)));
    verifyTrue(t,contains(r.status{3},'floor'));
    verifyTrue(t,contains(r.status{4},'restarted'));
end

function testNonPassiveAndValidation(t)
    r=QuasiOpticalNonIterative(10e9,0,1.2*exp(-.2i),.002);
    verifyFalse(t,r.valid); verifyTrue(t,contains(r.status{1},'Non-passive'));
    verifyError(t,@()QuasiOpticalNonIterative(1e9,.1,.8,.002,struct('initialEpsilon',4)), ...
        'QuasiOptical:RetrievalOptions');
    verifyError(t,@()QuasiOpticalNonIterative(1e9,.1,.8,.002,struct('method','NRW')), ...
        'QuasiOptical:RetrievalMethod');
    verifyError(t,@()QuasiOpticalNonIterative(1e9,.1,.8,.002,struct('angleDeg',30)), ...
        'QuasiOptical:RetrievalGeometry');
    verifyError(t,@()QuasiOpticalNonIterative(1e9,.1,.8,.002,struct('cutoffHz',1e9)), ...
        'QuasiOptical:RetrievalGeometry');
    verifyError(t,@()QuasiOpticalNonIterative([2e9;1e9],[.1;.1],[.8;.8],.002), ...
        'QuasiOptical:RetrievalFrequency');
    verifyError(t,@()QuasiOpticalNonIterative([1e9;2e9],.1,.8,.002), ...
        'QuasiOptical:RetrievalSize');
end

function [s11,s21]=slab(f,d,epsilon,mu)
    n=sqrt(epsilon*mu);
    if imag(n)>0||(imag(n)==0&&real(n)<0), n=-n; end
    z=mu/n; g=(z-1)/(z+1);
    p=exp(-1i*2*pi*f/299792458*n*d);
    denominator=1-g^2*p.^2;
    s11=g*(1-p.^2)./denominator;
    s21=(1-g^2)*p./denominator;
end
