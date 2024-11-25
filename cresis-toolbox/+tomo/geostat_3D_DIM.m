% Geostatistical Analsysis - 3D data
% Acquire geostatistics from ground-truth 3D layer data
%   Distance-to-ice-margin distributions
%
% Author: Victor Berger
%
% See also: geostat_2D_DIM_and_AlongTrack.m, geostat_3D_AlongTrack.m, geostat_3D_CrossTrack.m

params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'','post');
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
params = ct_set_params(params,'cmd.frms',[1]);

DoA_trim      = [5 5];
surfdata_path = 'CSARP_post/surfData';
music3D_path  = 'CSARP_post/music3D';

%%
totalDoA      = 54;
maxdist       = 5e3;

%%
dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s (%s)\n', dbstack_info(1).name, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

clear distanceMAP;
distanceMAP{maxdist} = [];

%% ICEMASK
param.radar_name = 'rds';
param.season_name = '2014_Greenland_P3';
ice_mask_fn = ct_filename_gis(param,fullfile('canada','ice_mask','03_rgi50_ArcticCanadaNorth','03_rgi50_ArcticCanadaNorth.bin'));
[ice_mask_fn_dir, ice_mask_fn_name] = fileparts(ice_mask_fn);
ice_mask_mat_fn = fullfile(ice_mask_fn_dir,[ice_mask_fn_name '.mat']);
ice_mask = load(ice_mask_mat_fn,'R','X','Y','proj');

[fid,msg] = fopen(ice_mask_fn,'r');
if fid < 1
  fprintf('Could not open file %s\n', ice_mask_bin_fn);
  error(msg);
end
ice_mask.mask = logical(fread(fid,[length(ice_mask.Y),length(ice_mask.X)],'uint8'));
ice_mask.dist = round(bwdist(ice_mask.mask == 0));
fclose(fid);
%%
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
    
    bottomDEM = load(fullfile(ct_filename_out(param, 'DEM', ''), ...
      sprintf('%s_%03d_bottom',param.day_seg, frm_idx)));
    
    margindist = interp2(ice_mask.X, ice_mask.Y, ice_mask.dist, ...
      bottomDEM.points.x, bottomDEM.points.y, 'nearest');
    
    for slice_idx = 1:length(data.surf(1).y)
      
      % Check QUALITY is all good
      if ~all(data.surf(9).y(1+DoA_trim(1):end-DoA_trim(2), slice_idx))
        continue
      end
      
      x_length = length(data.surf(2).y(:, slice_idx));
      trimmed_length = x_length-sum(DoA_trim);
      
      for doa = 1:trimmed_length
        dist_to_IM = margindist(doa, slice_idx);
        
        % Skip if current DoA has no ice
        if dist_to_IM <= 0 || dist_to_IM > maxdist
          continue;
        end
        
        % Find difference between top and bottom layers at desired DoA
        thick = data.surf(2).y(doa + DoA_trim(1), slice_idx) - ...
          data.surf(1).y(doa + DoA_trim(1), slice_idx);

        % Negative thickness (should not happen)
        if thick <= 0
          thick = 0;
        end
    
        if ~isnan(dist_to_IM)
          distanceMAP{dist_to_IM} = [distanceMAP{dist_to_IM}, thick];
        end
        
      end % END DoA-TO-DoA LOOP
    end % END SLICE-TO-SLICE LOOP
  end % END FRAME-TO-FRAME LOOP
end % END SEGMENT-TO-SEGMENT LOOP

%% Generate mean and variance vectors
meansvector = NaN * zeros(1, maxdist);
sigmavector = NaN * zeros(1, maxdist);

for midx = 1:maxdist
  if ~isempty(distanceMAP{midx})
    try
      fd = fitdist(distanceMAP{midx}', 'Normal');
      meansvector(midx) = fd.mu;
      sigmavector(midx) = fd.sigma;
    catch ME
      meansvector(midx) = 0;
      sigmavector(midx) = 0;
    end
  end
end