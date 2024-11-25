function create_vectors_from_records(param,param_override)
% create_vectors_from_records(param,param_override)
%
% Creates a .mat file containing a structure which has a time stamp,
% position, and filename for every filename passed in. It is used
% with the plot_vectors command.
%
% Can be run as a function by passing in the param argument
% or a script (by setting the default value of param).
%
% Output file contains:
% vectors: structure with the following fields
%    .year: vector
%    .month: vector
%    .day: vector
%    .timeUTC: vector of seconds since epoch Jan 1, 1970
%    .lat: latitude (double vector, degrees)
%    .lon: longitude (double vector, degrees)
%    .elevation: elevation (double vector, meters)
%    .file: structure containing fields to pass
%
% Inputs:
% param = struct with processing parameters
%         -- OR --
%         function handle to script with processing parameters
% param_override = parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% Examples:
%   See master
%
% Authors: John Paden
%
% See also: master

% =====================================================================
% General Setup
% =====================================================================

dbstack_info = dbstack;
if ~exist('param','var') || isempty(param) || length(dbstack_info) == 1
  % =====================================================================
  % Debug Setup
  % =====================================================================
  param = read_param_xls(ct_filename_param('rds_param_2017_Greenland_P3.xls'),'20170403_01');
  
  clear('param_override');
  param_override.sched.type = 'no scheduler';
  param_override.sched.rerun_only = true;

  % Input checking
  if ~exist('param','var')
    error('A struct array of parameters must be passed in\n');
  end
  global gRadar;
  if exist('param_override','var')
    param_override = merge_structs(gRadar,param_override);
  else
    param_override = gRadar;
  end
  
elseif ~isstruct(param)
  % Functional form
  param();
end
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', dbstack_info(1).name, param.day_seg, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

% =====================================================================
% Get the files
% =====================================================================

records = records_load(param);

if ~isfield(param.vectors.file,'adc') || isempty(param.vectors.file.adc)
  adc_idx = 1;
  param.vectors.file.adc = records.param_records.records.file.adcs(adc_idx);
else
  adc_idx = find(param.vectors.file.adc == records.param_records.records.file.adcs);
end

vectors_idx = 0;
for fn_idx = 1:length(records.relative_filename{adc_idx})
  fn = records.relative_filename{adc_idx}{fn_idx};
  
  if any(strcmpi(param.radar_name,{'accum'}))
    fname = fname_info_accum(fn);
  elseif any(strcmpi(param.radar_name,{'accum2'}))
    fname = fname_info_accum2(fn);
  elseif any(strcmpi(param.radar_name,{'snow','snow2','snow3','kuband','kuband2','kuband3'}))
    fname = fname_info_fmcw(fn);
  elseif any(strcmpi(param.radar_name,{'icards'}))
    fname = fname_info_icards(fn);
  elseif any(strcmpi(param.radar_name,{'mcords'}))
    fname = fname_info_mcords(fn);
  elseif any(strcmpi(param.radar_name,{'mcords2','mcords3'}))
    fname = fname_info_mcords2(fn);
  elseif any(strcmpi(param.radar_name,{'mcrds'}))
    fname = fname_info_mcrds(fn);
  end
  
  fprintf('  File index %d/%d (filename idx %d) (%s)\n', ...
    fn_idx, length(records.relative_filename{adc_idx}), fname.file_idx, ...
    datestr(now,'HH:MM:SS'));
  
  vectors_idx = vectors_idx + 1;
  % Store the filename information
  vectors.file(vectors_idx).idx = fname.file_idx;
  vectors.file(vectors_idx).adcs = param.vectors.file.adc;
  if isfield(fname,'group')
    vectors.file(vectors_idx).recording_group = fname.group;
  end
  vectors.file(vectors_idx).base_dir = param.vectors.file.base_dir;
  vectors.file(vectors_idx).adc_folder_name = param.vectors.file.adc_folder_name;
  if isfield(fname,'datenum')
    vectors.file(vectors_idx).datenum = fname.datenum;
  end
  vectors.fileNumber(vectors_idx) = fn_idx;
  
  % Find first record for this file
  vectors.gps_time(vectors_idx) = records.gps_time(records.relative_rec_num{adc_idx}(fn_idx));
  vectors.lat(vectors_idx) = records.lat(records.relative_rec_num{adc_idx}(fn_idx));
  vectors.lon(vectors_idx) = records.lon(records.relative_rec_num{adc_idx}(fn_idx));
  vectors.elev(vectors_idx) = records.elev(records.relative_rec_num{adc_idx}(fn_idx));
  vectors.roll(vectors_idx) = records.roll(records.relative_rec_num{adc_idx}(fn_idx));
  vectors.pitch(vectors_idx) = records.pitch(records.relative_rec_num{adc_idx}(fn_idx));
  vectors.heading(vectors_idx) = records.heading(records.relative_rec_num{adc_idx}(fn_idx));
end

% Make sure output directory exists
out_fn = ct_filename_support(param,param.vectors.out_fn,'vectors');
[out_dir out_name] = fileparts(out_fn);
if ~exist(out_dir,'dir')
  mkdir(out_dir);
end

param_vectors = param;

fprintf('  Saving file %s\n', out_fn);
save(out_fn,'vectors','param_vectors');

return;
