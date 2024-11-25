function ref = records_reference_trajectory_load(param,records)
% ref = records_reference_trajectory_load(param,records)
%
% Loads the reference trajectory using the input records structure. First
% it checks to see if the reference trajectory file exists in
% CSARP_reference_trajectory/ref_YYYYMMDD_SS.mat and loads from there if
% the file exists. If the file does not exist, then the reference
% trajectory is created.
%
% The reference trajectory is the trajectory of the sensor's nominal phase
% center location (usually the center antenna element).
%
% param: radar parameter structure usually read from read_param_xls.m, only
% the file paths will be used.
%
% records: loaded records file usually from records_load.m. If this
% argument is not passed in, then the records will be loaded and the
% reference trajectory fields will be added to it.
%
% ref: structure containing the reference phase center trajectory for the
% radar. These fields will be added to the records structure that is passed
% in. Fields are the same as records file but are the reference antenna
% phase center: gps_time, lat, lon, elev.
%
% Author: John Paden
%
% See also: records_reference_trajectory.m,
% records_reference_trajectory_load.m, run_records_reference_trajectory.m,
% run_all_records_reference_trajectory.m

% If records file not passed in, then load it
if ~exist('records','var') || isempty(records)
  records = records_load(param);
end

% Check to see if reference trajectory file exists
ref_fn_dir = ct_filename_out(param,'reference_trajectory','',1);
ref_fn = fullfile(ref_fn_dir,sprintf('ref_%s.mat', param.day_seg));
if exist(ref_fn,'file')
  % If reference trajectory file exists, load and use it (this is much
  % faster usually than creating a new reference trajectory)
  ref_traj = load(ref_fn);
  if strcmp(ref_traj.gps_source,records.gps_source)
    if ~isempty(param.radar.lever_arm_fh)
      trajectory_param = struct('gps_source',records.gps_source, ...
        'season_name',param.season_name,'radar_name',param.radar_name,'rx_path', 0, ...
        'tx_weights', [], 'lever_arm_fh', param.radar.lever_arm_fh);
      [lever_arm_val] = param.radar.lever_arm_fh(trajectory_param, [], 0);
    end
    if isempty(param.radar.lever_arm_fh) || sum(abs(ref_traj.lever_arm_val-lever_arm_val)) < 1e-6
      ref = records;
      ref.lat = ref_traj.lat;
      ref.lon = ref_traj.lon;
      ref.elev = ref_traj.elev;
      ref.param_records.radar.lever_arm_fh = ref_traj.lever_arm_fh;
      return;
    else
    end
  else
    warning('records_reference_trajectory_load:gps_source','Reference trajectory file exists, but gps_source does not match. Run records_reference_trajectory.m to recreate: %s', ref_fn);
  end
end

% No usable reference trajectory file, so we have to create the reference
% trajectory.
trajectory_param = struct('gps_source',records.gps_source, ...
  'season_name',param.season_name,'radar_name',param.radar_name,'rx_path', 0, ...
  'tx_weights', [], 'lever_arm_fh', param.radar.lever_arm_fh);
ref = trajectory_with_leverarm(records,trajectory_param);
ref.param_records.radar.lever_arm_fh = param.radar.lever_arm_fh;
