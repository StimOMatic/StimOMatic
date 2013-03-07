function dependencies = find_obsolete_files(dependencies)

    if nargin < 1
        % provide function name:
        disp('Looking for dependencies of "OSortViewer" & "experimentScenes1_testConditional" - please wait ...');
        dependencies = depfun('OSortViewer', 'experimentScenes1_testConditional', 'definePluginList');
    end

    %% remove matlab directories.
    matlab_files = check_if_dir_is_matlab_path(dependencies);

    % disp('Potential MATLAB files: ');
    % disp(dependencies(matlab_files == 1, 1));

    %%
    % list of files used by current program:
    program_files = dependencies(matlab_files ~= 1, 1);

    %%  list of directories
    paths = build_list_of_dirs_from_matlab_path();
    matlab_dirs = check_if_dir_is_matlab_path(paths);
    code_dirs = paths(matlab_dirs ~= 1, 1);
    nbr_dirs = numel(code_dirs);
    
    %% list of files in path
    list_of_all_files = build_list_of_all_files_in_dir(code_dirs, nbr_dirs);
    
    %%
    unused_files = setdiff(list_of_all_files, program_files);
    
    % this doesn't work, because depfun() only sees files that are in the
    % path.    
    % missing_files = setdiff(program_files, list_of_all_files);
    
    %%
    if ~isempty(unused_files)
        disp('The following files are potentially not used and can be (re)moved:');
        disp(unused_files);
    end

    % this doesn't work, because depfun() only sees files that are in the
    % path.
    %     if ~isempty(missing_files)
    %         disp('You are most probably missing the following files:');
    %         disp(missing_files);
    %     end


end

function list_of_all_files = build_list_of_all_files_in_dir(code_dirs, nbr_dirs)

    list_of_all_files = cell(1, 1);
    c = 0;
    dd = filesep();
    
    for j = 1 : nbr_dirs

        curr_dir = [code_dirs{j} dd];
        potential_files_in_dir = dir([curr_dir '*']);
        files_in_dir = potential_files_in_dir([potential_files_in_dir.isdir] ~= 1);
        for k = 1 : numel(files_in_dir)
            c = c + 1;
            list_of_all_files{c, 1} = [curr_dir files_in_dir(k).name];
        end

    end
    
end

function paths = build_list_of_dirs_from_matlab_path()

    dirs_in_path = path();
    % add '0' to the beginning, so that we include the first directory.
    new_path_starts = [0 strfind(dirs_in_path, ';') size(dirs_in_path, 2) + 1];
    nbr_dirs = numel(new_path_starts) - 1;
    paths = cell(nbr_dirs, 1);
    for j = 1 : nbr_dirs
        paths{j, 1} = dirs_in_path(new_path_starts(j) + 1 : new_path_starts(j+1) - 1);
    end
    
end


function matlab_dirs_or_files = check_if_dir_is_matlab_path(list_of_dirs)
    
    nbr_files = size(list_of_dirs, 1);
    matlab_dirs_or_files = nan(1, nbr_files);

    for j = 1 : nbr_files
       if isempty(strfind(list_of_dirs{j, 1}, 'MATLAB'))
           continue;
       end
       matlab_dirs_or_files(j) = 1;
    end

end

%% EOF