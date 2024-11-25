function cluster_cleanup(ctrl_chain,mode)
% cluster_cleanup(ctrl_chain,mode)
%
% Similar to cluster_stop, but also removes chain and batch files. Run with
% no arguments to clean everything.
%
% Inputs:
%
% ctrl_chain: Optional argument. If no arguments are passed to
%  cluster_cleanup you are given the option to remove all chains and
%  batches. Otherwise, the first argument must be one of the following
%  options:
%   1. Vector of chain IDs or batch IDs, if batch ID, then mode must be set to 'batch'
%   2. A ctrl structure identifying a batch
%   3. A chain (cell array of ctrl)
%   4. A list of chains (cell array of chains)
% mode: Only used if ctrl_chain is an integer array, default is 'chain'.
%   Integer array will be treated as chains if mode is 'chain' and batches
%   if mode is 'batch'.
%
% Examples:
%   cluster_cleanup % And then answer "y"
%
%   cluster_cleanup(1)
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
  
  % Delete all chain files
  global gRadar;
  param = gRadar;
  chain_fns = get_filenames(param.cluster.data_location,'chain_','','',struct('type','f'));
  for idx = 1:length(chain_fns)
    delete(chain_fns{idx});
  end

  if strcmpi(gRadar.cluster.type,'matlab')
    jm = parcluster;
    delete(jm.Jobs);
  end
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
        [tmp_ctrl_chain,chain_fn] = cluster_load_chain(ctrl_chain(idx));
      catch
        continue
      end
      cluster_cleanup(tmp_ctrl_chain);
      delete(chain_fn);
    end
    return;
  end
end
ctrls = ctrls(ctrls_mask);

%% Stop jobs in each batch and remove files
for ctrl_idx = 1:length(ctrls)
  ctrl = ctrls{ctrl_idx};
  fprintf('Removing batch %d (%s)\n', ctrl.batch_id, datestr(now));
  try
    ctrl = cluster_get_batch(ctrl,false,0);
    if strcmpi(ctrl.cluster.type,'matlab') && ~isfield(ctrl.cluster,'jm')
      ctrl.cluster.jm = parcluster;
    end
    if any(strcmpi(ctrl.cluster.type,{'torque','matlab','slurm'}))
      
      % For each job in the batch, delete the job
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

    end
  catch ME
    warning(ME.getReport);
  end
  fprintf('  %s: Removing %s\n', mfilename, ctrl.batch_dir);
  robust_rmdir(ctrl.batch_dir);
end
