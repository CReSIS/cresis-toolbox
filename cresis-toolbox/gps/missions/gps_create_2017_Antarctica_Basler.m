% script gps_create_2017_antarctica_Basler
%
% Makes the GPS files for 2017 Antarctica Basler field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2017_Antarctica_Basler');
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

in_base_path = fullfile(data_support_path,'2017_Antarctica_Basler');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'cresis';
if strcmpi(gps_source_to_use,'NMEA')
  
  year = 2017; month = 10; day = 21;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)),'GPS','','.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 0;
  
end

if strcmpi(gps_source_to_use,'cresis')
  
%   file_idx = file_idx + 1;
%   year = 2017; month = 11; day = 29;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('rover_PPP_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   year = 2017; month = 11; day = 30;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('rover_PPP_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-field';
%   sync_flag{file_idx} = 0;

%   file_idx = file_idx + 1;
%   year = 2017; month = 12; day = 1;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('rover_diff_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-field';
%   sync_flag{file_idx} = 0;
  
%   file_idx = file_idx + 1;
%   year = 2017; month = 12; day = 2;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('rover_diff_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-field';
%   sync_flag{file_idx} = 0;

%   file_idx = file_idx + 1;
%   year = 2017; month = 12; day = 4;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('rover_diff_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-field';
%   sync_flag{file_idx} = 0;

%   file_idx = file_idx + 1;
%   year = 2017; month = 12; day = 5;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('rover_diff_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-field';
%   sync_flag{file_idx} = 0;
%   file_idx = file_idx + 1;

%   year = 2017; month = 12; day = 7;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('rover_PPP_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-field';
%   sync_flag{file_idx} = 0;

%   year = 2017; month = 12; day = 14;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('rover_PPP_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-field';
%   sync_flag{file_idx} = 0;

%   file_idx = file_idx + 1;
%   year = 2017; month = 12; day = 15;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('rover_diff_%s.txt',date_string));
% %   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('rover_ppp_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-field';
%   sync_flag{file_idx} = 0;

%   file_idx = file_idx + 1;
%   year = 2017; month = 12; day = 16;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('rover_ppp_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-field';
%   sync_flag{file_idx} = 0;

%   file_idx = file_idx + 1;
%   year = 2017; month = 12; day = 17;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('rover_diff_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-field';
%   sync_flag{file_idx} = 0;


  file_idx = file_idx + 1;
  year = 2017; month = 12; day = 18;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = fullfile(in_base_path,sprintf('rover_diff_%s.txt',date_string));
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'cresis';
  params{file_idx} = struct();
  gps_source{file_idx} = 'cresis-field';
  sync_flag{file_idx} = 0;

end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

if any(strcmpi('gps_?.mat',out_fns)) ...
  || any(strcmpi('gps_?.mat',out_fns))
  warning('Jan ? and Dec ? traveled across 180 deg line and GPS file produced by Novatel may have errors! Novatel smoothing will produce points which interpolate -179.999 to +179.999 and vice versa incorrectly and you have to manually remove these points from the .txt input file before running gps_create.');
  keyboard
end



