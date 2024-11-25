function [in,out] = cluster_print(ctrl,ids,print_mode,ids_type)
% [in,out] = cluster_print(ctrl,ids,print_mode,ids_type)
%
% Prints out status information for a particular job ID.
%
% Inputs:
% ctrl: integer for which batch to get jobs info for
%   OR
%   control structure for the batch (e.g. returned from cluster_job_list)
% ids: OPTIONS:
%   integer array of task or job IDs to print information about
% print_mode = optional (default is 1)
%   0: do not print status (just return output arguments)
%   1: print detailed status
%   2: print brief status in table format
% ids_type: scalar integer indicating the type of the integers in the
%   ids input argument. 0 for ids containing task ID and 1 for
%   containing cluster side IDs (e.g. torque job ID). Default is 0.
%
% ts = cluster_print(1,1:500,2); % Prints table
% print_struct(ts,1) % Prints a tab-delimited array for spreadsheets
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

if ~exist('print_mode','var') || isempty(print_mode)
  print_mode = 1;
end

if ~exist('ids_type','var') || isempty(ids_type)
  ids_type = 0;
end

if isstruct(ctrl)
  batch_id = ctrl.batch_id;
  ctrls = cluster_get_batch_list(ctrl);
else
  batch_id = ctrl;
  ctrls = cluster_get_batch_list;
end

found = 0;
global gRadar;
for batch_idx = 1:length(ctrls)
  if ctrls{batch_idx}.batch_id == batch_id
    found = 1;
    ctrl = ctrls{batch_idx};
    break;
  end
end

if found == 0
  error('Batch %d not found\n', batch_id);
end

[fid,msg] = fopen(ctrl.job_id_fn,'r');
if fid < 1
  error('Could not open job id list file %s\n', ctrl.job_id_fn);
  ctrl.job_id_list = [];
  
  ctrl.error_mask = [];
  ctrl.job_status = [];
  return;
end
ctrl.job_id_list = textscan(fid,'%f');
fclose(fid);
ctrl.job_id_list = ctrl.job_id_list{1};

id_out_of_bounds_warning_sent = false;

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

%% Just return in,out from each task and print nothing except errors
if print_mode == 0
  % Create in/out filenames
  static_in_fn = fullfile(ctrl.in_fn_dir,'static.mat');
  dynamic_in_fn = fullfile(ctrl.in_fn_dir,'dynamic.mat');
  
  for id_idx = 1:length(ids)
    id = ids(id_idx);
    
    if ids_type == 0
      % cluster task ID (internal cluster*.m ID)
      task_id = id;
      try
        job_id = ctrl.job_id_list(id);
      catch
        if ~id_out_of_bounds_warning_sent
          warning('Ignoring out of bounds task ids (e.g. id %d).', id);
          id_out_of_bounds_warning_sent = true;
        end
        continue;
      end
    else
      % cluster job ID (e.g. torque job ID)
      job_id = id;
      task_id = ctrl.job_id_list(ctrl.job_id_list == id);
    end
    lead_task_id = find(ctrl.job_id_list==ctrl.job_id_list(task_id),1,'last');
    num_tasks = sum(ctrl.job_id_list==ctrl.job_id_list(task_id));
    
    %% Read input files
    % Read static input file
    try
      sparam = load(static_in_fn);
    catch
      warning('Failed to load static input file:\n  %s', static_in_fn);
      sparam = struct();
    end
    % Read dynamic input file
    try
      dparam = load(dynamic_in_fn);
    catch
      warning('Failed to load dynamic input file:\n  %s', dynamic_in_fn);
      dparam = struct();
    end
    in{id_idx} = merge_structs(sparam.static_param,dparam.dparam{task_id});
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
    in{id_idx}.argsin = {};
    for idx = 1:max(sparam_argsin_numel,dparam_argsin_numel)
      if idx <= sparam_argsin_numel
        if idx <= dparam_argsin_numel
          in{id_idx}.argsin{idx} = merge_structs(sparam.static_param.argsin{idx},dparam.dparam{task_id}.argsin{idx});
        else
          in{id_idx}.argsin{idx} = sparam.static_param.argsin{idx};
        end
      else
        in{id_idx}.argsin{idx} = dparam.dparam{task_id}.argsin{idx};
      end
    end
    
    %% Read output file
    out_fn = fullfile(ctrl.out_fn_dir,sprintf('out_%d.mat',task_id));
    out{id_idx} = [];
    try
      out{id_idx} = load(out_fn);
      if isfield(out{id_idx},'errorstruct')
        if ~isempty(out{id_idx}.errorstruct)
          fprintf('%s: %s\n', out{id_idx}.errorstruct.identifier, out{id_idx}.errorstruct.message);
          for stack_idx = 1:length(out{id_idx}.errorstruct.stack)
            fprintf('  %s: %d\n', out{id_idx}.errorstruct.stack(stack_idx).name, out{id_idx}.errorstruct.stack(stack_idx).line);
          end
        end
      end
    catch
      warning('Failed to load output file:\n  %s', out_fn);
    end
  end
  
  return;
