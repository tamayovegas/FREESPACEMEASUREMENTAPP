function tests=testQuasiOpticalMethodDispatch
    tests=functiontests(localfunctions);
end
function testThreeMethodsThroughPublicDispatcher(t)
    [data,epsilon,d]=sample();
    for name={'NRW','NIST iterative','New non-iterative'}
        options=struct('method',name{1});
        if strcmp(name{1},'NIST iterative'), options.initialEpsilon=4-.1i; end
        r=QuasiOpticalRetrieveData(data,d,options,'pair');
        verifyTrue(t,all(r.valid),strjoin(r.status));
        verifyEqual(t,r.epsilon,repmat(epsilon,size(data.fHz)),'AbsTol',1e-7);
        verifyEqual(t,r.mu,ones(size(data.fHz)),'AbsTol',1e-7);
        verifyEqual(t,r.muAssumed,~strcmp(name{1},'NRW'));
    end
end
function testAllFourProjectedAndReconstructed(t)
    [data,epsilon,d]=sample(); data.s12=data.s21; data.s22=data.s11;
    r=QuasiOpticalRetrieveData(data,d,struct('method','New non-iterative'),'four');
    verifyTrue(t,all(r.valid)); verifyEqual(t,r.channelMode,'four');
    verifyEqual(t,r.epsilon,repmat(epsilon,size(data.fHz)),'AbsTol',1e-8);
    verifyEqual(t,r.inputAsymmetry,zeros(size(data.fHz)),'AbsTol',1e-12);
    verifyLessThan(t,max(r.residual),1e-9);
end
function testFourAsymmetricInputsAreNotSilentlyAccepted(t)
    [data,~,d]=sample(); data.s12=data.s21; data.s22=data.s11-.02; data.s11=data.s11+.02;
    r=QuasiOpticalRetrieveData(data,d,struct('method','NRW'),'four');
    verifyFalse(t,any(r.valid));
    verifyTrue(t,all(contains(r.status,'four raw channels')));
    verifyGreaterThan(t,min(r.inputAsymmetry),.039);
end
function testOnlyFreeSpaceMethodsAndCompleteChannels(t)
    [data,~,d]=sample();
    verifyError(t,@()QuasiOpticalRetrieveData(data,d,struct,'four'),'QuasiOptical:FourChannels');
    verifyError(t,@()QuasiOpticalRetrieve(data.fHz,data.s11,data.s21,d,struct('method','SCL')),'QuasiOptical:RetrievalMethod');
    for name={'NIST iterative','New non-iterative'}
        o=struct('method',name{1},'angleDeg',10); if strcmp(name{1},'NIST iterative'),o.initialEpsilon=4-.1i;end
        verifyError(t,@()QuasiOpticalRetrieve(data.fHz,data.s11,data.s21,d,o),'QuasiOptical:RetrievalGeometry');
    end
end
function [data,epsilon,d]=sample()
    f=linspace(5e9,12e9,19).'; epsilon=4-.2i; d=.002; n=sqrt(epsilon); g=(1-n)/(1+n);
    P=exp(-1i*2*pi*f/299792458*n*d);
    data=struct('fHz',f,'s11',g*(1-P.^2)./(1-g^2*P.^2), ...
        's21',(1-g^2)*P./(1-g^2*P.^2));
end

function testRawFourChannelPassivityCannotBeHiddenByTolerance(t)
    [data,~,d]=sample(); data.s12=data.s21; data.s22=data.s11-2; data.s11=data.s11+2;
    r=QuasiOpticalRetrieveData(data,d,struct('method','NRW','reconstructionTolerance',100),'four');
    verifyFalse(t,any(r.valid));
    verifyTrue(t,all(contains(r.status,'raw two-port channels are non-passive')));
    verifyGreaterThan(t,min(r.rawMaximumPowerGain),1);
end
function testMalformedDataRejectedBeforeProjection(t)
    [data,~,d]=sample(); data.s21=data.s21(1:2);
    rejected=false;
    try
        QuasiOpticalRetrieveData(data,d,struct,'four');
    catch err
        rejected=true; verifyFalse(t,contains(err.message,'incompatible sizes'));
    end
    verifyTrue(t,rejected,'Mismatched raw channels must be rejected.');
    repeated=repmat(struct('fHz',1e9,'s11',.1,'s21',.8),1,2);
    verifyError(t,@()QuasiOpticalRetrieveData(repeated,d,struct,'pair'),'QuasiOptical:RetrievalData');
end
