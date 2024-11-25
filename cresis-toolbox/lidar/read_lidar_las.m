function [lidar] = read_lidar_las(fns, param)
% [lidar] = read_lidar_las(fns, param)
%
% Reads LIDAR data in the LAS format. UAF single otter rds and snow radar
% data and BAS Twin Otter accum and rds data may come in this format.
%
% This process should work with any LAZ/LAS LIDAR files as long as the x,
% y, and z fields correspond to longitude, latitude, and WGS-84 elevation.
% The filenames and file locations need to be modified to match the
% conventions required to work with read_lidar_las and get_filenames_lidar.
%
% -------------------------------------------------------------------------
% IMPORTANT NOTE:
% The x,y,z fields in the LAS file must be lat, lon, WGS-84 elevation
% -------------------------------------------------------------------------
%
% 1. Obtain LAZ (compressed LAS) files. If LAS files already skip the first
%    two steps. Technically lasdata.m can read LAZ files too if laszip
%    executable is in the system path, but this has not been tested.
% 2. Use laszip to decompress the laz files into las files. LAZ files use a
%    lidar-specific compression scheme.
%    Open Source Solution for decompression: https://laszip.org/
%    They have:
%    1. Linux C++ source files that can be compiled into executable
%    2. Windows based GUI binary: laszip.exe
%    3. Windows based CLI binary: laszip-cli.exe
% 3. Rename the LAS files to follow this convention:
%    YYYYMMDD_N.las such as 20191215_1.las, 20191224_1.las, 20191224_2.las
%
%    YYYYMMDD is the date of the data collection and needs to match the
%    date segment convention in the radar parameter segments.
%    
%    N is used to distinguish files when more than one file was collected
%    on a particular day. Numbering should be done in chronological order.
% 4. Place LAS files in the directory:
%    metadata/LIDAR_LAS/SEASON_NAME/
%
% param: struct that controls reading of file(s)
%   .season_name: String containing the season name such as
%   '2019_Antarctica_TObas', should match parameter spreadsheet season_name
%   field. This field is not required by read_lidar_las, but is required by
%   get_filenames_lidar.
%
%   .date_string: String containing the date in this format: 'YYYYMMDD'.
%   This field is not required by read_lidar_las, but is required by
%   get_filenames_lidar.
%     To convert gps time in seconds since Jan 1, 1970:
%       param.date_str = datestr(epoch_to_datenum(gps_time),'yyyymmdd'))
%     To convert day_seg field:
%       param.date_str = param.day_seg(1:8);
%
% lidar: struct of position and LIDAR data, each 1xNx vectors
%   where 1xNx is the number of records in the file(s). The fields are:
%  .gps_time: filled with NaN since this field is not available
%  .lat: latitude (deg)
%  .lon: longitude (deg)
%  .surface: WGS-84 surface elevation (m)
%
% Example:
%
% See also: read_lidar_atm, read_lidar_awi, read_lidar_dtu, read_lidar_las,
% get_filenames_lidar

%% Read Lidar Data from the LAS data files
lidar = [];
lidar.lat = [];
lidar.lon = [];
lidar.surface = [];
for fn_idx = 1:length(fns)
  fn = fns{fn_idx};
  
  % Create lasdata class with contents from file "fn"
  lidar_tmp = lasdata(fn);

  % Concatenate contents of this file to the lidar output structure fields:
  lidar.lat(1,end+(1:length(lidar_tmp.x))) = lidar_tmp.x;
  lidar.lon(1,end+(1:length(lidar_tmp.x))) = lidar_tmp.y;
  lidar.surface(1,end+(1:length(lidar_tmp.x))) = lidar_tmp.z;
  
  % Delete handle class or it will stay in memory
  delete(lidar_tmp);
end
lidar.gps_time = nan(size(lidar.lon));
