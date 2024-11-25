function [ctrl,new_job_id] = cluster_submit_job(ctrl,job_tasks,job_cpu_time,job_mem)
% [ctrl,new_job_id] = cluster_submit_job(ctrl,job_tasks,job_cpu_time,job_mem)
%
% Creates a new job. Calls to this function need to be proceeded by
% a single call to cluster_new_batch.m.
%
% Inputs:
% ctrl = ctrl structure returned from cluster_new_batch
%  .cluster = cluster parameters structure
%   .worker_fn = path to worker
%   .submit_arguments = submission arguments to add to qsub (-v currently
%     not supported)
%  .in_fn_dir = input arguments directory
%  .out_fn_dir = output arguments directory
%  .stdout_fn_dir = standard output directory
%  .error_fn_dir = error directory
%
% Outputs:
% ctrl = updated ctrl structure with new job
% job_id = ID of job (starts counting from one and never repeats)
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

%% Create the temporary file names
in_fn = ctrl.in_fn_dir;
out_fn = ctrl.out_fn_dir;
job_tasks = sort(job_tasks); % Sort tasks by ID (largest ID is last)
task_id_max = job_tasks(end); % Use max task ID for the stdout and error files
% There can be multiple task IDs associated with this job
stdout_fn = fullfile(ctrl.stdout_fn_dir,sprintf('stdout_%d.txt',task_id_max));
error_fn = fullfile(ctrl.error_fn_dir,sprintf('error_%d.txt',task_id_max));

new_job_status = 'Q';

task_list_str = sprintf('%dd',job_tasks); task_list_str = task_list_str(1:end-1);

