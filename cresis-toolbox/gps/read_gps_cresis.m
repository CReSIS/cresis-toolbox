function gps = read_gps_cresis(fn,param)
% gps = read_gps_cresis(fn,param)
%
% This function reads the DGPS/INS data output from the Waypoint Inertial
% Explorer from NovAtel, Canada. The format is:
%  16 header lines
%  9 columns (space in between each one)
%  1: 10 chars: GPS Date YYYY/MM/DD
%  2: 9 chars: GPS Time Seconds of Day S.FF (sec)
%  3: 14 chars: Latitude (deg)
%  4: 15 chars: Longitude (deg)
%  5: 12 chars: H-ellipsoid WGS1984 (m)
%  6: 14 chars: Roll (deg)
%  7: 14 chars: Pitch (deg)
%  8: 14 chars: Heading (deg)
%  9: 12 chars: Standard devision of position, estimate of accuracy (m)
% Example:
%2013/09/21 72007.52  51.1173063345 -114.0195467099     1067.619  -1.1887370000  11.5422700000 212.3486410000        0.028
%
% gps = structure of the output
%  .lat
%  .lon
%  .elev
%  .roll
%  .pitch
%  .heading
% param =
%  .time_reference = 'gps' or 'utc'
%
% Examples:
%  fn = 'C:\Users\dangermo\Desktop\GPS\test1.txt';
%  gps = read_gps_cresis(fn);
%  gps_plot(gps);
%
% Author: John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m


[fid,msg] = fopen(fn,'r');
if fid < 1
  fprintf('Could not open file %s\n', fn);
  error(msg);
end

A = textscan(fid,'%f %f %f %f %f %f %f %f %f %f %f', 'Headerlines', 20, 'Delimiter', sprintf('/ \t'), 'MultipleDelimsAsOne', true);

fclose(fid);

[year month day sod gps.lat gps.lon gps.elev gps.roll gps.pitch gps.heading stdev] = deal(A{:});
gps.gps_time = datenum_to_epoch(datenum(year,month,day,0,0,sod));
gps.roll = gps.roll/180*pi;
gps.pitch = gps.pitch/180*pi;
gps.heading = gps.heading/180*pi;

gps.gps_time = reshape(gps.gps_time,[1 length(gps.gps_time)]);
gps.lat = reshape(gps.lat,[1 length(gps.lat)]);
gps.lon = reshape(gps.lon,[1 length(gps.lon)]);
gps.elev = reshape(gps.elev,[1 length(gps.elev)]);
gps.roll = reshape(gps.roll,[1 length(gps.roll)]);
gps.pitch = reshape(gps.pitch,[1 length(gps.pitch)]);
gps.heading = reshape(gps.heading,[1 length(gps.heading)]);

return;
