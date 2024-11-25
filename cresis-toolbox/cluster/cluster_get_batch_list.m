function ctrls = cluster_get_batch_list(param,get_mode)
% ctrls = cluster_get_batch_list(param,get_mode)
%
% Gets a list of batches using the specified data location.
%
% Inputs:
% param: optional input (just needs to contain param.cluster.data_location)
%   default value is to use global gRadar
%  .batch_id: If it contains param.batch_id, then only return batches which
%    match this ID
% get_mode: mode 0 returns complete ctrl structure, mode 1 returns just the
%   batch ids
%
% Outputs:
% ctrls = cell vector of batch jobs (can be used with the other cluster_*
%   functions). Job information is not retrieved, just the basics.
%   Use cluster_job_list to get job information.
%  .cluster = cluster parameter structure
%   .data_location
%  .batch_dir = path to directory containing batch information
%  .job_id_fn = path to file containing torque job ids
%  .in_fn_dir = input arguments directory
%  .out_fn_dir = output arguments directory
%  .stdout_fn_dir = stdout directory
%  .error_fn_dir = error directory
%  .user_file = path of file containing the username who owns batch
%  .user = string containing username who owns batch
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

if ~exist('get_mode','var') || isempty(get_mode)
  get_mode = 0;
end

if ~exist('param','var') || isempty(param)
  global gRadar;
  param = gRadar;
end

if ~isfield(param,'batch_id') || isempty(param.batch_id)
  batch_id_match = [];
else
  batch_id_match = param.batch_id;
end

batch_dirs = get_filenames(param.cluster.data_location,'batch_','','',struct('type','d'));

%% Collect directories into a batch list and sort
ctrls = [];
batch_ids = [];
for dir_idx = 1:length(batch_dirs)
  
  [tmp batch_dir_name] = fileparts(batch_dirs{dir_idx});
  batch_id = strtok(batch_dir_name(7:end),'_');
  batch_id = str2double(batch_id);
  
  if isempty(batch_id_match) || batch_id_match == batch_id
    ctrls{end+1}.batch_dir = batch_dirs{dir_idx};
    ctrls{end}.batch_id = batch_id;
    batch_ids(end+1) = ctrls{end}.batch_id;
  end
end
[~,sort_idxs] = sort(batch_ids);
ctrls = ctrls(sort_idxs);
if get_mode == 1
  return
end

%% Print results or populate remaining fields for each batch
for batch_idx = 1:length(ctrls)  
  ctrls{batch_idx}.in_fn_dir = fullfile(ctrls{batch_idx}.batch_dir,'in');
  if nargout == 0
    % Create input filenames
    static_in_fn = fullfile(ctrls{batch_idx}.in_fn_dir,'static.mat');
    dynamic_in_fn = fullfile(ctrls{batch_idx}.in_fn_dir,'dynamic.mat');
    % Load input filenames
    if exist(static_in_fn,'file')
      sparam = load(static_in_fn);
    else
      warning('Missing %s', static_in_fn);
      sparam = [];
      sparam.static_param = [];
    end
    if exist(dynamic_in_fn,'file')
      tmp = load(dynamic_in_fn);
      ctrls{batch_idx}.dparam = tmp.dparam;
      if isempty(ctrls{batch_idx}.dparam)
        ctrls{batch_idx}.dparam = {[]};
      end
    else
      ctrls{batch_idx}.dparam = {[]};
    end
    
    fprintf('Batch %d %s\n', ctrls{batch_idx}.batch_id, ctrls{batch_idx}.batch_dir);
    
    param = merge_structs(sparam.static_param,ctrls{batch_idx}.dparam{1});
    if ~isfield(param,'task_function')
      param.task_function = '';
    end
    if ~isfield(param,'notes')
      param.notes = '';
    end
    fprintf('    task_function: %s\n', param.task_function);
    fprintf('    notes: %s\n', param.notes);
      
  else
    ctrls{batch_idx}.job_id_fn = fullfile(ctrls{batch_idx}.batch_dir,'job_id_file');
    ctrls{batch_idx}.out_fn_dir = fullfile(ctrls{batch_idx}.batch_dir,'out');
    ctrls{batch_idx}.stdout_fn_dir = fullfile(ctrls{batch_idx}.batch_dir,'stdout');
    ctrls{batch_idx}.error_fn_dir = fullfile(ctrls{batch_idx}.batch_dir,'error');
    ctrls{batch_idx}.hold_fn = fullfile(ctrls{batch_idx}.batch_dir,'hold');
    
    ctrls{batch_idx} = cluster_new_batch(param,ctrls{batch_idx});
  end
  
end
