

% script run_make_coverage_maps_seg

% Calls the make_coverage_maps function
%
% Author: John Paden, edits by Rohan Choudhari
%
% See also: make_coverage_maps

global gRadar

%% User Settings
% =========================================================================

% --------- STEP 1: SELECT THE DATA SOURCE ---------
% string 'gps' or 'records' (which files in csarp_support to use)
user_variables.data_source = 'records';
%user_variables.data_source = 'gps';




% --------- STEP 2: SELECTING THE SEASON ---------
% 1. Read the season
% 2. Set the params for that season using ct_set_params
% NOTE: If you want to use the same condition to set the params for all the
% seasons, use ct_set_params(params{params_idx}, ...) in the for loop in
% the automated section

params = {};

% params{end+1} = read_param_xls(ct_filename_param('rds_param_2010_Greenland_DC8.xls'));
% params{end} = ct_set_params(params{end},'cmd.generic',1);

params{end+1} = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'));
params{end} = ct_set_params(params{end},'cmd.generic',0);
params{end} = ct_set_params(params{end},'cmd.generic',1,'day_seg','20140325_07');
params{end} = ct_set_params(params{end},'cmd.generic',1,'day_seg','20140401_03');
params{end} = ct_set_params(params{end},'cmd.generic',1,'day_seg','20140506_01');

%params{end+1} = read_param_xls(ct_filename_param('rds_param_2011_Greenland_TO.xls'));
%params{end} = ct_set_params(params{end},'cmd.generic',1);




% --------- STEP 3 : SELECT THE GIS FILE  ---------
if strcmpi(params{1}(1).post.ops.location,'arctic')
  %user_variables.geotiff_fn = ct_filename_gis(gRadar,fullfile('arctic','Landsat-7','arctic_natural_90m.tif')); %Default
  user_variables.geotiff_fn = ct_filename_gis(gRadar,fullfile('arctic','NaturalEarth_Data','Arctic_NaturalEarth.tif'));
elseif strcmpi(params{1}(1).post.ops.location,'antarctic')
  user_variables.geotiff_fn = ct_filename_gis(gRadar,'antarctica/Landsat-7/Antarctica_LIMA_240m.tif'); %Default
  %user_variables.geotiff_fn = ct_filename_gis(gRadar,fullfile('antarctica','NaturalEarth_Data','Antarctica_NaturalEarth.tif'));
end




% --------- STEP 4 : SELECT WHETHER TO SAVE THE FIGURE ---------
% set save image flag
% user_variables.save_img = 1; %to save, default
user_variables.save_img = 0; % to not save




% --------- STEP 5 : SELECT THE FILE FORMAT ---------
%user_variables.ext = '.m'; %Default
user_variables.ext = '.jpg';
%user_variables.ext = '.fig';





% --------- STEP 6: SELECT THE DESTINATION WHERE THE FIGURE IS TO BE SAVED AT ---------
if user_variables.save_img == 1
  user_variables.out_dir = fullfile(gRadar.out_path,'coverage_maps');
end




% --------- STEP 7: SET THE DESIRED AXIS LIMIT ---------
if strcmpi(params{1}(1).post.ops.location,'arctic')
  user_variables.axis_limits = [-2300 1000 -3500 1500]; % All of Arctic (use for OIB coverage maps)
elseif strcmpi(params{1}(1).post.ops.location,'antarctic')
  user_variables.axis_limits = [-3000 1000 -1500 2500]; % All of Antarctica (use for OIB coverage maps)
end




% --------- STEP 9: ALTER OTHER OPTIONAL VALUES ---------
% dt = time spacing (sec) between each plotted point
user_variables.dt = 1;

% along_track_sampling: desired along track sampling of plot (m)
user_variables.along_track_sampling = 100;

% plot_args: cell array of argument to plot function (e.g. 'b.' for blue dots)
user_variables.plot_args = {'LineWidth',2};

% label: Add text labels to the plots for specific frames
%  .day_seg: cell list of day segments to match
%  .frm: equal length cell vector to .day_seg with specific frames to label
%  .text: equal length cell vector to .day_seg with string for text label
label.day_seg = {};
label.frm = {};
label.text = {};
label.day_seg = {'20140325_07','20140401_03','20140506_01'};
label.frm = {[1],[13],[1]};
label.text = {'20140325\_07','20140401\_03','20140506\_01'};
% label.day_seg = {'20091102_02','20091016_01','20091016_01','20091102_02','20091102_02'};
% label.frm = {8, 21, 26, 23, 32};
% label.text = {' 1',' 2',' 3',' 4',' 5'};
user_variables.label = label;

% figure_position: Set figure Position property (leave empty to use default/current figure size)
user_variables.figure_position = [];
% figure_position = [221   -60   654   704];






%% Automated section
% =========================================================================
%Looping through all the selected parameter spreadsheets
for params_idx = 1:length(params)
  
  %Set the params according to what you want
  params{params_idx} = ct_set_params(params{params_idx},'cmd.generic',0,'cmd.notes','do not process');
  user_variables.params_idx = params_idx;
  user_variables.proj = geotiff_plot(user_variables.geotiff_fn,[],[], params_idx);
  test_make_coverage_maps(params{params_idx}, user_variables);
  
  if ~exist(out_dir,'dir')
    mkdir(out_dir);
  end
end