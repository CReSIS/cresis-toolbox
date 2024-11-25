function active_stage = cluster_chain_stage(ctrl_chain)
% active_stage = cluster_chain_stage(ctrl_chain)
%
% Checks to see if a cluster chain is done running.
%
% INPUTS:
% ctrl_chain: cluster chain of control/batch structures
%
% OUTPUTS:
% active_stage: vector the same size as ctrl_chain representing the stage of
%   each chain.
%   Values from 1 to numel(chain) represent the active stage.
%   Value of inf means the chain is complete.
%   Value of -inf means chain stopped (usually because the chain is
%   out of retries due to errors).
%
% EXAMPLES:
% active_stage = cluster_chain_stage(ctrl_chain)
%
% Authors: John Paden
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


%% Traverse chain list
active_stage = ones(size(ctrl_chain));
for chain = 1:numel(ctrl_chain)
  for stage = 1:numel(ctrl_chain{chain})
    % 1. There is at least one batch left to run in this chain
    ctrl = ctrl_chain{chain}{stage};
    
    if all(ctrl.job_status=='C')
      if ~any(ctrl.error_mask)
        active_stage(chain) = active_stage(chain) + 1;
        if active_stage(chain) > numel(ctrl_chain{chain})
          % Chain is complete
          active_stage(chain) = inf;
        end
      elseif all(ctrl.retries >= ctrl.cluster.max_retries)
        % Chain is stopped
        active_stage(chain) = -inf;
        break;
      end
    else
      % Chain is working on this stage
      break;
    end
    
  end
end
