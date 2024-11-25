function rmpath_strs = ct_remove_toolboxes(toolbox_strs)
% rmpath_strs = ct_remove_toolboxes(toolbox_strs)
%
% Function for removing toolboxes from the path in order to test functions
% to verify that they use or do not use a toolbox.
%
% Run startup again to recover toolbox path or path(pathdef) to recover
% default matlab path.
%
% Inputs:
%
% toolbox_strs: cell array of strings containing the directory name for the toolboxes
% that are to be removed
%
% Outputs:
%
% rmpath_strs: colon delimited/separated paths that are removed
%
% Examples:
%
% rmpath_strs = ct_remove_toolboxes({'compiler','globaloptim','images','map','optim','signal'})
%
% path([path ':' rmpath_strs]);
%
% Author: John Paden
%
% See also: pathdef

% Return the Matlab root installation directory.
% e.g. /cresis/snfs1/sw/matlab/2020a/
path_root = matlabroot;

% Parses path into cell array
path_list = strsplit(path,':');

rmpath_strs = '';

if any(strcmpi(toolbox_strs,'images'))
  for idx_path = 1:length(path_list)
    if ~isempty(regexp(path_list{idx_path},fullfile(path_root,'toolbox','images')))
      fprintf('Removing:\t%s\n', path_list{idx_path});
      rmpath(path_list{idx_path});
      if isempty(rmpath_strs)
        rmpath_strs = path_list{idx_path};
      else
        rmpath_strs = [rmpath_strs, ':', path_list{idx_path}];
      end
    end
  end
end

if any(strcmpi(toolbox_strs,'map'))
  for idx_path = 1:length(path_list)
    if ~isempty(regexp(path_list{idx_path},fullfile(path_root,'toolbox','map')))
      fprintf('Removing:\t%s\n', path_list{idx_path});
      rmpath(path_list{idx_path});
      if isempty(rmpath_strs)
        rmpath_strs = path_list{idx_path};
      else
        rmpath_strs = [rmpath_strs, ':', path_list{idx_path}];
      end
    end
  end
end

if any(strcmpi(toolbox_strs,'signal'))
  for idx_path = 1:length(path_list)
    if ~isempty(regexp(path_list{idx_path},fullfile(path_root,'toolbox','signal')))
      fprintf('Removing:\t%s\n', path_list{idx_path});
      rmpath(path_list{idx_path});
      if isempty(rmpath_strs)
        rmpath_strs = path_list{idx_path};
      else
        rmpath_strs = [rmpath_strs, ':', path_list{idx_path}];
      end
    end
  end
end
