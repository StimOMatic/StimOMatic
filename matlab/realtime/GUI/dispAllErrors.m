%helper for try...catch
%
%urut/dec11
function dispAllErrors(E)
if ~isempty(E)
    
    
    disp( [E.identifier ' ' E.message '; Stack is:']);
    %if length(E.stack)>0
        for j=1:length(E.stack)
            disp(['file: ' E.stack(j).file ' name:' E.stack(j).name ' line:' num2str(E.stack(j).line) ]);
        end
    %end
    

    for ii = 1:length( E.cause )
        getReport(E.cause{ii})
    end
end