


figure(80);


origVals = randn(1,10000);
h=line(1:10000, origVals );

set(h,'EraseMode','background');

set(gca,'ylim',[-10 10],'xlim',[1 10000], 'ylimmode','manual','xlimmode','manual'); %,'XTickLabel',[]);

tic
for k=1:500

    %newVals = randn(1,10000);
    newVals=origVals;newVals(1:1000)=randn(1,1000)+2;
    set(h,'ydata', newVals );
drawnow;
end

toc


X = randn(1,512*50);

Y=buffer(X,512);

Z = reshape( Y(:,11:20),1,10*512 );

n=1e6;
X = zeros(n, 10);
for j=1:10
    X(:, j) =single(randn(1,n));
end

tic
for k=1:100

    
    X = [ X(1000:n-1000); single(ones(1000, 1)) ];
end
toc





filteredData(1:bufferSize) = [ filteredData( indsReuse ) newDataFiltered ];




