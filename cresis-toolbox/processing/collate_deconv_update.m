function collate_deconv_update(param,param_override)
% collate_deconv_update(param,param_override)
%
% This scripts updates the collate_deconv output files. It allows one to
% delete, add, and update waveforms to the final deconv file.
%
% Example:
%  See run_collate_deconv_update.m to run.
%
% Author: John Paden

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

physical_constants;

%% Input checks
% =====================================================================

[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

% param.collate_deconv_update structure
% =========================================================================

if ~isfield(param.collate_deconv_update,'abs_metric') || isempty(param.collate_deconv_update.abs_metric)
  param.collate_deconv_update.abs_metric = [58 5 -25 -35 inf inf];
end

if ~isfield(param.collate_deconv_update,'debug_plots')
  param.collate_deconv_update.debug_plots = {'final'};
  % param.collate_deconv_update.debug_plots = {'final','visible'};
end

if ~isfield(param.collate_deconv_update,'delete_existing') || isempty(param.collate_deconv_update.delete_existing)
  param.collate_deconv_update.delete_existing = false;
end

if ~isfield(param.collate_deconv_update,'gps_time_penalty') || isempty(param.collate_deconv_update.gps_time_penalty)
  param.collate_deconv_update.gps_time_penalty = 1/(10*24*3600);
end

if ~isfield(param.analysis,'imgs') || isempty(param.analysis.imgs)
  param.analysis.imgs = {[1 1]};
end
if ~isfield(param.collate_deconv_update,'imgs') || isempty(param.collate_deconv_update.imgs)
  param.collate_deconv_update.imgs = 1:length(param.analysis.imgs);
end

if ~isfield(param.collate_deconv_update,'in_path') || isempty(param.collate_deconv_update.in_path)
  param.collate_deconv_update.in_path = 'analysis';
end

if ~isfield(param.collate_deconv_update,'metric_weights') || isempty(param.collate_deconv_update.metric_weights)
  param.collate_deconv_update.metric_weights = [0.5 0 3 5 0 0];
end
error_mask = isinf(param.collate_deconv_update.abs_metric) & param.collate_deconv_update.metric_weights ~= 0;
if any(error_mask)
  warning('Fields set to inf in abs_metric must be set to 0 in metric_weights. Setting these to 0 now.');
  param.collate_deconv_update.metric_weights(error_mask) = 0;
end

if ~isfield(param.collate_deconv_update,'min_score') || isempty(param.collate_deconv_update.min_score)
  param.collate_deconv_update.min_score = -10;
end

if ~isfield(param.collate_deconv_update,'out_path') || isempty(param.collate_deconv_update.out_path)
  param.collate_deconv_update.out_path = param.collate_deconv_update.in_path;
end

if ~isfield(param.collate_deconv_update,'twtt_penalty') || isempty(param.collate_deconv_update.twtt_penalty)
  if strcmpi(radar_type,'deramp')
    param.collate_deconv_update.twtt_penalty = 1e6;
  else
    % No twtt dependence
    param.collate_deconv_update.twtt_penalty = 1e-6;
  end
end

if ~isfield(param.collate_deconv_update,'wf_adcs') || isempty(param.collate_deconv_update.wf_adcs)
  param.collate_deconv_update.wf_adcs = [];
end

% Other Setup
% =========================================================================

if ~isempty(param.collate_deconv_update.debug_plots)
  h_fig = get_figures(3,any(strcmp('visible',param.collate_deconv_update.debug_plots)),'collate_deconv');
end

%% Process commands
% =====================================================================
tmp_param = param;
for img = param.collate_deconv_update.imgs
  
  if isempty(param.collate_deconv_update.wf_adcs)
    % If no wf-adc pairs specified, then do them all.
    wf_adcs = 1:size(param.analysis.imgs{img},1);
  else
    wf_adcs = param.collate_deconv_update.wf_adcs;
  end
  for wf_adc = wf_adcs
    wf = param.analysis.imgs{img}(wf_adc,1);
    adc = param.analysis.imgs{img}(wf_adc,2);
    
    % Load input
    % ===================================================================
    fn_dir = fileparts(ct_filename_out(param,param.collate_deconv_update.in_path, ''));
    fn = fullfile(fn_dir,sprintf('deconv_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
    fprintf('\n==============================================================\n');
    fprintf('Loading %s img %d wf %d adc %d\n  %s\n', param.day_seg, img, wf, adc, fn);
    if param.collate_deconv_update.delete_existing
      delete(fn);
    end
    % Load existing waveforms for this segment
    if exist(fn,'file')
      deconv = load(fn,'param_collate_deconv','param_analysis','param_records');
      if ~isfield(deconv,'param_collate_deconv') || isempty(deconv.param_collate_deconv) ...
          || ~isfield(deconv,'param_analysis') || isempty(deconv.param_analysis) ...
          || ~isfield(deconv,'param_records') || isempty(deconv.param_records)
        new_file = true;
        deconv = [];
        deconv_lib = [];
        fprintf('  Does not exist.\n');
      else
        new_file = false;
        deconv_lib = load(fn);
      end
    else
      new_file = true;
      deconv = [];
      deconv_lib = [];
      fprintf('  Does not exist.\n');
    end
    
    % Execute update commands
    % ===================================================================
    for cmd_idx = 1:length(param.collate_deconv_update.cmd)
      switch lower(param.collate_deconv_update.cmd{cmd_idx}.method)
        case 'delete'
          fprintf('%s:', param.collate_deconv_update.cmd{cmd_idx}.method);
          fprintf(' %d', param.collate_deconv_update.cmd{cmd_idx}.idxs);
          fprintf('\n');
          
          if new_file
            error('Delete not allowed on segments that do not have a deconv file or any waveforms loaded.');
          end
          
          deconv_idxs = setdiff(1:length(deconv_lib.gps_time), param.collate_deconv_update.cmd{cmd_idx}.idxs);
          deconv_lib.elev = deconv_lib.elev(deconv_idxs);
          deconv_lib.fc = deconv_lib.fc(deconv_idxs);
          deconv_lib.frm = deconv_lib.frm(deconv_idxs);
          deconv_lib.gps_time = deconv_lib.gps_time(deconv_idxs);
          deconv_lib.heading = deconv_lib.heading(deconv_idxs);
          deconv_lib.impulse_response = deconv_lib.impulse_response(deconv_idxs);
          deconv_lib.lat = deconv_lib.lat(deconv_idxs);
          deconv_lib.lon  = deconv_lib.lon(deconv_idxs);
          deconv_lib.map_day_seg = deconv_lib.map_day_seg(deconv_idxs);
          deconv_lib.metric = deconv_lib.metric(:,deconv_idxs);
          deconv_lib.peakiness = deconv_lib.peakiness(deconv_idxs);
          deconv_lib.pitch = deconv_lib.pitch(deconv_idxs);
          deconv_lib.rec = deconv_lib.rec(deconv_idxs);
          deconv_lib.ref_mult_factor = deconv_lib.ref_mult_factor(deconv_idxs);
          deconv_lib.ref_negative = deconv_lib.ref_negative(deconv_idxs);
          deconv_lib.ref_nonnegative = deconv_lib.ref_nonnegative(deconv_idxs);
          deconv_lib.roll = deconv_lib.roll(deconv_idxs);
          deconv_lib.twtt = deconv_lib.twtt(deconv_idxs);
          
        case {'add','replace'}
          for seg_idx = 1:length(param.collate_deconv_update.cmd{cmd_idx}.day_seg)
            fprintf('%s: ', param.collate_deconv_update.cmd{cmd_idx}.method);
            fprintf(' (%s,', param.collate_deconv_update.cmd{cmd_idx}.day_seg{seg_idx});
            fprintf(' %d', param.collate_deconv_update.cmd{cmd_idx}.idxs{seg_idx});
            fprintf(')');
          end
          fprintf('\n');
          
          for seg_idx = 1:length(param.collate_deconv_update.cmd{cmd_idx}.day_seg)
            if ~isfield(param.collate_deconv_update.cmd{cmd_idx},'wf_adcs_map') ...
                || numel(param.collate_deconv_update.cmd{cmd_idx}.wf_adcs_map) < seg_idx ...
                || isempty(param.collate_deconv_update.cmd{cmd_idx}.wf_adcs_map{seg_idx})
              wf_map = wf;
              adc_map = adc;
            else
              wf_map = param.collate_deconv_update.cmd{cmd_idx}.wf_adcs_map{seg_idx}{img}(wf_adc,1);
              adc_map = param.collate_deconv_update.cmd{cmd_idx}.wf_adcs_map{seg_idx}{img}(wf_adc,2);
            end
            
            tmp_param.day_seg = param.collate_deconv_update.cmd{cmd_idx}.day_seg{seg_idx};
            fn_dir = fileparts(ct_filename_out(tmp_param,param.collate_deconv_update.in_path, ''));
            fn = fullfile(fn_dir,sprintf('deconv_%s_wf_%d_adc_%d.mat', tmp_param.day_seg, wf_map, adc_map));
            fprintf('  Loading %s img %d wf %d adc %d\n  %s\n', tmp_param.day_seg, img, wf_map, adc_map, fn);
            tmp_deconv{cmd_idx}{seg_idx} = load(fn);
            
            if new_file
              new_file = false;
              deconv_lib = tmp_deconv{cmd_idx}{seg_idx};
              deconv_lib.elev = [];
              deconv_lib.fc = [];
              deconv_lib.frm = [];
              deconv_lib.gps_time = [];
              deconv_lib.heading = [];
              deconv_lib.impulse_response = [];
              deconv_lib.lat = [];
              deconv_lib.lon  = [];
              deconv_lib.map_day_seg = [];
              deconv_lib.metric = [];
              deconv_lib.peakiness = [];
              deconv_lib.pitch = [];
              deconv_lib.rec = [];
              deconv_lib.ref_mult_factor = [];
              deconv_lib.ref_negative = [];
              deconv_lib.ref_nonnegative = [];
              deconv_lib.roll = [];
              deconv_lib.twtt = [];
            end
            
            if isfield(deconv_lib,'dt') && abs(tmp_deconv{cmd_idx}{seg_idx}.dt - deconv_lib.dt)/deconv_lib.dt > 1e-6
              error('Time bins do not align %g ~= deconv_lib.dt == %g', tmp_deconv{cmd_idx}{seg_idx}.dt, deconv_lib.dt);
            end
            deconv.param_collate_deconv = tmp_deconv{cmd_idx}{seg_idx}.param_collate_deconv;
            deconv.param_analysis = tmp_deconv{cmd_idx}{seg_idx}.param_analysis;
            deconv.param_records = tmp_deconv{cmd_idx}{seg_idx}.param_records;
            
            % Make sure selected waveforms to add/replace exist
            param.collate_deconv_update.cmd{cmd_idx}.idxs{seg_idx}  ...
              = intersect(param.collate_deconv_update.cmd{cmd_idx}.idxs{seg_idx}, ...
              1:length(tmp_deconv{cmd_idx}{seg_idx}.gps_time));
            
            new_idxs = param.collate_deconv_update.cmd{cmd_idx}.idxs{seg_idx};
            if strcmpi(param.collate_deconv_update.cmd{cmd_idx}.method,'add')
              deconv_lib.elev = [deconv_lib.elev tmp_deconv{cmd_idx}{seg_idx}.elev(new_idxs)];
              deconv_lib.fc = [deconv_lib.fc tmp_deconv{cmd_idx}{seg_idx}.fc(new_idxs)];
              deconv_lib.frm = [deconv_lib.frm tmp_deconv{cmd_idx}{seg_idx}.frm(new_idxs)];
              deconv_lib.gps_time = [deconv_lib.gps_time tmp_deconv{cmd_idx}{seg_idx}.gps_time(new_idxs)];
              deconv_lib.heading = [deconv_lib.heading tmp_deconv{cmd_idx}{seg_idx}.heading(new_idxs)];
              deconv_lib.impulse_response = [deconv_lib.impulse_response tmp_deconv{cmd_idx}{seg_idx}.impulse_response(new_idxs)];
              deconv_lib.lat = [deconv_lib.lat tmp_deconv{cmd_idx}{seg_idx}.lat(new_idxs)];
              deconv_lib.lon  = [deconv_lib.lon tmp_deconv{cmd_idx}{seg_idx}.lon(new_idxs)];
              deconv_lib.map_day_seg = [deconv_lib.map_day_seg tmp_deconv{cmd_idx}{seg_idx}.map_day_seg(new_idxs)];
              deconv_lib.metric = [deconv_lib.metric tmp_deconv{cmd_idx}{seg_idx}.metric(:,new_idxs)];
              deconv_lib.peakiness = [deconv_lib.peakiness tmp_deconv{cmd_idx}{seg_idx}.peakiness(new_idxs)];
              deconv_lib.pitch = [deconv_lib.pitch tmp_deconv{cmd_idx}{seg_idx}.pitch(new_idxs)];
              deconv_lib.rec = [deconv_lib.rec tmp_deconv{cmd_idx}{seg_idx}.rec(new_idxs)];
              deconv_lib.ref_mult_factor = [deconv_lib.ref_mult_factor tmp_deconv{cmd_idx}{seg_idx}.ref_mult_factor(new_idxs)];
              deconv_lib.ref_negative = [deconv_lib.ref_negative tmp_deconv{cmd_idx}{seg_idx}.ref_negative(new_idxs)];
              deconv_lib.ref_nonnegative = [deconv_lib.ref_nonnegative tmp_deconv{cmd_idx}{seg_idx}.ref_nonnegative(new_idxs)];
              deconv_lib.roll = [deconv_lib.roll tmp_deconv{cmd_idx}{seg_idx}.roll(new_idxs)];
              deconv_lib.twtt = [deconv_lib.twtt tmp_deconv{cmd_idx}{seg_idx}.twtt(new_idxs)];
            else
              deconv_lib.elev = tmp_deconv{cmd_idx}{seg_idx}.elev(new_idxs);
              deconv_lib.fc = tmp_deconv{cmd_idx}{seg_idx}.fc(new_idxs);
              deconv_lib.frm = tmp_deconv{cmd_idx}{seg_idx}.frm(new_idxs);
              deconv_lib.gps_time = tmp_deconv{cmd_idx}{seg_idx}.gps_time(new_idxs);
              deconv_lib.heading = tmp_deconv{cmd_idx}{seg_idx}.heading(new_idxs);
              deconv_lib.impulse_response = tmp_deconv{cmd_idx}{seg_idx}.impulse_response(new_idxs);
              deconv_lib.lat = tmp_deconv{cmd_idx}{seg_idx}.lat(new_idxs);
              deconv_lib.lon  = tmp_deconv{cmd_idx}{seg_idx}.lon(new_idxs);
              deconv_lib.map_day_seg = tmp_deconv{cmd_idx}{seg_idx}.map_day_seg(new_idxs);
              deconv_lib.metric = tmp_deconv{cmd_idx}{seg_idx}.metric(:,new_idxs);
              deconv_lib.peakiness = tmp_deconv{cmd_idx}{seg_idx}.peakiness(new_idxs);
              deconv_lib.pitch = tmp_deconv{cmd_idx}{seg_idx}.pitch(new_idxs);
              deconv_lib.rec = tmp_deconv{cmd_idx}{seg_idx}.rec(new_idxs);
              deconv_lib.ref_mult_factor = tmp_deconv{cmd_idx}{seg_idx}.ref_mult_factor(new_idxs);
              deconv_lib.ref_negative = tmp_deconv{cmd_idx}{seg_idx}.ref_negative(new_idxs);
              deconv_lib.ref_nonnegative = tmp_deconv{cmd_idx}{seg_idx}.ref_nonnegative(new_idxs);
              deconv_lib.roll = tmp_deconv{cmd_idx}{seg_idx}.roll(new_idxs);
              deconv_lib.twtt = tmp_deconv{cmd_idx}{seg_idx}.twtt(new_idxs);
            end
          end
          fprintf('\n');
      end
    end
    if ~isfield(deconv_lib,'gps_time') || isempty(deconv_lib.gps_time)
      error('Cannot create a deconv file with zero waveforms.');
    end
    
    % 2. Load surface using opsLoadLayers to determine which waveforms
    %    are needed
    layer_params = [];
    layer_params.name = 'surface';
    layer_params.source = 'layerData';
    layer = opsLoadLayers(param,layer_params);
    
    % 3. Decimate layer
    decim_idxs = get_equal_alongtrack_spacing_idxs(layer.gps_time,10);
    layer.gps_time = layer.gps_time(decim_idxs);
    layer.twtt = layer.twtt(decim_idxs);
    layer.lat = layer.lat(decim_idxs);
    layer.lon = layer.lon(decim_idxs);
    layer.elev = layer.elev(decim_idxs);
    
    % 4. Compare results to metric
    pass = bsxfun(@lt,deconv_lib.metric,param.collate_deconv_update.abs_metric(:));
    score = nansum(bsxfun(@times, param.collate_deconv_update.metric_weights(:), bsxfun(@minus, param.collate_deconv_update.abs_metric(:), deconv_lib.metric)));
    score(:,any(isnan(deconv_lib.metric))) = nan;
    
    % 5. Find best score at each point along the flight track
    min_score = nanmin(score);
    score = score-min_score;
    clear max_score unadjusted_score max_idx;
    for rline = 1:length(layer.twtt)
      % Score with twtt penalty and time constant penalty term
      d_twtt = layer.twtt(rline) - deconv_lib.twtt;
      d_gps_time = layer.gps_time(rline) - deconv_lib.gps_time;
      %adjusted_score = min_score + score .* exp(-abs(param.collate_deconv_update.twtt_penalty*d_twtt).^2) ...
      %  .* exp(-abs(param.collate_deconv_update.gps_time_penalty*d_gps_time).^2);
      adjusted_score = min_score + score - (100-100*exp(-abs(param.collate_deconv_update.twtt_penalty*d_twtt).^2)) ...
        - (50-50*exp(-abs(param.collate_deconv_update.gps_time_penalty*d_gps_time).^2));
      
      [max_score(rline),max_idx(rline)] = max(adjusted_score);
      unadjusted_score(rline) = min_score + score(max_idx(rline));
    end
    if any(max_score < param.collate_deconv_update.min_score)
      warning('Score is too low for %d of %d blocks of range lines.', sum(max_score < param.collate_deconv_update.min_score), length(max_score));
    end
    [max_idxs,~,max_idxs_mapping] = unique(max_idx);
    
    [~,sort_idxs] = sort(deconv_lib.twtt(max_idxs));
    unsort_idxs(sort_idxs) = 1:length(sort_idxs);
    max_idxs = max_idxs(sort_idxs);
    max_idxs_mapping = unsort_idxs(max_idxs_mapping);
    
    
    final = [];
    final.gps_time = deconv_lib.gps_time(max_idxs);
    final.lat = deconv_lib.lat(max_idxs);
    final.lon = deconv_lib.lon(max_idxs);
    final.elev = deconv_lib.elev(max_idxs);
    final.roll = deconv_lib.roll(max_idxs);
    final.pitch = deconv_lib.pitch(max_idxs);
    final.heading = deconv_lib.heading(max_idxs);
    final.frm = deconv_lib.frm(max_idxs);
    final.rec = deconv_lib.rec(max_idxs);
    final.ref_windowed = deconv_lib.ref_windowed;
    final.ref_window = deconv_lib.ref_window;
    final.ref_nonnegative = deconv_lib.ref_nonnegative(max_idxs);
    final.ref_negative = deconv_lib.ref_negative(max_idxs);
    final.ref_mult_factor = deconv_lib.ref_mult_factor(max_idxs);
    final.impulse_response = deconv_lib.impulse_response(max_idxs);
    final.metric = deconv_lib.metric(:,max_idxs);
    final.peakiness = deconv_lib.peakiness(max_idxs);
    final.fc = deconv_lib.fc(max_idxs);
    final.dt = deconv_lib.dt;
    final.twtt = deconv_lib.twtt(max_idxs);
    final.param_collate_deconv_final = param;
    final.param_collate_deconv = deconv.param_collate_deconv;
    final.param_analysis = deconv.param_analysis;
    final.param_records = deconv.param_records;
    final.map_day_seg = deconv_lib.map_day_seg(max_idxs); % differs from collate_deconv
    final.map_gps_time = layer.gps_time;
    final.map_twtt = layer.twtt;
    final.map_idxs = max_idxs_mapping(:).';
    final.max_score = max_score;
    final.unadjusted_score = unadjusted_score;
    if param.ct_file_lock
      final.file_version = '1L';
    else
      final.file_version = '1';
    end
    
    % 7. Plot final deconv waveforms
    if any(strcmp('final',param.collate_deconv_update.debug_plots))
      % TWTT Figure
      % ===================================================================
      clf(h_fig(1));
      set(h_fig(1),'Name',['TWTT ' param.day_seg]);
      h_axes = axes('parent',h_fig(1));
      
      legend_str = {};
      h_plot = [];
      for idx = 1:length(final.gps_time)
        h_plot(idx+1) = plot(h_axes(1), find(final.map_idxs==idx), final.twtt(final.map_idxs(final.map_idxs==idx)),'.');
        hold(h_axes(1),'on');
        legend_str{idx+1} = sprintf('%d',idx);
      end
      
      h_plot(1) = plot(h_axes(1), final.map_twtt, 'k', 'LineWidth',2);
      legend_str{1} = 'TWTT';
      
      xlabel(h_axes(1), 'Block');
      ylabel(h_axes(1), 'Two way travel time (\mus)');
      title(h_axes(1), ['TWTT ' regexprep(param.day_seg,'_','\\_')]);
      legend(h_axes(1), h_plot, legend_str,'location','best');
      grid(h_axes(1), 'on');
      
      fig_fn = [ct_filename_ct_tmp(param,'','collate_deconv',sprintf('%s_twtt_wf_%02d_adc_%02d',param.collate_deconv_update.out_path,wf,adc)) '.fig'];
      fprintf('Saving %s\n', fig_fn);
      fig_fn_dir = fileparts(fig_fn);
      if ~exist(fig_fn_dir,'dir')
        mkdir(fig_fn_dir);
      end
      ct_saveas(h_fig(1),fig_fn);
      fig_fn = [ct_filename_ct_tmp(param,'','collate_deconv',sprintf('%s_twtt_wf_%02d_adc_%02d',param.collate_deconv_update.out_path,wf,adc)) '.jpg'];
      fprintf('Saving %s\n', fig_fn);
      ct_saveas(h_fig(1),fig_fn);
      
      % Score Figure
      % ===================================================================
      clf(h_fig(2));
      set(h_fig(2),'Name',['Score ' param.day_seg]);
      h_axes(2) = axes('parent',h_fig(2));
      
      legend_str = {};
      h_plot = [];
      for idx = 1:length(final.gps_time)
        h_plot(idx) = plot(h_axes(2), find(final.map_idxs==idx), final.max_score(find(final.map_idxs==idx)),'.');
        hold(h_axes(2),'on');
        legend_str{idx} = sprintf('%d',idx);
      end
      for idx = 1:length(final.gps_time)
        h_new_plot = plot(h_axes(2), find(final.map_idxs==idx), final.unadjusted_score(find(final.map_idxs==idx)),'.');
        set(h_new_plot, 'Color', get(h_plot(idx),'Color'))
      end
      
      xlabel(h_axes(2), 'Block');
      ylabel(h_axes(2), 'Score');
      title(h_axes(2), ['Score ' regexprep(param.day_seg,'_','\\_')]);
      legend(h_axes(2), h_plot, legend_str,'location','best');
      grid(h_axes(2), 'on');
      
      fig_fn = [ct_filename_ct_tmp(param,'','collate_deconv',sprintf('%s_score_wf_%02d_adc_%02d',param.collate_deconv_update.out_path,wf,adc)) '.fig'];
      fprintf('Saving %s\n', fig_fn);
      ct_saveas(h_fig(2),fig_fn);
      fig_fn = [ct_filename_ct_tmp(param,'','collate_deconv',sprintf('%s_score_wf_%02d_adc_%02d',param.collate_deconv_update.out_path,wf,adc)) '.jpg'];
      fprintf('Saving %s\n', fig_fn);
      ct_saveas(h_fig(2),fig_fn);
      
      % Transfer Function Figure
      % ===================================================================
      clf(h_fig(3));
      set(h_fig(3),'Name',['Transfer function ' param.day_seg]);
      pos = get(h_fig(3),'Position');
      set(h_fig(3),'Position',[pos(1:2) 1000 600]);
      h_axes(3) = subplot(5,1,1:2,'parent',h_fig(3));
      h_axes(4) = subplot(5,1,3:5,'parent',h_fig(3));
      
      legend_str = {};
      max_val_overall = -inf;
      for idx = 1:length(final.gps_time)
        % Get the reference function
        h_nonnegative = final.ref_nonnegative{idx};
        h_negative = final.ref_negative{idx};
        h_mult_factor = final.ref_mult_factor(idx);
        
        % Adjust deconvolution signal to match sample rline
        h_filled = [h_nonnegative; h_negative];
        
        % Take FFT of deconvolution impulse response
        h_filled = fft(h_filled);
        
        Nt = numel(h_filled);
        df = 1/(Nt*final.dt);
        freq = final.fc(idx) + df * ifftshift(-floor(Nt/2) : floor((Nt-1)/2)).';
        freq = fftshift(freq);
        fc_idx = find(freq==final.fc(idx));
        
        h_filled_lp = fftshift(lp(h_filled));
        h_filled_phase = fftshift(angle(h_filled));
        h_filled_phase = unwrap(h_filled_phase)*180/pi;
        h_filled_phase = h_filled_phase - h_filled_phase(fc_idx);
        
        if max(h_filled_lp) > max_val_overall
          max_val_overall = max(h_filled_lp);
        end
        
        if max(freq) > 2e9
          freq_scale = 1e9;
        else
          freq_scale = 1e6;
        end
        plot(h_axes(3), freq/freq_scale, h_filled_lp);
        hold(h_axes(3),'on');
        plot(h_axes(4), freq/freq_scale, h_filled_phase);
        hold(h_axes(4),'on');
        radiometric_error_dB = lp(1/(c*final.twtt(idx)).^2) - lp(final.ref_nonnegative{idx}(1));
        legend_str{idx} = sprintf('%d %s_%03.0f %7.0f %4.0fdB %4.1fus',idx, ...
          final.map_day_seg{idx},floor(final.frm(idx)),final.rec(idx),radiometric_error_dB, ...
          final.twtt(idx)*1e6);
      end
      if isfinite(max_val_overall)
        ylim(h_axes(3), max_val_overall + [-31 1]);
      end
      
      if freq_scale == 1e9
        xlabel(h_axes(4), 'Frequency (GHz)');
      else
        xlabel(h_axes(4), 'Frequency (MHz)');
      end
      ylabel(h_axes(3), 'Relative power (dB)');
      ylabel(h_axes(4), 'Relative angle (deg)');
      title(h_axes(3), regexprep(sprintf('%s (Legend idx:frm:rec:radio:twtt)', param.day_seg),'_','\\_'));
      grid(h_axes(3), 'on');
      grid(h_axes(4), 'on');
      h_legend = legend(h_axes(3), legend_str, 'location', 'northeastoutside', 'interpreter','none');
      drawnow;
      pos3 = get(h_axes(3),'Position');
      pos4 = get(h_axes(4),'Position');
      set(h_axes(4),'Position',[pos4(1:2) pos3(3) pos4(4)]);
      
      fig_fn = [ct_filename_ct_tmp(param,'','collate_deconv',sprintf('%s_final_transfer_func_wf_%02d_adc_%02d',param.collate_deconv_update.out_path,wf,adc)) '.fig'];
      fprintf('Saving %s\n', fig_fn);
      ct_saveas(h_fig(3),fig_fn);
      fig_fn = [ct_filename_ct_tmp(param,'','collate_deconv',sprintf('%s_final_transfer_func_wf_%02d_adc_%02d',param.collate_deconv_update.out_path,wf,adc)) '.jpg'];
      fprintf('Saving %s\n', fig_fn);
      ct_saveas(h_fig(3),fig_fn);
    end
    
    % Save outputs
    % ===================================================================
    fn_dir = fileparts(ct_filename_out(param,param.collate_deconv_update.out_path, ''));
    if ~exist(fn_dir,'dir')
      mkdir(fn_dir);
    end
    out_fn = fullfile(fn_dir,sprintf('deconv_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
    fprintf('Saving %s img %d wf %d adc %d\n  %s\n', param.day_seg, img, wf, adc, out_fn);
    ct_file_lock_check(out_fn,2);
    ct_save(out_fn,'-v7.3','-struct','final');
  end
end

if ~any(strcmp('visible',param.(mfilename).debug_plots))
  try
    delete(h_fig);
  end
end
