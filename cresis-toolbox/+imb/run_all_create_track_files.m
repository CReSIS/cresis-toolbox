% script run_all_create_track_files
% run_all_create_track_files
%
% Creates season track file(s) containing the lat, lon, and other
% information. The imb.picker loads these file when plotting flightlines
% without OPS. Loading all the individual CSARP_layer files would be
% slow so using these track files helps speed imb.picker loading.
%
% Output filenames are of the form:
% .../csarp_support/tracks/tracks_SYSTEM_SEASONNAME.mat
% For example:
% .../csarp_support/tracks/tracks_accum_2018_Antarctica_TObas.mat
%
% Output file:
%
% These variables are all 1 by Nx vectors of the same length, segments are
% terminated with NaN and all segments are included in these Nx length
% vectors:
%   bottom: ice bottom two way travel time in seconds
%   elev: elevation in meters
%   frm_id: full frame ID 2019020401123
%   lat: latitude in degrees
%   lon: longitude in degrees
%   surf: ice surface two way travel time in seconds
%   quality: integer enumeration of bottom quality, 1=good, 2=moderate,
%     3=poor or derived from another source
%  frm_info: structure containing frame information
%    .frm_id: Nfrm element vector of frame IDs
%    .start_gps_time: Nfrm element vector of start GPS times for each frame
%    .stop_gps_time: Nfrm element vector of stop GPS times for each frame
%   
% Author: John Paden, Rohan Choudhari
%
% See also: imb.run_all_create_track_files.m,
% imb.create_track_files.m

%% User Settings
% =========================================================================

% Select seasons in run_all:
run_all;

%% User Settings: Select layers
% First layer is the "surface"
% Second layer is the "bottom"
if 1
  layer_params = struct('name','surface');
  layer_params.source = 'layerdata';
  % layer_params.layerdata_source = 'CSARP_post/layerData';
  layer_params.existence_check = true;
  layer_params(2).name = 'bottom';
  layer_params(2).source = 'layerdata';
  % layer_params(2).layerdata_source = 'CSARP_post/layerData';
  layer_params(2).existence_check = false;
else
  % Debug: Enable to use non-standard layer data
  keyboard
  layer_params = struct('name','surface');
  layer_params.source = 'layerdata';
  layer_params(1).layerdata_source = 'layer_koenig';
  layer_params(2).existence_check = true;
  layer_params(1).fix_broken_layerdata = true; % Found some bad files
  layer_params(2).name = 'bottom';
  layer_params(2).source = 'layerdata';
  layer_params(2).layerdata_source = 'layer_koenig';
  layer_params(2).existence_check = false;
  layer_params(2).fix_broken_layerdata = true; % Found some bad files
end

param_override = [];
param_override.create_track_files.layer_params = layer_params;
run_create_track_files.mode = 'create';
% run_create_track_files.mode = 'append';

%% Automated Section
% =========================================================================
% Input checking
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

