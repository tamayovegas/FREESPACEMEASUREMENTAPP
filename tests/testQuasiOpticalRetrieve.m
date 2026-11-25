function tests=testQuasiOpticalRetrieve
    tests=functiontests(localfunctions);
end

function testLossyMagneticRoundTrip(t)
    f=(2:1:12)'*1e9; thickness=.002;
    epsilon=4-.24i; mu=1.3-.08i;
    [s11,s21]=slab(f,thickness,epsilon,mu);
    r=QuasiOpticalRetrieve(f,s11,s21,thickness);
    verifyTrue(t,all(r.valid));
    verifyEqual(t,r.epsilon,repmat(epsilon,size(f)),'AbsTol',1e-10);
    verifyEqual(t,r.mu,repmat(mu,size(f)),'AbsTol',1e-10);
    verifyLessThan(t,max(r.residual),1e-12);
end

function testMatchedSlabWithZeroReflection(t)
    f=(2:2:10)'*1e9; thickness=.003;
    [s11,s21]=slab(f,thickness,2-.3i,2-.3i);
    verifyLessThan(t,max(abs(s11)),1e-14);
    r=QuasiOpticalRetrieve(f,s11,s21,thickness);
    verifyTrue(t,all(r.valid));
    verifyEqual(t,r.epsilon,repmat(2-.3i,size(f)),'AbsTol',1e-10);
    verifyEqual(t,r.mu,r.epsilon,'AbsTol',1e-10);
end

function testLosslessEvanescentImpedanceSign(t)
    f=5e9; thickness=.003; n=-2i; impedance=-.5i;
    gamma=(impedance-1)/(impedance+1); propagation=exp(-1i*2*pi*f/299792458*n*thickness);
    denominator=1-gamma^2*propagation^2;
    s11=gamma*(1-propagation^2)/denominator;
    s21=(1-gamma^2)*propagation/denominator;
    r=QuasiOpticalRetrieve(f,s11,s21,thickness);
    verifyTrue(t,r.valid);
    verifyEqual(t,r.epsilon,4,'AbsTol',1e-10);
    verifyEqual(t,r.mu,-1,'AbsTol',1e-10);
    verifyLessThan(t,abs(r.propagation),1);
end

function testContinuousPhaseAcrossTurns(t)
    f=(1:.1:20)'*1e9; thickness=.012; epsilon=4-.12i; mu=1-.03i;
    [s11,s21]=slab(f,thickness,epsilon,mu);
    r=QuasiOpticalRetrieve(f,s11,s21,thickness);
    verifyTrue(t,all(r.valid));
    verifyEqual(t,r.epsilon,repmat(epsilon,size(f)),'AbsTol',1e-9);
    verifyEqual(t,r.mu,repmat(mu,size(f)),'AbsTol',1e-9);
    verifyGreaterThan(t,max(r.branch),0);
end

function testManualAbsoluteBranch(t)
    f=20e9; thickness=.012;
    [s11,s21]=slab(f,thickness,4-.12i,1-.03i);
    r=QuasiOpticalRetrieve(f,s11,s21,thickness,struct('branch',2,'unwrapPhase',false));
    verifyTrue(t,r.valid);
    verifyEqual(t,r.epsilon,4-.12i,'AbsTol',1e-9);
    verifyEqual(t,r.mu,1-.03i,'AbsTol',1e-9);
    verifyEqual(t,r.branch,2);
end

function testHalfWaveAndOpaqueAreUnavailable(t)
    f=10e9; thickness=299792458/(4*f);
    [s11,s21]=slab(f,thickness,4,1);
    r=QuasiOpticalRetrieve(f,s11,s21,thickness);
    verifyFalse(t,r.valid); verifyTrue(t,isnan(r.epsilon));
    verifyTrue(t,contains(r.status{1},'singular'));
    r=QuasiOpticalRetrieve(f,-.95,0,.002);
    verifyFalse(t,r.valid); verifyTrue(t,isnan(r.mu));
    verifyTrue(t,contains(r.status{1},'floor'));
end

function testGeometryAndFrequencyValidation(t)
    verifyError(t,@()QuasiOpticalRetrieve(10e9,.1,.8,.002,struct('angleDeg',90)), ...
        'QuasiOptical:RetrievalGeometry');
    verifyError(t,@()QuasiOpticalRetrieve([2e9;1e9],[.1;.1],[.8;.8],.002), ...
        'QuasiOptical:RetrievalFrequency');
    verifyError(t,@()QuasiOpticalRetrieve([1e9;1e9],[.1;.1],[.8;.8],.002), ...
        'QuasiOptical:RetrievalFrequency');
end

function testNonPassiveDataFlagged(t)
    r=QuasiOpticalRetrieve(10e9,0,1.2*exp(-.2i),.002);
    verifyFalse(t,r.valid);
    verifyTrue(t,contains(r.status{1},'Non-passive'));
end

function testCSVRealImagSorting(t)
    file=[tempname '.csv']; cleanup=onCleanup(@()delete(file)); %#ok<NASGU>
    write(file,sprintf('frequency_GHz,S11_real,S11_imag,S21_real,S21_imag,S12_real,S12_imag\n2,0.1,-0.2,0.3,-0.4,0.3,-0.4\n1,0.2,-0.1,0.4,-0.3,0.4,-0.3\n'));
    d=QuasiOpticalReadSParameters(file);
    verifyEqual(t,d.fHz,[1;2]*1e9);
    verifyEqual(t,d.s11,[.2-.1i;.1-.2i],'AbsTol',1e-14);
    verifyEqual(t,d.s21,d.s12,'AbsTol',1e-14);
