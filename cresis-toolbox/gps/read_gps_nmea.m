function gps = read_gps_nmea(in_fns, param)
% gps = read_gps_nmea(in_fns, param)
%
% Reads in NMEA files and modified NMEA files that include the MCRDS
% radar time stamps.
%
% Example strings:
% $GPGGA,120448.00,6952.4649165,N,03256.5105286,W,1,10,0.80,3135.1254,M,55.3383,M,,*7B
% $GPGGA,221343.00,7928.1873712,S,11203.3163302,W,0,10,   ,1769.932,M,     , , ,*5e
% $GPGGA,151922.00,4402.1108,N,10330.6311,W,1,08,0.0,2030.41,M,-14.10,M,,*69
% $GPZDA,151923.00,02,03,2021,,*6B
% $GPRMC,194325.010,A,3857.135037,N,09515.861757,W,0.000,0.00,121018,,,A*46
%
% Special MCRDS GPS string with radar timing at the end:
% $GPGGA,163202.50,6909.94391,N,05045.73509,W,1,10,01.1,+00351,M,,M,,*6E,1216243966,190018,0,1204901900
%
% Input Args:
%   in_fns: string containing input NMEA filename
%     OR cell array of strings containing input NMEA filenames
%   param: controls how the NMEA file is read
%     .format = scalar integer from 1 to 4, default is 1
%       1. Standard NMEA
%       2. Standard NMEA comp_time_sec comp_time_usec
%          comp_time_sec + comp_time_usec/1e6
%           = seconds since the epoch Jan 1, 1970 00:00:00
%       3. Standard NMEA comp_time_sec comp_time_usec radar_32MSB radar_32LSB
%          radar_32MSB*2^32 + radar_32LSB (64 bit MCRDS radar time, 10 MHz clock)
%       4. From reveal system
%     .year: Optionally override the year (this field must be set if the
%       NMEA strings do not include the date)
%     .month: Optionally override the year (this field must be set if the
%       NMEA strings do not include the date)
%     .day: Optionally override the year (this field must be set if the
%       NMEA strings do not include the date)
%     .time_reference = 'gps' or 'utc' (should always be 'utc')
%
% Output Args:
% gps: output structure with fields
%  .gps_time: GPS time in seconds since Jan 1, 1970 epoch (sec)
%  .lat: latitude (deg)
%  .lon: longitude (deg)
%  .elev: elevation (m)
%  .roll: roll (rad)
%  .pitch: pitch (rad)
%  .heading: true heading (rad)
%  .comp_time: computer time in seconds since Jan 1, 1970 epoch (sec)
%  .radar_time: radar time, 64 bit counter free-running at 10 MHz
%
% Example:
%   fn = '/cresis/data2/MCoRDS/2010_Antarctica/GPS_new/GGA/RevealGPS_20100103A';
%   gps = read_gps_nmea(fn, struct('year',2010,'month',1,'day',3));
%   plot(gps.lon,gps.lat);
%   datestr(epoch_to_datenum(gps.gps_time(1)));
%   gps.utc_time = gps.gps_time - utc_leap_seconds(gps.gps_time(1))
%   gps_plot(gps)
%
%   fn = '/cresis/snfs1/dataproducts/metadata/2020_SouthDakota_N1KU/20210302/GPS_20210302_151952.txt';
%   gps = read_gps_nmea(fn);
%   gps_plot(gps);
%
%   fn = '/cresis/snfs1/dataproducts/metadata/2008_Greenland_TO/nmea.20080716163242.gps';
%   gps = read_gps_nmea(fn,struct('year',2008,'month',7,'day',16));
%   gps_plot(gps);
%
% Author: William Blake, John Paden, Anthony Hoch, Logan Smith
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

if ~exist('param','var')
  param = [];
end

if ~isfield(param,'year') || isempty(param.year)
  param.year = NaN;
end

if ~isfield(param,'month') || isempty(param.month)
  param.month = NaN;
end

if ~isfield(param,'day') || isempty(param.day)
  param.day = NaN;
end

if ~isfield(param,'time_reference') || isempty(param.time_reference)
  param.time_reference = 'utc';
end

if ischar(in_fns)
  in_fns = {in_fns};
