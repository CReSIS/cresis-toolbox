% script run_layer_tracker_tune
%
% Runs layer_tracker.m for tuning layer tracking hyperparameters.
%
% Authors: Anjali Pare, John Paden
%
% See also: layer_tracker.m, layer_tracker_combine_task.m,
% layer_tracker_task.m, layer_tracker_input_check.m,
% layer_tracker_profile.m, run_layer_tracker.m, run_layer_tracker_tune.m

%% User Settings
% ----------------------------------------------------------------------
param_override = [];

% params = read_param_xls(ct_filename_param('rds_param_2011_Greenland_P3.xls'));
params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'));
% params = read_param_xls(ct_filename_param('rds_param_2018_Greenland_P3.xls'))

params = ct_set_params(params,'cmd.generic',1);%|20140415_05|20140421_01|20140516_01');%'20140415_05|20140421_01|20140514_01|20140313_09');
params = ct_set_params(params,'cmd.generic',0, 'day_seg', '20140423_01');
params = ct_set_params(params,'cmd.generic',0,'cmd.notes','Do not process');

params = ct_set_params(params,'cmd.frms',[]); % Specify specific frames (or leave empty/undefined to do all frames)
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20110331_02');
% params = ct_set_params(params,'cmd.frms',19); % Specify specific frames (or leave empty/undefined to do all frames)

param_override.layer_tracker.debug_plots = {};
% param_override.layer_tracker.debug_plots = {'tracked_images'};
% param_override.layer_tracker.debug_plots = {'tracked_images','visible'}; % Uncomment for debugging

param_override.layer_tracker.echogram_img = 0; % To choose an image besides the base (0) image
% echogram_source: location of echogram data used for tracking
% param_override.layer_tracker.echogram_source = 'CSARP_post/qlook';
% param_override.layer_tracker.echogram_source = 'CSARP_post/mvdr';
param_override.layer_tracker.echogram_source = 'CSARP_post/standard';

% temp_name: set to any string value as a unique identifier to save the
% parameters
param_override.layer_tracker.temp_name = 'test_anj'; % Set this name as a  unique identifier to save the parameters

% layer_params: layerparams structure of where to store the output using
% opsCopyLayers.m
param_override.layer_tracker.layer_params = [];
if 1
  % Uncomment to enable layerdata storage
  % layer_tracker.layer_params.layerdate_source: Set the name of the layer
  param_override.layer_tracker.layer_params.layerdata_source = 'layer_tune_vit_season_C_test';
else
  % Uncomment to enable OPS storage
  % param_override.layer_tracker.layer_params.source = 'ops';
end

% tracker_method: Set which tracking method you want to use 'lsm' or 'viterbi'
tracker_method = 'viterbi'; % Choose the tracking method
% block_size_frms: Number of frames to be loaded at a time
param_override.layer_tracker.block_size_frms = 1;

% track_per_task: Number of tracks per task
param_override.layer_tracker.track_per_task = 1;

%% param.layer_tracker.track options
if strcmpi(tracker_method,'lsm')
  track_idx = 0;
  y_values = [140:20:280];%[140:20:280]; % Enter 1 as the first element if surface mean is calculated
  dy_values = [5 10 20 40 60 80 100];
  
  for y_idx = 1:length(y_values)
    y = y_values(y_idx);
    
    for dy_idx = 1:length(dy_values)
      dy = dy_values(dy_idx);
      track = [];
      
      %% Enable one set of parameters
      track.en = true;
      % RDS
      track.profile = 'rds_OIB';
      
      %% LSM User Settings
      track.method           = 'lsm';
      track.flag             = 0; %to specify whether we want to consider mean of y
      track.lsm.y            = y; % = '' for y = mean(SURF)
      track.lsm.dy           = dy;
      track.lsm.storeIter    = [75:25:500];
      track.idx_dim_name     = {'storeIter' 'dy' 'y'};
      track.idx_reshape      = [length(track.lsm.storeIter) length(dy_values) length(y_values)];
      track.idx              = length(dy_values)*length(track.lsm.storeIter)*(y_idx-1) ...
        + length(track.lsm.storeIter)*(dy_idx-1) + (1:length(track.lsm.storeIter));
      track.init.max_diff    = inf;
      track.detrend          = [];
      track.norm.scale       = [-40 90];
      
      track_idx = track_idx + 1;
      param_override.layer_tracker.track{track_idx} = track;
    end
  end
