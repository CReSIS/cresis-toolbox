% script run_layer_tracker_tune
% Runs layer_tracker.m for tuning layer tracking hyperparameters.
%
% Authors: Anjali Pare, John Paden
%
% See also: layer_tracker.m, layer_tracker_combine_task.m,
% layer_tracker_task.m, layer_tracker_profile.m, run_layer_tracker.m,
% run_layer_tracker_tune.m
%
% param_override.tmp_name - Enter the name of the file where images will be saved
% param_override.temp_name - Make sure this is the same unique identifier
% you used in run_layer_tracker_tune.m to save the paramters. In order to
% load the same parameters, the names must match
% tracker_method - Set which tracking method you want to use 'lsm' or 'viterbi'

% Running this script will create two ctrl_chains. Load each separately and
% run them one after the other. The command to run will be displayed in the
% command window


%% User Settings
% ----------------------------------------------------------------------
param_override = [];
params_all = [];
idx_segment = 1;

% To run the entire season
params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'));
params = ct_set_params(params,'cmd.generic',1);%|20140415_05|20140421_01|20140516_01');%'20140415_05|20140421_01|20140514_01|20140313_09');
params = ct_set_params(params,'cmd.generic',0,'day_seg','20140423_01');
params = ct_set_params(params,'cmd.generic',0,'cmd.notes','Do not process');
params = ct_set_params(params,'cmd.frms',[]); % Specify specific frames (or leave empty/undefined to do all frames)

% To run 2 segments with all frames
% params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140313_09|20140516_01');
% params(idx_segment).cmd.generic = 1;
% params(idx_segment).cmd.frms = [];
% idx_segment = idx_segment + 1;
% params(idx_segment).cmd.generic = 1;
% params(idx_segment).cmd.frms = [];

% To run 2 segments with frames 1 and 2 for the first segment and 3 and 4
% for the second segment
% params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140313_09|20140516_01');
% params(idx_segment).cmd.generic = 1;
% params(idx_segment).cmd.frms = [1 2];
% idx_segment = idx_segment + 1;
% params(idx_segment).cmd.generic = 1;
% params(idx_segment).cmd.frms = [3 4];

param_override.layer_tracker.layer_params = [];
param_override.layer_tracker.layer_params.layerdata_source = 'layer_tune_vit_seg4_C';
param_override.tmp_name = 'layer_tune_vit_season_CnoM'; % Enter the name of the file where images will be saved
param_override.temp_name = 'test_anj'; % Make sure this is the same unique identifier you used in run_layer_tracker_tune.m to save the paramters. In order to load the same parameters, the names must match

tracker_method = 'viterbi'; % Choose the tracking method

%% param.layer_tracker.track options
options = [];
options.set_range = 50; % set acceptable range for error
options.segment_vs_frame.plot = true; % absolute error vs frames (for each segment)
options.segment_vs_frame.fig_format = true; % save image as .fig file
options.season_vs_gps.plot = false; % absolute error vs gps time (for entire season)
options.season_vs_gps.fig_format = true; % save image as .fig file
options.season_vs_gps.multiple_figs = true; % choose this option if you separate plots generated for each layer. If set to false, 6 subplots will be plotted in one figure.
options.absolute_error.plot = true; % mean absolute error plots
options.absolute_error.fig_format = true; % save image as .fig file
options.absolute_error.multiple_plots = true; % set to true to create multiple plots
options.percentage_correct.plot = true; % plot of percentage correct vs frames (for each segment)
options.percentage_correct.fig_format = true; % save image as .fig file
options.percentage_correct.multiple_plots = true;% set to true to create multiple plots
options.hist_generation.plot = true; % histograms of data points vs absolute error
options.hist_generation.fig_format = true; % save image as .fig file
options.hist_generation.multiple_plots = true; % set to true to create multiple plots
param_override.options = options;

%% Set which layers you want - whether surface, bottom, or both

idx = 1;
% Uncomment below for surface and bottom
% gt_layer_params = [];
% gt_layer_params(idx).name = 'surface';
% idx = idx + 1;
gt_layer_params(idx).name = 'bottom'; % specify layer names
param_override.gt_layer_params = gt_layer_params;
layer_idx = length(gt_layer_params);

%% Load all the temporary param files
seg_idx = 0;
filename = [];
param_dir_dir = '/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/';
param_dir = dir([param_dir_dir]);
for i = 3:length(param_dir)
  if ~isempty(strfind(param_dir(i).name,param_override.temp_name))
    filename{end+1} = load(strcat(param_dir_dir,param_dir(i).name));
  end
