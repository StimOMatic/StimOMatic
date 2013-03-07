%
% pick a random image from a collection of possible imgs
% used during psychophysics experimentScenes1_conditional experiment
%
function [imgToUse,fNameUsed] = experimentScenes1_chooseRandomImg(filenamesPossible)

r=floor(rand*length( filenamesPossible ));
if r==0
    r=1;
end
if r>length( filenamesPossible )
    r=1;
end

fNameUsed = filenamesPossible{r};
imgToUse = imread( fNameUsed );