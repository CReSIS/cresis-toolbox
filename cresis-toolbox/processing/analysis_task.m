function [success] = analysis_task(param)
% [success] = analysis_task(param)
%
% Cluster support function for analysis.m
%
% https://ops.cresis.ku.edu/wiki/index.php/Analysis
%
% Author: John Paden

%% General Setup
% Load c=speed of light constant
physical_constants;

%% Load records file
% =========================================================================

% Adjust the load records to account for filtering and decimation. Care is
% taken to ensure that when blocks and frames are concatenated together,
% they are seamless (i.e. no discontinuities in the filtering and
% decimation at block and frame boundaries). Also, records before and after
% the desired output records are loaded when available to ensure filter inputs
% have full support when creating outputs. Since this is not possible
% at the the beginning and end of the segment, the filter coefficients are
% renormalized to account for the shorted support so that there is no roll
% off in signal power.

task_recs = param.load.recs; % Store this for later when creating output fn

% Translate the records to load into presummed record counts
%  *_ps: presummed record counts as opposed to raw record counts
load_recs_ps(1) = floor((param.load.recs(1)-1)/param.analysis.presums)+1;
load_recs_ps(2) = floor(param.load.recs(2)/param.analysis.presums);

records = records_load(param,param.load.recs);

% Store the parameters that were used to create the records file
param_records = records.param_records;

% Store the current GPS source
param_records.gps_source = records.gps_source;

