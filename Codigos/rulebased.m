% Codigo basado en reglas para conferencia 
clear all;clc;close all

%%
% Variables análisis de sensibilidad
for a=1
    alpasol=1;        % Sun
    alpadiesel=1;       % Diesel
    alpabat=1;          % Battery
end % Variables análisis de sensibilidad
%%

% Inicialización del algoritmo
for a=1
    iter=25;                    % Número de iteraciones
    HDPS=15;                     % Horizonte de pronostico de simulación
    ela=0.2;                    % Elasticidad de la demanda
    alfha=0.05;                 % Velocidad de convergencia
    ddvpv=25*365;               % Días de vida del sistema PV
    ddvbess=8*365;              % Días de vida del BESS
    ddvgd=15*365;               % Días de vida del DG
    ddvdr=25*365;               % Días de vida de la DR
    load('sol','-mat');         % Carga de datos de sol
    sole(1:15,:)=alpasol*sol;   % Creación de variable de sol para el análisis de sensibilidad
    load('qload','-mat');       % Carga de datos de la demanda
    soc=zeros(HDPS,24);         % Inicialización de la variable estado de carga
    exeene=zeros(HDPS,24);      % Exceso de energía
    lackene=zeros(HDPS,24);     % Falta de energía
    tcost=zeros(HDPS,1);        % Matriz de costos
    alpa=20;                    % Variable alpha para el costo de la batería

    % Costos unitarios de instalación diarios (FALTA PONER FACTOR DE DESCUENTO)
    IIPV=1300/(ddvpv);          % Inversion incial dividida en días de vida del PV  [kW]
    IIBESS=420*alpabat/(ddvbess);       % Inversion incial dividida en días de vida de BESS [kWh]
    IIGD=550/(ddvgd);           % Inversion incial dividida en días de vida del GD  [kW]
    IIDR=50/(ddvdr);            % Inversion incial dividida en días de vida del     [kW]
  
    % Variables despacho económico
    EHCDR=zeros(HDPS,24);       % Variable para almacenar costos horarios equivalentes de la DR
    EHCBESS=zeros(HDPS,24);     % Variable para almacenar costos horarios equivalentes del BESS
    EHCGD=zeros(HDPS,24);       % Variable para almacenar costos horarios equivalentes del GD
    QBESSin=zeros(HDPS,24);     % Variable de carga de la batería
    QBESSout=zeros(HDPS,24);    % Variable de descarga de la batería
    QDR=zeros(HDPS,24);         % variable de salida de la respuesta de la demanda
    QDR1=zeros(HDPS,24);        % variable de salida de la respuesta de la demanda
    QDR2=zeros(HDPS,24);        % variable de salida de la respuesta de la demanda
    gendispo=zeros(HDPS,24);    % Energía disponible cuando (QSUN-QLOAD es positivo)
end

% Dimensionamiento
for a=1
    CPV=350;                                % Capacidad instalada solar [kW]
    CBESS=200;                              % Capacidad de la batería   [kWh]
    CGD=500;                                % Generador diesel          [kW]
    CDR=10;                                 % Capacidad maxima de DR    [kW]
    saltopv=400;                            % Salto inicial de PV       [kW]
    saltob=500;                             % Salto inicial de BESS     [kW]
    saltogd=200;                            % Salto inicial de GD       [kW]
    saltodr=10;                             % Salto inicial de DR       [kW]
end % Variables de arranque previas

tic

