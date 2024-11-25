function [success] = qlook_task(param)
% [success] = qlook_task(param)
%
% Cluster task for quick look processing. Does the actual data loading
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
% .qlook = structure controlling qlook processing
%  .radar_name = name of radar string
%  .season_name = name of mission string
%  .day_seg = day-segment string
%
%  qlook fields used by load_mcords_data.m (see that function for details)
%  .ft_wind
%  .ft_wind_time
%  .trim_vals
%  .pulse_rfi.en
%  .pulse_rfi.inc_dec
%  .pulse_rfi.thresh_scale
%  .radar
%   .Vpp_scale = radar Vpp for full scale quanitization
%   .rxs = struct array of receiver equalization coefficients
%    .wfs = struct array for each waveform
%     .chan_equal = scalar complex double (data DIVIDED by this)
%     .td = time delay correction (applied during pulse compression)
%
%  qlook fields for post processing
%  .roll_correction = boolean, whether or not to apply roll phase correction
%  .lever_arm_fh = string containing function name
%  .elev_correction = boolean, whether or not to apply elevation phase correction
%  .B_filter: double vector, FIR filter coefficients to apply before
%    decimating, this function loads data before and after this frame
%    (if available) to avoid transients at the beginning and end of the
%    processing block. This filter controls how coherent averaging is done
%    (AKA stacking, presumming, or unfocused SAR). Default value is a
%    boxcar filter of length equal to the decimation rate or
%    ones(1,qlook.dec)/qlook.dec.
%  .dec: positive integer, decimation rate
%  .inc_B_filter: double vector, FIR filter coefficients to apply before
%    incoherent average decimation. If not defined or empty, then
%    inc_B_filter is set to ones(1,inc_dec)/inc_dec.
%  .inc_dec = integer scalar, number of incoherent averages to apply
%    (also decimates by this number). If set to < 1, complex data are
%    returned.  Setting to 1 causes the data to be power detected (i.e.
%    become incoherent), but no averaging is done.
%
%  .surf = qlook structure controlling surface tracking
%   .en = boolean, whether or not to apply surface tracking
%   .wf_idx = positive integer, which waveform in the wfs list to apply surface tracking on
%   .min_bin = double scalar, the minimum range time that the surface can be tracked to.
%     This is used to keep the surface tracking routine from picking up the
%     feedthrough.  It requires a minimum elevation AGL.
%   .manual = boolean, whether or not to enable the manual tracking
%     interface.  Generally better to let the automated routine run, fix in
%     picker, and then update records (so surf.manual is mostly for debugging)
%
%  .qlook = qlook structure controlling quick look generation
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
%
% Author: John Paden
%
% See also qlook.m

% Load c=speed of light constant
physical_constants;

%% Load records file
% =========================================================================

% Adjust the load records to account for filtering and decimation. Care is
% taken to ensure that when blocks and frames are concatenated together,
% they are seamless (i.e. no discontinuities in the filtering and
% decimation at block and frame boundaries). Also, records before and after
% the desired output records are loaded when available to ensure filter inputs
% have full support when creating outputs. Since this is not possible
% at the the beginning and end of the segment, the filter coefficients are
% renormalized to account for the shorted support so that there is no roll
% off in signal power.

task_recs = param.load.recs; % Store this for later when creating output fn
  
% Translate the records to load into presummed record counts
%  *_ps: presummed record counts as opposed to raw record counts
load_recs_ps(1) = floor((param.load.recs(1)-1)/param.qlook.presums)+1;
load_recs_ps(2) = floor(param.load.recs(2)/param.qlook.presums);

% inc_dec == 0 is treated as inc_dec = 1 with no power detection at the end
dec = param.qlook.dec*max(1,param.qlook.inc_dec);

% output_recs_ps: the outputs of the whole qlook process
output_recs_ps = 1:dec:load_recs_ps(2);
output_recs_ps = output_recs_ps(output_recs_ps >= load_recs_ps(1));

% Determine number of records before/after the start/stop output record
% that are needed for the filtering
start_buffer_ps = (length(param.qlook.inc_B_filter)-1)/2*param.qlook.dec + (length(param.qlook.B_filter)-1)/2;
stop_buffer_ps = start_buffer_ps;

