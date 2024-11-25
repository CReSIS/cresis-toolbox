% Class geotiff
%
% Class which creates a GUI for a Geotiff map and segments. If the geotiff
% is not specified, then lat, lon are used.
%
% Examples:
% obj = geotiff(geotiff_fn); % where geotiff_fn is the path to a geotiff
%
% obj = geotiff(''); % for lat/lon plot with no geotiff in background
% segment.lat = [60:70].';
% segment.lon = [-45:-35].';
% segment.name = 'First';
% A = cos(0:10).';
% segment.value = mat2cell(A,ones(size(A,1),1),ones(1,size(A,2)));
% segment.value_name{1} = 'Cosine';
% fns = {}; for idx=1:11; fns{idx,1} = sprintf('%d',idx); end;
% segment.value = cat(2,segment.value,fns);
% segment.value_name{2} = 'Index';
% obj.insert_segment(segment);

classdef (HandleCompatible = true) geotiff < handle
  properties
    % GUI handles
    h_fig
    h_axes
    h_fig_owned_by_geotiff
    line_style
    marker
    quiver_scale
    
    % zoom_mode: boolean
    zoom_mode
    
    % Projection information
    proj
    
    % Segment information is a struct array with fields:
    %  .name: string
    %  .lat: Nx1 double vector
    %  .lon: Nx1 double vector
    %  .x: Nx1 double vector
    %  .y: Nx1 double vector
    %  .value: NxM cell array
    %  .value_name: 1xM cell array of strings
    %  .h_plot: handle to plot
    %  .h_quiver: handle to quiver plot
    %  .h_plot_selected: handle to selected plot
    %  .h_text: handle to text
    segments
    
    xlims
    ylims
    
    % x,y: the location of the mouse at button_down
    x
    y
    ctrl_pressed
    shift_pressed
    
    % Behavior customization controls
    % stdout: set to false to disable stdout
    stdout
    F1_callback
    button_up_callback
    key_press_callback
    
  end
  
  events
    close_window_event % Signalled when user tries to close the window
    selection_event % Signalled when user changes the selection
  end
  
  methods
    %% Creator
    function obj = geotiff(geotiff_fn,h_fig)
      
      % Check inputs and setup figure
      if ~exist('geotiff_fn','var')
        geotiff_fn = '';
      end
      if ~exist('h_fig','var') || isempty(h_fig)
        obj.h_fig = figure;
        obj.h_fig_owned_by_geotiff = true;
        obj.h_axes = axes('parent',obj.h_fig);
        set(obj.h_fig,'DockControls','off');
        set(obj.h_fig,'ToolBar','none');
        set(obj.h_fig,'MenuBar','none');
      elseif length(h_fig) == 1
        obj.h_fig = h_fig;
        obj.h_fig_owned_by_geotiff = false;
        clf(obj.h_fig);
        obj.h_axes = axes('parent',obj.h_fig);
      else
        obj.h_axes = h_fig(2);
        obj.h_fig = h_fig(1);
        obj.h_fig_owned_by_geotiff = false;
      end
      
      % Create image and axes
      try
        if isempty(geotiff_fn)
          error('No geotiff file specified, using lat/lon.');
        end
        [obj.proj] = geotiff_plot(geotiff_fn,[],[],[obj.h_fig obj.h_axes]);
        xlabel(obj.h_axes,'X (km)');
        ylabel(obj.h_axes,'Y (km)');
        obj.xlims = xlim(obj.h_axes);
        obj.ylims = ylim(obj.h_axes);
      catch ME
        ME.getReport
        obj.proj = [];
        xlabel(obj.h_axes,'Longitude (deg)');
        ylabel(obj.h_axes,'Latitude (deg)');
        obj.xlims = [];
        obj.ylims = [];
      end
      hold(obj.h_axes,'on')
      
      % Set figure call back functions
      set(obj.h_fig,'WindowButtonUpFcn',@obj.button_up);
      set(obj.h_fig,'WindowButtonDownFcn',@obj.button_down);
      set(obj.h_fig,'WindowScrollWheelFcn',@obj.button_scroll);
      set(obj.h_fig,'WindowButtonMotionFcn',@obj.button_motion);
      set(obj.h_fig,'WindowKeyPressFcn',@obj.key_press);
      set(obj.h_fig,'WindowKeyReleaseFcn',@obj.key_release);
      set(obj.h_fig,'CloseRequestFcn',@obj.close_win);
      
      % Set up zoom
      zoom_setup(obj.h_fig);
      axis tight;
      obj.zoom_mode = true;
      set(obj.h_fig,'pointer','custom');
      
      obj.x = NaN;
      obj.y = NaN;
      obj.ctrl_pressed = false;
      obj.shift_pressed = false;
      
      % Behavior controls
      obj.stdout = true;
      obj.F1_callback = [];
      obj.button_up_callback = [];
      obj.key_press_callback = [];

      % Setup segments
      obj.line_style = '-';
      obj.marker = 'x';
      obj.quiver_scale = 0.4;
      obj.segments = [];

    end
    
    %% Destructor
    function delete(obj)
      if obj.h_fig_owned_by_geotiff
        % Delete the map figure handle
        try
          delete(obj.h_fig);
        end
      end
    end
    
    %% Close Window Handler
    function close_win(obj,h_obj,event)
      if obj.h_fig_owned_by_geotiff
        try
          delete(obj);
        end
      else
        notify(obj,'close_window_event');
      end
    end
    
    %% Button down handler
    function button_down(obj,h_obj,event)
      [obj.x,obj.y,but] = get_mouse_info(obj.h_fig,obj.h_axes);
      %fprintf('Button Down: x = %.3f, y = %.3f, but = %d\n', obj.x, obj.y, but); % DEBUG ONLY
      rbbox;
    end
    
    %% Button up handler
    function button_up(obj,h_obj,event)
      [x,y,but] = get_mouse_info(obj.h_fig,obj.h_axes);
      %fprintf('Button Up: x = %.3f, y = %.3f, but = %d\n', x, y, but); % DEBUG ONLY
      if obj.zoom_mode
        zoom_button_up(x,y,but,struct('x',obj.x,'y',obj.y, ...
          'h_axes',obj.h_axes,'xlims',obj.xlims,'ylims',obj.ylims,'axis_equal',true));
      else
        if ~obj.ctrl_pressed
          if ~isempty(obj.button_up_callback) && but == 3
            if ~obj.button_up_callback(h_obj,event)
              return;
            end
          end
          % Release all current selections
          for idx = 1:length(obj.segments)
            obj.segments(idx).selected = NaN*zeros(size(obj.segments(idx).y));
            set(obj.segments(idx).h_plot_selected,'YData',obj.segments(idx).selected);
          end
        end
        % Find selected points and print there values out
        if obj.stdout; fprintf('Selection:\n'); end;
        
        min_x = min(x,obj.x);
        max_x = max(x,obj.x);
        min_y = min(y,obj.y);
        max_y = max(y,obj.y);
        if min_x == max_x && min_y == max_y
          % Left click
          % 1. Find the closest point
          min_dist = inf;
          for idx = 1:length(obj.segments)
            [dist,pnt_idx] = min((obj.segments(idx).x-min_x).^2+(obj.segments(idx).y-min_y).^2);
            if dist < min_dist
              min_dist = dist;
              min_idx = idx;
              min_pnt_idx = pnt_idx;
            end
          end
          % 2. If a point was found, then select it
          if isfinite(min_dist)
            idx = min_idx;
            match_mask = false(size(obj.segments(idx).x));
            match_mask(min_pnt_idx) = true;
            
            obj.segments(idx).selected = NaN*zeros(size(obj.segments(idx).y));
            obj.segments(idx).selected(match_mask) = obj.segments(idx).y(match_mask);
            set(obj.segments(idx).h_plot_selected,'YData',obj.segments(idx).selected,'Marker','o','LineWidth',2);
            if obj.stdout
              fprintf('  Segment: %s\n', obj.segments(idx).name);
              for pnt_idx = find(match_mask(:).')
                for val_idx = 1:length(obj.segments(idx).value_name)
                  if ischar(obj.segments(idx).value{pnt_idx,val_idx})
                    fprintf('    %s: %s\n', obj.segments(idx).value_name{val_idx}, obj.segments(idx).value{pnt_idx,val_idx});
                  else
                    fprintf('    %s: %g\n', obj.segments(idx).value_name{val_idx}, obj.segments(idx).value{pnt_idx,val_idx});
                  end
                end
              end
            end
          end
          
        else
          % Left click and drag
          for idx = 1:length(obj.segments)
            % 1. For each segment, find the points enclosed by ribbon box
            match_mask = obj.segments(idx).x >= min_x & obj.segments(idx).x <= max_x ...
              & obj.segments(idx).y >= min_y & obj.segments(idx).y <= max_y;
            match_mask = xor(match_mask,~isnan(obj.segments(idx).selected));
            % 2. Select each of those points
            obj.segments(idx).selected = NaN*zeros(size(obj.segments(idx).y));
            obj.segments(idx).selected(match_mask) = obj.segments(idx).y(match_mask);
            set(obj.segments(idx).h_plot_selected,'YData',obj.segments(idx).selected,'Marker','o','LineWidth',2);
            if obj.stdout
              if any(match_mask)
                fprintf('  Segment: %s\n', obj.segments(idx).name);
                for pnt_idx = find(match_mask(:).')
                  for val_idx = 1:length(obj.segments(idx).value_name)
                    if ischar(obj.segments(idx).value{pnt_idx,val_idx})
                      fprintf('    %s: %s\n', obj.segments(idx).value_name{val_idx}, obj.segments(idx).value{pnt_idx,val_idx});
                    else
                      fprintf('    %s: %g\n', obj.segments(idx).value_name{val_idx}, obj.segments(idx).value{pnt_idx,val_idx});
                    end
                  end
                end
              end
            end
          end
        end
        
        notify(obj,'selection_event');
      end
    end
    
    %% Button scroll handler
    function button_scroll(obj,h_obj,event)
      zoom_button_scroll(event,struct('h_fig',obj.h_fig, ...
        'h_axes',obj.h_axes,'xlims',obj.xlims,'ylims',obj.ylims,'axis_equal',true));
    end
    
    %% Button motion handler
    function button_motion(obj,src,event)
      zoom_button_motion(event,struct('h_fig',obj.h_fig, ...
        'h_axes',obj.h_axes,'xlims',obj.xlims,'ylims',obj.ylims,'axis_equal',true,'zoom_mode',obj.zoom_mode));
    end
    
    %% Key press handler
    function key_press(obj,src,event)
      
      if any(strcmp('shift',event.Modifier))
        obj.shift_pressed = true;
      else
        obj.shift_pressed = false;
      end
      
      if any(strcmp('control',event.Modifier))
        obj.ctrl_pressed = true;
      else
        obj.ctrl_pressed = false;
      end
      
      if ~isempty(obj.key_press_callback)
        if ~obj.key_press_callback(src,event)
          return;
        end
      end
      
      % Check to make sure that a key was pressed and not
      % just a modifier (e.g. shift, ctrl, alt)
      if ~isempty(event.Key)
        
        % see event.Modifier for modifiers
        switch event.Key
          
          case 'f1'
            fprintf('\n<strong>Key Short Cuts</strong>\n');
            fprintf('z: Toggle between zoom mode and tool mode\n');
            fprintf('ctrl-z: Reset zoom to view whole image\n');
            fprintf('arrows: pan in the direction of the arrow\n');
            %fprintf('p: Select the previous point\n');
            %fprintf('n: Select the next point\n');
            
            fprintf('<strong>Tool Mode</strong>\n');
            fprintf('left-click and drag: prints information about selected points\n');
            fprintf('scroll: zoom in/out at point\n');
            
            fprintf('<strong>Zoom Mode</strong>\n');
            fprintf('left-click and drag: zoom to selection\n');
            fprintf('left-click: zoom in at point\n');
            fprintf('right-click: zoom out at point\n');
            fprintf('scroll: zoom in/out at point\n');
            
            if ~isempty(obj.F1_callback)
              obj.F1_callback(src,event);
            end
            
            fprintf('\n');
            
          case 'z'
            if obj.ctrl_pressed
              % zoom reset
              axis tight;
            else
              % toggle zoom mode
              obj.zoom_mode = ~obj.zoom_mode;
              if obj.zoom_mode
                set(obj.h_fig,'pointer','custom');
              else
                set(obj.h_fig,'pointer','arrow');
              end
            end
            
          case 'downarrow' % Down-arrow: Pan down
            zoom_arrow(event,struct('h_axes',obj.h_axes, ...
              'xlims',obj.xlims,'ylims',obj.ylims));
            
          case 'uparrow' % Up-arrow: Pan up
            zoom_arrow(event,struct('h_axes',obj.h_axes, ...
              'xlims',obj.xlims,'ylims',obj.ylims));
            
          case 'rightarrow' % Right arrow: Pan right
            zoom_arrow(event,struct('h_axes',obj.h_axes, ...
              'xlims',obj.xlims,'ylims',obj.ylims));
            
          case 'leftarrow' % Left arrow: Pan left
            zoom_arrow(event,struct('h_axes',obj.h_axes, ...
              'xlims',obj.xlims,'ylims',obj.ylims));
            
          otherwise
            
        end
        
      end
    end
    
    %% Key release handler
    function key_release(obj,src,event)
      
      if any(strcmp('shift',event.Modifier))
        obj.shift_pressed = true;
      else
        obj.shift_pressed = false;
      end
      
      if any(strcmp('control',event.Modifier))
        obj.ctrl_pressed = true;
      else
        obj.ctrl_pressed = false;
      end
      
    end
    
    %% Insert segment method
    function color = insert_segment(obj,segment)
      %  .name: string
      %  .lat: Nx1 double vector
      %  .lon: Nx1 double vector
      %  .value: NxM cell array, e.g. mat2cell(A,ones(size(A,1),1),ones(1,size(A,2))
      %  .value_name: 1xM cell array of strings
      
      N = size(segment.lat,1);
      M = size(segment.value_name,2);
      
      if size(segment.lat,2) > 1 ...
          || size(segment.value_name,1) > 1 ...
          || any(size(segment.lat)~=size(segment.lon)) ...
          || ~ischar(segment.name) ...
          || ~isempty(segment.value) && any(size(segment.value)~=[N M]) ...
          || any(~cellfun(@ischar,segment.value_name))
        error('Failed input check');
      end
      
      if isempty(obj.proj)
        x = segment.lon;
        y = segment.lat;
      else
        [x,y] = projfwd(obj.proj,segment.lat,segment.lon);
        x = x/1e3;
        y = y/1e3;
      end
      
      % Add new segment into the obj.segments property
      if isempty(obj.segments)
        obj.segments.name = segment.name;
      else
        obj.segments(end+1).name = segment.name;
      end
      obj.segments(end).lat = segment.lat;
      obj.segments(end).lon = segment.lon;
      obj.segments(end).x = x;
      obj.segments(end).y = y;
      obj.xlims(1) = min([obj.xlims(1:end-1);x]);
      obj.xlims(2) = max([obj.xlims(2:end);x]);
      obj.ylims(1) = min([obj.ylims(1:end-1);y]);
      obj.ylims(2) = max([obj.ylims(2:end);y]);
      
      obj.segments(end).value = segment.value;
      obj.segments(end).value_name= segment.value_name;
      
      % Plot
      obj.segments(end).selected = NaN*zeros(size(y));
      if ~isempty(x)
        obj.segments(end).h_plot = plot(x,y,'LineStyle',obj.line_style,'Marker',obj.marker,'Linewidth',2,'Parent',obj.h_axes);
        obj.segments(end).h_quiver = quiver(x,y,obj.quiver_scale*[diff(x); 0],obj.quiver_scale*[diff(y); 0],0,'Color',get(obj.segments(end).h_plot,'Color'));
        obj.segments(end).h_plot_selected = plot(x,obj.segments(end).selected,'LineStyle',obj.line_style,'Marker',obj.marker,'Linewidth',2,'Parent',obj.h_axes,'MarkerSize',10);
      else
        obj.segments(end).h_plot = plot(NaN,NaN,'LineStyle',obj.line_style,'Marker',obj.marker,'Linewidth',2,'Parent',obj.h_axes);
        set(obj.segments(end).h_plot,'XData',[],'YData',[]);
        obj.segments(end).h_quiver = quiver(NaN,NaN,0,0,0,'Color',get(obj.segments(end).h_plot,'Color'));
        set(obj.segments(end).h_quiver,'XData',[],'YData',[],'UData',[],'VData',[]);
        obj.segments(end).h_plot_selected = plot(NaN,NaN,'LineStyle',obj.line_style,'Marker',obj.marker,'Linewidth',2,'Parent',obj.h_axes,'MarkerSize',10);
        set(obj.segments(end).h_plot_selected,'XData',[],'YData',[]);
      end
      color = get(obj.segments(end).h_plot,'Color');
      
      if ~isempty(x)
        obj.segments(end).h_text = text(x(1),y(1),obj.segments(end).name,'Color',color,'Parent',obj.h_axes);
      else
        obj.segments(end).h_text = text(NaN,NaN,obj.segments(end).name,'Color',color,'Parent',obj.h_axes);
      end
      for idx=1:length(obj.segments)
        uistack(obj.segments(idx).h_text,'top');
      end
      
    end
    
    %% Insert point method
    function insert_pnt(obj,idx,pnt,segment)
      if pnt < 0 || pnt > length(obj.segments(idx).lat)
        error('pnt(%d) is outside valid range [0,%d].', pnt, length(obj.segments(idx).lat));
      end
      
      if isempty(obj.proj)
        x = segment.lon(:);
        y = segment.lat(:);
      else
        [x,y] = projfwd(obj.proj,segment.lat(:),segment.lon(:));
        x = x/1e3;
        y = y/1e3;
      end
      
      if ~isempty(obj.segments(idx).value) || isempty(obj.segments(idx).lat)
        obj.segments(idx).value = [obj.segments(idx).value(1:pnt,:); segment.value; obj.segments(idx).value(pnt+1:end,:)];
      end
      obj.segments(idx).lat = [obj.segments(idx).lat(1:pnt); segment.lat(:); obj.segments(idx).lat(pnt+1:end)];
      obj.segments(idx).lon = [obj.segments(idx).lon(1:pnt); segment.lon(:); obj.segments(idx).lon(pnt+1:end)];
      obj.segments(idx).x = [obj.segments(idx).x(1:pnt); x; obj.segments(idx).x(pnt+1:end)];
      obj.segments(idx).y = [obj.segments(idx).y(1:pnt); y; obj.segments(idx).y(pnt+1:end)];
      
      set(obj.segments(idx).h_plot, 'XData', obj.segments(idx).x, ...
        'YData', obj.segments(idx).y);
      
      set(obj.segments(idx).h_quiver, 'XData', obj.segments(idx).x, ...
        'YData', obj.segments(idx).y, 'UData', obj.quiver_scale*[diff(obj.segments(idx).x); 0], ...
        'VData', obj.quiver_scale*[diff(obj.segments(idx).y); 0]);
      
      obj.segments(idx).selected = [obj.segments(idx).selected(1:pnt); nan(size(x)); obj.segments(idx).selected(pnt+1:end)];
      set(obj.segments(idx).h_plot_selected, 'XData', obj.segments(idx).x, ...
        'YData', obj.segments(idx).selected);
      
      if pnt == 0
        set(obj.segments(idx).h_text, 'Position', ...
          [obj.segments(idx).x(1) obj.segments(idx).y(1) 0]);
      end
    end
    
    %% Update point method
    function update_pnt(obj,idx,pnts,segment)
      if isempty(obj.proj)
        x = segment.lon;
        y = segment.lat;
      else
        [x,y] = projfwd(obj.proj,segment.lat,segment.lon);
        x = x/1e3;
        y = y/1e3;
      end
      
      obj.segments(idx).lat(pnts) = segment.lat;
      obj.segments(idx).lon(pnts) = segment.lon;
      obj.segments(idx).x(pnts) = x;
      obj.segments(idx).y(pnts) = y;
      obj.segments(idx).value(pnts,:) = segment.value;
      
      set(obj.segments(idx).h_plot, 'XData', obj.segments(idx).x, ...
        'YData', obj.segments(idx).y);
      
      set(obj.segments(idx).h_quiver, 'XData', obj.segments(idx).x, ...
        'YData', obj.segments(idx).y, 'UData', obj.quiver_scale*[diff(obj.segments(idx).x); 0], ...
        'VData', obj.quiver_scale*[diff(obj.segments(idx).y); 0]);
      
      obj.segments(idx).selected(~isnan(obj.segments(idx).selected)) ...
        = obj.segments(idx).y(~isnan(obj.segments(idx).selected));
      set(obj.segments(idx).h_plot_selected, 'XData', obj.segments(idx).x, ...
        'YData', obj.segments(idx).selected);
      
      if any(pnts == 1)
        set(obj.segments(idx).h_text, 'Position', ...
          [obj.segments(idx).x(1) obj.segments(idx).y(1) 0]);
      end
    end
    
    %% Delete point method
    function delete_pnt(obj,idx,pnts)
      mask = true(size(obj.segments(idx).lat));
      mask(pnts) = false;
      
      obj.segments(idx).lat = obj.segments(idx).lat(mask);
      obj.segments(idx).lon = obj.segments(idx).lon(mask);
      obj.segments(idx).x = obj.segments(idx).x(mask);
      obj.segments(idx).y = obj.segments(idx).y(mask);
      if ~isempty(obj.segments(idx).value)
        obj.segments(idx).value = obj.segments(idx).value(mask,:);
      end
      
      set(obj.segments(idx).h_plot, 'XData', obj.segments(idx).x, ...
        'YData', obj.segments(idx).y);
      
      if isempty(obj.segments(idx).x)
        set(obj.segments(idx).h_quiver, 'XData', [], ...
          'YData', [], 'UData', [], ...
          'VData', []);
      else
        set(obj.segments(idx).h_quiver, 'XData', obj.segments(idx).x, ...
          'YData', obj.segments(idx).y, 'UData', obj.quiver_scale*[diff(obj.segments(idx).x); 0], ...
          'VData', obj.quiver_scale*[diff(obj.segments(idx).y); 0]);
      end
      
      obj.segments(idx).selected = obj.segments(idx).selected(mask);
      set(obj.segments(idx).h_plot_selected, 'XData', obj.segments(idx).x, ...
        'YData', obj.segments(idx).selected);
      
      if isempty(obj.segments(idx).lat)
        set(obj.segments(idx).h_text, 'Position', ...
          [NaN NaN 0]);
      elseif any(pnts==1)
        set(obj.segments(idx).h_text, 'Position', ...
          [obj.segments(idx).x(1) obj.segments(idx).y(1) 0]);
      end
    end
    
    %% Delete segment method
    function delete_segment(obj,idx)
      try
        delete(obj.segments(idx).h_plot);
        delete(obj.segments(idx).h_quiver);
        delete(obj.segments(idx).h_plot_selected);
        obj.segments = obj.segments([1:idx-1 idx+1:end]);
      end
    end
    
    %% Set selected segment and points for that segment
    function set_selection(obj,idx,pnts)
      all_pnts = 1:length(obj.segments(idx).selected);
      pnts = intersect(pnts,all_pnts);
      
      set_idx = idx;
      % Release all current selections
      for idx = 1:length(obj.segments)
        obj.segments(idx).selected = NaN*zeros(size(obj.segments(idx).y));
        set(obj.segments(idx).h_plot_selected,'YData',obj.segments(idx).selected);
      end
      idx = set_idx;
      
      obj.segments(idx).selected = NaN*zeros(size(obj.segments(idx).y));
      obj.segments(idx).selected(pnts) = obj.segments(idx).y(pnts);
      set(obj.segments(idx).h_plot_selected,'YData',obj.segments(idx).selected,'Marker','o','LineWidth',2);
      if obj.stdout
        fprintf('  Segment: %s\n', obj.segments(idx).name);
        for pnt_idx = pnts
          for val_idx = 1:length(obj.segments(idx).value_name)
            if ischar(obj.segments(idx).value{pnt_idx,val_idx})
              fprintf('    %s: %s\n', obj.segments(idx).value_name{val_idx}, obj.segments(idx).value{pnt_idx,val_idx});
            else
              fprintf('    %s: %g\n', obj.segments(idx).value_name{val_idx}, obj.segments(idx).value{pnt_idx,val_idx});
            end
          end
        end
      end
    end
    
    %% Get selected segments and points for each segment
    function [mask,value] = get_selection(obj,idxs)
      value = {};
      all_idxs = 1:length(obj.segments);
      if ~exist('idxs','var')
        idxs = all_idxs;
      else
        idxs = intersect(idxs,all_idxs);
      end
      mask = cell(size(obj.segments));
      if nargout > 1
        value = cell(size(obj.segments));
      end
      for idx = idxs
        match_mask = ~isnan(obj.segments(idx).selected);
        mask{idx} = match_mask;
        if nargout > 1
          for val_idx = 1:length(obj.segments(idx).value_name)
            value{idx}(:,val_idx) = obj.segments(idx).value(match_mask,val_idx);
          end
        end
      end
    end
    
  end
end




