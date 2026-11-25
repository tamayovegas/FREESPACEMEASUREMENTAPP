function tests=testQuasiOpticalNIST
    tests=functiontests(localfunctions);
end

function testLossyNonmagneticRoundTrip(t)
    f=(2:.5:12)'*1e9; thickness=.003; epsilon=4-.24i;
    [a,b]=slab(f,thickness,epsilon,1);
    r=QuasiOpticalNIST(f,a,b,thickness,struct('initialEpsilon',3.5-.1i));
    verifyTrue(t,all(r.valid)); verifyTrue(t,all(r.converged));
    verifyEqual(t,r.epsilon,repmat(epsilon,size(f)),'AbsTol',1e-7);
    verifyEqual(t,r.mu,ones(size(f)));
    verifyLessThan(t,max(r.objectiveResidual),1e-9);
    verifyLessThan(t,max(r.residual),1e-8);
    verifyTrue(t,any(contains(r.notes,'assumed, not measured')));
end

function testLosslessHalfWaveIsNotNRWSingularity(t)
    f=10e9; thickness=299792458/(4*f);
    [a,b]=slab(f,thickness,4,1);
    verifyLessThan(t,abs(a),1e-14);
    r=QuasiOpticalNIST(f,a,b,thickness,struct('initialEpsilon',3.7-.02i));
    verifyTrue(t,r.valid); verifyEqual(t,r.epsilon,4,'AbsTol',1e-7);
    verifyLessThan(t,r.residual,1e-8);
end

function testDenseFrequencyContinuationAcrossPhaseTurns(t)
    f=(1:.1:20)'*1e9; thickness=.012; epsilon=4-.12i;
    [a,b]=slab(f,thickness,epsilon,1);
    r=QuasiOpticalNIST(f,a,b,thickness,struct('initialEpsilon',3.5-.1i));
    verifyTrue(t,all(r.valid));
    verifyEqual(t,r.epsilon,repmat(epsilon,size(f)),'AbsTol',1e-7);
    verifyGreaterThan(t,max(r.branch),0);
    verifyTrue(t,isnan(r.selectedBranch));
end

function testWrongDeterminantRootFailsChannelReconstruction(t)
    f=10e9; thickness=299792458/(4*f);
    [a,b]=slab(f,thickness,4,1);
    % epsilon=16 has the same determinant but the wrong transmission sign.
    r=QuasiOpticalNIST(f,a,b,thickness,struct('initialEpsilon',16));
    verifyTrue(t,r.converged); verifyFalse(t,r.valid);
    verifyLessThan(t,r.objectiveResidual,1e-12);
    verifyGreaterThan(t,r.residual,1);
    verifyTrue(t,contains(r.status{1},'individual S channels'));
end

function testInconsistentMagneticDataRejected(t)
    f=(5:1:10)'*1e9; thickness=.003;
    [a,b]=slab(f,thickness,4-.2i,1.4-.1i);
    r=QuasiOpticalNIST(f,a,b,thickness,struct('initialEpsilon',4-.1i));
    verifyFalse(t,any(r.valid));
    verifyTrue(t,all(contains(r.status,'individual S channels')));
    verifyGreaterThan(t,min(r.residual),1e-4);
    verifyEqual(t,r.mu,ones(size(f)));
end

function testNonconvergenceIsNotAccepted(t)
    f=10e9; [a,b]=slab(f,.004,4-.24i,1);
    r=QuasiOpticalNIST(f,a,b,.004,struct('initialEpsilon',.2-.001i,'maxIterations',1,'tolerance',1e-13));
    verifyFalse(t,r.valid); verifyFalse(t,r.converged);
    verifyTrue(t,contains(r.status{1},'did not converge'));
    verifyEqual(t,r.iterations,1);
end

function testOpaqueAndNonpassiveDataAreFlagged(t)
    r=QuasiOpticalNIST(10e9,-.95,0,.002,struct('initialEpsilon',4-.1i));
    verifyFalse(t,r.valid); verifyTrue(t,contains(r.status{1},'floor'));
    [a,b]=slab(10e9,.002,4+.2i,1);
    r=QuasiOpticalNIST(10e9,a,b,.002,struct('initialEpsilon',4+.1i));
    verifyFalse(t,r.valid); verifyTrue(t,contains(r.status{1},'Non-passive'));
end

function testReferenceGeometryAndInitialGuessValidation(t)
    o=struct('initialEpsilon',4-.1i,'angleDeg',20);
    verifyError(t,@()QuasiOpticalNIST(10e9,.1,.8,.002,o),'QuasiOptical:RetrievalGeometry');
    o.angleDeg=0; o.cutoffHz=1e9;
    verifyError(t,@()QuasiOpticalNIST(10e9,.1,.8,.002,o),'QuasiOptical:RetrievalGeometry');
    verifyError(t,@()QuasiOpticalNIST(10e9,.1,.8,.002),'QuasiOptical:RetrievalInitialGuess');
    verifyError(t,@()QuasiOpticalNIST(10e9,.1,.8,.002,struct('initialEpsilon',4,'branch',1)),'QuasiOptical:RetrievalBranch');
    verifyError(t,@()QuasiOpticalNIST([2e9;1e9],[.1;.1],[.8;.8],.002,struct('initialEpsilon',4)),'QuasiOptical:RetrievalFrequency');
    verifyError(t,@()QuasiOpticalNIST(10e9,.1,.8,0,struct('initialEpsilon',4)),'MATLAB:QuasiOpticalNIST:expectedPositive');
end

function [s11,s21]=slab(f,thickness,epsilon,mu)
    n=sqrt(epsilon*mu); z=sqrt(mu/epsilon);
    gamma=(z-1)/(z+1); propagation=exp(-1i*2*pi*f/299792458*n*thickness);
    denominator=1-gamma^2*propagation.^2;
    s11=gamma*(1-propagation.^2)./denominator;
    s21=(1-gamma^2)*propagation./denominator;
end
