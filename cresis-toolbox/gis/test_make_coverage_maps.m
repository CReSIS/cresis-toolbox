 % script make_coverage_maps.m
% 
% Author: Rohan Choudhari

function test_make_coverage_maps(params, user_variables)

% This function creates the coverage map depending on the user_variables and
% params provided.
% 
%   user_variables: = struct whose fields are used to set the user settings
%     .data_source: string
%       'gps': Loads the data from gps files
%       'records': Loads the data from records files
%       'layer': Loads the layerData using opsLoadLayers
%     .proj: projection information returned by plot_geotiff.m
%       - eg. geotiff_fn = ct_filename_gis(gRadar,fullfile('arctic','NaturalEarth_Data','Arctic_NaturalEarth.tif'));
%             user_variables.proj = plot_geotiff(geotiff_fn,[],[], fig_h_idx);
%     .season_idx: integer
%       - index of the current season from the 
%     .save_img: 1 or 0
%       1: to save
%       2: to not save
%     .ext: string
%       '.m': MATLAB FIG-file and MATLAB code that opens figure 
%       '.jpg': JPEG image
%       '.fig': MATLAB FIG-file
%     '.axis_limits': vector
%       - a vector of axis limits for the geotiff
%     '.along_track_sampling': integer
%       - desired along track sampling of plot (m)
%       - default - 100
%     '.plot_args': cell array
%       - cell array of argument to plot function (e.g. 'b.' for blue dots)
%       - default - {'LineWidth',1}
%     label: Add text labels to the plots for specific frames
%       .day_seg: cell list of day segments to match
%       .frm: equal length cell vector to .day_seg with specific frames to label
%       .text: equal length cell vector to .day_seg with string for text label
%     '.figure_position': vector
%       - to set the figure position
%       eg. [221   -60   654   704]


global gRadar;
yyyymmdd_list = {};

% ***** OUTDATED, UPDATE *****
%Set the title for the figure, initialize required variables
if strcmp(user_variables.data_source,'gps') || strcmp(user_variables.data_source,'records')
  title(strcat(params(1).season_name,'_coverage_map'),'Interpreter','none');
  fprintf('  Creating coverage map for %s: \n', params(1).season_name);
elseif strcmp(user_variables.data_source,'layer')
%   fprintf('  Creating coverage map for %s: \n', user_variables.season_name);

  
  bottom = [];
  quality = [];
  x = [];
  y = [];
end

%Set custom axis limits if provided by the user
if isfield(user_variables, 'axis_limits')
  if ~isempty(user_variables.axis_limits)
    axis(user_variables.axis_limits);
  end
end

%Set the axes labels
xlabel('X (km)');
ylabel('Y (km)');
user_variables.label.h_text = [];

