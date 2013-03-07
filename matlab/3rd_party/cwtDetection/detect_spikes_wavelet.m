function TE=detect_spikes_wavelet(Signal,SFr,Wid,option,L,wname, ...
    Plot,Comment)

% DETECT_SPIKES_WAVELET wavelet based algorithm for detection of transients
% from neural data.
%
%   TE=DETECT_SPIKES_WAVELET(Signal,SFr,Wid,'option',L,'wname',Plot,Comment)
%
%   Signal - spike train to be analyzed 1 x Nt;
%
%   SFr - sampling frequency [kHz];
%
%   Wid - 1 x 2 vector of expected minimum and maximum width [msec] of transient 
%   to be detected Wid=[Wmin Wmax]. For most practical purposes Wid=[0.5 1.0];
%
%   option: the action taken when no coefficient survive hard thresholding
%           'drop' means return no spikes
%           'reset' means assume P(S)
%
%   L is the factor that multiplies [cost of comission]/[cost of omission].
%   For most practical purposes -0.2 <= L <= 0.2. Larger L --> omissions
%   likely, smaller L --> false positives likely. For unsupervised
%   detection, the suggested value of L is close to 0.  
%
%   wname : the name of wavelet family in use
%           'bior1.5' - biorthogonal
%           'bior1.3' - biorthogonal
%           'db2'     - Daubechies
%           'sym2'    - symmlet
%           'haar'    - Haar function
%   Note: sym2 and db2 differ only by sign --> they produce the same
%   result;
%
%   Plot is the plot flag, Plot=1 --> generate figures, otherwise do not;
%  
%   Comment is the comment flag, Comment=1 --> display comments, otherwise
%   do not;
%
%   TE is the vector of event occurrence times;

%   Zoran Nenadic
%   California Institute of Technology
%   May 2003

%admissible wavelet families
wfam={'bior1.5','bior1.3','sym2','db2','haar'};

if sum(strcmp(wname,wfam))==0
    error('unknown wavelet family')
elseif Comment==1
    disp(['wavelet family: ' wname])
    to=clock;
end

%make sure signal is zero-mean
Signal=Signal-mean(Signal);

Nt=length(Signal);      %# of time samples

%define relevant scales for detection
W1=Wid(1);
W2=Wid(2);
W1=round(W1*SFr)+1;
W2=round(W2*SFr)+1;

W1=W1-rem(W1,2);    %make sure it is even
W=W1:2:W2;          %filters should be of even length
Nw=length(W);

%initialize the matrix of thresholded coefficients
ct=zeros(Nw,Nt);

%get all coefficients 
c=cwt(Signal,W,wname);  

%define detection parameter
Lmax=36.7368;       %log(Lcom/Lom), where the ratio is the maximum 
                    %allowed by the current machine precision
L=L*Lmax;

%initialize the vector of spike indicators, 0-no spike, 1-spike
Io=zeros(1,Nt);

%loop over scales
for i=1:Nw
    
    %take only coefficients that are independent (W(i) apart) for median
    %standard deviation
    
    Sigmaj=median(abs(c(i,1:W(i):end)-mean(c(i,:))))/0.6745;
    Thj=Sigmaj*sqrt(2*log(Nt));     %hard threshold
    index=find(abs(c(i,:))>Thj);
    if isempty(index) & strcmp(num2str(option),'drop')
        %do nothing ct=[0];
    elseif isempty(index) & strcmp(num2str(option),'reset')
        Mj=Thj;
        %assume at least one spike
        PS=1/Nt;
        PN=1-PS;
        DTh=Mj/2+Sigmaj^2/Mj*[L+log(PN/PS)];    %decision threshold
        DTh=abs(DTh)*(DTh>=0);                 %make DTh>=0
        ind=find(abs(c(i,:))>DTh);
        if isempty(ind)
            %do nothing ct=[0];
        else
            ct(i,ind)=c(i,ind);
        end
    else
        Mj=mean(abs(c(i,index)));       %mean of the signal coefficients
        PS=length(index)/Nt;            %prior of spikes
        PN=1-PS;                        %prior of noise
        DTh=Mj/2+Sigmaj^2/Mj*[L+log(PN/PS)];   %decision threshold
        DTh=abs(DTh)*(DTh>=0);         %make DTh>=0
        ind=find(abs(c(i,:))>DTh);
        ct(i,ind)=c(i,ind);
    end
    
    %find which coefficients are non-zero
    Index=ct(i,:)~=0;
    
    %make a union with coefficients from previous scales
    Index=or(Io,Index);
    Io=Index;
