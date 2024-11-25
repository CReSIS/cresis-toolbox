% script gps_create_2018_antarctica_TObas
%
% Makes the GPS files for 2018 Antarctica TObas field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2018_Antarctica_TObas');
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
mergegps = true; % Set to true for days that require combining Arena and BAS GPS

if mergegps
  % Merge Arena and BAS GPS
  % Only one day can be enabled at once
  year = 2019; month = 2; day = 4;
%   year = 2019; month = 2; day = 7;
  datevecs = {[year, month, day]};
  
  baddatevecs = datevecs;
else
  % Multiple days (BAS GPS)
  % Each vec has format [YYYY, MM, DD] and it is iterated upon later[2019, 1, 29]
  % Uncomment which days you want to make
  
  datevecs = {};
%   datevecs{end+1} = [2019, 1, 29];
%   datevecs{end+1} = [2019, 1, 30];
%   datevecs{end+1} = [2019, 1, 31];
%   datevecs{end+1} = [2019, 2, 1];
%   datevecs{end+1} = [2019, 2, 3];
%   datevecs{end+1} = [2019, 2, 5];
%   datevecs{end+1} = [2019, 2, 6];

  baddatevecs = {};
end  

%Find all of the subdirectories in the base path for comparison to dates
in_base_path = fullfile(data_support_path,'2018_Antarctica_TObas');
in_base = dir(in_base_path);
in_base_dirs = {in_base(:).name};

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

% gps_source_to_use = 'arena';
% gps_source_to_use = 'arena_cpu_time';
gps_source_to_use = 'bas';

%Load days with "bad data" to be processed with arena settings
for date_idx = 1:length(baddatevecs)
    %Get the date and make it a string
    year = baddatevecs{date_idx}(1); month = baddatevecs{date_idx}(2); day = baddatevecs{date_idx}(3);
    date_str = sprintf('%04d%02d%02d',year,month,day);
    %Get folder names that match the date in question (looking for daya,
    %dayb, etc.)
      %Compare the dirs in the base path to the current date string
      compcells = strfind(in_base_dirs,date_str);
      %Extract the dirs that match the string
      match_dirs = {in_base_dirs{cellfun(@(x) ~isempty(x),compcells)}};
    %Iterate over the directories that match the date string
    for match_idx = 1:length(match_dirs)
      dir_str = match_dirs{match_idx};
      file_idx = file_idx + 1;
      in_fns{file_idx} = get_filenames(fullfile(in_base_path,dir_str),'','','gps.txt');
      out_fns{file_idx} = sprintf('gps_%s_arena.mat', date_str);
      file_type{file_idx} = 'arena';
      params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%       gps_source{file_idx} = 'arena-field';
      gps_source{file_idx} = 'arena';
      sync_flag{file_idx} = 1;
      sync_fns{file_idx} = get_filenames(fullfile(in_base_path,dir_str),'','','gps.txt');
      sync_file_type{file_idx} = 'arena';
      sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
    end
end
  
if strcmpi(gps_source_to_use,'arena')
%% ARENA  
%   year = 2019; month = 1; day = 26;
  for date_idx = 1:length(datevecs)
    %Get the date and make it a string
    year = datevecs{date_idx}(1); month = datevecs{date_idx}(2); day = datevecs{date_idx}(3);
    date_str = sprintf('%04d%02d%02d',year,month,day);
    %Get folder names that match the date in question (looking for daya,
    %dayb, etc.)
      %Compare the dirs in the base path to the current date string
      compcells = strfind(in_base_dirs,date_str);
      %Extract the dirs that match the string
      match_dirs = {in_base_dirs{cellfun(@(x) ~isempty(x),compcells)}};
    %Iterate over the directories that match the date string
    for match_idx = 1:length(match_dirs)
      dir_str = match_dirs{match_idx};
      file_idx = file_idx + 1;
      in_fns{file_idx} = get_filenames(fullfile(in_base_path,dir_str),'','','gps.txt');
      out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
      file_type{file_idx} = 'arena';
      params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
      gps_source{file_idx} = 'arena-field';
      sync_flag{file_idx} = 1;
      sync_fns{file_idx} = get_filenames(fullfile(in_base_path,dir_str),'','','gps.txt');
      sync_file_type{file_idx} = 'arena';
      sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
    end
  end

