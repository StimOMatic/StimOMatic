function  [S2D,f,windowOnsets] = calcWindowedSpect( trace, paramsIn, Fs, windowSize, stepSize )

indsOn = 1:stepSize:length(trace);


S2D=[];
for k=1:length(indsOn)
    indsToUse = indsOn(k):indsOn(k)+windowSize;
    if indsToUse(end)>length(trace)
        break;
    end
    
    traceSeg = trace( indsToUse );
    
    [S,f,Serr,paramsUsed] = calcSTAAvSpect( traceSeg, paramsIn, Fs);
    
    S2D(:,k) = S;
end


windowOnsets = indsOn(1:k);