end

%% Cluster Settings
% dbstop if error;
param_override.cluster.type = 'torque';
% param_override.cluster.type = 'matlab';
% param_override.cluster.type = 'debug';
% param_override.cluster.type = 'slurm';
% param_override.cluster.rerun_only = true;
% param_override.cluster.desired_time_per_job  = 240*60;
param_override.cluster.cpu_time_mult  = 30;
param_override.cluster.mem_mult  = 15;

%% Automated Section
% ----------------------------------------------------------------------

% Input checking
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

ctrl_chain = {};
img_fn_dir = {};
all_params = {};
% Process each of the segments
for param_idx = 1:length(params)
  param = params(param_idx);
  if isfield(param.cmd,'generic') && ~iscell(param.cmd.generic) && ~ischar(param.cmd.generic) && param.cmd.generic
    param = merge_structs(param, param_override);
    frames = frames_load(param);
    param.cmd.frms = frames_param_cmd_frms(param,frames);
    seg_idx = seg_idx + 1;
    param.filename = filename{seg_idx};
    all_params{end+1} = param.day_seg;
    fprintf('=====================================================================\n');
    fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
    fprintf('=====================================================================\n');
    
    %% Set up Cluster
    % ===================================================================
    
    ctrl = cluster_new_batch(param);
    cluster_compile({'layer_tracker_generate_task','layer_tracker_generate_combine_task'},ctrl.cluster.hidden_depend_funs,ctrl.cluster.force_compile,ctrl);
    
    %% layer_tracker
    % =========================================================================
    % =========================================================================
    
    % Cluster setup
    % -------------------------------------------------------------------------
    dparam = [];
    sparam.argsin{1} = param;
    sparam.task_function = 'layer_tracker_generate_task';
    sparam.argsin{1}.num_args_out = 1;
    sparam.num_args_out = 1;
    sparam.cpu_time = 100;
    sparam.mem = 1000e6;
    sparam.notes = '';
    sparam.file_success = {};
    
    % end
    
    %% layer_tracker: Loop to create tasks
    % -------------------------------------------------------------------------
    img_dir = '/cresis/snfs1/scratch/anjali/cluster_tuning/';
    img_dir_combine = sprintf('%s%s/',img_dir,param.tmp_name);
    img_dir = sprintf('%s%s',img_dir_combine,param.day_seg);
    if ~exist(img_dir,'dir')
      mkdir(img_dir);
    end
    img_fn_dir{end+1} = img_dir;
    dparam.argsin{1}.fname = img_dir;
    dparam.argsin{1}.img_dir_combine = img_dir_combine;
    dparam.argsin{1}.param_idx = param_idx;
    dparam.argsin{1}.season_idx = 1;
    dparam.num_args_out = 1;
    sparam.file_success{end+1} = img_dir;
    mem_combine = 0;
    cputime_combine = 0;
    frm_idx = 1;
    idx = 1;
    
    
    % Create task
    % ---------------------------------------------------------------------
    ctrl = cluster_new_task(ctrl,sparam,dparam,'dparam_save',0);
    ctrl = cluster_save_dparam(ctrl);
    ctrl_chain{end+1} = {ctrl};
    fprintf('Done %s\n',datestr(now));
    % ctrl_chain = {{ctrl}};
  end
end
cluster_print_chain(ctrl_chain);
[chain_fn,chain_id] = cluster_save_chain(ctrl_chain);

ctrl_chain = {};
ctrl = cluster_new_batch(param);

sparam = [];
sparam.argsin{1} = param;
sparam.task_function = 'layer_tracker_generate_combine_task';
sparam.num_args_out = 1;
sparam.file_success = {};

sparam.file_success{end+1} = img_dir;

sparam.cpu_time = 500;
sparam.mem = 500e6;
sparam.notes = '';

out_fn_dir = ct_filename_out(param,'',param.layer_tracker.layer_params.layerdata_source); %/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_layer_tune_vit_seg4_NC/20140313_09
save_names = {};
for i = 1:length(all_params)
  for layer_idx = 1:length(gt_layer_params)
    save_names{layer_idx,i} = sprintf('%s/result.mat',img_fn_dir{i});
  end
end
sparam.argsin{1}.save_names = save_names;


ctrl = cluster_new_task(ctrl,sparam,[]);
ctrl_chain{end+1} = {ctrl};
fprintf('Done %s\n',datestr(now));


cluster_print_chain(ctrl_chain);
[chain_fn,chain_id] = cluster_save_chain(ctrl_chain);