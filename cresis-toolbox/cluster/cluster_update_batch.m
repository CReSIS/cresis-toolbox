function ctrl = cluster_update_batch(ctrl,force_check)
% ctrl = cluster_update_batch(ctrl,force_check)
%
% Updates task status information from the cluster. Also prints
% out status information when job changes status. Generally this function
% is only called from the matlab session controlling the batch.
%
% Inputs:
% ctrl: ctrl structure returned from cluster_new_batch
%  .job_id_list: Nx1 vector of cluster job IDs
%  .job_status: Nx1 vector of job status
%  .out_fn_dir: string containing the output directory
%  .error_mask: Nx1 vector of error status
%  .out: up-to-Nx1 vector of cells containing the outputs for each
%    job as they complete (read in from the output.mat files)
% force_check: force check of success condition in each task
%
% Outputs:
% ctrl: updated ctrl structure
%
% torque job_status states:
% T -  Task is created, but not attached to a job
% Q -  Job containing task is queued, eligible to run or routed.
% C -  Task is completed
% E -  Job containing task is exiting after having run.
% H -  Job containing task is held.
% R -  Job containing task is running.
% W -  Job containing task is waiting for its execution time
%      (-a option) to be reached.
% S -  (Unicos only) Job containing task is suspended.
%
% matlab job_status states:
% T -  Task is created, but not attached to a job
% Q -  Task is queued or running
% C -  Task is completed after having finished.
%
% debug job_status states:
% T -  Task is created, but not attached to a job
% Q -  Task is queued or running
% C -  Task is completed after having run.
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

if strcmpi(ctrl.cluster.type,'debug')
  force_check = true;
end

task_status_found = zeros(size(ctrl.job_status));

%% Update task status for each task using cluster interface
ctrl.active_jobs = 0;
if any(strcmpi(ctrl.cluster.type,{'matlab','slurm','torque'}))

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
    % ---------------------------------------------------------------------
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
    % ---------------------------------------------------------------------
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
            new_job_status = qstat_res{5}{idx};
            % Debug: Print a message for all changes besides running and exiting
            fprintf(' Task %d:%d (%d) status changed to %s (%s)\n', ctrl.batch_id, task_id, ctrl.job_id_list(task_id), new_job_status, datestr(now))
            ctrl.job_status(task_id) = new_job_status;
            if any(ctrl.job_status(task_id) == 'C')
              % Get the output information
              ctrl = cluster_update_task(ctrl,task_id);
            end
          end
        end
      end
    end
  end
  
  %% Handle all jobs that were not found in the usual job query mechanism
  if any(task_status_found==0)
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

%% Force check on outputs of all other jobs
if force_check
  for task_id = find(ctrl.job_status ~= 'C' & ctrl.job_status ~= 'T')
    ctrl = cluster_update_task(ctrl,task_id);
  end
end
