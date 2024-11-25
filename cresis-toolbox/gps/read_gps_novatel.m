function gps = read_gps_novatel(fn,param)
% gps = read_gps_novatel(fn,param)
%
% This function reads the DGPS/INS data output from the Waypoint Inertial
% Explorer from NovAtel, Canada.  This is documented in the report
%   'CReSIS GPS+INS Post-Processing Guide'
%
% gps = structure of the output
% param =
%  .time_reference = 'gps' or 'utc' (normally 'gps')
%
% Examples:
%  fn = '/cresis/snfs1/dataproducts/metadata/2009_Antarctica_TO/rover_ppp_antarctica_01082010_LC.txt';
%  fn = '/cresis/snfs1/dataproducts/metadata/2009_Antarctica_TO/rover_diff_antarctica_01012010.txt';
%  fn = '/cresis/snfs1/dataproducts/metadata/2009_Antarctica_TO/rover_diff_antarctica_01022010.txt';
%  fn = '/cresis/snfs1/dataproducts/metadata/2011_Greenland_TO/2011_Greenland_TO_GPSwINS/txt/rover_TC_diff_Greenland_20110331.gps';
%  fn = '/cresis/snfs1/dataproducts/metadata/2011_Antarctica_TO/twinotter_diff_antarctica_20111129.txt';
%  gps = read_gps_novatel(fn, struct('time_reference','gps'));
%  gps_plot(gps);
%
% Author: Huan Zhao, John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

% 2009 Antarctica TO FORMAT:
% =========================================================================
% 
% Project:     rover_diff_antarctica_01022010
% Program:     Inertial Explorer Version 8.30.0623
% Profile:     CReSIS 
% Source:      GPS Epochs(Smoothed TC Combined)
% 
% Datum:       WGS84, (processing datum)
% Master 1:    Name base_antarctica, Status ENABLED
%              Antenna height 0.054 m, to L1-PC (JPSLEGANT_E, MeasDist 0.000 m to mark/ARP)
%              Position -80 00 42.83213, -119 33 24.98087, 1496.009 m (WGS84, Ellipsoidal hgt)
% Remote:      Antenna height 0.000 m, to L1-PC (Generic)
% SD/Covariance Scaling Settings:
%   Position: No scaling (1-sigma)
%   Velocity: No scaling (1-sigma)
%   Attitude: No scaling (1-sigma)
%   Increase SD on kinematic float: Yes
%   
%  CorrTime       Date         Latitude        Longitude        H-Ell        Heading        HdngSep         HdngSD          Pitch        PtchSep        PitchSD           Roll        RollSep         RollSD
%     (sec)      (MDY)       (+/-D M S)       (+/-D M S)          (m)          (Deg)          (Deg)          (Deg)          (Deg)          (Deg)          (Deg)          (Deg)          (Deg)          (Deg)
% 598861.01  1/02/2010  -79 28 10.85149 -112 03 17.05073     1765.359  51.2305580000 359.9682999998   0.0198516510  -1.2856740000 359.9926000000   0.0049116057   0.0289810000 359.9872000003   0.0048216125
% =========================================================================
%
% The number of header lines can be 14, 20 or 21, but always has "CorrTime"
% header field so this is used to identify the start of the data.
%
% The order of the fields changes for some files:
% rover_diff_antarctica_01012010.txt
% rover_diff_antarctica_01032010_1.txt
% rover_diff_antarctica_12122009.txt
% rover_diff_antarctica_12212009.txt
% rover_diff_antarctica_12242009.txt
% rover_diff_antarctica_12272009.txt
% rover_diff_antarctica_12282009_1.txt
% rover_diff_antarctica_12282009_2.txt
% rover_diff_antarctica_12302009_1.txt
% rover_diff_antarctica_12302009_2.txt
%  CorrTime       Date         Latitude        Longitude        H-Ell          Pitch        PtchSep        PitchSD           Roll        RollSep         RollSD        Heading        HdngSep         HdngSD

% Format 2011 Greenland TO:
% =========================================================================
% 400989.00    3/24/2011     69 12 10.87930    -51 26 56.16094       1648.423     8.1594     0     0.012 1.1392  0     0.01243   243.8001  0  0.0309800003
% =========================================================================
%
% There is no header, but the fields appear to be:
% GPS-SOW      DATE          Lat deg,min,sec   Lon deg,min,sec       elev m       ?/pitch    NA    NA    ?/roll       NA    NA        Heading   NA NA

