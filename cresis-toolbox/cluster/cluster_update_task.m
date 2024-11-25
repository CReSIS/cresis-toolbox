function ctrl = cluster_update_task(ctrl,task_id,update_mode)
% ctrl = cluster_update_task(ctrl,task_id,update_mode)
%
% Updates a specific task's status. Support function for cluster_job_status.
%
% Inputs:
% ctrl: ctrl structure returned from cluster_new_batch
%  .job_id_list = Nx1 vector of cluster job IDs
%  .job_status = Nx1 vector of job status
%  .out_fn_dir = string containing the output directory
%  .error_mask = Nx1 vector of error status
%  .out = up-to-Nx1 vector of cells containing the outputs for each
%    job as they complete (read in from the output.mat files)
% job_id: the job id to check up on
% update_mode: scalar integer (-1, 0, 1, or 2). Default is 1.
%   -1: populates cpu_time and like fields and returns without checking
%   ==0: is not subject to cluster_hold
%   >0: check stdout/stderr
%   >0: print error information
%   >0: cpu time and memory warnings
%   >0: retry failed jobs
%
% Outputs:
% ctrl = updated ctrl structure
%
% C -  Job is completed after having run.
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

if ~exist('update_mode','var') || isempty(update_mode)
  update_mode = 1;
end

% Create in/out filenames
static_in_fn = fullfile(ctrl.in_fn_dir,'static.mat');
dynamic_in_fn = fullfile(ctrl.in_fn_dir,'dynamic.mat');
out_fn = fullfile(ctrl.out_fn_dir,sprintf('out_%d.mat',task_id));

% Read input
sparam = load(static_in_fn);
if ~isfield(ctrl,'dparam') || numel(ctrl.dparam) < task_id || isempty(ctrl.dparam{task_id})
  tmp = load(dynamic_in_fn);
  ctrl.dparam = tmp.dparam;
end
param = merge_structs(sparam.static_param,ctrl.dparam{task_id});

ctrl.notes{task_id} = param.notes;
if ctrl.cpu_time(task_id) == 0
  ctrl.cpu_time(task_id) = param.cpu_time;
end
if ctrl.mem(task_id) == 0
  ctrl.mem(task_id) = param.mem;
end
ctrl.success{task_id} = param.success;
% HACK
if ~isfield(param,'file_success')
  param.file_success = {};
end
% END HACK
ctrl.file_success{task_id} = param.file_success;

cluster_error_mask; % Loads all the error masks

error_mask = 0;

if update_mode < 0
  return;
end
if update_mode > 0 && exist(ctrl.hold_fn,'file')
  fprintf('This batch has a hold. Run <strong>cluster_hold(ctrl)</strong> to remove. Either way, run <strong>dbcont</strong> to continue.\n');
  keyboard
end

% Get the job ID
job_id = ctrl.job_id_list(task_id);

% Get the task ID that the job ID is writing to
task_id_out = find(ctrl.job_id_list == job_id,1,'last');

