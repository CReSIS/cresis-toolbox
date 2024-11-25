function gps = read_gps_arena(fn, param)
% gps = read_gps_arena(fn, param)
%
% Reads in Arena GPS files that include NMEA and radar time.
%
% Ignores NMEA strings besides GPRMC and GPGGA which show up in the file as
% the following. GPGGA is required. GPRMC is optional and is used to
% estimate the date and heading.
%
% relTimeCntr:15393734057677147
% profileCntr:7678
% ppsCntr:1539373405
% nmea:$GPRMC,194325.010,A,3857.135037,N,09515.861757,W,0.000,0.00,121018,,,A*46
% relTimeCntr:15393734057677147
% profileCntr:7678
% ppsCntr:1539373405
% nmea:$GPGGA,194325.010,3857.135037,N,09515.861757,W,1,9,0.88,311.412,M,-29.504,M,,*65
%
% Input Args:
%   fn = string containing input Arena GPS filename
%     e.g. 20180817_094746_ARENA-CTU-ctu-gps.txt
%   param = tells the file GPS type and the year, month, day to determine
%     absolute time (GGA NMEA files just give the time of day)
%     .year
%     .month
%     .day
%     .time_reference: 'gps' or 'utc' (should always be 'utc')
%     .nmea_tag: NEMA string to identify good lines (e.g. '$GPGGA')
%     .clk: clock for radar_time counter, defaults to 10e6
%
% Output Args:
% gps = output structure with fields
%  .time = GPS time in seconds since Jan 1, 1970 epoch (sec)
%  .lat = latitude (deg)
%  .lon = longitude (deg)
%  .elev = elevation (m)
%  .roll = roll (rad)
%  .pitch = pitch (rad)
%  .heading = true heading (rad)
%  .relTimeCntr: radar time, 64 bit counter free-running at 10 MHz
%  .profileCntr: pulse counter
%  .ppsCntr: PPS counter
%
% Example:
%   fn = 'E:\tmp\2018_Antarctica_TObas\20180817\logs\20180817_094746_ARENA-CTU-ctu-gps.txt';
%   gps = read_gps_arena(fn, struct('year',2018,'month',8,'day',17,'time_reference','utc'));
%   plot(gps.lon,gps.lat);
%   datestr(epoch_to_datenum(gps.gps_time(1)));
%   gps.utc_time = gps.gps_time - utc_leap_seconds(gps.gps_time(1))
%   gps_plot(gps)
%
% Author: John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

%% NMEA String Format
% =============================================================================
% NMEA-0183 message: GGA
% Related Topics
% NMEA-0183 messages: Overview
% Time, position, and fix related data
% An example of the GGA message string is:
% 
% $GPGGA,172814.0,3723.46587704,N,12202.26957864,W,2,6,1.2,18.893,M,-25.669,M,2.0,0031*4F
% 
% Note: The data string exceeds the NMEA standard length.
% 
% GGA message fields
% Field	Meaning
% 0	Message ID $GPGGA
% 1	UTC of position fix
% 2	Latitude
% 3	Direction of latitude:
% 	N: North
% 	S: South
% 4	Longitude
% 5	Direction of longitude:
% 	E: East
% 	W: West
% 6	GPS Quality indicator:
% 	0: Fix not valid
% 	1: GPS fix
% 	2: Differential GPS fix, OmniSTAR VBS
% 	4: Real-Time Kinematic, fixed integers
% 	5: Real-Time Kinematic, float integers, OmniSTAR XP/HP or Location RTK
% 7	Number of SVs in use, range from 00 through to 24+
% 8	HDOP
% 9	Orthometric height (MSL reference)
% 10	M: unit of measure for orthometric height is meters
% 11	Geoid separation
% 12	M: geoid separation measured in meters
% 13	Age of differential GPS data record, Type 1 or Type 9. Null field when DGPS is not used.
% 14	Reference station ID, range 0000-4095. A null field when any reference station ID is selected and no corrections are received1.
% 15	
% The checksum data, always begins with *
% 
% Note: If a user-defined geoid model, or an inclined plane is loaded into the receiver, then the height output in the NMEA GGA string is always the orthometric height (height above a geoid). The orthometric height is output even if no user-defined geoid is loaded (there is a simplified default geoid in the receiver), or if a user-defined geoid is loaded, or if an inclined plane is used.
% 
% =============================================================================
% NMEA-0183 message: RMC
% Related Topics
% NMEA-0183 messages: Overview
% Position, velocity, and time
% The RMC string is:
% 
% $GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A
% 
% GPRMC message fields
% Field	Meaning
% 0	Message ID $GPRMC
% 1	UTC of position fix
% 2	Status A=active or V=void
% 3	Latitude
% 4	Longitude
% 5	Speed over the ground in knots
% 6	Track angle in degrees (True)
% 7	Date
% 8	Magnetic variation in degrees
% 9	The checksum data, always begins with *
% 
% =============================================================================
% NMEA-0183 message: ZDA
% Related Topics
% NMEA-0183 messages: Overview
% Date and time
% The ZDA string is:
% 
% $GPZDA,034558.00,09,12,2022,,*61
% 
% GPZDA message fields
% Field	Meaning
% 0	Message ID $GPZDA
% 1	UTC of position fix
% 2 Day
% 3	Month
% 4	Year
% 5	
% 6	The checksum data, always begins with *
% 
% =============================================================================
% NMEA-0183 message: VTG
% Related Topics
% NMEA-0183 messages: Overview
% Track made good and speed over ground
% An example of the VTG message string is:
% 
% $GPVTG,,T,,M,0.00,N,0.00,K*4E
% 
% VTG message fields
% Field	Meaning
% 0	Message ID $GPVTG
% 1	Track made good (degrees true)
% 2	T: track made good is relative to true north
% 3	Track made good (degrees magnetic)
% 4	M: track made good is relative to magnetic north
% 5	Speed, in knots
% 6	N: speed is measured in knots
% 7	Speed over ground in kilometers/hour (kph)
% 8	K: speed over ground is measured in kph
% 9	The checksum data, always begins with *
% =============================================================================

