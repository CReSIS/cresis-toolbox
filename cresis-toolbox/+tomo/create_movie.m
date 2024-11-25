function create_movie (params, options)
% tomo.create_movie (params, options)
%
% Generate 3D "flyover" movies from existing DEM files.
% Usually called from tomo.run_create_movie
%
% Authors: Victor Berger, John Paden
%
% See also: tomo.run_create_movie.m, tomo.plot_surf_geotiff.m,
%  tomo.plot_DEM, and tomo.freezeColors.m

dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s (%s)\n', dbstack_info(1).name, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

physical_constants;
drawCO = options.showCrossovers;
dbstop if error;

if options.showMAP
  fprintf('\nLoading GeoTIFF, this may take a minute.. (%s)', datestr(now));
  mapper.proj = geotiffinfo(options.pathMAP);
  [mapper.RGB_bg, mapper.R_bg, ~] = geotiffread(options.pathMAP);
  fprintf('\n  Done (%s)', datestr(now));
end

for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) ...
      || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  
  options.videoPathTMP = ct_filename_out(param, options.videoPath);
  
  if ~exist(options.videoPathTMP, 'dir')
    mkdir(options.videoPathTMP);
  end
  
  % Load frames file
  frames = frames_load(param);
  
  if isempty(param.cmd.frms)
    param.cmd.frms = 1:length(frames.frame_idxs);
  end
  
  for frm_idx = param.cmd.frms
    if options.createVideo
      options.videoName = sprintf('Movie_%s_%03d',param.day_seg, frm_idx);
      if exist(strcat(fullfile(options.videoPathTMP, options.videoName), '.mp4'), 'file') || ...
          exist(strcat(fullfile(options.videoPathTMP, options.videoName), '.avi'), 'file')
        fprintf('\nFile for %s already exists. Continuing to next...', sprintf('%s_%03d',param.day_seg, frm_idx));
        continue
      end
    end
    
    fprintf('\nLoading DEM of current frame, this may take a minute.. (%s)\n', datestr(now));
    try
      param.topDEM    = load(fullfile(ct_filename_out(param, options.DEM_source, ''), sprintf('%s_%03d_top',param.day_seg, frm_idx)));
      param.bottomDEM = load(fullfile(ct_filename_out(param, options.DEM_source, ''), sprintf('%s_%03d_bottom',param.day_seg, frm_idx)));
      records = records_load(param,[],'gps_time');
    catch ME
      warning('Attention: DEM for reference frame %s not found. Skipping this frame.', sprintf('%s_%03d',param.day_seg, frm_idx));
      continue;
    end
    fprintf('  Done (%s)', datestr(now));
    
    fprintf('\nLoading DEM of next frame, this may take a minute.. (%s)\n', datestr(now));
    try
      param.topDEM_next    = load(fullfile(ct_filename_out(param, options.DEM_source, ''), sprintf('%s_%03d_top',param.day_seg, frm_idx +1)));
      param.bottomDEM_next = load(fullfile(ct_filename_out(param, options.DEM_source, ''), sprintf('%s_%03d_bottom',param.day_seg, frm_idx +1)));
    catch ME
      warning('Attention: DEM for reference frame %s not found. Skipping this frame.', sprintf('%s_%03d',param.day_seg, frm_idx +1));
      continue;
    end
    fprintf('  Done (%s)', datestr(now));

    %% Over sample main frame
    if options.main_oversampling_rate > 0
      param.topDEM.points.x = interp2(param.topDEM.points.x, options.main_oversampling_rate);
      param.topDEM.points.y = interp2(param.topDEM.points.y, options.main_oversampling_rate);
      param.topDEM.points.elev = interp2(param.topDEM.points.elev, options.main_oversampling_rate);
      param.bottomDEM.points.x = interp2(param.bottomDEM.points.x, options.main_oversampling_rate);
      param.bottomDEM.points.y = interp2(param.bottomDEM.points.y, options.main_oversampling_rate);
      param.bottomDEM.points.elev = interp2(param.bottomDEM.points.elev, options.main_oversampling_rate);
    end
    
    %% Over sample current frame
    if options.main_oversampling_rate > 0
      param.topDEM_next.points.x = interp2(param.topDEM_next.points.x, options.main_oversampling_rate);
      param.topDEM_next.points.y = interp2(param.topDEM_next.points.y, options.main_oversampling_rate);
      param.topDEM_next.points.elev = interp2(param.topDEM_next.points.elev, options.main_oversampling_rate);
      param.bottomDEM_next.points.x = interp2(param.bottomDEM_next.points.x, options.main_oversampling_rate);
      param.bottomDEM_next.points.y = interp2(param.bottomDEM_next.points.y, options.main_oversampling_rate);
      param.bottomDEM_next.points.elev = interp2(param.bottomDEM_next.points.elev, options.main_oversampling_rate);
    end
    
    %% Function call to plot_DEM generates map and DEM
    warning off
    %   Returns cross over data
    param.frm = frm_idx;
    param = merge_structs(param, options);
    param.radar_name = options.sys;
    if drawCO
      [f2, ax2, cax2, data, crossover_frms, crossover_DEM, crossover_badmask] = ...
        tomo.plot_DEM(param, 'gt', mapper, 'crossover', 'on', 'title', 'off', ...
        'cmaplim', options.cmaplim);
    else
      [f2, ax2, cax2] = tomo.plot_DEM(param, 'gt', mapper, 'title', 'off');
    end
    
    min_x = min( inf, min(param.bottomDEM.points.x(:)));
    max_x = max(-inf, max(param.bottomDEM.points.x(:)));
    min_y = min( inf, min(param.bottomDEM.points.y(:)));
    max_y = max(-inf, max(param.bottomDEM.points.y(:)));
    
    figure_dots_per_km = 20;
    map_buffer = 2e3;
    
    map_min_x = min_x-map_buffer;
    map_max_x = max_x+map_buffer;
    map_min_y = min_y-map_buffer;
    map_max_y = max_y+map_buffer;
    
    set(ax2,'Units','pixels');
    map_axes = get(ax2,'Position');
    set(f2,'Units','pixels');
    map_pos = get(f2,'Position');
    
    map_new_axes = map_axes;
    map_new_axes(3) = round(figure_dots_per_km*(map_max_x-map_min_x)/1e3);
    map_new_axes(4) = round(figure_dots_per_km*(map_max_y-map_min_y)/1e3);
    map_pos(3) = map_new_axes(3) + map_pos(3)-map_axes(3);
    map_pos(4) = map_new_axes(4) + map_pos(4)-map_axes(4);
    
    set(f2,'Position',map_pos);
    set(ax2,'Position',map_new_axes);
    set(f2,'PaperPositionMode','auto');

    f1 = figure;
    ax1 = gca;
    
    % Draw reference TOP surface on figure 1
    filt_elev = imgaussfilt(param.topDEM.points.elev(:, 1:length(param.topDEM.points.x)), 5);
    vert_scale = 2;
    s1 = surf(param.topDEM.points.x(:, 1:length(param.topDEM.points.x))/vert_scale, ...
      param.topDEM.points.y(:, 1:length(param.topDEM.points.x))/vert_scale, filt_elev, ...
      'FaceAlpha', .5, 'EdgeColor', 'none', 'Parent', ax1);

    hold on;
    
    % Draw cross-over TOP surface(s) on figure 1
    if drawCO && exist('data', 'var') && isfield(data.properties, 'Frame')
      for surf_idx = 1:length(crossover_frms)
        if ~crossover_badmask(surf_idx) || strcmp(crossover_frms{surf_idx},sprintf('%s_%03d',param.day_seg, frm_idx))
          continue;
        end
        
        if options.CO_oversampling_rate > 0
          crossover_DEM{surf_idx}.topDEM.points.x = interp2(crossover_DEM{surf_idx}.topDEM.points.x, options.CO_oversampling_rate);
          crossover_DEM{surf_idx}.topDEM.points.y = interp2(crossover_DEM{surf_idx}.topDEM.points.y, options.CO_oversampling_rate);
          crossover_DEM{surf_idx}.topDEM.points.elev = interp2(crossover_DEM{surf_idx}.topDEM.points.elev, options.CO_oversampling_rate);
          crossover_DEM{surf_idx}.topDEM.points.elev = imgaussfilt(crossover_DEM{surf_idx}.topDEM.points.elev(:, 1:length(crossover_DEM{surf_idx}.topDEM.points.x)), 5);
        end
        
        surf(crossover_DEM{surf_idx}.topDEM.points.x(:, 1:length(crossover_DEM{surf_idx}.topDEM.points.x))/vert_scale, ...
          crossover_DEM{surf_idx}.topDEM.points.y(:, 1:length(crossover_DEM{surf_idx}.topDEM.points.x))/vert_scale, ...
          crossover_DEM{surf_idx}.topDEM.points.elev(:, 1:length(crossover_DEM{surf_idx}.topDEM.points.x)), ...
          'FaceAlpha', .5, 'EdgeColor', 'none', 'Parent', ax1);
        hold all
      end
    end
    
    caxis(ax1, cax2);
    warning off
    colormap gray;
    camlight
    shading interp
    hold all
    tomo.freezeColors
    
    % Draw reference BOTTOM surface on figure 1
    filt_elev = imgaussfilt(param.bottomDEM.points.elev(:, 1:length(param.bottomDEM.points.x)), 5);
    
    s2 = surfl(param.bottomDEM.points.x(:, 1:length(param.bottomDEM.points.x))/vert_scale, ...
      param.bottomDEM.points.y(:, 1:length(param.bottomDEM.points.x))/vert_scale, ...
      filt_elev(:, 1:length(param.bottomDEM.points.x)), 'light', 'Parent', ax1);
    
    % Draw cross-over BOTTOM surface(s) on figure 1
    if drawCO && exist('data', 'var') && isfield(data.properties, 'Frame')
      for surf_idx = 1:length(crossover_frms)
        if ~crossover_badmask(surf_idx) || strcmp(crossover_frms{surf_idx},sprintf('%s_%03d',param.day_seg, frm_idx))
          continue;
        end
        
        if options.CO_oversampling_rate > 0
          crossover_DEM{surf_idx}.bottomDEM.points.x = interp2(crossover_DEM{surf_idx}.bottomDEM.points.x, options.CO_oversampling_rate);
          crossover_DEM{surf_idx}.bottomDEM.points.y = interp2(crossover_DEM{surf_idx}.bottomDEM.points.y, options.CO_oversampling_rate);
          crossover_DEM{surf_idx}.bottomDEM.points.elev = interp2(crossover_DEM{surf_idx}.bottomDEM.points.elev, options.CO_oversampling_rate);
          crossover_DEM{surf_idx}.bottomDEM.points.elev = imgaussfilt(crossover_DEM{surf_idx}.bottomDEM.points.elev(:, 1:length(crossover_DEM{surf_idx}.bottomDEM.points.x)), 5);
        end
        
        surfl(crossover_DEM{surf_idx}.bottomDEM.points.x(:, 1:length(crossover_DEM{surf_idx}.bottomDEM.points.x))/vert_scale, ...
          crossover_DEM{surf_idx}.bottomDEM.points.y(:, 1:length(crossover_DEM{surf_idx}.bottomDEM.points.x))/vert_scale, ...
          crossover_DEM{surf_idx}.bottomDEM.points.elev(:, 1:length(crossover_DEM{surf_idx}.bottomDEM.points.x)), ...
          'light','Parent', ax1);
        shading(ax1, 'interp');
      end
    end
    
    clear crossover_DEM;
    
    camlight
    shading interp
    if isfield(options, 'cmaplim') && ~isempty(options.cmaplim)
      colormap(demcmap(options.cmaplim, 240));
    else
      colormap(demcmap(param.bottomDEM.points.elev, 24));
    end
    axis(ax1, 'off');
    
    %% Smooth camera position and target vectors
    if 1
      [B,A] = butter(2, .002);
      top_elev = filtfilt(B, A, ...
        interp_finite(param.topDEM.points.elev(round(size(param.bottomDEM.points.elev, 1)/2), :)));
      bot_elev = filtfilt(B, A, ...
        interp_finite(param.bottomDEM.points.elev(round(size(param.bottomDEM.points.elev, 1)/2), :)));
      top_elev_next = filtfilt(B, A, ...
        interp_finite(param.topDEM_next.points.elev(round(size(param.bottomDEM_next.points.elev, 1)/2), :)));
      bot_elev_next = filtfilt(B, A, ...
        interp_finite(param.bottomDEM_next.points.elev(round(size(param.bottomDEM_next.points.elev, 1)/2), :)));
    elseif 0
      top_elev = imgaussfilt(interp_finite(param.topDEM.points.elev(round(size(param.bottomDEM.points.elev, 1)/2), :)), 5);
      bot_elev = imgaussfilt(interp_finite(param.bottomDEM.points.elev(round(size(param.bottomDEM.points.elev, 1)/2), :)), 5);
    else
      windowSize = 20; b = (1/windowSize)*ones(1,windowSize); a = 1;
      top_elev = filter(b,a,interp_finite(param.topDEM.points.elev(round(size(param.bottomDEM.points.elev, 1)/2), :)));
      bot_elev = filter(b,a,interp_finite(param.bottomDEM.points.elev(round(size(param.bottomDEM.points.elev, 1)/2), :)));
      top_elev_next = filter(b,a,interp_finite(param.topDEM_next.points.elev(round(size(param.bottomDEM_next.points.elev, 1)/2), :)));
      bot_elev_next = filter(b,a,interp_finite(param.bottomDEM_next.points.elev(round(size(param.bottomDEM_next.points.elev, 1)/2), :)));
    end
    
    param.totalDEM_top.x = [param.topDEM.points.x param.topDEM_next.points.x];
    param.totalDEM_top.y = [param.topDEM.points.y param.topDEM_next.points.y];
    param.totalDEM_top.e = [param.topDEM.points.elev param.topDEM_next.points.elev];
    param.totalDEM_bot.x = [param.bottomDEM.points.x param.bottomDEM_next.points.x];
    param.totalDEM_bot.y = [param.bottomDEM.points.y param.bottomDEM_next.points.y];
    param.totalDEM_bot.e = [param.bottomDEM.points.elev param.bottomDEM_next.points.elev];
    total_top_e          = [top_elev top_elev_next];
    total_bot_e          = [bot_elev bot_elev_next];
    
    campos_vec = {};
    for i = 1:length(param.totalDEM_top.x)
      campos_vec{end + 1} = [param.totalDEM_bot.x(round(size(param.totalDEM_bot.x, 1)/2),i)/vert_scale, ...
        param.totalDEM_bot.y(round(size(param.totalDEM_bot.y, 1)/2), i)/vert_scale, total_top_e(i)+1000];
    end
    
    camtarget_vec = {}; oset = 300;
    for i = 1:length(param.totalDEM_top.x) - 10*oset
      camtarget_vec{end + 1} = [param.totalDEM_bot.x(round(size(param.totalDEM_bot.x, 1)/2),i+10*oset)/vert_scale, ...
        param.totalDEM_bot.y(round(size(param.totalDEM_bot.y, 1)/2), i+10*oset)/vert_scale, total_bot_e(i+2*oset)];
    end
    
    clear param.totalDEM_top param.totalDEM_bot
    
    %% Pad figures to obtain total size
    titleFrameWidth = 40;
    
    f1.Position = [200+options.videoSize(1)/2, 200, options.videoSize(1)/2,...
      options.videoSize(2)-titleFrameWidth];
    f2.Position = [200, 200, options.videoSize(1)/2, ...
      options.videoSize(2)-titleFrameWidth];
    
    set(ax2, 'Units', 'normalized')
    set(ax2, 'OuterPosition', [0 0 1 1.2])
    set(ax2, 'Position', [0.1 0.05 .8 .95 ])
    
    drawnow;
    
    % Generate line on 2D map figure
    slice_idx = 1;
    h = line(param.bottomDEM.points.x(:, find(~isnan(param.bottomDEM.points.x(round(size(param.bottomDEM.points.x, 1)/2),:)),1))/1e3,...
      param.bottomDEM.points.y(:, find(~isnan(param.bottomDEM.points.x(round(size(param.bottomDEM.points.x, 1)/2),:)),1))/1e3, ...
      ones(size(param.bottomDEM.points.elev(:, slice_idx))),...
      'LineWidth', 2, 'Color','r','Parent', ax2);
    
    f3          = figure(3);
    f3.Position = [0 f3.Position(2) options.videoSize(1) titleFrameWidth];
    ax3         = gca;
    axis(ax3, 'off');
    
    seg_year = str2double(param.day_seg(1:4));
    seg_month = str2double(param.day_seg(5:6));
    seg_day = str2double(param.day_seg(7:8));
    
    % Start time (used in title)
    ST = records.gps_time(frames.frame_idxs(frm_idx));
    % Stop time (used in title)
    if frm_idx == length(frames.frame_idxs)
      last_idx = length(records.gps_time);
    else
      last_idx = frames.frame_idxs(frm_idx+1)-1;
    end
    ET = records.gps_time(last_idx);
    
    [year,month,day,hour,minute,sec] = datevec(epoch_to_datenum(ST));
    days_offset = datenum(year,month,day) - datenum(seg_year,seg_month,seg_day);
    hour = hour + 24*days_offset;
    start_time_str = sprintf('%02d:%02d:%04.1f', hour, minute, sec);
    
    [year,month,day,hour,minute,sec] = datevec(epoch_to_datenum(ET));
    days_offset = datenum(year,month,day) - datenum(seg_year,seg_month,seg_day);
    hour = hour + 24*days_offset;
    stop_time_str = sprintf('%02d:%02d:%04.1f', hour, minute, sec);
    
    txt = title(sprintf('%s %s: "%s"  %s: %s to %s GPS', options.sys, param.season_name, ...
      param.cmd.mission_name, sprintf('%s_%03d',param.day_seg, frm_idx), start_time_str, ...
      stop_time_str),'Interpreter','none','FontWeight','normal','FontSize', 15);
    
    txt.Units = 'normalized';
    txt.HorizontalAlignment = 'center';
    txt.Position = [0.5000 -1.2000 0];
    
    fr3 = getframe(f3);
    close(f3);
    
    clear records
    
    warning on
    
    if options.createVideo
      try
        v = VideoWriter(fullfile(options.videoPathTMP, options.videoName), options.videoFormat);
        try
          v.Quality = 100;
        catch ME
        end
        try
          v.LosslessCompression = true;
        catch ME
        end
      catch ME
        warning('The selected video format is not supported. Using .avi instead.');
        warning('MPEG-4: only systems with Windows 7 and later, or Mac OS X 10.7 and later.');
        v = VideoWriter(fullfile(options.videoPathTMP, options.videoName));
      end
      v.FrameRate = options.frameRate;
      fprintf('\nWriting video to \n%s  (%s)\n', fullfile(options.videoPathTMP, options.videoName), datestr(now));
      open(v);
    end
    
    %% Set final parameters
    camzoom(ax1, options.zoom)
    oset         = 300;
    axis_isEqual = 0;
    
    %% Settings for the movie matrix
    movie_mat = {};
    dump_counter = 0;
    dump_part = 0;
    
    % Display options
    options
    
    %% Move along-track through frame to create animation
    while slice_idx <= length(param.bottomDEM.points.x)
      
      fprintf('\nMOVIE_MULTI :: Movie step %d out of %d', slice_idx, ...
        length(param.bottomDEM.points.x)-oset);
      
      if isnan(param.topDEM.points.x(round(size(param.bottomDEM.points.x, 1)/2), slice_idx)) ...
          || isnan(param.bottomDEM.points.x(round(size(param.bottomDEM.points.x, 1)/2), slice_idx)) 
        slice_idx = slice_idx + options.frameSkip;
        continue;
      end
      
      if any(isnan(campos_vec{slice_idx}))
        slice_idx = slice_idx + options.frameSkip;
        continue;
      end
      
      % Update line location on 2D map figure
      h.XData = param.bottomDEM.points.x(:, slice_idx)/1e3;
      h.YData = param.bottomDEM.points.y(:, slice_idx)/1e3;
      h.ZData = ones(size(param.bottomDEM.points.elev(:, slice_idx)));
      
      hold on
      
      try
        campos(ax1, campos_vec{slice_idx});
        camtarget(ax1, camtarget_vec{slice_idx});
      catch ME
        slice_idx = slice_idx + options.frameSkip;
        continue;
      end
      
      if ~axis_isEqual
        axis(ax1, 'equal')
        axis_isEqual = 1;
      end
      
      % Capture images, concatenate frames, and write to video
      if options.createVideo
        fr1 = getframe(f1);
        fr2 = getframe(f2);
        frame.colormap = [];
        frame.cdata = horzcat(fr2.cdata, fr1.cdata);
        try
          frame.cdata = vertcat(fr3.cdata, frame.cdata);
        catch ME
          fr3.cdata = imresize(fr3.cdata, [size(fr3.cdata ,1) size(frame.cdata, 2)]);
          frame.cdata = vertcat(fr3.cdata, frame.cdata);
        end
        
        writeVideo(v, frame);
      else
        pause(0.002);
      end
      
      if options.saveMAT
        movie_mat{end + 1} = frame.cdata;
        if options.memory_dump
          dump_counter = dump_counter + 1;
          if dump_counter >= options.memory_dump_size
            dump_counter = 0;
            dump_part = dump_part + 1;
            save(strcat(fullfile(options.videoPathTMP, options.videoName), '_part_', num2str(dump_part)), ...
              'movie_mat', '-v7.3');
            fprintf('\n  Saved memory (DUMP). Part: %d. Frame count: %d', dump_part, length(movie_mat));
            movie_mat = {};
          end
        end
      end
      
      slice_idx = slice_idx + options.frameSkip;
    end
    
    fprintf('  Done (%s)\n', datestr(now));
    
    if options.createVideo
      close(v)
    end
    
    if options.saveMAT && ~options.memory_dump
      lastwarn('');
      save(fullfile(options.videoPathTMP, options.videoName), 'movie_mat', '-v7.3');
      fprintf('\n  Saved memory. Frame count: %d', length(movie_mat));
      if ~isempty(lastwarn)
        keyboard
      end
    elseif options.saveMAT && options.memory_dump
      lastwarn('');
      dump_part = dump_part + 1;
      save(strcat(fullfile(options.videoPathTMP, options.videoName), '_part_', num2str(dump_part)), ...
              'movie_mat', '-v7.3');
      fprintf('\n  Saved memory (FINAL DUMP). Frame count: %d', length(movie_mat));
      if ~isempty(lastwarn)
        keyboard
      end
    end
    
    close all;
    clear f1 f2 fr1 fr2 frame flowline OPSparams WKT_polygon ST ET movie_mat
    fprintf('\n=====================================================================\n');
  end
end

fprintf('\n\nALL DONE ::: %s\n\n', datetime('now'));
