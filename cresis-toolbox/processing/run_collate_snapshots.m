% script run_collate_snapshots.m
%
% Script for running collate_snapshots.m.  Takes in raw snapshots and
% prepares them for calibration
%
% Authors: Theresa Moore
%
% See also: collate_snapshots.m

%% User Setup
% =====================================================================
param_override = [];

params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'));
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20140506_01');
% params = ct_set_params(params,'cmd.frms',[3:5 34:36 40:46]);
params = ct_set_params(params,'cmd.frms',[14:16]);

% params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
% params = ct_set_params(params,'cmd.frms',[1:5 15:16 34:35 41 42]);

% params = ct_set_params(params,'cmd.generic',1,'day_seg','20140325_07');
% params = ct_set_params(params,'cmd.frms',[1:5]);

params = ct_set_params(params,'collate_snapshots.in_path','snapshot_air');
params = ct_set_params(params,'collate_snapshots.img_list',[1 2 3]);
params = ct_set_params(params,'collate_snapshots.remove_multiple',true);

% params = ct_set_params(params,'measure_sv_offsets.out_path','
% params = ct_set_params(params,'measure_sv_offsets.gamma',
% Syntax for running a specific segment and frame by overriding parameter spreadsheet values
%params = read_param_xls(ct_filename_param('rds_param_2009_Antarctica_TO.xls'),'20091228_01');
%params = ct_set_params(params,'cmd.generic',0);
%params = ct_set_params(params,'cmd.generic',1,'day_seg','20091224_01|20091228|20091229|20100101_02|20100103|20100104_01|20100112');
%params = ct_set_params(params,'cmd.frms',[]);

% Set override parameters using ct_set_params, by setting param_override, or by setting FUNCTION_params variable which eventually is copied to param_override.FUNCTION).
% These two examples for setting input parameters are equivalent.
% Example 1
% params = ct_set_params(params,'FUNCTION.param1','first parameters');
% params = ct_set_params(params,'FUNCTION.param2',[2]);
% Example 2
% param_override.FUNCTION.param1 = 'first parameters';
% param_override.FUNCTION.param2 = [2];



%param_override.sched.type = 'no scheduler'; % Example to override default cluster settings

%% Automated Section
% =====================================================================

% Input checking
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end


% Process each of the segments
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  collate_snapshots(param,param_override);
end

% Post process code (only include if necessary)