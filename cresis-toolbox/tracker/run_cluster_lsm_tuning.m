%% Script run_cluster_LSM_tuning.m
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

% params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'));
%
% params = ct_set_params(params,'cmd.generic',0);
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20140313_08');
% params = ct_set_params(params,'cmd.frms',[1]);

% 23 segs
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20140313_07|20140313_08|20140313_10|20140325_07|20140331_02|20140401_04|20140405_01|20140409_02|20140410_01|20140412_01|20140412_02|20140412_04|20140415_04|20140415_05|20140416_01|20140421_01|20140501_01|20140506_01|20140507_01|20140520_04|20140520_05|20140521_01|20140508_01');

% %params = ct_set_params(params,'cmd.frms',[1]);
% for param_idx = 1:length(params)
%   param = params(param_idx);
%   if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) ...
%       || ischar(param.cmd.generic) || ~param.cmd.generic
%     continue;
%   end
% end
% for param_idx = 1:length(params)
%   param = params(param_idx);
%   if isfield(param.cmd,'generic') && ~iscell(param.cmd.generic) && ~ischar(param.cmd.generic) && param.cmd.generic
%     break;
%   end
% end
frm=1;
temp = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20200416_002026_t032_lsm.mat');
param= temp.param;
layer_params = [];
idx = 0;
idx = idx + 1;
layer_params(idx).name = 'surface';
layer_params(idx).source = 'layerdata';
layer_params(idx).layerdata_source = 'layer';
idx = idx+1;
layer_params(idx).name = 'bottom';
layer_params(idx).source = 'layerdata';
layer_params(idx).layerdata_source = 'layer';
layers = opsLoadLayers(param,layer_params);

for track_idx = 1:length(param.layer_tracker.track)
  for frm = param.cmd.frms
    data_fn_dir = ct_filename_out(param, param.layer_tracker.echogram_source, '');
    data_fn_name = sprintf('Data_%s_%03d.mat',param.day_seg,frm);
    data_fn      = fullfile(data_fn_dir, data_fn_name);
    data = load(data_fn);
    
    switch param.layer_tracker.track{track_idx}.method
      case 'lsm'
        for idx = 1:length(param.layer_tracker.track{track_idx}.lsm.storeIter)
          layer_params_surf(idx).name = sprintf('%s_%s_surface_%03d',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method,idx);
          layer_params_surf(idx).source = param.layer_tracker.layer_params.source;
          layer_params_surf(idx).layerdata_source = param.layer_tracker.layer_params.layerdata_source;
        end
        
        for idx = 1:length(param.layer_tracker.track{track_idx}.lsm.storeIter)
          layer_params_bot(idx).name = sprintf('%s_%s_bottom_%03d',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method,idx);
          layer_params_bot(idx).source = param.layer_tracker.layer_params.source;
          layer_params_bot(idx).layerdata_source = param.layer_tracker.layer_params.layerdata_source;
        end
        
      case 'viterbi'
        idx = 1;
        layer_params_bot(idx).name = sprintf('%s_%s_bottom',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method);
        layer_params_bot(idx).source = param.layer_tracker.layer_params.source;
        layer_params_bot(idx).layerdata_source = param.layer_tracker.layer_params.layerdata_source;
        
      case {'mcmc','stereo'}
        idx = 1;
        layer_params_surf(idx).name = sprintf('%s_%s_surface',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method);
        layer_params_surf(idx).source = param.layer_tracker.layer_params.source;
        layer_params_surf(idx).layerdata_source = param.layer_tracker.layer_params.layerdata_source;
        idx = idx + 1;
        layer_params_bot(idx).name = sprintf('%s_%s_bottom',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method);
        layer_params_bot(idx).source = param.layer_tracker.layer_params.source;
        layer_params_bot(idx).layerdata_source = param.layer_tracker.layer_params.layerdata_source;
        
      otherwise
        idx = 1;
        layer_params_surf(idx).name = sprintf('%s_%s_surface',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method);
        layer_params_surf(idx).source = param.layer_tracker.layer_params.source;
        layer_params_surf(idx).layerdata_source = param.layer_tracker.layer_params.layerdata_source;
    end
    
    layers_surf = opsLoadLayers(param,layer_params_surf);
    layers_bot = opsLoadLayers(param,layer_params_bot);
    
    
    surf = interp_finite(interp1(layers(1).gps_time,layers(1).twtt,data.GPS_time));
    surf_bins = round(interp1(data.Time,1:length(data.Time),surf));
    bot = interp_finite(interp1(layers(2).gps_time,layers(2).twtt,data.GPS_time));
    bot_bins = round(interp1(data.Time,1:length(data.Time),bot));
    dt = data.Time(2) - data.Time(1);
    for i = 1:length(layers_surf)
      num_isnan= 0;
      num_points = 0;
      surf = interp_finite(interp1(layers_surf(i).gps_time,layers_surf(i).twtt,data.GPS_time));
      surf_bins_itr = round(interp1(data.Time,1:length(data.Time),surf));
      num_gt_isfinite = length(find(isfinite(surf)));
      for temp = 1:length(surf)
        if(isfinite(surf(temp)) && isnan(surf_bins_itr(temp)))
          num_isnan = num_isnan + 1;
        end
        if (abs(surf(temp)-surf_bins_itr(temp)) < 5*dt)
          num_points = num_points+1;
        end
      end
      res_s.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).res(frm,i) = nanmean(abs(surf_bins - surf_bins_itr));
      res_s.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).num_gt_isfinite = num_gt_isfinite;
      res_s.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).num_isnan = num_isnan;
      res_s.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).num_points = num_points;
    end
    
    for i = 1:length(layers_bot)
      num_isnan= 0;
      num_points = 0;
      bot = interp_finite(interp1(layers_bot(i).gps_time,layers_bot(i).twtt,data.GPS_time));
      bot_bins_itr = round(interp1(data.Time,1:length(data.Time),bot));
      num_gt_isfinite = length(find(isfinite(bot)));
      for temp = 1:length(bot)
        if(isfinite(bot(temp)) && isnan(bot_bins_itr(temp)))
          num_isnan = num_isnan + 1;
        end
        if (abs(bot(temp)-bot_bins_itr(temp)) < 5*dt)
          num_points = num_points+1;
        end
      end
      res_b.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).res(frm,i) = nanmean(abs(bot_bins - bot_bins_itr));
      res_b.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).num_gt_isfinite = num_gt_isfinite;
      res_b.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).num_isnan = num_isnan;
      res_b.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).num_points = num_points;
    end
  end
end



fprintf('hi');