% Get output directory, radar type, and base radar name
[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

%% Load surface layer
% =========================================================================
frames = frames_load(param);

tmp_param = param;
% Determine which frames have the records that are needed
frms = find(task_recs(1) >= frames.frame_idxs,1,'last') : find(task_recs(2) >= frames.frame_idxs,1,'last');
tmp_param.cmd.frms = max(1,min(frms)-1) : min(length(frames.frame_idxs),max(frms)+1);
% Load the surface layer
surf_layer = opsLoadLayers(tmp_param,param.analysis.surf_layer);
if isempty(surf_layer.gps_time) || any(~isfinite(surf_layer.gps_time))
  records.surface = zeros(size(records.gps_time));
elseif length(surf_layer.gps_time) == 1;
  records.surface = surf_layer.twtt*ones(size(records.gps_time));
else
  records.surface = interp_finite(interp1(surf_layer.gps_time,surf_layer.twtt,records.gps_time),0);
end

%% Load and process each image separately
% =====================================================================
store_param = param;
for img = 1:length(store_param.load.imgs)

  param = store_param;
  param.load.raw_data = false;
  param.load.presums = param.analysis.presums;
  param.load.bit_mask = param.analysis.bit_mask; % Skip bad records marked in records.bit_mask
  param.load.imgs = param.load.imgs(img);
  cmd_img = img;
  img = 1;
  
  %% Collect waveform information into one structure
  % =========================================================================
  [wfs,states] = data_load_wfs(param,records);
  param.radar.wfs = merge_structs(param.radar.wfs,wfs);
  
  %% Load data
  % =========================================================================
  [hdr,raw_data] = data_load(param,records,states);
  
  for cmd_idx = 1:length(param.analysis.cmd)
    cmd = param.analysis.cmd{cmd_idx};
    if ~cmd.en
      continue;
    end
    fprintf('%s\n', '='*ones(1,40));
    fprintf('  Running method: %s\n', cmd.method);
    
    % Create temporary output directory
    tmp_out_fn_dir = ct_filename_out(param, cmd.out_path,'analysis_tmp');
    if ~exist(tmp_out_fn_dir,'dir')
      mkdir(tmp_out_fn_dir);
    end
    
    if strcmpi(cmd.method,{'saturation'})
      %% Saturation
      % ===================================================================
      % ===================================================================
      
      max_val_gps_time = 1;
      if ~any(strcmpi(radar_name,{'kuband','kuband2','kuband3','kaband3','snow','snow2','snow3','snow5','snow8'}))
        if( ~isfield(cmd,'layer') && ~isfield(cmd,'Nt'))
          [~,Nt,~] = size(data);
          layer = 1;
        end
        [vals,~,dim] = size(data);
        max_waveform = zeros(vals,dim);
        max_val_gps_time = zeros(1,dim);
        for i=1:1:dim
          
          if(layer+Nt > length(data) )
            [~,Nt,~] = size(data);
          end
          max_vals = max(data(:,(layer:Nt),i), [], 1);
          [~,max_rline] = max(max_vals);
          
          max_waveform(:,i) = data(:,max_rline,i);
          gps_time = records.gps_time;
          max_val_gps_time_adc(1,i) = gps_time(:,max_rline);
        end
        
      else
        if( ~isfield(cmd,'layer') && ~isfield(cmd,'Nt') )
          [~,Nt] = size(data);
          layer = 1;  %start bin to start search
        end
        
        if(layer+Nt > length(data) )
          [~,Nt] = size(data);
        end
        
        max_vals = max(data(:,(layer:Nt)), [], 1);
        [~,max_rline] = max(max_vals);
        
        max_waveform = [data(:,max_rline)];  %return max_val_waveform -> the waveform with the maximum value
        gps_time = records.gps_time;
        max_val_gps_time = gps_time(:,max_rline);
      end
      out_fn = fullfile(tmp_out_fn_dir, ...
        sprintf('saturation_img_%02d_%d_%d.mat',img,task_recs));
      param_analysis = param;
      fprintf('  Saving outputs %s (%s)\n', out_fn, datestr(now));
      if param.ct_file_lock
        file_version = '1L';
      else
        file_version = '1';
      end
      file_type = 'analysis_saturation_tmp';
      ct_save(out_fn,'max_rline', 'max_waveform', 'gps_time',...
        'max_val_gps_time', 'max_val_gps_time_adc', 'file_type', 'file_version');
      
      
    elseif strcmpi(cmd.method,{'specular'})
      %% Specular
      % ===================================================================
      % ===================================================================
      
      tmp_param = param;
      tmp_param.load.pulse_comp = true;
      tmp_param.load.motion_comp = true;
      tmp_param.load.combine_rx = false;
      tmp_param.load.trim = cmd.trim;
      tmp_hdr = hdr;
      
      for wf_adc = cmd.wf_adcs{cmd_img}(:).'
        tmp_param.load.imgs = {param.load.imgs{1}(wf_adc,:)};
        tmp_hdr.records = {hdr.records{1,wf_adc}};
        wf = tmp_param.load.imgs{1}(1,1);
        adc = tmp_param.load.imgs{1}(1,2);
        
        coh_ave_samples = [];
        coh_ave = [];
        nyquist_zone = [];
        gps_time = [];
        surface = [];
        lat = [];
        lon = [];
        elev = [];
        roll = [];
        pitch = [];
        heading = [];
        
        if isempty(raw_data{1})
          % There are no good records in the image
          % ===============================================================
          deconv_gps_time = [];
          deconv_mean = [];
          deconv_std = [];
          deconv_sample = [];
          deconv_twtt = [];
          deconv_forced = [];
          peakiness = nan(size(gps_time));
          deconv_fc = [];
          deconv_t0 = [];
          dt = NaN;
          
        else
          % There is at least one good record in the image
          % ===============================================================
          
          % Pulse compression
          tmp_param.radar.wfs(wf).deconv.en = false;
          [tmp_hdr,data,tmp_param] = data_pulse_compress(tmp_param,tmp_hdr,{raw_data{1}(:,:,wf_adc)});
          
          [tmp_hdr,data] = data_merge_combine(tmp_param,tmp_hdr,data);
          
          [tmp_hdr,data] = data_trim(tmp_hdr,data,tmp_param.load.trim);
          
          data = data{1};
          
          % Correct all the data to a constant elevation (no zero padding is
          % applied so wrap around could be an issue for DDC data)
          data(isnan(data)) = 0; % NaN values will create problems in ifft(fft(data))
          for rline = 1:size(data,2)
            elev_dt = (tmp_hdr.records{1,1}.elev(rline) - tmp_hdr.records{1,1}.elev(1)) / (c/2);
            data(:,rline,1) = ifft(fft(data(:,rline,1)) .* exp(1i*2*pi*tmp_hdr.freq{1,1}*elev_dt));
          end
          
          %% Specular: Coherence (STFT) Estimation
          
          % Grab the peak values
          if ~isfield(cmd,'min_bin') || isempty(cmd.min_bin)
            if strcmpi(radar_type,'deramp')
              cmd.min_bin = 0;
            else
              cmd.min_bin = wfs(wf).Tpd;
            end
          end
          min_bin_idxs = find(tmp_hdr.time{1,1} >= cmd.min_bin,1);
          [max_value,max_idx_unfilt] = max(data(min_bin_idxs:end,:,1));
          max_idx_unfilt = max_idx_unfilt + min_bin_idxs(1) - 1;
          
          % Perform STFT (short time Fourier transform) (i.e. overlapping short FFTs in slow-time)
          H = spectrogram(double(max_value),hanning(cmd.rlines),cmd.rlines/2,cmd.rlines);
          
          % Since there may be a little slope in the ice, we sum the powers from
          % the lower frequency doppler bins rather than just taking DC. It seems to help
          % a lot to normalize by the sum of the middle/high-frequency Doppler bins.   A coherent/specular
          % surface will have high power in the low bins and low power in the high bins
          % so this ratio makes sense.
          peakiness = lp(max(abs(H(cmd.signal_doppler_bins,:)).^2) ./ mean(abs(H(cmd.noise_doppler_bins,:)).^2));
          
          if 0
            figure(1); clf;
            imagesc(lp(data(:,:,1)))
            figure(2); clf;
            plot(peakiness)
            keyboard
          end
          
          % Threshold to find high peakiness range lines. (Note these are not
          % actual range line numbers, but rather indices into the STFT groups
          % of range lines.)
          good_rlines = find(peakiness > cmd.threshold);
          
          % Force there to be two good STFT groups in a row before storing
          % it to the specular file for deconvolution.
          good_rlines_idxs = diff(good_rlines) == 1;
          final_good_rlines = good_rlines(good_rlines_idxs);
          
          if ~isempty(cmd.max_rlines)
            [~,sort_idxs] = sort( peakiness(final_good_rlines)+peakiness(final_good_rlines+1) , 'descend');
            final_good_rlines = final_good_rlines(sort_idxs);
            final_good_rlines = final_good_rlines(1 : min(end,cmd.max_rlines));
          end
          
          % Prepare outputs for file
          peakiness_rlines = round((1:length(peakiness)+0.5)*cmd.rlines/2);
          gps_time = tmp_hdr.gps_time(peakiness_rlines);
          lat = tmp_hdr.records{1,1}.lat(peakiness_rlines);
          lon = tmp_hdr.records{1,1}.lon(peakiness_rlines);
          elev = tmp_hdr.records{1,1}.elev(peakiness_rlines);
          roll = tmp_hdr.records{1,1}.roll(peakiness_rlines);
          pitch = tmp_hdr.records{1,1}.pitch(peakiness_rlines);
          heading = tmp_hdr.records{1,1}.heading(peakiness_rlines);
          surface = tmp_hdr.surface(peakiness_rlines);
          
          %% Specular: Forced GPS Check
          deconv_forced = zeros(size(final_good_rlines));
          if isfield(cmd,'gps_times') && ~isempty(cmd.gps_times)
            for idx = 1:length(cmd.gps_times)
              force_gps_time = cmd.gps_times(idx);
              if records.gps_time(1) <= force_gps_time && records.gps_time(end) >= force_gps_time
                % This forced GPS time is in the block, find the peakiness block
                % closest to this time and force it to be included in final_good_rlines
                % if it is not already.
                [~,force_final_good_rline] = min(abs(gps_time - force_gps_time));
                match_idx = find(final_good_rlines == force_final_good_rline);
                if isempty(match_idx)
                  final_good_rlines = [final_good_rlines force_final_good_rline];
                  [final_good_rlines,new_idxs] = sort(final_good_rlines);
                  deconv_forced(new_idxs(end)) = 1;
                else
                  deconv_forced(match_idx) = 1;
                end
              end
            end
          end
          
          %% Specular: Extract specular waveforms
          deconv_gps_time = [];
          deconv_mean = {};
          deconv_std = {};
          deconv_sample = {};
          deconv_twtt = [];
          for good_rline_idx = 1:length(final_good_rlines)
            % Get the specific STFT group we will be extracting an answer from
            final_good_rline = final_good_rlines(good_rline_idx);
            
            % Determine the center range line that this STFT group corresponds to
            center_rline = round((final_good_rline+0.5)*cmd.rlines/2);
            
            fprintf('    SPECULAR %d %s (%s)!\n', center_rline, ...
              datestr(epoch_to_datenum(tmp_hdr.gps_time(center_rline)),'YYYYmmDD HH:MM:SS.FFF'), ...
              datestr(now));
            
            % Find the max values and correponding indices for all the range lines
            % in this group. Since we over-interpolate by Mt and the memory
            % requirements may be prohibitive, we do this in a loop
            % Enforce the same DDC filter in this group. Skip groups that have DDC filter swiches.
            STFT_rlines = -round(cmd.rlines/4) : round(cmd.rlines/4)-1;
            %           if any(strcmpi(radar_name,{'kuband','kuband2','kuband3','kaband3','snow','snow2','snow3','snow5','snow8'}))
            %             if any(diff(img_Mt(center_rline + STFT_rlines)))
            %               fprintf('    Including different DDC filters, skipped.\n');
            %               continue
            %             end
            %           end
            Mt = 100;
            max_value = zeros(size(STFT_rlines));
            max_idx_unfilt = zeros(size(STFT_rlines));
            for offset_idx = 1:length(STFT_rlines)
              offset = STFT_rlines(offset_idx);
              oversampled_rline = interpft(data(:,center_rline+offset),size(data,1)*Mt);
              [max_value(offset_idx),max_idx_unfilt(offset_idx)] ...
                = max(oversampled_rline(min_bin_idxs(1)*Mt:end));
              max_idx_unfilt(offset_idx) = max_idx_unfilt(offset_idx) + min_bin_idxs(1)*Mt - 1;
            end
            
            % Filter the max and phase vectors
            max_idx = sgolayfilt(max_idx_unfilt/100,cmd.peak_sgolay_filt{1},cmd.peak_sgolay_filt{2});
            phase_corr = sgolayfilt(double(unwrap(angle(max_value))),cmd.peak_sgolay_filt{1},cmd.peak_sgolay_filt{2});
            
            % Compensate range lines for amplitude, phase, and delay variance
            % in the peak value
            
            % Apply true time delay shift to flatten surface
            dt = diff(tmp_hdr.time{1,1}(1:2));
            Nt = size(data,1);
            comp_data = ifft(fft(data(:,center_rline+STFT_rlines,1)) .* exp(1i*2*pi*tmp_hdr.freq{1,1}*max_idx*dt) );
            % Apply amplitude correction
            %comp_data = max(abs(max_value)) * comp_data .* repmat(1./abs(max_value), [Nt 1]);
            % Apply phase correction (compensating for phase from time delay shift)
            comp_data = comp_data .* repmat(exp(-1i*(phase_corr + 2*pi*tmp_hdr.freq{1,1}(1)*max_idx*dt)), [Nt 1]);
            
            deconv_gps_time(end+1) = tmp_hdr.gps_time(center_rline);
            deconv_mean{end+1} = mean(comp_data,2);
            deconv_std{end+1} = std(comp_data,[],2);
            deconv_sample{end+1} = data(:,center_rline+1+cmd.rlines/4,1);
            deconv_twtt(:,end+1) = tmp_hdr.time{1,1}(round(mean(max_idx)));
          end
          
          deconv_fc = tmp_hdr.freq{1,1}(1) * ones(size(deconv_gps_time));
          deconv_t0 = tmp_hdr.time{1,1}(1) * ones(size(deconv_gps_time));
          dt = tmp_hdr.time{1,1}(2)-tmp_hdr.time{1,1}(1);
        end
        
        %% Specular: Save Results
        out_fn = fullfile(tmp_out_fn_dir, ...
          sprintf('specular_wf_%d_adc_%d_%d_%d.mat',wf,adc,task_recs));
        param_analysis = tmp_param;
        fprintf('  Saving outputs %s (%s)\n', out_fn, datestr(now));
        if param.ct_file_lock
          file_version = '1L';
        else
          file_version = '1';
        end
        file_type = 'analysis_spec_tmp';
        ct_save(out_fn, 'deconv_gps_time', 'deconv_mean', 'deconv_std','deconv_sample','deconv_twtt',...
          'deconv_forced','peakiness', 'deconv_fc', 'deconv_t0', 'dt', 'gps_time', 'lat', ...
          'lon', 'elev', 'roll', 'pitch', 'heading', 'surface', 'param_analysis', 'param_records','file_type','file_version');
      end
      
      
    elseif strcmpi(cmd.method,{'burst_noise'})
      %% Burst Noise
      % ===================================================================
      % ===================================================================
      
      for wf_adc = cmd.wf_adcs{cmd_img}(:).'
        wf = param.load.imgs{img}(wf_adc,1);
        adc = param.load.imgs{img}(wf_adc,2);
        
        % data_signal: create the temporary "signal" variable Format is
        % user defined and depends on how user plans to use data_signal in
        % test_fh and threshold_fh. Set the function to return [] if not
        % used.
        data_signal = cmd.signal_fh{cmd_img}(raw_data{1}(:,:,wf_adc),wfs(wf));
        % data_noise: create the temporary "noise" variable Format is user
        % defined and depends on how user plans to use data_signal in
        % test_fh and threshold_fh. Set the function to return [] if not
        % used.
        data_noise = cmd.noise_fh{cmd_img}(raw_data{1}(:,:,wf_adc),wfs(wf),data_signal);
        % test_metric: create the output "test_metric" variable Format is
        % user defined and depends on how user plans to use data_signal in
        % threshold_fh. Format is restricted by the concatenation operation
        % in analysis_combine_task (i.e. some data types may not
        % concatenate properly but regular matrices should have no
        % problems). Set the function to return [] if not used.
        test_metric = cmd.test_fh{cmd_img}(data_signal,data_noise,wfs(wf)); % optional
        % bad_samples: create the output "bad_samples" variable The format
        % of this must be a row vector or matrix equal to the size of the
        % data. If a row vector, then bad_samples must be a mask
        % representing bad records. If a matrix, then bad_samples must be a
        % mask representing bad samples. Set the function to return [] if
        % not used. This will cause bad bins, bad_recs, and bad_waveforms
        % to all be [].
        bad_samples = cmd.threshold_fh{cmd_img}(data_signal,data_noise,test_metric,wfs(wf));
        
        if size(bad_samples,1) < 2
          % bad_samples (row vector or empty) represents bad records
          % ---------------------------------------------------------------
          bad_bins = [];
          bad_recs = find(bad_samples);
        else
          % bad_samples represents bad samples
          % ---------------------------------------------------------------
          
          % Convert peaks to range-bin/records
          bad_idxs = find(bad_samples);
          Nt = size(raw_data{1},1);
          bad_bins = mod(bad_idxs-1,Nt)+1;
          bad_recs = floor((bad_idxs-1)/Nt)+1;
          % Remove detections that fall outside the valid bin range
          valid_mask = bad_bins >= cmd.valid_bins{img}(1) & bad_bins <= cmd.valid_bins{img}(2);
          bad_bins = bad_bins(valid_mask);
          bad_recs = bad_recs(valid_mask);
        end
        
        % Extract waveforms
        bad_recs_unique = unique(bad_recs);
        bad_waveforms = raw_data{1}(:,bad_recs_unique(1:min(end,cmd.max_bad_waveforms)),wf_adc);
        
        if 0 && ~isdeployed
          % Debug code (enable for debugging, does not run when compiled)
          figure(1); clf;
          subplot(3,1,1);
          imagesc(data_signal);
          axis tight
          subplot(3,1,2);
          if size(data_noise,1) < 10
            plot(test_metric.');
          else
            imagesc(test_metric);
          end
          grid on;
          axis tight
          subplot(3,1,3);
          if size(data_noise,1) < 2
            plot(bad_samples.');
          else
            imagesc(bad_samples);
          end
          axis tight
          if size(data_noise,1) < 2 || size(data_noise,1) < 10
            link_figures(1,'x');
          else
            link_figures(1,'xy');
          end
          keyboard;
        end
        
        if 0 && ~isdeployed
          % Debug plots
          figure(1); clf;
          plot(bad_recs, bad_bins, 'x')
          figure(2); clf;
          imagesc(data_signal)
          set(gca,'YDir','normal')
          link_figures([2 1],'xy');
        end
        
        %% Burst Noise: Save Results
        out_fn = fullfile(tmp_out_fn_dir, ...
          sprintf('burst_noise_wf_%d_adc_%d_%d_%d.mat',wf,adc,task_recs));
        param_analysis = tmp_param;
        fprintf('  Saving outputs %s (%s)\n', out_fn, datestr(now));
        if param.ct_file_lock
          file_version = '1L';
        else
          file_version = '1';
        end
        file_type = 'analysis_noise_tmp';
        if size(bad_samples,1) >= 2
          test_metric = test_metric(find(bad_samples));
        end
        ct_save(out_fn, 'bad_recs', 'bad_bins', 'bad_waveforms', 'test_metric', 'param_analysis', 'param_records','file_type','file_version');
      end
      
      
    elseif strcmpi(cmd.method,{'coh_noise'})
      %% Coh Noise
      % ===================================================================
      % ===================================================================
      
      tmp_param = param;
      tmp_param.load.pulse_comp = cmd.pulse_comp;
      tmp_param.load.motion_comp = false;
      tmp_param.load.combine_rx = false;
      tmp_hdr = hdr;
      
      for wf_adc = cmd.wf_adcs{cmd_img}(:).'
        tmp_param.load.imgs = {param.load.imgs{1}(wf_adc,:)};
        tmp_hdr.records = {hdr.records{1,wf_adc}};
        wf = tmp_param.load.imgs{1}(1,1);
        adc = tmp_param.load.imgs{1}(1,2);
        
        coh_ave_samples = single([]);
        coh_ave = single([]);
        coh_ave_mag = single([]);
        nyquist_zone = [];
        gps_time = [];
        surface = [];
        lat = [];
        lon = [];
        elev = [];
        roll = [];
        pitch = [];
        heading = [];
        along_track = [];
        bad_rec = [];
        DDC_dec = [];
        raw_or_DDC = [];
        DDC_freq_min = [];
        DDC_freq_max = [];
        
        % Pulse compression (special settings for coherent noise)
        if strcmp(radar_type,'deramp')
          tmp_param.radar.wfs(wf).chan_equal_dB(:) = 0;
          tmp_param.radar.wfs(wf).chan_equal_deg(:) = 0;
          tmp_param.radar.wfs(wf).Tsys(:) = 0;
        end
        tmp_param.radar.wfs(wf).coh_noise_method = '';
        tmp_param.radar.wfs(wf).deconv.en = false;
        tmp_param.radar.wfs(wf).nz_trim = {};

        tmp_hdr.nyquist_zone_signal{img} = double(tmp_hdr.nyquist_zone_hw{img});
        [tmp_hdr,data,tmp_param] = data_pulse_compress(tmp_param,tmp_hdr,{raw_data{1}(:,:,wf_adc)});
        
        [tmp_hdr,data] = data_merge_combine(tmp_param,tmp_hdr,data);
        data = data{1};

        if 0
          % Check data
          figure(2); clf;
          imagesc(lp(fir_dec(abs(fir_dec(bsxfun(@minus,data,nanmean(data,2)),4)).^2,ones(1,5)/5,3)));
          grid on;
          keyboard
        end
        
        %% Coh Noise: Doppler and Data-Statistics
        % Implement memory efficient fft and statistics operations by doing
        % one bin at a time
        doppler = zeros(1,size(data,2),'single');
        mu = zeros(size(data,1),1);
        sigma = zeros(size(data,1),1);
        num_bins = 0;
        for rbin=1:size(data,1)
          tmp = abs(fft(data(rbin,:))).^2;
          if all(~isnan(tmp))
            doppler = doppler + tmp;
            num_bins = num_bins + 1;
          end
          mu(rbin) = nanmean(data(rbin,:));
          sigma(rbin) = nanstd(data(rbin,:));
        end
        doppler = doppler/num_bins;
        mu(abs(mu)*10<sigma) = 0; % Throw out high variance means
        
        %% Coh Noise: Block Analysis
        
        if ischar(cmd.threshold)
          % threshold is a vector loaded from a coh_noise_simp file
          noise_fn_dir = fileparts(ct_filename_out(param,cmd.threshold, ''));
          noise_fn = fullfile(noise_fn_dir,sprintf('coh_noise_simp_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
          fprintf('  Loading coh_noise threshold: %s\n', noise_fn);
          if strcmp(radar_type,'deramp')
            load(noise_fn,'threshold','threshold_time');
            threshold = interp1(threshold_time, threshold, tmp_hdr.time{1}, 'nearest', 'extrap');
          else
            load(noise_fn,'threshold');
          end
        else
          % threshold is a scalar constant
          threshold = cmd.threshold;
        end
        
        % Do averaging
        rline0_list = 1:cmd.block_ave:size(data,2);
        for rline0_idx = 1:length(rline0_list)
          rline0 = rline0_list(rline0_idx);
          rlines = rline0 + (0:min(cmd.block_ave-1,size(data,2)-rline0));
          
          % Regular method for collecting good_samples
          % ===============================================================
          % threshold may be a scalar or a vector so bsxfun is used
          if size(data,1) == 0
            % All records contained bad data, so fast time dimension has
            % length of zero. This breaks bsxfun, so we handle this case
            % separately.
            good_samples = zeros(0,length(rlines));
          else
            if cmd.threshold_removeDC
              good_samples = bsxfun(@lt, lp(bsxfun(@minus,data(:,rlines),mu)), threshold);
            else
              if cmd.threshold_coh_ave == 1
                good_samples = bsxfun(@lt, lp(data(:,rlines)), threshold);
              else
                good_samples = bsxfun(@lt, lp(nan_fir_dec(data(:,rlines),ones(1,cmd.threshold_coh_ave)/cmd.threshold_coh_ave,1, [], [], [], [], 2)), threshold);
              end
            end
          end
          
          %% Coh Noise: Debug coh_ave.threshold
          if 0
            num_coh_ave = cmd.threshold_coh_ave;
            figure(1); clf;
            imagesc(lp(nan_fir_dec(data(:,rlines),ones(1,num_coh_ave)/num_coh_ave,1, [], [], [], [], 2)));
            title(sprintf('Raw data wf %d adc %d blk %d of %d', wf, adc, rline0_idx, length(rline0_list)))
            cc = caxis;
            a1 = gca;
            figure(2); clf;
            title(sprintf('Good sample mask wf %d adc %d blk %d of %d', wf, adc, rline0_idx, length(rline0_list)))
            imagesc(good_samples);
            colormap(gray);
            caxis([0 1]);
            title('Good sample mask (black is thresholded)');
            a2 = gca;
            figure(3); clf;
            if 0
              % Subtract mu (mean of data with high variance signals removed)
              imagesc( lp(bsxfun(@minus,nan_fir_dec(data(:,rlines),ones(1,num_coh_ave)/num_coh_ave,1, [], [], [], [], 2), mu                     )) );
              caxis(cc);
            else
              % Subtract the mean
              tmp = nan_fir_dec(data(:,rlines),ones(1,num_coh_ave)/num_coh_ave,1, [], [], [], [], 2);
              tmp(~good_samples) = NaN;
              tmp_mean = nanmean(tmp,2);
              imagesc( lp(bsxfun(@minus, tmp, tmp_mean )) );
              caxis(cc);
            end
            title(sprintf('Raw data coh noise removed wf %d adc %d blk %d of %d', wf, adc, rline0_idx, length(rline0_list)))
            a3 = gca;
            figure(4); clf;
            imagesc(angle(fir_dec(data(:,rlines),ones(1,num_coh_ave)/num_coh_ave,1)));
            title(sprintf('Raw data phase wf %d adc %d blk %d of %d', wf, adc, rline0_idx, length(rline0_list)))
            a4 = gca;
            linkaxes([a1 a2 a3 a4], 'xy');
            keyboard
          end
          
          %% Coh Noise: Concatenate Info
          tmp_along_track = geodetic_to_along_track(hdr.records{img,wf_adc}.lat(rlines),hdr.records{img,wf_adc}.lon(rlines));
          coh_ave_samples(:,rline0_idx) = sum(good_samples,2);
          if ~cmd.distance_weight || tmp_along_track(end) < 10
            % Too short, all good_sample measurements equal weight
            sum_weight = good_samples;
            sum_weight = bsxfun(@times,sum_weight,1./sum(sum_weight,2));
          else
            sum_weight = diff(tmp_along_track);
            sum_weight = [sum_weight(1) sum_weight];
            sum_weight = bsxfun(@times,good_samples,sum_weight);
            sum_weight = bsxfun(@times,sum_weight,1./sum(sum_weight,2));
          end
          if cmd.threshold_coh_ave == 1
            coh_ave(:,rline0_idx) = nansum(data(:,rlines) .* sum_weight,2);
          else
            coh_ave(:,rline0_idx) = nansum(nan_fir_dec(data(:,rlines),ones(1,cmd.threshold_coh_ave)/cmd.threshold_coh_ave,1, [], [], [], [], 2) .* sum_weight,2);
          end
          if cmd.mag_en
            coh_ave_mag(:,rline0_idx) = nansum(abs(data(:,rlines)) .* sum_weight,2);
          else
            coh_ave_mag = [];
          end          
          
          if strcmpi(radar_type,'deramp')
            % Nyquist_zone: bit mask for which nyquist zones are used in this
            % segment. For example, if nyquist zones 0 and 2 are used, then
            % nyquist zone will be 5 which is 0101 in binary and positions 0
            % and 2 are set to 1. If nyquist zones 0 and 1 are used, then
            % nyquist zone will be 3 which is 0011 in binary and positions 0
            % and 1 are set to 1.
            nz_mask = char('0'*ones(1,32));
            nz_mask(32-unique(hdr.nyquist_zone_hw{img}(rlines))) = '1';
            nyquist_zone(1,rline0_idx) = bin2dec(nz_mask);
          else
            nyquist_zone(1,rline0_idx) = 1;
          end
          
          gps_time(rline0_idx) = mean(hdr.gps_time(rlines));
          surface(rline0_idx) = mean(hdr.surface(rlines));
          lat(rline0_idx) = mean(hdr.records{img,wf_adc}.lat(rlines));
          lon(rline0_idx) = mean(hdr.records{img,wf_adc}.lon(rlines));
          elev(rline0_idx) = mean(hdr.records{img,wf_adc}.elev(rlines));
          roll(rline0_idx) = mean(hdr.records{img,wf_adc}.roll(rlines));
          pitch(rline0_idx) = mean(hdr.records{img,wf_adc}.pitch(rlines));
          heading(rline0_idx) = mean(hdr.records{img,wf_adc}.heading(rlines));
          along_track(rline0_idx) = tmp_along_track(end);
          
          bad_rec(rline0_idx) = mean(hdr.bad_rec{1}(rlines));
          tmp_DDC_dec = unique(hdr.DDC_dec{1}(rlines));
          if length(tmp_DDC_dec) == 1
            DDC_dec(rline0_idx) = tmp_DDC_dec;
          else
            DDC_dec(rline0_idx) = NaN;
          end
          DDC_freq_min(rline0_idx) = min(hdr.DDC_freq{1}(rlines));
          DDC_freq_max(rline0_idx) = max(hdr.DDC_freq{1}(rlines));
          raw_or_DDC(rline0_idx) = DDC_dec(rline0_idx)==1;
          
        end
        
        %% Coh Noise: Save results
        Nt = length(tmp_hdr.time{1});
        if isempty(tmp_hdr.freq{1})
          % All records were bad
          fc = NaN;
          t0 = NaN;
          dt = NaN;
        else
          fc = tmp_hdr.freq{1}(1);
          t0 = tmp_hdr.time{1}(1);
          dt = tmp_hdr.time{1}(2)-tmp_hdr.time{1}(1);
        end
        
        out_fn = fullfile(tmp_out_fn_dir, ...
          sprintf('coh_noise_wf_%d_adc_%d_%d_%d.mat',wf,adc,task_recs));
        param_analysis = tmp_param;
        fprintf('  Saving outputs %s (%s)\n', out_fn, datestr(now));
        if param.ct_file_lock
          file_version = '1L';
        else
          file_version = '1';
        end
        file_type = 'analysis_noise_tmp';
        ct_save(out_fn, 'coh_ave', 'coh_ave_samples', 'coh_ave_mag', 'doppler', 'Nt', 'fc', 't0', 'dt', 'gps_time', 'surface', 'lat', ...
          'lon', 'elev', 'roll', 'pitch', 'heading', 'along_track', 'param_analysis', 'param_records','nyquist_zone','file_type','file_version', 'bad_rec', 'DDC_dec', 'DDC_freq_min', 'DDC_freq_max', 'raw_or_DDC');
      end
      
    elseif strcmpi(cmd.method,{'waveform'})
      %% Waveform
      % ===================================================================
      % ===================================================================
      
      tmp_param = param;
      tmp_param.load.pulse_comp = cmd.pulse_comp;
      tmp_param.load.motion_comp = cmd.motion_comp;
      tmp_param.load.combine_rx = cmd.combine_rx;
      tmp_hdr = hdr;
      
      for wf_adc = cmd.wf_adcs{cmd_img}(:).'
        tmp_param.load.imgs = {param.load.imgs{1}(wf_adc,:)};
        tmp_hdr.records = {hdr.records{1,wf_adc}};
        wf = tmp_param.load.imgs{1}(1,1);
        adc = tmp_param.load.imgs{1}(1,2);
        
        % Pulse compression
        [tmp_hdr,data,tmp_param] = data_pulse_compress(tmp_param,tmp_hdr,{raw_data{1}(:,:,wf_adc)});
        
        [tmp_hdr,data] = data_merge_combine(tmp_param,tmp_hdr,data);
        
        data = data{1};
        freq = tmp_hdr.freq{1};
        time = tmp_hdr.time{1};
        
        % Averaging
        % =========================================================================
        gps_time = fir_dec(tmp_hdr.gps_time, cmd.B_filter, cmd.dec);
        surface = fir_dec(tmp_hdr.surface, cmd.B_filter, cmd.dec);
        data = fir_dec(data, cmd.B_filter, cmd.dec);
        
        lat = fir_dec(tmp_hdr.records{1,1}.lat, cmd.B_filter, cmd.dec);
        lon = fir_dec(tmp_hdr.records{1,1}.lon, cmd.B_filter, cmd.dec);
        elev = fir_dec(tmp_hdr.records{1,1}.elev, cmd.B_filter, cmd.dec);
        roll = fir_dec(tmp_hdr.records{1,1}.roll, cmd.B_filter, cmd.dec);
        pitch = fir_dec(tmp_hdr.records{1,1}.pitch, cmd.B_filter, cmd.dec);
        heading = fir_dec(tmp_hdr.records{1,1}.heading, cmd.B_filter, cmd.dec);
        
        %% Waveform: Load start and stop times
        % =========================================================================
        dt = time(2)-time(1);
        t0 = time(1);
        fc = freq(1);
        Tpd = tmp_param.radar.wfs(wf).Tpd;
        layer_nan_mask = [];
        if isnumeric(cmd.start_time)
          start_bin = find(time>=cmd.start_time,1)*ones(1,size(data,2));
          if isempty(start_bin)
            error('No time (%g-%g) is >= cmd.start_time (%g).', time(1), time(end), cmd.start_time);
          end
        elseif isstruct(cmd.start_time)
          cmd.start_time.eval.Tpd = Tpd;
          cmd.start_time.eval.dt = dt;
          cmd.start_time.eval.Tstart = time(1);
          cmd.start_time.eval.Tend = time(end);
          layers = opsLoadLayers(param,cmd.start_time);
          layer_nan_mask = isnan(interp1(layers.gps_time, layers.twtt, gps_time));
          layers.twtt = interp_finite(layers.twtt,0);
          layers.twtt = interp1(layers.gps_time, layers.twtt, gps_time);
          start_bin = round(interp1(time, 1:length(time), layers.twtt,'linear','extrap'));
          start_bin = min(max(1,start_bin),size(data,1));
        elseif ischar(cmd.start_time)
          es = [];
          es.Tpd = Tpd;
          es.dt = dt;
          es.Tstart = time(1);
          es.Tend = time(end);
          s = 0;
          eval(cmd.start_time);
          start_bin = find(time>=s,1)*ones(1,size(data,2));
          if isempty(start_bin)
            error('No time (%g-%g) is >= cmd.start_time (%g).', time(1), time(end), cmd.start_time);
          end
        end
        
        if isfinite(cmd.Nt)
          stop_bin = start_bin + cmd.Nt - 1;
        else
          stop_bin = length(time)*ones(1,size(data,2));
          cmd.Nt = max(stop_bin-start_bin+1);
        end
        
        %% Waveform: Extract waveform values according to bin_rng
        wf_data = zeros(cmd.Nt, size(data,2), size(data,3),'single');
        time_rng = zeros(2, size(data,2), size(data,3),'single');
        for rline = 1:size(data,2)
          start_bin0 = max(1,start_bin(rline));
          stop_bin0 = min(size(data,1),stop_bin(rline));
          out_bin0 = 1 + start_bin0-start_bin(rline);
          out_bin1 = size(wf_data,1) - (stop_bin(rline)-stop_bin0);
          wf_data(out_bin0:out_bin1,rline,:) = data(start_bin0:stop_bin0,rline,:);
          time_rng(1:2,rline) = t0+dt*([start_bin0, stop_bin0]-1);
        end
        
        %% Waveform: Save
        out_fn = fullfile(tmp_out_fn_dir, ...
          sprintf('waveform_wf_%d_adc_%d_%d_%d.mat',wf,adc,task_recs));
        param_analysis = tmp_param;
        fprintf('  Saving outputs %s (%s)\n', out_fn, datestr(now));
        if param.ct_file_lock
          file_version = '1L';
        else
          file_version = '1';
        end
        file_type = 'analysis_waveform_tmp';
        ct_save(out_fn, 'wf_data','time_rng', 'gps_time', 'lat', ...
          'lon', 'elev', 'roll', 'pitch', 'heading', 'dt', 'fc', 'layer_nan_mask', 'param_analysis', 'param_records','file_type','file_version');
      end
      
      
    elseif strcmpi(cmd.method,{'statistics'})
      %% Statistics
      % ===================================================================
      % ===================================================================
      
      tmp_param = param;
      tmp_param.load.pulse_comp = cmd.pulse_comp;
      tmp_param.load.motion_comp = cmd.motion_comp;
      tmp_param.load.combine_rx = cmd.combine_rx;
      tmp_hdr = hdr;
      
      for wf_adc = cmd.wf_adcs{cmd_img}(:).'        
        tmp_param.load.imgs = {param.load.imgs{1}(wf_adc,:)};
        tmp_hdr.records = {hdr.records{1,wf_adc}};
        wf = tmp_param.load.imgs{1}(1,1);
        adc = tmp_param.load.imgs{1}(1,2);
        
        % Pulse compression
        [tmp_hdr,data,tmp_param] = data_pulse_compress(tmp_param,tmp_hdr,{raw_data{1}(:,:,wf_adc)});
        
        [tmp_hdr,data] = data_merge_combine(tmp_param,tmp_hdr,data);
        
        data = data{1};
        freq = tmp_hdr.freq{1};
        time = tmp_hdr.time{1};
        
        %% Statistics: Load start and stop times
        dt = time(2)-time(1);
        Tpd = tmp_param.radar.wfs(wf).Tpd;
        if isnumeric(cmd.start_time)
          start_bin = find(time>=cmd.start_time,1)*ones(1,size(data,2));
          if isempty(start_bin)
            error('No time (%g-%g) is >= cmd.start_time (%g).', time(1), time(end), cmd.start_time);
          end
        elseif isstruct(cmd.start_time)
          cmd.start_time.eval.Tpd = Tpd;
          cmd.start_time.eval.dt = dt;
          cmd.start_time.eval.Tstart = time(1);
          cmd.start_time.eval.Tend = time(end);
          layers = opsLoadLayers(param,cmd.start_time);
          layers.twtt = interp_finite(layers.twtt,0);
          layers.twtt = interp1(layers.gps_time, layers.twtt, hdr.gps_time(1,:));
          start_bin = round(interp1(time, 1:length(time), layers.twtt,'linear','extrap'));
          start_bin = min(max(1,start_bin),size(data,1));
        elseif ischar(cmd.start_time)
          es = [];
          es.Tpd = Tpd;
          es.dt = dt;
          es.Tstart = time(1);
          es.Tend = time(end);
          s = 0;
          eval(cmd.start_time);
          start_bin = find(time>=s,1)*ones(1,size(data,2));
          if isempty(start_bin)
            error('No time (%g-%g) is >= cmd.start_time (%g).', time(1), time(end), cmd.start_time);
          end
        end
        if isnumeric(cmd.stop_time)
          stop_bin = find(time<=cmd.stop_time,1,'last')*ones(1,size(data,2));
          if isempty(stop_bin)
            error('No time (%g-%g) is <= cmd.stop_time (%g).', time(1), time(end), cmd.stop_time);
          end
        elseif isstruct(cmd.stop_time)
          cmd.stop_time.eval.Tpd = Tpd;
          cmd.stop_time.eval.dt = dt;
          layers = opsLoadLayers(param,cmd.stop_time);
          layers.twtt = interp1(layers.gps_time, layers.twtt, hdr.gps_time(1,:));
          layers.twtt = interp_finite(layers.twtt,0);
          stop_bin = round(interp1(time, 1:length(time), layers.twtt,'linear','extrap'));
          stop_bin = min(max(1,stop_bin),size(data,1));
        elseif ischar(cmd.stop_time)
          es = [];
          es.Tpd = Tpd;
          es.dt = dt;
          es.Tstart = time(1);
          es.Tend = time(end);
          s = 0;
          eval(cmd.stop_time);
          stop_bin = find(time<=s,1,'last')*ones(1,size(data,2));
          if isempty(stop_bin)
            error('No time (%g-%g) is >= cmd.stop_time (%g).', time(1), time(end), cmd.stop_time);
          end
        end
        Nt = max(floor(stop_bin - start_bin + 1));
        
        % Two modes for block_ave:
        % block_ave == 1: Special execution mode
        % block_ave > 1: x is carved into blocks for processing
        %
        % Two modes for cmd.stats
        % String: @fh(param,cmd,data,start_bin,stop_bin)
        %   block_ave == 1: data
        %   block_ave > 1: data(:,rline_subset)
        % Function handle: @fh(vals)
        %   bin_subset is forced to Nt = min(stop_bin-start_bin)
        %   block_ave == 1: data(bin_subset,:)
        %   block_ave > 1: data(bin_subset,rline_subset)
        %   bin_subset is start_bin+Nt, missing range bins are set to NaN
        
        %% Statistics: Block Analysis
        if cmd.block_ave == 1
          stats = {};
          for stat_idx = 1:numel(cmd.stats)
            if ischar(cmd.stats{stat_idx})
              % Function handle string
              fh = str2func(cmd.stats{stat_idx});
              stats{stat_idx} = fh(param,cmd,data,start_bin,stop_bin);
            else
              % Function handle
              if Nt == size(data,1)
                stats{stat_idx} = cmd.stats{stat_idx}(data);
              else
                vals = nan(Nt,size(data,2));
                for rline = 1:size(data,2)
                  vals(1:stop_bin(rline)-start_bin(rline)+1,rline) = data(start_bin(rline):stop_bin(rline),rline);
                end
                stats{stat_idx} = cmd.stats{stat_idx}(vals);
              end
            end
          end
          
          gps_time = hdr.gps_time;
          surface = hdr.surface;
          lat = hdr.records{img,wf_adc}.lat;
          lon = hdr.records{img,wf_adc}.lon;
          elev = hdr.records{img,wf_adc}.elev;
          roll = hdr.records{img,wf_adc}.roll;
          pitch = hdr.records{img,wf_adc}.pitch;
          heading = hdr.records{img,wf_adc}.heading;
          
        else
          rline0_list = 1:cmd.block_ave:size(data,2);
          stats = {};
          for stat_idx = 1:numel(cmd.stats)
            stats{stat_idx} = [];
          end
          gps_time = []; surface = [];
          lat = []; lon = []; elev = [];
          roll = []; pitch = []; heading = [];
          for rline0_idx = 1:length(rline0_list)
            rline0 = rline0_list(rline0_idx);
            rlines = rline0 + (0:min(cmd.block_ave-1,size(data,2)-rline0));
            
            %% Statistics: Run function handles on the layers
            vals = zeros(stop_bin(1)-start_bin(1)+1,cmd.block_ave);
            for rlines_idx = 1:length(rlines)
              vals(:,rlines_idx) = data(start_bin:stop_bin,rlines(rlines_idx));
            end
            for stat_idx = 1:numel(cmd.stats)
              if ischar(cmd.stats{stat_idx})
                % Function handle string
                fh = str2func(cmd.stats{stat_idx});
                tmp = fh(param,cmd,vals,start_bin,stop_bin);
                stats{stat_idx}(:,end+(1:size(tmp,2))) = tmp;
              else
                % Function handle
                tmp = cmd.stats{stat_idx}(vals);
                stats{stat_idx}(:,end+(1:size(tmp,2))) = tmp;
              end
            end
            
            gps_time(rline0_idx) = mean(hdr.gps_time(rlines));
            surface(rline0_idx) = mean(hdr.surface(rlines));
            lat(rline0_idx) = mean(hdr.records{img,wf_adc}.lat(rlines));
            lon(rline0_idx) = mean(hdr.records{img,wf_adc}.lon(rlines));
            elev(rline0_idx) = mean(hdr.records{img,wf_adc}.elev(rlines));
            roll(rline0_idx) = mean(hdr.records{img,wf_adc}.roll(rlines));
            pitch(rline0_idx) = mean(hdr.records{img,wf_adc}.pitch(rlines));
            heading(rline0_idx) = mean(hdr.records{img,wf_adc}.heading(rlines));
          end
        end
        
        %% Statistics: Save results
        
        out_fn = fullfile(tmp_out_fn_dir, ...
          sprintf('stats_wf_%d_adc_%d_%d_%d.mat',wf,adc,task_recs));
        param_analysis = tmp_param;
        fprintf('  Saving outputs %s (%s)\n', out_fn, datestr(now));
        if param.ct_file_lock
          file_version = '1L';
        else
          file_version = '1';
        end
        file_type = 'analysis_stats_tmp';
        ct_save(out_fn,'-v7.3', 'stats', 'freq', 'time', 'start_bin', 'gps_time', 'surface', 'lat', ...
          'lon', 'elev', 'roll', 'pitch', 'heading', 'param_analysis', 'param_records','file_type','file_version');
      end
      
    end
    
  end
end

fprintf('%s done %s\n', mfilename, datestr(now));

success = true;