% If do Doppler spikes nulling, set the default parameters for the equivalent adaptive notch filter
% at the end of data_pulse_compress.m. These parameters include the extra buffers at the start and 
% end of the data blocks in terms of a factor of the data block size to avoid bounary artifact 
% from fft and ifft transforms, and range bins to filt through, thresholds for Doppler noise and surface signals.
% (see more detailed descriptions in data_pulse_compress.m)
if isfield(param.radar.wfs,'DSN') && param.radar.wfs.DSN.en
  if ~isfield(param.radar.wfs.DSN,'rbin_clusters') || isempty(param.radar.wfs.DSN.rbin_clusters)
    param.radar.wfs.DSN.rbin_clusters = [1,inf];
  end
  if ~isfield(param.radar.wfs.DSN,'theshold') || isempty(param.radar.wfs.DSN.threshold)
    param.radar.wfs.DSN.threshold = 10;
  end
  if ~isfield(param.radar.wfs.DSN,'surf_theshold') || isempty(param.radar.wfs.DSN.threshold)
    param.radar.wfs.DSN.surf_threshold = 20;
  end
  if ~isfield(param.radar.wfs.DSN,'block_overlap_factor') || isempty(param.radar.wfs.DSN.block_overlap_factor)
    param.radar.wfs.DSN.block_overlap_factor = 0.1;
  end
  start_buffer_ps = start_buffer_ps + round(param.radar.wfs.DSN.block_overlap_factor*param.qlook.block_size);
  stop_buffer_ps = start_buffer_ps;
end

% Adjust start_buffer_ps in case at the beginning of the segment
start_buffer_ps = start_buffer_ps - max(0,(1- (output_recs_ps(1) - start_buffer_ps) ));

% These are the input records (in presummed record counts)
input_recs_ps(1) = output_recs_ps(1) - start_buffer_ps;
% input_recs_ps(2) = output_recs_ps(end) + stop_buffer_ps + 1;
input_recs_ps(2) = output_recs_ps(end) + stop_buffer_ps;

% These are the input records in raw record counts
param.load.recs(1) = param.qlook.presums * (input_recs_ps(1) - 1) + 1;
% param.load.recs(2) = param.qlook.presums * input_recs_ps(2);
param.load.recs(2) = param.qlook.presums * (input_recs_ps(2)-1) + 1;

% Load the records
records = records_load(param,param.load.recs);

% Adjust stop_buffer_ps and loaded records in case at the end of the segment
stop_buffer_ps = stop_buffer_ps + floor(length(records.gps_time)/param.qlook.presums) - (diff(input_recs_ps)+1);
input_recs_ps(2) = output_recs_ps(end) + stop_buffer_ps;
param.load.recs(2) = param.load.recs(1) + length(records.gps_time) - 1;

% output_coh_recs_ps: the outputs for the coherent filtering and decimation
output_coh_recs_ps = 1:param.qlook.dec:input_recs_ps(2);
output_coh_recs_ps = output_coh_recs_ps(output_coh_recs_ps >= input_recs_ps(1));

% Store the parameters that were used to create the records file
param_records = records.param_records;

% Store the current GPS source
param_records.gps_source = records.gps_source;

