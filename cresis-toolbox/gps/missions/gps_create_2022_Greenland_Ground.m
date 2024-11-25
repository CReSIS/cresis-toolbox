% script make_gps_2022_Greenland_Ground
%
% Makes the GPS files for 2022_Greenland_Ground field season

%% Setup
% =========================================================================
tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

season_name = '2022_Greenland_Ground';

gps_path = fullfile(support_path,'gps',season_name);
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

in_base_path = fullfile(data_support_path,season_name);

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

%% <== CHOOSE WHICH GPS SOURCE TO PROCESS
% gps_source_to_use = 'arena';
gps_source_to_use = 'cresis';

if strcmpi(gps_source_to_use,'arena')
  %% ARENA GPS SOURCE
  % =======================================================================
%   
  year = 2022; month = 5; day = 24;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  date_str{file_idx} = sprintf('%04d%02d%02d',year,month,day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('year',year,'time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
  year = 2022; month = 06; day = 02;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  date_str{file_idx} = sprintf('%04d%02d%02d',year,month,day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('year',year,'time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');

  year = 2022; month = 06; day = 07;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  date_str{file_idx} = sprintf('%04d%02d%02d',year,month,day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('year',year,'time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');

  year = 2022; month = 06; day = 13;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  date_str{file_idx} = sprintf('%04d%02d%02d',year,month,day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('year',year,'time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');

  year = 2022; month = 06; day = 27;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  date_str{file_idx} = sprintf('%04d%02d%02d',year,month,day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('year',year,'time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
    
elseif strcmpi(gps_source_to_use,'cresis')
  %% CRESIS GPS SOURCE
  % =======================================================================
  
%   year = 2022; month = 5; day = 24;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ie_%04d%02d%02d',year,month,day)),sprintf('ie_%04d%02d%02d',year,month,day),'','*.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('time_reference','gps','headerlines',16,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'cresis-final_20230304';
%   date_str{file_idx} = sprintf('%04d%02d%02d',year,month,day);
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2022; month = 6; day = 2;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ie_%04d%02d%02d',year,month,day)),sprintf('ie_%04d%02d%02d',year,month,day),'','*.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('time_reference','gps','headerlines',16,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'cresis-final_20230304';
%   date_str{file_idx} = sprintf('%04d%02d%02d',year,month,day);
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
  
  year = 2022; month = 6; day = 7;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ie_%04d%02d%02d',year,month,day)),sprintf('ie_%04d%02d%02d',year,month,day),'','*.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps','headerlines',16,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
  params{file_idx}.textscan = {};
  gps_source{file_idx} = 'cresis-final_20230304';
  date_str{file_idx} = sprintf('%04d%02d%02d',year,month,day);
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
%   year = 2022; month = 6; day = 13;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ie_%04d%02d%02d',year,month,day)),sprintf('ie_%04d%02d%02d',year,month,day),'','*.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('time_reference','gps','headerlines',16,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'cresis-final_20230304';
%   date_str{file_idx} = sprintf('%04d%02d%02d',year,month,day);
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2022; month = 6; day = 27;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ie_%04d%02d%02d',year,month,day)),sprintf('ie_%04d%02d%02d',year,month,day),'','*.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('time_reference','gps','headerlines',16,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'cresis-final_20230304';
%   date_str{file_idx} = sprintf('%04d%02d%02d',year,month,day);
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
  
  
end

%% gps_create
% Read and translate files according to user settings
% =========================================================================
gps_create;

%% custom fixes
% =========================================================================
for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  load(out_fn,'gps_source');
  if ~isempty(regexpi(gps_source,'arena'))
    % Extrapolation is necessary because GPS data starts after/stops before
    % the beginning/end of the radar data.
    warning('Extrapolating and filtering elevation for arena GPS data: %s', out_fn);
    gps = load(out_fn);
    
    if length(gps.lat) >= 2
      new_gps_time = [gps.gps_time(1)-10, gps.gps_time,gps.gps_time(end)+10];
      gps.lat = interp1(gps.gps_time,gps.lat,new_gps_time,'linear','extrap');
      gps.lon = interp1(gps.gps_time,gps.lon,new_gps_time,'linear','extrap');
      gps.elev = interp1(gps.gps_time,gps.elev,new_gps_time,'linear','extrap');
      gps.roll = interp1(gps.gps_time,gps.roll,new_gps_time,'linear','extrap');
      gps.pitch = interp1(gps.gps_time,gps.pitch,new_gps_time,'linear','extrap');
      gps.heading = interp1(gps.gps_time,gps.heading,new_gps_time,'linear','extrap');
      gps.gps_time = new_gps_time;
      
      gps.elev = fir_dec(gps.elev,ones(1,101)/101,1);
      
      save(out_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
    end
  end

  if ~isempty(regexpi(out_fn,'201910XX'))
    % Fake GPS for testing
    warning('Faking GPS data: %s', out_fn);
    gps = load(out_fn);
    
    velocity = 4;
    gps.lat = -75.5 - (gps.gps_time-gps.gps_time(1))*velocity/111111;
    gps.lon(:) = -106.75;
    gps.elev(:) = 500;
    gps.heading(:) = -pi;
    
    save(out_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
  end
  
end
