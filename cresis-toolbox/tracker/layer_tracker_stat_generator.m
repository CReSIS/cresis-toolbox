%% Script layer_tracker_tune_layerdata.m

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

dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s (%s)\n', dbstack_info(1).name, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

img_dir = '/cresis/snfs1/scratch/anjali/cluster_tuning/stat_generator';
if ~exist(img_dir,'dir')
  mkdir(img_dir);
end
%% Setup
%20140516_01_20210107_163106_t005_viterbi
%20140313_08_20210107_162824_t005_viterbi
%temp = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20201122_193803_t005_viterbi.mat');

% Example to run 1 season with 1 segment and frames 1:5
params_all = [];
idx_segment = 1;
params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140516_01');
params(idx_segment).cmd.generic = 1;
params(idx_segment).cmd.frms = [40 41];
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

temp = [];
temp{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20201202_020912_t005_viterbi.mat');
%temp{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20210124_024502_t004_lsm.mat');
% two segments
%temp{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140313_08_20210107_162824_t005_viterbi.mat');
%temp{end+1} = load('/cresis/snfs1/dataproducts/ct_data/ct_tmp/layer_tracker/rds/2014_Greenland_P3/20140516_01_20210107_163106_t005_viterbi.mat');

% which plots are wanted
options.segment_vs_frame.plot = true;
options.segment_vs_frame.fig_format = false;
options.season_vs_gps.plot = true;
options.season_vs_gps.fig_format = true;
options.absolute_error.plot = true;
options.absolute_error.fig_format = false;
options.percentage_correct.plot = true;
options.percentage_correct.fig_format = false;
options.hist_generation.plot = true;
options.hist_generation.fig_format = false;

save_name = '/cresis/snfs1/scratch/anjali/cluster_tuning/result_layer_tune_vit_s015'; % where to store tuning final result

gt_layer_params = [];
layer_params = [];
res_matrix = [];
res_list = [];
gps_time = [];
num_layers = 1;
range = 10;
idx = 1;
%gt_layer_params(idx).name = 'surface';
%idx = idx + 1;
gt_layer_params(idx).name = 'bottom'; % specify layer names


% run_all; % uncomment the seasons you want first
% params_all = [];
% for param_fns_idx = 1:length(param_fns)
%   param_fn = param_fns{param_fns_idx};
%   param = regexp(param_fn,'(?<radar_name>\w+)_param_(?<season_name>\w+)','names');
%   [output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);
%   param_fn = ct_filename_param(sprintf('%s_param_%s.xls', output_dir, param.season_name));
%   params = read_param_xls(param_fn,'20140516_01');
%
%   params = ct_set_params(params,'cmd.generic',0);
%   params = ct_set_params(params,'cmd.generic',1,'day_seg',segment_list{param_fns_idx});
%   params = ct_set_params(params,'cmd.frms',frm_list{param_fns_idx}); %% Specify specific frames (or leave empty/undefined to do all frames)
%   params_all{end+1} = params;
% end
season_vect = [];
segment_vect = [];
frame_vect  = [];

seg_idx = 0;
for season_idx = 1:length(params_all) %seasons
  params = params_all{season_idx};
  
  for param_idx = 1:length(params) % segments
    param = params(param_idx);
    
    if isfield(param.cmd,'generic') && ~iscell(param.cmd.generic) && ~ischar(param.cmd.generic) && param.cmd.generic
      seg_idx = seg_idx + 1;
      param_override = temp{seg_idx}.param;
      param = merge_structs(param,param_override);
      total_length = 0;
      layers = opsLoadLayers(param,gt_layer_params);
      idx_matrix = [(1:length(param.layer_tracker.track{1}.idx_reshape))+1 1]; % used for resizing
      
      for track_idx = 1:length(param.layer_tracker.track)
        range_percent_all_frms.(sprintf('%s', param.layer_tracker.track{track_idx}.name)) = 0;
        range_per{track_idx} = [];
        percent_error(track_idx) = 0;
        for frm_idx = 1:length(param.cmd.frms)
          range_percent.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm_idx)) = 0;
          prob_error.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm_idx)) = 0;
          frame_error{track_idx}(frm_idx) = 0;
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
            layer_params(layer_idx).name = sprintf('%s_%s_%s',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method,gt_layer_params(layer_idx).name);
            layer_params(layer_idx).source = param.layer_tracker.layer_params.source;
            layer_params(layer_idx).layerdata_source = param.layer_tracker.layer_params.layerdata_source;
            layers_new = opsLoadLayers(param,layer_params);
            
            surf = interp1(layers(layer_idx).gps_time,layers(layer_idx).twtt,data.GPS_time);
            surf_bins = round(interp1(data.Time,1:length(data.Time),surf));
            
            for pos = 1:length(layers_new)
              surf = interp1(layers_new(pos).gps_time,layers_new(pos).twtt,data.GPS_time);
              surf_bins_itr = round(interp1(data.Time,1:length(data.Time),surf));
              res_list(frm_idx,idx_list) = nanmean(abs(surf_bins - surf_bins_itr));
              res_matrix_all{layer_idx}(frm_idx,param.layer_tracker.track{track_idx}.idx(pos)) = nanmean(abs(surf_bins - surf_bins_itr));
              counter = 0;
              for i = 1:length(surf_bins)
                try
                  res_matrix{layer_idx}{param.layer_tracker.track{track_idx}.idx(pos)}(end+1) = surf_bins(i) - surf_bins_itr(i);
                catch ME
                  res_matrix{layer_idx}{param.layer_tracker.track{track_idx}.idx(pos)}(i) = surf_bins(i) - surf_bins_itr(i);
                end
                if (abs(surf_bins(i) - surf_bins_itr(i)) <= range)
                  counter = counter + 1;
                end
              end
              range_percent.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm)) = (counter/length(surf_bins))*100;
              range_per{track_idx}(end+1) = (counter/length(surf_bins))*100;
              percent_error(track_idx) = counter + percent_error(track_idx);
              prob_error.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm)) = counter*100;
              frame_error{track_idx}(frm_idx) = nanmean(abs(surf_bins - surf_bins_itr));
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
      
      %Histogram stuff
      %             hist_list = [];
      %
      %             for hist_track_idx = 1:length(param.layer_tracker.track)
      %               prob_error_list{hist_track_idx} = [];
      %               range_percent_all_frms.(sprintf('%s', param.layer_tracker.track{hist_track_idx}.name)) = range_percent_all_frms.(sprintf('%s', param.layer_tracker.track{hist_track_idx}.name))/length(param.cmd.frms);
      %             end
      %
      %             for hist_track_idx = 1:length(param.layer_tracker.track)
      %               for hist_frm_idx = param.cmd.frms
      %                 hist_list(end+1) = range_percent.(sprintf('%s_%03d', param.layer_tracker.track{hist_track_idx}.name,hist_frm_idx));
      %                 prob_error.(sprintf('%s_%03d', param.layer_tracker.track{hist_track_idx}.name,hist_frm_idx)) = prob_error.(sprintf('%s_%03d', param.layer_tracker.track{hist_track_idx}.name,hist_frm_idx))/total_length;
      %                 prob_error_list{hist_track_idx}(end+1) = prob_error.(sprintf('%s_%03d', param.layer_tracker.track{hist_track_idx}.name,hist_frm_idx));
      %               end
      %               %figure;
      %               %h = histogram(hist_list);
      %             end
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
      end
      
      % per segment vs frame
      if (options.segment_vs_frame.plot)
        h_fig(1) = figure;
        for fig_idx = 1:length(param.layer_tracker.track)
          hold on;
          plot(frame_error{fig_idx},'DisplayName',sprintf('tracker%d',fig_idx));
          legend('-DynamicLegend','Location','northeastoutside');
          labelNameX = 'frames';
          labelNameY = 'absolute error';
          ylabel(labelNameY);
          xlabel(labelNameX);
          title(sprintf('%s frames: %03d',param.day_seg,length(param.cmd.frms)),'Interpreter', 'none');
        end
        hold off;
        img_format = 'png';
        if(options.segment_vs_frame.fig_format)
          img_format = 'fig';
        end
        testname = param.layer_tracker.layer_params.layerdata_source;
        img_fn = fullfile(img_dir,sprintf('%03d_%s_%s_segment_vs_frame.%s',2,testname,param.day_seg,img_format));
        ct_saveas(h_fig(1),img_fn);
      end
      
      if (options.percentage_correct.plot)
        h_fig(1) = figure;
        for hist_idx = 1:length(param.layer_tracker.track)
          hold on;
          plot(range_per{hist_idx},'DisplayName',sprintf('tracker%d',hist_idx));
          legend('-DynamicLegend','Location','northeastoutside');
          xlabel('Number of frames');
          ylabel('Percentage error');
          title(param.day_seg,'Interpreter', 'none');
          percent_error(hist_idx) = percent_error(hist_idx)/total_length * 100;
        end
        img_format = 'png';
        if(options.percentage_correct.fig_format)
          img_format = 'fig';
        end
        testname = param.layer_tracker.layer_params.layerdata_source;
        img_fn = fullfile(img_dir,sprintf('%03d_%s_%s_percentage_correct.%s',2,testname,param.day_seg,img_format));
        ct_saveas(h_fig(1),img_fn);
        
        if (options.hist_generation.plot)
          h_fig(1) = figure;
          %           for hist_idx = 1:length(param.layer_tracker.track)
          %             hold on;
          %             plot(hist(range_per{hist_idx}),'DisplayName',sprintf('tracker%d',hist_idx));
          %             legend('-DynamicLegend');
          %             ylabel('Number of frames');
          %             xlabel('Bins');
          %             title(param.day_seg,'Interpreter', 'none');
          %             percent_error(hist_idx) = percent_error(hist_idx)/total_length * 100;
          %           end
          for hist_idx = 1:length(param.layer_tracker.track)
            hold on;
            [N,x] = hist(abs(res_matrix{1}{hist_idx}));
            plot(x,N,'DisplayName',sprintf('tracker%d',hist_idx));
            legend('-DynamicLegend','Location','northeastoutside');
            ylabel('Data points');
            xlabel('Absolute error');
            title(sprintf('%s frames: %03d',param.day_seg,length(param.cmd.frms)),'Interpreter', 'none');
          end
          hold off;
          img_format = 'png';
          if(options.hist_generation.fig_format)
            img_format = 'fig';
          end
          testname = param.layer_tracker.layer_params.layerdata_source;
          img_fn = fullfile(img_dir,sprintf('%03d_%s_%s_histogram_generation.%s',2,testname,param.day_seg,img_format));
          ct_saveas(h_fig(1),img_fn);
        end
        
        h_fig(1) = figure;
        plot(percent_error);
        hold on;
        plot(percent_error, 'r*');
        ylabel('Percentage correct');
        xlabel('Trackers');
        title(param.day_seg,'Interpreter', 'none');
        set(gca,'XTick',1:length(param.layer_tracker.track));
        img_format = 'png';
        if(options.percentage_correct.fig_format)
          img_format = 'fig';
        end
        testname = param.layer_tracker.layer_params.layerdata_source;
        img_fn = fullfile(img_dir,sprintf('%03d_%s_%s_total_percent_correct.%s',2,testname,param.day_seg,img_format));
        ct_saveas(h_fig(1),img_fn);
      end
      
      if(options.absolute_error.plot)
        if(strcmpi(param.layer_tracker.track{1}.method,'viterbi'))
          for layer_idx = 1:num_layers
            res_mat = res_matrix_all_frms{layer_idx};
            points_new = points{layer_idx};
            x = 1:length(res_mat); % x tick
            h_fig(1) = figure;
            plot(x,res_mat);
            hold on;
            for i = 1:length(res_mat)
              plot(x(i),res_mat(i), 'r*');
            end
            plot(x(points_new(1)),res_mat(points_new(1)), 'ko','LineWidth',4);
            set(gca,'XTick',x);
            ylabel('Mean absolute error');
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
          for layer_idx = 1:num_layers
            res_mat = res_matrix_all_frms{layer_idx};
            points = points{layer_idx};
            
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
              h_fig(1) = figure; % figure is not displayed
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
              img_format ='jpg';
              if(options.fig_generation)
                img_format = 'fig';
              end
              testname = param.layer_tracker.layer_params.layerdata_source;
              img_fn = fullfile(img_dir,sprintf('%03d_%s_%s_absolute_error.%s',2,testname,param.day_seg,img_format));
              ct_saveas(h_fig(1),img_fn);
              
            end
          end
        end
        
        
      end
      
      if(options.season_vs_gps.plot)
        for track_idx = 1:length(param.layer_tracker.track)
          h_fig(1) = figure;
          plot(gps_time,abs(res_matrix{1}{track_idx}));
          ylabel('Absolute error');
          xlabel('GPS time');
          title(sprintf('%s frames: %03d Tracker: %03d',param.season_name,length(param.cmd.frms), track_idx),'Interpreter', 'none');
          xlim([gps_time(1) gps_time(end)]);
          
          img_format = 'png';
          if(options.season_vs_gps.fig_format)
            img_format = 'fig';
          end
          testname = param.layer_tracker.layer_params.layerdata_source;
          img_fn = fullfile(img_dir,sprintf('%03d_%s_%s_season_gps_%03d.%s',2,testname,param.day_seg,track_idx,img_format));
          ct_saveas(h_fig(1),img_fn);
        end
      end
      
      
    end
  end
