% script post_csv_kml
%
% Creates a CSV and KML file for each segment file.
%
% Outputs:
%   gRadar.out_path/param.radar_name/param.season_name/CSARP_post/csv/
%     Data_YYYYMMDD_SS.csv
%     Browse_Data_YYYYMMDD_SS.kml
%
% Author: John Paden

%% User Settings

params = read_param_xls(ct_filename_param('snow_param_2019_SouthDakota_CESSNA.xls'));
params = ct_set_params(params,'cmd.generic',1);
params = ct_set_params(params,'cmd.generic',0,'cmd.notes','Do not process');

% point_spacing: specifies the spacing between geographic points in the CSV
% and KML files
point_spacing = 1000;

%% Automated Section

fprintf('=============================================================\n');
fprintf('post_csv_kml (%s)\n\n', datestr(now));
fprintf('=============================================================\n');

% =====================================================================
% Create param structure array
% =====================================================================
tic;
global gRadar;

clear('param_override');

% Input checking
if ~exist('params','var')
  error('Use run_master: A struct array of parameters must be passed in\n');
end
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

%% Process each of the segments
% =====================================================================
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
 
  csv_dir = fullfile(ct_filename_out(param,'post','',true),'csv');
  if ~exist(csv_dir,'dir')
    mkdir(csv_dir)
  end
  kml_dir = fullfile(ct_filename_out(param,'post','',true),'kml');
  if ~exist(kml_dir,'dir')
    mkdir(kml_dir)
  end
  
  try
    records = records_load(param);
    UTC_sod = epoch_to_sod(records.gps_time,param.day_seg(1:8));
    
    frames = frames_load(param);
  catch ME
    warning(ME.getReport);
    continue;
  end
  
  % Create new filename
  csv_fn = sprintf('Browse_Data_%s.csv',param.day_seg);
  csv_fn = fullfile(csv_dir,csv_fn);
  
  fid_csv = fopen(csv_fn,'wt');
  fprintf(fid_csv,'%s,%s,%s,%s,%s\n',...
    'LAT','LON','ELEVATION','UTCTIMESOD','FRAME');
  % Make a point every point_spacing and include at least the first and last point in each frame
  along_track = geodetic_to_along_track(records.lat,records.lon,records.elev);
  for frm = 1:length(frames.frame_idxs)
    first_rec = frames.frame_idxs(frm);
    if frm < length(frames.frame_idxs)
      last_rec = frames.frame_idxs(frm+1)-1;
    else
      last_rec = length(records.lat);
    end
    
    recs = first_rec;
    rec = first_rec + 1;
    while rec < last_rec
      if along_track(rec) > along_track(recs(end)) + point_spacing
        recs(end+1) = rec;
      end
      rec = rec + 1;
    end
    recs = [recs last_rec];
    
    frm_id_num = [param.day_seg(1:8) param.day_seg(10:11) sprintf('%03d',frm)];
    for rec = recs
      fprintf(fid_csv,'%2.6f,%2.6f,%5.4f,%4.4f,%s\n',...
        records.lat(rec),records.lon(rec),...
        records.elev(rec),UTC_sod(rec),frm_id_num);
    end
  end
  fclose(fid_csv);
  fprintf('  Writing %s\n',csv_fn);
  
  % Create KML browse files for each segment
  % Extract day_seg from filename
  in_fn = csv_fn;
  [in_fn_dir in_fn_name] = fileparts(in_fn);
  kml_out_fn = fullfile(kml_dir, [in_fn_name '.kml']);
  day_seg = in_fn_name(13:end);
  kml_write_cresis(in_fn, kml_out_fn, day_seg,'vectors',1);
  fprintf('  Writing %s\n',kml_out_fn);
end

% Create a concatenated CSV browse file of the whole season
in_search_str = fullfile(csv_dir,'*.csv');
delim = ',';
season_fn_name = sprintf('Browse_%s',param.season_name);
out_fn = fullfile(csv_dir, [season_fn_name '.csv']);
fprintf('Creating concatenated CSV browse file of the whole season %s\n',out_fn);
sys_cmd = sprintf('cat %s  | grep -v LAT | sed 1i"LAT%sLON%sELEVATION%sUTCTIMESOD%sFRAME" >%s', ...
  in_search_str,delim,delim,delim,delim,out_fn);
system(sys_cmd);

return;

