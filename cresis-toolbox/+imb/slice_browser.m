% script imb.slice_browser
%
% Class for browsing 3D imagery one 2D slice at a time and for editing
% surfaces in that imagery.
%
% Contructor: slice_browser(data,h_control_image,param)
% data: 3D imagery
% h_control_image: optional handle to a Matlab "image" which has an x-axis
%   aligned with the third dimension of the data. Clicks in this figure
%   will then choose difference slices out of data based on the third axis.
% param: structure controlling the operation of slice_browser
%  .surfdata_fn: filename of .mat file containing surf structure array
%
% Surf file should contain surfdata class fields.
%
% Example:
%  See run_slice_browser.m
%
% Author: Elijah Paden, John Paden

classdef slice_browser < handle
  
  properties
    select_mask
    data % N-dimensional matrix with last dimension equal to Nx
    slice % Integer from 1 to Nx
    sd % Surfdata class
    surfdata_fn
    surf_idx % Active surface
    bounds_relative
    
    % Slice GUI handles
    h_fig
    h_axes
    h_image
    x, y % Last click position
    
    % Control GUI handles
    h_control_fig
    h_control_axes
    h_control_image
    h_control_plot
    h_control_surf
    h_control_is_child % logical (true means slice_browser created control)
    control_x, control_y % Last click position
    
    % Surface GUI handles
    h_surf_fig
    h_surf_axes
    h_surf_image
    h_surf_plot
    surf_x, surf_y % Last click position
    
    gui
    
    % slice_tool: .list, .timer, .cluster, .cmds
    slice_tool
    
    % Function handle hooks for customizing clip_matrix
    fh_button_up
    fh_key_press
    fh_button_motion
    
    % zoom_mode: boolean, x,y: used by zoom mode
    zoom_mode
    shift_pressed
    ctrl_pressed
    plot_visibility
    undo_stack
    save_callback
    
    % DOA/beamforming method
    doa_method_flag
  end
  
  events
    SliceChange
  end
  
  methods
    %% constructor/slice_browser:
    function obj = slice_browser(mdata,h_control_image,param)
      if ~exist('param','var')
        param = [];
      end
      if ~isfield(param,'fh_button_up')
        param.fh_button_up = [];
      end
      if ~isfield(param,'fh_key_press')
        param.fh_key_press = [];
      end
      if ~isfield(param,'fh_button_motion')
        param.fh_button_motion = [];
      end
      if ~isfield(param,'fh_key_press')
        param.fh_key_press = [];
      end
      if ~isfield(param,'bounds_relative')
        param.bounds_relative = [0 0 0 0];
      end
      if ~isfield(param,'doa_method_flag')
        param.doa_method_flag = false;
      end
      obj.doa_method_flag = param.doa_method_flag;
      if param.doa_method_flag && ~isfield(param,'doa_limits')
        param.doa_limits = [-90 90];
      end
      if param.doa_method_flag && ~isfield(param,'nadir_doa_lim')
        param.nadir_doa_lim = [-2 2];
      end
      undo_param.id = [];
      obj.undo_stack = imb.undo_stack(undo_param);
      obj.data = 10*log10(mdata.Tomo.img);
      obj.slice = 1;
      obj.plot_visibility = true;
      obj.bounds_relative = param.bounds_relative;
      
      obj.slice_tool.list = [];
      
      obj.slice_tool.timer = timer;
      obj.slice_tool.timer.StartDelay = 2;
      obj.slice_tool.timer.Period = 2;
      obj.slice_tool.timer.TimerFcn = @obj.timer_callback;
      obj.slice_tool.timer.ExecutionMode = 'fixedSpacing';
      %start(obj.slice_tool.timer)
      
      % Load surface data
      obj.sd = tomo.surfdata(param.surfdata_fn);
      obj.sd.theta = mdata.Tomo.theta(:,1);
      obj.sd.time = mdata.Time;
      obj.sd.units('bins');
      obj.surfdata_fn = param.surfdata_fn;
      
      if ~isempty(h_control_image)
        obj.h_control_is_child = false;
        obj.h_control_image = h_control_image;
        obj.h_control_axes = get(obj.h_control_image,'Parent');
        obj.h_control_fig = get(obj.h_control_axes,'Parent');
      else
        obj.h_control_is_child = true;
        obj.h_control_fig = figure;
        obj.h_control_axes = axes('Parent',obj.h_control_fig,'YDir','reverse');
        hold(obj.h_control_axes,'on');
        if ~param.doa_method_flag
          obj.h_control_image = imagesc(squeeze(obj.data(:,floor(size(obj.data,2)/2)+1,:)),'Parent',obj.h_control_axes);
          colormap(obj.h_control_axes,parula(256));
          xlabel(obj.h_control_axes,'Along-track range line');
          ylabel(obj.h_control_axes,'Range bin');
        else
          % Find nadir DOAs
          nadir_theta_val = squeeze(nanmin(abs(obj.data - 0),[],2)); % Nx*Nt matrix
          nadir_theta_val(nadir_theta_val<param.nadir_doa_lim(1) | nadir_theta_val>param.nadir_doa_lim(2)) = NaN;
          [nadir_r nadir_c] = find(~isnan(nadir_theta_val));
          for theta_idx = 1:length(nadir_r)
            obj.h_control_image = scatter(nadir_c(theta_idx),nadir_r(theta_idx),25,nadir_theta_val(nadir_r(theta_idx),nadir_c(theta_idx)),'filled');%,'Parent',obj.h_control_axes);
          end
          obj.h_control_axes.XLim = [1 size(obj.data,3)];
          obj.h_control_axes.YLim = [1 size(obj.data,1)];
          xlabel(obj.h_control_axes,'Along-track range line');
          ylabel(obj.h_control_axes,'Range bin');
          grid(obj.h_control_axes,'on');
        end
      end
      obj.fh_button_up = param.fh_button_up;
      obj.fh_key_press = param.fh_key_press;
      obj.fh_button_motion = param.fh_button_motion;
      
      obj.h_surf_fig = figure;
      pos = get(obj.h_fig,'Position');
      pos(3) = 750;
      pos(4) = 500;
      set(obj.h_fig,'Position',pos);
      
      obj.h_surf_axes = axes('Parent',obj.h_surf_fig,'YDir','reverse');
      obj.h_surf_image = imagesc(NaN*zeros(size(obj.data,2),size(obj.data,3)),'parent',obj.h_surf_axes);  
      colormap(obj.h_surf_axes, parula(256));
      xlabel(obj.h_surf_axes,'Along-track range line');
      ylabel(obj.h_surf_axes,'Cross-track');
      hold(obj.h_surf_axes,'on');
      obj.h_surf_plot = plot(NaN,NaN,'parent',obj.h_surf_axes,'Marker','x','Color','black','LineWidth',2,'MarkerSize',10);
      
      obj.h_fig = figure;
      
      pos = get(obj.h_fig,'Position');
      pos(3) = 750;
      pos(4) = 500;
      set(obj.h_fig,'Position',pos);
      
      obj.gui.left_panel = uipanel('parent',obj.h_fig);
      obj.gui.right_panel = uipanel('parent',obj.h_fig);
      obj.h_axes = axes('Parent',obj.gui.right_panel,'YDir','reverse');
      hold(obj.h_axes,'on');
      if ~param.doa_method_flag
        colormap(obj.h_axes, parula(256));
        xlabel(obj.h_axes,'Cross-track');
        ylabel(obj.h_axes,'Range bin');
      else
        obj.h_axes.XLim = [param.doa_limits(1) param.doa_limits(2)];
        obj.h_axes.YLim = [1 size(obj.data,1)];
        xlabel(obj.h_axes,'Elevation angle (deg)');
        ylabel(obj.h_axes,'Range bin');
        grid(obj.h_axes,'on');
      end
      
      if ~param.doa_method_flag
        obj.h_image = imagesc(obj.data(:,:,obj.slice),'parent',obj.h_axes);
        for surf_idx = 1:numel(obj.sd.surf)
          obj.sd.surf(surf_idx).h_plot ...
            = plot(obj.sd.surf(surf_idx).x(:,obj.slice), ...
            obj.sd.surf(surf_idx).y(:,obj.slice), ...
            'parent',obj.h_axes,'color','black', ...
            obj.sd.surf(surf_idx).plot_name_values{:});
        end
      else
        % Use good data points to interpolate over bad data points
        for theta_idx = 1:size(obj.data,2)
          good_theta_idx = find(~isnan(obj.data(:,theta_idx,obj.slice)));
          if ~isempty(good_theta_idx)
            obj.data(good_theta_idx(1):good_theta_idx(end),theta_idx,obj.slice) = interp1(good_theta_idx,obj.data(good_theta_idx,theta_idx,obj.slice),[good_theta_idx(1):good_theta_idx(end)].');
          end
        end
        
        for surf_idx = 1:numel(obj.sd.surf)
          obj.sd.surf(surf_idx).h_plot ...
            = plot(obj.sd.surf(surf_idx).x(:,obj.slice), ...
            obj.sd.surf(surf_idx).y(:,obj.slice), ...
            'parent',obj.h_axes,'color','black', ...
            obj.sd.surf(surf_idx).plot_name_values{:});
        end
        legend('Ice-top','Ice-bottom')
      end
      
      addlistener(obj.undo_stack,'synchronize_event',@obj.undo_sync);
      
      obj.gui.h_select_plot = plot(NaN,NaN,'m.');
      
      hold(obj.h_control_axes,'on');
      obj.h_control_plot = plot(NaN,NaN,'parent',obj.h_control_axes,'Marker','x','Color','black','LineWidth',2,'MarkerSize',10);
      obj.h_control_surf = plot(NaN,NaN,'parent',obj.h_control_axes,'Marker','.','Color','red');
      
      % Set up figure callbacks and zoom
      if ~obj.doa_method_flag
        zoom_figure_setup(obj.h_fig,'slice');
        obj.zoom_mode = true;
        set(obj.h_fig,'pointer','custom');
      
      set(obj.h_fig,'WindowButtonUpFcn',@obj.button_up);
      set(obj.h_fig,'WindowButtonDownFcn',@obj.button_down);
      end
      set(obj.h_fig,'WindowButtonMotionFcn',@obj.button_motion);
      set(obj.h_fig,'WindowScrollWheelFcn',@obj.button_scroll);
      set(obj.h_fig,'WindowKeyPressFcn',@obj.key_press);
      set(obj.h_fig,'WindowKeyReleaseFcn',@obj.key_release);
      set(obj.h_fig,'CloseRequestFcn',@obj.close_win);
      
      if ~obj.doa_method_flag
        zoom_figure_setup(obj.h_surf_fig,'surface');
        set(obj.h_surf_fig,'pointer','custom');
      end
      set(obj.h_surf_fig,'WindowButtonUpFcn',@obj.surf_button_up);
      set(obj.h_surf_fig,'WindowButtonDownFcn',@obj.surf_button_down);
      %       set(obj.h_surf_fig,'WindowButtonMotionFcn',@obj.button_motion);
      set(obj.h_surf_fig,'WindowScrollWheelFcn',@obj.surf_button_scroll);
      set(obj.h_surf_fig,'WindowKeyPressFcn',@obj.key_press);
      set(obj.h_surf_fig,'WindowKeyReleaseFcn',@obj.key_release);
      set(obj.h_surf_fig,'CloseRequestFcn',[]);
      
      if obj.h_control_is_child
        if ~obj.doa_method_flag
          zoom_figure_setup(obj.h_control_fig,'echogram');
          set(obj.h_control_fig,'pointer','custom');
        end
        set(obj.h_control_fig,'WindowButtonUpFcn',@obj.control_button_up);
        set(obj.h_control_fig,'WindowButtonDownFcn',@obj.control_button_down);
        %         set(obj.h_control_fig,'WindowButtonMotionFcn',@obj.button_motion);
        set(obj.h_control_fig,'WindowScrollWheelFcn',@obj.control_button_scroll);
        set(obj.h_control_fig,'WindowKeyPressFcn',@obj.key_press);
        set(obj.h_control_fig,'WindowKeyReleaseFcn',@obj.key_release);
        set(obj.h_control_fig,'CloseRequestFcn',[]);
      end
      
      obj.select_mask = logical(zeros(size(obj.data,2),1));
      
      obj.gui.table.ui = obj.h_fig;
      obj.gui.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
      obj.gui.table.height_margin = NaN*zeros(30,30);
      obj.gui.table.false_width = NaN*zeros(30,30);
      obj.gui.table.false_height = NaN*zeros(30,30);
      obj.gui.table.offset = [0 0];
      row = 1;
      col = 1;
      obj.gui.table.handles{row,col}   = obj.gui.left_panel;
      obj.gui.table.width(row,col)     = 130;
      obj.gui.table.height(row,col)    = inf;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      
      row = 1;
      col = 2;
      obj.gui.table.handles{row,col}   = obj.gui.right_panel;
      obj.gui.table.width(row,col)     = inf;
      obj.gui.table.height(row,col)    = inf;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      
      clear row col
      table_draw(obj.gui.table);
      
      % Set limits to size of data
      if ~param.doa_method_flag
        xlim(obj.h_axes, [1 size(obj.data(:,:,obj.slice),2)]);
        ylim(obj.h_axes, [1 size(obj.data(:,:,obj.slice),1)]);
      else
        xlim(obj.h_axes, [param.doa_limits(1) param.doa_limits(2)]);
        ylim(obj.h_axes, [1 size(obj.data(:,:,obj.slice),1)]);
      end
      
      obj.gui.nextPB = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.nextPB,'style','pushbutton')
      set(obj.gui.nextPB,'string','>')
      set(obj.gui.nextPB,'Callback',@obj.next_button_callback)
      set(obj.gui.nextPB,'TooltipString','Move forward one slice (.)');
      
      obj.gui.prevPB = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.prevPB,'style','pushbutton')
      set(obj.gui.prevPB,'string','<')
      set(obj.gui.prevPB,'Callback',@obj.prev_button_callback)
      set(obj.gui.prevPB,'TooltipString','Move backward one slice (,)');
      
      obj.gui.prev10PB = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.prev10PB,'style','pushbutton')
      set(obj.gui.prev10PB,'string','<<')
      set(obj.gui.prev10PB,'Callback',@obj.prev10_button_callback)
      set(obj.gui.prev10PB,'TooltipString','Move backward five slices (k)');
      
      obj.gui.next10PB = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.next10PB,'style','pushbutton')
      set(obj.gui.next10PB,'string','>>')
      set(obj.gui.next10PB,'Callback',@obj.next10_button_callback)
      set(obj.gui.next10PB,'TooltipString','Move forward five slices (l)');
      if ~obj.doa_method_flag
        obj.gui.savePB = uicontrol('parent',obj.gui.left_panel);
        set(obj.gui.savePB,'style','pushbutton')
        set(obj.gui.savePB,'string','(S)ave')
        set(obj.gui.savePB,'Callback',@obj.save_button_callback)
        set(obj.gui.savePB,'TooltipString','Save surfaces to file (shift-S)');
        
        obj.gui.helpPB = uicontrol('parent',obj.gui.left_panel);
        set(obj.gui.helpPB,'style','pushbutton')
        set(obj.gui.helpPB,'string','Help (F1)')
        set(obj.gui.helpPB,'Callback',@obj.help_button_callback)
        set(obj.gui.helpPB,'TooltipString','Print help to stdout (F1)');
      end
      
        obj.gui.surfaceTXT = uicontrol('Style','text','string','Surface');
        obj.gui.surfaceLB = uicontrol('parent',obj.gui.left_panel);
        set(obj.gui.surfaceLB,'style','listbox')
        set(obj.gui.surfaceLB,'string',obj.sd.get_names());
        set(obj.gui.surfaceLB,'Callback',@obj.surfaceLB_callback)
        set(obj.gui.surfaceLB,'TooltipString','Select active surface (#)');
        obj.gui.surfaceCM = uicontextmenu('Parent',obj.h_fig);
        % Define the context menu items and install their callbacks
        obj.gui.surfaceCM_visible = uimenu(obj.gui.surfaceCM, 'Label', 'Toggle Visible', 'Callback', @obj.surfaceLB_visibility_toggle);
        set(obj.gui.surfaceLB,'UIContextMenu',obj.gui.surfaceCM);
        
        if ~obj.doa_method_flag
          % 'Apply' and 'Options' buttons are not supported for 'doa' method
          % at this point.
          obj.gui.applyPB= uicontrol('parent',obj.gui.left_panel);
          set(obj.gui.applyPB,'style','pushbutton')
          set(obj.gui.applyPB,'string','Apply')
          set(obj.gui.applyPB,'Callback',@obj.applyPB_callback)
          set(obj.gui.applyPB,'TooltipString','Apply selected tool');
          
          obj.gui.optionsPB = uicontrol('parent',obj.gui.left_panel);
          set(obj.gui.optionsPB,'style','pushbutton');
          set(obj.gui.optionsPB,'string','Options');
          set(obj.gui.optionsPB,'Callback',@obj.optionsPB_callback);
          set(obj.gui.optionsPB,'TooltipString','Open tool options window');
        end
      obj.gui.toolPM = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.toolPM,'style','popup');
      set(obj.gui.toolPM,'string',{''});
      set(obj.gui.toolPM,'TooltipString','Select active tool');
      
      %% Create GUI Table
      obj.gui.left_table.ui =  obj.gui.left_panel;
      obj.gui.left_table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
      obj.gui.left_table.height_margin = NaN*zeros(30,30);
      obj.gui.left_table.false_width = NaN*zeros(30,30);
      obj.gui.left_table.false_height = NaN*zeros(30,30);
      obj.gui.left_table.offset = [0 0];
      
      row = 0;
      col = 0;
      
      row = row + 1;
      col = col + 1;
      obj.gui.left_table.handles{row,col}   = obj.gui.prev10PB;
      obj.gui.left_table.width(row,col)     = inf;
      obj.gui.left_table.height(row,col)    = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      col = col + 1;
      obj.gui.left_table.handles{row,col}   = obj.gui.prevPB;
      obj.gui.left_table.width(row,col)     = inf;
      obj.gui.left_table.height(row,col)    = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      col = col + 1;
      obj.gui.left_table.handles{row,col}   = obj.gui.nextPB;
      obj.gui.left_table.width(row,col)     = inf;
      obj.gui.left_table.height(row,col)    = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      col = col + 1;
      obj.gui.left_table.handles{row,col}   = obj.gui.next10PB;
      obj.gui.left_table.width(row,col)     = inf;
      obj.gui.left_table.height(row,col)    = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      col = 0;
      row = row + 1;
      col = col + 1;
      if ~obj.doa_method_flag
        obj.gui.left_table.handles{row,col}   = obj.gui.savePB;
      end
      obj.gui.left_table.width(row,col)     = inf;
      obj.gui.left_table.height(row,col)    = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      col = col + 1;
      if ~obj.doa_method_flag
        obj.gui.left_table.handles{row,col}   = obj.gui.helpPB;
      end
      obj.gui.left_table.width(row,col)     = inf;
      obj.gui.left_table.height(row,col)    = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      col = 0;
      row = row + 1;
      col = col + 1;
      obj.gui.left_table.handles{row,col}   = obj.gui.surfaceTXT;
      obj.gui.left_table.width(row,col)     = inf;
      obj.gui.left_table.height(row,col)    = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      col = 0;
      row = row + 1;
      col = col + 1;
      obj.gui.left_table.handles{row,col}   = obj.gui.surfaceLB;
      obj.gui.left_table.width(row,col)     = inf;
      obj.gui.left_table.height(row,col)    = inf;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      col = 0;
      row = row + 1;
      col = col + 1;
      obj.gui.left_table.handles{row,col}   = obj.gui.toolPM;
      obj.gui.left_table.width(row,col)     = inf;
      obj.gui.left_table.height(row,col)    = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      if ~obj.doa_method_flag
        % 'Apply' and 'Options' are not supported for 'doa' method at this
        % point.
        col = 0;
        row = row + 1;
        col = col + 1;
        obj.gui.left_table.handles{row,col}   = obj.gui.applyPB;
        obj.gui.left_table.width(row,col)     = inf;
        obj.gui.left_table.height(row,col)    = 20;
        obj.gui.left_table.width_margin(row,col) = 1;
        obj.gui.left_table.height_margin(row,col) = 1;
        
        col = col + 1;
        obj.gui.left_table.handles{row,col}   = obj.gui.optionsPB;
        obj.gui.left_table.width(row,col)     = inf;
        obj.gui.left_table.height(row,col)    = 20;
        obj.gui.left_table.width_margin(row,col) = 1;
        obj.gui.left_table.height_margin(row,col) = 1;
      end
      clear row col
      table_draw(obj.gui.left_table);
      
      obj.update_slice(param);
    end
    
    %% destructor/delete
    function delete(obj)
      try; delete(obj.h_fig); end;
      try; delete(obj.h_surf_fig); end;
      for tool_idx = 1:length(obj.slice_tool.list)
        try; delete(obj.slice_tool.list{tool_idx}); end;
      end
      try; delete(obj.slice_tool.timer); end;
      
      % Control figure destructor
      try; set(obj.h_control_fig, 'WindowButtonUpFcn', []); end;
      if obj.h_control_is_child
        try; delete(obj.h_control_fig); end;
      end
      try; delete(obj.h_control_plot); end;
      try; delete(obj.h_control_surf); end;
    end
    
    %% close_win
    function close_win(obj,h_obj,event)
      try
        delete(obj);
      end
    end
    
    %% next_button_callback
    function next_button_callback(obj,source,callbackdata)
      obj.change_slice(obj.slice + 1,false);
    end
    
    %% prev_button_callback
    function prev_button_callback(obj,source,callbackdata)
      obj.change_slice(obj.slice - 1,false);
    end
    
    %% help_button_callback
    function help_button_callback(obj,source,callbackdata)
      obj.help_menu()
    end
    
    %% save_button_callback
    function save_button_callback(obj,source,callbackdata)
      obj.save();
    end
    
    %% next10_button_callback
    function next10_button_callback(obj,source,callbackdata)
      obj.change_slice(obj.slice + 5,false);
    end
    
    %% prev10_button_callback
    function prev10_button_callback(obj,source,callbackdata)
      obj.change_slice(obj.slice - 5,false);
    end
    
    %% undo_sync
    function undo_sync(obj,source,callbackdata)
      [cmds_list,cmds_direction] =  obj.undo_stack.get_synchronize_cmds();
      new_slice = [];
      if strcmp(cmds_direction,'redo')
        for cmd_idx = 1:length(cmds_list)
          for subcmd_idx = 1:length(cmds_list{cmd_idx})
            if strcmp(cmds_list{cmd_idx}{subcmd_idx}.type,'standard')
              surf_idx = cmds_list{cmd_idx}{subcmd_idx}.redo.surf;
              obj.sd.surf(surf_idx).y(round(cmds_list{cmd_idx}{subcmd_idx}.redo.x), ...
                cmds_list{cmd_idx}{subcmd_idx}.redo.slice) ...
                = cmds_list{cmd_idx}{subcmd_idx}.redo.y;
              new_slice = cmds_list{cmd_idx}{subcmd_idx}.redo.slice;
            elseif strcmp(cmds_list{cmd_idx}{subcmd_idx}.type,'slice_dummy')
              if ~any(obj.slice==cmds_list{cmd_idx}{subcmd_idx}.redo.slice)
                new_slice = cmds_list{cmd_idx}{subcmd_idx}.redo.slice(1);
                fprintf('Redo slices %d-%d\n', min(cmds_list{cmd_idx}{subcmd_idx}.redo.slice), max(cmds_list{cmd_idx}{subcmd_idx}.redo.slice));
              else
                new_slice = obj.slice;
              end
            end
          end
        end
      else
        for cmd_idx = 1:length(cmds_list)
          for subcmd_idx = 1:length(cmds_list{cmd_idx})
            if strcmp(cmds_list{cmd_idx}{subcmd_idx}.type,'standard')
              surf_idx = cmds_list{cmd_idx}{subcmd_idx}.undo.surf;
              obj.sd.surf(surf_idx).y(round(cmds_list{cmd_idx}{subcmd_idx}.undo.x), ...
                cmds_list{cmd_idx}{subcmd_idx}.undo.slice) ...
                = cmds_list{cmd_idx}{subcmd_idx}.undo.y;
              new_slice = cmds_list{cmd_idx}{subcmd_idx}.undo.slice;
            elseif strcmp(cmds_list{cmd_idx}{subcmd_idx}.type,'slice_dummy')
              if ~any(obj.slice==cmds_list{cmd_idx}{subcmd_idx}.redo.slice)
                new_slice = cmds_list{cmd_idx}{subcmd_idx}.redo.slice(1);
                fprintf('Undo slices %d-%d\n', min(cmds_list{cmd_idx}{subcmd_idx}.redo.slice), max(cmds_list{cmd_idx}{subcmd_idx}.redo.slice));
              else
                new_slice = obj.slice;
              end
            end
          end
        end
      end
      obj.change_slice(new_slice,true);
      
    end
    
    %% button_down
    function button_down(obj,h_obj,event)
      [obj.x,obj.y,but] = get_mouse_info(obj.h_fig,obj.h_axes);
      %fprintf('Button Down: x = %.3f, y = %.3f, but = %d\n', obj.x, obj.y, but); % DEBUG ONLY
      rbbox;
    end
    
    function control_button_down(obj,h_obj,event)
      [obj.control_x,obj.control_y,but] = get_mouse_info(obj.h_control_fig,obj.h_control_axes);
      %fprintf('Button Down: x = %.3f, y = %.3f, but = %d\n', obj.x, obj.y, but); % DEBUG ONLY
      rbbox;
    end
    
    function surf_button_down(obj,h_obj,event)
      [obj.surf_x,obj.surf_y,but] = get_mouse_info(obj.h_surf_fig,obj.h_surf_axes);
      %fprintf('Button Down: x = %.3f, y = %.3f, but = %d\n', obj.x, obj.y, but); % DEBUG ONLY
      rbbox;
    end
    
    %% button_up
    function button_up(obj,h_obj,event)
      % Run user defined button up callback
      if ~isempty(obj.fh_button_up)
        status = obj.fh_button_up(obj,h_obj,event);
        if status == 0
          return;
        end
      end
      
      % Get x,y position of user button release
      [x,y,but] = get_mouse_info(obj.h_fig,obj.h_axes);
      %fprintf('Button Up: x = %.3f, y = %.3f, but = %d\n', x, y, but); % DEBUG ONLY
      
      set(obj.h_fig,'Units','normalized');
      mouse_pos = get(obj.h_fig,'CurrentPoint');
      set(obj.gui.right_panel,'Units','normalized');
      uipanel_pos = get(obj.gui.right_panel,'Position');
      if mouse_pos(1) < uipanel_pos(1)
        return;
      end
      
      surf_idx = get(obj.gui.surfaceLB,'value');
      
      if obj.zoom_mode
        %% Zoom
        zoom_button_up(x,y,but,struct('x',obj.x,'y',obj.y, ...
          'h_axes',obj.h_axes,'xlims',[1 size(obj.data,2)],'ylims',[1 size(obj.data,1)]));
      else
        if but == 2 || but == 3
          %% Selection
          if obj.x == x
            if x > 1 && x < size(obj.data,2)
              obj.select_mask(round(x)) = ~obj.select_mask(round(x));
              obj.select_mask([1:obj.bounds_relative(1),end-obj.bounds_relative(2)+1:end]) = false;
            else
              obj.select_mask(:) = false;
            end
          else
            if ~obj.shift_pressed
              obj.select_mask(:) = false;
              obj.update_slice;
            end
            
            if ~isempty(regexp(obj.sd.surf(surf_idx).name, 'mask'))
              surf_y = obj.sd.surf(obj.sd.surf(surf_idx).top).y(:,obj.slice);
            elseif ~isempty(regexp(obj.sd.surf(surf_idx).name, 'quality'))
              surf_y = obj.sd.surf(obj.sd.surf(surf_idx).active).y(:,obj.slice);
            else
              surf_y = obj.sd.surf(surf_idx).y(:,obj.slice);
            end
            
            obj.select_mask = obj.select_mask | (obj.sd.surf(surf_idx).x(:,obj.slice) >= min(x,obj.x) ...
              & obj.sd.surf(surf_idx).x(:,obj.slice) <= max(x,obj.x) ...
              & surf_y >= min(y,obj.y) ...
              & surf_y <= max(y,obj.y));
            obj.select_mask([1:obj.bounds_relative(1),end-obj.bounds_relative(2)+1:end]) = false;
          end
        else
          %% Change point
          xlims = xlim(obj.h_axes);
          ylims = ylim(obj.h_axes);
          if x >= xlims(1) && x <= xlims(2) && y >= ylims(1) && y <= ylims(2)
            surf_idx = get(obj.gui.surfaceLB,'value');
            cmd = [];
            cmd{1}.undo.slice = obj.slice;
            cmd{1}.redo.slice = obj.slice;
            cmd{1}.undo.surf = obj.sd.surf(surf_idx).gt;
            cmd{1}.redo.surf = obj.sd.surf(surf_idx).gt;
            cmd{1}.undo.x = round(x);
            cmd{1}.undo.y = obj.sd.surf(obj.sd.surf(surf_idx).gt).y(round(x),obj.slice);
            cmd{1}.redo.x = round(x);
            cmd{1}.redo.y = y;
            cmd{1}.type = 'standard';
            obj.push(cmd);
          end
        end
        obj.update_slice();
      end
    end
    
    function control_button_up(obj,h_obj,event)
      [x,y,but] = get_mouse_info(obj.h_control_fig,obj.h_control_axes);
      if obj.zoom_mode
        zoom_button_up(x,y,but,struct('x',obj.control_x,'y',obj.control_y, ...
          'h_axes',obj.h_control_axes,'xlims',[1 size(obj.data,3)],'ylims',[1 size(obj.data,1)]));
      else
        xlims = xlim(obj.h_control_axes);
        ylims = ylim(obj.h_control_axes);
        if x >= xlims(1) && x <= xlims(end) && y >= ylims(1) && y <= ylims(end)
          obj.change_slice(round(x),false);
        end
      end
    end
    
    function surf_button_up(obj,h_obj,event)
      [x,y,but] = get_mouse_info(obj.h_surf_fig,obj.h_surf_axes);
      
      if obj.zoom_mode
        zoom_button_up(x,y,but,struct('x',obj.surf_x,'y',obj.surf_y, ...
          'h_axes',obj.h_surf_axes,'xlims',[1 size(obj.data,3)],'ylims',[1 size(obj.data,2)],'axes','x'));
      else
        if obj.surf_x == x
          xlims = xlim(obj.h_surf_axes);
          ylims = ylim(obj.h_surf_axes);
          if x >= xlims(1) && x <= xlims(end) && y >= ylims(1) && y <= ylims(end)
            obj.change_slice(round(x),false);
          end
        else
          ylims = sort([y obj.surf_y]);
          obj.select_mask(:) = false;
          y_idxs = round(ylims(1)):round(ylims(2));
          y_idxs = y_idxs(y_idxs>=1 & y_idxs<=size(obj.data,2));
          obj.select_mask(y_idxs) = true;
          obj.select_mask([1:obj.bounds_relative(1),end-obj.bounds_relative(2)+1:end]) = false;
          if but ~= 1
            for tool_idx = 1:length(obj.slice_tool.list)
              tool_name_list{tool_idx} = obj.slice_tool.list{tool_idx}.tool_name;
            end
            xlims = sort([x obj.surf_x]);
            slices = round(xlims(1)):round(xlims(2));
            slices = slices(slices>=1 & slices<=size(obj.data,3));
            title(obj.h_surf_axes,sprintf('Slices %d-%d, DOAs %d-%d\n', slices(1), slices(end), y_idxs(1), y_idxs(end)));
            [tool_idx,ok] = listdlg('PromptString','Choose slicetool:',...
              'SelectionMode','single',...
              'ListString',tool_name_list);
            if ok == 1
              obj.surf_idx = get(obj.gui.surfaceLB,'Value');
              cmd = obj.slice_tool.list{tool_idx}.apply_PB_callback(obj,slices);
              if ~isempty(cmd)
                obj.undo_stack.push(cmd);
              end
            else
              
            end
          end
          obj.update_slice();
        end
      end
    end
    
    
    %% button_motion
    function button_motion(obj,h_obj,event)
      % Run user defined button up callback
      if ~isempty(obj.fh_button_motion)
        status = obj.fh_button_motion(obj,h_obj,event);
        if status == 0
          return;
        end
      end
      
      set(obj.h_fig,'Units','normalized');
      mouse_pos = get(obj.h_fig,'CurrentPoint');
      set(obj.gui.right_panel,'Units','normalized');
      uipanel_pos = get(obj.gui.right_panel,'Position');
      if mouse_pos(1) < uipanel_pos(1)
        set(obj.h_fig,'Pointer','Arrow');
        return;
      elseif obj.zoom_mode
        set(obj.h_fig,'Pointer','custom');
      end
      
      [x,y,but] = get_mouse_info(obj.h_fig,obj.h_axes);
      set(obj.h_control_plot,'XData',obj.slice,'YData',y);
      set(obj.h_surf_plot,'XData',obj.slice,'YData',x);
    end
    
    %% button_scroll
    function button_scroll(obj,h_obj,event)
      zoom_button_scroll(event,struct('h_fig',obj.h_fig, ...
        'h_axes',obj.h_axes,'xlims',[1 size(obj.data,2)],'ylims',[1 size(obj.data,1)]));
    end
    
    function control_button_scroll(obj,h_obj,event)
      zoom_button_scroll(event,struct('h_fig',obj.h_control_fig, ...
        'h_axes',obj.h_control_axes,'xlims',[1 size(obj.data,3)],'ylims',[1 size(obj.data,1)]));
    end
    
    function surf_button_scroll(obj,h_obj,event)
      zoom_button_scroll(event,struct('h_fig',obj.h_surf_fig, ...
        'h_axes',obj.h_surf_axes,'xlims',[1 size(obj.data,3)],'ylims',[1 size(obj.data,2)],'axes','x'));
    end
    
    %% key_press
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
      
      if ~isempty(obj.fh_key_press)
        status = obj.fh_key_press(src,event);
        if status == 0
          return;
        end
      end
      
      % Check to see if this is a slicetool shortcut
      for tool_idx = 1:length(obj.slice_tool.list)
        if ~isempty(obj.slice_tool.list{tool_idx}.tool_shortcut) ...
            && strcmpi(obj.slice_tool.list{tool_idx}.tool_shortcut, event.Key) ...
            && any(obj.slice_tool.list{tool_idx}.ctrl_pressed == obj.ctrl_pressed) ...
            && any(obj.slice_tool.list{tool_idx}.shift_pressed == obj.shift_pressed)
          obj.surf_idx = get(obj.gui.surfaceLB,'Value');
          cmd = obj.slice_tool.list{tool_idx}.apply_PB_callback(obj);
          if ~isempty(cmd)
            obj.undo_stack.push(cmd);
          end
          return;
        end
      end
      
      % Check to make sure that a key was pressed and not
      % just a modifier (e.g. shift, ctrl, alt)
      if ~isempty(event.Key)
        
        if length(event.Key) == 1 && event.Key >= '0' && event.Key <= '9'
          set(obj.gui.surfaceLB,'value',event.Key-48)
          obj.update_slice();
          return;
        end
        
        % see event.Modifier for modifiers
        switch event.Key
          
          case 'f1'
            obj.help_menu()
            
          case 'z'
            if obj.ctrl_pressed
              %% zoom reset
              if src==obj.h_fig
                axis(obj.h_axes,'tight');
              elseif src==obj.h_control_fig
                axis(obj.h_control_axes,'tight');
              elseif src==obj.h_surf_fig
                axis(obj.h_surf_axes,'tight');
              end
              
            else
              % toggle zoom mode
              obj.zoom_mode = ~obj.zoom_mode;
              if obj.zoom_mode
                set(obj.h_fig,'pointer','custom');
                if obj.h_control_is_child
                  set(obj.h_control_fig,'pointer','custom');
                end
                set(obj.h_surf_fig,'pointer','custom');
              else
                set(obj.h_fig,'pointer','arrow');
                if obj.h_control_is_child
                  set(obj.h_control_fig,'pointer','arrow');
                end
                set(obj.h_surf_fig,'pointer','arrow');
              end
            end
            
          case {'downarrow','uparrow','rightarrow','leftarrow'}
            % Arrows: pan axes
            if src==obj.h_fig
              zoom_arrow(event,struct('h_axes',obj.h_axes, ...
                'xlims',[1 size(obj.data,2)],'ylims',[1 size(obj.data,1)]));
            elseif src==obj.h_control_fig
              zoom_arrow(event,struct('h_axes',obj.h_control_axes, ...
                'xlims',[1 size(obj.data,3)],'ylims',[1 size(obj.data,1)]));
            elseif src==obj.h_surf_fig
              zoom_arrow(event,struct('h_axes',obj.h_surf_axes, ...
                'xlims',[1 size(obj.data,3)],'ylims',[1 size(obj.data,2)]));
            end
            
          case 'period'
            obj.change_slice(obj.slice + 1,false);
          case 'comma'
            obj.change_slice(obj.slice - 1,false);
          case 'k'
            obj.change_slice(obj.slice - 5,false);
          case 'l'
            obj.change_slice(obj.slice + 5,false);
            
          case 'delete'
            surf_idx = get(obj.gui.surfaceLB,'Value');
            cmd = [];
            cmd{1}.redo.x = find(obj.select_mask);
            if ~isempty(regexp(obj.sd.surf(surf_idx).name, 'mask|quality'))
              if any(obj.sd.surf(surf_idx).y(obj.select_mask,obj.slice))
                cmd{1}.redo.y = false * ones(size(cmd{1}.redo.x));
              else
                cmd{1}.redo.y = true * ones(size(cmd{1}.redo.x));
              end
            else
              surf_idx = obj.sd.surf(surf_idx).gt;
              cmd{1}.redo.y = NaN * ones(size(cmd{1}.redo.x));
            end
            cmd{1}.undo.slice = obj.slice;
            cmd{1}.redo.slice = obj.slice;
            cmd{1}.undo.surf = surf_idx;
            cmd{1}.redo.surf = surf_idx;
            
            cmd{1}.undo.x = find(obj.select_mask);
            cmd{1}.undo.y = obj.sd.surf(surf_idx).y(obj.select_mask,obj.slice);
            
            cmd{1}.type = 'standard';
            obj.push(cmd);
            
            obj.update_slice();
            
          case 'space'
            if obj.plot_visibility == true;
              obj.plot_visibility = false;
            else
              obj.plot_visibility = true;
            end
            obj.update_slice();
            
          case 'g'
            prompt = {'Enter slice number:'};
            dlg_title = 'Go to slice';
            num_lines = 1;
            def = {sprintf('%d',obj.slice)};
            answer = inputdlg(prompt,dlg_title,num_lines,def);
            try
              obj.change_slice(str2double(answer),false)
            end
            
          case 'r'
            obj.undo_stack.redo();
            
          case 'u'
            obj.undo_stack.pop();
            
          otherwise
            
        end
        
      end
    end
    
    %% key_release
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
    
    %% Change slice
    function change_slice(obj, new_slice, force_update)
      if new_slice <= 0
        new_slice = 1;
      end
      if new_slice > size(obj.data,3)
        new_slice = size(obj.data,3);
      end
      if new_slice ~= obj.slice
        obj.slice = new_slice;
        obj.update_slice();
        notify(obj,'SliceChange');
        set(obj.h_control_plot,'XData',obj.slice);
        set(obj.h_surf_plot,'XData',obj.slice);
        
        xlims = xlim(obj.h_control_axes);
        ylims = ylim(obj.h_control_axes);
        if xlims(2) < obj.slice
          new_xlims = xlims + (obj.slice - 0.8*diff(xlims) - xlims(1));
        elseif xlims(1) > obj.slice
          new_xlims = xlims - (xlims(1) - (obj.slice - 0.2*diff(xlims)));
        else
          new_xlims = [];
        end
        if ~isempty(new_xlims)
          zoom_button_up(new_xlims(1),ylims(1),1,struct('x',new_xlims(2),'y',ylims(2), ...
            'h_axes',obj.h_control_axes,'xlims',[1 size(obj.data,3)],'ylims',[1 size(obj.data,1)]));
        end
        
        xlims = xlim(obj.h_surf_axes);
        ylims = ylim(obj.h_surf_axes);
        if xlims(2) < obj.slice
          new_xlims = xlims + (obj.slice - 0.8*diff(xlims) - xlims(1));
        elseif xlims(1) > obj.slice
          new_xlims = xlims - (xlims(1) - (obj.slice - 0.2*diff(xlims)));
        else
          new_xlims = [];
        end
        if ~isempty(new_xlims)
          zoom_button_up(new_xlims(1),ylims(1),1,struct('x',new_xlims(2),'y',ylims(2), ...
            'h_axes',obj.h_surf_axes,'xlims',[1 size(obj.data,3)],'ylims',[1 size(obj.data,2)]));
        end
        
      elseif force_update
        obj.update_slice();
      end
    end
    
    %% Update slice
    function update_slice(obj,param)
      if ~obj.doa_method_flag
        set(obj.h_image,'CData',obj.data(:,:,obj.slice));
      end
      
      title(sprintf('Slice:%d',obj.slice),'parent',obj.h_axes)
      
      % Update surface plots
      for surf_idx = 1:numel(obj.sd.surf)
        if ~obj.doa_method_flag
          if ~isempty(regexp(obj.sd.surf(surf_idx).name, 'mask'))
            tmp_y = obj.sd.surf(obj.sd.surf(surf_idx).top).y(:,obj.slice);
            tmp_y(~obj.sd.surf(surf_idx).y(:,obj.slice)) = NaN;
          elseif ~isempty(regexp(obj.sd.surf(surf_idx).name, 'quality'))
            tmp_y = obj.sd.surf(obj.sd.surf(surf_idx).active).y(:,obj.slice);
            tmp_y(obj.sd.surf(surf_idx).y(:,obj.slice) == 1) = NaN;
          else
            tmp_y = obj.sd.surf(surf_idx).y(:,obj.slice);
          end
          tmp_y(1:obj.bounds_relative(1),:) = NaN;
          tmp_y(end-obj.bounds_relative(2)+1:end,:) = NaN;
          set(obj.sd.surf(surf_idx).h_plot, ...
            'XData', obj.sd.surf(surf_idx).x(:,obj.slice), ...
            'YData', tmp_y);
        else
          if ~isempty(regexp(obj.sd.surf(surf_idx).name, 'mask'))
            tmp_y = obj.sd.surf(obj.sd.surf(surf_idx).top).y(:,obj.slice);
            tmp_y(~obj.sd.surf(surf_idx).y(:,obj.slice)) = NaN;
          elseif ~isempty(regexp(obj.sd.surf(surf_idx).name, 'quality'))
            tmp_y = obj.sd.surf(obj.sd.surf(surf_idx).active).y(:,obj.slice);
            tmp_y(obj.sd.surf(surf_idx).y(:,obj.slice) == 1) = NaN;
          else
            tmp_y = obj.sd.surf(surf_idx).y(:,obj.slice);
          end
          set(obj.sd.surf(surf_idx).h_plot, ...
            'XData', obj.sd.surf(surf_idx).x(:,obj.slice), ...
            'YData', tmp_y);
        end
      end
      surf_idx = get(obj.gui.surfaceLB,'value');
      surfaceLB_str = get(obj.gui.surfaceLB,'string');
      if ~isempty(get(obj.gui.surfaceLB,'String')) ...
          && (isempty(surf_idx) || surf_idx == 0 || all(surf_idx ~= 1:length(surfaceLB_str)))
        set(obj.gui.surfaceLB,'value',1);
        surf_idx = 1;
      end
      if ~isempty(get(obj.gui.surfaceLB,'String')) && ~isempty(surf_idx)
        % Update surface selection related plots
        surf_idx = get(obj.gui.surfaceLB,'value');
        x_select = obj.sd.surf(surf_idx).x(:,obj.slice);
        if ~isempty(regexp(obj.sd.surf(surf_idx).name, 'mask'))
          y_select = obj.sd.surf(obj.sd.surf(surf_idx).top).y(:,obj.slice);
        elseif ~isempty(regexp(obj.sd.surf(surf_idx).name, 'quality'))
          y_select = obj.sd.surf(obj.sd.surf(surf_idx).active).y(:,obj.slice);
        else
          y_select = obj.sd.surf(surf_idx).y(:,obj.slice);
        end
        set(obj.gui.h_select_plot,'XData',x_select(obj.select_mask), ...
          'YData',y_select(obj.select_mask),'Marker','o','LineWidth',2);
        tmp_y = double(obj.sd.surf(surf_idx).y);
        % Hide data outside bounds
        if ~obj.doa_method_flag
          tmp_y(1:obj.bounds_relative(1),:) = NaN;
          tmp_y(end-obj.bounds_relative(2)+1:end,:) = NaN;
        end
        % Hide bad quality data when active surface shown and quality surface
        % visible
        if ~isempty(obj.sd.surf(surf_idx).quality) ...
            && ~isempty(obj.sd.surf(surf_idx).active) ...
            && obj.sd.surf(surf_idx).active == surf_idx ...
            && obj.sd.surf(obj.sd.surf(surf_idx).quality).visible
          tmp_y(obj.sd.surf(obj.sd.surf(surf_idx).quality).y ~= 1) = NaN;
        end
        set(obj.h_surf_image,'CData',tmp_y);
        
        % Update surface visibility
        if obj.plot_visibility == true
          for surf_idx = 1:numel(obj.sd.surf)
            if obj.sd.surf(surf_idx).visible
              set(obj.sd.surf(surf_idx).h_plot,'visible','on')
            else
              set(obj.sd.surf(surf_idx).h_plot,'visible','off')
            end
          end
          set(obj.gui.h_select_plot,'visible','on')
        else
          for surf_idx = 1:numel(obj.sd.surf)
            set(obj.sd.surf(surf_idx).h_plot,'visible','off')
          end
          set(obj.gui.h_select_plot,'visible','off')
        end
        
        % Update control figure plots
        if obj.doa_method_flag &&(~exist('param','var') || ~isfield(param,'nadir_doa_lim'))
          param.nadir_doa_lim = [-2 2];
        end
        surf_idx = get(obj.gui.surfaceLB,'value');
        if ~isempty(regexp(obj.sd.surf(surf_idx).name, 'quality'))
          active_idx = obj.sd.surf(surf_idx).active;
          if ~isempty(active_idx)
            if ~obj.doa_method_flag
              new_y = obj.sd.surf(active_idx).y(ceil(size(obj.data,2)/2)+1,:);
              new_y(2 == obj.sd.surf(surf_idx).y(ceil(size(obj.data,2)/2)+1,:)) = NaN;
              set(obj.h_control_surf,'XData',1:size(obj.data,3),'YData',new_y);
            else
              % Find nadir DOA. The assumption is that it is the first
              % value in the search limits (nadir_doa_lim)
              for rline_idx = 1:size(obj.data,3)
                nadir_theta_val = squeeze(nanmin(abs(obj.sd.surf(active_idx).y(:,rline_idx) - 0),[],2)); % Nx*Nt matrix
                nadir_theta_val(nadir_theta_val<param.nadir_doa_lim(1) | nadir_theta_val>param.nadir_doa_lim(2)) = NaN;
                nadir_r = find(~isnan(nadir_theta_val));
                if ~isempty(nadir_r)
                  new_y(rline_idx,1) = obj.sd.surf(active_idx).y(nadir_r(1),rline_idx);
                  new_y(2 == obj.sd.surf(surf_idx).y(nadir_r(1)),rline_idx) = NaN;
                else
                  new_y(rline_idx,1) = NaN;
                end
              end
              set(obj.h_control_surf,'XData',1:size(obj.data,3),'YData',new_y);
            end
          end
        elseif ~isempty(regexp(obj.sd.surf(surf_idx).name, 'mask'))
          surf_idx = obj.sd.surf(surf_idx).top;
          if ~isempty(surf_idx)
            if ~obj.doa_method_flag
              new_y = obj.sd.surf(surf_idx).y(ceil(size(obj.data,2)/2)+1,:);
              new_y(~obj.sd.surf(surf_idx).y(ceil(size(obj.data,2)/2)+1,:)) = NaN;
              set(obj.h_control_surf,'XData',1:size(obj.data,3),'YData',new_y);
            else
              % Find nadir DOA. The assumption is that it is the first
              % value in the search limits (nadir_doa_lim)
              for rline_idx = 1:size(obj.data,3)
                nadir_theta_val = squeeze(nanmin(abs(obj.sd.surf(surf_idx).y(:,rline_idx) - 0),[],2)); % Nx*Nt matrix
                nadir_theta_val(nadir_theta_val<param.nadir_doa_lim(1) | nadir_theta_val>param.nadir_doa_lim(2)) = NaN;
                nadir_r = find(~isnan(nadir_theta_val));
                if ~isempty(nadir_r)
                  new_y(rline_idx,1) = obj.sd.surf(surf_idx).y(nadir_r(1),rline_idx);
                  new_y(2 == obj.sd.surf(surf_idx).y(nadir_r(1)),rline_idx) = NaN;
                else
                  new_y(rline_idx,1) = NaN;
                end
              end
              set(obj.h_control_surf,'XData',1:size(obj.data,3),'YData',new_y);
            end
          end
        else
          if ~obj.doa_method_flag
          set(obj.h_control_surf,'XData',1:size(obj.data,3),'YData',obj.sd.surf(surf_idx).y(ceil(size(obj.data,2)/2)+1,:));
          else
            for rline_idx = 1:size(obj.data,3)
              nadir_theta_val = squeeze(nanmin(abs(obj.sd.surf(surf_idx).y(:,rline_idx) - 0),[],2)); % Nx*Nt matrix
              nadir_theta_val(nadir_theta_val<param.nadir_doa_lim(1) | nadir_theta_val>param.nadir_doa_lim(2)) = NaN;
              nadir_r = find(~isnan(nadir_theta_val));
              if ~isempty(nadir_r)
                new_y(rline_idx,1) = obj.sd.surf(surf_idx).y(nadir_r(1),rline_idx);
              else
                new_y(rline_idx,1) = NaN;
              end
            end
            set(obj.h_control_surf,'XData',1:size(obj.data,3),'YData',new_y);
          end
        end
      end
    end
    
    %% surfaceLB_callback Tool
    function surfaceLB_callback(obj,src,event)
      obj.update_slice();
    end
    
    %% surfaceLB_visibility_toggle
    function surfaceLB_visibility_toggle(obj,src,event)
      surf_idx = get(obj.gui.surfaceLB,'value');
      obj.sd.surf(surf_idx).visible = ~obj.sd.surf(surf_idx).visible;
      obj.update_slice();
    end
    
    %% optionsPB_callback Tool
    function optionsPB_callback(obj,src,event)
      tool_idx = get(obj.gui.toolPM,'Value');
      obj.slice_tool.list{tool_idx}.open_win();
    end
    
    %% timer_callback
    function timer_callback(obj,src,event)
      %      fprintf('Timer\n');
    end
    
    %% applyPB_callback Tool
    function applyPB_callback(obj,src,event)
      tool_idx = get(obj.gui.toolPM,'Value');
      obj.surf_idx = get(obj.gui.surfaceLB,'Value');
      cmd = obj.slice_tool.list{tool_idx}.apply_PB_callback(obj);
      if ~isempty(cmd)
        obj.undo_stack.push(cmd);
      end
    end
    
    %% Insert Tool
    function insert_tool(obj, slice_browser_tool)
      % slice_browser_tool
      obj.slice_tool.list{end+1} = slice_browser_tool;
      obj.slice_tool.list{end}.add_listener(obj);
      obj.add_listener(obj.slice_tool.list{end});
      
      toolPM_str = {};
      for idx = 1:length(obj.slice_tool.list)
        toolPM_str = [toolPM_str obj.slice_tool.list{idx}.tool_menu_name];
      end
      
      set(obj.gui.toolPM,'String',toolPM_str);
    end
    
    %% Help
    function help_menu(obj)
      fprintf('\nMouse Operations\n');
      fprintf('======================================================\n');
      
      fprintf('\nZoom Mode\n');
      fprintf('left-click and drag: zoom to selection\n');
      fprintf('left-click: zoom in at point\n');
      fprintf('right-click: zoom out at point\n');
      
      fprintf('\nPointer Mode In "slice" window\n');
      fprintf('left-click: set ground truth point or toggle logical value if mask or quality selected\n');
      fprintf('right-click and drag: select points to operate on (shift-key holds selection)\n');
      
      fprintf('\nPointer Mode In "surface" and "echogram" window\n');
      fprintf('left-click: sets current slice\n');
      fprintf('right-click and drag: select region to operate on (shift-key holds selection)\n');
      
      fprintf('\nPointer Mode In "surface" window\n');
      fprintf('right-click and drag: select region and apply tool\n');
      fprintf('  For the quality tool, holding shift toggles setting true/false\n');
      
      fprintf('\nAll Modes\n');
      fprintf('scroll: zoom in/out at point\n');
      fprintf('delete: deletes selected points (or toggles logical values)\n');
      
      if ~isempty(obj.slice_tool.list)
        fprintf('\nInstalled tools:\n');
        for tool_idx = 1:length(obj.slice_tool.list)
          if ~isempty(obj.slice_tool.list{tool_idx}.help_string)
            fprintf('%s\n',obj.slice_tool.list{tool_idx}.help_string);
          end
        end
      end
      
      fprintf('\nKeyboard Shortcuts\n');
      fprintf('======================================================\n');
      
      fprintf('\nGeneral\n');
      fprintf('F1: print this help menu\n');
      fprintf('space: toggle surface visibility\n');
      fprintf('u: undo the last operation\n');
      fprintf('r: redo an operation that was undone with undo\n');
      fprintf('shift-S: save surfaces to surfdata file\n');
      fprintf('delete: deletes selected points (or sets to false if logical layer)\n');
      
      fprintf('\nMovement\n');
      fprintf('period . : go forward 1 frame\n');
      fprintf('comma , : go forward 1 frame\n');
      fprintf('g: go to a specific frame\n');
      fprintf('k: go back 5 frames\n');
      fprintf('l: go forward 5 frames\n');
      fprintf('arrow-keys: pan left/right/up/down in the image\n');
      fprintf('z: toggle zoom mode on/off\n');
      fprintf('ctrl-z: zoom reset (zooms all the way out to show the full image)\n');
    end
    
    %% getEventData
    function getEventData(obj,src,~)
      cmd = src.cmd;
      obj.undo_stack.push(cmd);
    end
    
    %% add_listener
    function add_listener(obj,src)
      evnts = src.get_events();
      
      if ~isempty(evnts)
        for i = 1:numel(evnts);
          addlistener(evnts.src,evnts.evnts{i},@obj.getEventData);
        end
      end
      
    end
    
    %% push
    function push(obj,cmd)
      obj.surf_idx = get(obj.gui.surfaceLB,'Value');
      for tool_idx = 1:length(obj.slice_tool.list)
        cmd = obj.slice_tool.list{tool_idx}.push_request(cmd);
      end
      obj.undo_stack.push(cmd);
    end
    
    %% save
    function save(obj)
      fprintf('Saving surfData (%s)...\n', datestr(now));
      obj.sd.save_surfdata(obj.surfdata_fn);
      fprintf('  Done\n');
      for tool_idx = 1:length(obj.slice_tool.list)
        if ~isempty(obj.slice_tool.list{tool_idx}.save_callback) && ...
            isa(obj.slice_tool.list{tool_idx}.save_callback,'function_handle')
          obj.slice_tool.list{tool_idx}.save_callback();
        end
      end
      obj.undo_stack.save();
    end
    
  end
  
end

