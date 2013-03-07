%init a file for shared variables between different matlab instances
%
%urut/MPI/jan12
function memFileHandle = initMemSharedVariable( filename, nrVals, createFile, writeMode )
if nargin<3
    createFile=0;
end
if nargin<2
    nrVals=1;
end
if nargin<4
    writeMode=true;
end

if createFile
    data = zeros(1,nrVals);
    
    fid = fopen(filename, 'w+');
    
    if fid==-1
        error(['could not open file: ' filename] );
    end
    
    fwrite(fid, data, 'uint8'); 
    fclose(fid);
    
end


memFileHandle = memmapfile(filename, 'Offset', 0,'Format', 'uint8', 'Writable', writeMode);
