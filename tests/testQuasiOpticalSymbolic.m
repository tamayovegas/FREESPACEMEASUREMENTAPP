function tests=testQuasiOpticalSymbolic
% Numerical substitutions validate identities in the symbolic guide only.
% These checks are not a tensor retrieval implementation.
    tests=functiontests(localfunctions);
end

function testRotatedTensorAndComponentMeaning(t)
    p=parameters(); p.yaw=37; m=QuasiOpticalModel(p);
    principal=[2-.2i,4-.3i,6-.1i]; T=diag(principal);
    L=m.rotation*T*m.rotation.';
    verifyEqual(t,L(1,2),(principal(1)-principal(2))*sind(p.yaw)*cosd(p.yaw),'AbsTol',1e-12);
    verifyEqual(t,sort(eig(L)),sort(principal.'),'AbsTol',1e-12);
    E=[1;2;3]; verifyEqual(t,L*(m.rotation*E),m.rotation*(T*E),'AbsTol',1e-12);
    verifyEqual(t,m.rotation*(3*eye(3))*m.rotation.',3*eye(3),'AbsTol',1e-12);
end

function testPrincipalPlaneModesSatisfyMaxwell(t)
    e=[2.3-.2i,3.7-.1i,5.1-.3i]; mu=[1.2-.05i,1.6-.1i,1.9-.08i];
    for alpha=[0 25 60]
        ky=sind(alpha);
        qTE=sqrt(e(3)*mu(2)-(mu(2)/mu(1))*ky^2);
        qTM=sqrt(mu(3)*e(2)-(e(2)/e(1))*ky^2);
        k=[qTE;ky;0]; E=[0;0;1];
        residual=cross(k,diag(1./mu)*cross(k,E))+diag(e)*E;
        verifyEqual(t,residual,zeros(3,1),'AbsTol',1e-12);
        k=[qTM;ky;0]; E=[-ky/e(1);qTM/e(2);0];
        residual=cross(k,diag(1./mu)*cross(k,E))+diag(e)*E;
        verifyEqual(t,residual,zeros(3,1),'AbsTol',1e-12);
    end
end

function testAngleEquationsReduceToExistingIsotropicSolver(t)
    p=parameters(); d=QuasiOpticalMaterialPreset('Custom material');
    d.epsReal=4; d.epsLoss=.3; d.muReal=1.4; d.muLoss=.1; d.conductivity=0; d.thicknessMM=7;
    e=d.epsReal-1i*d.epsLoss; mu=d.muReal-1i*d.muLoss;
    for alpha=[0 30 65]
        p.theta=alpha; m=QuasiOpticalModel(p); s=QuasiOpticalMaterial(p,m,d);
        q=sqrt(e*mu-sind(alpha)^2);
        Y0=[cosd(alpha),1/cosd(alpha)]; Y1=[q/mu,e/q];
        G=(Y0-Y1)./(Y0+Y1); P=exp(-1i*2*pi/m.lambda*q*d.thicknessMM/1000);
        r=G*(1-P^2)./(1-G.^2*P^2); tr=(1-G.^2)*P./(1-G.^2*P^2);
        verifyEqual(t,r,s.r,'AbsTol',1e-12); verifyEqual(t,tr,s.t,'AbsTol',1e-12);
    end
end

function testScalarRetrievalSpecialCase(t)
    p=parameters(); p.theta=0; m=QuasiOpticalModel(p);
    d=QuasiOpticalMaterialPreset('Custom material');
    d.epsReal=4; d.epsLoss=.2; d.muReal=1.3; d.muLoss=.05; d.conductivity=0; d.thicknessMM=2;
    s=QuasiOpticalMaterial(p,m,d); r=s.r(1); tr=s.t(1);
    X=(1+r^2-tr^2)/(2*r); candidates=[X+sqrt(X^2-1),X-sqrt(X^2-1)];
    G=candidates(abs(candidates)<1); verifyNumElements(t,G,1);
    P=(r+tr-G)/(1-G*(r+tr)); z=(1+G)/(1-G);
    n=1i*log(P)/(2*pi/m.lambda*d.thicknessMM/1000);
    verifyEqual(t,n/z,d.epsReal-1i*d.epsLoss,'AbsTol',1e-11);
    verifyEqual(t,n*z,d.muReal-1i*d.muLoss,'AbsTol',1e-11);
end

function testAngleAndSpecularDirectionUnderRotation(t)
    p=parameters(); p.yaw=23; p.pitch=17; p.roll=31; m=QuasiOpticalModel(p);
    n=-m.rotation*[1;0;0]; ki=m.ki(:);
    verifyEqual(t,acosd(abs(dot(ki,n))),m.incidence,'AbsTol',1e-12);
    kr=ki-2*dot(ki,n)*n;
    verifyEqual(t,norm(kr),1,'AbsTol',1e-12);
    verifyEqual(t,ki-dot(ki,n)*n,kr-dot(kr,n)*n,'AbsTol',1e-12);
end

function p=parameters()
    p=struct('fGHz',10,'D',.12,'R',1.2,'theta',30,'width',.5,'height',.5, ...
        'psi',0,'lensPosition',.2,'focal',.35,'useLens',false,'yaw',0,'pitch',0,'roll',0,'mode','Reflection');
end
