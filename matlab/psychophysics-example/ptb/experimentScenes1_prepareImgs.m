%
% prepare the image to show in the next trial
%
%
function imgToUse = experimentScenes1_prepareImgs( imgSequence1, imgSequence2, imgOrig, sequencePresentationMode, sequencePresentationState, pickRandomImgSecondary, pickRandomImgPrimary, filenamesSecondary)

if sequencePresentationMode
    if sequencePresentationState   % if yes, waiting for the secondary
        if pickRandomImgSecondary
            imgToUse = experimentScenes1_chooseRandomImg(filenamesSecondary);
        else
            imgToUse = imgSequence2;
        end
    else
        if pickRandomImgPrimary
            imgToUse = experimentScenes1_chooseRandomImg(filenamesSecondary);
        else
            imgToUse = imgSequence1;   % first image in the sequence
        end
    end
else
    %default if not in sequence mode
    imgToUse = imgOrig;
end
