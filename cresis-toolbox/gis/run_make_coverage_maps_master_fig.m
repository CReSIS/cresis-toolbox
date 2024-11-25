% script run_make_coverage_maps_master_fig

% Calls the make_coverage_maps function to generate the master fig
%
% Author: Rohan Choudhari, John Paden
%
% See also: make_coverage_maps


%% User Settings
% =========================================================================

global gRadar;
user_variables = {};
season_stats = {};

% --------- STEP 1: SET THE LOCATION ---------
location = 'Greenland';
%location = 'Antarctica';

if strcmpi(location,'Greenland')
  season_names = {};
  
%   season_names{end+1} = 'rds_param_1993_Greenland_P3';
%   season_names{end+1} = 'rds_param_1995_Greenland_P3';
%   season_names{end+1} = 'rds_param_1996_Greenland_P3';
%   season_names{end+1} = 'rds_param_1997_Greenland_P3';
%   season_names{end+1} = 'rds_param_1998_Greenland_P3';
%   season_names{end+1} = 'rds_param_1999_Greenland_P3';
%   season_names{end+1} = 'rds_param_2001_Greenland_P3';
%   season_names{end+1} = 'rds_param_2002_Greenland_P3';
%   season_names{end+1} = 'rds_param_2006_Greenland_TO';
%   season_names{end+1} = 'rds_param_2008_Greenland_Ground';
%   season_names{end+1} = 'rds_param_2008_Greenland_TO';
%   season_names{end+1} = 'rds_param_2009_Greenland_TO';
  season_names{end+1} = 'rds_param_2010_Greenland_DC8';
%   season_names{end+1} = 'rds_param_2010_Greenland_P3';
%   season_names{end+1} = 'rds_param_2011_Greenland_P3';
%   season_names{end+1} = 'rds_param_2012_Greenland_P3';
%   season_names{end+1} = 'rds_param_2013_Greenland_P3';
%   season_names{end+1} = 'rds_param_2014_Greenland_P3';
%   season_names{end+1} = 'rds_param_2015_Greenland_C130';
%   season_names{end+1} = 'rds_param_2015_Greenland_Polar6';
%   season_names{end+1} = 'rds_param_2016_Greenland_G1XB';
%   season_names{end+1} = 'rds_param_2016_Greenland_P3';
%   season_names{end+1} = 'rds_param_2016_Greenland_Polar6';
%   season_names{end+1} = 'rds_param_2016_Greenland_TOdtu';
%   season_names{end+1} = 'rds_param_2017_Greenland_P3';

  

  
  
  
  
%   season_names{end+1} = 'rds_param_2003_Greenland_P3';
%   season_names{end+1} = 'rds_param_2005_Greenland_TO';
%   season_names{end+1} = 'rds_param_2008_Greenland_Ground_NEEM';
%   season_names{end+1} = 'rds_param_2008_Greenland_TO_wise';
%   season_names{end+1} = 'rds_param_2010_Greenland_TO_wise';
%   season_names{end+1} = 'rds_param_2011_Greenland_TO';
%   season_names{end+1} = 'rds_param_2009_Greenland_TO_wise';
%   season_names{end+1} = 'rds_param_2018_Greenland_Polar6';
  
elseif strcmpi(location,'Antarctica')
  season_names = {};
  season_names{end+1,1} = 'rds/2013_Antarctica_P3';
else
  return
end



% --------- STEP 3 : SELECT WHETHER TO SAVE THE FIGURE ---------
% set save image flag
 user_variables.save_img = 1; %to save
% user_variables.save_img = 0; % to not save




% --------- STEP 4: SELECT THE FILE FORMAT ---------
ext = {};
ext{end+1} = '.m'; %Default
ext{end+1} = '.jpg';
ext{end+1} = '.fig';
user_variables.ext = ext;



% --------- STEP 5: SELECT THE DESTINATION WHERE THE FIGURE IS TO BE SAVED AT ---------
if user_variables.save_img == 1
  out_dir = fullfile(gRadar.out_path,'coverage_maps');
  
  if ~exist(out_dir,'dir')
    mkdir(out_dir);
  end
  user_variables.out_dir = out_dir;
