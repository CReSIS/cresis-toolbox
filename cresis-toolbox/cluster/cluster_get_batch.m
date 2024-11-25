function ctrl = cluster_get_batch(ctrl,force_check,update_mode)
% ctrl = cluster_get_batch(ctrl,force_check,update_mode)
%
% Updates task status information from the cluster. May be called from any
% matlab process since it rebuilds the ctrl structure.
%
% Inputs:
% ctrl = Must be specified. Identifies the batch.
% force_check: default to true, forces cluster_update_task to be run on all
%   tasks
% update_mode: Scalar integer indicating mode of operation:
%   -1: Only getting task information, but do not update tasks.
%   0: Only getting task information and do minimal updates to tasks.
%   1: Get task information AND update/print tasks as required (default)
%   2: Same as 1 except also assumes that "ctrl" is already fully populated
%
% Outputs:
% ctrl = ctrl structure for the specified batch_id
%
% C -  Job is completed after having run/
% E -  Job is exiting after having run.
% H -  Job is held.
% Q -  job is queued, eligible to run or routed.
% R -  job is running.
% T -  job is being moved to new location.
% W -  job is waiting for its execution time
%      (-a option) to be reached.
% S -  (Unicos only) job is suspend.
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
  force_check = true;
end
if ~exist('update_mode','var') || isempty(update_mode)
  update_mode = 1;
end

if isnumeric(ctrl)
  ctrl_is_struct = false;
  batch_id = ctrl;
  global gRadar;
  ctrl = [];
  ctrl.cluster = gRadar.cluster;
  ctrl.batch_id = batch_id;
else
  ctrl_is_struct = true;
end

if isfield(ctrl,'batch_id')
  batch_id = ctrl.batch_id;
end

if isempty(batch_id)
  error('%s called with no batch_id. Either ctrl.batch_id or batch_id must be specified.',mfilename);
end

% Get the specific batch (ctrl.batch_id specified)
ctrls = cluster_get_batch_list(ctrl);

if isempty(ctrls)
  error('Batch %d not found.', batch_id);
end
if ~ctrl_is_struct || ~isfield(ctrl,'batch_dir')
  if length(ctrls) == 1
    ctrl = ctrls{1};
  else
    fprintf('<strong>There are %d matches for this batch_id %d.</strong>\n', length(ctrls), batch_id);
    fprintf('Select a batch from the list below:\n');
    % This for-loop from cluster_get_batch_list.m:
    for batch_idx = 1:length(ctrls)
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
      
      fprintf('<strong>%d</strong>: Batch %d %s\n', batch_idx, ctrls{batch_idx}.batch_id, ctrls{batch_idx}.batch_dir);
      
      param = merge_structs(sparam.static_param,ctrls{batch_idx}.dparam{1});
      if ~isfield(param,'task_function')
        param.task_function = '';
      end
      if ~isfield(param,'notes')
        param.notes = '';
      end
      fprintf('    task_function: %s\n', param.task_function);
      fprintf('    notes: %s\n', param.notes);
    end
    
    % Check with user
    uinput = [];
    while length(uinput)~=1 || ~isnumeric(uinput) || uinput < 1 || uinput > length(ctrls)
      uinput = input('? ');
    end
    ctrl = ctrls{uinput};
  end
  
else
  found = false;
  for batch_idx = 1:length(ctrls)
    if strcmpi(ctrls{batch_idx}.batch_dir,ctrl.batch_dir)
      found = true;
      ctrl = merge_structs(ctrls{batch_idx}, ctrl);
      break;
    end
  end
  if ~found
    error('Batch %d found, but original batch seems to be deleted since ctrl.batch_dir does not match an existing batch.', batch_id);
  end
end

