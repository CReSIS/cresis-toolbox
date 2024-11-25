function echo_info = publish_echogram(param,mdata,lay,surface_layer)
% echo_info = publish_echogram(param,mdata,lay)
%
% param: structure controlling the plotting of the echogram
%  .fig_hand: figure handle to use for plot
%  .num_x_tics: number of xtics across the bottom (the xtics give
%     the geographic info), usually 4 for figure copy and 6 for
%     full page print out
%  .depth: 1x2 double vector representing the limits of the depth
%     axis to plots (-500 to 3500 typical, deep antarctica -500 to 4000,
%     but for custom plots -100 to 2000 or whatever highlights the data
%     best
%  .elev_comp: Elevation compensation mode
%     0: no elevation compensation (twtt)
%     1: level flight elevation compensation
%     2: depth elevation compensation
%     3: WGS-84 elevation compensation
%  .er_ice: the permittivity used to create the depth axis, default is 
%     loaded from physical_constants.
%  .plot_quality: boolean scalar, default is false, if true, plots each
%     layer with colors corresponding to the layers quality
% lay: structure containing layerData for layers to plot
%   .layerData: structure containing picking data for each layer to be 
%       plotted
% surface_layer: the layerData for the surface layer
%   .value: the manual and automatic picks for the surface layer
% echo_info: structure with handles to plots/axes
%  .ah_echo_time: time axis handle
%  .ah_echo: depth axis handle
%  .h_layers: plot handles for each layer
%
% Example: see run_load_data_by_gps_time
%
% Authors: John Paden, Reece Mathews
%
% See also: publish_map, run_publish_echogram

physical_constants;
if ~isfield(param,'er_ice') || isempty(param.er_ice)
  param.er_ice = er_ice;
end
if ~isfield(param,'er_depth') || isempty(param.er_depth)
  param.er_depth = 0;
end
if ~isfield(param,'axis_type') || isempty(param.axis_type)
  param.axis_type = 'standard';
end
if ~isfield(param,'caxis') || isempty(param.caxis) 
  param.caxis = [];
end
if ~isfield(param,'depth_offset') || isempty(param.depth_offset)
  % Adds an offset to the depth/elevation/range tics (in meters)
  param.depth_offset = 0;
end
if ~isfield(param,'time_offset') || isempty(param.time_offset) 
  % Adds an offset to the two way travel time tics (in seconds)
  param.time_offset = 0;
end
if ~isfield(param,'plot_quality')
  param.plot_quality = false;
end
if ~isreal(mdata.Data)
  warning('Input data are complex. Taking the abs()^2 of the data.');
  mdata.Data = abs(mdata.Data).^2;
end

% =======================================================================
% Move layer data and quality data to lay.layers and lay.qualities
% =======================================================================
lay.layers = {};
lay.qualities = {};
lay.layers{1} = surface_layer.value{2}.data;
for layer_idx = 1:length(lay.layerData)
  lay.layers{end + 1} = lay.layerData{layer_idx}.value{2}.data;
  if param.plot_quality
    lay.qualities{end + 1} = lay.layerData{layer_idx}.quality;
  end
end

lay.Thickness = lay.layers{end}-lay.layers{1};
neg_idxs = find(lay.Thickness < 0 & isfinite(lay.Thickness));
if ~isempty(neg_idxs)
  warning('  Negative thickness detected');
  lay.layers{end}(neg_idxs) = lay.layers{1}(neg_idxs);
end

% Interpolate layer onto GPS times of echogram
warning('off','MATLAB:interp1:NaNinY');
if param.plot_quality
  for quality_idx = 1:length(lay.qualities)
    lay.qualities{quality_idx} = interp1(lay.GPS_time,lay.qualities{quality_idx},mdata.GPS_time,'linear','extrap');
  end
end

for layer_idx = 1:length(lay.layers)
  lay.layers{layer_idx} = interp1(lay.GPS_time,lay.layers{layer_idx},mdata.GPS_time,'linear','extrap');
end
warning('on','MATLAB:interp1:NaNinY');

% Create fast-time correction vector
%   The layer file may contain a different elevation profile
%   than the data file. The surface and bottom need to be adjusted
%   to account for these differences.
elev_interp    = interp1(lay.GPS_time,lay.Elevation,mdata.GPS_time,'linear','extrap');
fast_time_correction = (mdata.Elevation - elev_interp)/(c/2);

% =======================================================================
% Mean removal detrending
% =======================================================================
if isfield(param,'detrend') && ~isempty(param.detrend)
  % if strcmpi(param.detrend.mode,'tonemap')
  %   if ispc
  %     load('H:\tmp\2016_Greenland_TOdtu_detrend_curve.mat');
  %   else
  %     load('~/tmp/2016_Greenland_TOdtu_detrend_curve.mat');
  %   end
  %   mdata.Data = 10.^(bsxfun(@minus,lp(mdata.Data),dd(1:size(mdata.Data,1)))/10); % HACK: DO NOT COMMIT
  % end
  if strcmpi(param.detrend.mode,'mean_removal')
    mdata.Data = 10.^(bsxfun(@minus,lp(mdata.Data),mean(lp(mdata.Data),2))/10);
  end
end

% =======================================================================
% Elevation compensation
% =======================================================================

if param.elev_comp == 1
  %% Relative elevation compensation
  max_elev = max(mdata.Elevation);
  dRange = max_elev - mdata.Elevation;
  dt = mdata.Time(2)-mdata.Time(1);
  dBins = round(dRange / (c/2) / dt);
  dtime = dRange/(c/2);
  dtime = interp_finite(dtime,0); % Deal with NaN (e.g. when GPS is missing)
  zero_pad_len = max(abs(dBins));
  if isnan(zero_pad_len)
    zero_pad_len = 0;
  end
  mdata.Data = cat(1,mdata.Data,zeros(zero_pad_len,size(mdata.Data,2)));
  mdata.Time = mdata.Time(1) + (mdata.Time(2)-mdata.Time(1)) * (0:1:size(mdata.Data,1)-1);

  warning off
  for rline = 1:size(mdata.Data,2)   
    mdata.Data(:,rline) = interp1(mdata.Time, mdata.Data(:,rline), mdata.Time - dtime(rline), 'linear',0);
    mdata.Elevation(rline) = mdata.Elevation(rline) + dRange(rline);
    for layer_idx = 1:length(lay.layers)
      lay.layers{layer_idx}(rline) = lay.layers{layer_idx}(rline) + dtime(rline);
    end
  end
  warning on;
elseif param.elev_comp == 2
  %% Compensate for surface variations (i.e. flatten to low pass filtered
  % version of surface)
  
  % Filter out high frequencies from surface layer
  lay.Surface_Filled = interp_finite(lay.layers{1},0); % Need surface points everywhere for filtering operation
  if ~isfield(param,'surf_filt_en') || isempty(param.surf_filt_en) || param.surf_filt_en
    if length(lay.Surface_Filled) >= 100
      [Bfilt,Afilt] = butter(2,0.02);
      surf_filt = filtfilt(Bfilt,Afilt,lay.Surface_Filled);
      tmp = polyval(polyfit(1:51,reshape(lay.Surface_Filled(1:51),[1 51]),2),1:51);
      surf_filt(1:50) = tmp(1:50) - tmp(51) + surf_filt(51);
      tmp = polyval(polyfit(1:51,reshape(lay.Surface_Filled(end-50:end),[1 51]),2),1:51);
      surf_filt(end-49:end) = tmp(2:51) - tmp(1) + surf_filt(end-50);
    else
      surf_filt = medfilt1(lay.Surface_Filled,round(length(lay.Surface_Filled)/20)*2+1);
    end
  elseif ~param.surf_filt_en || isempty(param.surf_filt_en)
    surf_filt = lay.Surface_Filled;
  end

  lay.layers{1} = surf_filt;
  mdata.Elevation = mean(mdata.Elevation) + (surf_filt - mean(surf_filt)) * c/2;  
  

  Surface_Depth = zeros(size(mdata.GPS_time));
  depth_range = eval(param.depth);

  
    % Determine sampling
  max_er = max(param.er_ice);
  dt = mdata.Time(2) - mdata.Time(1);
  dz = dt * c/2/sqrt(max_er);

  % Depth axis
  depth = (round(depth_range(1)/dz)*dz : dz : depth_range(end)).';
  
  % Depth time axis
  depth_time = size(depth);
  % Above surface
  depth_time(depth <= 0) = depth(depth <= 0) / (c/2);
  % Below surface and within dielectric profile defined depth
  if length(param.er_depth) > 1
    TWtime = genPropProfileFromPerm(param.er_depth,param.er_ice,1);
    profile_idxs = depth > 0 & depth < param.er_depth(end);
    depth_time(profile_idxs) = interp1(param.er_depth, TWtime, depth(profile_idxs));
  else
    TWtime = 0;
  end
  % Below surface and below dielectric profile defined depth
  const_idxs = depth >= param.er_depth(end);
  depth_time(const_idxs) = TWtime(end) + (depth(const_idxs) - param.er_depth(end)) / (c/2/sqrt(param.er_ice(end)));
  if length(depth_time) > length(mdata.Time);
      mdata.Data = cat(1,mdata.Data,ones(length(depth_time) -length(mdata.Time),size(mdata.Data,2))*mean(mdata.Data(end,:)));
      mdata.Time = cat(1,mdata.Time,mdata.Time(end) + (depth_time(end)-depth_time(end-1))*(1:(length(depth_time) -length(mdata.Time)))');
  end
  % Re-interpolate data to a constant depth axis
  newData = zeros(length(depth),size(mdata.Data,2));
  warning off;
  mdata.Data(mdata.Data == 0) = NaN;
  for rline = 1:size(mdata.Data,2)
    newData(:,rline) = interp1(mdata.Time, mdata.Data(:,rline), ...
      lay.layers{1}(rline) + depth_time);
    for layer_idx = 2:length(lay.layers)
      lay.layers{layer_idx}(rline) = lay.layers{layer_idx}(rline) - lay.layers{1}(rline);
    end
  end
  mdata.Data = newData;
  mdata.Data(isnan(mdata.Data)) = 0;
  warning on;

elseif param.elev_comp == 3
  %% Elevation compensate to WGS-84 y-axis
  
  % Filter surface
  lay.Surface_Filled = interp_finite(lay.layers{1},0); % Need surface points everywhere for filtering operation
  if all(isnan(lay.layers{1}))
    warning('All surface layer points are NaN. Plotting blank echogram.');
    mdata.Data(:) = NaN;
  end
  if ~isfield(param,'surf_filt_en') || param.surf_filt_en
    Nx = length(lay.Surface_Filled);
    if 30/Nx >= 0.5
      % Layer is too short to properly filter
      surf_filt = lay.Surface_Filled;
    else
      [B,A] = fir1(round(8*Nx/30/2)*2, 30/Nx);
      surf_filt = fir_dec(lay.Surface_Filled,B,1);
    end
  elseif ~param.surf_filt_en || isempty(param.surf_filt_en)
    surf_filt = lay.Surface_Filled;
  end
  
  % Remove data before zero time
  negative_bins = mdata.Time < 0;
  mdata.Time = mdata.Time(~negative_bins);
  mdata.Data = mdata.Data(~negative_bins,:);
  % Create elevation axis to interpolate to
  max_elev = max(mdata.Elevation);
  if length(mdata.Time) < 2
    min_elev = min(mdata.Elevation);
    dt = inf;
    dr = inf;
    elev_axis = max_elev:-dr:min_elev;
  else
    min_elev = min(mdata.Elevation - surf_filt*c/2 - (mdata.Time(end)-surf_filt)*c/2/sqrt(param.er_ice));
    dt = mdata.Time(2)-mdata.Time(1);
    dr = dt * c/2 / sqrt(param.er_ice);
    elev_axis = max_elev:-dr:min_elev;
  end

  % Zero pad data to create space for interpolated data
  zero_pad_len = length(elev_axis) - length(mdata.Time);
  mdata.Data = cat(1,mdata.Data,zeros(zero_pad_len,size(mdata.Data,2)));

  % Determine the corrections to apply to elevation and layers
  dRange = max_elev - mdata.Elevation;
  dBins = round(dRange / (c/2) / dt);
  dtime = dRange/(c/2);

  warning off
  for rline = 1:size(mdata.Data,2)
    % Determine elevation bins before surface
    surf_elev = mdata.Elevation(rline) - surf_filt(rline) * c/2;
    dt_air = dr/(c/2);
    time0 = -(max_elev - mdata.Elevation(rline))/(c/2);
    last_air_idx = find(elev_axis > surf_elev,1,'last');
    new_time = (time0 + dt_air*(0:last_air_idx-1)).';
    if isempty(last_air_idx)
      % Radar is on the surface of the ice
      last_air_idx = 0;
    end
    if last_air_idx < length(elev_axis)
      % Determine elevation bins after surface
      dt_ice = dr/(c/2/sqrt(param.er_ice));
      first_ice_idx = last_air_idx + 1;
      time0 = surf_filt(rline) + (surf_elev - elev_axis(first_ice_idx))/(c/2/sqrt(param.er_ice));
      new_time = cat(1,new_time, (time0 + dt_ice*(0:length(elev_axis)-length(new_time)-1)).');
    end
    if length(mdata.Time) < 2
      mdata.Data(1:length(new_time),rline) = nan(size(new_time));
    else
      mdata.Data(1:length(new_time),rline) = interp1(mdata.Time, mdata.Data(1:length(mdata.Time),rline), new_time, 'linear',0);
    end
    mdata.Elevation(rline) = mdata.Elevation(rline) + dRange(rline);
    for layer_idx = 1:length(lay.layers)
      lay.layers{layer_idx}(rline) = lay.layers{layer_idx}(rline) + dtime(rline);
    end
  end
  mdata.Data = mdata.Data(1:length(new_time),:);
  warning on

end

% Create depth axis
if all(isnan(lay.layers{1}))
  warning('No surface points defined. Setting to zero.');
  lay.layers{1}(:) = 0;
end
good_surface_vals = lay.layers{1} + fast_time_correction;
good_surface_vals = good_surface_vals(isfinite(good_surface_vals));
mean_surface_time = mean(good_surface_vals);
if ~isfinite(mean_surface_time)
  mean_surface_time = 0;
end

DLayers = {};

% Limit depths according to input param.depth
if param.elev_comp == 3
  DSurface = mdata.Elevation - lay.layers{1}*c/2;
  Surface_Elev = DSurface;
  lay.layers{end}(~isfinite(lay.layers{end})) = NaN;
  % Do not add first layer which is always surface
  for layer_idx = 2:length(lay.layers)
    DLayers{end + 1} = mdata.Elevation - lay.layers{1}*c/2 - (lay.layers{layer_idx}-lay.layers{1})*c/2/sqrt(param.er_ice);
  end
  % Example: param.depth = '[min(Surface_Elev) - 15 max(Surface_Elev)+3]';
  % Example: param.depth = '[100 120]';
  % Example: param.depth = '[publish_echogram_switch(Bbad,0.25,Surface_Elev,-1600,DBottom,-100),max(Surface_Elev+50)]';
  
  if length(DLayers) > 1
    max_components = DLayers{2};
    for dlayer_idx = 2:length(DLayers)
      max_components = max(max_components, DLayers{dlayer_idx});
    end
  else
    max_components = nan(size(DSurface));
  end

  DBottom = max_components;

  Bbad = sum(~isfinite(DBottom)) / numel(DBottom);
  
  depth_range = eval(param.depth);
  depth_good_idxs = find(elev_axis >= depth_range(1) & elev_axis <= depth_range(end));
  if isfield(param,'detrend') && ~isempty(param.detrend) && strcmpi(param.detrend.mode,'polynomial')
    detrend_depth_range = eval(param.detrend.depth);
    detrend_depth_good_idxs = find(elev_axis >= detrend_depth_range(1) ...
      & elev_axis <= detrend_depth_range(end));
  end
elseif param.elev_comp == 2
  Depth = depth;
  DSurface = lay.layers{1}; % All zero
  Surface_Depth = DSurface;
  for layer_idx = 2:length(lay.layers)
    DLayers{end + 1} = interp1(depth_time,depth,lay.layers{layer_idx});
  end

  if length(DLayers) > 1
    max_components = DLayers{2};
    for dlayer_idx = 2:length(DLayers)
      max_components = max(max_components, DLayers{dlayer_idx});
    end
  else
    max_components = nan(size(DSurface));
  end

  DBottom = max_components;

  Bbad = sum(isnan(DBottom)) / numel(DBottom);
  
  depth_good_idxs = 1:length(Depth);
  if isfield(param,'detrend') && ~isempty(param.detrend) && strcmpi(param.detrend.mode,'polynomial')
    detrend_depth_range = eval(param.detrend.depth);
    detrend_depth_good_idxs = find(Depth >= detrend_depth_range(1) ...
      & Depth <= detrend_depth_range(end));
  end
else
  Depth = (mdata.Time-mean_surface_time)*c/2/sqrt(param.er_ice);
  DSurface = lay.layers{1} - mean_surface_time + fast_time_correction;
  DSurface = DSurface*c/2/sqrt(param.er_ice);
  Surface_Depth = DSurface;

  for layer_idx = 2:length(lay.layers)
    DLayers{end + 1} = lay.layers{layer_idx} - mean_surface_time + fast_time_correction;
    DLayers{end} = DLayers{end}*c/2/sqrt(param.er_ice);
  end

  if length(DLayers) > 1
    max_components = DLayers{2};
    for dlayer_idx = 2:length(DLayers)
      max_components = max(max_components, DLayers{dlayer_idx});
    end
  else
    max_components = nan(size(DSurface));
  end

  DBottom = max_components;

  Bbad = sum(isnan(DBottom)) / numel(DBottom);
  
  depth_range = eval(param.depth);
  depth_good_idxs = find(Depth >= depth_range(1) & Depth <= depth_range(end));
  if isfield(param,'detrend') && ~isempty(param.detrend) && strcmpi(param.detrend.mode,'polynomial')
    detrend_depth_range = eval(param.detrend.depth);
    detrend_depth_good_idxs = find(Depth >= detrend_depth_range(1) ...
      & Depth <= detrend_depth_range(end));
  end
end

% =======================================================================
% Image filtering
% =======================================================================
if isfield(param,'filter') && ~isempty(param.filter)
  %% Apply optional image filter
  mdata.Data = param.filter(mdata.Data);
end

% =======================================================================
% Detrend
% =======================================================================
if isfield(param,'detrend') && ~isempty(param.detrend)
  if strcmpi(param.detrend.mode,'tonemap')
    %% Automated detrending Code using tonemap
    
    hdr1(:,:,1) = abs(mdata.Data(depth_good_idxs,:));
    hdr1(:,:,2) = abs(mdata.Data(depth_good_idxs,:));
    hdr1(:,:,3) = abs(mdata.Data(depth_good_idxs,:));
    % for generating synthetic HDR images
    detrend_tonemap = tonemap(hdr1, 'AdjustLightness', [0.1 1], 'AdjustSaturation', 1.5);
    detrend_tonemap = detrend_tonemap(:,:,2);

  elseif strcmpi(param.detrend.mode,'polynomial')
    %% Polynomial Detrending Code
    % Detrending splits echogram into 3 sections. The assumption is that
    % elevation compensation is set to 2 (i.e. surface is flattened)
    % Three sections are made to be continuous:
    % 1. Constant (usually above the ice surface)
    % 2. Polynomial fit to log of mean range bin power
    % 3. Constant (usually the noise floor)
    
    if param.elev_comp ~= 2
      warning('Currently polynomial detrending assumes elevation compensation set to 2 (surface flattening)');
    end
    
    detrend_rbins = detrend_depth_good_idxs; % Specifies bins for the polynomial section
    detrend_guard = round(0.1*length(detrend_depth_good_idxs));
    detrend_poly_order = param.detrend.poly_order; % Specify order of second section
    
    detrend_rlines = 1:size(mdata.Data,2);
    
    % Get the log of the mean range bin power
    detrend_profile = lp(nanmean(abs(mdata.Data),2));
    
    % Create an xaxis to prevent badly conditioned polynomials
    if isempty(detrend_rbins)
      detrend_rbins = (1:length(detrend_profile));
    end
    xaxis = (detrend_rbins - mean(detrend_rbins));
    
    % Find the polynomial coefficients
    detrend_poly = polyfit(xaxis, reshape(detrend_profile(detrend_rbins),size(xaxis)), detrend_poly_order);
    
    % Section 2: Evaluate the polynomial
    detrend_profile(detrend_rbins) = polyval(detrend_poly,xaxis);
    
    % Section 1: Constant
    detrend_profile(1:detrend_rbins(1)-1) = detrend_profile(detrend_rbins(1));
    
    % Section 3: Constant
    detrend_profile(detrend_rbins(end)-detrend_guard:end) = detrend_profile(detrend_rbins(end)-detrend_guard);
    
    % Check detrending
    if 0
      figure;
      plot(lp(nanmean(abs(mdata.Data),2)),'r');
      hold on;
      plot(detrend_profile);
      hold off;
    end
    
    % Apply detrending
    if all(isfinite(detrend_profile))
      mdata.Data = mdata.Data ./ repmat(10.^(detrend_profile/10), [1 size(mdata.Data,2)]);
    end
   end
end

% Create echogram plot
if length(param.fig_hand)>=1 && ishandle(param.fig_hand(1))
  clf(param.fig_hand(1));
else
  if length(param.fig_hand)>=1 && isnumeric(param.fig_hand(1))
    param.fig_hand(1) = figure(param.fig_hand(1));
  else
    param.fig_hand(1) = figure();
  end
end
echo_info.fig_hand = param.fig_hand(1);

ah_echo_time = axes('parent',param.fig_hand(1)); % 2-way travel time axis
ah_echo = axes('parent',param.fig_hand(1)); % Depth axis with data
if param.elev_comp == 3
  %% WGS-84 Elevation elevation comp plotting
  echogram_vals = lp(mdata.Data(depth_good_idxs,:));

  echo_info.image = imagesc(NaN,'Parent',ah_echo);
  if isfield(param,'detrend') && ~isempty(param.detrend) && strcmpi(param.detrend.mode,'tonemap')
    set(echo_info.image,'XData',1:size(echogram_vals,2), ...
      'YData',elev_axis(depth_good_idxs)+param.depth_offset, ...
      'CData',detrend_tonemap);
    if ~isempty(echogram_vals)
      if length(depth_good_idxs) < 2
        xlim(ah_echo,[1 size(detrend_tonemap,2)]);
      else
        axis(ah_echo,[1 size(detrend_tonemap,2) sort(elev_axis(depth_good_idxs([1 end]))+param.depth_offset)]);
        axis(ah_echo_time,[0.5 size(detrend_tonemap,2)+0.5 ...
          reshape(new_time(depth_good_idxs([1 end]))*1e6 + param.time_offset*1e6,[1 2])]);
      end
    end
  else
    set(echo_info.image,'XData',1:size(echogram_vals,2), ...
      'YData',elev_axis(depth_good_idxs)+param.depth_offset, ...
      'CData',echogram_vals);
    if ~isempty(echogram_vals)
      if length(depth_good_idxs) < 2
        xlim(ah_echo,[1 size(echogram_vals,2)]);
      else
        axis(ah_echo,[1 size(echogram_vals,2) sort(elev_axis(depth_good_idxs([end 1]))+param.depth_offset)]);
        axis(ah_echo_time,[0.5 size(echogram_vals,2)+0.5 ...
          reshape(new_time(depth_good_idxs([1 end]))*1e6 + param.time_offset*1e6,[1 2])]);
      end
    end
  end
  set(ah_echo,'YDir','Normal');
  ylabel(ah_echo,sprintf('WGS-84 Elevation, e_r = %.2f (m)', param.er_ice));
  
elseif param.elev_comp == 2
  %% Depth plot with surface variation compensation
  echogram_vals = lp(mdata.Data(depth_good_idxs,:));
  
  if isfield(param,'detrend') && ~isempty(param.detrend) && strcmpi(param.detrend.mode,'tonemap')
    echo_info.image = imagesc([],Depth(depth_good_idxs)+param.depth_offset, ...
      detrend_tonemap,'Parent',ah_echo);
    axis(ah_echo_time,[0.5 size(detrend_tonemap,2)+0.5 (mean(lay.layers{1}) + depth_time([1 end]) + param.time_offset)*1e6]);
  else
    echo_info.image = imagesc([],Depth(depth_good_idxs)+param.depth_offset, ...
      echogram_vals,'Parent',ah_echo);
    axis(ah_echo_time,[0.5 size(echogram_vals,2)+0.5 (mean(lay.layers{1}) + depth_time([1 end]) + param.time_offset)*1e6]);
  end
  if length(param.er_ice) == 1;
    ylabel(ah_echo,sprintf('Depth, e_r = %.2f (m)', param.er_ice));
  else
    ylabel(ah_echo,sprintf('Depth, e_r from profile (m)', param.er_ice));
  end
  
else
  %% Everything except WGS-84 Elevation elevation comp plotting
  echogram_vals = lp(mdata.Data(depth_good_idxs,:));
  
  if isfield(param,'detrend') && ~isempty(param.detrend) && strcmpi(param.detrend.mode,'tonemap')
    echo_info.image = imagesc([],Depth(depth_good_idxs)+param.depth_offset, ...
      detrend_tonemap,'Parent',ah_echo);
    axis(ah_echo_time,[0.5 size(detrend_tonemap,2)+0.5 reshape(mdata.Time(depth_good_idxs([1 end]))*1e6 + param.time_offset*1e6,[1 2])])
  else
    echo_info.image = imagesc([],Depth(depth_good_idxs)+param.depth_offset, ...
      echogram_vals,'Parent',ah_echo);
    axis(ah_echo_time,[0.5 size(echogram_vals,2)+0.5 reshape(mdata.Time(depth_good_idxs([1 end]))*1e6 + param.time_offset*1e6,[1 2])])
  end
  if length(param.er_ice) == 1;
    ylabel(ah_echo,sprintf('Depth, e_r = %.2f (m)', param.er_ice));
  else
    ylabel(ah_echo,sprintf('Depth, e_r from profile (m)', param.er_ice));
  end
end
ylabel(ah_echo_time,'Propagation delay (us)');
set(ah_echo_time,'XTickLabel','');
set(ah_echo_time,'YAxisLocation','Right');
set(ah_echo_time,'YDir','Reverse');
if strcmpi(param.axis_type,'bars')
  xlabel(ah_echo,'');
  ylabel(ah_echo,'');
  set(ah_echo,'XTick',[])
  set(ah_echo,'YTick',[])
  set(ah_echo_time,'Visible','off');
  xlims = xlim;
  ylims = ylim;
  
  ybar_length_exact = diff(ylims)*0.2;
  [~,min_log_match] = min(abs(mod(log(ybar_length_exact),log(10)) - log(1:10)));
  ybar_length = min_log_match * 10^floor(log(ybar_length_exact) / log(10));
  ybar_length_norm = ybar_length/diff(ylims);

  along_track = geodetic_to_along_track(mdata.Latitude,mdata.Longitude,mdata.Elevation);
  xbar_length_exact = (along_track(end) - along_track(1))*0.2;
  [~,min_log_match] = min(abs(mod(log(xbar_length_exact),log(10)) - log(1:10)));
  xbar_length = min_log_match * 10^floor(log(xbar_length_exact) / log(10));
  xbar_length_norm = xbar_length/(along_track(end) - along_track(1));
  
  set(ah_echo,'Units','pixels')
  pixel_pos = get(ah_echo,'Position');
  set(ah_echo,'Units','normalized')
  xbar_width = 4 / pixel_pos(4);
  ybar_width = 4 / pixel_pos(3);
  
  if strcmpi(get(ah_echo,'YDir'),'reverse')
    echo_info.yaxis_bar = patch(xlims(1)+diff(xlims)*ybar_width*[2 3 3 2 2], ylims(2)-diff(ylims)*(xbar_width*4+[0 0 ybar_length_norm ybar_length_norm 0]),'k','Parent',ah_echo);
    echo_info.xaxis_bar = patch(xlims(1)+diff(xlims)*(ybar_width*4+[0 xbar_length_norm xbar_length_norm 0 0]),ylims(2)-diff(ylims)*xbar_width*[2 2 3 3 2],'k','Parent',ah_echo);
    echo_info.yaxis_bar_text = text(xlims(1)+diff(xlims)*ybar_width*4, ...
      ylims(2)-diff(ylims)*(xbar_width*4+ybar_length_norm/2), ...
      sprintf('%.0f m',ybar_length),'Parent',ah_echo,'Color',[0 0 0],'FontWeight','Bold');
    if xbar_length >= 1000
      echo_info.xaxis_bar_text = text(xlims(1)+diff(xlims)*(ybar_width*4+xbar_length_norm/2), ...
        ylims(2)-diff(ylims)*xbar_width*3, ...
        sprintf('%.0f km',xbar_length/1000),'Parent',ah_echo,'Color',[0 0 0], ...
        'HorizontalAlignment','Center','VerticalAlignment','Bottom','FontWeight','Bold');
    else
      echo_info.xaxis_bar_text = text(xlims(1)+diff(xlims)*(ybar_width*4+xbar_length_norm/2), ...
        ylims(2)-diff(ylims)*xbar_width*3, ...
        sprintf('%.0f m',xbar_length),'Parent',ah_echo,'Color',[0 0 0], ...
        'HorizontalAlignment','Center','VerticalAlignment','Bottom','FontWeight','Bold');
    end
  else
    echo_info.yaxis_bar = patch(xlims(1)+diff(xlims)*ybar_width*[2 3 3 2 2], ylims(1)+diff(ylims)*(xbar_width*4+[0 0 ybar_length_norm ybar_length_norm 0]),'k','Parent',ah_echo);
    echo_info.xaxis_bar = patch(xlims(1)+diff(xlims)*(ybar_width*4+[0 xbar_length_norm xbar_length_norm 0 0]),ylims(1)+diff(ylims)*xbar_width*[2 2 3 3 2],'k','Parent',ah_echo);
    echo_info.yaxis_bar_text = text(xlims(1)+diff(xlims)*ybar_width*4, ...
      ylims(1)+diff(ylims)*(xbar_width*4+ybar_length_norm/2), ...
      sprintf('%.0f m',ybar_length),'Parent',ah_echo,'Color',[0 0 0],'FontWeight','Bold');
    if xbar_length >= 1000
      echo_info.xaxis_bar_text = text(xlims(1)+diff(xlims)*(ybar_width*4+xbar_length_norm/2), ...
        ylims(1)+diff(ylims)*xbar_width*3, ...
        sprintf('%.0f km',xbar_length/1000),'Parent',ah_echo,'Color',[0 0 0], ...
        'HorizontalAlignment','Center','VerticalAlignment','Bottom','FontWeight','Bold');
    else
      echo_info.xaxis_bar_text = text(xlims(1)+diff(xlims)*(ybar_width*4+xbar_length_norm/2), ...
        ylims(1)+diff(ylims)*xbar_width*3, ...
        sprintf('%.0f m',xbar_length),'Parent',ah_echo,'Color',[0 0 0], ...
        'HorizontalAlignment','Center','VerticalAlignment','Bottom','FontWeight','Bold');
    end
  end
else
  xtl = xlabel_create(mdata.Latitude,mdata.Longitude,mdata.Elevation,param.num_x_tics);
  xlabel_add(ah_echo,xtl,{'dist','lat','lon'});
  set(ah_echo_time,'Units','normalized');
  set(ah_echo,'Units','normalized');
  set(ah_echo_time,'Position',get(ah_echo,'Position'));
end

%% Set Colormap
if isfield(param,'colormap') && isfield(param.colormap,'mode') && ~isempty(param.colormap.mode)
  if strcmpi(param.colormap.mode,'QC')
    if ~isfield(param.colormap,'img_sidelobe')
      param.colormap.img_sidelobe = -45;
    end
    if ~isfield(param.colormap,'noise_buffer')
      param.colormap.noise_buffer = -0.5;
    end
    if ~isfield(param.colormap,'noise_threshold_offset_dB')
      param.colormap.noise_threshold_offset_dB = 8.2;
    end
    
    % noise_rows: contains the rows that will be used to estimate noise power
    yaxis_elev = elev_axis(depth_good_idxs)+param.depth_offset;
    noise_rows = find((param.colormap.noise_buffer + yaxis_elev(1))>yaxis_elev,1);
    
    % noise_threshold: threshold value for color axis (set to be the median of
    % the maximum noise power)
    max_noise = nanmax(echogram_vals(1:noise_rows,:));
    noise_threshold = nanmedian(max_noise)+param.colormap.noise_threshold_offset_dB;
    
    % Sets sidelobes to zero in CData: finds the max of each range line and all range
    % bins that are img_sidelobe less than this max are set to zero (-inf on dB scale).
    echogram_vals = get(echo_info.image,'CData');
    for rline=1:size(echogram_vals,2)
      echogram_vals(echogram_vals(:,rline) < max(echogram_vals(:,rline))+param.colormap.img_sidelobe,rline) = nan;
    end
    set(echo_info.image,'CData',echogram_vals);
    
    % noise_threshold: update this now that sidelobe threshold has been
    % applied
    max_noise = nanmax(echogram_vals(1:noise_rows,:));
    noise_threshold_updated = nanmedian(max_noise)+param.colormap.noise_threshold_offset_dB;
    if isfinite(noise_threshold_updated)
      % Use the pre-sidelobe-thresholding noise threshold
      noise_threshold = noise_threshold_updated;
    end
    
    % Set the colormap
    if isfinite(noise_threshold)
      img_caxis = noise_threshold + [-6 +12];
      caxis(ah_echo,img_caxis);
      img_cmap = [gray(64); flipud(hsv(128))];
      colormap(ah_echo,img_cmap)
    else
      keyboard
      error('Failed to find valid noise threshold.');
    end
  else
    colormap(ah_echo,param.colormap.mode);
  end
else
  colormap(ah_echo,1-gray);
end

if ~isempty(param.caxis)
  if isfield(param,'detrend') && ~isempty(param.detrend) && strcmpi(param.detrend.mode,'polynomial')
    check_vals = lp(mdata.Data(detrend_depth_good_idxs,:));
    check_vals = check_vals(isfinite(check_vals));
    check_vals = sort(check_vals(:));
    if length(check_vals) >= 2
      new_caxis = check_vals(1+round(param.caxis*(length(check_vals)-1)));
      caxis(ah_echo,new_caxis);
    end
  else
    echogram_vals = sort(echogram_vals(:));
    echogram_vals = echogram_vals(isfinite(echogram_vals));
    if length(echogram_vals) >= 2
      new_caxis = echogram_vals(1+round(param.caxis*(length(echogram_vals)-1)));
      caxis(ah_echo,new_caxis);
    end
  end
end

echo_info.h_title = title(ah_echo,sprintf('Data Frame ID: %s', param.frm_id),'Interpreter','none','FontWeight','normal');
echo_info.h_layers = {};

% Plot layers
hold(ah_echo,'on');
if param.plot_quality

  for layer_idx = 1:length(DLayers)
    moderate_mask = lay.qualities{layer_idx}~=2;
    derived_mask = lay.qualities{layer_idx}~=3;
    good_mask = lay.qualities{layer_idx}==2 | lay.qualities{layer_idx}==3;
    
    tmp_layer = DLayers{layer_idx};
    tmp_layer(good_mask) = NaN;
    good_handle = plot(ah_echo,tmp_layer,'g--');
    
    tmp_layer = DLayers{layer_idx};
    tmp_layer(moderate_mask) = NaN;
    moderate_handle = plot(ah_echo,tmp_layer,'y--');
    
    tmp_layer = DLayers{layer_idx};
    tmp_layer(derived_mask) = NaN;
    derived_handle = plot(ah_echo,tmp_layer,'r--');

    plot_handles = [good_handle, moderate_handle, derived_handle];
    echo_info.h_layers{end + 1} = plot_handles;

  end
else
  if ~isempty(DLayers) 
    echo_info.h_layers{1} = plot(ah_echo,DLayers{1},'--m');
  end
  for layer_idx = 2:length(DLayers)
    echo_info.h_layers{end + 1} = plot(ah_echo,DLayers{layer_idx},'--r');
  end
end
hold(ah_echo,'off');

echo_info.ah_echo_time = ah_echo_time;
echo_info.ah_echo = ah_echo;

end

function depth_range = publish_echogram_switch(Bbad,Bbad_Threshold,Surface_Elev,Surface_Elev_Offset,DBottom,DBottom_Offset)

if Bbad > Bbad_Threshold
  depth_range = min(Surface_Elev+Surface_Elev_Offset);
else
  depth_range = min(DBottom+DBottom_Offset);
end

end
