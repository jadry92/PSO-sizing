function [TCOST] = despacho2(CPV,CBESS,CGD,CDR,HDPS,QSUN,QLOAD,alpadiesel,alpabat)
% Despacho function is encharched to simulate the small grid
% and find the final cost of this system.

%% Initialtation variables



% Variables despacho econ�mico
ddvpv=25*365;               % D�as de vida del sistema PV
ddvbess=8*365;              % D�as de vida del BESS
ddvgd=15*365;               % D�as de vida del DG
ddvdr=25*365;               % D�as de vida de la DR
ela=0.2;                    % Elasticidad de la demanda
alpa=20;                    % Variable alpha para el costo de la bater�a

% Costos unitarios de instalaci�n diarios (FALTA PONER FACTOR DE DESCUENTO)
IIPV=1300/(ddvpv);          % Inversion incial dividida en d�as de vida del PV  [kW]
IIBESS=420*alpabat/(ddvbess);       % Inversion incial dividida en d�as de vida de BESS [kWh]
IIGD=550/(ddvgd);           % Inversion incial dividida en d�as de vida del GD  [kW]
IIDR=50/(ddvdr);            % Inversion incial dividida en d�as de vida del 

EHCDR=zeros(HDPS,24);       % Variable para almacenar costos horarios equivalentes de la DR
EHCBESS=zeros(HDPS,24);     % Variable para almacenar costos horarios equivalentes del BESS
EHCGD=zeros(HDPS,24);       % Variable para almacenar costos horarios equivalentes del GD
EHCPV=zeros(HDPS,24);
QBESSin=zeros(HDPS,24);     % Variable de carga de la bater�a
QBESSout=zeros(HDPS,24);    % Variable de descarga de la bater�a
QDR=zeros(HDPS,24);         % variable de salida de la respuesta de la demanda
QGD=zeros(HDPS,24);        % variable de salida de la respuesta de la demanda


% Extra variables
exeene1 = zeros(HDPS,24);
gendispo = zeros(HDPS,24);
soc=zeros(HDPS,24);         % Inicializaci�n de la variable estado de carga
exeene=zeros(HDPS,24);      % Exceso de energ�a
lackene=zeros(HDPS,24);     % Falta de energ�a
TQBESS = zeros(HDPS,24);
TQGD = zeros(HDPS,24);

%output varibles
operationalcost = zeros(HDPS,1);
tcost = zeros(HDPS,1);


%% Estimaci�n de costos fijos
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


%%
for d=1:HDPS
    for h=1:24
        EHCPV(d,h)=(CPV*IIPV+CPV*MPV)/24; % Costos fijos del PV
        
        % Despacho cuando QSUN es mayor a QLOAD
        if QSUN(d,h) > QLOAD(d,h)   
            gendispo(d,h)=QSUN(d,h)-QLOAD(d,h);
            if gendispo(d,h)>ratecha
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
            else
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
        else
            if QLOAD(d,h)>ratedis
                TQBESS(d,h)=0;      % Salida temporal de bater�a
                TQGD(d,h)=0;        % Salida temporal de generaci�n diesel
                tsoc=assoc;         % Reasignaci�n de estado actual de carga
                for cac=1:1:floor(QLOAD(d,h)-QSUN(d,h))
                    TBESS=CFBESS*(TQBESS(d,h)/tsoc);
                    TGD=CFGD+costolitro*CGD*(0.248225*TQGD(d,h)/CGD+0.031151);
                    if TBESS<TGD
                        TQBESS(d,h)=TQBESS(d,h)+1;
                        tsoc=tsoc-1;
                    else
                        TQGD(d,h)=TQGD(d,h)+1;
                    end
                end  % Distribuci�n optima de potencia en funci�n del costo

                if TQBESS(d,h)>ratedis
                    for ee=1:1
                        if assoc>liminfsoc
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
                        else
                            QBESSout(d,h)=0;
                            soc(d,h)=assoc+nin*QBESSin(d,h)-QBESSout(d,h)/nout;
                            EHCBESS(d,h)=CFBESS-alfa*(QBESSout(d,h)-limsupsoc)/dsoc;
                            assoc=soc(d,h);
                            if QLOAD(d,h)>liminfgd
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
                else
                    if assoc>liminfsoc
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
                    else
                        QBESSout(d,h)=0;
                        soc(d,h)=assoc+nin*QBESSin(d,h)-QBESSout(d,h)/nout;
                        EHCBESS(d,h)=CFBESS-alfa*(QBESSout(d,h)-limsupsoc)/dsoc;
                        assoc=soc(d,h);
                        if QLOAD(d,h)>liminfgd
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
            else
                TQBESS(d,h)=0;      % Salida temporal de bater�a
                TQGD=0;             % Salida temporal de generaci�n diesel
                tsoc=assoc;         % Reasignaci�n de estado actual de carga
                for cac=1:1:floor(QLOAD(d,h)-QSUN(d,h))
                    TBESS=CFBESS*(TQBESS(d,h)/tsoc);
                    TGD=CFGD+costolitro*CGD*(0.248225*TQGD/CGD+0.031151);
                    if TBESS<TGD
                        TQBESS(d,h)=TQBESS(d,h)+1;
                        tsoc=tsoc-1;
                    else
                        TQGD=TQGD+1;
                    end
                end  % Distribuci�n optima de potencia en funci�n del costo

                if assoc>liminfsoc
                    for gg=1:1
                        if assoc-TQBESS(d,h)<liminfsoc
                            QBESSout(d,h)=assoc-liminfsoc;
                        else
                            QBESSout(d,h)=TQBESS(d,h);
                        end
                        
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
                    QBESSout(d,h)=0;
                    soc(d,h)=assoc+nin*QBESSin(d,h)-QBESSout(d,h)/nout;
                    EHCBESS(d,h)=CFBESS-alfa*(QBESSout(d,h)-limsupsoc)/dsoc;
                    assoc=soc(d,h);
                    if QLOAD(d,h)>liminfgd
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
    end     % Final del end de las horas

    % Suma de costos totales
    operationalcost(d,1)=CFPV+(sum(EHCGD(d,:)))+(sum(EHCDR(d,:)))+(sum(EHCBESS(d,:)))+fcostexene*(sum(exeene(d,:)))+fcostlackene*(sum(lackene(d,:)));                    

    
    
end  % Despacho econ�mico    

TCOST=sum(operationalcost);


end

