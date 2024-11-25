% function echogram_to_jpeg(param,param_override)
% echogram_to_jpeg(param,param_override)
%
% Converts specified echogram image .mat files into small 8-bit jpegs after
% truncation and decimation.
%
% param = struct with processing parameters
% param_override = parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% Example:
%  See run_echogram_to_jpeg.m for how to run this function directly.
%  Normally this function is called from master.m using the param spreadsheet.
%
% Authors: John Paden
%
% See also: run_post.m, post.m, run_echogram_to_jpeg.m,
%  echogram_to_jpeg.m

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input Checks
% =====================================================================

if ~isfield(param,'echogram_to_jpeg') || isempty(param.echogram_to_jpeg)
  param.echogram_to_jpeg = [];
end

if ~isfield(param.echogram_to_jpeg,'data_type') || isempty(param.echogram_to_jpeg.data_type)
  param.echogram_to_jpeg.data_type = 'standard';
end
data_type = param.echogram_to_jpeg.data_type;

if ~isfield(param.echogram_to_jpeg,'data_img') || isempty(param.echogram_to_jpeg.data_img)
  % Combined image Data_YYYYMMDD_SS_FFF is default (as opposed to Data_img_II_YYYYMMDD_SS_FFF)
  param.echogram_to_jpeg.data_img = 0;
end
data_img = param.echogram_to_jpeg.data_img;

if ~isfield(param.echogram_to_jpeg, 'layers') || isempty(param.echogram_to_jpeg.layers)
  param.echogram_to_jpeg.layers = [struct('name', 'surface', 'source', 'layerData', 'existence_check', false) ...
    struct('name', 'bottom', 'source', 'layerData', 'existence_check', false)];
end

if ~isfield(param.echogram_to_jpeg,'N_before_surface') || isempty(param.echogram_to_jpeg.N_before_surface)
  param.echogram_to_jpeg.N_before_surface = 50;
end
N_before_surface = param.echogram_to_jpeg.N_before_surface;

if ~isfield(param.echogram_to_jpeg,'N_after_surface') || isempty(param.echogram_to_jpeg.N_after_surface)
  param.echogram_to_jpeg.N_after_surface = 1500;
end
N_after_surface = param.echogram_to_jpeg.N_after_surface;

if ~isfield(param.echogram_to_jpeg,'N_after_bottom') || isempty(param.echogram_to_jpeg.N_after_bottom)
  param.echogram_to_jpeg.N_after_bottom = 100;
end
N_after_bottom = param.echogram_to_jpeg.N_after_bottom;

if ~isfield(param.echogram_to_jpeg,'decimate_fasttime') || isempty(param.echogram_to_jpeg.decimate_fasttime)
  param.echogram_to_jpeg.decimate_fasttime = 2;
end
decimate_fasttime = param.echogram_to_jpeg.decimate_fasttime;

if ~isfield(param.echogram_to_jpeg,'decimate_slowtime') || isempty(param.echogram_to_jpeg.decimate_slowtime)
  param.echogram_to_jpeg.decimate_slowtime = 3;
end
decimate_slowtime = param.echogram_to_jpeg.decimate_slowtime;

if ~isfield(param.echogram_to_jpeg,'mat_out_path') || isempty(param.echogram_to_jpeg.mat_out_path)
  param.echogram_to_jpeg.mat_out_path = 'small_mat';
end
mat_out_path = param.echogram_to_jpeg.mat_out_path;

if ~isfield(param.echogram_to_jpeg,'jpeg_out_path') || isempty(param.echogram_to_jpeg.jpeg_out_path)
  param.echogram_to_jpeg.jpeg_out_path = 'small_jpg';
end
jpeg_out_path = param.echogram_to_jpeg.jpeg_out_path;

if ~isfield(param.post,'ops') || isempty(param.post.ops)
  param.post.ops = [];
end
if ~isfield(param.post.ops,'gaps_dist') || isempty(param.post.ops.gaps_dist)
  param.post.ops.gaps_dist = [300 60];
end

% Remove frames that do not exist from param.cmd.frms list
frames = frames_load(param);
if isempty(param.cmd.frms)
  param.cmd.frms = 1:length(frames.frame_idxs);
end
[valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
if length(valid_frms) ~= length(param.cmd.frms)
  bad_mask = ones(size(param.cmd.frms));
  bad_mask(keep_idxs) = 0;
  warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
    param.cmd.frms(find(bad_mask,1)));
  param.cmd.frms = valid_frms;
