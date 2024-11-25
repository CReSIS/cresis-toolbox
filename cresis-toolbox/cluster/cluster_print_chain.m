function [ctrl_chain,stats] = cluster_print_chain(ctrl_chain, force_check, mode)
% [ctrl_chain,stats] = cluster_print_chain(ctrl_chain, force_check, mode)
%
% Prints information about a list of batch chains, a chain, or a batch.
% Also returns the % information.
%
% Inputs:
% ctrl_chain: This input can be any of the following:
%   1. A cell array of chains that can be run in parallel (e.g. ctrl_chain)
%   2. A cell array of batches (aka chain) (e.g. ctrl_chain{chain})
%   3. A batch (e.g. ctrl_chain{chain}{stage}
% force_check: default to false, forces cluster_update_task to be run on all
%   tasks (very slow)
% mode: Only used if ctrl_chain is an integer, default is 'chain'.
%   Integer will be treated as chain if mode is 'chain' and batch
%   if mode is 'batch'.
%
% Outputs:
% ctrl_chain: updated list of batch chains that was passed in
% stats: statistics about all the batch chains
%
% Example:
%   [ctrl_chain,stats] = cluster_print_chain(ctrl_chain);
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

if ~exist('force_check','var') || isempty(force_check)
  force_check = false;
end

if ~exist('mode','var') || isempty(mode)
  mode = 'chain';
end

if iscell(ctrl_chain)
  %% Traverse chain list
  stats.cpu_time = [];
  stats.mem = [];
  stats.error_mask = [];
  stats.retries = [];
  stats.job_status = [];
  stats.str = '';
  for chain = 1:numel(ctrl_chain)
    stats.str = [stats.str sprintf('Chain %d\n', chain)];
    for stage=1:numel(ctrl_chain{chain})
      if isnumeric(ctrl_chain{chain}{stage})
        % If numeric and not a batch struct, then get the batch struct
        ctrl_chain{chain}{stage} = cluster_get_batch(ctrl_chain{chain}{stage},force_check,0);
      end
      stats.str = [stats.str sprintf('  Stage %d (Batch %d)\n', stage, ctrl_chain{chain}{stage}.batch_id)];
      [ctrl_chain{chain}{stage},ctrl_stats] = cluster_print_chain(ctrl_chain{chain}{stage},force_check);
      stats.cpu_time = cat(2,stats.cpu_time,ctrl_stats.cpu_time);
      stats.mem = cat(2,stats.mem,ctrl_stats.mem);
      stats.error_mask = cat(2,stats.error_mask,ctrl_stats.error_mask);
      stats.retries = cat(2,stats.retries,ctrl_stats.retries);
      stats.job_status = cat(2,stats.job_status,ctrl_stats.job_status);
      stats.str = cat(2,stats.str,ctrl_stats.str);
    end
  end
  fprintf('%s', stats.str);
  fprintf('====================================================\n');
  fprintf('Number of tasks: %.0f, %.0f/%.0f/%.0f/%.0f C/R/Q/T, %.0f error, %.0f retries\n', ...
    numel(stats.cpu_time), sum(stats.job_status=='C'), sum(stats.job_status=='R'), sum(stats.job_status=='Q'), sum(stats.job_status=='T'), sum(stats.error_mask~=0), sum(stats.retries));
  fprintf('Max CPU time: %.0f min\n', max(stats.cpu_time)/60);
  fprintf('Max mem: %.0f MB\n', max(stats.mem)/1e6);
  fprintf('Mean CPU time: %.0f min\n', mean(stats.cpu_time)/60);
  fprintf('Mean mem: %.0f MB\n', mean(stats.mem)/1e6);  
  
elseif isstruct(ctrl_chain)
  ctrl = ctrl_chain;
  
  ctrl = cluster_get_batch(ctrl,force_check,0);
  
  stats.cpu_time = ctrl.cpu_time;
  stats.mem = ctrl.mem;
  stats.error_mask = ctrl.error_mask;
  stats.retries = ctrl.retries;
  stats.job_status = ctrl.job_status;
  stats.str = '';
  
  if isempty(ctrl.job_status)
    stats.str = [stats.str sprintf('    No tasks\n')];
    
  else
    % Create in/out filenames
    static_in_fn = fullfile(ctrl.in_fn_dir,'static.mat');
    dynamic_in_fn = fullfile(ctrl.in_fn_dir,'dynamic.mat');
    
    % Read input
    sparam = load(static_in_fn);
    tmp = load(dynamic_in_fn);
    ctrl.dparam = tmp.dparam;
    if ~isempty(ctrl.dparam)
      param = merge_structs(sparam.static_param,ctrl.dparam{1});
      stats.str = [stats.str sprintf('    task_function: %s\n', param.task_function)];
      stats.str = [stats.str sprintf('    notes: %s\n', param.notes)];
    end
    
    stats.str = [stats.str sprintf('    Number of tasks: %.0f, %.0f/%.0f/%.0f/%.0f C/R/Q/T, %.0f error, %.0f retries\n', ...
      numel(stats.cpu_time), sum(stats.job_status=='C'), sum(stats.job_status=='R'), sum(stats.job_status=='Q'), sum(stats.job_status=='T'), sum(stats.error_mask~=0), sum(stats.retries))];
    stats.str = [stats.str sprintf('    Error tasks:'), sprintf(' %d', find(stats.error_mask~=0)), sprintf('\n')];
    stats.str = [stats.str sprintf('    Max CPU time: %.0f min\n', max(stats.cpu_time)/60)];
    stats.str = [stats.str sprintf('    Max mem: %.0f MB\n', max(stats.mem)/1e6)];
    stats.str = [stats.str sprintf('    Mean CPU time: %.0f min\n', mean(stats.cpu_time)/60)];
    stats.str = [stats.str sprintf('    Mean mem: %.0f MB\n', mean(stats.mem)/1e6)];
    
    [max_cpu_time,max_task_id] = max(stats.cpu_time);
    if max_cpu_time > ctrl.cluster.max_time_per_job
      warning(' %d:%d: Max task cpu time exceeds ctrl.cluster.max_time_per_job setting.', ctrl.batch_id, max_task_id);
    end
  end

  % Update output
  ctrl_chain = ctrl;
  
elseif isnumeric(ctrl_chain)
  if strcmpi(mode,'batch')
    ctrl = cluster_get_batch(ctrl_chain,false,0);
    [ctrl_chain,stats] = cluster_print_chain({{ctrl}},force_check);
  else
    ctrl_chain = cluster_load_chain(ctrl_chain);
    [ctrl_chain,stats] = cluster_print_chain(ctrl_chain,force_check);
  end
  
end