%% Submit the job
% =========================================================================
if strcmpi(ctrl.cluster.type,'torque')
  %% Run the qsub command
  worker = ctrl.cluster.cluster_job_fn;
  [cluster_job_fn_dir worker_name] = fileparts(worker);
  
  submit_arguments = ctrl.cluster.qsub_submit_arguments;
  match_idxs = regexp(submit_arguments,'%d');
  if ~isempty(match_idxs)
    error('Using deprecated ''%%d'' inside cluster.qsub_submit_arguments. Switch to %%m for memory, %%t for time, and %%p for number of processors. For example ''-m n -l nodes=1:ppn=%%p,pmem=%%m,walltime=%%t''. Current value is ''%s''.', submit_arguments);
  end
  if ~isempty(ctrl.cluster.ppn_fixed)
    % Option to give all jobs the same number of processors
    num_proc = ctrl.cluster.ppn_fixed;
  elseif ~isempty(ctrl.cluster.mem_to_ppn)
    % If ppn should be used to limit memory OR if memory requirements are
    % high enough that we might as well ask for more nodes too to prevent
    % nodes from sitting idle.
    num_proc = max(1,ceil(job_mem/ctrl.cluster.mem_to_ppn));
    num_proc = min(ctrl.cluster.max_ppn,num_proc);
  else
    num_proc = 1;
  end
  % Insert memory
  submit_arguments = regexprep(submit_arguments,'%m',sprintf('%.0fmb',ceil(job_mem/num_proc/1e6)));
  % Insert CPU time
  submit_arguments = regexprep(submit_arguments,'%t',sprintf('%.0f:00',ceil(job_cpu_time/60)));
  % Insert number of processors
  submit_arguments = regexprep(submit_arguments,'%p',sprintf('%.0f',num_proc));
  
  % Add "qsub -m abe -M your@email.edu" to debug:
  if ctrl.cluster.interactive
    cmd = sprintf('qsub -I %s -e %s -o %s -v INPUT_PATH="%s",OUTPUT_PATH="%s",TASK_LIST=''%s'',MATLAB_CLUSTER_PATH="%s",MATLAB_MCR_PATH="%s",NUM_PROC="%d",JOB_COMPLETE_PAUSE="%d"', ...
      submit_arguments, error_fn, stdout_fn, in_fn, out_fn, task_list_str, cluster_job_fn_dir, ctrl.cluster.matlab_mcr_path, num_proc, ctrl.cluster.job_complete_pause);
    fprintf('1. Run the command from the bash shell:\n  %s\n', cmd);
    fprintf('2. Once the interactive mode starts, run the command in the interactive shell:  %s\n', worker);
    fprintf('3. Once the job completes, exit the interactive shell which causes torque to realize the job is complete.\n');
    fprintf('4. In Matlab, set new_job_id to the torque job ID that you get from qsub. For example "2466505.m2" would need to have "new_job_id = 2466505" run.\n');
    fprintf('5. Once the job finishes, run "dbcont" in Matlab.\n');
    while ~exist('new_job_id','var')
      keyboard
    end
  else
    if isempty(ctrl.cluster.ssh_hostname)
      cmd = sprintf('qsub %s -e %s -o %s -v INPUT_PATH="%s",OUTPUT_PATH="%s",TASK_LIST=''%s'',MATLAB_CLUSTER_PATH="%s",MATLAB_MCR_PATH="%s",NUM_PROC="%d",JOB_COMPLETE_PAUSE="%d" %s  </dev/null', ...
        submit_arguments, error_fn, stdout_fn, in_fn, out_fn, task_list_str, cluster_job_fn_dir, ctrl.cluster.matlab_mcr_path, num_proc, ctrl.cluster.job_complete_pause, worker);
    else
      cmd = sprintf('ssh -p %d -o LogLevel=QUIET -t %s@%s "qsub %s -e %s -o %s -v INPUT_PATH=\"%s\",OUTPUT_PATH=\"%s\",TASK_LIST=''%s'',MATLAB_CLUSTER_PATH=\"%s\",MATLAB_MCR_PATH=\"%s\",NUM_PROC=\"%d\",JOB_COMPLETE_PAUSE=\"%d\" %s  </dev/null"', ...
        ctrl.cluster.ssh_port, ctrl.cluster.ssh_user_name, ctrl.cluster.ssh_hostname, submit_arguments, error_fn, stdout_fn, in_fn, out_fn, task_list_str, cluster_job_fn_dir, ctrl.cluster.matlab_mcr_path, num_proc, ctrl.cluster.job_complete_pause, worker);
    end
    
    [status,result] = robust_system(cmd);
    
    [job_id_str,result_tok] = strtok(result,'.');
    try
      new_job_id = str2double(job_id_str);
      if isnan(new_job_id)
        job_id_str
        warning('job_id_str expected numeric, but is not');
        keyboard;
      end
    catch
      job_id_str
      warning('job_id_str expected numeric, but is not');
      keyboard;
    end
  end
  ctrl.active_jobs = ctrl.active_jobs + 1;
  
elseif strcmpi(ctrl.cluster.type,'matlab')
  %% Create the job on the matlab cluster/job manager
  new_job = createJob(ctrl.cluster.jm);
  new_job_id = new_job.ID;
  task = createTask(new_job,@cluster_job,0,{in_fn,out_fn,task_list_str},'CaptureDiary',true);
  ctrl.active_jobs = ctrl.active_jobs + 1;
  while ~strcmpi(task.State,'pending')
    warning('%s: pausing because task is not in pending state.', mfilename);
    pause(1);
  end
  submit(new_job);
 
