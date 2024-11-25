function cluster_job(task_in_fn_dir,task_out_fn_dir,task_ids,num_proc)
% cluster_job(task_in_fn_dir,task_out_fn_dir,task_ids,num_proc)
%
% This M-file should be compiled with cluster_compile.
%
% Then when the distributed toolbox calls the cluster_job.sh command via
% the scheduler which calls the compiled version of this function.
%
% cluster_submit_batch.m shows how to use the scheduler from Matlab
%
% Author: John Paden
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

if ~exist('task_in_fn_dir','var')
  task_in_fn_dir = getenv('INPUT_PATH');
end
if ~exist('task_out_fn_dir','var')
  task_out_fn_dir = getenv('OUTPUT_PATH');
end
if ~exist('task_ids','var')
  task_ids = getenv('TASK_LIST');
end
task_ids = regexp(task_ids, 'd', 'split');
if ~exist('num_proc','var')
  num_proc = str2num(getenv('NUM_PROC'));
end
if ~isempty(num_proc)
  fprintf('Requesting %g processors with cpu affinity\n', num_proc);
  cluster_cpu_affinity(num_proc);
else
  fprintf('Not requesting any processors with cpu affinity\n');
end

fprintf('%s: Processing tasks %s', mfilename, task_ids{1});
fprintf(', %s', task_ids{2:end});
fprintf(' (%s)\n', datestr(now));

% Create input filenames
static_in_fn = fullfile(task_in_fn_dir,'static.mat');
dynamic_in_fn = fullfile(task_in_fn_dir,'dynamic.mat');
% Load inputs
sparam = load(static_in_fn);
dparam = load(dynamic_in_fn);

for task_idx = 1:length(task_ids)
  cluster_task_start_time = tic;
  task_id = str2double(task_ids{task_idx});
  fprintf('%s: Load task %d (%d of %d) (%s)\n', mfilename, task_id, task_idx, length(task_ids), datestr(now));
  
  % Create output filename
  out_fn = fullfile(task_out_fn_dir,sprintf('out_%d.mat',task_id));
  
  % Read input param struct
  %   param fields: 'taskfunction','argsin','num_args_out'
  param = merge_structs(sparam.static_param,dparam.dparam{task_id});
  % Special merge of argsin cell array
  if isfield(sparam.static_param,'argsin')
    sparam_argsin_numel = numel(sparam.static_param.argsin);
  else
    sparam.static_param.argsin = {};
    sparam_argsin_numel = 0;
  end
  if isfield(dparam.dparam{task_id},'argsin')
    dparam_argsin_numel = numel(dparam.dparam{task_id}.argsin);
  else
    dparam.dparam{task_id}.argsin = {};
    dparam_argsin_numel = 0;
  end
  for idx = 1:max(sparam_argsin_numel,dparam_argsin_numel)
    if idx <= sparam_argsin_numel
      if idx <= dparam_argsin_numel
        param.argsin{idx} = merge_structs(sparam.static_param.argsin{idx},dparam.dparam{task_id}.argsin{idx});
      else
        param.argsin{idx} = sparam.static_param.argsin{idx};
      end
    else
      param.argsin{idx} = dparam.dparam{task_id}.argsin{idx};
    end
  end
  
  % Creating command to evaluate
  if param.num_args_out == 0
    eval_cmd = sprintf('%s(',param.task_function);
  else
    eval_cmd = sprintf('[argsout{1:%i}] = %s(',param.num_args_out,param.task_function);
  end
  for argsin_idx = 1:length(param.argsin)
    if argsin_idx < length(param.argsin)
      eval_cmd = sprintf('%sparam.argsin{%i},', eval_cmd, argsin_idx);
    else
      eval_cmd = sprintf('%sparam.argsin{%i}', eval_cmd, argsin_idx);
    end
  end
  eval_cmd = sprintf('%s);', eval_cmd);
  
  % Evaluate command
  global gRadar;
  try
    argsout = {};
    fprintf('%s: %s\n', mfilename, param.notes);
    fprintf('%s: Eval %s\n', mfilename, eval_cmd);
    gRadar.cluster.is_cluster_job = true;
    eval(eval_cmd);
    gRadar.cluster.is_cluster_job = false;
    fprintf('%s: Done Eval (%s)\n', mfilename, datestr(now));
    errorstruct = [];
    cpu_time_actual = toc(cluster_task_start_time);
    save(out_fn,param.file_version,'argsout','errorstruct','cpu_time_actual');
  catch errorstruct
    gRadar.cluster.is_cluster_job = false;
    fprintf('%s: Error\n  %s: %s (%s)\n', mfilename, errorstruct.identifier, errorstruct.message, datestr(now));
    for stack_idx = 1:length(errorstruct.stack)
      fprintf('  %s: %d\n', errorstruct.stack(stack_idx).name, errorstruct.stack(stack_idx).line);
    end
    cpu_time_actual = toc(cluster_task_start_time);
    save(out_fn,param.file_version,'argsout','errorstruct','cpu_time_actual');
  end
end

if isdeployed
  quit
end
