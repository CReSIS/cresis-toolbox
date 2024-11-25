function cluster_hold(ctrl_chain,hold_state,mode)
% cluster_hold(ctrl_chain,hold_state,mode)
%
% Places or removes hold on specified batches.
%
% Inputs:
% ctrl_chain = Several options to specify
%   1. Vector of chain IDs or batch IDs, if batch ID, then mode must be set to 'batch'
%   2. A ctrl structure identifying a batch
%   3. A chain (cell array of ctrl)
%   4. A list of chains (cell array of chains)
% hold_state = mode must be one of the following
%   0: removes hold
%   1: applies hold
%   []: if empty or undefined, the hold_state is toggled
% mode: string containing mode identifiers. If 'chain' is contained in the
%   string then numeric IDs are treated as chain IDs. If 'batch' is contained
%   in the string, then numeric IDs are treated as batch IDs. If 'hold' is
%   contained in the string and torque cluster type, then each job will be
%   sent a hold or unhold state command.
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
  answer = input('Are you sure you want to hold all cluster jobs? [y/N] ','s');
  if isempty(regexpi(answer,'y'))
    return
  end
  
  ctrl_chain = cluster_get_batch_list;
end

if ~exist('hold_state','var')
  hold_state = [];
end

if ~exist('mode','var')
  mode = 'chain';
end

%% Get a list of all batches
ctrls = cluster_get_batch_list;
ctrls_mask = logical(zeros(size(ctrls)));

%% Determine which batches
if isstruct(ctrl_chain)
  % This is an array of batch control structures
  for batch_idx = 1:length(ctrl_chain)
    batch_id = ctrl_chain(batch_idx).batch_id;
    for batch_idx = 1:length(ctrls)
      if ctrls{batch_idx}.batch_id == batch_id
        ctrls_mask(batch_idx) = true;
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
    for batch_idx = 1:length(chain)
      batch_id = chain{batch_idx}.batch_id;
      for batch_idx = 1:length(ctrls)
        if ctrls{batch_idx}.batch_id == batch_id
          ctrls_mask(batch_idx) = true;
        end
      end
    end
  end
  
elseif isnumeric(ctrl_chain)
  if nargin >= 3 && ~isempty(mode) && ~isempty(regexpi(mode,'batch'))
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
        ctrl_chain_tmp = cluster_load_chain(ctrl_chain(idx));
      catch
        continue
      end
      cluster_hold(ctrl_chain_tmp,hold_state,mode);
    end
    return;
  end
end
ctrls = ctrls(ctrls_mask);

%% Place hold on each batch
for ctrl_idx = 1:length(ctrls)
  ctrl = ctrls{ctrl_idx};
  
  if isempty(hold_state)
    % When no hold state passed in, then toggle the hold state
    if exist(ctrl.hold_fn,'file')
      hold_state = 0;
    else
      hold_state = 1;
    end
  end
  if hold_state == 1
    fprintf(' Placing hold on batch %d\n', ctrl.batch_id);
  elseif hold_state == 0
    fprintf(' Removing hold on batch %d\n', ctrl.batch_id);
  end
  
  if hold_state == 1
    fid = fopen(ctrl.hold_fn,'w');
    fclose(fid);
    
  elseif hold_state == 0
    if exist(ctrl.hold_fn,'file')
      delete(ctrl.hold_fn);
    end
  end
  
  % Enable this code if you need to place torque-holds on the jobs in the
  % queue.
  if ~isempty(regexpi(mode,'hold')) && any(strcmpi(ctrl.cluster.type,{'torque'}))
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
    job_id_list = unique(ctrl.job_id_list);
    % For each job in the batch, remove/place as specified
    for job_id = 1:length(job_id_list)
      if hold_state == 1
        cmd = sprintf('qhold -h u %i', job_id_list(job_id));
        try
          [status,result] = system(cmd);
        catch
          cmd
          warning('system call failed');
          %   keyboard;
        end
        
      elseif hold_state == 0
        cmd = sprintf('qalter -h n %i', job_id_list(job_id));
        try
          [status,result] = system(cmd);
        catch
          cmd
          warning('system call failed');
          %   keyboard;
        end
      end
    end
  end
  
end

