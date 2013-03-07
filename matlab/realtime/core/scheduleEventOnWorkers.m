%
%
%scheduledEventsStack is a Composite
%
%urut/dec11
function scheduledEventsStack = scheduleEventOnWorkers( scheduledEventsStack, eventToSchedule, nrWorkersInUse )

for k=1:nrWorkersInUse
    currentStackOfWorker = scheduledEventsStack{k};
    
    for j=1:length(currentStackOfWorker)    %all channels on this worker
        currentStackOfWorker{j} = [ currentStackOfWorker{j}; eventToSchedule ] ;
    end
    
    scheduledEventsStack{k} = currentStackOfWorker;
end