%% Input checks
if ~exist('param','var') || isempty(param)
  error('Year, month, day must be specified in param struct');
end
if ~isfield(param,'clk') || isempty(param.clk)
  param.clk = 10e6;
end

%% Open file
[fid,msg] = fopen(fn,'r');
if fid < 0
  error('Error opening %s: %s', fn, msg);
end

%% Process file line by line
UTC_time_file = [];
latitude = [];
N_S = [];
longitude = [];
E_W = [];
altitude = [];
relTimeCntr = [];
profileCntr = [];
ppsCntr = [];
gps_date = [];
heading = [];

% $GPZDA,034558.00,09,12,2022,,*61
format_str_GPZDA = '%s%f%s%s%s%s%s';
% $GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A
format_str_GPRMC = '%s%f%s%f%c%f%c%f%f%f%f%s%s';
% $GPGGA,194325.010,3857.135037,N,09515.861757,W,1,9,0.88,311.412,M,-29.504,M,,*65
format_str_GPGGA = '%s%f%f%c%f%c%u%u%f%f%c%f%c%s%s';
nmea_idx = 1;
relTimeCntrTmp = NaN;
profileCntrTmp = NaN;
ppsCntrTmp = NaN;
heading_tmp = NaN;
gps_date_tmp = NaN;
gps_date_time_tmp = NaN;
line_num = 0;
while ~feof(fid)
  str = fgets(fid);
  line_num = line_num + 1;
  [token,remain] = strtok(str,':');
  if strcmpi(token,'nmea')
    if numel(str)>=11 && strcmp(str(7:11),'GPGGA')
      GPGGA_str = remain(2:end);
      C = textscan(GPGGA_str,format_str_GPGGA,'delimiter',', ','emptyvalue',NaN);
      [tag,UTC_time_file_tmp,latitude_tmp,N_S_tmp,longitude_tmp,E_W_tmp,fix,NoSatelite,dilution,...
        altitude_tmp,alt_unit,geoid_ref,geoid_unit,dgps,checksum] = deal(C{:});
      
      if ~isnan(relTimeCntrTmp) && ~isnan(profileCntrTmp) && ~isnan(ppsCntrTmp)
        if nmea_idx > 1
          if UTC_time_file_tmp <= UTC_time_file(nmea_idx-1)
            fprintf(2, '    GPS NOT MONOTONIC LINE %d: %.14g  <= %.14g\n', line_num, UTC_time_file_tmp, UTC_time_file(nmea_idx-1));
          end
          if relTimeCntrTmp == relTimeCntr(nmea_idx-1)
            fprintf(2, '    RADAR REPEAT LINE %d: %.0f\n', line_num, relTimeCntrTmp);
          end
          if relTimeCntrTmp < relTimeCntr(nmea_idx-1)
            fprintf(2, 'Radar time is not monotonic on line %d: %.0f  <= %.0f\n', line_num, relTimeCntrTmp, relTimeCntr(nmea_idx-1));
          end
        end
        
        if length(UTC_time_file_tmp) == 1 ...
            && length(latitude_tmp) == 1 ...
            && length(N_S_tmp) == 1 && any(N_S_tmp == 'SN') ...
            && length(longitude_tmp) == 1 ...
            && length(E_W_tmp) == 1 && any(E_W_tmp == 'EW') ...
            && length(altitude_tmp) == 1
          UTC_time_file(nmea_idx) = UTC_time_file_tmp;
          latitude(nmea_idx) = latitude_tmp;
          N_S(nmea_idx) = N_S_tmp;
          longitude(nmea_idx) = longitude_tmp;
          E_W(nmea_idx) = E_W_tmp;
          altitude(nmea_idx) = altitude_tmp;
          if ~isempty(geoid_ref) && isfinite(geoid_ref)
            altitude(nmea_idx) = altitude(nmea_idx) + geoid_ref;
          end
          relTimeCntr(nmea_idx) = relTimeCntrTmp;
          profileCntr(nmea_idx) = profileCntrTmp;
          ppsCntr(nmea_idx) = ppsCntrTmp;
          heading(nmea_idx) = heading_tmp;
          if UTC_time_file(nmea_idx) == gps_date_time_tmp
            gps_date(nmea_idx) = gps_date_tmp;
          else
            gps_date(nmea_idx) = NaN;
          end
          nmea_idx = nmea_idx + 1;
          relTimeCntrTmp = NaN;
          profileCntrTmp = NaN;
          ppsCntrTmp = NaN;
          heading_tmp = NaN;
        else
          fprintf(2, '    BAD LINE %d: %s\n', line_num, GPGGA_str(GPGGA_str ~= 10));
        end
      end
    elseif numel(str)>=11 && strcmp(str(7:11),'GPZDA')
      C = textscan(remain(2:end),format_str_GPZDA,'delimiter',', ','emptyvalue',NaN);
      [tag,gps_date_time_tmp,day_tmp,month_tmp,year_tmp,unknown,checksum] = deal(C{:});
      heading_tmp = NaN; % Do not use (low quality)
      if nmea_idx > 1
        % The GPZDA string may come before or after the corresponding GPZDA
        % string with the same time stamp.
        % 
        % If it comes afterwards, this string is just updating fields that
        % the GPGGA string already provided. The most important fields are
        % the day, month, and year, which the GPGGA does not provide. We
        % __think__ that all the other fields should be the same as what
        % were in the GPGGA string.
        %
        % If GPZDA comes before the GPGGA string, we do nothing now, but
        % use the gps_date_tmp and gps_date_time_tmp fields to update the
        % next GPGGA string when it comes.
        if ~isempty(day_tmp{1}) && ~isempty(month_tmp{1}) && ~isempty(year_tmp{1})
          gps_date_tmp = str2double([day_tmp{1},month_tmp{1},year_tmp{1}(3:4)]);
          if UTC_time_file(nmea_idx-1) == gps_date_time_tmp
            gps_date(nmea_idx-1) = gps_date_tmp;
            gps_date_tmp = NaN;
            gps_date_time_tmp = NaN;
            % fprintf(2, '    GPZDA WITH DIFFERENT TIME THAN LAST GPGGA LINE %d: %.14g  ~= %.14g\n', line_num, UTC_time_file_tmp, UTC_time_file(nmea_idx-1));
          end
        end
      end
    elseif numel(str)>=11 && strcmp(str(7:11),'GPRMC')
      C = textscan(remain(2:end),format_str_GPRMC,'delimiter',', ','emptyvalue',NaN);
      [tag,gps_date_time_tmp,nav_rx_warning,latitude_tmp,N_S_tmp,longitude_tmp,E_W_tmp,speed,heading_tmp,...
        gps_date_tmp,mag_Var,mag_var_E_W,checksum] = deal(C{:});
      heading_tmp = NaN; % Do not use (low quality)
      if nmea_idx > 1
        % The GPRMC string may come before or after the corresponding GPGGA
        % string with the same time stamp.
        % 
        % If it comes afterwards, this string is just updating fields that
        % the GPGGA string already provided. The most important field is
        % the gps_date which the GPGGA does not provide. We __think__ that
        % all the other fields should be the same as what were in the GPGGA
        % string.
        %
        % If GPRMC comes before the GPGGA string, we do nothing now, but
        % use the gps_date_tmp and gps_date_time_tmp fields to update the
        % next GPGGA string when it comes.
        if UTC_time_file(nmea_idx-1) == gps_date_time_tmp
          gps_date(nmea_idx-1) = gps_date_tmp;
          gps_date_tmp = NaN;
          gps_date_time_tmp = NaN;
          % fprintf(2, '    GPRMC WITH DIFFERENT TIME THAN LAST GPGGA LINE %d: %.14g  ~= %.14g\n', line_num, UTC_time_file_tmp, UTC_time_file(nmea_idx-1));
        end
      end
    end
  elseif strcmpi(token,'relTimeCntr')
    relTimeCntrTmp = str2double(remain(2:end));
  elseif strcmpi(token,'profileCntr')
    profileCntrTmp = str2double(remain(2:end));
  elseif strcmpi(token,'ppsCntr')
    ppsCntrTmp = str2double(remain(2:end));
  end
