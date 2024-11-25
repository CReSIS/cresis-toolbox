function [rline] = update_cursor(obj,x,y,notify_en)
% echowin.update_cursor(obj,x,y,notify_en)

% Find the range line in the image closest to the x-value "x"
[~,rline] = min(abs(obj.eg.image_xaxis-x));

% Update cursor with this range line (will be plotted by mapwin)
obj.cursor.lat = obj.eg.image_lat(rline);
obj.cursor.lon = obj.eg.image_lon(rline);

% Get A-scope (will be used by mapwin to pass to ascopewin)
obj.cursor.gps_time = obj.eg.image_gps_time(rline);
[~,orig_rline] = min(abs(obj.eg.gps_time-obj.cursor.gps_time));
obj.cursor.data = obj.eg.data(:,orig_rline);
obj.cursor.twtt = obj.eg.time;
obj.cursor.surf_twtt = obj.eg.surf_twtt(rline);

% Update the cursor plot
set(obj.cursor.h,{'XData','YData'},{obj.eg.image_xaxis(rline)*ones(1,3),...
  [obj.eg.image_yaxis(1) y obj.eg.image_yaxis(end)]});
set(obj.cursor.h,'visible','on');

% Update status text with cursor information
str = obj.status_text_cursor();
obj.status_text_set(str,'replace');

if notify_en
  physical_constants;
  
  % Determine clutter locations
  ecef = obj.eg.image_ecef(:,rline);
  y_vec = obj.eg.image_y_vec(:,rline);
  z_vec = obj.eg.image_z_vec(:,rline);
  
  z_offset = obj.cursor.surf_twtt*c/2;
  
  vel_air = c/2;
  slowness_air = 1/vel_air;
  vel_ice = c/(2*sqrt(er_ice));
  slowness_ice = 1/vel_ice;
  
  % Convert y-axis range units
  yaxis_choice = get(obj.left_panel.yaxisPM,'Value');
  
  if yaxis_choice == 1 % TWTT
    obj.cursor.target_twtt = y*1e-6;
    
  elseif yaxis_choice == 2 % WGS_84 Elevation
    if (obj.eg.image_elev(rline) - y) < obj.eg.image_surf_twtt(rline)*vel_air % above surface
      obj.cursor.target_twtt = (obj.eg.image_elev(rline)-y)*slowness_air;
    else
      obj.cursor.target_twtt = obj.eg.image_surf_twtt(rline) + (obj.eg.image_elev(rline) - y - obj.eg.image_surf_twtt(rline)*vel_air)*slowness_ice;
    end
    
  elseif yaxis_choice == 3 % Depth/Range
    if y < obj.eg.image_surf_twtt(rline)*vel_air % above surface
      obj.cursor.target_twtt = y*slowness_air;
    else
      obj.cursor.target_twtt = obj.eg.image_surf_twtt(rline) + (y - obj.eg.image_surf_twtt(rline)*vel_air)*slowness_ice;
    end
    
  elseif yaxis_choice == 4 % Range bin
    obj.cursor.target_twtt = obj.eg.time(1) + (y-1)*(obj.eg.time(2)-obj.eg.time(1));
    
  elseif yaxis_choice == 5 % Surface flat
    if y > 0
      obj.cursor.target_twtt = obj.eg.image_surf_twtt(rline) + y*slowness_ice; % Below ice
    else
      obj.cursor.target_twtt = obj.eg.image_surf_twtt(rline) + y*slowness_air; % Above ice
    end
  end
  
  obj.cursor.target_elev = obj.eg.image_elev(rline) ...
    - min(obj.eg.image_surf_twtt(rline), obj.cursor.target_twtt)*vel_air ...
    - max(0, (obj.cursor.target_twtt-obj.eg.image_surf_twtt(rline)))*vel_ice;
  
  cross_track = sqrt((obj.cursor.target_twtt*vel_air).^2 - z_offset.^2);
  if ~isreal(cross_track)
    cross_track = NaN;
  end
  
  ecef = ecef - z_vec*z_offset;
  ecef = [ecef + y_vec*cross_track, ecef - y_vec*cross_track];
  
  [obj.cursor.clutter_lat obj.cursor.clutter_lon] = ct_ecef2lla(ecef(1,:),ecef(2,:),ecef(3,:));
  %[obj.cursor.clutter_lat obj.cursor.clutter_lon] = ecef2geodetic(ecef(1,:),ecef(2,:),ecef(3,:),WGS84.ellipsoid);
  obj.cursor.clutter_lat = obj.cursor.clutter_lat * 180/pi;
  obj.cursor.clutter_lon = obj.cursor.clutter_lon * 180/pi;
  
  % Notify the map to redraw all cursors based on this cursor's location
  notify(obj,'update_cursors');
else
  obj.cursor.target_twtt = NaN;
  obj.cursor.target_elev = NaN;
  obj.cursor.clutter_lat = [];
  obj.cursor.clutter_lon = [];
end

