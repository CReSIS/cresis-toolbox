% script gps_create_1996_greenland_P3
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

gps_path = fullfile(support_path,'gps','1996_Greenland_P3');
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

in_base_path = fullfile(data_support_path,'1996_Greenland_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19960515_nmea.csv');
out_fns{file_idx} = 'gps_19960515.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19960520_nmea.csv');
out_fns{file_idx} = 'gps_19960520.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'19960522_nmea.csv');
out_fns{file_idx} = 'gps_19960522.mat';
file_type{file_idx} = 'csv';
params{file_idx} = struct('input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f','time_reference','utc','type',[3]);%add a new type valued 3 for "read_gps_csv" to process
gps_source{file_idx} = 'nmea-field'; 




gps_create;
latlon_min_jump=0.005;%latitude and longitude minimum jump threshold
latlon_spike_jump=10;%latitude and longitude spike jump threshold
elev_min_jump=300;%elevation minimum jump threshold

match_idx = strmatch('gps_19960515.mat',out_fns,'exact');
if ~isempty(match_idx)
  gps_fn = fullfile(gps_path,out_fns{match_idx});
  fprintf('Fixing GPS data for %s\n', gps_fn);
  gps = load(gps_fn);
  
  gps.lat(gps.lat>median(gps.lat)+latlon_spike_jump |gps.lat<median(gps.lat)-latlon_spike_jump )=NaN;%deal with "spikes"
  gps.lat=interp_finite(gps.lat);
  gps.lat=medfilt1(gps.lat);%median filter
  while any(gps.lat(abs(diff(gps.lat))>latlon_min_jump))%deal with too large jumps
    gps.lat(abs(diff(gps.lat))>latlon_min_jump)=NaN;
    gps.lat=interp_finite(gps.lat);
  end
  save(gps_fn,'-append','-struct','gps','lat');
  
  gps.lon(gps.lon>median(gps.lon)+latlon_spike_jump |gps.lon<median(gps.lon)-latlon_spike_jump )=NaN;%deal with "spikes"
  gps.lon=interp_finite(gps.lon,[],@gps1_interp1);
  gps.lon=medfilt1(gps.lon);%median filter
  while any(abs(diff(gps.lon))>latlon_min_jump)%deal with too large jumps
    gps.lon(abs(diff(gps.lon))>latlon_min_jump)=NaN;
    gps.lon=interp_finite(gps.lon,[],@gps_interp1);
  end
  save(gps_fn,'-append','-struct','gps','lon'); 
end



match_idx = strmatch('gps_19960520.mat',out_fns,'exact');
if ~isempty(match_idx)
  gps_fn = fullfile(gps_path,out_fns{match_idx});
  fprintf('Fixing GPS data for %s\n', gps_fn);
  gps = load(gps_fn);
  
  gps.lat(gps.lat>median(gps.lat)+latlon_spike_jump |gps.lat<median(gps.lat)-latlon_spike_jump )=NaN;%deal with "spikes"
  gps.lat=interp_finite(gps.lat);
  gps.lat=medfilt1(gps.lat);%median filter
  while any(gps.lat(abs(diff(gps.lat))>latlon_min_jump))%deal with too large jumps
    gps.lat(abs(diff(gps.lat))>latlon_min_jump)=NaN;
    gps.lat=interp_finite(gps.lat);
  end
  save(gps_fn,'-append','-struct','gps','lat');
  
  gps.lon(gps.lon>median(gps.lon)+latlon_spike_jump |gps.lon<median(gps.lon)-latlon_spike_jump )=NaN;%deal with "spikes"
  gps.lon=interp_finite(gps.lon,[],@gps_interp1);
  gps.lon=medfilt1(gps.lon);%median filter
  while any(abs(diff(gps.lon))>latlon_min_jump)%deal with too large jumps
    gps.lon(abs(diff(gps.lon))>latlon_min_jump)=NaN;
    gps.lon=interp_finite(gps.lon,[],@gps_interp1);
  end
  save(gps_fn,'-append','-struct','gps','lon'); 
  
  while any(abs(diff(gps.elev))>elev_min_jump)%deal with too large jumps
    gps.elev(abs(diff(gps.elev))>elev_min_jump)=NaN;
    gps.elev=interp_finite(gps.elev);
  end
   save(gps_fn,'-append','-struct','gps','elev');
end


match_idx = strmatch('gps_19960522.mat',out_fns,'exact');
if ~isempty(match_idx)
  gps_fn = fullfile(gps_path,out_fns{match_idx});
  fprintf('Fixing GPS data for %s\n', gps_fn);
  gps = load(gps_fn);
  
  gps.lat(gps.lat>median(gps.lat)+latlon_spike_jump |gps.lat<median(gps.lat)-latlon_spike_jump )=NaN;%deal with "spikes"
  gps.lat=interp_finite(gps.lat);
  gps.lat=medfilt1(gps.lat);%median filter
  while any(gps.lat(abs(diff(gps.lat))>latlon_min_jump))%deal with too large jumps
    gps.lat(abs(diff(gps.lat))>latlon_min_jump)=NaN;
    gps.lat=interp_finite(gps.lat);
  end
  save(gps_fn,'-append','-struct','gps','lat');
  
  gps.lon(gps.lon>median(gps.lon)+latlon_spike_jump |gps.lon<median(gps.lon)-latlon_spike_jump )=NaN;%deal with "spikes"
  gps.lon=interp_finite(gps.lon,[],@gps_interp1);
  gps.lon=medfilt1(gps.lon);%median filter
  while any(abs(diff(gps.lon))>latlon_min_jump)%deal with too large jumps
    gps.lon(abs(diff(gps.lon))>latlon_min_jump)=NaN;
    gps.lon=interp_finite(gps.lon,[],@gps_interp1);
  end
  save(gps_fn,'-append','-struct','gps','lon'); 
  
  while any(abs(diff(gps.elev))>elev_min_jump)%deal with too large jumps
    gps.elev(abs(diff(gps.elev))>elev_min_jump)=NaN;
    gps.elev=interp_finite(gps.elev);
  end
   save(gps_fn,'-append','-struct','gps','elev');
end


