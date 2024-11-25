% script gps_create_2009_antarctica_TO_Gambit_DGPSwINS
%
% Makes the DGPSwINS files for 2009 Antarctica TO field season

tic;
global gRadar;
support_path = '';
data_support_path = '';

if isempty(support_path) 
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2009_Antarctica_TO_Gambit');
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
debug_level = 2; 

% in_base_path = fullfile(support_path,'gps','MCRDS_2009_Greenland_POS_DGPSwINS');
% gps_path = fullfile(support_path,'gps','2009_Greenland_TO');
% in_fn = fullfile(in_base_path,'MCRDS_20090328_ALL_pos.mat');
in_fn = '/cresis/scratch1/shu/Gambit_DGPS/AIRGrav_Attitude_Flight_042.xyz';
out_fn = fullfile(gps_path, 'gps_Flight_042.mat');
fid = fopen(in_fn);
for ii = 1:6     % skip the header lines
    fgetl(fid);
end
DGPSwINS = fscanf(fid,'%g %g %g %g %g %g %g %g %g %g %g %g',[12,inf]);
fclose(fid);
DGPSwINS = DGPSwINS';
ymd = DGPSwINS(:,1);     % year, month,day
utc_sod = DGPSwINS(:,3);
pitch = DGPSwINS(:,5);
roll = DGPSwINS(:,6);
heading = DGPSwINS(:,7);
lat = DGPSwINS(:,8);
lon = DGPSwINS(:,9);
elev = DGPSwINS(:,12);

% the utc seconds of day, need to be  converted to gps time from epoch
epoch = datenum(1970,1,1,0,0,0);
ymd_str = num2str(ymd);
year = str2num(ymd_str(:,1:4));
month = str2num(ymd_str(:,5:6));
day = str2num(ymd_str(:,7:8));
utc_leap_seconds = ones(size(year))*14;  % for year 2008
utc_leap_seconds(find(year==2009))=15;   % for year 2009
tmpTime = (datenum(year,month,day,zeros(size(year)),zeros(size(year)),zeros(size(year)))-epoch)*86400+utc_leap_seconds;

% for ii = 1:length(year)
%     utc_leap_seconds = 14; % for year 2008
%     if year(ii)==2009
%         utc_leap_seconds = 15;
%     end
%     tmpTime(ii) = (datenum(year(ii),month(ii),day(ii),0,0,0)-epoch)*86400 + utc_leap_seconds;
% end
gps.gps_time = utc_sod+tmpTime;
% load('/cresis/data1/MCRDS/2009_Antarctica_Gambit/processed_data/Flight_06/gps_Files/nmea.20081225.mat','UTC_time','comp_time');
load('/cresis/data1/MCRDS/2009_Antarctica_Gambit/processed_data/Flight_43/gps_Files/nmea.20090110.mat','UTC_time','comp_time');
gps.time_offset = UTC_time(1)-comp_time(1);
gps.lat = lat;
gps.lon = lon;
gps.elev = elev;
gps.roll = roll*pi/180;
gps.pitch = pitch*pi/180;
gps.heading = heading*pi/180;
save(out_fn, '-STRUCT','gps','gps_time','time_offset','lat','lon','elev','roll','pitch','heading');
if debug_level >= 2
    gps_plot(out_fn);
end

return;
  
