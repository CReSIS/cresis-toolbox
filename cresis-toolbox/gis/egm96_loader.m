function [lat,lon,egm96] = egm96_loader(fn)
% [lat,lon,egm96] = egm96_loader(fn): geoid loader
%
% Loads EGM96 geoid data from 
% http://earth-info.nga.mil/GandG/wgs84/gravitymod/egm96/egm96.html
%
% Specifically:
% http://earth-info.nga.mil/GandG/wgs84/gravitymod/egm96/binary/WW15MGH.DAC
%
% Data Description for 15 minute worldwide binary geoid height file:
% ---- FILE: WW15MGH.DAC
% The total size of the file is 2,076,480 bytes. This file was created
% using an INTEGER*2 data type format and is an unformatted direct access
% file. The data on the file is arranged in records from north to south.
% There are 721 records on the file starting with record 1 at 90 N. The
% last record on the file is at latitude 90 S. For each record, there
% are 1,440 15 arc-minute geoid heights arranged by longitude from west to
% east starting at the Prime Meridian (0 E) and ending 15 arc-minutes west
% of the Prime Meridian (359.75 E). On file, the geoid heights are in units
% of centimeters. While retrieving the Integer*2 values on file, divide by
% 100 and this will produce a geoid height in meters.
%
% fn = string containing input filename (path to WW15MGH.DAC file)
% lat = Nx1 double vector, latitude (deg,N)
% lon = Mx1 double vector, longitude (deg,E)
% egm = NxM double matrix containing error from WGS-84 of actual sea level (m)
%   First axis (row): Latitude
%   Second axis (col): Longitude
%
% Example:
% fn = ct_filename_gis([],'world\egm96_geoid\WW15MGH.DAC');
% [lat,lon,egm96] = egm96_loader(fn);
% imagesc(lon,lat,egm96/100);
% set(gca,'YDir','normal');
% xlabel('longitude (deg,E)');
% ylabel('latitude (deg,N)');
%
% interp2(lon,lat,egm96,mod(-155.812,360),71.361)
% 
% Author: John Paden

fid = fopen(fn,'r');

egm96 = fread(fid,[1440 721],'int16',0,'ieee-be');

fclose(fid);

egm96 = egm96.'/100;
lat = linspace(90,-90,721);
lon = linspace(0,359.75,1440);

return;




