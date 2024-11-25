function [success surfTimes] = slope_tracker_task(param)
% [success surfTimes] = slope_tracker_task(param)
%
% Cluster task for slope_tracker. Does the actual data loading
% and surface tracking.
%
% param = struct controlling the loading, processing, surface tracking,
%   and quick look generation
%  .load = structure for which records to load
%   .recs = current records
%   .imgs = cell vector of images to load, each image is Nx2 array of
%     wf/adc pairs
%     NOTE: wfs/adc pairs are not indices into anything, they are the absolute
%     waveform/adc numbers. The records file will be loaded to decode
%     which index each wf/adc belongs to.
%  .debug_level = debug level (scalar integer)
%
%  .proc = structure containing information about framing
%   .frm = only used to determine the filename of the output
%
% .slope_tracker = structure controlling slope_tracker processing
%  .radar_name = name of radar string
%  .season_name = name of mission string
%  .day_seg = day-segment string
%  
%  slope_tracker fields used by load_mcords_data.m (see that function for details)
%  .ft_wind
%  .ft_wind_time
%  .trim_vals
%  .pulse_rfi.en
%  .pulse_rfi.inc_ave
%  .pulse_rfi.thresh_scale
%  .radar
%   .Vpp_scale = radar Vpp for full scale quanitization
%   .rxs = struct array of receiver equalization coefficients
%    .wfs = struct array for each waveform
%     .chan_equal = scalar complex double (data DIVIDED by this)
%     .td = time delay correction (applied during pulse compression)
%  
%  slope_tracker fields for post processing
%  .roll_correction = boolean, whether or not to apply roll phase correction
%  .lever_arm_fh = string containing function name
%  .elev_correction = boolean, whether or not to apply elevation phase correction
%  .B_filter = double vector, FIR filter coefficients to apply before
%    decimating, this function loads data before and after this frame
%    (if available) to avoid transients at the beginning and end
%  .decimate_factor = positive integer, decimation rate
%  .inc_ave = positive integer, number of incoherent averages to apply
%    (also decimates by this number)
%
%  .surf = slope_tracker structure controlling surface tracking
%   .en = boolean, whether or not to apply surface tracking
%   .wf_idx = positive integer, which waveform in the wfs list to apply surface tracking on
%   .min_bin = double scalar, the minimum range time that the surface can be tracked to.
%     This is used to keep the surface tracking routine from picking up the
%     feedthrough.  It requires a minimum elevation AGL.
%   .manual = boolean, whether or not to enable the manual tracking
%     interface.  Generally better to let the automated routine run, fix in
%     picker, and then update records (so surf.manual is mostly for debugging)
%
%  .qlook = slope_tracker structure controlling quick look generation
%   .en = boolean, whether or not to produce a quick look product
%    .out_path = output path of the quick look.  Three forms:
%      1. empty: default path based on the gRadar.out_path, param.records_name,
%         param.season_name, and param.day_seg
%      2. relative path: path based on gRadar.out_path and the contents of
%         .qlook.out_path
%      3. absolute path: uses this specific path for outputs
%   .wf_comb = vector of times of when to combine waveforms
%
% success = boolean which is true when the function executes properly
%   if a task fails before it can return success, then success will be
%   empty
% surfTimes = vector of propagation delays to the surface
%
% Author: John Paden
%
% See also slope_tracker.m

global g_data;

physical_constants;
surfTimes = [];

if ~isfield(param.slope,'elev_correction') || isempty(param.slope.elev_correction)
  param.slope.elev_correction = false;
end

if ~param.slope.elev_correction ...
    && length(param.slope.B_filter) == param.slope.decimate_factor ...
    && all(param.slope.B_filter == 1)
  simple_firdec = true;
else
  simple_firdec = false;
end

if ~isfield(param.slope,'trim_vals') || isempty(param.slope.trim_vals)
  param.slope.trim_vals = [0 0];
end

