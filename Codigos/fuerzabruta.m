clc;close all;clear all;
extiter=100;
maxmem=zeros(1,extiter);
matmem=zeros(1,extiter);
phiav=zeros(1,extiter);
phitot=zeros(1,extiter);
for supercon=1:100
    
tic
for a=1
    alpasol=1;          % Sun
    alpadiesel=1;       % Diesel
    alpabat=1;          % Battery
end % Variables analisis de sensibilidad

%% Limits
CPVMin = 0;           % Inferior Limit PV
CPVMax = 800;           % Inferior Limit PV
CBESSMin = 0;           % Inferior Limit PV
CBESSMax = 800;          % Inferior Limit PV
CGDMin = 0;           % Inferior Limit PV
CGDMax = 800;           % Inferior Limit PV
CDRMin = 0;             % Inferior Limit PV
CDRMax = 50;            % Inferior Limit PV

%% Initialitaion Particles
n=15; %%% <-- NO MORE THAN 20 

CPV=linspace(CPVMin,CPVMax,n);          % Capacidad instalada solar [kW]
CBESS=linspace(CBESSMin,CBESSMax,n);    % Capacidad de la bater?a   [kWh]
CGD=linspace(CGDMin,CGDMax,n);          % Generador diesel          [kW]
CDR=linspace(CDRMin,CDRMax,n);          % Capacidad maxima de DR    [kW]                            
                                                             
C = [CPV;CBESS;CGD;CDR];
sizeC = size(C);

costMatrix = zeros(n,n,6);
allC = allcomb(C(1,:),C(2,:),C(3,:),C(4,:));
allC = allC';
allCSize = size(allC);
%%

HDPS=15;
load('sol','-mat');% Carga de datos de sol
sole(1:15,:)=alpasol*sol;   % Creación de variable de sol para el an?lisis de sensibilidad
load('qload','-mat');  

operationalCost = zeros(1,allCSize(2));
for ip = 1:allCSize(2)
    QSUN=allC(1,ip)*sole/1000;
    temp = despachofusion(allC(:,ip)',HDPS,QSUN,QLOAD,alpasol,alpadiesel,alpabat);
    operationalCost(ip) = sum(temp);
end
pos = find(min(operationalCost) == operationalCost);
globalMinimun = allC(:,pos);
min(operationalCost);
%%
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


% figure
for a=1
% figu=figure;
% plot(operationalCost)
% hold on
% y = linspace(0,max(operationalCost),10);
% plot(pos*ones(1,10),y','red')
% grid on
% set(gcf,'renderer','Painters')
% title(['\fontsize{14}Exhaustive search'])
% figu.PaperSize = [5.6 4.3];
% figu.PaperPosition(1:2) = [-0.2 -0.1];
% print -dpdf exhaustive.pdf


end