if update_mode ~= 2
  [fid,msg] = fopen(ctrl.job_id_fn,'r');
  if fid < 1
    warning ('Could not open job id list file %s\n', ctrl.job_id_fn);
    ctrl.job_id_list = [];
    ctrl.error_mask = [];
    ctrl.job_status = [];
    return;
  end
  ctrl.job_id_list = textscan(fid,'%f');
  fclose(fid);
  ctrl.job_id_list = ctrl.job_id_list{1};
  ctrl.task_id = length(ctrl.job_id_list);
  
  % Start by assuming that all jobs are in the to be submitted queue
  ctrl.submission_queue = 1:numel(ctrl.job_id_list);
  ctrl.job_status = char('T'*ones(1,numel(ctrl.job_id_list)));
  
  % Start by assuming that there are no errors in any tasks
  ctrl.error_mask = zeros(size(ctrl.job_status));
  
  % Start by assuming no retries yet
  ctrl.retries = zeros(size(ctrl.job_status));
  
  % Start by assuming zero cpu time and memory requirements
  ctrl.cpu_time = zeros(size(ctrl.job_status));
  ctrl.mem = zeros(size(ctrl.job_status));
end

task_status_found = zeros(size(ctrl.job_status));

%% Update task status for each task using cluster interface
ctrl.active_jobs = 0;
if any(strcmpi(ctrl.cluster.type,{'torque','matlab','slurm'}))
  
  if any(strcmpi(ctrl.cluster.type,{'slurm','torque'}))
    if ~isfield(ctrl.cluster,'user_name') || isempty(ctrl.cluster.user_name)
      [~,ctrl.cluster.user_name] = system('whoami </dev/null');
      ctrl.cluster.user_name = ctrl.cluster.user_name(1:end-1);
    end
    if ~isfield(ctrl.cluster,'ssh_user_name') || isempty(ctrl.cluster.ssh_user_name)
      [~,ctrl.cluster.ssh_user_name] = system('whoami </dev/null');
      ctrl.cluster.ssh_user_name = ctrl.cluster.ssh_user_name(1:end-1);
    end
  end
  
  if strcmpi(ctrl.cluster.type,'torque')
    % Runs qstat command
    % -----------------------------------------------------------------------
    if isempty(ctrl.cluster.ssh_hostname)
      cmd = sprintf('qstat -u %s </dev/null', ctrl.cluster.user_name);
    else
      cmd = sprintf('ssh -p %d -o LogLevel=QUIET -t %s@%s "qstat -u %s </dev/null"', ctrl.cluster.ssh_port, ctrl.cluster.ssh_user_name, ctrl.cluster.ssh_hostname, ctrl.cluster.ssh_user_name);
    end
    [status,result] = robust_system(cmd);
    
  elseif strcmpi(ctrl.cluster.type,'matlab')
    status = 0;
    result = 'NA';
    
  elseif strcmpi(ctrl.cluster.type,'slurm')
    % Runs squeue command
    % -----------------------------------------------------------------------
    if isempty(ctrl.cluster.ssh_hostname)
      cmd = sprintf('squeue --users=%s </dev/null', ctrl.cluster.user_name);
    else
      cmd = sprintf('ssh -p %d -o LogLevel=QUIET -t %s@%s "squeue --users=%s </dev/null"', ctrl.cluster.ssh_port, ctrl.cluster.ssh_user_name, ctrl.cluster.ssh_hostname, ctrl.cluster.ssh_user_name);
    end
    [status,result] = robust_system(cmd);
  end
  
  % Parse qstat command results
  % -----------------------------------------------------------------------
  if ~isempty(result)
    if strcmpi(ctrl.cluster.type,'torque')
      qstat_res = textscan(result,'%s %s %s %s %s %s %s %s %s %s %s %s','Headerlines',5,'Delimiter',sprintf(' \t'),'MultipleDelimsAsOne',1);
      for idx = 1:size(qstat_res{1},1)
        qstat_res{1}{idx} = str2double(strtok(qstat_res{1}{idx},'.'));
        if qstat_res{10}{idx} ~= 'C'
          ctrl.active_jobs = ctrl.active_jobs + 1;
        end
      end
      qstat_res{7} = cell2mat(qstat_res{1});
      qstat_res{5} = qstat_res{10};
      
    elseif strcmpi(ctrl.cluster.type,'matlab')
      qstat_res{5} = {};
      qstat_res{7} = [];
      if ~isfield(ctrl.cluster,'jm')
        ctrl.cluster.jm = parcluster;
        if isfield(ctrl.cluster,'matlab_NumWorkers') && ~isempty(ctrl.cluster.matlab_NumWorkers)
          ctrl.cluster.jm.NumWorkers = ctrl.cluster.matlab_NumWorkers;
        end
      end
      IDs = cell2mat({ctrl.cluster.jm.Jobs.ID});
      States = {ctrl.cluster.jm.Jobs.State};
      for job_idx = 1:length(IDs)
        qstat_res{7}(job_idx,1) = IDs(job_idx);
        if any(strcmpi(States(job_idx),{'finished','failed'}))
          qstat_res{5}{job_idx,1} = 'C';
        elseif any(strcmpi(States(job_idx),{'running'}))
          ctrl.active_jobs = ctrl.active_jobs + 1;
          qstat_res{5}{job_idx,1} = 'R';
        else
          ctrl.active_jobs = ctrl.active_jobs + 1;
          qstat_res{5}{job_idx,1} = 'Q';
        end
      end
      
    elseif strcmpi(ctrl.cluster.type,'slurm')
      qstat_res = textscan(result,'%s %s %s %s %s %s %s %*[^\n]','Headerlines',1,'Delimiter',sprintf(' \t'),'MultipleDelimsAsOne',1);
      try
      for idx = 1:size(qstat_res{1},1)
        qstat_res{1}{idx} = str2double(qstat_res{1}{idx});
        qstat_res{5}{idx} = qstat_res{5}{idx}(1);
        if qstat_res{5}{idx} ~= 'C'
          ctrl.active_jobs = ctrl.active_jobs + 1;
        end
      end
      catch ME
        ME.getReport
        keyboard
      end
      qstat_res{7} = cell2mat(qstat_res{1});
      
    end
    % Loop through all the jobs that qstat returned
    % qstat_res{7}(idx): JOB ID
    % qstat_res{5}{idx}: JOB STATUS
    for idx = 1:size(qstat_res{5},1)
      task_ids = find(qstat_res{7}(idx)==ctrl.job_id_list);
      % Qstat returns all jobs, just look at jobs in this batch
      while ~isempty(task_ids)
        task_id = task_ids(1);
        task_ids = task_ids(2:end);
        task_status_found(task_id) = 1;
        if qstat_res{5}{idx} ~= ctrl.job_status(task_id)
          if ctrl.job_status(task_id) ~= 'C'
            % Only update job if it is not complete
            new_job_status = qstat_res{5}{idx};
            % Debug print
            if update_mode > 0
              fprintf(' Task %d:%d (%d) status changed to %s (%s)\n', ctrl.batch_id, task_id, ctrl.job_id_list(task_id), new_job_status, datestr(now))
            end
            ctrl.job_status(task_id) = new_job_status;
            if update_mode == 2 && any(ctrl.job_status(task_id) == 'C')
              % Get the output information
              ctrl = cluster_update_task(ctrl,task_id);
            end
          end
        end
      end
    end
  end
  
  %% Handle all jobs that were not found in the usual job query mechanism
  if update_mode == 2 && any(task_status_found==0)
    lost_tasks = find(~task_status_found);
    for task_id = lost_tasks
      if ctrl.job_status(task_id) ~= 'C' && ctrl.job_status(task_id) ~= 'T'
        % Since the job has been queued (status is not equal to 'T') and
        % the job is no longer in the cluster scheduler, we assume the job
        % has completed and was removed from the cluster cache.
        ctrl.job_status(task_id) = 'C';
        ctrl = cluster_update_task(ctrl,task_id);
      end
    end
  end
end

if update_mode == 2
  return;
end

if ~force_check
  static_in_fn = fullfile(ctrl.in_fn_dir,'static.mat');
  dynamic_in_fn = fullfile(ctrl.in_fn_dir,'dynamic.mat');
  if isempty(ctrl.job_status)
    sparam = [];
  else
    sparam = load(static_in_fn);
  end
  for task_id = 1:length(ctrl.job_status)
    if ~isfield(ctrl,'dparam') || numel(ctrl.dparam) < task_id || isempty(ctrl.dparam{task_id})
      tmp = load(dynamic_in_fn);
      ctrl.dparam = tmp.dparam;
    end
    param = merge_structs(sparam.static_param,ctrl.dparam{task_id});
    ctrl.cpu_time(task_id) = param.cpu_time;
    ctrl.mem(task_id) = param.mem;
  end
  
  return
end

for task_id = 1:length(ctrl.job_status)
  ctrl = cluster_update_task(ctrl,task_id,update_mode);
end
