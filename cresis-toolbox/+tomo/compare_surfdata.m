function [frm_id,rmse_f,mean_f,median_f,min_f,max_f,total_diff] ...
  = compare_surfdata(param,param_override)
% function [rmse_f,mean_f,median_f,min_f,max_f,total_diff] ...
%   = compare_surfdata(param,param_override)
%
% Compares surface A (reference) and surface B
%   from a surfData file.
%
% param = struct with processing parameters
% param_override = parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% .compare: Struct with parameters controlling compare_surfdata
%  .surfdata_ref: Directory where reference (ideal) surface exists
%  .surf_name_ref: Name of surface in reference file
%  .surfdata_quality: Directory where quality surface exists
%  .surfdata_other: Cell array of directories where surfaces to compare are
%  .surf_name_other: Name of surface comparison file
%  .cdf_title: Title or label to use in plots
%  .cutoffs: Cutoff interval in percentage of statistics
%  .DOA_trim: DOA bins to ignore in the comparison. First number is
%    number of columns to trim from start and second number is number of
%    columns to trim from the end of the DOA bin list.
%  .out_dir: Output directory to store CDF image (cumulative
%    distribution function).
%  .save_cdf_flag: Logical, set to true to enable CDF figure saving
%  .display_status_flag: logical, set to true to display results for
%    each frame as the comparisons are done
%
% Each output is a cell array except frm_id that contains aggregation of all the
% results. Each element of the cell array is for the corresponding
% surfdata_other. Each cell element contains a vectors with the result
% for each frame compared.
%
% frm_id: (Cell) String containing frame ID
% rmse_f: Root mean squared error
% mean_f: Mean of the absolute value of the error
% median_f: Median of the absolute value of the error
% min_f: Min of the absolute value of the error
% max_f: Max of the absolute value of the error
% total_diff: (Cell) Full error matrix for each frame
%     
% Example:
%  See run_compare_surfdata.m for how to run this function directly.
%
% Authors: Victor Berger, Mohanad Al-Ibadi, John Paden
%
% See also: tomo.run_compare_surfdata.m, tomo.compare_surfdata,
%   tomo.surfdata.m

%% General Setup
% =====================================================================

if ~isstruct(param)
  % Functional form
  param();
end
param = merge_structs(param, param_override);

dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', dbstack_info(1).name, param.day_seg, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

if ~isfield(param.compare,'mode') | isempty(param.compare.mode)
  param.compare.method = 'twtt';
end

% Load frames file
frames = frames_load(param);

if isempty(param.cmd.frms)
  param.cmd.frms = 1:length(frames.frame_idxs);
end
% Remove frames that do not exist from param.cmd.frms list
[valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
if length(valid_frms) ~= length(param.cmd.frms)
  bad_mask = ones(size(param.cmd.frms));
  bad_mask(keep_idxs) = 0;
  warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
    param.cmd.frms(find(bad_mask,1)));
  param.cmd.frms = valid_frms;
end

% LAYER A (REFERENCE):
surfdata_ref = param.compare.surfdata_ref;
surf_name_ref = param.compare.surf_name_ref;
% LAYER B (OTHER):
surfdata_other     = param.compare.surfdata_other;
surf_name_other   = param.compare.surf_name_other;
% BOTH lAYERS:
cutoffs            = param.compare.cutoffs;
DOA_trim           = param.compare.DOA_trim;

out_dir = param.compare.out_dir;

display_status_flag = param.compare.display_status_flag;
  
%% Process each frame
% =========================================================================
rmse_f  = {};
mean_f = {};
median_f  = {};
max_f = {};
min_f = {};
frm_id = {};
total_diff = {};
h_figure = figure;
for frame_idx = 1:length(param.cmd.frms)
  frm = param.cmd.frms(frame_idx);
  
  frm_id{frame_idx} = sprintf('%s_%03d', param.day_seg, frm);
  
  fn_A = fullfile(ct_filename_out(param,surfdata_ref,''),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
  A = tomo.surfdata(fn_A);
  
  for comp_idx = 1:length(surfdata_other)
    fn_B = fullfile(ct_filename_out(param,surfdata_other{comp_idx},''),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
    B = tomo.surfdata(fn_B);
    
    switch param.compare.mode
      case 'twtt'
        [rmse,mean_diff,median_diff,min_diff,max_diff,surf_diff] ...
          = A.compare(surf_name_ref, B,surf_name_other{comp_idx},DOA_trim);
      case 'doa'
        [rmse,mean_diff,median_diff,min_diff,max_diff,surf_diff] ...
          = A.compare_doa(surf_name_ref, B,surf_name_other{comp_idx},DOA_trim,param.radar.fs);  
    end
    
    rmse_f{comp_idx}(frame_idx) = rmse;
    mean_f{comp_idx}(frame_idx) = mean_diff;
    median_f{comp_idx}(frame_idx)  = median_diff;
    min_f{comp_idx}(frame_idx) = min_diff;
    max_f{comp_idx}(frame_idx) = max_diff;
    total_diff{comp_idx}{frame_idx} = surf_diff;
    
    if display_status_flag
      fprintf('\n%s_%03d:', param.day_seg, frm);
      fprintf('\n Root mean squared error: %.4f', rmse);
      fprintf('\n Mean difference: %.4f', mean_diff);
      fprintf('\n Median difference: %.4f', median_diff);
      fprintf('\n Minimum difference: %.4f', min_diff);
      fprintf('\n Maximum difference: %.4f\n', max_diff);
      figure(h_figure); clf;
      imagesc(surf_diff); colorbar;
      warning('Run dbcont when ready.\n');
      keyboard;
    end
  end
end

try
  delete(h_figure);
end
