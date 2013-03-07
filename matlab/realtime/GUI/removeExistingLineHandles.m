%
%removes list of handles (lines)
%
function removeExistingLineHandles ( plotLine1_axesCSCall )
plotLine1_axesCSCall=plotLine1_axesCSCall(:); 
    for j=1:length(plotLine1_axesCSCall)
        if ishandle( plotLine1_axesCSCall(j) )
            delete(  plotLine1_axesCSCall(j) );
        end
    end