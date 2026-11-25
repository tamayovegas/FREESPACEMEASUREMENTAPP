function tests = testQuasiOpticalMethodCatalog
tests = functiontests(localfunctions);
end

function testOnlyFreeSpaceMethods(testCase)
m = QuasiOpticalMethodCatalog;
verifyEqual(testCase,{m.id},{'NRW','NIST iterative','New non-iterative'});
verifyEqual(testCase,{m.setup},{'Free space','Free space','Free space'});
verifyFalse(testCase,any(strcmp({m.id},'SCL')));
end

function testMagneticAssumptionsAreExplicit(testCase)
m = QuasiOpticalMethodCatalog;
verifyTrue(testCase,contains(m(1).outputs,'mu_r'));
verifyTrue(testCase,contains(m(1).muTreatment,'Retrieved'));
for k = 2:3
    verifyTrue(testCase,contains(m(k).muTreatment,'Assumed mu_r = 1'));
    verifyTrue(testCase,contains(m(k).muTreatment,'not measured'));
    verifyTrue(testCase,contains(m(k).outputs,'fixed'));
end
end

function testTablesHaveSourceAndTradeoffs(testCase)
m = QuasiOpticalMethodCatalog;
verifyEqual(testCase,{m.speed},{'Fast','Slow','Fast'});
verifyEqual(testCase,{m.accuracyQualitative},{'Medium','Good','Good'});
for k = 1:numel(m)
    verifyNotEmpty(testCase,m(k).advantages);
    verifyNotEmpty(testCase,m(k).disadvantages);
    verifyTrue(testCase,ismember(11,m(k).sourcePages));
    verifyTrue(testCase,ismember(16,m(k).sourcePages));
    verifyTrue(testCase,contains(m(k).accuracyMeaning,'uncertainty'));
end
end
