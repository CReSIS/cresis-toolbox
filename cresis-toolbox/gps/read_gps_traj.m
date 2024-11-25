function gps = read_gps_traj(in_fn, param)
% gps = read_gps_traj(in_fn, param)
%
% Reads in .traj files from ATM group.
%
% Input File Format Examples:
% 2011 Format:
%  11   81   43875.00   76.53513100  291.27909300   108.733    2.4    0.0
% 2002 Format:
%   2  144   36120.00   78.24448929   15.49499684    64.135    2.9    2.6 29   0.49 10  2  0.0   0.64
% 2018 Format:
%    18  283   62620.00  -78.14931235  323.66596746  5033.078    1.9    1.8 17 23 40.0
%
% Input Args:
%   in_fn (string) input .traj filename
%   param = tells the file GPS type
%     .time_reference = 'gps' or 'utc'
%     .headerlines = default is 0, this is passed to textscan
%     .delimiter_type = default is ' ', this is passed to textscan
%     .input_format = string of char values, default '%f%f%f%f%f%f%f%f'
%        other used value is '%f%f%f%f%f%f%f%f%f%f%f%f%f%f'
%        or '%f%f%f%f%f%f%f%f%f%f%f%f%f%f'
%     .year = year of data collection (since year is 2-digits in file, it could
%        be ambiguous)
%
% Output Args:
% gps = output structure with fields
%  .gps_time = GPS time in seconds since Jan 1, 1970 epoch (sec)
%  .lat = latitude (deg)
%  .lon = longitude (deg)
%  .elev = elevation (m)
%  .roll = roll (rad)
%  .pitch = pitch (rad)
%  .heading = true heading (rad)
%
% Example:
% % Read 2002 NASA .traj data:
% traj_fin = '/cresis/data1/NASA/2002_Greenland_P3_traj/020524_aa_l12_jgs_itrf00_17jul02_npm';
% traj_param.time_reference = 'utc'; % Maybe gps?
% traj_param.input_format = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f';
% gps = read_gps_traj(traj_fin,traj_param);
% gps_plot(gps)
%
% % Read 2011 NASA .traj data:
% traj_fin = '/cresis/data1/NASA/2011_Greenland_P3/110316.traj';
% traj_param.time_reference = 'utc'; % Maybe gps?
% gps = read_gps_traj(traj_fin,traj_param);
% gps_plot(gps)
%
% % Read 2018 NASA .traj data:
% traj_fin = '/cresis/snfs1/dataproducts/metadata/2018_Antarctica_DC8/Trajectory/181010_aa_l12_cfm_itrf14_29oct18_roth_amu2';
% traj_param.time_reference = 'gps'; 
% gps = read_gps_traj(traj_fin,traj_param);
% gps_plot(gps)
%
% Author: John Paden, Kyle Purdon
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

% Set Defaults (If var does not exist)
if ~isfield(param,'headerlines')
    param.headerlines = 1;
end
if ~isfield(param,'delimiter_type')
    param.delimiter_type = ' ';
end
if ~isfield(param,'input_format')
    param.input_format = '%f%f%f%f%f%f%f%f';
end

% Open, read file, close
fin = fopen(in_fn);
T = textscan(fin,param.input_format,'delimiter',param.delimiter_type, ...
  'headerlines',param.headerlines,'emptyvalue',NaN,'MultipleDelimsAsOne',1);
fclose(fin);

% Variable assignments
year = T{:,1};
day_of_year = T{:,2};
time_sod = T{:,3};
gps.lat = T{:,4};
gps.lon = T{:,5};
gps.elev = T{:,6};

if ~isfield(param,'year')
  warning('Estimating year from 2-digit year since param.year unspecified');
  if year(1) > 80
    param.year = 1900;
  else
    param.year = 2000;
  end
end
gps.gps_time = datenum(100*floor(param.year/100)+year, 0, day_of_year, 0, 0, time_sod);
gps.gps_time = datenum_to_epoch(gps.gps_time);
if strcmpi(param.time_reference,'utc')
  % UTC time stored in file, so need to add leap seconds back in
  gps.gps_time = gps.gps_time + utc_leap_seconds(gps.gps_time(1));
else
  gps.gps_time = gps.gps_time;
end

% ENSURE ALL VECTORS IN 1xN FORMAT
gps.gps_time = reshape(gps.gps_time,[1 length(gps.gps_time)]);
gps.lat = reshape(gps.lat,[1 length(gps.lat)]);
gps.lon = reshape(gps.lon,[1 length(gps.lon)]);
gps.elev = reshape(gps.elev,[1 length(gps.elev)]);

% ZERO FILL INS DATA
gps.roll = zeros(size(gps.lat));
gps.pitch = zeros(size(gps.lat));
gps.heading = zeros(size(gps.lat));

return;