end

for in_fns_idx = 1:length(in_fns)
  in_fn = in_fns{in_fns_idx};
  fprintf('Opening_file\t%s\n', in_fn);
  if ~exist(in_fn,'file')
    error('File does not exist %s\n', in_fn);
  end

  [fid,msg] = fopen(in_fn,'rb');
  if fid < 0
    error('Error opening %s: %s', in_fn, msg);
  end

  file_contents = fread(fid,inf,'char=>char').';
  fclose(fid);
  
  line_start_idxs = [find(file_contents=='$') numel(file_contents)+1];
  gps_idx = 0;
  gps.gps_time = nan(1,length(line_start_idxs));
  gps.lat = nan(1,length(line_start_idxs));
  gps.lon = nan(1,length(line_start_idxs));
  gps.elev= nan(1,length(line_start_idxs));
  gps.comp_time = nan(1,length(line_start_idxs));
  gps.radar_time = nan(1,length(line_start_idxs));
  cur_hour = NaN;
  cur_min = NaN;
  cur_sec = NaN;
  start_time = -inf;
  for line = 1:length(line_start_idxs)-1
    if now > start_time+1/86400
      fprintf('File_line\t%d\tof\t%d\t%s\n', line, length(line_start_idxs), datestr(now,'yyyymmdd_HHMMSS'));
      start_time = now;
    end
    line_str = file_contents(line_start_idxs(line) : line_start_idxs(line+1)-1);
    
    comma_idxs = find(line_str == ',');
    star_idx = find(line_str == '*');
    
    if length(comma_idxs) > 1 && ~isempty(star_idx) && length(line_str) >= star_idx(end)+2
      line_uint8 = uint8(line_str);
      
      % This is a simple calculator to compute the checksum field for the
      % NMEA protocol. The checksum is simple, just an XOR of all the bytes
      % between the $ and the * (not including the delimiters themselves),
      % and written in hexadecimal.
      check_sum = line_uint8(2);
      for idx = 3:star_idx-1
        check_sum = bitxor(check_sum,line_uint8(idx));
      end
      
      if check_sum == sscanf(line_str(star_idx(end)+(1:2)),'%x')
        % Checksum is correct
        
        if strcmp('GPGGA',line_str(2:comma_idxs(1)-1)) && length(comma_idxs) >= 10 ...
            && comma_idxs(2) - comma_idxs(1) >= 2 ...
            && comma_idxs(3) - comma_idxs(2) >= 2 ...
            && comma_idxs(4) - comma_idxs(3) >= 2 ...
            && comma_idxs(5) - comma_idxs(4) >= 2 ...
            && comma_idxs(6) - comma_idxs(5) >= 2 ...
            && comma_idxs(10) - comma_idxs(9) >= 2
          
          try
            [~,~,~,cur_hour,cur_min,cur_sec] = datevec(datenum(line_str(comma_idxs(1)+1 : comma_idxs(2)-1), 'HHMMSS.FFF'));
          end
          
          lat = 10*(line_str(comma_idxs(2)+1)-48) + (line_str(comma_idxs(2)+2)-48) ...
            + sscanf(line_str(comma_idxs(2)+3:comma_idxs(3)-1),'%f')/60;
          if line_str(comma_idxs(3)+1) == 'S'
            lat = -lat;
          end
          lon = 100*(line_str(comma_idxs(4)+1)-48) + 10*(line_str(comma_idxs(4)+2)-48) + (line_str(comma_idxs(4)+3)-48) ...
            + sscanf(line_str(comma_idxs(4)+4:comma_idxs(5)-1),'%f')/60;
          if line_str(comma_idxs(5)+1) == 'W'
            lon = -lon;
          end
          elev = sscanf(line_str(comma_idxs(9)+1:comma_idxs(10)-1),'%f');
          
          gps_idx = gps_idx + 1;
          gps.gps_time(gps_idx) = datenum(param.year,param.month,param.day,cur_hour,cur_min,cur_sec);
          if isnan(gps.gps_time(gps_idx))
            warning('NaN gps_time.');
          end
          gps.lat(gps_idx) = lat;
          gps.lon(gps_idx) = lon;
          gps.elev(gps_idx) = elev;
          
          if length(comma_idxs) == 16 ...
            && comma_idxs(16) - comma_idxs(15) >= 2 ...
            && length(line_str) - comma_idxs(16) >= 2
            % NMEA file with computer time stamps at end
            
            [time_fields,count] = sscanf(line_str(comma_idxs(15)+1:end),'%f,%f');
            if count == 2
              gps.comp_time(gps_idx) = time_fields(1) + time_fields(2)/10e6;
            end
            
          elseif length(comma_idxs) == 18 ...
            && comma_idxs(16) - comma_idxs(15) >= 2 ...
            && comma_idxs(17) - comma_idxs(16) >= 2 ...
            && comma_idxs(18) - comma_idxs(17) >= 2 ...
            && length(line_str) - comma_idxs(18) >= 2
            % MCRDS NMEA file (computer and radar time stamps at the end)
          
            [time_fields,count] = sscanf(line_str(comma_idxs(15)+1:end),'%f,%f,%f,%f');
            if count == 4
              gps.comp_time(gps_idx) = time_fields(1) + time_fields(2)/1e6;
              gps.radar_time(gps_idx) = time_fields(3) + time_fields(4)/10e6;
            end
          end
          
        elseif strcmp('GPZDA',line_str(2:comma_idxs(1)-1)) && length(comma_idxs) >= 5 ...
            && comma_idxs(2) - comma_idxs(1) >= 2 ...
            && comma_idxs(3) - comma_idxs(2) >= 2 ...
            && comma_idxs(4) - comma_idxs(3) >= 2 ...
            && comma_idxs(5) - comma_idxs(4) >= 2
          
          try
            gps_time = datenum(line_str(comma_idxs(1)+1 : comma_idxs(5)-1), 'HHMMSS.FFF,dd,mm,yyyy');
            [param.year,param.month,param.day,test_hour,test_min,test_sec] = datevec(gps_time);
          end
          
          if test_hour == cur_hour && test_min == cur_min && test_sec == cur_sec
            gps.gps_time(gps_idx) = gps_time;
          end
          
        elseif strcmp('GPRMC',line_str(2:comma_idxs(1)-1)) && length(comma_idxs) >= 10 ...
            && comma_idxs(2) - comma_idxs(1) >= 2 ...
            && comma_idxs(10) - comma_idxs(9) >= 2
          
          try
            gps_time = datenum(line_str([comma_idxs(1)+1 : comma_idxs(2)-1,comma_idxs(9) : comma_idxs(10)-1]), 'HHMMSS.FFF,ddmmyy');
            [param.year,param.month,param.day,test_hour,test_min,test_sec] = datevec(gps_time);
          end
          
          if test_hour == cur_hour && test_min == cur_min && test_sec == cur_sec
            gps.gps_time(gps_idx) = gps_time;
          end
        end
      end
    end
    
  end
