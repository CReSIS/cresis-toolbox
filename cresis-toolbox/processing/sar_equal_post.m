% function sar_equal_output = sar_equal_post(param,param_override)
% sar_equal_output = sar_equal_post(param,param_override)
%
% Support function for sar_equal.m. Run this function from
% run_sar_equal_post.m after run_sar_equal.m has been run.

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input checking
% =====================================================================

% .debug_in_dir: string containing the ct_tmp output folder name where
% sar_equal stored the debug outputs. This is input to
% ct_filename_ct_tmp().
if ~isfield(param.sar_equal_post,'debug_in_dir') || isempty(param.sar_equal_post.debug_in_dir)
  param.sar_equal_post.debug_in_dir = 'sar_equal';
end
debug_in_dir = param.sar_equal_post.debug_in_dir;

%% Other Setup
% =========================================================================

physical_constants;

% Find the first wf-adc pair for the last image, the input file name
% is formed with these.
for img = 1:length(param.sar_equal_post.imgs)
  if img ~= ref_img
    fn_wf = param.sar_equal_post.imgs{img}(1,1);
    fn_adc = param.sar_equal_post.imgs{img}(1,2);
  end
end

%% Loop Frames: load each frame one at a time
% =========================================================================
sar_equal_output = {};
for frm_idx = 1:length(param.cmd.frms)
  frm = param.cmd.frms(frm_idx);
  
  %% Loop Frames: Load
  
  mat_fn = [ct_filename_ct_tmp(param,'',debug_in_dir,sprintf('sar_equal_wf_%02d_adc_%02d',fn_wf,fn_adc)) sprintf('_%03d.mat',frm)];
  fprintf('Loading %s\n', mat_fn);
  sar_equal_output{frm} = load(mat_fn);
  
end
