% script run_all_download_track_files
% run_all_download_track_files
%
% Downloads a season track file. The imb.picker loads these files when
% plotting flightlines without OPS.
%
% Filenames are of the form:
% .../csarp_support/tracks/tracks_SYSTEM_SEASONNAME.mat
% For example:
% .../csarp_support/tracks/tracks_accum_2018_Antarctica_TObas.mat
%
% Author: John Paden, Rohan Choudhari
%
% See also: imb.run_all_download_track_files.m

%% User Settings
% =========================================================================

% Select seasons in run_all:
run_all;

%% User Settings
% =========================================================================
param_override = [];
param_override.download_track_files.force_update = false; % Only download if the files does not already exist

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

  % Read in parameter spreadsheet
  param_fn = ct_filename_param(param_fns{param_idx});
  fprintf('Reading %s\n', param_fn);
  params = read_param_xls(param_fn,'');

  if isempty(params)
    continue;
  end

  % Run all segments (except "do not process")
  params = ct_set_params(params,'cmd.generic',1);
  params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');

  %% Look for a good segment
  found_good_segment = false;
  for param_idx = 1:length(params)
    param = params(param_idx);

    if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
      fprintf('%s\tdo not process\n', param.day_seg);
      continue;
    else
      found_good_segment = true;
      param = merge_structs(param,param_override);
      break;
    end
  end
  if ~found_good_segment
    warning('No good segment found in this segment so skipping this segment''s track file.')
  else
    %% Save output for this season
    out_fn_dir = ct_filename_support(param,'tracks','');
    out_fn_name = sprintf('tracks_%s_%s_%s.mat', param.post.ops.location, ct_output_dir(param.radar_name), param.season_name);
    out_fn = fullfile(out_fn_dir,out_fn_name);
    url = sprintf('%s/data/csarp_support/tracks/%s', param.data.url, out_fn_name);
    if exist(out_fn,'file') && ~param.download_track_files.force_update
      fprintf('  File already exists %s\n  Set param.download_track_files.force_update to true to redownload.\n', out_fn)
    else
      if exist(out_fn,'file')
        fprintf('  Downloading %s\n', url);
        fprintf('  to overwrite %s\n', out_fn);
      else
        fprintf('  Downloading %s\n', url);
        fprintf('  to %s\n', out_fn);
      end
      if ~exist(out_fn_dir,'dir')
        mkdir(out_fn_dir);
      end
      wget_cmd = sprintf('wget -P %s %s', out_fn_dir, url);
      fprintf('  %s\n', wget_cmd);
      system(wget_cmd);
      if ~exist(out_fn,'file')
        warning('Failed to download file.');
      end
    end
  end
end
