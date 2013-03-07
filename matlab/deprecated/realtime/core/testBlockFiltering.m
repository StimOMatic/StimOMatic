%
%test blockwise filtering vs filtering the entire trace, to reduce artifacts
%

%%
Fs =32000;
Wn=120;
n=4;
[b,a]=butter(n,Wn/(Fs/2),'low');
Hd{1}=b;
Hd{2}=a;


%filter for spikes
WnSpikes=[300 3000];
[b,a]=butter(n,WnSpikes/(Fs/2));
HdSpikes{1}=b;
HdSpikes{2}=a;


rawSignal = cumsum( randn(1,Fs*3) );

filteredSignal = filtfilt(HdSpikes{1}, HdSpikes{2}, rawSignal);

%% try sequential filtering

blockSize = 5000;

nrOverlap = 1000;


nrBlocks = floor(length(rawSignal)/blockSize);

filteredBlocks=[];

filteredSignal2=[];
for k=1:nrBlocks

    indsToUse = 1+(k-1)*blockSize:blockSize*k;
    
    if k>1
        %add overlap at beginning
        
        indsToUse = [ indsToUse(1)-nrOverlap:indsToUse(1)-1 indsToUse];
    end
    
    
    tmpAdd = filtfilt(HdSpikes{1}, HdSpikes{2}, rawSignal(indsToUse) );
    
  
    if k==1
        filteredSignal2 = [ filteredSignal2 tmpAdd];
    %filteredBlocks(k,:) = tmpAdd;
        
    else
        filteredSignal2 = [ filteredSignal2(1:end-(nrOverlap/2)) tmpAdd(nrOverlap/2+1:end)];
    %filteredBlocks(k,:) = tmpAdd(nrOverlap/2:end);
        
    end
end


%filteredSignal3 = filterSignal_appendBlock( HdSpikes, CSCBufferData, processedData.filteredDataLFP, newDataScaled, nrOverlap );
                
%%
figure(30);
subplot(3,1,1);
plot(1:length(rawSignal),rawSignal);

subplot(3,1,2);
plot(1:length(filteredSignal),filteredSignal,'b', 1:length(filteredSignal2),filteredSignal2,'r', 1:length(filteredSignal2),filteredSignal2-filteredSignal( 1:length(filteredSignal2)),'g');

subplot(3,1,3);
inds= 1:length(filteredSignal2)-400;
plot(inds,filteredSignal2(inds)-filteredSignal(inds), 'g' );