% Format 2011 Antarctica TO:
% =========================================================================
% 160655.52   12/13/2011    -77 57 05.28618    166 30 35.94068        -45.443     0.1118350000     0.0000000000     0.0056934711     0.9424050000     0.0000000000     0.0056666844   106.3087120000     0.0000000000     0.  0320764817
% =========================================================================
%
% There is no header, but the fields appear to be:
% GPS-SOW      DATE          Lat deg,min,sec   Lon deg,min,sec       elev m       ?/pitch    NA    NA    ?/roll       NA    NA        Heading   NA NA

% 1. Seconds of week (GPS time)
%  Field 1
% 2. Date (GPS time)
%  Field 2
% 3. Latitude (deg,min,sec)
%  Field 3-5
% 4. Longitude (deg,min,sec)
%  Field 6-8
% 5. Elevation (m) with respect to WGS-84 ellipsoid
%  Field 9
% 6. Pitch (deg) [value, separation?, standard deviation]
%  Field 10-12 --> Field 13-15 sometimes
% 7. Roll (deg) [value, separation?, standard deviation]
%  Field 13-15 --> Field 16-18 sometimes
% 8. Heading (deg) [value, separation?, standard deviation]
%  Field 16-18 --> Field 10-12 sometimes

[fid,msg] = fopen(fn,'r');
if fid < 1
  fprintf('Could not open file %s\n', fn{fn_idx});
  error(msg);
end

% Check to see if first line of file is empty
first_line = fgets(fid);

% Normally the header is not first (pitch, roll, heading)
heading_first = false;

if all(isspace(first_line))
  % Skip to header line
  done = false;
  while ~done
    header_line = fgets(fid);
  
    % Interpret header line to determine if heading or pitch comes first
    headers = textscan(header_line,'%s');
    
    if ~isempty(headers)
      headers = headers{1};
      if length(headers)>=6 && strcmpi(headers{1},'CorrTime')
        done = true;
        if strcmpi(headers{6},'Heading')
          % Heading is first (heading, pitch, roll)
          heading_first = true;
        end
      end
    end
  end
  
  % Skip one more header line to get to the first data line
  fgets(fid);
  
else
  % This file does not have a header, data starts on first line
  fseek(fid,0,-1);
end

% Read the data and close the file
A = textscan(fid,'%f %s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f');
fclose(fid);

% Convert SOW and date into absolute time
dates = datenum(A{2});
gps.gps_time = A{1};

% Fix bug in Novatel files... at the week wrap of the seconds of week,
% the date is bad.
diff_time = diff(gps.gps_time);
median_diff_time = median(diff_time);
bad_idxs = [0; abs(diff_time - median_diff_time) > 2.5];
if ~isempty(bad_idxs)
  warning('Found some large gps time jumps in seconds of week field, discarding\n');
end
dates = dates(~bad_idxs);
gps.gps_time = gps.gps_time(~bad_idxs);

diff_dates = diff(dates);
bad_idx = find(diff_dates < 0)+1;
if ~isempty(bad_idx)
  warning('Found a week wrap in the dates/seconds of week field\n');
  dates(bad_idx:end) = dates(bad_idx:end) + 7;
end

gps.gps_time = gps_sow_to_epoch(gps.gps_time,dates);

if strcmpi(param.time_reference,'utc')
  warning('Normally these files are GPS time reference');
  % UTC time stored in file, so need to add leap seconds back in
  gps.gps_time = gps.gps_time + utc_leap_seconds(gps.gps_time(1));
elseif strcmpi(param.time_reference,'gps')
else
  error('You must specify a time reference');
end

gps.lat = sign(A{3}).*(abs(A{3}) + A{4}/60 + A{5}/3600);
gps.lon = sign(A{6}).*(abs(A{6}) + A{7}/60 + A{8}/3600);

gps.elev = A{9};

if heading_first
  gps.heading = A{10}/180*pi;
  gps.pitch = A{13}/180*pi;
  gps.roll = A{16}/180*pi;
else
  gps.pitch = A{10}/180*pi;
  gps.roll = A{13}/180*pi;
  gps.heading = A{16}/180*pi;
end

gps.gps_time = reshape(gps.gps_time,[1 length(gps.gps_time)]);
gps.lat = reshape(gps.lat,[1 length(gps.lat)]);
gps.lon = reshape(gps.lon,[1 length(gps.lon)]);
gps.elev = reshape(gps.elev,[1 length(gps.elev)]);
gps.roll = reshape(gps.roll,[1 length(gps.roll)]);
gps.pitch = reshape(gps.pitch,[1 length(gps.pitch)]);
gps.heading = reshape(gps.heading,[1 length(gps.heading)]);

gps.lat = gps.lat(~bad_idxs);
gps.lon = gps.lon(~bad_idxs);
gps.elev = gps.elev(~bad_idxs);
gps.roll = gps.roll(~bad_idxs);
gps.pitch = gps.pitch(~bad_idxs);
gps.heading = gps.heading(~bad_idxs);

return;
