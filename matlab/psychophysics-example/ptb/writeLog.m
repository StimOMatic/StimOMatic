function writeLog(fid, TTLvalue, text)

fprintf(fid,'%s\n', [num2str(round(now*1000000000),15) ';' num2str(TTLvalue) ';' text ';' ]);