% cluster_new_task_sparam_check.m
%
% Support script for cluster_new_task.m and cluster_save_sparam.m

%% Input checking
if ~exist('sparam','var')
  error('sparam must be specified');
end
if ~isfield(sparam,'task_function') || isempty(sparam.task_function)
  error('sparam.task_function must be specified');
end
if isempty(which(sparam.task_function))
  error('sparam.task_function (%s) is not in the path', sparam.task_function);
end
if ~isfield(sparam,'argsin') || isempty(sparam.argsin)
  sparam.argsin = {};
end
if ~isfield(sparam,'num_args_out')
  sparam.num_args_out = 0;
end
if ~isfield(sparam,'notes')
  sparam.notes = '';
end
if ~isfield(sparam,'cpu_time') || isempty(sparam.cpu_time)
  sparam.cpu_time = 0;
end
if ~isfield(sparam,'mem') || isempty(sparam.mem)
  sparam.mem = 0;
end
if ~isfield(sparam,'success') || isempty(sparam.success)
  sparam.success = '';
end
if ~isfield(sparam,'file_success') || isempty(sparam.file_success)
  sparam.file_success = {};
end
sparam.file_version = ctrl.cluster.file_version;
