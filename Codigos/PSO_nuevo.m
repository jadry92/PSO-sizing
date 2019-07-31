clc;close all;clear all;
extiter=100;
maxmem=zeros(1,extiter);
matmem=zeros(1,extiter);
phiav=zeros(1,extiter);
phitot=zeros(1,extiter);

for supercon=1:100

% [userview,systemview] = memory
tic
for a=1
    alpasol=1;          % Sun
    alpadiesel=1;       % Diesel
    alpabat=1;          % Battery
end % Variables analisis de sensibilidad

%% Initialitaion Particles
% Limits

CPVMin = 0; % Inferior Limit PV
CPVMax = 700; % Inferior Limit PV

CBESSMin = 0; % Inferior Limit PV
CBESSMax = 700; % Inferior Limit PV

CGDMin = 0; % Inferior Limit PV
CGDMax = 700; % Inferior Limit PV

CDRMin = 0; % Inferior Limit PV
CDRMax = 46; % Inferior Limit PV

CLimt = [CPVMin,CPVMax;
        CBESSMin,CBESSMax;
        CGDMin,CGDMax;
        CDRMin,CDRMax];
n=100;

CPV=    (CPVMin     + (CPVMax)*rand(n,1))';     % Capacidad instalada solar [kW]
CBESS=  (CBESSMin   + (CBESSMax)*rand(n,1))';   % Capacidad de la bater?a   [kWh]
CGD=    (CGDMin     + (CGDMax)*rand(n,1))';     % Generador diesel          [kW]
CDR=    (CDRMin     + (CDRMax)*rand(n,1))';     % Respuesta de la demanda
                                                             
C = [CPV;CBESS;CGD;CDR];
sizeC = size(C);

%% Parameters
w_CPV = 0.5; % Inertial factor CPV
c1_CPV = 2; % Constant Speed Local CPV 
c2_CPV = 2; % Constant Speed Global CPV

w_CBESS = 0.5; % Inertial factor CBESS
c1_CBESS = 2; % Constant Speed Local CBESS
c2_CBESS = 2; % Constant Speed Global CBESS

w_CGD = 0.5; % Inertial factor CGD
c1_CGD = 2; % Constant Speed Local CGD 
c2_CGD = 2; % Constant Speed Global CGD

w_CDR = 0.5; % Inertial factor CDR
c1_CDR = 2; % Constant Speed Local CDR 
c2_CDR = 2; % Constant Speed Global CDR