hostname = '';
attempt = -1;
max_attempts = -1;
max_mem = -1;
last_task_id = -1;
if any(strcmpi(ctrl.cluster.type,{'torque','slurm'}))
  % Extract information from stdout
  stdout_fn = fullfile(ctrl.stdout_fn_dir,sprintf('stdout_%d.txt',task_id_out));
  if exist(stdout_fn,'file')
    stdout_file_str = '';
    try
      fid = fopen(stdout_fn);
      stdout_file_str = fread(fid,inf,'char=>char');
      stdout_file_str = stdout_file_str(:).';
      fclose(fid);
    end
    
    % Find the hostname of the execution node
    try
      idx = regexp(stdout_file_str,'hostname:');
      end_idx = idx+9 + find(stdout_file_str(idx+9:end)==' ',1)-1;
      hostname = stdout_file_str(idx+9:end_idx-1);
    end
    
    % Find the number of attempts to start the job
    try
      idx = regexp(stdout_file_str,'Attempt ');
      attempt = sscanf(stdout_file_str(idx+8:end),'%d');
    end
    if isempty(attempt)
      attempt = -1;
    end
    
    % Find the allowed maximum number of attempts to start the job
    try
      idx = regexp(stdout_file_str,'max_attempts:');
      max_attempts = sscanf(stdout_file_str(idx+13:end),'%d');
    end
    if isempty(max_attempts)
      max_attempts = -1;
    end
    
    % Find the last task that this job started
    try
      search_str = 'cluster_job: Load task ';
      idxs = regexp(stdout_file_str,search_str);
      if ~isempty(idxs)
        % Look at the task ID from the last start message
        last_task_id = sscanf(stdout_file_str(idxs(end)+length(search_str):end),'%d');
      end
    end
  end
  if isempty(last_task_id)
    last_task_id = -1;
  end
  
  % Find the maximum memory used
  try
    idxs = regexp(stdout_file_str,'Max Mem \(KB\):');
    while ~isempty(idxs)
      max_mem = max(max_mem,sscanf(stdout_file_str(idxs(1)+13:end),'%d') * 1024);
      idxs = idxs(2:end);
    end
    if max_mem > 0.9*ctrl.mem(task_id)*ctrl.cluster.mem_mult
      error_mask = bitor(error_mask,max_mem_exceeded_error);
    end
  end
  if isempty(max_mem)
    max_mem = -1;
  end
  
  % Check to see if there is insufficient space
  try
    idx = regexp(stdout_file_str,'Insufficient space on MCR_CACHE_ROOT:');
    if ~isempty(idx)
      error_mask = bitor(error_mask,insufficient_mcr_space);
    end
  end
  
  % If the last task started is the task that is getting updated, then
  % check to see if that task was killed during execution.
  error_fn = fullfile(ctrl.error_fn_dir,sprintf('error_%d.txt',task_id_out));
  if last_task_id == task_id && exist(error_fn,'file')
    try
      fid = fopen(error_fn);
      error_file_str = fread(fid,inf,'char=>char');
      error_file_str = error_file_str(:).';
      fclose(fid);
      if ~isempty(regexp(error_file_str,'PBS: job killed:'))
        error_mask = bitor(error_mask,cluster_killed_error);
      end
      if ~isempty(regexp(error_file_str,'PBS: job killed: walltime'))
        error_mask = bitor(error_mask,walltime_exceeded_error);
      end
      % slurmstepd: error: *** JOB 15269436 ON prod-0105 CANCELLED AT 2022-05-15T23:32:22 DUE TO TIME LIMIT ***
      if ~isempty(regexp(error_file_str,'CANCELLED'))
        error_mask = bitor(error_mask,cluster_killed_error);
      end
      if ~isempty(regexp(error_file_str,'DUE TO TIME LIMIT'))
        error_mask = bitor(error_mask,walltime_exceeded_error);
      end
    end
  end
end

if update_mode && strcmpi(ctrl.cluster.type,'matlab') && ctrl.job_status(task_id) == 'C'
  stdout_fn = fullfile(ctrl.stdout_fn_dir,sprintf('stdout_%d.txt',task_id_out));
  error_fn = fullfile(ctrl.error_fn_dir,sprintf('error_%d.txt',task_id_out));
  
  if ~exist(error_fn,'file')
    fid = fopen(error_fn,'w');
    try
      str = evalc(sprintf('ctrl.cluster.jm.Jobs.findobj(''ID'',%d).Tasks(1)',job_id));
      fwrite(fid,str,'char');
    end
    fclose(fid);
  end
  
  if ~exist(stdout_fn,'file')
    fid = fopen(stdout_fn,'w');
    try
      fwrite(fid,ctrl.cluster.jm.Jobs.findobj('ID',job_id).Tasks(1).Diary,'char');
    end
    fclose(fid);
  end
end

if exist(out_fn,'file')
  success = robust_cmd('out = load(out_fn);',2);
  if ~success
    out = [];
    error_mask = bitor(error_mask,out_fn_load_error);
  end
else
  out = [];
  error_mask = bitor(error_mask,out_fn_exist_error);
end

if isfield(out,'argsout')
  if length(out.argsout) ~= param.num_args_out
    error_mask = bitor(error_mask,argsout_length_error);
  end
else
  error_mask = bitor(error_mask,argsout_exist_error);
