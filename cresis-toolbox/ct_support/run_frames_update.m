% script run_frames_update
%
% This script sets up the parameters and calls frames_update.  Rename to
% a local copy of the file in your personal folder before making changes.
%
% Author: John Paden
%
% See also: run_all_frames_update, run_frames_update, frames_update

%% User Settings
% =========================================================================
param_override = [];

% Parameters spreadsheet to use for updating
%   1. Segment and frame list are taken from the parameter sheet
%   2. For GPS update, GPS time offsets are pulled from the parameter sheet
params = read_param_xls(ct_filename_param('rds_param_2019_Antarctica_Ground.xls'));
params = ct_set_params(params,'cmd.generic',0);
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20191231');
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20200107');
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20200108');

% param.frames_update.force_update: required if only updating gps_time from
% records file.
% param_override.frames_update.force_update = true;

%% Automated section
% =========================================================================

global gRadar;

% Input checking
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  
  frames_update(param,param_override);
end
