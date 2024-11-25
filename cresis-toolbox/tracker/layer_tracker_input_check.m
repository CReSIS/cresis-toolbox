% script layer_tracker_input_check
%
% Support function for layer_tracker.m and layer_tracker_task.m that checks
% the inputs.
%
% Authors: Anjali Pare, John Paden
%
% See also: layer_tracker.m, layer_tracker_combine_task.m,
% layer_tracker_task.m, layer_tracker_input_check.m,
% layer_tracker_profile.m, run_layer_tracker.m, run_layer_tracker_tune.m

%% Input Checks: layer_tracker
% =====================================================================

physical_constants;

%  .layer_tracker: parameter structure controlling layer tracker
if ~isfield(param,'layer_tracker') || isempty(param.layer_tracker)
  param.layer_tracker = [];
end

%  .block_size_frms: Number of data frames to load and process at a time.
%  Default is 1 frame at a time.
if ~isfield(param.layer_tracker,'block_size_frms') || isempty(param.layer_tracker.block_size_frms)
  param.layer_tracker.block_size_frms = 1;
end
param.layer_tracker.block_size_frms = min(length(param.cmd.frms), param.layer_tracker.block_size_frms);

%  .copy_param: Final output opsCopyLayer parameter struct
if ~isfield(param.layer_tracker,'copy_param') || isempty(param.layer_tracker.copy_param)
  param.layer_tracker.copy_param = [];
end
%  .copy_param.copy_method
if ~isfield(param.layer_tracker.copy_param,'copy_method') || isempty(param.layer_tracker.copy_param.copy_method)
  param.layer_tracker.copy_param.copy_method = 'overwrite';
end
%  .copy_param.gaps_fill
if ~isfield(param.layer_tracker.copy_param,'gaps_fill') || isempty(param.layer_tracker.copy_param.gaps_fill)
  param.layer_tracker.copy_param.gaps_fill = [];
end
%  .copy_param.gaps_fill.method
if ~isfield(param.layer_tracker.copy_param.gaps_fill,'method') || isempty(param.layer_tracker.copy_param.gaps_fill.method)
  param.layer_tracker.copy_param.gaps_fill.method = 'preserve_gaps';
end

%  .debug_plots: cell array of strings
if ~isfield(param.layer_tracker,'debug_plots') || isempty(param.layer_tracker.debug_plots)
  param.layer_tracker.debug_plots = {};
end

if ~isfield(param.layer_tracker,'debug_out_dir') || isempty(param.layer_tracker.debug_out_dir)
  param.layer_tracker.debug_out_dir = 'layer_tracker';
end
debug_out_dir = param.layer_tracker.debug_out_dir;

%  .echogram_img: To choose an image besides the base (0) image
if ~isfield(param.layer_tracker,'echogram_img') || isempty(param.layer_tracker.echogram_img)
  param.layer_tracker.echogram_img = 0;
end

%  .echogram_source: string containing location of echogram data used for
%  tracking
if ~isfield(param.layer_tracker,'echogram_source') || isempty(param.layer_tracker.echogram_source)
  param.layer_tracker.echogram_source = 'qlook';
end

if ~isfield(param.layer_tracker,'frm_types') || isempty(param.layer_tracker.frm_types)
  param.layer_tracker.frm_types = {-1,-1,-1,-1,-1};
end

%  .layer_params: layerparams structure of where to store the output using
%  opsCopyLayers.m
if ~isfield(param.layer_tracker,'layer_params') || isempty(param.layer_tracker.layer_params)
  param.layer_tracker.layer_params = [];
end
if ~isfield(param.layer_tracker.layer_params,'source') || isempty(param.layer_tracker.layer_params.source)
  param.layer_tracker.layer_params.source = 'layerdata';
end
if ~any(strcmpi(param.layer_tracker.layer_params.source,{'ops','layerdata','lidar','records','echogram'}))
  error('Unsupported output param.layer_tracker.layer_params.source = ''%s'', but must be one of ''ops'',''layerdata'',''lidar'',''records'',''echogram''.', param.layer_tracker.layer_params.source);
end
if ~isfield(param.layer_tracker.layer_params,'layerdata_source') || isempty(param.layer_tracker.layer_params.layerdata_source)
  param.layer_tracker.layer_params.layerdata_source = 'layer';
