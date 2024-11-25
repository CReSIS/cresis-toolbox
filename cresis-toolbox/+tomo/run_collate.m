% script tomo.run_collate
%
% Description: Run script for tomo.collate
%
% See also: tomo.run_collate, tomo.collate, tomo_collate_task,
%   tomo.fuse_images, tomo.add_icemask_surfacedem, tomo.create_surfData
%
% Author: John Paden, Jordan Sprick, Mingze Xu, and Victor Berger

%% User Setup
% =====================================================================
param_override = [];

% example_setup = 'horizontal';
% example_setup = 'vertical';
example_setup = 'grid';

tomo_collate = [];
if strcmpi(example_setup,'vertical')
  %% Vertical multiwaveform fuse example
  params = read_param_xls(ct_filename_param('rds_param_2011_Greenland_P3.xls'),'','post');
  params = ct_set_params(params,'cmd.generic',0);
  params = ct_set_params(params,'cmd.generic',1,'day_seg','20110413_01');
%   params = ct_set_params(params,'cmd.generic',1,'day_seg','20091224_01|20091228|20091229|20100101_02|20100103|20100104_01|20100112');
  params = ct_set_params(params,'cmd.frms',[]);
  
  % .in_path: ct_filename_out directory to use at input, fused image will be stored here.
  tomo_collate.in_path = 'test_music3D';
  
  % .surf_out_path: ct_filename_out directory to use at output for surfdata
  tomo_collate.surf_out_path = 'surf';

  % .imgs: list of images II to use from .in_path (Data_img_II*.mat). These
  %   should be listed from left most beam to right most beam for
  %   horizontal fusing and top to bottom for vertical fusing.
  tomo_collate.imgs = {1,2};
  
  % .img_comb: Same as get_heights and combine worksheets. This is
  %   used for vertical using only. For N images,
  %   there will be (N-1) combines performed. Each combine is described by
  %   three numbers so that there should be (N-1)*3 elements in this
  %   vector. Each set of three numbers indicates the following:
  %     1st element: Minimum time to begin combine
  %     2nd element: Minimum time after ice surface to begin combine
  %     3rd element: Time at end of the preceeding waveform to not use
  tomo_collate.img_comb = [9e-6 -inf 1e-6];
  
  % .fuse_columns: aligns with .imgs, each entry should contain 2xN-1
  % entries where N is the length of the corresponding cell in .imgs. Each
  % column of 2 numbers represents the start/stop columns to blend with.
  % There should be one column per interface between two images that needs
  % to be blended in the horizontal dimension. E.g. If blending 3 images in
  % the horizontal dimension, the entry should be 2x2. If blending 2
  % images, the entry should be 2x1. If there is only one image for a
  % particular vertical index, then fuse_columns should be empty.
  tomo_collate.fuse_columns = {[],[]};
  
  % .sv_cal_fn: filename containing steering vector calibration, leave empty to not use
  tomo_collate.sv_cal_fn = '';
  
  % .ice_mask_fn: filename of ice mask, leave empty to not use
  tomo_collate.ice_mask_fn = ct_filename_gis(param,fullfile('greenland','IceMask','GimpIceMask_90m_v1.1.bin'));%'antarctica\DEM\BEDMAP2\original_data\bedmap2_tiff\bedmap2_icemask_grounded_and_shelves.tif';

  % .dem_guard: additional region in meters around flight line to search for DEM points
  %   Setting too high slows the process down, setting too low will miss
  %   DEM points needed to properly represent the surface.
  tomo_collate.dem_guard = 12e3;
  
  % .dem_per_slice_guard: additional region in meters around each slice to search for DEM points
  %   Setting too high slows the process down, setting too low will miss
  %   DEM points needed to properly represent the surface.
  tomo_collate.dem_per_slice_guard = 240;
  
  % .ground_based_flag: logical default is false, if true data are treated
  % as ground based and surface twtt and ice_mask are set to zero and one
  % for all pixels respectively.
  tomo_collate.ground_based_flag = false;
  
  % .bounds_relative: DOA bins and along-track slices to trim off from each edge [top bottom left right]
  tomo_collate.bounds_relative = [3 2 0 0];
  
  % .layer_params: parameter structure for opsLoadLayer (first layer should
  %   be ice top and second layer should be ice bottom)
  tomo_collate.layer_params = struct('name','surface','source','layerdata');
  tomo_collate.layer_params(2).name = 'bottom';
  tomo_collate.layer_params(2).source = 'layerdata';
  
  % surfData_mode: surfData mode ('overwrite','fillgaps', or 'append', note that append with the
  %   same surface name as an existing surface will overwrite that surface whereas fillgaps
  %   will leave the surface untouched if it already exists)
  tomo_collate.surfData_mode = 'append';
  
  % surfdata_cmds: surfdata commands to run
  tomo_collate.surfdata_cmds = [];
  tomo_collate.surfdata_cmds(end+1).cmd = 'trws';
  tomo_collate.surfdata_cmds(end).surf_names = {'bottom trws','bottom'};
  tomo_collate.surfdata_cmds(end).visible = true;
  
  % .fuse_images_flag: runs fuse_images.m when true
  tomo_collate.fuse_images_flag = true;
  
  % .add_icemask_surfacedem_flag: runs add_icemask_surfacedem.m when true
  tomo_collate.add_icemask_surfacedem_flag = true;
  
  % create_surfData_flag: runs create_surfData.m when true
  tomo_collate.create_surfData_flag = true;
  
  param_override.tomo_collate = tomo_collate;

