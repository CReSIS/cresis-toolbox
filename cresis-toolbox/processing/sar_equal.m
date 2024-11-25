% function sar_equal(param,param_override)
% sar_equal(param,param_override)
%
% Perform equalization using SAR data. Since images are what are compared,
% the images can be made up of individual wf-adc pairs and/or groups of
% wf-adc pairs. This program is similar to collate_equal.m in that it
% assumes the target is at nadir and motion compensation is done for the
% nadir direction of arrival. Any residual time delay, phase, or amplitude
% differences are assumed to be system effects and the average of these are
% the new equalization coefficients that are recommended.
%
% This function was created for measuring the time and phase offset between
% waveforms. In this mode the imgs field generally combines all the adc's
% together for each waveform to increase the SNR and reduce side clutter.
%
% Use run_sar_equal.m to run sar_equal.m. After running, use
% run_sar_equal_post.m to combine results from different segments and
% frames to find the overall mean and trends.
%
% Inputs
% =========================================================================
%
% param: struct with processing parameters
%
% param_override: parameters in this struct will override parameters in
% param.  This struct must also contain the gRadar fields. Typically global
% gRadar; param_override = gRadar;
%
% Outputs
% =========================================================================
%
% No outputs besides debug plots and the output file that are stored in the
% ct_tmp output directory specified by param.sar_equal.debug_out_dir.
%
% Author: John Paden
%
% See also: run_sar_equal.m, run_sar_equal_post.m, run_sar_load.m, sar_equal.m,
% sar_equal_post.m, sar_load.m

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input checking
% =====================================================================

% .coh_ave: Positive scalar integer. Slow-time averaging/stacking. Default
% is 1.
if ~isfield(param.sar_equal,'coh_ave') || isempty(param.sar_equal.coh_ave)
  param.sar_equal.coh_ave = 1;
end

% .debug_out_dir: string containing the ct_tmp output folder name to use
% for the debug outputs. This is input to ct_filename_ct_tmp().
if ~isfield(param.sar_equal,'debug_out_dir') || isempty(param.sar_equal.debug_out_dir)
  param.sar_equal.debug_out_dir = 'sar_equal';
end
debug_out_dir = param.sar_equal.debug_out_dir;

% debug_plots: cell array of debug plots to enable
if ~isfield(param.sar_equal,'debug_plots')
  param.sar_equal.debug_plots = {'final','visible'};
end
enable_visible_plot = any(strcmp('visible',param.sar_equal.debug_plots));

% .delay: strucure controlling how the equalization coefficients are
% estimated.
if ~isfield(param.sar_equal,'delay') || isempty(param.sar_equal.delay)
  param.sar_equal.delay = [];
end
% .delay.method: string containing the method name. Default is
% 'xcorr_complex'.
if ~isfield(param.sar_equal.delay,'method') || isempty(param.sar_equal.delay.method)
  param.sar_equal.delay.method = 'xcorr_complex';
end
% .delay.Mt: Positive scalar integer. Fast-time oversampling to use in
% equalization. Default is 64.
if ~isfield(param.sar_equal.delay,'Mt') || isempty(param.sar_equal.delay.Mt)
  param.sar_equal.delay.Mt = 64;
end
% .delay.ref_bins: Array of scalar integers. Default is [-19 20]. Only the
% first and last entry are used in the array. This specifies the relative
% to zero_surf_bin range to use for correlation methods for the
% param.sar_equal.ref wf_adc pair. For example, [-19 20] specifies 19
% bins before the zero_surf_bin to 20 bins after the zero_surf_bin (so 40
% total).
if ~isfield(param.sar_equal.delay,'ref_bins') || isempty(param.sar_equal.delay.ref_bins)
  param.sar_equal.delay.ref_bins = [-19 20];
end
% .delay.search_bins: Array of scalar integers. Default is [-13 14]. Only
% the first and last entry are used in the array. This specifies the
% relative to zero_surf_bin range to use for correlation methods. For
% example, [-13 14] specifies 13 bins before the zero_surf_bin to 14 bins
% after the zero_surf_bin (so 28 total).
if ~isfield(param.sar_equal.delay,'search_bins') || isempty(param.sar_equal.delay.search_bins)
  param.sar_equal.delay.search_bins = [-13 14];
end