end
  
%  .overlap: nonnegative scalar integer indicating the number of range
%  lines to load before and after the current set of frames in order to
%  reduce edge effects (if data are not available because this is the first
%  or last frame or the data files for the overlapping data are missing,
%  then the overlap is set to zero for this side).
if ~isfield(param.layer_tracker,'overlap') || isempty(param.layer_tracker.overlap)
  param.layer_tracker.overlap = 0;
end

%  .surf_layer: layer parameter structure for loading a layer with
%  opsLoadLayers.m
if ~isfield(param.layer_tracker,'surf_layer') || isempty(param.layer_tracker.surf_layer)
  param.layer_tracker.surf_layer = [];
end

%  .track_per_task: Positive integer specifying the number of tracks to
%  process per cluster task. Default is inf which means each task will
%  process all of the specified param.layer_tracker.track{:} commands.
if ~isfield(param.layer_tracker,'track_per_task') || isempty(param.layer_tracker.track_per_task)
  param.layer_tracker.track_per_task = inf;
end

%% Input Checks: layer_tracker.track field
% ======================================================================

if ~isfield(param.layer_tracker,'track') || isempty(param.layer_tracker.track)
  param.layer_tracker.track = {};
end
if isstruct(param.layer_tracker.track)
  param.layer_tracker.track = {param.layer_tracker.track};
end

