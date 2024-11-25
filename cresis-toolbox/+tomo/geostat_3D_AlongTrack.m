% Geostatistical Analsysis - 3D data
% Acquire geostatistics from ground-truth 3D layer data
%   Along-track transition model
%
% Author: Victor Berger
%
% See also: geostat_2D_DIM_and_AlongTrack.m, geostat_3D_CrossTrack.m, geostat_3D_DIM.m

params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'','post');
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
params = ct_set_params(params,'cmd.frms',[1]);

surfdata_path = 'CSARP_post/surfData';
music3D_path  = 'CSARP_post/music3D';

%%
sl_vars = nan * ones(64, 3332*52);

%%
dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s (%s)\n', dbstack_info(1).name, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

sl_counter = 1;

for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) ...
      || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  
  % Load frames file
  frames = frames_load(param);
  
  if isempty(param.cmd.frms)
    param.cmd.frms = 1:length(frames.frame_idxs);
  end
  
  for frm_idx = param.cmd.frms        
    fprintf('\n\n$$$ %s_%03d $$$',param.day_seg, frm_idx);

    data = load(fullfile(ct_filename_out(param, surfdata_path), ...
      sprintf('Data_%s_%03d',param.day_seg, frm_idx)), 'surf');
    
    for slice_idx = 1 : length(data.surf(1).y)-1
      % Load first ice-bottom layer
      bottom_1 = data.surf(2).y(:, slice_idx);
      % Check bottom_1 is ALL ICE
      if any(data.surf(3).y(:, slice_idx))
        continue;
      end
      % Load second ice-bottom layer
      bottom_2 = data.surf(2).y(:, slice_idx + 1);
      % Check bottom_2 is ALL ICE
      if any(data.surf(3).y(:, slice_idx + 1))
        continue;
      end
      
      sl_vars(:, sl_counter) = bottom_1' - bottom_2';
      sl_counter = sl_counter + 1;
    end % END SLICE-TO-SLICE LOOP
  end % END FRAME-TO-FRAME LOOP
end % END SEGMENT-TO-SEGMENT LOOP

%% Result calculation
vars_vector = nan * ones(1, 64);
for doa_idx = 1:64
  vars_vector(doa_idx) = nanvar(sl_vars(doa_idx, :));  
end