elseif strcmpi(gps_source_to_use,'arena_cpu_time')
  %% Arena used computer time with no GPS inputs

%   year = 2019; month = 1; day = 27;
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'GPS_FILE_20190127.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'nmea';
  params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','awg0.txt');
  sync_file_type{file_idx} = 'arena_cpu_time';
  sync_params{file_idx} = struct('time_reference','utc', ...
    'cpu_time_fn',fullfile(in_base_path,sprintf('cpu_time_%04d%02d%02d.csv',year,month,day)));

elseif strcmpi(gps_source_to_use,'bas')
  %% BAS
  for date_idx = 1:length(datevecs)
    %Get the date and make it a string
    year = datevecs{date_idx}(1); month = datevecs{date_idx}(2); day = datevecs{date_idx}(3);
    date_str = sprintf('%04d%02d%02d',year,month,day);
    
    %Select the correct input files
    switch date_str
      case '20190129'
        incase_fns = {fullfile(in_base_path,'03.txt'); fullfile(in_base_path,'04.txt')};
      case '20190130'
        incase_fns = {fullfile(in_base_path,'05.txt')};
      case '20190131'
        incase_fns =  {fullfile(in_base_path,'06.txt')};
      case '20190201'
        incase_fns = {fullfile(in_base_path,'07.txt')};
      case '20190203'
        incase_fns = {fullfile(in_base_path,'08.txt')};
      case '20190204'
        incase_fns = {fullfile(in_base_path,'09.txt')};
      case '20190205'
        incase_fns = {fullfile(in_base_path,'11.txt')};
      case '20190206'
        incase_fns = {fullfile(in_base_path,'12.txt'); fullfile(in_base_path,'13.txt')};
      case '20190207'
        incase_fns = {fullfile(in_base_path,'14.txt')};        
      otherwise
        return
    end
    %Increase file id
    file_idx = file_idx + 1;
    
    %Load the structures
    in_fns{file_idx} = incase_fns;
    out_fns{file_idx} = sprintf('gps_%s.mat', date_str);
    file_type{file_idx} = 'General_ASCII';
    params{file_idx} = struct('time_reference','gps');
    params{file_idx}.format_str = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f';
    params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg',...
      'elev_m','f1','f2','f3','roll_deg','pitch_deg','heading_deg','f4',...
      'f5','f6','f7'};
    params{file_idx}.textscan = {};
    params{file_idx}.headerlines = 5;
    gps_source{file_idx} = 'bas-final20190313';
    sync_flag{file_idx} = 1;
    sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%s',date_str)),'','','gps.txt');
    sync_file_type{file_idx} = 'arena';
%     sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
    sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  end


end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn,'gps_source');
  if ~isempty(regexpi(gps.gps_source,'arena'))
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
    
  if regexpi(out_fn,'20180929')
    % Fake GPS for testing
    warning('Faking GPS data: %s', out_fn);
    gps = load(out_fn);
    
    velocity = 70;
    gps.lat = -75.5 - (gps.gps_time-gps.gps_time(1))*velocity/111111;
    gps.lon(:) = -106.75;
    gps.elev(:) = 500;
    gps.heading(:) = -pi;
    
    save(out_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
  end
  
end

%Merge the structures for the "bad data" dates
for id_bd = 1:length(baddatevecs)
  %Get the date
  year = baddatevecs{id_bd}(1); month = baddatevecs{id_bd}(2); day = baddatevecs{id_bd}(3);
  date_str = sprintf('%04d%02d%02d',year,month,day);
  %Get the output file names
  out_fn_arena = fullfile(gps_path,sprintf('gps_%s_arena',date_str));
  out_fn_bas = fullfile(gps_path,sprintf('gps_%s',date_str));
  %Load the files
  gps_arena = load(out_fn_arena);
  gps_bas = load(out_fn_bas);
  %Append data to gps_bas
  gps = gps_bas;
  fappend = {'elev','heading','lat','lon','pitch','roll','gps_time'}; %Fields to append data
  applogicvec = [gps_arena.gps_time>=gps_bas.gps_time(end)];
  for fid = 1:length(fappend)
    basf = gps_bas.(fappend{fid});
    appf = gps_arena.(fappend{fid});
    gps.(fappend{fid}) = [basf, appf(applogicvec)];
  end
  %Save the merged data
  save(out_fn_bas,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
end