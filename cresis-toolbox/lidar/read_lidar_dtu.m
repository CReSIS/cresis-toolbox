function [lidar] = read_lidar_dtu(fns, param)
% [lidar] = read_lidar_dtu(fns, param)
%
% Reads the LIDAR data take by the Twin Otter for the hfrds2 radar
% param = struct that controls reading of file(s)
%   .season_name: season name such as 2016_Greenland_TOdtu
%
% lidar = struct of position and LIDAR data, each N x 1 vectors
%   where N is the number of records in the file(s). The fields are:
%  .gps_time = GPS time in decimal hours (UTC)
%  .lat = latitude (deg)
%  .lon = longitude (deg)
%  .surface = WGS-84 surface elevation (m)
%
% See also: read_lidar_atm, read_lidar_awi, read_lidar_dtu,
% get_filenames_lidar

%% Read Lidar Data from the TOdtu data
for fn_idx = 1:length(fns)
  fn = fns{fn_idx};
  
  [~,fn_name] = fileparts(fn);
  % Expecting file name format: 312_t4_1x1 where "312" represents the day
  % of year
  day = str2double(fn_name(1:find(fn_name=='_',1)-1));
  
  year = str2double(param.season_name(1:find(param.season_name=='_',1)-1));
  
  %  The  *.ver files only contain the central scan point, format is:
  % dec.hour(UTC) latitude longitude  surface_elevation #points/swath  GPS.height  range
  %  14.3257462  69.185200  -49.753230   29.75  30  480.83  454.23
  lidar_param = [];
  lidar_param.format_str = '%f%f%f%f%f%f%f';
  lidar_param.types = {'hour','lat_deg','lon_deg','surface_m','num_points','elev_m','range_m'};
  lidar_param.textscan = {};
  lidar_param.headerlines = 0;
  lidar_param.time_reference = 'utc';
  lidar_param.year = year;
  lidar_param.day = day;

  if fn_idx == 1
    lidar = read_gps_general_ascii(fn,lidar_param);
  else
    tmp_lidar = read_gps_general_ascii(fn,lidar_param);
    fieldnames_list = fieldnames(lidar);
    for field_idx = 1:length(fieldnames_list)
      fieldname = fieldnames_list{field_idx};
      lidar.(fieldname)(end+(1:length(tmp_lidar.(fieldname)))) = tmp_lidar.(fieldname);
    end
  end

end
