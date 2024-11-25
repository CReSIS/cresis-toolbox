% script run_echo_plot.m
%
% Example and test script for echo_plot.m
%
% Author: John Paden, Dhagash Kapadia
%
% See also: echo_plot.m, echo_plot_profile.m, elevation_compensation.m,
% load_L1B.m, run_echo_plot.m

%% Choose example (enable just one)
% test_case_str = 'no_layers';
% test_case_str = 'no_layers_fn';
% test_case_str = 'no_layers_twtt_fn';
% test_case_str = 'default_layers';
% test_case_str = 'nonstandard_surface';
% test_case_str = 'no_plot';
% test_case_str = 'posted_layers';
% test_case_str = 'arbitrary_layers';
test_case_str = 'uniform_sampling';
% test_case_str = 'layer_params';
% test_case_str = 'wildcard_layers';
% test_case_str = 'surface_nan';

%% Examples

param = read_param_xls(ct_filename_param('snow_param_2012_Greenland_P3.xls'),'20120330_04');
[mdata,echo_fn] = echo_load(param,'CSARP_post/qlook',3);

if strcmpi(test_case_str,'no_layers')
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(mdata);
end

if strcmpi(test_case_str,'no_layers_fn')
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn);
end

if strcmpi(test_case_str,'no_layers_twtt_fn')
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn,'TWTT');
end

if strcmpi(test_case_str,'default_layers')
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn, [], 'rds_layers');
end

if strcmpi(test_case_str,'nonstandard_surface')
  echo_plot_param = echo_plot_profile('DEPTH');
  echo_plot_param.surf.source = 0;
  echo_plot_param.h_fig = 1;
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn, echo_plot_param, 'rds_layers');
  echo_plot_param.surf.source = 1;
  echo_plot_param.h_fig = 2;
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn, echo_plot_param, 'rds_layers');
end

if strcmpi(test_case_str,'no_plot')
  % Just loads the data (twtt) and provides all the variables to plot
  [mdata,x_axis,y_axis,surf_comp,layers_comp] = echo_plot(mdata,'NONE','rds_layers');
end

if strcmpi(test_case_str,'posted_layers')
  layer_params = struct('name',{'surface','bottom'},'layerdata_source','layer_old','existence_check',false);
  [data, layers_comp, h] = echo_plot(echo_fn, [], layer_params);
end

if strcmpi(test_case_str,'arbitrary_layers')
  layer_names = {'surface','bottom','layer_01'};
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn, setfield(echo_plot_profile('DEPTH'),'h_fig',1), struct('name',layer_names, 'source', 'layerdata','existence_check',false));
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn, setfield(echo_plot_profile('RANGE'),'h_fig',2), struct('name',layer_names, 'source', 'layerdata','existence_check',false));
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn, setfield(echo_plot_profile('TWTT'),'h_fig',3), struct('name',layer_names, 'source', 'layerdata','existence_check',false));
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn, setfield(echo_plot_profile('WGS84'),'h_fig',4), struct('name',layer_names, 'source', 'layerdata','existence_check',false));
end

if strcmpi(test_case_str,'uniform_sampling')
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn, setfield(setfield(echo_plot_profile('WGS84'),'h_fig',4),'mode_x_axis','ALONG_TRACK'));
end

if strcmpi(test_case_str,'layer_params')
  layer_params = struct('source','layerdata','name','surface');
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn, [], layer_params);
end

if strcmpi(test_case_str,'wildcard_layers')
  layer_params = struct('source','layerdata','name',{'surface',''},'regexp',{[],'layer.*'},'existence_check',false);
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn, 'TWTT', layer_params);
end

if strcmpi(test_case_str,'surface_nan')
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(mdata, setfield(echo_plot_profile('DEPTH'),'h_fig',1), struct('name',{'surface', 'bottom'}, 'source', 'layerdata'));
  mdata.Surface(:) = NaN;
  [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(mdata, setfield(echo_plot_profile('DEPTH'),'h_fig',2), struct('name',{'surface', 'bottom'}, 'source', 'layerdata'));
end
