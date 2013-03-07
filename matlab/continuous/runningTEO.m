%
% calcs the function x(n)^2 - x(n-1)*x(n+1)
%
% this is the standard energy operator (TEO)
% some people like to invent new names for old concepts and call this "NEO -> nonlinear energy operator"
%
% urut/aprl07
function out = runningTEO(rawSignal,k)
if nargin==1
    k=1;
end

out = rawSignal.^2 - [rawSignal(1+k:end) repmat(0,1,k)].*[repmat(0,1,k) rawSignal(1:end-k)];

