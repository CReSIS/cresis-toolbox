function cluster_cpu_affinity(num_my_processors,process_list,force)
% cluster_cpu_affinity(num_my_processors,process_list,force)
%
% Assigns the current process to "num_my_processors" using cpu affinity
% settings.
%
% Inputs:
% num_my_processors: the number of physical cores to assign.
% process_list: string argument which overrides process list to taskset;
%   default is an empty string which sets this scripts process id.
% force: logical; default is false; if true force processor affinity to be
% set even if there are not enough processors
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

if ~exist('process_list','var')
  process_list = '';
end

if ~exist('force','var')
  force = false;
end

try  
  % 1. Get Matlab's process id:
  % feature getpid
  pid = feature('getpid');
  
  % 2. Determine what processors this machine has
  % numactl -H
  cmd = 'numactl -H';
  [status,result] = system(cmd);
  node_idxs = regexpi(result,'node [0-9] cpus:');
  node = [];
  for node_idxs_idx = 1:length(node_idxs)
    end_idx = find(result(node_idxs(node_idxs_idx)+12:end) == 10,1);
    node(end+1,:) = cellfun(@str2double, regexpi(result(node_idxs(node_idxs_idx)+12+(1:end_idx-2)),' ','split'));
  end
  
  % 3. Determine what the cpu affinity is for each process
  if 0
    % Debug output
    cmd = 'for pid in $(ps -u root -N -o pid=); do taskset -p $pid 2>/dev/null; echo "  " `ps -p $pid -f|tail -n -1`; done';
    system(cmd);
  end
  cmd = 'for pid in $(ps -u root -N -o pid=); do taskset -p $pid 2>/dev/null | awk ''{print $6}''; done';
  [status,result] = system(cmd);
  
  process = [];
  if status == 0
    cpu_affinity_dec = sscanf(result, '%x');
    for proc_idx = 1:length(cpu_affinity_dec)
      new_process = double(dec2bin(cpu_affinity_dec(proc_idx),numel(node)) - '0').';
      if ~all(new_process)
        process(end+1,:) = new_process;
      end
    end
  else
    error('Failed to get cpu affinity.');
  end
  
  % Identify if any processes have affinity. Avoid processors that have
  % affinity to specific processes.
  if isempty(process)
    % No processes have affinity, so assume that all processors are available
    processors = zeros(1,numel(node));
  else
    processors = fliplr(any(process,1));
  end
  
  fprintf('%2d ', 1:length(processors)); fprintf('\n');
  fprintf('%2d ', processors); fprintf('\n');
  
  % Loop through available processors and select processors that are
  % available and are not logical pairs to already selected processors. If
  % there are not enough processors available, print a warning message since
  % this never happen.Confirm which process is the lead logical pr
  my_processors = [];
  for cpu_idx = 1:length(processors)
    if processors(cpu_idx) == 0
      cpu = cpu_idx - 1;
      % Find all of this processor's logical pairs
      cmd = sprintf('cat /sys/devices/system/cpu/cpu%d/topology/thread_siblings_list', cpu);
      [status,result] = system(cmd);
      logical_processors = cellfun(@str2double,regexp(result,',','split'));
      % Verify that none of the processor's logical pairs are used
      if ~all(~processors(logical_processors+1))
        fprintf('Core %d logical pair in use.\n', cpu_idx);
        processors(logical_processors+1) = 0;
        continue;
      end
      fprintf('Core %d available.\n', cpu_idx);
      % Take this processor and its logical pairs
      processors(logical_processors+1) = 1;
      my_processors(end+1) = cpu;
      num_my_processors = num_my_processors - 1;
    else
      fprintf('Core %d in use.\n', cpu_idx);
    end
    if num_my_processors == 0
      break;
    end
  end
  if num_my_processors ~= 0
    if force
      my_processors = 0:size(process,2)-1;
    else
      error('Insufficient processors available. Need %d more processors.', num_my_processors);
    end
  end
  
  % 4. Set this processes CPU affinity
  % taskset -p MY_CPU_AFFINITY PID
  process = zeros(1,size(process,2));
  process(my_processors+1) = 1;
  process_str = sprintf('%d,',find(process)-1);
  process_str = process_str(1:end-1);

  % Check to see if Torque can provide processor list
  jobid = getenv('PBS_JOBID');
  if ~isempty(jobid)
    fprintf('PBS_JOBID = %s\n', jobid);
    cmd = sprintf('qstat -f %s | grep exec_host', jobid);
    [status,result] = system(cmd);
    fprintf('QSTAT: %s\n', result);
    matches = regexp(result,'(/)([0-9]*)[+\n]','match')
    process_str = '';
    for idx=1:length(matches)
      if idx == 1
        process_str = matches{idx}(2:end-1);
      else
        process_str = [process_str ',' matches{idx}(2:end-1)];
      end
    end
    fprintf('process_str: %s\n', process_str);
  end

  % Set parent process CPU affinity
  cmd = sprintf('ps -p %d -o pid,ppid | grep %d | awk ''{print $2}''', pid, pid);
  [status,result] = system(cmd);
  ppid = cellfun(@str2double,regexp(result,'\n','split'));
  if ~isempty(process_list)
    % Override
    cmd = sprintf('taskset -cp %s %d', process_list, ppid(1));
  else
    cmd = sprintf('taskset -cp %s %d', process_str, ppid(1));
  end
  fprintf('%s\n', cmd);
  system(cmd);
  
  % Set this process and all of its thread's cpu affinity
  cmd = sprintf('ps -eLo pid,tid | grep %d| awk ''{print $2}''', pid);
  [status,result] = system(cmd);
  pids = cellfun(@str2double,regexp(result,'\n','split'));
  cmd_printed = false;
  for pid_idx = 1:length(pids)
    pid = pids(pid_idx);
    if ~isnan(pid)
      if ~isempty(process_list)
        % Override
        cmd = sprintf('taskset -cp %s %d >/dev/null 2>&1', process_list, pid);
      else
        cmd = sprintf('taskset -cp %s %d >/dev/null 2>&1', process_str, pid);
      end
      if ~cmd_printed
        fprintf('%s\n', cmd);
        cmd_printed = true;
      end
      system(cmd);
    end
  end
  
catch ME
  warning(ME.getReport);
end
