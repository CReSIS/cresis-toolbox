function records_reference_trajectory(param,param_override)
% records_reference_trajectory(param,param_override)
%
% Function for creating reference trajectory files (ref_YYYYMMDD_SS.mat) in
% CSARP_reference_trajectory.
%
% The reference trajectory files can then be loaded with
% records_reference_trajectory_load.m.
%
% Inputs:
% param: struct with processing parameters
%         -- OR --
%         function handle to script with processing parameters
% param_override: parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% Authors: John Paden
%
% See also: records_reference_trajectory.m,
% records_reference_trajectory_load.m, run_records_reference_trajectory.m,
% run_all_records_reference_trajectory.m

%% General Setup
% =====================================================================
if exist('param_override','var')
  param = merge_structs(param, param_override);
end

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Load records
% =====================================================================

fprintf('Loading records\t%s\n', datestr(now,'yyyymmdd_HHMMSS'));
records = records_load(param);

%% Create reference trajectory using records and lever arm
% =====================================================================

fprintf('Creating reference trajectory\t%s\n', datestr(now,'yyyymmdd_HHMMSS'));
% Create reference trajectory (rx_path == 0, tx_weights = []). Update
% the records field with this information.
trajectory_param = struct('gps_source',records.gps_source, ...
  'season_name',param.season_name,'radar_name',param.radar_name,'rx_path', 0, ...
  'tx_weights', [], 'lever_arm_fh', param.radar.lever_arm_fh);
[records,lever_arm_val] = trajectory_with_leverarm(records,trajectory_param);

%% Save output
% =====================================================================

ref_fn_dir = ct_filename_out(param,'reference_trajectory','',1);
if ~exist(ref_fn_dir,'dir')
  mkdir(ref_fn_dir);
end
ref_fn = fullfile(ref_fn_dir,sprintf('ref_%s.mat', param.day_seg));
fprintf('Saving reference trajectory\t%s\t%s\n', ref_fn, datestr(now,'yyyymmdd_HHMMSS'));
records.lever_arm_val = lever_arm_val;
records.lever_arm_fh = param.radar.lever_arm_fh;
records.file_version = '1';
records.file_type = 'reference_trajectory';
records.sw_version = current_software_version;
ct_save(ref_fn,'-struct','records','gps_time','lat','lon','elev','gps_source','lever_arm_val','lever_arm_fh','file_version','file_type','sw_version');
