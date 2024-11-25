function success = layer_tracker_task(param)
% success = layer_tracker_task(param)
%
% layer_tracker_task is used to load and prepare the data and metadata and
% run the tracker. See run_layer_tracker.m.
%
% param: parameter structure from parameter spreadsheet
%   param.layer_tracker.echogram_source: The normal cluster mode is for
%   this to be a ct_filename_out compatible string. The normal
%   qlook_combine_task mode is for this to be a structure and this function
%   returns the tracked surface and does not save the result.
%
% success:
%   In cluster mode: logical scalar, true when task completes successfully
%   In qlook_combine_task mode: surface twtt corresponding to the
%   param.layer_tracker.echogram_source.GPS_time.
%
% Authors: Anjali Pare, John Paden
%
% See also: layer_tracker.m, layer_tracker_combine_task.m,
% layer_tracker_task.m, layer_tracker_input_check.m,
% layer_tracker_profile.m, run_layer_tracker.m, run_layer_tracker_tune.m

%% Input Checks: track field
% =====================================================================

physical_constants('c');

if isstruct(param.layer_tracker.echogram_source)
  % echogram_source is the data structure
  param.layer_tracker.track = {param.qlook.surf};
  layer_tracker_input_check;
end

tracked_images_en = any(strcmp('tracked_images',param.layer_tracker.debug_plots));
visible_en = any(strcmp('visible',param.layer_tracker.debug_plots));
if tracked_images_en
  h_fig = get_figures(1,visible_en);
end

%% Create output directory paths
if strcmp(param.layer_tracker.layer_params.source,'ops')
  tmp_out_fn_dir_dir = ct_filename_out(param,'ops','layer_tracker_tmp');
  param.layer_tracker.layer_params.layerdata_source = 'ops'; % Only used for stdout
else
  tmp_out_fn_dir_dir = ct_filename_out(param,param.layer_tracker.layer_params.layerdata_source,'layer_tracker_tmp');
end

%% Load echogram data
if isstruct(param.layer_tracker.echogram_source)
  % echogram_source is the radar image/data structure
  % =======================================================================
  mdata = param.layer_tracker.echogram_source;
  frm_str = {sprintf('%s_%03d',param.day_seg,param.layer_tracker.frms)};
  frm_start = 1;
  frm_stop = length(mdata.GPS_time);
  param.layer_tracker.tracks_in_task = 1;
  dt = mdata.Time(2) - mdata.Time(1);
  
