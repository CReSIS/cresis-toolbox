%% Script compare_layers_2D
%
% Calculates error measurements between a reference layer dataset and a 
%  target layer dataset
%
% Authors: Victor Berger

dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s (%s)\n', dbstack_info(1).name, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'','post');
% params = ct_set_params(params,'cmd.generic',0);
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
% params = ct_set_params(params,'cmd.frms',[1]);

%% IMPORTANT VARIABLES
echo_name = 'CSARP_post/mvdr';

% Set to true to also receive results in which the 
%  no-ice coordinates are ignored (this is slow)
flag_ignore_icemask = false;

greenland_icemask = 'greenland/IceMask/GimpIceMask_90m_v1.1.tif';
caa_icemask = '/cresis/snfs1/dataproducts/GIS_data/canada/ice_mask/03_rgi50_ArcticCanadaNorth/03_rgi50_ArcticCanadaNorth.bin';

%% Set reference and target layers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REFERENCE LAYER
if 0
  % Load a single layer from OPS% big enough for 2000 frms of 4000 rbins
  layer_params(1).name = 'bottom';
  layer_params(1).source = 'ops';
  layer_params(1).echogram_source = 'CSARP_post/mvdr';
else
  % Load a single layer from the layerData file
  layer_params(1).name = 'bottom'; 
  layer_params(1).source = 'layerData';
  layer_params(1).layerdata_source = 'CSARP_post/layerData';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TARGET LAYER
if 0
  % Load a single layer from OPS
  layer_params(2).name = 'top';
  layer_params(2).source = 'ops';
  layer_params(2).echogram_source = 'CSARP_post/mvdr';  echo_data  = load(data_fn, 'GPS_time', 'Time', 'Latitude', 'Longitude');
      % Load icemask for desired frame
      [mask.x, mask.y] = projfwd(mask.proj, echo_data.Latitude, echo_data.Longitude);
      mask.X = mask.R(3,1) + mask.R(2,1)*(1:size(mask.maskmask,2));
      mask.Y = mask.R(3,2) + mask.R(1,2)*(1:size(mask.maskmask,1));
      [mask.X,mask.Y] = meshgrid(mask.X,mask.Y);
      mask.mask = round(interp2(mask.X, mask.Y, double(mask.maskmask), mask.x, mask.y));
      mask.mask(isnan(mask.mask)) = 1;
else
  % Load a single layer from the layerData file
  layer_params(2).name = 'bottom';
  layer_params(2).source = 'layerData';
  layer_params(2).layerdata_source = 'layerData';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Automated section
global gRadar;
overall_frm_ctr = 1;

% Make matrix bigger than needs to be
big_error_matrix = NaN * ones(2000, 4000);

if flag_ignore_icemask
  big_error_matrix_ignore_icemask = NaN * ones(2000, 4000);
end

