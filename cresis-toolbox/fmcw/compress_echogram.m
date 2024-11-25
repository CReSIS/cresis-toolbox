function compress_echogram(param, param_override)
% compress_echogram(param, param_override)
%
% Compresses echogram files (CSARP_*). This involves three steps:
% 1. Elevation compensation
% 2. Fast-time truncation according to param spreadsheet posting settings
% 3. Quantization of 32 bit float to user specified type (e.g. uint8)
%
% Inputs are full resolution qlook files and outputs are saved in posting
% directory.  The parameter file's command worksheet is used to determine
% which segments and frames are compressed (using the generic field).
% The posting worksheet is also used.
%
% Settings for NSIDC:
% compress_type = '';
% truncate_data = true;
% guard_depth_rng = [0 0];
% min_depth_rng = [-8 5];
% elev_comp = true;
% param_post_echo_depth_override_sea = '[min(Surface_Depth)-4 max(Surface_Depth)+5]'; % Sea Ice Segments Only
% param_post_echo_depth_override_land = '[min(Surface_Depth)-10 max(Surface_Depth)+80]'; % Land Ice Segments Only
% frm_types = {-1,0,-1,-1,-1}; % Which types of frames to compress (usual is {-1,0,-1,-1,-1})
%
% Examples:
% See run_compress_echogram.m for how to run.
%
% Author: John Paden

%% General Setup
% =========================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input check
% =========================================================================

if ~isfield(param.compress_echogram,'compress_type') ...
    || isempty(param.compress_echogram.compress_type)
  param.compress_echogram.compress_type = '';
end
compress_type = param.compress_echogram.compress_type;
if ~isempty(compress_type)
  compress_func = str2func(sprintf('@%s', compress_type));
end

if ~isfield(param.compress_echogram,'echogram_dir') ...
    || isempty(param.compress_echogram.echogram_dir)
  param.compress_echogram.echogram_dir = 'qlook';
end
echogram_dir = ct_filename_out(param,param.compress_echogram.echogram_dir,'');

if ~isfield(param.compress_echogram,'elev_comp') ...
    || isempty(param.compress_echogram.elev_comp)
  param.compress_echogram.elev_comp = true;
end
elev_comp = param.compress_echogram.elev_comp;

if ~isfield(param.compress_echogram,'guard_depth_rng') ...
    || isempty(param.compress_echogram.guard_depth_rng)
  param.compress_echogram.guard_depth_rng = [0 0];
end
guard_depth_rng = param.compress_echogram.guard_depth_rng;

if ~isfield(param.compress_echogram,'frm_types') ...
    || isempty(param.compress_echogram.frm_types)
  param.compress_echogram.frm_types = {-1,0,-1,-1,-1};
end
frm_types = param.compress_echogram.frm_types;

if ~isfield(param.compress_echogram,'imgs') ...
    || isempty(param.compress_echogram.imgs)
  param.compress_echogram.imgs = 0;
end

if ~isfield(param.compress_echogram,'layer_params') ...
    || isempty(param.compress_echogram.layer_params)
  param.compress_echogram.layer_params = [];
end
if ~isfield(param.compress_echogram.layer_params,'name') ...
    || isempty(param.compress_echogram.layer_params.name)
  param.compress_echogram.layer_params.name = 'surface';
end
if ~isfield(param.compress_echogram.layer_params,'source') ...
    || isempty(param.compress_echogram.layer_params.source)
  param.compress_echogram.layer_params.source = 'layerData';
end

if ~isfield(param.compress_echogram,'min_depth_rng') ...
    || isempty(param.compress_echogram.min_depth_rng)
  param.compress_echogram.min_depth_rng = [-8 5];
end
min_depth_rng = param.compress_echogram.min_depth_rng;

if ~isfield(param.compress_echogram,'out_dir') ...
    || isempty(param.compress_echogram.out_dir)
  param.compress_echogram.out_dir = 'CSARP_post/qlook';
end
out_dir = ct_filename_out(param,param.compress_echogram.out_dir,'');

