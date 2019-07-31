% Codigo basado en reglas para conferencia 

clear all;
clc;
close all;

for a=1
    alpasol=1;        % Sun
    alpadiesel=1;       % Diesel
    alpabat=1;          % Battery
end % Variables an�lisis de sensibilidad
for a=1
    iter=3;                    % N�mero de iteraciones
    HDPS=15;                    % Horizonte de pronostico de simulaci�n
    alfha=0.3;                  % Velocidad de convergencia
end % Inicializaci�n del algoritmo
for a=1
    ddvpv=25*365;               % D�as de vida del sistema PV
    ddvbess=8*365;              % D�as de vida del BESS
    ddvgd=15*365;               % D�as de vida del DG
    ddvdr=25*365;               % D�as de vida de la DR
    load('sol','-mat');         % Carga de datos de sol
    sole(1:15,:)=alpasol*sol;   % Creaci�n de variable de sol para el an�lisis de sensibilidad
    load('qload','-mat');       % Carga de datos de la demanda
    tcost=zeros(HDPS,1);        % Matriz de costos
    alpa=20;                    % Variable alpha para el costo de la bater�a
    ela=0.2;                    % Elasticidad de la demanda
    soc=zeros(HDPS,24);         % Inicializaci�n de la variable estado de carga
    exeene=zeros(HDPS,24);      % Exceso de energ�a
    lackene=zeros(HDPS,24);     % Falta de energ�a
    
    % Costos unitarios de instalaci�n diarios (FALTA PONER FACTOR DE DESCUENTO)
    IIPV=1300/(ddvpv);          % Inversion incial dividida en d�as de vida del PV  [kW]
    IIBESS=420*alpabat/(ddvbess);       % Inversion incial dividida en d�as de vida de BESS [kWh]
    IIGD=550/(ddvgd);           % Inversion incial dividida en d�as de vida del GD  [kW]
    IIDR=50/(ddvdr);            % Inversion incial dividida en d�as de vida del     [kW]
  
    % Variables despacho econ�mico
    EHCDR=zeros(HDPS,24);       % Variable para almacenar costos horarios equivalentes de la DR
    EHCBESS=zeros(HDPS,24);     % Variable para almacenar costos horarios equivalentes del BESS
    EHCGD=zeros(HDPS,24);       % Variable para almacenar costos horarios equivalentes del GD
    QBESSin=zeros(HDPS,24);     % Variable de carga de la bater�a
    QBESSout=zeros(HDPS,24);    % Variable de descarga de la bater�a
    QDR=zeros(HDPS,24);         % variable de salida de la respuesta de la demanda
    QDR1=zeros(HDPS,24);        % variable de salida de la respuesta de la demanda
    QDR2=zeros(HDPS,24);        % variable de salida de la respuesta de la demanda
    gendispo=zeros(HDPS,24);    % Energ�a disponible cuando (QSUN-QLOAD es positivo)
end % Variables de capacidad

for a=1
    CPV=350;                                % Capacidad instalada solar [kW]
    CBESS=200;                              % Capacidad de la bater�a   [kWh]
    CGD=200;                                % Generador diesel          [kW]
    CDR=10;                                 % Capacidad maxima de DR    [kW]
    saltopv=400;                            % Salto inicial de PV       [kW]
    saltob=500;                             % Salto inicial de BESS     [kW]
    saltogd=200;                            % Salto inicial de GD       [kW]
    saltodr=10;                             % Salto inicial de DR       [kW]
end % Variables de arranque previas

