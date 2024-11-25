% script runOpsLoadLayers.m
%
% Example script for running opsLoadLayers.m. Demonstrates a few of the
% most common operations to be performed with opsLoadLayers and supports
% interpolation of various layer sources for better comparison.
%
% Authors: John Paden

% =====================================================================
%% User Settings
% =====================================================================

% params = read_param_xls(ct_filename_param('rds_param_2012_Greenland_P3.xls'));
params = read_param_xls(ct_filename_param('snow_param_2012_Greenland_P3.xls'));

params = ct_set_params(params,'cmd.generic',0);
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20120330_03');
params = ct_set_params(params,'cmd.generic',1,'day_seg','20120330_04');

layer_params = [];
idx = 0;

%% Example Inputs (just choose one)

if 0
  %% Load a single layer from the echogram
  ref_idx = 1;
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'echogram';
  layer_params(idx).echogram_source = 'qlook';

elseif 1
  %% Load two layers from the layerData file
  ref_idx = 1;
  idx = idx + 1;
  layer_params(idx).name = {'surface','bottom'};
  layer_params(idx).source = 'layerdata';
  layer_params(idx).layerdata_source = 'layer';

elseif 0
  %% Load two layers from the layerData file
  ref_idx = 1;
  idx = idx + 1;
  layer_params(idx).name = {'surface','layer.*'};
  layer_params(idx).source = 'layerdata';
  layer_params(idx).layerdata_source = 'layer';

elseif 0
  %% Compare echogram, layerData, and records
  ref_idx = 1;
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'echogram';
  layer_params(idx).echogram_source = 'qlook';
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'layerData';
  layer_params(idx).layerdata_source = 'layerData';
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'records';
 
elseif 0
  %% Compare echogram and custom layers in layerData
  ref_idx = 1;
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'lidar';
  layer_params(idx).lidar_source = 'awi';
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'layerData';
  layer_params(idx).layerdata_source = 'layerData';
  layer_params(idx).twtt_offset = 0;
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'echogram';
  layer_params(idx).echogram_source = 'standard';
  layer_params(idx).twtt_offset = 0;% 1.18603e-07;
  idx = idx + 1;
  layer_params(idx).name = 'GIMP';
  layer_params(idx).source = 'layerData';
  layer_params(idx).layerdata_source = 'layerData';
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'records';
  layer_params(idx).twtt_offset = 0;
  
elseif 0
  %% Compare OPS surface (records and OPS) to ATM data (raw and OPS)
  ref_idx = 2;
  idx = idx + 1;
  layer_params(idx).name = 'atm';
  layer_params(idx).source = 'ops';
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'ops';
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'records';
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'lidar';
elseif 0
  %% load surface, bottom and MacGregor layers
  ref_idx = 1;
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'layerdata';
  layer_params(idx).layerdata_source = 'layer';
  idx = idx + 1;
  layer_params(idx).name = 'bottom';
  layer_params(idx).source = 'layerdata';
  layer_params(idx).layerdata_source = 'layer';
  idx = idx + 1;
  layer_params(idx).regexp = 'L';
  layer_params(idx).source = 'layerdata';
  layer_params(idx).layerdata_source = 'layer_MacGregor';
else
  %% load surface, bottom and snow layers
  ref_idx = 1;
  idx = idx + 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'layerdata';
  layer_params(idx).layerdata_source = 'layer';
  idx = idx + 1;
  layer_params(idx).name = 'bottom';
  layer_params(idx).source = 'layerdata';
  layer_params(idx).layerdata_source = 'layer';
  idx = idx + 1;
  layer_params(idx).regexp = 'snow';
  layer_params(idx).source = 'layerdata';
  layer_params(idx).layerdata_source = 'layer';
end

% =====================================================================
%% Automated Section
% =====================================================================

global gRadar;

%% Load each of the day segments
layers = {};
day_seg = {};
params_list = {};
new_layer_params = [];
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) ...
      || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  
  param = merge_structs(param,gRadar);
  
  fprintf('opsLoadLayers %s\n', param.day_seg);
  [layers{end+1},new_layer_params] = opsLoadLayers(param,layer_params);
  day_seg{end+1} = param.day_seg;
  params_list{end+1} = param;
end
layer_params = new_layer_params;

% =====================================================================
%% Example Section
% =====================================================================

