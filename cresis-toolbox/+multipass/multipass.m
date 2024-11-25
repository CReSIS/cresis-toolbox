% function multipass(param,param_override)
% multipass(param,param_override)
%
% Synchronize, register, correct passes from combine_passes and then apply
% array processing.
%
% param.multipass.comp_mode: integer from 1 to 4 controlling the mode
% 1: 1 to find equalization coefficients
%   Motion compensation of FCS z-motion
%   (Motion compensation with phase correction)
%   Quits after computing equalization coefficients
% 2: to do coregistration and (if input_type=='sar') array process
%   This is the mode that must be used when using input_type='echo'
%   Co-register images using GPS and nadir squint angle assumption
%   (Motion compensation without phase correction)
%   Runs array processing if input_type=='sar' and is used for cross-track
%   slope estimation and basal swath imaging
% 3: to differential INSAR
%   Co-register images using GPS and nadir squint angle assumption (Motion
%   compensation with phase correction AND slope correction) Saves output
%   for (differential) interferometry (coherence and interferometric phase
%   images created) and vertical velocity estimation.
% 4: to plot results
%   Co-register images using GPS and nadir squint angle assumption
%   Quits after plotting results
%
% param.multipass.fn: string containing the full file to the file created
% by multipass.combine_passes.
%
% param.multipass.layer: opsLoadLayers layer parameter structure that
% specifies all the layers to load for each pass and to synchronize. The
% default is struct('name',{'surface','bottom'}).
%

%% Setup
% =========================================================================
fprintf('=====================================================================\n');
fprintf('%s [Mode %d]: %s  (%s)\n', mfilename, param.multipass.comp_mode, ...
  param.multipass.pass_name, datestr(now));
fprintf('=====================================================================\n');

param = merge_structs(param,param_override);

physical_constants;
proj_load_standard;

%% Load multipass.combine_passes file
fn = param.multipass.fn;
[fn_dir,fn_name] = fileparts(fn);
load(fn,'param_combine_passes','pass');

%% Input check
% =========================================================================

% Confirm either SAR or echogram data
if ~isfield(pass(1),'input_type')
  input_type = 'echo';
else
  input_type = pass(1).input_type;
end

% Confirm echo input type is running comp_mode==2
if param.multipass.comp_mode ~= 2 && strcmpi(input_type,'echo')
  warning('Only param.multipass.comp_mode == 2 may be used with input_type=="echo".');
  param.multipass.comp_mode = 2;
end

% baseline_master_idx: All images are registered to the pass indicated by
% the baseline_master_idx. Default is the first pass.
if ~isfield(param.multipass,'baseline_master_idx') || isempty(param.multipass.baseline_master_idx)
  param.multipass.baseline_master_idx = 1;
end
baseline_master_idx = param.multipass.baseline_master_idx;

% coregistration_time_shift: Fast time time shift. Default is zero.
% Positive values cause the image to move towards the radar. Units are in
% range bins.
if ~isfield(param.multipass,'coregistration_time_shift') || isempty(param.multipass.coregistration_time_shift)
  param.multipass.coregistration_time_shift = zeros(1,length(pass));
end
if length(param.multipass.coregistration_time_shift) < length(pass)
  param.multipass.coregistration_time_shift(length(pass)) = 0;
end
coregistration_time_shift = param.multipass.coregistration_time_shift;

% debug_plots: cell array of strings that enable certain debug outputs
if ~isfield(param.multipass,'debug_plots') || isempty(param.multipass.debug_plots)
  if strcmpi(input_type,'echo')
    param.multipass.debug_plots = {'debug'};
  else
    param.multipass.debug_plots = {'debug','coherent'};
  end
end
enable_debug_plot = any(strcmp('debug',param.multipass.debug_plots));
enable_coherent_plot = any(strcmp('coherent',param.multipass.debug_plots));

% equalization: Equalization (complex weight) for each pass. Default weight is all ones.
if ~isfield(param.multipass, 'equalization')
  % Written with /20 and /180*pi to emphasize the dB and deg format.
  % param.multipass.equalization = exp(1i*(zeros(1,length(pass))/20)/180*pi);
  param.multipass.equalization = ones(1,length(pass));
end
equalization = param.multipass.equalization;

% layer: layer struct to opsLoadLayers which indicates which layers will be
% loaded and coregistered along with each image
if ~isfield(param.multipass,'layer') || isempty(param.multipass.layer)
  param.multipass.layer = struct('name',{'surface','bottom'},'source','layerdata');
end

% master_idx: Index to pass that will be used as the master pass for the
% interferograms. Default is one.
if ~isfield(param.multipass,'master_idx') || isempty(param.multipass.master_idx)
  param.multipass.master_idx = 1;
end
master_idx = param.multipass.master_idx;

% output_fn_midfix: string to add to output filenames (default is empty string)
if ~isfield(param.multipass,'output_fn_midfix') || isempty(param.multipass.output_fn_midfix)
  param.multipass.output_fn_midfix = '';
end
output_fn_midfix = param.multipass.output_fn_midfix;

% pass_en_mask: logical mask for each pass (default is all true)
if ~isfield(param.multipass,'pass_en_mask') || isempty(param.multipass.pass_en_mask)
  param.multipass.pass_en_mask = [];
