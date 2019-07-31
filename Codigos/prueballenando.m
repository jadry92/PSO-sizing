clc;close all;clear all;
% extiter=100;
% maxmem=zeros(1,extiter);
% matmem=zeros(1,extiter);
% phiav=zeros(1,extiter);
% phitot=zeros(1,extiter);

% for supercon=1:100
tic
for a=1
    alpasol=1;          % Sun
    alpadiesel=1;       % Diesel
    alpabat=1;          % Battery
end % Variables para el análisis de sensibilidad
for a=1
    HDPS=15;
    load('sol','-mat');% Carga de datos de sol
    sole(1:15,:)=alpasol*sol;   % Creacion de variable de sol para el analisis de sensibilidad
    load('qload','-mat');  
    
    for b=1
        alfapv=0.2397;
        alfabess=0.2629;
        alfagd=0.2585;
        alfadr=0.6743;

        % Limits
        CPVMin      =52.4602;    % Inferior Limit PV
        CPVMax      =666.7057;   % Inferior Limit PV
        CBESSMin    =244.3750;   % Inferior Limit PV
        CBESSMax    =600.1111;   % Inferior Limit PV
        CGDMin      =305.2681;   % Inferior Limit PV
        CGDMax      =566.8599;   % Inferior Limit PV
        CDRMin      =35.1856;    % Inferior Limit PV
        CDRMax      =50;         % Inferior Limit PV
    end % Pruebas arregladas con AG
    for b=1
%         alfapv=0.2397;
%         alfabess=0.2629;
%         alfagd=0.2585;
%         alfadr=0.6743;
% 
%         % Limits
%         CPVMin      =100.4602;   % Inferior Limit PV
%         CPVMax      =700.7057;   % Inferior Limit PV
%         CBESSMin    =100.3750;   % Inferior Limit PV
%         CBESSMax    =600.1111;   % Inferior Limit PV
%         CGDMin      =200.2681;   % Inferior Limit PV
%         CGDMax      =700.8599;   % Inferior Limit PV
%         CDRMin      =10.1856;    % Inferior Limit PV
%         CDRMax      =50;         % Inferior Limit PV
    end % Pruebas arregladas sin AG
end % Inicialización del algortimo
for grco=1:10 
    for a=1
        % Initialitaion Particles
        n=3; %%% <-- NO MORE THAN 20 

        CPVcomb=linspace(CPVMin,CPVMax,n);          % FC = FILA GRANDE
        CBESScomb=linspace(CBESSMin,CBESSMax,n);    % fc = fila chiquita
        CGDcomb=linspace(CGDMin,CGDMax,n);          % CG = COLUMNA GRANDE
        CDRcomb=linspace(CDRMin,CDRMax,n);          % cc = columna chiquita                            

        C = [CPVcomb;CBESScomb;CGDcomb;CDRcomb];
        sizeC = size(C);
        [FG,fc,CG,cc]=cartesiano(C(1,:),C(2,:),C(3,:),C(4,:)); % Asignación de valores a filas y columnas
        
        for f=1:9
            for c=1:9
                CPV=FG(f);
                CBESS=fc(f);

                CGD=CG(c);
                CDR=cc(c);

                QSUN=CPV*sole/1000;
                CM2(f,c)=despacho2(CPV,CBESS,CGD,CDR,HDPS,QSUN,QLOAD,alpadiesel,alpabat);
            end
        end % Llenado de la matriz completa
        mint=min(min(CM2));
        for f=1:9
            for c=1:9
                if CM2(f,c)==mint
                    fmin=f;
                    cmin=c;
                end
            end
        end % Ubicación del minimo (fila, columna)

    end % Lanzado de particulas para la busqueda
    for a=1
        for b=1
            saltopv=CPVcomb(2)-CPVcomb(1);
            if fmin==1 || fmin==2 || fmin ==3
                if CPVcomb(1)-saltopv>0
                    CPVMin=CPVcomb(1)-saltopv;
                    CPVMax=CPVcomb(2);
                else 
                    CPVMin=0;
                    CPVMax=2*saltopv;
                end
            end

            if fmin==4 || fmin==5 || fmin ==6
                CPVMin=CPVcomb(2)-alfapv*saltopv;
                CPVMax=CPVcomb(2)+alfapv*saltopv;
            end

            if fmin==7 || fmin==8 || fmin ==9
                CPVMin=CPVcomb(2);
                CPVMax=CPVcomb(3)+saltopv;
            end
        end   % Actualización de PV
        for b=1
            saltobess=CBESScomb(2)-CBESScomb(1);
            if fmin==1 || fmin==4 || fmin ==7
                if CBESScomb(1)-saltobess>0
                    CBESSMin=CBESScomb(1)-saltobess;
                    CBESSMax=CBESScomb(2);
                else 
                    CBESSMin=0;
                    CBESSMax=2*saltobess;
                end
            end

            if fmin==2 || fmin==5 || fmin ==8
                CBESSMin=CBESScomb(2)-alfabess*saltobess;
                CBESSMax=CBESScomb(2)+alfabess*saltobess;
            end

            if fmin==3 || fmin==6 || fmin ==9
                CBESSMin=CBESScomb(2);
                CBESSMax=CBESScomb(3)+saltobess;
            end
        end   % Actualización de BESS        
        for b=1
            saltogd=CGDcomb(2)-CGDcomb(1);
            if cmin==1 || cmin==2 || cmin ==3
                if CGDcomb(1)-saltogd>0
                    CGDMin=CGDcomb(1)-saltogd;
                    CGDMax=CGDcomb(2);
                else 
                    CGDMin=0;
                    CGDMax=2*saltogd;
                end
            end

            if cmin==4 || cmin==5 || cmin ==6
                CGDMin=CGDcomb(2)-alfagd*saltogd;
                CGDMax=CGDcomb(2)+alfagd*saltogd;
            end

            if cmin==7 || cmin==8 || cmin ==9
                CGDMin=CGDcomb(2);
                CGDMax=CGDcomb(3)+saltogd;
            end
        end   % Actualización de GD
        for b=1
            saltodr=CDRcomb(2)-CDRcomb(1);
            if cmin==1 || cmin==4 || cmin ==7
                if CDRcomb(1)-saltodr>0
                    CDRMin=CDRcomb(1)-saltodr;
                    CDRMax=50;
                else 
                    CDRMin=0;
                    CDRMax=50;
                end
            end

            if cmin==2 || cmin==5 || cmin ==8
                CDRMin=CDRcomb(2)-alfadr*saltodr;
                CDRMax=50;
            end

            if cmin==3 || cmin==6 || cmin ==9
                CDRMin=CDRcomb(2);
                CDRMax=50;
            end
        end   % Actualización de DR
    end % Proceso de actualización de límites
    for a=1
        PVP(1,grco)=FG(fmin);saltopvplo(1,grco)=saltopv;
        BESSP(1,grco)=fc(fmin);saltobessplo(1,grco)=saltobess;
        GDP(1,grco)=CG(cmin);saltogdplo(1,grco)=saltogd;
        DRP(1,grco)=cc(cmin);saltodrplo(1,grco)=saltodr;
        % Creación de grafíca de convergencia
        tt=clock;segu(1,grco)=tt(6);
        dispv(1,grco)=(PVP(1,grco)-355);
        disb(1,grco)=(BESSP(1,grco)-3);
        disgd(1,grco)=(GDP(1,grco)-530);
        disdr(1,grco)=(DRP(1,grco)-50);
    end % Proceso de almacenamiento de variables para graficación
