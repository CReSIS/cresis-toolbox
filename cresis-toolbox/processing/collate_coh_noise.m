% function collate_coh_noise(param,param_override)
% collate_coh_noise(param,param_override)
%
% Collects analysis.m results from coherent noise tracking (coh_noise
% command) and creates files for removing the coherent noise during data
% loading.
% Loads all the coh_noise_* files and creates coh_noise_simp_* files that
% are pre-filtered for speed and saves as netcdf so that subsets of the
% files can be loaded efficiently.
%
% Example:
%  See run_collate_coh_noise for how to run.
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

if ~isfield(param,'collate_coh_noise') || isempty(param.collate_coh_noise)
  param.collate_coh_noise = [];
end

% param.collate_coh_noise.imgs: Check this first since other input checks
%   are dependent on its value.
if ~isfield(param.analysis,'imgs') || isempty(param.analysis.imgs)
  param.analysis.imgs = {[1 1]};
end
if ~isfield(param.collate_coh_noise,'imgs') || isempty(param.collate_coh_noise.imgs)
  param.collate_coh_noise.imgs = 1:length(param.analysis.imgs);
end
if ~isnumeric(param.collate_coh_noise.imgs)
  error('param.collate_coh_noise.imgs must be a numeric integer array with indices into param.analysis.imgs. Default is 1:length(param.analysis.imgs).');
end

% cmd_idx: which command index to pull values from param.analysis.cmd{cmd_idx}
if ~isfield(param.collate_coh_noise,'cmd_idx') || isempty(param.collate_coh_noise.cmd_idx)
  param.collate_coh_noise.cmd_idx = 1;
end

% debug_max_size: maximum size allowed for .fig files to be saved in
% cn_plot mode. .jpg files will always be saved.
if ~isfield(param.(mfilename),'debug_max_size') || isempty(param.(mfilename).debug_max_size)
  param.(mfilename).debug_max_size = 0;
end

% debug_out_dir: the output directory for the debug plots and text files,
% default is to place in ct_tmp under the name of the present m-file
if ~isfield(param.(mfilename),'debug_out_dir') || isempty(param.(mfilename).debug_out_dir)
  param.(mfilename).debug_out_dir = mfilename;
end
debug_out_dir = param.(mfilename).debug_out_dir;

% debug_plots: cell array of strings that enable functionality, the
% possible strings are {'cn_plot','reuse','threshold_plot','visible'}. The
% default setting is {'cn_plot','threshold_plot'}.
% 'threshold_plot': enable plotting of threshold plots (should always be
%   enabled if threshold might be used).
% 'visible': displays figures and enters debug mode to allow reviewing for
%   each wf-adc pair
% 'cn_plot': enable plotting of coherent noise plots (should always be
%   enabled).
% 'reuse': causes the reuse file to be loaded if it exists rather than
%   rebuilding the coherent noise. Typical use would be to create all the
%   collate_coh_noise files without visible enabled and then enable both
%   visible and reuse to review all the files.
if ~isfield(param.collate_coh_noise,'debug_plots') || isempty(param.collate_coh_noise.debug_plots)
  param.collate_coh_noise.debug_plots = {'cn_plot','threshold_plot'};
end
enable_visible_plot = any(strcmp('visible',param.collate_coh_noise.debug_plots));
enable_threshold_plot = any(strcmp('threshold_plot',param.collate_coh_noise.debug_plots));
enable_cn_plot = any(strcmp('cn_plot',param.collate_coh_noise.debug_plots));
enable_reuse_files = any(strcmp('reuse',param.collate_coh_noise.debug_plots));
enable_debug_plot = any(strcmp('debug',param.collate_coh_noise.debug_plots));
if ~isempty(param.collate_coh_noise.debug_plots)
  h_fig = get_figures(5,enable_visible_plot);
end

if isfield(param.collate_coh_noise,'dft_corr_length')
  error('Change field name param.collate_coh_noise.dft_corr_length to dft_corr_time and specify an entry for each image to be processed.');
end

if ~isfield(param.collate_coh_noise,'dft_corr_time')
  param.collate_coh_noise.dft_corr_time = {};