% Default for sea ice segments ("sea" in mission name)
if ~isfield(param.compress_echogram,'param_post_echo_depth_override_sea') ...
    || isempty(param.compress_echogram.param_post_echo_depth_override_sea)
  param.compress_echogram.param_post_echo_depth_override_sea ...
    = '[min(Surface_Depth)-4 max(Surface_Depth)+5]';
end
param_post_echo_depth_override_sea = param.compress_echogram.param_post_echo_depth_override_sea;
% Default for land segments (no "sea" in mission name)
if ~isfield(param.compress_echogram,'param_post_echo_depth_override_land') ...
    || isempty(param.compress_echogram.param_post_echo_depth_override_land)
  param.compress_echogram.param_post_echo_depth_override_land ...
    = '[min(Surface_Depth)-10 max(Surface_Depth)+80]';
end
param_post_echo_depth_override_land = param.compress_echogram.param_post_echo_depth_override_land;
% Determine if segment is sea or land ice
if ~isempty(regexpi(param.cmd.mission_names,'Sea'))
  param_post_echo_depth_override = param_post_echo_depth_override_sea;
else
  param_post_echo_depth_override = param_post_echo_depth_override_land;
end

if ~isfield(param.compress_echogram,'truncate_data') ...
    || isempty(param.compress_echogram.truncate_data)
  param.compress_echogram.truncate_data = true;
end
truncate_data = param.compress_echogram.truncate_data;

% Load the frames file
frames = frames_load(param);
param.cmd.frms = frames_param_cmd_frms(param,frames);

%% Setup
% =========================================================================

physical_constants;

layers = opsLoadLayers(param,param.compress_echogram.layer_params);