end
% Assume any undefined passes are enabled
param.multipass.pass_en_mask(end+1:length(pass)) = true;
param.multipass.pass_en_mask = logical(param.multipass.pass_en_mask);
pass_en_mask = param.multipass.pass_en_mask;
if ~pass_en_mask(master_idx)
  error('The master index pass %d must be enabled in param.multipass.pass_en_mask.', master_idx);
end
pass_en_idxs = find(pass_en_mask);

% slope_correction_en. Logical boolean that enables slope correction
if ~isfield(param.multipass,'slope_correction_en') || isempty(param.multipass.slope_correction_en)
  param.multipass.slope_correction_en = false;
end
if param.multipass.comp_mode ~= 3 && param.multipass.slope_correction_en
  warning('Only param.multipass.comp_mode == 3 may have param.multipass.slope_correction_en == true.');
  param.multipass.slope_correction_en = false;
end

% time_gate: Two element vector, [min_time max_time] that restricts the
% time range of the master image to the time gate range min_time to
% max_time. Default is [-inf inf] which results in no restriction at all.
if ~isfield(param.multipass,'time_gate') || isempty(param.multipass.time_gate)
  param.multipass.time_gate = [-inf inf];
end

% units: string containing "meters" or "bins" for plots
if ~isfield(param.multipass,'units') || isempty(param.multipass.units)
  param.multipass.units = 'meters'; % 'meters' or 'bins'
end

% post.ops.location: Determine which projection to use
if strcmpi(param_combine_passes.post.ops.location,'arctic')
  proj = arctic_proj;
elseif strcmpi(param_combine_passes.post.ops.location,'antarctic')
  proj = antarctic_proj;
else
  error('Unsupported location param_combine_passes.post.ops.location.', baseline_master_idx);
end

