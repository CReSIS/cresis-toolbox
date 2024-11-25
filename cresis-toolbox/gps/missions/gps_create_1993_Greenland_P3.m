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

gps_path = fullfile(support_path,'gps','1993_Greenland_P3');
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

in_base_path = fullfile(data_support_path,'1993_Greenland_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'19930623_nmea.csv');
% out_fns{file_idx} = 'gps_19930623.mat';
% file_type{file_idx} = 'csv';
% params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
% gps_source{file_idx} = 'nmea-field'; 
% % 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'19930624_nmea.csv');
% out_fns{file_idx} = 'gps_19930624.mat';
% file_type{file_idx} = 'csv';
% params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
% gps_source{file_idx} = 'nmea-field'; 
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'19930627_nmea.csv');
% out_fns{file_idx} = 'gps_19930627.mat';
% file_type{file_idx} = 'csv';
% params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
% gps_source{file_idx} = 'nmea-field'; 
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'19930628_nmea.csv');
% out_fns{file_idx} = 'gps_19930628.mat';
% file_type{file_idx} = 'csv';
% params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
% gps_source{file_idx} = 'nmea-field'; 
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'19930701_nmea.csv');
% out_fns{file_idx} = 'gps_19930701.mat';
% file_type{file_idx} = 'csv';
% params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
% gps_source{file_idx} = 'nmea-field'; 
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'19930702_nmea.csv');
% out_fns{file_idx} = 'gps_19930702.mat';
% file_type{file_idx} = 'csv';
% params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
% gps_source{file_idx} = 'nmea-field'; 
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'19930703_nmea.csv');
% out_fns{file_idx} = 'gps_19930703.mat';
% file_type{file_idx} = 'csv';
% params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
% gps_source{file_idx} = 'nmea-field'; 
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'19930707_nmea.csv');
% out_fns{file_idx} = 'gps_19930707.mat';
% file_type{file_idx} = 'csv';
% params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
% gps_source{file_idx} = 'nmea-field'; 

% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'19930708_nmea.csv');
% out_fns{file_idx} = 'gps_19930708.mat';
% file_type{file_idx} = 'csv';
% params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
% gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19930709_nmea.csv');
out_fns{file_idx} = 'gps_19930709.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

gps_create;

latlon_min_jump=0.005;%latitude and longitude minimum jump threshold
latlon_spike_jump=20;%latitude and longitude spike jump threshold
elev_min_jump=20;%elevation minimum jump threshold

match_idx = strmatch('gps_19930709.mat',out_fns,'exact');
% if ~isempty(match_idx)%----qishi
%   gps_fn = fullfile(gps_path,out_fns{match_idx});
%   fprintf('Fixing GPS data for %s\n', gps_fn);
%   gps = load(gps_fn);
%     
%   
%   close all;
%   gps.lat(gps.lat>median(gps.lat)+latlon_spike_jump |gps.lat<median(gps.lat)-latlon_spike_jump )=NaN;%deal with "spikes"
%   gps.lat=interp_finite(gps.lat);
%   gps.lat=medfilt1(gps.lat);%median filter
%   while any(gps.lat(abs(diff(gps.lat))>latlon_min_jump))%deal with too large jumps
%     gps.lat([logical(0),abs(diff(gps.lat))>latlon_min_jump])=NaN;
%     gps.lat=interp_finite(gps.lat);
%   end
%   save(gps_fn,'-append','-struct','gps','lat');
%   
%   gps.lon(gps.lon>median(gps.lon)+latlon_spike_jump |gps.lon<median(gps.lon)-latlon_spike_jump )=NaN;%deal with "spikes"
%   gps.lon=interp_finite(gps.lon,[],@gps_interp1);
%   gps.lon=medfilt1(gps.lon);%median filter
%   while any(abs(diff(gps.lon))>latlon_min_jump)%deal with too large jumps
%     gps.lon([logical(0),abs(diff(gps.lon))>latlon_min_jump])=NaN;
%     gps.lon=interp_finite(gps.lon,[],@gps_interp1);
%   end
%   
%   jump_idxs=find(abs(diff(gps.elev))>=elev_min_jump);
%   for ii=1:length(jump_idxs)
%     gps.elev(jump_idxs(ii)+1:end)=gps.elev(jump_idxs(ii)+1:end)+gps.elev(jump_idxs(ii))-gps.elev(jump_idxs(ii)+1);
%   end
%   gps.elev=medfilt1(gps.elev);%median filter
%   
%   
%   save(gps_fn,'-append','-struct','gps','elev'); 
% end

if ~isempty(match_idx)%---paden
  gps_fn = fullfile(gps_path,out_fns{match_idx});
  fprintf('Fixing GPS data for %s\n', gps_fn);
  gps = load(gps_fn);
  % FIX CODE HERE
  gps.elev(gps.elev > 10000) = NaN;
  gps.elev = interp_finite(gps.elev);
  save(gps_fn,'-append','-struct','gps','elev');
  gps.lon(gps.lon < -150) = NaN;
  gps.lon = interp_finite(gps.lon,[],@gps_interp1);
  save(gps_fn,'-append','-struct','gps','lon');
end




