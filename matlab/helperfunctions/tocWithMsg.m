%
%helper function for using tic/toc
%display elapsed time with a message, use instead of toc
%
%urut/aug11
function t = tocWithMsg( msg, tstart, dispMessage )
if nargin<3
    dispMessage=1;
end

if nargin==1
    t=toc;
else
    t=toc(tstart);
end

if dispMessage
    disp([msg ' ' num2str(t)]);
end