% function collate_burst_noise(param,param_override)
% collate_burst_noise(param,param_override)
%
% Collects analysis.m results from burst noise tracking (burst_noise
% command) and creates files for removing the burst noise during data
% loading.
% Loads all the burst_noise_* files and creates burst_noise_simp_* files that
% are pre-filtered for speed and saves as netcdf so that subsets of the
% files can be loaded efficiently.
%
% Example:
%  See run_collate_burst_noise for how to run.
%
% Authors: John Paden

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input checks
% =====================================================================

if ~isfield(param,'collate_burst_noise') || isempty(param.collate_burst_noise)
  param.collate_burst_noise = [];
end

% param.collate_burst_noise.imgs: Check this first since other input checks
%   are dependent on its value.
if ~isfield(param.analysis,'imgs') || isempty(param.analysis.imgs)
  param.analysis.imgs = {[1 1]};
end
if ~isfield(param.collate_burst_noise,'imgs') || isempty(param.collate_burst_noise.imgs)
  param.collate_burst_noise.imgs = 1:length(param.analysis.imgs);
end

if ~isfield(param.collate_burst_noise,'cmd_idx') || isempty(param.collate_burst_noise.cmd_idx)
  param.collate_burst_noise.cmd_idx = 1;
end

if ~isfield(param.collate_burst_noise,'bit_mask') || isempty(param.collate_burst_noise.bit_mask)
  % These are the records.bit_mask bits that will be set by collate_burst_noise
  param.collate_burst_noise.bit_mask = 4;
end

if ~isfield(param.collate_burst_noise,'bit_mask_clear') || isempty(param.collate_burst_noise.bit_mask_clear)
  % These are the records.bit_mask bits that will be cleared/reset by collate_burst_noise
  param.collate_burst_noise.bit_mask_clear = 12;
end

if ~isfield(param.collate_burst_noise,'debug_plots')
  param.collate_burst_noise.debug_plots = {'bn_plot'};
end
enable_visible_plot = any(strcmp('visible',param.collate_burst_noise.debug_plots));
enable_bn_plot = any(strcmp('bn_plot',param.collate_burst_noise.debug_plots));
if ~isempty(param.collate_burst_noise.debug_plots)
  h_fig = get_figures(3,enable_visible_plot);
end

if ~isfield(param.collate_burst_noise,'debug_max_plot_size') || isempty(param.collate_burst_noise.debug_max_plot_size)
  param.collate_burst_noise.debug_max_plot_size = 50e6;
end

if ~isfield(param.(mfilename),'debug_out_dir') || isempty(param.(mfilename).debug_out_dir)
  param.(mfilename).debug_out_dir = mfilename;
end
debug_out_dir = param.(mfilename).debug_out_dir;

if ~isfield(param.collate_burst_noise,'filt_length') || isempty(param.collate_burst_noise.filt_length)
  param.collate_burst_noise.filt_length = 1;
end

if ~isfield(param.collate_burst_noise,'filt_threshold') || isempty(param.collate_burst_noise.filt_threshold)
  param.collate_burst_noise.filt_threshold = 0.5;
end

if ~isfield(param.collate_burst_noise,'in_path') || isempty(param.collate_burst_noise.in_path)
  param.collate_burst_noise.in_path = 'analysis';
end

if ~isfield(param.collate_burst_noise,'max_bad_waveforms') || isempty(param.collate_burst_noise.max_bad_waveforms)
  param.collate_burst_noise.max_bad_waveforms = 1;
end

if ~isfield(param.collate_burst_noise,'out_path') || isempty(param.collate_burst_noise.out_path)
  param.collate_burst_noise.out_path = param.collate_burst_noise.in_path;
end

if ~isfield(param.collate_burst_noise,'test_wf_adcs') || isempty(param.collate_burst_noise.test_wf_adcs)
  param.collate_burst_noise.test_wf_adcs = [];
end

if ~isfield(param.collate_burst_noise,'threshold_fh') || isempty(param.collate_burst_noise.threshold_fh)
  for img = 1:max(param.collate_burst_noise.imgs)
    param.collate_burst_noise.threshold_fh{img} = [];
  end
end

if ~isfield(param.collate_burst_noise,'wf_adcs') || isempty(param.collate_burst_noise.wf_adcs)
  param.collate_burst_noise.wf_adcs = {};