% imgs: cell array of wf_adc pair lists, images to load, equalization will
% be performed between the reference image specified by ref
if ~isfield(param.sar_equal,'imgs') || isempty(param.sar_equal.imgs)
  error('param.sar_equal.imgs must be set.');
end

% ref_img: positive scalar integer. Index of reference image in
% param.sar_equal.imgs list. Default is 1.
if ~isfield(param.sar_equal,'ref_img') || isempty(param.sar_equal.ref_img)
  param.sar_equal.ref_img = 1;
end
ref_img = param.sar_equal.ref_img;

% sar_load: structure array for param.sar_load. fields which will be copied
% to param.sar_load when loading the SAR data.
if ~isfield(param.sar_equal,'sar_load') || isempty(param.sar_equal.sar_load)
  param.sar_equal.sar_load = [];
end

% start_time: See analysis waveform cmd start_time field for options.
if ~isfield(param.sar_equal,'start_time') || isempty(param.sar_equal.start_time)
  error('param.sar_equal.start_time must be set.');
end

%% Other Setup
% =========================================================================

physical_constants;

if ~isempty(param.sar_equal.debug_plots)
  h_fig = get_figures(5,enable_visible_plot);
end

% Find the first wf-adc pair for the last image, the output file names
% are formed with these.
for img = 1:length(param.sar_equal.imgs)
  if img ~= ref_img
    fn_wf = param.sar_equal.imgs{img}(1,1);
    fn_adc = param.sar_equal.imgs{img}(1,2);
  end
end

