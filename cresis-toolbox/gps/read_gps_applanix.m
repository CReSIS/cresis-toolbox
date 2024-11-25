function gps = read_gps_applanix(applanix_fn, param)
% gps = read_gps_applanix(applanix_fn, param)
%
% Read's Applanix data. This is PPP GPS/INS data from 2009 Antarctica DC-8
% and beyond (NASA runs Applanix 510 and 610).
% Generally elevation data is referenced to the WGS-84 ellipsoid.
%
%   WARNING: Applanix time may be in GPS or UTC time!
%
% applanix_fn = filename of Applanix output (see format below)
% param = struct passed to gps_sow_to_epoch.m that gives absolute
%   reference to find which GPS week we are in. Fields:
%  .year
%  .month
%  .day
%  .time_reference = 'gps' or 'utc'
%  .roll_byte_offset: offset in bytes to the roll field (default 56)
%    Some 2016 Antarctica DC8 data requires 64
%  .pitch_byte_offset: offset in bytes to the pitch field (default 64)
%    Some 2016 Antarctica DC8 data requires 56
%
% gps = struct of position and attitude data, each N x 1 vectors
%   where N is the number of records in the file. The fields are:
%  .time = GPS time in seconds since Jan 1, 1970 epoch (sec)
%  .lat = latitude (deg)
%  .lon = longitude (deg)
%  .elev = elevation (m)
%  .roll = roll (rad)
%  .pitch = pitch (rad)
%  .heading = true heading (rad)
%
% POSPROC STANDARD NAVIGATION RECORD format
% The table below shows the post-processed output file. The output
% is a sequential binary file consistent with C-language sequential
% files of Fortran binary files. C-language data types used to
% specify the individual data items have the following sizes:
% C-Type  FORTRAN Type          Length
% double  double precision real 8 bytes
% long    integer               4 bytes
% logical logical               1 byte
% 
% Total Length 136 bytes
% Data Item Units Type
% time seconds double
% Latitude radians double
% Longitude radians double
% Altitude meters double
% x w.a. velocity meters/second double
% y w.a. velocity meters/second double
% z w.a. velocity meters/second double
% roll radians double
% pitch radians double
% platform heading radians double
% wander angle radians double
% x body specific force meters/second double
% y body specific force meters/second double
% z body specific force meters/second double
% x body angular rate radians/second double
% y body angular rate radians/second double
% z body angular rate radians/second double
% copied from Applanix (Applied Analytics Corporation),
% postproc Version 1.1 User Manual,
% Section 4.5: Output Data Files
% The postproc STANDARD NAVIGATION RECORD format.
% 40908441 Release 1.0 (July 19, 1995)
%
% Example:
%
%   fn = '/cresis/scratch1/mdce/csarp_support/gps/2009_Antarctica_DC8_DGPSwINS/Javadsbet_02Nov09_PPP_Revised.out'
%   gps = read_gps_applanix(fn,struct('year',2009,'month',11,'day',2,'time_reference','gps'));
%   gps_plot(gps);
%   datestr(epoch_to_datenum(gps.gps_time(1)));
%   gps.utc_time = gps.gps_time - utc_leap_seconds(gps.gps_time(1))
% 
% Author: John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

if ~isfield(param,'roll_byte_offset') || isempty(param.roll_byte_offset)
  param.roll_byte_offset = 56;
end

if ~isfield(param,'pitch_byte_offset') || isempty(param.pitch_byte_offset)
  param.pitch_byte_offset = 64;
end

[fid,msg] = fopen(applanix_fn,'r');
if fid < 1
  fprintf('Could not open file %s\n', applanix_fn);
  error(msg);
end

gps.gps_time = fread(fid,inf,'float64',16*8);
gps.gps_time = gps_sow_to_epoch(gps.gps_time,param);

if strcmpi(param.time_reference,'utc')
  % UTC time stored in file, so need to add leap seconds back in
  gps.gps_time = gps.gps_time + utc_leap_seconds(gps.gps_time(1));
end

fseek(fid,8,'bof');
gps.lat = fread(fid,inf,'float64',16*8) * 180/pi;

fseek(fid,16,'bof');
gps.lon = fread(fid,inf,'float64',16*8) * 180/pi;

fseek(fid,24,'bof');
gps.elev = fread(fid,inf,'float64',16*8);

fseek(fid,param.pitch_byte_offset,'bof');
gps.pitch = fread(fid,inf,'float64',16*8);

fseek(fid,param.roll_byte_offset,'bof');
gps.roll = fread(fid,inf,'float64',16*8);

fseek(fid,72,'bof');
heading_data = fread(fid,[2 inf],'2*float64',15*8);
gps.heading = (heading_data(1,:) - heading_data(2,:)).';
% Take mod 2*pi in uniform way:
gps.heading = angle(exp(j*gps.heading));

fclose(fid);

% Reshape into row vectors
gps.gps_time = reshape(gps.gps_time,[1 length(gps.gps_time)]);
gps.lat = reshape(gps.lat,[1 length(gps.lat)]);
gps.lon = reshape(gps.lon,[1 length(gps.lon)]);
gps.elev = reshape(gps.elev,[1 length(gps.elev)]);
gps.roll = reshape(gps.roll,[1 length(gps.roll)]);
gps.pitch = reshape(gps.pitch,[1 length(gps.pitch)]);
gps.heading = reshape(gps.heading,[1 length(gps.heading)]);

return;