if 1
  %% Interpolate all layers onto a common reference (ref_idx)
  for seg_idx = 1:length(layers)
    lay_idxs = [1:ref_idx-1 ref_idx+1:length(layers{seg_idx})];
    
    layers{seg_idx}(ref_idx).twtt_ref = layers{seg_idx}(ref_idx).twtt;
    
    master = [];
    master.GPS_time = layers{seg_idx}(ref_idx).gps_time;
    master.Latitude = layers{seg_idx}(ref_idx).lat;
    master.Longitude = layers{seg_idx}(ref_idx).lon;
    master.Elevation = layers{seg_idx}(ref_idx).elev;
    for lay_idx = lay_idxs
      ops_layer = [];
      ops_layer{1}.gps_time = layers{seg_idx}(lay_idx).gps_time;
      ops_layer{1}.type = layers{seg_idx}(lay_idx).type;
      ops_layer{1}.quality = layers{seg_idx}(lay_idx).quality;
      ops_layer{1}.twtt = layers{seg_idx}(lay_idx).twtt;
      ops_layer{1}.type(isnan(ops_layer{1}.type)) = 2;
      ops_layer{1}.quality(isnan(ops_layer{1}.quality)) = 1;
      lay = opsInterpLayersToMasterGPSTime(master,ops_layer,[300 60]);
      layers{seg_idx}(lay_idx).twtt_ref = lay.layerData{1}.value{2}.data;
    end
  end
end

if 1
  %% Simple plot of all layers versus time
  % ref_color: Reference plot color
  ref_color = 'k.';
  % Layer indexes for comparison layers
  lay_idxs = [1:ref_idx-1 ref_idx+1:length(layers{seg_idx})];
  % plot_modes: Different colors used to plot
  plot_modes = {'r.','g.','c.','b.','m.'};
  
  for seg_idx = 1:length(layers)
    if ~isfield(layer_params(ref_idx),'twtt_offset') ...
        || isempty(layer_params(ref_idx).twtt_offset)
      layer_params(ref_idx).twtt_offset = 0;
    end

    figure(1); clf;
    h_axes = axes('Parent',1);
    [~,ref_frm,~] = get_frame_id(params_list{seg_idx},layers{seg_idx}(ref_idx).gps_time,struct('segment_id_num',true));
    h_plot = plot(ref_frm, ...
      layers{seg_idx}(ref_idx).twtt + layer_params(ref_idx).twtt_offset, ...
      'k.','Parent',h_axes);
    title(sprintf('%s', day_seg{seg_idx}),'Interpreter','none','Parent',h_axes);
    legend_strs = {sprintf('Ref %d', ref_idx)};
    hold(h_axes,'on');
    grid(h_axes,'on');
    xlabel('Frame','Parent',h_axes);
    ylabel('TWTT (us)','Parent',h_axes);
    
    figure(2); clf(2);
    h_axes_comp = axes('Parent',2);
    h_plot_comp = plot(ref_frm, ...
      layers{seg_idx}(ref_idx).twtt_ref + layer_params(ref_idx).twtt_offset ...
      - (layers{seg_idx}(ref_idx).twtt_ref + layer_params(ref_idx).twtt_offset), ...
      'k.','Parent',h_axes_comp);
    title(sprintf('%s', day_seg{seg_idx}),'Interpreter','none','Parent',h_axes_comp);
    hold(h_axes_comp,'on');
    grid(h_axes_comp,'on');
    xlabel('Frame','Parent',h_axes_comp);
    ylabel('TWTT Difference (us)','Parent',h_axes_comp);
    
    fprintf('Layer Index\tMedian Offset\tMean Offset\n');
    
    for lay_idx = lay_idxs
      if ~isfield(layer_params(lay_idx),'twtt_offset') ...
          || isempty(layer_params(lay_idx).twtt_offset)
        layer_params(lay_idx).twtt_offset = 0;
      end
      
      [~,lay_frm,~] = get_frame_id(params_list{seg_idx},layers{seg_idx}(lay_idx).gps_time,struct('segment_id_num',true));
      h_plot(end+1) = plot(lay_frm, ...
        layers{seg_idx}(lay_idx).twtt + layer_params(lay_idx).twtt_offset, ...
        plot_modes{mod(lay_idx-1,length(plot_modes))+1},'Parent',h_axes);
      legend_strs{end+1} = sprintf('Layer %d', lay_idx);

      h_plot_comp(end+1) = plot(ref_frm, ...
        layers{seg_idx}(lay_idx).twtt_ref + layer_params(lay_idx).twtt_offset ...
        - (layers{seg_idx}(ref_idx).twtt_ref + layer_params(ref_idx).twtt_offset), ...
        plot_modes{mod(lay_idx-1,length(plot_modes))+1},'Parent',h_axes_comp);
      
      fprintf('%11d\t%13g\t%11g\n', lay_idx, ...
        nanmedian(layers{seg_idx}(lay_idx).twtt_ref + layer_params(lay_idx).twtt_offset ...
        - (layers{seg_idx}(ref_idx).twtt_ref + layer_params(ref_idx).twtt_offset)), ...
        nanmean(layers{seg_idx}(lay_idx).twtt_ref + layer_params(lay_idx).twtt_offset ...
        - (layers{seg_idx}(ref_idx).twtt_ref + layer_params(ref_idx).twtt_offset)));
    end
    legend(h_plot, legend_strs);
    legend(h_plot_comp, legend_strs);
    linkaxes([h_axes_comp h_axes],'x');
    
    if seg_idx ~= length(layers)
      pause;
    end
  end