end

if isfield(out,'errorstruct')
  if ~isempty(out.errorstruct)
    if regexp(out.errorstruct.message,'Out of memory')
      % Warning: Out of memory. Type "help memory" for your options.
      error_mask = bitor(error_mask,max_mem_exceeded_error);
      error_mask = bitor(error_mask,matlab_task_out_of_memory);
    else
      error_mask = bitor(error_mask,errorstruct_contains_error);
    end
  end
else
  error_mask = bitor(error_mask,errorstruct_exist_error);
end

if isfield(out,'cpu_time_actual')
  ctrl.cpu_time_actual(task_id) = out.cpu_time_actual;
else
  ctrl.cpu_time_actual(task_id) = -1;
end

% Check success criteria
try
  eval(param.success); % Runs some form of "error_mask = bitor(error_mask,success_error);" on failure
catch success_eval_ME
  error_mask = bitor(error_mask,success_eval_error);
end

% Check that all output files are successfully generated
error_mask = bitor(error_mask,cluster_file_success(param.file_success));

ctrl.error_mask(task_id) = 0;
if ctrl.job_status(task_id) == 'T'
  % This job was not found in the cluster: if output exists, then assume it
  % is 'C' and update error_mask based on output files. Otherwise, assume
  % it has not been submitted yet.
  if ~bitand(error_mask,out_fn_exist_error)
    ctrl.submission_queue = ctrl.submission_queue(ctrl.submission_queue~=task_id);
    ctrl.job_status(task_id) = 'C';
    ctrl.error_mask(task_id) = error_mask;
  end
  
elseif ctrl.job_status(task_id) == 'C'
  % This job was found on the cluster and was completed: update error
  % flag based on output files. Make sure this job is not in the submission
  % queue.
  ctrl.submission_queue = ctrl.submission_queue(ctrl.submission_queue~=task_id);
  ctrl.error_mask(task_id) = error_mask;
  
else
  % This job was found in the cluster: if output exists, then assume it
  % is 'C' and update error_mask based on output files. Make sure this job
  % is not in the submission queue.
  ctrl.submission_queue = ctrl.submission_queue(ctrl.submission_queue~=task_id);
  if ~bitand(error_mask,out_fn_exist_error)
    ctrl.job_status(task_id) = 'C';
    ctrl.error_mask(task_id) = error_mask;
  end
  
end

