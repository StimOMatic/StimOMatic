%
%normalize a spectrum by its baseline (to cancel 1/f)
%normalization is done independently at each frequency
%
%if spect2DforBaseline is not set, spect2D is also used to estimate the
%baseline
%
%urut/sept10/MPI
function [spect2DNorm,baselineUsed] = baselineNormalizeSpectra( spect2D, indsBaseline, spect2DforBaseline )
if nargin<3
    spect2DforBaseline=spect2D;
end

spect2DNorm = [];
baselineUsed=[];
for k=1:size(spect2D,1)
    
    baselineUsed(k) = mean(spect2DforBaseline(k, indsBaseline ));
    spect2DNorm(k,:) = spect2D(k,:) ./ baselineUsed(k);
end