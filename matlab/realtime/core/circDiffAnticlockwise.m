%
%
% circular difference between two phases, in rad
% all inputs/outputs are in the counterclockwise notation of 0...pi/2...pi/-pi...-pi/2...0
%
% differences can only be positive, meaning starting at x, it takes d phase time to reach y
% 
% the aim is to find how long one needs to wait into the future, starting at x, to reach y
%
%urut/april12
function d = circDiffAnticlockwise(x,y)
d=0;
%range is now 0...2pi
x=x+pi;
y=y+pi;

if x<y
    d=y-x;
end
if x>y    
    d = y - (x-2*pi);
end


    
