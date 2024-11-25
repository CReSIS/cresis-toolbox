% script run_layer_create
%
% Calls the layer_create function
%
% Author: John Paden
%
% See also: layer_create, run_layer_create

%% User Settings
% =========================================================================
param_override = [];

% Parameters spreadsheet to use for updating
% params = read_param_xls(ct_filename_param('rds_param_2010_Greenland_DC8.xls'));
% params = read_param_xls(ct_filename_param('rds_param_2010_Greenland_P3.xls'));
% params = read_param_xls(ct_filename_param('rds_param_2011_Greenland_P3.xls'));
% params = read_param_xls(ct_filename_param('rds_param_2012_Greenland_P3.xls'));
% params = read_param_xls(ct_filename_param('rds_param_2013_Greenland_P3.xls'));
% params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'));
% params = read_param_xls(ct_filename_param('rds_param_2015_Greenland_C130.xls'));
% params = read_param_xls(ct_filename_param('rds_param_2016_Greenland_P3.xls'));
params = read_param_xls(ct_filename_param('rds_param_2017_Greenland_P3.xls'));
% params = read_param_xls(ct_filename_param('snow_param_2014_Greenland_P3.xls'));
% params = read_param_xls(ct_filename_param('snow_param_2016_Greenland_P3.xls'));

params = ct_set_params(params,'cmd.generic',0);
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20160501_01');
% params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');
% params = ct_set_params(params,'cmd.frms',[]);

params = ct_set_params(params,'cmd.generic',1);
params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');
params = ct_set_params(params,'cmd.frms',[]);

% .out_path: string containing file path where layer files will be stored
% to; string is passed to ct_filename_out to form the file path.
%  Default is 'layer'.
param_override.layer_file_make.out_path = 'layer';
% param_override.layer_file_make.out_path = 'CSARP_post/layer';

% param_override.layer_file_make.update_mode
% 0: no updates are made, layer file is created only if no layer file
% exists or if there were problems with an existing layer file. This is
% the default setting.
% 1: layer file is overwritten with new information (blank layer file)
% and old layer data is lost
% 2: Old GPS time field is adjusted according to changes in
% param.records.gps.time_offset and then the position and layer
% information is reinterpolated from the old GPS time field to the new
% GPS time field.
param_override.layer_file_make.update_mode = 0;
% param_override.layer_file_make.update_mode = 1;
% param_override.layer_file_make.update_mode = 2;

  
%% Automated section
% =========================================================================

global gRadar;

% Input checking
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

%% Make layer data files for each of the enabled segments
failed_segments = [];
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  try
    layer_create(param,param_override);
    %layer_create
  catch ME
    failed_segments(end+1).param_idx = param_idx;
    failed_segments(end).report = ME.getReport;
    failed_segments(end).message = ME.message;
    %keyboard
  end
  fprintf('  Complete (%s)\n', datestr(now));
end

for failed_idx = 1:length(failed_segments)
  fprintf('%s: %s\n', params(failed_segments(failed_idx).param_idx).day_seg, ...
    failed_segments(failed_idx).message);
end
