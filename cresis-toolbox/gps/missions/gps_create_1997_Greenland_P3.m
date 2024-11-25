% script gps_create_2002_greenland_P3
% Makes the DGPSwINS????? files for 2002 Greenland P3 field season
%see icards_gps_missinNASA_csv.m to get csv files for days without
%trajectory data. (check time reference: should be gps)
tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','1997_Greenland_P3');
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

in_base_path = fullfile(data_support_path,'1997_Greenland_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};


file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19970511_nmea.csv');
out_fns{file_idx} = 'gps_19970511.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19970513_nmea.csv');
out_fns{file_idx} = 'gps_19970513.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19970514_nmea.csv');
out_fns{file_idx} = 'gps_19970514.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19970515_nmea.csv');
out_fns{file_idx} = 'gps_19970515.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19970517_nmea.csv');
out_fns{file_idx} = 'gps_19970517.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19970519_nmea.csv');
out_fns{file_idx} = 'gps_19970519.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19970521_nmea.csv');
out_fns{file_idx} = 'gps_19970521.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19970523_nmea.csv');
out_fns{file_idx} = 'gps_19970523.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19970524_nmea.csv');
out_fns{file_idx} = 'gps_19970524.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19970527_nmea.csv');
out_fns{file_idx} = 'gps_19970527.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19970528_nmea.csv');
out_fns{file_idx} = 'gps_19970528.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 


gps_create;
match_idx = strmatch('gps_19950518.mat',out_fns,'exact');
if ~isempty(match_idx)
  gps_fn = fullfile(gps_path,out_fns{match_idx});
  fprintf('Fixing GPS data for %s\n', gps_fn);
  gps = load(gps_fn);
  % FIX CODE HERE
  gps.elev(gps.elev > 10000) = NaN;
  gps.elev = interp_finite(gps.elev);
  save(gps_fn,'-append','-struct','gps','elev');
end