%% Loop Frames: load each frame one at a time
% =====================================================================
for frm_idx = 1:length(param.cmd.frms)
  frm = param.cmd.frms(frm_idx);
  
  %% Load SAR for frame
  % =====================================================================
  
  param_load = param;
  param_load.sar_load = param.sar_equal.sar_load;
  param_load.sar_load.frms = frm;
  param_load.sar_load.chunk = {};
  param_load.sar_load.subap = [];
  param_load.sar_load.imgs = param.sar_equal.imgs;
  param_load.sar_load.combine_channels = 0;
  param_load.sar_load.incoherent = 0;
  param_load.sar_load.combine_imgs = 0;
  param_load.sar_load.detrend.cmd = 0;
  
  [data,metadata] = sar_load(param_load);
  
  ref_wf = param.sar_equal.imgs{ref_img}(1,1);
  ref_adc = param.sar_equal.imgs{ref_img}(1,2);
  
  %% Channel equalization
  % =====================================================================
  for img = 1:length(param.sar_equal.imgs)
    for wf_adc = 1:size(data{img},3)
      wf = param.sar_equal.imgs{img}(wf_adc,1);
      adc = param.sar_equal.imgs{img}(wf_adc,2);
      chan_equal = 10.^((param.radar.wfs(wf).chan_equal_dB(param.radar.wfs(wf).rx_paths(adc)) ...
        - metadata.param_sar.radar.wfs(wf).chan_equal_dB(param.radar.wfs(wf).rx_paths(adc)) )/20) ...
        .* exp(1i*( ...
        param.radar.wfs(wf).chan_equal_deg(param.radar.wfs(wf).rx_paths(adc)) ...
        - metadata.param_sar.radar.wfs(wf).chan_equal_deg(param.radar.wfs(wf).rx_paths(adc)) )/180*pi);
      data{img}(:,:,wf_adc) = data{img}(:,:,wf_adc) ./ chan_equal;
      chan_equal
    end
  end
  
  %% Motion compensation
  % =======================================================================
  param.array.squint = [0; 0; -1];
  for img = 1:length(param.sar_equal.imgs)
    % Determine number of range bins
    Nt = size(data{img},1);
    % Determine number of range lines
    Nx = size(data{img},2);
    
    for wf_adc = 1:size(data{img},3)
      wf = param.sar_equal.imgs{img}(wf_adc,1);
      adc = param.sar_equal.imgs{img}(wf_adc,2);
      %         %Interested in finding the magnitude of the projection of y in the z
      %         %direction [y_inz = dot(y,z)/mag(z)]
      %         zmag = sqrt(dot(fcs{img}{wf_adc}.z,fcs{img}{wf_adc}.z));
      %         dTsys_mocomp = dot(fcs{img}{wf_adc}.z,fcs{img}{wf_adc}.y)./zmag;
      %         %Compensate for desired squint angle
      %         dTsys_mocomp = dTsys_mocomp/cos(squint_angle);
      
      % Calculate complex baseband frequencies
      df = metadata.param_sar.radar.wfs(wf).freq(2)-metadata.param_sar.radar.wfs(wf).freq(1);
      fc = metadata.param_sar.radar.wfs.fc;
      % freq: double vector. Carrier band frequency axis since we are
      % correcting for the envelope and phase.
      freq =  fc + df * ifftshift( -floor(Nt/2) : floor((Nt-1)/2) ).';
      
      % Correct any changes in Tsys
      Tsys = param.radar.wfs(wf).Tsys(param.radar.wfs(wf).rx_paths(adc));
      Tsys_old = metadata.param_sar.radar.wfs(wf).Tsys(param.radar.wfs(wf).rx_paths(adc));
      dTsys = Tsys-Tsys_old;
      for rline = 1:Nx
        % range_offset: dot product between squint direction and phase
        % center offset. If the phase center was closer to the target, then
        % the phase will be more positive (less negative).
        range_offset = dot(param.array.squint,[0 metadata.fcs{img}{wf_adc}.pos(2,rline) metadata.fcs{img}{wf_adc}.pos(3,rline)]);
        % time_offset: convert range offset to two way travel time
        time_offset = range_offset * 2/c;
        % If time offset is non-zero, apply time shift in frequency domain
        if time_offset+dTsys ~= 0
          % 1. Positive dTsys means Tsys > Tsys_old and the time delay is
          % too large. We compensate by reducing the time delay to all
          % targets by dTsys. Reducing time delay means making the phase
          % more positive.
          %
          % 2. Positive time_offset means the range is less; to undo this,
          % the phase is made more negative to increase the range and
          % time_delay.
          data{img}(:,rline,wf_adc) = ifft(bsxfun(@times,fft(data{img}(:,rline,wf_adc),[],1), ...
            exp(-1j*2*pi*freq*(dTsys+time_offset))));
        end
      end
    end
  end
  if 0
    % Debug plots
    rline = 1; % <== SPECIFY WHICH RANGE LINE TO PLOT
    colors_cell = {'k','r','y','g','b','c','m'};
    h_plot = [];
    legend_str = {};
    figure; clf;
    for img = 1:length(data)
      for wf_adc = 1:size(data{img},3)
        wf = param.sar_equal.imgs{img}(wf_adc,1);
        adc = param.sar_equal.imgs{img}(wf_adc,2);
        rline = max(1,min(rline,size(data{img},2)));
        h_tmp = plot(metadata.wfs(wf).time, squeeze(imag(data{img}(:,rline,wf_adc))), colors_cell{1+mod(img-1,length(colors_cell))});
        if wf_adc == 1
          legend_str{img} = sprintf('Img %d wf %d adc %d', img, wf, adc);
          h_plot(img) = h_tmp;
        end
        hold on;
      end
    end
    legend(h_plot, legend_str);
  end
  
  %% Combine wf-adc channels
  % =======================================================================
  for img = 1:length(param.sar_equal.imgs)
    data{img} = mean(data{img},3);
  end
  
  %% Determine fast time bin for equalization (reference)
  % =======================================================================
  time = metadata.param_sar.radar.wfs(ref_wf).time;
  dt = time(2)-time(1);
  t0 = time(1);
  fc = metadata.param_sar.radar.wfs(ref_wf).fc;
  Tpd = metadata.param_sar.radar.wfs(ref_wf).Tpd;
  if isnumeric(param.sar_equal.start_time)
    ref_start_bin = find(time>=param.sar_equal.start_time,1)*ones(1,size(data{ref_img},2));
    if isempty(ref_start_bin)
      error('No time (%g-%g) is >= param.sar_equal.start_time (%g).', time(1), time(end), param.sar_equal.start_time);
    end
  elseif isstruct(param.sar_equal.start_time)
    param.sar_equal.start_time.eval.Tpd = Tpd;
    param.sar_equal.start_time.eval.dt = dt;
    param.sar_equal.start_time.eval.Tstart = time(1);
    param.sar_equal.start_time.eval.Tend = time(end);
    layers = opsLoadLayers(param,param.sar_equal.start_time);
    layers.twtt = interp_finite(layers.twtt,0);
    layers.twtt = interp1(layers.gps_time, layers.twtt, metadata.fcs{ref_img}{1}.gps_time);
    ref_start_bin = round(interp1(time, 1:length(time), layers.twtt,'linear','extrap'));
    ref_start_bin = interp_finite(ref_start_bin);
    ref_start_bin = min(max(1,ref_start_bin),size(data{ref_img},1));
  elseif ischar(param.sar_equal.start_time)
    es = [];
    es.Tpd = Tpd;
    es.dt = dt;
    es.Tstart = time(1);
    es.Tend = time(end);
    s = 0;
    eval(param.sar_equal.start_time);
    ref_start_bin = find(time>=s,1)*ones(1,size(data{ref_img},2));
    if isempty(ref_start_bin)
      error('No time (%g-%g) is >= param.sar_equal.start_time (%g).', time(1), time(end), param.sar_equal.start_time);
    end
  end
  
  %% Equalization setup
  % =====================================================================
  
  % Setup for estimating equalization coefficients
  switch(param.sar_equal.delay.method)
    case 'threshold'
      delay_method = 1;
    case 'xcorr_complex'
      delay_method = 2;
    case 'xcorr_magnitude'
      delay_method = 3;
    otherwise
      error('delay.method %d is not supported', param.sar_equal.delay.method);
  end
  
  Mt = param.sar_equal.delay.Mt;
  
  search_bins = param.sar_equal.delay.search_bins(1) : param.sar_equal.delay.search_bins(end);
  ref_bins = param.sar_equal.delay.ref_bins(1) : param.sar_equal.delay.ref_bins(end);
  
  if delay_method == 2
    Hcorr_wind = boxcar(length(ref_bins));
  else
    Hcorr_wind = boxcar(Mt*length(ref_bins));
  end
  zero_padding_offset = length(search_bins) - length(ref_bins);
  
  peak_val = nan(length(param.sar_equal.imgs),floor(Nx/param.sar_equal.coh_ave));
  peak_offset = nan(length(param.sar_equal.imgs),floor(Nx/param.sar_equal.coh_ave));
  gps_time = nan(length(param.sar_equal.imgs),floor(Nx/param.sar_equal.coh_ave));
  surface = nan(length(param.sar_equal.imgs),floor(Nx/param.sar_equal.coh_ave));
  dsurface = nan(length(param.sar_equal.imgs),floor(Nx/param.sar_equal.coh_ave));
  
  %% Cross-correlation to extract time delay, phase, and amplitude offsets
  % =====================================================================
  for img = 1:length(param.sar_equal.imgs)
    if img == ref_img
      continue;
    end
    % Determine number of range bins
    Nt = size(data{img},1);
    
    wf_adc = 1;
    wf = param.sar_equal.imgs{img}(wf_adc,1);
    adc = param.sar_equal.imgs{img}(wf_adc,2);
    
    %% Determine fast time bin for equalization
    % =======================================================================
    time = metadata.param_sar.radar.wfs(wf).time;
    dt = time(2)-time(1);
    t0 = time(1);
    fc = metadata.param_sar.radar.wfs(wf).fc;
    Tpd = metadata.param_sar.radar.wfs(wf).Tpd;
    if isnumeric(param.sar_equal.start_time)
      start_bin = find(time>=param.sar_equal.start_time,1)*ones(1,size(data{img},2));
      if isempty(start_bin)
        error('No time (%g-%g) is >= param.sar_equal.start_time (%g).', time(1), time(end), param.sar_equal.start_time);
      end
    elseif isstruct(param.sar_equal.start_time)
      param.sar_equal.start_time.eval.Tpd = Tpd;
      param.sar_equal.start_time.eval.dt = dt;
      param.sar_equal.start_time.eval.Tstart = time(1);
      param.sar_equal.start_time.eval.Tend = time(end);
      start_bin = round(interp1(time, 1:length(time), layers.twtt,'linear','extrap'));
      start_bin = interp_finite(start_bin);
      start_bin = min(max(1,start_bin),size(data{img},1));
    elseif ischar(param.sar_equal.start_time)
      es = [];
      es.Tpd = Tpd;
      es.dt = dt;
      es.Tstart = time(1);
      es.Tend = time(end);
      s = 0;
      eval(param.sar_equal.start_time);
      start_bin = find(time>=s,1)*ones(1,size(data{img},2));
      if isempty(start_bin)
        error('No time (%g-%g) is >= param.sar_equal.start_time (%g).', time(1), time(end), param.sar_equal.start_time);
      end
    end
    
    %% Plot echogram images
    % =======================================================================
    if 1
      wf = param.sar_equal.imgs{img}(1,1);
      adc = param.sar_equal.imgs{img}(1,2);
      clf(h_fig(4));
      h_axes(4) = axes('parent',h_fig(4));
      title(sprintf('img %d wf %d adc %s',img, wf, adc),'parent',h_axes(4));
      imagesc(db(data{img}),'parent',h_axes(4));
      grid(h_axes(4),'on');
      xlabel(h_axes(4),'Range line');
      ylabel(h_axes(4),'Range bin');
      h_color = colorbar(h_axes(4));
      hold(h_axes(4),'on');
      plot(start_bin,'parent',h_axes(4))
      plot(start_bin+search_bins(1),'parent',h_axes(4))
      plot(start_bin+search_bins(end),'parent',h_axes(4),'Color',[0 1 0])
      
      clf(h_fig(5));
      h_axes(5) = axes('parent',h_fig(5));
      title(sprintf('img %d wf %d adc %s',img, wf, adc),'parent',h_axes(5));
      imagesc(db(data{ref_img}),'parent',h_axes(5));
      grid(h_axes(5),'on');
      xlabel(h_axes(5),'Range line');
      ylabel(h_axes(5),'Range bin');
      h_color = colorbar(h_axes(5));
      hold(h_axes(5),'on');
      plot(ref_start_bin,'parent',h_axes(5))
      plot(ref_start_bin+ref_bins(1),'parent',h_axes(5))
      plot(ref_start_bin+ref_bins(end),'parent',h_axes(5),'Color',[0 1 0])
    end
    
    fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('img_wf_%02d_adc_%02d',wf,adc)) sprintf('_%03d.jpg',frm)];
    fprintf('Saving %s\n', fig_fn);
    fig_fn_dir = fileparts(fig_fn);
    if ~exist(fig_fn_dir,'dir')
      mkdir(fig_fn_dir);
    end
    ct_saveas(h_fig(4),fig_fn);
    
    fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('ref_img_wf_%02d_adc_%02d',ref_wf,ref_adc)) sprintf('_%03d.jpg',frm)];
    fprintf('Saving %s\n', fig_fn);
    fig_fn_dir = fileparts(fig_fn);
    if ~exist(fig_fn_dir,'dir')
      mkdir(fig_fn_dir);
    end
    ct_saveas(h_fig(5),fig_fn);
    
    %% Cross-correlation to extract time delay, phase, and amplitude offsets
    % =====================================================================
    rline_out = 0;
    corr_out_accum = 0;
    coh_ave = 0;
    for rline = 1:Nx
      if ~mod(rline-1,10^floor(log10(Nx)-1))
        fprintf('  Estimating rline %d of %d (%s)\n', rline, Nx, datestr(now));
      end
      if start_bin(rline) + search_bins(1) < 1 ...
          || start_bin(rline) + search_bins(end) > size(data{img},1) ...
          || ref_start_bin(rline)+ref_bins(1) < 1 ...
          || ref_start_bin(rline)+ref_bins(end) > size(data{ref_img},1)
        continue;
      end
      in = data{img}(start_bin(rline) + search_bins,rline);
      ref_in = data{ref_img}(ref_start_bin(rline)+ref_bins,rline);
      if 0
        figure(1); clf;
        plot(db(in))
        hold on
        plot(db(ref_in))
        grid on;
      end
      % Notes:
      % xcorr zero pads the end of the shorter waveform
      % If "in" lags behind "ref_in", then the lag will be positive.
      % If "in" leads ahead of "ref_in", then the lag will be negative.
      [corr_out,lags0] = xcorr(in, ref_in .* Hcorr_wind);
      lags = lags0(1) + search_bins(1) - ref_bins(1) + (0:length(lags0)-1);
      if 0
        figure(1); clf;
        plot(lags,db(corr_out))
        grid on;
      end
      corr_out_accum = corr_out_accum + corr_out;
      coh_ave = coh_ave + 1;
      if coh_ave >= param.sar_equal.coh_ave
        corr_int = interpft(corr_out_accum,Mt*length(corr_out_accum));
        lags_Mt = lags(1) + 1/Mt*(0:Mt*length(lags)-1);
        if 0
          figure(1); clf;
          plot(lags_Mt,db(corr_int))
          grid on;
        end
        corr_out_accum = 0;
        coh_ave = 0;
        rline_out = rline_out + 1;
        [peak_val(img,rline_out) peak_offset(img,rline_out)] = max(corr_int);
        peak_offset(img,rline_out) = lags_Mt(peak_offset(img,rline_out));
        
        
        % IMPORTANT: WE SHOULD STORE AMPLITUDE SEPARATELY!!!!!!!!!!!
        % Using the max method is good, but the max method is not good for
        % phase averaging
        %
        % PHASE SHOULD BE KEPT with real peak amplitudes for the purposes of
        % averaging 
        
        
        
        
        
        peak_val(img,rline_out) = abs( ...
          max(data{img}(start_bin(rline) + search_bins,rline)) ...
          ./ max(data{ref_img}(ref_start_bin(rline)+ref_bins,rline))) ...
          .* exp(1i*angle(peak_val(img,rline_out)));
        gps_time(img,rline_out) = metadata.fcs{1}{1}.gps_time(rline);
        surface(img,rline_out) = metadata.fcs{1}{1}.surface(rline);
        if rline < Nx
          dsurface(img,rline_out) = metadata.fcs{1}{1}.surface(rline+1) - metadata.fcs{1}{1}.surface(rline);
        else
          dsurface(img,rline_out) = metadata.fcs{1}{1}.surface(rline) - metadata.fcs{1}{1}.surface(rline-1);
        end

      end
    end
    
  end
  
  % plot(metadata.fcs{1}{1}.gps_time, metadata.fcs{1}{1}.surface); hold on;
  % plot(gps_time(img,:), surface(img,:));
  % plot(gps_time(img,:), abs(dsurface(img,:)));
  
  %% Compute mean
  
  [offset_ave,mask] = mean_without_outliers(peak_offset, 1, 0.2, 2);
  
  peak_val_mean = peak_val;
  peak_val_mean(mask) = NaN;
  peak_val_mean = nanmean(peak_val_mean, 2);
  
  Tsys_deg = angle(exp(1i*2*pi*offset_ave*dt * fc))*180/pi
  Tsys = -offset_ave*dt
  chan_equal_dB = db(nanmean(abs(peak_val_mean).^2, 2),'power')
  chan_equal_deg = angle(peak_val_mean)*180/pi
  
  %% Print results
  new_wfs = param.radar.wfs;
  for img = 1:length(param.sar_equal.imgs)
    wf = param.sar_equal.imgs{img}(1,1);
    adc = param.sar_equal.imgs{img}(1,2);
    
    if img == ref_img
      fprintf('%% img %d wf %d adc %d (reference image)\n', img, wf, adc);
      fprintf('  Tsys = old_Tsys + %g;\n', 0);
      fprintf('  chan_equal_deg = old_chan_equal_deg + %g;\n', 0);
      fprintf('  chan_equal_dB = old_chan_equal_dB + %g;\n', 0);
    else
      fprintf('%% img %d wf %d adc %d\n', img, wf, adc);
      fprintf('  Tsys = Tsys + %g;\n', Tsys(img));
      fprintf('  chan_equal_deg = chan_equal_deg + %g;\n', chan_equal_deg(img) + Tsys_deg(img));
      fprintf('  chan_equal_dB = chan_equal_dB + %g;\n', chan_equal_dB(img));
      fprintf('  chan_equal_deg = chan_equal_deg + %g; %% Use this if not changing Tsys\n', chan_equal_deg(img));
      
      for wf_adc = 1:size(param.sar_equal.imgs{img},1)
        wf = param.sar_equal.imgs{img}(wf_adc,1);
        adc = param.sar_equal.imgs{img}(wf_adc,2);
        new_wfs(wf).Tsys(adc) = new_wfs(wf).Tsys(adc) + Tsys(img);
        new_wfs(wf).chan_equal_deg(adc) = new_wfs(wf).chan_equal_deg(adc) + chan_equal_deg(img) + Tsys_deg(img);
        new_wfs(wf).chan_equal_dB(adc) = new_wfs(wf).chan_equal_dB(adc) + chan_equal_dB(img);
      end
    end
  end
  for wf = 1:length(new_wfs)
    fprintf('param_override.radar.wfs(%d).Tsys = %s;\n', wf, mat2str_generic(new_wfs(wf).Tsys));
    fprintf('param_override.radar.wfs(%d).chan_equal_deg = %s;\n', wf, mat2str_generic(new_wfs(wf).chan_equal_deg));
    fprintf('param_override.radar.wfs(%d).chan_equal_dB = %s;\n', wf, mat2str_generic(new_wfs(wf).chan_equal_dB));
  end

  %% Plot results
  for fig_num = 1:3
    clf(h_fig(fig_num));
    h_axes(fig_num) = axes('parent',h_fig(fig_num));
    title(h_axes(fig_num), sprintf('ref\_img %d ref\_wf %d ref\_adc %d',ref_img, ref_wf, ref_adc));
  end
  legend_str = {};
  for img = 1:length(param.sar_equal.imgs)
    if img ~= ref_img
      wf = param.sar_equal.imgs{img}(1,1);
      adc = param.sar_equal.imgs{img}(1,2);
      legend_str{end+1} = sprintf('img %d wf %d adc %d',img, wf, adc);
      
      plot(h_axes(1),angle(peak_val(img,:))*180/pi)
      grid(h_axes(1),'on');
      hold(h_axes(1),'on');
      xlabel(h_axes(1),'Range line');
      ylabel(h_axes(1),'Angle (deg)');
      
      plot(h_axes(2),db(peak_val(img,:)))
      grid(h_axes(2),'on');
      hold(h_axes(2),'on');
      xlabel(h_axes(2),'Range line');
      ylabel(h_axes(2),'Relative power (dB)');
      
      plot(h_axes(3),peak_offset(img,:),'.')
      grid(h_axes(3),'on');
      hold(h_axes(3),'on');
      xlabel(h_axes(3),'Range line');
      ylabel(h_axes(3),'Time delay (bins)');
    end
  end
  legend(h_axes(1),legend_str);
  legend(h_axes(2),legend_str);
  legend(h_axes(3),legend_str);
  
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('angle_%02d_adc_%02d',fn_wf,fn_adc)) sprintf('_%03d.jpg',frm)];
  fprintf('Saving %s\n', fig_fn);
  fig_fn_dir = fileparts(fig_fn);
  if ~exist(fig_fn_dir,'dir')
    mkdir(fig_fn_dir);
  end
  ct_saveas(h_fig(1),fig_fn);
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('angle_%02d_adc_%02d',fn_wf,fn_adc)) sprintf('_%03d.fig',frm)];
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(h_fig(1),fig_fn);
  
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('abs_%02d_adc_%02d',fn_wf,fn_adc)) sprintf('_%03d.jpg',frm)];
  fprintf('Saving %s\n', fig_fn);
  fig_fn_dir = fileparts(fig_fn);
  if ~exist(fig_fn_dir,'dir')
    mkdir(fig_fn_dir);
  end
  ct_saveas(h_fig(2),fig_fn);
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('abs_%02d_adc_%02d',fn_wf,fn_adc)) sprintf('_%03d.fig',frm)];
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(h_fig(3),fig_fn);
  
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('td_%02d_adc_%02d',fn_wf,fn_adc)) sprintf('_%03d.jpg',frm)];
  fprintf('Saving %s\n', fig_fn);
  fig_fn_dir = fileparts(fig_fn);
  if ~exist(fig_fn_dir,'dir')
    mkdir(fig_fn_dir);
  end
  ct_saveas(h_fig(3),fig_fn);
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('td_%02d_adc_%02d',fn_wf,fn_adc)) sprintf('_%03d.fig',frm)];
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(h_fig(3),fig_fn);

  %% Save outputs
  mat_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('sar_equal_wf_%02d_adc_%02d',fn_wf,fn_adc)) sprintf('_%03d.mat',frm)];
  fprintf('Saving %s\n', mat_fn);
  mat_fn_dir = fileparts(mat_fn);
  if ~exist(mat_fn_dir,'dir')
    mkdir(mat_fn_dir);
  end
  param_sar_equal = param;
  ct_save(mat_fn,'peak_offset','peak_val','Tsys','Tsys_deg','chan_equal_dB','chan_equal_deg','gps_time','surface','param_sar_equal');
end