end

%% Convert .mat echograms to .jpg
% =====================================================================

layers = opsLoadLayers(param, param.echogram_to_jpeg.layers);
layers_cell = {};
for layer = layers
  layers_cell{end + 1} = layer;
end
clear layers;

mat_out_fn_dir = ct_filename_out(param,mat_out_path);
jpeg_out_fn_dir = ct_filename_out(param,jpeg_out_path);

for frm_idx = 1:length(param.cmd.frms)
  frm = param.cmd.frms(frm_idx);
  fprintf('%s_%03d\n', param.day_seg, frm);

  % Parse filename
  if data_img == 0
    echo_fn = fullfile(ct_filename_out(param,data_type,''), ...
      sprintf('Data_%s_%03d.mat', param.day_seg, frm));
  else
    echo_fn = fullfile(ct_filename_out(param,data_type,''), ...
      sprintf('Data_img_%02d_%s_%03d.mat', data_img, param.day_seg, frm));
  end
  
  % Load echogram file
  mdata = load_L1B(echo_fn);
  
  % Interpolate layer surface to echogram
  lay = opsInterpLayersToMasterGPSTime(mdata,layers_cell,param.post.ops.gaps_dist);
  if isempty(lay.layerData)
    lay.layerData{1}.value{2}.data = nan(size(lay.GPS_time));
  end
  if length(lay.layerData) == 1
    lay.layerData{2} = lay.layerData{1};
  end
  
  % Convert from twtt to bins
  surf = interp1(mdata.Time,1:length(mdata.Time),lay.layerData{1}.value{2}.data);
  bottom = interp1(mdata.Time,1:length(mdata.Time),lay.layerData{2}.value{2}.data);
  
  if 0
    % Image for debugging
    figure(1); clf;
    imagesc(lp(mdata.Data));
    hold on;
    plot(surf);
    plot(bottom);
  end
  
  % Find first good bin and last good bin based on surface/bottom layers
  first_bin = round(max(1,nanmin(surf)-N_before_surface));
  last_bin = round(min(size(mdata.Data,1),nanmax([nanmax(surf)+N_after_surface nanmax(bottom)+N_after_bottom])));
  
  % Scale data to uint8 and filter
  data = 10*log10(mdata.Data(first_bin:last_bin,:));
  data = fir_dec(data,decimate_slowtime);
  data = fir_dec(data.',decimate_fasttime).';
  min_data = min(data(:));
  max_data = max(data(:));
  data = uint8(255*(data-min_data)/(max_data-min_data));
  
  % Create output metadata
  out = [];
  out.Data_Scale = max_data-min_data;
  out.Data_Offset = min_data;
  out.Time = mdata.Time(first_bin:last_bin); out.Time = out.Time(1:decimate_fasttime:end);
  out.GPS_time = fir_dec(mdata.GPS_time,decimate_slowtime);
  out.Latitude = fir_dec(mdata.Latitude,decimate_slowtime);
  out.Longitude = fir_dec(mdata.Longitude,decimate_slowtime);
  surf = (fir_dec(surf,decimate_slowtime) - first_bin+1)/2;
  bottom = (fir_dec(bottom,decimate_slowtime) - first_bin+1)/2;
  out.Surface = surf;
  out.Bottom = bottom;
  
  if 0
    % Image for debugging
    figure(1); clf;
    imagesc(data);
    colormap(gray(256));
    hold on;
    plot(surf);
    plot(bottom);
    drawnow
  end
  
  % Save small metadata in mat file
  if ~exist(mat_out_fn_dir,'dir')
    mkdir(mat_out_fn_dir);
  end
  out_fn = fullfile(mat_out_fn_dir,sprintf('Data_%s_%03d.mat',param.day_seg,frm));
  fprintf('  Saving %s (%s)\n',out_fn,datestr(now));
  save(out_fn,'-v7.3','-struct','out');
  
  % Save small image in jpg file
  if ~exist(jpeg_out_fn_dir,'dir')
    mkdir(jpeg_out_fn_dir);
  end
  out_fn = fullfile(jpeg_out_fn_dir,sprintf('Data_%s_%03d.jpg',param.day_seg,frm));
  fprintf('  Saving %s (%s)\n',out_fn,datestr(now));
  imwrite(data,out_fn);
end
