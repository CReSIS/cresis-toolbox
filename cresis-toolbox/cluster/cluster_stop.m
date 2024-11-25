function cluster_stop(ctrl_chain,mode)
% cluster_stop(ctrl_chain,mode)
%
% Sets a hold and kills jobs for a chain or batch specified by ctrl_chain, but
% leaves the ctrl_chain data files (unlike cluster_cleanup which kills jobs
% and removes data files).
%
% Inputs:
% ctrl_chain = Several options to specify
%   1. Vector of chain IDs or batch IDs, if batch ID, then mode must be set to 'batch'
%   2. A ctrl structure identifying a batch
%   3. A chain (cell array of ctrl)
%   4. A list of chains (cell array of chains)
% mode: Only used if ctrl_chain is an integer array, default is 'chain'.
%   Integer array will be treated as chains if mode is 'chain' and batches
%   if mode is 'batch'.
%
% Examples:
%   cluster_stop(1)
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

%% Input check
if nargin == 0 || isempty(ctrl_chain)
  answer = input('Are you sure you want to stop all cluster jobs? [y/N] ','s');
  if isempty(regexpi(answer,'y'))
    return
  end
  
  ctrl_chain = cluster_get_batch_list;
end

%% Get a list of all batches
ctrls = cluster_get_batch_list;
ctrls_mask = logical(zeros(size(ctrls)));

%% Determine which batches
if isstruct(ctrl_chain)
  % This is an array of batch control structures
  for batch_idx2 = 1:length(ctrl_chain)
    batch_id = ctrl_chain(batch_idx2).batch_id;
    for batch_idx = 1:length(ctrls)
      if ctrls{batch_idx}.batch_id == batch_id
        ctrls_mask(batch_idx) = true;
        ctrls{batch_idx} = merge_structs(ctrls{batch_idx},ctrl_chain(batch_idx2));
      end
    end
  end
elseif iscell(ctrl_chain)
  for chain_idx = 1:length(ctrl_chain)
    if ~iscell(ctrl_chain{chain_idx})
      % This is a control chain
      chain = {ctrl_chain{chain_idx}};
    else
      % This is a list of control chains
      chain = ctrl_chain{chain_idx};
    end
    for batch_idx2 = 1:length(chain)
      batch_id = chain{batch_idx2}.batch_id;
      for batch_idx = 1:length(ctrls)
        if ctrls{batch_idx}.batch_id == batch_id
          ctrls_mask(batch_idx) = true;
          ctrls{batch_idx} = merge_structs(ctrls{batch_idx},chain{batch_idx2});
        end
      end
    end
  end
  
elseif isnumeric(ctrl_chain)
  if nargin >= 2 && ~isempty(mode) && strcmpi(mode,'batch')
    % This is a list of batch IDs
    for idx = 1:length(ctrl_chain)
      batch_id = ctrl_chain(idx);
      for batch_idx = 1:length(ctrls)
        if ctrls{batch_idx}.batch_id == batch_id
          ctrls_mask(batch_idx) = true;
        end
      end
    end
    
  else
    % This is a list of chain IDs
    for idx = 1:length(ctrl_chain)
      try
        ctrl_chain = cluster_load_chain(ctrl_chain(idx));
      catch
        continue
      end
      cluster_stop(ctrl_chain);
    end
    return;
  end
end
ctrls = ctrls(ctrls_mask);

%% Stop jobs in each batch
for ctrl_idx = 1:length(ctrls)
  ctrl = ctrls{ctrl_idx};
  fprintf('Stopping batch %d\n', ctrl.batch_id);
  try
    ctrl = cluster_get_batch(ctrl,false,0);
    if strcmpi(ctrl.cluster.type,'matlab') && ~isfield(ctrl.cluster,'jm')
      ctrl.cluster.jm = parcluster;
    end
    cluster_hold(ctrl,1);
    if any(strcmpi(ctrl.cluster.type,{'torque','matlab','slurm'}))
      
      % Create a list of each job in the batch (for matlab cluster, also
      % delete the job)
      stopped_job_id_list = [];
      for task_id = 1:length(ctrl.job_id_list)
        if any(ctrl.job_id_list(task_id) == stopped_job_id_list)
          continue
        end
        if ctrl.job_status(task_id) ~= 'C'
          % Only delete jobs that have not been completed (completed jobs
          % are effectively deleted already)
          if strcmpi(ctrl.cluster.type,'matlab')
            for job_idx = length(ctrl.cluster.jm.Jobs):-1:1
              if ctrl.cluster.jm.Jobs(job_idx).ID == ctrl.job_id_list(task_id)
                try; delete(ctrl.cluster.jm.Jobs(job_idx)); end;
              end
            end
          end
          stopped_job_id_list(end+1) = ctrl.job_id_list(task_id);
        end
      end
     
      % For torque and slurm, kill the jobs in the created list
      if strcmpi(ctrl.cluster.type,'torque')
        if isempty(ctrl.cluster.ssh_hostname)
          cmd = sprintf('qdel -W 60 %s </dev/null', sprintf('%d ',stopped_job_id_list));
        else
          cmd = sprintf('ssh -p %d -o LogLevel=QUIET -t %s@%s "qdel -W 60 %s </dev/null"', ctrl.cluster.ssh_port, ctrl.cluster.ssh_user_name, ctrl.cluster.ssh_hostname, sprintf('%d ',stopped_job_id_list));
        end
        try; [status,result] = system(cmd); end
      elseif strcmpi(ctrl.cluster.type,'slurm')
        if isempty(ctrl.cluster.ssh_hostname)
          cmd = sprintf('scancel %s </dev/null', sprintf('%d ',stopped_job_id_list));
        else
          cmd = sprintf('ssh -p %d -o LogLevel=QUIET -t %s@%s "scancel %s </dev/null"', ctrl.cluster.ssh_port, ctrl.cluster.ssh_user_name, ctrl.cluster.ssh_hostname, sprintf('%d ',stopped_job_id_list));
        end
        try; [status,result] = system(cmd); end
      end

      % Update the job's kill status by setting the id to -1
      fid = fopen(ctrl.job_id_fn,'r+');
      for task_id = 1:length(ctrl.job_id_list)
        fseek(fid, 21*(task_id-1), -1);
        fprintf(fid,'%-20d\n', -1);
      end
      fclose(fid);
    end
  catch ME
    warning(ME.getReport);
  end
end
