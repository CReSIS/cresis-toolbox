% function status = block_data(param,param_override)
% status = block_data(param,param_override)
%
% param: Parameter structure from read_param_xls parameter spreadsheet
%
% param.block_data: Structure which controls the size of each block
%
%  .block_size: number of columns in each block
%
%  .block_overlap: the percentage of overlap between each block
%
%  .debug_plot:	Set to true for debug plots.
%
%  .detrend_debug:	Set to true for detrend debug plots.
%
%  .bottom_pad : number of rows after the deepest layer
%
%  .early_trunc:	Truncate data immediately after surface flattening
%  (before detrending and normalizing)
%
%  .echo_path:	Path to echogram data, typically an argument of
%  ct_filename_out function e.g 'CSARP\standard' =>
%  ct_filename_out(param,'CSARP\standard').
%
%  .late_trunc:	Truncate data after all data manipulation( i.e detrending
%  and normalizing ) is done.
%
%  .layer_params: opsLoadLayers.m structure describing which layers to load
%  and store in the block files
%
%  .layers_source:	This specifies where the layer data is loaded from(e.g
%  layerdata, records, lidar, etc). This forms a field of the layer_params
%  struct passed into opsLoadLayers. See runOpsLoadLayers.m
%
%  .layerdata_source:	When layers_source is layerdata, this string
%  specifies the layerdata (e.g layer_koenig, layer, post) to be loaded.
%  This field is also one of the fields of the layer_params struct passed
%  into opsLoadLayers. See runOpsLoadLayers.m
%
%  .out_fn:	Path where output blocks and files are saved. Currently, this
%  is passed as an argument to ct_filename_tmp to save the outputs in KU
%  user's scratch
%
%  .post_detrend_filter_en:	Enable/Disable filtering after detrending
%  (before normalization)
%
%  .pre_detrend_filter_en:	Enable/Disable filtering before detrending
%
%  .regexp:	When layers_source is layerdata, all the layers with layer
%  names that match this regular expression pattern are loaded. This field
%  is also one of the fields of the layer_params struct passed into
%  opsLoadLayers. See runOpsLoadLayers.m
%
%  .surf_param: opsLoadLayers.m structure describing which surface to load
%  and store in the preprocessing and in the block files
%
%  .surface_flat_en:	Enable/Disable surface flattening
%
%  .surface_rel_layers_flat_en:	Optional feature when surface filtering is
%  enabled. Enable this feature to flatten the layers relative to the
%  filtered surface.
%
%  .surface_filter_len:	Specifies the length of the filter for filtering
%  the surface
%
%  .top_gap: number of rows before the first layer
%
%  .uncompress_en:	Depending on the echogram data product used (e.g qlook,
%  post), the echogram may be compressed. This flag when true uncompresses
%  the compressed data using uncompress_echogram function prior to any
%  processing.
%
% Authors: Ibikunle ( Adapted from John Paden's koenig_mat_loader )
%
% See also: run_block_data.m, block_data.m, run_unblock_data.m,
% unblock_data.m

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

physical_constants;

%% Input Checks: cmd
% =========================================================================

% Remove frames that do not exist from param.cmd.frms list
frames = frames_load(param);
param.cmd.frms = frames_param_cmd_frms(param,frames);

records = records_load(param);
ref = records_reference_trajectory_load(param,records);
along_track = geodetic_to_along_track(ref.lat,ref.lon,ref.elev);

%% Input Checks: block_data
% =========================================================================

if ~isfield(param,'block_data') || isempty(param.block_data)
  param.block_data = [];
end

% block_data.block_along_track: scalar double, along-track length of each
% block in meters, default is 5000 m
if ~isfield(param.block_data,'block_along_track') || isempty(param.block_data.block_along_track)
  param.block_data.block_along_track = 5e3; % Use default block size
end

% block_data.block_Nx: scalar integer, number of columns in each output
% block, default is 256
if ~isfield(param.block_data,'block_Nx') || isempty(param.block_data.block_Nx)
  param.block_data.block_Nx = 256; % Use default block size
end

% block_data.block_overlap: scalar double, percentage overlap for each
% block, default is 0.5, valid range is 0 to 1
if ~isfield(param.block_data,'block_overlap') || isempty(param.block_data.block_overlap)
  param.block_data.block_overlap = 0.5;
end
param.block_data.block_overlap = min(1,param.block_data.block_overlap);
param.block_data.block_overlap = max(0,param.block_data.block_overlap);

% block_data.echo_img: scalar integer, image number, default is 0 (the
% combined image Data_YYYYMMDD_SS_FFF.mat).
if ~isfield(param.block_data,'echo_img') || isempty(param.block_data.echo_img)
  param.block_data.echo_img = 0; % Use default echo_img
end

% block_data.file: structure controlling file saving and which output files
% will be generated
if ~isfield(param.block_data,'file') || isempty(param.block_data.file)
  param.block_data.file = [];
end
if ~isfield(param.block_data.file,'img_en') || isempty(param.block_data.file.img_en)
  param.block_data.file.img_en = true;
end
if ~isfield(param.block_data.file,'layer_bin_en') || isempty(param.block_data.file.layer_bin_en)
  param.block_data.file.layer_bin_en = true;
end
if ~isfield(param.block_data.file,'layer_mult_en') || isempty(param.block_data.file.layer_mult_en)
  param.block_data.file.layer_mult_en = true;
end
if ~isfield(param.block_data.file,'layer_seg_en') || isempty(param.block_data.file.layer_seg_en)
  param.block_data.file.layer_seg_en = true;
end
if ~isfield(param.block_data.file,'mat_en') || isempty(param.block_data.file.mat_en)
  param.block_data.file.mat_en = true;
end

% block_data.flatten: structure controlling echo_flatten.m
if ~isfield(param.block_data,'flatten') || isempty(param.block_data.flatten)
  param.block_data.flatten = [];
end
if ~isfield(param.block_data.flatten,'resample_field') || isempty(param.block_data.flatten.resample_field)
  param.block_data.flatten.resample_field = [];
end
if ~isfield(param.block_data.flatten,'interp_method') || isempty(param.block_data.flatten.interp_method)
  param.block_data.flatten.interp_method = [];
end

% Incoherent decimation (inc_dec, inc_B_filter) input check
% Setting inc_dec = 0: returns coherent data
% Setting inc_dec = 1: returns power detected data with no decimation
% Setting inc_dec > 1: decimates at the rate specified by inc_dec
if ~isfield(param.block_data,'inc_dec') || isempty(param.block_data.inc_dec)
  param.block_data.inc_dec = 1;
end
if ~isfield(param.block_data,'inc_B_filter') || isempty(param.block_data.inc_B_filter)
  if param.block_data.inc_dec == 0 || param.block_data.inc_dec == 1
    param.block_data.inc_B_filter = 1;
  else
    param.block_data.inc_B_filter = hanning(2*param.block_data.inc_dec+1);
  end
end
if ~mod(length(param.block_data.inc_B_filter),2)
  error('param.block_data.inc_B_filter must be odd length.');
end
param.block_data.inc_B_filter = param.block_data.inc_B_filter(:).'; % Must be row vector
if abs(sum(param.block_data.inc_B_filter)-1) > 1e4*eps % Ensure filter weights sum to 1 to preserve radiometry
  param.block_data.inc_B_filter = param.block_data.inc_B_filter / sum(param.block_data.inc_B_filter);
end

% block_data.out_path: string specifying which output directory to put the
% block images in
if ~isfield(param.block_data,'out_path') || isempty(param.block_data.out_path)
  param.block_data.out_path = 'block_data';
end
out_fn_dir = ct_filename_out(param,param.block_data.out_path);

% block_data.rows: structure controlling truncation in row dimension
if ~isfield(param.block_data,'rows') || isempty(param.block_data.rows)
  param.block_data.rows = [];
end

% block_data.rows.t0_pad: integer controlling how many rows of the image
% will be preserved beyond the top layer. Default is inf which will
% preserve all available rows on the top of the image.
if ~isfield(param.block_data.rows,'t0_pad') || isempty(param.block_data.rows.t0_pad)
  param.block_data.rows.t0_pad = inf;
end

% block_data.rows.t1_pad: integer controlling how many rows of the image
% will be preserved below the bottom layer. Default is inf which will
% preserve all available rows on the bottom of the image.
if ~isfield(param.block_data.rows,'t1_pad') || isempty(param.block_data.rows.t1_pad)
  param.block_data.rows.t1_pad = inf;
end

%% Create blocks
% =========================================================================
dx = param.block_data.block_along_track*param.block_data.block_overlap;
X = param.block_data.block_along_track;
x0 = 0:dx:along_track(end)-X;
x1 = x0 + X;

%% Determine which blocks to create
% =========================================================================
block_mask = false(size(x0));
for frm = param.cmd.frms
  start_x = along_track(frames.frame_idxs(frm));
  if frm == length(frames.frame_idxs)
    stop_x = along_track(end);
  else
    stop_x = along_track(frames.frame_idxs(frm+1)-1);
  end
  for block_idx = 1:length(x0)
    if x0(block_idx) < stop_x && x1(block_idx) > start_x
      block_mask(block_idx) = true;
    end
  end
end
% Add additional frames to start and end to account for blocks that extend
% before the first desired frame and past the last desired frame
frm_list = [];
for block_idx = find(block_mask)
  for frm = 1:length(frames.frame_idxs)
    start_x = along_track(frames.frame_idxs(frm));
    if frm == length(frames.frame_idxs)
      stop_x = along_track(end);
    else
      stop_x = along_track(frames.frame_idxs(frm+1)-1);
    end
    if start_x < x1(block_idx) && stop_x > x0(block_idx)
      frm_list(end+1) = frm;
    end
  end
end
frm_list = unique(frm_list);

%% Load layers
% =========================================================================
ops_param = param;
ops_param.cmd.frms = frm_list;
[layers,layer_params] = opsLoadLayers(ops_param, param.block_data.layer_params);

%% Load surface layer
% =========================================================================
ops_param = param;
ops_param.cmd.frms = frm_list;
[surf,surf_param] = opsLoadLayers(ops_param, param.block_data.surf_param);

%% Block Loop
% =========================================================================
frm_mask = false(size(frames.frame_idxs));
echogram_fn_dir = ct_filename_out(param,param.block_data.echo_path);
mdata = {};
for block_idx = find(block_mask)
  
  %% Block: Frames to load
  % =========================================================================
  cat_data = [];
  for frm = 1:length(frames.frame_idxs)
    start_x = along_track(frames.frame_idxs(frm));
    if frm == length(frames.frame_idxs)
      stop_x = along_track(end);
    else
      stop_x = along_track(frames.frame_idxs(frm+1)-1);
    end
    if start_x < x1(block_idx) && stop_x > x0(block_idx)
      if ~frm_mask(frm)
        frm_mask(frm) = true;
        % Load frame into memory
        if param.block_data.echo_img == 0
          echogram_fn_name = sprintf('Data_%s_%03d.mat', param.day_seg, frm);
        else
          echogram_fn_name = sprintf('Data_img_%02d_%s_%03d.mat', param.block_data.echo_img, param.day_seg, frm);
        end
        echogram_fn = fullfile(echogram_fn_dir,echogram_fn_name);
        mdata{frm} = load_L1B(echogram_fn);
      end
      
      % Concatenate data
      cat_data = echo_concatenate(cat_data,mdata{frm});
      
    else
      if frm_mask(block_idx)
        frm_mask(frm) = false;
        % Remove frame from memory
        mdata{frm} = [];
      end
    end
  end
  Nx_original = length(cat_data.GPS_time);
  if ~isempty(param.block_data.surf_param)
    cat_data.Surface = interp_finite(interp1(surf.gps_time,surf.twtt,cat_data.GPS_time),0);
  end
  
  %% Block: Echogram layer flattening
  % =======================================================================
  if isfield(param.block_data,'flatten') && ~isempty(param.block_data.flatten)
    [cat_data.Data,resample_field] = echo_flatten(cat_data, ...
      param.block_data.flatten.resample_field, false, ...
      param.block_data.flatten.interp_method,[],true);
  end
  
  %% Block: Incoherent filtering
  % =======================================================================
  
  %  .inc_B_filter: double vector, FIR filter coefficients to apply before
  %    incoherent average decimation. If not defined or empty, then
  %    inc_B_filter is set to ones(1,inc_dec)/inc_dec.
  %  .inc_dec = integer scalar, number of incoherent averages to apply
  %    (also decimates by this number). If set to < 1, complex data are
  %    returned.  Setting to 1 causes the data to be power detected (i.e.
  %    become incoherent), but no averaging is done.
  param.block_data.inc_B_filter = ones(1,21)/21;
  param.block_data.inc_dec = 10;
  param.block_data.nan_dec_normalize_threshold = [];
  param.block_data.nan_dec = false;
  % Along-track incoherent filtering (multilooking) of data
  if param.block_data.nan_dec
    cat_data.Data = nan_fir_dec(abs(cat_data.Data).^2, param.block_data.inc_B_filter, ...
      param.block_data.inc_dec, [], [], [], [], param.block_data.nan_dec_normalize_threshold);
  else
    cat_data.Data = fir_dec(abs(cat_data.Data).^2, param.block_data.inc_B_filter, ...
      param.block_data.inc_dec);
  end
  % Account for filtering and decimation in remaining fields
  cat_data.GPS_time = fir_dec(cat_data.GPS_time, param.block_data.inc_B_filter, ...
    param.block_data.inc_dec);
  cat_data.Latitude = fir_dec(cat_data.Latitude, param.block_data.inc_B_filter, ...
    param.block_data.inc_dec);
  cat_data.Longitude = fir_dec(cat_data.Longitude, param.block_data.inc_B_filter, ...
    param.block_data.inc_dec);
  cat_data.Elevation = fir_dec(cat_data.Elevation, param.block_data.inc_B_filter, ...
    param.block_data.inc_dec);
  cat_data.Roll = fir_dec(cat_data.Roll, param.block_data.inc_B_filter, ...
    param.block_data.inc_dec);
  cat_data.Pitch = fir_dec(cat_data.Pitch, param.block_data.inc_B_filter, ...
    param.block_data.inc_dec);
  cat_data.Heading = fir_dec(cat_data.Heading, param.block_data.inc_B_filter, ...
    param.block_data.inc_dec);
  cat_data.Surface = fir_dec(cat_data.Surface, param.block_data.inc_B_filter, ...
    param.block_data.inc_dec);
  resample_field = fir_dec(resample_field, param.block_data.inc_B_filter, ...
    param.block_data.inc_dec);
  
  %% Block: Extract block
  % =======================================================================
  start_rec = find(along_track >= x0(block_idx),1);
  stop_rec = find(along_track <= x1(block_idx),1,'last');
  start_idx = find(cat_data.GPS_time >= records.gps_time(start_rec),1);
  stop_idx = find(cat_data.GPS_time <= records.gps_time(stop_rec),1,'last');
  
  dec_idxs = fir_dec(1:Nx_original, param.block_data.inc_B_filter, ...
    param.block_data.inc_dec);
  new_axis = linspace(dec_idxs(start_idx),dec_idxs(stop_idx),param.block_data.block_Nx);
  
  cat_data.Data = interp1(dec_idxs.',cat_data.Data.',new_axis.').';
  cat_data.Elevation = interp1(dec_idxs,cat_data.Elevation,new_axis);
  cat_data.GPS_time = interp1(dec_idxs,cat_data.GPS_time,new_axis);
  cat_data.Heading = interp1(dec_idxs,cat_data.Heading,new_axis);
  cat_data.Latitude = interp1(dec_idxs,cat_data.Latitude,new_axis);
  cat_data.Longitude = interp1(dec_idxs,cat_data.Longitude,new_axis);
  cat_data.Roll = interp1(dec_idxs,cat_data.Roll,new_axis);
  cat_data.Pitch = interp1(dec_idxs,cat_data.Pitch,new_axis);
  cat_data.Surface = interp1(dec_idxs,cat_data.Surface,new_axis);
  resample_field = interp1(dec_idxs.',resample_field.',new_axis).';
  
  %% Block: Extract surface
  % =======================================================================
  Nx = length(cat_data.GPS_time);
  if isempty(param.block_data.surf_param)
    surf_bin = interp1(cat_data.Time,1:length(cat_data.Time),cat_data.Surface);
  else
    % Loaded an update to the surface
    cat_data.Surface = interp_finite(interp1(surf.gps_time,surf.twtt,cat_data.GPS_time),0);
    twtt = interp1(surf.gps_time,surf.twtt,cat_data.GPS_time);
    surf_bin = zeros(size(twtt));
    if isfield(param.block_data,'flatten') && ~isempty(param.block_data.flatten)
      for rline = 1:Nx
        % time_flat: vector of twtt associated with each pixel for the
        % particular column
        time_flat = interp1(1:length(cat_data.Time),cat_data.Time,resample_field(:,rline),'linear','extrap');
        surf_bin(rline) = interp1(time_flat,1:length(time_flat),twtt(rline),'linear','extrap');
      end
    end
  end
  
  %% Block: Extract layers
  % =======================================================================
  layers_bin_bitmap = zeros(size(cat_data.Data),'uint8');
  layers_bitmap = zeros(size(cat_data.Data),'uint16');
  layers_segment_bitmap = zeros(size(cat_data.Data),'uint16');
  layers_vector = nan(length(layers),Nx);
  for idx = 1:length(layers)
    twtt = interp1(layers(idx).gps_time,layers(idx).twtt,cat_data.GPS_time);
    twtt_bin = zeros(size(twtt));
    if isfield(param.block_data,'flatten') && ~isempty(param.block_data.flatten)
      for rline = 1:Nx
        % time_flat: vector of twtt associated with each pixel for the
        % particular column
        time_flat = interp1(1:length(cat_data.Time),cat_data.Time,resample_field(:,rline),'linear','extrap');
        twtt_bin(rline) = interp1(time_flat,1:length(time_flat),twtt(rline),'linear','extrap');
      end
    else
      twtt_bin = interp1(cat_data.Time, 1:length(cat_data.Time), twtt);
    end
    twtt_bin = round(twtt_bin);
    
    Nt = size(cat_data.Data,1);
    good_idxs = find(isfinite(twtt_bin) & twtt_bin >= 1 & twtt_bin <= Nt);
    layers_bin_bitmap(twtt_bin(good_idxs) + Nt*(good_idxs-1)) = 1;
    layers_bitmap(twtt_bin(good_idxs) + Nt*(good_idxs-1)) = idx;
    for col = 1:Nx
      if isfinite(twtt_bin(col)) && twtt_bin(col) >= 1 && twtt_bin(col) <= Nt
        layers_segment_bitmap(twtt_bin(col):end,col) = idx;
      end
    end
    layers_vector(idx,good_idxs) = twtt_bin(good_idxs);
  end
  
  min_layer = interp_finite(min(layers_vector),0) - param.block_data.rows.t0_pad;
  max_layer = interp_finite(max(layers_vector),0) + param.block_data.rows.t1_pad;
  min_layer = min(min_layer);
  max_layer = max(max_layer);
  min_layer = min(Nt,max(1,min_layer));
  max_layer = min(Nt,max(1,max_layer));
  
  layers_bin_bitmap = layers_bin_bitmap(min_layer:max_layer,:);
  layers_bitmap = layers_bitmap(min_layer:max_layer,:);
  layers_segment_bitmap = layers_segment_bitmap(min_layer:max_layer,:);
  layers_vector = layers_vector - min_layer + 1;
  cat_data.Data = cat_data.Data(min_layer:max_layer,:);
  resample_field = resample_field(min_layer:max_layer,:);
  
  %% Block: Log scaling data
  % =======================================================================
  cat_data.Data = db(cat_data.Data);
  
  %% Block: Detrend
  % =======================================================================
  if isfield(param.block_data,'detrend') && ~isempty(param.block_data.detrend)
    param.block_data.detrend.layer_top = interp_finite(surf_bin,1);
    param.block_data.detrend.layer_bottom = nan(size(surf_bin));
    cat_data.Data = echo_detrend(cat_data,param.block_data.detrend);
  end
  
  %% Block: TBD (roll compensation, etc.)
  % =======================================================================
  
  %% Block: Normalization
  % =======================================================================
  if isfield(param.block_data,'norm') && ~isempty(param.block_data.norm)
    cat_data.Data = echo_norm(cat_data.Data,param.block_data.norm);
  end
  
  %% Block: Save
  % =======================================================================
  if ~exist(out_fn_dir,'dir')
    mkdir(out_fn_dir);
  end
  
  if param.block_data.file.img_en
    out_fn_name = sprintf('img_%s_%04d.png',param.day_seg,block_idx);
    out_fn = fullfile(out_fn_dir,out_fn_name);
    fprintf('%s\t%s\n', out_fn, datestr(now,'yyyymmdd_HHMMSS'));
    min_val = min(cat_data.Data(:));
    max_val = max(cat_data.Data(:));
    img_tmp = uint8((cat_data.Data-min_val)/(max_val-min_val)*255);
    imwrite(uint8(img_tmp), out_fn);
    clear img_tmp;
  end
  
  if param.block_data.file.layer_bin_en
    out_fn_name = sprintf('layer_bin_%s_%04d.png',param.day_seg,block_idx);
    out_fn = fullfile(out_fn_dir,out_fn_name);
    fprintf('%s\t%s\n', out_fn, datestr(now,'yyyymmdd_HHMMSS'));
    imwrite(uint8(layers_bin_bitmap), out_fn);
  end
  
  if param.block_data.file.layer_mult_en
    out_fn_name = sprintf('layer_mult_%s_%04d.png',param.day_seg,block_idx);
    out_fn = fullfile(out_fn_dir,out_fn_name);
    fprintf('%s\t%s\n', out_fn, datestr(now,'yyyymmdd_HHMMSS'));
    imwrite(uint8(layers_bitmap), out_fn);
  end
  
  if param.block_data.file.layer_seg_en
    out_fn_name = sprintf('layer_seg_%s_%04d.png',param.day_seg,block_idx);
    out_fn = fullfile(out_fn_dir,out_fn_name);
    fprintf('%s\t%s\n', out_fn, datestr(now,'yyyymmdd_HHMMSS'));
    imwrite(uint8(layers_segment_bitmap), out_fn);
  end
  
  if 0
    % Debug code to review images
    % =====================================================================
    out_fn_name = sprintf('img_%s_%04d.png',param.day_seg,block_idx);
    out_fn = fullfile(out_fn_dir,out_fn_name);
    fprintf('%s\t%s\n', out_fn, datestr(now,'yyyymmdd_HHMMSS'));
    img_test = imread(out_fn);
    imagesc(img_test);
    imshow(out_fn);
    
    out_fn_name = sprintf('layer_bin_%s_%04d.png',param.day_seg,block_idx);
    out_fn = fullfile(out_fn_dir,out_fn_name);
    fprintf('%s\t%s\n', out_fn, datestr(now,'yyyymmdd_HHMMSS'));
    img_test = imread(out_fn);
    imagesc(img_test);
    
    out_fn_name = sprintf('layer_mult_%s_%04d.png',param.day_seg,block_idx);
    out_fn = fullfile(out_fn_dir,out_fn_name);
    fprintf('%s\t%s\n', out_fn, datestr(now,'yyyymmdd_HHMMSS'));
    img_test = imread(out_fn);
    imagesc(img_test);
    
    out_fn_name = sprintf('layer_seg_%s_%04d.png',param.day_seg,block_idx);
    out_fn = fullfile(out_fn_dir,out_fn_name);
    fprintf('%s\t%s\n', out_fn, datestr(now,'yyyymmdd_HHMMSS'));
    img_test = imread(out_fn);
    imagesc(img_test);
  end
  
  if ~param.block_data.file.mat_en
    cat_data = rmfield(cat_data,'Data');
  end
  out_fn_name = sprintf('%s_%04d.mat',param.day_seg,block_idx);
  out_fn = fullfile(out_fn_dir,out_fn_name);
  cat_data.param_block_data = param;
  cat_data.layers_vector = layers_vector;
  fprintf('%s\t%s\n', out_fn, datestr(now,'yyyymmdd_HHMMSS'));
  ct_save(out_fn,'-struct','cat_data');
  
end
status = true;