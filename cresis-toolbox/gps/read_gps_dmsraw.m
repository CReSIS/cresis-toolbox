function gps = read_gps_dmsraw(fn,param)
% gps = read_gps_dmsraw(fn,param)
%
% This function reads the raw GPS/INS data output from an Applanix system.
% This is the format DMS gave us for testflight data.  I added a date field
% in column 2 by hand.
%
% File Format: .csv
% Seconds of Week	Date	Latitude	Longitude	Altitude	Roll	Pitch	True Heading
% 135376.957	3/5/2012	37.93319311	-75.47048079	-23.9530238	0.363419776	-1.553658714	212.4498188
%
% gps = structure of the output
% param = 
%  .time_reference = 'gps' or 'utc'
%
% Examples: See end of file
%
% Author: Huan Zhao, John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

[fid,msg] = fopen(fn,'r');
if fid < 1
fprintf('Could not open file %s\n', fn{fn_idx});
error(msg);
end

A = textscan(fid,'%f %s %f %f %f %f %f %f', 'Delimiter',',','Headerlines', 1);

fclose(fid);

dates = datenum(A{2});
gps.gps_time = A{1};
for idx = 1:length(A{1})
  gps.gps_time(idx) = gps_sow_to_epoch(gps.gps_time(idx),dates(idx));
end

if strcmpi(param.time_reference,'utc')
  % UTC time stored in file, so need to add leap seconds back in
  gps.gps_time = gps.gps_time + utc_leap_seconds(gps.gps_time(1));
end

gps.lat = A{3};
gps.lon = A{4};

gps.elev = A{5};

gps.roll = A{6}/180*pi;
gps.pitch = A{7}/180*pi;
gps.heading = A{8}/180*pi;

return;

% ================================================================
% ================================================================
% Examples
% ================================================================
% ================================================================

fns = get_filenames('/cresis/scratch2/hzhao/Twinotter_output/','','','*.txt');

% Choose a file of interest from the list:
fn = fns{2};

tic; gps = read_gps_novatel(fn); toc;

gps_plot(gps);




