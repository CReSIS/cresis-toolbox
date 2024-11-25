function cluster_compile(fun,hidden_depend_funs,force_compile,ctrl)
% cluster_compile(fun,hidden_depend_funs,force_compile,ctrl)
%
% Compiles functions to be used with the cluster_* functions. It tries
% to detect if any of the dependent functions to "fun" have changed
% and will recompile if they have.
%
% Makes use of "fdep.m" which is an external party function with separate
% license rules.
%
% MODE1:
% Inputs:
%  fun: specific function to be called by cluster_create_task
%    default is to check every function, specifying a function here allows
%    the date check part of cluster_compile to go faster
%  hidden_depend_funs: cell vector of hidden dependent functions cells
%    default is to use gRadar.cluster.hidden_depend_funs
%    Each cell in the cell vector has two fields:
%    {1}: filename
%    {2}: numeric integer (0, 1, or 2) that specifies timestamp check level.
%      These levels mean:
%        0: do not check if file is newer
%        1: always check if file is newer
%        2: only check if file is newer when fun not specified.
%      Typical settings:
%        0: typical setting for builtin matlab functions that never change
%        1: typical setting for functions that are passed in as function
%          handles and so there dependence cannot be determined by Matlab
%          (typical examples are tukeywin_trim, lever_arm_fh)
%        2: typical setting for all other functions
%  force_compile: force a compile even if dependent functions have not changed
%    default is true if ctrl is undefined or if ctrl.cluster.type is 'slurm' or
%    'torque'
% ctrl: ctrl structure returned from cluster_new_batch, default is empty
%  .cluster: cluster parameters
%    .type: (only used to determine default state of force_compile)
%    .mcc: string containing 'system' or 'eval' and specifies which of
%      these two functions will be used to execute the mcc command
%      system is generally preferred because it only requires the matlab
%      compiler license while the command line is running and then releases
%      it. Calling eval does not release the license until the matlab
%      session ends.
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

% Find dependencies that are directly called

global gRadar;

if ~exist('ctrl','var')
  ctrl = [];
end

if ~isfield(ctrl,'cluster')
  ctrl.cluster = [];
  if isfield(gRadar,'cluster') && isfield(gRadar.cluster,'mcc')
    ctrl.cluster.mcc = gRadar.cluster.mcc;
  end
end

if ~isfield(ctrl.cluster,'mcc') || isempty(ctrl.cluster.mcc)
  ctrl.cluster.mcc = 'system';
end

if ~isfield(ctrl.cluster,'mcc_delete_output') || isempty(ctrl.cluster.mcc_delete_output)
  ctrl.cluster.mcc_delete_output = false;
end

if ~isfield(ctrl.cluster,'cluster_job_fn') || isempty(ctrl.cluster.cluster_job_fn)
  ctrl.cluster.cluster_job_fn = fullfile(gRadar.path,'cluster','cluster_job.sh');
end

if ~isfield(ctrl.cluster,'mem_to_ppn') || isempty(ctrl.cluster.mem_to_ppn)
  if isfield(gRadar.cluster,'mem_to_ppn')
    ctrl.cluster.mem_to_ppn = gRadar.cluster.mem_to_ppn;
  else
    ctrl.cluster.mem_to_ppn = [];
  end
end

if ~exist('fun','var')
  fun = {};
end

% Support the legacy format of a single string containing a function
if ischar(fun)
  fun = {fun};
end

if ~exist('hidden_depend_funs','var') || isempty(hidden_depend_funs)
  hidden_depend_funs = gRadar.cluster.hidden_depend_funs;
end

if isfield(ctrl.cluster,'type') && all(~strcmpi(ctrl.cluster.type,{'torque','slurm'}))
  return;
end  

if ~exist('force_compile','var')
  force_compile = 1;
end

matlab_ver = ver('matlab');
% 8.3 was first version of builtin, but it has bugs. So using 8.6 as
% threshold especially since fdep no longer works in that version
use_builtin_fdep = str2double(matlab_ver.Version) >= 8.6;

cluster_job_fn_dir = fileparts(ctrl.cluster.cluster_job_fn);
cluster_job_fn = fullfile(cluster_job_fn_dir,'cluster_job.m');
cluster_job_bin_fn = fullfile(cluster_job_fn_dir,'cluster_job');
cluster_job_fn_compiled = fullfile(cluster_job_fn_dir,'run_cluster_job.sh');

