%% Script run_tracker_2D
%
% Runs the selected 2D tracking algorithms
%  on the desired dataset
%
% Authors: Victor Berger
%
% See also: viterbi_tracker_2D.m, mcmc_tracker_2D.m, lsm_tracker_2D.m

dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s (%s)\n', dbstack_info(1).name, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

%% General User Settings
% Tracking algorithms: 'viterbi', 'mcmc', 'lsm', 'stereo'
algorithms = {'viterbi'};

params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'','post');
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20140407_01');
params = ct_set_params(params,'cmd.frms',[2]);

options.name       = 'CSARP_post/mvdr';
options.debug      = true;
options.ops_write  = false;
options.save_img   = false;
options.save_add_f = false;

%% Image saving options
% Only effective if options.save_img == true
options.save_img_format = '-djpeg';
options.save_img_path   = '';

%% OPS/layerData writing options
% Only effective if options.ops_write == true

% Usually 'layerdata' or 'ops'
options.layer_dest_source = 'layerdata';

% If using 'layerdata':
options.layer_dest_layerdata_source = 'layerData_CP'; % layerData file will be saved in this location
options.layer_dest_echogram_source  = 'CSARP_post/mvdr';   % Only required if layerData files do not exist and need to be created

%% Additional file writing options
% Only effective if options.save_add_f == true
options.save_add_f_path = '';

%% Ice mask options
if 1 % If using GeoTIFF file for ice mask
  if strcmpi(param.post.ops.location,'arctic')
    if 1
      % Greenland
      options.binary_icemask = false;
      options.icemask_fn = 'greenland/IceMask/GimpIceMask_90m_v1.1.tif';
      options.icemask_fn = ct_filename_gis([], options.icemask_fn);
    else
      % Canada
      options.binary_icemask = true;
      options.icemask_fn = '/cresis/snfs1/dataproducts/GIS_data/canada/ice_mask/03_rgi50_ArcticCanadaNorth/03_rgi50_ArcticCanadaNorth.bin';
      [options.ice_mask_fn_dir,options.ice_mask_fn_name] = fileparts(options.icemask_fn);
      options.ice_mask_mat_fn = fullfile(options.ice_mask_fn_dir,[options.ice_mask_fn_name '.mat']);
  else
    % Useful for Antarctica seasons:
    options.icemask_fn = ct_filename_gis([], 'greenland/IceMask/GimpIceMask_90m_v1.1.tif');
  end

end

%% Viterbi User Settings
options.viterbi.crossoverload  = true;
options.viterbi.layername      = 'viterbi_bot';
options.viterbi.detrending     = true;
options.viterbi.top_sup        = false;
options.viterbi.mult_sup       = false;
options.viterbi.custom_combine = false;
options.viterbi.DIM_matrix     = fullfile('+tomo', 'Layer_tracking_2D_parameters_Matrix.mat');

options.viterbi.bottom_bin    = -1;
options.viterbi.egt_weight    = -1;
options.viterbi.mu_size       = 31;
options.viterbi.mu            = log10(exp(-(-(options.viterbi.mu_size-1)/2 : (options.viterbi.mu_size-1)/2).^4/1));
options.viterbi.mu_thr        = -30;
options.viterbi.mu(options.viterbi.mu < options.viterbi.mu_thr) = options.viterbi.mu_thr;
options.viterbi.mu            = options.viterbi.mu - mean(options.viterbi.mu);
options.viterbi.sigma         = sum(abs(options.viterbi.mu))/10*ones(1,options.viterbi.mu_size);
options.viterbi.smooth_var    = inf;
options.viterbi.repulsion     = 150000;
options.viterbi.smooth_weight = 1;
options.viterbi.ice_bin_thr   = 10;

%% MCMC User Settings
options.mcmc.lyrtop = 'mcmc_top';
options.mcmc.lyrbot = 'mcmc_bot';

%% LSM User Settings
options.lsm.lyrtop       = 'lsm_top';
options.lsm.lyrbot       = 'lsm_bot';
options.lsm.y            = 220; % = '' for y = mean(SURF)
options.lsm.dy           = 10;
options.lsm.numOuterIter = 350;
options.lsm.maxOuterIter = 50;

%% Stereo User Settings
options.stereo.lyrtop        = 'stereo_top';
options.stereo.lyrbot        = 'stereo_bot';
options.stereo.surfaceload   = true;
options.stereo.crossoverload = true;
options.stereo.top_smooth    = 1000;
options.stereo.bottom_smooth = 1000;
options.stereo.top_peak      = 0.5;
options.stereo.bottom_peak   = 0.5;
options.stereo.repulsion     = 10;

%% Automated section
global gRadar;

% Load all frames of each segment at a time for the Viterbi algorithm
if any(strcmp(algorithms, 'viterbi'))
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
    data_fn_dir = ct_filename_out(param, options.name, '');
    for frm = param.cmd.frms
      data_fn_name = sprintf('Data_%s_%03d.mat',param.day_seg,frm);
      data_fn      = fullfile(data_fn_dir, data_fn_name);
      options.viterbi.data_fn = data_fn;
      try
        data_struct.(sprintf('data_%s_%03d',param.day_seg,frm)) = load(data_fn);
      catch ME
        fprintf('\nFailed to load file %s, skipping.\n', data_fn);
        continue;
      end
    end
    tomo.viterbi_tracker_2D(param, options, data_struct);
  end
end

% Load one frame at a time for the MCMC, LSM, and Stereo algorithms
if any(strcmp(algorithms, 'mcmc')) || any(strcmp(algorithms, 'lsm')) ...
    || any(strcmp(algorithms, 'stereo'))
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
    data_fn_dir = ct_filename_out(param, options.name, '');
    for frm = param.cmd.frms
      data_fn_name = sprintf('Data_%s_%03d.mat',param.day_seg,frm);
      data_fn      = fullfile(data_fn_dir, data_fn_name);
      try
        data = load(data_fn);
        data.frm = frm;
      catch ME
        fprintf('\nFailed to load file %s, skipping.\n', data_fn);
        continue;
      end
      if any(strcmp(algorithms, 'mcmc'))
        tomo.mcmc_tracker_2D(param, options, data);
      end
      if any(strcmp(algorithms, 'lsm'))
        tomo.lsm_tracker_2D(param, options, data);
      end
      if any(strcmp(algorithms, 'stereo'))
        tomo.stereo_tracker_2D(param, options, data);
      end
    end
  end
end

fprintf('\n\nAll done. (%s)\n\n',datestr(now,'dd-mmm-yyyy HH:MM:SS'));