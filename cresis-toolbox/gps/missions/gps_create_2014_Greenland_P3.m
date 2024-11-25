% script gps_create_2014_greenland_P3
%
% Makes the GPS files for 2014 Greenland P3 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2014_Greenland_P3');
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

in_base_path = fullfile(data_support_path,'2014_Greenland_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'NMEA';
% gps_source_to_use = 'ATM-field';
% gps_source_to_use = 'ATM';

if strcmpi(gps_source_to_use,'NMEA')
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20140306NMEA.TXT');
  %   out_fns{file_idx} = 'gps_20140306.mat';11
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2014,'month',03,'day',6,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';1111
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140306','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',6,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'accum2_201403112_105414.gps');
  %   out_fns{file_idx} = 'gps_20140312.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2014,'month',03,'day',12,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140312','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',12,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;1
  %   in_fns{file_idx} = fullfile(in_base_path,'20140314NMEA.TXT');
  %   out_fns{file_idx} = 'gps_20140314.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2014,'month',03,'day',14,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140314','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',14,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140315NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140315.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',03,'day',15,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140315','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',03,'day',15,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140317NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140317.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',03,'day',17,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140317','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',03,'day',17,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140318NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140318.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',03,'day',18,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;8
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140318','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',03,'day',18,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140319NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140319.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',03,'day',19,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140319','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',03,'day',19,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140321NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140321.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',03,'day'1,21,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140321','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',03,'day',21,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140324NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140324.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',03,'day',24,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;1
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140324','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',03,'day',24,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140325NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140325.mat';1
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',03,'day',25,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140325','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',03,'day',25,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140326NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140326.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',03,'day',26,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140326','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',03,'day',26,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140328NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140328.mat';8
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',03,'day',28,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140328','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',03,'day',28,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140331NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140331.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',03,'day',31,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140331','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',03,'day',31,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140401NMEA1.TXT');
  %     out_fns{file_idx} = 'gps_20140401.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',01,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140401','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',01,'time_reference','utc','format',3);

      file_idx = file_idx + 1;
      in_fns{file_idx} = fullfile(in_base_path,'20140403NMEA.TXT');
      out_fns{file_idx} = 'gps_20140403.mat';
      file_type{file_idx} = 'NMEA';
      params{file_idx} = struct('year',2014,'month',04,'day',03,'format',3,'time_reference','utc');
      gps_source{file_idx} = 'nmea-field';
      sync_flag{file_idx} = 1;
      sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140403','','.gps');
      sync_params{file_idx} = struct('year',2014,'month',04,'day',03,'time_reference','utc','format',3);

  %     file_idx = file_idx + 1;1
  %     in_fns{file_idx} = fullfile(in_base_path,'20140405NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140405.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',05,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;1
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140405','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',05,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140407NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140407.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',07,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';1
  %     sync_flag{file_1idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140407','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',07,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140408NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140408.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day'1,08,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140408','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',08,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140409NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140409.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',09,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140409','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',09,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140410NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140410.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',10,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140410','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',10,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140412NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140412.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',12,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140412','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',12,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140414NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140414.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',14,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;1
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140414','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',14,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140415NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140415.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',15,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';1
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140415','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',15,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140416NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140416.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',16,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140416','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',16,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;1
  %     in_fns{file_idx} = fullfile(in_base_path,'20140419NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140419.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',19,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140419','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',19,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140421NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140421.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',21,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140421','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',21,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140423NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140423.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',23,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140423','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',23,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140424NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140424.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',24,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140424','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',24,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140425NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140425.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',25,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  %     sync_fns{file_idx} = fullfile(in_base_path,'20140425NMEA.TXT');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',25,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140426NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140426.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',26,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140426','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',26,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140428NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140428.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',28,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140428','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',28,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140429NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140429.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',29,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140429','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',29,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140430NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140430.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',04,'day',30,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140430','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',04,'day',30,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140501NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140501.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',05,'day',01,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140501','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',05,'day',01,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140502NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140502.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',05,'day',02,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140502','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',05,'day',02,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140505NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140505.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',05,'day',05,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140505','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',05,'day',05,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140506NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140506.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',05,'day',06,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140506','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',05,'day',06,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140507NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140507.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',05,'day',07,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140507','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',05,'day',07,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140508NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140508.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',05,'day',08,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140508','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',05,'day',08,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140509NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140509.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',05,'day',09,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140509','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',05,'day',09,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140512NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140512.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',05,'day',12,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140512','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',05,'day',12,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140514NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140514.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',05,'day',14,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140514','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',05,'day',14,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20140515NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20140515.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2014,'month',05,'day',15,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140515','','.gps');
  %     sync_params{file_idx} = struct('year',2014,'month',05,'day',15,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     year = 2014; month = 5; day = 16;
  %     in_fns{file_idx} = fullfile(in_base_path,sprintf('%04d%02d%02dNMEA.TXT',year,month,day));
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  %     sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     year = 2014; month = 5; day = 19;
  %     in_fns{file_idx} = fullfile(in_base_path,sprintf('%04d%02d%02dNMEA.TXT',year,month,day));
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 1;
  %     sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  %     sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  %
  %     file_idx = file_idx + 1;
  %     year = 2014; month = 5; day = 20;
  %     in_fns{file_idx} = fullfile(in_base_path,sprintf('%04d%02d%02dNMEA.TXT',year,month,day));
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  %     sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  %     sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
%   file_idx = file_idx + 1;
%   year = 2014; month = 5; day = 21;
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('%04d%02d%02dNMEA.TXT',year,month,day));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
  
elseif strcmpi(gps_source_to_use,'ATM-field')
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_07Mar14_PGNSSK_P08Mar14.out');
  %   out_fns{file_idx} = 'gps_20140307.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',7,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140307','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',7,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_10Mar14_OMNIK_P10Mar14.out');
  %   out_fns{file_idx} = 'gps_20140310.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',10,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140310','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',10,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_12Mar14_PPPK_P13Mar14.out');
  out_fns{file_idx} = 'gps_20140312.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2014,'month',03,'day',12,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'atm-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140312','','.gps');
  sync_params{file_idx} = struct('year',2014,'month',03,'day',12,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_13Mar14_OMNIK_P13Mar14.out');
  %   out_fns{file_idx} = 'gps_20140313.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',13,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140313','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',13,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_14Mar14_PPPK_P21Mar14.out');
  %   out_fns{file_idx} = 'gps_20140314.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',14,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140314','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',14,'time_reference','utc','format',3);
  %
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_15Mar14_PPPK_P21Mar14.out');
  %   out_fns{file_idx} = 'gps_20140315.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',15,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140315','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',15,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_17Mar14_PPPK_P21Mar14.out');
  %   out_fns{file_idx} = 'gps_20140317.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',17,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140317','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',17,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_18Mar14_PPPK_P21Mar14.out');
  %   out_fns{file_idx} = 'gps_20140318.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',18,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140318','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',18,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_19Mar14_PPPK_P21Mar14.out');
  %   out_fns{file_idx} = 'gps_20140319.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',19,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140319','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',19,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_21Mar14_PPPK_P21Mar14.out');
  %   out_fns{file_idx} = 'gps_20140321.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',21,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140321','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',21,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_24Mar14_PPPK_P26Mar14.out');
  %   out_fns{file_idx} = 'gps_20140324.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',24,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140324','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',24,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_25Mar14_PPPK_P26Mar14.out');
  %   out_fns{file_idx} = 'gps_20140325.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',25,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140325','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',25,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_26Mar14_PPPK_P28Mar14.out');
  %   out_fns{file_idx} = 'gps_20140326.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',26,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140326','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',26,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_28Mar14_PPPK_P30Mar14.out');
  %   out_fns{file_idx} = 'gps_20140328.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',28,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140328','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',28,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_31Mar14_PPPK_P02Apr14.out');
  %   out_fns{file_idx} = 'gps_20140331.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',03,'day',31,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140331','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',03,'day',31,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_01Apr14_PPPK_P02Apr14.out');
  %   out_fns{file_idx} = 'gps_20140401.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',01,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140401','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',01,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_05Apr14_PPPK_P07Apr14.out');
  %   out_fns{file_idx} = 'gps_20140405.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',05,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140405','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',05,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_05Apr14_PPPK_P11Apr14.out');
  %   out_fns{file_idx} = 'gps_20140405.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',05,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140405','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',05,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_07Apr14_PPPK_P11Apr14.out');
  %   out_fns{file_idx} = 'gps_20140407.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',07,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140407','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',07,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_08Apr14_PPPK_EXT.out');
  %   out_fns{file_idx} = 'gps_20140408.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',08,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140408','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',08,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_09Apr14_PPPK_P11Apr14.out');
  %   out_fns{file_idx} = 'gps_20140409.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',09,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140409','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',09,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_10Apr14_PPPK_P11Apr14.out');
  %   out_fns{file_idx} = 'gps_20140410.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',10,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140410','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',10,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_12Apr14_PPPK_P24Apr14.out');
  %   out_fns{file_idx} = 'gps_20140412.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',12,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140412','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',12,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_14Apr14_PPPK_P16Apr14.out');
  %   out_fns{file_idx} = 'gps_20140414.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',14,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140414','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',14,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_15Apr14_PPPK_P21Apr14.out');
  %   out_fns{file_idx} = 'gps_20140415.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',15,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140415','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',15,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_16Apr14_PPPK_P24Apr14.out');
  %   out_fns{file_idx} = 'gps_20140416.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',16,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140416','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',16,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_19Apr14_PPPK_P21Apr14.out');
  %   out_fns{file_idx} = 'gps_20140419.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',19,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140419','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',19,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_21Apr14_PPPK_P24Apr14.out');
  %   out_fns{file_idx} = 'gps_20140421.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',21,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140421','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',21,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_23Apr14_PPPK_P24Apr14.out');
  %   out_fns{file_idx} = 'gps_20140423.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2014,'month',04,'day',23,'format',3,'time_reference','utc');
  %   gps_source{file_idx} = 'atm-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20140423','','.gps');
  %   sync_params{file_idx} = struct('year',2014,'month',04,'day',23,'time_reference','utc','format',3);
  
