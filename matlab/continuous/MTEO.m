%
%impements the MTEO detector according to 
%Choi,Jung,Kim 2006, IEEE T Biomed Eng
%
%urut/april07
function runTEO = MTEO(rawSignal, ks)

tmp=zeros(length(ks),length(rawSignal));

for i=1:length(ks)
    tmp(i,:) = runningTEO(rawSignal, ks(i));
    v(i) = var(tmp(i,:));

    %apply the window
    win = hamming( 4*ks(i)+1, 'symmetric');
    tmp(i,:) = filter( win,1,tmp(i,:)) ./ v(i);
    
end

runTEO= sum(tmp); %runTEO + tmp./v(i);