if ~isfield(param.slope,'coh_noise_method') || isempty(param.slope.coh_noise_method)
  param.slope.coh_noise_method = 0;
end

if ~isfield(param.slope,'pulse_rfi')
  param.slope.pulse_rfi.en = 0;
end

if ~isfield(param.slope,'ft_dec') || isempty(param.slope.ft_dec)
  param.slope.ft_dec = 1;
end

% =====================================================================
% Determine which records to load with load_mcords_data
%
% Load records on either side of the current block, note if at the
% beginning or end of the segment.  Load with minimal presumming.

if simple_firdec
  load_param.load.recs(1) = param.load.recs(1);
  load_param.load.recs(2) = param.load.recs(2);
  records = records_load(param,load_param.load.recs);
  old_param_records = records.param_records;
else
  if mod(length(param.slope.B_filter)-1,2)
    error('Filter order must be even (e.g. fir1(EVEN_NUMBER,cutoff))');
  end
  filter_order = length(param.slope.B_filter) - 1;
  start_buffer = min(filter_order/2,param.load.recs(1)-1);
  load_param.load.recs(1) = param.load.recs(1)-start_buffer;
  load_param.load.recs(2) = param.load.recs(2)+filter_order/2;
  records = records_load(param,load_param.load.recs);
  old_param_records = records.param_records;
  stop_buffer = filter_order/2 - ((load_param.load.recs(2)-load_param.load.recs(1)+1) ...
    - length(records.lat));
end
old_param_records.gps_source = records.gps_source;

if isfield(param.slope,'surface_src') % && ~isempty(param.slope.surface_src)
  %% Get the generic layer data path
  layer_path = fullfile(ct_filename_out(param,'layerData','',0));
  
  %% Load the current frame
  layer_fn = fullfile(layer_path,sprintf('Data_%s_%03d.mat',param.day_seg,param.proc.frm));
  layer = load(layer_fn);
  new_surface_gps_time = layer.GPS_time;
  new_surface = layer.layerData{1}.value{2}.data;
  new_bottom = layer.layerData{2}.value{2}.data;
  %% Get the previous frame if necessary
  if records.gps_time(1) < new_surface_gps_time(1)-1
    layer_fn = fullfile(layer_path,sprintf('Data_%s_%03d.mat',param.day_seg,param.proc.frm-1));
    if exist(layer_fn,'file')
      layer = load(layer_fn);
      new_surface_gps_time = [layer.GPS_time new_surface_gps_time];
      new_surface = [layer.layerData{1}.value{2}.data new_surface];
      new_bottom = [layer.layerData{2}.value{2}.data new_bottom];
    end
  end
  %% Get the next frame if necessary
  if records.gps_time(end) > new_surface_gps_time(end)+1
    layer_fn = fullfile(layer_path,sprintf('Data_%s_%03d.mat',param.day_seg,param.proc.frm+1));
    if exist(layer_fn,'file')
      layer = load(layer_fn);
      new_surface_gps_time = [new_surface_gps_time layer.GPS_time];
      new_surface = [new_surface layer.layerData{1}.value{2}.data];
      new_bottom = [new_bottom layer.layerData{2}.value{2}.data];
    end
  end
  %% Since layer files may have overlapping data, sort it
  [new_surface_gps_time new_surface_idxs] = sort(new_surface_gps_time);
  new_surface = new_surface(new_surface_idxs);
  new_bottom = new_bottom(new_surface_idxs);

  %% Do the interpolation and overwrite the records.surface variable
  new_surface = interp1(new_surface_gps_time,new_surface,records.gps_time,'linear','extrap');
  records.surface = new_surface;
  new_bottom = interp1(new_surface_gps_time,new_bottom,records.gps_time,'linear','extrap');
  records.bottom = new_bottom;
end

% =====================================================================
% Collect waveform information into one structure
%  (used by load_RADARNAME_data)

if simple_firdec
  param.slope.presums = param.slope.decimate_factor;
else
  param.slope.presums = 1;
