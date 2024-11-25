function [ds] = load_data_by_gps_time(param)
% [ds] = load_data_by_gps_time(param)
%
% Loads data from one of the radars (mcords, mcords2, kuband, snow,
% and accum) and returns a data structure with all the standard fields
% contained in the data output files.
%
% param = parameters structure
%  .start.gps_time =
%  .stop.gps_time = seconds since epoch
%  .radar_name = e.g. 'accum', 'snow', etc
%  .season_name = e.g. '2011_Greenland_P3'
%  .post_dir = usually '' or 'CSARP_post' (an optional posting directory)
%  .out = usually 'qlook', 'standard', 'mvdr', etc
%  .layerData = usually undefined or '' to ignore and 'layerData' if you want it to
%    load layer data (Surface and Bottom). Currently only RDS pipeline data
%    supported.
%
% ds = data structure with:
%   Data
%   Latitude
%   Longitude
%   Elevation
%   GPS_time
%   Surface
%   Time
%   param_radar
%   param_qlook
%   param_vectors
%
% Example:
%   See run_load_data_by_gps_time
%
% Author: John Paden

start = param.start;
stop = param.stop;

physical_constants;
load_data_by_gps_time_tstart = tic;

if ~isfield(param,'layerData')
  param.layerData = '';
end

if ~isfield(param,'img_name')
  param.img_name = '';
end

