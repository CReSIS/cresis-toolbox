function wp = read_gps_sonntagsequence2(fn)
% wp = read_gps_sonntagsequence2(fn)
%
% Sonntag navigation software waypoint reader.
% 
% John Sonntag's navigation software takes a waypoints file where each line
% contains one waypoint, space delimited fields, with fields:
% 1. waypoint string with no spaces
% 2. lat (deg,N)
% 3. lon (deg,E)
% 4. elev (meters, WGS-84)
% 
% Example:
% NPX -89.9990 90.0000 11200
% cas_340_6000 -89.3300 -20.0000 14950
% CLXr84p90 -88.4822 38.0367 15500
% CLXr84p88 -88.3292 41.7100 11650
% CLXr84p46 -84.6462 64.1158 13450
% CLXr84p42 -84.2835 64.7233 13650
% CLXr76p42 -84.3068 66.8772 13650
% CLXr76p46 -84.6733 66.6340 13450
% CLXr76p88 -88.5053 56.8550 12000
% CLXr76p90 -88.6835 54.9785 15950
% NPX -89.9990 90.0000 15500
% NPX -89.9990 90.0000 11200


fid = fopen(fn);
A = textscan(fid,'%s %f %f %f');
fclose(fid);

wp.name = A{1};
wp.lat = A{2};
wp.lon = A{3};
% Convert from feet to meters
wp.elev = A{4} * 12*2.54/100;