end
if isnumeric(param.collate_coh_noise.dft_corr_time)
  param.collate_coh_noise.dft_corr_time = {param.collate_coh_noise.dft_corr_time};
end
for img = param.collate_coh_noise.imgs
  if length(param.collate_coh_noise.dft_corr_time) < img
    param.collate_coh_noise.dft_corr_time{img} = inf;
  end
end

% distance_weight: default is to match the setting during coh_noise
% analysis or false if the setting is absent; if true, then the coherent
% averaging is weighted by the distance travelled. This is primarily useful
% for ground based traverses where long stops can bias the coherent noise
% estimate. Setting this to true will reduce the affect the long stops have
% on the estimated coherent noise mean.
% NOTE: Only the dft method uses this field.
if ~isfield(param.collate_coh_noise,'distance_weight') || isempty(param.collate_coh_noise.distance_weight)
  param.collate_coh_noise.distance_weight = {};
end
for img = param.collate_coh_noise.imgs
  if length(param.collate_coh_noise.distance_weight) < img
    param.collate_coh_noise.distance_weight{img} = [];
  end
end

if ~isfield(param.collate_coh_noise,'firdec_fs') || isempty(param.collate_coh_noise.firdec_fs)
  for img = param.collate_coh_noise.imgs
    param.collate_coh_noise.firdec_fs{img} = 0;
  end
end

if ~isfield(param.collate_coh_noise,'firdec_fcutoff') || isempty(param.collate_coh_noise.firdec_fcutoff)
  for img = param.collate_coh_noise.imgs
    param.collate_coh_noise.firdec_fcutoff{img} = 0;
  end
end

if ~isfield(param.collate_coh_noise,'in_path') || isempty(param.collate_coh_noise.in_path)
  param.collate_coh_noise.in_path = 'analysis';
end

if ~isfield(param.collate_coh_noise,'min_samples') || isempty(param.collate_coh_noise.min_samples)
  param.collate_coh_noise.min_samples = 0.5;
end

if ~isfield(param.collate_coh_noise,'method') || isempty(param.collate_coh_noise.method)
  for img = param.collate_coh_noise.imgs
    param.collate_coh_noise.method{img} = 'dft';
  end
end
if ~iscell(param.collate_coh_noise.method)
  error('param.collate_coh_noise.method is not a cell array. It must be a cell array of strings containing the method for each image to be processed.');
end
if isempty(param.collate_coh_noise.method)
  error('In param.collate_coh_noise.method cell array of strings, a collate coh noise method must be specified for each image. For example {''dft'',''dft''} for images 1 and 2.');
end
for img = param.collate_coh_noise.imgs
  if length(param.collate_coh_noise.method) < img
    param.collate_coh_noise.method{img} = param.collate_coh_noise.method{1};
  end
end

if ~isfield(param.collate_coh_noise,'out_path') || isempty(param.collate_coh_noise.out_path)
  param.collate_coh_noise.out_path = param.collate_coh_noise.in_path;
end

if ~isfield(param.collate_coh_noise,'threshold_en') || isempty(param.collate_coh_noise.threshold_en)
  param.collate_coh_noise.threshold_en = false;
end
% Enable threshold if threshold_plot is enabled
if enable_threshold_plot
  param.collate_coh_noise.threshold_en = true;
end
enable_threshold = param.collate_coh_noise.threshold_en;

if ~isfield(param.collate_coh_noise,'threshold_eval') || isempty(param.collate_coh_noise.threshold_eval)
  % Default is no evaluation
  % Example of how to use evaluation:
  %   params(param_idx).collate_coh_noise.threshold_eval{wf} = 'tmp=threshold(max(1,round(1.1*Tpd_bin)+60):end); tmp(tmp>-110)=-110; threshold(max(1,round(1.1*Tpd_bin)+60):end)=tmp; threshold=threshold+10;';
  param.collate_coh_noise.threshold_eval = {};
end

