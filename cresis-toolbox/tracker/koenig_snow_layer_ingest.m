% script koenig_snow_layer_ingest
%
% Script for reading in Koenig's snow layer picks and synchronizing them to
% the snow radar data.
%
% Author: John Paden

% file base	trace index	trace lat	trace lon	trace time	trace time res	L1 pick	L1 pick depth	L1 water eq pick	L1 pick depth hl	L1 water eq pick hl	L2 pick	L2 pick depth	L2 water eq pick	L2 pick depth hl	L2 water eq pick hl	L3 pick	L3 pick depth	L3 water eq pick	L3 pick depth hl	L3 water eq pick hl	L4 pick	L4 pick depth	L4 water eq pick	L4 pick depth hl	L4 water eq pick hl	L5 pick	L5 pick depth	L5 water eq pick	L5 pick depth hl	L5 water eq pick hl	L6 pick	L6 pick depth	L6 water eq pick	L6 pick depth hl	L6 water eq pick hl	L7 pick	L7 pick depth	L7 water eq pick	L7 pick depth hl	L7 water eq pick hl	L8 pick	L8 pick depth	L8 water eq pick	L8 pick depth hl	L8 water eq pick hl	L9 pick	L9 pick depth	L9 water eq pick	L9 pick depth hl	L9 water eq pick hl	L10 pick	L10 pick depth	L10 water eq pick	L10 pick depth hl	L10 water eq pick hl	L11 pick	L11 pick depth	L11 water eq pick	L11 pick depth hl	L11 water eq pick hl	L12 pick	L12 pick depth	L12 water eq pick	L12 pick depth hl	L12 water eq pick hl	L13 pick	L13 pick depth	L13 water eq pick	L13 pick depth hl	L13 water eq pick hl	L14 pick	L14 pick depth	L14 water eq pick	L14 pick depth hl	L14 water eq pick hl	L15 pick	L15 pick depth	L15 water eq pick	L15 pick depth hl	L15 water eq pick hl	L16 pick	L16 pick depth	L16 water eq pick	L16 pick depth hl	L16 water eq pick hl	L17 pick	L17 pick depth	L17 water eq pick	L17 pick depth hl	L17 water eq pick hl	L18 pick	L18 pick depth	L18 water eq pick	L18 pick depth hl	L18 water eq pick hl	L19 pick	L19 pick depth	L19 water eq pick	L19 pick depth hl	L19 water eq pick hl	L20 pick	L20 pick depth	L20 water eq pick	L20 pick depth hl	L20 water eq pick hl	L21 pick	L21 pick depth	L21 water eq pick	L21 pick depth hl	L21 water eq pick hl	L22 pick	L22 pick depth	L22 water eq pick	L22 pick depth hl	L22 water eq pick hl	L23 pick	L23 pick depth	L23 water eq pick	L23 pick depth hl	L23 water eq pick hl	L24 pick	L24 pick depth	L24 water eq pick	L24 pick depth hl	L24 water eq pick hl	L25 pick	L25 pick depth	L25 water eq pick	L25 pick depth hl	L25 water eq pick hl	L26 pick	L26 pick depth	L26 water eq pick	L26 pick depth hl	L26 water eq pick hl	L27 pick	L27 pick depth	L27 water eq pick	L27 pick depth hl	L27 water eq pick hl	L28 pick	L28 pick depth	L28 water eq pick	L28 pick depth hl	L28 water eq pick hl	L29 pick	L29 pick depth	L29 water eq pick	L29 pick depth hl	L29 water eq pick hl	L30 pick	L30 pick depth	L30 water eq pick	L30 pick depth hl	L30 water eq pick hl
% layers_20120314_01_dec01	2	82.669345	-55.54293	1331733559	2.88567E-10	5	0.14	0.06	0.14	0.06	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1

% 2009: gps_time is bad
% param_fn = ct_filename_param('snow_param_2009_Greenland_P3.xls');
% fns = get_filenames('E:\tmp\layers\Koenig_Snow_Radar\output_mapdata_2009_v32','mapdata','','.txt');