else
  % Load in the specified frames from files
  % =======================================================================
  
  % Create input directory paths
  in_fn_dir = ct_filename_out(param,param.layer_tracker.echogram_source,'');
  
  mdata = [];
  mdata.GPS_time = [];
  mdata.Data = [];
  mdata.Time = [];
  mdata.Elevation=[];
  mdata.Latitude = [];
  mdata.Longitude = [];
  mdata.Roll = [];
  % Keep track of start/stop index for each frame
  frm_start = zeros(size(param.layer_tracker.frms));
  frm_stop = zeros(size(param.layer_tracker.frms));
  frm_str = cell(size(param.layer_tracker.frms));
  for frm_idx = 1:length(param.layer_tracker.frms)
    frm = param.layer_tracker.frms(frm_idx);
    
    % Load the current frame
    frm_str{frm_idx} = sprintf('%s_%03d',param.day_seg,frm);
    if param.layer_tracker.echogram_img == 0
      data_fn = fullfile(in_fn_dir, sprintf('Data_%s.mat',frm_str{frm_idx}));
    else
      data_fn = fullfile(in_fn_dir, sprintf('Data_img_%02d_%s.mat',param.layer_tracker.echogram_img,frm_str{frm_idx}));
    end
    fprintf('Loading %s (%s)\n', data_fn, datestr(now));
    if frm_idx == 1
      mdata = load_L1B(data_fn);
      frm_start(frm_idx) = 1;
      frm_stop(frm_idx) = length(mdata.GPS_time);
      if length(mdata.Time) >= 2
        dt = mdata.Time(2) - mdata.Time(1);
      else
        dt = NaN;
      end
      
    else
      tmp_data = load_L1B(data_fn);
      
      Nx = length(tmp_data.GPS_time);
      frm_start(frm_idx) = length(mdata.GPS_time)+1;
      frm_stop(frm_idx) = length(mdata.GPS_time)+Nx;
      
      mdata.GPS_time(1,end+(1:Nx)) = tmp_data.GPS_time;
      mdata.Elevation(1,end+(1:Nx)) = tmp_data.Elevation;
      mdata.Latitude(1,end+(1:Nx)) = tmp_data.Latitude;
      mdata.Longitude(1,end+(1:Nx)) = tmp_data.Longitude;
      mdata.Roll(1,end+(1:Nx)) = tmp_data.Roll;
      mdata.Surface(1,end+(1:Nx)) = tmp_data.Surface;
      
      % Handle time axis that changes from one frame to the next
      min_time = min(tmp_data.Time(1),mdata.Time(1));
      if isnan(dt) && length(mdata.Time) >= 2
        dt = mdata.Time(2) - mdata.Time(1);
      end
      Time = (mdata.Time(1) - dt*round((mdata.Time(1) - min_time)/dt) ...
        : dt : max(tmp_data.Time(end),mdata.Time(end))).';
      % Interpolate data to new time axes
      warning off;
      mdata.Data = interp1(mdata.Time,mdata.Data,Time);
      tmp_data.Data = interp1(tmp_data.Time,tmp_data.Data,Time);
      warning on;
      mdata.Time = Time;
      mdata.Data(:,end+(1:Nx)) = tmp_data.Data;
    end
  end
  
  overlap = [0 0];
  if param.layer_tracker.frms(1) > 1 && param.layer_tracker.overlap > 0
    frm = param.layer_tracker.frms(1)-1;
    
    % Load the previous frame
    frm_str{frm_idx} = sprintf('%s_%03d',param.day_seg,frm);
    if param.layer_tracker.echogram_img == 0
      data_fn = fullfile(in_fn_dir, sprintf('Data_%s.mat',frm_str{frm_idx}));
    else
      data_fn = fullfile(in_fn_dir, sprintf('Data_img_%02d_%s.mat',param.layer_tracker.echogram_img,frm_str{frm_idx}));
    end
    if exist(data_fn,'file')
      fprintf('Loading previous frame %s (%s)\n', data_fn, datestr(now));
      tmp_data = load_L1B(data_fn);
      
      overlap(1) = min(param.layer_tracker.overlap,length(tmp_data.GPS_time));
      mdata.GPS_time = [tmp_data.GPS_time(end-overlap(1)+1:end) mdata.GPS_time];
      mdata.Elevation = [tmp_data.Elevation(end-overlap(1)+1:end) mdata.Elevation];
      mdata.Latitude = [tmp_data.Latitude(end-overlap(1)+1:end) mdata.Latitude];
      mdata.Longitude = [tmp_data.Longitude(end-overlap(1)+1:end) mdata.Longitude];
      mdata.Roll = [tmp_data.Roll(end-overlap(1)+1:end) mdata.Roll];
      mdata.Surface = [tmp_data.Surface(end-overlap(1)+1:end) mdata.Surface];
      
      % Handle time axis that changes from one frame to the next
      min_time = min(tmp_data.Time(1),mdata.Time(1));
      if isnan(dt) && length(mdata.Time) >= 2
        dt = mdata.Time(2) - mdata.Time(1);
      end
      Time = (mdata.Time(1) - dt*round((mdata.Time(1) - min_time)/dt) ...
        : dt : max(tmp_data.Time(end),mdata.Time(end))).';
      % Interpolate data to new time axes
      warning off;
      mdata.Data = interp1(mdata.Time,mdata.Data,Time);
      tmp_data.Data = interp1(tmp_data.Time,tmp_data.Data(:,end-overlap(1)+1:end),Time);
      warning on;
      mdata.Time = Time;
      mdata.Data = [tmp_data.Data mdata.Data];
    end
  end
  frames = frames_load(param);
  if param.layer_tracker.frms(end) <= length(frames.frame_idxs) && param.layer_tracker.overlap > 0
    frm = param.layer_tracker.frms(end)+1;
    
    % Load the next frame
    frm_str{frm_idx} = sprintf('%s_%03d',param.day_seg,frm);
    if param.layer_tracker.echogram_img == 0
      data_fn = fullfile(in_fn_dir, sprintf('Data_%s.mat',frm_str{frm_idx}));
    else
      data_fn = fullfile(in_fn_dir, sprintf('Data_img_%02d_%s.mat',param.layer_tracker.echogram_img,frm_str{frm_idx}));
    end
    if exist(data_fn,'file')
      fprintf('Loading next frame %s (%s)\n', data_fn, datestr(now));
      tmp_data = load_L1B(data_fn);
      
      overlap(2) = min(param.layer_tracker.overlap,length(tmp_data.GPS_time));
      mdata.GPS_time(1,end+(1:overlap(2))) = tmp_data.GPS_time(1:overlap(2));
      mdata.Elevation(1,end+(1:overlap(2))) = tmp_data.Elevation(1:overlap(2));
      mdata.Latitude(1,end+(1:overlap(2))) = tmp_data.Latitude(1:overlap(2));
      mdata.Longitude(1,end+(1:overlap(2))) = tmp_data.Longitude(1:overlap(2));
      mdata.Roll(1,end+(1:overlap(2))) = tmp_data.Roll(1:overlap(2));
      mdata.Surface(1,end+(1:overlap(2))) = tmp_data.Surface(1:overlap(2));
      
      % Handle time axis that changes from one frame to the next
      min_time = min(tmp_data.Time(1),mdata.Time(1));
      if isnan(dt) && length(mdata.Time) >= 2
        dt = mdata.Time(2) - mdata.Time(1);
      end
      Time = (mdata.Time(1) - dt*round((mdata.Time(1) - min_time)/dt) ...
        : dt : max(tmp_data.Time(end),mdata.Time(end))).';
      % Interpolate data to new time axes
      warning off;
      mdata.Data = interp1(mdata.Time,mdata.Data,Time);
      tmp_data.Data = interp1(tmp_data.Time,tmp_data.Data(:,(1:overlap(2))),Time);
      warning on;
      mdata.Time = Time;
      mdata.Data(:,end+(1:overlap(2))) = tmp_data.Data;
    end
  end

end
mdata = echo_param_update(mdata,param);
Nx = size(mdata.Data,2);
if isnan(dt)
  warning('This set of frame(s) does not have a fast-time axis because the data records were all bad.');
  mdata.Time = [0 1];
end


