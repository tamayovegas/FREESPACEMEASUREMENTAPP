function tests=testQuasiOpticalComparison
    tests=functiontests(localfunctions);
end
function testBenchmarkBothPolarizations(t)
    for pol={'TE','TM'}
        [data,other,spec]=QuasiOpticalSynthetic('Paper benchmark',[],pol{1});
        verifyTrue(t,data.synthetic.generated); verifyFalse(t,data.synthetic.isMeasurement);
        verifyEqual(t,data.fHz,6e9); verifyEqual(t,spec.thicknessM,.010); verifyEqual(t,spec.angleDeg,45);
        primary=QuasiOpticalRetrieveData(data,spec.thicknessM,struct('angleDeg',spec.angleDeg,'polarization',pol{1}),'pair');
        second=struct('angleDeg',other.angleDeg,'thicknessM',other.thicknessM,'polarization',other.polarization);
        comparison=QuasiOpticalComparePolarizations(primary,other,second,'pair');
        verifyTrue(t,all(comparison.valid)); verifyLessThan(t,max(abs(comparison.deltaEpsilon)),1e-8);
        verifyLessThan(t,max(abs(comparison.deltaMu)),1e-8);
        verifyEqual(t,comparison.TE.epsilon,4-.08i,'AbsTol',1e-8);
        verifyLessThan(t,max(comparison.TE.residual),1e-10); verifyLessThan(t,max(comparison.TM.residual),1e-10);
    end
end
function testComparisonRequiresMatchingExperiment(t)
    [data,other,spec]=QuasiOpticalSynthetic('Paper benchmark');
    primary=QuasiOpticalRetrieveData(data,spec.thicknessM,struct('angleDeg',45,'polarization','TE'),'pair');
    second=struct('angleDeg',45,'thicknessM',.010,'polarization','TM');
    changed=second; changed.angleDeg=30;
    verifyError(t,@() QuasiOpticalComparePolarizations(primary,other,changed),'QuasiOptical:ComparisonAngle');
    changed=second; changed.thicknessM=.011;
    verifyError(t,@() QuasiOpticalComparePolarizations(primary,other,changed),'QuasiOptical:ComparisonThickness');
    changed=second; changed.polarization='TE';
    verifyError(t,@() QuasiOpticalComparePolarizations(primary,other,changed),'QuasiOptical:ComparisonPolarization');
    changedData=other; changedData.fHz=other.fHz+1;
    verifyError(t,@() QuasiOpticalComparePolarizations(primary,changedData,second),'QuasiOptical:ComparisonGrid');
end
function testBroadbandUsesSelectedBandAndMaterial(t)
    material=struct('preset','Custom material','thicknessMM',2,'epsReal',3.2,'epsLoss',.04,'muReal',1.3,'muLoss',.02,'conductivity',.003);
    setup=struct('parameters',struct('fGHz',8),'model',struct('materialSweepGHz',linspace(4,12,41),'incidence',30),'materialInput',material);
    [data,other,spec]=QuasiOpticalSynthetic('Current simulation band + material',setup,'TE');
    verifyEqual(t,data.fHz,setup.model.materialSweepGHz(:)*1e9);
    expected=3.2-1i*(.04+.003./(2*pi*data.fHz*8.8541878128e-12));
    verifyEqual(t,data.synthetic.epsilon,expected,'AbsTol',1e-14);
    r=QuasiOpticalRetrieveData(data,spec.thicknessM,struct('angleDeg',30,'polarization','TE'),'four');
    c=QuasiOpticalComparePolarizations(r,other,struct('angleDeg',30,'thicknessM',.002,'polarization','TM'),'four');
    verifyTrue(t,all(c.valid)); verifyLessThan(t,max(abs(c.TE.epsilon-expected)),1e-8);
    verifyLessThan(t,max(abs(c.deltaEpsilon)),1e-8); verifyLessThan(t,max(c.TM.residual),1e-10);
end
function testUnretrievableSyntheticSetupsRejected(t)
    material=struct('preset','Perfect conductor (PEC)','thicknessMM',2);
    setup=struct('parameters',struct,'model',struct('materialSweepGHz',[4 8],'incidence',30),'materialInput',material);
    verifyError(t,@()QuasiOpticalSynthetic('Current simulation band + material',setup),'QuasiOptical:SyntheticPEC');
    material=struct('preset','Custom material','thicknessMM',0,'epsReal',3,'epsLoss',.01,'muReal',1,'muLoss',0,'conductivity',0);
    setup.materialInput=material;
    verifyError(t,@()QuasiOpticalSynthetic('Current simulation band + material',setup),'QuasiOptical:SyntheticThickness');
end

function testSyntheticHighBandBranchUsesKnownTruth(t)
    material=struct('preset','Custom material','thicknessMM',10,'epsReal',4,'epsLoss',.08,'muReal',1,'muLoss',0,'conductivity',0);
    setup=struct('parameters',struct,'model',struct('materialSweepGHz',linspace(20,25,30),'incidence',45),'materialInput',material);
    [data,~,spec]=QuasiOpticalSynthetic('Current simulation band + material',setup,'TM');
    verifyGreaterThan(t,spec.branch,0);
    r=QuasiOpticalRetrieveData(data,spec.thicknessM,struct('angleDeg',45,'polarization','TM','branch',spec.branch),'pair');
    verifyTrue(t,all(r.valid)); verifyLessThan(t,max(abs(r.epsilon-(4-.08i))),1e-8);
    verifyLessThan(t,max(abs(r.mu-1)),1e-8);
end
