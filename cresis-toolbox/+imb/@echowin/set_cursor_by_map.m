function set_cursor_by_map(obj,lat,lon,type,elev)
% echowin.set_cursor_by_map(obj,lat,lon,type,elev)
%
% Finds the closest point on the echowin's flightline to (lat,lon) and then
% updates the cursor to that position.

map_caused_call = regexp(type,'mapwin');
notify_en = strcmp(type,'mapwin_notify');

if ~obj.busy_mode
  physical_constants;
  [x,y,z] = ct_lla2ecef(lat/180*pi,lon/180*pi,0);
  %[x,y,z] = geodetic2ecef(lat/180*pi,lon/180*pi,0,WGS84.ellipsoid);
  [~,rline] = min((obj.eg.image_ecef(1,:)-x).^2 + (obj.eg.image_ecef(2,:)-y).^2 + (obj.eg.image_ecef(3,:)-z).^2);
  
  % CONVERT range/elev to y
  yaxis_choice = get(obj.left_panel.yaxisPM,'Value');
  surf_range = obj.eg.image_surf_twtt(rline)*c/2;
  slowness_air = 2/c;
  if map_caused_call
    [x,y,z] = ct_lla2ecef(lat/180*pi,lon/180*pi,obj.eg.image_elev(rline));
    %[x,y,z] = geodetic2ecef(lat/180*pi,lon/180*pi,obj.eg.image_elev(rline),WGS84.ellipsoid);
    range = sqrt((obj.eg.image_ecef(1,rline)-x).^2 + (obj.eg.image_ecef(2,rline)-y).^2 + (obj.eg.image_ecef(3,rline)-z).^2);
    if yaxis_choice == 1 % TWTT
      y = range*slowness_air*1e6;
    elseif yaxis_choice == 2 % WGS_84 Elevation
      y = obj.eg.image_elev(rline) - min(range,surf_range) - min(0,range-surf_range)/sqrt(er_ice);
    elseif yaxis_choice == 3 % Range
      y = min(range,surf_range) + min(0,range-surf_range)/sqrt(er_ice);
    elseif yaxis_choice == 4 % Range bin
      y = (range*slowness_air-obj.eg.time(1)) / (obj.eg.time(2)-obj.eg.time(1));
    elseif yaxis_choice == 5 % Surface flat
      y = min(0,surf_range-range) - min(0,range-surf_range)/sqrt(er_ice);
    end
  else
    surf_elev = obj.eg.elev(rline) - surf_range;
    slowness_ice = 2/c*sqrt(er_ice);
    if yaxis_choice == 1 % TWTT
      y = 1e6*(min(obj.eg.image_surf_twtt(rline), (obj.eg.elev(rline)-elev)*slowness_air) ...
        + max(0, surf_elev-elev)*slowness_ice);
    elseif yaxis_choice == 2 % WGS_84 Elevation
      y = elev;
    elseif yaxis_choice == 3 % Range
      y = obj.eg.elev(rline) - elev;
    elseif yaxis_choice == 4 % Range bin
      y = min(obj.eg.image_surf_twtt(rline), (obj.eg.elev(rline)-elev)*slowness_air) ...
        + min(0, surf_elev-elev)*slowness_ice;
      y = (y-obj.eg.time(1)) / (obj.eg.time(2)-obj.eg.time(1));
    elseif yaxis_choice == 5 % Surface flat
      y = surf_elev - elev;
    end
  end
  
  obj.update_cursor(obj.eg.image_xaxis(rline),y,notify_en);
end