end
param.slope.pulse_comp = 1;
param.slope.combine_rx = 0;
if strcmpi(param.radar_name,'mcrds')
  [wfs,rec_data_size] = load_mcrds_wfs(records.wfs, param, ...
    1:max(old_param_records.file.adcs), param.slope);
  load_param.load.rec_data_size = rec_data_size;
elseif any(strcmpi(param.radar_name,{'mcords','mcords2','mcords3','seaice','accum2'}))
  [wfs,rec_data_size] = load_mcords_wfs(records.settings, param, ...
    1:max(old_param_records.records.file.adcs), param.slope);
  load_param.load.rec_data_size = rec_data_size;
elseif any(strcmpi(param.radar_name,{'snow','kuband','snow2','kuband2','snow3','kuband3'}))
  wfs_idx = find(records.settings.wfs_records <= load_param.load.recs(1),1,'last');
  records.settings.wfs = records.settings.wfs(wfs_idx).wfs;
  wfs = load_fmcw_wfs(records.settings, param, ...
    1:max(old_param_records.records.file.adcs), param.slope);
end
% load_wf_cmd=['load_',param.radar_name,'_wfs(records.wfs,param,1:max(old_param_records.file.adcs),param.slope)'];
% [wfs,rec_data_size] = eval(load_wf_cmd);
load_param.wfs = wfs;

% =====================================================================
% Collect record file information required for using load_RADAR_NAME_data
%  - Performs mapping between param.rxs and the records file contents
%  - Translates filenames from relative to absolute
%  - Makes filenames have the correct filesep
 