%% Track
% =========================================================================
for track_idx = param.layer_tracker.tracks_in_task
  track = param.layer_tracker.track{track_idx};
  orig_track = track;
  layer_param = param;
  % Load layer data from the frame before and after the current frame.
  % opsLoadLayers will check to see if the frame exists or not so we don't
  % need to worry about specifying frames that do not exist.
  layer_param.cmd.frms = [param.layer_tracker.frms(1)-1 param.layer_tracker.frms param.layer_tracker.frms(end)+1];
  
  %% Track: Load reference surface
  if isfield(track,'init') && isfield(track.init,'dem_layer') ...
      && ~isempty(track.init.dem_layer)
    layers = opsLoadLayers(layer_param,track.init.dem_layer);
    
    % Ensure that layer gps times are monotonically increasing
    lay_idx = 1;
    layers_fieldnames = {'gps_time','twtt','elev','lat','lon','type','quality','frm'};
    [~,unique_idxs] = unique(layers(lay_idx).gps_time);
    for field_idx = 1:length(layers_fieldnames)-1
      if ~isempty(layers(lay_idx).(layers_fieldnames{field_idx}))
        layers(lay_idx).(layers_fieldnames{field_idx}) = layers(lay_idx).(layers_fieldnames{field_idx})(unique_idxs);
      end
    end
    if length(layers(lay_idx).gps_time) < 2
      mdata.Surface = nan(size(mdata.GPS_time));
    else
      mdata.Surface = interp_finite(interp1(layers(lay_idx).gps_time,layers(lay_idx).twtt,mdata.GPS_time), NaN);
    end
  end
  
  %% Track: Load ocean mask, land DEM, sea surface DEM
  if isfield(track,'init') && strcmpi(track.init.method,'dem')
    if isstruct(param.layer_tracker.echogram_source)
      % Only do this if it has not already been done in layer_tracker.m
      global gdem;
      if isempty(gdem) || ~isa(gdem,'dem_class') || ~isvalid(gdem)
        gdem = dem_class(param,500);
      end
      gdem.set_res(500);
      gdem.ocean_mask_mode = 'l';
      
      gdem_str = sprintf('%s:%s:%s_%03d_%03d',param.radar_name,param.season_name,param.day_seg,param.layer_tracker.frms([1 end]));
      if ~strcmpi(gdem_str,gdem.name)
        gdem.set_vector(mdata.Latitude,mdata.Longitude,gdem_str);
      end
    end
  end
  
  %% Track: Interpolate DEM, ocean mask, and mean sea level
  if strcmpi(track.init.method,'dem')
    if isstruct(param.layer_tracker.echogram_source)
      % If layer_tracker.m did not load dem:
      gdem.set_vector(mdata.Latitude,mdata.Longitude);
      [land_dem,msl,ocean_mask] = gdem.get_vector_dem();
    else
      % If layer_tracker.m did load dem:
      land_dem = interp1(param.layer_tracker.gps_time,param.layer_tracker.land_dem,mdata.GPS_time);
      ocean_mask = interp1(param.layer_tracker.gps_time,double(param.layer_tracker.ocean_mask),mdata.GPS_time);
      msl = interp1(param.layer_tracker.gps_time,param.layer_tracker.msl,mdata.GPS_time);
    end

    ocean_mask = logical(ocean_mask);
    % Merge land surface and sea surface DEMs
    track.dem = double(land_dem);
    track.dem(ocean_mask) = msl(ocean_mask);
    track.dem = (mdata.Elevation - track.dem) / (c/2);
    track.dem = interp1(mdata.Time,1:length(mdata.Time),track.dem + track.init.dem_offset,'linear','extrap');
    track.dem = interp_finite(track.dem,1);
  end
  
  %% Track: Ice mask calculation
  if track.ice_mask.en
    if isstruct(param.layer_tracker.echogram_source)
      % If layer_tracker.m did not load ice_mask:
      if strcmp(track.ice_mask.type,'bin')
        mask = load(track.ice_mask.mat_fn,'R','X','Y','proj');
        [fid,msg] = fopen(track.ice_mask.fn,'r');
        if fid < 1
          fprintf('Could not open file %s\n', track.ice_mask.fn);
          error(msg);
        end
        mask.maskmask = logical(fread(fid,[length(mask.Y),length(mask.X)],'uint8'));
        fclose(fid);
      else
        [mask.maskmask,mask.R,~] = geotiffread(track.ice_mask.fn);
        mask.proj = geotiffinfo(track.ice_mask.fn);
      end
      [mask.x, mask.y] = projfwd(mask.proj, mdata.Latitude, mdata.Longitude);
      mask.X = mask.R(3,1) + mask.R(2,1)*(1:size(mask.maskmask,2));
      mask.Y = mask.R(3,2) + mask.R(1,2)*(1:size(mask.maskmask,1));
      [mask.X,mask.Y] = meshgrid(mask.X,mask.Y);
      ice_mask.mask = round(interp2(mask.X, mask.Y, double(mask.maskmask), mask.x, mask.y));
      ice_mask.mask(isnan(ice_mask.mask)) = 1;
      track.ice_mask = ice_mask.mask;
    else
      % If layer_tracker.m did load ice_mask:
      track.ice_mask = interp1(param.layer_tracker.gps_time,param.layer_tracker.ice_mask,mdata.GPS_time);
    end
  else
    track.ice_mask = ones(1,Nx);
  end
  
  %% Track: Ground Truth
  if track.ground_truth.en
    ground_truth = opsLoadLayers(layer_param,track.ground_truth.layers);
    % Convert ground_truths twtt to source twtt and then convert from twtt
    % to rows/bins
    cols = round(interp1(mdata.GPS_time,1:length(mdata.GPS_time), ground_truth.gps_time));
    rows = round(interp1(mdata.Time,1:length(mdata.Time), ground_truth.twtt));
    track.ground_truths = [cols; rows; track.ground_truth.cutoff*ones(size(cols))];
    track.ground_truths = track.ground_truths(:,isfinite(cols));
  else
    track.ground_truths = zeros(3,0);
  end
  
  %% Track: Crossover loading
  if track.crossover.en
    if isstruct(param.layer_tracker.echogram_source)
      % Crossovers not loaded during layer_tracker.m
      sys = ct_output_dir(param.radar_name);
      ops_param = [];
      ops_param.properties.search_str = frm_str{frm_idx};
      ops_param.properties.location = param.post.ops.location;
      ops_param.properties.season = param.season_name;
      [status,ops_data_segment] = opsGetFrameSearch(sys,ops_param);
      if status == 1
        ops_param = [];
        ops_param.properties.location = param.post.ops.location;
        ops_param.properties.lyr_name = track.crossover.name;
        ops_param.properties.frame = frm_str;
        ops_param.properties.segment_id = ops_data_segment.properties.segment_id;
        [status,ops_data] = opsGetCrossovers(sys,ops_param);
        if status == 1
          ops_data.properties.twtt = ops_data.properties.twtt(:).';
          ops_data.properties.source_point_path_id = double(ops_data.properties.source_point_path_id(:).');
          ops_data.properties.cross_point_path_id = double(ops_data.properties.cross_point_path_id(:).');
          ops_data.properties.source_elev = ops_data.properties.source_elev.';
          ops_data.properties.cross_elev = ops_data.properties.cross_elev.';
          
          % Get the OPS
          ops_param = [];
          ops_param.properties.location = param.post.ops.location;
          ops_param.properties.point_path_id = [ops_data.properties.source_point_path_id ops_data.properties.cross_point_path_id];
          [status,ops_data_gps_time] = opsGetPath(sys,ops_param);
          
          source_gps_time = zeros(size(ops_data.properties.source_point_path_id));
          crossover_gps_time = zeros(size(ops_data.properties.source_point_path_id));
          good_mask = true(size(ops_data.properties.source_point_path_id));
          % Ensure crossover season is good
          for idx = 1:length(ops_data.properties.source_point_path_id)
            match_idx = find(ops_data.properties.source_point_path_id(idx) == ops_data_gps_time.properties.id,1);
            source_gps_time(idx) = ops_data_gps_time.properties.gps_time(match_idx);
            match_idx = find(ops_data.properties.cross_point_path_id(idx) == ops_data_gps_time.properties.id,1);
            crossover_gps_time(idx) = ops_data_gps_time.properties.gps_time(match_idx);
            if any(strcmp(ops_data.properties.season_name{idx}, track.crossover.season_names_bad))
              good_mask(idx) = false;
            end
          end
          % Ensure crossover gps_time is good
          good_mask = good_mask & track.crossover.gps_time_good_eval(crossover_gps_time);
          
          % Convert crossover twtt to source twtt and then convert from twtt
          % to rows/bins
          cols = round(interp1(mdata.GPS_time,1:length(mdata.GPS_time), source_gps_time(good_mask)));
          rows = round(interp1(mdata.Time,1:length(mdata.Time), ops_data.properties.twtt(good_mask) ...
            + (ops_data.properties.source_elev(good_mask) - ops_data.properties.cross_elev(good_mask))*2/c ));
          track.crossovers = [cols; rows];
          track.crossovers(3,:) = track.viterbi.gt_cutoff;
        end
      end
      
    else
      % Crossovers already loaded during layer_tracker.m
      % Ensure season of the crossing line is good
      good_mask = true(size(param.layer_tracker.crossover.twtt));
      for idx = 1:length(param.layer_tracker.crossover.twtt)
        if any(strcmp(param.layer_tracker.crossover.season_name{idx}, track.crossover.season_names_bad))
          good_mask(idx) = false;
        end
      end
      % Ensure gps_time of the crossing line is good
      good_mask = good_mask & track.crossover.gps_time_good_eval(param.layer_tracker.crossover.crossover_gps_time);
      
      % Convert crossover twtt to source twtt and then convert from twtt
      % to rows/bins
      cols = round(interp1(mdata.GPS_time,1:length(mdata.GPS_time), param.layer_tracker.crossover.source_gps_time(good_mask)));
      rows = round(interp1(mdata.Time,1:length(mdata.Time), param.layer_tracker.crossover.twtt(good_mask) ...
        + (param.layer_tracker.crossover.source_elev(good_mask) - param.layer_tracker.crossover.cross_elev(good_mask))*2/c ));
      % Crossover with NaN cols is a crossover that is not in this frame,
      % remove any cols that fall outside of this frame
      good_mask = isfinite(cols);
      % Build crossover matrix, track.crossovers
      track.crossovers = [cols(good_mask); rows(good_mask)];
      track.crossovers(3,:) = track.viterbi.gt_cutoff;
      
    end
    
  else
    track.crossovers = zeros(2,0);
  end
  
  %% Track: Multiple Suppression
  if track.mult_suppress.en
    data = lp(echo_mult_suppress(mdata,[],track.mult_suppress),1);
  else
    data = lp(mdata.Data,1);
  end
 
  %% Track: Prefilter trim
  % prefilter_trim: convert prefilter_trim to range bins
  if strcmpi(track.prefilter_trim_units,'bins')
    % Units of range bins (rows)
    prefilter_trim = track.prefilter_trim;
  else
    % Units of time (default)
    if isnan(dt)
      prefilter_trim = [0 0];
    else
      prefilter_trim = round(track.prefilter_trim/dt);
    end
  end
  for rline = 1:Nx
    % Step 1. Sets leading zeros or ~isfinite to NaN
    start_bin = find(isfinite(data(:,rline)) & data(:,rline) ~= 0,1);
    if ~isempty(start_bin)
      % Found finite non-zero value
      stop_bin = min(size(data,1), start_bin+prefilter_trim(1)-1);
      data(1:stop_bin,rline) = NaN;
      
      % Step 2. Sets leading/following zeros or ~isfinite to NaN
      stop_bin = find(isfinite(data(:,rline)) & data(:,rline) ~= 0,1,'last');
      if ~isempty(stop_bin)
        % Found finite non-zero value
        start_bin = max(1, stop_bin-prefilter_trim(2)+1);
        data(start_bin:end,rline) = NaN;
      else
        % No finite non-zero values in this range line
        data(:,rline) = NaN;
      end
      
    else
      % No finite non-zero values in this range line
      data(:,rline) = NaN;
    end
  end
  
  if track.data_noise_en
    data_noise = data;
  end
  
  %% Track: Feed through removal
  if ~isempty(track.feedthru)
    % Interpolate feed through power levels on to data time axis
    feedthru_threshold = interp1(track.feedthru.time,track.feedthru.power_dB,mdata.Time);
    feedthru_threshold = interp_finite(feedthru_threshold,-inf,[],@(x) ~isnan(x));
    
    % Set all data to zero that does not exceed the feed through
    % threshold power
    for rline=1:Nx
      data(data(:,rline) <= feedthru_threshold,rline) = NaN;
    end
  end
  
  %% Track: Detrend
  if isfield(track,'detrend') && ~isempty(track.detrend)
    echo_detrend_data.Data = data;
    echo_detrend_data.Time = mdata.Time;
    echo_detrend_data.Surface = mdata.Surface;
    data = echo_detrend(echo_detrend_data,track.detrend);
  end

  %% Track: Fasttime Cross Correlation (xcorr)
  if isfield(track,'xcorr') && ~isempty(track.xcorr)
    data = echo_xcorr(data,track.xcorr);
  end
  
  %% Track: Sidelobe
  if ~isempty(track.sidelobe_rows)
    mask = sidelobe_mask_mex(single(data),int32(track.sidelobe_rows),single(track.sidelobe_dB));
    data(mask) = NaN;
  end
  
  %% Track: Flatten
  if isfield(track,'flatten') && ~isempty(track.flatten)
    mdata_flatten = [];
    mdata_flatten.param = param;
    mdata_flatten.param.load.frm = param.layer_tracker.frms;
    mdata_flatten.Data = data;
    mdata_flatten.Time = mdata.Time;
    mdata_flatten.GPS_time = mdata.GPS_time;
    [data,resample_field] = echo_flatten(mdata_flatten,track.flatten);
    % Debug to convert to twtt: resample_field = mdata.Time(1) + (resample_field-1)*dt;
    % Flatten supporting fields
    if strcmpi(track.init.method,'dem')
      for rline = 1:Nx
        track.dem(rline) = interp1(resample_field(:,rline),1:size(resample_field,1),track.dem(rline),'linear','extrap');
      end
      for idx = 1:size(track.crossovers,2)
        track.crossovers(2,idx) = interp1(resample_field(:,track.crossovers(1,idx)),1:size(resample_field,1),track.crossovers(2,idx),'linear','extrap');
      end
      for idx = 1:size(track.ground_truths,2)
        track.ground_truths(2,idx) = interp1(resample_field(:,track.ground_truths(1,idx)),1:size(resample_field,1),track.ground_truths(2,idx),'linear','extrap');
      end
    end
  end
  
  %% Track: Max Range Filter
  if ~isequal(track.max_rng_filter,track.filter)
    % Multilooking in cross-track/fast-time
    data_max_rng = lp(nan_fir_dec(10.^(data/10).',ones(1,track.max_rng_filter(1))/track.max_rng_filter(1),1,[],[],[],[],2.0).');
    % Multilooking in along-track
    data_max_rng = lp(nan_fir_dec(10.^(data_max_rng/10),ones(1,track.max_rng_filter(2))/track.max_rng_filter(2),1,[],[],[],[],2.0));
  end
  
  %% Track: Filter
  if track.filter(1) ~= 1
    % Multilooking in cross-track/fast-time
    data = lp(nan_fir_dec(10.^(data/10).',ones(1,track.filter(1))/track.filter(1),1,[],[],[],[],2.0).');
    if track.data_noise_en
      data_noise = lp(nan_fir_dec(10.^(data_noise/10).',ones(1,track.filter(1))/track.filter(1),1,[],[],[],[],2.0).');
    end
  end
  if track.filter(2) ~= 1
    % Multilooking in along-track
    data = lp(nan_fir_dec(10.^(data/10),ones(1,track.filter(2))/track.filter(2),1,[],[],[],[],2.0));
    if track.data_noise_en
      data_noise = lp(nan_fir_dec(10.^(data_noise/10),ones(1,track.filter(2))/track.filter(2),1,[],[],[],[],2.0));
    end
  end
  
  %% Track: Post-filter trim
  for rline = 1:Nx
    start_bin = find(isfinite(data(:,rline)),1);
    if ~isempty(start_bin)
      stop_bin = min(size(data,1), start_bin+track.filter_trim(1)-1);
      data(start_bin:stop_bin,rline) = NaN;
      if track.data_noise_en
        data_noise(start_bin:stop_bin,rline) = NaN;
      end
      if ~isequal(track.max_rng_filter,track.filter)
        data_max_rng(start_bin:stop_bin,rline) = NaN;
      end
    end
    stop_bin = find(isfinite(data(:,rline)),1,'last');
    if ~isempty(stop_bin)
      start_bin = max(1, stop_bin-track.filter_trim(2)+1);
      data(start_bin:stop_bin,rline) = NaN;
      if track.data_noise_en
        data_noise(start_bin:stop_bin,rline) = NaN;
      end
      if ~isequal(track.max_rng_filter,track.filter)
        data_max_rng(start_bin:stop_bin,rline) = NaN;
      end
    end
  end

  %% Track: Surface suppression
  if ~isempty(track.surf_suppress)
    time = mdata.Time;
    for rline = 1:size(data,2)
      surf = mdata.Surface(rline);
      data(:,rline) = data(:,rline) + eval(track.surf_suppress.eval_cmd);
    end
  end

  %% Track: Compress values
  if ~isempty(track.compress)
    data = atan((data-track.compress/2)/2)*track.compress/pi+track.compress/2;
    data(data<0) = 0;
  end

  %% Track: Emphasize last
  if ~isempty(track.emphasize_last)
    last_metric = flipud(cumsum(flipud(data>track.emphasize_last.threshold)));
    last_metric = 1 - last_metric ./ (max(last_metric)+1);
    last_metric = circshift(last_metric,[track.emphasize_last.shift 0]);
    data = data .* last_metric;
  end
  
  %% Track: min_bin/max_bin + time to bins conversions
  if isnumeric(track.min_bin)
    % Convert from two way travel time to bins
    track.min_bin = ones(1,Nx) * find(mdata.Time >= orig_track.min_bin, 1);
  elseif isstruct(track.min_bin)
    % Load layer
    track.min_bin = opsLoadLayers(layer_param, orig_track.min_bin);
    % Interpolate min_bin_layer onto echogram GPS times
    track.min_bin = layerdata.interp(mdata,track.min_bin);
    track.min_bin = interp1(mdata.Time,1:length(mdata.Time),track.min_bin.twtt_ref);
  end
  
  if isnumeric(track.max_bin)
    % Convert from two way travel time to bins
    track.max_bin = find(mdata.Time >= orig_track.max_bin, 1);
    if isempty(track.max_bin)
      track.max_bin = ones(1,Nx) * length(mdata.Time);
    else
      track.max_bin = ones(1,Nx) * track.max_bin;
    end
    
  elseif isstruct(track.max_bin)
    % Load layer
    track.max_bin = opsLoadLayers(layer_param, orig_track.max_bin);
    % Interpolate max_bin_layer onto echogram GPS times
    track.max_bin = layerdata.interp(mdata,track.max_bin);
    track.max_bin = interp1(mdata.Time,1:length(mdata.Time),track.max_bin.twtt_ref);
  end
  
  if isfield(track,'flatten') && ~isempty(track.flatten)
    % Flatten supporting fields
    for rline = 1:Nx
      track.min_bin(rline) = interp1(resample_field(:,rline),1:size(resample_field,1),track.min_bin(rline),'linear','extrap');
      track.max_bin(rline) = interp1(resample_field(:,rline),1:size(resample_field,1),track.max_bin(rline),'linear','extrap');
    end
  end
  track.min_bin(~isfinite(track.min_bin)) = 1;
  track.max_bin(~isfinite(track.max_bin)) = size(data,1);
  
  % Fix invalid min_bin and max_bin by setting to the midpoint
  invalid_min_max = track.max_bin < track.min_bin;
  track.min_bin(invalid_min_max) = round((track.max_bin(invalid_min_max) + track.min_bin(invalid_min_max))/2);
  track.max_bin(invalid_min_max) = track.min_bin(invalid_min_max);
  
  min_min_bin = round(max(1,min(track.min_bin)));
  max_max_bin = round(min(size(data,1),max(track.max_bin)));
  
  if isnan(dt)
    track.init.max_diff = inf;
  else
    track.init.max_diff = orig_track.init.max_diff/dt;
  end
  if strcmpi(track.max_rng_units,'bins')
    track.max_rng = orig_track.max_rng(1) : orig_track.max_rng(end);
  else
    if isnan(dt)
      track.max_rng = 0;
    else
      track.max_rng = round(orig_track.max_rng(1)/dt) : round(orig_track.max_rng(end)/dt);
    end
  end
  data = data(min_min_bin:max_max_bin,:);
  if track.data_noise_en
    data_noise = data_noise(min_min_bin:max_max_bin,:);
  end
  if ~isequal(track.max_rng_filter,track.filter)
    data_max_rng = data_max_rng(min_min_bin:max_max_bin,:);
  end
  if isnan(dt)
    track.zero_bin = 1;
  else
    track.zero_bin = floor(-mdata.Time(min_min_bin)/dt + 1);
  end
  
  track.min_bin = track.min_bin - min_min_bin;
  track.max_bin = track.max_bin - min_min_bin;
  track.crossovers(2,:) = track.crossovers(2,:) - min_min_bin;
  
  %% Track: Create Initial Layer
  if strcmpi(track.init.method,'dem')
    % Correct for min_bin removal
    track.dem = track.dem - min_min_bin + 1;
  elseif strcmp(track.init.method,'snake')
    if isnan(dt)
      track.init.search_rng = 0;
    else
      track.init.search_rng = round(orig_track.init.snake_rng(1)/dt) : round(orig_track.init.snake_rng(2)/dt);
    end
    track.dem = tracker_snake_simple(data,track.init);
  elseif strcmp(track.init.method,'nan')
    track.dem = nan(1,Nx);
  else
    % max or medfilt
    [~,track.dem] = max(data,[],1);
    if strcmp(track.init.method,'medfilt')
      track.dem = medfilt1(track.dem,track.init.medfilt);
    end
  end
  
  %% Track: Merge DEM and reference layer
  if ~isempty(track.init.dem_layer)
    % Interpolate reference layer onto radar GPS time
    ref_interp_gaps_dist = [150 75];
    ops_layer = [];
    ops_layer{1}.gps_time = layers(lay_idx).gps_time;
    ops_layer{1}.type = layers(lay_idx).type;
    ops_layer{1}.quality = layers(lay_idx).quality;
    ops_layer{1}.twtt = layers(lay_idx).twtt;
    ops_layer{1}.type(isnan(ops_layer{1}.type)) = 2;
    ops_layer{1}.quality(isnan(ops_layer{1}.quality)) = 1;
    lay = opsInterpLayersToMasterGPSTime(mdata,ops_layer,ref_interp_gaps_dist);
    dem_layer = lay.layerData{1}.value{2}.data;
    dem_layer = interp1(mdata.Time,1:length(mdata.Time),dem_layer)-min_min_bin+1;
    if isfield(track,'flatten') && ~isempty(track.flatten)
      % Flatten supporting fields
      for rline = 1:Nx
        dem_layer(rline) = interp1(resample_field(:,rline),1:size(resample_field,1),dem_layer(rline),'linear','extrap');
      end
    end
    track.dem = merge_vectors(dem_layer, track.dem);
  end
  
  %% Track: Normalization
  if isfield(track,'norm') && ~isempty(track.norm)
    data = echo_norm(data,track.norm);
  end
  
  %% Track: Tracking
  if strcmpi(track.method, 'lsm') && track.lsm.use_mean_surf_en
    surf = interp_finite(interp1(param.layer_tracker.gt_params.gps_time,param.layer_tracker.gt_params.twtt,mdata.GPS_time));
    surf_bins = round(interp1(mdata.Time,1:length(mdata.Time),surf));
    track.lsm.y = mean(surf_bins);
  end
  
  if strcmpi(track.method,'threshold')
    if isnan(dt)
      new_layers = nan(1,Nx);
      new_quality = ones(1,Nx);
    else
      track.threshold_noise_rng = round(orig_track.threshold_noise_rng/dt);
      if track.data_noise_en
        track.data_noise = data_noise;
      else
        track.data_noise = data;
      end
      [new_layers,new_quality] = tracker_threshold(data,track);
    end
  elseif strcmpi(track.method,'max')
    new_layers = tracker_max(data,track);
    new_quality = ones(1,Nx);
  elseif strcmpi(track.method,'viterbi')
    new_layers = tracker_viterbi(data,track);
    new_quality = ones(1,Nx);
  elseif strcmpi(track.method,'lsm')
    new_layers = tracker_lsm(data,track);
    new_quality = ones(1,Nx);
  elseif strcmpi(track.method,'stereo')
    [new_layers,big_matrix] = tracker_stereo(data,track);
    new_quality = ones(1,Nx);
  elseif strcmpi(track.method,'mcmc')
    new_layers = tracker_mcmc(data,track);
    new_quality = ones(1,Nx);
  elseif strcmpi(track.method,'snake')
    if isnan(dt)
      new_layers = nan(1,Nx);
      new_quality = ones(1,Nx);
    else
      track.search_rng = round(orig_track.snake_rng(1)/dt) : round(orig_track.snake_rng(2)/dt);
      new_layers = tracker_snake_simple(data,track);
      new_quality = ones(1,Nx);
    end
  elseif strcmpi(track.method,'fixed')
    new_layers = ones(size(mdata.GPS_time)) * track.fixed_value;
    new_quality = ones(1,Nx);
  elseif isempty(track.method)
    new_layers = track.dem;
    new_quality = ones(1,Nx);
  else
    error('Not a supported layer tracking method.');
  end
  
  % Trackers may output multiple layers (different rows in new_layers). For
  % loop to post-process each of these layers.
  for layer_idx = 1:size(new_layers,1)
    new_layer = new_layers(layer_idx,:);
    
    %% Track: max_diff
    new_layer(abs(new_layer  - track.dem) > track.init.max_diff) = NaN;
    switch (track.init.max_diff_method)
      case 'merge_vectors'
        new_layer = merge_vectors(new_layer, track.dem);
      case 'interp_finite'
        new_layer = interp_finite(new_layer,NaN);
    end
    
    %% Track: Median filtering
    if isfield(track,'medfilt') && ~isempty(track.medfilt)
      % This median filter is designed to only operate when the point in
      % question is an outlier exceeding track.medfilt_threshold
      for rline=1:Nx
        rlines = rline + (-track.medfilt:track.medfilt);
        rlines = rlines(rlines>=1 & rlines<=length(new_layer));
        if abs(new_layer(rline) - nanmedian(new_layer(rlines))) > track.medfilt_threshold
          new_layer(rline) = nanmedian(new_layer(rlines));
        end
      end
    end
    
    %% Track: Max search
    if (length(track.max_rng) > 1 || track.max_rng ~= 0)
      % Find the next peak after the threshold
      for rline = 1:Nx
        search_bins = round(new_layer(rline)) + track.max_rng;
        search_bins = search_bins(find(search_bins >= 1 & search_bins <= size(data,1)));
        if ~isequal(track.max_rng_filter,track.filter)
          [~,offset] = max(data_max_rng(search_bins,rline));
        else
          [~,offset] = max(data(search_bins,rline));
        end
        if ~isempty(offset)
          new_layer(rline) = search_bins(offset);
        end
      end
    end
    
    %% Track: Smooth sgolayfilt
    if ~isempty(track.smooth_sgolayfilt)
      % This smooth filter is for smoothing the layer output
      new_layer = sgolayfilt(new_layer,track.smooth_sgolayfilt{:});
    end
    
    %% Track: Convert bins to twtt
    if isfield(track,'flatten') && ~isempty(track.flatten)
      % Unflatten layers
      for rline = 1:Nx
        new_layer(rline) = interp1(1:size(resample_field,1),resample_field(:,rline),new_layer(rline)+min_min_bin-1,'linear','extrap');
      end
      for rline = 1:Nx
        track_dem(rline) = interp1(1:size(resample_field,1),resample_field(:,rline),track.dem(rline)+min_min_bin-1,'linear','extrap');
      end
      if isnan(dt)
        % Use "fake" dt of  1 when isnan(dt)
        new_layer = mdata.Time(1) + (new_layer-1)*1;
        track_dem = mdata.Time(1) + (track_dem-1)*1;
      else
        new_layer = mdata.Time(1) + (new_layer-1)*dt;
        track_dem = mdata.Time(1) + (track_dem-1)*dt;
      end
    else
      % Some layer sources may not be "double", but we require that layers be double type:
      new_layer = interp1(1:length(mdata.Time), mdata.Time, new_layer + min_min_bin - 1,'linear','extrap');
      track_dem = interp1(1:length(mdata.Time), mdata.Time, track.dem + min_min_bin - 1,'linear','extrap');
    end

    %% Track: Remove overlap
    if ~exist('overlap','var')
      overlap = [0 0];
    end
    overlap_rlines = 1+overlap(1) : Nx-overlap(2);
    if any(overlap) > 0
      new_layer = new_layer(overlap_rlines);
      new_quality = new_quality(overlap_rlines);
    end
    
    %% Track: Debug plot
    if tracked_images_en || visible_en
      clf(h_fig(1));
      figure_name = sprintf('layer_tracker %s %d-%d layer %d',param.day_seg, param.layer_tracker.frms([1 end]), layer_idx);
      set(h_fig(1),'name',figure_name);
      h_axes(1) = axes('parent',h_fig(1));
      imagesc([],mdata.Time,lp(mdata.Data(:,overlap_rlines)), 'parent', h_axes(1));
      colormap(h_axes(1), 1-gray(256));
      hold(h_axes(1),'on');
      plot(h_axes(1),find(new_quality==1),new_layer(new_quality==1),'g.');
      plot(h_axes(1),find(new_quality==2|new_quality==3),new_layer(new_quality==2|new_quality==3),'r.');
      if strcmpi(track.init.method,{'dem'}) || ~isempty(track.init.dem_layer)
        plot(h_axes(1),track_dem(:,overlap_rlines),'m--');
        plot(h_axes(1),track_dem(:,overlap_rlines)-orig_track.init.max_diff,'r--');
        plot(h_axes(1),track_dem(:,overlap_rlines)+orig_track.init.max_diff,'b--');
      end
      hold(h_axes(1),'off');
      if ~isempty(mdata.Time)
        ylims = [max(mdata.Time(1),min(new_layer)-track.debug_time_guard) min(mdata.Time(end),max(new_layer)+track.debug_time_guard)];
        if ylims(end)>ylims(1)
          ylim(h_axes(1),ylims);
        end
      end
      title(h_axes(1),regexprep(figure_name,'_','\\_'));
      if visible_en
        fprintf('Debug plots: review "%s" and then run "dbcont" to continue.\n', figure_name);
        keyboard
      end
      
      if tracked_images_en
        fig_fn = fullfile(ct_filename_ct_tmp(param,'',param.layer_tracker.debug_out_dir,''), ...
          param.layer_tracker.layer_params.layerdata_source, ...
          sprintf('%s_%s_l%03d_frm_%03d.jpg',track.name,track.method,layer_idx,param.layer_tracker.frms(1)));
        fprintf('Saving %s\n', fig_fn);
        fig_fn_dir = fileparts(fig_fn);
        if ~exist(fig_fn_dir,'dir')
          mkdir(fig_fn_dir);
        end
        ct_saveas(h_fig(1),fig_fn);
      end
    end
    
    new_layers(layer_idx,overlap_rlines) = new_layer;
  end
  new_layers = new_layers(:,overlap_rlines);
  
  %% Track: Save
  if isstruct(param.layer_tracker.echogram_source)
    % Qlook mode
    
    % Return twtt in "success" variable
    success = new_layers(:, frm_start(1):frm_stop(1));
    
  else
    % Cluster Mode
    for frm_idx = 1:length(param.layer_tracker.frms)
      frm = param.layer_tracker.frms(frm_idx);
      
      % Get just the current frames layer data
      gps_time = mdata.GPS_time(frm_start(frm_idx)+overlap(1):frm_stop(frm_idx)+overlap(1));
      twtt = new_layers(:, frm_start(frm_idx):frm_stop(frm_idx));
      param_layer_tracker = param;
      file_version = '1';
      file_type = 'layer_tracker';
      
      tmp_out_fn_name = sprintf('t%03d_%s.mat', track_idx, track.method);
      tmp_out_fn = fullfile(tmp_out_fn_dir_dir,sprintf('layer_tracker_%03d', frm),tmp_out_fn_name);
      fprintf('  Saving %s (%s)\n', tmp_out_fn, datestr(now));
      tmp_out_fn_dir = fileparts(tmp_out_fn);
      if ~exist(tmp_out_fn_dir,'dir')
        mkdir(tmp_out_fn_dir);
      end
      ct_save(tmp_out_fn,'twtt','gps_time','param_layer_tracker','file_type','file_version');
    end
    success = true;
  end
end

fprintf('Done %s\n',datestr(now));
