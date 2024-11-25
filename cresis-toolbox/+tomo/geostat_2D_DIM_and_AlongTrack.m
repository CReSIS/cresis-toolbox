% Geostatistical Analsysis - 2D data
% Acquire geostatistics from ground-truth 2D layer data
%   Along-track transition model and distance-to-ice-margin distributions
%
% Author: Victor Berger
%
% See also: geostat_3D_AlongTrack.m, geostat_3D_CrossTrack.m, geostat_3D_DIM.m

dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s (%s)\n', dbstack_info(1).name, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'','post');
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
params = ct_set_params(params,'cmd.frms',[1]);

options.name = 'CSARP_post/mvdr';
maxdist = 5e3;
distanceMAP{maxdist} = [];
along_track_diff_vector = nan * ones(800, 3500);

%% Automated section
global gRadar;
frm_ctr = 1;

%% ICEMASK - CAA
param.radar_name = 'rds';
param.season_name = '2014_Greenland_P3';
ice_mask_fn = ct_filename_gis(param,fullfile('canada','ice_mask','03_rgi50_ArcticCanadaNorth','03_rgi50_ArcticCanadaNorth.bin'));
[ice_mask_fn_dir, ice_mask_fn_name] = fileparts(ice_mask_fn);
ice_mask_mat_fn = fullfile(ice_mask_fn_dir,[ice_mask_fn_name '.mat']);
ice_mask = load(ice_mask_mat_fn);
ice_mask.distmatrix = round(bwdist(ice_mask.mask == 0));
caa = ice_mask;

%% ICEMASK - Non-CAA
icemask_fn = 'greenland/IceMask/GimpIceMask_90m_v1.1.tif';
icemask_fn = ct_filename_gis([], icemask_fn);
[mask.maskmask,mask.R,~] = geotiffread(icemask_fn);
mask.proj = geotiffinfo(icemask_fn);
not_caa = mask;
not_caa.distmatrix = round(bwdist(not_caa.maskmask == 0));

for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  % Load frames file
  frames = frames_load(param);
  if isempty(param.cmd.frms)
    param.cmd.frms = 1:length(frames.frame_idxs);
  end
  % Remove frames that do not exist from param.cmd.frms list
  [valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
  if length(valid_frms) ~= length(param.cmd.frms)
    bad_mask = ones(size(param.cmd.frms));
    bad_mask(keep_idxs) = 0;
    warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
      param.cmd.frms(find(bad_mask,1)));
    param.cmd.frms = valid_frms;
  end
  
  if strcmp(param.day_seg, '20140506_01') ||  strcmp(param.day_seg, '20140401_03')...
        || strcmp(param.day_seg, '20140325_05') || strcmp(param.day_seg, '20140325_07')
      is_caa = true;
  else
    is_caa = false;
  end

  fprintf('\nData_%s',param.day_seg);
  
  data_fn_dir = ct_filename_out(param, options.name, '');
  for frm = param.cmd.frms
    fprintf('\n %03d (%s)',frm,datestr(now,'HH:MM:SS'));
    
    data_fn_name = sprintf('Data_%s_%03d.mat',param.day_seg,frm);
    data_fn      = fullfile(data_fn_dir, data_fn_name);
    
    try
      data = load(data_fn, 'GPS_time', 'Time', 'Latitude', 'Longitude');
      if is_caa
        [x,y] = projfwd(ice_mask.proj,data.Latitude,data.Longitude);
        frame_dist = round(interp2(ice_mask.X,ice_mask.Y,ice_mask.distmatrix,x,y));
      else
        not_caa.X = not_caa.R(3,1) + not_caa.R(2,1)*(1:size(not_caa.maskmask,2));
        not_caa.Y = not_caa.R(3,2) + not_caa.R(1,2)*(1:size(not_caa.maskmask,1));
        [not_caa.X,not_caa.Y] = meshgrid(not_caa.X,not_caa.Y);
        [x,y] = projfwd(not_caa.proj,data.Latitude,data.Longitude);
        frame_dist = round(interp2(not_caa.X,not_caa.Y,not_caa.distmatrix,x,y));
      end
    catch ME
      fprintf('\nProblem with frame %s.',data_fn_name);
      continue;
    end
    
    try
      layer_params(1).name = 'surface';
      layer_params(1).source = 'layerData';
      layer_params(1).layerdata_source = 'CSARP_post/layerData';
      surf_layer = opsLoadLayers(param,layer_params(1));
      surf_bins  = interp_finite(interp1(surf_layer.gps_time, surf_layer.twtt, data.GPS_time));
      surf_bins = round(interp1(data.Time, 1:length(data.Time), surf_bins));
      layer_params(2).name = 'bottom';
      layer_params(2).source = 'layerData';
      layer_params(2).layerdata_source = 'CSARP_post/layerData';
      bot_layer = opsLoadLayers(param,layer_params(2));
      bot_bins  = interp_finite(interp1(bot_layer.gps_time, bot_layer.twtt, data.GPS_time));
      bot_bins = round(interp1(data.Time, 1:length(data.Time), bot_bins));
    catch ME
      fprintf('\nProblem with frame %s.',data_fn_name);
      continue;
    end
      
    for rline = 1:length(data.Latitude)
      % Thickness calculation
      thick = round(bot_bins(rline) - surf_bins(rline));
      % Add thickness to the corresponding DIM matrix entry
      if thick > 0 && frame_dist(rline) > 0
        distanceMAP{frame_dist(rline)} = [distanceMAP{frame_dist(rline)}, thick];
      end
      % Along-track calculation
      along_track_diff_vector(frm_ctr, 1:length(bot_bins)-1) = abs(diff(bot_bins));
    end
  end
  
  fprintf('\n')
end
