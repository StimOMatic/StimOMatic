function handlesGUI = pContinuousOpenGL_initGUI( handlesGUI, handlesParent )
% basic 'initGUI' function for 'non-matlab' plotting.
% This function is only called once on the master.

    % Return empty 'handlesGUI', which is needed by
    % 'pContinuousOpenGL_initPlugin'.
    handlesGUI = [];

    % TODO: add automatic creation of mmap files based on
    % 'nrActiveChannels'
    nrActiveChannels = handlesParent.StimOMaticData.nrActiveChannels;

end
%% EOF
