%% Script layer_tracker_tune.m

% Used to find best combination of paramters for given tracker method
% Uses temporary saved files stored in CSARP_layer_tracker_tmp
% Enter layer names in the gt_layer_params(idx).name field
% set temp to the file location of the param structure used for tracking in run_layer_tracker.m script
% set save_name to store final tuning results
% Statistical data saved: 
%   number of points with finite values of ground truth of twtt (num_gt_infinite),
%   number of points where ground truth twtt is finite and tracked data twtt is NaN (num_isnan) 
%   number of points where (tracked data twtt - ground truth twtt) < 5 * dt (num_points)
%   nanmean of (tracked data twtt - ground truth twtt) (res_matrix)
% Authors: Anjali Pare, John Paden
%
% See layer_tracker_tune_plot.m to view 2 dimensional imagesc plots of the data.


dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s (%s)\n', dbstack_info(1).name, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

%% General User Settings

temp = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20200909_032808_t056_lsm.mat');
param= temp.param;
filename = ct_filename_out(param,param.layer_tracker.layer_params.layerdata_source,'layer_tracker_tmp'); % where temporary files are saved
save_name = '/cresis/snfs1/scratch/anjali/cluster_tuning/resultTest3.mat'; % where to store tuning final result

gt_layer_params = [];
res_matrix = [];
num_layers = 0;
idx = 1;
gt_layer_params(idx).name = 'surface';
idx = idx + 1;
gt_layer_params(idx).name = 'bottom';

%% Find Best combination
%for layer_names = 1:length(gt_layer_names)
for layer_names = 1:idx
  res_matrix{layer_names} = zeros([length(param.cmd.frms),param.layer_tracker.track{1}.idx_reshape]);
  num_gt_isfinite.(sprintf('%s',gt_layer_params(layer_names).name)) = 0;
  num_isnan.(sprintf('%s',gt_layer_params(layer_names).name)) = 0;
  num_points.(sprintf('%s',gt_layer_params(layer_names).name)) = 0;
  num_layers = num_layers+1;
end

layers = opsLoadLayers(param,gt_layer_params);

idx_matrix = [(1:length(param.layer_tracker.track{1}.idx_reshape))+1 1]; % used for resizing

for track_idx = 1:length(param.layer_tracker.track)
  frm_idx = 0;
  for frm = param.cmd.frms
    frm_idx = frm_idx+1;
    data_fn_dir = ct_filename_out(param, param.layer_tracker.echogram_source, '');
    data_fn_name = sprintf('Data_%s_%03d.mat',param.day_seg,frm);
    data_fn      = fullfile(data_fn_dir, data_fn_name);
    data = load(data_fn);
    frm_dir = sprintf('layer_tracker_%03d',frm);
    dt = data.Time(2) - data.Time(1);
    
    fname = sprintf('%s_%s.mat',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method);
    frame_fn_name = fullfile(filename,frm_dir,fname); 
    track_data = load(frame_fn_name); % temporary file data
    ctr = 1;
    layer_idx = 1;
    pos = 0;
    for i = 1:(temp.param.layer_tracker.track{track_idx}.idx_reshape(1)*num_layers) % Number of iterations 
      pos = pos + 1;
      surf = interp1(layers(layer_idx).gps_time,layers(layer_idx).twtt,data.GPS_time);
      surf_bins = round(interp1(data.Time,1:length(data.Time),surf));
      surf = interp1(track_data.gps_time,track_data.twtt(i,:),data.GPS_time);
      surf_bins_itr = round(interp1(data.Time,1:length(data.Time),surf));
      num_gt_isfinite.(sprintf('%s',gt_layer_params(layer_idx).name)) = num_gt_isfinite.(sprintf('%s',gt_layer_params(layer_idx).name)) + sum(isfinite(surf_bins));
      num_isnan.(sprintf('%s',gt_layer_params(layer_idx).name)) = num_isnan.(sprintf('%s',gt_layer_params(layer_idx).name)) + (sum(isfinite(surf_bins) & ~isfinite(surf_bins_itr)));
      num_points.(sprintf('%s',gt_layer_params(layer_idx).name)) = num_points.(sprintf('%s',gt_layer_params(layer_idx).name)) + (sum(abs(surf_bins-surf_bins_itr) < 5*dt));
      res_matrix{layer_idx}(frm_idx,param.layer_tracker.track{track_idx}.idx(pos)) = nanmean(abs(surf_bins - surf_bins_itr));
      
      if mod(ctr,temp.param.layer_tracker.track{track_idx}.idx_reshape(1)) == 0
        layer_idx = layer_idx +1;
        pos = 0;
      end
      ctr = ctr +1;
    end
  end
end

points = [];
min_val = [];
res_matrix_all_frms = [];
for layer_names = 1:idx
  res_matrix_all_frms{layer_names} = nanmean(res_matrix{layer_names},1);
  res_matrix_all_frms{layer_names} = permute(res_matrix_all_frms{layer_names},idx_matrix);
  [min_val{layer_names},i]=min(res_matrix_all_frms{layer_names}(:));
  sizeMatrix = size(res_matrix_all_frms{layer_names});
  
  for dim = 1:length(size(res_matrix_all_frms{layer_names}))
    points{layer_names}(dim) = mod(floor((i-1)/prod(sizeMatrix(1:dim-1))),sizeMatrix(dim))+1;
  end
end

file_version = '1';
file_type = 'layer_tracker_tuning';

fn_dir = fileparts(save_name);
if ~exist(fn_dir,'dir')
   mkdir(fn_dir);
end

save(save_name,'res_matrix','num_isnan','num_points','num_gt_isfinite','points','min_val','res_matrix_all_frms','param','file_version','file_type');


