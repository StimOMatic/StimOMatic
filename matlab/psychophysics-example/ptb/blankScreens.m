function blankScreens( winHandles, colorToUse )

for k=1:length(winHandles)   
    if winHandles(k)>-1
        textureIndex = Screen('MakeTexture', winHandles(k), colorToUse);

        Screen('DrawTexture', winHandles(k), textureIndex, [], []);%srect defines spot size, automatic centred
 
        Screen('FillRect',winHandles(k),colorToUse); %,[w/2-fixs h/2-fixs w/2+fixs h/2+fixs])
 
        Screen('Flip', winHandles(k));
        Screen('Close', textureIndex); 
        
        
    end
end
