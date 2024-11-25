function [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn,echo_plot_param,layer_params)
% [mdata,x_axis,y_axis,surf_comp,layers_comp,h] = echo_plot(echo_fn,echo_plot_param,layer_params)
%
% Function for loading and plotting data with layers using
% elevation_compensation.m
%
% Plots data based on echo_plot_param. Loads and plots layers based on
% layer_params.
%
% Inputs:
% =========================================================================
%
% echo_fn: string containing an echogram filename or an echogram structure
% (e.g. loaded with echo_load.m)
%
% echo_plot(echo_fn,echo_plot_param,layer_params)
%
% echo_plot_param: See echo_plot_profile.m. Can be either a profile string
% or a parameter structure.
%
% layer_params: See layerdata.m profile() static function. Can be either a
% profile string or a opsLoadLayers.m parameter structure.
%
% Outputs:
% =========================================================================
%
% data,x_axis,y_axis,surf_comp,layers_comp: From elevation_compensation.m
%
% h: figure, axes, image, and plot handles created or used by this function
%
% Examples: See run_echo_plot.m
%
% Author: John Paden, Dhagash Kapadia
%
% See also: echo_plot.m, echo_plot_profile.m, elevation_compensation.m,
% load_L1B.m, run_echo_plot.m


%% Input Checks
% =========================================================================

if ~exist('echo_plot_param', 'var') || isempty(echo_plot_param)
  echo_plot_param = [];
end

echo_plot_param = echo_plot_profile(echo_plot_param);

if ~exist('layer_params', 'var')
  layer_params = [];
end

layer_params = layerdata.profile(layer_params);

%% Load Data
% =========================================================================
if isstruct(echo_fn)
  mdata = echo_fn;
else
  mdata = echo_load(echo_fn);
end

%% Load Layers
% =========================================================================
layers_twtt = {};
if ~isempty(layer_params)
  param = echo_param(mdata);
  % Determine the range of frames that this echogram covers
  [~,frm_id] = get_frame_id(param,mdata.GPS_time([1 end]));
  % Get the frame before/after so that layers will be interpolated
  % correctly.
  param.cmd.frms = floor(frm_id(1))-1 : floor(frm_id(end))+1;
  % Load the layers
  [layers] = opsLoadLayers(param,layer_params);
  % Format each layer
  for lay_idx = 1:length(layers)
    ops_layer = [];
    ops_layer{1}.gps_time = layers(lay_idx).gps_time;
    ops_layer{1}.type = layers(lay_idx).type;
    ops_layer{1}.quality = layers(lay_idx).quality;
    ops_layer{1}.twtt = layers(lay_idx).twtt;
    ops_layer{1}.type(isnan(ops_layer{1}.type)) = 2;
    ops_layer{1}.quality(isnan(ops_layer{1}.quality)) = 1;
    lay = opsInterpLayersToMasterGPSTime(mdata,ops_layer,[300 60]);
    layers_twtt{lay_idx} = lay.layerData{1}.value{2}.data;
    layers_twtt{lay_idx} = interp_finite(layers_twtt{lay_idx}, 0);
  end
end

%% Elevation compensation
% =========================================================================
[mdata,x_axis,y_axis,surf_comp,layers_comp] = elevation_compensation(mdata,echo_plot_param,layers_twtt);

%% Plot results
% =========================================================================
% h: output GUI handles
h = [];
if ~echo_plot_param.plot_en
  return;
end
if isempty(echo_plot_param.h_fig)
  h.fig = get_figures(1,true);
else
  h.fig = echo_plot_param.h_fig;
  if ~ishandle(h.fig)
    figure(h.fig);
  end
end
clf(h.fig);
h.axes = axes('parent',h.fig);
if ~isreal(mdata.Data)
  % Complex (voltage data are always represented in complex baseband format)
  h.image = imagesc(x_axis, y_axis, db(mdata.Data), 'parent', h.axes);
else
  % Linear power
  h.image = imagesc(x_axis, y_axis, db(mdata.Data,'power'), 'parent', h.axes);
end
colormap(h.axes,1-gray(256));

%% Plot x-axis
% =========================================================================
if strcmpi(echo_plot_param.mode_x_axis, 'range_line')
  xlabel(h.axes,'Range line');
elseif strcmpi(echo_plot_param.mode_x_axis, 'gps_time')
  xlabel(h.axes,'GPS time (sec)');
elseif strcmpi(echo_plot_param.mode_x_axis, 'along_track')
  xlabel(h.axes,'Along track (km)');
end

%% Plot y-axis
% =========================================================================
if strcmpi(echo_plot_param.mode_y_axis, 'TWTT')
  ylabel(h.axes,'Two way travel time (sec)')
  set(h.axes,'YDir','reverse')
  
elseif strcmpi(echo_plot_param.mode_y_axis,'RANGE')
  ylabel(h.axes,'Range (m)')
  set(h.axes,'YDir','reverse')
  
elseif strcmpi(echo_plot_param.mode_y_axis, 'WGS84')
  ylabel(h.axes,'WGS-84 (m)')
  set(h.axes,'YDir','normal')
  
elseif strcmpi(echo_plot_param.mode_y_axis, 'DEPTH')
  ylabel(h.axes,'Depth (m)');
  set(h.axes,'YDir','reverse')
end

%% Plot layers
% =========================================================================
hold(h.axes,'on');
h.plot = [];
for layer_idx = 1:length(layers_comp)
  h.plot(layer_idx) = plot(h.axes,x_axis,layers_comp{layer_idx});
end
hold(h.axes,'off')
