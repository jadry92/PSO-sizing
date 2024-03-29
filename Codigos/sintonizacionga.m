function mint=sintonizacionga(X)

for a=1
    alpasol=1;          % Sun
    alpadiesel=1;       % Diesel
    alpabat=1;          % Battery
end % Variables para el análisis de sensibilidad

for a=1
    alfapv=     X(1,1);
    alfabess=   X(1,2);
    alfagd=     X(1,3);
    alfadr=     X(1,4);
    
    HDPS=15;
    load('sol','-mat');% Carga de datos de sol
    sole(1:15,:)=alpasol*sol;   % Creacion de variable de sol para el analisis de sensibilidad
    load('qload','-mat');  
    
    % Limits
    CPVMin      = 305;      % Inferior Limit PV
    CPVMax      = 700;      % Inferior Limit PV
    CBESSMin    = 400;       % Inferior Limit PV
    CBESSMax    = 500;      % Inferior Limit PV
    CGDMin      = 300;      % Inferior Limit PV
    CGDMax      = 900;      % Inferior Limit PV
    CDRMin      = 10;       % Inferior Limit PV
    CDRMax      = 50;       % Inferior Limit PV
end % Inicialización del algortimo

for grco=1:20 
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

        CM=5e5*ones(9,9);
        % Particula 1
        fini1=3;cini1=5; % Punto de inicio
        [CM,fmin1,cmin1]=busqueda(fini1,cini1,CM,FG,fc,CG,cc,HDPS,sole,QLOAD,alpadiesel,alpabat);
        minp1=min(min(CM));mint=minp1;fmin=fmin1;cmin=cmin1;
%         % Particula 2
%         fini2=7;cini2=3; % Punto de inicio
%         [CM,fmin2,cmin2]=busqueda(fini2,cini2,CM,FG,fc,CG,cc,HDPS,sole,QLOAD,alpadiesel,alpabat);
%         minp2=min(min(CM));
% 
%         if minp1~=minp2
%             % Particula 3
%             fini3=4;cini3=7; % Punto de inicio
%             [CM,fmin3,cmin3]=busqueda(fini3,cini3,CM,FG,fc,CG,cc,HDPS,sole,QLOAD,alpadiesel,alpabat);
%             minp3=min(min(CM));
%             [mint,pos]=min([minp1 minp2 minp3]);
%             if pos==1;fmin=fmin1;cmin=cmin1;end
%             if pos==2;fmin=fmin2;cmin=cmin2;end
%             if pos==3;fmin=fmin3;cmin=cmin3;end
%         else
%             mint=minp2;
%             fmin=fmin2;
%             cmin=cmin2;
%         end
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
end % Número de iteraciones del algoritmo
mint

end