const_w = [[w_CPV ;c1_CPV ; c2_CPV]';
           [w_CBESS ;c1_CBESS ;c2_CBESS]';
           [w_CGD ;c1_CGD ;c2_CGD]';
           [w_CDR ;c1_CDR ;c2_CDR]'];

V = zeros(sizeC);
       
% Gloval
gBest = zeros(4,1);
gBestValuePass = 0;
id_gBest = 0;

% Local
lBest = zeros(4,sizeC(2));
lBestValuePass = zeros(1,sizeC(2));       
lBestValuePres = zeros(1,sizeC(2));

%%
numberOfIterations = 60;
HDPS=15;
load('sol','-mat');% Carga de datos de sol 
sole(1:HDPS,:)=alpasol*sol;   % Creaci?n de variable de sol para el an?lisis de sensibilidad
load('qload','-mat');  


operationalCostIte = zeros(HDPS,sizeC(2));
operationalCostIteGlobal = zeros(HDPS,sizeC(2),numberOfIterations);

CTotal = zeros(sizeC(1),sizeC(2),numberOfIterations);
%%
Stop = false;
iter = 1;
con=1;

while ( Stop == false )
    % 
    for ip = 1:sizeC(2)
        QSUN=C(1,ip)*sole/1000;
        operationalCostIte(:,ip) = despachofusion(C(:,ip)',HDPS,QSUN,QLOAD,alpasol,alpadiesel,alpabat);
    end
    operationalCostIteGlobal(:,:,iter) = operationalCostIte(:,:);
    % calculate Gbest and Lbest
    if iter == 1
        % Local
        lBest = C;
        lBestValuePass = sum(operationalCostIte);
        % Global
        gBestValuePass = min(sum(operationalCostIte));
        id_gBest = find(sum(operationalCostIte) == gBestValuePass);
        gBest(:,1) = C(:,id_gBest);
    else
        % Local
        lBestValuePres = sum(operationalCostIte);
        for ip = 1:sizeC(2)
            if lBestValuePass(ip) > lBestValuePres(ip)
                lBest(:,ip) = C(:,ip);
                lBestValuePass(ip) = lBestValuePres(ip);
                % Creación de grafíca de convergencia
                tt=clock;segu(1,iter)=tt(6);
                dispv(1,iter)=(C(1,ip)-355);
                disb(1,iter)=(C(2,ip)-3);
                disgd(1,iter)=(C(3,ip)-530);
                disdr(1,iter)=(C(4,ip)-50);
            end
        end
        
        % Global
        gBestValuePres = min(sum(operationalCostIte));
        if gBestValuePres < gBestValuePass
            id_gBest = find(sum(operationalCostIte) == gBestValuePres);
            gBest(:,1) = C(:,id_gBest(1));
            gBestValuePass = gBestValuePres;
        end
    end
    CTotal(:,:,iter) = C;
    % Update particules
    V = (const_w(:,1).*V) + (const_w(:,2)*rand(1,1)).*(lBest-C) ...
        + (const_w(:,3)*rand(1,1)).*(gBest-C);
    
    C = C + V;
    for ip = 1:sizeC(2)
        for ival = 1:sizeC(1)
                % Limit Minimun
            if CLimt(ival,1) > C(ival,ip)
                C(ival,ip) = CLimt(ival,1); 
                % Limit Maximun
            elseif CLimt(ival,2) < C(ival,ip)
                C(ival,ip) = CLimt(ival,2);
            end
        end  
    end
    
    
    % Stop criterion
    if numberOfIterations == iter
        Stop = true;
    end
    iter = iter + 1;
    lBestValuePres = zeros(1,sizeC(2));
end

toc

[userview,systemview] = memory;

maxmem(1,supercon)=userview.MaxPossibleArrayBytes;
matmem(1,supercon)=userview.MemUsedMATLAB;
phiav(1,supercon)=systemview.PhysicalMemory.Available;
phitot(1,supercon)=systemview.PhysicalMemory.Total;



end 

totalmem=sum(maxmem)/extiter
matlabmem=sum(matmem)/extiter
phisicaldisponible=sum(phiav)/extiter
pshisicaltotal=sum(phitot)/extiter


% gBest(:,1)
% gBestValuePass

% plot(segu-segu(1,2),dispv);hold on;grid on
% plot(segu-segu(1,2),disb)
% plot(segu-segu(1,2),disgd)
% plot(segu-segu(1,2),disdr)
% legend('PV','BESS','GD','DR')

% 
% figure
% plot(squeeze(sum(operationalCostIteGlobal))')

% 
% figure
% subplot(2,2,1)
% figu=figure;
% plot(squeeze(CTotal(:,1,:))','LineWidth',1.2)
% xlabel('Number of Iterations')
% ylabel('Capacity [KW]')
% legend('CPV','CBESS','CGD','CDR')
% grid on
% set(gcf,'renderer','Painters')
% title(['\fontsize{14}PSO'])
% figu.PaperSize = [5.6 4.3];
% figu.PaperPosition(1:2) = [-0.2 -0.1];
% print -dpdf pso.pdf


% 
% subplot(2,2,2)
% plot(squeeze(CTotal(:,2,:))')
% title('Particle 2')
% xlabel('Number of Iterations')
% ylabel('Capacity [KW]')
% legend('CPV','CBESS','CGD','CDR')
% 
% subplot(2,2,3)
% plot(squeeze(CTotal(:,3,:))')
% title('Particle 3')
% xlabel('Number of Iterations')
% ylabel('Capacity [KW]')
% legend('CPV','CBESS','CGD','CDR')
% 
% subplot(2,2,4)
% plot(squeeze(CTotal(:,4,:))')
% title('Particle 4')
% xlabel('Number of Iterations')
% ylabel('Capacity [KW]')
% legend('CPV','CBESS','CGD','CDR')