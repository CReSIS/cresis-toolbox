% Geostatistical Analsysis - 3D data
% Acquire geostatistics from ground-truth 3D layer data
%   Cross-track transition model
%
% Author: Victor Berger
%
% See also: geostat_2D_DIM_and_AlongTrack.m, geostat_3D_AlongTrack.m, geostat_3D_DIM.m

params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'','post');
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
params = ct_set_params(params,'cmd.frms',[1]);

numDOABINS = 64;
surfdata_path = 'CSARP_post/surfData';
music3D_path  = 'CSARP_post/music3D';

%%
totalnumfr    = 102;
totalnumsl    = 3332;

%%
dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s (%s)\n', dbstack_info(1).name, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

frm_counter = 0;

clear steps;
steps = NaN * ones(totalnumfr, totalnumsl, numDOABINS);

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
    
    frm_counter = frm_counter + 1;
    
    fprintf('\n\n$$$ %s_%03d $$$',param.day_seg, frm_idx);
    
    data = load(fullfile(ct_filename_out(param, surfdata_path), ...
      sprintf('Data_%s_%03d',param.day_seg, frm_idx)), 'surf');
    
    for slice_idx = 1:length(data.surf(1).y)
      
      % Check ICEMASK is all ice
      % Check QUALITY is all good
      if ~all(data.surf(3).y(:, slice_idx)) || ~all(data.surf(9).y(:, slice_idx))
        continue
      end
      
      for doa = 1 : size(data.surf(2).y,1) - 1 % doa is the source doa
        % RBIN difference between source (doa) and dest (doa+1)
        steps(frm_idx, slice_idx, doa) = data.surf(2).y(doa,slice_idx) - data.surf(2).y(doa+1,slice_idx);
       
      end % END DoA-TO-DoA LOOP
    end % END SLICE-TO-SLICE LOOP
  end % END FRAME-TO-FRAME LOOP
end % END SEGMENT-TO-SEGMENT LOOP

vars_vector = zeros(1, numDOABINS);
mean_vector = zeros(1, numDOABINS);

for idx = 1 : numDOABINS
  temp_mat = steps(:, :, idx);
  temp_mat = temp_mat(:);
  vars_vector(idx) = nanvar(temp_mat);
  mean_vector(idx) = nanmean(temp_mat);
end