for grco=1:iter
    for a=1
        % FILA F
        fila(1).CPV=CPV;
        fila(2).CPV=CPV ;
        fila(3).CPV=CPV ;
        fila(4).CPV=CPV+saltopv ;
        fila(5).CPV=CPV+saltopv ;
        fila(6).CPV=CPV+saltopv ;
        fila(7).CPV=CPV+2*saltopv ;
        fila(8).CPV=CPV+2*saltopv ;
        fila(9).CPV=CPV+2*saltopv ;

        %fila f
        fila(1).CBESS= CBESS;
        fila(2).CBESS= CBESS+saltob;
        fila(3).CBESS= CBESS+2*saltob;
        fila(4).CBESS= CBESS;
        fila(5).CBESS= CBESS+saltob;
        fila(6).CBESS= CBESS+2*saltob;
        fila(7).CBESS= CBESS;
        fila(8).CBESS= CBESS+saltob;
        fila(9).CBESS= CBESS+2*saltob; 

        % COLUMNA C
        columna(1).CDR=CDR;
        columna(2).CDR=CDR;
        columna(3).CDR=CDR;
        columna(4).CDR=CDR+saltodr;
        columna(5).CDR=CDR+saltodr;
        columna(6).CDR=CDR+saltodr;
        columna(7).CDR=CDR+2*saltodr;
        columna(8).CDR=CDR+2*saltodr;
        columna(9).CDR=CDR+2*saltodr;

        % columna c
        columna(1).CGD= CGD;
        columna(2).CGD= CGD+saltogd;
        columna(3).CGD= CGD+2*saltogd;
        columna(4).CGD= CGD;
        columna(5).CGD= CGD+saltogd;
        columna(6).CGD= CGD+2*saltogd;
        columna(7).CGD= CGD;
        columna(8).CGD= CGD+saltogd;
        columna(9).CGD= CGD+2*saltogd;    
    end % Crear estructura para las filas y las columnas
    
    
    for a=1
        for filacon=1:9
            for columnacon=1:9
                for a=1
                    CBESS=fila(filacon).CBESS;
                    CPV=fila(filacon).CPV;  
                    CGD=columna(columnacon).CGD;        
                    CDR=columna(columnacon).CDR;            
                                    

                    % Creaci�n de la demanda                          
                    QSUN=CPV*sole/1000;          % Carga
                    for ee=1:HDPS
                        dee(ee,:)=round(QLOAD(ee,:)-QSUN(ee,:));
                    end 
                    d=dee';
                    for b=1
                        MPV=0.02*CPV/365;
                        MBESS=0.01*CBESS/365;
                        MGD=0.75/365;
                        MDR=0;
                        CFPV=(CPV*IIPV+CPV*MPV);
                        CFGD=(CGD*IIGD+CGD*MGD);
                        CFDR=(CDR*IIDR+CDR*MDR);
                        CFBESS=(CBESS*IIBESS+CBESS*MBESS);
                        fcosfi=(CFPV+CFGD+CFDR+CFBESS);
                        alfa=10;
                        CPO=CFPV+CFBESS+CFGD+CFDR;
                    end % Estimaci�n de costos fijos
                    
                    % Generador diesel
                    liminfgd=ceil(0.25*CGD);    % Limite inferior del Generador Diesel [kW]
                    limsupgd=ceil(0.8*CGD);     % Limite superior del Generador Diesel [kW]
                    costolitro=0.79*alpadiesel;  % Costo del litro de diesel
                    fcostgd=costolitro*0.24;     % Costo fijo del GD
                    vcostgd=costolitro*0.031*CGD;% Costo fijo variable del GD

                    % Bater�a
                    liminfsoc=ceil(0.3*CBESS);        % L�mite inferior de descarga           [kWh]
                    limsupsoc=ceil(0.95*CBESS);       % L�mite superior de carga              [kWh]
                    dsoc=limsupsoc-liminfsoc;         % Delta de SOC
                    ratedis=ceil(0.2*CBESS);          % L�mite de tasa de descarga            [kW]
                    ratecha=ceil(0.2*CBESS);          % L�mite de tasa de carga               [kW]
                    costbin=5;                          % Costo de carga                        [$/kWh]
                    costbout=5;                         % Costo de descarga                     [$/kWh]
                    socini=ceil(0.3*CBESS);           % Estado de carga inicial               [kWh] 
                    soc=zeros(24,1);                % Variable de incializaci�n del soc
                    fcostsoc=alpa./(dsoc+1);         % Costo de mantener energ�a almacenada  [$/kWh]
                    vcostsoc=alpa.*(liminfsoc+dsoc)/(dsoc+1);  % Costo fijo variable del soc
                    issoc=0.2*CBESS;            % Estado inicial de carga de la bater�a [kWh]
                    assoc=issoc;                % Estado actual de carga de la bater�a  [kWh]
                    nin=0.99;                   % Eficiencia de carga de la bater�a
                    nout=0.99;                  % Eficiencia de descarga de la bater�a

                    % Respuesta de la demanda
                    fcostdr=0.03;               % Costo de DR (negativo) 
                    liminfdr=ceil(0.3*CDR);           % L�mite inferior de DR
                    limsupdr=ceil(0.3*CDR);           % L�mite superior de DR

                    % Exceso y faltas de energ�a
                    fcostexene=5;
                    fcostlackene=5;
                    % Variales dependientes
                end % Definici�n de variables dependientes de la capacidad   

                % DESPACHO ECON�MICO RULE-BASED
                operationalcost = despacho([CPV,CBESS,CGD,CDR],HDPS,QSUN,QLOAD,alpasol,alpadiesel,alpabat);
                CM(filacon,columnacon)=sum(operationalcost);
                
            end
        end
        
    end % Llenado y busqueda del minimo de CM  
    
    
    
    
    
    
    for a=1
