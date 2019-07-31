function [FG,fc,CG,cc] = cartesiano(varargin)

for a=1
    narginchk(1,Inf) ;
    NC = nargin ;
    % check if we should flip the order
    if ischar(varargin{end}) && (strcmpi(varargin{end}, 'matlab') || strcmpi(varargin{end}, 'john'))
        % based on a suggestion by JD on the FEX
        NC = NC-1 ;
        ii = 1:NC ; % now first argument will change fastest
    else
        % default: enter arguments backwards, so last one (AN) is changing fastest
        ii = NC:-1:1 ;
    end
    args = varargin(1:NC) ;
    if any(cellfun('isempty', args)) % check for empty inputs
        warning('ALLCOMB:EmptyInput','One of more empty inputs result in an empty output.') ;
        A = zeros(0, NC) ;
    elseif NC == 0 % no inputs
        A = zeros(0,0) ; 
    elseif NC == 1 % a single input, nothing to combine
        A = args{1}(:) ; 
    else
        isCellInput = cellfun(@iscell, args) ;
        if any(isCellInput)
            if ~all(isCellInput)
                error('ALLCOMB:InvalidCellInput', ...
                    'For cell input, all arguments should be cell arrays.') ;
            end
            % for cell input, we use to indices to get all combinations
            ix = cellfun(@(c) 1:numel(c), args, 'un', 0) ;

            % flip using ii if last column is changing fastest
            [ix{ii}] = ndgrid(ix{ii}) ;

            A = cell(numel(ix{1}), NC) ; % pre-allocate the output
            for k = 1:NC
                % combine
                A(:,k) = reshape(args{k}(ix{k}), [], 1) ;
            end
        else
            % non-cell input, assuming all numerical values or strings
            % flip using ii if last column is changing fastest
            [A{ii}] = ndgrid(args{ii}) ;
            % concatenate
            A = reshape(cat(NC+1,A{:}), [], NC) ;
        end
    end
end % Codigo que crea el producto cartesiano y lo asigna a una matriz

con=1;
for f=1:9
    for c=1:9
        FG(f,1)=A(con,1);
        fc(f,1)=A(con,2);
        CG(c,1)=A(con,3);
        cc(c,1)=A(con,4);
        con=con+1;
    end
end

end