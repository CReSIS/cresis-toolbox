function [data,metadata] = sar_load(param)
% [data,metadata] = sar_load(param)
%
% Loads and concatenates sar data from a single frame. Currently requires
% all data to be in the same directory. Returns data, position, and header
% information associated with the sar data.
%
% param.sar_load: parameter structure controlling how data are loaded.
% See input arguments section for details
%
% Author: John Paden, Logan Smith
%
% See also: run_master.m, master.m, run_array.m, array.m, run_sar_equal.m,
% run_sar_load.m, sar_equal.m, sar_load.m, array_proc.m, array_task.m,
% array_combine_task.m

%% Check input arguments
% =========================================================================

%% Input: sar param
% subap: list of subapertures to load (array of integers, default is 1)
if ~isfield(param.sar,'sub_aperture_steering') || isempty(param.sar.sub_aperture_steering)
  % Single aperture which points broadside to SAR is default
  param.sar.sub_aperture_steering = [0];
end

%% Input: sar_load param
% combine_channels: Logical scaler. Sum wf-adc pairs together coherently in
% each image to form a single image.
if ~isfield(param.sar_load,'combine_channels') || isempty(param.sar_load.combine_channels)
  param.sar_load.combine_channels = false;
end

% combine_imgs: Logical scaler. Combine images together in fast-time
% (requires wf_comb to be set). Often used to combine low gain and high
% gain images and short and long pulse duration images.
if ~isfield(param.sar_load,'combine_imgs') || isempty(param.sar_load.combine_imgs)
  param.sar_load.combine_imgs = false;
end

% debug_level
if ~isfield(param.sar_load,'debug_level') || isempty(param.sar_load.debug_level)
  param.sar_load.debug_level = 1;
end

% detrend: structure controlling detrending. Arguments are passed into
% local_detrend.m. Detrend is disabled by default (detrend.cmd == 0).
% Detrending only runs if combine_channels == true and incoherent == true.
if ~isfield(param.sar_load,'detrend') || isempty(param.sar_load.detrend)
  param.sar_load.detrend.cmd = [];
end
if ~isfield(param.sar_load.detrend,'B_noise') || isempty(param.sar_load.detrend.B_noise)
  param.sar_load.detrend.B_noise = [100 200];
end
if ~isfield(param.sar_load.detrend,'B_sig') || isempty(param.sar_load.detrend.B_sig)
  param.sar_load.detrend.B_sig = [10 20];
end
if ~isfield(param.sar_load.detrend,'cmd') || isempty(param.sar_load.detrend.cmd)
  param.sar_load.detrend.cmd = 0;
end
if ~isfield(param.sar_load.detrend,'minVal') || isempty(param.sar_load.detrend.minVal)
  param.sar_load.detrend.minVal = -inf;
end

% fn: Data directory. Default is "sar" which loads from "CSARP_sar".
if ~isfield(param.sar_load,'in_path') || isempty(param.sar_load.in_path)
  param.sar_load.in_path = 'sar';
end

% frm: Data frames to load
if isfield(param.sar_load,'frm')
  warning('Legacy input field param.sar_load.frm is ignored and is now called param.sar_load.frms since sar_load.m now supports loading multiple frames at once.');
end
if ~isfield(param.sar_load,'frms') || isempty(param.sar_load.frms)
  warning('The param.sar_load.frms field must be set to an integer array indicating which frames to load. Defaulting to param.sar_load.frms = 1.');
  param.sar_load.frms = 1;
end
% chunk: two element vector specifying the start and stop chunk to load
% (minimum value is 1 and maximum value is the number of chunks in the
% frame). If the stop chunk is specified, then the stop chunk is set to the
% number of chunks. The default is to load all chunks which is [1 inf]. All
% chunks for a single frame in param.sar_load.frms is {[1 inf]}.
if ~isfield(param.sar_load,'chunk') || isempty(param.sar_load.chunk)
  param.sar_load.chunk = {};
elseif isnumeric(param.sar_load.chunk) && length(param.sar_load.chunk) == 2
  % Legacy: support old single frame format
  param.sar_load.chunk = {param.sar_load.chunk};
end
for frm_idx = 1:length(param.sar_load.frms)
  if length(param.sar_load.chunk) < frm_idx || isempty(param.sar_load.chunk{frm_idx})
    % Load all chunks if chunk range is not specified for a frame
    param.sar_load.chunk{frm_idx} = [1 inf];
  end
end

% imgs: cell array of images to load. Each cell array contains a 2 by N
% waveform-adc pair list where N is the number of wf-adc pairs to load.
% Default is {[1 1]} which loads one image and this image is pulled from
% waveform = 1, adc = 1.
if ~isfield(param.sar_load,'imgs') || isempty(param.sar_load.imgs)
  param.sar_load.imgs = {[1 1]};
end

% incoherent: logical scalar, default is false, if true, the data will be
% power detected on load with abs()^2. Incoherent only runs if
% combine_channels == true.
if ~isfield(param.sar_load,'incoherent') || isempty(param.sar_load.incoherent)
  param.sar_load.incoherent = false;