% threshold_fir_dec: Amount of filtering (number of blocks to average) to apply when finding
% the suggested threshold
if ~isfield(param.collate_coh_noise,'threshold_fir_dec') || isempty(param.collate_coh_noise.threshold_fir_dec)
  param.collate_coh_noise.threshold_fir_dec = 10;
end

if ~isfield(param.collate_coh_noise,'threshold_ylims') || isempty(param.collate_coh_noise.threshold_ylims)
  param.collate_coh_noise.threshold_ylims = [];
end

% wf_adcs: list of wf-adc pairs to use from the wf-adc pair lists in
% param.analysis.imgs. This is a cell array where each cell corresponds to
% the image with the same index so that different wf-adc pairs can be
% pulled from each image. If left empty, then all wf-adc pairs are
% processed for all images.
if ~isfield(param.collate_coh_noise,'wf_adcs') || isempty(param.collate_coh_noise.wf_adcs)
  param.collate_coh_noise.wf_adcs = [];
end
if ~isempty(param.collate_coh_noise.wf_adcs) && ~iscell(param.collate_coh_noise.wf_adcs)
  wf_adcs = param.collate_coh_noise.wf_adcs;
  param.collate_coh_noise.wf_adcs = {};
  for img = 1:max(param.collate_coh_noise.imgs)
    param.collate_coh_noise.wf_adcs{img} = wf_adcs;
  end
end

