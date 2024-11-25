function load_flightline(obj)
% echowin.load_flightline(obj)
%
% Load flightline from database
%% OPS: Loading flight path from database
if strcmpi(obj.eg.layers.source,'OPS')
  fprintf(' Loading flight path from database (%s)\n', datestr(now,'HH:MM:SS'));
  ops_param = struct('properties',[]);
  ops_param.properties.location = obj.eg.cur_sel.location;
  ops_param.properties.season = obj.eg.cur_sel.season_name;
  ops_param.properties.start_gps_time = obj.eg.start_gps_time(obj.eg.frms(1));
  ops_param.properties.stop_gps_time = obj.eg.stop_gps_time(obj.eg.frms(end));
  [status,data] = opsGetPath(obj.eg.system,ops_param);
  
  obj.eg.map_id = double(data.properties.id);
  obj.eg.map_gps_time = double(data.properties.gps_time);
  obj.eg.map_elev = double(data.properties.elev);
  if obj.eg.map.source == 1
    [lat,lon] = projinv(obj.eg.proj,data.properties.X,data.properties.Y);
    [data.properties.X,data.properties.Y] = google_map.latlon_to_world(lat,lon);
    data.properties.Y = 256-data.properties.Y;
  elseif obj.eg.map.source == 3
    [data.properties.Y,data.properties.X] = projinv(obj.eg.proj,data.properties.X,data.properties.Y);
  end
  obj.eg.map_x = double(data.properties.X)/obj.eg.map.scale;
  obj.eg.map_y = double(data.properties.Y)/obj.eg.map.scale;
  
%% LayerData: Loading flight path from tracks files
else
  fprintf(' Loading flight path from csarp_support/tracks files (%s)\n', datestr(now,'HH:MM:SS'));
  obj.eg.map_id = [];
  obj.eg.map_gps_time = [];
  obj.eg.map_elev = [];
  obj.eg.map_x = [];
  obj.eg.map_y = [];
  for idx = 1:length(obj.eg.frms)
    Nx = length(obj.undo_stack.user_data.layer_info(obj.eg.frms(idx)).gps_time);
    obj.eg.map_gps_time(end+1:end+Nx) ...
      = double(obj.undo_stack.user_data.layer_info(obj.eg.frms(idx)).gps_time);
    obj.eg.map_elev(end+1:end+Nx) ...
      = double(obj.undo_stack.user_data.layer_info(obj.eg.frms(idx)).elev);
    if obj.eg.map.source == 1
      [X,Y] = google_map.latlon_to_world(obj.undo_stack.user_data.layer_info(obj.eg.frms(idx)).lat,obj.undo_stack.user_data.layer_info(obj.eg.frms(idx)).lon);
      Y = 256-Y;
    elseif obj.eg.map.source == 3
      X = obj.undo_stack.user_data.layer_info(obj.eg.frms(idx)).lon;
      Y = obj.undo_stack.user_data.layer_info(obj.eg.frms(idx)).lat;
    else
      [X,Y] = projfwd(obj.eg.proj,obj.undo_stack.user_data.layer_info(obj.eg.frms(idx)).lat,obj.undo_stack.user_data.layer_info(obj.eg.frms(idx)).lon);
    end
    obj.eg.map_x(end+1:end+Nx) = double(X)/obj.eg.map.scale;
    obj.eg.map_y(end+1:end+Nx) = double(Y)/obj.eg.map.scale;
  end
  
  % Get the unique point path ids for layerData and save it in the
  % point_path_id field of the undo_stack
  LDpoint_path_id=[];
  for frm = obj.eg.frms(1):obj.eg.frms(end)
    k = find(obj.undo_stack.user_data.frame==frm);
    points = (k(1):k(end));
    LDpoint_path_id = cat(2,LDpoint_path_id,points);
  end
  obj.eg.map_id = LDpoint_path_id; %contains the unquie point path ids.
end