elseif strcmpi(example_setup,'horizontal')
  %% Horizontal multibeam fuse example
  params = read_param_xls(ct_filename_param('rds_param_2011_Greenland_P3.xls'),'','post');
  params = ct_set_params(params,'cmd.generic',0);
%   params = ct_set_params(params,'cmd.generic',1,'day_seg','20140325_05|20140325_06|20140325_07|20140401_03|20140506_01');
  params = ct_set_params(params,'cmd.generic',1,'day_seg','20110413_01');
  params = ct_set_params(params,'cmd.frms',[]);

  % .in_path: ct_filename_out directory to use at input, fused image will be stored here.
  tomo_collate.in_path = 'test_music3D';
  
  % .surf_out_path: ct_filename_out directory to use at output for surfdata
  tomo_collate.surf_out_path = 'surf';

  % .imgs: list of images II to use from .in_path (Data_img_II*.mat). These
  %   should be listed from left most beam to right most beam for
  %   horizontal fusing and top to bottom for vertical fusing.
  tomo_collate.imgs = {[1 2 3]};
  
  % .img_comb: Same as get_heights and combine worksheets. This is
  %   used for vertical using only. For N images,
  %   there will be (N-1) combines performed. Each combine is described by
  %   three numbers so that there should be (N-1)*3 elements in this
  %   vector. Each set of three numbers indicates the following:
  %     1st element: Minimum time to begin combine
  %     2nd element: Minimum time after ice surface to begin combine
  %     3rd element: Time at end of the preceeding waveform to not use
  tomo_collate.img_comb = [];
  
  % .fuse_columns: aligns with .imgs, each entry should contain 2xN-1
  % entries where N is the length of the corresponding cell in .imgs. Each
  % column of 2 numbers represents the start/stop columns to blend with.
  % There should be one column per interface between two images that needs
  % to be blended in the horizontal dimension. E.g. If blending 3 images in
  % the horizontal dimension, the entry should be 2x2. If blending 2
  % images, the entry should be 2x1. If there is only one image for a
  % particular vertical index, then fuse_columns should be empty.
  tomo_collate.fuse_columns = {[[22 28].' [38 44].']};
  
  % .sv_cal_fn: filename containing steering vector calibration, leave empty to not use
  tomo_collate.sv_cal_fn = ct_filename_ct_tmp(rmfield(params(1),'day_seg'),'','sv_calibration','theta_cal.mat');
  
  % .ice_mask_fn: filename of ice mask, leave empty to not use
  tomo_collate.ice_mask_fn = ct_filename_gis([],'canada/ice_mask/03_rgi50_ArcticCanadaNorth/03_rgi50_ArcticCanadaNorth.mat');
  
  % .ocean_mask_fn: filename of ocean mask
  tomo_collate.ocean_mask_fn = ct_filename_gis([],fullfile('world','land_mask','Land_Mask_IDL_jharbeck','GSHHS_f_L1.shp'));

  % .dem_guard: additional region in meters around flight line to search for DEM points
  %   Setting too high slows the process down, setting too low will miss
  %   DEM points needed to properly represent the surface.
  tomo_collate.dem_guard = 12e3;
  
  % .dem_per_slice_guard: additional region in meters around each slice to search for DEM points
  %   Setting too high slows the process down, setting too low will miss
  %   DEM points needed to properly represent the surface.
  tomo_collate.dem_per_slice_guard = 240;
  
  % .ground_based_flag: logical default is false, if true data are treated
  % as ground based and surface twtt and ice_mask are set to zero and one
  % for all pixels respectively.
  tomo_collate.ground_based_flag = false;
  
  % .bounds_relative: DOA bins and along-track slices to trim off from each edge [top bottom left right]
  tomo_collate.bounds_relative = [3 2 0 0];

  % .layer_params: parameter structure for opsLoadLayer (first layer should
  %   be ice top and second layer should be ice bottom)
  tomo_collate.layer_params = struct('name','surface','source','layerdata');
  tomo_collate.layer_params(2).name = 'bottom';
  tomo_collate.layer_params(2).source = 'layerdata';

  % surfData_mode: surfData mode ('overwrite','fillgaps', or 'append', note that append with the
  %   same surface name as an existing surface will overwrite that surface whereas fillgaps
  %   will leave the surface untouched if it already exists)
  tomo_collate.surfData_mode = 'append';
  
  % surfdata_cmds: surfdata commands to run
  tomo_collate.surfdata_cmds = [];
  
  % Detect (old Viterbi algorithm)
  %   tomo_collate.surfdata_cmds(end+1).cmd = 'detect';
  %   tomo_collate.surfdata_cmds(end).surf_names = 'bottom detect';
  %   tomo_collate.surfdata_cmds(end).visible = false;
  %   tomo_collate.surfdata_cmds(end).data_threshold = 13.5;
  
  % Extract (old TRW-S algorithm)
  %   tomo_collate.surfdata_cmds(end+1).cmd = 'extract';
  %   tomo_collate.surfdata_cmds(end).surf_names = 'bottom extract';
  %   tomo_collate.surfdata_cmds(end).visible = false;
  %   tomo_collate.surfdata_cmds(end).data_threshold = 13.5;
  
  % Viterbi
  %   tomo_collate.surfdata_cmds(end+1).cmd = 'viterbi';
  %   tomo_collate.surfdata_cmds(end).surf_names = 'bottom viterbi';
  %   tomo_collate.surfdata_cmds(end).visible = false;
  %   tomo_collate.surfdata_cmds(end).smooth_weight = 55; % schu
  %   tomo_collate.surfdata_cmds(end).smooth_var = -1; 
  %   tomo_collate.surfdata_cmds(end).repulsion = 150; % schu
  %   tomo_collate.surfdata_cmds(end).egt_weight = 10; 
  %   tomo_collate.surfdata_cmds(end).ice_bin_thr = 3;
  
  % TRW-S (Tree Reweighted Sequential algorithm)
    tomo_collate.surfdata_cmds(end+1).cmd = 'trws';
    tomo_collate.surfdata_cmds(end).surf_names = {'bottom trws','bottom'};
    tomo_collate.surfdata_cmds(end).visible = true;
    tomo_collate.surfdata_cmds(end).smooth_weight = [22 22];
    tomo_collate.surfdata_cmds(end).smooth_var = 32;
    tomo_collate.surfdata_cmds(end).max_loops = 50;
  
  % C3D/RNN (3D convolutional and recurrent neural network)
  tomo_collate.surfdata_cmds(end+1).cmd = 'c3d_rnn';
  tomo_collate.surfdata_cmds(end).surf_names = {'c3d_rnn_surface', 'c3d_rnn_bottom'};
  tomo_collate.surfdata_cmds(end).visible = true;  
  tomo_collate.surfdata_cmds(end).surface_threshold = true;
  
  % DEM (Digital Elevation Model)
  %   tomo_collate.surfdata_cmds(end+1).cmd = 'dem';
  %   tomo_collate.surfdata_cmds(end).surf_names = 'bottom dem';
  %   tomo_collate.surfdata_cmds(end).visible = false;
  %   tomo_collate.surfdata_cmds(end).plot_name_values = {'color','red','marker','^'};
  %   tomo_collate.surfdata_cmds(end).dem_fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_DEM_nofilt/20140401_03/20140401_03_007_bottom.tif';
  %   tomo_collate.surfdata_cmds(end).dem_bad_value = -32767;
  
  % .fuse_images_flag: runs fuse_images.m when true
  tomo_collate.fuse_images_flag = true;
  
  % .add_icemask_surfacedem_flag: runs add_icemask_surfacedem.m when true
  tomo_collate.add_icemask_surfacedem_flag = false;
  
  % create_surfData_flag: runs create_surfData.m when true
  tomo_collate.create_surfData_flag = false;

  param_override.tomo_collate = tomo_collate;
  
