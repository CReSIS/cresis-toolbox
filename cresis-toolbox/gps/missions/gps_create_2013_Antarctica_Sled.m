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

gps_path = fullfile(support_path,'gps','2013_Antarctica_Sled');
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

in_base_path = fullfile(data_support_path,'2013_Antarctica_Sled');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'accum';
if strcmpi(gps_source_to_use,'accum')
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = {fullfile(in_base_path,'accum2_20130107_204649.gps'),...
%                       fullfile(in_base_path,'accum2_20130107_214152.gps'),...
%                       fullfile(in_base_path,'accum2_20130107_215023.gps'),...
%                       fullfile(in_base_path,'accum2_20130107_230650.gps')};
%   out_fns{file_idx} = 'gps_20130107.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',01,'day',07,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20130107_204649.gps'),...
%                         fullfile(in_base_path,'accum2_20130107_214152.gps'),...
%                         fullfile(in_base_path,'accum2_20130107_215023.gps'),...
%                         fullfile(in_base_path,'accum2_20130107_230650.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',01,'day',07,'time_reference','utc','format',3);

%   file_idx = file_idx + 1;
%   in_fns{file_idx} = {fullfile(in_base_path,'accum2_20130111_204833.gps'),...
%                       fullfile(in_base_path,'accum2_20130111_211109.gps'),...
%                       fullfile(in_base_path,'accum2_20130111_213821.gps')};
%   out_fns{file_idx} = 'gps_20130111.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',01,'day',11,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20130111_204833.gps'),...
%                         fullfile(in_base_path,'accum2_20130111_211109.gps'),...
%                         fullfile(in_base_path,'accum2_20130111_213821.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',01,'day',11,'time_reference','utc','format',3);

%%% ISSUE %%%
%   file_idx = file_idx + 1; 
%   in_fns{file_idx} = {fullfile(in_base_path,'accum2_20130112_022119.gps'),...
%                       fullfile(in_base_path,'accum2_20130112_023007.gps')};
%   out_fns{file_idx} = 'gps_20130112.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',01,'day',13,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20130112_022119.gps'),...
%                         fullfile(in_base_path,'accum2_20130112_023007.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',01,'day',13,'time_reference','utc','format',3);

%   file_idx = file_idx + 1;
%   in_fns{file_idx} = {fullfile(in_base_path,'accum2_20130113_015936.gps'),...
%                       fullfile(in_base_path,'accum2_20130113_021651.gps'),...
%                       fullfile(in_base_path,'accum2_20130113_030519.gps'),...
%                       fullfile(in_base_path,'accum2_20130113_032547.gps'),...
%                       fullfile(in_base_path,'accum2_20130113_040235.gps')};
%   out_fns{file_idx} = 'gps_20130113.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',01,'day',13,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20130113_015936.gps'),...
%                         fullfile(in_base_path,'accum2_20130113_021651.gps'),...
%                         fullfile(in_base_path,'accum2_20130113_030519.gps'),...
%                         fullfile(in_base_path,'accum2_20130113_032547.gps'),...
%                         fullfile(in_base_path,'accum2_20130113_040235.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',01,'day',13,'time_reference','utc','format',3);
  
%   file_idx = file_idx + 1; 
%   in_fns{file_idx} = {fullfile(in_base_path,'accum2_20130116_200204.gps'),...
%                       fullfile(in_base_path,'accum2_20130116_203725.gps')};
%   out_fns{file_idx} = 'gps_20130116.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',01,'day',16,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20130116_200204.gps'),...
%                         fullfile(in_base_path,'accum2_20130116_203725.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',01,'day',16,'time_reference','utc','format',3);

%   file_idx = file_idx + 1;
%   in_fns{file_idx} = {fullfile(in_base_path,'accum2_20130117_010900.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_012814.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_032536.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_032806.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_033240.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_033817.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_034620.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_035613.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_040021.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_040940.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_042804.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_043405.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_045402.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_045826.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_051423.gps'),...
%                       fullfile(in_base_path,'accum2_20130117_051726.gps')};
%   out_fns{file_idx} = 'gps_20130117.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',01,'day',17,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20130117_010900.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_012814.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_032536.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_032806.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_033240.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_033817.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_034620.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_035613.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_040021.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_040940.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_042804.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_043405.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_045402.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_045826.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_051423.gps'),...
%                         fullfile(in_base_path,'accum2_20130117_051726.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',01,'day',17,'time_reference','utc','format',3);

%   file_idx = file_idx + 1;
%   in_fns{file_idx} = {fullfile(in_base_path,'accum2_20130120_215210.gps'),...
%                       fullfile(in_base_path,'accum2_20130120_230725.gps'),...
%                       fullfile(in_base_path,'accum2_20130120_234144.gps')};
%   out_fns{file_idx} = 'gps_20130120.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',01,'day',20,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20130120_215210.gps'),...
%                         fullfile(in_base_path,'accum2_20130120_230725.gps'),...
%                         fullfile(in_base_path,'accum2_20130120_234144.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',01,'day',20,'time_reference','utc','format',3);

%   file_idx = file_idx + 1;
%   in_fns{file_idx} = {fullfile(in_base_path,'accum2_20130120_234144.gps')};
%   out_fns{file_idx} = 'gps_20130121.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2013,'month',01,'day',21,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = {fullfile(in_base_path,'accum2_20130120_234144.gps')};
%   sync_params{file_idx} = struct('year',2013,'month',01,'day',21,'time_reference','utc','format',3);
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