%Looping through all the params for the season
if strcmp(user_variables.data_source,'gps') || strcmp(user_variables.data_source,'records')
  for param_idx = 1:length(params)
    
    parameter = params(param_idx);
    
    %Skipping segments that are already covered
    parameter.yyyymmdd = parameter.day_seg(1:8);
    if strcmp(user_variables.data_source,'gps') && any(strcmp(parameter.yyyymmdd,yyyymmdd_list))
      % Already done this segment
      return;
    end
    
    %Plotting if not 'do not process'
    if ct_generic_en(parameter) && isempty(regexpi(parameter.cmd.notes,'do not process'))
      yyyymmdd_list{end+1} = parameter.yyyymmdd; %Adding segment to the list of segments already covered
      
      %Load lat, lon depending on data source
      if strcmp(user_variables.data_source,'gps')
        gps_fn = ct_filename_support(parameter,[],'gps',1);
        gps = load(gps_fn,'gps_time','lat','lon');
      elseif strcmp(user_variables.data_source,'records')
        records_fn = ct_filename_support(parameter,[],'records');
        if ~exist(records_fn,'file')
          warning('No records file: %s\n', records_fn);
          return;
        end
        frames_fn = ct_filename_support(parameter,'','frames');
        if ~exist(frames_fn,'file')
          warning('No frames file: %s\n', frames_fn);
          return;
        end
        gps = records_load(parameter,'gps_time','lat','lon');
        
        % Load frames file
        frames = frames_load(parameter);
        
        if isempty(parameter.cmd.frms)
          parameter.cmd.frms = 1:length(frames.frame_idxs);
        end
        
        % Remove frames that do not exist from param.cmd.frms list
        [valid_frms,keep_idxs] = intersect(parameter.cmd.frms, 1:length(frames.frame_idxs));
        if length(valid_frms) ~= length(parameter.cmd.frms)
          bad_mask = ones(size(parameter.cmd.frms));
          bad_mask(keep_idxs) = 0;
          warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
            parameter.cmd.frms(find(bad_mask,1)));
          parameter.cmd.frms = valid_frms;
        end
        % Force into a row vector
        parameter.cmd.frms = parameter.cmd.frms(:).';
      end
      
      if strcmp(user_variables.data_source,'gps')
        % Force GPS time to be monotonic (only necessary for corrupt GPS data)
        idxs = logical(zeros(size(gps.gps_time)));
        idxs(1) = 1;
        cur_time = gps.gps_time(1);
        for idx = 2:length(gps.gps_time)
          if gps.gps_time(idx) > cur_time + user_variables.dt
            idxs(idx) = true;
            cur_time = gps.gps_time(idx);
          end
        end
        
        % Plot
        [x,y] = projfwd(user_variables.proj,gps.lat(idxs),gps.lon(idxs));
        hold on;
        h = plot(x/1e3,y/1e3,user_variables.plot_args{:},'UserData',parameter.day_seg);
        drawnow;
        hold off;
        
      elseif strcmp(user_variables.data_source,'records')
        lat = NaN*zeros(size(gps.lat));
        for frm = parameter.cmd.frms
          first_idx = frames.frame_idxs(frm);
          if frm ~= length(frames.frame_idxs)
            last_idx = frames.frame_idxs(frm+1)-1;
          else
            last_idx = length(gps.gps_time);
          end
          lat(first_idx:last_idx) = gps.lat(first_idx:last_idx);
        end
        
        along_track = geodetic_to_along_track(gps.lat,gps.lon);
        decim_idxs = get_equal_alongtrack_spacing_idxs(along_track,user_variables.along_track_sampling);        
        [x,y] = projfwd(user_variables.proj,lat(decim_idxs),gps.lon(decim_idxs));
        hold on;
        h = plot(x/1e3,y/1e3,user_variables.plot_args{:},'UserData',parameter.day_seg);
        drawnow;
        
        if isfield(user_variables.label,'day_seg')
          match_idxs = find(strcmpi(parameter.day_seg,user_variables.label.day_seg(:).'));
          for match_idx = match_idxs
            for frm = user_variables.label.frm{match_idx}
              first_idx = frames.frame_idxs(frm);
              [x,y] = projfwd(user_variables.proj,gps.lat(first_idx),gps.lon(first_idx));
              plot(x/1e3,y/1e3,'.','MarkerSize',12,'Color','Black');
              user_variables.label.h_text(match_idx) = text(x/1e3,y/1e3,user_variables.label.text{match_idx},'Color','black','FontWeight','bold','FontSize',14);
            end
          end
        end
        
      end
    end
    % saving the coverage map
    if user_variables.save_img == 1
      if strcmp(user_variables.data_source,'gps') || strcmp(user_variables.data_source,'records')
        image_fn_name = sprintf('%s_coverage_map_%s%s', params(1).season_name, date, user_variables.ext);
        image_fn = fullfile(user_variables.out_dir,image_fn_name);
        saveas(figure(user_variables.season_idx), image_fn);
      elseif strcmp(user_variables.data_source,'layer')
        image_fn = fullfile(user_variables.out_dir,'Master_coverage_map');
        saveas(figure(1), image_fn);
      end
    end
    
    
  end

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
elseif strcmp(user_variables.data_source,'layer')
  
  %Getting the layer params 
  layer_params = user_variables.layer_params;
  
  % Colorwise handles
  good_data_handles = [];
  mod_data_handles = [];
  mag_data_handles = [];
  bad_data_handles = [];
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% AGGREGATE METHOD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  if strcmpi(user_variables.method,'agg')
    
    %Arrays store points to be plotted on the map
    x_red = [];
    x_magenta = [];
    x_yellow = [];
    x_green = [];
    y_red = [];
    y_yellow = [];
    y_green = [];
    y_magenta = [];
    
    
    %Looping through seasons
    for season_idx = length(params):-1:1
      
      %Reinitializing for each season
      x_red = [];
      x_magenta = [];
      x_yellow = [];
      x_green = [];
      y_red = [];
      y_yellow = [];
      y_green = [];
      y_magenta = [];
      
      
      fprintf('Loading season %s \n',  user_variables.season_names{season_idx});
      
      %Looping through the params of the season
      for param_idx = 1:length(params{season_idx})
        
        fprintf('Param %d \n', param_idx);
        param = params{season_idx}(param_idx);
        param = merge_structs(param,gRadar);
        
        if(strcmp(param.day_seg(1:end-3), '20100402'))
          disp('Found');
        else
          continue;
        end
        
        %Reading layerData
        try
          layer = opsLoadLayers(param,layer_params);
        catch
          continue;
        end
        
        if isempty(layer)
          continue;
        end;
        
        %Looping through the layer data
        for layer_idx = 1:length(layer)
          
          %Checking for bad file
          if length(layer(layer_idx).lat) ~= length(layer(layer_idx).type)
            fprintf('    Bad file\n');
            continue;
          end
          
          %Getting the spacing indexes
          along_track = geodetic_to_along_track(layer(layer_idx).lat,layer(layer_idx).lon,zeros(size(layer(layer_idx).lat)));
          idxs = get_equal_alongtrack_spacing_idxs(along_track,500);
          
          %Looping through the spacing index
          for idx = 1:(length(idxs)-1)
            
            %Aggregating points between indexes
            %bottom_sec: logical vector, true if points exists
            bottom_sec = isfinite(layer(layer_idx).twtt(idxs(idx):idxs(idx+1)-1));
            quality_sec = layer(layer_idx).quality(idxs(idx):idxs(idx+1)-1);
            % If point does not exist, then set its quality to NaN
            quality_sec(~bottom_sec) = NaN;
            % Assume good quality for all points that exist, but have NaN
            % quality.
            quality_sec(bottom_sec & isnan(quality_sec)) = 1;
            [x_sec,y_sec] = projfwd(user_variables.proj,layer(layer_idx).lat(idxs(idx):idxs(idx+1)-1),layer(layer_idx).lon(idxs(idx):idxs(idx+1)-1));
            x_sec = x_sec/1e3;
            y_sec = y_sec/1e3;
            
            %If the vector satisfies any condition, the middle point is
            %selected to be plotted.
            %if(all(green==1))
            if all(quality_sec==1)
              x_green(end+1) = mean(x_sec);
              y_green(end+1) = mean(y_sec);
            %elseif(all(yellow==1))
            elseif all(quality_sec==1 | quality_sec==2)
              x_yellow(end+1) = mean(x_sec);
              y_yellow(end+1) = mean(y_sec);
%               x_yellow = cat(2, x_yellow,x_sec(round(length(yellow)/2)));
%               y_yellow = cat(2, y_yellow,y_sec(round(length(yellow)/2)));
            %elseif(all(red==1))
            elseif all(isnan(quality_sec))
              x_red(end+1) = mean(x_sec);
              y_red(end+1) = mean(y_sec);
%               x_red = cat(2, x_red,x_sec(round(length(red)/2)));
%               y_red = cat(2, y_red,y_sec(round(length(red)/2)));
            else
              %if(any(magenta==1))
              x_magenta(end+1) = mean(x_sec);
              y_magenta(end+1) = mean(y_sec);
%               x_magenta = cat(2, x_magenta,x_sec(round(length(magenta)/2)));
%               y_magenta = cat(2, y_magenta,y_sec(round(length(magenta)/2)));
            end
            
          end
        end
       
      
      end
      
      %Plotting
      if ~isempty(x_green)
        good_data_handles(season_idx) = plot(x_green, y_green,'g.');
      else
        good_data_handles(season_idx) = plot(1,NaN,'g.');
      end
      
      if ~isempty(x_yellow)      
        mod_data_handles(season_idx) = plot(x_yellow, y_yellow,'y.');
      else
        mod_data_handles(season_idx) = plot(1,NaN,'y.');
      end
      
      if ~isempty(x_magenta)      
        mag_data_handles(season_idx) = plot(x_magenta, y_magenta,'m.');
      else
        mag_data_handles(season_idx) = plot(1,NaN,'m.');
      end
      
      if ~isempty(x_red)      
        bad_data_handles(season_idx) = plot(x_red, y_red,'r.');
      else
        bad_data_handles(season_idx) = plot(1,NaN,'r.');
      end

      
    end
      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLAIN DECIMATION METHOD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  elseif strcmpi(user_variables.method,'dec')
    
        
    % for plotting the quality of data
    bad_data_handles = [];
    moderate_data_handles = [];
    good_data_handles = [];
    
    for season_idx = 1:length(params)
      for param_idx = 1:length(params{season_idx})
        param = params{season_idx}(param_idx);
        param = merge_structs(param,gRadar);
        
        try
          layer = opsLoadLayers(param,layer_params);
        catch
          continue;
        end
        
        if isempty(layer)
          continue;
        end;
        
        for layer_idx = 1:length(layer)
        
          if length(layer(layer_idx).lat) ~= length(layer(layer_idx).type)
            fprintf('    Bad file\n');
            continue;
          end
          
          along_track = geodetic_to_along_track(layer(layer_idx).lat,layer(layer_idx).lon,zeros(size(layer(layer_idx).lat)));
          idxs = get_equal_alongtrack_spacing_idxs(along_track,500);
    
          bottom = cat(2,bottom,isfinite(layer(layer_idx).twtt(idxs)));
          quality = cat(2,quality,layer(layer_idx).quality(idxs));
          [x_tmp,y_tmp] = projfwd(user_variables.proj,layer(layer_idx).lat(idxs),layer(layer_idx).lon(idxs));
          x = cat(2,x,x_tmp/1e3);
          y = cat(2,y,y_tmp/1e3);
        end
      end
      
      no_bottom_mask = bottom==0;
      moderate_mask = bottom==1 & quality > 1;
      bottom_mask = bottom==1 & ~moderate_mask;
      
      if any(no_bottom_mask)
        bad_data_handles(season_idx) = plot(x(no_bottom_mask),y(no_bottom_mask),'r.');
      else
        bad_data_handles(season_idx) = plot(1,NaN,'r.');
      end
      if any(moderate_mask)
        moderate_data_handles(season_idx) = plot(x(moderate_mask),y(moderate_mask),'y.');
      else
        moderate_data_handles(season_idx) = plot(1,NaN,'y.');
      end
      if any(bottom_mask)
        good_data_handles(season_idx) = plot(x(bottom_mask),y(bottom_mask),'g.');
      else
        good_data_handles(season_idx) = plot(1,NaN,'g.');
      end
      
    end
    
  end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  





    % saving the coverage map
    if user_variables.save_img == 1
      for ext_idx = 1:length(user_variables.ext)
        if strcmp(user_variables.ext{ext_idx}, '.fig')
%           image_fn_name = sprintf('saveas_2014_P3_coverage_map_%s', date);
%           image_fn = fullfile(user_variables.out_dir,image_fn_name);
%           saveas(figure(1), image_fn);

%           image_fn_name = sprintf('aggregate_greenland_master_coverage_map_%s', date);
          
          image_fn_name = sprintf('coverage_map%s', date);
          image_fn = fullfile(user_variables.out_dir,image_fn_name);
          savefig(figure(1), image_fn, 'compact');

%           image_fn_name = sprintf('hgsave_2014_P3_coverage_map_%s', date);
%           image_fn = fullfile(user_variables.out_dir,image_fn_name);
%           hgsave(1, strcat('',image_fn), '-v7.3');
        else
%           image_fn_name = sprintf('Master_fig_coverage_map_%s%s', date, user_variables.ext{ext_idx});
%           image_fn = fullfile(user_variables.out_dir,image_fn_name);
%           saveas(figure(1), image_fn);

        end
        %         saveas(image_fn, user_variables.ext{ext_idx},'-v7.3');
      end
    end
    
end
return

