% script run_BW_window_gen
%
% Script for running BW_window_gen
%
% Authors: John Paden, Hara Madhav Talasila
%
% See also: run_BW_window_gen.m, BW_window_gen.m

%% User Setup
% =====================================================================

param_override = [];

% params = read_param_xls(ct_filename_param('snow_param_2012_Greenland_P3.xls'));
% params = ct_set_params(params,'radar.wfs.DDC_valid',1);

% params = read_param_xls(ct_filename_param('snow_param_2013_Greenland_P3.xls'));
% params = ct_set_params(params,'radar.wfs.DDC_valid',[1 4 8 16 32]);

% params = read_param_xls(ct_filename_param('snow_param_2014_Greenland_P3.xls'));
% params = ct_set_params(params,'radar.wfs.DDC_valid',[1 2 4 8 16]);

% params = read_param_xls(ct_filename_param('snow_param_2017_Greenland_P3.xls'));
% params = ct_set_params(params,'radar.wfs.DDC_valid',1);

params = read_param_xls(ct_filename_param('snow_param_2019_Arctic_GV.xls'));
params = ct_set_params(params,'radar.wfs.DDC_valid',1);

% params = read_param_xls(ct_filename_param('snow_param_2019_Arctic_Polar6.xls'));
% params = ct_set_params(params,'radar.wfs(1).DDC_valid',[1 2 4 8 16]);
% params = ct_set_params(params,'radar.wfs(2).DDC_valid',[1 2 4 8 16]);

params = ct_set_params(params,'cmd.generic',1);
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20120330_03');
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20120330_04');

% BW_guard: Two element vector which specifies the bandwidth guard to
% remove at the start and end of the bandwidth (e.g. if the signal is poor
% on the edges or you are selecting a subband; subband is normally done
% during deconvolution and not with BW_guard). Default is [1 1] and the
% BW_guard_units are set to '%' which means 1% of the bandwidth if removed
% at the start and end. The default units are 'Hz' if BW_guard is defined.
% param_override.BW_window_gen.BW_guard = [0.8e9 0.5e9];

% nice_BW_ratio: Specify the range of bandwidth to search for a nicer round
% number for the bandwidth. This is a percentage of abs(f1-f0). Default is
% 1% or 0.01.
% param_override.BW_window_gen.nice_BW_ratio = 0.005;

warning off;

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
fprintf('Consider using BW_window_nice rather than BW_window to use more readable numbers.\n');
fprintf('%s\t%s\t%s\t%s\t%s\n', 'day_seg', 'BW_window_GHz', 'BW_window', 'BW_window_nice', 'df');
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  if isempty(regexpi(param.cmd.notes,'do not process'))
    try
      BW_window_gen(param,param_override);
    catch ME
      fprintf('%s\tFAILED: %s\t\n', param.day_seg, regexprep(ME.getReport,'[\n\r]',' '));
    end
  else
    fprintf('%s\tDO NOT PROCESS\t\n', param.day_seg);
  end
end