end
fclose(fid);

%% Parse file contents

if nmea_idx < 2
  gps.gps_time = [];
  gps.lat = [];
  gps.lon = [];
  gps.elev = [];
  gps.roll = [];
  gps.pitch = [];
  gps.heading = [];
  gps.radar_time = [];
  gps.profileCntr = [];
  gps.comp_time = [];
  return;
end

%   CONVERT LATITUDE AND LONGITUDE TO [DD.DDD] FROM [DDDMM.MMM]
lat_MM = mod(latitude,100);
lat_DD = (latitude - lat_MM)./100;
lat = lat_DD + lat_MM./60;
lon_MM = mod(longitude,100);
lon_DD = (longitude - lon_MM)./100;
lon = lon_DD + lon_MM./60;

%   IMPLY NEGATIVE LATITUDE AND LONGITUDE TO SOUTH AND WEST COORDINATES
lat(N_S == 'S') = -1 * lat(N_S == 'S');
lon(E_W == 'W') = -1 * lon(E_W == 'W');

%   CREATE NEW ELEVATION VARIABLE
elev = altitude;

% Convert HHMMSS format to ANSI-C standard, seconds since Jan 1 1970
  % gps_date = HHMMSS format
sec = mod(UTC_time_file,100);
minute = mod((UTC_time_file-sec)./100,100);
hour = ((UTC_time_file-sec)./100 - minute)./100;
if ~all(isnan(gps_date))
  % gps_date = DDMMYY format
  gps_date = interp_finite(gps_date);
  year = mod(gps_date,100);
  month = mod((gps_date-year)./100,100);
  day = ((gps_date-year)./100 - month)./100;
  year = year+2000; % Add in century information
  if isfield(param,'year')
    year(:) = param.year(:);
  else
    param.year = year;
  end
  if isfield(param,'month')
    month(:) = param.month;
  else
    param.month = month;
  end
  if isfield(param,'day')
    day(:) = param.day;
  else
    param.day = day;
  end
  UTC_time = datenum_to_epoch(datenum(year,month,day,hour,minute,sec));