elseif strcmpi(example_setup,'grid')
  %% Grid multiwaveform fuse example
%   params = read_param_xls(ct_filename_param('rds_param_2011_Greenland_P3.xls'),'','post');
%   params = read_param_xls(ct_filename_param('rds_param_2018_Greenland_Polar6_paden.xls'));
  params = read_param_xls(ct_filename_param('rds_param_2018_Greenland_P3.xls'));
  
  cmd_method = 'array';
  param_override.array.out_path = 'music3D';
  rds_settings;
  
  params = ct_set_params(params,'cmd.generic',0);
  params = ct_set_params(params,'cmd.generic',1,'day_seg','20180406_01');
  params = ct_set_params(params,'cmd.frms',[1 2]);

% 
% %   params = ct_set_params(params,'array.imgs',{[ones(15,1) (2:16)'],[2*ones(15,1) (2:16)']});
%   params = ct_set_params(params,'array.imgs',{[ones(7,1) (2:8)'],[2*ones(7,1) (2:8)']});
%   params = ct_set_params(params,'array.img_comb',[9e-6 -inf 1e-6]);
% %   params = ct_set_params(params,'array.Nsrc',4); % Nsrc=2 or 4 for MUSIC
%   params = ct_set_params(params,'array.Nsrc',2); % Nsrc=2 for MLE
%   params = ct_set_params(params,'array.Nsv',64); % For MLE, this is the number of search grid points I think.
%   params = ct_set_params(params,'array.tomo_en',1);
%   params = ct_set_params(params,'array.method','mle');

