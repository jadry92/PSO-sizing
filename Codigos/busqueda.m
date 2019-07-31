function [CM,fout,cout]=busqueda(f0,c0,CM,FG,fc,CG,cc,HDPS,sole,QLOAD,alpadiesel,alpabat)


% Punto de inicio y proceso de busqueda de minimo
m=200;
while m>100
    for fi=1:3
        for co=1:3
            t=0;
            if fi-2+f0==0;t=1;end;if fi-2+f0==0;t=1;end; if co-2+c0==0;t=1;end; if co-2+c0==9;t=1;end
            if t>0
                CM(fi-1+f0,co-1+c0)=50e6;
            else
                if  CM(fi-2+f0,co-2+c0)==5e5
                    CPV=FG(fi-2+f0);CBESS=fc(fi-2+f0);CGD=CG(co-2+c0);CDR=cc(co-2+c0);
                    QSUN=CPV*sole/1000;
                    CM(fi-2+f0,co-2+c0)=despacho2(CPV,CBESS,CGD,CDR,HDPS,QSUN,QLOAD,alpadiesel,alpabat); 
                end
            end

        end
    end

    % Dirección de avance
    t=0;dif=zeros(9,9);
    for fi=1:3
        for co=1:3
            if fi-2+f0==0;t=1;end;if fi-2+f0==0;t=1;end; if co-2+c0==0;t=1;end; if co-2+c0==9;t=1;end
            if t>0
                dif(fi-1+f0,co-1+c0)=-5e3;
            else
                dif(fi-2+f0,co-2+c0)=CM(f0,c0)-CM(fi-2+f0,co-2+c0);
            end
        end
    end % Llenado de la matriz CM

    m=max(max(dif));
    if m>0;
        for fi=1:3
            for co=1:3
                if dif(fi-2+f0,co-2+c0)==m
                    fav=fi-2+f0;
                    cav=co-2+c0;
                end
            end
        end % Dirección de avance
        
    else
        fav=f0;
        cav=c0;
    end

    % Reasignación de 'centro' para nueva busqueda en alrededores
    f0=fav;
    c0=cav;
end

fout=f0;
cout=c0;
          


end