end



% --------- STEP 6: SET THE GEOTIFF, FIGURE SIZE AND PAPER POSITION ---------
if strcmpi(location,'Greenland')
  geotiff_fn = ct_filename_gis(gRadar,'greenland/Landsat-7/Greenland_natural_250m.tif');
  fig_size = [50 50 600 800];
  fig_paper_position = [0.25 2.5 6 8];
elseif strcmpi(location,'Antarctica')
  fig_size = [50 50 800 600];
  fig_paper_position = [0.25 2.5 8 6];
  geotiff_fn = ct_filename_gis(gRadar,'antarctica/Landsat-7/Antarctica_LIMA_480m.tif');
end

% --------- STEP 6: SET THE GEOTIFF, FIGURE SIZE AND PAPER POSITION ---------
user_variables.method = 'agg'; %Aggregation after aggregation
% user_variables.method = 'dec'; %Plain decimation


%% Automated section
% =========================================================================


% Load the geotiffs + plot them in the master figure
figure_handle = 1;
figure(figure_handle); clf;
RGB = {};
R = {};

user_variables.proj = geotiffinfo(geotiff_fn);
[RGB, R, tmp] = geotiffread(geotiff_fn);
R = R/1e3;
mapshow(RGB, R);
hold on;

% Setting the position, axis, title etc
set(figure_handle,'Position',fig_size + [625 0 0 0]);
hold on;
title(strcat(location,'_Master_Fig_',datestr(now,'yyyymmdd')),'Interpreter','none');
axis([R(3,1)+[0 R(2,1)*(size(RGB,2)-1)] sort(R(3,2)+[0 R(1,2)*(size(RGB,1)-1)])]);

% data_source for the master_fig file is 'layer'
user_variables.data_source = 'layer';

%initializing variables
layers = {};
params = {};
season_layers = {};
layer_params = [];
idx = 1;
layer_params(idx).name = 'bottom';
layer_params(idx).source = 'layerData';
% layer_params(idx).layerdata_source = 'CSARP_post/layerData';
layer_params(idx).layerdata_source = 'layerData';
%Setting layer_params which is passed to opsLoadLayers from
%make_coverage_maps.m
% idx = idx + 1;
% layer_params(idx).name = 'surface';
% layer_params(idx).source = 'layerData';
% layer_params(idx).layerdata_source = 'CSARP_post/layerData';
user_variables.layer_params = layer_params;




h_good = plot(1,NaN,'g.');
h_mod = plot(1,NaN,'y.');
h_bad = plot(1,NaN,'r.');

if strcmpi(user_variables.method, 'agg')
  mag = plot(1,NaN,'m.');
  legend([mag h_good h_mod h_bad], 'Bad', 'Good','Moderate','No data','Location','Best');
else
  legend([h_good h_mod h_bad], 'Good','Moderate','Bad','Location','Best');
end

set(figure_handle,'UserData',season_names);
h_children = get(1,'Children');
%debug_test = get(h_children(2),'Children');
h_geotiff = h_children(end);




% Reading params for the selected seasons
for season_idx = 1:length(season_names)

  layers = {};

%   try
    params{end+1} = read_param_xls(ct_filename_param(strcat(season_names{season_idx},'.xls')),'','post');
    params{end} = ct_set_params(params{end},'cmd.generic',1);
    params{end} = ct_set_params(params{end},'cmd.generic',0,'cmd.notes','do not process');
%   catch 
%     warning('Error reading %s', sseason_names{season_idx});
%     continue;
%   end
  
end

user_variables.season_names = season_names;

% *** Call to make_coverage_maps ***
test_make_coverage_maps(params, user_variables);

% mag = plot(1,NaN,'m.');
% h_good = plot(1,NaN,'g.');
% h_mod = plot(1,NaN,'y.');
% h_bad = plot(1,NaN,'r.');
% legend([mag h_good h_mod h_bad], 'NaN', 'Good','Moderate','Bad','Location','Best');
% set(figure_handle,'UserData',season_names);
% h_children = get(1,'Children');
% h_children = get(h_children(2),'Children');
% h_geotiff = h_children(end);