%% Compress each frame in the list
% =========================================================================
for frm = param.cmd.frms
  % Get the filename
  for img = param.compress_echogram.imgs
    if img == 0
      fn = fullfile(echogram_dir,sprintf('Data_%s_%03d.mat', ...
        param.day_seg, frm));
    else
      fn = fullfile(echogram_dir,sprintf('Data_img_%02d_%s_%03d.mat', ...
        img, param.day_seg, frm));
    end
    
    if ct_proc_frame(frames.proc_mode(frm),frm_types)
      fprintf(' Input %s (%s)\n', fn, datestr(now));
    else
      fprintf(' Skipping %s (%s)\n', fn, datestr(now));
      continue;
    end
    
    if ~exist(fn,'file')
      warning('File %s does not exist!!!!!', fn);
      continue;
    end
    
    clear minData;
    tmp = load(fn);
    tmp.Surface = interp_finite(interp1(layers.gps_time,layers.twtt,tmp.GPS_time),NaN);
    if all(~isfinite(tmp.Surface))
      warning('No surface data.');
    end
    if ~isfield(tmp,'minData')
      orig_size = 4*numel(tmp.Data);
      
      % Elevation compensation
      if elev_comp
        max_elev = max(tmp.Elevation);
        dRange = max_elev - tmp.Elevation;
        if length(tmp.Time)<2
          dt = 1;
          dBins = zeros(size(dRange));
        else
          dt = tmp.Time(2)-tmp.Time(1);
          dBins = round(dRange / (c/2) / dt);
        end
        zero_pad_len = max(abs(dBins));
        tmp.Data = cat(1,tmp.Data,nan(zero_pad_len,size(tmp.Data,2)));
        if ~isempty(tmp.Time)
          tmp.Time = tmp.Time(1) + dt * (0:size(tmp.Data,1)-1).';
        end
        for rline = 1:size(tmp.Data,2)
          if dBins(rline) > 0
            tmp.Data(1+dBins(rline):end,rline) = tmp.Data(1:end-dBins(rline),rline);
            tmp.Data(1:dBins(rline),rline) = 0;
          elseif dBins(rline) < 0
            tmp.Data(1:end+dBins(rline),rline) = tmp.Data(1-dBins(rline):end,rline);
            tmp.Data(end+dBins(rline)+1:end,rline) = 0;
          end
          tmp.Elevation(rline) = tmp.Elevation(rline) + dBins(rline)*dt*c/2;
          tmp.Surface(rline) = tmp.Surface(rline) + dBins(rline)*dt;
        end
        tmp.Elevation_Correction = dBins;
      else
        dBins = zeros(1,size(tmp.Data,2));
      end
      
      if truncate_data
        % Truncate data in fast-time
        tmp.Depth = (tmp.Time-median(tmp.Surface))*c/2/sqrt(param.post.echo.er_ice);
        Surface_Depth = (tmp.Surface-median(tmp.Surface))*c/2/sqrt(param.post.echo.er_ice);
        if isempty(param.post.echo.depth)
          depth_rng = [tmp.Depth(1) tmp.Depth(end)];
        elseif ~isempty(param_post_echo_depth_override)
          depth_rng = eval(param_post_echo_depth_override);
        else
          depth_rng = eval(param.post.echo.depth);
        end
        depth_rng = depth_rng + guard_depth_rng;
        if depth_rng(1) > min_depth_rng(1)
          depth_rng(1) = min_depth_rng(1);
        end
        if depth_rng(2) < min_depth_rng(2)
          depth_rng(2) = min_depth_rng(2);
        end
        good_bins = find(tmp.Depth > depth_rng(1) & tmp.Depth < depth_rng(2));
        
        % Truncating data adds four variables
        % 1)Truncate_Bins
        tmp.Truncate_Bins = good_bins;
        tmp.Truncate_Median = nan(1,size(tmp.Data,2));
        tmp.Truncate_Mean = nan(1,size(tmp.Data,2));
        tmp.Truncate_Std_Dev = nan(1,size(tmp.Data,2));
        % 2) Truncate_Median, Truncate_Mean, Truncate_Std_Dev
        %    These will have a NaN for a range line when no valid bins were
        %    truncated for that range line.  Zero padded bins from elevation
        %    compensation are not valid.
        if ~isempty(good_bins)
          for rline = 1:size(tmp.Data,2)
            if 1+dBins(rline) < good_bins(1)
              tmp.Truncate_Median(rline) = median(tmp.Data(1+dBins(rline):good_bins(1),rline));
              tmp.Truncate_Mean(rline) = mean(tmp.Data(1+dBins(rline):good_bins(1),rline));
              tmp.Truncate_Std_Dev(rline) = std(tmp.Data(1+dBins(rline):good_bins(1),rline));
            end
          end
        end
        tmp.Data = tmp.Data(good_bins,:);
      end
      
      if ~isempty(compress_type)
        % Rescale float32 data to compress_type (uint8 or uint16)
        % Two new variables, minData and maxData, get
        % created in this process and Data becomes compressed
        tmp.Data = 10*log10(tmp.Data);
        tmp.minData = max(min(tmp.Data(isfinite(tmp.Data))), median(tmp.Data(isfinite(tmp.Data))) - 20);
        if ~isempty(tmp.Data)
          tmp.Data = tmp.Data - tmp.minData;
        end
        tmp.maxData = min(max(tmp.Data(isfinite(tmp.Data))), median(tmp.Data(isfinite(tmp.Data))) + 60);
        if ~isempty(tmp.Data)
          tmp.Data = compress_func(round(tmp.Data*double(intmax(compress_type))/tmp.maxData));
        else
          tmp.Data = compress_func(tmp.Data);
        end
      end
      
      if 0
        compressed_size = whos('Data');
        fprintf('Original size %d, Compressed sized %d\n', ...
          orig_size.bytes, compressed_size.bytes);
        figure(1); clf;
        imagesc([],tmp.Depth,double(tmp.Data));
        colormap(1-gray(256));
        pause;
      end
      
      [~,fn_name,fn_ext] = fileparts(fn);
      out_fn = [fullfile(out_dir,fn_name) fn_ext];
      out_fn_dir = fileparts(out_fn);
      if ~exist(out_fn_dir,'dir')
        mkdir(out_fn_dir);
      end
      fprintf('  Output %s\n', out_fn);
      tmp = rmfield(tmp,'Depth');
      save('-v7.3',out_fn,'-struct','tmp');
    end
  end
end