%         for bessc=1
%             if colcentro==1 || colcentro==4 || colcentro ==7
%                 if floor(columna(colcentro).CBESS-(alfha)*saltob)>0
%                     CBESS=floor(columna(colcentro).CBESS-(alfha)*saltob);
% %                     saltob=floor((0.9)*saltob);
%                 else 
%                     CBESS=0;
%                 end
%             end
% 
%             if colcentro==2 || colcentro==5 || colcentro ==8
%                 CBESS=floor(columna(colcentro).CBESS-(alfha)*saltob);
%                 saltob=floor((1-alfha)*saltob);
%             end
% 
%             if colcentro==3 || colcentro==6 || colcentro ==9
%                 CBESS=(alfha)*columna(colcentro).CBESS;
% %                 saltob=floor((0.9)*saltob);
%             end
%         end  % Actualizaci�n de CBESS
% 
%         for pvco=1
%             if filcentro==1 || filcentro==4 || filcentro ==7
%                 if floor(fila(filcentro).CPV-(alfha)*saltopv)>0
%                     CPV=floor(fila(filcentro).CPV-(alfha)*saltopv);
% %                     saltopv=floor((0.9)*saltopv);
%                 else 
%                     CPV=0;
%                 end
%             end
% 
%             if filcentro==2 || filcentro==5 || filcentro ==8
%                 CPV=floor(fila(filcentro).CPV-(alfha)*saltopv);
%                 saltopv=floor((1-alfha)*saltopv);
%             end
% 
%             if filcentro==3 || filcentro==6 || filcentro ==9
%                 CPV=fila(filcentro).CPV;
% %                 saltopv=floor((0.9)*saltopv);
%             end
%         end   % Actualizaci�n de PV
%         
%         for cdrco=1
%             if filcentro==1 || filcentro==2 || filcentro ==3
%                 if floor(fila(filcentro).CDR-(alfha)*saltodr)>0
%                     CDR=floor(fila(filcentro).CDR-(alfha)*saltodr);
% %                     saltodr=floor((1-alfha)*saltodr);
%                 else 
%                     CDR=0;
%                 end
%             end
% 
%             if filcentro==4 || filcentro==5 || filcentro ==6
%                 CDR=floor(fila(filcentro).CDR-(alfha)*saltodr);
%                 saltodr=floor((1-alfha)*saltodr);
%             end
% 
%             if filcentro==7 || filcentro==8 || filcentro ==9
%                 if floor(fila(filcentro).CDR)<floor(0.1*max(max(QLOAD)))
%                     CDR=fila(filcentro).CDR;
% %                     saltodr=floor((1-alfha)*saltodr);
%                 else 
%                     CDR=floor(0.1*max(max(QLOAD)));
%                 end
%                 
%             end
%         end % Actualizaci�n de CDR
%         
%         for gdco=1
%             if colcentro==1 || colcentro==2 || colcentro ==3
%                 if floor(columna(colcentro).CGD-(alfha)*saltogd)>0
%                     CGD=floor(columna(colcentro).CGD-(alfha)*saltogd);
% %                     saltogd=floor((1-alfha)*saltogd);
%                 else 
%                     CGD=0;
%                 end
%             end
% 
%             if colcentro==4 || colcentro==5 || colcentro ==6
%                 CGD=floor(columna(colcentro).CGD-(alfha)*saltogd);
%                 saltogd=floor((1-alfha)*saltogd);
%             end
% 
%             if colcentro==7 || colcentro==8 || colcentro ==9
%                 CGD=columna(colcentro).CGD;
% %                 saltogd=floor((1-alfha)*saltogd);
%             end
%         end  % Actualizaci�n de GD
         
    end % Actualizaci�n de variables de dimensionamiento CPV, CBESS, CGD, CDR
    for a=1
        cpvplo(grco,1)=CPV;saltopvplo(grco,1)=saltopv;
        cbessplo(grco,1)=CBESS;saltobplo(grco,1)=saltob;
        cgdplo(grco,1)=CGD;saltogdplo(grco,1)=saltogd;
        cdrplo(grco,1)=CDR;saltodrplo(grco,1)=saltodr;
        
    end % almacenamiento de datos para graficaci�n de convergencia
end % Dimensionamiento
for a=1
%     TCOST=sum(tcost);
%     LCOE=TCOST/sum(sum((QGD+QDR+QBESSin+QBESSout+QSUN)));
%     CPV, CGD, CBESS, CDR, LCOE, vpa(TCOST,7)

    for b=1
%         subplot(2,2,1)
%         plot(cpvplo);hold on
%         grid on;plot(saltopvplo);
%         % axis([1 iter 0 1300])
%         legend('PV','Step')
% 
%         subplot(2,2,2)
%         plot(cbessplo);hold on
%         grid on;plot(saltobplo);
%         % axis([1 iter 0 600])
%         legend('BESS','Step')
% 
%         subplot(2,2,3)
%         plot(cgdplo);hold on
%         grid on;plot(saltogdplo);
%         % axis([1 iter 0 600])
%         legend('GD','Step')
% 
%         subplot(2,2,4)
%         plot(cdrplo);hold on
%         grid on;plot(saltodrplo);
%         % axis([1 iter 0 floor(0.1*max(max(QLOAD))+10)])
%         legend('DR','Step')
    end % Graficaci�n de convergencia del algoritmo
end % Resultados 

contour(CM)
title('PV, bess, DR, gd')
ylabel('F=PV // f=bess')
xlabel('C=DR // c=gd')
grid on
saveas(gcf,'5a.png')
figure

surf(CM)
title('PV, bess, DR, gd')
ylabel('F=PV // f=bess')
xlabel('C=DR // c=gd')
zlabel('Costs [USD]')
grid on
saveas(gcf,'5b.png')

save('cm_new.mat','CM');