% 2010: gps_time is bad
% param_fn = ct_filename_param('snow_param_2010_Greenland_DC8.xls');
% fns = get_filenames('E:\tmp\layers\Koenig_Snow_Radar\output_mapdata_2010_v32','mapdata','','.txt');
% param_fn = ct_filename_param('snow_param_2010_Greenland_P3.xls');
% fns = get_filenames('E:\tmp\layers\Koenig_Snow_Radar\output_mapdata_2010_v32','mapdata','','.txt');

% 2011: gps_time is good
% param_fn = ct_filename_param('snow_param_2011_Greenland_P3.xls');
% fns = get_filenames('E:\tmp\layers\Koenig_Snow_Radar\output_mapdata_2011_v32','mapdata','','.txt');

% 2012: gps_time is good
param_fn = ct_filename_param('snow_param_2012_Greenland_P3.xls');
if ispc
  fns = get_filenames('E:\tmp\layers\Koenig_Snow_Radar\output_mapdata_2012','mapdata','','.txt');
else
  fns = get_filenames('/cresis/snfs1/dataproducts/metadata/koenig_snow_layers/output_mapdata_2012','mapdata','','.txt');
end

%% Load Koenig Data
physical_constants;
surf_filter_len = 51; % Range lines to average surf twtt (must be odd integer)
num_layers = 30;
layer_data = {};
for fn_idx = 1:length(fns)
  fn = fns{fn_idx};
  fprintf('Reading %s\n', fn);
  fid = fopen(fn,'r');
  
  % 1: file base: layers_20090331_dec03
  % 2: trace index: 886
  % 3: trace lat: 83.329896
  % 4: trace lon: -57.521430
  % 5: trace time: 44.81 (2009-2010 with unknown units)
  %    trace time: 1e9 (2011-2012 with ANSI C units, seconds since Jan 1, 1970)
  % 6: trace time res: 0.0000000001171607
  % 7: L1 pick: 3
  % 8: L1 pick depth: 0.03
  % 9: L1 water eq pick: 0.01
  % 10: L1 pick depth hl: 0.03
  % 11: L1 water eq pick hl: 0.01
  % ...
  % 156: L30 water eq pick hl: 0.01
  textscan_format = '%s %f %f %f %f %f';
  textscan_format = [textscan_format repmat(' %f %f %f %f %f',[1 num_layers])];
  raw_layer_data = textscan(fid, textscan_format);
  
  fclose(fid);
  
  for idx=1:length(raw_layer_data)-1
    raw_layer_data{idx} = raw_layer_data{idx}(1:numel(raw_layer_data{end}));
  end
  
  if fn_idx == 1
    layer_data = raw_layer_data;
  else
    for idx=1:length(raw_layer_data)
      layer_data{idx} = [layer_data{idx}; raw_layer_data{idx}];
    end
  end
end

%% Get unique days
days = cell(size(layer_data{1}));
for idx = 1:length(layer_data{1})
  if length(layer_data{1}{idx}) < 15
    days{idx} = 'zzzzzzzz';
  else
    days{idx} = layer_data{1}{idx}(8:15);
  end
end

days{end+1} = 'zzzzzzzz';
[days,~,map_idxs] = unique(days);
map_idxs = map_idxs(1:end-1);

%% Extract other fields
trace_idx = {};
lat = {};
lon = {};
gps_time = {};
dt = {};
layers = {};
for day_idx = 1:length(days)-1
  trace_idx{day_idx} = layer_data{2}(map_idxs==day_idx);
  lat{day_idx} = layer_data{3}(map_idxs==day_idx);
  lon{day_idx} = layer_data{4}(map_idxs==day_idx);
  gps_time{day_idx} = layer_data{5}(map_idxs==day_idx);
  dt{day_idx} = layer_data{6}(map_idxs==day_idx);
  for layer_idx = 1:num_layers
    layers{day_idx,layer_idx} = layer_data{7 + (layer_idx-1)*5}(map_idxs==day_idx);
    layers{day_idx,layer_idx}(layers{day_idx,layer_idx}==-1) = NaN;
  end
  
  if 1
    fprintf('%d\t%s', day_idx, days{day_idx})
    fprintf('\t%.14g', unique(dt{day_idx}))
    fprintf('\n');
  end