end

keyboard;

%% Find Best Combination
for layer_names = 1:idx
  res_matrix{layer_names} = zeros([length(param.cmd.frms),param.layer_tracker.track{1}.idx_reshape]);
  num_gt_isfinite.(sprintf('%s',gt_layer_params(layer_names).name)) = 0;
  num_isnan.(sprintf('%s',gt_layer_params(layer_names).name)) = 0;
  num_points.(sprintf('%s',gt_layer_params(layer_names).name)) = 0;
  num_layers = num_layers+1;
end


idx_matrix = [(1:length(param.layer_tracker.track{1}.idx_reshape))+1 1]; % used for resizing

for track_idx = 1:length(param.layer_tracker.track)
  frm_idx = 0;
  for frm = param.cmd.frms
    frm_idx = frm_idx+1;
    data_fn_dir = ct_filename_out(param, param.layer_tracker.echogram_source, '');
    data_fn_name = sprintf('Data_%s_%03d.mat',param.day_seg,frm);
    data_fn      = fullfile(data_fn_dir, data_fn_name);
    data = load(data_fn);
    dt = data.Time(2) - data.Time(1);
    for layer_idx = 1:length(gt_layer_params)
      
      layer_params(1).name = sprintf('%s_%s_%s',param.layer_tracker.track{track_idx}.name,param.layer_tracker.track{track_idx}.method,gt_layer_params(layer_idx).name);
      layer_params(1).source = param.layer_tracker.layer_params.source;
      layer_params(1).layerdata_source = param.layer_tracker.layer_params.layerdata_source;
      layers_new = opsLoadLayers(param,layer_params);
      
      surf = interp1(layers(layer_idx).gps_time,layers(layer_idx).twtt,data.GPS_time);
      surf_bins = round(interp1(data.Time,1:length(data.Time),surf));
      
      for pos = 1:length(layers_new)
        surf = interp1(layers_new(pos).gps_time,layers_new(pos).twtt,data.GPS_time);
        surf_bins_itr = round(interp1(data.Time,1:length(data.Time),surf));
        num_gt_isfinite.(sprintf('%s',gt_layer_params(layer_idx).name)) = num_gt_isfinite.(sprintf('%s',gt_layer_params(layer_idx).name)) + sum(isfinite(surf_bins));
        num_isnan.(sprintf('%s',gt_layer_params(layer_idx).name)) = num_isnan.(sprintf('%s',gt_layer_params(layer_idx).name)) + (sum(isfinite(surf_bins) & ~isfinite(surf_bins_itr)));
        num_points.(sprintf('%s',gt_layer_params(layer_idx).name)) = num_points.(sprintf('%s',gt_layer_params(layer_idx).name)) + (sum(abs(surf_bins-surf_bins_itr) < 5*dt));
        res_matrix{layer_idx}(frm_idx,param.layer_tracker.track{track_idx}.idx(pos)) = nanmean(abs(surf_bins - surf_bins_itr));
        counter = 0;
        for i = 1:length(surf_bins)
          if (abs(surf_bins(i) - surf_bins_itr(i)) <= range)
            counter = counter + 1;
          end
        end
        range_percent.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm))= (counter/length(surf_bins))*100;
      end
    end
  end
  counter = 0;
  for i = 1:length(param.cmd.frms)
    counter = counter + range_percent.(sprintf('%s_%03d', param.layer_tracker.track{track_idx}.name,frm));
  end
  range_percent_all_frms.(sprintf('%s', param.layer_tracker.track{track_idx}.name)) = counter/length(param.cmd.frms);
end

points = [];
min_val = [];
res_matrix_all_frms = [];
for layer_names = 1:num_layers
  res_matrix_all_frms{layer_names} = nanmean(res_matrix{layer_names},1);
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

file_version = '1';
file_type = 'layer_tracker_tuning';

fn_dir = fileparts(save_name);
if ~exist(fn_dir,'dir')
  mkdir(fn_dir);
end

save(save_name,'res_matrix','range_percent','range_percent_all_frms','num_isnan','num_points','num_gt_isfinite','points','min_val','res_matrix_all_frms','param','file_version','file_type');
