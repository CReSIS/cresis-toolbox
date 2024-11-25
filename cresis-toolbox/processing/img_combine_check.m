function mdata = img_combine_check(data_fns, rlines)
% mdata = img_combine_check(data_fns, rlines)
%
% Function for checking the gains of different images including those
% formed with img_combine. Note that this function automatically searches
% for all images for each data filename passed in. In other words, specify
% only one filename per set of files that only differ by "img_II_" in the
% file path.
%
% % The following loads Data_20160413_17_005, Data_img_01_20160413_17_005,
% Data_img_02_20160413_17_005, Data_img_03_20160413_17_005:
% mdata = img_combine_check('/cresis/snfs1/dataproducts/ct_data/rds/2016_Greenland_Polar6/CSARP_qlook/20160413_17/Data_20160413_17_005');
%
% % The following compares different processing types:
% mdata = img_combine_check({'/N/dcwan/projects/cresis/output/snow/2017_Greenland_P3/CSARP_deconv/20170309_01/Data_20170309_01_158.mat', ...
%   '/N/dcwan/projects/cresis/output/snow/2017_Greenland_P3/CSARP_qlook/20170309_01/Data_20170309_01_158.mat', ...
%   '/N/dcwan/projects/cresis/output/snow/2017_Greenland_P3/CSARP_qlook_uwb/20170309_01/Data_20170309_01_158.mat', ...
%   '/N/dcwan/projects/cresis/output/snow/2017_Greenland_P3/CSARP_qlook_kuband/20170309_01/Data_20170309_01_158.mat'},372);
%
% Author: John Paden
%
% See also: check_data_products.m, img_combine_check.m,
%   run_check_data_products.m

%% Setup
close all;

if ~exist('rlines','var')
  rlines = 1;
end

if ~iscell(data_fns)
  data_fns = {data_fns};
end

h_plot_fig = figure; clf(h_plot_fig);
h_plot_axes = axes('parent',h_plot_fig);
legend_str = {};
clear h_axes;

%% Load files
for file_idx = 1:numel(data_fns)
  data_fn = data_fns{file_idx};
  
  [data_fn_dir,data_fn_name] = fileparts(data_fn);
  
  clear mdata;
  mdata{1} = load_L1B(data_fn);
  
  %% Image of the file passed in
  h_fig = figure; clf(h_fig);
  h_axes(file_idx) = axes('parent',h_fig);
  imagesc([], mdata{1}.Time*1e6, lp(mdata{1}.Data), 'Parent', h_axes(file_idx));
  xlabel(h_axes(file_idx), 'Range line');
  ylabel(h_axes(file_idx), 'Time (us)');
  h_colorbar = colorbar(h_axes(file_idx));
  set(get(h_colorbar,'ylabel'),'String','Relative power (dB)');
  grid(h_axes(file_idx),'on');
  if file_idx == 1
    clims = caxis;
  else
    caxis(clims);
  end
  
  %% Plot A-scope for all associated image files (img_II and combined)
  done = false; img = 1;
  while ~done
    if data_fn_name(6) == 'i'
      data_img_fn = data_fn_name;
      data_img_fn(10:11) = sprintf('%02d', img);
      data_img_fn = fullfile(data_fn_dir,[data_img_fn '.mat']);
    else
      data_img_fn = fullfile(data_fn_dir,[data_fn_name(1:5) sprintf('img_%02d_', img) data_fn_name(6:end) '.mat']);
    end
    if exist(data_img_fn,'file')
      mdata{img+1} = load_L1B(data_img_fn);
      img = img + 1;
    else
      done = true;
    end
  end
  
  for rline = rlines(:).'
    for img = 1:length(mdata)
      h_plot = plot(h_plot_axes,mdata{img}.Time*1e6, lp(mdata{img}.Data(:,rline)));
      hold(h_plot_axes,'on');
      if img == 1
        if numel(data_fns) == 1
          legend_str{end+1} = sprintf('Combined');
        else
          legend_str{end+1} = sprintf('%d: Combined', file_idx);
        end
        set(h_plot,'LineWidth',2);
      else
        if numel(data_fns) == 1
          legend_str{end+1} = sprintf('Img %d', img-1);
        else
          legend_str{end+1} = sprintf('%d: Img %d', file_idx, img-1);
        end
      end
    end
  end
end

xlabel(h_plot_axes,'Time (us)');
ylabel(h_plot_axes,'Relative power (dB)');
grid(h_plot_axes,'on');
legend(h_plot_axes,legend_str);

linkaxes(h_axes);
