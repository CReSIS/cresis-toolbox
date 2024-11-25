function [ stats_obj ] = cluster_kernel_viterbi_2D( params, param_override, options, geotiff_fn, geotiff2_fn, viterbi_params, stats_obj, OPS_Surface, OPS_Bottom, OPS_data, OPS_crossover_data )
%VITERBI_2D_KERNEL Summary of this function goes here
%   Detailed explanation goes here

  % set warnings off  
  warning('off','all');
  
  physical_constants;

  % constant part
  bottom_bin    = -1;
  egt_weight    = -1;
  mu_size       = 31;
  mu            = log10(exp(-(-(mu_size-1)/2 : (mu_size-1)/2).^4/1));
  mu(mu<-30)    = -30;
  mu            = mu - mean(mu);
  sigma         = sum(abs(mu))/10*ones(1,mu_size);

  % testing parameters part  
  smooth_var    = viterbi_params.sv;
  repulsion     = viterbi_params.repls;
  smooth_weight = viterbi_params.sw;
  ice_bin_thr   = viterbi_params.ibt;
   
  for param_idx = 1:length(params)
    param = params(param_idx);
    if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
%       fprintf('passing %d \n', param_idx);
      continue;
    end

    clear big_matrix Surface;

    param = merge_structs(param,param_override);

%     dbstack_info = dbstack;
%     fprintf('=====================================================================\n');
%     fprintf('%s: %s (%s)\n', dbstack_info(1).name, param.day_seg, datestr(now,'HH:MM:SS'));
%     fprintf('=====================================================================\n');

    big_matrix          = {};
    big_matrix.Data     = [];
    big_matrix.GPS_time = [];
    big_matrix.Lat      = [];
    big_matrix.Lon      = [];
    layer_params.name   = 'surface';
    layer_params.source = 'ops';

%     try
%       Surface = opsLoadLayers(param,layer_params);
%     catch ME
% %       warning(ME.getReport);
%       fprintf('data not loaded\n');
%       continue;
%     end


    try
      Surface = OPS_Surface(param_idx);  
    catch ME
      fprintf('Skippe surface %d since OPS did not load this \n', param_idx);
      continue;
    end

    

    if ~isstruct(Surface)
      disp('No Surface variable');%ds_param_2017_Greenland_P3
    end
    % Catch error with layer not having correctly loaded from OPS
    if(isempty(Surface.gps_time) || any(isnan(Surface.gps_time)) || any(isnan(Surface.twtt)))
      warning('on', 'all');
      warning('PROBLEM PROCESSING FRAME %s', param.day_seg);
      warning('off', 'all');
      continue;
    end

    % Load frames file
    frames = frames_load(param);

    if isempty(param.cmd.frms)
      param.cmd.frms = 1:length(frames.frame_idxs);
    end

    % Remove frames that do not exist from param.cmd.frms list
    [valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs)); layer_params.name   = 'bottom';
    if length(valid_frms) ~= length(param.cmd.frms)
      bad_mask = ones(size(param.cmd.frms));
      bad_mask(keep_idxs) = 0;
      warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
        param.cmd.frms(find(bad_mask,1)));
      param.cmd.frms = valid_frms;
    end

    data_fn_dir = ct_filename_out(param, options.name, '');
    for frm = param.cmd.frms
      data_fn_name        = sprintf('Data_%s_%03d.mat',param.day_seg,frm);
      data_fn             = fullfile(data_fn_dir, data_fn_name);      
      try
        cur_matrix          = load(data_fn);
      catch ME
        fprintf('Skipping frm %d from the seg %d (has a total of %d frms)\n', frm, param_idx+5, length(param.cmd.frms)); 
        continue;
      end           
      
      if size(big_matrix.Data, 1) ~= size(cur_matrix.Data,1) && size(big_matrix.Data, 1) ~= 0
        keyboard
        
        
      end

      big_matrix.Data = horzcat(big_matrix.Data, cur_matrix.Data);
      big_matrix.GPS_time = horzcat(big_matrix.GPS_time, cur_matrix.GPS_time);
      big_matrix.Lat      = horzcat(big_matrix.Lat, cur_matrix.Latitude);
      big_matrix.Lon      = horzcat(big_matrix.Lon, cur_matrix.Longitude);
      big_matrix.Time     = cur_matrix.Time;
    end

%     opsAuthenticate(param,false);
%     layer_name                   = 'bottom';
%     sys                          = ct_output_dir(param.radar_name);
%     ops_param                    = struct('properties',[]);
%     ops_param.properties.season  = param.season_name;
%     ops_param.properties.segment = param.day_seg;
%     [status,ops_frames]          = opsGetSegmentInfo(sys,ops_param);
%     ops_frames = OPS_frame(param_idx);

