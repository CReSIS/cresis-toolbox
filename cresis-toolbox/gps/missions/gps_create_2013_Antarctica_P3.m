% script gps_create_2013_antarctica_P3
%
% Makes the GPS files for 2013 Antarctica P3 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
    support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2013_Antarctica_P3');
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

in_base_path = fullfile(data_support_path,'2013_Antarctica_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'ATM';
% gps_source_to_use = 'ATM-field';
% gps_source_to_use = 'NMEA';
% gps_source_to_use = 'Gravimeter';

if strcmpi(gps_source_to_use,'ATM')
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_18Nov13_PPPK_P09Dec13.out');
  %   out_fns{file_idx} = 'gps_20131119.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2013,'month',11,'day',18,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-final_20131220';
  %   sync_flag{file_idx} = 0;
  %   %
  %   %
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_19Nov13_PPPK_P09Dec13.out');
%   out_fns{file_idx} = 'gps_20131120.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',11,'day',19,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20131220';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',2013,11,20),'','.gps');
%   sync_fns{file_idx}(end-3:end) = [];
%   sync_params{file_idx} = struct('year',2013,'month',11,'day',19,'time_reference','utc','format',3);
  
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_20Nov13_PPPK_P10Dec13.out');
%   out_fns{file_idx} = 'gps_20131121.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',11,'day',20,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20131220';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',2013,11,20),'','.gps');
%   sync_fns{file_idx} = sync_fns{file_idx}(end-3:end);
%   sync_params{file_idx} = struct('year',2013,'month',11,'day',20,'time_reference','utc','format',3);
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_25Nov13_PPPK_P10Dec13.out');
%   out_fns{file_idx} = 'gps_20131126.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',11,'day',25,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20131220';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',2013,11,25),'','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',11,'day',25,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1; 
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_26Nov13_PPPK_P10Dec13.out');
%   out_fns{file_idx} = 'gps_20131127.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',11,'day',26,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20131220';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',2013,11,26),'','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',11,'day',26,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_27Nov13_PPPK_P10Dec13.out');
  out_fns{file_idx} = 'gps_20131128.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2013,'month',11,'day',27,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20131220';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',2013,11,27),'','.gps');
  sync_params{file_idx} = struct('year',2013,'month',11,'day',27,'time_reference','utc','format',3);
  
  
elseif strcmpi(gps_source_to_use,'ATM-field')
    %
    %   file_idx = file_idx + 1;
    %   in_fns{file_idx} = fullfile(in_base_path,'131119.gps');
    %   out_fns{file_idx} = 'gps_20131119.mat';
    %   file_type{file_idx} = 'ATM';
    %   params{file_idx} = struct('year',2013,'month',11,'day',19,'time_reference','gps');
    %   gps_source{file_idx} = 'ATM-field';
    %     sync_flag{file_idx} = 0;
    % %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130323','','.gps');
    % %     sync_params{file_idx} = struct('year',2013,'month',03,'day',23,'time_reference','utc','format',3);
    %
    % file_idx = file_idx + 1;
    % in_fns{file_idx} = fullfile(in_base_path,'131120.gps');
    % out_fns{file_idx} = 'gps_20131120.mat';
    % file_type{file_idx} = 'ATM';
    % params{file_idx} = struct('year',2013,'month',11,'day',20,'time_reference','gps');
    % gps_source{file_idx} = 'ATM-field';
    % sync_flag{file_idx} = 1;
    % sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20131120_combined','','.gps');
    % sync_params{file_idx} = struct('year',2013,'month',11,'day',19,'time_reference','utc','format',3);
    % %
    %
    % file_idx = file_idx + 1;
    % in_fns{file_idx} = fullfile(in_base_path,'131121.gps');
    % out_fns{file_idx} = 'gps_20131121.mat';
    % file_type{file_idx} = 'ATM';
    % params{file_idx} = struct('year',2013,'month',11,'day',21,'time_reference','gps');
    % gps_source{file_idx} = 'ATM-field';
    % sync_flag{file_idx} = 1;
    % sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20131121_combined','','.gps');
    % sync_params{file_idx} = struct('year',2013,'month',11,'day',20,'time_reference','utc','format',3);
    %
    %
    % %
    % file_idx = file_idx + 1;
    % in_fns{file_idx} = fullfile(in_base_path,'131126.gps');
    % out_fns{file_idx} = 'gps_20131126.mat';
    % file_type{file_idx} = 'ATM';
    % params{file_idx} = struct('year',2013,'month',11,'day',26,'time_reference','gps');
    % gps_source{file_idx} = 'ATM-field';
    % sync_flag{file_idx} = 1;
    % sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20131126_combined','','.gps');
    % sync_params{file_idx} = struct('year',2013,'month',11,'day',25,'time_reference','utc','format',3);
    %
    % %
    % file_idx = file_idx + 1;
    % in_fns{file_idx} = fullfile(in_base_path,'131127.gps');
    % out_fns{file_idx} = 'gps_20131127.mat';
    % file_type{file_idx} = 'ATM';
    % params{file_idx} = struct('year',2013,'month',11,'day',27,'time_reference','gps');
    % gps_source{file_idx} = 'ATM-field';
    % sync_flag{file_idx} = 1;
    % sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20131127_combined','','.gps');
    % sync_params{file_idx} = struct('year',2013,'month',11,'day',26,'time_reference','utc','format',3);
