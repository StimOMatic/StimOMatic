%
%finds the peak of a spike for the purpose of realignment.
%
%alignMethod: 1=pos, 2=neg, 3=mix (order if both peaks are sig,otherwise max)
%
%urut/dec04
function peakInd = findPeak( spikeSignal,stdEstimate, alignMethod )

%find peak (either neagtive or positive)
maximum=max(spikeSignal);
minimum=min(spikeSignal);
peakInd=0;

sigLevel = 2*stdEstimate;

doMinMax=false;
switch(alignMethod)
    case 1 %pos if pos peak is sig,otherwise use neg.
        if abs(maximum)>sigLevel
            peakInd = find( spikeSignal == maximum );
        else
            peakInd = find( spikeSignal == minimum );
        end
        doMinMax=false;
    case 2 %neg if neg peak is sig,otherwise use max
        if abs(minimum)>sigLevel
            peakInd = find( spikeSignal == minimum );
        else
            peakInd = find( spikeSignal == maximum );
        end
        doMinMax=false;
    case 3 %mixed
        %if both the maximum and minimum are significant
        if abs(minimum)>sigLevel && abs(maximum)>sigLevel
            %one peak dominant -> use min max realignment
            if abs(minimum/maximum)>2 || abs(maximum/minimum)>2
                doMinMax=true;
            end
            %realign according to order of min .... max
            if find(spikeSignal==maximum) < find(spikeSignal==minimum)
                peakInd = find( spikeSignal == maximum );
            else
                %implies min...max
                peakInd = find( spikeSignal == minimum );
            end
        else
            %only minimum is significant -> realign at minimum
            if (abs(minimum)>sigLevel && abs(maximum)<sigLevel) || (abs(maximum)>sigLevel && abs(minimum)<sigLevel)
                doMinMax=true;
            else
                %neither max nor min is significant --> can't use this spike,
                %not enough information
                %'nothing significant'
                peakInd=-1;
            end
        end
end

if doMinMax
    if abs(maximum)>abs(minimum)
        peakInd = find( spikeSignal == maximum );
    else
        peakInd = find( spikeSignal == minimum );
    end
end
