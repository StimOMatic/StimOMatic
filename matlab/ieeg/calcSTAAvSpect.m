%
%spectrum of the STA (spike-triggered average)
%
%urut/nov08
function [S,f,Serr,paramsUsed] = calcSTAAvSpect( avTrace, paramsIn, FsSTA)
Serr=[];

%setup the tapers
params.Fs=FsSTA; % sampling frequency
params.err=[0 0.05]; % population error bars
params.trialave=0;
params.fpass = copyFieldIfExists( paramsIn, 'fpass', [1 100] );
params.tapers= copyFieldIfExists( paramsIn, 'tapers', [2 3]);
params.err= copyFieldIfExists( paramsIn, 'err', [0 0.05]);
params.pad= copyFieldIfExists( paramsIn, 'pad', -1);

if params.err(1)>0
    [S,f,Serr]=mtspectrumc( avTrace, params);
else
    [S,f]=mtspectrumc( avTrace, params);
end

paramsUsed=params;