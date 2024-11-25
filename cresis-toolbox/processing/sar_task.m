function [success] = sar_task(param)
% [success] = sar_task(param)
%
% SAR process a chunk of data (a frame is divided into chunks
% to keep the memory requirements low enough).  This function
% is called from sar.m.
%
% param = structure controlling the SAR processor
%  .debug_level = scalar integer, debugging level
%  .radar = structured used by load_mcords_hdr
%
%  .load = structure containing info about what data to load
%   .recs = 2 element vector containing the start and stop records
%   .imgs = cell vector of images to load, each image is Nx2 array of
%     wf/adc pairs
%     NOTE: wfs/ads are not indices into anything, they are the absolute
%     waveform/adc numbers. The records file will be loaded to decode
%     which index each wf/adc belongs to.
%
%  .proc = structure about which frame to process and how it is broken
%    into chunks
%   .frm = only used to determine the file name of the output
%   .output_along_track_offset = along-track offset from first input
%      record to the first output range line
%   .output_along_track_Nx = length of output in along-track
%
%  .sar = structure containing SAR processing parameters
%   .file = struct with input file information
%      .base_dir: string, e.g. '/cresis/data3/MCoRDS/2011_Greenland_P3/'
%      .adc_folder_name = string, e.g. '20110507/board%b/seg_01'
%      .file_prefix = string, e.g. ''
%   .out_path = output path string
%   .combine_rx = boolean, combine channels before SAR processing
%   .coh_noise_removal = boolean, slow-time DC removal
%   .lever_arm_fh = string containing function name to lever arm
%   .mocomp = struct for motion compensation
%      .en = boolean, apply motion compensation
%      .type = see motion_comp.m for details
%      .uniform_en = boolean, resample data to uniform sampling in along-track
%   .sar_type = string, 'fk' or 'tdbp'
%   .sigma_x = along-track output sample spacing (meters)
%   .sub_aperture_steering = vector of doppler centroids to process to
%     (i.e. subapertures) normalized to the doppler bandwidth
%   .st_wind = function handle for slow time decimation
%   .start_eps = epsilon to use for sub-surface
%
% Fields used by load_mcords_data.m (see that function for details)
%  .pulse_rfi.en
%  .pulse_rfi.inc_ave
%  .pulse_rfi.thresh_scale
%  .trim_vals
%  .pulse_comp
%  .ft_dec
%  .ft_wind
%  .ft_wind_time
%  .radar.rx_path.chan_equal
%  .radar.rx_path.td
%
% success = boolean which is true when the function executes properly
%   if a task fails before it can return success, then success will be
%   empty
%
% Authors: William Blake, John Paden
%
% See also: run_master.m, master.m, run_sar.m, sar.m, sar_task.m,
%   sar_coord_task.m

%% Initialization and checking arguments

% Get speed of light, dielectric of ice constants
physical_constants;
wgs84 = wgs84Ellipsoid('meters');