elseif strcmpi(gps_source_to_use,'NMEA')
    
    %   file_idx = file_idx + 1;
    %   in_fns{file_idx} = fullfile(in_base_path,'accum2_20131107_combined.gps');
    %   out_fns{file_idx} = 'gps_20131107.mat';
    %   file_type{file_idx} = 'NMEA';
    %   params{file_idx} = struct('year',2013,'month',11,'day',07,'format',3,'time_reference','utc');
    %   gps_source{file_idx} = 'nmea-field';
    %   sync_flag{file_idx} = 1;
    %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20131107_combined','','.gps');
    %   sync_params{file_idx} = struct('year',2013,'month',11,'day',07,'time_reference','utc','format',3);
    
    %   file_idx = file_idx + 1;
    %   in_fns{file_idx} = fullfile(in_base_path,'accum2_20131108_combined.gps');
    %   out_fns{file_idx} = 'gps_20131108.mat';
    %   file_type{file_idx} = 'NMEA';
    %   params{file_idx} = struct('year',2013,'month',11,'day',08,'format',3,'time_reference','utc');
    %   gps_source{file_idx} = 'nmea-field';
    %   sync_flag{file_idx} = 1;
    %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20131108_combined','','.gps');
    %   sync_params{file_idx} = struct('year',2013,'month',11,'day',08,'time_reference','utc','format',3);
    %
    
    %   file_idx = file_idx + 1;
    %   in_fns{file_idx} = fullfile(in_base_path,'GPS_112513_190418.txt');
    %   out_fns{file_idx} = 'gps_20131126.mat';
    %   file_type{file_idx} = 'NMEA';
    %   params{file_idx} = struct('year',2013,'month',11,'day',25,'format',3,'time_reference','utc');
    %   gps_source{file_idx} = 'nmea-field';
    %   sync_flag{file_idx} = 1;
    %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20131126_combined','','.gps');
    %   sync_params{file_idx} = struct('year',2013,'month',11,'day',25,'time_reference','utc','format',3);
    
elseif strcmpi(gps_source_to_use,'Gravimeter')
    %
    %   file_idx = file_idx + 1;
    %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_911.xyz');
    %   out_fns{file_idx} = 'gps_20131108.mat';
    %   file_type{file_idx} = 'TXT';
    %   params{file_idx} = struct('time_reference','utc');
    %   gps_source{file_idx} = 'gravimeter-field';
    %   sync_flag{file_idx} = 1;
    %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20131108','','.gps');
    %   sync_params{file_idx} = struct('year',2013,'month',11,'day',08,'time_reference','utc','format',3);
    
    %   file_idx = file_idx + 1;
    %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_401.xyz');
    %   out_fns{file_idx} = 'gps_20131119.mat';
    %   file_type{file_idx} = 'TXT';
    %   params{file_idx} = struct('time_reference','utc');
    %   gps_source{file_idx} = 'gravimeter-field';
    %   sync_flag{file_idx} = 0;
    %
    %   file_idx = file_idx + 1;
    %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_402.xyz');
    %   out_fns{file_idx} = 'gps_20131120.mat';
    %   file_type{file_idx} = 'TXT';
    %   params{file_idx} = struct('time_reference','utc');
    %   gps_source{file_idx} = 'gravimeter-field';
    %   sync_flag{file_idx} = 1;
    %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20131120_combined','','.gps');
    %   sync_params{file_idx} = struct('year',2013,'month',11,'day',20,'time_reference','utc','format',3);
    %
    %   file_idx = file_idx + 1;
    %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_911.xyz');
    %   out_fns{file_idx} = 'gps_20131108.mat';
    %   file_type{file_idx} = 'TXT';
    %   params{file_idx} = struct('time_reference','utc');
    %   gps_source{file_idx} = 'gravimeter-field';
    %   sync_flag{file_idx} = 1;
    %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20131108','','.gps');
    %   sync_params{file_idx} = struct('year',2013,'month',11,'day',08,'time_reference','utc','format',3);
    
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

