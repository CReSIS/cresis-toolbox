function success = layer_tracker_tune_plot
%% Function layer_tracker_tune_plot.m

% Used to plot 2 dimensional imagesc plots of data matrix from layer_tracker_tune.m
% set filename to the file location of where result data matrix is stored in layer_tracker_plot.m script
% set number of total layers (num_layers)
% set the format image must be saved in (e.g. fig, jpg, png)
% Plots will be saved in same folder as specified in filename
% Plots will be saved in the filename formatted as
% Authors: Anjali Pare, John Paden
%
% See layer_tracker_tune.m
%% Set Input
% =====================================================================
%filename = ct_filename_out(param,param.layer_tracker.layer_params.layerdata_source,'layer_tracker_tmp'); %where temporary files are saved
img_format = 'jpg';
filename = '/cresis/snfs1/scratch/anjali/cluster_tuning/result_layer_tune_vit_s011.mat'; % where the matrix is saved. Images generated will be saved in the same folder
num_layers = 1; % enter number of layers
img_dir = fileparts(filename);
if ~exist(img_dir,'dir')
  mkdir(img_dir);
end

%% Generate Input for Figure
matrix_fn = load(filename);
param = matrix_fn.param;
data = [];
for dim = 1:length(param.layer_tracker.track{1}.idx_reshape)
  temp = [];
  for track = 1:length(param.layer_tracker.track)
    if isempty(temp)
      temp = param.layer_tracker.track{track}.(param.layer_tracker.track{track}.method).(param.layer_tracker.track{track}.idx_dim_name{dim});
    else
      if ~any(temp == param.layer_tracker.track{track}.(param.layer_tracker.track{track}.method).(param.layer_tracker.track{track}.idx_dim_name{dim}))
        temp(end+1) = param.layer_tracker.track{track}.(param.layer_tracker.track{track}.method).(param.layer_tracker.track{track}.idx_dim_name{dim});
      end
    end
    
  end
  data{dim}=temp;
end


for layer_idx = 1:num_layers
  res_mat = matrix_fn.res_matrix_all_frms{layer_idx};
  points = matrix_fn.points{layer_idx};
  
  A = nchoosek(1:length(param.layer_tracker.track{1}.idx_reshape),2); % changed from 2
  for id = 1:length(A)
    min_points = setdiff(1:length(param.layer_tracker.track{1}.idx_reshape),A(id,:));
    min_idxs = points(min_points);
    res_matrix = permute(res_mat,[A(id,:) setdiff(1:length(param.layer_tracker.track{1}.idx_reshape),A(id,:))]);
    res_matrix = res_matrix(:,:,min_idxs(:));
    idx = A(id,:);
    labelTickX = data{idx(1)}; % x tick label
    labelTickY = data{idx(2)}; % y tick label
    labelNameX = param.layer_tracker.track{1}.idx_dim_name{idx(1)}; % x label name
    labelNameY = param.layer_tracker.track{1}.idx_dim_name{idx(2)}; % y label name
    xTick = 1:length(labelTickX); % x tick
    yTick = 1:length(labelTickY); % y tick
    %% Generate Figure
    h_fig(1) = figure('visible','off'); % figure is not displayed
    imagesc(squeeze(res_matrix'));
    hold on;
    plot(points(idx(1)),points(idx(2)),'x','LineWidth',4,'MarkerSize',10,'Color','white');
    
    ylabel(labelNameY);
    xlabel(labelNameX);
    set(gca,'XTickLabel',labelTickX);
    set(gca,'YTickLabel',labelTickY);
    set(gca,'XTick',xTick);
    set(gca,'YTick',yTick);
    h_colorbar = colorbar(gca);
    set(get(h_colorbar,'YLabel'),'String','Mean absolute error (rows)');
    testname = param.layer_tracker.layer_params.layerdata_source;
    img_fn = fullfile(img_dir,sprintf('%03d_%s_%s_%s.%s',layer_idx,testname,labelNameX,labelNameY,img_format));
    ct_saveas(h_fig(1),img_fn);
    
  end
end

% if param.layer_tracker.track{1}.flag == 1  
%   for layer_idx = 1:num_layers
%     res_mat = matrix_fn.res_matrix_mean{layer_idx};
%     points = matrix_fn.points_mean{layer_idx};
%     
%     A = nchoosek(1:length(param.layer_tracker.track{1}.idx_reshape),2);
%     for id = 1:length(A)
%       min_points = setdiff(1:length(param.layer_tracker.track{1}.idx_reshape),A(id,:));
%       min_idxs = points(min_points);
%       res_matrix = permute(res_mat,[A(id,:) setdiff(1:length(param.layer_tracker.track{1}.idx_reshape),A(id,:))]);
%       res_matrix = res_matrix(:,:,min_idxs(:));
%       idx = A(id,:);
%       labelTickX = data{idx(1)}; % x tick label
%       labelTickY = data{idx(2)}; % y tick label
%       labelNameX = param.layer_tracker.track{1}.idx_dim_name{idx(1)}; % x label name
%       labelNameY = param.layer_tracker.track{1}.idx_dim_name{idx(2)}; % y label name
%       xTick = 1:length(labelTickX); % x tick
%       yTick = 1:length(labelTickY); % y tick
%       %% Generate Figure
%       h_fig(1) = figure('visible','off'); % figure is not displayed
%       imagesc(squeeze(res_matrix'));
%       hold on;
%       plot(points(idx(1)),points(idx(2)),'x','LineWidth',4,'MarkerSize',10,'Color','white');
%       
%       ylabel(labelNameY);
%       xlabel(labelNameX);
%       set(gca,'XTickLabel',labelTickX);
%       set(gca,'YTickLabel',labelTickY);
%       set(gca,'XTick',xTick);
%       set(gca,'YTick',yTick);
%       h_colorbar = colorbar(gca);
%       set(get(h_colorbar,'YLabel'),'String','Mean absolute error (rows)');
%       testname = param.layer_tracker.layer_params.layerdata_source;
%       testname = 'check';
%       img_fn = fullfile(img_dir,sprintf('%03d_%s_%s_%s.%s',layer_idx,testname,labelNameX,labelNameY,img_format));
%       ct_saveas(h_fig(1),img_fn);
%       
%     end
%   end
% end
end