elseif strcmpi(tracker_method,'viterbi')
  track_idx = 0;
  transition_weight_values = [0.1 0.316 1 3.16 10]; % Enter the transition weight (smoothness) values to consider
  
  for tw_idx = 1:length(transition_weight_values)
    transition_weight = transition_weight_values(tw_idx);
    track = [];
    
    %% Enable one set of parameters
    track.en = true;
    % RDS
    track.profile = 'rds_OIB';
    
    %% Viterbi User Settings
    track.method                    = 'viterbi';
    track.viterbi.transition_weight = transition_weight;
    track.idx_dim_name              = {'transition_weight'};
    track.idx_reshape               = [length(track.viterbi.transition_weight)];
    track.idx                       = tw_idx;
    %track.min_bin = struct('name','tomo_top');
    track.min_bin.name = 'surface';
    track.min_bin.eval.cmd = 's=s+0.5e-6;';
    track.max_bin = struct('name','tomo_bottom');
    track.crossover.en = false;
    track.crossover.season_names_bad = {'2003_Greenland_P3', '2005_Greenland_P3'}; % Bad seasons to not include
    % track.crossover.gps_time_good_eval = @(x) true; % All cross overs are good
    track.crossover.gps_time_good_eval = @(x) x < datenum_to_epoch(datenum('2014/03/01')); % Cross overs before this date are good
    if 0
      track.ice_mask.en = false;
    elseif 1
      % Greenland
      track.ice_mask.en = true;
      track.ice_mask.type = 'geotiff';
      track.ice_mask.fn = ct_filename_gis([], fullfile('greenland','IceMask','GimpIceMask_90m_v1.1.tif'));
    elseif 0
      % Canada
      track.ice_mask.en = true;
      track.ice_mask.type = 'bin';
      track.ice_mask.fn = ct_filename_gis([], fullfile('canada','ice_mask','03_rgi50_ArcticCanadaNorth','03_rgi50_ArcticCanadaNorth.bin'));
      track.ice_mask.mat_fn = ct_filename_gis([], fullfile('canada','ice_mask','03_rgi50_ArcticCanadaNorth','03_rgi50_ArcticCanadaNorth.mat'));
    elseif 0
      % Antarctica
      track.ice_mask.en = true;
      track.ice_mask.type = 'geotiff2';
      track.ice_mask.fn = ct_filename_gis([], fullfile('antarctica/DEM/BEDMAP2/original_data/bedmap2_tiff/bedmap2_icemask_grounded_and_shelves.tif'));
      track.ice_mask.fn2 = ct_filename_gis([], fullfile('antarctica/DEM/BEDMAP2/original_data/bedmap2_tiff/bedmap2_rockmask.tif'));
    end
    track.init.dem_layer        = struct('name','surface');
    track.viterbi.gt_cutoff     = 50;
    track.mult_suppress.en      = true;
    track.init.max_diff         = inf;
    track.detrend               = [];
    track.filter_trim           = [0 120];
    track.norm.scale            = [-40 90];
    track.xcorr                 = echo_xcorr_profile('short_unitstep');
    track.ground_truth.en = false;
    track.ground_truth.layers.source = 'layerdata';
    track.ground_truth.layers.layerdata_source = 'layer';
    track.ground_truth.layers.name = 'bottom_mc';
    track.ground_truth.cutoff = 450;
    track_idx = track_idx + 1;
    param_override.layer_tracker.track{track_idx} = track;
  end
end

% param_override.layer_tracker.surf_layer = struct('name','surface','source','layerdata','layerdata_source','layer');

% param_override.layer_tracker.crossover_layer = struct('name','bottom','source','ops');

% dbstop if error;
 param_override.cluster.type = 'torque';
% param_override.cluster.type = 'matlab';
% param_override.cluster.type = 'debug';
% param_override.cluster.type = 'slurm';
% param_override.cluster.rerun_only = true;
% param_ovserride.cluster.desired_time_per_job  = 240*60;
param_override.cluster.cpu_time_mult  = 2;
param_override.cluster.mem_mult  = 2;

%% Automated Section
% ----------------------------------------------------------------------

% Input checking
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

ctrl_chain = {};
% Process each of the segments
for param_idx = 1:length(params)
  param = params(param_idx);
  if isfield(param.cmd,'generic') && ~iscell(param.cmd.generic) && ~ischar(param.cmd.generic) && param.cmd.generic
    if strcmpi(tracker_method,'lsm')
      if track.flag == 1
        gt_layer_params = [];
        idx = 1;
        gt_layer_params(idx).name = 'surface';
        layers = opsLoadLayers(param,gt_layer_params);
        param_override.layer_tracker.gt_params = layers;
      end
    end
    [ctrl_chain{end+1},param] = layer_tracker(param,param_override);
    % Since we are tuning, save the parameters
    out_param_fn = [ct_filename_ct_tmp(param,'','layer_tracker',param.layer_tracker.temp_name),sprintf('_%s_t%03d_%s.mat',datestr(now,'yyyymmdd_HHMMSS'),length(param.layer_tracker.track), param.layer_tracker.track{1}.method)];
    fprintf('Saving tuning parameters %s\n',out_param_fn);
    ct_save(out_param_fn,'param');
  end
end

cluster_print_chain(ctrl_chain);

[chain_fn,chain_id] = cluster_save_chain(ctrl_chain);
