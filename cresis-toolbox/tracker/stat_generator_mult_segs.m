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
num_layers = 1;
fprintf('\n=====All segements=====\n');
  ff{1} = load('/cresis/snfs1/scratch/anjali/cluster_tuning/vit_fig1/result_layer_tune_lsm_s1');
  ff{2} = load('/cresis/snfs1/scratch/anjali/cluster_tuning/vit_fig1/result_layer_tune_lsm_s2');
  foo{1} = [];
  gps_time = [];
  season_vect = [];
  for hist_idx = 1:length(ff{1}.frame_error{layer_idx})
    range_per{1}{hist_idx} = [];
    res_matrix{1}{hist_idx} = [];
  end
  percent_error{layer_names} = zeros(1,(length(ff{1}.frame_error{layer_names})));
  
  for i = 1:length(ff)
    foo{layer_names} = [foo{layer_names};ff{i}.res_matrix_all{layer_names}];
    percent_error{layer_names} = percent_error{layer_names} + ff{i}.percent_error{layer_names};
    gps_time = cat(2,gps_time,ff{i}.gps_time);
    season_vect = cat(2,gps_time,ff{i}.gps_time);
    for hist_idx = 1:length(frame_error{layer_idx})
      range_per{1}{hist_idx} = cat(2,range_per{1}{hist_idx},ff{i}.range_per{1}{hist_idx});
      res_matrix{1}{hist_idx} = cat(2,res_matrix{1}{hist_idx},ff{i}.res_matrix{1}{hist_idx});
    end
  end
  
 
  
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
      h_fig(1) = figure;%('visible','off');
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
      %ct_saveas(h_fig(1),img_fn);
    end
    
    for layer_idx = 1:length(gt_layer_params)
      h_fig(1) = figure;%('visible','off');
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
      %ct_saveas(h_fig(1),img_fn);
    end
    %end
  end
  
  if (options.hist_generation.plot)
    fprintf('\n=====Hist generation all plots=====\n');
    %if (~options.hist_generation.multiple_plots)
    for layer_idx = 1:length(gt_layer_params)
      h_fig(1) = figure;%('visible','off');
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
     % ct_saveas(h_fig(1),img_fn);
    end
    %end
  end
  
  
  if(options.season_vs_gps.plot)
    fprintf('\n=====season plots=====\n');
    if(options.season_vs_gps.multiple_figs)
      for layer_idx = 1:length(gt_layer_params)
        for track_idx = 1:length(frame_error{layer_idx})
          h_fig(1) = figure;%('visible','off');
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
          %ct_saveas(h_fig(1),img_fn);
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