elseif strcmpi(gps_source_to_use,'ATM')
  % Just some simple code to automate creation of the code in this section:
  %
  % ATM_fns = get_filenames(in_base_path,'','','.out');
  % fn_dates = [];
  % for idx = 1:length(ATM_fns)
  %   fn = ATM_fns{idx};
  %   [~,fn_name] = fileparts(fn);
  %   fn_dates(end+1) = datenum(sprintf('%s %s, 20%s', fn_name(9:11), fn_name(7:8), fn_name(12:13)));
  % end
  % fn_dates = sort(fn_dates);
  % for idx = 1:length(fn_dates)
  %   [year,month,day] = datevec(fn_dates(idx));
  %   fprintf('year = %d; month = %d; day = %d;\n', year, month, day);
  % end
  
%   year = 2014; month = 3; day = 6;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 0;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 10;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 12;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 13;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 14;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 15;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 17;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 18;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 19;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 21;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 24;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 25;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 26;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 3; day = 28;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
  year = 2014; month = 3; day = 31;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'atm-final_20140812';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 1;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 4;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 0;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 5;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 7;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 8;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 9;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 10;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 12;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 14;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
  year = 2014; month = 4; day = 15;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'atm-final_20140812';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

%   year = 2014; month = 4; day = 16;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 19;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 21;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 23;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 24;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
% 
%   year = 2014; month = 4; day = 26;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
   
%   year = 2014; month = 4; day = 28;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 29;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 4; day = 30;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 5; day = 1;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 5; day = 2;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 5; day = 5;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 5; day = 6;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 5; day = 7;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 5; day = 8;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 5; day = 9;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   

  year = 2014; month = 5; day = 12;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'atm-final_20140812';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

%   year = 2014; month = 5; day = 14;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
%   year = 2014; month = 5; day = 15;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 5; day = 16;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 5; day = 19;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
%   year = 2014; month = 5; day = 20;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 0;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   year = 2014; month = 5; day = 21;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-final_20140613';
%   sync_flag{file_idx} = 0;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
end


% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;




