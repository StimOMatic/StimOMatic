function pluginData = pContinuousOpenGL_shutdownWorker( pluginData  )
% shutdown function.

    try
        % 'pluginData.trial_start' will only be initialized, if 'pContinuousOpenGL_processData' did run.
        t_total = toc(pluginData.trial_start);
        disp('pContinuousOpenGL stats:');
        disp(['total time: ' num2str(t_total) '; ' num2str(t_total /  pluginData.tmp1) ' seconds per iteration']);
    catch me %#ok<NASGU>

    end

end
%% EOF