if update_mode && ctrl.error_mask(task_id)
  fprintf('%s\n','='*ones(1,80));
  warning(' Job Error %d:%d/%d (lead task %d) (%s)\n', ctrl.batch_id, task_id, job_id, task_id_out, datestr(now));
  if any(strcmpi(ctrl.cluster.type,{'torque','slurm'}))
    fprintf('   hostname:%s attempt:%d max_attempts:%d\n', hostname, attempt, max_attempts);
  end
  if bitand(ctrl.error_mask(task_id),out_fn_exist_error)
    fprintf('  Output file does not exist: %s\n', out_fn);
  end
  if bitand(ctrl.error_mask(task_id),out_fn_load_error)
    fprintf('  Output file exists, but failed to load: %s\n', out_fn);
  end
  if bitand(ctrl.error_mask(task_id),argsout_exist_error)
    fprintf('  argsout does not exist in output file: %s\n', out_fn);
  end
  if bitand(ctrl.error_mask(task_id),argsout_length_error)
    fprintf('  argsout is the wrong length in the output file: %s\n', out_fn);
  end
  if bitand(ctrl.error_mask(task_id),errorstruct_exist_error)
    fprintf('  errorstruct does not exist in output file: %s\n', out_fn);
  end
  if bitand(ctrl.error_mask(task_id),errorstruct_contains_error)
    fprintf('  errorstruct contains an error:\n');
    warning('%s',out.errorstruct.getReport);
    if ctrl.cluster.stop_on_error
      fprintf('\nctrl.cluster.stop_on_error is enabled which causes the cluster running process to stop whenever there is a Matlab coding error. To disable this for this batch, you can run "ctrl.cluster.stop_on_error=false". Fix the coding bug printed above which might require running cluster_compile.m if you change cluster task code and then run "dbcont". You may also run "cluster_run_mode=-1" to stop cluster_run.m in a clean way (it will complete updating this branch and then exit). You can test the function by running "cluster_exec_task(ctrl,task_id);". If the task completes successfully, then the error mask can be set to zero by running "ctrl.error_mask(task_id)=0;".\n');
      keyboard
    end
  end
  if bitand(ctrl.error_mask(task_id),max_mem_exceeded_error)
    fprintf('  Max memory potentially exceeded\n');
    fprintf('    Job max_mem used is %.1f GB\n', max_mem/1e9);
    fprintf('    Task id %d:%d\n', ctrl.batch_id, task_id);
    fprintf('    Task memory requested %.1f*%.1f = %.1f GB\n', ctrl.mem(task_id)/1e9, ctrl.cluster.mem_mult, ctrl.mem(task_id)*ctrl.cluster.mem_mult/1e9);
    fprintf('    Job''s last executed task id %d\n', last_task_id);
  end
  if bitand(ctrl.error_mask(task_id),matlab_task_out_of_memory) ...
    || bitand(ctrl.error_mask(task_id),max_mem_exceeded_error) && task_id == last_task_id
    fprintf('  Task max memory exceeded.\n');
    if ~isempty(regexpi(ctrl.cluster.mem_mult_mode,'debug'))
      ctrl.cluster.mem_mult_mode
      fprintf('  task memory (%.1f GB) exceeded the maximum memory requested (%.1f*%.1f = %.1f GB):\n', max_mem/1e9, ctrl.mem(task_id)/1e9, ctrl.cluster.mem_mult, ctrl.mem(task_id)*ctrl.cluster.mem_mult/1e9);
      fprintf('%s\n',ones(1,80)*'=');
      fprintf('Options:\n');
      fprintf('  1. Increase ctrl.mem(task_id) or ctrl.cluster.mem_mult\n');
      fprintf('  2. Run job locally by running cluster_exec_task(ctrl,task_id);\n');
      fprintf('     Be sure to run ctrl.error_mask(task_id) = 0 after successfully\n');
      fprintf('     running task.\n');
      fprintf('  3. Set ctrl.cluster.mem_mult_mode = ''auto''; to automatically increase the memory requested.\n');
      fprintf('After making changes, run dbcont to continue.\n');
      keyboard
    end
    if ~isempty(regexpi(ctrl.cluster.mem_mult_mode,'auto'))
      fprintf('    Automatically 1.5x the memory request for this task.\n');
      ctrl.mem(task_id) = max(max_mem/ctrl.cluster.mem_mult,ctrl.mem(task_id))*1.5;
    end
  end
  if bitand(ctrl.error_mask(task_id),insufficient_mcr_space)
    fprintf('  Insufficient space in MCR_CACHE_ROOT\n');
  end
  if bitand(ctrl.error_mask(task_id),success_error)
    fprintf('  Task did not pass success criteria\n');
  end
  if bitand(ctrl.error_mask(task_id),success_eval_error)
    fprintf('  Task success condition failed to evaluate: %s\n', success_eval_ME.getReport);
  end
  if bitand(ctrl.error_mask(task_id),cluster_killed_error)
    fprintf('  Cluster killed this job. The cause is not known.\n');
  end
  if bitand(ctrl.error_mask(task_id),walltime_exceeded_error)
    fprintf('  Cluster killed this job due to wall time. This means the job requested too little cpu time. cluster.cpu_time_mult should be increased.\n');
    fprintf('    Automatically doubling wall time request for this task.\n');
    ctrl.cpu_time(task_id) = ctrl.cpu_time(task_id)*2/ctrl.cluster.cpu_time_mult;
  end
  if bitand(ctrl.error_mask(task_id),file_success_error)
    fprintf('  File success check failed (missing files)\n');
  end
  if bitand(ctrl.error_mask(task_id),file_success_corrupt_error)
    fprintf('  File success check failed (corrupt files)\n');
  end
end

if update_mode && ctrl.error_mask(task_id) && ~bitand(ctrl.error_mask(task_id),critical_error)
  fprintf('    Since no critical errors occured, setting error mask to 0.\n');
  ctrl.error_mask(task_id) = 0;
