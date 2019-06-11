
clc;
close all;
clear all;

%% Initialitaion Particles

saltopv=200;                            % Salto inicial de PV       [kW]
saltob=300;                             % Salto inicial de BESS     [kW]
saltogd=100;                            % Salto inicial de GD       [kW]
saltodr=10;                             % Salto inicial de DR       [kW]

CPV=[1, saltopv, (2*saltopv),20];    % Capacidad instalada solar [kW]
CBESS=[1, saltob, (2*saltob),20];    % Capacidad de la bater�a   [kWh]
CGD=[1, saltogd, (2*saltogd),20];    % Generador diesel          [kW]
CDR=[1, saltodr, (2*saltodr),20];      % Capacidad maxima de DR    [kW]

%           i_Particles           
%    |CPV_1   , .. ,CPV_i   |   p
%    |CBESS_1 , .. ,CBESS_i |   o
% C =|CGD_1   , .. ,CGD_i   |   s 
%    |CDR_1   , .. ,CDR_i   |   
%                               
                                                             
C = [CPV;CBESS;CGD;CDR];
sizeC = size(C);

%% Parameters
w_CPV = 1; % Inertial factor CPV
c1_CPV = 1; % Constant Speed Local CPV 
c2_CPV = 1; % Constant Speed Global CPV

w_CBESS = 1; % Inertial factor CBESS
c1_CBESS = 1; % Constant Speed Local CBESS
c2_CBESS = 1; % Constant Speed Global CBESS

w_CGD = 1; % Inertial factor CGD
c1_CGD = 1; % Constant Speed Local CGD 
c2_CGD = 1; % Constant Speed Global CGD

w_CDR = 1; % Inertial factor CDR
c1_CDR = 1; % Constant Speed Local CDR 
c2_CDR = 1; % Constant Speed Global CDR

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
%% Limits

CPVMin = 10; % Inferior Limit PV
CPVMax = 700; % Inferior Limit PV

CBESSMin = 10; % Inferior Limit PV
CBESSMax = 700; % Inferior Limit PV

CGDMin = 10; % Inferior Limit PV
CGDMax = 700; % Inferior Limit PV

CDRMin = 0; % Inferior Limit PV
CDRMax = 46; % Inferior Limit PV

CLimt = [CPVMin,CPVMax;
        CBESSMin,CBESSMax;
        CGDMin,CGDMax;
        CDRMin,CDRMax];
%%
numberOfIterations = 60;
HDPS=15;
load('sol','-mat');% Carga de datos de sol
alpasol=0.7; 
sole(1:15,:)=alpasol*sol;   % Creaci�n de variable de sol para el an�lisis de sensibilidad
load('qload','-mat');  


operationalCostIte = zeros(HDPS,sizeC(2));
operationalCostIteGlobal = zeros(HDPS,sizeC(2),numberOfIterations);
%%
Stop = false;
iter = 1;

while ( Stop == false )
    % 
    for ip = 1:sizeC(2)
        QSUN=C(1,ip)*sole/1000;
        operationalCostIte(:,ip) = despacho(C(:,ip)',HDPS,QSUN,QLOAD);
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
        gBest = C(:,id_gBest);
    else
        % Local
        lBestValuePres = sum(operationalCostIte);
        for ip = 1:sizeC(2)
            if lBestValuePass(ip) > lBestValuePres(ip)
                lBest(:,ip) = C(:,ip);
                lBestValuePass(ip) = lBestValuePres(ip);
            end
        end
        
        % Global
        gBestValuePres = min(sum(operationalCostIte));
        if gBestValuePres < gBestValuePass
            id_gBest = find(sum(operationalCostIte) == gBestValuePres);
            gBest = C(:,id_gBest);
            gBestValuePass = gBestValuePres;
        end
    end
    % Update particules
    V = (const_w(:,1).*V) + (const_w(:,2).*rand(4,1)).*(lBest-C) ...
        + (const_w(:,3).*rand(4,1)).*(gBest-C);
  
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

    
 figure
 plot(squeeze(sum(operationalCostIteGlobal))')