for track_idx = 1:length(param.layer_tracker.track)
  
  track = merge_structs(param.qlook.surf,param.layer_tracker.track{track_idx});
  
  % profile: default is the profile named after the system (e.g. accum,
  % kaband, kuband, rds, or snow), otherwise loads preset configuration
  if ~isfield(track,'profile') || isempty(track.profile)
    track.profile = ct_output_dir(param.radar_name);
  end
  
  track = merge_structs(layer_tracker_profile(param,track.profile), track);
  
  if ~isfield(track,'en') || isempty(track.en)
    % If true, tracking will be done on this segment. If false, then no
    % tracking is done. Default is true.
    track.en = true;
  end
  if ~track.en
    continue;
  end
  
  %  .age: override age in output layer (see layerdata for field info)
  if ~isfield(track,'age') || isempty(track.age)
    track.age = [];
  end
  %  .age_source: override age source in output layer (see layerdata for
  %  field info)
  if ~isfield(track,'age_source') || isempty(track.age_source)
    track.age_source = [];
  end
  
  %  .compress: double scalar (default is empty), empty matrix disables,
  %  compress values to a limited range from [0 to .compress]
  if ~isfield(track,'compress') || isempty(track.compress)
    track.compress = [];
  end
  
  %  .crossover: struct controlling crossover loading
  if ~isfield(track,'crossover') || isempty(track.crossover)
    track.crossover = [];
  end
  %  .crossover.cutoff: scalar integer, default is 50, layer may go plus or
  %  minus this many bins from the crossover ground truth
  if ~isfield(track.crossover,'cutoff') || isempty(track.crossover.cutoff)
    track.crossover.cutoff = 50;
  end
  %  .crossover.en: enable loading of crossovers
  if ~isfield(track.crossover,'en') || isempty(track.crossover.en)
    track.crossover.en = false;
  end
  %  .crossover.gps_time_good_eval: function which returns good/bad based
  %  on crossover gps time.
  if ~isfield(track.crossover,'gps_time_good_eval') || isempty(track.crossover.gps_time_good_eval)
    track.crossover.gps_time_good_eval = @(x) true;
  end
  %  .crossover.name: layer name to load crossovers for
  if ~isfield(track.crossover,'name') || isempty(track.crossover.name)
    track.crossover.name = 'bottom';
  end
  %  .crossover.season_names_bad: cell array of strings with bad seasons to
  %  not include in crossovers
  if ~isfield(track.crossover,'season_names_bad') || isempty(track.crossover.season_names_bad)
    track.crossover.season_names_bad = {};
  end
  
  if ~isfield(track,'data_noise_en') || isempty(track.data_noise_en)
    % If true, then a matrix data_noise will be created which will go through
    % all the same operations as data except no "sidelobe" and no "feedthru"
    % masking will be done. This is sometimes necessary to enable when
    % sidelobe or feedthru remove too much data so that the noise estimatation
    % process in the tracker does not function properly. Currently only
    % tracker_threshold makes use of data_noise.
    track.data_noise_en = false;
  end
  
  %  .debug_time_guard: Vertical band around layer in debug plot
  if ~isfield(track,'debug_time_guard') || isempty(track.debug_time_guard)
    track.debug_time_guard = 50e-9;
  end
  param.layer_tracker.debug_time_guard = track.debug_time_guard;
  
  %  .desc: override description in output layer (see layerdata for
  %  field info)
  if ~isfield(track,'desc') || isempty(track.desc)
    track.desc = [];
  end
  
  %  .detrend: optional detrending fields (NEED MORE DESCRIPTION HERE)
  if ~isfield(track,'detrend') || isempty(track.detrend)
    track.detrend = [];
  end
  
  %  .emphasize_last: structure controlling emphasize last bins, default is
  %  empty which disables
  %
  %  .emphasize_last.threshold: scalar threshold value
  %
  %  .emphasize_last.shift: scalar integer representing the number of bins
  %  to shift the emphasis scaling (usually a negative)
  if ~isfield(track,'emphasize_last') || isempty(track.emphasize_last)
    track.emphasize_last = [];
  end
    
  if ~isfield(track,'feedthru') || isempty(track.feedthru)
    track.feedthru = [];
  end
  
  if ~isfield(track,'filter') || isempty(track.filter)
    track.filter = [1 1];
  end
  if length(track.filter) == 1
    warning('Deprecated surf.filter format. Should specify 2 element vector that specifies the multilooks in [cross-track along-track].');
    track.filter = [1 track.filter(1)];
  end
  if any(mod(track.filter,2) == 0)
    error('Surface filter lengths must be odd. layer_tracker.track.filter = [%d %d].', layer_tracker.track.filter);
  end
  
  if ~isfield(track,'filter_trim') || isempty(track.filter_trim)
    track.filter_trim = [0 0];
  end
  
  if ~isfield(track,'fixed_value') || isempty(track.fixed_value)
    track.fixed_value = 0;
  end
  
  %  .ground_truth: struct controlling ground truth loading
  if ~isfield(track,'ground_truth') || isempty(track.ground_truth)
    track.ground_truth = [];
  end
  %  .ground_truth.en: enable loading of ground truth
  if ~isfield(track.ground_truth,'en') || isempty(track.ground_truth.en)
    track.ground_truth.en = false;
  end
  %  .ground_truth.layers: layer struct array to load ground truth from
  if ~isfield(track.ground_truth,'layers') || isempty(track.ground_truth.layers)
    track.ground_truth.layers = [];
  end
  %  .ground_truth.cutoff: integer vector the same length as
  %  .ground_truth.layers, default is 100, layer may go plus or minus this
  %  many bins from the ground truth
  if ~isfield(track.ground_truth,'cutoff') || isempty(track.ground_truth.cutoff)
    track.ground_truth.cutoff = 50;
  end
  if length(track.ground_truth.cutoff) == 1
    % If only 1 element specified, then assume the same cutoff should be
    % used for all ground truth layers.
    track.ground_truth.cutoff = track.ground_truth.cutoff*ones(size(track.ground_truth.layers));
  end
  if numel(track.ground_truth.layers) ~= numel(track.ground_truth.cutoff)
    error('The number of ground truth layers must match the number of elements in the cutoff vector. numel(track.ground_truth.layers)=%d ~= numel(track.ground_truth.cutoff)=%d.',numel(track.ground_truth.layers),numel(track.ground_truth.cutoff));
  end
  
  %  .group_name: override group name in output layer (see layerdata for
  %  field info)
  if ~isfield(track,'group_name') || isempty(track.group_name)
    track.group_name = [];
  end

  %  .ice_mask: struct controlling ice mask loading
  if ~isfield(track,'ice_mask') || isempty(track.ice_mask)
    track.ice_mask = [];
  end
  %  .ice_mask.en: enable loading of ice mask
  if ~isfield(track.ice_mask,'en') || isempty(track.ice_mask.en)
    track.ice_mask.en = false;
  end
  
  if ~isfield(track,'init') || isempty(track.init)
    track.init = [];
  end
  if ~isfield(track.init,'method') || isempty(track.init.method)
    track.init.method = 'max';
  end
  if ~isfield(track.init,'snake_rng') || isempty(track.init.snake_rng)
    track.init.snake_rng = [-2e-7 2e-7];
  end
  if ~isfield(track.init,'dem_layer') || isempty(track.init.dem_layer)
    track.init.dem_layer = '';
  end
  if isfield(track.init.dem_layer,'source') ...
      && ~any(strcmpi(track.init.dem_layer.source,{'ops','layerdata','lidar','records','echogram'}))
    error('Unsupported output track.init.dem_layer.source = ''%s'', but must be one of ''ops'',''layerdata'',''lidar'',''records'',''echogram''.', track.init.dem_layer.source);
  end
  if ~any(strcmpi(track.init.method,{'max','nan','snake','medfilt','dem'}))
    error('Unsupported surface init method %s. Options are max, nan, snake, medfilt, or dem. max is default.', track.init.method);
  end
  if ~isfield(track.init,'max_diff') || isempty(track.init.max_diff)
    track.init.max_diff = inf;
  end
  if ~isfield(track.init,'max_diff_method') || isempty(track.init.max_diff_method)
    if strcmpi(track.init.method,{'dem'}) || ~isempty(track.init.dem_layer)
      % If the initial surface is from a dem or reference layer, the default
      % method for outliers is to use merge_vectors to fill the outliers in.
      track.init.max_diff_method = 'merge_vectors';
    else
      % Otherwise the default method is just to interpolate between the good
      % points that exist to fill the outliers in.
      track.init.max_diff_method = 'interp_finite';
    end
  end
  if ~any(strcmpi(track.init.max_diff_method,{'merge_vectors','interp_finite'}))
    error('Unsupported max diff method %s. Options are merge_vectors, interp_finite. The default is interp_finite unless a dem or reference layer is provided.', track.init.max_diff_method);
  end
  
  if ~isfield(track,'lsm') || isempty(track.lsm)
    track.lsm = [];
  end
  % lsm.use_mean_surf_en: logical scalar, default false. If true, tracker
  % uses the mean surface to initialize lsm.y
  if ~isfield(track.lsm,'use_mean_surf_en') || isempty(track.lsm.use_mean_surf_en)
    track.lsm.use_mean_surf_en = false;
  end
  % lsm.y: initial surface layer bin
  if ~isfield(track.lsm,'y') || isempty(track.lsm.y)
    track.lsm.y = 1;
  end
  
  if ~isfield(track,'max_bin') || isempty(track.max_bin)
    track.max_bin = inf;
  elseif isstruct(track.max_bin)
    if ~isfield(track.max_bin,'existence_check')
      track.max_bin.existence_check = false;
    end
  end
  
  % max_rng: two element numeric vector, default is [0 0]. After the layer
  % is tracked, this allows the tracked layer to be updated with the
  % maximum value in a window around the tracked layer. Specifies the range
  % of bins [start stop] to search for a maximum relative to the tracked
  % layer. Negative values are before the tracked layer and positive values
  % are after the tracked layer. To not update the tracked layer set this
  % to [0 0]. A common use is to use the threshold tracker and then follow
  % this with a positive range to search for a peak after the treshold was
  % exceeded. For example, [0 0.1e-6] with max_rng_units of 'time' would
  % cause the layer to be updated to the location of the maximum value that
  % occurs in the range from where the threshold was exceeded to 0.1e-6
  % seconds after it was exceeded.
  if ~isfield(track,'max_rng') || isempty(track.max_rng)
    track.max_rng = [0 0];
  end
  
  if ~isfield(track,'max_rng_filter') || isempty(track.max_rng_filter)
    track.max_rng_filter = track.filter;
  end
  
  % max_rng_units: string, default 'time'. Specifies the units of max_rng.
  % Options are 'time' (units of seconds two way travel time) and 'bins'
  % (range bins or rows).
  if ~isfield(track,'max_rng_units') || isempty(track.max_rng_units)
    track.max_rng_units = 'time';
  end
  
  if ~isfield(track,'medfilt') || isempty(track.medfilt)
    % Like medfilt1 except it handles the edges of the frame better
    track.medfilt = 0;
  end
  if ~isfield(track,'medfilt_threshold') || isempty(track.medfilt_threshold)
    % medfilt_threshold: the point is compared to the medfilt1 result and if
    % the point is > medfilt_threshold from medfilt1, then the point is
    % replaced with the medfilt1 result. The two extremes are:
    %   0 makes medfilt act like medfilt1
    %   inf effectively disables the medfilt operation
    track.medfilt_threshold = 0;
  end
  
  if ~isfield(track,'method') || isempty(track.method)
    track.method = '';
  end
  
  if ~isfield(track,'min_bin') || isempty(track.min_bin)
    track.min_bin = 0;
  elseif isstruct(track.min_bin)
    if ~isfield(track.min_bin,'existence_check')
      track.min_bin.existence_check = false;
    end
  end
  
  %  .mult_suppress: struct controlling surface multiple suppression
  if ~isfield(track,'mult_suppress') || isempty(track.mult_suppress)
    track.mult_suppress = [];
  end
  %  .mult_suppress.en: enable surface multiple suppression
  if ~isfield(track.mult_suppress,'en') || isempty(track.mult_suppress.en)
    track.mult_suppress.en = false;
  end
  %  .mult_suppress.param: param field to pass to mult_suppress.m
  if ~isfield(track.mult_suppress,'param') || isempty(track.mult_suppress.param)
    track.mult_suppress.param = [];
  end
  
  if ~isfield(track,'name') || isempty(track.name)
    track.name = sprintf('t%03d', track_idx);
  end
  
  % prefilter_trim: two element numeric vector of nonnegative numbers,
  % default is [0 0]. The first values specifies how much to trim off the
  % start of each range line before any processing occurs and the second
  % number specifies how much to trim off the end of each range line.
  % Useful, when it is known that there are artifacts at the start/stop of
  % each range line that will confuse the tracker and the layer to be
  % tracked does not go into these regions of the image. The default value
  % [0 0] effectively disables the prefilter_trim since nothing will be
  % trimmed off.
  if ~isfield(track,'prefilter_trim') || isempty(track.prefilter_trim)
    track.prefilter_trim = [0 0];
  end
  
  % prefilter_trim_units: string, default 'time'. Specifies the units of
  % prefilter_trim. Options are 'time' (units of seconds two way travel
  % time) and 'bins' (range bins or rows).
  if ~isfield(track,'prefilter_trim_units') || isempty(track.prefilter_trim_units)
    track.prefilter_trim_units = 'time';
  end
  
  if ~isfield(track,'sidelobe_rows') || isempty(track.sidelobe_rows) || ~isfield(track,'sidelobe_dB') || isempty(track.sidelobe_dB)
    track.sidelobe_dB = [];
    track.sidelobe_rows = [];
  end
  
  if ~isfield(track,'smooth_sgolayfilt') || isempty(track.smooth_sgolayfilt)
    track.smooth_sgolayfilt = [];
  end
  
  if ~isfield(track,'snake_rng') || isempty(track.snake_rng)
    track.snake_rng = [-2e-7 2e-7];
  end
  
  %  .surf_suppress: structure controlling surface suppression. Default is
  %  []. Empty matrix disables surface suppression.
  %
  % .eval_cmd: evaluation
  if ~isfield(track,'surf_suppress') || isempty(track.surf_suppress)
    track.surf_suppress = [];
  end
  
  if ~isfield(track,'threshold') || isempty(track.threshold)
    track.threshold = 15;
  end
  
  if ~isfield(track,'threshold_noise_rng') || isempty(track.threshold_noise_rng)
    track.threshold_noise_rng = [0 -inf -1];
  end
  
  % viterbi: structure controlling operation of the viterbi method tracker
  if ~isfield(track,'viterbi') || isempty(track.viterbi)
    track.viterbi = [];
  end
  
  % viterbi.transition_weight: controls the smoothness weighting, larger
  % numbers cause the layer to be smoother
  if ~isfield(track.viterbi,'transition_weight') || isempty(track.viterbi.transition_weight)
    track.viterbi.transition_weight = 1;
  end
  
  param.layer_tracker.track{track_idx} = track;
end
