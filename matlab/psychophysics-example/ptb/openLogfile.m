%
%prepare logfile
%urut/july04
function [fid,fname] = openLogfile(basepath, expLabel)

C=clock;
year=C(1);
month=C(2);
day=C(3);
hour=C(4);
min=C(5);
ss=C(6);

fname=[basepath expLabel '_' num2str(year) num2str(month,'%.2d') num2str(day,'%.2d') '_' num2str(hour,'%.2d') num2str(min,'%.2d') num2str(fix(ss),'%.2d')];
fid= fopen([fname '.txt'],'w+');