function [ctrl_chain,cluster_run_mode] = cluster_run(ctrl_chain,cluster_run_mode)
% ctrl_chain = cluster_run(ctrl_chain,cluster_run_mode)
%
% Submits jobs in a list of batch chains. Each chain in the list runs in
% parallel. Batches within a chain are run in series.
%
% Inputs:
% ctrl_chain: cell array of chains that can be run in parallel
%  ctrl_chain{chain}: cell array of batches that must be run in series (stages)
%   ctrl_chain{chain}{stage}: control structure for a batch
% cluster_run_mode: integer specifying the mode to run tasks. Possible
%   modes are:
%   0: Non-blocking mode. Use this mode when the ctrl_chain structure
%     properly represents which tasks have completed successfully.
%   1: Blocking mode. Same as 0 except continuously polls tasks until all
%     chains are finished. Default mode.
%   2: Non-block mode. Use this mode when the ctrl_chain structure does not
%     represent which tasks have completed successfully. cluster_run will
%     check every task in a chain before starting to run the chain.
%   3: Block mode. Same as 2 except continuously polls tasks until all
%     chains are finished.
%
% Outputs:
% ctrl_chain: updated list of batch chains that was passed in
%
% Example:
% % If there is just one control structure to run called ctrl
% ctrl_chain = {{ctrl}};
% ctrl_chain = cluster_run(ctrl_chain);
%
% % Let ctrl1 be in chain 1, let ctrl2a and ctrl2b be in chain 2
% ctrl_chain = {{ctrl1},{ctrl2a,ctrl2b}};
% ctrl_chain = cluster_run(ctrl_chain);
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

%% Input checking
if ~exist('cluster_run_mode','var') || isempty(cluster_run_mode)
  cluster_run_mode = 1;
end
if cluster_run_mode < 0
  return;
end

if isnumeric(ctrl_chain)
  ctrl_chain = cluster_load_chain(ctrl_chain);
end

if iscell(ctrl_chain)
  %% Traverse chain list
  global gctrl_chain;
  gctrl_chain = ctrl_chain;
  active_stage = ones(numel(ctrl_chain),1);
  first_run = ones(numel(ctrl_chain),1);
  while any(isfinite(active_stage))
    active_stage_update = false;
    for chain = 1:numel(ctrl_chain)
      if isempty(ctrl_chain{chain})
        % No batches in this chain
        active_stage(chain) = inf;
        continue;
      end
      if isfinite(active_stage(chain))
        % 1. There is at least one batch left to run in this chain
        ctrl = ctrl_chain{chain}{active_stage(chain)};
        
        % 2. If this is the first loop of cluster_run, force a complete
        %   update of the job status information.
        if first_run(chain)
          if cluster_run_mode < 2
            ctrl = cluster_get_batch(ctrl,[],2);
          else
            ctrl = cluster_get_batch(ctrl);
          end
          first_run(chain) = false;
        else
          ctrl = cluster_update_batch(ctrl);
          pause(ctrl.cluster.stat_pause);
        end
        
        % 3. Update ctrl_chain
        ctrl_chain{chain}{active_stage(chain)} = ctrl;
        gctrl_chain = ctrl_chain;
        
        % 4. Submit jobs from the active stage for each parallel control structure
        %   ctrl.max_active_jobs.
        [ctrl,cluster_run_mode] = cluster_run(ctrl,cluster_run_mode);
        
        % 5. Update ctrl_chain
        ctrl_chain{chain}{active_stage(chain)} = ctrl;
        gctrl_chain = ctrl_chain;
        
        % 6. If all jobs completed in a batch and:
        %    If no errors, move to the next stage
        %    If errors, stop chain
        %    Note: cluster_update_task guarantees that a task that still has retries left will never have 'C' status if it had errors
        if all(ctrl.job_status=='C')
          if ~any(ctrl.error_mask)
            % Advance to the next stage
            fprintf('Chain %d succeeded on stage %d.\n', chain, active_stage(chain));
            active_stage(chain) = active_stage(chain) + 1;
            first_run(chain) = true;
            if active_stage(chain) > numel(ctrl_chain{chain})
              % Chain is complete (no more stages/batches to complete)
              active_stage(chain) = inf;
            else
              % Chain is not complete
              active_stage_update = true;
            end
          else
            % Stop chain
            warning('Chain %d failed on stage %d.', chain, active_stage(chain));
            active_stage(chain) = -inf;
          end
        end
        
        % 7. Check to see if a hold has been placed on this batch
        if cluster_run_mode >= 0 && exist(ctrl.hold_fn,'file')
          warning('This batch has a hold. Run cluster_hold(ctrl) to remove. Run "cluster_run_mode=-1" to stop cluster_run.m now in a clean way. Either way, run dbcont to continue.\n');
          keyboard
        end
      end
      if cluster_run_mode < 0
        break;
      end
    end
    % Check if in a block mode or not. If a stage finished and still has
    % more stages to complete, then do not exit yet since we should start
    % the next stage running first.
    if cluster_run_mode < 0 || (~active_stage_update && (cluster_run_mode == 0 || cluster_run_mode == 2))
      break;
    end
  end

  for chain=1:numel(ctrl_chain)
    if active_stage(chain) == inf
      fprintf('Chain %d succeeded (%s)\n', chain, datestr(now));
    else
      fprintf('Chain %d not finished or failed (%s)\n', chain, datestr(now));
      for stage=1:numel(ctrl_chain{chain})
        ctrl = ctrl_chain{chain}{stage};
        if all(ctrl.job_status=='C')
          if all(ctrl.error_mask==0)
            fprintf('  Stage %d succeeded\n', stage);
          else any(ctrl.error_mask)
            fprintf('  Stage %d (batch %d) failed (%d of %d tasks failed)\n', stage, ctrl.batch_id, sum(ctrl.error_mask~=0), length(ctrl.error_mask));
          end
        else
          fprintf('  Stage %d not finished\n', stage);
        end
      end
    end
  end
  