else
  UTC_time = datenum_to_epoch(datenum(param.year,param.month,param.day,hour,minute,sec));
end

% ENSURE ALL VECTORS IN 1xN FORMAT
UTC_time = reshape(UTC_time,[1 length(UTC_time)]);
lat = reshape(lat,[1 length(lat)]);
lon = reshape(lon,[1 length(lon)]);
elev = reshape(elev,[1 length(elev)]);

goodIdxs = find(~isnan(lat));
UTC_time = UTC_time(goodIdxs);
lat = lat(goodIdxs);
lon = lon(goodIdxs);
elev = elev(goodIdxs);

if all(isnan(gps_date))
  % ===================================================================
  % Find jumps in the GPS time that are probably due to day interval
  % 86400 seconds.
  day_jumps = find(diff(UTC_time) < -60000);
  for jump_idx = day_jumps
    UTC_time(jump_idx+1:end) = UTC_time(jump_idx+1:end) + 86400;
  end
end

%% Store outputs in structure
% ===================================================================
if strcmpi(param.time_reference,'utc')
  % UTC time stored in file, so need to add leap seconds back in
  if ~isempty(UTC_time)
    gps.gps_time = UTC_time + utc_leap_seconds(UTC_time(1));
  else
    gps.gps_time = [];
  end
