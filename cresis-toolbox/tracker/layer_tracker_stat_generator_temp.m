%% Script layer_tracker_tune_layerdata.m
% % sign and percentage correct plot_best_segment_overall/segment % correct
% and mean absolute error.
% /cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140313_08_20210211_201501_t006_lsm.mat
% /cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20210211_201509_t006_lsm.mat
% Tuning script to work with layerdata files rather than temporary files
% Used to find best combination of paramters for given tracker method
% Enter layer names in the gt_layer_params(idx).name field
% set temp to the file location of the param structure used for tracking in run_layer_tracker.m script
% set save_name to store final tuning results
% Statistical data saved:
%   number of points with finite values of ground truth of twtt (num_gt_infinite),
%   number of points where ground truth twtt is finite and tracked data twtt is NaN (num_isnan)
%   number of points where (tracked data twtt - ground truth twtt) < 5 * dt (num_points)
%   nanmean of (tracked data twtt - ground truth twtt) (res_matrix)
% Authors: Anjali Pare, John Paden
% See layer_tracker_tune_plot.m to view 2 dimensional imagesc plots of the data.

% Look at % correct. If we're close to the right ans 100 % of the time but
% not quite right 100 % of the time is worse than being right 90% of the
% time and completely wrong 10 % of the time. Need to correct in quality
% control. Check if you are outside of a wondow and label as bad. % correct
% should be exactly the same (not necesary). There could be offsets.
% 1-2 range bin.

% Have fig option for all. Use hist instead of histogram. Histogram plots
% separate from % correct graphs. Enable option to generate best histogram
% plot. Plot as regular line using hist

% What to plot, finding best combination, trying with LSM
clear;
dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s (%s)\n', dbstack_info(1).name, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

%% Setup param
%20140516_01_20210107_163106_t005_viterbi
%20140313_08_20210107_162824_t005_viterbi
%temp = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20201122_193803_t005_viterbi.mat');

% Example to run 1 season with 1 segment all frames
params_all = [];
idx_segment = 1;
params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140421_01');%'20140313_09|20140415_05|20140421_01|20140514_01');
params(idx_segment).cmd.generic = 1;
params(idx_segment).cmd.frms = [];
% idx_segment = idx_segment + 1;
% params(idx_segment).cmd.generic = 1;
% params(idx_segment).cmd.frms = [];
% idx_segment = idx_segment + 1;
% params(idx_segment).cmd.generic = 1;
% params(idx_segment).cmd.frms = [];
% idx_segment = idx_segment + 1;
% params(idx_segment).cmd.generic = 1;
% params(idx_segment).cmd.frms = [];
params_all{end+1} = params;

% Example to run 1 season with 2 segment and different frames
% params_all = [];
% idx_segment = 1;
% params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140313_08|20140516_01');
% params(idx_segment).cmd.generic = 1;
% params(idx_segment).cmd.frms = 1:2;
% idx_segment = idx_segment + 1;
% params(idx_segment).cmd.generic = 1;
% params(idx_segment).cmd.frms = 3:4;
% params_all{end+1} = params;

% Example to run 2 season with 1 segment frames 1:5
% params_all = [];
% idx_segment = 1;
% params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140516_01');
% params(idx_segment).cmd.generic = 1;
% params(idx_segment).cmd.frms = 1:5;
% params_all{end+1} = params;

% idx_segment = 1;
% params = read_param_xls(ct_filename_param('rds_param_2014_Antarctica_DC8.xls'),'20141122_08');
% idx_segment = idx_segment + 1;
% params(idx_segment).cmd.generic = 1;
% params(idx_segment).cmd.frms = 1:5;
% params_all{end+1} = params;


% Example to run all segments and all frames of a season
% params_all = [];
% idx_segment = 1;
% params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'));
% params = ct_set_params(params,'cmd.generic',1);
% params(idx_segment).cmd.frms = [];

%% Setup filename
filename = [];
% one segment
%%filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20201202_020912_t005_viterbi.mat');
% filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20210124_024502_t004_lsm.mat');
%filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20200921_121933_t063_lsm.mat');
%filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20210204_195538_t006_lsm.mat');


% filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140313_08_20210211_201501_t006_lsm.mat');
% filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20210211_201509_t006_lsm.mat');

 %filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140313_08_20210304_221148_t005_viterbi.mat');
 %filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20210315_220253_t005_viterbi.mat');
%filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140313_09_20210311_013103_t056_lsm.mat');
%filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140415_05_20210311_013232_t056_lsm.mat');
filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140421_01_20210311_014435_t056_lsm.mat');
%filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140514_01_20210311_015110_t056_lsm.mat');
 % two segments
%filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140313_08_20210107_162824_t005_viterbi.mat');
%filename{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20210107_163106_t005_viterbi.mat');

%% Setup plots
% set fig_format to true to generate .fig plots
options.segment_vs_frame.plot = true; % absolute error vs frames (for each segment)
options.segment_vs_frame.fig_format = true;
options.season_vs_gps.plot = true; % absolute error vs gps time (for entire season)
options.season_vs_gps.fig_format = true;
options.season_vs_gps.multiple_figs = true; % choose this option if you separate plots generated for each layer. If set to false, 6 subplots will be plotted in one figure.
options.absolute_error.plot = true; % mean absolute error plots
options.absolute_error.fig_format = true;
options.absolute_error.multiple_plots = true;
options.percentage_correct.plot = true; % plot of percentage correct vs frames (for each segment)
options.percentage_correct.fig_format = true;
options.percentage_correct.multiple_plots = true;
options.hist_generation.plot = true; % histograms of data points vs absolute error
options.hist_generation.fig_format = true;
options.hist_generation.multiple_plots = true;

%% Setup save
% Enter filename of where you want to store the images
img_dir = '/cresis/snfs1/scratch/anjali/cluster_tuning/lsm_test';
if ~exist(img_dir,'dir')
  mkdir(img_dir);
end

%% Setup general
% set the range and indicate the layers to track

gt_layer_params = [];
layer_params = [];
res_matrix = [];
res_list = [];
gps_time = [];
season_vect = [];
segment_vect = [];
frame_vect  = [];
seg_idx = 0;
season_vect_frm = [];
segment_vect_frm = [];
frame_vect_frm  = [];
range = 100; % set acceptable range for error
idx = 1;

% If only bottom
 %gt_layer_params(idx).name = 'bottom'; % specify layer names

% If surface and bottom
foo{idx} = [];
gt_layer_params(idx).name = 'surface';
idx = idx + 1;
foo{idx} = [];
gt_layer_params(idx).name = 'bottom'; % specify layer names

num_layers = idx;

%% Implementation

for season_idx = 1:length(params_all) %seasons
  params = params_all{season_idx};
  for param_idx = 1:length(params) % segments
    param = params(param_idx);
    for frm = param.cmd.frms
      season_vect_frm(end+1) = season_idx;
      segment_vect_frm(end+1) = param_idx;
      frame_vect_frm(end+1) = frm;
    end
  end
end

for season_idx = 1:length(params_all) %seasons
  params = params_all{season_idx};
  for param_idx = 1:length(params) % segments
    param = params(param_idx);
    
    if isfield(param.cmd,'generic') && ~iscell(param.cmd.generic) && ~ischar(param.cmd.generic) && param.cmd.generic
      seg_idx = seg_idx + 1;
      param_override = filename{seg_idx}.param;
      param = merge_structs(param,param_override);
      total_length = 0;
      layers = opsLoadLayers(param,gt_layer_params);
      idx_matrix = [(1:length(param.layer_tracker.track{1}.idx_reshape))+1 1]; % used for resizing
      for layer_names = 1:idx
        res_matrix_all{layer_names} = zeros([length(param.cmd.frms),param.layer_tracker.track{1}.idx_reshape]);
        res_mat_temp{layer_names} = cell([param.layer_tracker.track{1}.idx_reshape]);
      end
      
      if (param_idx == 1)
        for layer_idx = 1:length(gt_layer_params)
          if strcmpi(param.layer_tracker.track{1}.method,'lsm')
            percent_error{layer_idx} = zeros(1,(length(param.layer_tracker.track)*length(param.layer_tracker.track{1}.lsm.storeIter)));
            for iter_idx = 1:(length(param.layer_tracker.track)*length(param.layer_tracker.track{1}.lsm.storeIter))
              range_per{layer_idx}{iter_idx} = [];
            end
          elseif strcmpi(param.layer_tracker.track{1}.method,'viterbi')
            percent_error{layer_idx} = zeros(1,(length(param.layer_tracker.track)));
            for iter_idx = 1:(length(param.layer_tracker.track))
              range_per{layer_idx}{iter_idx} = [];
            end
          end
        end
      end
      %       for layer_idx = 1:length(gt_layer_params)
      %         percent_error{layer_idx} = zeros(1,(length(param.layer_tracker.track)*length(param.layer_tracker.track{1}.lsm.storeIter)));
      %       end
      
      for track_idx = 1:length(param.layer_tracker.track)
        range_percent_all_frms.(sprintf('%s', param.layer_tracker.track{track_idx}.name)) = 0;
        for frm_idx = 1:length(param.cmd.frms)
          range_percent.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm_idx)) = 0;
          prob_error.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm_idx)) = 0;
          %frame_error{track_idx}(frm_idx) = 0;
        end
      end
      frm_idx = 0;
      for frm = param.cmd.frms
        frm_idx = frm_idx+1;
        data_fn_dir = ct_filename_out(param, param.layer_tracker.echogram_source, '');
        data_fn_name = sprintf('Data_%s_%03d.mat',param.day_seg,frm);
        data_fn      = fullfile(data_fn_dir, data_fn_name);
        data = load(data_fn, 'GPS_time', 'Time');
        gps_time = cat(2,gps_time,data.GPS_time);
        dt = data.Time(2) - data.Time(1);
        total_length = total_length + length(data.GPS_time);
        idx_list = 1;
        
        frm_length = length(data.GPS_time);
        for j = 1:length(data.GPS_time)
          season_vect(end+1) = season_idx;
          segment_vect(end+1) = param_idx;
          frame_vect(end+1) = frm;
        end
        
        for track_idx = 1:length(param.layer_tracker.track)
          
          for layer_idx = 1:length(gt_layer_params)
            if strcmpi(param.layer_tracker.track{1}.method,'lsm')
              for idx = 1:length(param.layer_tracker.track{track_idx}.lsm.storeIter)
                layer_params(idx).name = sprintf('%s_%s_%s_%03d',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method,gt_layer_params(layer_idx).name,idx);
                layer_params(idx).source = param.layer_tracker.layer_params.source;
                layer_params(idx).layerdata_source = param.layer_tracker.layer_params.layerdata_source;
              end
            else
              layer_params(1).name = sprintf('%s_%s_%s',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method,gt_layer_params(layer_idx).name);
              layer_params(1).source = param.layer_tracker.layer_params.source;
              layer_params(1).layerdata_source = param.layer_tracker.layer_params.layerdata_source;
            end
            ids = 1;
            sprintf('\n=====Loading layers tracker: %d=====\n',track_idx);
            layers_new = opsLoadLayers(param,layer_params);
            sprintf('\n=====Loaded layers tracker: %d=====\n',track_idx);
            
            surf = interp1(layers(layer_idx).gps_time,layers(layer_idx).twtt,data.GPS_time);
            surf_bins = round(interp1(data.Time,1:length(data.Time),surf));
            
            for pos = 1:length(layers_new)
              surf = interp1(layers_new(pos).gps_time,layers_new(pos).twtt,data.GPS_time);
              surf_bins_itr = round(interp1(data.Time,1:length(data.Time),surf));
              res_matrix_all{layer_idx}(frm_idx,param.layer_tracker.track{track_idx}.idx(pos)) = nanmean(abs(surf_bins - surf_bins_itr));
              counter = 0;
              for i = 1:length(surf_bins)
                try
                  res_matrix{layer_idx}{param.layer_tracker.track{track_idx}.idx(pos)}(end+1) = surf_bins(i) - surf_bins_itr(i);
                  res_mat_temp{layer_idx}{param.layer_tracker.track{track_idx}.idx(pos)}(end+1) = surf_bins(i) - surf_bins_itr(i);
                catch ME
                  res_matrix{layer_idx}{param.layer_tracker.track{track_idx}.idx(pos)}(i) = surf_bins(i) - surf_bins_itr(i);
                  res_mat_temp{layer_idx}{param.layer_tracker.track{track_idx}.idx(pos)}(i) = surf_bins(i) - surf_bins_itr(i);
                end
                if (abs(surf_bins(i) - surf_bins_itr(i)) <= range)
                  counter = counter + 1;
                end
              end
              range_percent.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm)) = (counter/length(surf_bins))*100;
              range_per{layer_idx}{param.layer_tracker.track{track_idx}.idx(pos)}(end+1) = (counter/length(surf_bins))*100;
              percent_error{layer_idx}(param.layer_tracker.track{track_idx}.idx(pos)) = counter + percent_error{layer_idx}(param.layer_tracker.track{track_idx}.idx(pos));
              prob_error.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm)) = counter*100;
              frame_error{layer_idx}{param.layer_tracker.track{track_idx}.idx(pos)}(frm_idx) = nanmean(abs(surf_bins - surf_bins_itr));
              try
                range_percent_all_frms.(sprintf('%s', param.layer_tracker.track{track_idx}.name)) = range_percent_all_frms.(sprintf('%s', param.layer_tracker.track{track_idx}.name)) + counter;
              catch ME
                range_percent_all_frms.(sprintf('%s', param.layer_tracker.track{track_idx}.name)) = counter;
              end
            end
          end
          idx_list = idx_list + 1;
        end
      end
      
      
      points = [];
      min_val = [];
      res_matrix_all_frms = [];
      for layer_names = 1:num_layers
        res_matrix_all_frms{layer_names} = nanmean(res_matrix_all{layer_names},1);
        res_matrix_all_frms{layer_names} = permute(res_matrix_all_frms{layer_names},idx_matrix);
        [min_val{layer_names},i]=min(res_matrix_all_frms{layer_names}(:));
        sizeMatrix = size(res_matrix_all_frms{layer_names});
        for dim = 1:length(size(res_matrix_all_frms{layer_names}))
          points{layer_names}(dim) = mod(floor((i-1)/prod(sizeMatrix(1:dim-1))),sizeMatrix(dim))+1;
        end
        if (length(size(res_matrix_all_frms{layer_names})) < length(param.layer_tracker.track{1}.idx_reshape))
          points{layer_names}(dim+1) = 1;
        end
        if(param_idx==1)
          foo{layer_names} = res_matrix_all{layer_names};
        else
          foo{layer_names} = [foo{layer_names};res_matrix_all{layer_names}];
        end
      end
      
      % per segment vs frame
      if (options.segment_vs_frame.plot)
        fprintf('\n=====Segment frame plots=====\n');
        for layer_idx = 1:length(gt_layer_params)
          h_fig(1) = figure('visible','off');
          for fig_idx = 1:length(frame_error{layer_idx})
            hold on;
            %plot(frame_error{layer_idx}{fig_idx},'DisplayName',sprintf('tracker%d',fig_idx));
            %legend('-DynamicLegend','Location','northeastoutside');
            plot(frame_error{layer_idx}{fig_idx},'.-','DisplayName',sprintf('layer%d',fig_idx));
            labelNameX = 'Frames';
            labelNameY = 'Absolute error (bins)';
            ylabel(labelNameY);
            xlabel(labelNameX);
            xlim = ([1 length(param.cmd.frms)]);
            %             labelNameX = 'frames';
            %             labelNameY = 'absolute error';
            %             ylabel(labelNameY);
            %             xlabel(labelNameX);
            %             set(gca,'XTick',1:length(param.cmd.frms));
            %             set(gca,'XTickLabel',[param.cmd.frms])
            title(sprintf('%s Layer: %d',param.day_seg,layer_idx),'Interpreter', 'none');
          end
          
          hold off;
          img_format = 'png';
          if(options.segment_vs_frame.fig_format)
            img_format = 'fig';
          end
          testname = param.layer_tracker.layer_params.layerdata_source;
          img_fn = fullfile(img_dir,sprintf('%s_%s_segment_vs_frame_%03d.%s',testname,param.day_seg,layer_idx,img_format));
          ct_saveas(h_fig(1),img_fn);
        end
      end
      
      if (options.percentage_correct.plot)
          fprintf('\n=====Percentage plots=====\n');
        if (options.percentage_correct.multiple_plots)
          for layer_idx = 1:length(gt_layer_params)
            h_fig(1) = figure('visible','off');
            for hist_idx = 1:length(frame_error{layer_idx})
              %             hold on;
              %             plot(range_per{layer_idx}{hist_idx},'DisplayName',sprintf('tracker%d',hist_idx));
              %             legend('-DynamicLegend','Location','northeastoutside');
              %             xlabel('Number of frames');
              %             ylabel('Percentage error');
              %             set(gca,'XTick',1:length(param.cmd.frms));
              %             set(gca,'XTickLabel',[param.cmd.frms]);
              hold on;
              y = range_per{layer_idx}{hist_idx}(segment_vect_frm == param_idx);
              plot(y,'.-','DisplayName',sprintf('layer%d',hist_idx));
              xlabel('Frames');
              ylabel('Percentage error');
              xlim = ([1 length(param.cmd.frms)]);
              title(sprintf('%s Layer: %d',param.day_seg,layer_idx),'Interpreter', 'none');
              % percent_error{layer_idx}(hist_idx) = percent_error{layer_idx}(hist_idx)/length(season_vect) * 100;
            end
            img_format = 'png';
            if(options.percentage_correct.fig_format)
              img_format = 'fig';
            end
            testname = param.layer_tracker.layer_params.layerdata_source;
            img_fn = fullfile(img_dir,sprintf('%s_%s_percentage_correct_%03d.%s',testname,param.day_seg,layer_idx,img_format));
            ct_saveas(h_fig(1),img_fn);
          end
        end
      end
      
      if (options.hist_generation.plot)
        fprintf('\n=====Hist generation plots=====\n');
        if (options.hist_generation.multiple_plots)
          for layer_idx = 1:length(gt_layer_params)
            h_fig(1) = figure('visible','off');
            for hist_idx = 1:length(frame_error{layer_idx})
              hold on;
              plot_hist = abs(res_matrix{layer_idx}{hist_idx}(segment_vect == param_idx));
              [N,x] = hist(plot_hist);
              plot(x,N,'DisplayName',sprintf('layer%d',hist_idx));
              %legend('-DynamicLegend','Location','northeastoutside');
              ylabel('Data points');
              xlabel('Absolute error (bins)');
              title(sprintf('%s Layer: %d',param.day_seg,layer_idx),'Interpreter', 'none');
            end
            hold off;
            img_format = 'png';
            if(options.hist_generation.fig_format)
              img_format = 'fig';
            end
            testname = param.layer_tracker.layer_params.layerdata_source;
            img_fn = fullfile(img_dir,sprintf('%s_%s_histogram_generation_%03d.%s',testname,param.day_seg,layer_idx,img_format));
             ct_saveas(h_fig(1),img_fn);
          end
        end
      end
      
      %               for layer_idx = 1:length(gt_layer_params)
      %                 h_fig(1) = figure('visible','off');
      %                 plot(percent_error{layer_idx});
      %                 hold on;
      %                 plot(percent_error{layer_idx}, 'r*');
      %                 ylabel('Percentage correct');
      %                 xlabel('Trackers');
      %                 title(sprintf('%s frames: %d Layer: %d',param.day_seg,length(param.cmd.frms),layer_idx),'Interpreter', 'none');
      %                 set(gca,'XTick',1:length(frame_error{layer_idx}));
      %                 img_format = 'png';
      %                 if(options.percentage_correct.fig_format)
      %                   img_format = 'fig';
      %                 end
      %                 testname = param.layer_tracker.layer_params.layerdata_source;
      %                 img_fn = fullfile(img_dir,sprintf('%s_%s_total_percent_correct_%03d.%s',testname,param.day_seg,layer_idx,img_format));
      %                 ct_saveas(h_fig(1),img_fn);
      %               end
      
      if(options.absolute_error.plot)
        fprintf('\n=====Absolute error plots=====\n');
        if (options.absolute_error.multiple_plots)
          if(strcmpi(param.layer_tracker.track{1}.method,'viterbi'))
            for layer_idx = 1:num_layers
              res_mat = res_matrix_all_frms{layer_idx};
              points_new = points{layer_idx};
              x = 1:length(res_mat); % x tick
              h_fig(1) = figure('visible','off');
              plot(x,res_mat);
              hold on;
              for i = 1:length(res_mat)
                plot(x(i),res_mat(i), 'r*');
              end
              plot(x(points_new(1)),res_mat(points_new(1)), 'ko','LineWidth',4);
              set(gca,'XTick',x);
              ylabel('Mean absolute error (bins)');
              xlabel('Trackers');
              title(sprintf('%s frames: %03d',param.day_seg,length(param.cmd.frms)),'Interpreter', 'none');
            end
            img_format = 'png';
            if(options.absolute_error.fig_format)
              img_format = 'fig';
            end
            testname = param.layer_tracker.layer_params.layerdata_source;
            img_fn = fullfile(img_dir,sprintf('%03d_%s_%s_absolute_error.%s',2,testname,param.day_seg,img_format));
            ct_saveas(h_fig(1),img_fn);
            
          elseif(strcmpi(param.layer_tracker.track{1}.method,'lsm'))
            data = [];
            for dim = 1:length(param.layer_tracker.track{1}.idx_reshape)
              temp = [];
              for track_idx = 1:length(param.layer_tracker.track)
                if isempty(temp)
                  temp = param.layer_tracker.track{track_idx}.(param.layer_tracker.track{track_idx}.method).(param.layer_tracker.track{track_idx}.idx_dim_name{dim});
                else
                  if ~any(temp == param.layer_tracker.track{track_idx}.(param.layer_tracker.track{track_idx}.method).(param.layer_tracker.track{track_idx}.idx_dim_name{dim}))
                    temp(end+1) = param.layer_tracker.track{track_idx}.(param.layer_tracker.track{track_idx}.method).(param.layer_tracker.track{track_idx}.idx_dim_name{dim});
                  end
                end
                
              end
              data{dim}=temp;
            end
            for layer_idx = 1:num_layers
              res_mat = res_matrix_all_frms{layer_idx};
              temp_points = points{layer_idx};
              
              A = nchoosek(1:length(param.layer_tracker.track{1}.idx_reshape),2); % changed from 2
              for id = 1:length(A)
                min_points = setdiff(1:length(param.layer_tracker.track{1}.idx_reshape),A(id,:));
                min_idxs = temp_points(min_points);
                res_matrix_tot = permute(res_mat,[A(id,:) setdiff(1:length(param.layer_tracker.track{1}.idx_reshape),A(id,:))]);
                res_matrix_tot = res_matrix_tot(:,:,min_idxs(:));
                idx = A(id,:);
                labelTickX = data{idx(1)}; % x tick label
                labelTickY = data{idx(2)}; % y tick label
                labelNameX = param.layer_tracker.track{1}.idx_dim_name{idx(1)}; % x label name
                labelNameY = param.layer_tracker.track{1}.idx_dim_name{idx(2)}; % y label name
                xTick = 1:length(labelTickX); % x tick
                yTick = 1:length(labelTickY); % y tick
                %% Generate Figure
                h_fig(1) = figure('visible','off'); % figure is not displayed
                imagesc(squeeze(res_matrix_tot'));
                hold on;
                plot(temp_points(idx(1)),temp_points(idx(2)),'x','LineWidth',4,'MarkerSize',10,'Color','white');
                
                ylabel(labelNameY);
                xlabel(labelNameX);
                set(gca,'XTickLabel',labelTickX);
                set(gca,'YTickLabel',labelTickY);
                set(gca,'XTick',xTick);
                set(gca,'YTick',yTick);
                h_colorbar = colorbar(gca);
                set(get(h_colorbar,'YLabel'),'String','Mean absolute error (rows)');
                img_format ='jpg';
                if(options.absolute_error.fig_format)
                  img_format = 'fig';
                end
                testname = param.layer_tracker.layer_params.layerdata_source;
                img_fn = fullfile(img_dir,sprintf('%s_%s_absolute_error_%s_vs_%s_%03d.%s',testname,param.day_seg,labelNameX,labelNameY,layer_idx,img_format));
                ct_saveas(h_fig(1),img_fn);
                
              end
            end
          end
        end
        
        
      end
      
      %       if(options.season_vs_gps.plot)
      %         if(options.season_vs_gps.multiple_figs)
      %           for layer_idx = 1:length(gt_layer_params)
      %             for track_idx = 1:length(frame_error{layer_idx})
      %               h_fig(1) = figure;
      %               plot(gps_time,abs(res_matrix{layer_idx}{track_idx}));
      %               ylabel('Absolute error (bins)');
      %               xlabel('GPS time');
      %               title(sprintf('%s frames: %03d Tracker: %d Layer: %d',param.season_name,length(param.cmd.frms), track_idx, layer_idx),'Interpreter', 'none');
      %               %xlim([gps_time(1) gps_time(end)]);
      %
      %               img_format = 'png';
      %               if(options.season_vs_gps.fig_format)
      %                 img_format = 'fig';
      %               end
      %               testname = param.layer_tracker.layer_params.layerdata_source;
      %               img_fn = fullfile(img_dir,sprintf('%s_%s_season_gps_%03d_%03d.%s',testname,param.day_seg,track_idx,layer_idx,img_format));
      %               ct_saveas(h_fig(1),img_fn);
      %             end
      %           end
      %         else
      %           for layer_idx = 1:length(gt_layer_params)
      %             h_fig(1) = figure;
      %             subplot_idx = 0;
      %             for track_idx = 1:length(frame_error{layer_idx})
      %               subplot_idx = subplot_idx + 1;
      %               if(subplot_idx < 6)
      %                 subplot(3,2,subplot_idx)
      %                 plot(gps_time,abs(res_matrix{layer_idx}{track_idx}));
      %                 ylabel('Absolute error (bins)');
      %                 xlabel('GPS time');
      %                 title(sprintf('%s frames: %03d Tracker: %d Layer: %d',param.season_name,length(param.cmd.frms), track_idx, layer_idx),'Interpreter', 'none');
      %                 %xlim([gps_time(1) gps_time(end)]);
      %               else
      %                 subplot(3,2,subplot_idx)
      %                 plot(gps_time,abs(res_matrix{layer_idx}{track_idx}));
      %                 ylabel('Absolute error (bins)');
      %                 xlabel('GPS time');
      %                 title(sprintf('%s Tracker: %d Layer: %d',param.season_name, track_idx, layer_idx),'Interpreter', 'none');
      %                 %xlim([gps_time(1) gps_time(end)]);
      %                 img_format = 'png';
      %                 if(options.season_vs_gps.fig_format)
      %                   img_format = 'fig';
      %                 end
      %                 testname = param.layer_tracker.layer_params.layerdata_source;
      %                 img_fn = fullfile(img_dir,sprintf('%s_%s_season_gps_%03d_%03d.%s',testname,param.day_seg,track_idx,layer_idx,img_format));
      %                 ct_saveas(h_fig(1),img_fn);
      %                 h_fig(1) = figure;
      %                 subplot_idx = 0;
      %               end
      %
      %             end
      %           end
      %         end
      %
      %       end
      
      save_name = sprintf('/cresis/snfs1/scratch/anjali/cluster_tuning/lsm_test/result_layer_tune_lsm_s%d',param_idx);
      save(save_name,'res_matrix_all','frame_error','range_per','percent_error','season_vect','res_matrix','points','min_val','gps_time','param');
    end
  end
  fprintf('\n=====All segements=====\n');
  points = [];
  min_val = [];
  res_matrix_all_frms = [];
  for layer_names = 1:num_layers
    res_matrix_all_frms{layer_names} = nanmean(foo{layer_names},1);
    res_matrix_all_frms{layer_names} = permute(res_matrix_all_frms{layer_names},idx_matrix);
    [min_val{layer_names},i]=min(res_matrix_all_frms{layer_names}(:));
    sizeMatrix = size(res_matrix_all_frms{layer_names});
    for dim = 1:length(size(res_matrix_all_frms{layer_names}))
      points{layer_names}(dim) = mod(floor((i-1)/prod(sizeMatrix(1:dim-1))),sizeMatrix(dim))+1;
    end
    if (length(size(res_matrix_all_frms{layer_names})) < length(param.layer_tracker.track{1}.idx_reshape))
      points{layer_names}(dim+1) = 1;
    end
  end
  
  if (options.percentage_correct.plot)
    fprintf('\n=====Percentage correct all plots=====\n');
    %if (~options.percentage_correct.multiple_plots)
    for layer_idx = 1:length(gt_layer_params)
      h_fig(1) = figure('visible','off');
      for hist_idx = 1:length(frame_error{layer_idx})
        %             hold on;
        %             plot(range_per{layer_idx}{hist_idx},'DisplayName',sprintf('tracker%d',hist_idx));
        %             legend('-DynamicLegend','Location','northeastoutside');
        %             xlabel('Number of frames');
        %             ylabel('Percentage error');
        %             set(gca,'XTick',1:length(param.cmd.frms));
        %             set(gca,'XTickLabel',[param.cmd.frms]);
        hold on;
        plot(range_per{layer_idx}{hist_idx},'.-','DisplayName',sprintf('layer%d',hist_idx));
        xlabel('Frames');
        ylabel('Percentage correct (%)');
        xlim = ([1 length(param.cmd.frms)]);
        title(sprintf('Percentage correct vs frames Layer:%d %s',layer_idx,param.season_name),'Interpreter', 'none');
        percent_error{layer_idx}(hist_idx) = percent_error{layer_idx}(hist_idx)/length(season_vect) * 100;
      end
      img_format = 'png';
      if(options.percentage_correct.fig_format)
        img_format = 'fig';
      end
      testname = param.layer_tracker.layer_params.layerdata_source;
      img_fn = fullfile(img_dir,sprintf('%s_%s_percentage_correct_overall_%03d.%s',testname,param.season_name,layer_idx,img_format));
      ct_saveas(h_fig(1),img_fn);
    end
    
    for layer_idx = 1:length(gt_layer_params)
      h_fig(1) = figure('visible','off');
      plot(percent_error{layer_idx});
      hold on;
      plot(percent_error{layer_idx}, 'r*');
      ylabel('Percentage correct (%)');
      xlabel('Trackers');
      title(sprintf('Percentage correct vs trackers Layer:%d %s',layer_idx,param.season_name),'Interpreter', 'none');
      set(gca,'XTick',1:length(frame_error{layer_idx}));
      img_format = 'png';
      if(options.percentage_correct.fig_format)
        img_format = 'fig';
      end
      testname = param.layer_tracker.layer_params.layerdata_source;
      img_fn = fullfile(img_dir,sprintf('%s_%s_total_percent_correct_%03d.%s',testname,param.season_name,layer_idx,img_format));
      ct_saveas(h_fig(1),img_fn);
    end
    %end
  end
  
  if (options.hist_generation.plot)
    fprintf('\n=====Hist generation all plots=====\n');
    %if (~options.hist_generation.multiple_plots)
    for layer_idx = 1:length(gt_layer_params)
      h_fig(1) = figure('visible','off');
      for hist_idx = 1:length(frame_error{layer_idx})
        hold on;
        [N,x] = hist(abs(res_matrix{layer_idx}{hist_idx}));
        plot(x,N,'DisplayName',sprintf('layer%d',hist_idx));
        %legend('-DynamicLegend','Location','northeastoutside');
        ylabel('Data points');
        xlabel('Absolute error (bins)');
        title(sprintf('Data points vs Absolute error Layer:%d %s',layer_idx,param.season_name),'Interpreter', 'none');
      end
      hold off;
      img_format = 'png';
      if(options.hist_generation.fig_format)
        img_format = 'fig';
      end
      testname = param.layer_tracker.layer_params.layerdata_source;
      img_fn = fullfile(img_dir,sprintf('%s_%s_histogram_generation_overall_%03d.%s',testname,param.season_name,layer_idx,img_format));
      ct_saveas(h_fig(1),img_fn);
    end
    %end
  end
  
  
  if(options.season_vs_gps.plot)
    fprintf('\n=====season plots=====\n');
    if(options.season_vs_gps.multiple_figs)
      for layer_idx = 1:length(gt_layer_params)
        for track_idx = 1:length(frame_error{layer_idx})
          h_fig(1) = figure('visible','off');
          plot(gps_time,abs(res_matrix{layer_idx}{track_idx}));
          ylabel('Absolute error (bins)');
          xlabel('GPS time');
          title(sprintf('%s frames: %03d Tracker: %d Layer: %d',param.season_name,length(param.cmd.frms), track_idx, layer_idx),'Interpreter', 'none');
          %xlim([gps_time(1) gps_time(end)]);
          
          img_format = 'png';
          if(options.season_vs_gps.fig_format)
            img_format = 'fig';
          end
          testname = param.layer_tracker.layer_params.layerdata_source;
          img_fn = fullfile(img_dir,sprintf('%s_%s_season_gps_%03d_%03d.%s',testname,param.season_name,track_idx,layer_idx,img_format));
          ct_saveas(h_fig(1),img_fn);
        end
      end
    else
      for layer_idx = 1:length(gt_layer_params)
        h_fig(1) = figure('visible','off');
        subplot_idx = 0;
        for track_idx = 1:length(frame_error{layer_idx})
          subplot_idx = subplot_idx + 1;
          
          if(subplot_idx < 6)
            subplot(3,2,subplot_idx)
            plot(gps_time,abs(res_matrix{layer_idx}{track_idx}));
            ylabel('Absolute error (bins)');
            xlabel('GPS time');
            title(sprintf('%s frames: %03d Tracker: %d Layer: %d',param.season_name,length(param.cmd.frms), track_idx, layer_idx),'Interpreter', 'none');
            %xlim([gps_time(1) gps_time(end)]);
          else
            subplot(3,2,subplot_idx)
            plot(gps_time,abs(res_matrix{layer_idx}{track_idx}));
            ylabel('Absolute error (bins)');
            xlabel('GPS time');
            title(sprintf('%s Tracker: %d Layer: %d',param.season_name, track_idx, layer_idx),'Interpreter', 'none');
            %xlim([gps_time(1) gps_time(end)]);
            img_format = 'png';
            if(options.season_vs_gps.fig_format)
              img_format = 'fig';
            end
            testname = param.layer_tracker.layer_params.layerdata_source;
            img_fn = fullfile(img_dir,sprintf('%s_%s_season_gps_%03d_%03d.%s',testname,param.season_name,track_idx,layer_idx,img_format));
            ct_saveas(h_fig(1),img_fn);
            h_fig(1) = figure('visible','off');
            subplot_idx = 0;
          end
        end
      end
    end
    
  end
  
  if(options.absolute_error.plot)
    fprintf('\n=====Absolute error all plots=====\n');
    if(strcmpi(param.layer_tracker.track{1}.method,'viterbi'))
      for layer_idx = 1:num_layers
        res_mat = res_matrix_all_frms{layer_idx};
        points_new = points{layer_idx};
        x = 1:length(res_mat); % x tick
        h_fig(1) = figure('visible','off');
        plot(x,res_mat);
        hold on;
        for i = 1:length(res_mat)
          plot(x(i),res_mat(i), 'r*');
        end
        plot(x(points_new(1)),res_mat(points_new(1)), 'ko','LineWidth',4);
        set(gca,'XTick',x);
        ylabel('Mean absolute error (bins)');
        xlabel('Trackers');
        title(sprintf('%s frames: %03d',param.day_seg,length(param.cmd.frms)),'Interpreter', 'none');
      end
      img_format = 'png';
      if(options.absolute_error.fig_format)
        img_format = 'fig';
      end
      testname = param.layer_tracker.layer_params.layerdata_source;
      img_fn = fullfile(img_dir,sprintf('%03d_%s_%s_absolute_error.%s',2,testname,param.day_seg,img_format));
      ct_saveas(h_fig(1),img_fn);
      
    elseif(strcmpi(param.layer_tracker.track{1}.method,'lsm'))
      data = [];
      for dim = 1:length(param.layer_tracker.track{1}.idx_reshape)
        temp = [];
        for track_idx = 1:length(param.layer_tracker.track)
          if isempty(temp)
            temp = param.layer_tracker.track{track_idx}.(param.layer_tracker.track{track_idx}.method).(param.layer_tracker.track{track_idx}.idx_dim_name{dim});
          else
            if ~any(temp == param.layer_tracker.track{track_idx}.(param.layer_tracker.track{track_idx}.method).(param.layer_tracker.track{track_idx}.idx_dim_name{dim}))
              temp(end+1) = param.layer_tracker.track{track_idx}.(param.layer_tracker.track{track_idx}.method).(param.layer_tracker.track{track_idx}.idx_dim_name{dim});
            end
          end
          
        end
        data{dim}=temp;
      end
      for layer_idx = 1:num_layers
        res_mat = res_matrix_all_frms{layer_idx};
        temp_points = points{layer_idx};
        
        A = nchoosek(1:length(param.layer_tracker.track{1}.idx_reshape),2); % changed from 2
        for id = 1:length(A)
          min_points = setdiff(1:length(param.layer_tracker.track{1}.idx_reshape),A(id,:));
          min_idxs = temp_points(min_points);
          res_matrix_tot = permute(res_mat,[A(id,:) setdiff(1:length(param.layer_tracker.track{1}.idx_reshape),A(id,:))]);
          res_matrix_tot = res_matrix_tot(:,:,min_idxs(:));
          idx = A(id,:);
          labelTickX = data{idx(1)}; % x tick label
          labelTickY = data{idx(2)}; % y tick label
          labelNameX = param.layer_tracker.track{1}.idx_dim_name{idx(1)}; % x label name
          labelNameY = param.layer_tracker.track{1}.idx_dim_name{idx(2)}; % y label name
          xTick = 1:length(labelTickX); % x tick
          yTick = 1:length(labelTickY); % y tick
          %% Generate Figure
          h_fig(1) = figure('visible','off'); % figure is not displayed
          imagesc(squeeze(res_matrix_tot'));
          hold on;
          plot(temp_points(idx(1)),temp_points(idx(2)),'x','LineWidth',4,'MarkerSize',10,'Color','white');
          
          ylabel(labelNameY);
          xlabel(labelNameX);
          set(gca,'XTickLabel',labelTickX);
          set(gca,'YTickLabel',labelTickY);
          set(gca,'XTick',xTick);
          set(gca,'YTick',yTick);
          h_colorbar = colorbar(gca);
          set(get(h_colorbar,'YLabel'),'String','Mean absolute error (rows)');
          img_format ='jpg';
          if(options.absolute_error.fig_format)
            img_format = 'fig';
          end
          testname = param.layer_tracker.layer_params.layerdata_source;
          img_fn = fullfile(img_dir,sprintf('%s_%s_absolute_error_%s_vs_%s_%03d.%s',testname,param.season_name,labelNameX,labelNameY,layer_idx,img_format));
          ct_saveas(h_fig(1),img_fn);
          
        end
      end
    end
    
    
  end
  
end

keyboard;
%
% %% Find Best Combination
% for layer_names = 1:idx
%   res_matrix{layer_names} = zeros([length(param.cmd.frms),param.layer_tracker.track{1}.idx_reshape]);
%   num_gt_isfinite.(sprintf('%s',gt_layer_params(layer_names).name)) = 0;
%   num_isnan.(sprintf('%s',gt_layer_params(layer_names).name)) = 0;
%   num_points.(sprintf('%s',gt_layer_params(layer_names).name)) = 0;
%   num_layers = num_layers+1;
% end
%
%
% idx_matrix = [(1:length(param.layer_tracker.track{1}.idx_reshape))+1 1]; % used for resizing
%
% for track_idx = 1:length(param.layer_tracker.track)
%   frm_idx = 0;
%   for frm = param.cmd.frms
%     frm_idx = frm_idx+1;
%     data_fn_dir = ct_filename_out(param, param.layer_tracker.echogram_source, '');
%     data_fn_name = sprintf('Data_%s_%03d.mat',param.day_seg,frm);
%     data_fn      = fullfile(data_fn_dir, data_fn_name);
%     data = load(data_fn);
%     dt = data.Time(2) - data.Time(1);
%     for layer_idx = 1:length(gt_layer_params)
%
%       layer_params(1).name = sprintf('%s_%s_%s',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method,gt_layer_params(layer_idx).name);
%       layer_params(1).source = param.layer_tracker.layer_params.source;
%       layer_params(1).layerdata_source = param.layer_tracker.layer_params.layerdata_source;
%       layers_new = opsLoadLayers(param,layer_params);
%
%       surf = interp1(layers(layer_idx).gps_time,layers(layer_idx).twtt,data.GPS_time);
%       surf_bins = round(interp1(data.Time,1:length(data.Time),surf));
%
%       for pos = 1:length(layers_new)
%         surf = interp1(layers_new(pos).gps_time,layers_new(pos).twtt,data.GPS_time);
%         surf_bins_itr = round(interp1(data.Time,1:length(data.Time),surf));
%         num_gt_isfinite.(sprintf('%s',gt_layer_params(layer_idx).name)) = num_gt_isfinite.(sprintf('%s',gt_layer_params(layer_idx).name)) + sum(isfinite(surf_bins));
%         num_isnan.(sprintf('%s',gt_layer_params(layer_idx).name)) = num_isnan.(sprintf('%s',gt_layer_params(layer_idx).name)) + (sum(isfinite(surf_bins) & ~isfinite(surf_bins_itr)));
%         num_points.(sprintf('%s',gt_layer_params(layer_idx).name)) = num_points.(sprintf('%s',gt_layer_params(layer_idx).name)) + (sum(abs(surf_bins-surf_bins_itr) < 5*dt));
%         res_matrix{layer_idx}(frm_idx,param.layer_tracker.track{track_idx}.idx(pos)) = nanmean(abs(surf_bins - surf_bins_itr));
%         counter = 0;
%         for i = 1:length(surf_bins)
%           if (abs(surf_bins(i) - surf_bins_itr(i)) <= range)
%             counter = counter + 1;
%           end
%         end
%         range_percent.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm))= (counter/length(surf_bins))*100;
%       end
%     end
%   end
%   counter = 0;
%   for i = 1:length(param.cmd.frms)
%     counter = counter + range_percent.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm));
%   end
%   range_percent_all_frms.(sprintf('%s', param.layer_tracker.track{track_idx}.name)) = counter/length(param.cmd.frms);
% end
%
% points = [];
% min_val = [];
% res_matrix_all_frms = [];
% for layer_names = 1:num_layers
%   res_matrix_all_frms{layer_names} = nanmean(res_matrix{layer_names},1);
%   res_matrix_all_frms{layer_names} = permute(res_matrix_all_frms{layer_names},idx_matrix);
%   [min_val{layer_names},i]=min(res_matrix_all_frms{layer_names}(:));
%   sizeMatrix = size(res_matrix_all_frms{layer_names});
%   for dim = 1:length(size(res_matrix_all_frms{layer_names}))
%     points{layer_names}(dim) = mod(floor((i-1)/prod(sizeMatrix(1:dim-1))),sizeMatrix(dim))+1;
%   end
%   if (length(size(res_matrix_all_frms{layer_names})) < length(param.layer_tracker.track{1}.idx_reshape))
%     points{layer_names}(dim+1) = 1;
%   end
% end
%
% file_version = '1';
% file_type = 'layer_tracker_tuning';
%
% fn_dir = fileparts(save_name);
% if ~exist(fn_dir,'dir')
%   mkdir(fn_dir);
% end
%
% save(save_name,'res_matrix','range_percent','range_percent_all_frms','num_isnan','num_points','num_gt_isfinite','points','min_val','res_matrix_all_frms','param','file_version','file_type');
