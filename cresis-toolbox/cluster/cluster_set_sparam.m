function ctrl_chain = cluster_set_sparam(ctrl_chain,varargin)
% ctrl_chain = cluster_set_sparam(ctrl_chain,varargin)
%
% cluster_set_sparam(ctrl_chain,'argsin{1}.records.file.base_dir','/archive/');
% cluster_set_sparam(ctrl,'argsin{1}.records.file.base_dir','/archive/');
% cluster_set_sparam(ctrl,'argsin{1}',20);
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

if iscell(ctrl_chain)
  %% Traverse chain lists
  for chain = 1:numel(ctrl_chain)
    fprintf('Chain %d\n', chain);
    for stage=1:numel(ctrl_chain{chain})
      fprintf('  Stage %d\n', stage);
      [ctrl_chain{chain}{stage}] = cluster_set_sparam(ctrl_chain{chain}{stage},varargin{:});
    end
  end
  
elseif isstruct(ctrl_chain)
  %% Set batch
  ctrl = ctrl_chain;
  
  % Load the sparam file
  static_in_fn = fullfile(ctrl.in_fn_dir,'static.mat');
  sparam = load(static_in_fn);
  
  for arg_idx = 1:2:numel(varargin)
    % Create and run the set commands
    if 1
      cmd = sprintf('sparam.static_param.%s = varargin{arg_idx+1};', varargin{arg_idx});
    else
      field_name_list = regexp(varargin{arg_idx}, '\.+', 'split');
      cmd = 'sparam.static_param';
      for idx=1:length(field_name_list)
        cmd = cat(2,cmd,sprintf('.(field_name_list{%d})',idx));
      end
      cmd = cat(2,cmd,sprintf(' = varargin{%d};',arg_idx+1));
    end
    try
      eval(cmd)
    catch ME
      warning(ME.getReport);
    end
  end
  
  % Save the updated sparam
  save(static_in_fn,'-append','-struct','sparam','static_param');
end
