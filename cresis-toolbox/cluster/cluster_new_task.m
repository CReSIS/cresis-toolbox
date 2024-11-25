function [ctrl,task_id] = cluster_new_task(ctrl,sparam,dparam,varargin)
% [ctrl,task_id] = cluster_new_task(ctrl,sparam,dparam,varargin)
%
% Creates a new job. Calls to this function need to be proceeded by
% a single call to cluster_new_batch.m.
%
% Inputs:
% ctrl: ctrl structure returned from cluster_new_batch
%  .sched: scheduler structure
%  .in_fn_dir: input arguments directory
%  .out_fn_dir: output arguments directory
%  .stdout_fn_dir: standard output directory
%  .error_fn_dir: error directory
% sparam: Struct containing static arguments to task
%  .task_function: function handle of job, this function handle tells
%    cluster_job.m what to run
%  .argsin: cell vector of input arguments (default is {})
%  .num_args_out: number of output arguments to expect (default is 0)
%  .notes: optional note to print after successful submission of job
%    default is '' (nothing is written out)
%  .cpu_time: maximum cpu time of this task in seconds
%  .mem: maximum memory usage of this task in bytes (default is 0)
%  .file_success: cell array of files that must exist to determine the
%    task a success. If the file is a .mat file, then it must have the
%    file_version variable and not be marked for deletion.
% dparam: Dynamic arguments to task (will be merged with sparam when the
%   task runs). This structure has all the same fields as sparam. After
%   merging, sparam and dparam must have all the required fields. It does
%   not matter where the field is set. For example, "task_function" could
%   be set from dparam and "mem" could be set from sparam. Note that if a
%   field is set in both structures, then dparam will overrule sparam.
% varargin: List of name value pairs to set additional variables in the
%   function. These include:
%   'dparam_save': Logical scalar. Default is true. If set to false, this
%     function does not save the dparam settings into the dparam input file
%     and a call to cluster_save_dparam is required. This is useful when
%     many tasks are being created because saving to the dparam file is
%     slow and it is much better to do it all at once at the end.
%
% Outputs:
% ctrl: updated ctrl structure with new job
% task_id: ID of task (integer, starts counting from one and never repeats)
%
% EXAMPLES:
%   See cluster_submit_batch.m
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


%% Input checking
cluster_new_task_sparam_check;

if ~exist('dparam','var')
  error('dparam must be specified');
end
if isfield(dparam,'task_function') && isempty(which(dparam.task_function))
  error('dparam.task_function is not in the path');
end

% Read in name-value pairs from user's varargin
dparam_save = 1; % Default is true
for param_idx = 1:2:length(varargin)
  eval(sprintf('%s = varargin{param_idx+1};', varargin{param_idx}));
end

%% Check for hold on this batch
if exist(fullfile(ctrl.batch_dir,'hold'), 'file')
  % Hold file exists
  keyboard
end

%% Get the new task id
if ~isfield(ctrl,'task_id')
  [fid,msg] = fopen(ctrl.task_id_file,'r');
  if fid < 1
    warning ('Could not open job id list file %s\n', ctrl.task_id_file);
    ctrl.job_id_list = [];
    ctrl.error_mask = [];
    ctrl.job_status = [];
    return;
  end
  ctrl.job_id_list = textscan(fid,'%f');
  fclose(fid);
  ctrl.job_id_list = ctrl.job_id_list{1};
  ctrl.task_id = length(ctrl.job_id_list);
end
ctrl.task_id = ctrl.task_id + 1;
task_id = ctrl.task_id;


%% Create task input file
if task_id == 1
  static_in_fn = fullfile(ctrl.in_fn_dir,'static.mat');
  static_param = sparam;
  robust_save(static_in_fn,ctrl.cluster.file_version,'static_param');
  if dparam_save
    dynamic_in_fn = fullfile(ctrl.in_fn_dir,'dynamic.mat');
    dynamic_param = [];
    dynamic_param.dparam{task_id} = dparam;
    robust_save(dynamic_in_fn,ctrl.cluster.file_version,'-struct','dynamic_param','dparam');
  else
    ctrl.dparam{task_id} = dparam;
  end
else
  % Add the dynamic parameters
  if dparam_save
    dynamic_in_fn = fullfile(ctrl.in_fn_dir,'dynamic.mat');
    dynamic_param = load(dynamic_in_fn);
    dynamic_param.dparam{task_id} = dparam;
    robust_save(dynamic_in_fn,ctrl.cluster.file_version,'-struct','dynamic_param','dparam');
  else
    ctrl.dparam{task_id} = dparam;
  end
end
param = merge_structs(sparam,dparam);

%% Add task to ctrl structure
ctrl.submission_queue = cat(2,ctrl.submission_queue,task_id);
new_job_status = 'T';
new_job_id = -1;
ctrl.job_id_list(end+1) = new_job_id;
ctrl.job_status(end+1) = new_job_status;
ctrl.error_mask(end+1) = 0;
ctrl.retries(end+1) = 0;
ctrl.notes{end+1} = param.notes;
ctrl.cpu_time(end+1) = param.cpu_time;
ctrl.mem(end+1) = param.mem;
ctrl.success{end+1} = param.success;
ctrl.file_success{end+1} = param.file_success;
ctrl.cpu_time_actual(end+1) = -1;

%% Write new task ID to task_id file
fid = fopen(ctrl.job_id_fn,'a');
fprintf(fid,'%-20d\n', ctrl.job_id_list(end));
fclose(fid);

%% Print out debug information to stdout
if ~isempty(param.notes)
  fprintf('  task %d:%d: %s (%s)\n', ctrl.batch_id, task_id, param.notes, datestr(now));
end

end