end

if update_mode
  if ctrl.cluster.cpu_time_mult*ctrl.cpu_time(task_id)*0.9 < ctrl.cpu_time_actual(task_id)
    warning(' %d:%d/%d: CPU time actual (%.0f sec) is more than 90%% of estimated time (%.0f sec). Consider revising estimates. (%s)', ...
      ctrl.batch_id, task_id, job_id, ctrl.cpu_time_actual(task_id), ctrl.cluster.cpu_time_mult*ctrl.cpu_time(task_id), datestr(now));
  elseif ctrl.cpu_time_actual(task_id)>0 && ctrl.cluster.cpu_time_mult*ctrl.cpu_time(task_id)*0.2 > ctrl.cpu_time_actual(task_id)
    warning(' %d:%d/%d: CPU time actual (%.0f sec) is less than 20%% of estimated time (%.0f sec). Consider revising estimates. (%s)', ...
      ctrl.batch_id, task_id, job_id, ctrl.cpu_time_actual(task_id), ctrl.cluster.cpu_time_mult*ctrl.cpu_time(task_id), datestr(now));
  end
end

if update_mode && ctrl.job_status(task_id) == 'C' && ctrl.error_mask(task_id)
  % Job is completed and has an error
  
  % Copy stdout and error files
  if any(strcmpi(ctrl.cluster.type,{'torque','slurm'}))
    stdout_fn = fullfile(ctrl.stdout_fn_dir,sprintf('stdout_%d.txt',task_id_out));
    error_fn = fullfile(ctrl.error_fn_dir,sprintf('error_%d.txt',task_id_out));
    retry_stdout_fn = fullfile(ctrl.stdout_fn_dir,sprintf('stdout_%d_%d.txt',task_id, ctrl.retries(task_id)));
    retry_error_fn = fullfile(ctrl.error_fn_dir,sprintf('error_%d_%d.txt',task_id, ctrl.retries(task_id)));
    if exist(stdout_fn,'file')
      copyfile(stdout_fn,retry_stdout_fn);
    end
    if exist(error_fn,'file')
      copyfile(error_fn,retry_error_fn);
    end
  end
  
  if ctrl.retries(task_id) < ctrl.cluster.max_retries
    if ~bitand(ctrl.error_mask(task_id),out_fn_exist_error)
      delete(out_fn);
    end
    
    % Update task to ctrl structure
    ctrl.submission_queue = cat(2,ctrl.submission_queue,task_id);
    new_job_status = 'T';
    new_job_id = -1;
    ctrl.job_id_list(task_id) = new_job_id;
    ctrl.job_status(task_id) = new_job_status;
    
    % Update job IDs in job ID file
    fid = fopen(ctrl.job_id_fn,'r+');
    fseek(fid, 21*(task_id-1), -1);
    fprintf(fid,'%-20d\n', new_job_id);
    fclose(fid);
    
    if any(strcmpi(ctrl.cluster.type,{'torque','slurm'})) ...
        && last_task_id ~= -1 && task_id ~= last_task_id && ~exist(out_fn,'file')
      % Job failed but last_task_id (the task that the job failed on) is
      % not this task and so
    else
      ctrl.retries(task_id) = ctrl.retries(task_id) + 1;
    end
    
    % If there are no more tasks using the output files, then delete them
    % so that the new retry files start with a blank file.
    if any(strcmpi(ctrl.cluster.type,{'torque','slurm'}))
      if ~any(ctrl.job_id_list == job_id)
        if exist(stdout_fn,'file')
          delete(stdout_fn);
        end
        if exist(error_fn,'file')
          delete(error_fn);
        end
      end
    end
    
    % Print out retry message
    fprintf(' Retry %d Job %d:%d/%d %s (%s)\n', ctrl.retries(task_id), ctrl.batch_id, task_id, ctrl.job_id_list(task_id), param.notes, datestr(now));
  else
    fprintf(' Out of retries %d Job %d:%d/%d %s (%s)\n', ctrl.retries(task_id), ctrl.batch_id, task_id, ctrl.job_id_list(task_id), param.notes, datestr(now));
  end

end