% Get output directory, radar type, and base radar name
[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

%% Load surface layer
% =========================================================================
frames = frames_load(param);
tmp_param = param;
tmp_param.cmd.frms = max(1,param.load.frm-1) : min(length(frames.frame_idxs),param.load.frm+1);
surf_layer = opsLoadLayers(tmp_param,param.qlook.surf_layer);
if isempty(surf_layer.gps_time)
  records.surface(:) = 0;
elseif length(surf_layer.gps_time) == 1;
  records.surface(:) = surf_layer.twtt;
else
  records.surface = interp_finite(interp1(surf_layer.gps_time,surf_layer.twtt,records.gps_time),0);
end

%% Collect waveform information into one structure
% =========================================================================
[wfs,states] = data_load_wfs(param,records);
param.radar.wfs = merge_structs(param.radar.wfs,wfs);

%% Load data
% =========================================================================
param.load.raw_data = false;
param.load.presums = param.qlook.presums;
param.load.bit_mask = param.qlook.bit_mask; % Skip bad records marked in records.bit_mask
[hdr,data] = data_load(param,records,states);

param.load.pulse_comp = true;
[hdr,data,param] = data_pulse_compress(param,hdr,data);
param.load.motion_comp = param.qlook.motion_comp;
param.load.combine_rx = true;
[hdr,data] = data_merge_combine(param,hdr,data);

%% Unfocussed SAR processing (stacking only)
% =========================================================================
% Check for edge conditions that caused not enough data to be loaded
% in the case where a segment starts and stops.
% If not enough data was loaded, modify the filter coefficient
% normalization so that it handles this
rline0 = output_coh_recs_ps(1) - input_recs_ps(1) + 1;
Nidxs = length(output_coh_recs_ps);

hdr.gps_time = fir_dec(hdr.gps_time, param.qlook.B_filter, ...
  param.qlook.dec, rline0, Nidxs);
hdr.surface = fir_dec(hdr.surface, param.qlook.B_filter, ...
  param.qlook.dec, rline0, Nidxs);

for img = 1:length(param.load.imgs)
  
  % Remove elevation variations
  if param.load.motion_comp && ~isempty(hdr.freq{img})
    % Reference time delay
    ref_td = max(hdr.ref.elev) / (c/2);
    % Relative time delay to reference time delay
    relative_td = hdr.records{img}.elev / (c/2) - ref_td;
    % Add zero padding (NaNs)
    dt = hdr.time{img}(2) - hdr.time{img}(1);
    zero_pad = max(ceil(abs(relative_td / dt)));
    data{img} = [data{img}; nan(zero_pad,size(data{img},2))];
    Nt = size(data{img},1);
    df = 1/(Nt*dt);
    freq = hdr.freq{img}(1) + df*ifftshift( -floor(Nt/2) : floor((Nt-1)/2) ).';
    % Apply time delay
    nanmask = isnan(data{img});
    data{img}(nanmask) = 0;
    data{img} = fft(data{img},[],1);
    data{img} = data{img} .* exp(1j*2*pi*freq*relative_td);
    data{img} = ifft(data{img},[],1);
    
    % Relative time delay to reference time delay in time bin units
    relative_bins = round( relative_td / dt);
    % Apply circular shift
    for rline = 1:size(data{img},2)
      nanmask(:,rline) = circshift(nanmask(:,rline),[-relative_bins(rline) 0]);
    end
    data{img}(nanmask) = NaN;
  end
  
  % OLD phase only motion_comp:
  % phase_weights = exp(-1i * hdr.records{img}.elev * 4*pi*hdr.freq{img}(1)/c);
  % data{img} = fir_dec(data{img}, param.qlook.B_filter, ...
  %   param.qlook.dec, rline0, Nidxs, [], phase_weights);
  
  if param.qlook.nan_dec
    data{img} = nan_fir_dec(data{img}, param.qlook.B_filter, ...
      param.qlook.dec, rline0, Nidxs, [], [], param.qlook.nan_dec_normalize_threshold);
  else
    data{img} = fir_dec(data{img}, param.qlook.B_filter, ...
      param.qlook.dec, rline0, Nidxs);
  end
  
  % Reapply elevation variations
  if param.load.motion_comp && ~isempty(hdr.freq{img})
    % Remove time delay
    relative_td = fir_dec(relative_td, param.qlook.B_filter, ...
      param.qlook.dec, rline0, Nidxs);
    nanmask = isnan(data{img});
    data{img}(nanmask) = 0;
    data{img} = fft(data{img},[],1);
    data{img} = data{img} .* exp(-1j*2*pi*freq*relative_td);
    data{img} = ifft(data{img},[],1);
    
    % Relative time delay to reference time delay in time bin units
    relative_bins = round( relative_td / dt);
    % Apply circular shift
    for rline = 1:size(data{img},2)
      nanmask(:,rline) = circshift(nanmask(:,rline),[relative_bins(rline) 0]);
    end    
    data{img}(nanmask) = NaN;
    
    % Remove zero padding
    data{img} = data{img}(1:end-zero_pad,:);
  end

  hdr.records{img}.lat = fir_dec(hdr.records{img}.lat, param.qlook.B_filter, ...
    param.qlook.dec, rline0, Nidxs);
  hdr.records{img}.lon = fir_dec(hdr.records{img}.lon, param.qlook.B_filter, ...
    param.qlook.dec, rline0, Nidxs);
  hdr.records{img}.elev = fir_dec(hdr.records{img}.elev, param.qlook.B_filter, ...
    param.qlook.dec, rline0, Nidxs);
  hdr.records{img}.roll = fir_dec(hdr.records{img}.roll, param.qlook.B_filter, ...
    param.qlook.dec, rline0, Nidxs);
  hdr.records{img}.pitch = fir_dec(hdr.records{img}.pitch, param.qlook.B_filter, ...
    param.qlook.dec, rline0, Nidxs);
  hdr.records{img}.heading = fir_dec(hdr.records{img}.heading, param.qlook.B_filter, ...
    param.qlook.dec, rline0, Nidxs);
end

%% Resample
% ===================================================================
[hdr,data] = data_resample(hdr,data,param.qlook.resample);

%% Trim
% ===================================================================
[hdr,data] = data_trim(hdr,data,param.qlook.trim);

%% Multilook the data (incoherent averaging with decimation)
% =========================================================================
% param.qlook.inc_dec == 0: saves voltage data
% param.qlook.inc_dec >= 1: saves power detected data with optional incoherent
% filtering and decimation specified by param.qlook.inc_B_filter and
% param.qlook.inc_dec respectively
if param.qlook.inc_dec >= 1
  rline0 = (output_recs_ps(1) - input_recs_ps(1))/param.qlook.dec + 1;
  Nidxs = length(output_recs_ps);
  hdr.gps_time = fir_dec(hdr.gps_time, param.qlook.inc_B_filter, ...
    param.qlook.inc_dec, rline0, Nidxs);
  hdr.surface = fir_dec(hdr.surface, param.qlook.inc_B_filter, ...
    param.qlook.inc_dec, rline0, Nidxs);

  for img = 1:length(param.load.imgs)
    
    % Remove elevation variations
    if param.load.motion_comp
      % Relative time delay to reference time delay in time bin units
      dt = hdr.time{img}(2) - hdr.time{img}(1);
      relative_bins = round( relative_td / dt);
      % Add zero padding (NaNs)
      data{img} = [data{img}; nan(zero_pad,size(data{img},2))];
      % Apply circular shift
      for rline = 1:size(data{img},2)
        data{img}(:,rline) = circshift(data{img}(:,rline),[-relative_bins(rline) 0]);
      end
    end
    
    if param.qlook.nan_dec
      data{img} = nan_fir_dec(abs(data{img}).^2, param.qlook.inc_B_filter, ...
        param.qlook.inc_dec, rline0, Nidxs, [], [], param.qlook.nan_dec_normalize_threshold);
    else
      data{img} = fir_dec(abs(data{img}).^2, param.qlook.inc_B_filter, ...
        param.qlook.inc_dec, rline0, Nidxs);
    end
    
    % Reapply elevation variations
    if param.load.motion_comp
      % Apply circular shift
      relative_bins = round(fir_dec(relative_bins, param.qlook.inc_B_filter, ...
      param.qlook.inc_dec, rline0, Nidxs));
      for rline = 1:size(data{img},2)
        data{img}(:,rline) = circshift(data{img}(:,rline),[relative_bins(rline) 0]);
      end
      % Remove zero padding
      data{img} = data{img}(1:end-zero_pad,:);
    end
    
    hdr.records{img}.lat = fir_dec(hdr.records{img}.lat, param.qlook.inc_B_filter, ...
      param.qlook.inc_dec, rline0, Nidxs);
    hdr.records{img}.lon = fir_dec(hdr.records{img}.lon, param.qlook.inc_B_filter, ...
      param.qlook.inc_dec, rline0, Nidxs);
    hdr.records{img}.elev = fir_dec(hdr.records{img}.elev, param.qlook.inc_B_filter, ...
      param.qlook.inc_dec, rline0, Nidxs);
    hdr.records{img}.roll = fir_dec(hdr.records{img}.roll, param.qlook.inc_B_filter, ...
      param.qlook.inc_dec, rline0, Nidxs);
    hdr.records{img}.pitch = fir_dec(hdr.records{img}.pitch, param.qlook.inc_B_filter, ...
      param.qlook.inc_dec, rline0, Nidxs);
    hdr.records{img}.heading = fir_dec(hdr.records{img}.heading, param.qlook.inc_B_filter, ...
      param.qlook.inc_dec, rline0, Nidxs);
  end

end

%% Save quick look results
% =========================================================================
for img = 1:length(param.load.imgs)
  Data = data{img};
  GPS_time = hdr.gps_time;
  Latitude = hdr.records{img}.lat;
  Longitude = hdr.records{img}.lon;
  Elevation = hdr.records{img}.elev;
  Roll = hdr.records{img}.roll;
  Pitch = hdr.records{img}.pitch;
  Heading = hdr.records{img}.heading;
  Surface = hdr.surface;
  
  Time = hdr.time{img};
  
  % Output filename
  out_fn_name = sprintf('qlook_img_%02d_%d_%d.mat',img,task_recs(1),task_recs(end));
  % Output directory name (_01_01 refer to subaperture and subband which are
  % hardcoded to 1 for now)
  tmp_out_fn_dir = fullfile(ct_filename_out(param, ...
    param.qlook.out_path, 'qlook_tmp'), ...
    sprintf('ql_data_%03d_01_01',param.load.frm));
  out_fn = fullfile(tmp_out_fn_dir,out_fn_name);
  fprintf('  Save %s\n', out_fn);
  if ~exist(tmp_out_fn_dir,'dir')
    mkdir(tmp_out_fn_dir);
  end
  param_qlook = param;
  if param.ct_file_lock
    file_version = '1L';
  else
    file_version = '1';
  end
  file_type = 'qlook_tmp';
  ct_save(out_fn,'-v7.3', 'Data', 'Time', 'GPS_time', 'Latitude', ...
    'Longitude', 'Elevation', 'Roll', 'Pitch', 'Heading', 'Surface', 'param_qlook', 'param_records', 'file_version', 'file_type');
end

%% Done
% =========================================================================

fprintf('%s done %s\n', mfilename, datestr(now));

success = true;
