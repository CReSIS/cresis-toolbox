% script gps_create_2019_Antarctica_GV
%
% Makes the GPS files for 2019_Antarctica_GV field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2019_Antarctica_GV');
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

in_base_path = fullfile(data_support_path,'2019_Antarctica_GV');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

% gps_source_to_use = 'NMEA';
% gps_source_to_use = 'ATM-field';
gps_source_to_use = 'ATM';

if strcmpi(gps_source_to_use,'NMEA')
%% NMEA
  
%   year = 2019; month = 10; day = 7;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
%   
%   year = 2019; month = 10; day = 8;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
%   
%   year = 2019; month = 10; day = 9;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2019; month = 10; day = 17;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

  year = 2019; month = 10; day = 17;
  file_idx = file_idx + 1;
  in_fns{file_idx} =  get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  file_type{file_idx} = 'NMEA+General_ASCII';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  in_fns_ins{file_idx} = get_filename(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'IWG1','17Oct2019','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',0,'format_str',...
      '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  params_ins{file_idx}.types = {'IWG1','date_time','lat_deg','lon_deg','elev_m','elev_m_not_used','press_alt_ft','radar_alt_ft',...
      'grnd_spd_mps','true_airspeed_mps','indicated_airspeed_knots','mach_number','vert_velocity_mps','heading_deg',...
      'track_deg','drift_deg','pitch_deg','roll_deg','side_slip_deg','angle_of_attach_deg','ambient_temp_degc',...
      'dew_tmp_degc','total_tmp_degc','static_press_mbar','dynamic_press_mbar','cabin_press_mbar','wind_speed_mps',...
      'wind_dir_deg','vert_wind_speed_mps','solar_zenith_deg','sun_ele_ac_deg','sun_az_grd_deg','sun_az_ac_deg'};
  params_ins{file_idx}.textscan ={'delimiter',','};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 0;

%   year = 2019; month = 10; day = 24;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2019; month = 10; day = 25;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
% 
%   year = 2019; month = 10; day = 27;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
  
%   year = 2019; month = 10; day = 28;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
  
%   year = 2019; month = 10; day = 29;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2019; month = 10; day = 30;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
  
%   year = 2019; month = 11; day = 1;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2019; month = 11; day = 3;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2019; month = 11; day = 4;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
  
%   year = 2019; month = 11; day = 5;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2019; month = 11; day = 6;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

  
elseif strcmpi(gps_source_to_use,'ATM-field')
  %% ATM-field
  
  year = 2019; month = 4; day = 3;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  gps_source{file_idx} = 'atm-field';
  sync_flag{file_idx} = 0; 
  
    
elseif strcmpi(gps_source_to_use,'ATM')
  %% ATM
  
  % Just some simple code to automate creation of the code in this section:
  %
  %   ATM_fns = get_filenames(in_base_path,'','','.out');
  %   fn_dates = [];
  %   for idx = 1:length(ATM_fns)
  %     fn = ATM_fns{idx};
  %     [~,fn_name] = fileparts(fn);
  %     if strcmpi(fn_name(1:2),'BD')
  %       fn_dates(end+1) = datenum(sprintf('%s %s, 20%s', fn_name(9:11), fn_name(7:8), fn_name(12:13)));
  %     elseif strcmpi(fn_name(1:2),'00')
  %       fn_dates(end+1) = datenum(sprintf('%s %s, 20%s', fn_name(13:15), fn_name(11:12), fn_name(16:17)));
  %     end
  %   end
  %   fn_dates = sort(fn_dates);
  %   for idx = 1:length(fn_dates)
  %     [year,month,day] = datevec(fn_dates(idx));
  %     fprintf('year = %d; month = %d; day = %d;\n', year, month, day);
  %   end
  
  ATM_fns = get_filenames(in_base_path,'','','BD982*.out');
  fn_dates = [];
  for idx = 1:length(ATM_fns)
    fn = ATM_fns{idx};
    [~,fn_name] = fileparts(fn);
    fn_dates(end+1) = datenum(sprintf('%s %s, 20%s', fn_name(9:11), fn_name(7:8), fn_name(12:13)));
  end
  fn_dates = sort(fn_dates);
  
  for idx = 1:length(fn_dates)
    [year,month,day] = datevec(fn_dates(idx));
    fprintf('year = %d; month = %d; day = %d;\n', year, month, day);
    file_idx = file_idx + 1;
    if month == 10 & day == 17
      in_fns{file_idx} = {get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'.out'),...
        get_filename(in_base_path,'IWG1','17Oct2019','')};
    else
      in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'.out');
    end
    % The local dates in spreadsheets are one day behind
    if month == 10 & day == 31 
      month = 11;
      day = 1;
    elseif ~(month == 10 & day == 17)
      day = day + 1;
    end
    out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
    
    % Change the day back
    if month == 11 & day == 1 
      month = 10;
      day = 31;
    elseif ~(month == 10 & day == 17)
      day = day -1;
    end
    
    if month == 10 & day == 17
      file_type{file_idx} = {'applanix','General_ASCII'};
      params{file_idx}{1} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
      params{file_idx}{2} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',0,'format_str',...
        '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
      params{file_idx}{2}.types = {'IWG1','date_time','lat_deg','lon_deg','elev_m','elev_m_not_used','press_alt_ft','radar_alt_ft',...
        'grnd_spd_mps','true_airspeed_mps','indicated_airspeed_knots','mach_number','vert_velocity_mps','heading_deg',...
        'track_deg','drift_deg','pitch_deg','roll_deg'};
      params{file_idx}{2}.textscan ={'delimiter',','};
      params{file_idx}{2}.date_time_format = 'yyyy-mm-ddTHH:MM:SS.FFF';
      gps_source{file_idx} = 'atm-final_20200110+IWG1';
      sync_flag{file_idx} = 0;
    else
      file_type{file_idx} = 'applanix';
      params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
      gps_source{file_idx} = 'atm-final_20200110';
      sync_flag{file_idx} = 0;
    end
  end
  
end


% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn);
  if regexpi(gps.gps_source,'atm')
    
    warning('Smoothing INS data: %s', out_fn);
    
    gps.roll = sgolayfilt(gps.roll,2,101); % Adjust filter length as needed to remove high frequency noise
    gps.pitch = sgolayfilt(gps.pitch,2,101); % Adjust filter length as needed to remove high frequency noise
    heading_x = cos(gps.heading);
    heading_y = sin(gps.heading);
    heading_x  = sgolayfilt(heading_x,2,101); % Adjust filter length as needed to remove high frequency noise
    heading_y  = sgolayfilt(heading_y,2,101); % Adjust filter length as needed to remove high frequency noise
    gps.heading = atan2(heading_y,heading_x);
    
    save(out_fn,'-append','-struct','gps','roll','pitch','heading');
  end
end
