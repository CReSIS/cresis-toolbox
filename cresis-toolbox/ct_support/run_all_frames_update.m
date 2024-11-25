% script run_all_frames_update
% run_all_frames_update
%
% Run frames_update on all seasons.
%   
% Author: John Paden
%
% See also: run_all_frames_update, run_frames_update, frames_update

%% User Settings
% =========================================================================

% Select seasons in run_all:
run_all;

param_override = [];
param_override.frames_update.force_update = false;

%% Automated Section
% =========================================================================
% Input checking
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

%% Loop to process each season
for param_idx = 1:length(param_fns)
  
  % Read in parameter spreadsheet
  param_fn = ct_filename_param(param_fns{param_idx});
  fprintf('Reading %s\n', param_fn);
  params = read_param_xls(param_fn,'');
  
  if isempty(params)
    continue;
  end
  
  % Run all segments (except "do not process")
  if 1
    params = ct_set_params(params,'cmd.generic',1);
    params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');
  else
    % HACK!!!
    keyboard
    params = ct_set_params(params,'cmd.generic',0);
    params = ct_set_params(params,'cmd.generic',1,'day_seg','20120330_04');
  end
  
  %% Update each segment
  for param_idx = 1:length(params)
    param = params(param_idx);
    
    if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
      fprintf('%s\tdo not process\n', param.day_seg);
      continue;
    end
    
    try
      frames_update(param,param_override);
    catch ME
      fprintf('%s\terror!!!\t%s\n', param.day_seg, ME.getReport);
      continue;
    end
  end
end