end

TE=parse(Index,SFr,Wid);

if Plot==1
    close all
    figure(1)
    scale=64./[max(abs(c),[],2)*ones(1,Nt)];
    temp=zeros(1,Nt);
    temp(TE)=1;
    image(flipud(abs(c)).*scale)
    colormap pink
    ylabel('Scales')
    Wt=[fliplr(W)];
    set(gca,'YTick',1:Nw,'YTickLabel',Wt,'Position',[0.1 0.2 0.8 0.6], ...
        'XTick',[])
    title(['|C| across scales: ' num2str(W)])
    ah2=axes;
    set(ah2,'Position',[0.1 0.1 0.8 0.1])
    plot(temp,'o-m','MarkerSize',4,'MarkerFaceColor','m')
    set(gca,'YTick',[],'XLim',[1 Nt])
    xlabel('Time (samples)')
    ylabel('Spikes')
    
    figure(2)
    plot(Signal,'Color',[0.7 0.7 0.7],'LineWidth',2)
    hold on
    plot(ct','-o','LineWidth',1,'MarkerFaceColor','k', ...
        'MarkerSize',4)
    xlabel('Time (samples)')
    ylabel('Coefficients')
    set(gca,'XLim',[1 Nt])
end

if Comment == 1
    disp([num2str(length(TE)) ' spikes found'])
    disp(['elapsed time: ' num2str(etime(clock,to))])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function f=parse(Index,SFr,Wid);

%This is a special function, it takes the vector Index which has 
%the structure [0 0 0 1 1 1 0 ... 0 1 0 ... 0]. This vector was obtained
%by coincidence detection of certain events (lower and upper threshold
%crossing for threshold detection, and the appearance of coefficients at
%different scales for wavelet detection). 
%The real challenge here is to merge multiple 1's that belong to the same
%spike into one event and to locate that event

Refract=1.5*Wid(2);     %[ms] the refractory period -- can't resolve spikes 
                        %that are closer than Refract;
Refract=round(Refract*SFr);

Merge=mean(Wid);        %[ms] merge spikes that are closer than Merge, since 
                        %it is likely they belong to the same spike
Merge=round(Merge*SFr);   


Index([1 end])=0;   %discard spikes that are located at first and last sample

ind_ones=find(Index==1);    %find where the ones are

if isempty(ind_ones)
    TE=[];
else
    temp=diff(Index);  %there will be 1 followed by -1 for each spike
    N_sp=sum(temp==1); %nominal number of spikes
    
    lead_t=find(temp==1);  %index of the beginning of a spike
    lag_t=find(temp==-1);  %index of the end of the spike
    
    for i=1:N_sp
        tE(i)=ceil(mean([lead_t(i) lag_t(i)]));
    end
   
    i=1;        %initialize counter
    while 0 < 1
        if i>length(tE)-1
            break;
        else
            Diff=tE(i+1)-tE(i);
            if Diff<Refract & Diff>Merge
                tE(i+1)=[];         %discard spike too close to its predecessor
            elseif Diff<=Merge
                tE(i)=ceil(mean([tE(i) tE(i+1)]));  %merge
                tE(i+1)=[];                         %discard
            else
                i=i+1;
            end
        end
    end 
    TE=tE;
end

f=TE;
