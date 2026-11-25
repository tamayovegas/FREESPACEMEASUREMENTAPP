function tests=testQuasiOpticalSweepPlan
    tests=functiontests(localfunctions);
end
function testCountsAndFrequencySamples(t)
    p=QuasiOpticalSweepPlan(struct('angleCount',5,'azimuthCount',3, ...
        'orientationCount',2,'frequencyCount',101,'polarizationChannels',4));
    verifyEqual(t,p.nConfigurations,30);
    verifyEqual(t,p.nChannelsPerConfiguration,8);
    verifyEqual(t,p.nTraceAcquisitions,240);
    verifyEqual(t,p.nComplexSamples,24240);
    verifyEqual(t,p.nSParameterPairs,12120);
    verifyEqual(t,p.nCoPolarizedPairs,6060);
    verifyEqual(t,p.nCrossPolarizedPairs,6060);
    verifyTrue(t,p.nrwEligible);
    zero=QuasiOpticalSweepPlan(struct('angleStartDeg',0,'angleStopDeg',0,'angleCount',1));
    verifyTrue(t,zero.nrwEligible);
    grazing=QuasiOpticalSweepPlan(struct('angleStartDeg',89.99999,'angleStopDeg',89.99999,'angleCount',1));
    verifyFalse(t,grazing.nrwEligible);
end
function testOneSettingUsesStartAndNormalizesUnusedStop(t)
    p=QuasiOpticalSweepPlan(struct('angleStartDeg',0,'angleStopDeg',60, ...
        'angleCount',1,'azimuthStartDeg',25,'azimuthStopDeg',90,'azimuthCount',1));
    verifyEqual(t,p.anglesDeg,0);
    verifyEqual(t,p.azimuthDeg,25);
    verifyEqual(t,p.config.angleStopDeg,0);
    verifyEqual(t,p.config.azimuthStopDeg,25);
    verifyTrue(t,p.nrwEligible);
end
function testReflectionOnlyDoesNotSupplyPair(t)
    p=QuasiOpticalSweepPlan(struct('geometry','Reflection arc', ...
        'angleCount',3,'azimuthCount',1,'frequencyCount',11));
    verifyEqual(t,p.nBlocks,1);
    verifyEqual(t,p.nTraceAcquisitions,6);
    verifyEqual(t,p.nComplexSamples,66);
    verifyEqual(t,p.nSParameterPairs,0);
    verifyFalse(t,p.scalarRetrievalEligible);
    verifyTrue(t,p.hasReflection);
    verifyFalse(t,p.hasTransmission);
end
function testTransmissionAndObservation(t)
    p=QuasiOpticalSweepPlan(struct('geometry','Transmission line', ...
        'scanKind','Rx observation arc','angleStartDeg',-60));
    verifyFalse(t,p.hasReflection);
    verifyTrue(t,p.hasTransmission);
    verifyFalse(t,p.scalarRetrievalEligible);
    verifyEqual(t,p.nSParameterPairs,0);
    verifyTrue(t,contains(strjoin(p.messages),'not an incidence sweep'));
end
function testScheduledRepeatsDoNotClaimIndependence(t)
    p=QuasiOpticalSweepPlan(struct('angleStartDeg',10,'angleStopDeg',10, ...
        'angleCount',3,'azimuthStartDeg',0,'azimuthStopDeg',360,'azimuthCount',2));
    verifyEqual(t,p.nConfigurations,6);
    verifyTrue(t,contains(strjoin(p.messages),'scheduled repeats'));
    verifyTrue(t,contains(strjoin(p.messages),'do not add new angular projections'));
end
function testInvalidAnglesAndCounts(t)
    verifyError(t,@()QuasiOpticalSweepPlan(struct('angleStopDeg',90)), ...
        'QuasiOptical:SweepIncidence');
    verifyError(t,@()QuasiOpticalSweepPlan(struct('polarizationChannels',3)), ...
        'QuasiOptical:SweepPolarization');
    verifyError(t,@()QuasiOpticalSweepPlan(struct('scanKind','Rx observation arc', ...
        'angleStartDeg',-181)),'QuasiOptical:SweepObservation');
end