end

good_mask = ~isnan(gps.gps_time);
gps.gps_time = gps.gps_time(good_mask);
gps.lat = gps.lat(good_mask);
gps.lon = gps.lon(good_mask);
gps.elev = gps.elev(good_mask);
gps.comp_time = gps.comp_time(good_mask);
gps.radar_time = gps.radar_time(good_mask);

gps.roll = zeros(size(gps.lat));
gps.pitch = zeros(size(gps.lat));
gps.heading = zeros(size(gps.lat));

%% Day Jumps
% =========================================================================
% Find negative jumps in the GPS time of more than 75% of a day that are
% probably due to day wraps of 1.
day_jumps = find(diff(gps.gps_time) < -0.75);
for jump_idx = day_jumps
  gps.gps_time(jump_idx+1:end) = gps.gps_time(jump_idx+1:end) + 1;
end

%% UTC or GPS time reference
% =========================================================================
% Convert gps_time into ANSI-C standard (seconds since 1970)
gps.gps_time = datenum_to_epoch(gps.gps_time);
if strcmpi(param.time_reference,'utc')
  % UTC time stored in file, so need to add leap seconds back in
  gps.gps_time = gps.gps_time + utc_leap_seconds(gps.gps_time(1));
else
  warning('NMEA files are usually always UTC time, but GPS time has been specified.');
end
