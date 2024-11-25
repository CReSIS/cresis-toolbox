function track = layer_tracker_profile(param,profile_str)
% track = layer_tracker_profile(param,profile_str)
%
% Returns a default set of tracking parameters for layer tracking with
% layer_tracker.m.
%
% param: parameter spreadsheet structure
% profile_str: optional string containing the profile name to load (default
%   is "default"
%
% track: Parameters used to control the tracker. See layer_tracker.m.
%
% Example:
%   Should only be used from layer_tracker.m
%
% Authors: Anjali Pare, John Paden
%
% See also: layer_tracker.m, layer_tracker_combine_task.m,
% layer_tracker_task.m, layer_tracker_input_check.m,
% layer_tracker_profile.m, run_layer_tracker.m, run_layer_tracker_tune.m

%% Check input arguments
if ~exist('profile_str','var') || isempty(profile_str)
  profile_str = 'default';
end
track.profile = profile_str;

%% Default track settings
track.data_noise_en = false;
track.detrend = [];
track.en = true;
track.init = [];
track.init.method = 'max';
track.init.snake_rng = [-2e-7 2e-7];
track.init.dem_layer = '';
track.init.dem_offset = 0;
track.init.dem_layer_offset = 0;
track.init.max_diff = inf;
track.init.max_diff_method = 'interp_finite';
track.filter = [1 1];
track.filter_trim = [0 0];
track.fixed_value = 0;
track.min_bin = 0;
track.max_bin = inf;
track.max_rng = [0 0];
track.max_rng_units = 'time';
track.medfilt = 0;
track.medfilt_threshold = 0;
track.method = 'threshold';
track.prefilter_trim = [0 0];
track.sidelobe_dB = [];
track.sidelobe_rows = [];
track.snake_rng = [-2e-7 2e-7];
track.threshold = 15;
track.threshold_noise_rng = [0 -inf -1];

if strcmpi(profile_str,'default')
  %% Default profile
  
elseif strcmpi(profile_str,'ACCUM')
  %% ACCUM profile
  track.debug_time_guard = 2e-6;
  track.filter	= [3 3];
  track.filter_trim = [0 3];
  track.init.method	= 'medfilt';
  track.init.medfilt	= 11;
  track.init.max_diff = 1e-6;%0.5e-6;
  track.max_rng	= [0 3];
  track.max_rng_units = 'bins';
  track.medfilt = 3;%11;
  track.medfilt_threshold = 10;%30;
  track.method = 'threshold';
  track.min_bin = 0;%1.6e-6;
  track.threshold = 5;%10;
  track.threshold_noise_rng = [0 -1e-6 -0.3e-6];
  track.threshold_rel_max = -9;
  track.threshold_rng = 5;
  
elseif strcmpi(profile_str,'KABAND')
  %% KABAND profile
  track.debug_time_guard = 50e-9;
  track.min_bin = 0.1e-6;
  track.prefilter_trim = [0 0];
  track.filter = [5 3];
  track.filter_trim = [10 10];
  track.init.method	= 'medfilt';
  track.init.medfilt	= 51;
  track.init.max_diff = 0.3e-6;
  track.max_rng	= [0 9];
  track.max_rng_units = 'bins';
  track.medfilt = 11;
  track.medfilt_threshold = 100;
  track.method = 'threshold';
  track.threshold = 8;
  track.threshold_noise_rng = [15e-9 -75e-9 -30e-9];
  track.threshold_rel_max = -9;
  
elseif strcmpi(profile_str,'KUBAND')
  %% KUBAND profile
  track.debug_time_guard = 50e-9;
  track.min_bin = 0.1e-6;
  track.prefilter_trim = [0 0];
  track.filter = [5 3];
  track.filter_trim = [10 10];
  track.init.method	= 'medfilt';
  track.init.medfilt	= 51;
  track.init.max_diff = 0.3e-6;
  track.max_rng	= [0 9];
  track.max_rng_units = 'bins';
  track.medfilt = 11;
  track.medfilt_threshold = 100;
  track.method = 'threshold';
  track.threshold = 8;
  track.threshold_noise_rng = [15e-9 -75e-9 -30e-9];
  track.threshold_rel_max = -9;
  
elseif strcmpi(profile_str,'RDS')
  %% RDS profile
  track.debug_time_guard = 2e-6;
  track.filter	= [1 5];
  track.init.method	= 'medfilt';
  track.init.medfilt	= 11;
  track.init.max_diff = 0.5e-6;
  track.max_rng	= [0 1];
  track.max_rng_units = 'bins';
  track.medfilt = 11;
  track.medfilt_threshold = 30;
  track.method = 'threshold';
  track.min_bin = 1.6e-6;
  track.threshold = 10;
  track.threshold_noise_rng = [0 -2e-6 -0.2e-6];
  track.threshold_rel_max = -9;
  track.threshold_rng = 5;
  
elseif strcmpi(profile_str,'RDS_OIB')
  %% RDS_OIB profile
  track.debug_time_guard = 2e-6;
  track.filter	= [1 5];
  track.init.method	= 'medfilt';
  track.init.medfilt	= 11;
  track.init.max_diff = 0.5e-6;
  track.max_rng	= [0 1];
  track.max_rng_units = 'bins';
  track.medfilt = 11;
  track.medfilt_threshold = 30;
  track.method = 'threshold';
  track.min_bin = 1.6e-6;
  track.threshold = 10;
  track.threshold_noise_rng = [0 -2e-6 -0.2e-6];
  track.threshold_rel_max = -9;
  track.threshold_rng = 5;
  
elseif strcmpi(profile_str,'SNOW')
  %% SNOW profile
  track.debug_time_guard = 50e-9;
  track.min_bin = 0.1e-6;
  track.prefilter_trim = [0 0];
  track.filter = [5 3];
  track.filter_trim = [10 10];
  track.init.method	= 'medfilt';
  track.init.medfilt	= 51;
  track.init.max_diff = 0.3e-6;
  track.max_rng	= [0 9];
  track.max_rng_units = 'bins';
  track.medfilt = 11;
  track.medfilt_threshold = 100;
  track.method = 'threshold';
  track.threshold = 8;
  track.threshold_noise_rng = [15e-9 -75e-9 -30e-9];
  track.threshold_rel_max = -9;
  
elseif strcmpi(profile_str,'SNOW_FLAT_STEP1')
  %% SNOW FLAT step 1 of 2 profile
  % Use param.layer_tracker.overlap == 50 and track.layer_names = {'surface_flatten'}
  track.layer_names = {'surface_flatten'};
  track.debug_time_guard = 50e-9;
  track.min_bin = 0.1e-6;
  track.prefilter_trim = [0 0];
  track.filter = [5 7]; % Use longer filter 
  track.filter_trim = [10 10];
  track.init.method  = 'dem';
  track.init.dem_layer.name = 'surface';
  track.init.dem_layer.source = 'lidar';
  track.init.dem_layer.lidar_source = 'atm';
  track.init.dem_layer.lever_arm_en = true;
  track.init.max_diff_method = 'merge_vectors';
  track.init.max_diff = 0.3e-6;
  track.max_rng	= [0 9];
  track.max_rng_units = 'bins';
  track.medfilt = 11;
  track.medfilt_threshold = 0; % Median filter more tightly
  track.method = 'threshold';
  track.threshold = 8;
  track.threshold_noise_rng = [15e-9 -75e-9 -30e-9];
  track.threshold_rel_max = -21; % Allow for bright shallow layers
  track.max_rng_filter = [5 3]; % During max_rng, use less filtered data to track the surface more closely
  track.smooth_sgolayfilt = {3,41}; % Smooth layer
  
elseif strcmpi(profile_str,'SNOW_FLAT_STEP2')
  %% SNOW FLAT step 2 of 2 profile
  track.debug_time_guard = 50e-9;
  track.min_bin = 0.1e-6;
  track.prefilter_trim = [0 0];
  track.min_bin = struct('name','surface_flatten','eval',struct('cmd','s=fir_dec(s,ones(1,41)/41,1)-150e-9;'));
  track.max_bin = struct('name','surface_flatten','eval',struct('cmd','s=fir_dec(s,ones(1,41)/41,1)+80e-9;'));
  track.filter = [1 19]; % Use longer filter because of surface flattening
  track.filter_trim = [10 10];
  track.flatten  = struct('name','surface_flatten');
  track.init.method  = 'nan';
  track.init.dem_layer.name = 'surface_flatten';
  track.init.dem_layer.source = 'layerdata';
  track.init.max_diff_method = 'merge_vectors';
  track.max_rng	= [0 9];
  track.max_rng_filter = [1 5]; % During max_rng, use less filtered data to track the surface more closely
  track.max_rng_units = 'bins';
  if 0
    track.xcorr = echo_xcorr_profile('snow');
    track.method = 'viterbi';
  else
    track.method = 'threshold';
    track.threshold = 8;
    track.threshold_noise_rng = [15e-9 -75e-9 -30e-9];
    track.threshold_rel_max = -21; % Allow for bright shallow layers
  end
  
elseif strcmpi(profile_str,'SNOW_AWI')
  %% SNOW_AWI profile
  track.debug_time_guard = 50e-9;
  track.min_bin = 0.1e-6;
  track.prefilter_trim = [0 0];
  track.filter = [5 3];
  track.filter_trim = [10 10];
  track.init.method	= 'medfilt';
  track.init.medfilt	= 51;
  track.init.max_diff = 0.3e-6;
  track.max_rng	= [0 9];
  track.max_rng_units = 'bins';
  track.medfilt = 11;
  track.medfilt_threshold = 100;
  track.method = 'threshold';
  track.threshold = 8;
  track.threshold_noise_rng = [15e-9 -75e-9 -30e-9];
  track.threshold_rel_max = -9;
  
elseif strcmpi(profile_str,'DEM_LIDAR')
  %% DEM profile
  track.debug_time_guard = 100e-9;
  track.min_bin = 0e-6;
  track.init.method  = 'dem';
  track.init.dem_layer.name = 'surface';
  track.init.dem_layer.source = 'lidar';
  track.init.dem_layer.lidar_source = 'atm';
  track.init.dem_layer.lever_arm_en = true;
  track.init.max_diff_method = 'merge_vectors';
  track.init.max_diff = 0e-6; % Force output layer to equal DEM
  track.max_rng	= [0 0];
  track.method = ''; % No data dependent tracking
  
else
  error('Invalid profile selected: %s\n', profile_str);
end