end

function testCSVMagnitudePhaseFormats(t)
    file=[tempname '.csv']; cleanup=onCleanup(@()delete(file)); %#ok<NASGU>
    write(file,sprintf('frequency_Hz,S11_dB,S11_phase_deg,S21_mag,S21_phase_rad\n1e9,-20,90,0.5,-1.570796326794897\n'));
    d=QuasiOpticalReadSParameters(file);
    verifyEqual(t,d.s11,.1i,'AbsTol',1e-14);
    verifyEqual(t,d.s21,-.5i,'AbsTol',1e-14);
end

function testCSVRejectsIncompleteAndDuplicateData(t)
    file=[tempname '.csv']; cleanup=onCleanup(@()delete(file)); %#ok<NASGU>
    write(file,sprintf('frequency_Hz,S11_mag,S21_mag\n1e9,.1,.5\n'));
    verifyError(t,@()QuasiOpticalReadSParameters(file),'QuasiOptical:SParameterCSV');
    write(file,sprintf('frequency_Hz,S11_real,S11_imag,S21_real,S21_imag\n1e9,.1,0,.5,0\n1e9,.2,0,.6,0\n'));
    verifyError(t,@()QuasiOpticalReadSParameters(file),'QuasiOptical:SParameterFrequency');
    write(file,sprintf('frequency,S11_real,S11_imag,S21_real,S21_imag\n1,.1,0,.5,0\n'));
    verifyError(t,@()QuasiOpticalReadSParameters(file),'QuasiOptical:SParameterCSV');
end

function testTouchstoneRIAndContinuation(t)
    file=[tempname '.s2p']; cleanup=onCleanup(@()delete(file)); %#ok<NASGU>
    write(file,sprintf('! test data\n# MHz S RI R 50\n2000 .1 -.2 .3 -.4 ! inline comment\n.3 -.4 .2 -.1\n1000 .2 -.1 .4 -.3 .4 -.3 .1 -.2\n'));
    d=QuasiOpticalReadSParameters(file);
    verifyEqual(t,d.fHz,[1;2]*1e9);
    verifyEqual(t,d.s11,[.2-.1i;.1-.2i],'AbsTol',1e-14);
    verifyEqual(t,d.s21,[.4-.3i;.3-.4i],'AbsTol',1e-14);
    verifyEqual(t,d.referenceOhms,50);
end

function testTouchstoneMagnitudeFormats(t)
    file=[tempname '.s2p']; cleanup=onCleanup(@()delete(file)); %#ok<NASGU>
    write(file,sprintf('# GHz S MA R 75\n1 .1 90 .5 -90 .5 -90 .2 0\n'));
    d=QuasiOpticalReadSParameters(file);
    verifyEqual(t,d.s11,.1i,'AbsTol',1e-14);
    verifyEqual(t,d.s21,-.5i,'AbsTol',1e-14);
    write(file,sprintf('# Hz S DB R 50\n1D9 -20 90 -6.020599913279624 -90 -6.020599913279624 -90 -20 0\n'));
    d=QuasiOpticalReadSParameters(file);
    verifyEqual(t,d.fHz,1e9); verifyEqual(t,d.s21,-.5i,'AbsTol',1e-14);
end

function testTouchstoneRejectsUnsupportedData(t)
    file=[tempname '.s2p']; cleanup=onCleanup(@()delete(file)); %#ok<NASGU>
    write(file,sprintf('[Version] 2.0\n# GHz S RI R 50\n'));
    verifyError(t,@()QuasiOpticalReadSParameters(file),'QuasiOptical:SParameterTouchstone');
    write(file,sprintf('# GHz Y RI R 50\n1 .1 0 .5 0 .5 0 .1 0\n'));
    verifyError(t,@()QuasiOpticalReadSParameters(file),'QuasiOptical:SParameterTouchstone');
    write(file,sprintf('# GHz S RI R 50\n1 .1 0 .5 0\n'));
    verifyError(t,@()QuasiOpticalReadSParameters(file),'QuasiOptical:SParameterTouchstone');
    write(file,sprintf('# GHz S RI R 50\n1 .1 0 .5 0 .5 0 .1 0\n1 .1 .2 .3 .4\n2 .1 .2 .3 .4\n'));
    verifyError(t,@()QuasiOpticalReadSParameters(file),'QuasiOptical:SParameterTouchstone');
end

function [s11,s21]=slab(f,thickness,epsilon,mu)
    s11=zeros(size(f)); s21=zeros(size(f));
    p=struct('fGHz',10,'D',.12,'R',1.2,'theta',0,'width',.5,'height',.5, ...
        'psi',0,'lensPosition',.2,'focal',.35,'useLens',false,'yaw',0,'pitch',0,'roll',0,'mode','Transmission');
    d=QuasiOpticalMaterialPreset('Custom material');
    d.epsReal=real(epsilon); d.epsLoss=-imag(epsilon); d.muReal=real(mu); d.muLoss=-imag(mu);
    d.conductivity=0; d.thicknessMM=1000*thickness;
    for k=1:numel(f)
        p.fGHz=f(k)/1e9; response=QuasiOpticalMaterial(p,QuasiOpticalModel(p),d);
        s11(k)=response.r(1); s21(k)=response.t(1);
    end
end

function write(path,contents)
    handle=fopen(path,'w'); cleanup=onCleanup(@()fclose(handle)); %#ok<NASGU>
    fwrite(handle,contents,'char');
end
