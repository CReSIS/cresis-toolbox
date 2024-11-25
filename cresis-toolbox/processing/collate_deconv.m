function collate_deconv(param,param_override)
% collate_deconv(param,param_override)
%
% This scripts takes the results from analysis cmd spectral
% and creates deconvolution waveforms from spectral targets. The spectral
% analysis has actually already created the deconv_H filter and this
% function groups these filters together using correlation statistics,
% finds the best one for each twtt, and then stores these best waveforms
% into a file. This is done per segment, but if a segment does not have
% any spectral targets for a particular twtt bin, waveforms from other
% days are used.
%
% Sections:
% 1. Debug section for visualizing results
% 2. Stage 1: Remove bad waveforms, group good ones based on statistical
%    similarity (but require that groups are contiguous in time). Also
%    put each waveform into an altitude bin.
% 3. Stage 2: Often segments will not have a good deconvolution waveform
%    for all twtt bins. This stage grabs good deconv waveforms from
%    neighboring segments to fill in for the missing twtts.
%
% Problems/Short-comings:
% 1. The same deconvolution waveform is used for the entire segment.
%    This means that falling edge sidelobes from internal reflections
%    tend to not be suppressed well.
% 2. Current application of deconvolution waveform assumes the surface
%    is at 0 m elevation (i.e. so that the surface does not have to be
%    tracked). This works okay for sea ice, but will not work for land ice.
%    This weakness is in load_fmcw_data.m and not this script
%    (coh_noise_tracker_task does track the surface for the twtt estimate).
% 3. ONLY WORKS ON SEA ICE WHERE SPECULAR TARGETS ARE COMMON
%
% Example:
%  See run_collate_deconv.m to run.
%
% Author: Jilu Li, John Paden

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

physical_constants;

%% Input checks
% =====================================================================

if ~isfield(param.collate_deconv,'cmd_idx') || isempty(param.collate_deconv.cmd_idx)
  param.collate_deconv.cmd_idx = 1;
