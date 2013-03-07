%
%a special version of interpolateTimestamps.m, speed optimized.
%
%urut/feb12
function [yi] = interpolateTimestamps_optimized( timestamps, Fs)
%blockSize=512;
stepsize=1e6/Fs;

yi=nan(1,512*length(timestamps));

for j=1:length(timestamps)
    yi(1+(j-1)*512:512*j) =  [timestamps(j):stepsize:(timestamps(j)+stepsize*511)] ;
end

%timestamps = [ timestamps timestamps(end)+512*Fs/1e6 ]; % need to add one timepoint

%x = 0:blockSize:length(dataSamples);
%xi = 1:length(dataSamples);
%yi = interp1q(x',timestamps', xi' );