end

%% Print detailed information about each task
if print_mode == 1
  
  % Create in/out filenames
  static_in_fn = fullfile(ctrl.in_fn_dir,'static.mat');
  dynamic_in_fn = fullfile(ctrl.in_fn_dir,'dynamic.mat');
  
  for id_idx = 1:length(ids)
    id = ids(id_idx);
    
    if ids_type == 0
      % cluster task ID (internal cluster*.m ID)
      task_id = id;
      try
        job_id = ctrl.job_id_list(id);
      catch
        if ~id_out_of_bounds_warning_sent
          warning('Ignoring out of bounds task ids (e.g. id %d).', id);
          id_out_of_bounds_warning_sent = true;
        end
        continue;
      end
    else
      % cluster job ID (e.g. torque job ID)
      job_id = id;
      task_id = find(ctrl.job_id_list == id,1);
      if isempty(task_id)
        error('Task not found.');
      end
    end
    if ctrl.job_id_list(task_id) == -1
      lead_task_id = task_id;
      num_tasks = 1;
    else
      lead_task_id = find(ctrl.job_id_list==ctrl.job_id_list(task_id),1,'last');
      num_tasks = sum(ctrl.job_id_list==ctrl.job_id_list(task_id));
    end
    
    %% Print cluster scheduler information if available
    fprintf('Matlab Task ID %d (lead by %d with %d tasks)\n', task_id, lead_task_id, num_tasks);
    fprintf('Cluster Job ID %d\n', job_id);
    
    if job_id ~= -1
      if strcmpi(ctrl.cluster.type,'torque')
        if isempty(ctrl.cluster.ssh_hostname)
          cmd = sprintf('qstat -f %d </dev/null', job_id);
        else
          cmd = sprintf('ssh -p %d -o LogLevel=QUIET -t %s@%s "qstat -f %d </dev/null"', ctrl.cluster.ssh_port, ctrl.cluster.ssh_user_name, ctrl.cluster.ssh_hostname, job_id);
        end
        try; [status,result] = system(cmd); end;
        
      elseif strcmpi(ctrl.cluster.type,'matlab')
        cmd = 'NA';
        status = -1;
        
      elseif strcmpi(ctrl.cluster.type,'slurm')
        %cmd = sprintf('sstat --format=AveCPU,AvePages,AveRSS,AveVMSize,JobID -j %d --allsteps', job_id);
        if isempty(ctrl.cluster.ssh_hostname)
          cmd = sprintf('scontrol show job %d </dev/null', job_id);
        else
          cmd = sprintf('ssh -p %d -o LogLevel=QUIET -t %s@%s "scontrol show job %d </dev/null"', ctrl.cluster.ssh_port, ctrl.cluster.ssh_user_name, ctrl.cluster.ssh_hostname, job_id);
        end
        try; [status,result] = system(cmd); end;
        
      elseif strcmpi(ctrl.cluster.type,'debug')
        cmd = 'NA';
        status = -1;
      else
        error('Invalid ctrl.cluster.type ("%s") for this task. May be populated from gRadar.cluster.type in startup.m.', ctrl.cluster.type);
      end
      
      if status == 0
        fprintf('\nSCHEDULER INFO ============================================================\n');
        fprintf('%s\n', cmd);
        result
      end
    end
    
    %% Print stdout and stderr files if available
    if strcmpi(ctrl.cluster.type,'matlab')
      fprintf('\n\nSTDOUT ======================================================================\n');
      try
        if ~isfield(ctrl.cluster,'jm')
          ctrl.cluster.jm = parcluster;
        end
        fprintf('%s\n', ctrl.cluster.jm.findJob('ID',job_id).Tasks.Diary);
      catch ME
        fprintf('Failed to retrieve\n');
      end
    elseif any(strcmpi(ctrl.cluster.type,{'torque','slurm'}))
      retry = 0;
      fn = fullfile(ctrl.stdout_fn_dir,sprintf('stdout_%d_%d.txt',task_id, retry));
      while exist(fn,'file')
        fprintf('\n\nSTDOUT RETRY %d ==========================================================\n', retry);
        fprintf('%s\n', fn);
        type(fn);
        retry = retry + 1;
        fn = fullfile(ctrl.stdout_fn_dir,sprintf('stdout_%d_%d.txt',task_id, retry));
      end
      fn = fullfile(ctrl.stdout_fn_dir,sprintf('stdout_%d.txt',lead_task_id));
      fprintf('\n\nSTDOUT ======================================================================\n');
      fprintf('%s\n', fn);
      if exist(fn,'file')
        type(fn);
      else
        fprintf('  Does not exist\n');
      end
      
      retry = 0;
      fn = fullfile(ctrl.error_fn_dir,sprintf('error_%d_%d.txt',task_id, retry));
      while exist(fn,'file')
        fprintf('\n\nSTDERR RETRY %d ==========================================================\n', retry);
        fprintf('%s\n', fn);
        type(fn);
        retry = retry + 1;
        fn = fullfile(ctrl.error_fn_dir,sprintf('error_%d_%d.txt',task_id, retry));
      end
      fn = fullfile(ctrl.error_fn_dir,sprintf('error_%d.txt',lead_task_id));
      fprintf('\n\nSTDERR ======================================================================\n');
      fprintf('%s\n', fn);
      if exist(fn,'file')
        type(fn);
      else
        fprintf('  Does not exist\n');
      end
    end
    
    %% Read input files
    % Read static input file
    fprintf('\n\nSTATIC INPUT ==================================================================\n');
    fprintf('%s\n', static_in_fn);
    try
      sparam = load(static_in_fn);
      fprintf('  Loaded\n');
    catch
      fprintf('  Failed to load\n');
      sparam = struct();
    end
    % Read dynamic input file
    fprintf('\n\nDYNAMIC INPUT =================================================================\n');
    fprintf('%s\n', dynamic_in_fn);
    try
      dparam = load(dynamic_in_fn);
      fprintf('  Loaded\n');
    catch
      fprintf('  Failed to load\n');
      dparam = struct();
    end
    in{id_idx} = merge_structs(sparam.static_param,dparam.dparam{task_id});
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
    in{id_idx}.argsin = {};
    for idx = 1:max(sparam_argsin_numel,dparam_argsin_numel)
      if idx <= sparam_argsin_numel
        if idx <= dparam_argsin_numel
          in{id_idx}.argsin{idx} = merge_structs(sparam.static_param.argsin{idx},dparam.dparam{task_id}.argsin{idx});
        else
          in{id_idx}.argsin{idx} = sparam.static_param.argsin{idx};
        end
      else
        in{id_idx}.argsin{idx} = dparam.dparam{task_id}.argsin{idx};
      end
    end
    
    %% Read output file
    out_fn = fullfile(ctrl.out_fn_dir,sprintf('out_%d.mat',task_id));
    out{id_idx} = [];
    fprintf('\n\nOUT ===========================================================================\n');
    fprintf('%s\n', out_fn);
    if ~exist(out_fn,'file')
      fprintf('  File does not exist\n');
    else
      try
        out{id_idx} = load(out_fn);
        fprintf('  Loaded\n');
        try
          if isfield(out{id_idx},'errorstruct')
            if ~isempty(out{id_idx}.errorstruct)
              fprintf('%s: %s\n', out{id_idx}.errorstruct.identifier, out{id_idx}.errorstruct.message);
              for stack_idx = 1:length(out{id_idx}.errorstruct.stack)
                fprintf('  %s: %d\n', out{id_idx}.errorstruct.stack(stack_idx).name, out{id_idx}.errorstruct.stack(stack_idx).line);
              end
            end
          end
        catch
          fprintf('  Failed during errorstruct interpretation\n');
        end
      catch
        fprintf('  Failed to load\n');
      end
    end
    
  end
  
  return
