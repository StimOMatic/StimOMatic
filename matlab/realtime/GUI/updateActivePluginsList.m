%
function updateActivePluginsList(handles)

pluginStrs = [];
for k=1:length(handles.activePlugins)
    pluginStrs{k} = ['ID=' num2str(handles.activePlugins{k}.abs_ID) ' ' handles.activePlugins{k}.pluginDef.displayName];
end
set(handles.listLoadedPlugins,'String',pluginStrs);


%set(handles.listLoadedPlugins,'Value', 1);  % put marker to first automatically
set(handles.listLoadedPlugins,'Value', length(pluginStrs));  % put marker to last