end % Número de iteraciones del algoritmo
toc

[userview,systemview] = memory

% maxmem(1,supercon)=userview.MaxPossibleArrayBytes;
% matmem(1,supercon)=userview.MemUsedMATLAB;
% phiav(1,supercon)=systemview.PhysicalMemory.Available;
% phitot(1,supercon)=systemview.PhysicalMemory.Total;

for a=1
% Resultados
% PV=FG(fmin)
% BESS=fc(fmin)
% GD=CG(cmin)
% DR=cc(cmin)
% mint

% plot(segu-segu(1,1),dispv);hold on;grid on
% plot(segu-segu(1,1),disb)
% plot(segu-segu(1,1),disgd)
% plot(segu-segu(1,1),disdr)
% legend('PV','BESS','GD','DR')
end % Resultados 
for a=1
% subplot(2,2,1)
% plot(PVP);hold on
% grid on;plot(saltopvplo);
% legend('PV','Step')
% 
% subplot(2,2,2)
% plot(BESSP);hold on
% grid on;plot(saltobessplo);
% legend('BESS','Step')
% 
% subplot(2,2,3)
% plot(GDP);hold on
% grid on;plot(saltogdplo);
% legend('GD','Step')
% 
% subplot(2,2,4)
% plot(DRP);hold on
% grid on;plot(saltodrplo);
% legend('DR','Step')
end % Graficación de convergencia del algoritmo
for f=1:9
%     for c=1:9
%         CPV=FG(f);
%         CBESS=fc(f);
%         
%         CGD=CG(c);
%         CDR=cc(c);
%         
%         QSUN=CPV*sole/1000;
%         CM(f,c)=despacho2(CPV,CBESS,CGD,CDR,HDPS,QSUN,QLOAD,alpadiesel,alpabat);
%     end
end % Llenado total de la matriz CM
for a=1
% figu=figure;
% surf(CM)
% grid on
% set(gcf,'renderer','Painters')
% title(['\fontsize{26}5. FDGfbCPVcdr'])
% figu.PaperSize = [5.6 4.3];
% figu.PaperPosition(1:2) = [-0.2 -0.1];
% print -dpdf 11.pdf
end % Graficación de la matriz CM
% end



% totalmem=sum(maxmem)/extiter
% matlabmem=sum(matmem)/extiter
% phisicaldisponible=sum(phiav)/extiter
% pshisicaltotal=sum(phitot)/extiter