end

%% Print summary information about each task
if print_mode == 2
  % Create in/out filenames
  static_in_fn = fullfile(ctrl.in_fn_dir,'static.mat');
  dynamic_in_fn = fullfile(ctrl.in_fn_dir,'dynamic.mat');
  
  %% Read input files
  % Read static input file
  try
    sparam = load(static_in_fn);
  catch
    warning('Failed to load static input file:\n  %s', static_in_fn);
    sparam = struct();
  end
  % Read dynamic input file
  try
    dparam = load(dynamic_in_fn);
  catch
    warning('Failed to load dynamic input file:\n  %s', dynamic_in_fn);
    dparam = struct();
  end
  
  info = struct();
  
  exec_node_max_len = 0;
  cluster_job_id = [];
  cluster_status = [];
  cluster_result = {};
  for id_idx = 1:length(ids)
    id = ids(id_idx);
    
    if ids_type == 0
      % cluster task ID (internal cluster*.m ID)
      task_id = id;
      try
        job_id = ctrl.job_id_list(id);
      catch
        if ~id_out_of_bounds_warning_sent
          warning('Ignoring out of bounds task ids (e.g. id %d).', id);
          id_out_of_bounds_warning_sent = true;
        end
        continue;
      end
    else
      % cluster job ID (e.g. torque job ID)
      job_id = id;
      task_id = find(ctrl.job_id_list == id);
      if isempty(task_id)
        error('Job %d no longer exists in batch file list.', id);
      end
    end
    lead_task_id = find(ctrl.job_id_list==ctrl.job_id_list(task_id),1,'last');
    num_tasks = sum(ctrl.job_id_list==ctrl.job_id_list(task_id));
    
    info(id_idx).task_id = uint32(task_id);
    info(id_idx).job_id = int32(job_id);
    
    info(id_idx).job_state = '-';
    info(id_idx).exec_node = '';
    info(id_idx).task_est = NaN;
    info(id_idx).task = NaN;
    info(id_idx).job_est = '';
    info(id_idx).job = '';
    info(id_idx).mem_est = NaN;
    info(id_idx).mem = NaN;
   
    if job_id ~= -1
      if strcmpi(ctrl.cluster.type,'torque')
        cluster_result_idx = find(cluster_job_id == job_id);
        if isempty(cluster_result_idx)
          if isempty(ctrl.cluster.ssh_hostname)
            cmd = sprintf('qstat -f %d </dev/null', job_id);
          else
            cmd = sprintf('ssh -p %d -o LogLevel=QUIET -t %s@%s "qstat -f %d </dev/null"', ctrl.cluster.ssh_port, ctrl.cluster.ssh_user_name, ctrl.cluster.ssh_hostname, job_id);
          end
          try; [status,result] = system(cmd); end;
          cluster_job_id(end+1) = job_id;
          cluster_status(end+1) = status;
          cluster_result{end+1} = result;
        else
          status = cluster_status(cluster_result_idx);
          result = cluster_result{cluster_result_idx};
        end
        
        if status == 0
          
          % Job State
          try
            idx = regexp(result,'job_state');
            tmp_result = result(idx:end);
            idx = find(tmp_result=='=',1);
            tmp_result = tmp_result(idx+2:end);
            idx = find(tmp_result==10|tmp_result==13,1);
            tmp_result = tmp_result(1:idx);
            tmp_result(tmp_result==10 | tmp_result==13) = 0;
            info(id_idx).job_state = tmp_result(1);
          end

          % Execution host
          try
            idx = regexp(result,'exec_host');
            tmp_result = result(idx:end);
            idx = find(tmp_result=='=',1);
            tmp_result = tmp_result(idx+2:end);
            idx = find(tmp_result==10|tmp_result==13,1);
            tmp_result = tmp_result(1:idx);
            tmp_result(tmp_result==10 | tmp_result==13) = 0;
            info(id_idx).exec_node = tmp_result;
            if length(tmp_result) > exec_node_max_len
              exec_node_max_len = length(tmp_result);
            end
          end
          
          % CPU time in minutes
          try
            idx = regexp(result,'resources_used.walltime');
            tmp_result = result(idx:end);
            idx = find(tmp_result=='=',1);
            tmp_result = tmp_result(idx+2:end);
            idx = find(tmp_result==10|tmp_result==13,1);
            tmp_result = tmp_result(1:idx);
            if ~isempty(tmp_result)
              info(id_idx).job = sprintf('=%d/%d', round((datenum(tmp_result) - datenum('00:00:00'))*86400/60), num_tasks);
            end
          end
          
          % Memory in megabytes
          try
            idx = regexp(result,'resources_used.mem');
            tmp_result = result(idx:end);
            idx = find(tmp_result=='=',1);
            tmp_result = tmp_result(idx+2:end);
            idx = find(tmp_result==10|tmp_result==13,1);
            tmp_result = tmp_result(1:idx);
            [mem,~,~,idx] = sscanf(tmp_result,'%d');
            tmp_result = tmp_result(idx:end);
            mem_units = sscanf(tmp_result,'%s');
            if strcmpi(mem_units,'mb')
              info(id_idx).mem = mem;
            elseif strcmpi(mem_units,'kb')
              info(id_idx).mem = mem/1e3;
            elseif strcmpi(mem_units,'gb')
              info(id_idx).mem = mem*1e3;
            else
              info(id_idx).mem = mem/1e6;
            end
          end
          
          % CPU time requested in minutes
          try
            idx = regexp(result,'Resource_List.walltime');
            tmp_result = result(idx:end);
            idx = find(tmp_result=='=',1);
            tmp_result = tmp_result(idx+2:end);
            idx = find(tmp_result==10|tmp_result==13,1);
            tmp_result = tmp_result(1:idx);
            if ~isempty(tmp_result)
              info(id_idx).job_est = sprintf('=%d/%d', round((datenum(tmp_result) - datenum('00:00:00'))*86400/60), num_tasks);
            end
          end
          
          % Memory requested in megabytes
          try
            idx = regexp(result,'Resource_List.pmem');
            tmp_result = result(idx:end);
            idx = find(tmp_result=='=',1);
            tmp_result = tmp_result(idx+2:end);
            idx = find(tmp_result==10|tmp_result==13,1);
            tmp_result = tmp_result(1:idx);
            [mem_est,~,~,idx] = sscanf(tmp_result,'%d');
            tmp_result = tmp_result(idx:end);
            mem_units = sscanf(tmp_result,'%s');
            if strcmpi(mem_units,'mb')
              info(id_idx).mem_est = uint32(mem_est);
            elseif strcmpi(mem_units,'kb')
              info(id_idx).mem_est = uint32(mem_est/1e3);
            elseif strcmpi(mem_units,'gb')
              info(id_idx).mem_est = uint32(mem_est*1e3);
            else
              info(id_idx).mem_est = uint32(mem_est/1e6);
            end
          end
        end
        
      elseif strcmpi(ctrl.cluster.type,'slurm')
        cluster_result_idx = find(cluster_job_id == job_id);
        if isempty(cluster_result_idx)
          %cmd = sprintf('sstat --format=AveCPU,AvePages,AveRSS,AveVMSize,JobID -j %d --allsteps', job_id);
          if isempty(ctrl.cluster.ssh_hostname)
            cmd = sprintf('scontrol show job %d </dev/null', job_id);
          else
            cmd = sprintf('ssh -p %d -o LogLevel=QUIET -t %s@%s "scontrol show job %d </dev/null"', ctrl.cluster.ssh_port, ctrl.cluster.ssh_user_name, ctrl.cluster.ssh_hostname, job_id);
          end
          try; [status,result] = system(cmd); end;
          cluster_job_id(end+1) = job_id;
          cluster_status(end+1) = status;
          cluster_result{end+1} = result;
        else
          status = cluster_status(cluster_result_idx);
          result = cluster_result{cluster_result_idx};
        end
        
        % This section not completed yet

        % NodeList=snowflake0
      end
    end
    
    % Check stdout and stderr files
    if any(strcmpi(ctrl.cluster.type,{'torque','slurm'}))
      retry = 0;
      fn = fullfile(ctrl.stdout_fn_dir,sprintf('stdout_%d_%d.txt',task_id, retry));
      while exist(fn,'file')
        retry = retry + 1;
        fn = fullfile(ctrl.stdout_fn_dir,sprintf('stdout_%d_%d.txt',task_id, retry));
      end
      info(id_idx).stdout_retry = retry;
      
      retry = 0;
      fn = fullfile(ctrl.stdout_fn_dir,sprintf('error_%d_%d.txt',task_id, retry));
      while exist(fn,'file')
        retry = retry + 1;
        fn = fullfile(ctrl.stdout_fn_dir,sprintf('error_%d_%d.txt',task_id, retry));
      end
      info(id_idx).stderr_retry = retry;
      
      fn = fullfile(ctrl.stdout_fn_dir,sprintf('stdout_%d.txt',lead_task_id));
      if exist(fn,'file')
        info(id_idx).stdout = 1;
      else
        info(id_idx).stdout = 0;
      end
      fn = fullfile(ctrl.error_fn_dir,sprintf('error_%d.txt',lead_task_id));
      if exist(fn,'file')
        info(id_idx).stderr = 1;
      else
        info(id_idx).stderr = 0;
      end
      
    else
      info(id_idx).stdout = NaN;
      info(id_idx).stderr = NaN;
    end
    
    % Check input files
    if exist(static_in_fn,'file')
      info(id_idx).in_static = 1;
    else
      info(id_idx).in_static = 0;
    end
    if exist(dynamic_in_fn,'file')
      info(id_idx).in_dynamic = 1;
    else
      info(id_idx).in_dynamic = 0;
    end
    
    % Check output file
    out_fn = fullfile(ctrl.out_fn_dir,sprintf('out_%d.mat',task_id));
    if exist(out_fn,'file')
    else
    end

    task_in = merge_structs(sparam.static_param,dparam.dparam{task_id});
    if isnan(info(id_idx).mem_est)
      info(id_idx).mem_est = task_in.mem/1e6;
    end
    
    % Read output file
    out_fn = fullfile(ctrl.out_fn_dir,sprintf('out_%d.mat',task_id));
    out{id_idx} = [];
    try
      out{id_idx} = load(out_fn);
      info(id_idx).out = 1;
      try
        if isfield(out{id_idx},'errorstruct')
          if ~isempty(out{id_idx}.errorstruct)
            fprintf('%s: %s\n', out{id_idx}.errorstruct.identifier, out{id_idx}.errorstruct.message);
            for stack_idx = 1:length(out{id_idx}.errorstruct.stack)
              fprintf('  %s: %d\n', out{id_idx}.errorstruct.stack(stack_idx).name, out{id_idx}.errorstruct.stack(stack_idx).line);
            end
          end
        end
      catch
        info(id_idx).out = 0;
      end
    catch
      info(id_idx).out = 0;
    end
    
    info(id_idx).task_est = round(task_in.cpu_time/60);
    if isfield(out{id_idx},'cpu_time_actual')
      info(id_idx).task = round(out{id_idx}.cpu_time_actual/60);
    end
    
    info(id_idx).notes = task_in.notes;
    
    if isnan(info(id_idx).mem)
      fn = fullfile(ctrl.stdout_fn_dir,sprintf('stdout_%d.txt',lead_task_id));
      [fid,msg] = fopen(fn);
      if fid > 0
        result = fread(fid,inf,'char=>char').';
        fclose(fid);
        try
          % Memory requested in megabytes
          idx = regexp(result,'Max Mem');
          tmp_result = result(idx(end):end);
          idx = find(tmp_result==':',1);
          tmp_result = tmp_result(idx+2:end);
          idx = find(tmp_result==10|tmp_result==13,1);
          tmp_result = tmp_result(1:idx);
          [mem,~,~,idx] = sscanf(tmp_result,'%d');
          info(id_idx).mem = mem/1e3;
        end
        try
          if isempty(info(id_idx).exec_node)
            % Exec host
            idx = regexp(result,'hostname:');
            tmp_result = result(idx(end):end);
            idx = find(tmp_result==':',1);
            tmp_result = tmp_result(idx+2:end);
            idx = find(tmp_result==' ');
            tmp_result = tmp_result(1:idx-1);
            info(id_idx).exec_node = tmp_result;
            if length(tmp_result) > exec_node_max_len
              exec_node_max_len = length(tmp_result);
            end
          end
        end
      end
    end
    
  end
  in = info;
  
  fprintf(print_struct(in));
  
  return
end