if strcmpi(param.radar_name,'accum_old')
  % ====================================================================
  % ====================================================================
  % 1U-DAQ radars under old processing chain: accum
  % ====================================================================
  % ====================================================================
  
  % Get list of vectors files
  vectors_dir = ct_filename_support(param, '', 'vectors');
  fns = get_filenames(vectors_dir,'vectors_','','.mat');
  
  % Load in vectors files
  for file_idx = 1:length(fns)
    fn = fns{file_idx};
    [fn_dir fn_name] = fileparts(fn);
    if file_idx == 1
      load(fn);
      vectors.day_seg = repmat(fn_name(9:end),[length(vectors.gps_time) 1]);
    else
      tmp = load(fn);
      vectors.gps_time = cat(2,vectors.gps_time,tmp.vectors.gps_time);
      vectors.file = cat(2,vectors.file,tmp.vectors.file);
      vectors.day_seg = cat(1,vectors.day_seg,repmat(fn_name(9:end),[length(tmp.vectors.gps_time) 1]));
    end
  end
  
  % Find file containing start data
  start_file_idx = find(vectors.gps_time > start.gps_time,1);
  if isempty(start_file_idx)
    start_file_idx = length(vectors.gps_time);
  elseif start_file_idx == 1
    error('Start time is before first file');
  else
    start_file_idx = start_file_idx - 1;
  end
  
  % Find file containing stop data
  stop_file_idx = find(vectors.gps_time > stop.gps_time,1);
  if isempty(stop_file_idx)
    stop_file_idx = length(vectors.gps_time);
  elseif stop_file_idx == 1
    error('Stop time is before first file');
  else
    stop_file_idx = stop_file_idx - 1;
  end
  
  if 0
    % Construct original data filename
    time_stamp_str = datestr(vectors.file(file_idx).datenum,'yyyymmdd_HHMMSSFFF');
    time_stamp_str = time_stamp_str(1:end-1);
    fn = fullfile(base_dir, ...
      vectors.file(file_idx).adc_folder_name, ...
      sprintf('%s_%s_%04d.dat',param.radar_name,time_stamp_str, ...
      vectors.file(file_idx).idx));
    
    fn
  end
  
  start_frm_id = sprintf('%s_%03.0f', vectors.day_seg(start_file_idx,:), vectors.file(start_file_idx).idx);
  stop_frm_id = sprintf('%s_%03.0f', vectors.day_seg(stop_file_idx,:), vectors.file(stop_file_idx).idx);
  
  fprintf('%s data contained in frames %s to %s\n', param.radar_name, start_frm_id, stop_frm_id);
  
  file_idxs = start_file_idx:stop_file_idx;
  for file_idx_idx = 1:length(file_idxs)
    file_idx = file_idxs(file_idx_idx);
    
    % Construct data output filename
    param.day_seg = vectors.day_seg(file_idx,:);
    frm_id = sprintf('%s_%03.0f', param.day_seg, vectors.file(file_idx).idx);
    out_name = sprintf('Data_%s.mat', frm_id);
    
    out_dir = ct_filename_out(param,'','',1);
    out_fn = fullfile(out_dir,param.post_dir,strcat('CSARP_',param.out),param.day_seg,out_name);
    
    if file_idx_idx == 1
      ds = load(out_fn);
      ds = uncompress_echogram(ds);

    else
      tmp = load(out_fn);
      tmp = uncompress_echogram(tmp);
      
      % If two frames are processed in different Nyquist Zones, their
      % Time vector and Data matrices may not overlap 100%. This code pads
      % and interpolates to line everything up.
      dt = ds.Time(2) - ds.Time(1);
      t0 = ds.Time(1);
      Nt = length(ds.Time);
      
      if tmp.Time(1) < ds.Time(1)
        % Move start time forward Nz0 bins
        Nz0 = floor((ds.Time(1) - tmp.Time(1))/dt);
        t0 = t0 - dt * Nz0;
        Nt = Nt + Nz0;
        ds.Data = [zeros(Nz0,size(ds.Data,2)); ds.Data];
      end
      if tmp.Time(end) > ds.Time(end)
        % Move stop time back Nze bins
        Nze = floor((tmp.Time(end) - ds.Time(end))/dt);
        Nt = Nt + Nze;
        ds.Data = [ds.Data; zeros(Nze,size(ds.Data,2))];
      end
      ds.Time = t0 + dt*(0:Nt-1).';
      tmp.Data = interp1(tmp.Time,tmp.Data,ds.Time,'linear',0);
      
      ds.Data = cat(2,ds.Data,tmp.Data);
      ds.Latitude = cat(2,ds.Latitude,tmp.Latitude);
      ds.Longitude = cat(2,ds.Longitude,tmp.Longitude);
      ds.Elevation = cat(2,ds.Elevation,tmp.Elevation);
      ds.GPS_time = cat(2,ds.GPS_time,tmp.GPS_time);
      ds.Surface = cat(2,ds.Surface,tmp.Surface);
    end
  end
  
  % Trim output to start/stop times
  good_rlines = find(ds.GPS_time > start.gps_time & ds.GPS_time < stop.gps_time);
  if length(good_rlines) == 0
    if stop_file_idx+1 < length(vectors.gps_time)
      fprintf('  Next data frame after stop frame: %s_%03.0f %s\n', ...
        vectors.day_seg(stop_file_idx+1,:), ...
        vectors.file(stop_file_idx+1).idx, ...
        datestr(epoch_to_datenum(vectors.gps_time(stop_file_idx+1))));
    else
      fprintf('No data exists after the stop frame\n');
    end
    error('No data found!');
  elseif abs(ds.GPS_time(good_rlines(1)) - start.gps_time) > 1 ...
      || abs(ds.GPS_time(good_rlines(end)) - stop.gps_time) > 1
    warning('Requested range probably includes time with no data');
  end
  ds.Data = ds.Data(:,good_rlines);
  ds.Latitude = ds.Latitude(good_rlines);
  ds.Longitude = ds.Longitude(good_rlines);
  ds.Elevation = ds.Elevation(good_rlines);
  ds.GPS_time = ds.GPS_time(good_rlines);
  ds.Surface = ds.Surface(good_rlines);
  
  
