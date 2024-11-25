function load_layers(obj)
% echowin.load_layers(obj)
%
% Load layer information from database and update layer plot handles

%% Determine GPS time domain for layers to load
dx = obj.eg.gps_time(2)-obj.eg.gps_time(1);
min_gps_time = obj.eg.gps_time(1);
max_gps_time = obj.eg.gps_time(end);
if obj.eg.frms(1) == 1
  % First frame in segment so adjust beginning to make sure all layer points
  % will be displayed.
  min_gps_time = obj.eg.start_gps_time(1)-dx;
end
if obj.eg.frms(end) == length(obj.eg.stop_gps_time)
  % Last frame of segment so adjust end to make sure all layer points will
  % be displayed.
  max_gps_time = obj.eg.stop_gps_time(end)+dx;
end

if strcmpi(obj.eg.layers.source,'OPS')
  %% OPS: Load layer points from database
  fprintf(' Loading layer points from database (%s)\n',datestr(now,'HH:MM:SS'));
  ops_param = struct('properties',[]);
  ops_param.properties.location = obj.eg.cur_sel.location;
  ops_param.properties.season = obj.eg.cur_sel.season_name;
  ops_param.properties.segment_id = obj.eg.cur_sel.seg_id;
  ops_param.properties.start_gps_time = min_gps_time;
  ops_param.properties.stop_gps_time = max_gps_time;
  ops_param.properties.lyr_name = obj.eg.layers.lyr_name;
  % query database
  [status,data] = opsGetLayerPoints(obj.eg.system,ops_param);
  
  %% OPS: Preallocate layer arrays
  obj.eg.layers.y = {};
  obj.eg.layers.qual = {};
  obj.eg.layers.type = {};
  obj.eg.layers.x = double(obj.eg.map_gps_time); % gps-time
  for idx = 1:length(obj.eg.layers.lyr_name)
    obj.eg.layers.y{idx} = nan(size(obj.eg.map_id)); % twtt
    obj.eg.layers.qual{idx} = nan(size(obj.eg.map_id)); % integer 1-3
    obj.eg.layers.type{idx} = nan(size(obj.eg.map_id)); % this is either 1 (manual) or 2 (auto)
  end
  
  %% OPS: Fill layer arrays with points from database
  for idx = 1:length(data.properties.point_path_id)
    layer_idx = obj.eg.layers.lyr_id == data.properties.lyr_id(idx);
    point_path_idx = obj.eg.map_id == data.properties.point_path_id(idx);
    obj.eg.layers.y{layer_idx}(point_path_idx) = data.properties.twtt(idx);
    obj.eg.layers.qual{layer_idx}(point_path_idx) = data.properties.quality(idx);
    obj.eg.layers.type{layer_idx}(point_path_idx) = data.properties.type(idx);
  end
  
  %% OPS: Update echogram surface if there are enough good points from OPS
  % Find good surface points
  if ~any(obj.eg.layers.lyr_id==1)
    error('standard:surface must be added in the "Layers" preference window before loading echograms.');
  end
  good_mask = ~isnan(obj.eg.layers.y{obj.eg.layers.lyr_id==1});
  if sum(good_mask) > 2
    % There are surface layer points in the database, overwrite the surface
    % with these
    obj.eg.surf_twtt = interp1(obj.eg.map_gps_time(good_mask),obj.eg.layers.y{obj.eg.layers.lyr_id==1}(good_mask),obj.eg.gps_time);
    obj.eg.surf_twtt = interp_finite(obj.eg.surf_twtt,0);
  end
  
elseif strcmpi(obj.eg.layers.source,'layerdata')
  %% LayerData: Load layer points from layerdata
  
  %% LayerData: Preallocate layer arrays
  fprintf(' Loading layer points from layer data files (%s)\n',datestr(now));
  obj.eg.layers.x = [];
  obj.eg.layers.y = {};
  obj.eg.layers.qual = {};
  obj.eg.layers.type = {};
  for idx = 1:length(obj.eg.layers.lyr_id)
    obj.eg.layers.y{idx} = []; % twtt
    obj.eg.layers.qual{idx} = []; % integer 1-3
    obj.eg.layers.type{idx} = []; % this is either 1 (manual) or 2 (auto)
  end
  %% LayerData: Load gps_time, quality, twtt and type of layers from undo_stack
  for frm = obj.eg.frms(1):obj.eg.frms(end);
    gps_time = obj.undo_stack.user_data.layer_info(frm).gps_time;
    obj.eg.layers.x = cat(2,obj.eg.layers.x,gps_time); % concatenates the layer GPS time
    
    for idx=1:length(obj.eg.layers.lyr_name)
      lay_idx = find(obj.eg.layers.lyr_id(idx) == obj.undo_stack.user_data.layer_info(frm).id);
      if ~isempty(lay_idx)
        qual = obj.undo_stack.user_data.layer_info(frm).quality(lay_idx,:);
        obj.eg.layers.qual{idx}(end+(1:length(qual))) = qual; % quality (integer 1-3)
        twtt = obj.undo_stack.user_data.layer_info(frm).twtt(lay_idx,:);
        obj.eg.layers.y{idx}(end+(1:length(twtt))) = twtt; % twtt
        type = obj.undo_stack.user_data.layer_info(frm).type(lay_idx,:);
        obj.eg.layers.type{idx}(end+(1:length(type))) = type; % this is either 1 (manual) or 2 (auto)
      else
        % Layer does not exist in this file, set to defaults
        obj.eg.layers.qual{idx}(end+(1:length(gps_time))) = 1; % quality (integer 1-3)
        obj.eg.layers.y{idx}(end+(1:length(gps_time))) = nan; % twtt
        obj.eg.layers.type{idx}(end+(1:length(gps_time))) = 2; % this is either 1 (manual) or 2 (auto)
      end
    end
  end
  
  %% LayerData: Update echogram surface if there are enough good points
  if ~isempty(obj.eg.layers.lyr_id)
    if isempty(obj.eg.layers.surf_id) || all(obj.eg.layers.surf_id ~= obj.eg.layers.lyr_id)
      % Surface ID not set yet, assume it is the minimum
      obj.eg.layers.surf_id = min(obj.eg.layers.lyr_id);
    end
    % good_mask: logical vector with 1 where the twtt of the surface is a number and 0
    % when NaN.
    good_mask = ~isnan(obj.eg.layers.y{obj.eg.layers.lyr_id==obj.eg.layers.surf_id});
    if sum(good_mask) > 2
      obj.eg.surf_twtt = interp1(obj.eg.layers.x(good_mask),obj.eg.layers.y{obj.eg.layers.lyr_id==obj.eg.layers.surf_id}(good_mask),obj.eg.gps_time);
      obj.eg.surf_twtt = interp_finite(obj.eg.surf_twtt,0);
    end
  end
end
