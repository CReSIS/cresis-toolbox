% script gps_create_2016_greenland_G1XB
%
% Makes the GPS files for 2016 Greenland G1XB field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2016_Greenland_G1XB');
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

debug_level = 1;

in_base_path = fullfile(data_support_path,'2016_Greenland_G1XB');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'postprocessed';

if strcmpi(gps_source_to_use,'postprocessed')
  % =======================================================================
  % Post processed data (from GRA Jonathan Lyle)
  % =======================================================================

%   file_idx = file_idx + 1;
%   year = 2016; month = 4; day = 13;
%   in_fns{file_idx} = get_filenames(in_base_path,sprintf('%02d%02d%04d_UAV',month,day,year),'','.csv');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','gps');
%   params{file_idx}.format_str = '%f%s%s%f%f%f%f%f%f';
%   params{file_idx}.types = {'sow','lat_dsm','lon_dsm','elev_m'};
%   params{file_idx}.textscan = {'delimiter',',','emptyvalue',NaN};
%   params{file_idx}.headerlines = 1;
%   gps_source{file_idx} = 'postprocessed-20160509';
%   sync_flag{file_idx} = 0;
% 
%   file_idx = file_idx + 1;
%   year = 2016; month = 4; day = 16;
%   in_fns{file_idx} = get_filenames(in_base_path,sprintf('%02d%02d%04d_UAV',month,day,year),'','.csv');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','gps');
%   params{file_idx}.format_str = '%f%s%s%f%f%f%f%f%f';
%   params{file_idx}.types = {'sow','lat_dsm','lon_dsm','elev_m'};
%   params{file_idx}.textscan = {'delimiter',',','emptyvalue',NaN};
%   params{file_idx}.headerlines = 1;
%   gps_source{file_idx} = 'postprocessed-20160509';
%   sync_flag{file_idx} = 0;

  file_idx = file_idx + 1;
  year = 2016; month = 4; day = 17;
  in_fns{file_idx} = get_filenames(in_base_path,sprintf('%02d%02d%04d_UAV',month,day,year),'','.csv');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','gps');
  params{file_idx}.format_str = '%f%s%s%f%f%f%f%f%f';
  params{file_idx}.types = {'sow','lat_dsm','lon_dsm','elev_m'};
  params{file_idx}.textscan = {'delimiter',',','emptyvalue',NaN};
  params{file_idx}.headerlines = 1;
  gps_source{file_idx} = 'postprocessed-20160509';
  sync_flag{file_idx} = 0;
  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;
