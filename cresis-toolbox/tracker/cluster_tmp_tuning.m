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

temp = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20200416_181841_t032_lsm.mat');
param= temp.param;
res_matrix_surface = zeros([length(param.cmd.frms),param.layer_tracker.track{1}.idx_reshape]);
res_matrix_bottom = zeros([length(param.cmd.frms),param.layer_tracker.track{1}.idx_reshape]);
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
filename = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_layer_tracker_tmp/CSARP_layer_tune/20140516_01/';
save_name = '/cresis/snfs1/scratch/anjali/cluster_tuning/';
num_gt_isfinite_surf = 0;
num_isnan_surf = 0;
num_points_surf = 0;

num_gt_isfinite_bot = 0;
num_isnan_bot = 0;
num_points_bot = 0;

for track_idx = 1:3
  frm_idx = 1;
  for frm = [40 41]
    data_fn_dir = ct_filename_out(param, param.layer_tracker.echogram_source, '');
    data_fn_name = sprintf('Data_%s_%03d.mat',param.day_seg,frm);
    data_fn      = fullfile(data_fn_dir, data_fn_name);
    data = load(data_fn);
    frm_dir = sprintf('layer_tracker_%03d',frm);
    surf = interp1(layers(1).gps_time,layers(1).twtt,data.GPS_time);
    surf_bins = round(interp1(data.Time,1:length(data.Time),surf));
    bot = interp1(layers(2).gps_time,layers(2).twtt,data.GPS_time);
    bot_bins = round(interp1(data.Time,1:length(data.Time),bot));
    dt = data.Time(2) - data.Time(1);
    switch param.layer_tracker.track{track_idx}.method
      case 'lsm'
        
        fname = sprintf('%s_%s.mat',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method);
        frame_fn_name = fullfile(filename,frm_dir,fname);
        track_data = load(frame_fn_name);
        for i = 1:16
          try
          surf = interp1(track_data.gps_time,track_data.twtt(i,:),data.GPS_time);
          catch ME
            surf = interp_finite(interp1(track_data.gps_time,track_data.twtt(i,:),data.GPS_time),NaN);
          end
          surf_bins_itr = round(interp1(data.Time,1:length(data.Time),surf));
          num_gt_isfinite = sum(isfinite(surf_bins));
          num_gt_isfinite_surf = num_gt_isfinite_surf + num_gt_isfinite;
          num_isnan = sum(isfinite(surf_bins) & ~isfinite(surf_bins_itr));
          num_isnan_surf = num_isnan_surf + num_isnan;
          num_points = sum(abs(surf_bins-surf_bins_itr) < 5*dt);
          num_points_surf = num_points_surf + num_points;
%           for temp = 1:length(surf)
%             if(isfinite(surf(temp)) && isnan(surf_bins_itr(temp)))
%               num_isnan = num_isnan + 1;
%             end
%             if (abs(surf(temp)-surf_bins_itr(temp)) < 5*dt)
%               num_points = num_points+1;
%             end
%           end
          res_s.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).res(frm_idx,param.layer_tracker.track{track_idx}.idx(i)) = nanmean(abs(surf_bins - surf_bins_itr));
          res_s.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).num_gt_isfinite(frm_idx) = num_gt_isfinite;
          res_s.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).num_isnan(frm_idx) = num_isnan;
          res_s.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).num_points(frm_idx) = num_points;
        end
        
        pos = 1;
        for i = 17:32
          try
          bot = interp1(track_data.gps_time,track_data.twtt(i,:),data.GPS_time);
          catch ME
          bot = interp_finite(interp1(track_data.gps_time,track_data.twtt(i,:),data.GPS_time),NaN);
          end
          bot_bins_itr = round(interp1(data.Time,1:length(data.Time),bot));
          num_gt_isfinite = sum(isfinite(bot_bins));
          num_gt_isfinite_bot = num_gt_isfinite_bot + num_gt_isfinite;
          num_isnan = sum(isfinite(bot_bins) & ~isfinite(bot_bins_itr));
          num_isnan_bot = num_isnan_bot + num_isnan;
          num_points = sum(abs(bot_bins-bot_bins_itr) < 5*dt);
          num_points_bot = num_points_bot + num_points;
%           for temp = 1:length(bot)
%             if(isfinite(bot(temp)) && isnan(bot_bins_itr(temp)))
%               num_isnan = num_isnan + 1;
%             end
%             if (abs(bot(temp)-bot_bins_itr(temp)) < 5*dt)
%               num_points = num_points+1;
%             end
         
          res_b.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).res(frm_idx,param.layer_tracker.track{track_idx}.idx(i)) = nanmean(abs(bot_bins - bot_bins_itr));
          
          res_b.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).num_gt_isfinite(frm_idx) = num_gt_isfinite;
          res_b.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).num_isnan(frm_idx) = num_isnan;
          res_b.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).num_points(frm_idx) = num_points;
          pos = pos+1;
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
    ctr = ctr+1;
  end
%   res_matrix_surface = res_matrix_surface + res_s.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).res;
%   res_matrix_bottom = res_matrix_bottom + res_b.(sprintf('%s_%s',param.layer_tracker.track{track_idx}.method,param.layer_tracker.track{track_idx}.name)).res;
end
[min_val_surf,min_idx1] = min(res_matrix_surface,[],1);
[min_val_surf,min_idx2] = min(min_val_surf,[],2);
min_idx1 = min_idx1(min_idx2);

fprintf('hi');