end

if 1
  for day_idx = 1:length(days)-1
    figure(day_idx); clf;
    plot(gps_time{day_idx})
    set(day_idx,'WindowStyle','docked')
  end
  for day_idx = 1:length(days)-1
    figure(100 + day_idx); clf;
    plot(lon{day_idx},lat{day_idx},'.')
    set(100+day_idx,'WindowStyle','docked')
  end
  for day_idx = 1:length(days)-1
    figure(200 + day_idx); clf;
    for layer_idx = 1:num_layers
      plot(layers{day_idx,layer_idx},'.')
      hold on;
    end
    set(200+day_idx,'WindowStyle','docked')
  end
end

%% Process Each Day
enable_visible_plot = false;
enable_debug_plot = false;
if enable_debug_plot
  h_fig = get_figures(2,enable_visible_plot);
end
params = read_param_xls(param_fn);
for day_idx=13:13 %1:length(days)
  
  fprintf('%s\n','='*ones(1,72));
  fprintf('%s\n', days{day_idx});
  fprintf('%s\n','='*ones(1,72));
  
  param_idxs = strmatch(days{day_idx},{params.day_seg});
  
  %% Process: Process Each Segment
  for param_idx = param_idxs(:).'
    param = params(param_idx);
    
    layer_params = [];
    layer_params.name = 'surface';
    if 0
      layer_params.source = 'echogram';
      layer_params.echogram_source = 'CSARP_post/qlook';
    else
      layer_params.source = 'layerdata';
    end
    surf = opsLoadLayers(param,layer_params);
    surf.twtt = interp_finite(surf.twtt);
    
    %% Process:Segment Filter Surf Data
    surf.twtt_filtered = surf.twtt - surf.elev/(c/2);
    surf.twtt_filtered = fir_dec(surf.twtt_filtered,ones(1,surf_filter_len)/surf_filter_len,1);
    surf.twtt_filtered = surf.twtt_filtered + surf.elev/(c/2);
    
    %% Process:Segment Sync Layers
    master = [];
    master.GPS_time = surf.gps_time;
    master.Latitude = surf.lat;
    master.Longitude = surf.lon;
    master.Elevation = surf.elev;
    ops_layer = [];
    ops_layer{1}.gps_time = gps_time{day_idx};
    % Treat all points as auto
    ops_layer{1}.type = 2*ones(size(gps_time{day_idx}));
    % Treat all points as quality good
    ops_layer{1}.quality = ones(size(gps_time{day_idx}));
    for lay_idx = 1:num_layers
      ops_layer{1}.twtt = layers{day_idx,lay_idx};
      % Convert from range bins to twtt
      ops_layer{1}.twtt = ops_layer{1}.twtt .* dt{day_idx};
      lay = opsInterpLayersToMasterGPSTime(master,ops_layer,[300 60]);
      new_layer_twtt = lay.layerData{1}.value{2}.data;
      if lay_idx == 1
        surf_ref = new_layer_twtt;
        % Ice surface
        % Manual points
        master.layerData{lay_idx}.value{1}.data = nan(size(master.GPS_time));
        master.layerData{lay_idx}.value{1}.data(surf.type == 1) ...
          = surf.twtt(surf.type==1);
        % Auto points
        master.layerData{lay_idx}.value{2}.data = surf.twtt_filtered;
        master.layerData{lay_idx}.name = 'surface';
        master.layerData{lay_idx}.quality = ones(size(master.GPS_time));
      end
      if lay_idx > 1
        master.layerData{lay_idx}.value{1}.data = nan(size(master.GPS_time));
        master.layerData{lay_idx}.value{2}.data = surf.twtt_filtered + new_layer_twtt - surf_ref;
        master.layerData{lay_idx}.name = sprintf('Koenig_%d', lay_idx);
        master.layerData{lay_idx}.quality = ones(size(master.GPS_time));
      end
    end
    
    %% Process:Segment Save Output
    copy_param = [];
    copy_param.copy_method = 'overwrite';
    copy_param.gaps_fill.method = 'preserve_gaps';
    copy_param.layer_source.existence_check = false;
    copy_param.layer_source.source = 'custom';
    copy_param.layer_dest.source = 'layerdata';
    copy_param.layer_dest.layerdata_source = 'layer_koenig';
    copy_param.layer_dest.existence_check = false;
    
    copy_param.layer_source.gps_time = {};
    copy_param.layer_source.quality = {};
    copy_param.layer_source.twtt = {};
    copy_param.layer_source.type = {};
    copy_param.layer_dest.name = {};
    layer_str = '';
    deepest_layer_with_points = NaN;
    if enable_debug_plot
      clf(h_fig(1));
      h_axes(1) = axes('parent',h_fig(1));
      clf(h_fig(2));
      h_axes(2) = axes('parent',h_fig(2));
    end
    for lay_idx = 1:num_layers-1
      copy_param.layer_source.gps_time{end+1} = surf.gps_time;
      copy_param.layer_source.twtt{end+1} = master.layerData{lay_idx}.value{2}.data;
      if any(~isnan(master.layerData{lay_idx}.value{2}.data))
        deepest_layer_with_points = lay_idx;
        layer_str = [layer_str sprintf(' %d', lay_idx)];
      end
      if lay_idx == 1
        copy_param.layer_source.quality{end+1} = surf.quality;
        copy_param.layer_source.type{end+1} = surf.type;
        copy_param.layer_dest.name{end+1} = sprintf('surface', lay_idx);
      else
        copy_param.layer_source.quality{end+1} = ones(size(surf.quality));
        copy_param.layer_source.type{end+1} = 2*ones(size(surf.type));
        copy_param.layer_dest.name{end+1} = sprintf('Koenig_%d', lay_idx);
      end
      if enable_debug_plot
        plot(copy_param.layer_source.gps_time{end}, copy_param.layer_source.twtt{end}, 'parent', h_axes(1));
        hold(h_axes(1), 'on');
        xlabel(h_axes(1), 'GPS time (ANSI-C sec since Jan 1, 1970)');
        ylabel(h_axes(1), 'Two way travel time (sec)');
        
        plot(copy_param.layer_source.gps_time{end}, surf.elev - copy_param.layer_source.twtt{end}*c/2, 'parent', h_axes(2));
        hold(h_axes(2), 'on');
        xlabel(h_axes(2), 'GPS time (ANSI-C sec since Jan 1, 1970)');
        ylabel(h_axes(2), 'Elevation (m, WGS-84)');
      end
    end
    
    fprintf('opsCopyLayers %s (%s)\n', param.day_seg, datestr(now));
    fprintf('  Layers:%s\n', layer_str);
    fprintf('  Deepest\t%d\n', deepest_layer_with_points);
    
    if enable_visible_plot
      % Bring plots to front
      for h_fig_idx = 1:length(h_fig)
        figure(h_fig(h_fig_idx));
      end
      % Enter debug mode
      keyboard
    end
    
    opsCopyLayers(param,copy_param);
    
  end
end

return

mdata = load_L1B('X:\ct_data\snow\2011_Greenland_P3\CSARP_post\CSARP_qlook\20110329_01\Data_20110329_01_239.mat');
lay = load('X:\ct_data\snow\2011_Greenland_P3\CSARP_layerData\20110329_01\Data_20110329_01_239.mat');
figure(1000); clf;
imagesc([],mdata.Time,lp(mdata.Data))
hold on;
for idx = 1:length(lay.layerData)
  plot(lay.layerData{idx}.value{2}.data);
end

mdata = load_L1B('X:\ct_data\snow\2011_Greenland_P3\CSARP_post\CSARP_qlook\20110329_01\Data_20110329_01_240.mat');
lay = load('X:\ct_data\snow\2011_Greenland_P3\CSARP_layerData\20110329_01\Data_20110329_01_240.mat');
figure(1000); clf;
imagesc([],mdata.Time,lp(mdata.Data))
hold on;
for idx = 1:length(lay.layerData)
  plot(lay.layerData{idx}.value{2}.data);
end