for grco=1:iter
    for a=1
        fila(1).CDR=CDR;
        fila(2).CDR=CDR ;
        fila(3).CDR=CDR ;
        fila(4).CDR=CDR+saltodr ;
        fila(5).CDR=CDR+saltodr ;
        fila(6).CDR=CDR+saltodr ;
        fila(7).CDR=CDR+2*saltodr ;
        fila(8).CDR=CDR+2*saltodr ;
        fila(9).CDR=CDR+2*saltodr ;

        fila(1).CPV= CPV; 
        fila(2).CPV= CPV+saltopv;
        fila(3).CPV= CPV+2*saltopv;
        fila(4).CPV= CPV; 
        fila(5).CPV= CPV+saltopv;
        fila(6).CPV= CPV+2*saltopv;
        fila(7).CPV= CPV; 
        fila(8).CPV= CPV+saltopv;
        fila(9).CPV= CPV+2*saltopv;

        columna(1).CGD=CGD;
        columna(2).CGD=CGD;
        columna(3).CGD=CGD;
        columna(4).CGD=CGD+saltogd;
        columna(5).CGD=CGD+saltogd;
        columna(6).CGD=CGD+saltogd;
        columna(7).CGD=CGD+2*saltogd;
        columna(8).CGD=CGD+2*saltogd;
        columna(9).CGD=CGD+2*saltogd;

        columna(1).CBESS= CBESS;
        columna(2).CBESS= CBESS+saltob;
        columna(3).CBESS= CBESS+2*saltob;
        columna(4).CBESS= CBESS;
        columna(5).CBESS= CBESS+saltob;
        columna(6).CBESS= CBESS+2*saltob;
        columna(7).CBESS= CBESS;
        columna(8).CBESS= CBESS+saltob;
        columna(9).CBESS= CBESS+2*saltob;        
    end % Crear estructura para las filas y las columnas 
        
    for a=1
        searchgap=2000;
        CM=zeros(9,9);
        filcentro=5;
        colcentro=5;
        filreco=filcentro;colreco=colcentro;
    end  % Inicialización para el dimensionamiento
    
    while searchgap>100
        
        for ffil=1:3
            for ccol=1:3              
                if (ffil+filreco-2)>9 || (ccol+colreco-2)>9 || (ffil+filreco-2)<1 || (ccol+colreco-2)<1
                    if colreco==1;colreco=2;end
                    if filreco==1;filreco=3;end
                    CM(ffil+filreco-2,ccol+colreco-2)=10e5;
                else
                    if CM(ffil+filreco-2,ccol+colreco-2)==0
                        
                        for a=1
                            CPV=fila(ffil+filreco-2).CPV;                  % Capacidad instalada solar [kW]
                            CBESS=columna(ccol+colreco-2).CBESS;           % Capacidad de la batería [kWh]
                            CGD=columna(ccol+colreco-2).CGD;               % Generador diesel [kW]
                            CDR=fila(ffil+filreco-2).CDR;                  % Capacidad maxima de DR [kW]

                            % Creación de la demanda                          
                            QSUN=CPV*sole/1000;          % Carga
                            for ee=1:HDPS
                                dee(ee,:)=round(QLOAD(ee,:)-QSUN(ee,:));
                            end 
                            d=dee';

                            % Estimación de costos fijos
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
                            end
                            
                            % Generador diesel
                            liminfgd=ceil(0.25*CGD);    % Limite inferior del Generador Diesel [kW]
                            limsupgd=ceil(0.8*CGD);     % Limite superior del Generador Diesel [kW]
                            costolitro=0.79*alpadiesel;  % Costo del litro de diesel
                            fcostgd=costolitro*0.24;     % Costo fijo del GD
                            vcostgd=costolitro*0.031*CGD;% Costo fijo variable del GD

                            % Batería
                            liminfsoc=ceil(0.3*CBESS);        % Límite inferior de descarga           [kWh]
                            limsupsoc=ceil(0.95*CBESS);       % Límite superior de carga              [kWh]
                            dsoc=limsupsoc-liminfsoc;         % Delta de SOC
                            ratedis=ceil(0.2*CBESS);          % Límite de tasa de descarga            [kW]
                            ratecha=ceil(0.2*CBESS);          % Límite de tasa de carga               [kW]
                            costbin=5;                          % Costo de carga                        [$/kWh]
                            costbout=5;                         % Costo de descarga                     [$/kWh]
                            socini=ceil(0.3*CBESS);           % Estado de carga inicial               [kWh] 
                            soc=zeros(24,1);                % Variable de incialización del soc
                            fcostsoc=alpa./(dsoc+1);         % Costo de mantener energía almacenada  [$/kWh]
                            vcostsoc=alpa.*(liminfsoc+dsoc)/(dsoc+1);  % Costo fijo variable del soc
                            issoc=0.2*CBESS;            % Estado inicial de carga de la batería [kWh]
                            assoc=issoc;                % Estado actual de carga de la batería  [kWh]
                            nin=0.99;                   % Eficiencia de carga de la batería
                            nout=0.99;                  % Eficiencia de descarga de la batería
                            
                            % Respuesta de la demanda
                            fcostdr=0.03;               % Costo de DR (negativo) 
                            liminfdr=ceil(0.3*CDR);           % Límite inferior de DR
                            limsupdr=ceil(0.3*CDR);           % Límite superior de DR
                            
                            % Exceso y faltas de energía
                            fcostexene=5;
                            fcostlackene=5;
                        end % Definición de variables dependientes de la capacidad   
                        
                        % DESPACHO ECONÓMICO RULE-BASED
                        for d=1:HDPS
                            for h=1:24
                                EHCPV(d,h)=(CPV*IIPV+CPV*MPV)/24; % Costos fijos del PV
                                if QSUN(d,h)>QLOAD(d,h)   % Despacho cuando QSUN es mayor a QLOAD
                                    for bb=1
                                            gendispo(d,h)=QSUN(d,h)-QLOAD(d,h);
                                            if gendispo(d,h)>ratecha
                                                for a=1:1
                                                    exeene1(d,h)=gendispo(d,h)-ratecha;
                                                    if exeene1(d,h)>limsupdr
                                                        QDR(d,h)=limsupdr;
                                                        exeene(d,h)=exeene1(d,h)-QDR(d,h);
                                                    else
                                                        QDR(d,h)=exeene1(d,h);
                                                        exeene(d,h)=0;
                                                    end
                                                    EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                    QBESSin(d,h)=ratecha;
                                                    EHCGD(d,h)=0;
                                                    QBESSout(d,h)=0;
                                                    soc(d,h)=assoc+nin*QBESSin(d,h)-QBESSout(d,h)/nout;
                                                    EHCBESS(d,h)=CFBESS-alfa*(soc(d,h)-0.3*CBESS-dsoc)/dsoc;
                                                    assoc=soc(d,h);
                                                end
                                            else
                                                for a=1:1
                                                    exeene(d,h)=0;
                                                    QDR(d,h)=exeene(d,h);
                                                    EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                    QBESSin(d,h)=gendispo(d,h);
                                                    EHCGD(d,h)=0;
                                                    QBESSout(d,h)=0;
                                                    soc(d,h)=assoc+nin*QBESSin(d,h)-QBESSout(d,h)/nout;
                                                    EHCBESS(d,h)=CFBESS-alfa*(QBESSout(d,h)-limsupsoc)/dsoc;
                                                    assoc=soc(d,h);
                                                end
                                            end
                                    end
                                else
                                    for bb=1
                                                if QLOAD(d,h)>ratedis
                                                    for dd=1:1
                                                        TQBESS(d,h)=0;      % Salida temporal de batería
                                                        TQGD(d,h)=0;        % Salida temporal de generación diesel
                                                        tsoc=assoc;         % Reasignación de estado actual de carga
                                                        for cac=1:1:floor(QLOAD(d,h)-QSUN(d,h))
                                                            TBESS=CFBESS*(TQBESS(d,h)/tsoc);
                                                            TGD=CFGD+costolitro*CGD*(0.248225*TQGD(d,h)/CGD+0.031151);
                                                            if TBESS<TGD
                                                                TQBESS(d,h)=TQBESS(d,h)+1;
                                                                tsoc=tsoc-1;
                                                            else
                                                                TQGD(d,h)=TQGD(d,h)+1;
                                                            end
                                                        end  % Distribución optima de potencia en función del costo

                                                        if TQBESS(d,h)>ratedis
                                                            for ee=1:1
                                                                if assoc>liminfsoc
                                                                    for gg=1:1
                                                                        if assoc-ratedis<liminfsoc;QBESSout(d,h)=assoc-liminfsoc;else;QBESSout(d,h)=ratedis;end
                                                                        soc(d,h)=assoc+nin*QBESSin(d,h)-QBESSout(d,h)/nout;
                                                                        EHCBESS(d,h)=CFBESS-alfa*(QBESSout(d,h)-limsupsoc)/dsoc;
                                                                        assoc=soc(d,h);
                                                                        if QLOAD(d,h)-QBESSout(d,h)>liminfgd
                                                                            if QLOAD(d,h)-QBESSout(d,h)<limsupgd
                                                                                QGD(d,h)=QLOAD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                QDR(d,h)=0;
                                                                                EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                                EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                            else
                                                                                QGD(d,h)=limsupgd;
                                                                                drtt=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                if drtt>limsupdr
                                                                                    QDR(d,h)=limsupdr;
                                                                                    lackene(d,h)=drtt-QDR(d,h);
                                                                                else
                                                                                    QDR(d,h)=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                    lackene(d,h)=0;
                                                                                end                                                                           
                                                                                EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                                EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                            end
                                                                        else
                                                                            QGD(d,h)=0;
                                                                            drtt=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                            if drtt>limsupdr
                                                                                QDR(d,h)=limsupdr;
                                                                                lackene(d,h)=drtt-QDR(d,h);
                                                                            else
                                                                                QDR(d,h)=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                lackene(d,h)=0;
                                                                            end 
                                                                            EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                            EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                        end
                                                                    end
                                                                else
                                                                    for ii=1:1
                                                                        QBESSout(d,h)=0;
                                                                        soc(d,h)=assoc+nin*QBESSin(d,h)-QBESSout(d,h)/nout;
                                                                        EHCBESS(d,h)=CFBESS-alfa*(QBESSout(d,h)-limsupsoc)/dsoc;
                                                                        assoc=soc(d,h);
                                                                        if QLOAD(d,h)>liminfgd
                                                                            for hh=1:1
                                                                                if QLOAD(d,h)<limsupgd
                                                                                    QGD(d,h)=QLOAD(d,h)-QSUN(d,h);
                                                                                    QDR(d,h)=0;
                                                                                    EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                                    EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                                else
                                                                                    QGD(d,h)=limsupgd;
                                                                                    drtt=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                    if drtt>limsupdr
                                                                                        QDR(d,h)=limsupdr;
                                                                                        lackene(d,h)=drtt-QDR(d,h);
                                                                                    else
                                                                                        QDR(d,h)=drtt;
                                                                                        lackene(d,h)=0;
                                                                                    end
                                                                                    EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                                    EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                                end
                                                                            end
                                                                        else
                                                                            QGD(d,h)=0;
                                                                            drtt=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                            if drtt>limsupdr
                                                                                QDR(d,h)=limsupdr;
                                                                                lackene(d,h)=drtt-QDR(d,h);
                                                                            else
                                                                                QDR(d,h)=drtt;
                                                                                lackene(d,h)=0;
                                                                            end
                                                                            EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                            EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        else
                                                            for f=1:1
                                                                if assoc>liminfsoc
                                                                    for gg=1:1
                                                                        QBESSout(d,h)=TQBESS(d,h);
                                                                        soc(d,h)=assoc+nin*QBESSin(d,h)-QBESSout(d,h)/nout;
                                                                        EHCBESS(d,h)=CFBESS-alfa*(QBESSout(d,h)-limsupsoc)/dsoc;    
                                                                        assoc=soc(d,h);
                                                                        if QLOAD(d,h)-QBESSout(d,h)>liminfgd
                                                                            if QLOAD(d,h)-QBESSout(d,h)<limsupgd
                                                                                QGD(d,h)=QLOAD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                QDR(d,h)=0;
                                                                                EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                                EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                            else
                                                                                QGD(d,h)=limsupgd;
                                                                                drtt=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                if drtt>limsupdr
                                                                                    QDR(d,h)=limsupdr;
                                                                                    lackene(d,h)=drtt-QDR(d,h);
                                                                                else
                                                                                    QDR(d,h)=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                    lackene(d,h)=0;
                                                                                end 
                                                                                EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                                EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                            end
                                                                        else
                                                                            QGD(d,h)=0;
                                                                            QDR(d,h)=-(QLOAD(d,h)-QBESSout(d,h)-QSUN(d,h));
                                                                            drtt=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                            if drtt>limsupdr
                                                                                QDR(d,h)=limsupdr;
                                                                                lackene(d,h)=drtt-QDR(d,h);
                                                                            else
                                                                                QDR(d,h)=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                lackene(d,h)=0;
                                                                            end 
                                                                            EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                            EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                        end
                                                                    end
                                                                else
                                                                    for ii=1:1
                                                                        QBESSout(d,h)=0;
                                                                        soc(d,h)=assoc+nin*QBESSin(d,h)-QBESSout(d,h)/nout;
                                                                        EHCBESS(d,h)=CFBESS-alfa*(QBESSout(d,h)-limsupsoc)/dsoc;
                                                                        assoc=soc(d,h);
                                                                        if QLOAD(d,h)>liminfgd
                                                                            for hh=1:1
                                                                                if QLOAD(d,h)<limsupgd
                                                                                    QGD(d,h)=QLOAD(d,h)-QSUN(d,h);
                                                                                    QDR(d,h)=0;
                                                                                    EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                                    EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                                else
                                                                                    QGD(d,h)=limsupgd;
                                                                                    drtt=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                    if drtt>limsupdr
                                                                                        QDR(d,h)=limsupdr;
                                                                                        lackene(d,h)=drtt-QDR(d,h);
                                                                                    else
                                                                                        QDR(d,h)=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                        lackene(d,h)=0;
                                                                                    end                                                                                   
                                                                                    EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                                    EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                                end
                                                                            end
                                                                        else
                                                                            QGD(d,h)=0;
                                                                            drtt=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                            if drtt>limsupdr
                                                                                QDR(d,h)=limsupdr;
                                                                                lackene(d,h)=drtt-QDR(d,h);
                                                                            else
                                                                                QDR(d,h)=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                lackene(d,h)=0;
                                                                            end 
                                                                            EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                            EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                else
                                                    for f=1:1
                                                        TQBESS(d,h)=0;      % Salida temporal de batería
                                                        TQGD=0;             % Salida temporal de generación diesel
                                                        tsoc=assoc;         % Reasignación de estado actual de carga
                                                        for cac=1:1:floor(QLOAD(d,h)-QSUN(d,h))
                                                            TBESS=CFBESS*(TQBESS(d,h)/tsoc);
                                                            TGD=CFGD+costolitro*CGD*(0.248225*TQGD/CGD+0.031151);
                                                            if TBESS<TGD
                                                                TQBESS(d,h)=TQBESS(d,h)+1;
                                                                tsoc=tsoc-1;
                                                            else
                                                                TQGD=TQGD+1;
                                                            end
                                                        end  % Distribución optima de potencia en función del costo

                                                        if assoc>liminfsoc
                                                            for gg=1:1
                                                                if assoc-TQBESS(d,h)<liminfsoc;QBESSout(d,h)=assoc-liminfsoc;else;QBESSout(d,h)=TQBESS(d,h);end
                                                                soc(d,h)=assoc+nin*QBESSin(d,h)-QBESSout(d,h)/nout;
                                                                EHCBESS(d,h)=CFBESS-alfa*(QBESSout(d,h)-limsupsoc)/dsoc;
                                                                assoc=soc(d,h);
                                                                if QLOAD(d,h)-QBESSout(d,h)>liminfgd
                                                                    if QLOAD(d,h)-QBESSout(d,h)<limsupgd
                                                                        QGD(d,h)=QLOAD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                        QDR(d,h)=0;
                                                                        EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                        EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                    else
                                                                        QGD(d,h)=limsupgd;
                                                                        drtt=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                        if drtt>limsupdr
                                                                            QDR(d,h)=limsupdr;
                                                                            lackene(d,h)=drtt-QDR(d,h);
                                                                        else
                                                                            QDR(d,h)=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                            lackene(d,h)=0;
                                                                        end
                                                                        EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                        EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                    end
                                                                else
                                                                    QGD(d,h)=0;
                                                                    drtt=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                    if drtt>limsupdr
                                                                        QDR(d,h)=limsupdr;
                                                                        lackene(d,h)=drtt-QDR(d,h);
                                                                    else
                                                                        QDR(d,h)=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                        lackene(d,h)=0;
                                                                    end
                                                                    EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                    EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                end
                                                            end
                                                        else
                                                            for ii=1:1
                                                                QBESSout(d,h)=0;
                                                                soc(d,h)=assoc+nin*QBESSin(d,h)-QBESSout(d,h)/nout;
                                                                EHCBESS(d,h)=CFBESS-alfa*(QBESSout(d,h)-limsupsoc)/dsoc;
                                                                assoc=soc(d,h);
                                                                if QLOAD(d,h)>liminfgd
                                                                    for hh=1:1
                                                                        if QLOAD(d,h)<limsupgd
                                                                            QGD(d,h)=QLOAD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                            QDR(d,h)=0;
                                                                            EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                            EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                        else
                                                                            QGD(d,h)=limsupgd;
                                                                            drtt=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                            if drtt>limsupdr
                                                                                QDR(d,h)=limsupdr;
                                                                                lackene(d,h)=drtt-QDR(d,h);
                                                                            else
                                                                                QDR(d,h)=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                                lackene(d,h)=0;
                                                                            end
                                                                            EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                            EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                        end
                                                                    end
                                                                else
                                                                    QGD(d,h)=0;
                                                                    drtt=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                    if drtt>limsupdr
                                                                        QDR(d,h)=limsupdr;
                                                                        lackene(d,h)=drtt-QDR(d,h);
                                                                    else
                                                                        QDR(d,h)=QLOAD(d,h)-QGD(d,h)-QBESSout(d,h)-QSUN(d,h);
                                                                        lackene(d,h)=0;
                                                                    end
                                                                    EHCDR(d,h)=CFDR+QDR(d,h)*CPO/(ela*QLOAD(d,h));
                                                                    EHCGD(d,h)=CFGD+costolitro*CGD*(0.248225*QGD(d,h)/CGD+0.031151);
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                    end
                                end
                            end     % Final del end de las horas
                            
                            % Suma de costos totales
                            operationalcost(d,1)=(sum(EHCGD(d,:)))+(sum(EHCDR(d,:)))+(sum(EHCBESS(d,:)))+fcostexene*(sum(exeene(d,:)))+fcostlackene*(sum(lackene(d,:)));                    
                            tcost(d,1)=operationalcost(d,1);
                        end  % Despacho económico
                        
                        % llenado de matriz CM
                        CM(ffil+filreco-2,ccol+colreco-2)=operationalcost(HDPS,1);  % Aquí deben ir los costos del despacho
                    end
                end
            end
        end   % Llenado de la matriz

        for abbc=1
            % creación de descensos
            if colcentro==1;colcentro=8;searchgap=50;end
            if filcentro==1;filcentro=7;searchgap=50;end
            dir1=CM(filcentro,colcentro)-CM(filcentro-1,colcentro-1);
            dir2=CM(filcentro,colcentro)-CM(filcentro-1,colcentro);
            dir3=CM(filcentro,colcentro)-CM(filcentro-1,colcentro+1);
            dir4=CM(filcentro,colcentro)-CM(filcentro,colcentro-1);
            dir5=CM(filcentro,colcentro)-CM(filcentro,colcentro+1);
            dir6=CM(filcentro,colcentro)-CM(filcentro+1,colcentro-1);
            dir7=CM(filcentro,colcentro)-CM(filcentro+1,colcentro);
            dir8=CM(filcentro,colcentro)-CM(filcentro+1,colcentro+1);

            % comparación de descensos
            dirr=[dir1 dir2 dir3 dir4 dir5 dir6 dir7 dir8];
            [searchgap,dire]=max(dirr);
            % Actualización de centro
            if searchgap>0
                if dire==1; filcentro=filcentro-1;   colcentro=colcentro-1;  end
                if dire==2; filcentro=filcentro-1;   colcentro=colcentro;    end
                if dire==3; filcentro=filcentro-1;   colcentro=colcentro+1;  end
                if dire==4; filcentro=filcentro;     colcentro=colcentro-1;  end
                if dire==5; filcentro=filcentro;     colcentro=colcentro+1;  end
                if dire==6; filcentro=filcentro+1;   colcentro=colcentro-1;  end
                if dire==7; filcentro=filcentro+1;   colcentro=colcentro;    end
                if dire==8; filcentro=filcentro+1;   colcentro=colcentro+1;  end
            end

            % Actulización de las variables de recorrido
            filreco=filcentro;colreco=colcentro;
        end     % Definir dirección de avance
        
    end % Busqueda del minimo
        
    for a=1
        for bessc=1
            if colcentro==1 || colcentro==4 || colcentro ==7
                if floor(columna(colcentro).CBESS-(alfha)*saltob)>0
                    CBESS=floor(columna(colcentro).CBESS-(alfha)*saltob);
                    saltob=floor((0.9)*saltob);
                else 
                    CBESS=0;
                end
            end

            if colcentro==2 || colcentro==5 || colcentro ==8
                CBESS=floor(columna(colcentro).CBESS-(alfha)*saltob);
                saltob=floor((1-alfha)*saltob);
            end

            if colcentro==3 || colcentro==6 || colcentro ==9
                CBESS=(alfha)*columna(colcentro).CBESS;
                saltob=floor((0.9)*saltob);
            end
        end  % Actualización de CBESS

        for pvco=1
            if filcentro==1 || filcentro==4 || filcentro ==7
                if floor(fila(filcentro).CPV-(alfha)*saltopv)>0
                    CPV=floor(fila(filcentro).CPV-(alfha)*saltopv);
                    saltopv=floor((alfha)*saltopv);
                else 
                    CPV=0;
                end
            end

            if filcentro==2 || filcentro==5 || filcentro ==8
                CPV=floor(fila(filcentro).CPV-(alfha)*saltopv);
                saltopv=floor((1-alfha)*saltopv);
            end

            if filcentro==3 || filcentro==6 || filcentro ==9
                CPV=fila(filcentro).CPV;
                saltopv=floor((alfha)*saltopv);
            end
        end   % Actualización de PV
        
        for cdrco=1
            if filcentro==1 || filcentro==2 || filcentro ==3
                if floor(fila(filcentro).CDR-(alfha)*saltodr)>0
                    CDR=floor(fila(filcentro).CDR-(alfha)*saltodr);
                    saltodr=floor((1-alfha)*saltodr);
                else 
                    CDR=0;
                end
            end

            if filcentro==4 || filcentro==5 || filcentro ==6
                CDR=floor(fila(filcentro).CDR-(1-alfha)*saltodr);
                saltodr=floor((1-alfha)*saltodr);
            end

            if filcentro==7 || filcentro==8 || filcentro ==9
                if floor(fila(filcentro).CDR)<floor(0.1*max(max(QLOAD)))
                    CDR=fila(filcentro).CDR;
                    saltodr=floor((1-alfha)*saltodr);
                else 
                    CDR=floor(0.1*max(max(QLOAD)));
                end
                
            end
        end % Actualización de CDR
        
        for gdco=1
            if colcentro==1 || colcentro==2 || colcentro ==3
                if floor(columna(colcentro).CGD-(alfha)*saltogd)>0
                    CGD=floor(columna(colcentro).CGD-(alfha)*saltogd);
                    saltogd=floor((1-alfha)*saltogd);
                else 
                    CGD=0;
                end
            end

            if colcentro==4 || colcentro==5 || colcentro ==6
                CGD=floor(columna(colcentro).CGD-(1-alfha)*saltogd);
                saltogd=floor((1-alfha)*saltogd);
            end

            if colcentro==7 || colcentro==8 || colcentro ==9
                CGD=columna(colcentro).CGD;
                saltogd=floor((1-alfha)*saltogd);
            end
        end  % Actualización de GD
         
    end % Actualización de variables de dimensionamiento CPV, CBESS, CGD, CDR
    
    for a=1
        cpvplo(grco,1)=CPV;saltopvplo(grco,1)=saltopv;
        cbessplo(grco,1)=CBESS;saltobplo(grco,1)=saltob;
        cgdplo(grco,1)=CGD;saltogdplo(grco,1)=saltogd;
        cdrplo(grco,1)=CDR;saltodrplo(grco,1)=saltodr;
        
    end % almacenamiento de datos para graficación de convergencia

end % CM y redimensionado de CM 

toc

% Resultados 

TCOST=sum(tcost);
LCOE=TCOST/sum(sum((QGD+QDR+QBESSin+QBESSout+QSUN)));

CPV, CGD, CBESS, CDR, LCOE, vpa(TCOST,7)

for a=1
subplot(2,2,1)
plot(cpvplo);hold on
grid on;plot(saltopvplo);
% axis([1 iter 0 1300])
legend('PV','Step')

subplot(2,2,2)
plot(cbessplo);hold on
grid on;plot(saltobplo);
% axis([1 iter 0 600])
legend('BESS','Step')

subplot(2,2,3)
plot(cgdplo);hold on
grid on;plot(saltogdplo);
% axis([1 iter 0 600])
legend('GD','Step')

subplot(2,2,4)
plot(cdrplo);hold on
grid on;plot(saltodrplo);
% axis([1 iter 0 floor(0.1*max(max(QLOAD))+10)])
legend('DR','Step')
end % Graficación de convergencia del algoritmo

