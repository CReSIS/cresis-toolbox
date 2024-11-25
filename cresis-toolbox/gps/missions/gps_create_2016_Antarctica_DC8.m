% script gps_create_2016_antarctica_DC8
%
% Makes the GPS files for 2016 Antarctica DC8 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2016_Antarctica_DC8');
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

in_base_path = fullfile(data_support_path,'2016_Antarctica_DC8');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

% gps_source_to_use = 'NMEA';
% gps_source_to_use = 'ATM-field';
gps_source_to_use = 'ATM';

if strcmpi(gps_source_to_use,'NMEA')
  
  %   year = 2016; month = 10; day = 12;
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_flag{file_idx} = 0;
  %
  %   year = 2016; month = 10; day = 14;
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_flag{file_idx} = 0;
  %
  %   year = 2016; month = 10; day = 15;
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_flag{file_idx} = 0;
  %
%   year = 2016; month = 10; day = 17;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'IWG1.OCT16_Science3');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'reveal';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'reveal-field';
%   sync_flag{file_idx} = 0;
  
%    year = 2016; month = 10; day = 20;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
  
%     year = 2016; month = 10; day = 22;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
  
    year = 2016; month = 11; day = 15;
    file_idx = file_idx + 1;
    in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
    out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
    file_type{file_idx} = 'NMEA';
    params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
    gps_source{file_idx} = 'nmea-field';
    sync_flag{file_idx} = 0;

    year = 2016; month = 11; day = 17;
    file_idx = file_idx + 1;
    in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
    out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
    file_type{file_idx} = 'NMEA';
    params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
    gps_source{file_idx} = 'nmea-field';
    sync_flag{file_idx} = 0;
    
    year = 2016; month = 11; day = 18;
    file_idx = file_idx + 1;
    in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
    out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
    file_type{file_idx} = 'NMEA';
    params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
    gps_source{file_idx} = 'nmea-field';
    sync_flag{file_idx} = 0;
elseif strcmpi(gps_source_to_use,'ATM-field')
  
  year = 2016; month = 10; day = 4;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'atm-field';
  sync_flag{file_idx} = 0;
  
elseif strcmpi(gps_source_to_use,'ATM')
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
  % !!!   ALL data, including test flights, from Oct 7th to OCT29th are in
  % GPS time. From Nov2nd to Nov 22nd the data is in UTC time.
  
%   year = 2016; month = 10; day = 14;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20170717';
%   sync_flag{file_idx} = 0;
  
%   year = 2016; month = 10; day = 15;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710717';
%   sync_flag{file_idx} = 0;
%   
%   year = 2016; month = 10; day = 17;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20171717';
%   sync_flag{file_idx} = 0;
%   
%   year = 2016; month = 10; day = 20;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
%   gps_source{file_idx} = 'atm-final_201710717';
%   sync_flag{file_idx} = 0;
%   
%   year = 2016; month = 10; day = 22;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
%   gps_source{file_idx} = 'atm-final_201710717';
%   sync_flag{file_idx} = 0;
%   
%   year = 2016; month = 10; day = 24;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710717';
%   sync_flag{file_idx} = 0;
%   
%     year = 2016; month = 10; day = 25;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710717';
%   sync_flag{file_idx} = 0;
% 
%   year = 2016; month = 10; day = 26;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710717';
%   sync_flag{file_idx} = 0;
% 
%   year = 2016; month = 10; day = 27;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710717';
%   sync_flag{file_idx} = 0;
% 
%   year = 2016; month = 10; day = 28;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710717';
%   sync_flag{file_idx} = 0;

%   year = 2016; month = 10; day = 31;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710717';
%   sync_flag{file_idx} = 0;
% 
%   year = 2016; month = 11; day = 02;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710717';
%   sync_flag{file_idx} = 0;
%   
%   year = 2016; month = 11; day = 03;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710222';
%   sync_flag{file_idx} = 0;
   
%   year = 2016; month = 11; day = 04;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710222';
%   sync_flag{file_idx} = 0;
%   
%   year = 2016; month = 11; day = 05;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710222';
%   sync_flag{file_idx} = 0;
% 
%   year = 2016; month = 11; day = 07;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710222';
%   sync_flag{file_idx} = 0;
% 
%   year = 2016; month = 11; day = 09;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710222';
%   sync_flag{file_idx} = 0;
%   
%   year = 2016; month = 11; day = 10;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710222';
%   sync_flag{file_idx} = 0;
%   
%   year = 2016; month = 11; day = 11;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710222';
%   sync_flag{file_idx} = 0;
% 
%   year = 2016; month = 11; day = 12;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_201710222';
%   sync_flag{file_idx} = 0;
% 
%   year = 2016; month = 11; day = 14;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20170222';
%   sync_flag{file_idx} = 0;
  
%   year = 2016; month = 11; day = 15;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20170222';
%   sync_flag{file_idx} = 0;
%   
%   year = 2016; month = 11; day = 17;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20170222';
%   sync_flag{file_idx} = 0;
%   
  year = 2016; month = 11; day = 18;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'atm-final_20170222';
  sync_flag{file_idx} = 0;

end


% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

% Debug code that can be used when no GPS data is available and we need to
% fake it.
hack_idx = cell2mat(strfind(out_fns,'gps_20140904.mat'));
if ~isempty(hack_idx)
  out_fn = fullfile(gps_path,out_fns{hack_idx});
  
  warning('Creating fake trajectory with lab data: %s', out_fn);
  
  gps = load(out_fn);
  gps.lat(:) = gps.lat(1) + (gps.gps_time-gps.gps_time(1))*125/111e3;
  gps.lon(:) = gps.lon(1);
  save(out_fn,'-append','-struct','gps','lat','lon')
end

% Reveal files are known to have GPS time errors which are corrected here.
for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn);
  if regexp(gps.gps_source,'reveal')
    
    warning('Fixing non-monotonic GPS data in reveal file: %s', out_fn);
    
    [gps,error_flag] = gps_force_monotonic(gps);
    
    if error_flag
      save(out_fn,'-append','-struct','gps');
    end
  end
end

% ATM and DMS files are known to have a small high frequency INS error which is
% corrected here.
for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn);
  if regexpi(gps.gps_source,'(atm|dms)')
    
    warning('Smoothing INS data: %s', out_fn);
    
    gps.roll = sgolayfilt(gps.roll,2,101);
    gps.pitch = sgolayfilt(gps.pitch,2,101);
    heading_x = cos(gps.heading);
    heading_y = sin(gps.heading);
    heading_x  = sgolayfilt(heading_x,2,101); % Adjust filter length as needed to remove high frequency noise
    heading_y  = sgolayfilt(heading_y,2,101); % Adjust filter length as needed to remove high frequency noise
    gps.heading = atan2(heading_y,heading_x);
    
    save(out_fn,'-append','-struct','gps','roll','pitch','heading');
  end
end