elseif strcmpi(ctrl.cluster.type,'slurm')
  worker = ctrl.cluster.cluster_job_fn;
  [cluster_job_fn_dir worker_name] = fileparts(worker);
  
  submit_arguments = sprintf(ctrl.cluster.slurm_submit_arguments,ceil(job_mem/1e6),ceil(job_cpu_time/60));
  
  submit_arguments = ctrl.cluster.slurm_submit_arguments;
  match_idxs = regexp(submit_arguments,'%d');
  if ~isempty(match_idxs)
    error('Using deprecated ''%%d'' inside cluster.slurm_submit_arguments. Switch to %%m for memory and %%t for time. For example ''-N 1 -n 1 --mem=%m --time=%t''. Current value is ''%s''.', submit_arguments);
  end
  if ~isempty(ctrl.cluster.ppn_fixed)
    % Option to give all jobs the same number of processors
    num_proc = ctrl.cluster.ppn_fixed;
  elseif ~isempty(ctrl.cluster.mem_to_ppn)
    % If ppn should be used to limit memory OR if memory requirements are
    % high enough that we might as well ask for more nodes too to prevent
    % nodes from sitting idle.
    num_proc = max(1,ceil(job_mem/ctrl.cluster.mem_to_ppn));
    num_proc = min(ctrl.cluster.max_ppn,num_proc);
  else
    num_proc = 1;
  end
  % Insert memory
  submit_arguments = regexprep(submit_arguments,'%m',sprintf('%.0f',ceil(job_mem/1e6)));
  % Insert CPU time
  submit_arguments = regexprep(submit_arguments,'%t',sprintf('%.0f',ceil(job_cpu_time/60)));  
  % Insert number of processors
  submit_arguments = regexprep(submit_arguments,'%p',sprintf('%.0f',num_proc));  
  
  if isempty(ctrl.cluster.ssh_hostname)
    cmd = sprintf('sbatch %s -e %s -o %s --export=INPUT_PATH="%s",OUTPUT_PATH="%s",TASK_LIST="%s",MATLAB_CLUSTER_PATH="%s",MATLAB_MCR_PATH="%s",JOB_COMPLETE_PAUSE="%d" %s </dev/null', ...
      submit_arguments, error_fn, stdout_fn, in_fn, out_fn, task_list_str, cluster_job_fn_dir, ctrl.cluster.matlab_mcr_path, ctrl.cluster.job_complete_pause, worker);
  else
    cmd = sprintf('ssh -p %d -o LogLevel=QUIET -t %s@%s "sbatch %s -e %s -o %s --export=INPUT_PATH=\"%s\",OUTPUT_PATH=\"%s\",TASK_LIST=\"%s\",MATLAB_CLUSTER_PATH=\"%s\",MATLAB_MCR_PATH=\"%s\",JOB_COMPLETE_PAUSE=\"%d\" %s </dev/null"', ...
      ctrl.cluster.ssh_port, ctrl.cluster.ssh_user_name, ctrl.cluster.ssh_hostname, submit_arguments, error_fn, stdout_fn, in_fn, out_fn, task_list_str, cluster_job_fn_dir, ctrl.cluster.matlab_mcr_path, ctrl.cluster.job_complete_pause, worker);
  end
  
  [status,result] = robust_system(cmd);
  ctrl.active_jobs = ctrl.active_jobs + 1;
  
  search_str = 'Submitted batch job ';
  job_id_str = regexp(result,search_str);
  try
    new_job_id = sscanf(result(job_id_str(1)+length(search_str):end),'%d');
    if isnan(new_job_id)
      job_id_str
      warning('job_id_str expected numeric, but is not');
      keyboard;
    end
  catch
    job_id_str
    warning('job_id_str expected numeric, but is not');
    keyboard;
  end
    
elseif strcmpi(ctrl.cluster.type,'debug')
  %% Run the command now
  new_job_id = job_tasks(end);
  
  if ~isfield(ctrl.cluster,'run_mode')
    ctrl.cluster.run_mode = [];
  end
  cluster_exec_task(ctrl,job_tasks,ctrl.cluster.run_mode);
else
  error('Invalid cluster type %s.', ctrl.cluster.type);
end

%% Update job IDs in job ID file
fid = fopen(ctrl.job_id_fn,'r+');
for task_idx = 1:length(job_tasks)
  task_id = job_tasks(task_idx);
  fseek(fid, 21*(task_id-1), -1);
  fprintf(fid,'%-20d\n', new_job_id);
  ctrl.job_id_list(task_id) = new_job_id;
  ctrl.job_status(task_id) = 'Q';
  ctrl.error_mask(task_id) = 0;
end
fclose(fid);

end
