% script gps_create_2013_antarctica_Ground
%
% Makes the GPS files for 2013 Antarctica Basler field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2013_Antarctica_Ground');
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

% ======================================================================
% User Settings
% ======================================================================
debug_level = 1;

in_base_path = fullfile(data_support_path,'2013_Antarctica_Ground');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'accum';
if strcmpi(gps_source_to_use,'accum')
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'accum2_20131217.gps');
%   out_fns{file_idx} = 'gps_20131217.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',12,'day',16,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20131217.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',12,'day',16,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'accum2_20131219.gps');
%   out_fns{file_idx} = 'gps_20131219.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',12,'day',19,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20131219.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',12,'day',19,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'accum2_20131220.gps');
%   out_fns{file_idx} = 'gps_20131220.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',12,'day',20,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20131220.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',12,'day',20,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'accum2_20131221.gps');
%   out_fns{file_idx} = 'gps_20131221.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',12,'day',21,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20131221.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',12,'day',21,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'accum2_20131223.gps');
%   out_fns{file_idx} = 'gps_20131223.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',12,'day',23,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20131223.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',12,'day',23,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'accum2_20140102.gps');
%   out_fns{file_idx} = 'gps_20140102.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2014,'month',01,'day',02,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20140102.gps')};
%   sync_params{file_idx} = struct('year',2014,'month',01,'day',02,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'accum2_20140103.gps');
%   out_fns{file_idx} = 'gps_20140103.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2014,'month',01,'day',03,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20140103.gps')};
%   sync_params{file_idx} = struct('year',2014,'month',01,'day',03,'time_reference','utc','format',3);
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'accum2_20140107.gps');
%   out_fns{file_idx} = 'gps_20140107.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2014,'month',01,'day',07,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20140107.gps')};
%   sync_params{file_idx} = struct('year',2014,'month',01,'day',07,'time_reference','utc','format',3);
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'accum2_20140108.gps');
%   out_fns{file_idx} = 'gps_20140108.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2014,'month',01,'day',08,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20140108.gps')};
%   sync_params{file_idx} = struct('year',2014,'month',01,'day',08,'time_reference','utc','format',3);
   
%   file_idx = file_idx + 1;
%   year = 2014; month = 1; day = 10;
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('accum2_%04d%02d%02d.gps',year,month,day));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,sprintf('accum2_%04d%02d%02d.gps',year,month,day))};
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
   
%   file_idx = file_idx + 1;
%   year = 2014; month = 1; day = 16;
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('accum2_%04d%02d%02d.gps',year,month,day));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,sprintf('accum2_%04d%02d%02d.gps',year,month,day))};
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
   
%   file_idx = file_idx + 1;
%   year = 2014; month = 1; day = 17;
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('accum2_%04d%02d%02d.gps',year,month,day));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,sprintf('accum2_%04d%02d%02d.gps',year,month,day))};
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
   
%   file_idx = file_idx + 1;
%   year = 2014; month = 1; day = 18;
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('accum2_%04d%02d%02d.gps',year,month,day));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,sprintf('accum2_%04d%02d%02d.gps',year,month,day))};
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
   
%   file_idx = file_idx + 1;
%   year = 2014; month = 1; day = 19;
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('accum2_%04d%02d%02d.gps',year,month,day));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,sprintf('accum2_%04d%02d%02d.gps',year,month,day))};
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

end


% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;


% Smooth NMEA GPS data
% Correct for GPS to UTC time jumps that happen at beginning
% out_fns = get_filenames('/mnt/products/csarp_support/gps/2013_Antarctica_Ground/','gps','','.mat');
for file_idx = 1:length(out_fns)
  
  if ~isempty(findstr('nmea',gps_source{file_idx}))
    out_fn = fullfile(gps_path,out_fns{file_idx});
    
    fprintf('Filtering gps %s\n', out_fn);
    gps = load(out_fn);
    
    figure(1); clf;
    plot(gps.lat);
    [B,A] = butter(4,1/15);

    % Find the breaks in the GPS data (e.g. where GPS was turned on/off)
    break_idxs = [0 find(diff(gps.gps_time) > 30)];
    for idx = 1:length(break_idxs)
      % Filter this segment of GPS data
      if idx == length(break_idxs)
        segment_idxs = break_idxs(idx)+1 : length(gps.gps_time);
      else
        segment_idxs = break_idxs(idx)+1 : break_idxs(idx+1);
      end
      
      % Correct GPS to UTC time jumps (happen when GPS receiver finally locks)
      backward_jump_idx = find(diff(gps.gps_time(segment_idxs)) < 0.1);
      if ~isempty(backward_jump_idx)
        if length(backward_jump_idx) > 1
          % Should only be one jump per segment... assuming GPS receiver
          % stays locked the whole time.
          keyboard
        end
        jump_size = gps.gps_time(segment_idxs(backward_jump_idx+1)) ...
          - gps.gps_time(segment_idxs(backward_jump_idx));
        if abs(jump_size+utc_leap_seconds(gps.gps_time(1))) < 1.5
          gps.gps_time(segment_idxs(1:backward_jump_idx)) ...
            = gps.gps_time(segment_idxs(1:backward_jump_idx)) ...
            + jump_size - median(diff(gps.gps_time));
        else
          % Jump does not match GPS to UTC conversion
          keyboard
        end
      end
      gps.lat(segment_idxs) = filtfilt(B,A,gps.lat(segment_idxs));
      gps.lon(segment_idxs) = filtfilt(B,A,gps.lon(segment_idxs));
      gps.elev(segment_idxs) = filtfilt(B,A,gps.elev(segment_idxs));
    end
    
    hold on;
    plot(gps.lat,'r');
    hold off;
    drawnow;
    pause(0.1);
    save(out_fn,'-append','-struct','gps');
  end
end



