function success = preprocess_task(param)
% success = preprocess_task(param)
%
% Cluster enabled task called from preprocess.m.
%
% Example:
% Called from preprocess.m
%
% Author: John Paden
%
% See also: run_preprocess.m, preprocess.m, preprocess_task.m

command_window_out_fn = ct_filename_ct_tmp(param,'','headers', sprintf('%s_console.txt',param.config.date_str));
command_window_out_fn_dir = fileparts(command_window_out_fn);
if ~exist(command_window_out_fn_dir,'dir')
  mkdir(command_window_out_fn_dir);
end
diary(command_window_out_fn);

if strcmpi(param.config.daq_type,'arena')
  success = preprocess_task_arena(param);
elseif strcmpi(param.config.daq_type,'cresis')
  success = preprocess_task_cresis(param);
elseif strcmpi(param.config.daq_type,'utua')
  success = preprocess_task_utua(param);
elseif strcmpi(param.config.daq_type,'bas')
  success = preprocess_task_bas(param);
elseif strcmpi(param.config.daq_type,'utig')
  success = preprocess_task_utig(param);
else
  error('Invalid param.config.daq_type %s\n', param.config.daq_type);
end

diary off;
fprintf('Console output: %s\n', command_window_out_fn);