[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

records = records_load(param,'settings','param_records');

if param.sar.combine_rx && param.sar.mocomp.en
  warning('SAR motion compensation mode must be 0 for combine_rx (setting to 0)');
  param.sar.mocomp.en = 0;
end

% SAR output directory
sar_out_dir = ct_filename_out(param, param.sar.out_path);
sar_coord_dir = ct_filename_out(param, param.sar.coord_path);

% Load SAR coordinate system
sar_fn = fullfile(sar_coord_dir,'sar_coord.mat');
sar = load(sar_fn,'file_version','Lsar','gps_source','type','sigma_x','presums','along_track','surf_pp');

% Determine output range lines
output_along_track = 0 : param.sar.sigma_x : sar.along_track(end);
start_x = sar.along_track(param.load.recs(1));
stop_x = sar.along_track(param.load.recs(2));
out_rlines = find(output_along_track >= start_x & output_along_track <= stop_x);
output_along_track = output_along_track(out_rlines);

%% Collect waveform information into one structure
% =========================================================================
[wfs,states] = data_load_wfs(param,records);
param.radar.wfs = merge_structs(param.radar.wfs,wfs);

%% Determine chunk overlap to ensure full support
% =====================================================================
% Determine overlap of chunks from the range to furthest target
if strcmp(radar_type,'deramp')
  if ~isfinite(param.sar.time_of_full_support)
    error('param.sar.time_of_full_support must be finite for deramp radars.');
  end
  times_of_full_support = param.sar.time_of_full_support;
else
  times_of_full_support = cell2mat({wfs.time}.');
end
max_time = min(max(times_of_full_support),param.sar.time_of_full_support);

% wavelength (m)
wf = abs(param.load.imgs{1}(1,1));
lambda = c/wfs(wf).fc;
% twtt to surface (sec)
surf_time = ppval(sar.surf_pp, start_x); surf_time = min(max_time,surf_time);
% effective in air max range (m)
max_range = ((max_time-surf_time)/sqrt(param.sar.start_eps) + surf_time) * c/2;
% chunk overlap (m), accounts for SAR aperture and arbitrary_resample.m aperture (16*param.sar.sigma_x)
chunk_overlap_start = max(16*param.sar.sigma_x, (max_range*lambda)/(2*param.sar.sigma_x) / 2);
% chunk_overlap_start = max_range/sqrt((2*param.sar.sigma_x/lambda)^2-1);

% twtt to surface (sec)
surf_time = ppval(sar.surf_pp, stop_x); surf_time = min(max_time,surf_time);
% effective in air max range (m)
max_range = ((max_time-surf_time)/sqrt(param.sar.start_eps) + surf_time) * c/2;
% chunk overlap (m), accounts for SAR aperture and arbitrary_resample.m aperture (16*param.sar.sigma_x)
chunk_overlap_stop = max(16*param.sar.sigma_x, (max_range*lambda)/(2*param.sar.sigma_x) / 2);
% chunk_overlap_stop = max_range/sqrt((2*param.sar.sigma_x/lambda)^2-1);

% These are the records which will be used
cur_recs = [find(sar.along_track > start_x-chunk_overlap_start,1) ...
  find(sar.along_track < stop_x+chunk_overlap_stop, 1, 'last')];
param.load.recs = cur_recs;

%% Determine zero padding to prevent circular convolution aliasing
% =====================================================================
param.load.start_zero_pad = floor((sar.along_track(cur_recs(1)) - (start_x-chunk_overlap_start)) / param.sar.sigma_x);
param.load.stop_zero_pad = floor((stop_x+chunk_overlap_stop - sar.along_track(cur_recs(2))) / param.sar.sigma_x);

%% Prepare trajectory information
% =========================================================================

% Create along-track vectors (output rline 1 is zero/origin)
along_track = sar.along_track(param.load.recs(1):param.load.recs(end));

% Create FCS: SAR (flight) coordinate system
fcs = [];
fcs.Lsar = sar.Lsar;
fcs.gps_source = sar.gps_source;

% Slow, but memory efficient way to load SAR coordinate system
tmp = load(sar_fn,'origin');
fcs.origin = tmp.origin(:,out_rlines);
tmp = load(sar_fn,'x');
fcs.x = tmp.x(:,out_rlines);
tmp = load(sar_fn,'z');
fcs.z = tmp.z(:,out_rlines);
fcs.y = cross(fcs.z,fcs.x);
% fcs.pos: to be added for each individual SAR image
tmp = load(sar_fn,'roll');
fcs.roll = tmp.roll(1,out_rlines);
tmp = load(sar_fn,'pitch');
fcs.pitch = tmp.pitch(1,out_rlines);
tmp = load(sar_fn,'heading');
fcs.heading = tmp.heading(1,out_rlines);
tmp = load(sar_fn,'gps_time');
fcs.gps_time = tmp.gps_time(1,out_rlines);

fcs.surface = ppval(sar.surf_pp,output_along_track);
fcs.bottom = NaN*ones(size(fcs.surface));

%% Load records file
% =========================================================================
recs = [(param.load.recs(1)-1)*param.sar.presums+1, ...
        param.load.recs(2)*param.sar.presums];
records = records_load(param,recs);
% Decimate records according to presums
if param.sar.presums > 1
  records.lat = fir_dec(records.lat,param.sar.presums);
  records.lon = fir_dec(records.lon,param.sar.presums);
  records.elev = fir_dec(records.elev,param.sar.presums);
  records.roll = fir_dec(records.roll,param.sar.presums);
  records.pitch = fir_dec(records.pitch,param.sar.presums);
  records.heading = fir_dec(records.heading,param.sar.presums);
  records.gps_time = fir_dec(records.gps_time,param.sar.presums);
  records.surface = fir_dec(records.surface,param.sar.presums);
end

% Store the parameters that were used to create the records file
param_records = records.param_records;

% Store the current GPS source
param_records.gps_source = records.gps_source;

%% Load surface layer
% =========================================================================
frames = frames_load(param);
tmp_param = param;
tmp_param.cmd.frms = max(1,param.load.frm-1) : min(length(frames.frame_idxs),param.load.frm+1);
layer_params = [];
layer_params.name = 'surface';
layer_params.source = 'layerdata';
surf_layer = opsLoadLayers(tmp_param,layer_params);
if isempty(surf_layer.gps_time)
  records.surface(:) = 0;
elseif length(surf_layer.gps_time) == 1
  records.surface(:) = surf_layer.twtt;
else
  records.surface = interp_finite(interp1(surf_layer.gps_time,surf_layer.twtt,records.gps_time),0);
end

%% Load fast-time processing restriction layers
% =========================================================================
if isempty(param.sar.time_start)
  time_start = -inf;
else
  tmp_param = param;
  tmp_param.cmd.frms = max(1,param.load.frm-1) : min(length(frames.frame_idxs),param.load.frm+1);
  surf_layer = opsLoadLayers(tmp_param,param.sar.time_start);
  if isempty(surf_layer.gps_time)
    time_start = -inf;
  elseif length(surf_layer.gps_time) == 1
    time_start = surf_layer.twtt;
  else
    time_start = min(surf_layer.twtt);
  end
end
if isempty(param.sar.time_stop)
  time_stop = inf;
else
  tmp_param = param;
  tmp_param.cmd.frms = max(1,param.load.frm-1) : min(length(frames.frame_idxs),param.load.frm+1);
  surf_layer = opsLoadLayers(tmp_param,param.sar.time_stop);
  if isempty(surf_layer.gps_time)
    time_stop = inf;
  elseif length(surf_layer.gps_time) == 1
    time_stop = surf_layer.twtt;
  else
    time_stop = max(surf_layer.twtt);
  end
end


%% Load data
% =========================================================================
param.load.raw_data = false;
param.load.presums = param.sar.presums;
param.load.bit_mask = param.sar.bit_mask; % Skip stationary records and bad records marked in records.bit_mask
[hdr,data] = data_load(param,records,states);

param.load.pulse_comp = true;
[hdr,data,param] = data_pulse_compress(param,hdr,data);

param.load.motion_comp = false;
param.load.combine_rx = param.sar.combine_rx;
[hdr,data] = data_merge_combine(param,hdr,data);

%% Prepare reference trajectory information
% =========================================================================

% Resample reference trajectory at output positions
% 1. Convert hdr.ref trajectory to ecef
ecef = zeros(3,size(hdr.ref.lat,2));
[ecef(1,:) ecef(2,:) ecef(3,:)] = geodetic2ecef(hdr.ref.lat/180*pi, hdr.ref.lon/180*pi, hdr.ref.elev, WGS84.ellipsoid);
% 2. Resample based on input and output along track
mono_idxs = monotonic_indexes(along_track,true);
ecef = interp1(along_track(mono_idxs),ecef(:,mono_idxs).',output_along_track,'linear','extrap').';
% 3. Convert ecef to geodetic
[lat,lon,elev] = ecef2geodetic(ecef(1,:), ecef(2,:), ecef(3,:), WGS84.ellipsoid);
clear ecef;
lat = lat*180/pi;
lon = lon*180/pi;

%% Main loop to process each image
% =========================================================================
for img = 1:length(param.load.imgs)
  
  %% Loop to process each wf-adc pair
  for wf_adc = 1:size(param.load.imgs{img},1)
    % Processing loop
    % Runs once for combine_rx = true
    % Runs for each wf/adc pair in image if combine_rx = false
    
    wf = abs(param.load.imgs{img}(wf_adc,1));
    adc = abs(param.load.imgs{img}(wf_adc,2));
    
    %% Compute SAR phase center and coordinate system

    % Create fcs.pos: phase center in the flight coordinate system
    % 1. Convert phase center trajectory to ecef
    ecef = zeros(3,size(hdr.records{img,wf_adc}.lat,2));
    [ecef(1,:),ecef(2,:),ecef(3,:)] ...
      = geodetic2ecef(wgs84,hdr.records{img,wf_adc}.lat,hdr.records{img,wf_adc}.lon,hdr.records{img,wf_adc}.elev);

    % 2. Use the fcs to convert ecef to fcs coordinates and store in fcs.pos
    Nx = size(fcs.origin,2);
    good_rline = logical(ones(1,Nx));
    for out_rline = 1:Nx
      % For this output range line determine the input range lines
      rlines_in = find(along_track >= output_along_track(out_rline)-fcs.Lsar/2 ...
        & along_track <= output_along_track(out_rline)+fcs.Lsar/2);
      if isempty(rlines_in)
        % Sometimes there are gaps in the data, we will use neighboring points
        % to fill in these gaps
        good_rline(out_rline) = 0;
        continue;
      end
      fcs.pos(:,out_rline) = [fcs.x(:,out_rline) fcs.y(:,out_rline) fcs.z(:,out_rline)] \ (mean(ecef(:,rlines_in),2) - fcs.origin(:,out_rline));
    end
    if ~any(good_rline)
      error('Data gap extends across entire chunk. Consider breaking segment into two at this gap or increasing the chunk size.');
    end

    % 3. Fill in any missing lines
    if length(good_rline) > 1
      fcs.pos(:,~good_rline) = interp1(output_along_track(good_rline),fcs.pos(:,good_rline).',output_along_track(~good_rline).','linear','extrap').';
    elseif length(good_rline) == 1
      fcs.pos(1,~good_rline) = fcs.pos(1,good_rline);
      fcs.pos(2,~good_rline) = fcs.pos(2,good_rline);
      fcs.pos(3,~good_rline) = fcs.pos(3,good_rline);
    else
      error('good_rline is empty; no good data?');
    end
    
    
    %% SAR Processing
    if strcmpi(param.sar.sar_type,'fk')
      % fk migration overview
      %
      % 1. Loop for each subaperture (repeat steps 2-4 for each aperture)
      %
      % 2. Motion compensation required before taking FFT
      %    data (raw with coherent noise optionally removed)
      %      --> data (motion compensated ft-fft)
      %
      % 3. Uniform re-sampling
      %   a. uniform_en = false, Assume data is uniformly sampled, apply fft in slow time and
      %      decimate in this domain by dropping doppler bins outside window
      %      data (motion compensated ft-fft)
      %        --> data (slow time ft/st-fft) [only done on the first loop]
      %        --> data (decimated ft/st-fft)
      %   b. uniform_en = true, Spatial filter to decimated axis and then take fft
      %      data (motion compensated ft-fft)
      %        --> data (decimated ft-fft)
      %        --> data (decimated ft/st-fft)
      %
      % 4. Regular fk migration for each subaperture

      %% Fast-time restriction
      time_bins = hdr.time{img}>=time_start & hdr.time{img}<=time_stop;
      time = hdr.time{img}(time_bins);
      Nt = length(time);
      dt = time(2)-time(1);
      freq = hdr.freq{img}(1) + 1/(Nt*dt) * ifftshift( -floor(Nt/2) : floor((Nt-1)/2) ).';
      
      good_mask = ~hdr.bad_rec{img}(1,:,wf_adc);

      % To conserve memory, shift the data out one wf_adc at a time
      if isempty(data{img})
        % All records were bad so data is an empty matrix
        fk_data = wfs(wf).bad_value * ones(length(time_bins),size(data{img},2));
      else
        fk_data = data{img}(time_bins,:,1);
      end
      data{img} = data{img}(:,:,2:end);

      fk_data(~isfinite(fk_data)) = 0;
      fk_data = fft(fk_data,[],1);
      
      fcs.squint = [0 0 -1].';
      %fcs.squint = fcs.squint ./ sqrt(dot(fcs.squint,fcs.squint));
      
      %% Motion Compensation for fk migration
      if param.sar.mocomp.en
        % Determine the required motion compensation (drange and dx)
        %  Positive drange means the the range will be made longer, time delay
        %  will be made larger, and phase will be more negative
        %  Positive dx means that the data will be shifted forward (i.e. it
        %  currently lags behind)
        fcs.type = param.sar.mocomp.type;
        fcs.filter = param.sar.mocomp.filter;
        [drange,dx] = sar_motion_comp(fcs,hdr.records{img,wf_adc},hdr.ref,along_track,output_along_track);
        
        % Time shift data in the frequency domain
        dtime = 2*drange/c;
        for rline = 1:size(fk_data,2)
          fk_data(:,rline) = fk_data(:,rline) ...
            .*exp(-1i*2*pi*freq*dtime(rline));
        end
        
        along_track_mc = along_track + dx;
      else
        along_track_mc = along_track;
      end
      
      % output_along_track: these are the output values from sar
      % output_along_track_pre/post: these are the buffers to keep the
      %   data from wrapping around in slow-time (i.e. linear convolution
      %   vs. circular convolution)
      output_along_track_pre = fliplr(output_along_track(1)-param.sar.sigma_x:-param.sar.sigma_x:along_track(1));
      if isempty(output_along_track_pre)
        output_along_track_pre = [output_along_track(1)-param.sar.sigma_x*(param.load.start_zero_pad:-1:1), output_along_track_pre];
      else
        output_along_track_pre = [output_along_track_pre(1)-param.sar.sigma_x*(param.load.start_zero_pad:-1:1), output_along_track_pre];
      end
      output_along_track_post = output_along_track(end)+param.sar.sigma_x:param.sar.sigma_x:along_track(end);
      if isempty(output_along_track_post)
        output_along_track_post = [output_along_track_post, output_along_track(end)+param.sar.sigma_x*(1:param.load.stop_zero_pad)];
      else
        output_along_track_post = [output_along_track_post, output_along_track_post(end)+param.sar.sigma_x*(1:param.load.stop_zero_pad)];
      end
      output_along_track_full = [output_along_track_pre output_along_track output_along_track_post];

      %% Prepare subaperture variables
      num_subapertures = length(param.sar.sub_aperture_steering);
      if mod(num_subapertures,2) ~= 1
        error('Number of subapertures must be even');
      end
      if any(param.sar.sub_aperture_steering ~= -(num_subapertures-1)/4 : 0.5 : (num_subapertures-1)/4)
        error('param.sar.sub_aperture_steering must be of the form -N:0.5:N');
      end
      proc_oversample = (1+num_subapertures)/2; % Oversampling rate
      proc_sigma_x = param.sar.sigma_x / proc_oversample;
      proc_along_track = output_along_track_full(1) ...
        + proc_sigma_x * (0:length(output_along_track_full)*proc_oversample-1);
      
      %% Uniform resampling and subaperture selection for fk migration
      if param.sar.mocomp.uniform_en
        % Uniformly resample data in slow-time onto output along-track
        if param.sar.mocomp.uniform_mask_en && any(good_mask)
          % Mask
          fk_data = arbitrary_resample(fk_data(:,good_mask), ...
            along_track_mc(good_mask),proc_along_track, struct('filt_len', ...
            proc_sigma_x*16,'dx',proc_sigma_x,'method','sinc'));
        else
          % No mask
          fk_data = arbitrary_resample(fk_data, ...
            along_track_mc,proc_along_track, struct('filt_len', ...
            proc_sigma_x*16,'dx',proc_sigma_x,'method','sinc'));
        end
        fk_data = fft(fk_data,[],2);
        
      else
        % Assume data is already uniformly sampled in slow-time
        % There are lots of approximations in this section... it's a bit
        % of a hack.
        x_lin = linspace(along_track(1), ...
          along_track(end),length(along_track));
        dx = mean(diff(x_lin));
        pre_x_lin = fliplr(x_lin(1)-dx:-dx:output_along_track_full(1));
        post_x_lin = x_lin(end)+dx:dx:output_along_track_full(end);
        x_lin = [pre_x_lin, x_lin, post_x_lin];
        fk_data = [zeros(size(fk_data,1),length(pre_x_lin)), fk_data, zeros(size(fk_data,1),length(post_x_lin))];
        
        % Create kx (along-track wavenumber) axis of input data
        kx = gen_kx(x_lin);
        
        % Create kx axis of output (desired) data
        kx_desired = gen_kx(output_along_track_full);
        
        % Take slow-time FFT and decimate the data onto the desired
        % output along track positions by selecting just the doppler
        % bins that correspond to this

        fk_data = fft(fk_data,[],2);
        filt_idx = kx < max(kx_desired) & kx > min(kx_desired);
        % Since kx and kx_desired won't match up perfectly, we may have
        % to append a few more doppler bins to get the numbers to line
        % up.
        if length(output_along_track_full) - sum(filt_idx) == 1
          filt_idx(find(filt_idx==0,1)) = 1;
        elseif length(output_along_track_full) - sum(filt_idx) == 2
          filt_idx(find(filt_idx==0,1)) = 1;
          filt_idx(find(filt_idx==0,1,'last')) = 1;
        end
        filt_len = length(find(filt_idx));
        filt_idx = filt_idx.';
        filt_idx = find(filt_idx);
        kx_sa    = kx(filt_idx);
        [kx_sa,kx_idxs] = sort(kx_sa);
        filt_idx = filt_idx(kx_idxs);
        filt_idx = ifftshift(filt_idx);
        fk_data = fk_data(:,filt_idx);
      end
      
      %% fk migration
      if param.sar.mocomp.en
        eps_r  = perm_profile(mean(hdr.surface + dtime),time,'constant',param.sar.start_eps);
      else
        eps_r  = perm_profile(mean(hdr.surface),time,'constant',param.sar.start_eps);
      end

      kx = gen_kx(proc_along_track);
      fk_data_ml = fk_migration(fk_data,time,freq,kx,eps_r,param);
      fk_data_ml = fk_data_ml(:,1+length(output_along_track_pre):end-length(output_along_track_post),:);

      if 0
        % DEBUG code
        figure(1); clf;
        for subap = 1:num_subapertures
          imagesc(lp(fk_data_ml(300:700,:,subap)))
          title(sprintf('%d',subap ));
          pause(1);
        end
        figure(1); clf;
        imagesc(lp(mean(abs(fk_data_ml(300:700,:,:)).^2,3)));
        figure(2); clf;
        imagesc(lp(mean(abs(fk_data_ml(300:700,:,1:6)).^2,3)));
        figure(3); clf;
        imagesc(lp(mean(abs(fk_data_ml(300:700,:,end-5:end)).^2,3)));
      end
      
      if param.sar.mocomp.en
        %% Undo motion compensation
        % Resample dtime to fk migration output
        dtime = interp1(hdr.gps_time,dtime,fcs.gps_time);
        
        % Time shift data in the frequency domain
        fk_data_ml = fft(fk_data_ml,[],1);
        if param.sar.mocomp.tukey > 0
          % Tukey window because other steps (e.g. fk migration) may have
          % shifted the frequency domain content so that it is not
          % approximately zero on the edges of the frequenecy band which
          % can lead to ringing.
          fk_data_ml = bsxfun(@times,fk_data_ml,ifftshift(tukeywin(size(fk_data_ml,1),param.sar.mocomp.tukey)));
        end
        fk_data_ml = fk_data_ml.*exp(1i*2*pi*repmat(freq, [1,size(fk_data_ml,2),size(fk_data_ml,3)]) ...
          .*repmat(dtime, [size(fk_data_ml,1),1,size(fk_data_ml,3)]));
        fk_data_ml = ifft(fk_data_ml,[],1);
      end
      
      %% Save Radar data
      for subap = 1:num_subapertures
        % Create output path
        out_fn_dir = fullfile(ct_filename_out(param, ...
          param.sar.out_path), ...
          sprintf('%s_data_%03d_%02d_%02d',param.sar.sar_type,param.load.frm, ...
          subap, param.load.sub_band_idx));
        if ~exist(out_fn_dir,'dir')
          mkdir(out_fn_dir);
        end
        
        % Save
        param_sar = param;
        if param.ct_file_lock
          file_version = '1L';
        else
          file_version = '1';
        end
        file_type = 'sar';
        if param.sar.combine_rx
          out_fn = fullfile(out_fn_dir,sprintf('img_%02d_chk_%03d.mat', img, param.load.chunk_idx));
        else
          out_fn = fullfile(out_fn_dir,sprintf('wf_%02d_adc_%02d_chk_%03d.mat', wf, adc, param.load.chunk_idx));
        end
        fk_data = fk_data_ml(:,:,subap);
        fprintf('  Saving %s (%s)\n', out_fn, datestr(now));
        wfs(wf).time = time;
        wfs(wf).freq = freq;
        ct_save(out_fn,'fk_data','fcs','lat','lon','elev','out_rlines','wfs','param_sar','param_records','file_version','file_type');
      end
      
    elseif strcmpi(param.sar.sar_type,'tdbp_old')
      % time domain backporjection overview
      data = data{img}(:,:,wf_adc);
      
      % set up SAR coordinate system
      [x_ecef, y_ecef, z_ecef] = geodetic2ecef(records.lat*pi/180, records.lon*pi/180, records.elev, WGS84.ellipsoid);
      records.lon_ref = mean(records.lon);
      records.lat_ref = mean(records.lat);
      records.elev_ref = mean(records.elev);
      [x_enu,y_enu,z_enu] = ecef2lv(x_ecef, y_ecef, z_ecef, records.lat_ref*pi/180, records.lon_ref*pi/180, records.elev_ref, WGS84.ellipsoid);
%       along_track =  [0 cumsum(sqrt(diff(x_enu).^2 + diff(y_enu).^2))];
      SAR_coord_param.phase_center = [x_enu;y_enu;z_enu];
      SAR_coord_param.Lsar = Lsar;
      SAR_coord_param.along_track = along_track;
      SAR_coord_param.output_along_track_idxs = param.proc.output_along_track_idxs;
%       if strcmpi(param.season_name,'mcords_simulator') % for 20110708_01_001 simulated data
%         param.proc.output_along_track_idxs = [fliplr([4632:-10:0]),[4642:10:length(along_track)]];
%         SAR_coord_param.output_along_track_idxs = param.proc.output_along_track_idxs;
%       end
      SAR_coord_param.wfs = wfs(wf);
      
      % surface tracker
      % two methods to get ice surface: param.surf_source 1/2
      % 1: from get_heights; 2:from laser data;
      param.surf_source = 1;
      if param.surf_source == 1
        surfTimes = records.surface;
      elseif param.surf_source == 2
        param.laser_surface = 1;
        param.laser_data_fn = '/cresis/projects/metadata/2008_Greenland_TO_icessn/2008_Greenland/080801a_icessn_nadir0seg';
        param.laser_data_fn = '/cresis/projects/metadata/2008_Greenland_TO_icessn/2008_Greenland/080707_icessn_nadir0seg';
        fid = fopen(param.laser_data_fn);
        [laser_data_tmp] = textscan(fid,'%f%f%f%f%f%f%f%f%f%f%f');
        fclose(fid);
        Year = 2008;
        Mon = 7;
        Day = 7;
        laser_data.gps_time = (datenum(Year,Mon,Day)-datenum(1970,1,1))*86400 + laser_data_tmp{1};
        laser_data.surf_elev = laser_data_tmp{4};
        laser_data.surf_elev = interp1(laser_data.gps_time,laser_data.surf_elev,records.gps_time);
        surfTimes = 2*(records.elev-laser_data.surf_elev)/c;
        clear laser_data_tmp;
      end
      
      SAR_coord_param.surf = zeros(3,length(along_track));
      SAR_coord_param.surf(1,:) = x_enu;
      SAR_coord_param.surf(2,:) = y_enu;
      SAR_coord_param.surf(3,:) = z_enu - surfTimes*c/2;
      SAR_coord_param.surf_p = polyfit(along_track,SAR_coord_param.surf(3,:),10);
      SAR_coord_param.surf(3,:) = polyval(SAR_coord_param.surf_p,along_track);
      N = length(SAR_coord_param.surf_p);
      surfSlope = SAR_coord_param.surf_p(N-1);
      x_pwr = along_track;
      for ii = N-3:-1:1
        surfSlope = surfSlope + (N-ii)*SAR_coord_param.surf_p(ii)*along_track.*x_pwr;
        x_pwr = x_pwr.*along_track;
      end
      surfSlope = surfSlope + 2*SAR_coord_param.surf_p(N-2)*along_track;
      surfSlope(abs(surfSlope)<0.0001*pi/180) = 0;
      SAR_coord_param.surfAngle = atan(surfSlope);
      % SAR_coord_param.surfNormal = zeros(3,length(along_track));
      % SAR_coord_param.surfNormal(1,:) = cos(atan(surfSlope)+pi/2);
      % SAR_coord_param.surfNormal(3,:) = sin(atan(surfSlope)+pi/2);
      % SAR_coord_param.surfNormalAngle = atan(surfSlope)+pi/2;
      SAR_coord_param.surfBins = round((2*(z_enu-SAR_coord_param.surf(3,:))/c-wfs(wf).time(1))/wfs(wf).dt) + 1;
      
      n = size(data,1);
      m = length(param.proc.output_along_track_idxs);
      SAR_coord_param.pixel = zeros(3,n,m);
      SAR_coord_param.pixel(1,:,:) = repmat(x_enu(param.proc.output_along_track_idxs),n,1);
      SAR_coord_param.pixel(2,:,:) = repmat(y_enu(param.proc.output_along_track_idxs),n,1);
      eta_ice = sqrt(er_ice);
      for line = 1:m
        out_idx = param.proc.output_along_track_idxs(line);
        SAR_coord_param.pixel(3,1:SAR_coord_param.surfBins(out_idx),line) = z_enu(out_idx) - wfs(wf).time(1)*c/2 - ...
          [(0:SAR_coord_param.surfBins(out_idx)-1)'*wfs(wf).dt*c/2];
        SAR_coord_param.pixel(3,SAR_coord_param.surfBins(out_idx)+1,line) = ...
          SAR_coord_param.pixel(3,SAR_coord_param.surfBins(out_idx),line) -...
          c*(surfTimes(out_idx)-wfs(wf).time(SAR_coord_param.surfBins(out_idx)))/2 -...
          (wfs(wf).time(SAR_coord_param.surfBins(out_idx)+1)-surfTimes(out_idx))*c/(2*eta_ice);
        SAR_coord_param.pixel(3,SAR_coord_param.surfBins(out_idx)+2:n,line) = ...
          SAR_coord_param.pixel(3,SAR_coord_param.surfBins(out_idx)+1,line) - ...
          (1:n-SAR_coord_param.surfBins(out_idx)-1)'*wfs(wf).dt*c/(2*eta_ice);
      end
      SAR_coord_param.h = SAR_coord_param.phase_center(3,:)-SAR_coord_param.surf(3,:);
      SAR_coord_param.h_mean = mean(SAR_coord_param.h);
      Lsar_surf = c/wfs(wf).fc*SAR_coord_param.h_mean/(2*param.sar.sigma_x);
      SAR_coord_param.HbeamWidth = atan(0.5*Lsar_surf/SAR_coord_param.h_mean);
      
      tdbp_param = SAR_coord_param;
      clear SAR_coord_param;
      tdbp_param.proc.Nfft = 2^ceil(log2(length(wfs(wf).time_raw)));
      tdbp_param.proc.skip_surf = param.sar.skip_surf;
      tdbp_param.proc.start_range_bin_above_surf = param.sar.start_range_bin_above_surf;
      tdbp_param.proc.start_range_bin = param.sar.start_range_bin;
      tdbp_param.proc.end_range_bin = param.sar.end_range_bin;
      tdbp_param.refraction_method = param.sar.refraction_method;
      tdbp_param.fc = wfs(wf).fc;
      tdbp_param.time = wfs(wf).time;
      tdbp_param.c = c;
      tdbp_param.eta_ice = eta_ice;
      tdbp_param.st_wind = param.sar.st_wind;
      tdbp_param.sub_aperture_steering = param.sar.sub_aperture_steering;
            
      fcs.squint = [0 0 -1].';
      tdbp_data0 = tdbp(tdbp_param,data);
      
      for subap = 1:size(tdbp_data0,3) % save each subaperture data to its own folder
        % Create output path
        out_path = fullfile(ct_filename_out(param,param.sar.out_path, 'CSARP_out'),...
          sprintf('tdbp_data_%03d_%02d_%02d',param.proc.frm,subap, param.proc.sub_band_idx));
        if ~exist(out_path,'dir')
          mkdir(out_path);
        end
        
        % Create filename
        % - Hack: multiple receivers are named with the first receiver in the list
        out_fn = sprintf('wf_%02d_adc_%02d_chk_%03d', wf, adc, param.sar.chunk_id);
        out_full_fn = fullfile(out_path,[out_fn '.mat']);
        
        % Save
        fprintf('  Saving output %s\n', out_full_fn);
        param_sar = param;
        param_sar.tdbp = tdbp_param;
        tdbp_data = tdbp_data0(:,:,subap);
        ct_save(out_full_fn,'tdbp_data','fcs','lat','lon','elev','wfs','param_sar','param_records','tdbp_param');
      end
    elseif strcmpi(param.sar.sar_type,'mltdp')
      fcs.squint = [0 0 -1].';
      [B,A] = butter(4,0.1);

      % Force elevation to be smooth (might be required for refraction)
      smoothed_elevation = filtfilt(B,A,records.elev);
      smoothed_ref_elevation = filtfilt(B,A,hdr.ref.elev);

      % Fit surface to polynomial to force it to be smooth (required for refraction)
      %  - Fit is done with special x-axis to prevent bad conditioning
      smoothed_surface = filtfilt(B,A,records.surface);
      sz_poly_order = 11;
      xfit = linspace(-1,1,length(smoothed_surface));
      smoothed_surface = polyval(polyfit(xfit,smoothed_surface,sz_poly_order),xfit);
      if 0 % set to 1 for surface fit over whole frame
        smoothed_elevation = interp1(param.proc.along_track_frm,param.proc.smoothed_elevation,param.proc.along_track,'linear','extrap');
        smoothed_surface = interp1(param.proc.along_track_frm,param.proc.smoothed_surface,param.proc.along_track,'linear','extrap');
      end

      data = data{img}(:,:,wf_adc);        
      % options for processing window in fast time
      surfBins_at_output = round((smoothed_surface-wfs(wf).time(1))/wfs(wf).dt)+1;
      if isempty(param.sar.skip_surf)
        param.scarp.skip_surf = 0;                   % default value
      end
      if isempty(param.sar.start_range_bin_above_surf)
        param.sar.start_range_bin_above_surf = 5;  % default value
      end
      if param.sar.skip_surf
        if isempty(param.sar.start_range_bin)
          param.sar.start_range_bin = max(surfBins_at_output) + 5;   % default value
        end
      else
        param.sar.start_range_bin = min(surfBins_at_output) - param.sar.start_range_bin_above_surf;        % default value
      end
      if isempty(param.sar.end_range_bin)
        param.sar.end_range_bin = size(data,1);  % default value
      end
%       if strcmpi(param.season_name,'mcords_simulator') % for 20110708_01_001 simulated data
%         output_along_track(463) = along_track(4632);
%         output_along_track(1:462) = output_along_track(463)-[462:-1:1]*param.sar.sigma_x;
%         output_along_track(464:925) = output_along_track(463)+[1:462]*param.sar.sigma_x;
%       end
      mltdp_data0 = ml_tdp(data,wfs(wf).fc,wfs(wf).time,along_track, smoothed_ref_elevation, ...
        smoothed_elevation,smoothed_surface,output_along_track,Lsar, ...
        length(param.sar.sub_aperture_steering),param.sar.start_range_bin,param.sar.end_range_bin,param.sar.start_eps);
      
      for subap = 1:size(mltdp_data0,3) % save each subaperture data to its own folder
        % Create output path
        out_path = fullfile(ct_filename_out(param,param.sar.out_path, 'CSARP_out'),...
          sprintf('mltdp_data_%03d_%02d_%02d',param.proc.frm,subap, param.proc.sub_band_idx));
        if ~exist(out_path,'dir')
          mkdir(out_path);
        end
        
        % Create filename
        % - Hack: multiple receivers are named with the first receiver in the list
        out_fn = sprintf('wf_%02d_adc_%02d_chk_%03d',wf, adc,param.sar.chunk_id);
        out_full_fn = fullfile(out_path,[out_fn '.mat']);
        
        fprintf('  Saving output %s\n', out_full_fn);
        param_sar = param;
        mltdp_data = mltdp_data0(:,:,subap);
        ct_save('-v7.3',out_full_fn,'mltdp_data','fcs','lat','lon','elev','wfs','param_sar','param_records');
      end
    elseif strcmpi(param.sar.sar_type,'tdbp')
    %% Time Domain Processor
      % time domain backporjection overview
      data = data{img}(:,:,wf_adc);
      
%       fcs_phase_centers = SAR_coord_system(SAR_coord_param,records,hdr.ref,along_track,along_track);
      fcs_phase_center_idxs = interp1(output_along_track,1:length(output_along_track),along_track,'nearest');
      if isnan(fcs_phase_center_idxs(1))
        fcs_phase_center_idxs(1:find(~isnan(fcs_phase_center_idxs),1)-1) = 1;
      end
      if isnan(fcs_phase_center_idxs(end))
        fcs_phase_center_idxs(find(~isnan(fcs_phase_center_idxs),1,'last')+1:end) = length(output_along_track);
      end
      for fcs_idx = 1:length(fcs_phase_center_idxs)
        fcs_phase_centers.x(:,fcs_idx) = fcs.x(:,fcs_phase_center_idxs(fcs_idx));
      end
      
      records.lon_ref = mean(records.lon);
      records.lat_ref = mean(records.lat);
      records.elev_ref = mean(records.elev);
      
      % set up SAR coordinate system
      [x_ecef, y_ecef, z_ecef] = geodetic2ecef(records.lat*pi/180, records.lon*pi/180, records.elev, WGS84.ellipsoid);

      SAR_coord_param.phase_center = [x_ecef;y_ecef;z_ecef];
      SAR_coord_param.Lsar = sar.Lsar;
      a1 = along_track(1);
      SAR_coord_param.along_track = along_track-a1;
      % Should be in c++ indices.
      SAR_coord_param.output_along_track = output_along_track-a1;
      SAR_coord_param.output_pos = fcs.origin;
      SAR_coord_param.wfs = wfs(wf);
      
      % surface tracker
      % two methods to get ice surface: param.surf_source 1/2
      % 1: from get_heights; 2:from laser data;
      param.surf_source = 1;
      if param.surf_source == 1
        surfTimes = records.surface;
      elseif param.surf_source == 2
        param.laser_surface = 1;
        param.laser_data_fn = '/cresis/projects/metadata/2008_Greenland_TO_icessn/2008_Greenland/080801a_icessn_nadir0seg';
        param.laser_data_fn = '/cresis/projects/metadata/2008_Greenland_TO_icessn/2008_Greenland/080707_icessn_nadir0seg';
        fid = fopen(param.laser_data_fn);
        [laser_data_tmp] = textscan(fid,'%f%f%f%f%f%f%f%f%f%f%f');
        fclose(fid);
        Year = 2008;
        Mon = 7;
        Day = 7;
        laser_data.gps_time = (datenum(Year,Mon,Day)-datenum(1970,1,1))*86400 + laser_data_tmp{1};
        laser_data.surf_elev = laser_data_tmp{4};
        laser_data.surf_elev = interp1(laser_data.gps_time,laser_data.surf_elev,records.gps_time);
        surfTimes = 2*(records.elev-laser_data.surf_elev)/c;
        clear laser_data_tmp;
      end
      
      for i = 1:3
        fcs_phase_centers.x(i,:) = interp1(output_along_track,fcs.x(i,:),along_track);
        fcs_phase_centers.z(i,:) = interp1(output_along_track,fcs.z(i,:),along_track);
      end
      idx1 = find(~isnan(fcs_phase_centers.x(1,:)),1)-1;
      idx2 = find(~isnan(fcs_phase_centers.x(1,:)),1,'last')+1;
      for i = 1:3
        fcs_phase_centers.x(i,1:idx1) = fcs_phase_centers.x(i,idx1+1);
        fcs_phase_centers.x(i,idx2:end) = fcs_phase_centers.x(i,idx2-1);
        fcs_phase_centers.z(i,1:idx1) = fcs_phase_centers.z(i,idx1+1);
        fcs_phase_centers.z(i,idx2:end) = fcs_phase_centers.z(i,idx2-1);
      end
      
%       SAR_coord_param.surf = zeros(3,length(along_track));
%       SAR_coord_param.surf(1,:) = x_ecef +surfTimes*c/2 .* fcs_phase_centers.z(1,:);
%       SAR_coord_param.surf(2,:) = y_ecef + surfTimes*c/2 .* fcs_phase_centers.z(2,:);
%       SAR_coord_param.surf(3,:) = z_ecef + surfTimes*c/2 .* fcs_phase_centers.z(3,:);
      
      surfTimes = sgolayfilt(records.surface,3,round(param.sar.surf_filt_dist / median(diff(along_track))/2)*2+1);
%       surfTimes = sar.surf_pp.coefs(out_rlines,end);
%       SAR_coord_param.surf_poly = sar.surf_pp.coefs(out_rlines,:).'*c/2;
      SAR_coord_param.surf_along_track = -surfTimes*c/2;
      surf_poly = spline(along_track,SAR_coord_param.surf_along_track);
      SAR_coord_param.surf_poly = surf_poly.coefs.';
      SAR_coord_param.surf_line = polyfit(along_track,SAR_coord_param.surf_along_track,1);
      
      [~,surf_max_idx] = max(SAR_coord_param.surf_along_track);
      if surf_max_idx==length(SAR_coord_param.surf_along_track);
        surf_max_idx = surf_max_idx-1;
      elseif surf_max_idx==1;
        surf_max_idx = 2;
      end
      surf_max_poly = SAR_coord_param.surf_poly(:,surf_max_idx);
      surf_der = polyval([length(surf_max_poly)-1:-1:1].'.*surf_max_poly(1:end-1),0);
      if surf_der==0
        surf_max = surf_max_poly(end);
      elseif surf_der<0
        surf_max_idx = surf_max_idx-1;
        surf_max_poly = SAR_coord_param.surf_poly(:,surf_max_idx);
      end
      surf_at_max = roots((length(surf_max_poly)-1:-1:1).'.*surf_max_poly(1:end-1));
     	surf_at_max = surf_at_max(surf_at_max>0 & surf_at_max<diff(along_track(surf_max_idx+[0,1])));
      if isempty(surf_at_max)
        surf_max = max(SAR_coord_param.surf_along_track(surf_max_idx+[0,1]));
      else
        surf_max = max(polyval(surf_max_poly,surf_at_max));
      end
      
      SAR_coord_param.surf_max = surf_max;
      
      x_ecef = fcs.origin(1,:);
      y_ecef = fcs.origin(2,:);
      z_ecef = fcs.origin(3,:);
            
      SAR_coord_param.surfBins = floor((surfTimes - wfs(wf).time(1))/wfs(wf).dt);
      
      jordan; % filter these
      output_surfTimes = -fcs.surface;
      output_surfBins = floor((fcs.surface - wfs(wf).time(1))/wfs(wf).dt);
      
      t0 = wfs(wf).time(1);
            
      n = size(data,1);
      m = length(output_along_track);
      SAR_coord_param.pixel = zeros(3,n,m);
      eta_ice = sqrt(er_ice);
      for line = 1:m
        surfBin = output_surfBins(line);
        surfTime = abs(output_surfTimes(line));
        
        % if surface data is collected by radar
        if surfBin<n
%           
          pixel_ranges = wfs(wf).time(1:surfBin)*c/2;
          SAR_coord_param.pixel(1,1:surfBin,line) = x_ecef(line) + ...
            pixel_ranges*fcs_phase_centers.z(1,line);
          SAR_coord_param.pixel(2,1:surfBin,line) = y_ecef(line) + ...
            pixel_ranges*fcs_phase_centers.z(2,line);
          SAR_coord_param.pixel(3,1:surfBin,line) = z_ecef(line) + ...
            pixel_ranges*fcs_phase_centers.z(3,line);
          
          pixel_ranges = (surfTime + (wfs(wf).time(surfBin+1)-surfTime)/eta_ice) * c/2;
          SAR_coord_param.pixel(1,surfBin+1,line) = x_ecef(line) + ...
            pixel_ranges*fcs_phase_centers.z(1,line);
          SAR_coord_param.pixel(2,surfBin+1,line) = y_ecef(line) + ...
            pixel_ranges*fcs_phase_centers.z(2,line);
          SAR_coord_param.pixel(3,surfBin+1,line) = z_ecef(line) + ...
            pixel_ranges*fcs_phase_centers.z(3,line);
          
          if surfBin<n-1
            pixel_ranges = pixel_ranges+(wfs(wf).time(surfBin+2:end)-wfs(wf).time(surfBin+1))*c/eta_ice/2;
            SAR_coord_param.pixel(1,surfBin+2:end,line) = x_ecef(line) + ...
              pixel_ranges*fcs_phase_centers.z(1,line);
            SAR_coord_param.pixel(2,surfBin+2:end,line) = y_ecef(line) + ...
              pixel_ranges*fcs_phase_centers.z(2,line);
            SAR_coord_param.pixel(3,surfBin+2:end,line) = z_ecef(line) + ...
              pixel_ranges*fcs_phase_centers.z(3,line);
          end
          
        % if surface data is not collected by radar
        else
          
          pixel_ranges = wfs(wf).time(1:surfBin)*c/2;
          SAR_coord_param.pixel(1,:,line) = x_ecef(line) + ...
            pixel_ranges*fcs_phase_centers.z(1,line);
          SAR_coord_param.pixel(2,:,line) = y_ecef(line) + ...
            pixel_ranges*fcs_phase_centers.z(2,line);
          SAR_coord_param.pixel(3,:,line) = z_ecef(line) + ...
            pixel_ranges*fcs_phase_centers.z(3,line);
          
        end
      end
      
      if isfield(param.sar,'end_time') && ~isempty(param.sar.end_time)
        if param.sar.end_time<=wfs(wf).time(end) && param.sar.end_time>=wfs(wf).time(1)
          tdbp_param.end_time = param.sar.end_time;
          t_idx = interp1(wfs(wf).time,1:length(wfs(wf).time),param.sar.end_time,'next');
          SAR_coord_param.pixel = SAR_coord_param.pixel(:,1:t_idx,:);
        end
      end
%       
      if isfield(param.sar,'time_start') && ~isempty(param.sar.time_start)
        if param.sar.time_start<=wfs(wf).time(end) && param.sar.time_start>=wfs(wf).time(1)
          tdbp_param.time_start = param.sar.time_start;
          t_idx = interp1(wfs(wf).time,1:length(wfs(wf).time),param.sar.time_start,'previous');
          SAR_coord_param.pixel = SAR_coord_param.pixel(:,t_idx:end,:);
        end
      end
            
      % number of entries in library
      N_lib = 32;

      dt = wfs(wf).dt;

      bw = wfs(wf).f1 - wfs(wf).f0;
      
      % sub-time bin step given number of entries
      dts = dt/N_lib;

      matched_sig_lib = zeros(wfs(wf).Nt,N_lib);
      mid = ceil(wfs(wf).Nt/2+1);
      % loop through delays and directly create matched signal response
      %   implements marginal time shift in signal to find envelope.
      t = ((1:size(matched_sig_lib,1)).'-mid)*dt;
      for del_idx = 0:(N_lib-1)
          matched_sig_lib(:,del_idx+1) = sinc((t-dts*del_idx)*bw);
      end
      % Filter contains ~97.5% of area under sinc^2 curve
      matched_sig_lib = matched_sig_lib(mid+(-ceil(3.94/bw/dt):ceil(3.94/bw/dt)),:);
      
      tdbp_param = SAR_coord_param;
      clear SAR_coord_param;
            
      tdbp_param.fc = wfs(wf).fc;
      tdbp_param.t0 = t0;
      tdbp_param.dt = dt;
      tdbp_param.matched_sig_lib = matched_sig_lib;
      
      tdbp_param.fcs_x = fcs_phase_centers.x;
      
      tdbp_param.st_wind = param.sar.st_wind;
      tdbp_param.k_window = 1;
      
      tdbp_param.n0 = 1;
      tdbp_param.n1 = eta_ice;
      
      if isfield(param.sar,'refraction_flag');
        tdbp_param.refraction_flag = param.sar.refraction_flag;
      end
      
      kx_bw = abs(c/wfs(wf).fc)/param.sar.sigma_x;
      
      num_subapertures = length(param.sar.sub_aperture_steering);
      tdbp_data0 = [];
      for subap = 1:num_subapertures
      
        kx0 = param.sar.sub_aperture_steering(subap);
        kx_support_limits = asin(kx0+kx_bw*[-1,1]/2);
        
        tdbp_param.kx_support_limits = kx_support_limits;
        
        fprintf('Beginning SAR Processing...\n');
        tdbp_data0(:,:,subap) = sar_proc_task(tdbp_param,double(data));
      end
      
      for subap = 1:size(tdbp_data0,3) % save each subaperture data to its own folder
        % Create output path
        out_path = fullfile(ct_filename_out(param,param.sar.out_path, 'CSARP_out'),...
          sprintf('tdbp_data_%03d_%02d_%02d',param.load.frm,subap, param.load.sub_band_idx));
        if ~exist(out_path,'dir')
          mkdir(out_path);
        end
        
        % Create filename
        % - Hack: multiple receivers are named with the first receiver in the list
        out_fn = sprintf('wf_%02d_adc_%02d_chk_%03d', wf, adc, param.load.chunk_idx);
        out_full_fn = fullfile(out_path,[out_fn '.mat']);
        
        % Save
        fprintf('  Saving output %s\n', out_full_fn);
        param_sar = param;
        param_sar.tdbp = tdbp_param;
        tdbp_data = tdbp_data0(:,:,subap);
        ct_save('-v7.3',out_full_fn,'tdbp_data','fcs','lat','lon','elev','wfs','param_sar','param_records','tdbp_param');
      end
    end
  end
end

fprintf('%s done %s\n', mfilename, datestr(now));

success = true;