end

if 0
  %% Compare N layers
  % ref_color: Reference plot color
  ref_color = 'k.';
  % Layer indexes for comparison layers
  lay_idxs = [1:ref_idx-1 ref_idx+1:length(layers{seg_idx})];
  % plot_modes: Different colors used to plot
  plot_modes = {'r.','g.','c.','b.','m.'};
  
  status = {};
  for seg_idx = 1:length(layers)

    figure(1); clf;
    plot(layers{seg_idx}(ref_idx).gps_time, layers{seg_idx}(ref_idx).twtt, 'k.');
    title(sprintf('%s', day_seg{seg_idx}),'Interpreter','none');
    hold on;
    for lay_idx = lay_idxs
      plot(layers{seg_idx}(lay_idx).gps_time, layers{seg_idx}(lay_idx).twtt, ...
        plot_modes{mod(lay_idx-1,length(plot_modes))+1});
    end
    h_axis = gca;
    grid on
    xlabel('GPS time (sec)');
    ylabel('TWTT ({\mu}s)','interpreter','tex');
    
    figure(2); clf;
    plot(layers{seg_idx}(ref_idx).gps_time, layers{seg_idx}(ref_idx).twtt, '.');
    title(sprintf('%s', day_seg{seg_idx}),'Interpreter','none');
    for lay_idx = lay_idxs
      hold on;
      plot(layers{seg_idx}(ref_idx).gps_time, layers{seg_idx}(lay_idx).twtt_ref, 'r.')
      grid on
      hold off;
    end
    h_axis(2) = gca;
    xlabel('GPS time (sec)');
    ylabel('TWTT ({\mu}s)','interpreter','tex');
    
    figure(3); clf;
    for lay_idx = lay_idxs
      plot(layers{seg_idx}(ref_idx).gps_time, layers{seg_idx}(lay_idx).twtt_ref ...
        - layers{seg_idx}(ref_idx).twtt, plot_modes{lay_idx});
      title(sprintf('%s', day_seg{seg_idx}),'Interpreter','none');
      mean_offset = nanmean(layers{seg_idx}(lay_idx).twtt_ref - layers{seg_idx}(ref_idx).twtt);
      fprintf('\t%.3f\t%.3f\t%.3f', ...
        1e6*mean_offset, ...
        1e6*nanmedian(layers{seg_idx}(lay_idx).twtt_ref - layers{seg_idx}(ref_idx).twtt), ...
        1e6*nanstd(layers{seg_idx}(lay_idx).twtt_ref - layers{seg_idx}(ref_idx).twtt), ...
        1e6*nanmax(abs(layers{seg_idx}(lay_idx).twtt_ref - layers{seg_idx}(ref_idx).twtt - mean_offset)));
      hold on;
      grid on
    end
    hold off;
    h_axis(3) = gca;
    xlabel('GPS time (sec)');
    ylabel('TWTT ({\mu}s)','interpreter','tex');
    fprintf('\n');

    linkaxes(h_axis,'x');
    
    if seg_idx ~= length(layers)
      pause;
    end
    
  end
end

if 0
  %% Example for saving output
  layers_fn = ct_filename_tmp(rmfield(param,'day_seg'),'','surf_layers','surf_layers.mat')
  layers_fn_dir = fileparts(layers_fn);
  if ~exist(layers_fn_dir,'dir')
    mkdir(layers_fn_dir);
  end
  save(layers_fn,'-v7.3','day_seg','layers')
end
