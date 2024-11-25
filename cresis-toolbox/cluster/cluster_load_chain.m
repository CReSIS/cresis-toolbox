function [ctrl_chain,chain_fn] = cluster_load_chain(chain_fn)
% [ctrl_chain,chain_fn] = cluster_load_chain(chain_fn)
%
% Load a control chain from a file. Usually saved by cluster_save_chain.m.
%
% INPUTS
% chain_fn: A control chain ID (positive integer) or filename string. If a number,
%   gRadar.cluster.data_location determines the directory to load cluster chains and batches
%
% OUTPUTS
% ctrl_chain: control chain loaded from the control chain file specified by
%   the input
%
% EXAMPLES
% [ctrl_chain,chain_fn] = cluster_load_chain(1);
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

if ischar(chain_fn)
  load(chain_fn);
  return;
  
elseif isnumeric(chain_fn)
  load_chain_id = chain_fn(1);
  
  global gRadar;
  
  chain_fns = get_filenames(gRadar.cluster.data_location,'chain_','','',struct('type','f'));
  
  for chain_idx = 1:length(chain_fns)
    chain_fn = chain_fns{chain_idx};
    [~,chain_fn_name] = fileparts(chain_fn);
    chain_id = strtok(chain_fn_name(7:end),'_');
    chain_id = str2double(chain_id);
    if chain_id == load_chain_id
      load(chain_fn);
      return;
    end
  end
  
  error('Chain ID %d not found.', load_chain_id);
end