% Create a list of unique adcs required by the imgs list
param.load.adcs = [];
for idx = 1:length(param.load.imgs)
  new_adcs = abs(param.load.imgs{idx}(:,2:2:end)).';
  param.load.adcs = unique(cat(2, new_adcs(:).', param.load.adcs));
end

recs = load_param.load.recs - load_param.load.recs(1) + 1;
if any(strcmpi(param.radar_name,{'mcords','mcords2','mcords3','mcords4','accum2'}))
  boards = adc_to_board(param.radar_name,records.param_records.records.file.adcs);
  for idx = 1:length(param.load.adcs)
    adc = param.load.adcs(idx);
    adc_idx = find(old_param_records.records.file.adcs == param.load.adcs(idx));
    if isempty(adc_idx)
      error('ADC %d not present in records file\n', param.load.adcs(idx));
    end
    
    % Just get the file-information for the records we need
    board = adc_to_board(param.radar_name,adc);
    board_idx = find(board == boards);
    load_param.load.file_idx{idx} = relative_rec_num_to_file_idx_vector( ...
      load_param.load.recs(1):load_param.load.recs(end),records.relative_rec_num{board_idx});
    load_param.load.offset{idx} = records.offset(board_idx,:);
    file_idxs = unique(load_param.load.file_idx{idx});
    
    % Recognize if first record is really from previous file and it is a
    % valid record (i.e. offset does not equal -2^31)
    if sign(load_param.load.offset{idx}(1)) < 0 && load_param.load.offset{idx}(1) ~= -2^31
      file_idxs = [file_idxs(1)-1 file_idxs];
    end
    
    % Just copy the filenames we need
    load_param.load.filenames{idx}(file_idxs) = records.relative_filename{board_idx}(file_idxs);
    
    filepath = get_segment_file_list(param,adc);
    
    % Convert relative file paths into absolute file paths if required,
    % also corrects filesep (\ and /)
    for file_idx = 1:length(load_param.load.filenames{idx})
      load_param.load.filenames{idx}{file_idx} ...
        = fullfile(filepath,load_param.load.filenames{idx}{file_idx});
    end
  end
  load_param.load.file_version = param.records.file_version;
  
elseif strcmpi(param.radar_name,'mcrds')
  load_param.load.file_rec_offset = records.file_rec_offset;
  load_param.load.filenames = records.filenames;
  base_dir = ct_filename_data(ct_filename_param,param.slope.file.base_dir);
  adc_folder_name = param.slope.file.adc_folder_name;
  load_param.load.filepath = fullfile(base_dir, adc_folder_name);
  load_param.load.wfs = records.wfs;
  load_param.load.wfs_file = records.wfs_file;
elseif any(strcmpi(param.radar_name,{'snow','kuband','snow2','kuband2','snow3','kuband3'}))
  load_param.load.offset = records.offset;
  load_param.load.file_rec_offset = records.relative_rec_num;
  load_param.load.filenames = records.relative_filename;
  base_dir = ct_filename_data(param,param.vectors.file.base_dir);
  adc_folder_name = param.vectors.file.adc_folder_name;
  load_param.load.filepath = fullfile(base_dir, adc_folder_name);
  load_param.load.wfs = records.settings.wfs;
  load_param.load.radar_name = param.radar_name;
  load_param.load.season_name = param.season_name;
  load_param.load.tmp_path = param.tmp_path;
  load_param.load.file_version = param.records.file_version;
%   if any(strcmpi(param.radar_name,{'snow','kuband'}))
%     load_param.load.header_size = 4*40;
%   elseif any(strcmpi(param.radar_name,{'snow2','kuband2'}))
%     load_param.load.header_size = 32;
%   elseif any(strcmpi(param.radar_name,{'snow3','kuband3'}))
%     if param.records.file_version == 4
%       load_param.load.header_size = 32;
%     else
%       load_param.load.header_size = 48;
%     end
%   end
end

% =====================================================================
% Setup control parameters for load_mcords_data

load_param.load.adcs = param.load.adcs;

load_param.proc.trim_vals           = param.slope.trim_vals;
load_param.proc.pulse_comp          = param.slope.pulse_comp;
load_param.proc.ft_dec              = param.slope.ft_dec;
load_param.proc.ft_wind             = param.slope.ft_wind;
load_param.proc.ft_wind_time        = param.slope.ft_wind_time;
load_param.proc.presums             = param.slope.presums;
load_param.proc.combine_rx          = param.slope.combine_rx;
load_param.proc.pulse_rfi           = param.slope.pulse_rfi;
load_param.proc.coh_noise_method    = param.slope.coh_noise_method;
load_param.proc.coh_noise_arg       = param.slope.coh_noise_arg;

load_param.radar = param.radar;

% =====================================================================
% Load and process each waveform separately
%
% For each waveform:
% 1. Load receiver data separately (minimal presumming)
% 2. Remove coherent noise (slow-time mean removal)
% 3. Apply roll correction
% 4. Combine receivers
% 5. Apply elevation compensation
% 6. FIR decimate the data
% =====================================================================

for img_idx = 1:length(param.load.imgs)
  % Setup roll correction
  if param.slope.roll_correction
    trajectory_param = struct('gps_source',records.gps_source, ...
      'season_name',param.season_name,'radar_name',param.radar_name,'rx_path', 0, ...
      'tx_weights', [], 'lever_arm_fh', param.slope.lever_arm_fh);
    ref = trajectory_with_leverarm(records,trajectory_param);

%     lever_arm_fh = param.slope.lever_arm_fh;
%     % Setup motion compensation (roll removal)
%     radar_lever_arm = zeros(3,size(param.load.imgs{img_idx},1));
%     for wf_adc_idx = 1:size(param.load.imgs{img_idx},1)
%       wf = abs(param.load.imgs{img_idx}(wf_adc_idx,1));
%       adc = abs(param.load.imgs{img_idx}(wf_adc_idx,2));
%       radar_lever_arm(:,wf_adc_idx) = lever_arm_fh(param,wfs(wf).tx_weights,wfs(wf).rx_paths(adc));
%     end
  end
  
  % Default values to use
  wf = abs(param.load.imgs{img_idx}(1,1));
  adc = abs(param.load.imgs{img_idx}(1,2));
  lambda_fc = c/wfs(wf).fc;

  %% Compute trajectory using GPS/INS data and the lever arm
  % out_records = motion compensated data
  % records = original record information (not to be used below this section)
  if isempty(param.slope.lever_arm_fh)
    out_records = records;
  else
    trajectory_param = struct('gps_source',old_param_records.gps_source, ...
          'season_name',param.season_name,'radar_name',param.radar_name, ...
          'rx_path', wfs(wf).rx_paths(adc), ...
      'tx_weights', wfs(wf).tx_weights, 'lever_arm_fh', param.slope.lever_arm_fh);
    for tmp_wf_adc_idx = 2:size(param.load.imgs{1},1)
      tmp_wf = abs(param.load.imgs{1}(tmp_wf_adc_idx,1));
      tmp_adc = abs(param.load.imgs{1}(tmp_wf_adc_idx,2));
      trajectory_param.rx_path(tmp_wf_adc_idx) = wfs(tmp_wf).rx_paths(tmp_adc);
    end
    out_records = trajectory_with_leverarm(records,trajectory_param);
  end
  
  %% Load data into g_data using load_mcords_data
  load_param.load.imgs = param.load.imgs(img_idx);
  
  if param.slope.qlook.wf_adc_comb.en
    % Waveforms-adc pairs are combined in fast-time during loading and pulse compression
    %   param.slope.qlook.wf_adc_comb.comb_times <-- cell vector of strings containing Matlab
    %      command which uses "wf_adc_surface" variable to determine where
    %      first wf-adc pair will transition to second wf-adc pair and so on.
    %   param.slope.qlook.wf_adc_comb.out_times <-- two-element vector that truncates the
    %      fast-time to a range of interest... hack?
    %
    % This section creates three variables for loading:
    %  load_param.load.wf_adc_comb = wf/adc combination control struct
    %   .en = true
    %   .rbins = 2 by Nx array
    %     First row is rbin in first waveform to combine to
    %     Second row is rbin in second waveform to start reading from
    %   .keep_bins
    %     Range bins in new time axis that are going to be kept
    %   .Nt_orig = scalar
    %     Original number of samples
    %   .Nt = scalar = length(keep_bins)
    %     Number of samples after keeping just keep_bins
    load_param.load.wf_adc_comb.en = 1;
    
    % CURRENT HACK: only two wf-adc pairs supported
    wf1 = load_param.load.imgs{1}(1,1);
    wf2 = load_param.load.imgs{1}(1,3);
    
    % comb_time = time to switch from wf-adc pair 1 to wf-adc pair 2
    wf_adc_surface = records.surface;
    comb_time = eval(param.slope.qlook.wf_adc_comb.comb_times{1});
    
    % If the time to switch is longer than wf1 then it gets capped to wf1
    comb_time(comb_time > wfs(wf1).time(end) - wfs(wf1).Tpd) = wfs(wf1).time(end) - wfs(wf1).Tpd;
    comb_time = fir_dec(comb_time, param.slope.decimate_factor);
    
    load_param.load.wf_adc_comb.Nt = 1 + floor((wfs(wf2).time(end) - wfs(wf1).time(1)) / wfs(wf1).dt);
    load_param.load.wf_adc_comb.rbins(1,:) = round((comb_time-wfs(wf1).time(1))/wfs(wf1).dt);
    load_param.load.wf_adc_comb.rbins(2,:) = 1 + load_param.load.wf_adc_comb.rbins(1,:) ...
      - round((wfs(wf2).time(1)-wfs(wf1).time(1))/wfs(wf1).dt);
    
    new_wfs.fc = wfs(wf1).fc;
    new_wfs.time = (wfs(1).time(1) : wfs(1).dt : wfs(2).time(end)).';
    keep_bins = find(new_wfs.time > param.slope.qlook.wf_adc_comb.out_times(1) & new_wfs.time < param.slope.qlook.wf_adc_comb.out_times(end) );
    new_wfs.time = new_wfs.time(keep_bins);
    load_param.load.wf_adc_comb.keep_bins = keep_bins;
    load_param.load.wf_adc_comb.Nt_orig = load_param.load.wf_adc_comb.Nt;
    load_param.load.wf_adc_comb.Nt = length(keep_bins);
    
    new_wfs.dt = new_wfs.time(2)-new_wfs.time(1);
    Nt = length(new_wfs.time);
    T = Nt*new_wfs.dt;
    df = 1/T;
    new_wfs.fs = wfs(1).fs;
    new_wfs.freq = fftshift(new_wfs.fc + df*(-floor(Nt/2) + (0:Nt-1)).');
  end
  
  if strcmpi(param.radar_name,'mcords')
    load_mcords_data(load_param);
    g_data = g_data{1};
  elseif any(strcmpi(param.radar_name,{'mcords2','mcords3'}))
    load_mcords2_data(load_param);
    g_data = g_data{1};
  elseif strcmpi(param.radar_name,'mcrds')
    load_mcrds_data(load_param);
    g_data = g_data{1};
  elseif strcmpi(param.radar_name,'accum2')
    load_accum2_data(load_param);
    g_data = g_data{1};
  elseif any(strcmpi(param.radar_name,{'kuband','snow','kuband2','snow2','kuband3','snow3'}))
    wfs.time = load_fmcw_data(load_param);
  end
  
  %% Remove overlap data
  recs_keep = 1+param.load.recs_keep(1)-load_param.load.recs(1) ...
    : length(out_records.lat)+param.load.recs_keep(end)-load_param.load.recs(end);
  out_records.lat = out_records.lat(recs_keep);
  out_records.lon = out_records.lon(recs_keep);
  out_records.elev = out_records.elev(recs_keep);
  out_records.roll = out_records.roll(recs_keep);
  out_records.pitch = out_records.pitch(recs_keep);
  out_records.heading = out_records.heading(recs_keep);
  out_records.gps_time = out_records.gps_time(recs_keep);
  out_records.surface = out_records.surface(recs_keep);
  if simple_firdec
    recs_keep = 1+(param.load.recs_keep(1)-load_param.load.recs(1))/param.slope.decimate_factor ...
      : size(g_data,2)+(param.load.recs_keep(end)-load_param.load.recs(end))/param.slope.decimate_factor;
  end
  g_data = g_data(:,recs_keep,:);
  
  
  
  %% FIR Decimate
  if simple_firdec
%     if img_idx == 1
      out_records.gps_time = fir_dec(out_records.gps_time, param.slope.decimate_factor);
      out_records.lat = fir_dec(out_records.lat, param.slope.decimate_factor);
      out_records.lon = fir_dec(out_records.lon, param.slope.decimate_factor);
      out_records.elev = fir_dec(out_records.elev, param.slope.decimate_factor);
      out_records.roll = fir_dec(out_records.roll, param.slope.decimate_factor);
      out_records.pitch = fir_dec(out_records.pitch, param.slope.decimate_factor);
      out_records.heading = fir_dec(out_records.heading, param.slope.decimate_factor);
      out_records.surface = fir_dec(out_records.surface, param.slope.decimate_factor);
%     end
    
  else
    % Check for edge conditions that caused not enough data to be loaded
    % in the case where a segment starts and stops.
    % If not enough data was loaded, modify the filter coefficient
    % normalization so that it handles this
    Nidxs = floor((load_param.load.recs(2)-load_param.load.recs(1)+1) / param.slope.decimate_factor);
    rline0 = 1 + start_buffer;
    g_data = fir_dec(g_data, param.slope.B_filter, ...
      param.slope.decimate_factor, rline0, Nidxs);

%     if img_idx == 1
      out_records.gps_time = fir_dec(out_records.gps_time, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.lat = fir_dec(out_records.lat, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.lon = fir_dec(out_records.lon, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.elev = fir_dec(out_records.elev, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.roll = fir_dec(out_records.roll, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.pitch = fir_dec(out_records.pitch, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.heading = fir_dec(out_records.heading, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.surface = fir_dec(out_records.surface, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
%     end
  end
  
  
  %% Remove coherent noise
  if param.slope.coh_noise_method == 1 && ~any(strcmpi(param.radar_name,{'kuband','snow','kuband2','snow2','kuband3','snow3'}))
    for wf_adc_idx = 1:size(g_data,3)
      g_data(:,:,wf_adc_idx) = g_data(:,:,wf_adc_idx) - repmat( mean(g_data(:,:,wf_adc_idx),2) , ...
        [1 size(g_data,2)]);
    end
  end

  while 1
  keyboard;
  end
  slope_tracker_subtask;

  %% FIR Decimate
  if simple_firdec
%     if img_idx == 1
      out_records.gps_time = fir_dec(out_records.gps_time, param.slope.decimate_factor);
      out_records.lat = fir_dec(out_records.lat, param.slope.decimate_factor);
      out_records.lon = fir_dec(out_records.lon, param.slope.decimate_factor);
      out_records.elev = fir_dec(out_records.elev, param.slope.decimate_factor);
      out_records.roll = fir_dec(out_records.roll, param.slope.decimate_factor);
      out_records.pitch = fir_dec(out_records.pitch, param.slope.decimate_factor);
      out_records.heading = fir_dec(out_records.heading, param.slope.decimate_factor);
%     end
    
  else
    % Check for edge conditions that caused not enough data to be loaded
    % in the case where a segment starts and stops.
    % If not enough data was loaded, modify the filter coefficient
    % normalization so that it handles this
    Nidxs = floor((load_param.load.recs(2)-load_param.load.recs(1)+1) / param.slope.decimate_factor);
    rline0 = 1 + start_buffer;
    g_data = fir_dec(g_data, param.slope.B_filter, ...
      param.slope.decimate_factor, rline0, Nidxs);

%     if img_idx == 1
      out_records.gps_time = fir_dec(out_records.gps_time, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.lat = fir_dec(out_records.lat, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.lon = fir_dec(out_records.lon, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.elev = fir_dec(out_records.elev, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.roll = fir_dec(out_records.roll, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.pitch = fir_dec(out_records.pitch, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
      out_records.heading = fir_dec(out_records.heading, param.slope.B_filter, ...
        param.slope.decimate_factor, rline0, Nidxs);
%     end
  end

  %% Run tracker
  if param.slope.surf.en && img_idx == param.slope.surf.img_idx
    
    % Convert time min_bin into range bins
    min_bin = find(wfs(wf).time > param.slope.surf.min_bin, 1);
    
    % Set initial point
    %  - Look at the maximum along Ninit_pnts equally spaced range lines
    %    and choose the sort_ind bin. The range line and corresponding
    %    bin become the initial point.
    Ninit_pnts = 15;
    sort_ind = 3;
    startInds = unique(round(size(data_incoh,2) * linspace(0.2,0.8,Ninit_pnts)));
    surfBins = zeros(1,size(data_incoh,2));
    [tmp surfBins_init] = max(data_incoh(min_bin:end,startInds));
    surfBins_init = surfBins_init + min_bin - 1;
    [tmp surfBins_init_sort_ind] = sort(surfBins_init);
    if length(surfBins_init_sort_ind)<sort_ind
        sort_ind = length(surfBins_init_sort_ind);
    end
    startInd = startInds(surfBins_init_sort_ind(sort_ind));
    surfBins(startInd) = surfBins_init(surfBins_init_sort_ind(sort_ind));
    pnt(1).col = startInd;
    pnt(1).row = surfBins(startInd);
    pnt(1).method = 's';
    
    % Automated: find remaining points (snake method)
    searchRng = param.slope.surf.search_rng; % Must be centered on zero, as in -X to X
    done = zeros(1,size(data_incoh,2));
    for pntInd = 1:length(pnt)
      done(pnt(pntInd).col) = 1;
      surfBins(pnt(pntInd).col) = pnt(pntInd).row;
    end
    while sum(done) ~= length(done)
      for line = 1:length(done)
        if done(line) == 0
          if line < length(done) && done(line+1) == 1
            done(line) = 1;
            tmpSearchRng = searchRng(1+max(0,1-(surfBins(line+1)+searchRng(1))) : ...
              length(searchRng)-max(0,(surfBins(line+1)-searchRng(1))-size(data_incoh,1)));
            [tmp newBin] = max(data_incoh(surfBins(line+1)+tmpSearchRng,line));
            surfBins(line) = surfBins(line+1)+tmpSearchRng(1)-1 + newBin;
          end
          if line > 1 && done(line-1) == 1
            done(line) = 1;
            tmpSearchRng = searchRng(1+max(0,1-(surfBins(line-1)+searchRng(1))) : ...
              length(searchRng)-max(0,(surfBins(line-1)-searchRng(1))-size(data_incoh,1)));
            [tmp newBin] = max(data_incoh(surfBins(line-1)+tmpSearchRng,line));
            surfBins(line) = surfBins(line-1)+tmpSearchRng(1)-1 + newBin;
          end
        end
      end
    end
    
    if param.slope.surf.manual
      
      fprintf('Manual tracker: \n');
      fprintf('  left mouse button click then CMD: add point;\n');
      fprintf('    s: snake point\n');
      fprintf('    t: threshold point\n');
      fprintf('    c: constant point\n');
      fprintf('  backspace: delete last point;\n');
      fprintf('  q: quit and continue;\n');
      fprintf('  k: debug tracker code;\n');
      startAxis = [1 size(data_incoh,2) min(surfBins)-30 max(surfBins)+30];
      surfBins = simple_tracker(10*log10(data_incoh),pnt,startAxis);
      
      if 0
        figure(1); clf;
        imagesc(10*log10(data_incoh));
        hold on;
        plot(surfBins)
        hold off;
        axis([1 size(data_incoh,2) min(surfBins)-30 max(surfBins)+30]);
        fprintf('Type dbcont to continue\n');
        keyboard;
      end
      
    end
    
    % =====================================================================
    % Return results (to be saved in records file eventually)
    % =====================================================================
    surfTimes = wfs(wf).time(surfBins);
  end
  
  if param.slope.qlook.en
    % Save quick look results
    Data = data_incoh;
    
    Time = new_wfs(1).time;
    Surface = [];
    
    GPS_time = fir_dec(out_records.gps_time,param.slope.inc_ave);
    Latitude = fir_dec(out_records.lat,param.slope.inc_ave);
    Longitude = fir_dec(out_records.lon,param.slope.inc_ave);
    Elevation = fir_dec(out_records.elev,param.slope.inc_ave);
    Roll = fir_dec(out_records.roll,param.slope.inc_ave);
    Pitch = fir_dec(out_records.pitch,param.slope.inc_ave);
    Heading = fir_dec(out_records.heading,param.slope.inc_ave);
    
    fn = fullfile(ct_filename_out(param, ...
      param.slope.qlook.out_path, 'CSARP_slope'), ...
      sprintf('ql_data_%03d_01_01',param.proc.frm), sprintf('%s_img_%02d.mat', ...
      datestr(epoch_to_datenum(out_records.gps_time(1)), 'yyyymmdd_HHMMSS'), ...
      img_idx));
    [path name ext] = fileparts(fn);
    if ~exist(path,'dir')
      mkdir(path);
    end
    param_records = old_param_records;
    param_slope_tracker = param;
    save(fn, 'Data', 'Time', 'Surface', 'GPS_time', 'Latitude', ...
      'Longitude', 'Elevation', 'Roll', 'Pitch', 'Heading', 'param_slope_tracker', 'param_records');
  end
  
end

success = true;

return;
