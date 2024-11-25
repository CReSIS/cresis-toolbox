function ctrl_chain = cluster_reset(ctrl_chain)
% ctrl_chain = cluster_reset(ctrl_chain)
%
% Resets tasks in a control chain that failed due to errors and prepares
% the control chain to be submitted to cluster_run again.
%  1. Resets the error mask to zero for tasks with nonzero errors.
%  2. The retries are reset to zero for these tasks.
%  3. The status is set to 'T'
%  4. The tasks are added to the submission queue
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

if iscell(ctrl_chain)
  %% Traverse chain list
  for chain = 1:numel(ctrl_chain)
    fprintf('Chain %d\n', chain);
    for stage=1:numel(ctrl_chain{chain})
      fprintf('  Stage %d\n', stage);
      [ctrl_chain{chain}{stage}] = cluster_reset(ctrl_chain{chain}{stage});
    end
  end
  
elseif isstruct(ctrl_chain)
  ctrl = ctrl_chain;
  
  error_task_ids = find(ctrl.error_mask);
  ctrl.error_mask(error_task_ids) = 0;
  ctrl.retries(error_task_ids) = 0;
  ctrl.job_status(error_task_ids) = 'T';
  ctrl.submission_queue(end+(1:length(error_task_ids))) = error_task_ids;
  
  % Update output
  ctrl_chain = ctrl;
end