end
cmd = param.analysis.cmd{param.collate_deconv.cmd_idx};
[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

% analysis structure
% =========================================================================

if ~isfield(param.analysis,'imgs') || isempty(param.analysis.imgs)
  param.analysis.imgs = {[1 1]};
end
if ~isfield(param.collate_deconv,'imgs') || isempty(param.collate_deconv.imgs)
  param.collate_deconv.imgs = 1:length(param.analysis.imgs);
end

% param.collate_deconv structure
% =========================================================================

if ~isfield(param.collate_deconv,'abs_metric') || isempty(param.collate_deconv.abs_metric)
  param.collate_deconv.abs_metric = [58 5 -25 -35 inf inf];
end

% param.collate_deconv.bad_gps_times: specify ranges of gps-times to
% exclude. Nrng by 2 numeric matrix. Nrng is the number of ranges to
% exclude. The first column is the start time of the range and the second
% column is the end time of the range. bad_gps_times has no effect on
% waveforms that are selected via gps_times.
if ~isfield(param.collate_deconv,'bad_gps_times') || isempty(param.collate_deconv.bad_gps_times)
  param.collate_deconv.bad_gps_times = [];
end

if ~isfield(param.collate_deconv,'day_segs') || isempty(param.collate_deconv.day_segs)
  % Default is to use this day_seg only to find deconvolution waveforms
  param.collate_deconv.day_segs = {param.day_seg};
end

if ~isfield(param.collate_deconv,'debug_out_dir') || isempty(param.collate_deconv.debug_out_dir)
  param.collate_deconv.debug_out_dir = mfilename;
end
debug_out_dir = param.collate_deconv.debug_out_dir;

if ~isfield(param.collate_deconv,'debug_plots')
  param.collate_deconv.debug_plots = {'peakiness','metric','final','visible'};
  %param.collate_deconv.debug_plots = {'peakiness','rbins','deconv','metric','final','visible'};
end

if ~isfield(param.collate_deconv,'debug_rlines') || isempty(param.collate_deconv.debug_rlines)
  param.collate_deconv.debug_rlines = [];
end

if ~isfield(param.collate_deconv,'debug_ylim') || isempty(param.collate_deconv.debug_ylim)
  param.collate_deconv.debug_ylim = 120;
end
debug_ylim = param.collate_deconv.debug_ylim;

% decimate_table_sec: decimation spacing in seconds (default 10 sec), an entry
% in the deconvolution waveform mapping will be made every decimate_table_sec
% seconds.
if ~isfield(param.collate_deconv,'decimate_table_sec') || isempty(param.collate_deconv.decimate_table_sec)
  param.collate_deconv.decimate_table_sec = 10;
end

if ~isfield(param.collate_deconv,'f0') || isempty(param.collate_deconv.f0)
  % Default is no limits on lower frequency
  param.collate_deconv.f0 = -inf;
end

if ~isfield(param.collate_deconv,'f1') || isempty(param.collate_deconv.f1)
  % Default is no limits on upper frequency
  param.collate_deconv.f1 = inf;
end

if ~isfield(param.collate_deconv,'gps_time_penalty') || isempty(param.collate_deconv.gps_time_penalty)
  param.collate_deconv.gps_time_penalty = 1/(10*24*3600);
end

% gps_times is a Ngt by 3 matrix where the number of rows, Ngt, is the
% number of gps times to specifically consider in the final deconvolution
% mapping. If gps_times is empty (Ngt == 0), then all waveforms are
% considered. The first column specifies the GPS time of the deconvolution
% waveform to use (the deconvolution waveform closest to this GPS time will
% be used), the second column and third column specify the range of GPS
% times that this waveform will be considered for. To consider a waveform
% for all times then the 2nd and 3rd columns should be -inf and +inf
% respectively.
if ~isfield(param.collate_deconv,'gps_times') || isempty(param.collate_deconv.gps_times)
  param.collate_deconv.gps_times = [];
end

if ~isfield(param.collate_deconv,'imgs') || isempty(param.collate_deconv.imgs)
  param.collate_deconv.imgs = 1:length(param.analysis.imgs);
end

if ~isfield(param.collate_deconv,'in_path') || isempty(param.collate_deconv.in_path)
  param.collate_deconv.in_path = 'analysis';
end

if ~isfield(param.collate_deconv,'magnitude_only') || isempty(param.collate_deconv.magnitude_only)
  param.collate_deconv.magnitude_only = [];
end

if ~isfield(param.collate_deconv.magnitude_only,'en') || isempty(param.collate_deconv.magnitude_only.en)
  param.collate_deconv.magnitude_only.en = false;
end

if ~isfield(param.collate_deconv.magnitude_only,'f_cutoff') || isempty(param.collate_deconv.magnitude_only.f_cutoff)
  param.collate_deconv.magnitude_only.f_cutoff = 0.1;
end

% metric_mode: scalar integer or a string containing one of three allowed
% strings:
% * "each" means that the deconvolution will be done for each sample with
% the averaged sample waveform itself (DEFAULT mode)
% * "best" means that the deconvolution will be done by the waveform with
% the best score (requires stage one to have been run)
% * "final" means that the deconvolution will be done with the waveform
% determined in the final deconvolution file (requires stage two to have
% been run)
% * integer: scalar integer which determines the index of he waveform that
% will be used for the deconvolution
if ~isfield(param.collate_deconv,'metric_mode') || isempty(param.collate_deconv.metric_mode)
  param.collate_deconv.metric_mode = 'each';
end

if ~isfield(param.collate_deconv,'metric_weights') || isempty(param.collate_deconv.metric_weights)
  param.collate_deconv.metric_weights = [0.5 0 3 5 0 0];
end
error_mask = isinf(param.collate_deconv.abs_metric) & param.collate_deconv.metric_weights ~= 0;
if any(error_mask)
  warning('Fields set to inf in abs_metric must be set to 0 in metric_weights. Setting these to 0 now.');
  param.collate_deconv.metric_weights(error_mask) = 0;
end

if ~isfield(param.collate_deconv,'min_score') || isempty(param.collate_deconv.min_score)
  param.collate_deconv.min_score = -10;
end

if ~isfield(param.collate_deconv,'ML_threshold') || isempty(param.collate_deconv.ML_threshold)
  param.collate_deconv.ML_threshold = 15;
end

if ~isfield(param.collate_deconv,'Mt') || isempty(param.collate_deconv.Mt)
  param.collate_deconv.Mt = 10;
end
Mt = param.collate_deconv.Mt;

if ~isfield(param.collate_deconv,'out_path') || isempty(param.collate_deconv.out_path)
  param.collate_deconv.out_path = param.collate_deconv.in_path;
end

if ~isfield(param.collate_deconv,'preserve_old') || isempty(param.collate_deconv.preserve_old)
  param.collate_deconv.preserve_old = false;
end

if  ~isfield(param.collate_deconv,'rbins') || isempty(param.collate_deconv.rbins)
  warning('The "rbins" field should be set in the param.collate_deconv to a range of indices about the peak to use in the deconvolution waveform, e.g. param.collate_deconv.rbins = {[-200 150]} to use 200 bins before the peak and 150 bins after the peak for image 1. rbins should be a cell array with each element corresponding to the param.collate_deconv.imgs array. Using default settings [-200 150] now which may not work for this radar data.');
  for img = 1:length(param.analysis.imgs)
    param.collate_deconv.rbins{img} = [-200 150];
  end
end
if ~iscell(param.collate_deconv.rbins)
  error('collate_deconv.rbins should be a cell array with an entry for each image. E.g. {[-200 150],[-200 150]}.');
end

if ~isfield(param.collate_deconv,'rec_adjustments') || isempty(param.collate_deconv.rec_adjustments)
  for img = 1:length(param.analysis.imgs)
    param.collate_deconv.rec_adjustments{img} = [];
  end
end

if ~isfield(param.collate_deconv,'SL_guard_bins') || isempty(param.collate_deconv.SL_guard_bins)
  param.collate_deconv.SL_guard_bins = 3;
end

if ~isfield(param.collate_deconv,'stage_one_en') || isempty(param.collate_deconv.stage_one_en)
  param.collate_deconv.stage_one_en = true;
end

if ~isfield(param.collate_deconv,'stage_two_en') || isempty(param.collate_deconv.stage_two_en)
  param.collate_deconv.stage_two_en = true;
end

if ~isfield(param.collate_deconv,'surf_layer') || isempty(param.collate_deconv.surf_layer)
  param.collate_deconv.surf_layer.name = 'surface';
  param.collate_deconv.surf_layer.source = 'layerdata';
end

if ~isfield(param.collate_deconv,'threshold') || isempty(param.collate_deconv.threshold)
  param.collate_deconv.threshold = -inf;
end

% twtt_penalty: This is generally not relevant for non-deramp systems since
% the twtt should not affect the impulse response. However, for deramp
% systems and the way that pulse compression and deskew are done, the twtt
% affects the impulse reponse since sidelobes are affected by the relative
% time displacement between the imperfect reference-deramp and imperfect RF
% signal.
if ~isfield(param.collate_deconv,'twtt_penalty') || isempty(param.collate_deconv.twtt_penalty)
  if strcmpi(radar_type,'deramp')
    param.collate_deconv.twtt_penalty = 1e6;
  else
    % No twtt dependence
    param.collate_deconv.twtt_penalty = 1e-6;
  end
end

if ~isfield(param.collate_deconv,'wf_adcs') || isempty(param.collate_deconv.wf_adcs)
  param.collate_deconv.wf_adcs = [];
end

% Other Setup
% =========================================================================
if ~isempty(param.collate_deconv.debug_plots)
  h_fig = get_figures(4,any(strcmp('visible',param.collate_deconv.debug_plots)));
end

%% Stage 1
% =========================================================================
% Loads all the specular_* files and creates deconv_tmp_* files that have the
% poorly performing deconvolution waveforms removed and the good ones
% grouped and averaged.
% Outputs:
%  deconv.gps_time: gps-time of the impulse reponse, 1 by Nx
%  deconv.lat = 1 by Nx vector containing the latitude of this response
%  deconv.lon = 1 by Nx vector containing the longitude of this response
%  deconv.elev = 1 by Nx vector containing the elevation of this response
%  deconv.roll = 1 by Nx vector containing the roll of this response
%  deconv.pitch = 1 by Nx vector containing the pitch of this response
%  deconv.heading = 1 by Nx vector containing the heading of this response
%  deconv.frm: frame containing impulse response, 1 by Nx
%  deconv.rec: record containing impulse response, 1 by Nx
%  deconv.ref_windowed: logical indicating if reference impulse responses
%    are windowed
%  deconv.ref_window: reference window function handle
%  deconv.ref_nonnegative: impulse responses for non-negative time, Nt_nonneg by Nx
%  deconv.ref_negative: impulse responses for negative time, Nt_neg by Nx
%  deconv.ref_mult_factor: multiplication factor for deconv wf, 1 by Nx
%  deconv.impulse_reponse: deconvolved impulse reponse: Nt by Nx
%  deconv.metric: metrics for each impulse response: 6 by Nx
%  deconv.peakiness: peakiness score of each response: 1 by Nx
%  deconv.fc: center frequency (Hz): 1 by Nx
%  deconv.dt: fast-time sample spacing (sec)
%  deconv.twtt = 1 by Nx vector containing the exact TWTT of this response
%  deconv.twtt_min = 1 by Nx vector containing the minimum TWTT
%      bin that this impulse response should be used for; deramp only.
%  deconv.twtt_max = 1 by Nx vector with max TWTT bin; deramp only.
%  deconv.param_collate_deconv = parameter structure during call to collate_deconv.
%  deconv.param_analysis = parameter structure during call to analysis.
%  deconv.param_records = parameter structure during call to create records.
% =========================================================================

if param.collate_deconv.stage_one_en
  for img = param.collate_deconv.imgs
    
    if isempty(param.collate_deconv.wf_adcs)
      % If no wf-adc pairs specified, then do them all.
      wf_adcs = 1:size(param.analysis.imgs{img},1);
    else
      wf_adcs = param.collate_deconv.wf_adcs{img};
    end
    for wf_adc = wf_adcs
      %% Stage 1: Load specular analysis file
      % ===================================================================
      wf = param.analysis.imgs{img}(wf_adc,1);
      adc = param.analysis.imgs{img}(wf_adc,2);
      
      % spec: Load specular file from analysis specular outputs
      fn_dir = fileparts(ct_filename_out(param,param.collate_deconv.in_path, ''));
      fn = fullfile(fn_dir,sprintf('specular_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
      fprintf('Loading %s img %d wf %d adc %d\n  %s\n', param.day_seg, img, wf, adc, fn);
      spec = load(fn);
      [~,spec.frm,spec.rec] = get_frame_id(param,spec.gps_time);
      fprintf('  File contains %d waveforms\n', length(spec.deconv_gps_time));
      
      if any(strcmp('peakiness',param.collate_deconv.debug_plots))
        % Plot peakiness
        clf(h_fig(1));
        set(h_fig(1),'Name',['Peakiness ' param.day_seg]);
        h_axes = subplot(2,1,1,'parent',h_fig(1));
        plot(h_axes(1), spec.frm, spec.peakiness,'x');
        xlabel(h_axes(1), 'Frame');
        ylabel(h_axes(1), 'Peakiness (higher is better)');
        title(h_axes(1), regexprep(param.day_seg,'_','\\_'));
        grid(h_axes(1), 'on');
        
        h_axes(2) = subplot(2,1,2,'parent',h_fig(1));
        plot(h_axes(2), spec.rec, spec.peakiness,'x');
        xlabel(h_axes(2), 'Record');
        ylabel(h_axes(2), 'Peakiness (higher is better)');
        grid(h_axes(2), 'on');
        
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_peakiness_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.fig'];
        fprintf('Saving %s\n', fig_fn);
        fig_fn_dir = fileparts(fig_fn);
        if ~exist(fig_fn_dir,'dir')
          mkdir(fig_fn_dir);
        end
        ct_saveas(h_fig(1),fig_fn);
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_peakiness_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.jpg'];
        fprintf('Saving %s\n', fig_fn);
        ct_saveas(h_fig(1),fig_fn);
        
        if any(strcmp('visible',param.collate_deconv.debug_plots))
          keyboard
        end
      end
      
      if isempty(spec.deconv_gps_time)
        warning('No specular waveforms found.');
        continue;
      end
      
      % Load surface layer
      layer = opsLoadLayers(param,param.collate_deconv.surf_layer);
      spec.surface = interp_finite(interp1(layer.gps_time, layer.twtt, spec.gps_time));
      spec.deconv_twtt = interp_finite(interp1(layer.gps_time, layer.twtt, spec.deconv_gps_time));
      
      %% Stage 1: Preallocation
      deconv = [];
      deconv.gps_time = [];
      deconv.lat = [];
      deconv.lon = [];
      deconv.elev = [];
      deconv.roll = [];
      deconv.pitch = [];
      deconv.heading = [];
      [~,deconv.frm,deconv.rec] = get_frame_id(param,spec.deconv_gps_time);
      if ~isempty(spec.param_analysis.radar.wfs(wf).ft_wind)
        deconv.ref_windowed = true;
        deconv.ref_window = spec.param_analysis.radar.wfs(wf).ft_wind;
      else
        error('collate_deconv requires a window to have been used.');
      end
      deconv.ref_nonnegative = [];
      deconv.ref_negative = [];
      deconv.ref_mult_factor = [];
      deconv.impulse_response = {};
      deconv.metric = [];
      deconv.peakiness = [];
      deconv.fc = [];
      deconv.dt = spec.dt;
      deconv.twtt = spec.deconv_twtt;
      %param.analysis.cmd{param.collate_deconv.cmd_idx} = cmd;
      cmd = spec.param_analysis.analysis.cmd{param.collate_deconv.cmd_idx};
      deconv.param_collate_deconv = param;
      deconv.param_analysis = spec.param_analysis;
      deconv.param_records = spec.param_records;
      if param.ct_file_lock
        deconv.file_version = '1L';
      else
        deconv.file_version = '1';
      end
      
      % Handle the case where no specular targets were found
      % ===================================================================
      if size(spec.deconv_mean,2) == 0
        warning('This segment has no deconvolution waveforms');
        continue;
      end
      
      % Load best and final metric_mode information
      % ===================================================================
      if strcmpi(param.collate_deconv.metric_mode,'best')
        out_fn = fullfile(fn_dir,sprintf('deconv_lib_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
        if ~exist(out_fn,'file')
          error('param.collate_deconv.metric_mode == "best" except there is no deconv_lib file. Run stage one first with metric_mode set to "each".');
        end
        fprintf('  Loading best deconv info in %s\n', out_fn);
        best_deconv = load(out_fn,'metric','rec');
        
        % Compute the score
        best_score = nansum(bsxfun(@times, param.collate_deconv.metric_weights(:), bsxfun(@minus, param.collate_deconv.abs_metric(:), best_deconv.metric)));
        best_score(:,any(isnan(best_deconv.metric))) = -inf;

        % Make score adjustments for param.collate_deconv.rec_adjustments
        for rec_idx = 1:size(param.collate_deconv.rec_adjustments{img},1)
          [rec_offset,score_idx] = min(abs(best_deconv.rec-param.collate_deconv.rec_adjustments{img}(rec_idx,1)));
          if rec_offset > cmd.rlines
            warning('Record offset to closest waveform to rec_adjustments{%d}(%d,1) is larger than the STFT interval used in analysis spec. This may mean that the record in rec_adjustments{%d}(%d,1) is incorrect.',img,rec_idx,img,rec_idx);
          else
            score(score_idx) = score(score_idx) + param.collate_deconv.rec_adjustments{img}(rec_idx,2);
          end
        end

        [~,best_rline] = max(best_score);
        clear best_deconv best_score;
        
      elseif strcmpi(param.collate_deconv.metric_mode,'final')
        out_fn = fullfile(fn_dir,sprintf('deconv_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
        if ~exist(out_fn,'file')
          error('param.collate_deconv.metric_mode == "final" except there is no deconv file. Run stage two first.');
        end
        fprintf('  Loading final deconv info in %s\n', out_fn);
        final_deconv = load(out_fn);
      end

      % Stage 1: Loop to analyze each waveform
      % ===================================================================
      for rline = 1:length(spec.deconv_gps_time)
        
        %% Stage 1: Impulse response
        
        if interp1(spec.gps_time,spec.peakiness,spec.deconv_gps_time(rline)) < param.collate_deconv.threshold ...
          || isnan(spec.deconv_fc(rline)) || isnan(spec.deconv_t0(rline)) || isnan(spec.dt)
          % Waveform peakiness is too low OR NaN in deconv_fc or dt
          deconv.metric(:,rline) = nan(6,1);
          [~,match_idx] = min(abs(spec.gps_time - spec.deconv_gps_time(rline)));
          deconv.gps_time(rline) = spec.gps_time(match_idx);
          deconv.lat(rline) = spec.lat(match_idx);
          deconv.lon(rline) = spec.lon(match_idx);
          deconv.elev(rline) = spec.elev(match_idx);
          deconv.roll(rline) = spec.roll(match_idx);
          deconv.pitch(rline) = spec.pitch(match_idx);
          deconv.heading(rline) = spec.heading(match_idx);
          deconv.peakiness(rline) = spec.peakiness(match_idx);
          deconv.fc(rline) = spec.deconv_fc(rline);
          deconv.ref_nonnegative{rline} = [];
          deconv.ref_negative{rline} = [];
          deconv.ref_mult_factor(rline) = NaN;
          deconv.radiometric_error_dB(rline) = NaN;
          deconv.impulse_response{rline} = [];

          continue;
        end
        
        % Find peak of specular return
        radiometric_measured = max(lp(spec.deconv_sample{rline}));
        % Calculate the range R for debugging. Usually the specular
        % reflection is 0 dB (i.e. the specular target is a perfect
        % reflector) and we expect the voltage to be 1/R after corrections
        % are applied when loading data (e.g. system_dB, adc_gains_dB,
        % etc.).
        R = interp1(spec.gps_time,spec.surface,spec.deconv_gps_time(rline)) * c/2;
        % Assuming specular return is water with 0 dB reflection
        % coefficient and no roughness
        radiometric_expected = lp(1/R^2);
        deconv.radiometric_error_dB(rline) = radiometric_measured-radiometric_expected;
        
        if strcmpi(param.collate_deconv.metric_mode,'final')
          deconv_map_idx = interp1(final_deconv.map_gps_time,final_deconv.map_idxs,spec.deconv_gps_time(rline),'nearest','extrap');
          
          % Get the reference function
          h_nonnegative = final_deconv.ref_nonnegative{deconv_map_idx};
          h_negative = final_deconv.ref_negative{deconv_map_idx};
          
        else
          if strcmpi(param.collate_deconv.metric_mode,'each')
            % Use this range line to generate the metrics for this waveform.
            % h: impulse response
            h = spec.deconv_mean{rline};
          elseif strcmpi(param.collate_deconv.metric_mode,'best')
            % Use the best range line to generate the metrics for this
            % waveform.
            % h: impulse response
            h = spec.deconv_mean{best_rline};
          elseif isnumeric(param.collate_deconv.metric_mode)
            % Manually select the range line to use to generate the metrics
            % for this waveform.
            % h: impulse response
            h = spec.deconv_mean{param.collate_deconv.metric_mode};
          end
          
          % Time gate signal according to cmd.rlines
          Htg = tukeywin(param.collate_deconv.rbins{img}(end)*2+1,0.2);
          h_nonnegative = h(1:1+param.collate_deconv.rbins{img}(end)) .* Htg(end-param.collate_deconv.rbins{img}(end):end);
          Htg = tukeywin(-param.collate_deconv.rbins{img}(1)*2,0.2);
          h_negative = h(end+1+param.collate_deconv.rbins{img}(1):end) .* Htg(1:-param.collate_deconv.rbins{img}(1));
        end
        
        rbins_plot = any(strcmp('rbins',param.collate_deconv.debug_plots)) ...
            && (isempty(param.collate_deconv.debug_rlines) || any(rline==param.collate_deconv.debug_rlines));
        deconv_plot = any(strcmp('deconv',param.collate_deconv.debug_plots)) ...
            && (isempty(param.collate_deconv.debug_rlines) || any(rline==param.collate_deconv.debug_rlines));
        [h_mult_factor,h_deconvolved] = collate_deconv_ascope(param,spec,deconv,h_fig,img,wf_adc,h_nonnegative,h_negative,rline,rbins_plot,deconv_plot);        
        
        %% Stage 1: Metrics
        h_metric = abs(h_deconvolved).^2; % Convert to power
        [max_val,max_idx] = max(h_metric); % Find maximum value and index
        h_metric = circshift(h_metric,[-max_idx 1]); % Shift peak to first bin
        
        % Compute negated peak power
        peak = -max(lp(max_val,1));
        
        % Compute main lobe width
        main_lobe = 2;
        for bin = 2:param.collate_deconv.rbins{img}(2)*Mt
          if lp(h_metric(bin),1) < lp(max_val,1)-param.collate_deconv.ML_threshold
            break;
          end
          main_lobe = main_lobe + 1;
        end
        for bin = 0:-param.collate_deconv.rbins{img}(1)*Mt
          if lp(h_metric(end-bin),1) < lp(max_val,1)-param.collate_deconv.ML_threshold
            break;
          end
          main_lobe = main_lobe + 1;
        end
        main_lobe = main_lobe / Mt;
        
        % Compute falling edge peak sidelobe
        peak_sidelobe_falling_edge = -inf;
        for bin = round(param.collate_deconv.SL_guard_bins*Mt) : param.collate_deconv.rbins{img}(2)*Mt
          if lp(h_metric(bin),1) > peak_sidelobe_falling_edge
            peak_sidelobe_falling_edge = lp(h_metric(bin),1);
          end
        end
        peak_sidelobe_falling_edge = peak_sidelobe_falling_edge + peak;
        
        % Compute rising edge peak sidelobe
        peak_sidelobe_rising_edge = -inf;
        for bin = round(param.collate_deconv.SL_guard_bins*Mt)-1:-param.collate_deconv.rbins{img}(1)*Mt
          if lp(h_metric(end-bin),1) > peak_sidelobe_rising_edge
            peak_sidelobe_rising_edge = lp(h_metric(end-bin),1);
          end
        end
        peak_sidelobe_rising_edge = peak_sidelobe_rising_edge + peak;
        
        % Compute falling edge integrated sidelobe
        bins = round(param.collate_deconv.SL_guard_bins*Mt) : param.collate_deconv.rbins{img}(2)*Mt;
        integrated_sidelobe_falling_edge = sum(h_metric(bins))/Mt;
        integrated_sidelobe_falling_edge = lp(integrated_sidelobe_falling_edge,1);
        integrated_sidelobe_falling_edge = integrated_sidelobe_falling_edge + peak;
        
        % Compute falling edge integrated sidelobe
        bins = round(param.collate_deconv.SL_guard_bins*Mt)-1 : -param.collate_deconv.rbins{img}(1)*Mt;
        integrated_sidelobe_rising_edge = sum(h_metric(end-bins))/Mt;
        integrated_sidelobe_rising_edge = lp(integrated_sidelobe_rising_edge,1);
        integrated_sidelobe_rising_edge = integrated_sidelobe_rising_edge + peak;
        
        deconv.metric(:,rline) = [peak, main_lobe, peak_sidelobe_falling_edge, peak_sidelobe_rising_edge, ...
          integrated_sidelobe_falling_edge, integrated_sidelobe_rising_edge];
        
        %% Stage 1: Deconvolution for storage
        [~,match_idx] = min(abs(spec.gps_time - spec.deconv_gps_time(rline)));
        deconv.gps_time(rline) = spec.gps_time(match_idx);
        deconv.lat(rline) = spec.lat(match_idx);
        deconv.lon(rline) = spec.lon(match_idx);
        deconv.elev(rline) = spec.elev(match_idx);
        deconv.roll(rline) = spec.roll(match_idx);
        deconv.pitch(rline) = spec.pitch(match_idx);
        deconv.heading(rline) = spec.heading(match_idx);
        deconv.peakiness(rline) = spec.peakiness(match_idx);
        deconv.fc(rline) = spec.deconv_fc(rline);
        deconv.ref_nonnegative{rline} = h_nonnegative;
        deconv.ref_negative{rline} = h_negative;
        deconv.ref_mult_factor(rline) = h_mult_factor;
        deconv.impulse_response{rline} = h_deconvolved;
        
      end
      
      %% Stage 1: Plot metric
      if any(strcmp('metric',param.collate_deconv.debug_plots))
        % Compare results to metric
        pass = bsxfun(@lt,deconv.metric,param.collate_deconv.abs_metric(:));
        
        score = nansum(bsxfun(@times, param.collate_deconv.metric_weights(:), bsxfun(@minus, param.collate_deconv.abs_metric(:), deconv.metric)));
        score(:,any(isnan(deconv.metric))) = -inf;
        
        % Make score adjustments for param.collate_deconv.rec_adjustments
        for rec_idx = 1:size(param.collate_deconv.rec_adjustments{img},1)
          [rec_offset,score_idx] = min(abs(deconv.rec-param.collate_deconv.rec_adjustments{img}(rec_idx,1)));
          if rec_offset > cmd.rlines
            warning('Record offset to closest waveform to rec_adjustments{%d}(%d,1) is larger than the STFT interval used in analysis spec. This may mean that the record in rec_adjustments{%d}(%d,1) is incorrect.',img,rec_idx,img,rec_idx);
          else
            score(score_idx) = score(score_idx) + param.collate_deconv.rec_adjustments{img}(rec_idx,2);
          end
        end
        
        % Find the highest score in each bin
        twtts = unique(round(deconv.twtt*param.collate_deconv.twtt_penalty*10)/10/param.collate_deconv.twtt_penalty);
        
        max_score_rlines = zeros(size(twtts));
        for twtt_idx = 1:length(twtts)
          twtt = twtts(twtt_idx);
          twtt_idxs = find(abs(deconv.twtt-twtt) < 1/param.collate_deconv.twtt_penalty/10*2);
          [~,max_score_rlines(twtt_idx)] = max(score(twtt_idxs));
          max_score_rlines(twtt_idx) = twtt_idxs(max_score_rlines(twtt_idx));
        end
        
        % Plot metrics
        
        clf(h_fig(1));
        set(h_fig(1),'Name',['Passed Metric ' param.day_seg]);
        h_axes = axes('parent',h_fig(1));
        plot(h_axes(1), find(all(pass)), deconv.metric(1,all(pass)), '.-')
        hold(h_axes(1),'on');
        plot(h_axes(1), find(all(pass)), deconv.metric(2,all(pass)), '.-')
        plot(h_axes(1), find(all(pass)), deconv.metric(3,all(pass)), '.-')
        plot(h_axes(1), find(all(pass)), deconv.metric(4,all(pass)), '.-')
        plot(h_axes(1), find(all(pass)), deconv.metric(5,all(pass)), '.-')
        plot(h_axes(1), find(all(pass)), deconv.metric(6,all(pass)), '.-')
        xlabel(h_axes(1), 'Deconv waveform index');
        ylabel(h_axes(1), 'Metric (lower is better)');
        title(h_axes(1), [regexprep(param.day_seg,'_','\\_') ': passed']);
        legend(h_axes(1), 'P','ML','FSL','RSL','IFSL','IRSL','location','best');
        grid(h_axes(1), 'on');
        
        clf(h_fig(2));
        set(h_fig(2),'Name',['Metric ' param.day_seg]);
        h_axes(2) = axes('parent',h_fig(2));
        h_plot = plot(h_axes(2), deconv.metric(1,:));
        hold(h_axes(2),'on');
        h_plot(2) = plot(h_axes(2), deconv.metric(2,:));
        h_plot(3) = plot(h_axes(2), deconv.metric(3,:));
        h_plot(4) = plot(h_axes(2), deconv.metric(4,:));
        h_plot(5) = plot(h_axes(2), deconv.metric(5,:));
        h_plot(6) = plot(h_axes(2), deconv.metric(6,:));
        plot(h_axes(2), find(all(pass)), deconv.metric(1,all(pass)), '.','Color',get(h_plot(1),'Color'))
        plot(h_axes(2), find(all(pass)), deconv.metric(2,all(pass)), '.','Color',get(h_plot(2),'Color'))
        plot(h_axes(2), find(all(pass)), deconv.metric(3,all(pass)), '.','Color',get(h_plot(3),'Color'))
        plot(h_axes(2), find(all(pass)), deconv.metric(4,all(pass)), '.','Color',get(h_plot(4),'Color'))
        plot(h_axes(2), find(all(pass)), deconv.metric(5,all(pass)), '.','Color',get(h_plot(5),'Color'))
        plot(h_axes(2), find(all(pass)), deconv.metric(6,all(pass)), '.','Color',get(h_plot(6),'Color'))
        xlabel(h_axes(2), 'Deconv waveform index');
        ylabel(h_axes(2), 'Metric (lower is better)');
        title(h_axes(2), regexprep(param.day_seg,'_','\\_'));
        legend(h_axes(2), 'P','ML','FSL','RSL','IFSL','IRSL','location','best');
        grid(h_axes(2), 'on');
        
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_metric_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.fig'];
        fprintf('Saving %s\n', fig_fn);
        fig_fn_dir = fileparts(fig_fn);
        if ~exist(fig_fn_dir,'dir')
          mkdir(fig_fn_dir);
        end
        ct_saveas(h_fig(2),fig_fn);
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_metric_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.jpg'];
        fprintf('Saving %s\n', fig_fn);
        ct_saveas(h_fig(2),fig_fn);
        
        try; linkaxes(h_axes); end;
        
        twtt_bin = deconv.twtt * param.collate_deconv.twtt_penalty;
        
        clf(h_fig(3));
        set(h_fig(3),'Name',['TWTT ' param.day_seg]);
        h_axes(3) = axes('parent',h_fig(3));
        plot(h_axes(3), twtt_bin)
        hold(h_axes(3),'on');
        %plot(h_axes(3), find(all(pass)), twtt_bin(all(pass)), '.','markersize',14)
        scatter(h_axes(3), find(all(pass)),twtt_bin(all(pass)), 200,score(all(pass)).','.')
        xlabel(h_axes(3), 'Deconv waveform index');
        ylabel(h_axes(3), 'TWTT bin');
        title(h_axes(3), regexprep(param.day_seg,'_','\\_'));
        legend(h_axes(3), 'TWTT','Passed','location','best');
        grid(h_axes(3), 'on');
        h_colorbar = colorbar;
        set(get(h_colorbar,'YLabel'),'String','Score');
        
        clf(h_fig(4));
        set(h_fig(4),'Name',['TWTT vs GPS Time ' param.day_seg]);
        h_axes(4) = axes('parent',h_fig(4));
        plot(h_axes(4), spec.gps_time, spec.surface * param.collate_deconv.twtt_penalty);
        hold(h_axes(4),'on');
        scatter(h_axes(4), deconv.gps_time(all(pass)),twtt_bin(all(pass)), 200,score(all(pass)).','.')
        scatter(h_axes(4), deconv.gps_time(all(pass)),twtt_bin(all(pass)), 200,score(all(pass)).','x')
        h_colorbar = colorbar;
        set(get(h_colorbar,'YLabel'),'String','Score');
        xlabel(h_axes(4), 'GPS time (sec)');
        ylabel(h_axes(4), 'TWTT bin');
        title(h_axes(4), regexprep(param.day_seg,'_','\\_'));
        grid(h_axes(4), 'on');
        xlim(h_axes(4), spec.gps_time([1 end]))
        ylim(h_axes(4), [min(5,min(spec.surface * param.collate_deconv.twtt_penalty)) max(15,max(spec.surface * param.collate_deconv.twtt_penalty))]);
        
        % Print table
        diary_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_table_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.txt'];
        fid = fopen(diary_fn,'wb');
        for fid = [1 fid]
          if fid == 1; fid_error = 2; else fid_error = fid; end;
          fprintf(fid,'Metric Threshold (Must be below this to pass)\n');
          fprintf(fid,'Peak\tML\tPSL FE\tPSL RE\tISL FE\tISL RE\n');
          fprintf(fid,'%.1f\t', param.collate_deconv.abs_metric); fprintf('\n');
          fprintf(fid,'Metric ( '); fprintf(fid_error,'Red Failed '); fprintf(fid,')\n');
          fprintf(fid,'INDEX\tFRM\tREC\tPeak\tML\tPSL FE\tPSL RE\tISL FE\tISL RE\tPASS\tSCORE\tTWTT\tGPS_TIME\tGPS_TIME\tRADIOMETRIC\n');
          for rline = 1:length(deconv.gps_time)
            fprintf(fid,'%d\t',rline);
            fprintf(fid,'%.02f\t',floor(deconv.frm(rline)*100)/100);
            fprintf(fid,'%d\t',deconv.rec(rline));
            for metric = 1:6
              if pass(metric,rline)
                fprintf(fid,'%.1f\t', deconv.metric(metric,rline));
              else
                fprintf(fid_error,'%.1f\t', deconv.metric(metric,rline));
              end
            end
            
            % Print "pass" field
            max_score_idx = find(rline == max_score_rlines);
            pass_field = '';
            if all(pass(:,rline))
              pass_field(end+1) = '*';
            end
            if ~isempty(max_score_idx)
              pass_field(end+1) = 'H';
            end
            fprintf(fid,'%s\t',pass_field);
            
            % Print "score" and "twtt" fields
            if ~isempty(max_score_idx)
              if fid == 1
                fprintf(fid,'<strong>%.1f\t', score(rline));
              else
                fprintf(fid,'%.1f\t', score(rline));
              end
              fprintf(fid,'%.3g ', twtts(max_score_idx));
              if fid == 1
                fprintf('</strong>');
              end
            else
              fprintf(fid,'%.1f\t', score(rline));
              [~,twtts_idx] = min(abs(deconv.twtt(rline)-twtts));
              fprintf(fid,'%.3g ', twtts(twtts_idx));
            end
            
            % Print gps_time
            fprintf(fid, '\t%.14g\t%s', deconv.gps_time(rline), datestr(epoch_to_datenum(deconv.gps_time(rline)),'yyyy-mm-dd HH:MM:SS.FFF'));
            
            % Print radiometric error (dB)
            fprintf(fid, '\t%.1f', deconv.radiometric_error_dB(rline));
            
            fprintf(fid,'\n');
          end
        end
        fclose(fid);
        fprintf('Metric table: %s\n', diary_fn);
      
        if any(strcmp('visible',param.collate_deconv.debug_plots))
          keyboard
        end
      end
      
      %% Stage 1: Plot the best waveform
      rbins_plot = any(strcmp('rbins_best',param.collate_deconv.debug_plots));
      deconv_plot = any(strcmp('deconv_best',param.collate_deconv.debug_plots));
      if rbins_plot || deconv_plot
        % Compute the score
        score = nansum(bsxfun(@times, param.collate_deconv.metric_weights(:), bsxfun(@minus, param.collate_deconv.abs_metric(:), deconv.metric)));
        score(:,any(isnan(deconv.metric))) = -inf;
        
        % Make score adjustments for param.collate_deconv.rec_adjustments
        for rec_idx = 1:size(param.collate_deconv.rec_adjustments{img},1)
          [rec_offset,score_idx] = min(abs(deconv.rec-param.collate_deconv.rec_adjustments{img}(rec_idx,1)));
          if rec_offset > cmd.rlines
            warning('Record offset to closest waveform to rec_adjustments{%d}(%d,1) is larger than the STFT interval used in analysis spec. This may mean that the record in rec_adjustments{%d}(%d,1) is incorrect.',img,rec_idx,img,rec_idx);
          else
            score(score_idx) = score(score_idx) + param.collate_deconv.rec_adjustments{img}(rec_idx,2);
          end
        end
        
        % Find the best waveform
        [max_val,rline] = max(score);
        
        % h: impulse response
        h = spec.deconv_mean{rline};
        % Time gate signal according to cmd.rlines
        Htg = tukeywin(param.collate_deconv.rbins{img}(end)*2+1,0.2);
        h_nonnegative = h(1:1+param.collate_deconv.rbins{img}(end)) .* Htg(end-param.collate_deconv.rbins{img}(end):end);
        Htg = tukeywin(-param.collate_deconv.rbins{img}(1)*2,0.2);
        h_negative = h(end+1+param.collate_deconv.rbins{img}(1):end) .* Htg(1:-param.collate_deconv.rbins{img}(1));
        
        % Plot waveform
        [h_mult_factor,h_deconvolved] = collate_deconv_ascope(param,spec,deconv,h_fig,img,wf_adc,h_nonnegative,h_negative,rline,rbins_plot,deconv_plot);
      end
      
      %% Stage 1: Save results
      if ~strcmpi(param.collate_deconv.metric_mode,'each')
        % Outputs should not be saved if metric_mode is not "each" since
        % all other metric_mode's are for debugging.
        param.collate_deconv.stage_two_en = false;
        continue
      end
      fn_dir = fileparts(ct_filename_out(param,param.collate_deconv.out_path, ''));
      if ~exist(fn_dir,'dir')
        mkdir(fn_dir);
      end
      out_fn = fullfile(fn_dir,sprintf('deconv_lib_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
      fprintf('Saving %s img %d wf %d adc %d\n  %s\n', param.day_seg, img, wf, adc, out_fn);
      ct_file_lock_check(out_fn,2);
      if 0
        % For debugging: quick hand manipulation of the results before
        % saving. Specifically setup to remove certain waveforms from the
        % deconv_lib file. param.collate_deconv.bad_gps_times field should
        % be used in the end.
        good_mask = true(size(deconv.gps_time));
        good_mask(1:7) = false; % Manually select which waveforms to remove
        deconv.gps_time = deconv.gps_time(good_mask);
        deconv.lat = deconv.lat(good_mask);
        deconv.lon = deconv.lon(good_mask);
        deconv.elev = deconv.elev(good_mask);
        deconv.roll = deconv.roll(good_mask);
        deconv.pitch = deconv.pitch(good_mask);
        deconv.heading = deconv.heading(good_mask);
        deconv.frm = deconv.frm(good_mask);
        deconv.rec = deconv.rec(good_mask);
        deconv.ref_nonnegative = deconv.ref_nonnegative(good_mask);
        deconv.ref_negative = deconv.ref_negative(good_mask);
        deconv.ref_mult_factor = deconv.ref_mult_factor(good_mask);
        deconv.impulse_response = deconv.impulse_response(good_mask);
        deconv.metric = deconv.metric(:,good_mask);
        deconv.peakiness = deconv.peakiness(good_mask);
        deconv.fc = deconv.fc(good_mask);
        deconv.twtt = deconv.twtt(good_mask);
      end
      deconv.file_version = '1';
      deconv.file_type = 'deconv_lib';
      ct_save(out_fn,'-struct','deconv');
      
    end
  end
end

if param.collate_deconv.stage_two_en
  for img = param.collate_deconv.imgs
    
    if isempty(param.collate_deconv.wf_adcs)
      % If no wf-adc pairs specified, then do them all.
      wf_adcs = 1:size(param.analysis.imgs{img},1);
    else
      wf_adcs = param.collate_deconv.wf_adcs{img};
    end
    for wf_adc = wf_adcs
      wf = param.analysis.imgs{img}(wf_adc,1);
      adc = param.analysis.imgs{img}(wf_adc,2);
      
      %% Stage 2: Determine best waveform for each record
      % ===================================================================
      
      %% Stage 2: 1. Load deconv
      fn_dir = fileparts(ct_filename_out(param,param.collate_deconv.out_path, ''));
      fn = fullfile(fn_dir,sprintf('deconv_lib_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
      fprintf('Loading %s img %d wf %d adc %d\n  %s\n', param.day_seg, img, wf, adc, fn);
      if exist(fn)
        deconv = load(fn,'param_collate_deconv','param_analysis','param_records');
        new_file = false;
      else
        fprintf('  Does not exist.\n');
        new_file = true;
      end
      
      %% Stage 2: 2. Load all segments that are specified
      %  (default is to load just the current segment's deconv file)
      deconv_lib = [];
      for day_seg_idx = 1:length(param.collate_deconv.day_segs)
        day_seg = param.collate_deconv.day_segs{day_seg_idx};
        fn_dir = fileparts(ct_filename_out(param,param.collate_deconv.out_path, ''));
        fn = fullfile(fn_dir,sprintf('deconv_lib_%s_wf_%d_adc_%d.mat', day_seg, wf, adc));
        if exist(fn,'file')
          fprintf('Loading lib %s img %d wf %d adc %d\n  %s\n', day_seg, img, wf, adc, fn);
        else
          fprintf('Not found!!! %s img %d wf %d adc %d\n  %s\n', day_seg, img, wf, adc, fn);
          continue;
        end
        if isempty(deconv_lib)
          % For the first file loaded, just load directly
          deconv_lib = load(fn);
          deconv_lib.day_seg = repmat({day_seg},[length(deconv_lib.gps_time) 1]);
        else
          % Load and append all subsequent files
          tmp = load(fn);
          deconv_lib.gps_time(end+(1:length(tmp.gps_time))) = tmp.gps_time;
          deconv_lib.lat(end+(1:length(tmp.lat))) = tmp.lat;
          deconv_lib.lon(end+(1:length(tmp.lon))) = tmp.lon;
          deconv_lib.elev(end+(1:length(tmp.elev))) = tmp.elev;
          deconv_lib.roll(end+(1:length(tmp.roll))) = tmp.roll;
          deconv_lib.pitch(end+(1:length(tmp.pitch))) = tmp.pitch;
          deconv_lib.heading(end+(1:length(tmp.heading))) = tmp.heading;
          deconv_lib.frm(end+(1:length(tmp.frm))) = tmp.frm;
          deconv_lib.rec(end+(1:length(tmp.rec))) = tmp.rec;
          deconv_lib.ref_nonnegative(end+(1:length(tmp.ref_nonnegative))) = tmp.ref_nonnegative;
          deconv_lib.ref_negative(end+(1:length(tmp.ref_negative))) = tmp.ref_negative;
          deconv_lib.ref_mult_factor(end+(1:length(tmp.ref_mult_factor))) = tmp.ref_mult_factor;
          deconv_lib.impulse_response(end+(1:length(tmp.impulse_response))) = tmp.impulse_response;
          deconv_lib.metric(:,end+(1:length(tmp.metric))) = tmp.metric;
          deconv_lib.peakiness(end+(1:length(tmp.peakiness))) = tmp.peakiness;
          deconv_lib.fc(end+(1:length(tmp.fc))) = tmp.fc;
          deconv_lib.twtt(end+(1:length(tmp.twtt))) = tmp.twtt;
          deconv_lib.day_seg(end+(1:length(tmp.gps_time))) = repmat({day_seg},[length(tmp.gps_time) 1]);
        end
        if new_file
          deconv.param_collate_deconv = deconv_lib.param_collate_deconv;
          deconv.param_analysis = deconv_lib.param_analysis;
          deconv.param_records = deconv_lib.param_records;
        end
        
      end
      if isempty(deconv_lib) || isempty(deconv_lib.gps_time)
        warning(sprintf('There are no deconvolution waveforms in the files loaded!!!\nSpecify other cmd.day_seg to load or remake current day_seg files with lower metric thresholds.'));
        continue
      end
      
      %% Stage 2: 3. Load surface using opsLoadLayers
      %  To determine which waveforms are needed
      layer = opsLoadLayers(param,param.collate_deconv.surf_layer);
      
      %% Stage 2: 4. Decimate layer
      decim_idxs = get_equal_alongtrack_spacing_idxs(layer.gps_time,param.collate_deconv.decimate_table_sec);
      layer.gps_time = layer.gps_time(decim_idxs);
      layer.twtt = layer.twtt(decim_idxs);
      layer.lat = layer.lat(decim_idxs);
      layer.lon = layer.lon(decim_idxs);
      layer.elev = layer.elev(decim_idxs);
      
      %% Stage 2: 5. Compare results to metric
      pass = bsxfun(@lt,deconv_lib.metric,param.collate_deconv.abs_metric(:));
      score = nansum(bsxfun(@times, param.collate_deconv.metric_weights(:), bsxfun(@minus, param.collate_deconv.abs_metric(:), deconv_lib.metric)));
      score(:,any(isnan(deconv_lib.metric))) = nan;
      
      % Make score adjustments for param.collate_deconv.rec_adjustments
      cmd = deconv_lib.param_analysis.analysis.cmd{param.collate_deconv.cmd_idx};
      for rec_idx = 1:size(param.collate_deconv.rec_adjustments{img},1)
        [rec_offset,score_idx] = min(abs(deconv_lib.rec-param.collate_deconv.rec_adjustments{img}(rec_idx,1)));
        if rec_offset > cmd.rlines
          warning('Record offset to closest waveform to rec_adjustments{%d}(%d,1) is larger than the STFT interval used in analysis spec. This may mean that the record in rec_adjustments{%d}(%d,1) is incorrect.',img,rec_idx,img,rec_idx);
        else
          score(score_idx) = score(score_idx) + param.collate_deconv.rec_adjustments{img}(rec_idx,2);
        end
      end
      
      %% Stage 2: 6. Find best scores for each record
      min_score = nanmin(score);
      score = score-min_score;
      clear max_score unadjusted_score max_idx;
      for rline = 1:length(layer.twtt)
        % Score with twtt penalty and time constant penalty term
        d_twtt = layer.twtt(rline) - deconv_lib.twtt;
        d_gps_time = layer.gps_time(rline) - deconv_lib.gps_time;
        adjusted_score = min_score + score - (100-100*exp(-abs(param.collate_deconv.twtt_penalty*d_twtt).^2)) ...
          - (50-50*exp(-abs(param.collate_deconv.gps_time_penalty*d_gps_time).^2));
        if ~isempty(param.collate_deconv.gps_times)
          % The user has specifies a list of gps_times to use rather than
          % using the default best waveform search method.
          gps_times_mask = false(size(deconv_lib.gps_time));
          for gps_times_idx = 1:size(param.collate_deconv.gps_times,1)
            if param.collate_deconv.gps_times(gps_times_idx,2) <= layer.gps_time(rline) ...
                && param.collate_deconv.gps_times(gps_times_idx,3) > layer.gps_time(rline)
              [~,min_idx] = min(abs(param.collate_deconv.gps_times(gps_times_idx,1) - deconv_lib.gps_time));
              gps_times_mask(min_idx) = true;
            end
          end
          if all(~gps_times_mask)
            % If this record does not have any waveforms specified by
            % gps_times field, then revert to the default best waveform
            % search method:
            gps_times_mask = true(size(deconv_lib.gps_time));
            % Remove bad regions
            for gps_times_idx = 1:size(param.collate_deconv.bad_gps_times,1)
              gps_times_mask(deconv_lib.gps_time >= param.collate_deconv.bad_gps_times(gps_times_idx,1) ...
                & deconv_lib.gps_time <= param.collate_deconv.bad_gps_times(gps_times_idx,2)) = false;
            end
          end
        else
          gps_times_mask = true(size(deconv_lib.gps_time));
          % Remove bad regions
          for gps_times_idx = 1:size(param.collate_deconv.bad_gps_times,1)
            gps_times_mask(deconv_lib.gps_time >= param.collate_deconv.bad_gps_times(gps_times_idx,1) ...
              & deconv_lib.gps_time <= param.collate_deconv.bad_gps_times(gps_times_idx,2)) = false;
          end
          
        end
        adjusted_score(~gps_times_mask) = NaN;
        
        [max_score(rline),max_idx(rline)] = max(adjusted_score);
        unadjusted_score(rline) = min_score + score(max_idx(rline));
      end
      if any(max_score < param.collate_deconv.min_score)
        warning('Score is too low for %d of %d blocks of range lines.', sum(max_score < param.collate_deconv.min_score), length(max_score));
      end
      [max_idxs,~,max_idxs_mapping] = unique(max_idx);
      
      [~,sort_idxs] = sort(deconv_lib.twtt(max_idxs));
      unsort_idxs(sort_idxs) = 1:length(sort_idxs);
      max_idxs = max_idxs(sort_idxs);
      max_idxs_mapping = unsort_idxs(max_idxs_mapping);
      
      %% Stage 2: 7. Final output structure
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
      final.map_day_seg = deconv_lib.day_seg(max_idxs);
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
      
      %% Stage 2: 8. Plot final results
      if any(strcmp('final',param.collate_deconv.debug_plots))
        [~,map_frm] = get_frame_id(param,final.map_gps_time);
        
        % TWTT Figure
        % ===================================================================
        clf(h_fig(1));
        set(h_fig(1),'Name',['TWTT ' param.day_seg]);
        h_axes = axes('parent',h_fig(1));
        
        legend_str = {};
        h_plot = [];
        for idx = 1:length(final.gps_time)
          h_plot(idx+1) = plot(h_axes(1), map_frm(final.map_idxs==idx), final.twtt(final.map_idxs(final.map_idxs==idx)),'.');
          hold(h_axes(1),'on');
          legend_str{idx+1} = sprintf('%d',idx);
        end
        
        h_plot(1) = plot(h_axes(1), map_frm, final.map_twtt, 'k', 'LineWidth',2);
        legend_str{1} = 'TWTT';
        
        xlabel(h_axes(1), 'Frame');
        ylabel(h_axes(1), 'Two way travel time (\mus)');
        title(h_axes(1), ['TWTT ' regexprep(param.day_seg,'_','\\_')]);
        legend(h_axes(1), h_plot, legend_str,'location','best');
        grid(h_axes(1), 'on');
        
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_twtt_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.fig'];
        fprintf('Saving %s\n', fig_fn);
        fig_fn_dir = fileparts(fig_fn);
        if ~exist(fig_fn_dir,'dir')
          mkdir(fig_fn_dir);
        end
        ct_saveas(h_fig(1),fig_fn);
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_twtt_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.jpg'];
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
          h_plot(idx) = plot(h_axes(2), map_frm(final.map_idxs==idx), final.max_score(find(final.map_idxs==idx)),'.');
          hold(h_axes(2),'on');
          legend_str{idx} = sprintf('%d',idx);
        end
        for idx = 1:length(final.gps_time)
          h_new_plot = plot(h_axes(2), map_frm(final.map_idxs==idx), final.unadjusted_score(find(final.map_idxs==idx)),'.');
          set(h_new_plot, 'Color', get(h_plot(idx),'Color'))
        end
        
        xlabel(h_axes(2), 'Frame');
        ylabel(h_axes(2), 'Score');
        title(h_axes(2), ['Score ' regexprep(param.day_seg,'_','\\_')]);
        legend(h_axes(2), h_plot, legend_str,'location','best');
        grid(h_axes(2), 'on');
        
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_score_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.fig'];
        fprintf('Saving %s\n', fig_fn);
        ct_saveas(h_fig(2),fig_fn);
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_score_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.jpg'];
        fprintf('Saving %s\n', fig_fn);
        ct_saveas(h_fig(2),fig_fn);
        
        % Deconvolution Transfer Function Figure
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
          radiometric_error_dB = lp(1/(c/2*final.twtt(idx)).^2) - lp(final.ref_nonnegative{idx}(1));
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
        
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_final_transfer_func_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.fig'];
        fprintf('Saving %s\n', fig_fn);
        ct_saveas(h_fig(3),fig_fn);
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_final_transfer_func_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.jpg'];
        fprintf('Saving %s\n', fig_fn);
        ct_saveas(h_fig(3),fig_fn);
      end
      
      %% Stage 2: 9. Store final output file
      fn_dir = fileparts(ct_filename_out(param,param.collate_deconv.out_path, ''));
      if ~exist(fn_dir,'dir')
        mkdir(fn_dir);
      end
      out_fn = fullfile(fn_dir,sprintf('deconv_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
      fprintf('Saving %s img %d wf %d adc %d\n  %s\n', param.day_seg, img, wf, adc, out_fn);
      ct_file_lock_check(out_fn,2);
      final.file_version = '1';
      final.file_type = 'deconv';
      ct_save(out_fn,'-struct','final');
      
    end
  end
end

if ~any(strcmp('visible',param.(mfilename).debug_plots))
  try
    delete(h_fig);
  end
end
