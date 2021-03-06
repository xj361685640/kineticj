function [stat] = kj_iterate_gmes()

phys = dlg_constants();

c = phys('c');
u0 = phys('u0');
eps0 = phys('eps0');

solutionFile = 'gmres-solution.mat';

% Load initial guess for x (stacked E=[Er,Et,Ez] field)

initialSolutionDir = 'template-ar';

arS = ar2_read_solution(initialSolutionDir);

rIn = arS('r');

E_r_init = arS('E_r')';
E_t_init = arS('E_t')';
E_z_init = arS('E_z')';

% % Perturb the correct initial guess by smoothing it to remove some of the
% % IBW. 
% 
% width = 50;
% smooth = hanning(width)/sum(hanning(width));
% 
% E_r_init = conv(E_r_init,smooth,'same');
% E_t_init = conv(E_t_init,smooth,'same');
% E_z_init = conv(E_z_init,smooth,'same');

E_init = [E_r_init,E_t_init,E_z_init]';

loadPreviousSolution = 1;

if loadPreviousSolution
    
    load(solutionFile);
    E_init = E_final;
    
end

[M,N] = size(E_init);
n = M/3;

f1=figure();
f1.Name = 'E_init';
ax1 = subplot(3,1,1);
plot(ax1,rIn,real(E_r_init))
hold on
plot(ax1,rIn,imag(E_r_init))
ax2 = subplot(3,1,2);
plot(ax2,rIn,real(E_t_init))
hold on
plot(ax2,rIn,imag(E_t_init))
ax3 = subplot(3,1,3);
plot(ax3,rIn,real(E_z_init))
hold on
plot(ax3,rIn,imag(E_z_init))


% Load b (RHS for that guess)

arR = ar2_read_rundata(initialSolutionDir);

f2=figure();
f2.Name = 'RHS';
ax1 = subplot(3,1,1);
plot(ax1,arR('r'),real(arR('jA_r')))
hold on
plot(ax1,arR('r'),imag(arR('jA_r')))
ax2 = subplot(3,1,2);
plot(ax2,arR('r'),real(arR('jA_t')))
hold on
plot(ax2,arR('r'),imag(arR('jA_t')))
ax3 = subplot(3,1,3);
plot(ax3,arR('r'),real(arR('jA_z')))
hold on
plot(ax3,arR('r'),imag(arR('jA_z')))

f = arR('freq');
nPhi = cast(arR('nPhi'),'single');
kz = arR('kz_1d');
w = 2 * pi * f;