if ~force_compile
  % If any of the functions in depend_fun are newer, then recompile
  
  test_date = dir(cluster_job_fn_compiled);
  
  if length(test_date) == 0
    % File does not exist, have to compile to make the file
    force_compile = true;
  else
    fun_info = dir(cluster_job_fn);
    if fun_info.datenum > test_date.datenum
      force_compile = true;
    end
    
    if ~isempty(fun)
      for input_idx = 1:length(fun)
        try
          if use_builtin_fdep
            flist = matlab.codetools.requiredFilesAndProducts(fun{input_idx});
          else
            warning off
            flist = fdep(fun{input_idx},'-q');
            warning on
            flist = flist.fun;
          end
          for fun_idx = 1:length(flist)
            fun_info = dir(flist{fun_idx});
            if fun_info.datenum > test_date.datenum
              force_compile = true;
              break;
            end
          end
        catch
          force_compile = true;
        end
      end
    end
    
    if ~force_compile
      for fun_idx = 1:length(hidden_depend_funs)
        fn = hidden_depend_funs{fun_idx}{1};
        level = hidden_depend_funs{fun_idx}{2};
        if level == 1 || level == 2 && isempty(fun)
          try
            if use_builtin_fdep
              flist = matlab.codetools.requiredFilesAndProducts(fn);
            else
              warning off
              flist = fdep(fn,'-q');
              warning on
              flist = flist.fun;
            end
            for fun_idx = 1:length(flist)
              fun_info = dir(flist{fun_idx});
              if fun_info.datenum > test_date.datenum
                force_compile = true;
                break;
              end
            end
          catch
            force_compile = true;
            break;
          end
        end
      end
    end
    
  end
end

if force_compile
  if ctrl.cluster.mem_to_ppn
    cmd = sprintf('mcc -m -d %s %s', cluster_job_fn_dir, cluster_job_fn);
  else
    cmd = sprintf('mcc -m -d %s -R ''-singleCompThread'' %s', cluster_job_fn_dir, cluster_job_fn);
  end
  
  for dep_idx = 1:length(hidden_depend_funs)
    cmd = [cmd ' ' hidden_depend_funs{dep_idx}{1}];
  end
  
  for input_idx = 1:length(fun)
    % Add in functions in case they are not in the hidden dependency list
    if isempty(regexpi(cmd, fun{input_idx}))
      cmd = [cmd ' ' fun{input_idx}];
    end
  end
  
  % Check to make sure the working directory is not a package or class
  % directory. This messes up the compiler if it uses functions from those
  % packages or classes.
  working_dir = pwd;
  [~,working_dir_name] = fileparts(working_dir);
  if ~isempty(working_dir_name) && (working_dir_name(1) == '+' || working_dir_name(1) == '@')
    warning('Before dbcont, change directory out of any package or class directories, because this can cause mcc to fail. (E.g. "cd ..")');
    keyboard
  end
  
  fprintf('Start Compiling %s\n\n', datestr(now));
  if ctrl.cluster.mcc_delete_output
    system(sprintf('rm -f %s', cluster_job_bin_fn));
  end
  fprintf('  %s\n', cmd);
  if strcmpi(ctrl.cluster.mcc,'system')
    status = system(cmd);
    if status ~= 0
      error('mcc failed to compile.');
    end
  elseif strcmpi(ctrl.cluster.mcc,'system_eval')
    % This uses an extra Matlab license, but allows the mcc license to be freed immediately after compiling
    % Unfortunately, 
    system_cmd = ['matlab -nodisplay -r "try;' cmd '; catch; fprintf(''FAILED\n''); end; exit;"'];
    [status,result] = system(system_cmd,'-echo');
    if status ~= 0 || ~isempty(regexpi(result,'FAILED'))
      error('mcc failed to compile.');
    end
  elseif strcmpi(ctrl.cluster.mcc,'eval')
    eval(cmd);
  else
    error('Invalid ctrl.cluster.mcc setting (%s). Must be system, eval, or system_eval.', ctrl.cluster.mcc);
  end
  fprintf('\nDone Compiling %s\n', datestr(now));
end