end
if ~isempty(param.collate_burst_noise.wf_adcs) && ~iscell(param.collate_burst_noise.wf_adcs)
  wf_adcs = param.collate_burst_noise.wf_adcs;
  param.collate_burst_noise.wf_adcs = {};
  for img = 1:max(param.collate_burst_noise.imgs)
    param.collate_burst_noise.wf_adcs{img} = wf_adcs;
  end
end

records = records_load(param);
new_bit_mask = zeros(size(records.bit_mask));
[~,frm_id,~] = get_frame_id(param,records.gps_time);

for img = param.collate_burst_noise.imgs
  
  if isempty(param.collate_burst_noise.wf_adcs)
    wf_adcs = 1:size(param.analysis.imgs{img},1);
  else
    wf_adcs = param.collate_burst_noise.wf_adcs{img};
  end
  for wf_adc = wf_adcs
    wf = param.analysis.imgs{img}(wf_adc,1);
    adc = param.analysis.imgs{img}(wf_adc,2);
    fprintf('Processing wf %d adc %d\t%s\n', wf, adc, datestr(now,'yyyymmdd_HHMMSS'));
    
    % Determine the boards for this wf-adc pair, find the time axis
    param.load.imgs = {[wf adc]};
    [wfs,states] = data_load_wfs(param, records);
    
    %% Load the burst noise file
    % ===================================================================
    % For the detection of burst noise in a particular wf-adc channel, any
    % number of wf-adc channels can be loaded, but the default is to just
    % load the wf-adc channel in question
    if isempty(param.collate_burst_noise.test_wf_adcs) ...
      || length(param.collate_burst_noise.test_wf_adcs) < img ...
      || isempty(param.collate_burst_noise.test_wf_adcs{img}) ...
      || length(param.collate_burst_noise.test_wf_adcs{img}) < wf_adc ...
      || isempty(param.collate_burst_noise.test_wf_adcs{img}{wf_adc})
      param.collate_burst_noise.test_wf_adcs{img}{wf_adc} = [wf adc];
    end
    % Load each of the wf-adc channels that are to be loaded to detect
    % noise in the current wf-adc channel.
    noise = cell(size(param.collate_burst_noise.test_wf_adcs{img}{wf_adc},1),1);
    for tmp_wf_adc = 1:size(param.collate_burst_noise.test_wf_adcs{img}{wf_adc},1)
      tmp_wf = param.collate_burst_noise.test_wf_adcs{img}{wf_adc}(tmp_wf_adc,1);
      tmp_adc = param.collate_burst_noise.test_wf_adcs{img}{wf_adc}(tmp_wf_adc,2);
      fn_dir = fileparts(ct_filename_out(param,param.collate_burst_noise.in_path));
      fn = fullfile(fn_dir,sprintf('burst_noise_%s_wf_%d_adc_%d.mat', param.day_seg, tmp_wf, tmp_adc));
      fprintf('Loading %s (%s)\n', fn, datestr(now));
      noise{tmp_wf_adc} = load(fn);
    end
    cmd = noise{1}.param_analysis.analysis.cmd{param.collate_burst_noise.cmd_idx};
    
    % Optionally update bad_recs field
    if ~isempty(param.collate_burst_noise.threshold_fh{img})
      bad_recs = find(param.collate_burst_noise.threshold_fh{img}{wf_adc}(noise,wfs));
    else
      bad_recs = noise{1}.bad_recs;
    end
    
    % noise.bad_recs: a list of all the bad records for each burst noise
    % event, there will be multiple entries for a record if there are
    % multiple burst noise events in that record
    bad_recs_unique = unique(bad_recs);
    
    % Optional along-track filtering to handle missed detections and false
    % alarms when there are groups of burst noise
    if param.collate_burst_noise.filt_length > 1
      % Create a mask of all the bad records
      bad_recs_unique_filt = zeros(1,size(records.bit_mask,2));
      bad_recs_unique_filt(bad_recs_unique) = 1;
      % Filter the mask with a boxcar filter and then threshold the output
      bad_recs_unique_filt = fir_dec(bad_recs_unique_filt,ones(1,param.collate_burst_noise.filt_length),1) ...
        > param.collate_burst_noise.filt_length*param.collate_burst_noise.filt_threshold;
      % Store the new filtered result back into bad_recs_unique
      bad_recs_unique = find(bad_recs_unique_filt);
    end
    
    % Force all wf-adc pairs to be considered bad
    if bitand(param.collate_burst_noise.bit_mask,8)
          
      % Add the specific section to be blanked out
      % -------------------------------------------------------------------
      % burst_noise_table is a 3xNb table where Nb is the number of burst
      % noise detections. Each column corresponds to one burst.
      %
      % burst_noise_table(1,:): The record that the burst occurs in.
      %
      % burst_noise_table(2,:): The start time of the burst
      %
      % burst_noise_table(3,:): The stop of the burst
      if 0
        burst_noise_table = zeros(3,length(bad_recs_unique));
      else
        burst_noise_table = zeros(3,0);
      end
      for col = 1:length(bad_recs_unique)
        fasttime0 = -inf;
        fasttime1 = inf;
        if ~isempty(noise{1}.bad_bins)
          mask = noise{1}.bad_recs == bad_recs_unique(col);
          if 0
            % Combine all burst detections into one and mask out everything
            % from the first detection bin to the last detection bin.
            fasttime0 = wfs(wf).time_raw(min(noise{1}.bad_bins(mask)));
            fasttime1 = wfs(wf).time_raw(max(noise{1}.bad_bins(mask)));
            burst_noise_table(:,col) = [bad_recs_unique(col) fasttime0 fasttime1].';
          else
            % Parse detections into individual events
            bad_bins = noise{1}.bad_bins(mask);
            while ~isempty(bad_bins)
              cur_bad_bin = bad_bins(1);
              fasttime0 = wfs(wf).time_raw(cur_bad_bin);
              bad_bins = bad_bins(2:end);
              while ~isempty(bad_bins) && bad_bins(1) == cur_bad_bin + 1
                cur_bad_bin = bad_bins(1);
                bad_bins = bad_bins(2:end);
              end
              fasttime1 = wfs(wf).time_raw(cur_bad_bin);
              burst_noise_table(:,end+1) = [bad_recs_unique(col) fasttime0 fasttime1].';
            end
          end
        end
      end
      
    else
      % Sub-rangeline/bin specific burst noise not being used so
      % burst_noise_table is empty
      burst_noise_table = [];
    end
    
    % Combine all boards: Some wf-adc pairs result in multiple waveforms
    % being loaded (e.g. for IQ on transmit or separate IQ channels or
    % zero-pi mod sequences that are stored separately)
    boards = cell2mat({states.board_idx});
    
    % Set bits (usually bit 2 (value 4) or bit 3 (value 8)) to true for the bad records
    new_bit_mask(boards,bad_recs_unique) = bitor(param.collate_burst_noise.bit_mask,new_bit_mask(boards,bad_recs_unique));
    
    %% Plot
    % =====================================================================
    if enable_bn_plot
      %% Plot: Figure 1
      clf(h_fig(1));
      set(h_fig(1), 'name', 'burst_noise rec-bin');
      h_axes(1) = axes('parent',h_fig(1));
      % Unfiltered bad samples/records
      if isempty(noise{1}.bad_bins)
        plot(noise{1}.bad_recs, ones(size(noise{1}.bad_recs)), 'bx', 'parent', h_axes(1));
      else
        plot(noise{1}.bad_recs, noise{1}.bad_bins, 'bx', 'parent', h_axes(1));
      end
      % Filtered bad records
      hold(h_axes(1),'on');
      bad_recs_mask = zeros(size(records.gps_time));
      bad_recs_mask(bad_recs_unique) = 1;
      plot(bad_recs_mask, 'r-', 'parent', h_axes(1));
      title(h_axes(1), sprintf('%s wf %d adc %d',regexprep(param.day_seg,'_','\\_'), wf, adc));
      xlabel(h_axes(1), 'Record');
      ylabel(h_axes(1), 'Range bin');
      
      fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('burst_rec_bin_wf_%02d_adc_%02d',wf,adc)) '.jpg'];
      fprintf('Saving %s %s\n', datestr(now), fig_fn);
      fig_fn_dir = fileparts(fig_fn);
      if ~exist(fig_fn_dir,'dir')
        mkdir(fig_fn_dir);
      end
      ct_saveas(h_fig(1),fig_fn);
      if 2*ct_whos(noise{1}.bad_bins) < param.collate_burst_noise.debug_max_plot_size
        fig_fn(end-2:end) = 'fig';
        fprintf('Saving %s %s\n', datestr(now), fig_fn);
        ct_saveas(h_fig(1),fig_fn);
      end
      
      %% Plot: Figure 2
      clf(h_fig(2));
      set(h_fig(2), 'name', 'burst_noise waveforms');
      h_axes(2) = axes('parent',h_fig(2));
      for block_idx = 1:length(noise{1}.bad_waveforms)
        num_bad_waveforms = size(noise{1}.bad_waveforms{block_idx},2);
        plot(lp(noise{1}.bad_waveforms{block_idx}(:,1:min(param.collate_burst_noise.max_bad_waveforms,num_bad_waveforms))), 'parent', h_axes(2));
        hold(h_axes(2),'on');
      end
      title(h_axes(2), sprintf('%s wf %d adc %d',regexprep(param.day_seg,'_','\\_'), wf, adc));
      xlabel(h_axes(2), 'Range bin');
      ylabel(h_axes(2), 'Relative power (dB)');
      
      fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('burst_waveform_wf_%02d_adc_%02d',wf,adc)) '.jpg'];
      fprintf('Saving %s %s\n', datestr(now), fig_fn);
      fig_fn_dir = fileparts(fig_fn);
      if ~exist(fig_fn_dir,'dir')
        mkdir(fig_fn_dir);
      end
      ct_saveas(h_fig(2),fig_fn);
      if ct_whos(noise{1}.bad_waveforms) < param.collate_burst_noise.debug_max_plot_size
        fig_fn(end-2:end) = 'fig';
        fprintf('Saving %s %s\n', datestr(now), fig_fn);
        ct_saveas(h_fig(2),fig_fn);
      end
      
      %% Plot: Figure 3 and 4
      if ~isempty(noise{1}.test_metric)
        clf(h_fig(3));
        set(h_fig(3), 'name', 'burst_noise test_metric');
        h_axes(3) = subplot(2,1,1,'parent',h_fig(3));
        plot(noise{1}.test_metric, '.-', 'parent', h_axes(3));
        grid(h_axes(3),'on');
        title(h_axes(3), sprintf('%s wf %d adc %d',regexprep(param.day_seg,'_','\\_'), wf, adc));
        xlabel(h_axes(3), 'Record');
        ylabel(h_axes(3), 'test_metric output', 'interpreter','none');
        h_axes(4) = subplot(2,1,2,'parent',h_fig(3));
        if length(noise{1}.bad_recs) == length(noise{1}.test_metric)
          plot(frm_id(noise{1}.bad_recs), noise{1}.test_metric, '.-', 'parent', h_axes(4));
        else
          plot(frm_id, noise{1}.test_metric, '.-', 'parent', h_axes(4));
        end
        grid(h_axes(4),'on');
        xlabel(h_axes(4), 'Frame');
        ylabel(h_axes(4), 'test_metric output', 'interpreter','none');
        linkaxes(h_axes([1 3]),'x');
        axis(h_axes([3 4]),'tight');
        
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('burst_test_metric_wf_%02d_adc_%02d',wf,adc)) '.jpg'];
        fprintf('Saving %s %s\n', datestr(now), fig_fn);
        fig_fn_dir = fileparts(fig_fn);
        if ~exist(fig_fn_dir,'dir')
          mkdir(fig_fn_dir);
        end
        ct_saveas(h_fig(3),fig_fn);
        fig_fn(end-2:end) = 'fig';
        fprintf('Saving %s %s\n', datestr(now), fig_fn);
        ct_saveas(h_fig(3),fig_fn);
      end
    end
    
    if enable_visible_plot && ~isempty(bad_recs_unique)
      % Bring plots to front
      for h_fig_idx = 1:length(h_fig)
        figure(h_fig(h_fig_idx));
      end
      % Enter debug mode
      keyboard
    end

    if ~isempty(burst_noise_table)
      %% Save the result
      % =====================================================================
      out_fn_dir = fileparts(ct_filename_out(param,param.collate_burst_noise.out_path, ''));
      out_fn = fullfile(out_fn_dir,sprintf('burst_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
      fprintf('Saving %s (%s)\n', out_fn, datestr(now));
      ct_save(out_fn,'burst_noise_table');
    end
  end
end

%% Update records file
records.bit_mask = records.bit_mask - bitand(param.collate_burst_noise.bit_mask_clear,records.bit_mask) + uint8(new_bit_mask);
records_fn = ct_filename_support(param,'','records');
fprintf('Saving %s %s\n', datestr(now), records_fn);
ct_save(records_fn,'-append','-struct','records','bit_mask');

if ~enable_visible_plot
  try
    delete(h_fig);
  end
end
