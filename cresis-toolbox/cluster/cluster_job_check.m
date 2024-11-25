function is_cluster_job = cluster_job_check()
% is_cluster_job = cluster_job_check()
%
% Call to determine if the current process is running on the cluster. Uses
% the param.cluster.is_cluster_job field.
%
% Inputs:
% global variable gRadar (uses gRadar.cluster.is_cluster_job)
%
% Outputs:
% is_cluster_job: logical scalar. True if this current process is a cluster
% job called from cluster_job.m (param.cluster.is_cluster_job is true).
% Returns false otherwise.
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

global gRadar;
if isfield(gRadar,'cluster') && isfield(gRadar.cluster,'is_cluster_job') && gRadar.cluster.is_cluster_job
  is_cluster_job = true;
else
  is_cluster_job = false;
end