else
  warning('NMEA files are usually always UTC time, but GPS time has been specified.');
  gps.gps_time = UTC_time;
end

gps.lat = lat;
gps.lon = lon;
gps.elev = elev;

gps.roll = zeros(size(gps.lat));
gps.pitch = zeros(size(gps.lat));
gps.heading = interp_finite(heading,0);

gps.radar_time = relTimeCntr/param.clk;
gps.profileCntr = profileCntr;
gps.comp_time = ppsCntr;

% If GPS is bad, NMEA may be constant, return empty arrays in this case
if all(gps.lat(1)==gps.lat)
  warning('GPS data is constant. This generally means invalid data so not loading this file.');
  gps.gps_time = [];
  gps.lat = [];
  gps.lon = [];
  gps.elev = [];
  gps.roll = [];
  gps.pitch = [];
  gps.heading = [];
  gps.radar_time = [];
  gps.profileCntr = [];
  gps.comp_time = [];
  return;
end

if all(gps.radar_time(1)==gps.radar_time)
  warning('gps.radar_time is constant. GPS 1 PPS may not have been received. Radar synchronization to GPS will not be possible with this file.');
end

if all(gps.comp_time(1)==gps.comp_time)
  warning('gps.comp_time is constant. GPS 1 PPS may not have been received.');
  
else
  [comp_time_year,comp_time_month,comp_time_day] = datevec(epoch_to_datenum(gps.comp_time));
  if any(comp_time_year ~= param.year)
    warning('comp_time year values are %s and does not always match values param.year %s.', ...
      mat2str_generic(unique(comp_time_year)), mat2str_generic(unique(param.year)));
  end
  if any(comp_time_month ~= param.month)
    warning('comp_time month values are %s and does not always match values param.month %s.', ...
      mat2str_generic(unique(comp_time_month)), mat2str_generic(unique(param.month)));
  end
  if any(comp_time_day ~= param.day)
    warning('comp_time day values are %s and does not always match values param.day %s.', ...
      mat2str_generic(unique(comp_time_day)), mat2str_generic(unique(param.day)));
  end
end

if 0
  % DEBUG CODE
  
  dd = diff(gps.profileCntr);
  ll = diff(gps.lat);
  bad_mask = dd ~= 25000 | abs(ll)>1e-3;
  bad_mask = fir_dec(bad_mask,[1 1 1 1 1],1);
  bad_mask(bad_mask~=0) = 1;
  bad_mask = logical(bad_mask);
  bad_mask = ~bad_mask;
  gps.gps_time = gps.gps_time(bad_mask);
  gps.lat = gps.lat(bad_mask);
  gps.lon = gps.lon(bad_mask);
  gps.elev = gps.elev(bad_mask);
  gps.roll = gps.roll(bad_mask);
  gps.pitch = gps.pitch(bad_mask);
  gps.heading = gps.heading(bad_mask);
  gps.radar_time = gps.radar_time(bad_mask);
  gps.profileCntr = gps.profileCntr(bad_mask);
  gps.comp_time = gps.comp_time(bad_mask);
  
  figure(2); clf;
  dd = diff(gps.profileCntr);
  plot(dd);
  bad_mask = mod(dd,25000);
  bad_mask = fir_dec(bad_mask,[1 1 1],1);
  bad_mask(bad_mask~=0) = 1;
  bad_mask = logical(bad_mask);
  hold on;
  plot(dd(~bad_mask),'.');
  idxs = find(~bad_mask);
  
  figure(1); clf;
  ee = diff(gps.radar_time);
  plot(ee);
  hold on;
  plot(idxs,ee(idxs),'.');
  
  figure(3); clf;
  ee = diff(gps.gps_time);
  plot(ee);
  hold on;
  plot(idxs,ee(idxs),'.');
  keyboard
end
