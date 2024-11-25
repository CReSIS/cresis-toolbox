function [chain_fn,chain_id] = cluster_save_chain(ctrl_chain,chain_id,print_mode)
% [chain_fn,chain_id] = cluster_save_chain(ctrl_chain,chain_id,print_mode)
%
% Saves a cluster chain to a file. Usually loaded by cluster_load_chain.m.
%
% INPUTS
% ctrl_chain: A cluster chain. This is a cell array containing a list of
%   sub-cell arrays. Each of these sub-cell arrays is a chain of control
%   parameters for cluster batches (cluster_new_batch.m).
% chain_id: Optional. If specified, the specific chain ID will be used. If
%   a chain exists with the same chain ID, it will be overwritten.
% print_mode: defaults to true, set to false to not print to stdout
%
% OUTPUTS
% chain_fn: The unique filename that was used to save this cluster chain
% chain_id: The unique chain ID
%
% EXAMPLES
% [chain_fn,chain_id] = cluster_save_chain(ctrl_chain);
%
% Author: John Paden
%
% See also: cluster_chain_stage.m, cluster_cleanup.m, cluster_compile.m,
% cluster_cpu_affinity.m, cluster_error_mask.m, cluster_exec_task.m,
% cluster_file_success.m, cluster_get_batch_list.m, cluster_get_batch.m,
% cluster_get_chain_list.m, cluster_hold.m, cluster_job_check.m,
% cluster_job.m, cluster_job.sh, cluster_load_chain.m, cluster_new_batch.m,
% cluster_new_task.m, cluster_print_chain.m, cluster_print.m,
% cluster_reset.m, cluster_run.m, cluster_save_chain.m,
% cluster_save_dparam.m, cluster_save_sparam.m, cluster_set_chain.m,
% cluster_set_dparam.m, cluster_set_sparam.m, cluster_stop.m,
% cluster_submit_batch.m, cluster_submit_job.m, cluster_update_batch.m,
% cluster_update_task.m

%% Input Checks
good_chain_idx = [];
for chain_idx = 1:length(ctrl_chain)
  if ~isempty(ctrl_chain{chain_idx})
    good_chain_idx = chain_idx;
    break;
  end
end
if isempty(ctrl_chain) || isempty(good_chain_idx)
  fprintf('ctrl_chain is empty. Nothing to save.\n');
  chain_fn = '';
  chain_id = [];
  return
end

if nargin < 3 || isempty(print_mode)
  print_mode = true;
end

%% Determine the new chain ID and chain filename
data_location = ctrl_chain{good_chain_idx}{1}.cluster.data_location;

chain_fns = get_filenames(data_location,'chain_','','',struct('type','f'));

if nargin >= 2 && ~isempty(chain_id)
  % chain_id was specified by the user
  new_chain_id = chain_id;
  chain_fn = [];
  for chain_idx = 1:length(chain_fns)
    [tmp chain_fn_name] = fileparts(chain_fns{chain_idx});
    chain_id = strtok(chain_fn_name(7:end),'_');
    chain_id = str2double(chain_id);
    if chain_id == new_chain_id
      % Use this filename
      chain_fn = chain_fns{chain_idx};
      break;
    end
  end
  
  if isempty(chain_fn)
    [tmp tmp_name] = fileparts(tempname);
    chain_fn = fullfile(data_location,sprintf('chain_%i_%s', new_chain_id, tmp_name));
  end
  
else
  % chain_id was NOT specified by the user, find the first available ID
  new_chain_id = 1;
  done = 0;
  while ~done
    done = 1;
    for chain_idx = 1:length(chain_fns)
      [tmp chain_fn_name] = fileparts(chain_fns{chain_idx});
      chain_id = strtok(chain_fn_name(7:end),'_');
      chain_id = str2double(chain_id);
      if chain_id == new_chain_id
        done = 0;
        new_chain_id = new_chain_id + 1;
        break;
      end
    end
  end
  
  [tmp tmp_name] = fileparts(tempname);
  chain_fn = fullfile(data_location,sprintf('chain_%i_%s', new_chain_id, tmp_name));
end

%% Save/print outputs

% Create the chain file directory
chain_fn_dir = fileparts(chain_fn);
if ~exist(chain_fn_dir,'dir')
  mkdir(chain_fn_dir)
end

% Build directory dependency list
file_deps = {chain_fn};
for chain=1:numel(ctrl_chain)
  for stage=1:numel(ctrl_chain{chain})
    file_deps{end+1} = ctrl_chain{chain}{stage}.batch_dir;
  end
end

% Save the chain
save(chain_fn,'ctrl_chain','file_deps');

% Return the new chain ID
chain_id = new_chain_id;

% Print information to load and run
if print_mode
  fprintf('Saving chain %d to %s\n\n\n', chain_id, chain_fn);
  fprintf('%% Commands to load and run from any computer (chain file contains list of file dependencies):\n');
  fprintf('[ctrl_chain,chain_fn] = cluster_load_chain(%d);\n', chain_id);
  fprintf('ctrl_chain = cluster_run(ctrl_chain);\n\n');
end