% Each cell array represent one horizontal (potentially combined) image,
% which may contain more than one vertical image. For example, {[1 2],[1]}
% means there are 2 horizontal images: the first one contains 2 vertical
% images and the second contains just 1 vertical image.
  tomo_collate.imgs = {[1]}; % No fusing (single image)
%   tomo_collate.imgs = {[1],[2]}; % Vertical fusing
%   tomo_collate.imgs = {[1 2]}; % Horizontal fusing

% .img_comb: vertical (fast-time) combining times (see img_combine.m
% "img_comb" description).
  tomo_collate.img_comb = [];
%   tomo_collate.img_comb = [3e-06 -Inf 1e-06 1e-05 -Inf 3e-06];

%   for param_idx = 1:length(params)
%     if params(param_idx).cmd.generic
%       if length(params(param_idx).radar.wfs) == 4
%         params(param_idx).array.imgs = {[ones([7 1]),[6:12].'],[2*ones([7 1]),[6:12].'],[3*ones([7 1]),[6:12].'],[4*ones([7 1]),[6:12].']};
%         tomo_collate.imgs = {[1 2],[3 4]};
%         tomo_collate.img_comb = [0 3e-6 1e-6];
%         params = ct_set_params(params,'array.Nsv',64);
%         params = ct_set_params(params,'array.Nsrc',2);
%       elseif length(params(param_idx).radar.wfs) == 6
%         params(param_idx).array.imgs = {[ones([7 1]),[6:12].'],[2*ones([7 1]),[6:12].'],[3*ones([7 1]),[6:12].'],[4*ones([7 1]),[6:12].'],[5*ones([7 1]),[6:12].'],[6*ones([7 1]),[6:12].']};
%         tomo_collate.imgs = {[1 2],[3 4],[5 6]};
%         tomo_collate.img_comb = [0 3e-6 1e-6 0 10e-6 3e-6];
%         params = ct_set_params(params,'array.Nsv',64);
%         params = ct_set_params(params,'array.Nsrc',2);
%       elseif length(params(param_idx).radar.wfs) == 2
%         % imgs: No change required
%         tomo_collate.imgs = {1};
%         tomo_collate.img_comb = [];
%         params = ct_set_params(params,'array.Nsv',128);
%         params = ct_set_params(params,'array.Nsrc',4);
%       else
%         keyboard
%       end
%     end
%   end
  
  % .in_path: ct_filename_out directory to use at input, fused image will be stored here.
