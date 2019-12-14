function search_callback(obj,src,event)
% mapwin.search_callback(obj,src,event)

% return focus to figure
try
  warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
  javaFrame = get(obj.h_fig,'JavaFrame');
  javaFrame.getAxisComponent.requestFocus;
catch
  fprintf('JavaFrame figure property not available, click inside echogram window after pressing a listbox button before using key shortcuts\n');
end

if strcmpi(get(obj.map_panel.h_axes,'Visible'),'off')
  % No map selected, so just return
  return;
end

% Update map selection plot
if obj.map.fline_source==1
  % layerdata flineslines selected
  % -----------------------------------------------------------------------
  
  % Find the first frame that matches the search string
  frm_id = get(obj.top_panel.searchTB,'String');
  frm_id(regexp(frm_id,'_')) = [];
  % Add default segment number
  if length(frm_id) < 10
    frm_id(9:10) = '01';
  end
  % Add default frame number
  if length(frm_id) < 13
    frm_id(11:13) = '001';
  end
  frm_id = str2num(frm_id);
  
  % Get a logical mask indicating all indices that match the frame
  frm_mask = obj.layerdata.frms == frm_id;
  idx = find(frm_mask,1);
  if isempty(idx)
    % No frames match, so just return
    return;
  end
  frm_id = obj.layerdata.frms(idx);
  season_idx = obj.layerdata.season_idx(idx);
  season_name = obj.cur_map_pref_settings.seasons{season_idx};
  [sys,season_name_short] = strtok(season_name,'_');
  season_name_short = season_name_short(2:end);

  % Generate search string
  frm_id = num2str(frm_id);
  day = frm_id(1:8);
  seg = frm_id(9:10);
  frame = frm_id(11:13);
  frame_name = strcat(day,'_',seg,'_',frame);

  if strcmpi(obj.cur_map_pref_settings.layer_source,'layerdata')
    % Set data properties
    data = struct('properties',[]);
    data.properties.frame = frame_name;
    data.properties.season = season_name;
    data.properties.segment_id = str2num(frm_id(1:10));
    data.properties.X = obj.layerdata.x(frm_mask);
    data.properties.Y = obj.layerdata.y(frm_mask);
    new_xdata = data.properties.X;
    new_ydata = data.properties.Y;    
  else
    % Get segment id from opsGetFrameSearch
    frame_search_param = struct('properties',[]);
    frame_search_param.properties.search_str = frame_name;
    frame_search_param.properties.location = obj.cur_map_pref_settings.map_zone;
    frame_search_param.properties.season = season_name_short;
    [frm_status,frm_data] = opsGetFrameSearch(sys,frame_search_param);
    if frm_status == 2 || ~frm_status
      % result not found; warning already printed to console, so just exit
      return;
    end
    
    % Set data properties
    data = struct('properties',[]);
    data.properties.frame = frame_name;
    data.properties.season = frm_data.properties.season;
    data.properties.segment_id = frm_data.properties.segment_id;
    data.properties.X = obj.layerdata.x(frm_mask);
    data.properties.Y = obj.layerdata.y(frm_mask);
    new_xdata = data.properties.X;
    new_ydata = data.properties.Y;
  end

else
  % OPS flineslines selected
  % -----------------------------------------------------------------------
  sys = obj.cur_map_pref_settings.system;
  ops_param.properties.search_str = get(obj.top_panel.searchTB,'String');
  ops_param.properties.season = obj.cur_map_pref_settings.seasons;
  ops_param.properties.location = obj.cur_map_pref_settings.map_zone;
  
  [status,data] = opsGetFrameSearch(sys,ops_param);
  if status == 2 || ~status
    % result not found; warning already printed to console, so just exit
    return;
  end
  
  if obj.map.source == 1
    [lat,lon] = projinv(obj.map.proj,data.properties.X,data.properties.Y);
    [data.properties.X,data.properties.Y] = google_map.latlon_to_world(lat,lon);
    data.properties.Y = 256-data.properties.Y;
  end
  new_xdata = data.properties.X/obj.map.scale;
  new_ydata = data.properties.Y/obj.map.scale;
end
  
% Record current frame selection
obj.map.sel.frame_name = data.properties.frame;
obj.map.sel.season_name = data.properties.season;
obj.map.sel.segment_id = data.properties.segment_id;
obj.map.sel.radar_name = sys;

% Update map selection plot
set(obj.map_panel.h_cur_sel,{'XData','YData'},{new_xdata,new_ydata});

% Update map limits if necessary
[changed,pos] = obj.compute_new_map_limits(new_xdata,new_ydata);
if changed
  obj.query_redraw_map(pos(1),pos(2),pos(3),pos(4));
end

% Change map title to the currently selected frame
set(obj.top_panel.flightLabel,'String',obj.map.sel.frame_name);