%% Convert FCS to ECEF and Geodetic
% =========================================================================
min_twtt = inf;
max_twtt = -inf;
max_rlines = -inf;
for pass_idx = 1:length(pass)
  if ~pass_en_mask(pass_idx) && pass_idx ~= baseline_master_idx
    pass(pass_idx).data = []; % Save some memory
    continue;
  end
  
  % Debug: GPS offset
  if 0
    pass_idx = 5;
    time_offset = -5;
    pass(pass_idx).ecef = interp1(pass(pass_idx).gps_time,pass(pass_idx).ecef.',pass(pass_idx).gps_time+time_offset,'linear','extrap').';
    pass(pass_idx).x = interp1(pass(pass_idx).gps_time,pass(pass_idx).x.',pass(pass_idx).gps_time+time_offset,'linear','extrap').';
  end
  
  % Convert SAR coordinate system (aka flight coordinate system, FCS) to
  % earth centered earth fixed (ECEF)
  pass(pass_idx).ecef = pass(pass_idx).origin;
  for rline = 1:size(pass(pass_idx).origin,2)
    pass(pass_idx).ecef(:,rline) = pass(pass_idx).ecef(:,rline) ...
      + [pass(pass_idx).x(:,rline) pass(pass_idx).y(:,rline) pass(pass_idx).z(:,rline)]*pass(pass_idx).pos(:,rline);
  end
  
  % Convert ECEF to Geodetic
  [pass(pass_idx).lat,pass(pass_idx).lon,pass(pass_idx).elev] = ecef2geodetic(referenceEllipsoid('wgs84'), ...
    pass(pass_idx).ecef(1,:), pass(pass_idx).ecef(2,:), pass(pass_idx).ecef(3,:));
  
  % Convert Geodetic to projected coordinates
  [pass(pass_idx).proj_x,pass(pass_idx).proj_y] = projfwd(proj,pass(pass_idx).lat,pass(pass_idx).lon);
  
  min_twtt = min(min_twtt,pass(pass_idx).time(1));
  max_twtt = max(max_twtt,pass(pass_idx).time(end));
  max_rlines = max(max_rlines,length(pass(pass_idx).gps_time));
end
param.multipass.time_gate(1) = max(param.multipass.time_gate(1),min_twtt);
param.multipass.time_gate(2) = min(param.multipass.time_gate(2),max_twtt);

%% Load layers
% =========================================================================
for pass_idx = 1:length(pass)
  if ~pass_en_mask(pass_idx)
    continue
  end

  % Update the parameters with current gRadar settings so that the paths
  % are correct. A common issue is that multipass.combine_passes files are
  % created in one environemnt and then loaded here under a different
  % environment and the paths are different.
  param_override = merge_structs(gRadar,param_override);
  param_paths_updated = merge_structs(pass(pass_idx).param_pass,param_override);
  
  % Load layers
  pass(pass_idx).layers = opsLoadLayers(param_paths_updated,param.multipass.layer);
  
  % Interpolate all layers onto a common reference (ref)
  for lay_idx = 1:length(pass(pass_idx).layers)
    pass(pass_idx).layers(lay_idx).twtt ...
      = interp_finite(interp1(pass(pass_idx).layers(lay_idx).gps_time, ...
      pass(pass_idx).layers(lay_idx).twtt, ...
      pass(pass_idx).gps_time,'linear'),0);
  end
end

%% Plot Raw Passes
% =========================================================================
if enable_debug_plot
  h_fig_map = figure(1001); clf(h_fig_map);
  h_plot_map = [];
  h_legend_map = {};
  h_axes_map = axes('parent',h_fig_map);
  hold(h_axes_map,'on');
  axis(h_axes_map, 'equal');
  xlabel(h_axes_map, 'X (km)');
  ylabel(h_axes_map, 'Y (km)');
  grid(h_axes_map, 'on');
  
  h_fig_elev = figure(1002); clf(h_fig_elev);
  h_plot_elev = [];
  h_legend_elev = {};
  h_axes_elev = axes('parent',h_fig_elev);
  hold(h_axes_elev,'on');
  xlabel(h_axes_elev, 'Range line');
  ylabel(h_axes_elev, 'WGS-84 elevation (m)');
  grid(h_axes_elev, 'on');
  
  clear h_axes_echo;
  for pass_idx = 1:length(pass)
    if ~pass_en_mask(pass_idx)
      continue
    end
    
    %% Plot: 1. plot echogram
    h_fig_echo = figure(pass_idx); clf(h_fig_echo);
    set(h_fig_echo,'WindowStyle','docked')
    set(h_fig_echo,'NumberTitle','off')
    set(h_fig_echo,'Name',num2str(pass_idx))
    h_axes_echo(pass_idx) = axes('parent',h_fig_echo);
    imagesc([],pass(pass_idx).time*1e6,lp(pass(pass_idx).data),'parent', h_axes_echo(pass_idx));
    title_str = pass(pass_idx).param_pass.day_seg;
    title_str = regexprep(title_str,'_','\\_');
    title(h_axes_echo(pass_idx),title_str);
    colormap(h_axes_echo(pass_idx), 1-gray(256));
    hold(h_axes_echo(pass_idx),'on');
    if 1
      xlabel(h_axes_echo(pass_idx), 'Range line');
      ylabel(h_axes_echo(pass_idx), 'Two way travel time (\mus)');
    else
      [h_axes_echo_background,hp1,hp2] = plotyy(0:Nt-1,0:Nt-1,pass(pass_idx).time*1e6,pass(pass_idx).time*1e6,'parent',h_fig_echo);
      ylim(h_axes_echo_background(1),[0 Nt-1]);
      ylim(h_axes_echo_background(2),pass(pass_idx).time([1 end])*1e6);
      xlabel(h_axes_echo_background(1), 'Range line');
      ylabel(h_axes_echo_background(1), 'Range bin');
      ylabel(h_axes_echo_background(2), 'Time (\mus)');
      set(hp1,'XData',NaN,'YData',NaN);
      set(hp2,'XData',NaN,'YData',NaN);
      set(h_axes_echo_background(2),'YDir','reverse')
    end
    
    %% Plot: 2. plot layers
    Nx = size(pass(pass_idx).data,2);
    for lay_idx = 1:length(pass(pass_idx).layers)
      plot(1:Nx,pass(pass_idx).layers(lay_idx).twtt*1e6,'parent',h_axes_echo(pass_idx));
    end
    
    %% Plot: 3. plot map
    h_plot_map(end+1) = plot(pass(pass_idx).proj_x/1e3, pass(pass_idx).proj_y/1e3,'.','parent',h_axes_map);
    h_legend_map{end+1} = sprintf('%d',pass_idx);
    color = get(h_plot_map(end),'Color');
    h_text = text(pass(pass_idx).proj_x(1)/1e3, pass(pass_idx).proj_y(1)/1e3, sprintf('%d', pass_idx), 'Color', color,'parent',h_axes_map);
    
    %% Plot: 4. plot elevation
    if baseline_master_idx == pass_idx
      h_plot_elev(end+1) = plot(pass(pass_idx).elev,'LineWidth',2,'UserData',pass_idx,'parent',h_axes_elev);
    else
      h_plot_elev(end+1) = plot(pass(pass_idx).elev,'UserData',pass_idx,'parent',h_axes_elev);
    end
    h_legend_elev{end+1} = sprintf('%d',pass_idx');
  end
  legend(h_plot_map,h_legend_map);
  legend(h_plot_elev,h_legend_elev);
  h_axes_echo = h_axes_echo(pass_en_mask);
  % x-axes from each pass do not line up since the images are not
  % registered yet so this does not really work in the x-axis unless the
  % along-track sampling rate is similar between each pass
  linkaxes(h_axes_echo);
  xlim(h_axes_echo(1),[1 max_rlines]);
  ylim(h_axes_echo(1),param.multipass.time_gate*1e6);
end

%% Define reference path
% =========================================================================

if 1
  % Option 1: Use a single pass as the reference.
  ref = pass(baseline_master_idx);
  
else
  % Option 2: Take a single pass as master and construct along track vectors relative
  % to it. Fit a polynomial to all the data using the along track vector
  % from step 1. Use this as the reference. This may be useful to do if no
  % single pass follows the center of the tube of passes.
  
  % With reference, run SAR coord system in a special mode where the mean is
  % not taken across Lsar, but instead each point is directly passed to the
  % output.
end
along_track = geodetic_to_along_track(ref.lat,ref.lon,ref.elev);

if 0
  h_fig_ref_idx = figure(102); clf;
  hold on;
end

%% Pass Processing
% =========================================================================
data = [];
surf_flatten_en = false;
if surf_flatten_en
  ref.surface_bin = interp1(ref.time, 1:length(ref.time), ref.surface);
end
for pass_out_idx = 1:length(pass_en_idxs)
  pass_idx = pass_en_idxs(pass_out_idx);
  fprintf('Coregister: %d of %d (pass %d) (%s)\n', pass_out_idx, length(pass_en_idxs), pass_idx, datestr(now,'yyyymmdd_HHMMSS'));
  
  %% Pass: 1. Position in ref coordinate system
  pass(pass_idx).ref_idx = zeros(1,size(pass(pass_idx).origin,2));
  last_idx = 0;
  for rline = 1:size(pass(pass_idx).ecef,2)
    % offset: offset from position rline of pass pass_idx from every point
    %         on the ref line
    offset = bsxfun(@minus, pass(pass_idx).ecef(:,rline), ref.ecef);
    % dist: converts offset into along-track distance of the slave line
    dist = offset.'*pass(pass_idx).x(:,rline);
    % min_idx: finds the point on the reference line that is closest to
    %          this point
    [min_dist,min_idx] = min(abs(dist));
    %       if min_idx == last_idx
    %         keyboard
    %       end
    last_idx = min_idx;
    pass(pass_idx).ref_idx(rline) = min_idx;
    
    % x_offset: along-track offset on master line of the closest point
    x_offset = offset(:,min_idx).'*ref.x(:,min_idx);
    % Compute FCS of slave point in master line coordinate system
    %   FCS: flight (aka SAR) coordinate system
    pass(pass_idx).along_track(rline) = along_track(min_idx) + x_offset;
    pass(pass_idx).ref_y(rline) = offset(:,min_idx).'*ref.y(:,min_idx);
    pass(pass_idx).ref_z(rline) = offset(:,min_idx).'*ref.z(:,min_idx);
    
    if 0 %strcmp('sar',input_type)
      % Compute the location of all pixels from this range line in ECEF
      pass(pass_idx).time;
      time = pass(pass_idx).time(2)-pass(pass_idx).time(1);
      
      range = time * c/2;
      range(time>pass(pass_idx).surface(rline)) = pass(pass_idx).surface(rline)*c/2 ...
        + (time(time>pass(pass_idx).surface(rline)) - pass(pass_idx).surface(rline))*c/2/sqrt(er_ice);
      
      pixels = pass(pass_idx).ecef(:,rline) + pass(pass_idx).z(:,rline)*range;
      
      % Compute the location of all pixels from this range line in the master
      % line coordinate system FCS.
      Tfcs = [ref.x, ref.y, ref.z];
      pass(pass_idx).pixels(:,:,rline) = (pixels - ref.origin) / Tfcs;
    end
  end
  pass(pass_idx).along_track_slave = geodetic_to_along_track(pass(pass_idx).lat,pass(pass_idx).lon,pass(pass_idx).elev);
  
  if 0
    % Debug plot showing indexes for alignment of passes
    figure(h_fig_ref_idx);
    plot(pass(pass_idx).ref_idx)
    drawnow;
  end
  
  %% Pass: 2. Resample in along-track
  % Resample images and position vectors onto a common along-track axes
  if strcmp('sar',input_type)
    % 1. Oversample slave data by 10x in along track
    Mx = 10;
    Nx = size(pass(pass_idx).data,2);
    data_oversample = interpft(pass(pass_idx).data.',Mx*Nx);
    % 2. Interpolate to find the oversampled slave axes
    along_track_oversample = interp1(0:Nx-1, ...
      pass(pass_idx).along_track, (0:Nx*Mx-1)/Mx,'linear','extrap');
    % 3. Interpolate oversampled slave data onto master along track axes
    pass(pass_idx).ref_data = interp1(along_track_oversample, ...
      data_oversample, along_track,'linear','extrap').';
  elseif strcmp('echo',input_type)
    pass(pass_idx).ref_data = interp1(pass(pass_idx).along_track, ...
      pass(pass_idx).data.', along_track,'linear').';
  end
  
  pass(pass_idx).ref_y = interp1(pass(pass_idx).along_track, ...
    pass(pass_idx).ref_y, along_track,'linear','extrap').';
  pass(pass_idx).ref_z = interp1(pass(pass_idx).along_track, ...
    pass(pass_idx).ref_z, along_track,'linear','extrap').';
  
  for lay_idx = 1:length(pass(pass_idx).layers)
    pass(pass_idx).layers(lay_idx).twtt_ref = interp1(pass(pass_idx).along_track, ...
      pass(pass_idx).layers(lay_idx).twtt, along_track,'linear').';
  end
  
  %% Pass: 3. Apply fixed coregistration time shift
  Nt = size(pass(pass_idx).ref_data,1);
  dt = pass(pass_idx).time(2)-pass(pass_idx).time(1);
  df = 1/(dt*Nt);
  pass(pass_idx).freq_baseband = df * ifftshift( -floor(Nt/2) : floor((Nt-1)/2) ).';
  fc = pass(pass_idx).wfs(pass(pass_idx).wf).fc;
  pass(pass_idx).freq = fc + pass(pass_idx).freq_baseband;
  if pass_idx == baseline_master_idx
    ref.freq = pass(pass_idx).freq;
  end
  
  time_shift = coregistration_time_shift(pass_idx) * dt;
  
  if strcmp('echo',input_type)
    % Apply time shift with interpolation
    pass(pass_idx).ref_data = interp1(pass(pass_idx).time, pass(pass_idx).ref_data, pass(pass_idx).time+time_shift, 'linear');
    pass(pass_idx).ref_data = interp_finite(pass(pass_idx).ref_data,NaN);
    
  else
    % Apply frequency domain time shift (envelope only shift so baseband frequency)
    pass(pass_idx).ref_data = ifft(bsxfun(@times,fft(pass(pass_idx).ref_data),exp(-1i*2*pi*pass(pass_idx).freq_baseband*time_shift)));
  end
  % Apply time shift to layers
  for lay_idx = 1:length(pass(pass_idx).layers)
    pass(pass_idx).layers(lay_idx).twtt_ref = pass(pass_idx).layers(lay_idx).twtt_ref - time_shift;
  end
  
  %% Pass: 4. Motion/slope compensation
  if strcmp('sar',input_type)
    Htime_window = tukeywin_trim(Nt,0.5);
    if param.multipass.comp_mode == 1 || param.multipass.comp_mode == 3
      % Motion compensation of FCS z-motion (envelope and phase)
      for rline = 1:size(pass(pass_idx).ref_data,2)
        % Convert z-offset into time-offset assuming nadir DOA
        time_shift = pass(pass_idx).ref_z(rline)/(c/2);
        pass(pass_idx).ref_data(:,rline) = ifft(fft(pass(pass_idx).ref_data(:,rline).*Htime_window) ...
          .*exp(1i*2*pi*pass(pass_idx).freq*time_shift) );
      end
    else
      % Motion compensation of FCS z-motion (envelope only)
      for rline = 1:size(pass(pass_idx).ref_data,2)
        % Convert z-offset into time-offset assuming nadir DOA
        time_shift = pass(pass_idx).ref_z(rline)/(c/2);
        pass(pass_idx).ref_data(:,rline) = ifft(fft(pass(pass_idx).ref_data(:,rline).*Htime_window) ...
          .*exp(1i*2*pi*pass(pass_idx).freq_baseband*time_shift) );
      end
    end
    if param.multipass.slope_correction_en
      % Phase only correction for cross-track layer slope
      fn_slope = fullfile(fn_dir,[fn_name '_slope.mat']);
      slope = load(fn_slope,'slope','GPS_time','Latitude','Longitude','Elevation','Time','Surface');
      slope.slope = interp1(slope.GPS_time,slope.slope.',pass(baseline_master_idx).gps_time).';
      slope.slope = interp_finite(slope.slope.',0).';
      slope.slope = interp1(slope.Time,slope.slope,pass(pass_idx).time);
      slope.slope = interp_finite(slope.slope);
      
      pass(pass_idx).ref_data = pass(pass_idx).ref_data .* exp(-1i*4*pi*pass(pass_idx).freq(1)/c *bsxfun(@times,sin(slope.slope),pass(pass_idx).ref_y(:).'));
    end
  elseif strcmp('echo',input_type)
    % Motion compensation of FCS z-motion using linear interpolation
    for rline = 1:size(pass(pass_idx).ref_data,2)
      time_shift = pass(pass_idx).ref_z(rline)/(c/2);
      pass(pass_idx).ref_data(:,rline) = interp1(pass(pass_idx).time, pass(pass_idx).ref_data(:,rline), pass(pass_idx).time+time_shift, 'linear');
      pass(pass_idx).ref_data(:,rline) = interp_finite(pass(pass_idx).ref_data(:,rline),NaN);
    end
  end
  
  % Motion compensation for layers
  time_shift = pass(pass_idx).ref_z/(c/2);
  for lay_idx = 1:length(pass(pass_idx).layers)
    pass(pass_idx).layers(lay_idx).twtt_ref = pass(pass_idx).layers(lay_idx).twtt_ref - time_shift;
  end
  
  %% Pass: Match time axis to baseline_master_idx
  % =========================================================================
  if 0
    pass(pass_idx).ref_data = interp1(pass(pass_idx).wfs(pass(pass_idx).wf).time, pass(pass_idx).ref_data, pass(baseline_master_idx).time, 'linear', 0);
  elseif 1
    Mt = 4;
    Nt = length(pass(pass_idx).time);
    dt = pass(pass_idx).time(2)-pass(pass_idx).time(1);
    if strcmp('sar',input_type)
      pass(pass_idx).ref_data = interpft(pass(pass_idx).ref_data,Mt*Nt);
      time_Mt = pass(pass_idx).time(1) + dt/Mt*(0:Mt*Nt-1);
      pass(pass_idx).ref_data = interp1(time_Mt, pass(pass_idx).ref_data, pass(baseline_master_idx).time, 'linear', 0);
    elseif strcmp('echo',input_type)
      pass(pass_idx).ref_data = interp1(pass(pass_idx).time, pass(pass_idx).ref_data, pass(baseline_master_idx).time, 'linear', 0);
    end
  end
  
  if surf_flatten_en
    % Normalize surface phase
    Nt = size(pass(pass_idx).ref_data,1);
    Nx = size(pass(pass_idx).ref_data,2);
    H = pass(baseline_master_idx).ref_data(round(ref.surface_bin)+(0:Nx-1)*Nt) .* conj(pass(pass_idx).ref_data(round(ref.surface_bin)+(0:Nx-1)*Nt));
    H = exp(1i*angle(H));
    pass(pass_idx).ref_data = bsxfun(@times,pass(pass_idx).ref_data,H);
  end
  
  % Concatenate data into a single matrix
  data = cat(3,data,single(pass(pass_idx).ref_data));
end

%% Apply equalization
% -----------------------
if param.multipass.comp_mode ~= 1 && strcmp('sar',input_type)
  equalization = reshape(equalization,[1 1 numel(equalization)]);
  data = bsxfun(@times,data,1./equalization(:,:,pass_en_idxs));
end

if 0
  %% Estimate Coregistration: Data Dependent method to estimate System Time Delay
  % Apply fixed coregistration time shift
  coherence_sum = [];
  coregistration_time_shifts = -2:0.05:2;
  rbins = param.multipass.rbins;
  for pass_out_idx = 1:length(pass_en_idxs)
    pass_idx = pass_en_idxs(pass_out_idx);
    fprintf('Estimate Coregistration: %d of %d, pass %d (%s)\n', pass_out_idx, length(pass_en_idxs), pass_idx, datestr(now,'yyyymmdd_HHMMSS'));
    
    freq = ref.freq;
    freq = freq - freq(1); % Remove center frequency offset
    for coregistration_time_shift_idx = 1:length(coregistration_time_shifts)
      coregistration_time_shift = coregistration_time_shifts(coregistration_time_shift_idx);
      dt = coregistration_time_shift * (ref.time(2)-ref.time(1));
      adjusted = ifft(bsxfun(@times,fft(data(:,:,pass_idx)),exp(-1i*2*pi*freq*dt)));
      coherence = fir_dec(adjusted(rbins,:) .* conj(data(rbins,:,master_idx)) ./ abs(adjusted(rbins,:) .* data(rbins,:,master_idx)),ones(1,7)/7,1);
      coherence = fir_dec(coherence.',ones(1,3)/3,1).';
      coherence = abs(coherence);
      %     coherence_sum(coregistration_time_shift_idx) = sum(coherence(coherence>0.5));
      coherence_sum(coregistration_time_shift_idx,pass_idx) = sum(coherence(coherence>0));
      %    TriangleRayIntersection fprintf('%g %.2f\n', coregistration_time_shift, coherence_sum(coregistration_time_shift_idx));
      %     imagesc(coherence); colormap(1-gray(256));
      %     pause
    end
    [~,coregistration_time_shift_idx] = max(coherence_sum,[],1);
    coregistration_time_shift = coregistration_time_shifts(coregistration_time_shift_idx)
  end
  figure(2000); clf;
  plot(coregistration_time_shifts,coherence_sum)
  [~,coregistration_time_shift_idx] = max(coherence_sum,[],1);
  coregistration_time_shift = coregistration_time_shifts(coregistration_time_shift_idx);
  fprintf('%g ', coregistration_time_shift); fprintf('\n');
  return
end

%% Plot co-registered echograms/interferograms
h_data_axes = [];
new_equalization = [];
rbins = 1:size(data,1);
master_out_idx = find(pass_en_idxs == master_idx);
for pass_out_idx = 1:length(pass_en_idxs)
  pass_idx = pass_en_idxs(pass_out_idx);
  fprintf('Plot: %d of %d, pass %d (%s)\n', pass_out_idx, length(pass_en_idxs), pass_idx, datestr(now,'yyyymmdd_HHMMSS'));
  
  figure(pass_idx); clf;
  set(pass_idx,'WindowStyle','docked')
  if strcmp('echo',input_type)
    % Echogram: Power detected image
    % =====================================================================
    if strcmp(param.multipass.units,'meters')
      img = lp(data(rbins,:,pass_out_idx));
      
      elevation = pass(master_idx).elev;
      time = pass(master_idx).time(rbins);
      surface = pass(pass_idx).layers(1).twtt_ref(:).';
      %surface = pass(master_idx).surface;
      elev_max = max(elevation - time(1)*c/2);
      elev_min = min(elevation - surface*c/2 - (time(end)-surface)*c/(sqrt(er_ice)*2));
      dt = time(2) - time(1);
      drange = dt * c/(sqrt(er_ice)*2);
      elev_uniform = (elev_max:-drange:elev_min).';
      % update image_data
      Nt = size(img,1);
      img = [img;...
        zeros(length(elev_uniform)-Nt,size(img,2))];
      warning('off','MATLAB:interp1:NaNinY')
      for idx = 1:length(surface)
        range = min(time,surface(idx)) * c/2 ...
          + max(0,time-surface(idx)) * c/(sqrt(er_ice)*2);
        elev = elevation(idx) - range;
        img(:,idx) = interp1(elev,...
          img(1:Nt,idx),elev_uniform,'linear');
      end
      warning('on','MATLAB:interp1:NaNinY')
      pass(pass_idx).data_elev = img;
      pass(pass_idx).data_elev_yaxis = elev_uniform;
      imagesc(pass(master_idx).along_track/1e3, elev_uniform, img);
      ylabel('Elevation (m, WGS-84)');
      xlabel('Along-track (km)');
      set(gca,'YDir','normal');
      
      % Convert layerPnts_y from TWTT to WGS_84 Elevation
      surface = pass(pass_idx).layers(1).twtt_ref;
      for lay_idx = 1:length(pass(pass_idx).layers)
        layer_y_curUnit = pass(pass_idx).layers(lay_idx).twtt_ref;
        for pnt_idx = 1:length(layer_y_curUnit)
          range = min(layer_y_curUnit(pnt_idx),surface(pnt_idx))*c/2 ...
            +max(0,layer_y_curUnit(pnt_idx)-surface(pnt_idx)) * c/(sqrt(er_ice)*2);
          layer_y_curUnit(pnt_idx) = elevation(pnt_idx) - range;
        end
        layer_y_curUnit(isnan(pass(pass_idx).layers(lay_idx).twtt_ref)) = NaN;
        pass(pass_idx).layers(lay_idx).layer_elev = layer_y_curUnit;
        hold on;
        plot(pass(master_idx).along_track/1e3, pass(pass_idx).layers(lay_idx).layer_elev);
      end
      
    else
      imagesc(lp(data(rbins,:,pass_out_idx)))
      ylabel('Range bin');
      xlabel('Range line');
    end
    colormap(1-gray(256));
    title(sprintf('%s_%03d %d',pass(pass_idx).param_pass.day_seg,pass(pass_idx).param_pass.cmd.frms(1),pass(pass_idx).direction),'interpreter','none')
    %caxis([-90 8]);
    
  else
    % SAR: Interferogram image
    % =====================================================================
    complex_data = fir_dec(data(rbins,:,pass_out_idx) .* conj(data(rbins,:,master_out_idx)),ones(1,11)/11,1);
    if ~exist('equalization_rlines','var') || isempty(equalization_rlines)
      new_equalization(pass_idx) = mean(complex_data(:)); % equalization only valid when motion compensation with phase is used
    else
      new_equalization(pass_idx) = mean(mean(complex_data(:,equalization_rlines))); % equalization only valid when motion compensation with phase is used
    end
    if param.multipass.comp_mode == 1
      complex_data = complex_data ./ new_equalization(pass_idx);
    end
    if enable_coherent_plot
      % Plot interferogram
      coherence = abs(fir_dec(data(rbins,:,pass_out_idx) .* conj(data(rbins,:,master_out_idx)) ./ abs(data(rbins,:,pass_out_idx) .* data(rbins,:,master_out_idx)),ones(1,11)/11,1)) ...
        .* exp(1i*angle(complex_data));
      imagesc(hsv_plot_coherence(coherence,[0 1]));
      colormap(hsv(256))
      h_colorbar = colorbar;
      caxis([-pi pi])
      set(get(h_colorbar,'ylabel'),'string','Angle (radians)');
    else
      % Plot echogram
      imagesc(lp(data(rbins,:,pass_out_idx)));
      colormap(1-gray(256));
      h_colorbar = colorbar;
      set(get(h_colorbar,'ylabel'),'string','Relative power (dB)');
    end
    ylabel('Range bin');
    xlabel('Range line');
    title(sprintf('%s_%03d %d',pass(pass_idx).param_sar.day_seg,pass(pass_idx).param_sar.load.frm,pass(pass_idx).direction),'interpreter','none')
    
    if 0
      imagesc(abs(coherence));
      colormap(1-gray(256))
      h_colorbar = colorbar;
      caxis([0 1])
      set(get(h_colorbar,'ylabel'),'string','Coherence');
      ylabel('Range bin');
      xlabel('Range line');
      title(sprintf('%s_%03d %d',pass(pass_idx).param_sar.day_seg,pass(pass_idx).param_sar.load.frm,pass(pass_idx).direction),'interpreter','none')
    end
    
  end
  h_data_axes(end+1) = gca;
  
end
linkaxes(h_data_axes,'xy');

if ~strcmp('echo',input_type)
  fprintf('=============================================\n');
  fprintf('New equalization\n');
  fprintf('%.1f ', db(new_equalization,'voltage')-mean(db(new_equalization(pass_en_idxs),'voltage')));
  fprintf('\n');
  fprintf('%.1f ', angle(new_equalization)*180/pi)
  fprintf('\n');
  fprintf('=============================================\n');
end

if param.multipass.comp_mode == 4
  return;
end

%% Plot baseline
if enable_debug_plot
  h_fig_baseline = figure(200); clf;
  h_plot_baseline = [];
  h_legend_baseline = {};
  for pass_out_idx = 1:length(pass_en_idxs)
    pass_idx = pass_en_idxs(pass_out_idx);
    
    base_line ...
      = sqrt( (pass(pass_idx).ref_z - pass(master_idx).ref_z).^2 ...
      + (pass(pass_idx).ref_y - pass(master_idx).ref_y).^2 );
    
    h_plot_baseline(end+1) = plot(base_line);
    h_legend_baseline{end+1} = sprintf('%d',pass_idx);
    hold on;
  end
  xlabel('Range line');
  ylabel('Baseline (m)');
  grid on;
  legend(h_plot_baseline,h_legend_baseline);
  
  fn_map = fullfile(fn_dir,[fn_name output_fn_midfix '_map.fig']);
  saveas(h_fig_map,fn_map);
  fn_elev = fullfile(fn_dir,[fn_name output_fn_midfix '_elev.fig']);
  saveas(h_fig_elev,fn_elev);
  fn_baseline = fullfile(fn_dir,[fn_name output_fn_midfix '_baseline.fig']);
  saveas(h_fig_baseline,fn_baseline);
end

%% Save Result
% =========================================================================
param_multipass = param;
% Remove input and temporary pass data images to reduce output file size
pass = rmfield(pass,'ref_data');
pass = rmfield(pass,'data');

out_fn = fullfile(fn_dir, sprintf('%s_multipass%02.0f.mat', fn_name, param.multipass.comp_mode));
fprintf('Saving %s (%s)\n', out_fn, datestr(now));
out_fn_dir = fileparts(out_fn);
if ~exist(out_fn_dir,'dir')
  mkdir(out_fn_dir);
end
ct_save(out_fn,'-v7.3','pass','data','ref','param_combine_passes','param_multipass');

if param.multipass.comp_mode ~= 2 || strcmp('echo',input_type)
  return
end

%% Array Processing (comp_mode == 2)
% Package data to call array_proc.m
% 1. Data
% 2. Trajectory and attitude
% 3. Array processing parameters
data = {permute(data,[1 2 4 5 3])};

param.array = [];
param.array.method = 1;
% param.array.Nsv = 256; param.array = rmfield(param.array,'theta'); % Forces default theta
% param.array.theta = linspace(-20,20,256);
param.array.theta = linspace(-6,6,256);
param.array.Nsrc = 2;
param.array.bin_rng = [-4:4];
param.array.line_rng = [-20:20];
param.array.dbin = 1;
param.array.dline = 11;
h_fig_baseline = figure(200); clf;
h_plot_baseline = [];
h_legend_baseline = {};
wf_cells = {[],[],[]};
for pass_out_idx = 1:length(pass_en_idxs)
  pass_idx = pass_en_idxs(pass_out_idx);
  
  param.array.fcs{1}{pass_out_idx}.pos = along_track;
  param.array.fcs{1}{pass_out_idx}.pos(2,:) = pass(pass_idx).ref_y;
  param.array.fcs{1}{pass_out_idx}.pos(3,:) = pass(pass_idx).ref_z;
  param.array.fcs{1}{pass_out_idx}.base_line ...
    = sqrt( (pass(pass_idx).ref_z - pass(master_idx).ref_z).^2 ...
    + (pass(pass_idx).ref_y - pass(master_idx).ref_y).^2 );
  
  param.array.fcs{1}{pass_out_idx}.surface = ref.surface;
end

param.array.wfs.time = ref.time;
dt = param.array.wfs.time(2)-param.array.wfs.time(1);
param.array_proc.bin0 = param.array.wfs.time(1)/dt;
param.array.sv_fh = @array_proc_sv;
param.array.wfs.fc = ref.wfs(ref.wf).fc;
param.array.imgs = {[ones(length(pass_en_idxs),1), (1:length(pass_en_idxs)).']};
% param.array.imgs = wf_cells;
param.array.tomo_en = true;

%%
array_proc_methods;
param = array_proc(param);
param.array.method = STANDARD_METHOD;
[param_array0,result0] = array_proc(param,{data{1}(:,:,:,:,:)});
% param.array.method = MVDR_METHOD;
% [param_array1,result1] = array_proc(param,{data{1}(:,:,:,:,:)});
param.array.method = MUSIC_METHOD;
[param_array2,result2] = array_proc(param,{data{1}(:,:,:,:,:)});


%% Save Results
[fn_dir,fn_name] = fileparts(fn);

Tomo = result0.tomo;
Data = result0.img;
GPS_time = ref.gps_time(param_array0.array_proc.lines);
Latitude = ref.lat(param_array0.array_proc.lines);
Longitude = ref.lon(param_array0.array_proc.lines);
Elevation = ref.elev(param_array0.array_proc.lines);
Roll = ref.roll(param_array0.array_proc.lines);
Pitch = ref.pitch(param_array0.array_proc.lines);
Heading = ref.heading(param_array0.array_proc.lines);
Surface = ref.surface(param_array0.array_proc.lines);
Bottom = nan(size(Surface));
param_sar = pass(baseline_master_idx).param_sar;
param_records = pass(baseline_master_idx).param_records;
param_array = param_array0;
Time = pass(master_idx).time(param_array2.array_proc.bins);
file_version = '1';
fn_mat = fullfile(fn_dir,[fn_name output_fn_midfix '_standard.mat']);
fprintf('Saving %s (%s)\n', fn_mat, datestr(now));
ct_save('-v7.3',fn_mat,'Tomo','Data','Latitude','Longitude','Elevation','GPS_time', ...
  'Surface','Bottom','Time','param_array','param_records', ...
  'param_sar', 'Roll', 'Pitch', 'Heading', 'file_version');

Tomo = result2.tomo;
Data = result2.img;
GPS_time = ref.gps_time(param_array2.array_proc.lines);
Latitude = ref.lat(param_array2.array_proc.lines);
Longitude = ref.lon(param_array2.array_proc.lines);
Elevation = ref.elev(param_array2.array_proc.lines);
Roll = ref.roll(param_array2.array_proc.lines);
Pitch = ref.pitch(param_array2.array_proc.lines);
Heading = ref.heading(param_array2.array_proc.lines);
Surface = ref.surface(param_array2.array_proc.lines);
Bottom = nan(size(Surface));
param_sar = pass(baseline_master_idx).param_sar;
param_records = pass(baseline_master_idx).param_records;
param_array = param_array2;
Time = pass(master_idx).time(param_array2.array_proc.bins);
file_version = '1';
fn_mat = fullfile(fn_dir,[fn_name output_fn_midfix '_music.mat']);
fprintf('Saving %s (%s)\n', fn_mat, datestr(now));
ct_save('-v7.3',fn_mat,'Tomo','Data','Latitude','Longitude','Elevation','GPS_time', ...
  'Surface','Bottom','Time','param_array','param_records', ...
  'param_sar', 'Roll', 'Pitch', 'Heading', 'file_version');