for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  
  param = merge_structs(param,gRadar);

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
  
  frms        = param.cmd.frms;
  data_fn_dir = ct_filename_out(param, echo_name, '');
  ref_layers  = {};
  tar_layers  = {};
  ref_bins    = {};
  tar_bins    = {};
  echo_data   = {};
  
  if flag_ignore_icemask
    if strcmp(param.day_seg, '20140506_01') ||  strcmp(param.day_seg, '20140401_03')...
        || strcmp(param.day_seg, '20140325_05') || strcmp(param.day_seg, '20140325_07')
      icemask_fn = caa_icemask;
      [ice_mask_fn_dir ice_mask_fn_name] = fileparts(icemask_fn);
      ice_mask_mat_fn = fullfile(ice_mask_fn_dir,[ice_mask_fn_name '.mat']);
      mask = load(ice_mask_mat_fn,'R','X','Y','proj');
      [fid,msg] = fopen(icemask_fn,'r');
      if fid < 1
        fprintf('Could not open file %s\n', ice_mask_bin_fn);
        error(msg);
      end
      mask.maskmask = logical(fread(fid,[length(mask.Y),length(mask.X)],'uint8'));
      fclose(fid);
    else
      icemask_fn = greenland_icemask;
      icemask_fn = ct_filename_gis([], icemask_fn);
       [mask.maskmask,mask.R,~] = geotiffread(icemask_fn);
      mask.proj = geotiffinfo(icemask_fn);
    end
  end

  % Load reference and target layers for each frame
  for frm = frms
    param.cmd.frms = frm;
    data_fn_name = sprintf('Data_%s_%03d.mat',param.day_seg,frm);
    data_fn = fullfile(data_fn_dir, data_fn_name);
    
    % If ignoring no-ice RLINES
    if flag_ignore_icemask
      echo_data  = load(data_fn, 'GPS_time', 'Time', 'Latitude', 'Longitude');
      % Load icemask for desired frame
      [mask.x, mask.y] = projfwd(mask.proj, echo_data.Latitude, echo_data.Longitude);
      mask.X = mask.R(3,1) + mask.R(2,1)*(1:size(mask.maskmask,2));
      mask.Y = mask.R(3,2) + mask.R(1,2)*(1:size(mask.maskmask,1));
      [mask.X,mask.Y] = meshgrid(mask.X,mask.Y);
      mask.mask = round(interp2(mask.X, mask.Y, double(mask.maskmask), mask.x, mask.y));
      mask.mask(isnan(mask.mask)) = 1;
    else
      echo_data  = load(data_fn, 'GPS_time', 'Time');
    end

    try
      % Load layers
      ref_layers = opsLoadLayers(param,layer_params(1));
      tar_layers = opsLoadLayers(param,layer_params(2));
      
      % Convert reference and target TWTT to RBINS for each frame
      ref_bins = interp_finite(interp1(ref_layers.gps_time, ref_layers.twtt, echo_data.GPS_time));
      ref_bins = round(interp1(echo_data.Time, 1:length(echo_data.Time), ref_bins));
      tar_bins = interp_finite(interp1(tar_layers.gps_time, tar_layers.twtt, echo_data.GPS_time));
      tar_bins = round(interp1(echo_data.Time, 1:length(echo_data.Time), tar_bins));
      
      % Store error for each RLINE
      diff_measurement = abs(ref_bins - tar_bins);
      
      big_error_matrix(overall_frm_ctr, 1:length(ref_bins)) = abs(ref_bins - tar_bins);
      
      % Store error for each RLINE ignoring no-ice RLINES
      if flag_ignore_icemask
        dummy = big_error_matrix(overall_frm_ctr, 1:length(ref_bins));
        dummy(mask.mask < 1) = NaN;
        big_error_matrix_ignore_icemask(overall_frm_ctr, 1:length(ref_bins)) = dummy;
      end
      if 0
        fprintf('\n[%s_%03d]',param.day_seg,frm);
      end
    catch ME
      fprintf('\nProblem with frame %s_%03d.mat.',param.day_seg,frm);
      continue;
    end
    overall_frm_ctr = overall_frm_ctr + 1;
    
    if mod(overall_frm_ctr, 50) == 0
      fprintf('\nFrames processed: %d, mean so far: %f', overall_frm_ctr, nanmean(big_error_matrix(:)));
    end
    
  end
end

%% Print results
% Mean and median error
fprintf('\n ======');
fprintf('\nFor all frames, all range-lines: mean: %f   median: %f', ...
  nanmean(big_error_matrix(:)), nanmedian(big_error_matrix(:)));

% Accuracy calculation
result_matrix = big_error_matrix(:);
result_matrix = result_matrix(~isnan(big_error_matrix(:)));
acc_3 = length(find(result_matrix <= 3));
acc_5 = length(find(result_matrix <= 5));
acc_10 = length(find(result_matrix <= 10));

fprintf('\nPercentage of columns within 3 pixels of the ground-truth: %.2f',...
  (100 * acc_3 ./ length(result_matrix)));
fprintf('\nPercentage of columns within 5 pixels of the ground-truth: %.2f',...
  (100 * acc_5 ./ length(result_matrix)));
fprintf('\nPercentage of columns within 10 pixels of the ground-truth: %.2f',...
  (100 * acc_10 ./ length(result_matrix)));

%% Print results ignoring no-ice RLINES
if flag_ignore_icemask
  % Mean and median error
  fprintf('\n ======');
  fprintf('\nFor all frames, ignoring no-ice range-lines: mean: %f   median: %f', ...
    nanmean(big_error_matrix_ignore_icemask(:)), nanmedian(big_error_matrix_ignore_icemask(:)));
  % Accuracy calculation
  result_matrix = big_error_matrix_ignore_icemask(:);
  result_matrix = result_matrix(~isnan(big_error_matrix_ignore_icemask(:)));
  acc_3 = length(find(result_matrix <= 3));
  acc_5 = length(find(result_matrix <= 5));
  acc_10 = length(find(result_matrix <= 10));
  
  fprintf('\nPercentage of columns within 3 pixels of the ground-truth: %.2f',...
    (100 * acc_3 ./ length(result_matrix)));
  fprintf('\nPercentage of columns within 5 pixels of the ground-truth: %.2f',...
    (100 * acc_5 ./ length(result_matrix)));
  fprintf('\nPercentage of columns within 10 pixels of the ground-truth: %.2f',...
    (100 * acc_10 ./ length(result_matrix)));
end