elseif isstruct(ctrl_chain)
  ctrl = ctrl_chain;
  
  if strcmpi(ctrl.cluster.type,'none')
    return;
  end
  
  % Ensure that submission_queue and job_status=='T' match
  if ~isempty(setxor(ctrl.submission_queue,find(ctrl.job_status=='T')))
    warning('submission_queue and job_status are not in sync. Resyncing.')
    ctrl.submission_queue = find(ctrl.job_status=='T');
  end
  
  % Sort submission queue tasks based on memory usage: this is done to
  % increase the chance that tasks with similar memory usage will be
  % grouped together in jobs to make the cluster memory request more
  % efficient.
  [~,sort_idxs] = sort(ctrl.mem(ctrl.submission_queue));
  ctrl.submission_queue = ctrl.submission_queue(sort_idxs);
  
  job_tasks = [];
  job_cpu_time = 0;
  job_mem = 0;
  while ~isempty(ctrl.submission_queue) && ctrl.active_jobs < ctrl.cluster.max_jobs_active
    % Get task from queue
    task_id = ctrl.submission_queue(1);
    task_cpu_time = 30 + ctrl.cluster.cpu_time_mult*ctrl.cpu_time(task_id); % 30 sec to match cluster_run.sh end pause
    task_mem = ctrl.cluster.mem_mult*ctrl.mem(task_id);

    if ctrl.cluster.max_time_per_job < task_cpu_time
      warning('ctrl.cluster.max_time_per_job (%.0f sec) is less than task %d:%d''s requested time: %.0f sec. You may override "ctrl.cluster.max_time_per_job" or "task_cpu_time" and then run "dbcont" to continue submission.', ...
        ctrl.cluster.max_time_per_job, ctrl.batch_id, task_id, task_cpu_time);
      keyboard;
    end
    if ctrl.cluster.desired_time_per_job < job_cpu_time + task_cpu_time && ~isempty(job_tasks)
      [ctrl,new_job_id] = cluster_submit_job(ctrl,job_tasks,job_cpu_time,job_mem);
      fprintf('Submitted %d tasks in cluster job (%d): (%s)\n  %s\n  %d: %d', length(job_tasks), ...
        new_job_id, datestr(now), ctrl.notes{job_tasks(1)}, ctrl.batch_id, job_tasks(1));
      if length(job_tasks) > 1
        fprintf(', %d', job_tasks(2:end));
      end
      fprintf('\n');
      job_tasks = [];
      job_cpu_time = 0;
      job_mem = 0;
      pause(ctrl.cluster.submit_pause);
    end
    if task_mem <= ctrl.cluster.max_mem_per_job
      job_tasks(end+1) = task_id;
      job_cpu_time = job_cpu_time + task_cpu_time;
      job_mem = max(job_mem, task_mem);
      ctrl.submission_queue = ctrl.submission_queue(2:end);
    else
      warning('ctrl.cluster.max_mem_per_job (%.1f GB) is less than task %d:%d''s requested mem: %.1f GB', ...
        ctrl.cluster.max_mem_per_job/1e9, ctrl.batch_id, task_id, task_mem/1e9);
      if ~isempty(regexpi(ctrl.cluster.max_mem_mode,'debug'))
        fprintf('%s\n',ones(1,80)*'=');
        fprintf('ctrl.cluster.max_mem_mode = ''debug''\n');
        fprintf('Options:\n');
        fprintf('  1. Set ctrl.cluster.max_mem_mode to ''local'' to run tasks that\n');
        fprintf('     exceed memory limits locally for this batch.\n');
        fprintf('  2. et ctrl.cluster.max_mem_mode to ''truncate'' to run tasks that\n');
        fprintf('     exceed memory limits with the max allowed memory.\n');
        fprintf('  3. Adjust task_mem manually for this specific task.\n');
        fprintf('After making changes, run dbcont to continue.\n');
        keyboard;
      end
      if ~isempty(regexpi(ctrl.cluster.max_mem_mode,'local'))
        % Run the task now locally
        cur_cluster_type = ctrl.cluster.type;
        ctrl.cluster.type = 'debug';
        ctrl = cluster_submit_job(ctrl,task_id,task_cpu_time,task_mem);
        ctrl.cluster.type = cur_cluster_type;
      end
      if ~isempty(regexpi(ctrl.cluster.max_mem_mode,'truncate'))
        % Run the task anyway, but truncate the memory request to the
        % maximum allowed.
        task_mem = ctrl.cluster.max_mem_per_job;
        job_tasks(end+1) = task_id;
        job_cpu_time = job_cpu_time + task_cpu_time;
        job_mem = max(job_mem, task_mem);
      end
      ctrl.submission_queue = ctrl.submission_queue(2:end);
    end
    
    % Check to see if a hold has been placed on this batch
    if exist(ctrl.hold_fn,'file')
      warning('This batch has a hold. Run cluster_hold(ctrl) to remove. Run "cluster_run_mode=-1" to stop cluster_run.m now in a clean way. Either way, run dbcont to continue.\n');
      keyboard;
      if cluster_run_mode < 0
        % Clean up and exit function
        ctrl_chain = ctrl;
        ctrl.submission_queue = cat(2,job_tasks,ctrl.submission_queue);
        return;
      end
    end
    
  end
  
  if ctrl.active_jobs < ctrl.cluster.max_jobs_active && ~isempty(job_tasks)
    [ctrl,new_job_id] = cluster_submit_job(ctrl,job_tasks,job_cpu_time,job_mem);
    fprintf('Submitted %d tasks in cluster job (%d): (%s)\n  %s\n  %d: %d', length(job_tasks), ...
      new_job_id, datestr(now), ctrl.notes{job_tasks(1)}, ctrl.batch_id, job_tasks(1));
    if length(job_tasks) > 1
      fprintf(', %d', job_tasks(2:end));
    end
    fprintf('\n');
    pause(ctrl.cluster.submit_pause);
    
  else
    % Put jobs back in the queue because they can't be run yet
    ctrl.submission_queue = cat(2,job_tasks,ctrl.submission_queue);
  end
  
  % Return the updated ctrl
  ctrl_chain = ctrl;
end

return
