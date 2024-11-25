function ctrl = cluster_save_dparam(ctrl)
% ctrl = cluster_save_dparam(ctrl)
%
% Function to save dparam all at once. Saving dparam as the tasks are being
% generated can be very slow when there are many tasks. It is better to set
% 'dparam_save' to false in cluster_new_task.m and then call
% cluster_save_dparam at the end when many tasks could be created.
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

if isfield(ctrl,'dparam')
  dynamic_in_fn = fullfile(ctrl.in_fn_dir,'dynamic.mat');
  if exist(dynamic_in_fn,'file')
    % Dynamic input arguments file already exists
    dynamic_param = load(dynamic_in_fn,'dparam');
    if ~isfield(dynamic_param,'dparam')
      dynamic_param.dparam = {};
    end
    % Merge file inputs with ctrl inputs
    for task_id = 1:length(ctrl.dparam)
      if ~isempty(ctrl.dparam{task_id})
        dynamic_param.dparam{task_id} = ctrl.dparam{task_id};
      end
    end
    save(dynamic_in_fn,ctrl.cluster.file_version,'-struct','dynamic_param','dparam');
  else
    % Dynamic input arguments file does not exist
    save(dynamic_in_fn,ctrl.cluster.file_version,'-struct','ctrl','dparam');
  end
end