%   tomo_collate.in_path = 'test_music3D';
%   tomo_collate.in_path = 'test_music3D_Nsv128_Nc15';
%   tomo_collate.in_path = 'test_music3D_Nsv64_Nc7';
  tomo_collate.in_path = 'music3D';

  
  % .surf_out_path: ct_filename_out directory to use at output for surfdata
  tomo_collate.surf_out_path = 'surf';

  % .imgs: list of images II to use from .in_path (Data_img_II*.mat). These
  %   should be listed from left most beam to right most beam for
  %   horizontal fusing and top to bottom for vertical fusing.
  
  % .img_comb: Same as qlook and array worksheets. This is
  %   used for vertical/fast-time using only. For N images,
  %   there will be (N-1) combines performed. Each combine is described by
  %   three numbers so that there should be (N-1)*3 elements in this
  %   vector. Each set of three numbers indicates the following:
  %     1st element: Minimum time to begin combine
  %     2nd element: Minimum time after ice surface to begin combine
  %     3rd element: Time at end of the preceeding waveform to not use
  
  % .fuse_columns: aligns with .imgs, each entry should contain 2x(N-1)
  % entries where N is the length of the corresponding cell in .imgs. Each
  % column of 2 numbers represents the start/stop columns to blend with.
  % There should be one column per interface between two images that needs
  % to be blended in the horizontal dimension. E.g. If blending 3 images in
  % the horizontal dimension, the entry should be 2x2. If blending 2
  % images, the entry should be 2x1. If there is only one image for a
  % particular vertical index, then fuse_columns should be empty.
  %tomo_collate.fuse_columns = {[], [], [32, 33]};
  tomo_collate.fuse_columns = {[]};
  
  % .sv_cal_fn: filename containing steering vector calibration, leave empty to not use
  tomo_collate.sv_cal_fn = '';
  
  % .ice_mask_fn: filename of ice mask, leave empty to not use
  tomo_collate.ice_mask_fn = 'greenland/IceMask/GimpIceMask_90m_v1.1.tif';
  %tomo_collate.ice_mask_fn = ct_filename_gis([],'canada/ice_mask/03_rgi50_ArcticCanadaNorth/03_rgi50_ArcticCanadaNorth.mat');
  

  % .dem_guard: additional region in meters around flight line to search for DEM points
  %   Setting too high slows the process down, setting too low will miss
  %   DEM points needed to properly represent the surface.
  tomo_collate.dem_guard = 12e3;
  
  % .dem_per_slice_guard: additional region in meters around each slice to search for DEM points
  %   Setting too high slows the process down, setting too low will miss
  %   DEM points needed to properly represent the surface.
  tomo_collate.dem_per_slice_guard = 240;
  
  % .ground_based_flag: logical default is false, if true data are treated
  % as ground based and surface twtt and ice_mask are set to zero and one
  % for all pixels respectively.
  tomo_collate.ground_based_flag = false;
  
  % .bounds_relative: DOA bins and along-track slices to trim off from each edge [top bottom left right]
  tomo_collate.bounds_relative = [3 2 0 0];
  
  % .layer_params: parameter structure for opsLoadLayer (first layer should
  %   be ice top and second layer should be ice bottom), these are used for
  %   the initial ground truth for tracking.
  tomo_collate.layer_params = struct('name','surface','source','layerdata');
  tomo_collate.layer_params(2).name = 'bottom';
  tomo_collate.layer_params(2).source = 'layerdata';
  
  % .tomo_params: parameters to constrain the range-bins of the 3D tracker
  %tomo_collate.tomo_params = struct('name','surface','source','layerdata','eval',struct('cmd','s=s-1e-6;'));
  %tomo_collate.tomo_params(2) = struct('name','bottom','source','layerdata','eval',struct('cmd','s=s+5e-6;'));
  
  % surfData_mode: surfData mode ('overwrite','fillgaps', or 'append', note that append with the
  %   same surface name as an existing surface will overwrite that surface whereas fillgaps
  %   will leave the surface untouched if it already exists)
  tomo_collate.surfData_mode = 'overwrite';
  
  % surfdata_cmds: surfdata commands to run
  tomo_collate.surfdata_cmds = [];
  
  % TRW-S (Tree Reweighted Sequential algorithm)
  tomo_collate.surfdata_cmds(end+1).cmd = 'trws';
  tomo_collate.surfdata_cmds(end).surf_names = {'bottom trws','bottom'};
  tomo_collate.surfdata_cmds(end).visible = true;
  tomo_collate.surfdata_cmds(end).smooth_weight = [22 22];
  tomo_collate.surfdata_cmds(end).smooth_var = 32;
  tomo_collate.surfdata_cmds(end).max_loops = 50;
  
  %param.tomo_collate.top_name = 'top';
  param.tomo_collate.top_name = '';
  
  % .fuse_images_flag: runs fuse_images.m when true
  tomo_collate.fuse_images_flag = true;
  
  % .add_icemask_surfacedem_flag: runs add_icemask_surfacedem.m when true
  tomo_collate.add_icemask_surfacedem_flag = true;
  
  % create_surfData_flag: runs create_surfData.m when true
  tomo_collate.create_surfData_flag = true;
  
  param_override.tomo_collate = tomo_collate;

else
  error('%s is not a valid example_setup.', example_setup);
end

dbstop if error;
% param_override.cluster.type = 'torque';
% param_override.cluster.type = 'matlab';
param_override.cluster.type = 'debug';
% param_override.cluster.rerun_only = true;
% param_override.cluster.desired_time_per_job  = 240*60;
param_override.cluster.cpu_time_mult  = 2;
% param_override.cluster.mem_mult  = 2;

%% Automated Section
% =====================================================================

% Input checking
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

% Process each of the segments
ctrl_chain = {};
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  ctrl_chain{end+1} = tomo.collate(param,param_override);
end

cluster_print_chain(ctrl_chain);

[chain_fn,chain_id] = cluster_save_chain(ctrl_chain);
