function success = layer_tracker_generate_task(param)
params_all = [];
params_all{end+1} = param;

%% Setup general
% set the range and indicate the layers to track

options = param.options;

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
range = options.set_range; 
idx = 1;

gt_layer_params = param.gt_layer_params;

num_layers = length(gt_layer_params);
img_dir = param.fname;
for idx = 1:num_layers
  foo{idx} = [];
end
%% Implementation

season_idx = param.season_idx;
param_idx = param.param_idx;
for frm = param.cmd.frms
  season_vect_frm(end+1) = season_idx;
  segment_vect_frm(end+1) = param_idx;
  frame_vect_frm(end+1) = frm;
end

param_override = param.filename.param;
param = merge_structs(param,param_override);
total_length = 0;
layers = opsLoadLayers(param,gt_layer_params);
idx_matrix = [(1:length(param.layer_tracker.track{1}.idx_reshape))+1 1]; % used for resizing
for layer_names = 1:num_layers
  res_matrix_all{layer_names} = zeros([length(param.cmd.frms),param.layer_tracker.track{1}.idx_reshape]);
  res_mat_temp{layer_names} = cell([param.layer_tracker.track{1}.idx_reshape]);
end

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

for track_idx = 1:length(param.layer_tracker.track)
  range_percent_all_frms.(sprintf('%s', param.layer_tracker.track{track_idx}.name)) = 0;
  for frm_idx = 1:length(param.cmd.frms)
    range_percent.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm_idx)) = 0;
    prob_error.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm_idx)) = 0;
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
      fprintf('\n=====Loading layers tracker: %d %d %s=====\n',track_idx,frm,datestr(now));
      layers_new = opsLoadLayers(param,layer_params);
      fprintf('\n=====Loaded layers tracker: %d %d %s=====\n',track_idx,frm,datestr(now));
      
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
    h_fig(1) = figure('visible','off','Name',param.tmp_name);
    for fig_idx = 1:length(frame_error{layer_idx})
      hold on;
      plot(frame_error{layer_idx}{fig_idx},'.-','DisplayName',sprintf('layer%d',fig_idx));
      labelNameX = 'Frames';
      labelNameY = 'Absolute error (bins)';
      ylabel(labelNameY);
      xlabel(labelNameX);
      xlim = ([1 length(param.cmd.frms)]);
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
      h_fig(1) = figure('visible','off','Name',param.tmp_name);
      for hist_idx = 1:length(frame_error{layer_idx})
        hold on;
        y = range_per{layer_idx}{hist_idx}(segment_vect_frm == param_idx);
        plot(y,'.-','DisplayName',sprintf('layer%d',hist_idx));
        xlabel('Frames');
        ylabel('Percentage error');
        xlim = ([1 length(param.cmd.frms)]);
        title(sprintf('%s Layer: %d',param.day_seg,layer_idx),'Interpreter', 'none');
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
      h_fig(1) = figure('visible','off','Name',param.tmp_name);
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

if(options.absolute_error.plot)
  fprintf('\n=====Absolute error plots=====\n');
  if (options.absolute_error.multiple_plots)
    if(strcmpi(param.layer_tracker.track{1}.method,'viterbi'))
      for layer_idx = 1:num_layers
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
save_name = sprintf('%s/result.mat',img_dir);
params = param;
save(save_name,'res_matrix_all','frame_error','range_per','percent_error','season_vect','res_matrix','points','min_val','gps_time','params','idx_matrix','-v7.3');


success = true;


