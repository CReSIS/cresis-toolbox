function lidar_fns = get_filenames_lidar(param,lidar_source,gps_time)
% lidar_fns = get_filenames_lidar(param,lidar_source,gps_time)
%
% Gets a cell array of absolute filename strings for LIDAR files. Works
% with AWI LIDAR and DTU LIDAR data. Also works with generic LAS files. For
% LAS files, see read_lidar_las.m to see how these files must be setup for
% this to work.
%
% Input:
%   param: structure controlling which LIDAR files are loaded
%     .season_name: string containing the season that the data is from
%   gps_time: start and stop times in ANSI-C time (seconds since Jan 1,
%     1970). Used to determine which files to get. Note that all files in a
%     day will be returned even if a single gps_time is given. The
%     start/stop is only necessary for crossing date boundaries.
%   lidar_source: string containing 'awi' or 'dtu'
%
% Output:
%   lidar_fns: (cell of strings) lidar filenames (same as get_filenames output)
%
% Examples:
%   lidar_fns = get_filenames_lidar(struct('season_name','2015_Greenland_Polar6'),'awi',datenum_to_epoch(datenum('20150913','YYYYmmDD')))
%
% Author: John Paden
%
% See also: get_filenames.m, get_filenames_atm.m

if ~isfield(param,'data_support_path') || isempty(param.data_support_path)
  global gRadar;
  data_support_path = gRadar.data_support_path;
else
  data_support_path = param.data_support_path;
end
  
in_base_path = fullfile(data_support_path,sprintf('LIDAR_%s',upper(lidar_source)),param.season_name);

if strcmpi(lidar_source,'awi')
  [year month day] = datevec(epoch_to_datenum(gps_time(1)));
  day_of_year_start = datenum(year,month,day) - datenum(year,0,0);
  [year month day] = datevec(epoch_to_datenum(gps_time(end)));
  day_of_year_end = datenum(year,month,day) - datenum(year,0,0);
  lidar_fns = {};
  for day_of_year = day_of_year_start:day_of_year_end
    new_fns = get_filenames(in_base_path, sprintf('ALS_L1B_%sT',datestr(datenum(year,0,day_of_year),'YYYYmmDD')), '', '.nc');
    lidar_fns(end+(1:length(new_fns)),1) = new_fns;
  end

elseif strcmpi(lidar_source,'awi_L2B')
  [year month day] = datevec(epoch_to_datenum(gps_time(1)));
  day_of_year_start = datenum(year,month,day) - datenum(year,0,0);
  [year month day] = datevec(epoch_to_datenum(gps_time(end)));
  day_of_year_end = datenum(year,month,day) - datenum(year,0,0);
  lidar_fns = {};
  for day_of_year = day_of_year_start:day_of_year_end
    new_fns = get_filenames(in_base_path, sprintf('ALS_L2B_%sT',datestr(datenum(year,0,day_of_year),'YYYYmmDD')), '', '.nc');
    lidar_fns(end+(1:length(new_fns)),1) = new_fns;
  end

elseif strcmpi(lidar_source,'las')
  [year month day] = datevec(epoch_to_datenum(gps_time(1)));
  day_of_year_start = datenum(year,month,day) - datenum(year,0,0);
  [year month day] = datevec(epoch_to_datenum(gps_time(end)));
  day_of_year_end = datenum(year,month,day) - datenum(year,0,0);
  lidar_fns = {};
  for day_of_year = day_of_year_start:day_of_year_end
    new_fns = get_filenames(in_base_path, datestr(datenum(year,0,day_of_year),'yyyymmdd'), '', '.las');
    lidar_fns(end+(1:length(new_fns)),1) = new_fns;
  end

else % strcmpi(lidar_source,'dtu')
  % dec.hour(UTC) latitude longitude  elevation  amplitude  #points/swath  GPS.h  range
  [year month day] = datevec(epoch_to_datenum(gps_time(1)));
  day_of_year_start = datenum(year,month,day) - datenum(year,0,0);
  [year month day] = datevec(epoch_to_datenum(gps_time(end)));
  day_of_year_end = datenum(year,month,day) - datenum(year,0,0);
  lidar_fns = {};
  for day_of_year = day_of_year_start:day_of_year_end
    new_fns = get_filenames(in_base_path, sprintf('%.0f_',day_of_year), '', '_1x1.ver');
    lidar_fns(end+(1:length(new_fns)),1) = new_fns;
  end
end

end
