function success = layer_tracker_generate_combine_task(param)
%% Setup plots
options = param.options;
ff = {};
num_layers = 1;
for layer_idx = 1:num_layers
  for param_idx = 1
    ff{param_idx} = load(param.save_names{layer_idx,param_idx});
    param = merge_structs(param,ff{param_idx}.params);
  end
end

num_layers = length(param.gt_layer_params);
layer_names = num_layers;
img_dir = param.img_dir_combine;

for layer_idx = 1:num_layers
fprintf('\n=====All segements=====\n');
  foo{layer_idx} = [];
  gps_time = [];
  season_vect = [];
  for hist_idx = 1:length(ff{1}.frame_error{layer_idx})
    range_per{layer_idx}{hist_idx} = [];
    res_matrix{layer_idx}{hist_idx} = [];
  end
  percent_error{layer_idx} = zeros(1,(length(ff{1}.frame_error{layer_idx})));
  
  for i = 1:length(ff)
    foo{layer_idx} = [foo{layer_idx};ff{i}.res_matrix_all{layer_idx}];
    percent_error{layer_idx} = percent_error{layer_idx} + ff{i}.percent_error{layer_idx};
    gps_time = cat(2,gps_time,ff{i}.gps_time);
    season_vect = cat(2,gps_time,ff{i}.gps_time);
    for hist_idx = 1:length(ff{i}.frame_error{layer_idx})
      range_per{layer_idx}{hist_idx} = cat(2,range_per{layer_idx}{hist_idx},ff{i}.range_per{layer_idx}{hist_idx});
      res_matrix{layer_idx}{hist_idx} = cat(2,res_matrix{layer_idx}{hist_idx},ff{i}.res_matrix{layer_idx}{hist_idx});
    end
  end
  
 
  
  points = [];
  min_val = [];
  res_matrix_all_frms = [];
    res_matrix_all_frms{layer_idx} = nanmean(foo{layer_idx},1);
    res_matrix_all_frms{layer_idx} = permute(res_matrix_all_frms{layer_idx},ff{1}.idx_matrix);
    [min_val{layer_idx},i]=min(res_matrix_all_frms{layer_idx}(:));
    sizeMatrix = size(res_matrix_all_frms{layer_idx});
    for dim = 1:length(size(res_matrix_all_frms{layer_idx}))
      points{layer_idx}(dim) = mod(floor((i-1)/prod(sizeMatrix(1:dim-1))),sizeMatrix(dim))+1;
    end
    if (length(size(res_matrix_all_frms{layer_idx})) < length(param.layer_tracker.track{1}.idx_reshape))
      points{layer_idx}(dim+1) = 1;
    end
  
  if (options.percentage_correct.plot)
    fprintf('\n=====Percentage correct all plots=====\n');
   
      h_fig(1) = figure('visible','off','Name',param.tmp_name);
      for hist_idx = 1:length(ff{1}.frame_error{layer_idx})
        
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
    
     h_fig(1) = figure('visible','off','Name',param.tmp_name);
      plot(percent_error{layer_idx});
      hold on;
      plot(percent_error{layer_idx}, 'r*');
      ylabel('Percentage correct (%)');
      xlabel('Trackers');
      title(sprintf('Percentage correct vs trackers Layer:%d %s',layer_idx,param.season_name),'Interpreter', 'none');
      set(gca,'XTick',1:length(ff{1}.frame_error{layer_idx}));
      img_format = 'png';
      if(options.percentage_correct.fig_format)
        img_format = 'fig';
      end
      testname = param.layer_tracker.layer_params.layerdata_source;
      img_fn = fullfile(img_dir,sprintf('%s_%s_total_percent_correct_%03d.%s',testname,param.season_name,layer_idx,img_format));
      ct_saveas(h_fig(1),img_fn);

  end
  
  if (options.hist_generation.plot)
    fprintf('\n=====Hist generation all plots=====\n');
    
      h_fig(1) = figure('visible','off','Name',param.tmp_name);
      for hist_idx = 1:length(ff{1}.frame_error{layer_idx})
        hold on;
        [N,x] = hist(abs(res_matrix{layer_idx}{hist_idx}));
        plot(x,N,'DisplayName',sprintf('layer%d',hist_idx));
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
  
  
  if(options.season_vs_gps.plot)
    fprintf('\n=====season plots=====\n');
    if(options.season_vs_gps.multiple_figs)
        for track_idx = 1:length(ff{1}.frame_error{layer_idx})
          h_fig(1) = figure('visible','off','Name',param.tmp_name);
          plot(gps_time,abs(res_matrix{layer_idx}{track_idx}));
          ylabel('Absolute error (bins)');
          xlabel('GPS time');
          title(sprintf('%s Tracker: %d Layer: %d',param.season_name,track_idx,layer_idx),'Interpreter', 'none');
          
          img_format = 'png';
          if(options.season_vs_gps.fig_format)
            img_format = 'fig';
          end
          testname = param.layer_tracker.layer_params.layerdata_source;
          img_fn = fullfile(img_dir,sprintf('%s_%s_season_gps_%03d_%03d.%s',testname,param.season_name,track_idx,layer_idx,img_format));
          ct_saveas(h_fig(1),img_fn);
        end
    else
        h_fig(1) = figure('visible','off','Name',param.tmp_name);
        subplot_idx = 0;
        for track_idx = 1:length(ff{1}.frame_error{layer_idx})
          subplot_idx = subplot_idx + 1;
          
          if(subplot_idx < 6)
            subplot(3,2,subplot_idx)
            plot(gps_time,abs(res_matrix{layer_idx}{track_idx}));
            ylabel('Absolute error (bins)');
            xlabel('GPS time');
            title(sprintf('%s Tracker: %d Layer: %d',param.season_name, track_idx, layer_idx),'Interpreter', 'none');
          else
            subplot(3,2,subplot_idx)
            plot(gps_time,abs(res_matrix{layer_idx}{track_idx}));
            ylabel('Absolute error (bins)');
            xlabel('GPS time');
            title(sprintf('%s Tracker: %d Layer: %d',param.season_name, track_idx, layer_idx),'Interpreter', 'none');
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
  
  
  if(options.absolute_error.plot)
    fprintf('\n=====Absolute error all plots=====\n');
    if(strcmpi(param.layer_tracker.track{1}.method,'viterbi'))
        res_mat = res_matrix_all_frms{layer_idx};
        points_new = points{layer_idx};
        x = 1:length(res_mat); % x tick
        h_fig(1) = figure('visible','off','Name',param.tmp_name);
        plot(x,res_mat);
        hold on;
        for i = 1:length(res_mat)
          plot(x(i),res_mat(i), 'r*');
        end
        plot(x(points_new(1)),res_mat(points_new(1)), 'ko','LineWidth',4);
        set(gca,'XTick',x);
        ylabel('Mean absolute error (bins)');
        xlabel('Trackers');
        title(sprintf('%s',param.season_name),'Interpreter', 'none');
      img_format = 'png';
      if(options.absolute_error.fig_format)
        img_format = 'fig';
      end
      testname = param.layer_tracker.layer_params.layerdata_source;
      img_fn = fullfile(img_dir,sprintf('%03d_%s_%s_absolute_error.%s',2,testname,param.season_name,img_format));
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
success = true;
end

