%
% removes entry from a listbox. if indRemove=-1, remove current entry if
% one is selected
% h is handle to a listbox
%
%urut/dec11
function valOfRemovedEntry = removeEntryFromListbox( h, indRemove )
if nargin<2
    indRemove=-1;
end
if indRemove==-1
    indRemove = get( h, 'Value');
end
valOfRemovedEntry=[];

oldVals = get(h, 'String');
    
if indRemove>0 & length(oldVals)>=indRemove
    valOfRemovedEntry = oldVals{indRemove};
    
    newInds = setdiff(1:length(oldVals), indRemove);
    newVals = oldVals( newInds );
    set(h,'String', newVals );
end

if indRemove>length(get(h,'String'))
    %if last one was removed, mark the new last one so list doesnt jump
    set(h,'Value',length(get(h,'String')));
else    
    set(h,'Value',1);  %select an other
end