for img = param.collate_coh_noise.imgs
  
  if isempty(param.collate_coh_noise.wf_adcs) || length(param.collate_coh_noise.wf_adcs) < img
    wf_adcs = 1:size(param.analysis.imgs{img},1);
  else
    wf_adcs = param.collate_coh_noise.wf_adcs{img};
  end
  for wf_adc = wf_adcs
    wf = param.analysis.imgs{img}(wf_adc,1);
    adc = param.analysis.imgs{img}(wf_adc,2);
    
    %% Reuse debug file if exists
    % =====================================================================
    reuse_success = 0;
    reuse_fn = ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('reuse_debug_wf_%02d_adc_%02d.mat',wf,adc));
    if enable_reuse_files
      try
        fprintf('Loading %s\n', reuse_fn);
        load(reuse_fn, 'param_collate_coh_noise');
        if strcmpi( param_collate_coh_noise.method{img}, param.collate_coh_noise.method{img} ) ...
            && param_collate_coh_noise.dft_corr_time(img) == param.collate_coh_noise.dft_corr_time(img) ...
            && param_collate_coh_noise.firdec_fs{img} == param.collate_coh_noise.firdec_fs{img} ...
            && strcmpi( func2str(param_collate_coh_noise.firdec_fcutoff{img}), func2str(param.collate_coh_noise.firdec_fcutoff{img}) )...
            && param_collate_coh_noise.threshold_en == param.collate_coh_noise.threshold_en ...
            && param_collate_coh_noise.threshold_fir_dec == param.collate_coh_noise.threshold_fir_dec
          load(reuse_fn);
          noise.gps_time = gps_time;
          noise.dt = dt;
          noise.fc = fc;
          noise.param_records = param_records;
          noise.param_analysis = param_analysis;
          Nt = size(dft_noise,1);
          time = start_bin*noise.dt + noise.dt*(0:Nt-1).';
          Tpd = param.radar.wfs(wf).Tpd;
          if enable_threshold
            coh_noise_est = sort(max_filt1(cn_before.',15),2);
            coh_noise_est = lp(coh_noise_est(:,round(0.05*end)),2);
            if Nt > 101
              coh_noise_est = sgolayfilt(coh_noise_est,3,101);
            end
          end
          reuse_success = 1;
        else
          reuse_success = 0;
        end
      catch
        fprintf('Unable to reuse file: %s\n',reuse_fn);
        reuse_success = 0;
      end
    end
    
    if ~reuse_success % rerun estimate or jump to plots
      %% Load the coherent noise file
      % ===================================================================
      fn_dir = fileparts(ct_filename_out(param,param.collate_coh_noise.in_path));
      fn = fullfile(fn_dir,sprintf('coh_noise_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
      fprintf('Loading %s (%s)\n', fn, datestr(now));
      noise = load(fn);
      
      cmd = noise.param_analysis.analysis.cmd{param.collate_coh_noise.cmd_idx};
      min_samples = param.collate_coh_noise.min_samples*cmd.block_ave;
      
      % Each processed block has a constant start and stop bin, but between
      % blocks the start/stop range bin may change.
      start_bins = round(noise.t0/noise.dt);
      stop_bins = round(noise.t0/noise.dt) + noise.Nt - 1;
      % Determine the first start bin and the last stop bin
      start_bin = min(start_bins);
      stop_bin = max(stop_bins);
      Nt = stop_bin-start_bin+1;
      
      % Get the size of each processing block
      block_size = cellfun(@(t) size(t,2),noise.coh_ave);
      block_start = 1 + [0 cumsum(block_size(1:end-1))];
      
      % Remove bad blocks
      % =====================================================================
      % NOT DONE YET
      
      %% Fourier analysis of each bin
      % =====================================================================
      Nx = length(noise.gps_time);
      recs = noise.param_analysis.analysis.block_size/2 + noise.param_analysis.analysis.block_size * (0:Nx-1);
      
      Nx_dft = round(Nx / param.collate_coh_noise.dft_corr_time{img});
      if Nx_dft<1
        Nx_dft = 1;
      end
      dft_freqs = ifftshift(-floor(Nx_dft/2) : floor((Nx_dft-1)/2));
      [~,dft_freqs_idxs] = sort(abs(dft_freqs));
      dft_freqs = dft_freqs(dft_freqs_idxs);
      dft_noise = zeros(Nt, Nx_dft, 'single');
      
      % Average time step in slow time/GPS time. If there is only one
      % record, then diff(noise.gps_time) returns an empty matrix and
      % median returns NaN. This condition is captured below.
      dgps_time = median(diff(noise.gps_time));
      
      dx = max(1,round(1/(dgps_time * param.collate_coh_noise.firdec_fs{img})));
      dec_idxs = 1:dx:Nx;
      firdec_gps_time = noise.gps_time(dec_idxs);
      Nx_coh_noise = length(dec_idxs);
      firdec_noise = zeros(Nt, Nx_coh_noise, 'single');
      
      if enable_threshold
        threshold = zeros(Nt,1);
        cn_before_mag = zeros(Nx,Nt);
      end
      
      if enable_cn_plot
        % Transposed to speed up writes
        cn_before = zeros(Nx,Nt);
        cn_after = zeros(Nx,Nt);
      end
      time = start_bin*noise.dt + noise.dt*(0:Nt-1).';
      Tpd = param.radar.wfs(wf).Tpd;
      for bin = start_bin:stop_bin
        bin_idx = bin-start_bin+1;
        if ~mod(bin_idx-1,10^floor(log10(Nt)-1))
          fprintf('  Estimating rbin index %d of %d (%s)\n', bin_idx, Nt, datestr(now));
        end
        coh_bin = nan(size(noise.gps_time));
        if enable_threshold
          coh_bin_mag = nan(size(noise.gps_time));
        end
        for block_idx = 1:length(noise.coh_ave)
          if bin >= start_bins(block_idx) && bin <= stop_bins(block_idx)
            if size(noise.coh_ave_samples{block_idx},1) == 0
              % This block was all bad data so it has fast time dimension
              % of zero. We handle this case separately.
              coh_bin(block_start(block_idx)+(0:block_size(block_idx)-1)) = NaN;
              if enable_threshold
                coh_bin_mag(block_start(block_idx)+(0:block_size(block_idx)-1)) = NaN;
              end
            else
              tmp = noise.coh_ave{block_idx}(bin-start_bins(block_idx)+1,:);
              tmp(noise.coh_ave_samples{block_idx}(bin-start_bins(block_idx)+1,:) < min_samples) = NaN;
              coh_bin(block_start(block_idx)+(0:block_size(block_idx)-1)) = tmp;
              if enable_threshold
                coh_bin_mag(block_start(block_idx)+(0:block_size(block_idx)-1)) = noise.coh_ave_mag{block_idx}(bin-start_bins(block_idx)+1,:);
              end
            end
          end
        end
        if 0
          % Debug plots
          figure(1); clf;
          plot(real(coh_bin)); title(sprintf('%d',bin));
          if enable_threshold
            plot(coh_bin_mag); title(sprintf('%d',bin));
          end
          figure(2); clf;
          plot(imag(coh_bin)); title(sprintf('%d',bin));
        end
        if enable_cn_plot
          cn_before(:,bin_idx) = coh_bin;
        end
        if enable_threshold
          cn_before_mag(:,bin_idx) = coh_bin_mag;
          if size(coh_bin_mag,2) < param.collate_coh_noise.threshold_fir_dec
            threshold(bin_idx) = lp(nanmean(abs(coh_bin_mag).^2,2),1);
          else
            threshold(bin_idx) = min(lp(fir_dec(abs(coh_bin_mag).^2,param.collate_coh_noise.threshold_fir_dec),1),[],2);
          end
        end
        if isempty(param.collate_coh_noise.distance_weight{img})
          if isfield(cmd,'distance_weight')
            param.collate_coh_noise.distance_weight{img} = cmd.distance_weight;
          else
            param.collate_coh_noise.distance_weight{img} = false;
          end
        end
        if strcmpi(param.collate_coh_noise.method{img},'dft')
          for dft_idx = 1:length(dft_freqs)
            mf = exp(1i*2*pi/Nx * dft_freqs(dft_idx) .* (0:Nx-1));
            if ~param.collate_coh_noise.distance_weight{img} || sum(noise.along_track) < 10
              dft_noise(bin_idx,dft_idx) = nanmean(conj(mf).*coh_bin);
            else
              distance_weight = noise.along_track./sum(noise.along_track);
              distance_weight = distance_weight ./ sum(distance_weight);
              dft_noise(bin_idx,dft_idx) = nansum(bsxfun(@times, conj(mf).*coh_bin, distance_weight));
            end
            coh_bin = coh_bin - dft_noise(bin_idx,dft_idx) * mf;
          end
        elseif strcmpi(param.collate_coh_noise.method{img},'firdec')
          dft_noise(bin_idx,1) = nanmean(coh_bin);
          fcutoff = param.collate_coh_noise.firdec_fcutoff{img}(noise.dt*bin);
          if fcutoff == 0
            % Zero cutoff frequency: Take mean over all values
            firdec_noise(bin_idx,:) = nanmean(coh_bin);
          elseif fcutoff < 0
            % Negative cutoff frequency: Disable coherent noise removal
            firdec_noise(bin_idx,:) = 0;
          else
            % Positive cutoff frequency: Regular FIR filter
            if ~isfinite(dgps_time)
              error('dgps_time is not finite, use dft method instead. This is probably because length(noise.gps_time) < 2 because the segment is too short. length(noise.gps_time) = %d', length(noise.gps_time));
            end
            B = tukeywin(round(1/(fcutoff*dgps_time)/2)*2+1,0.5).';
            B = B / sum(B);
            firdec_noise(bin_idx,:) = interp_finite(nan_fir_dec(coh_bin,B,dx),0);
          end
          %firdec_noise(bin_idx,isnan(firdec_noise(bin_idx,:))) = 0;
          noise_est = interp1(firdec_gps_time,firdec_noise(bin_idx,:),noise.gps_time);
          coh_bin = coh_bin - noise_est;
        end
        if enable_cn_plot
          cn_after(:,bin_idx) = coh_bin;
        end
        if 0
          % Debug plots
          dft_noise(bin_idx,dft_idx)
          keyboard
        end
      end
      
      %% Threshold update
      % =====================================================================
      time = start_bin*noise.dt + noise.dt*(0:Nt-1).';
      Tpd = param.radar.wfs(wf).Tpd;
      if enable_threshold
        coh_noise_est = sort(max_filt1(cn_before.',15),2);
        coh_noise_est = lp(coh_noise_est(:,round(0.05*(end-1))+1),2);
        if Nt > 101
          coh_noise_est = sgolayfilt(coh_noise_est,3,101);
        end
      end
      if enable_threshold
        % For debugging and plotting, save the original threshold value
        % When debugging, run "threshold = orig_threshold;" to test
        % different threshold values.
        orig_threshold = threshold;
        if ~isempty(param.collate_coh_noise.threshold_eval)
          if numel(param.collate_coh_noise.threshold_eval) < img
            error('If param.collate_coh_noise.threshold_eval is specified, there must be a cell entry for each image. Image %d cannot be found since numel(param.collate_coh_noise.threshold_eval)=%d',img,numel(param.collate_coh_noise.threshold_eval));
          end
          
          cmd_str = param.collate_coh_noise.threshold_eval;
          if iscell(cmd_str)
            % Not a string, so threshold_eval is specified on a per image basis
            cmd_str = cmd_str{img};
            if iscell(cmd_str)
              % Not a string, so threshold_eval is specified on a per wf-adc pair basis
              cmd_str = cmd_str{wf_adc};
            end
          end
          %figure(100); plot(threshold); hold on;
          % Examples:
          % param.collate_coh_noise.threshold_eval{img} = 'threshold(time>Tpd+0.85e-6 & threshold>-110) = -100; threshold(time<=Tpd+0.85e-6) = inf;'
          % param.collate_coh_noise.threshold_eval{img} = 'threshold(time>Tpd+2.3e-6 & threshold>-130) = -110; threshold(time<=Tpd+2.3e-6) = threshold(time<=Tpd+2.3e-6)+20;';
          % param.collate_coh_noise.threshold_eval{img} = 'threshold = max(min(-100,threshold + 20),10*log10(abs(dft_noise(:,1)).^2)+6);';
          % param.collate_coh_noise.threshold_eval{img} = 'threshold = max(min(nt,threshold+6),max_filt1(10*log10(abs(dft_noise(:,1)).^2)+15-1e6*(time>(Tpd+1.2e-6)),5));';
          % To update threshold in debug mode run:
          %   threshold = orig_threshold;
          %   cmd_str = param.collate_coh_noise.threshold_eval{img}; % Fill in string with new threshold_eval command
          %   eval(cmd_str);
          eval(cmd_str);
        end
      end
      
      %% Save reuse debug file
      % ===================================================================
      reuse.Nx                  = Nx;
      reuse.recs                = recs;
      reuse.start_bin           = start_bin;
      reuse.dft_freqs           = dft_freqs;
      reuse.dft_noise           = dft_noise;
      reuse.firdec_noise     = firdec_noise;
      reuse.firdec_gps_time  = firdec_gps_time;
      
      reuse.dt              = noise.dt;
      reuse.fc              = noise.fc;
      reuse.gps_time        = noise.gps_time;
      reuse.param_records   = noise.param_records;
      reuse.param_analysis  = noise.param_analysis;
      
      reuse.cn_after                = cn_after;
      reuse.cn_before               = cn_before;
      reuse.param_collate_coh_noise = param.collate_coh_noise;
      
      if enable_threshold
        reuse.orig_threshold  = orig_threshold;
        reuse.threshold       = threshold;
        reuse.cn_before_mag   = cn_before_mag;
      end
      
      reuse.file_version = '1';
      reuse.file_type = 'collate_coh_noise';
      fprintf('Saving %s\n', reuse_fn);
      ct_save(reuse_fn, '-struct', 'reuse');
      clear reuse
      
    end
    
    %% Plot
    % =====================================================================
    if enable_cn_plot
      cn_before = cn_before.';
      cn_after = cn_after.';
      
      dxt = mean_without_outliers(diff(noise.gps_time)); % Determine slow-time step
      Xt = Nx*dxt; % Determine extent of slow time axis
      dxf = 1/Xt; % Determine "Doppler" frequency step size
      doppler = dxf * (-floor(Nx/2) : floor((Nx-1)/2)); % "Doppler" frequency axis
      
      mask = isnan(cn_before);
      cn_before(mask) = 0;
      
      clf(h_fig(1));
      set(h_fig(1), 'name', 'collate_coh_noise FFT');
      h_axes(1) = axes('parent',h_fig(1));
      imagesc(doppler, [], fftshift(lp( fft(cn_before,[],2),2 ),2), 'parent', h_axes(1));
      cn_before(mask) = NaN;
      title(h_axes(1), sprintf('%s wf %d adc %d',regexprep(param.day_seg,'_','\\_'), wf, adc));
      xlabel(h_axes(1), 'Doppler frequency (1/sec)');
      ylabel(h_axes(1), 'Range bin');
      
      fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('coh_fft_wf_%02d_adc_%02d',wf,adc)) '.jpg'];
      fprintf('Saving %s\n', fig_fn);
      fig_fn_dir = fileparts(fig_fn);
      if ~exist(fig_fn_dir,'dir')
        mkdir(fig_fn_dir);
      end
      ct_saveas(h_fig(1),fig_fn);
      if numel(cn_before)*16 < param.(mfilename).debug_max_size
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('coh_fft_wf_%02d_adc_%02d',wf,adc)) '.fig'];
        fprintf('Saving %s\n', fig_fn);
        ct_saveas(h_fig(1),fig_fn);
      end
      
      %cn_before(bsxfun(@gt,lp(cn_before,2),threshold)) = NaN;
      clf(h_fig(2));
      set(h_fig(2), 'name', 'collate_coh_noise Before');
      h_axes(2) = axes('parent',h_fig(2));
      imagesc(lp(cn_before,2),'parent',h_axes(2));
      cc=caxis(h_axes(2));
      title(h_axes(2), sprintf('Before coherent noise removal %s wf %d adc %d',regexprep(param.day_seg,'_','\\_'), wf, adc));
      ylabel(h_axes(2), 'Range bin');
      xlabel(h_axes(2), 'Block');
      fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('coh_wf_%02d_adc_%02d',wf,adc)) '.jpg'];
      fprintf('Saving %s\n', fig_fn);
      ct_saveas(h_fig(2),fig_fn);
      if numel(cn_before)*16 < param.(mfilename).debug_max_size
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('coh_wf_%02d_adc_%02d',wf,adc)) '.fig'];
        fprintf('Saving %s\n', fig_fn);
        ct_saveas(h_fig(1),fig_fn);
      end
      
      %cn_before(bsxfun(@gt,lp(cn_before,2),threshold)) = NaN;
      clf(h_fig(3));
      set(h_fig(3), 'name', 'collate_coh_noise Before Phase');
      h_axes(3) = axes('parent',h_fig(3));
      imagesc(angle(cn_before),'parent',h_axes(3));
      title(h_axes(3), sprintf('Before coherent noise removal %s wf %d adc %d (phase)',regexprep(param.day_seg,'_','\\_'), wf, adc));
      ylabel(h_axes(3), 'Range bin');
      xlabel(h_axes(3), 'Block');
      fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('coh_phase_wf_%02d_adc_%02d',wf,adc)) '.jpg'];
      fprintf('Saving %s\n', fig_fn);
      ct_saveas(h_fig(3),fig_fn);
      if numel(cn_before)*16 < param.(mfilename).debug_max_size
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('coh_phase_wf_%02d_adc_%02d',wf,adc)) '.fig'];
        fprintf('Saving %s\n', fig_fn);
        ct_saveas(h_fig(1),fig_fn);
      end
      
      clf(h_fig(4));
      set(h_fig(4), 'name', 'collate_coh_noise After');
      h_axes(4) = axes('parent',h_fig(4));
      imagesc(lp(cn_after,2),'parent',h_axes(4));
      caxis(h_axes(4), cc);
      title(h_axes(4), sprintf('After coherent noise removal %s wf %d adc %d',regexprep(param.day_seg,'_','\\_'), wf, adc));
      xlabel(h_axes(4), 'Block');
      ylabel(h_axes(4), 'Range bin');
      fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('coh_after_wf_%02d_adc_%02d',wf,adc)) '.jpg'];
      fprintf('Saving %s\n', fig_fn);
      ct_saveas(h_fig(4),fig_fn);
      if numel(cn_before)*16 < param.(mfilename).debug_max_size
        fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('coh_after_wf_%02d_adc_%02d',wf,adc)) '.fig'];
        fprintf('Saving %s\n', fig_fn);
        ct_saveas(h_fig(1),fig_fn);
      end
      
      linkaxes(h_axes(2:4));
    end
    
    if enable_threshold_plot
      clf(h_fig(5));
      set(h_fig(5), 'name', 'Threshold');
      h_axes(5) = axes('parent',h_fig(5));
      plot(h_axes(5), orig_threshold)
      hold(h_axes(5), 'on');
      grid(h_axes(5), 'on');
      plot(h_axes(5), threshold, 'LineStyle', '--')
      plot(h_axes(5), lp(abs(dft_noise(:,1)).^2,1))
      plot(h_axes(5), coh_noise_est);
      legend(h_axes(5), 'Original', 'Modified', 'DC Noise', 'Coh Noise Est', 'location', 'best')
      xlabel(h_axes(5), 'Range bin');
      ylabel(h_axes(5), 'Relative power (dB)');
      title(h_axes(5), sprintf('Threshold %s wf %d adc %d',regexprep(param.day_seg,'_','\\_'), wf, adc));
      if ~isempty(param.collate_coh_noise.threshold_ylims)
        ylim(h_axes(5),param.collate_coh_noise.threshold_ylims);
      end
      fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('threshold_wf_%02d_adc_%02d',wf,adc)) '.jpg'];
      fprintf('Saving %s\n', fig_fn);
      fig_fn_dir = fileparts(fig_fn);
      if ~exist(fig_fn_dir,'dir')
        mkdir(fig_fn_dir);
      end
      ct_saveas(h_fig(5),fig_fn);
      fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('threshold_wf_%02d_adc_%02d',wf,adc)) '.fig'];
      fprintf('Saving %s\n', fig_fn);
      ct_saveas(h_fig(5),fig_fn);
    end
    
    if enable_visible_plot
      % frm_id
      fprintf('\nDebug breakpoint:\n  The variable "frm_id" maps the "Block" to the frame that the block occurs in. The fast-time axis is stored in the "time" variable. \n\n');
      [~,frm_id] = get_frame_id(param,noise.gps_time);

      % Bring plots to front
      for h_fig_idx = 1:length(h_fig)
        figure(h_fig(h_fig_idx));
      end
      
      if enable_debug_plot
        % Enter debug mode
        keyboard
      end
    end
    
    %% Create the simplified output
    % =====================================================================
    noise_simp            = struct('gps_time',noise.gps_time);
    noise_simp.dt         = noise.dt;
    noise_simp.fc         = noise.fc;
    noise_simp.recs       = recs;
    noise_simp.start_bin  = start_bin;
    noise_simp.param_collate_coh_noise  = param;
    if strcmpi(param.collate_coh_noise.method{img},'dft')
      noise_simp.dft_freqs  = dft_freqs;
      noise_simp.dft_noise  = dft_noise;
    elseif strcmpi(param.collate_coh_noise.method{img},'firdec')
      noise_simp.firdec_gps_time = firdec_gps_time;
      noise_simp.firdec_noise    = firdec_noise;
    end
    noise_simp.param_records  = noise.param_records;
    noise_simp.param_analysis = noise.param_analysis;
    if enable_threshold
      noise_simp.threshold      = threshold;
      noise_simp.threshold_time = time;
    end
    
    if param.ct_file_lock
      noise_simp.file_version = '1L';
    else
      noise_simp.file_version = '1';
    end
    noise_simp.file_type = 'collate_coh_noise_simp';
    
    %% Save the result
    % =====================================================================
    out_fn_dir = fileparts(ct_filename_out(param,param.collate_coh_noise.out_path, ''));
    out_fn = fullfile(out_fn_dir,sprintf('coh_noise_simp_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
    fprintf('Saving %s (%s)\n', out_fn, datestr(now));
    ct_save(out_fn,'-struct','noise_simp');

  end
end

if ~enable_visible_plot
  try
    delete(h_fig);
  end
end
