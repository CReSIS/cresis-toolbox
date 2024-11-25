%% Script run_LSM_tuning.m
%
% Runs the lsm 2D tracking algorithm
% on the desired dataset
%
% See also: LSM_tuning.m

dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s (%s)\n', dbstack_info(1).name, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

%% General User Settings
% Tracking algorithms: lsm

params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'','post');
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20140426_01');

% 23 segs
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20140313_07|20140313_08|20140313_10|20140325_07|20140331_02|20140401_04|20140405_01|20140409_02|20140410_01|20140412_01|20140412_02|20140412_04|20140415_04|20140415_05|20140416_01|20140421_01|20140501_01|20140506_01|20140507_01|20140520_04|20140520_05|20140521_01|20140508_01');

params = ct_set_params(params,'cmd.frms',[35]);

save_name = '/cresis/snfs1/projects/LSM_anjali/LSM_result_part9.mat';

options.name       = 'CSARP_post/mvdr';
options.debug      = false;
options.ops_write  = false;
options.save_img   = false;
options.save_add_f = false;

%% LSM User Settings
options.lsm.lyrtop       = 'lsm_top';
options.lsm.lyrbot       = 'lsm_bot';
options.lsm.numOuterIter = 350;
options.lsm.maxOuterIter = 50;

%% Automated section
global gRadar;

% Load one frame at a time
  for param_idx = 1:length(params)
    param = params(param_idx);
    if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
      continue;
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
    data_fn_dir = ct_filename_out(param, options.name, '');
    
    layer_params=[];
    layer_params(1).source = 'layerdata';
    layer_params(1).name = 'surface';
    layer_params(2).source = 'layerdata';
    layer_params(2).name = 'bottom';
    
    for frm = param.cmd.frms
      tuning_tic = tic;
      % get ground-truth for each frame using opsLoadlayers.m
      data_fn_name = sprintf('Data_%s_%03d.mat',param.day_seg,frm);
      data_fn      = fullfile(data_fn_dir, data_fn_name);
      layers_temp = opsLoadLayers(param,layer_params);
      
      try
        data = load(data_fn);
        data.frm = frm;
      catch ME
        fprintf('\nFailed to load file %s, skipping.\n', data_fn);
        continue;
      end
      Surface = layers_temp(1);
      Bottom = layers_temp(2);
      surf = interp_finite(interp1(Surface.gps_time,Surface.twtt,data.GPS_time));
      surf_bins = round(interp1(data.Time,1:length(data.Time),surf));
      try
        bot = interp_finite(interp1(Bottom.gps_time,Bottom.twtt,data.GPS_time));
      catch ME
        bot = interp_finite(interp1(Bottom.gps_time,Bottom.twtt,data.GPS_time),NaN);
      end
      bot_bins = round(interp1(data.Time,1:length(data.Time),bot));
      
      y = [160:20:300 mean(surf_bins)];
      dy = [5 10 20 40];
      for y_val = 1:length(y)
        options.lsm.y = y(y_val);
        for dy_val = 1:length(dy)
          options.lsm.dy = dy(dy_val);
          [matrix_x,matrix_y,flag]=tomo.LSM_tuning(param, options, data);
          
          matrix_y(matrix_y > size(data.Data,1)) = size(data.Data,1);
          matrix_y(matrix_y < 1) = 1;
          
          for iter = 1:16
            res_s = mean(abs(surf_bins - matrix_y(1,:,iter))); % error in the surface
            res_b = mean(abs(bot_bins - matrix_y(2,:,iter))); % error in the bottom
            
            %                if res_s > 1e4 || res_b > 1e4
            %                   keyboard
            %                end
            LSM.(sprintf('Data_%s_%03d',param.day_seg,frm)).res_s(y_val,dy_val,iter) = res_s;
            LSM.(sprintf('Data_%s_%03d',param.day_seg,frm)).res_b(y_val,dy_val,iter) = res_b;
            LSM.(sprintf('Data_%s_%03d',param.day_seg,frm)).flag(y_val,dy_val,iter) = flag(iter);
            try
              LSM.(sprintf('Data_%s_%03d',param.day_seg,frm)).(sprintf('y_%d_dy_%d',y(y_val),dy(dy_val))).matrix_y = matrix_y;
            catch ME
              LSM.(sprintf('Data_%s_%03d',param.day_seg,frm)).(sprintf('y_mean_dy_%d',dy(dy_val))).matrix_y = matrix_y;
            end
            
            if options.debug
              figure; imagesc(lp(data.Data)); colormap(1 - gray(256)); hold on; p1 = plot(surf_bins); p2 = plot(matrix_y(1,:,k)); p3 = plot(bot_bins); p4 =  plot(matrix_y(2,:,k)); legend([p1 p2 p3 p4], 'GTS', 'LSM_S','GTB','LSM_B')
            end
          end
        end
      end
      tuning_toc = toc(tuning_tic);
      fprintf('\nThis frame took: %.2f seconds', tuning_toc); % time taken for a single frame
      try
        save(save_name,'LSM','-append');
      catch ME
        save(save_name,'LSM');
      end
    end
  end
fprintf('\n\nAll done. (%s)\n\n',datestr(now,'dd-mmm-yyyy HH:MM:SS'));