end

% sar_type: 'fk' or 'tdbp'. Default is 'fk'.
if ~isfield(param.sar_load,'sar_type') || isempty(param.sar_load.sar_type)
  param.sar_load.sar_type = 'fk';
end

% subap: list of subapertures to load (array of integers, default is all
% subapertures specified in param.sar.sub_aperture_steering)
if ~isfield(param.sar_load,'subap') || isempty(param.sar_load.subap)
  param.sar_load.subap = 1:length(param.sar.sub_aperture_steering);
end

physical_constants;

%% Load subapertures
% =========================================================================

% The base path for all the data
base_path = ct_filename_out(param,param.sar_load.in_path,'');

% Initialize memory for outputs
data     = cell(length(param.sar_load.imgs),1);
metadata = [];
metadata.lat = [];

for subap_idx = 1:length(param.sar_load.subap)
  subap = param.sar_load.subap(subap_idx);

  %% Frames: Load frames of SAR data
  cur_rline = 0;
  for frm_idx = 1:length(param.sar_load.frms)
    frm = param.sar_load.frms(frm_idx);
    
    in_path = fullfile(base_path, ...
      sprintf('%s_data_%03d_%02d_01',param.sar_load.sar_type,frm,subap));
    
    %% Determine which chunks are available for this subaperture
    img = 1;
    wf_adc_list = param.sar_load.imgs{img};
    wf_adc = 1;
    wf = wf_adc_list(wf_adc,1);
    adc = wf_adc_list(wf_adc,2);
    fns = get_filenames(in_path,sprintf('wf_%02.0f_adc_%02.0f_chk_',wf,adc),'','.mat');
    valid_chks = [];
    for fns_idx = 1:length(fns)
      [~,fn_name] = fileparts(fns{fns_idx});
      valid_chks(end+1) = str2double(fn_name(end-2:end));
    end
    if isempty(valid_chks)
      error('No valid sar chunks/blocks exist for the requested data.');
    end
    param.sar_load.chunk{frm_idx}(param.sar_load.chunk{frm_idx}==inf) = max(valid_chks);
    chks_to_load = param.sar_load.chunk{frm_idx}(1):param.sar_load.chunk{frm_idx}(end);
    
    % Remove chunks that do not exist from chunks_to_load list
    [valid_chks,keep_idxs] = intersect(chks_to_load, valid_chks);
    if length(valid_chks) ~= length(chks_to_load)
      bad_mask = ones(size(chks_to_load));
      bad_mask(keep_idxs) = 0;
      warning('Nonexistent chunks specified in chks_to_load (e.g. chunk "%g" is invalid), removing these', ...
        chks_to_load(find(bad_mask,1)));
      chks_to_load = valid_chks;
    end
    
    %% Subapertures: Load chunks (blocks) of SAR data for frame
    for chunk = chks_to_load
      
      if param.sar_load.debug_level >= 1
        fprintf('Loading chunk %d (%s)\n', chunk, datestr(now,'HH:MM:SS'));
      end
      
      % =====================================================================
      % Load data
      
      tx = 1;
      for img = 1:length(param.sar_load.imgs)
        wf_adc_list = param.sar_load.imgs{img};
        
        % -------------------------------------------------------------------
        % Load data
        for wf_adc = 1:size(wf_adc_list,1)
          wf = wf_adc_list(wf_adc,1);
          adc = wf_adc_list(wf_adc,2);
          
          sar_fn = fullfile(in_path,sprintf('wf_%02.0f_adc_%02.0f_chk_%03.0f.mat',wf,adc,chunk));
          if param.sar_load.debug_level >= 2
            fprintf(' %s (%s)\n', sar_fn, datestr(now,'HH:MM:SS'));
          end
          sar_data = load(sar_fn);
          
          % Only add in non-overlapping part of SAR image (this is to support
          % legacy SAR data format since current format does not have
          % overlap)
          if img == 1 && wf_adc == 1
            if frm_idx == 1 && chunk == param.sar_load.chunk{frm_idx}(1)
              new_idxs = 1:length(sar_data.fcs.gps_time);
            else
              % 1e-6 added to avoid rounding errors... this is a hack
              new_idxs = find(sar_data.fcs.gps_time > fcs{img}{wf_adc}.gps_time(end)+1e-6);
            end
          end
          
          % Get output image positions (not phase centers)
          if img == 1 && wf_adc == 1 && subap_idx == 1
            if isempty(metadata.lat)
              metadata.lat = sar_data.lat;
              metadata.lon = sar_data.lon;
              metadata.elev = sar_data.elev;
            else
              metadata.lat = [metadata.lat sar_data.lat(new_idxs)];
              metadata.lon = [metadata.lon sar_data.lon(new_idxs)];
              metadata.elev = [metadata.elev sar_data.elev(new_idxs)];
            end
          end
          
          if subap_idx == 1
            if frm_idx == 1 && chunk == param.sar_load.chunk{frm_idx}(1)
              fcs{img}{wf_adc} = sar_data.fcs;
              
            else
              fcs{img}{wf_adc}.gps_time = cat(2,fcs{img}{wf_adc}.gps_time, ...
                sar_data.fcs.gps_time(new_idxs));
              fcs{img}{wf_adc}.x = cat(2,fcs{img}{wf_adc}.x, ...
                sar_data.fcs.x(:,new_idxs));
              fcs{img}{wf_adc}.y = cat(2,fcs{img}{wf_adc}.y, ...
                sar_data.fcs.y(:,new_idxs));
              fcs{img}{wf_adc}.z = cat(2,fcs{img}{wf_adc}.z, ...
                sar_data.fcs.z(:,new_idxs));
              fcs{img}{wf_adc}.origin = cat(2,fcs{img}{wf_adc}.origin, ...
                sar_data.fcs.origin(:,new_idxs));
              fcs{img}{wf_adc}.pos = cat(2,fcs{img}{wf_adc}.pos, ...
                sar_data.fcs.pos(:,new_idxs));
              fcs{img}{wf_adc}.roll = cat(2,fcs{img}{wf_adc}.roll, ...
                sar_data.fcs.roll(new_idxs));
              fcs{img}{wf_adc}.pitch = cat(2,fcs{img}{wf_adc}.pitch, ...
                sar_data.fcs.pitch(new_idxs));
              fcs{img}{wf_adc}.heading = cat(2,fcs{img}{wf_adc}.heading, ...
                sar_data.fcs.heading(new_idxs));
              fcs{img}{wf_adc}.surface = cat(2,fcs{img}{wf_adc}.surface, ...
                sar_data.fcs.surface(new_idxs));
              fcs{img}{wf_adc}.bottom = cat(2,fcs{img}{wf_adc}.bottom, ...
                sar_data.fcs.bottom(new_idxs));
            end
          end
          
          Nt = size(sar_data.fk_data,1);
          if ~param.sar_load.combine_channels
            if subap_idx == 1 && wf_adc == 1
              % Allocate memory in a special way when loading 3D data
              data{img}(size(sar_data.fk_data,1), ...
                size(data{img},2)+length(new_idxs),size(wf_adc_list,1),length(param.sar_load.subap)) = single(0);
            end
            data{img}(:,cur_rline + (1:length(new_idxs)),wf_adc,subap_idx) = sar_data.fk_data(:,new_idxs);
          else
            % When combining channels, take the mean of the data as it
            % is loaded in to reduce peak memory consumption.
            if wf_adc == 1
              sar_data_data = sar_data.fk_data(:,new_idxs) / size(wf_adc_list,1);
            else
              sar_data_data = sar_data_data + sar_data.fk_data(:,new_idxs) / size(wf_adc_list,1);
            end
          end
          
        end
        
        if param.sar_load.combine_channels
          if param.sar_load.incoherent
            data{img} = [data{img} abs(sar_data_data).^2];
          else
            data{img} = [data{img} sar_data_data];
          end
        end
      end
      
      cur_rline = cur_rline + length(new_idxs);
    end
  end
