function out = cluster_submit_batch(fun,block,argsin,num_args_out,cpu_time,mem)
% out = cluster_submit_batch(fun,block,argsin,num_args_out,notes,cpu_time,mem)
%
% Runs an arbitrary job called "fun" with inputs "argsin". Introduces
% about 30 seconds of overhead as long as a compile is not necessary.
%
% INPUTS:
%
% fun: String containing the function name (e.g. 'hanning') that the task
% will run. This should NOT include '.m'. Note that if there are any
% function dependencies to this function that are not explicit, these must
% be added to gRadar.cluster.hidden_depend_funs in startup.m. This happens
% when passing in a function handle or function name string as an input or
% creating commands that run via eval because the cluster_compile function
% cannot detect these implicit dependencies since the code must be
% evaluated to see them.
%
% argsin: cell vector of input arguments to the task (e.g. {10,'arg2'})
%
% num_args_out: number of output arguments
%
% notes: string containing notes about the task
%
% cpu_time: expected maximum cpu time in seconds
%
% mem: expected maximum memory usage in bytes
%
% OUTPUTS:
% out: if block = true, cell vector of output arguments from the task
% out: if block = false, cluster control structure for the batch
%
% EXAMPLES:
% % Blocking example:
% out = cluster_submit_batch('hanning',true,{10},1,60,1500e6)
%
% % Non-blocking example:
% ctrl = cluster_submit_batch('hanning',false,{10},1,60,1500e6);
% ctrl_chain = {{ctrl}};
% [~,chain_id] = cluster_save_chain(ctrl_chain);
%
% while true
%   % These are the three lines of code that should be run to poll the job:
%   fprintf('%s\nPoll the chain:\n',repmat('=',[1 40]));
%   ctrl_chain = cluster_run(chain_id,false);
%   cluster_save_chain(ctrl_chain,chain_id,false);
%
%   % Check to see if any tasks are not complete and did not fail
%   if ~any(isfinite(cluster_chain_stage(ctrl_chain)))
%     % Done with all tasks (either completed or failed)
%     break;
%   end
%   pause(10);
% end
% [in,out] = cluster_print(ctrl_chain{1}{1}.batch_id,1,0);
% cluster_cleanup(ctrl_chain{1}{1}.batch_id);
%
% Author: John Paden
%
% See also: cluster_chain_stage, cluster_cleanup, cluster_compile
%   cluster_exec_job, cluster_get_batch, cluster_get_batch_list, 
%   cluster_hold, cluster_job, cluster_new_batch, cluster_new_task,
%   cluster_print, cluster_run, cluster_submit_batch, cluster_submit_task,
%   cluster_update_batch, cluster_update_task

ctrl = cluster_new_batch;

cluster_compile({[fun '.m']},[],0,ctrl);

param.task_function = fun;
param.argsin = argsin;
param.num_args_out = num_args_out;
param.cpu_time = cpu_time;
param.mem = mem;
repeat_task = 1;
for tmp = 1:repeat_task
  ctrl = cluster_new_task(ctrl,param,[]);
end

if block
  % Blocking, submit and wait
  fprintf('Submitting %s\n', ctrl.batch_dir);
  ctrl_chain = {{ctrl}};
  ctrl_chain = cluster_run(ctrl_chain,block);
  [in,out] = cluster_print(ctrl_chain{1}{1}.batch_id,1,0);
  cluster_cleanup(ctrl);
else
  % Non-blocking, do not submit
  out = ctrl;
  
end

return;