% Hand correction of gps_20131107 accum2 sync radar time information
hand_idx = strmatch('gps_20131107.mat',out_fns);
if ~isempty(hand_idx)
    out_fn = fullfile(gps_path,out_fns{hand_idx});
    fprintf('Hand update of %s\n', out_fn);
    gps = load(out_fn);
    % Synthesize all fields
    gps.gps_time = datenum_to_epoch(datenum(2013,11,7,18,0,0)) ...
        : datenum_to_epoch(datenum(2013,11,7,23,0,0));
    gps.lat = 37.559932 + 125/111131.745 * (1:length(gps.gps_time));
    gps.lon = 07528.3222*ones(size(gps.gps_time));
    gps.elev = 21*ones(size(gps.gps_time));
    gps.roll = zeros(size(gps.gps_time));
    gps.pitch = zeros(size(gps.gps_time));
    
    along_track = geodetic_to_along_track(gps.lat,gps.lon,gps.elev);
    rlines = get_equal_alongtrack_spacing_idxs(along_track,10);
    physical_constants; % Load WGS84.spheroid
    for rline_idx = 1:length(rlines)
        rline = rlines(rline_idx);
        if rline_idx < length(rlines)
            rline_end = rlines(rline_idx+1);
        else
            rline_end = length(along_track);
        end
        [origin(1),origin(2),origin(3)] = geodetic2ecef(WGS84.spheroid, gps.lat(rline),gps.lon(rline),gps.elev(rline));
        [heading(1),heading(2),heading(3)] = geodetic2ecef(WGS84.spheroid, gps.lat(rline_end),gps.lon(rline_end),gps.elev(rline_end));
        heading = heading - origin;
        % Determine east vector
        [east(1) east(2) east(3)] = enu2ecef(1,0,0,gps.lat(rline),gps.lon(rline),gps.elev(rline),WGS84.spheroid);
        east = east - origin;
        % Determine north vector
        [north(1) north(2) north(3)] = enu2ecef(0,1,0,gps.lat(rline),gps.lon(rline),gps.elev(rline),WGS84.spheroid);
        north = north - origin;
        % Determine heading
        gps.heading(rline:rline_end) = atan2(dot(east,heading),dot(north,heading));
    end
    
    gps.comp_time = gps.gps_time;
    gps.sync_gps_time = gps.gps_time;
    gps.radar_time = 0:1:length(gps.gps_time)-1;
    save(out_fn,'-v6','-struct','gps');
end

% Hand correction of gps_20131108
hand_idx = strmatch('gps_20131108.mat',out_fns);
if ~isempty(hand_idx) && strcmpi(gps_source_to_use,'NMEA')
    out_fn = fullfile(gps_path,out_fns{hand_idx});
    fprintf('Hand update of %s\n', out_fn);
    gps = load(out_fn);
    orig_time = gps.gps_time;
    % Synthesize all fields
    gps.gps_time = gps.gps_time(end) ...
        : datenum_to_epoch(datenum(2013,11,8,24,0,0));
    gps.lat = interp1(orig_time, gps.lat, gps.gps_time,'linear','extrap');
    gps.lon = interp1(orig_time, gps.lon, gps.gps_time,'linear','extrap');
    gps.elev = 6000*ones(size(gps.gps_time));
    gps.roll = zeros(size(gps.gps_time));
    gps.pitch = zeros(size(gps.gps_time));
    
    along_track = geodetic_to_along_track(gps.lat,gps.lon,gps.elev);
    rlines = get_equal_alongtrack_spacing_idxs(along_track,10);
    physical_constants; % Load WGS84.spheroid
    for rline_idx = 1:length(rlines)
        rline = rlines(rline_idx);
        if rline_idx < length(rlines)
            rline_end = rlines(rline_idx+1);
        else
            rline_end = length(along_track);
        end
        [origin(1),origin(2),origin(3)] = geodetic2ecef(WGS84.spheroid, gps.lat(rline),gps.lon(rline),gps.elev(rline));
        [heading(1),heading(2),heading(3)] = geodetic2ecef(WGS84.spheroid, gps.lat(rline_end),gps.lon(rline_end),gps.elev(rline_end));
        heading = heading - origin;
        % Determine east vector
        [east(1) east(2) east(3)] = enu2ecef(1,0,0,gps.lat(rline),gps.lon(rline),gps.elev(rline),WGS84.spheroid);
        east = east - origin;
        % Determine north vector
        [north(1) north(2) north(3)] = enu2ecef(0,1,0,gps.lat(rline),gps.lon(rline),gps.elev(rline),WGS84.spheroid);
        north = north - origin;
        % Determine heading
        gps.heading(rline:rline_end) = atan2(dot(east,heading),dot(north,heading));
    end
    
    gps.comp_time = interp1(orig_time, gps.comp_time, gps.gps_time,'linear','extrap');
    gps.sync_gps_time = interp1(orig_time, gps.sync_gps_time, gps.gps_time,'linear','extrap');
    gps.radar_time = interp1(orig_time, gps.radar_time, gps.gps_time,'linear','extrap');
    save(out_fn,'-v6','-struct','gps');
end


