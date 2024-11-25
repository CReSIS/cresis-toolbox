% Class clip_vectors
%
% Class which creates a GUI for clipping out bad sections of vector
% graphics. Note that other graphics can be plotted on the same axes
% and not affected by simply excluding it from h_plots.
%
% figure;
% h_plots(1) = plot(1:5,[10 10 10 11 11]);
% hold on;
% h_plots(2) = plot(2:4,9:11,'rx');
% obj = clip_vectors(h_plots);

classdef (HandleCompatible = true) clip_vectors < handle
  properties
    % h_plots = matrix of plot handles, all with the same parent axes
    h_plots
    
    % bad_val = value that represents bad data (YData)
    bad_val
    
    % xdata and ydata = cell matrix of size(h_plots) containing original
    %   Xdata and YData for each entry in h_plots
    xdata
    ydata
    % old_xlims and old_ylims: the original limits of the data
    old_xlims
    old_ylims
    
    % Function handle hooks for customizing clip_vectors
    fh_close_win
    fh_button_up
    fh_button_motion
    fh_key_press
    user_data

    % tool_list: structure array of tools
    %  .event_key: string containing the matching event.Key,
    %  .shift_pressed: boolean matching shift_pressed,
    %  .ctrl_pressed: boolean matching ctrl_pressed,
    %  .help_str: string containing tool descriptor for F1/help,
    %  .fh_callback: function handle to manipulate data according to tool selection
    tool_list
    % active_tool_idx: index into tool_list of active tool (zero if no
    %   tool is active)
    active_tool_idx
    
    % Undo stack
    undo_stack
    
    % GUI handles
    h_fig
    h_axes
    sf % selection figure GUI handles
    
    % zoom_mode: boolean
    zoom_mode
    
    % x,y: the location of the mouse at button_down
    x
    y

    % actions: state structure that tells what the current action is
    %   (used for drawing polygon)
    actions
  end
  
  methods
    function obj = clip_vectors(h_plots,param)
      
      % Check inputs
      if ~exist('param','var')
        param = [];
      end
      if ~isfield(param,'bad_val')
        param.bad_val = NaN;
      end
      if ~isfield(param,'fh_close_win')
        param.fh_close_win = [];
      end
      if ~isfield(param,'fh_button_motion')
        param.fh_button_motion = [];
      end
      if ~isfield(param,'fh_button_up')
        param.fh_button_up = [];
      end
      if ~isfield(param,'fh_key_press')
        param.fh_key_press = [];
      end
      if ~isfield(param,'user_data')
        param.user_data = [];
      end
      if ~isfield(param,'tool_list')
        obj.tool_list = [];
        tool_idx = 0;
        
        tool_idx = tool_idx + 1;
        obj.tool_list(tool_idx).event_key = 'd';
        obj.tool_list(tool_idx).shift_pressed = NaN;
        obj.tool_list(tool_idx).ctrl_pressed = NaN;
        obj.tool_list(tool_idx).type = 'delete';
        obj.tool_list(tool_idx).help_str = 'd: delete (set work area to bad values)';
        obj.tool_list(tool_idx).fh_callback = @obj.tool_delete;
        
        tool_idx = tool_idx + 1;
        obj.tool_list(tool_idx).event_key = 'o';
        obj.tool_list(tool_idx).shift_pressed = NaN;
        obj.tool_list(tool_idx).ctrl_pressed = NaN;
        obj.tool_list(tool_idx).type = 'old';
        obj.tool_list(tool_idx).help_str = 'o: restores old values';
        obj.tool_list(tool_idx).fh_callback = @obj.tool_old;
      else
        obj.tool_list = tool_list;
      end
      
      % Set active tool to the first tool (or zero if no tools)
      obj.active_tool_idx = min(1,length(obj.tool_list));

      % Set parameters
      obj.h_plots = h_plots;
      obj.bad_val = param.bad_val;
      obj.fh_close_win = param.fh_close_win;
      obj.fh_button_up = param.fh_button_up;
      obj.fh_button_motion = param.fh_button_motion;
      obj.fh_key_press = param.fh_key_press;
      obj.user_data = param.user_data;
      obj.actions.getting_polygon = 0;
      
      % Get the parent axes and parent figure
      obj.h_axes = get(obj.h_plots(1),'Parent');
      obj.h_fig = get_parent_figure(obj.h_plots(1));
      
      % Copy all the original ydata (so the old tool to restore if needed)
      obj.old_xlims = [inf -inf];
      obj.old_ylims = [inf -inf];
      obj.xdata = {};
      obj.ydata = {};
      for idx = 1:numel(obj.h_plots)
        obj.ydata{idx} = get(obj.h_plots(idx),'YData');
        min_ydata = min(obj.ydata{idx});
        max_ydata = max(obj.ydata{idx});
        if min_ydata < obj.old_ylims(1)
          obj.old_ylims(1) = min_ydata;
        end
        if max_ydata > obj.old_ylims(2)
          obj.old_ylims(2) = max_ydata;
        end
        
        obj.xdata{idx} = get(obj.h_plots(idx),'XData');
        min_xdata = min(obj.xdata{idx});
        max_xdata = max(obj.xdata{idx});
        if min_xdata < obj.old_xlims(1)
          obj.old_xlims(1) = min_xdata;
        end
        if max_xdata > obj.old_xlims(2)
          obj.old_xlims(2) = max_xdata;
        end
      end
      
      % Set figure call back functions
      set(obj.h_fig,'CloseRequestFcn',@obj.close_win);
      set(obj.h_fig,'WindowButtonUpFcn',@obj.button_up);
      set(obj.h_fig,'WindowButtonUpFcn',@obj.button_up);
      set(obj.h_fig,'WindowButtonMotionFcn',@obj.button_motion);
      set(obj.h_fig,'WindowButtonDownFcn',@obj.button_down);
      set(obj.h_fig,'WindowScrollWheelFcn',@obj.button_scroll);
      set(obj.h_fig,'WindowKeyPressFcn',@obj.key_press);

      % Set up undo stack
      obj.undo_stack = imb.undo_stack(struct('id',1));
      addlistener(obj.undo_stack,'synchronize_event',@obj.cmds_synchronize);
      
      % Set up zoom
      zoom_setup(obj.h_fig);
      obj.zoom_mode = true;
      set(obj.h_fig,'pointer','custom');
      
      obj.create_ui();
    end
    
    function delete(obj)
      try
        delete(obj.sf.h_fig);
      end
      try
        delete(obj.h_fig);
      end
    end
    
    function close_win(obj,varargin)
      try
        if ~isempty(obj.fh_close_win)
          obj.fh_close_win(obj);
        end
      end
      try
        delete(obj);
      end
    end
    
    function button_down(obj,h_obj,event)
      if obj.actions.getting_polygon
        if obj.actions.getting_polygon == 2
          obj.actions.getting_polygon = 0;
        end
      end
      [obj.x,obj.y,but] = get_mouse_info(obj.h_fig,obj.h_axes);
      fprintf('Button Down: x = %.3f, y = %.3f, but = %d\n', obj.x, obj.y, but); % DEBUG ONLY
      rbbox;
    end
    
    function button_motion(obj,h_obj,event)
      if ~isempty(obj.fh_button_motion)
        obj.fh_button_motion(obj,h_obj,event);
      end
    end
    
    function button_up(obj,h_obj,event)
      if obj.actions.getting_polygon
        return;
      end
      
      if ~isempty(obj.fh_button_up)
        status = obj.fh_button_up(obj,h_obj,event);
        if status == 0
          return;
        end
      end
      
      [x,y,but] = get_mouse_info(obj.h_fig,obj.h_axes);
      fprintf('Button Up: x = %.3f, y = %.3f, but = %d\n', x, y, but); % DEBUG ONLY
      if obj.zoom_mode
        zoom_button_up(x,y,but,struct('x',obj.x,'y',obj.y, ...
          'h_axes',obj.h_axes,'xlims',obj.old_xlims,'ylims',obj.old_ylims));
      elseif obj.active_tool_idx ~= 0
        % Tool mode and there is an active tool
        
        % Determine work area
        xlims = sort([x obj.x]);
        ylims = sort([y obj.y]);
        xlims(1) = max(xlims(1),obj.old_xlims(1));
        ylims(1) = max(ylims(1),obj.old_ylims(1));
        xlims(2) = min(xlims(2),obj.old_xlims(2));
        ylims(2) = min(ylims(2),obj.old_ylims(2));
        polygon.xv = xlims([1 1 2 2 1]);
        polygon.yv = ylims([1 2 2 1 1]);

        % Apply active tool
        obj.tool_list(obj.active_tool_idx).fh_callback(polygon);
      end
    end
    
    function button_scroll(obj,h_obj,event)
      zoom_button_scroll(event,struct('h_fig',obj.h_fig, ...
        'h_axes',obj.h_axes,'xlims',obj.old_xlims,'ylims',obj.old_ylims));
    end
    
    function key_press(obj,src,event)
      
      if any(strcmp('shift',event.Modifier))
        shift_pressed = true;
      else
        shift_pressed = false;
      end
      
      if any(strcmp('control',event.Modifier))
        ctrl_pressed = true;
      else
        ctrl_pressed = false;
      end
      
      if ~isempty(obj.fh_key_press)
        status = obj.fh_key_press(src,event);
        if status == 0
          return;
        end
      end
      
      % Check to make sure that a key was pressed and not
      % just a modifier (e.g. shift, ctrl, alt)
      if ~isempty(event.Key)
        
        % see event.Modifier for modifiers
        switch event.Key
          
          case 'f1'
            fprintf('============================================================\n');
            fprintf('clip_vectors.m help message\n');
            fprintf('============================================================\n');
            fprintf('Key Short Cuts\n');
            fprintf('F1: print this help message\n');
            fprintf('f: open the selection filter window\n');
            fprintf('p: draw a polygon to select the working area\n');
            fprintf('u: undo the last command\n');
            fprintf('r: redo a command that has been undone\n');
            fprintf('z: Toggle between zoom mode and tool mode\n');
            fprintf('ctrl-z: Reset zoom to view whole image\n');
            fprintf('arrows: pan in the direction of the arrow\n');
            for tool_idx = 1:length(obj.tool_list)
              fprintf(obj.tool_list(tool_idx).help_str);
            end
            
            fprintf('Tool Mode\n');
            fprintf('left-click and drag: selects a rectangular work area\n');
            fprintf('scroll: zoom in/out at point\n');
            
            fprintf('Zoom Mode\n');
            fprintf('left-click and drag: zoom to selection\n');
            fprintf('left-click: zoom in at point\n');
            fprintf('right-click: zoom out at point\n');
            fprintf('scroll: zoom in/out at point\n');
            fprintf('============================================================\n');
            
          case 'z'
            if ctrl_pressed
              %% zoom reset
              xlim(obj.old_xlims);
              ylim(obj.old_ylims);
            else
              %% toggle zoom mode
              obj.zoom_mode = ~obj.zoom_mode;
              if obj.zoom_mode
                set(obj.h_fig,'pointer','custom');
              else
                set(obj.h_fig,'pointer','arrow');
              end
            end
            
          case 'p'
            if obj.active_tool_idx ~= 0
              obj.actions.getting_polygon = 1;
              poly_handle = impoly;
              position = wait(poly_handle);
              obj.actions.getting_polygon = 2;
              [polyPts] = getPosition(poly_handle);
              xPoly = polyPts(:,1);
              yPoly = polyPts(:,2);
              delete(poly_handle);

              polygon.xv = xPoly;
              polygon.yv = yPoly;
            
              % Apply active tool
              obj.tool_list(obj.active_tool_idx).fh_callback(polygon);
            end
            
          case 's'
            %% Make the selection filter window visible
            set(obj.sf.h_fig,'Visible','on')
            
          case 'r'
            %% Redo last tool operation
            if length(obj.undo_stack.stack) > obj.undo_stack.pointer
              obj.undo_stack.redo();
              cmd = obj.undo_stack.peak(); cmd = cmd{1};
              if ~isempty(cmd.sf_mask)
                set(obj.sf.h_gui.caxis_maskCB,'Value',cmd.sf_mask);
              end
              if ~isempty(cmd.sf_min_val)
                obj.sf.h_gui.min_slider.set_value(cmd.sf_min_val);
              end
              if ~isempty(cmd.sf_max_val)
                obj.sf.h_gui.max_slider.set_value(cmd.sf_max_val);
              end
            else
              fprintf('No more commands to redo.\n');
            end
            
          case 'u'
            %% Undo last tool operation
            if ~isempty(obj.undo_stack.peak())
              obj.undo_stack.pop();
              cmd = obj.undo_stack.peak();
              if ~isempty(cmd)
                cmd = cmd{1};
                if ~isempty(cmd.sf_mask)
                  set(obj.sf.h_gui.caxis_maskCB,'Value',cmd.sf_mask);
                end
                if ~isempty(cmd.sf_min_val) && isfinite(cmd.sf_min_val)
                  obj.sf.h_gui.min_slider.set_value(cmd.sf_min_val);
                end
                if ~isempty(cmd.sf_max_val) && isfinite(cmd.sf_max_val)
                  obj.sf.h_gui.max_slider.set_value(cmd.sf_max_val);
                end
              end
            else
              fprintf('No more commands to undo.\n');
            end
            
          case 'downarrow' % Down-arrow: Move Echogram Down
            zoom_arrow(event,struct('h_axes',obj.h_axes, ...
              'xlims',obj.old_xlims,'ylims',obj.old_ylims));
            
          case 'uparrow' % Up-arrow: Move Echogram Up
            zoom_arrow(event,struct('h_axes',obj.h_axes, ...
              'xlims',obj.old_xlims,'ylims',obj.old_ylims));
            
          case 'rightarrow' % Right arrow
            zoom_arrow(event,struct('h_axes',obj.h_axes, ...
              'xlims',obj.old_xlims,'ylims',obj.old_ylims));
            
          case 'leftarrow' % Left arrow
            zoom_arrow(event,struct('h_axes',obj.h_axes, ...
              'xlims',obj.old_xlims,'ylims',obj.old_ylims));
            
          otherwise
            for tool_idx = 1:length(obj.tool_list)
              if strcmpi(obj.tool_list(tool_idx).event_key,event.Key)
                obj.active_tool_idx = tool_idx;
                break;
              end
            end
            
        end
        
      end
      
      if ~isempty(obj.fh_key_press)
        obj.fh_key_press(src,event)
      end
    end
    
    function set_data(obj,CData)
      obj.data = CData;
      set(obj.h_img,'CData',obj.data);
    end

    function tool_delete(obj,polygon)
      % Set values in selection mask to bad value
      fprintf('Adding delete command\n'); % DEBUG
      cmd.type = 'delete';
      cmd.polygon = polygon;

      cmd.sf_mask = get(obj.sf.h_gui.caxis_maskCB,'Value');
      if cmd.sf_mask
        auto_setting = get(obj.sf.h_gui.caxis_autoCB,'Value');
        if auto_setting
          % Get all the y values in the polygon
          ydata_polygon = [];
          for idx = 1:numel(obj.h_plots)
            xdata = get(obj.h_plots(idx),'XData');
            ydata = get(obj.h_plots(idx),'YData');
            
            idxs = find(inpolygon(xdata,ydata,polygon.xv,polygon.yv));
            ydata_polygon(end+(1:length(idxs))) = ydata(idxs);
          end
          
          mean_val = nanmean(ydata_polygon);
          std_val = nanstd(ydata_polygon);
          num_std = str2double(get(obj.sf.h_gui.caxis_num_stdLE,'String'));
          if num_std > 0 && ~isnan(mean_val) && ~isnan(std_val)
            obj.sf.h_gui.min_slider.set_value(mean_val-num_std*std_val);
            obj.sf.h_gui.max_slider.set_value(mean_val+num_std*std_val);
          end
        end
        
        cmd.sf_min_val = obj.sf.h_gui.min_slider.get_value();
        cmd.sf_max_val = obj.sf.h_gui.max_slider.get_value();
        
      else
        cmd.sf_min_val = -inf;
        cmd.sf_max_val = inf;
      end

      % Find the values that fall within the polygon and sf limits
      warning('off','MATLAB:inpolygon:ModelingWorldLower')
      for idx = 1:numel(obj.h_plots)
        xdata = get(obj.h_plots(idx),'XData');
        ydata = get(obj.h_plots(idx),'YData');
        
        cmd.idxs{idx} = find(inpolygon(xdata,ydata,polygon.xv,polygon.yv) & ydata >= cmd.sf_min_val & ydata <= cmd.sf_max_val);
        cmd.old_vals{idx} = ydata(cmd.idxs{idx});
        cmd.new_vals{idx} = obj.bad_val * ones(size(cmd.idxs{idx}));
      end
      
      obj.undo_stack.push(cmd);
    end
    
    function tool_old(obj,polygon)
      % Restores old values over all bad pixels (i.e. pixels with a value equal to
      %   bad value) in polygon mask
      fprintf('Adding old command\n'); % DEBUG
      cmd.type = 'old';
      cmd.polygon = polygon;

      cmd.sf_mask = get(obj.sf.h_gui.caxis_maskCB,'Value');
      if cmd.sf_mask
        auto_setting = get(obj.sf.h_gui.caxis_autoCB,'Value');
        if auto_setting
          % Get all the y values in the polygon
          ydata_polygon = [];
          for idx = 1:numel(obj.h_plots)
            xdata = get(obj.h_plots(idx),'XData');
            ydata = get(obj.h_plots(idx),'YData');
            
            idxs = find(inpolygon(xdata,ydata,polygon.xv,polygon.yv));
            ydata_polygon(end+(1:length(idxs))) = ydata(idxs);
          end
          
          mean_val = nanmean(ydata_polygon);
          std_val = nanstd(ydata_polygon);
          num_std = str2double(get(obj.sf.h_gui.caxis_num_stdLE,'String'));
          if num_std > 0 && ~isnan(mean_val) && ~isnan(std_val)
            obj.sf.h_gui.min_slider.set_value(mean_val-num_std*std_val);
            obj.sf.h_gui.max_slider.set_value(mean_val+num_std*std_val);
          end
          
          cmd.sf_min_val = obj.sf.h_gui.min_slider.get_value();
          cmd.sf_max_val = obj.sf.h_gui.max_slider.get_value();
        end
        
      else
        cmd.sf_min_val = -inf;
        cmd.sf_max_val = inf;
      end

      % Find the values that fall within the polygon and sf limits
      warning('off','MATLAB:inpolygon:ModelingWorldLower')
      for idx = 1:numel(obj.h_plots)
        xdata = obj.xdata{idx};
        ydata = obj.ydata{idx};
        cmd.idxs{idx} = find(inpolygon(xdata,ydata,polygon.xv,polygon.yv) & ydata >= cmd.sf_min_val & ydata <= cmd.sf_max_val);
        cmd.new_vals{idx} = ydata(cmd.idxs{idx});
        ydata = get(obj.h_plots(idx),'YData');
        cmd.old_vals{idx} = ydata(cmd.idxs{idx});
      end
      
      obj.undo_stack.push(cmd);
    end
    
    function cmds_synchronize(obj,varargin)
      % Applies commands from undo stack
      
      % Get the list of commands from the undo stack that need to be run to
      % synchronize the echowin
      [cmds_list,cmds_direction] = obj.undo_stack.get_synchronize_cmds();
      
      % Execute the commands
      if strcmpi(cmds_direction,'undo')
        for cmd_idx = 1:length(cmds_list)
          for idx = 1:numel(obj.h_plots)
            ydata = get(obj.h_plots(idx),'YData');
            ydata(cmds_list{cmd_idx}.idxs{idx}) = cmds_list{cmd_idx}.old_vals{idx};
            set(obj.h_plots(idx),'YData',ydata);
          end
        end
      elseif strcmpi(cmds_direction,'redo')
        for cmd_idx = 1:length(cmds_list)
          for idx = 1:numel(obj.h_plots)
            ydata = get(obj.h_plots(idx),'YData');
            ydata(cmds_list{cmd_idx}.idxs{idx}) = cmds_list{cmd_idx}.new_vals{idx};
            set(obj.h_plots(idx),'YData',ydata);
          end
        end
      end
    end
    
    
    % ====================================================================
    % ====================================================================
    % ====================================================================

    function sf_hide_win(obj,varargin)
      set(obj.sf.h_fig,'Visible','off')
    end
    
    function sf_update(obj,varargin)
      % Get the last command off the undostack
      cmd = obj.undo_stack.peak();
      if isempty(cmd)
        return;
      end
      obj.undo_stack.pop();
      
      % Put the command back on the undostack
      for tool_idx = 1:length(obj.tool_list)
        if strcmpi(obj.tool_list(tool_idx).type,cmd{1}.type)
          obj.tool_list(obj.active_tool_idx).fh_callback(cmd{1}.polygon);
          break;
        end
      end
    end
    
    function create_ui(obj)
      % clip_vectors.create_ui(obj)
      %
      % Create the selection filter figure and GUI

      ylims = [inf -inf];
      for idx = 1:numel(obj.h_plots)
        ydata = get(obj.h_plots(idx),'YData');
        min_ydata = min(ydata);
        max_ydata = max(ydata);
        if min_ydata < ylims(1)
          ylims(1) = min_ydata;
        end
        if max_ydata > ylims(2)
          ylims(2) = max_ydata;
        end
      end
      if isfinite(ylims) == [0 0]
        ylims = obj.old_ylims;
      end

      %% Create Figure
      obj.sf.h_fig = figure;
      %obj.sf.h_fig = figure('Visible','off');
      
      set(obj.sf.h_fig,'DockControls','off');
      set(obj.sf.h_fig,'NumberTitle','off');
      if isnumeric(obj.h_fig)
        set(obj.sf.h_fig,'Name',sprintf('%d: Selection Filter', obj.h_fig));
      else
        set(obj.sf.h_fig,'Name',sprintf('%d: Selection Filter', obj.h_fig.Number));
      end
      set(obj.sf.h_fig,'ToolBar','none');
      set(obj.sf.h_fig,'MenuBar','none');
      set(obj.sf.h_fig,'CloseRequestFcn',@obj.sf_hide_win);
      set(obj.sf.h_fig,'Units','Points');
      pos = get(obj.sf.h_fig,'Position');
      set(obj.sf.h_fig,'Position',[pos(1:2) 240 60]);
      
      %% Create GUI Objects
       
      obj.sf.h_gui.caxis_maskCB = uicontrol('Parent',obj.sf.h_fig);
      set(obj.sf.h_gui.caxis_maskCB,'Style','CheckBox');
      set(obj.sf.h_gui.caxis_maskCB,'String','Mask');
      set(obj.sf.h_gui.caxis_maskCB,'Value',false);
      set(obj.sf.h_gui.caxis_maskCB,'Callback',@obj.sf_update);
      
      obj.sf.h_gui.caxis_autoCB = uicontrol('Parent',obj.sf.h_fig);
      set(obj.sf.h_gui.caxis_autoCB,'Style','CheckBox');
      set(obj.sf.h_gui.caxis_autoCB,'String','Auto caxis');
      set(obj.sf.h_gui.caxis_autoCB,'Value',false);
      set(obj.sf.h_gui.caxis_autoCB,'Callback',@obj.sf_update);
      
      obj.sf.h_gui.caxis_num_stdLE = uicontrol('Parent',obj.sf.h_fig);
      set(obj.sf.h_gui.caxis_num_stdLE,'Style','Edit');
      set(obj.sf.h_gui.caxis_num_stdLE,'String','1');
      set(obj.sf.h_gui.caxis_num_stdLE,'Callback',@obj.sf_update);

      obj.sf.h_gui.min_slider = slider(obj.sf.h_fig,'Min',ylims,ylims(1));
      
      obj.sf.h_gui.max_slider = slider(obj.sf.h_fig,'Max',ylims,ylims(end));
      
      addlistener(obj.sf.h_gui.min_slider,'slider_changed',@obj.sf_update);
      addlistener(obj.sf.h_gui.max_slider,'slider_changed',@obj.sf_update);
      
      %% Create GUI Table
      obj.sf.h_gui.table.ui = obj.sf.h_fig;
      obj.sf.h_gui.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
      obj.sf.h_gui.table.height_margin = NaN*zeros(30,30);
      obj.sf.h_gui.table.false_width = NaN*zeros(30,30);
      obj.sf.h_gui.table.false_height = NaN*zeros(30,30);
      obj.sf.h_gui.table.offset = [0 0];
      
      row = 1;
      col = 1;
      obj.sf.h_gui.table.handles{row,col}   = obj.sf.h_gui.caxis_maskCB;
      obj.sf.h_gui.table.width(row,col)     = inf;
      obj.sf.h_gui.table.height(row,col)    = 20;
      obj.sf.h_gui.table.width_margin(row,col) = 1;
      obj.sf.h_gui.table.height_margin(row,col) = 1;
      col = 2;
      obj.sf.h_gui.table.handles{row,col}   = obj.sf.h_gui.caxis_autoCB;
      obj.sf.h_gui.table.width(row,col)     = inf;
      obj.sf.h_gui.table.height(row,col)    = 20;
      obj.sf.h_gui.table.width_margin(row,col) = 1;
      obj.sf.h_gui.table.height_margin(row,col) = 1;
      col = 3;
      obj.sf.h_gui.table.handles{row,col}   = obj.sf.h_gui.caxis_num_stdLE;
      obj.sf.h_gui.table.width(row,col)     = inf;
      obj.sf.h_gui.table.height(row,col)    = 20;
      obj.sf.h_gui.table.width_margin(row,col) = 1;
      obj.sf.h_gui.table.height_margin(row,col) = 1;
      
      row = row + 1;
      col = 1;
      obj.sf.h_gui.table.handles{row,col}   = obj.sf.h_gui.min_slider.h_text;
      obj.sf.h_gui.table.width(row,col)     = 50;
      obj.sf.h_gui.table.height(row,col)    = 20;
      obj.sf.h_gui.table.width_margin(row,col) = 1;
      obj.sf.h_gui.table.height_margin(row,col) = 5;
      col = 2;
      obj.sf.h_gui.table.handles{row,col}   = obj.sf.h_gui.min_slider.h_slider;
      obj.sf.h_gui.table.width(row,col)     = inf;
      obj.sf.h_gui.table.height(row,col)    = 20;
      obj.sf.h_gui.table.width_margin(row,col) = 1;
      obj.sf.h_gui.table.height_margin(row,col) = 1;
      col = 3;
      obj.sf.h_gui.table.handles{row,col}   = obj.sf.h_gui.min_slider.h_LE;
      obj.sf.h_gui.table.width(row,col)     = 50;
      obj.sf.h_gui.table.height(row,col)    = 20;
      obj.sf.h_gui.table.width_margin(row,col) = 1;
      obj.sf.h_gui.table.height_margin(row,col) = 1;
      
      row = row + 1;
      col = 1;
      obj.sf.h_gui.table.handles{row,col}   = obj.sf.h_gui.max_slider.h_text;
      obj.sf.h_gui.table.width(row,col)     = 50;
      obj.sf.h_gui.table.height(row,col)    = 20;
      obj.sf.h_gui.table.width_margin(row,col) = 1;
      obj.sf.h_gui.table.height_margin(row,col) = 5;
      col = 2;
      obj.sf.h_gui.table.handles{row,col}   = obj.sf.h_gui.max_slider.h_slider;
      obj.sf.h_gui.table.width(row,col)     = inf;
      obj.sf.h_gui.table.height(row,col)    = 20;
      obj.sf.h_gui.table.width_margin(row,col) = 1;
      obj.sf.h_gui.table.height_margin(row,col) = 1;
      col = 3;
      obj.sf.h_gui.table.handles{row,col}   = obj.sf.h_gui.max_slider.h_LE;
      obj.sf.h_gui.table.width(row,col)     = 50;
      obj.sf.h_gui.table.height(row,col)    = 20;
      obj.sf.h_gui.table.width_margin(row,col) = 1;
      obj.sf.h_gui.table.height_margin(row,col) = 1;
      
      clear row col
      table_draw(obj.sf.h_gui.table);
    end
    
  end
end