else
  % Check to make sure it is a valid radar_name
  [output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);
    
  % ====================================================================
  % ====================================================================
  % General processing chain radars
  % ====================================================================
  % ====================================================================
  
  % Get list of records files
  frames_dir = ct_filename_support(param, '', 'frames');
  fns = get_filenames(frames_dir,'frames','','.mat');

  if isempty(fns)
    error('No frames file found in %s', frames_dir);
  end

  % Load in first and last record from each records file
  first_gps_time = [];
  last_gps_time = [];
  for file_idx = 1:length(fns)
    frames_fn = fns{file_idx};

    try
      % Continue to run even if a frames file fails to load
      frames = frames_load(frames_fn);
      first_gps_time(file_idx) = frames.gps_time(1);
      last_gps_time(file_idx) = frames.gps_time(end);
    catch ME
      warning(ME.getReport)
    end
  end
  
  start_file_idx = find(start.gps_time >= first_gps_time,1,'last');
  stop_file_idx = find(stop.gps_time <= last_gps_time,1);
  
  if isempty(start_file_idx)
    error('Start time (%s) is before any radar data exists (%s)', ...
      datestr(epoch_to_datenum(start.gps_time)), ...
      datestr(epoch_to_datenum(first_gps_time(1))));
  end
  if isempty(stop_file_idx)
    error('Stop time (%s) is after any radar data exists (%s)', ...
      datestr(epoch_to_datenum(stop.gps_time)), ...
      datestr(epoch_to_datenum(first_gps_time(end))));
  end
  if start_file_idx ~= stop_file_idx
    error('Time range (%s to %s) includes times when no radar data exists', ...
      datestr(epoch_to_datenum(start.gps_time)), ...
      datestr(epoch_to_datenum(stop.gps_time)));
  end
  
  frames = frames_load(fns{start_file_idx});
  param.day_seg = frames.param.day_seg;
  records = records_load(param);
  
  % Determine which frames need to be loaded
  start_frame = find(start.gps_time >= frames.gps_time,1,'last');
  stop_frame = find(stop.gps_time >= frames.gps_time,1,'last');
  
  start_frm_id = sprintf('%s_%03.0f', param.day_seg, start_frame);
  stop_frm_id = sprintf('%s_%03.0f', param.day_seg, stop_frame);
  
  fprintf('Data contained in frames %s to %s\n', start_frm_id, stop_frm_id);
  
  frms = start_frame:stop_frame;
  for frm_idx = 1:length(frms)
    frm = frms(frm_idx);
    
    % Construct data output filename
    frm_id = sprintf('%s_%03.0f', param.day_seg, frm);
    out_name = sprintf('Data_%s%s.mat', param.img_name, frm_id);
    
    out_fn = fullfile(ct_filename_out(param,param.out,''), out_name);
    
    if ~isempty(param.layerData)
      layer_dir = ct_filename_out(param,'','',1);
      layer_fn = fullfile(layer_dir,param.post_dir,strcat('CSARP_',param.layerData),param.day_seg,out_name);
    end
        
    % Determine this frames valid GPS time range
    frm_gps_time_start = frames.gps_time(start_frame);
    frm_gps_time_stop = frames.gps_time(stop_frame+1);
    
    fprintf('  %s\n', out_fn);
    if frm_idx == 1
      ds = load(out_fn);
      ds = uncompress_echogram(ds);
      
      good_rlines = find(ds.GPS_time >= frm_gps_time_start ...
        & ds.GPS_time < frm_gps_time_stop);
      ds.Data = ds.Data(:,good_rlines);
      
      ds.Latitude = ds.Latitude(good_rlines);
      ds.Longitude = ds.Longitude(good_rlines);
      ds.Elevation = ds.Elevation(good_rlines);
      ds.GPS_time = ds.GPS_time(good_rlines);
      ds.Surface = ds.Surface(good_rlines);
      if isfield(ds,'Bottom')
        ds.Bottom = ds.Bottom(good_rlines);
      end
      
      if ~isempty(param.layerData)
        layer = load(layer_fn);
        % Interpolate based on GPS time and difference in elevation
        layer.Elevation_Interp = interp1(layer.GPS_time,layer.Elevation,ds.GPS_time);
        layer.Surface_Interp = interp1(layer.GPS_time,layer.layerData{1}.value{2}.data,ds.GPS_time);
        layer.Bottom_Interp = interp1(layer.GPS_time,layer.layerData{2}.value{2}.data,ds.GPS_time);
        ds.Surface = layer.Surface_Interp + (ds.Elevation - layer.Elevation_Interp)/(c/2);
        ds.Bottom = layer.Bottom_Interp + (ds.Elevation - layer.Elevation_Interp)/(c/2);
      end
      
    else
      tmp = load(out_fn);
      tmp = uncompress_echogram(tmp);
      
      good_rlines = find(tmp.GPS_time >= frm_gps_time_start ...
        & tmp.GPS_time < frm_gps_time_stop);
      tmp.Data = tmp.Data(:,good_rlines);
      tmp.Latitude = tmp.Latitude(good_rlines);
      tmp.Longitude = tmp.Longitude(good_rlines);
      tmp.Elevation = tmp.Elevation(good_rlines);
      tmp.GPS_time = tmp.GPS_time(good_rlines);
      tmp.Surface = tmp.Surface(good_rlines);
      if isfield(tmp,'Bottom')
        tmp.Bottom = tmp.Bottom(good_rlines);
      end
      
      ds.Latitude = cat(2,ds.Latitude,tmp.Latitude);
      ds.Longitude = cat(2,ds.Longitude,tmp.Longitude);
      ds.Elevation = cat(2,ds.Elevation,tmp.Elevation);
      ds.GPS_time = cat(2,ds.GPS_time,tmp.GPS_time);
      %% Reinterpolate original data and data to be appended onto a common time axis
      % Since time axes are not consistent, we avoid reinterpolating the
      % same data for each appending process by enforcing that the new time bins
      % fall on the
      % same points every time and may only add additional points.
      
      % Create new time axis (but ensure start point will cause the new
      % time axes to fall on all the old ds.Time points)
      min_time = min(tmp.Time(1),ds.Time(1));
      dt = ds.Time(2)-ds.Time(1);
      Time = ds.Time(1) - dt*round((ds.Time(1) - min_time)/dt) ...
        : dt : max(tmp.Time(end),ds.Time(end));
      Time = reshape(Time,[numel(Time) 1]);
      % Interpolate original data
      ds.Data = interp1(ds.Time,ds.Data,Time);
      ds.Time = Time;
      % Interpolate data to be appended
      tmp.Data = interp1(tmp.Time,tmp.Data,Time);
      % Concatenate the two
      ds.Data = cat(2,ds.Data,tmp.Data);
      
      if ~isempty(param.layerData)
        layer = load(layer_fn);
        % Interpolate based on GPS time and difference in elevation
        layer.Elevation_Interp = interp1(layer.GPS_time,layer.Elevation,tmp.GPS_time);
        layer.Surface_Interp = interp1(layer.GPS_time,layer.layerData{1}.value{2}.data,tmp.GPS_time);
        layer.Bottom_Interp = interp1(layer.GPS_time,layer.layerData{2}.value{2}.data,tmp.GPS_time);
        tmp.Surface = layer.Surface_Interp + (tmp.Elevation - layer.Elevation_Interp)/(c/2);
        tmp.Bottom = layer.Bottom_Interp + (tmp.Elevation - layer.Elevation_Interp)/(c/2);
        ds.Surface = cat(2,ds.Surface,tmp.Surface);
        ds.Bottom = cat(2,ds.Bottom,tmp.Bottom);
      else
        ds.Surface = cat(2,ds.Surface,tmp.Surface);
        if isfield(ds,'Bottom')
          ds.Bottom = cat(2,ds.Bottom,tmp.Bottom);
        end
      end
      
    end
  end
  
  % Trim output to start/stop times
  good_rlines = find(ds.GPS_time > start.gps_time & ds.GPS_time < stop.gps_time);
  ds.Data = ds.Data(:,good_rlines);
  ds.Latitude = ds.Latitude(good_rlines);
  ds.Longitude = ds.Longitude(good_rlines);
  ds.Elevation = ds.Elevation(good_rlines);
  ds.GPS_time = ds.GPS_time(good_rlines);
  ds.Surface = ds.Surface(good_rlines);
  if isfield(ds,'Bottom')
      ds.Bottom = ds.Bottom(good_rlines);
  end
  ds.frm_id = frm_id;
  ds.start_frame = start_frame;
  ds.stop_frame = stop_frame;  
  
end

return;