end

% Create lat/lon fields in FCS for convenience
for img = 1:length(fcs)
  for wf_adc = 1:length(fcs{img})
    [fcs{img}{wf_adc}.lat,fcs{img}{wf_adc}.lon,fcs{img}{wf_adc}.elev] ...
      = ecef2geodetic(fcs{img}{wf_adc}.origin(1,:) + sum(fcs{img}{wf_adc}.x.*fcs{img}{wf_adc}.pos), ...
      fcs{img}{wf_adc}.origin(2,:) + sum(fcs{img}{wf_adc}.y.*fcs{img}{wf_adc}.pos), ...
      fcs{img}{wf_adc}.origin(3,:) + sum(fcs{img}{wf_adc}.z.*fcs{img}{wf_adc}.pos), ...
      WGS84.ellipsoid);
    fcs{img}{wf_adc}.lat = fcs{img}{wf_adc}.lat * 180/pi;
    fcs{img}{wf_adc}.lon = fcs{img}{wf_adc}.lon * 180/pi;
  end
end

metadata.fcs = fcs;
metadata.wfs = sar_data.wfs;
metadata.param_records = sar_data.param_records;
metadata.param_sar = sar_data.param_sar;

if param.sar_load.combine_channels && param.sar_load.combine_imgs
  
end

if param.sar_load.combine_channels && param.sar_load.incoherent ...
    && param.sar_load.detrend.cmd
  % Detrend data
  detrend = param.sar_load.detrend;
  if param.sar_load.combine_imgs
    data = local_detrend(data, detrend.B_noise, ...
      detrend.B_sig, detrend.cmd, detrend.minVal);
  else
    for img = 1:length(param.imgs)
      data{img} = local_detrend(data{img}, detrend.B_noise, ...
        detrend.B_sig, detrend.cmd, detrend.minVal);
    end
  end
end