%% Loop to process each season
for param_idx = 1:length(param_fns)
  
  % Initialize variables to be extracted from layers
  lat = [];
  lon = [];
  gps_time = [];
  frm_id = [];
  surf = [];
  bottom = [];
  elev = [];
  quality = [];
  frm_info = [];
  frm_info.frm_id = [];
  frm_info.start_gps_time = [];
  frm_info.stop_gps_time = [];
  
  % Read in parameter spreadsheet
  param_fn = ct_filename_param(param_fns{param_idx});
  fprintf('Reading %s\n', param_fn);
  params = read_param_xls(param_fn,'');
  
  if isempty(params)
    continue;
  end
  
  % Run all segments (except "do not process")
  if 1
    params = ct_set_params(params,'cmd.generic',1);
    params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');
  else
    % Debug: Enable to run only particular segments
    keyboard
    params = ct_set_params(params,'cmd.generic',0);
    params = ct_set_params(params,'cmd.generic',1,'day_seg','20120330_04');
  end
  
  %% Load each segment
  for param_idx = 1:length(params)
    param = params(param_idx);
    
    if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
      fprintf('%s\tdo not process\n', param.day_seg);
      continue;
    end
    
    % Input checks: run_create_track_files
    if ~exist('run_create_track_files','var')
      run_create_track_files = [];
    end
    % run_create_track_files.mode: string containing the mode. Must be either
    % 'create' (default) or 'append'. The create mode overwrites the existing file. The
    % append mode adds segments to the existing file. Append is slower for doing whole seasons,
    % but is faster if just adding a few segments.
    if ~isfield(run_create_track_files,'mode') || isempty(run_create_track_files.mode)
      run_create_track_files.mode = 'create';
    end
    
    tmp = [];
    try
      param.cmd.frms = [];
      [tmp.lat,tmp.lon,tmp.gps_time,tmp.frm_id,tmp.elev,tmp.surf,tmp.bottom,tmp.quality,tmp.frm_info,gps_source] = imb.create_track_files(param,param_override);
    catch ME
      fprintf('%s\terror!!!\t%s\n', param.day_seg, ME.getReport);
      continue;
    end
    
    if strcmpi(run_create_track_files.mode,'append')
      %% Append to existing season file
      
      % Load existing file for this season
      % -------------------------------------------------------------------
      out_fn_dir = ct_filename_support(param,'tracks','');
      out_fn_name = sprintf('tracks_%s_%s_%s.mat', param.post.ops.location, ct_output_dir(param.radar_name), param.season_name);
      out_fn = fullfile(out_fn_dir,out_fn_name);
      if ~exist(out_fn,'file')
        % If file does not exist, switch to create mode
        run_create_track_files.mode = 'create';
      else
        fprintf('%s\tloaded\t%d\t%d\t', param.day_seg, length(tmp.lat), sum(~isnan(tmp.bottom)));
        fprintf('Appending\t%s\n', out_fn);
        old = load(out_fn);
        
        % Determine the numeric frm_id for the segment that is being inserted
        tmp_frm_id = str2num(param.day_seg([1:8,10:11]))*1000;
        
        % Store along-track data
        % -----------------------------------------------------------------
        % stop_idx: index to stop at for old data
        stop_idx = find(old.frm_id < tmp_frm_id,1,'last');
        if isempty(stop_idx)
          stop_idx = 0;
        else
          stop_idx = stop_idx + 1; % Include the NaN at the end of the segment
        end
        
        % start_idx: the index to start again after the top index
        start_idx = find(old.frm_id > tmp_frm_id+999,1);
        if isempty(start_idx)
          start_idx = length(old.frm_id) + 1;
        end
        
        % Add new segment to file; also removes old data for the segment if
        % it was there.
        lat = [old.lat(1:stop_idx) tmp.lat NaN old.lat(start_idx:end)];
        lon = [old.lon(1:stop_idx) tmp.lon NaN old.lon(start_idx:end)];
        gps_time = [old.gps_time(1:stop_idx) tmp.lon NaN old.gps_time(start_idx:end)];
        frm_id = [old.frm_id(1:stop_idx) tmp.frm_id NaN old.frm_id(start_idx:end)];
        elev = [old.elev(1:stop_idx) tmp.elev NaN old.elev(start_idx:end)];
        surf = [old.surf(1:stop_idx) tmp.surf NaN old.surf(start_idx:end)];
        bottom = [old.bottom(1:stop_idx) tmp.bottom NaN old.bottom(start_idx:end)];
        quality = [old.quality(1:stop_idx) tmp.quality NaN old.quality(start_idx:end)];
        
        % Store frame GPS time boundaries
        % -----------------------------------------------------------------
        % stop_idx: index to stop at for old data
        stop_idx = find(old.frm_info.frm_id < tmp_frm_id,1,'last');
        if isempty(stop_idx)
          stop_idx = 0;
        end
        
        % start_idx: the index to start again after the top index
        start_idx = find(old.frm_info.frm_id > tmp_frm_id+999,1);
        if isempty(start_idx)
          start_idx = length(old.frm_info.frm_id) + 1;
        end
        
        frm_info.frm_id = [old.frm_info.frm_id(1:stop_idx) tmp.frm_info.frm_id old.frm_info.frm_id(start_idx:end)];
        frm_info.start_gps_time = [old.frm_info.start_gps_time(1:stop_idx) tmp.frm_info.start_gps_time old.frm_info.start_gps_time(start_idx:end)];
        frm_info.stop_gps_time = [old.frm_info.stop_gps_time(1:stop_idx) tmp.frm_info.stop_gps_time old.frm_info.stop_gps_time(start_idx:end)];
        
        ct_save(out_fn,'-append','bottom','elev','frm_id','frm_info','lat','lon','quality','surf');
      end
    end
    
    if strcmpi(run_create_track_files.mode,'create')
      % Concatenate on new season file
      % -------------------------------------------------------------------
      fprintf('%s\tloaded\t%d\t%d\n', param.day_seg, length(tmp.lat), sum(~isnan(tmp.bottom)));
      lat = [lat tmp.lat NaN];
      lon = [lon tmp.lon NaN];
      gps_time = [gps_time tmp.gps_time NaN];
      % Store full frame ID number 20190204_01_003 --> 2019020401003
      frm_id = [frm_id tmp.frm_id NaN];
      elev = [elev tmp.elev NaN];
      surf = [surf tmp.surf NaN];
      bottom = [bottom tmp.bottom NaN];
      quality = [quality tmp.quality NaN];
      % Store frame GPS time boundaries
      frm_info.frm_id = [frm_info.frm_id tmp.frm_info.frm_id];
      frm_info.start_gps_time = [frm_info.start_gps_time tmp.frm_info.start_gps_time];
      frm_info.stop_gps_time = [frm_info.stop_gps_time tmp.frm_info.stop_gps_time];
    elseif ~strcmpi(run_create_track_files.mode,'append')
      error('Valid modes are append or create. Invalid mode specified for run_create_track_files.mode: %s', run_create_track_files.mode);
    end
  end
  
  if strcmpi(run_create_track_files.mode,'create')
    if isempty(lat)
      %% No data error
      error('There is no data available and so no season layer file can be saved.');
      
    else
      %% Save output for this season
      out_fn_dir = ct_filename_support(param,'tracks','');
      out_fn_name = sprintf('tracks_%s_%s_%s.mat', param.post.ops.location, ct_output_dir(param.radar_name), param.season_name);
      out_fn = fullfile(out_fn_dir,out_fn_name);
      fprintf('  Saving %s\n\n', out_fn);
      if ~exist(out_fn_dir,'dir')
        mkdir(out_fn_dir);
      end
      file_type = 'tracks';
      file_version = '1';
      param = struct('day_seg',param.day_seg,'radar_name',param.radar_name, ...
        'season_name',param.season_name,'sw_version',param.sw_version);
      ct_save(out_fn,'bottom','elev','file_type','file_version','frm_id','frm_info','gps_source','gps_time','lat','lon','param','quality','surf');
    end
  end
end