jA = [arR('jA_r')',arR('jA_t')',arR('jA_z')']';

RHS = -i * w * u0 * jA;


% Test my LHS function by applying it to the AORSA solution and then
% comparing LHS with RHS.

[myLHS,LHS_t1,LHS_t2] = kj_LHS(E_init);

jP_ar = ([sum(arS('jP_r'),3)',sum(arS('jP_t'),3)',sum(arS('jP_z'),3)']');

LHS_t2_ar = w^2/c^2 .* ( E_init + i/(w*eps0).*jP_ar );

res = myLHS;% - RHS;

res_r = res(0*n+1:1*n);
res_t = res(1*n+1:2*n);
res_z = res(2*n+1:3*n);

f5=figure();
f5.Name = 'Residual Test';
ax1 = subplot(3,1,1);
plot(ax1,rIn,real(res_r))
hold on
plot(ax1,rIn,imag(res_r))
ax2 = subplot(3,1,2);
plot(ax2,rIn,real(res_t))
hold on
plot(ax2,rIn,imag(res_t))
ax3 = subplot(3,1,3);
plot(ax3,rIn,real(res_z))
hold on
plot(ax3,rIn,imag(res_z))

f6=figure();
f6.Name = 'Residual terms : LHS_t1, LHS_t2, RHS';
ax1 = subplot(3,1,1);
hold on
plot(ax1,rIn,real(LHS_t1(1:n)))
plot(ax1,rIn,real(LHS_t2(1:n)))
plot(ax1,rIn,real(RHS(1:n)))
plot(ax1,rIn,real(LHS_t2_ar(1:n)))

ax2 = subplot(3,1,2);
hold on
plot(ax2,rIn,real(LHS_t1(1+n:2*n)))
plot(ax2,rIn,real(LHS_t2(1+n:2*n)))
plot(ax2,rIn,real(RHS(1+n:2*n)))

ax3 = subplot(3,1,3);
hold on
plot(ax3,rIn,real(LHS_t1(1+2*n:3*n)))
plot(ax3,rIn,real(LHS_t2(1+2*n:3*n)))
plot(ax3,rIn,real(RHS(1+2*n:3*n)))


% Call GMRES (using the nested function handle defined below)

b = RHS;
restart = [];
tol = [];
maxit = 250;
M1 = [];
M2 = [];
x0 = E_init;

[x,flag,relres,ite,resvec] = gmres(@kj_LHS,b,restart,tol,maxit,M1,M2,x0);

E_final = x;

save(solutionFile, 'E_final');

f3=figure();
f3.Name = 'Residual';
semilogy(0:maxit,resvec/norm(b),'-o');

E_r_final = x(0*n+1:1*n);
E_t_final = x(1*n+1:2*n);
E_z_final = x(2*n+1:3*n);

f4=figure();
f4.Name = 'E_final';
ax1 = subplot(3,1,1);
plot(ax1,arS('r'),real(E_r_final))
hold on
plot(ax1,arS('r'),imag(E_r_final))
ax2 = subplot(3,1,2);
plot(ax2,arS('r'),real(E_t_final))
hold on
plot(ax2,arS('r'),imag(E_t_final))
ax3 = subplot(3,1,3);
plot(ax3,arS('r'),real(E_z_final))
hold on
plot(ax3,arS('r'),imag(E_z_final))

stat = 0;

% Setup A*x = LHS evaluation function handle as nested function

    function [LHS,LHS_t1,LHS_t2] = kj_LHS (E)
        
        Er = E(0*n+1:1*n);
        Et = E(1*n+1:2*n);
        Ez = E(2*n+1:3*n);
                        
        [M,N] = size(rIn);
        
        LHS = zeros(size(E));
        
        LHS_r = zeros(1,n);
        LHS_t = zeros(1,n);
        LHS_z = zeros(1,n);
        
        LHS_t1_r = zeros(1,n);
        LHS_t1_t = zeros(1,n);
        LHS_t1_z = zeros(1,n);
        
        LHS_t1_r_2 = zeros(1,n);
        LHS_t1_t_2 = zeros(1,n);
        LHS_t1_z_2 = zeros(1,n);
        
        LHS_t1_r_2_h = zeros(1,n-1);
        LHS_t1_t_2_h = zeros(1,n-1);
        LHS_t1_z_2_h = zeros(1,n-1);
        
        LHS_t2_r = zeros(1,n);
        LHS_t2_t = zeros(1,n);
        LHS_t2_z = zeros(1,n);
        
        % Call to kineticj for this E to get jP
            
        [jP_r,jP_t,jP_z] = kj_runkj(Er,Et,Ez);
        
        h = rIn(2)-rIn(1);
        
        % term1 = -curlxcurl(E)
        
        t1_r = -(i*nPhi./rIn.^2.*gradient(rIn.*Et,h) + nPhi^2./rIn.^2.*Er + kz^2*Er + i*kz.*gradient(Ez,h));
        t1_t = -(-kz*nPhi./rIn.*Ez + kz^2.*Et - gradient(gradient(rIn.*Et,h)./rIn,h) + i*nPhi.*gradient(Er./rIn,h));
        t1_z = -(i*kz./rIn.*gradient(rIn.*Er,h) - 1./rIn.*gradient(rIn.*gradient(Ez,h),h) + nPhi^2./rIn.^2.*Ez - nPhi*kz./rIn.*Et);
        
        % term2 = +w^2/c^2 * ( E + i/(w*e0) * jP )
        
        t2_r = w^2/c^2 .* ( Er + i/(w*eps0) .* jP_r );
        t2_t = w^2/c^2 .* ( Et + i/(w*eps0) .* jP_t );
        t2_z = w^2/c^2 .* ( Ez + i/(w*eps0) .* jP_z );
        
        LHS_r = t1_r' + t2_r';
        LHS_t = t1_t' + t2_t';
        LHS_z = t1_z' + t2_z';
        
        % Return A*x vector for GMRES
        
        LHS = [LHS_r,LHS_t,LHS_z]';
        
        LHS_t1 = [t1_r',t1_t',t1_z']';
        LHS_t2 = [t2_r',t2_t',t2_z']';
        
    end

    function [w] = hanning(N)
        
        alpha = 0.5;
        k = linspace(0,N-1,N);
        w = alpha - (1-alpha)*cos(2*pi*k/N);
        
    end

end