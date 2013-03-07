%
%update the status listbox in the gui
%
%urut/dec11, ak/nov2012
function addEntryToStatusListbox( h, newVal, isAddTimestamp, maxVals )

    if nargin < 3
        isAddTimestamp=1;
    end

    if nargin < 4
        maxVals=5;
    end
    
    %%

    if isAddTimestamp
        timeStr =  datestr(now,'mm/dd HH:MM:SS');
        newVal = [timeStr ' ' newVal ];
    end

    vals = get(h, 'String');
    % first dimension is 1 even if "vals" is empty.
    if isempty(vals)
        nbr_vals = 0;
    else
        nbr_vals = size(vals, 1);
    end

    if nbr_vals >= maxVals
        valsNew = { vals{2:maxVals},newVal };
    else
        if nbr_vals > 0
            valsNew = { vals{1:end} newVal };
        else
            valsNew = {newVal};
        end
    end

    set(h, 'String', valsNew );

end
%% EOF    

    