
fVarStore ='c:\temp\varstorePython.dat';
nrVals=100;

%% Instance 1 (writes)

memFileHandle1 = initMemSharedVariable( fVarStore, nrVals, 1 )

memFileHandle1.Data(2)=100;

memFileHandle1.Data(1)=100;

%% Instance 2 (reads)

memFileHandle2 = initMemSharedVariable( fVarStore )

running=1
while running

    if memFileHandle2.Data(1)==100
        disp('received 100');
        memFileHandle2.Data(1)=0;
    end
end


%% to add to psychophysics code
defineSharedVarName;

memFileHandle = initMemSharedVariable( fVarStore );

data = readSharedVarValue;




%%
fVarStore ='c:\temp\varstorePython4.dat';
nrVals=100;

memFileHandle2 = initMemSharedVariable( fVarStore, nrVals, 0, false );


memFileHandle2.Data(100)



clear memFileHandle2