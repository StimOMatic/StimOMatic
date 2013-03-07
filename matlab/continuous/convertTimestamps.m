%
%converts from internal representation of timestamps to real timestamps
%
%internal representation (indTimestamps) is relative to the currently processed block (0=start of current block)
%rawTimestamps is absolute value retrieved from file. file has only one timestamp per block. each block
%consists of 512 values. 
%
%Fs: sampling rate
%
%if indTimestamps empty - > convert entire rawTimestamps to realTimestamps (multiply out blocks)
%
%orig: urut/april04
%updates: 
%urut/feb07. added Fs parameter.
%urut/april07. added fileformat parameter.
%
function realTimestamps = convertTimestamps( rawTimestamps, indTimestamps, Fs, fileFormat )

usPerSample=1000000/Fs;

if fileFormat<=2
    %for neuralynx fileformat, convert to blocks
    
    samplesPerBlock=512; %this is a property of the Ncs format (512 samples per timestamp).
    
    if ~isempty( indTimestamps)
        realTimestamps=zeros(1,length(indTimestamps));
        for i=1:length(indTimestamps)
            n = floor(indTimestamps(i)/512);

            realTimestamps(i) = rawTimestamps(n+1) + (indTimestamps(i) - n*samplesPerBlock)*usPerSample;
            %for example: 0.00004 = 25khz sampling rate. timestamps are in us
        end
    else        
        realTimestamps = zeros(1, length(rawTimestamps)*samplesPerBlock );
        for i=1:length(rawTimestamps)           
            realTimestamps( (i-1)*samplesPerBlock+1:samplesPerBlock*i ) = [ rawTimestamps(i):usPerSample:(rawTimestamps(i)+(samplesPerBlock-1)*usPerSample) ];
        end
    end
else
    %for other formats, take raw timestamp
    realTimestamps = rawTimestamps(indTimestamps);
    realTimestamps = realTimestamps';
end



