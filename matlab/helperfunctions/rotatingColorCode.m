%
%return a color identifier, rotating starting at 1
%uses the default colors or the one specified (param2)
%
%urut/march12
function col = rotatingColorCode( ind, colors )
if nargin<2
    colors={'r','g','b','m','k','c','y'};
end
col= colors{mod( ind,length(colors))+1};
