function gps = read_gps_litton(litton_fn, param)
% gps = read_gps_litton(litton_fn, param)
%
% Read's GPS data from the Litton 100.
%
% litton_fn = filename of Litton output OR a cell array of files
% param = struct passed to gps_sow_to_epoch.m that gives absolute
%   reference to find which GPS week we are in. Fields:
%  .year
%  .month
%  .day
%  .time_reference = 'gps' or 'utc' ('gps' is default)
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
% File format: ASCII with seven fields
% time(seconds of day)  lat lon elev pitch  roll  heading
%
% Example:
%
%   fn = '/users/paden/tmp/litton_20100503/ln100g.20100503_151708.bin.asc';
%   gps = read_ins_litton(fn,struct('year',2010,'month',05,'day',3,'time_reference','gps'));
%   gps_plot(gps);
%
%   fns = get_filenames('/users/paden/tmp/litton_20100503/','ln100g.','','.bin.asc');
%   gps = read_ins_litton(fns,struct('year',2010,'month',05,'day',3,'time_reference','gps'));
%   gps_plot(gps);
%
% Author: John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

if ischar(litton_fn)
  tmp = litton_fn;
  litton_fn = cell(1);
  litton_fn{1} = tmp;
end

C = cell(0);
for file_idx = 1:length(litton_fn)
  fprintf('Opening file %s\n',litton_fn{file_idx});
  [fid,msg] = fopen(litton_fn{file_idx},'r');
  if fid < 1
    fprintf('Could not open file %s\n', litton_fn{file_idx});
    error(msg);
  end
  
  Cnew = textscan(fid,'%f%f%f%f%f%f%f');
  %   fprintf('  %d %d %d %d\n',length(Cnew{1}),length(Cnew{2}), ...
  %     length(Cnew{3}),length(Cnew{4}));
  if file_idx == 1
    C = Cnew;
  else
    for idx = 1:7
      C{idx} = cat(1,C{idx},Cnew{idx});
    end
  end
  fclose(fid);
end

gps_sod = C{1};

gps.lat = C{2};
gps.lon = C{3};
gps.elev = C{4};

gps.pitch= C{6}/180*pi;
gps.roll = C{5}/180*pi;
gps.heading = C{7}/180*pi;

dt = median(diff(gps_sod));

cur_time = gps_sod(1)-1;
bad_mask = zeros(size(gps_sod));
for idx = 1:length(gps_sod)
  if gps_sod(idx) <= cur_time
    bad_mask(idx) = 1;
  else
    if gps_sod(idx) >= cur_time + 10*dt && idx > 1
      fprintf('Skip at idx %d time %f skip %f\n', idx, ...
        gps_sod(idx), gps_sod(idx)-cur_time);
    end
    cur_time = gps_sod(idx);
  end
end
fprintf('Removing %d records due to repeat time stamps\n', sum(bad_mask));

gps_sod = gps_sod(~bad_mask);

gps.gps_time = datenum_to_epoch( ...
  datenum([repmat([param.year param.month param.day 0 0],[length(gps_sod) 1]) gps_sod]));

gps.lat = gps.lat(~bad_mask);
gps.lon = gps.lon(~bad_mask);
gps.elev = gps.elev(~bad_mask);

if strcmpi(param.time_reference,'utc')
  % UTC time stored in file, so need to add leap seconds back in
  gps.gps_time = gps.gps_time + utc_leap_seconds(gps.gps_time(1));
end

gps.pitch = gps.pitch(~bad_mask);
gps.roll = gps.roll(~bad_mask);
gps.heading = gps.heading(~bad_mask);

% Take mod 2*pi in uniform way:
gps.heading = angle(exp(j*gps.heading));

% ENSURE ALL VECTORS IN 1xN FORMAT
gps.gps_time = reshape(gps.gps_time,[1 length(gps.gps_time)]);
gps.lat = reshape(gps.lat,[1 length(gps.lat)]);
gps.lon = reshape(gps.lon,[1 length(gps.lon)]);
gps.elev = reshape(gps.elev,[1 length(gps.elev)]);
gps.pitch = reshape(gps.pitch,[1 length(gps.pitch)]);
gps.roll = reshape(gps.roll,[1 length(gps.roll)]);
gps.heading = reshape(gps.heading,[1 length(gps.heading)]);

return;