%     ops_param = struct('properties',[]);
%     ops_param.properties.location = param.post.ops.location;
%     ops_param.properties.season = param.season_name;
%     ops_param.properties.start_gps_time = ops_frames.properties.start_gps_time(1);
%     ops_param.properties.stop_gps_time = ops_frames.properties.stop_gps_time(end);
%     ops_param.properties.nativeGeom = true;
%     [~,ops_data] = opsGetPath(sys,ops_param);

    
    ops_data = OPS_data(param_idx);
    
    big_matrix.Data = interp1(big_matrix.GPS_time, big_matrix.Data.', ops_data.properties.gps_time);
    for rbin=1:size(big_matrix.Data,2)
      big_matrix.Data(:,rbin) = interp_finite(big_matrix.Data(:,rbin));
    end
    big_matrix.Data = big_matrix.Data.';
    big_matrix.Lat = interp_finite(interp1(big_matrix.GPS_time, big_matrix.Lat.', ops_data.properties.gps_time));
    big_matrix.Lon = interp_finite(interp1(big_matrix.GPS_time, big_matrix.Lon.', ops_data.properties.gps_time));
    big_matrix.GPS_time = ops_data.properties.gps_time;
    big_matrix.Surface = interp_finite(interp1(Surface.gps_time,Surface.twtt,big_matrix.GPS_time));

    %% Multiple suppression
    big_matrix.Data = lp(big_matrix.Data);
    Tmultiple_offset = -200e-9;
    threshold = -60;
    surface_guard = 10;
    surf_bins = round(interp1(big_matrix.Time, 1:length(big_matrix.Time), big_matrix.Surface));
    for rline = 1:size(big_matrix.Data,2)
      % Threshold and shift the large values
      mult = zeros(size(big_matrix.Data,1),1);
      mult(big_matrix.Data(:,rline)>threshold) = big_matrix.Data(big_matrix.Data(:,rline)>threshold,rline) - threshold;
      % Ignore time before the surface bin since no multiples can occur at these
      % times and the feed through does occur and could create problems if we do not suppress it.
      mult(1:surf_bins(rline)-surface_guard) = 0;
      % Interpolate to the surface multiple time
      mult = interp1((big_matrix.Time+Tmultiple_offset)*2,mult,(big_matrix.Time+Tmultiple_offset));
      
      
      if size(mult) == size(big_matrix.Data(:,rline))
         big_matrix.Data(:,rline) = big_matrix.Data(:,rline) - mult;
      else
        big_matrix.Data(:,rline) = big_matrix.Data(:,rline) - mult';
      end
      
    end

    %%
    Nx             = size(big_matrix.Data, 2);
    slope          = round(diff(big_matrix.Surface));
    viterbi_weight = ones([1 Nx]);
    mc             = -1 * ones(1, Nx);
    mc_weight      = 0;

    
    
  if isempty(geotiff_fn)
    mask = inf * ones([1 Nx]);
  else
    [mask,R,~] = geotiffread(geotiff_fn);
    proj = geotiffinfo(geotiff_fn);
    [points.x, points.y] = projfwd(proj, big_matrix.Lat, big_matrix.Lon);
    X = R(3,1) + R(2,1)*(1:size(mask,2));
    Y = R(3,2) + R(1,2)*(1:size(mask,1));
    if 0
      figure;
      imagesc(X,Y,mask);
      hold on;
      plot(points.x,points.y)
    end
    [X,Y] = meshgrid(X,Y);
    fl_mask = round(interp2(X, Y, double(mask), points.x, points.y));
    mask = fl_mask;
    mask(isnan(mask)) = 1;

    % TEMPORARILY HARDCODED FOR ANTARTICA:
    if 1
      [mask,R,~] = geotiffread(geotiff_fn);
      [mask2, R2, ~] = geotiffread(geotiff2_fn);
      proj = geotiffinfo(geotiff_fn);
      [points.x, points.y] = projfwd(proj, big_matrix.Lat, big_matrix.Lon);
      X = R(3,1) + R(2,1)*(1:size(mask,2));
      Y = R(3,2) + R(1,2)*(1:size(mask,1));
      if 0
        figure;
        imagesc(X,Y,mask);
        hold on;
        plot(points.x,points.y)
      end
      [X,Y] = meshgrid(X,Y);
      fl_mask = interp2(X, Y, double(mask), points.x, points.y);
      fl_mask = round(interp2(X, Y, double(mask), points.x, points.y));
      mask = fl_mask;
      mask(isnan(mask)) = 1;
      fl_mask2 = interp2(X, Y, double(mask2), points.x, points.y);
      fl_mask2 = round(interp2(X, Y, double(mask2), points.x, points.y));
      mask2 = fl_mask2;
      mask2(isnan(mask2)) = 1;
      f_mask = zeros(size(mask));
      for i = 1:length(f_mask)
        if ((mask(1, i) == 0 || mask(1, i) == 1) && (mask2(1, i) == 127))
          f_mask(1, i) = 1;
        end
      end
      mask = f_mask;
      if max(max(mask)) > 100
        tmp_mask = zeros(size(mask));
        tmp_mask(mask == 0) = 1;
        mask = tmp_mask;
      end
    end
  end


    delete X Y
  
%     query = sprintf('SELECT rds_segments.id FROM rds_seasons,rds_segments where rds_seasons.name=''%s'' and rds_seasons.id=rds_segments.season_id and rds_segments.name=''%s''',param.season_name,param.day_seg);
%     [status,tables] = opsQuery(query);
%     segment_id = tables{1};
% 
%     ops_param                       = struct('properties',[]);
%     ops_param.properties.location   = param.post.ops.location;
%     ops_param.properties.lyr_name   = layer_name;
%     ops_param.properties.frame      = ops_frames.properties.frame;
%     ops_param.properties.segment_id = ones(size(ops_param.properties.frame)) ...
%       *double(segment_id);
% 
%     [status,data] = opsGetCrossovers(sys,ops_param);
  data = OPS_crossover_data(param_idx);

    %% Crossover loading
    rline = [];
    rows  = [];
    cols  = [];
    gps_time = [];
    season_name = {};
    for i = 1 : length(data.properties.source_point_path_id)
      if ~isnan(data.properties.twtt(i))
        new_rline = find(ops_data.properties.id == data.properties.source_point_path_id(i));
        new_gps_time = ops_data.properties.gps_time(new_rline);
        new_season_name = data.properties.season_name{i};
        if big_matrix.GPS_time(1) <= new_gps_time ...
            && big_matrix.GPS_time(end) >= new_gps_time ...
            && str2double(new_season_name(1:4)) >= 2006
          rline(end+1) = new_rline;
          gps_time(end+1) = new_gps_time;
          season_name{end+1} = new_season_name;
          [~, cols(end+1)] = min(abs(big_matrix.GPS_time - ops_data.properties.gps_time(rline(end))));
          twtt = data.properties.twtt(i);
          twtt = twtt + (data.properties.source_elev(i)-data.properties.cross_elev(i))/(c/2);
          rows(end+1) = round(interp1(big_matrix.Time, 1:length(big_matrix.Time), twtt));
        end
      end
    end

    %% Set variable echogram tracking parameters
    gt     = [cols(:).'; rows(:).'];
    bounds = [0 Nx];
    mask   = 90*fir_dec(double(mask), ones(1,5)/3.7);
    mask(mask>=90) = inf;
    
    
    %% Detrending routine
    if 1
      detect_data = big_matrix.Data;
      % Along track filtering
      detect_data = fir_dec(detect_data,ones(1,5)/5,1);
      % Estimate noise level
      noise_value = mean(mean(detect_data(end-80:end-60,:)));
      % Estimate trend
      trend = mean(detect_data,2);
      trend(trend<noise_value) = noise_value;
      % Subtract trend
      detect_data = bsxfun(@minus,detect_data,trend);
      % Remove bad circular convolution wrap around at end of record
      detect_data(end-70:end,:) = 0;
      big_matrix.Data = detect_data;
    end


    %% Call viterbi.cpp
    tic
    big_matrix.Labels = tomo.viterbi(double(detect_data), double(surf_bins), ...
      double(bottom_bin), double(gt), double(mask), double(mu), ...
      double(sigma), double(egt_weight), double(smooth_weight), ...
      double(smooth_var), double(slope), int64(bounds), ...
      double(viterbi_weight), double(repulsion), double(ice_bin_thr), ...
      double(mc), double(mc_weight));
    toc
    
    %% load the reference
%     layer_params.name   = 'bottom';
%     reference = opsLoadLayers(param,layer_params);
    reference = OPS_Bottom(param_idx);
    y = interp_finite(interp1(reference.gps_time,reference.twtt,big_matrix.GPS_time));
    bottom_bins = round(interp1(big_matrix.Time, 1:length(big_matrix.Time), y));   
    
    
%     figure; image(detect_data); hold on; plot(big_matrix.Labels, 'r', 'LineWidth', 2.5)
       
    layer_diff  = abs(big_matrix.Labels - bottom_bins);
    rmse        = sqrt(mean(layer_diff(:).^2));
    mean_diff   = nanmean(layer_diff(:));
    median_diff = nanmedian(layer_diff(:));
    min_diff    = nanmin(layer_diff(:)); % Make this global for convenience in debugging
    max_diff    = nanmax(layer_diff(:));

    stats_obj.rmse_f(stats_obj.counter_f) = rmse;
    stats_obj.diff_f(stats_obj.counter_f) = mean_diff;
    stats_obj.med_f(stats_obj.counter_f)  = median_diff;
    stats_obj.min_df(stats_obj.counter_f) = min_diff;
    stats_obj.max_df(stats_obj.counter_f) = max_diff;
    stats_obj.total_diff  = cat(2, stats_obj.total_diff, layer_diff(:)');
    stats_obj.counter_f   = stats_obj.counter_f + 1;
  end

end

