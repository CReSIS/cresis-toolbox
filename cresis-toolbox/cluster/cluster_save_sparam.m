function ctrl = cluster_save_sparam(ctrl,sparam)
% ctrl = cluster_save_sparam(ctrl,sparam)
%
% Function to save sparam separately from creating new tasks. Sometimes
% useful when the full sparam structure is not known until all the tasks
% have already been created.
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

static_in_fn = fullfile(ctrl.in_fn_dir,'static.mat');
cluster_new_task_sparam_check;
static_param = sparam;
robust_save(static_in_fn,ctrl.cluster.file_version,'static_param');
