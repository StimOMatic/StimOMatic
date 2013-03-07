%
% loop over a list of all active plugins and call their initGUI function
% pre-compute data-dependency relationships between the different plugins
%
%
function handles = plugins_allActive_initGUI( handles )

%== loop over all plugin GUI inits
for k=1:length( handles.activePlugins )
    handles.activePlugins{k}.handlesGUI = handles.activePlugins{k}.pluginDef.initGUIFunc( handles.activePlugins{k}.handlesGUI, handles );
end

%pre-compute dependencies
for pluginNr=1:length( handles.activePlugins )
    dependenceInds=[];
    if isfield( handles.activePlugins{pluginNr}.pluginDef, 'dependsOn')
        dependsOn = handles.activePlugins{pluginNr}.pluginDef.dependsOn;
        
        %copy data it depends on
        for depNr=1:length(dependsOn)
            %search for this dependency in all active plugins
            for sInd=1:length( handles.activePlugins )
                if handles.activePlugins{sInd}.pluginDef.ID == dependsOn(depNr)
                    dependenceInds = [ dependenceInds sInd];
                end
            end
        end
    end
    
    handles.activePlugins{pluginNr}.dependenceInds = dependenceInds;
end