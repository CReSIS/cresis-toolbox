classdef ice_mask_edit < handle
  
  properties
    
    slice
    ice_mask_fn
    mdata
    proj
    
    h_flight_dem_plot
    h_flight_mask_plot
    h_true_dem_plot
    h_false_dem_plot
    h_true_mask_plot
    h_false_mask_plot
    h_intersect_dem_fig
    h_intersect_mask_fig
    
    flight_line
    mdata_loaded
    intersections
    
    dem
    gray
    mask
    
    intensity_thresh
    intensity_thresh_default
    
    h_dem_fig
    h_dem_axes
    h_dem_plot
    
    h_mask_fig
    h_mask_axes
    h_mask_plot
    
    x
    y
    zoom_mode
    
    dem_x_mesh
    dem_y_mesh
    dem_x
    dem_y
    ice_x_mesh
    ice_y_mesh
    ice_x
    ice_y
    ice_x_idx
    ice_y_idx
    
    R
    X
    Y
    mask_all
    ice_x_all
    ice_y_all
    
    reduce_flag
    run_hold_flag
    hold_flag
    
    gui
    tools
    toggle_val
    active_tool_idx
    actions
    tool_list
    local_undo_stack
    local_undo_flag
    
    cmd
    
    shift_pressed
    ctrl_pressed
    
  end
  
  events
    IceChange
    SliceChange
    Undo
    Redo
  end
  
  methods
    %     function obj = ice_mask_edit(dem_x_mesh,dem_y_mesh,dem,ice_x_mesh,ice_y_mesh,ice_mask)
    function obj = ice_mask_edit(param)
      
      if isfield(param,'DEM')
        obj.dem = param.DEM;
      end
      
      if isfield(param,'R')
        obj.R = param.R;
        obj.dem_x = (param.R(3,1) + param.R(2,1)*(0:size(param.DEM,2)-1));
        obj.dem_y = (param.R(3,2) + param.R(1,2)*(0:size(param.DEM,1)-1));
      end
      
      if isfield(param,'ice_mask')
        obj.mask = param.ice_mask.mask;
        obj.ice_x = param.ice_mask.X;
        obj.ice_y = param.ice_mask.Y;
      end
      
      if isfield(param,'ice_mask_fn');
        obj.ice_mask_fn = param.ice_mask_fn;
      end
      
      if isfield(param,'mdata')
        %         obj.mdata.twtt = param.mdata.twtt;
        %         obj.mdata.theta = param.mdata.theta;
        %         obj.mdata.ice_mask = param.mdata.ice_mask;
        %         obj.mdata.param_array = param.mdata.param_array;
        %         rmfield(param,'mdata');
        obj.mdata = param.mdata;
      end
      
      if isfield(param,'proj')
        obj.proj = param.proj;
      end
      
      undo_param.id = [];
      obj.local_undo_stack = imb.undo_stack(undo_param);
      addlistener(obj.local_undo_stack,'synchronize_event',@obj.undo_sync);
      obj.local_undo_flag = 1;
      
      obj.dem = obj.dem(obj.dem_y>=min(obj.ice_y) & obj.dem_y<=max(obj.ice_y) , ...
        obj.dem_x>=min(obj.ice_x) & obj.dem_x<=max(obj.ice_x),:);
      obj.dem_x = obj.dem_x(obj.dem_x>=min(obj.ice_x) & obj.dem_x<=max(obj.ice_x));
      obj.dem_y = obj.dem_y(obj.dem_y>=min(obj.ice_y) & obj.dem_y<=max(obj.ice_y));
      
      obj.dem_x_mesh = repmat(obj.dem_x,length(obj.dem_y),1);
      obj.dem_y_mesh = repmat(obj.dem_y',1,length(obj.dem_x));
      obj.ice_x_mesh = repmat(obj.ice_x,length(obj.ice_y),1);
      obj.ice_y_mesh = repmat(obj.ice_y',1,length(obj.ice_x));
      
      obj.gray = rgb2gray(obj.dem);
      
      obj.reduce_flag = 0;
      obj.actions.getting_polygon = 0;
      obj.run_hold_flag = 1;
      
      ice_mean = 242;
      ice_std = 14;
      rock_mean = 105;
      rock_std = 18;
      water_mean = 169;
      water_std = 15;
      obj.intensity_thresh_default = ice_mean-ice_std;
      obj.intensity_thresh = obj.intensity_thresh_default;
      
      obj.h_dem_fig = figure;
      set(obj.h_dem_fig,'DockControls','off');
      set(obj.h_dem_fig,'NumberTitle','off');
      set(obj.h_dem_fig,'ToolBar','none');
      set(obj.h_dem_fig,'MenuBar','none');
      set(obj.h_dem_fig,'Name','Satellite');
      pos = get(obj.h_dem_fig,'Position');
      pos(3) = pos(3)+70+60;
      set(obj.h_dem_fig,'Position',pos);
      
      obj.gui.left_panel = uipanel('parent',obj.h_dem_fig);
      obj.gui.right_panel = uipanel('parent',obj.h_dem_fig);
      obj.h_dem_axes = axes('Parent',obj.gui.right_panel);
      obj.h_dem_plot = imagesc(obj.dem_x/1e3,obj.dem_y/1e3,obj.dem,'Parent',obj.h_dem_axes);
      set(obj.h_dem_axes,'YDir','normal');
      xlabel(obj.h_dem_axes,'X (km)');
      ylabel(obj.h_dem_axes,'Y (km)');
      hold(obj.h_dem_axes,'on')
      
      obj.h_mask_fig = figure;
      set(obj.h_mask_fig,'DockControls','off');
      set(obj.h_mask_fig,'NumberTitle','off');
      set(obj.h_mask_fig,'ToolBar','none');
      set(obj.h_mask_fig,'MenuBar','none');
      set(obj.h_mask_fig,'Name','Ice Mask');
      
      obj.h_mask_axes = axes('Parent',obj.h_mask_fig);
      obj.h_mask_plot = imagesc(obj.ice_x/1e3,obj.ice_y/1e3,obj.mask,'Parent',obj.h_mask_axes);
      set(obj.h_mask_axes,'YDir','normal');
      xlabel(obj.h_mask_axes,'X (km)');
      ylabel(obj.h_mask_axes,'Y (km)');
      hold(obj.h_mask_axes,'on')
      
      
      set(obj.h_dem_fig,'WindowButtonUpFcn',@obj.button_up);
      set(obj.h_mask_fig,'WindowButtonUpFcn',@obj.button_up);
      set(obj.h_dem_fig,'WindowButtonDownFcn',@obj.button_down);
      set(obj.h_mask_fig,'WindowButtonDownFcn',@obj.button_down);
      set(obj.h_dem_fig,'WindowScrollWheelFcn',@obj.button_scroll);
      set(obj.h_mask_fig,'WindowScrollWheelFcn',@obj.button_scroll);
      set(obj.h_dem_fig,'WindowKeyPressFcn',@obj.key_press);
      set(obj.h_mask_fig,'WindowKeyPressFcn',@obj.key_press);
      set(obj.h_dem_fig,'WindowKeyReleaseFcn',@obj.key_release);
      set(obj.h_mask_fig,'WindowKeyReleaseFcn',@obj.key_release);
      
      % Set up zoom
      zoom_setup(obj.h_dem_fig);
      obj.zoom_mode = true;
      set(obj.h_dem_fig,'pointer','custom');
      
      zoom_setup(obj.h_mask_fig);
      
      obj.toggle_val = 0;
      
      obj.tools(1).str = '(E)stimate';
      obj.tools(1).sc = 'e';
      obj.tools(1).init_fh = @estimate_init;
      obj.tools(1).fh = @update_mask;
      obj.tools(1).figh = obj.h_dem_fig;
      obj.tools(2).str = '(S)et Mask';
      obj.tools(2).sc = 's';
      obj.tools(2).init_fh = @set_mask_init;
      obj.tools(2).fh = @set_mask;
      obj.tools(2).figh = [obj.h_dem_fig,obj.h_mask_fig];
      
      obj.gui.table.ui = obj.h_dem_fig;
      obj.gui.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
      obj.gui.table.height_margin = NaN*zeros(30,30);
      obj.gui.table.false_width = NaN*zeros(30,30);
      obj.gui.table.false_height = NaN*zeros(30,30);
      obj.gui.table.offset = [0 0];
      row = 1;
      col = 1;
      obj.gui.table.handles{row,col}   = obj.gui.left_panel;
      obj.gui.table.width(row,col)     = 70;
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
      
      %% UI Interface
      
      obj.gui.threshSlider = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.threshSlider,'style','slider')
      set(obj.gui.threshSlider,'string','Theshold')
      set(obj.gui.threshSlider,'Min',0,'Max',255)
      set(obj.gui.threshSlider,'Value',obj.intensity_thresh_default);
      set(obj.gui.threshSlider,'Callback',@obj.update_threshold_callback)
      set(obj.gui.threshSlider,'TooltipString','Changes intensity threshold for ice.');
      
      obj.gui.threshDefault = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.threshDefault,'style','pushbutton')
      set(obj.gui.threshDefault,'string','Default')
      set(obj.gui.threshDefault,'Callback',@obj.PB_default)
      
      obj.gui.threshDisp = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.threshDisp,'style','text')
      set(obj.gui.threshDisp,'String',sprintf('%0.0f',obj.intensity_thresh_default));
      
      obj.gui.I_text = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.I_text,'style','text')
      set(obj.gui.I_text,'String','Image Tool');
      
      obj.gui.toolPM = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.toolPM,'style','popup');
      set(obj.gui.toolPM,'TooltipString','Select active tool');
      set(obj.gui.toolPM,'String',{obj.tools.str});
      set(obj.gui.toolPM,'Callback',@obj.toolPM_callback)
      
      obj.gui.toggleVal = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.toggleVal,'style','pushbutton');
      set(obj.gui.toggleVal,'TooltipString','Select active tool');
      set(obj.gui.toggleVal,'String','No Ice');
      set(obj.gui.toggleVal,'Callback',@obj.toggleVal_callback);
      set(obj.gui.toggleVal,'BackgroundColor',obj.h_mask_fig.Colormap(1,:));
      
      obj.gui.polyPB = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.polyPB,'style','pushbutton');
      set(obj.gui.polyPB,'TooltipString','Select active tool');
      set(obj.gui.polyPB,'String','(P)oly');
      set(obj.gui.polyPB,'Callback',@obj.poly);
      
      obj.gui.hold_CB = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.hold_CB,'style','checkbox');
      set(obj.gui.hold_CB,'String','Hold');
      set(obj.gui.hold_CB,'Value',obj.run_hold_flag);
      set(obj.gui.hold_CB,'Callback',@obj.hold_CB_callback);
      
      obj.gui.help_PB = uicontrol('parent',obj.gui.left_panel);
      set(obj.gui.help_PB,'style','pushbutton');
      set(obj.gui.help_PB,'TooltipString','Select active tool');
      set(obj.gui.help_PB,'String','Help (F1)');
      set(obj.gui.help_PB,'Callback',@obj.help_PB_callback);
      
      obj.active_tool(1);
      
      
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
      obj.gui.left_table.handles{row,col}   = obj.gui.threshSlider;
      obj.gui.left_table.width(row,col)     = inf;
      obj.gui.left_table.height(row,col)    = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      row = row + 1;
      obj.gui.left_table.handles{row,col} = obj.gui.threshDisp;
      obj.gui.left_table.width(row,col) = inf;
      obj.gui.left_table.height(row,col) = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      row = row + 1;
      obj.gui.left_table.handles{row,col} = obj.gui.threshDefault;
      obj.gui.left_table.width(row,col) = inf;
      obj.gui.left_table.height(row,col) = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      row = row + 1;
      obj.gui.left_table.handles{row,col} = {};
      obj.gui.left_table.width(row,col) = inf;
      obj.gui.left_table.height(row,col) = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      row = row + 1;
      obj.gui.left_table.handles{row,col} = obj.gui.I_text;
      obj.gui.left_table.width(row,col) = inf;
      obj.gui.left_table.height(row,col) = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      row = row + 1;
      obj.gui.left_table.handles{row,col} = obj.gui.toolPM;
      obj.gui.left_table.width(row,col) = inf;
      obj.gui.left_table.height(row,col) = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      row = row + 1;
      obj.gui.left_table.handles{row,col} = obj.gui.polyPB;
      obj.gui.left_table.width(row,col) = 50;
      obj.gui.left_table.height(row,col) = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      row = row + 1;
      obj.gui.left_table.handles{row,col} = obj.gui.toggleVal;
      obj.gui.left_table.width(row,col) = 50;
      obj.gui.left_table.height(row,col) = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      row = row + 1;
      obj.gui.left_table.handles{row,col} = obj.gui.hold_CB;
      obj.gui.left_table.width(row,col) = inf;
      obj.gui.left_table.height(row,col) = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      row = row + 1;
      obj.gui.left_table.handles{row,col} = {};
      obj.gui.left_table.width(row,col) = inf;
      obj.gui.left_table.height(row,col) = inf;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      row = row + 1;
      obj.gui.left_table.handles{row,col} = obj.gui.help_PB;
      obj.gui.left_table.width(row,col) = inf;
      obj.gui.left_table.height(row,col) = 20;
      obj.gui.left_table.width_margin(row,col) = 1;
      obj.gui.left_table.height_margin(row,col) = 1;
      
      
      clear row col
      table_draw(obj.gui.left_table);
      
      %%
      
      if isfield(param,'mdata')
        obj.change_slice(1);
      end
      
    end
    
    function delete(obj)
      try; delete(obj.h_dem_fig); end;
      try; delete(obj.h_mask_fig); end;
    end
    
    function button_down(obj,h_obj,event)
      
      if h_obj == obj.h_dem_fig
        h_axes = obj.h_dem_axes;
      else
        h_axes = obj.h_mask_axes;
      end
      
      [obj.x,obj.y,but] = get_mouse_info(h_obj,h_axes);
      rbbox;
    end
    
    
    %     function button_down_mask(obj,h_obj,event)
    %       [obj.x_mask,obj.y_mask,but] = get_mouse_info(obj.h_mask_fig,obj.h_mask_axes);
    %       rbbox;
    %     end
    
    
    function button_up(obj,h_obj,event)
      %       h_axes = get(h_obj,'Children');
      
      if h_obj == obj.h_dem_fig
        h_axes = obj.h_dem_axes;
        h_axes_alt = obj.h_mask_axes;
      else
        h_axes = obj.h_mask_axes;
        h_axes_alt = obj.h_dem_axes;
      end
      [x,y,but] = get_mouse_info(h_obj,h_axes);
      
      if obj.zoom_mode && ~obj.actions.getting_polygon
        zoom_button_up(x,y,but,struct('x',obj.x,'y',obj.y, ...
          'h_axes',h_axes,'xlims',[min(obj.dem_x),max(obj.dem_x)]/1e3,'ylims',[min(obj.dem_y),max(obj.dem_y)]/1e3,'axis_equal',1));
        
        set(h_axes_alt,'xlim',get(h_axes,'xlim'));
        set(h_axes_alt,'ylim',get(h_axes,'ylim'));
        
      elseif but == 3 && x==obj.x && y==obj.y && ~isempty(obj.intersections)
        inter_x = reshape(obj.intersections(1,:,:),...
          size(obj.intersections,2),size(obj.intersections,3));
        inter_y = reshape(obj.intersections(2,:,:),...
          size(obj.intersections,2),size(obj.intersections,3));
        slices = repmat(1:size(inter_x,2),size(inter_x,1),1);
        
        near_mask = inter_x >= x*1e3-1e3 & inter_x <= x*1e3+1e3 &...
          inter_y >= y*1e3-1e3 & inter_y <= y*1e3+1e3;
        inter_x = inter_x(near_mask);
        inter_y = inter_y(near_mask);
        slices = slices(near_mask);
        
        slice = griddata(inter_x,inter_y,slices,x*1e3,y*1e3,'nearest');
        if ~isnan(slice)
          obj.slice = slice;
          obj.change_slice(obj.slice);
          notify(obj,'SliceChange')
        end
        
      elseif but == 1 && x~=obj.x && y~=obj.y && obj.active_tool_idx > 0 ...
          && any(obj.tools(obj.active_tool_idx).figh == h_obj)
        xlims = xlim(h_axes);
        ylims = ylim(h_axes);
        if x >= xlims(1) && x <= xlims(2) && y >= ylims(1) && y <= ylims(2)
          x_poly = [sort([x,obj.x]),sort([x,obj.x],'descend')];
          y_poly = [max(y,obj.y),max(y,obj.y),min(y,obj.y),min(y,obj.y)];
          
          obj.tools(obj.active_tool_idx).fh(obj,x_poly,y_poly)
        end
      end
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
      
      % Check to make sure that a key was pressed and not
      % just a modifier (e.g. shift, ctrl, alt)
      if ~isempty(event.Key)
        
        for tool_idx = 1:length(obj.tools)
          if strcmp(event.Key,obj.tools(tool_idx).sc)
            set(obj.gui.toolPM,'Value',tool_idx);
            obj.active_tool(tool_idx);
            obj.zoom_mode = 0;
            set(obj.h_dem_fig,'pointer','arrow');
            set(obj.h_mask_fig,'pointer','arrow');
            break;
          end
        end
        
        switch event.Key
          
          case 'z'
            % toggle zoom mode
            obj.zoom_mode = ~obj.zoom_mode;
            if obj.zoom_mode
              set(obj.h_dem_fig,'pointer','custom');
              set(obj.h_mask_fig,'pointer','custom');
            else
              set(obj.h_dem_fig,'pointer','arrow');
              set(obj.h_mask_fig,'pointer','arrow');
            end
            
          case 'downarrow' % Down-arrow: Pan down
            zoom_arrow(event,struct('h_axes',obj.h_dem_axes, ...
              'xlims',[min(obj.dem_x),max(obj.dem_x)]/1e3,'ylims',[min(obj.dem_y),max(obj.dem_y)]/1e3));
            set(obj.h_mask_axes,'xlim',get(obj.h_dem_axes,'xlim'));
            set(obj.h_mask_axes,'ylim',get(obj.h_dem_axes,'ylim'));
            
          case 'uparrow' % Up-arrow: Pan up
            zoom_arrow(event,struct('h_axes',obj.h_dem_axes, ...
              'xlims',[min(obj.dem_x),max(obj.dem_x)]/1e3,'ylims',[min(obj.dem_y),max(obj.dem_y)]/1e3));
            set(obj.h_mask_axes,'xlim',get(obj.h_dem_axes,'xlim'));
            set(obj.h_mask_axes,'ylim',get(obj.h_dem_axes,'ylim'));
            
          case 'rightarrow' % Right arrow: Pan right
            zoom_arrow(event,struct('h_axes',obj.h_dem_axes, ...
              'xlims',[min(obj.dem_x),max(obj.dem_x)]/1e3,'ylims',[min(obj.dem_y),max(obj.dem_y)]/1e3));
            set(obj.h_mask_axes,'xlim',get(obj.h_dem_axes,'xlim'));
            set(obj.h_mask_axes,'ylim',get(obj.h_dem_axes,'ylim'));
            
          case 'leftarrow' % Left arrow: Pan left
            zoom_arrow(event,struct('h_axes',obj.h_dem_axes, ...
              'xlims',[min(obj.dem_x),max(obj.dem_x)]/1e3,'ylims',[min(obj.dem_y),max(obj.dem_y)]/1e3));
            set(obj.h_mask_axes,'xlim',get(obj.h_dem_axes,'xlim'));
            set(obj.h_mask_axes,'ylim',get(obj.h_dem_axes,'ylim'));
            
          case 'period'
            if ~obj.shift_pressed
              obj.slice = obj.slice + 1;
            else
              obj.slice = obj.slice + 10;
            end
            obj.change_slice(obj.slice);
            notify(obj,'SliceChange')
            
          case 'comma'
            if ~obj.shift_pressed
              obj.slice = obj.slice - 1;
            else
              obj.slice = obj.slice - 10;
            end
            obj.change_slice(obj.slice);
            notify(obj,'SliceChange')
            
          case 'p'
            obj.poly([],[]);
            
          case 't'
            obj.toggleVal_callback(obj.gui.toggleVal,[]);
            
          case 'r'
            obj.local_undo_stack.redo();
            notify(obj,'Redo');
            
          case 'u'
            obj.local_undo_stack.pop();
            notify(obj,'Undo')
            
          case 'f'
            obj.force_mask();
            
          case 'f1'
            obj.help_PB_callback([],[]);
            
          otherwise
            
        end
        
      end
    end
    
    
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
    
    
    function update_mask(obj,xv,yv)
      
      xv = xv*1e3;
      yv = yv*1e3;
      
      x_p_lim = [min(xv),max(xv)];
      y_p_lim = [min(yv),max(yv)];
      
      gray_idx = find(obj.dem_y_mesh>=y_p_lim(1) & obj.dem_y_mesh<=y_p_lim(2) &...
        obj.dem_x_mesh>=x_p_lim(1) & obj.dem_x_mesh<=x_p_lim(2));
      
      if isempty(gray_idx)
        return
      end
      
      gray_tmp = obj.gray(gray_idx);
      x_tmp = obj.dem_x_mesh(gray_idx);
      y_tmp = obj.dem_y_mesh(gray_idx);
      
      %       ice_block_idx = find(obj.ice_y_mesh>=y_p_lim(1) & obj.ice_y_mesh<=y_p_lim(2) &...
      %         obj.ice_x_mesh>=x_p_lim(1) & obj.ice_x_mesh<=x_p_lim(2));
      ice_block_idx = find(obj.ice_y_mesh>=min(y_tmp) & obj.ice_y_mesh<=max(y_tmp) &...
        obj.ice_x_mesh>=min(x_tmp) & obj.ice_x_mesh<=max(x_tmp));
      
      if isempty(ice_block_idx)
        return
      end
      %       ice_block_idx = find(obj.ice_y_mesh>=min(y_tmp)-diff_y/2 & obj.ice_y_mesh<=max(y_tmp)+diff_y/2 &...
      %         obj.ice_x_mesh>=min(x_tmp)-diff_x/2 & obj.ice_x_mesh<=max(x_tmp)+diff_x/2);
      
      
      ice_x_tmp = obj.ice_x_mesh(ice_block_idx);
      ice_y_tmp = obj.ice_y_mesh(ice_block_idx);
      [ice_x_mesh,ice_y_mesh] = meshgrid(sort(unique(ice_x_tmp)),sort(unique(ice_y_tmp),'descend'));
      
      diff_x = abs(mean(diff(obj.ice_x)));
      diff_y = abs(mean(diff(obj.ice_y)));
      
      if length(ice_x_tmp)~=numel(ice_x_mesh)
        keyboard;
      end
      
      gray_tmp = griddata(x_tmp,y_tmp,double(gray_tmp),ice_x_mesh,ice_y_mesh);
      [ice_in] = inpolygon(ice_x_mesh,ice_y_mesh,xv,yv);
      gray_tmp_in = gray_tmp(ice_in);
      
      if obj.run_hold_flag
        obj.hold_estimate(gray_tmp_in,ice_block_idx(ice_in));
      end
      mask_tmp = gray_tmp_in>=obj.intensity_thresh;
      
      if all(obj.mask(ice_block_idx(ice_in))==mask_tmp)
        return
      end
      
      cmd = obj.update_intersects(xv,yv,ice_block_idx(ice_in),mask_tmp);
      
      cmd{1}.undo.mask = obj.mask(ice_block_idx(ice_in));
      cmd{1}.redo.mask = mask_tmp;
      cmd{1}.undo.mask_idx = ice_block_idx(ice_in);
      cmd{1}.redo.mask_idx = ice_block_idx(ice_in);
      
      cmd{1}.type = 'ice_mask';
      
      if obj.local_undo_flag
        obj.local_undo_stack.push(cmd);
      else
        obj.cmd = cmd;
        notify(obj,'IceChange');
      end
      obj.cmd = [];
      
    end
    
    
    function set_mask(obj,xv,yv)
      
      xv = xv*1e3;
      yv = yv*1e3;
      
      x_p_lim = [min(xv),max(xv)];
      y_p_lim = [min(yv),max(yv)];
      
      mask_idx = find(obj.ice_y_mesh>=y_p_lim(1) & obj.ice_y_mesh<=y_p_lim(2) &...
        obj.ice_x_mesh>=x_p_lim(1) & obj.ice_x_mesh<=x_p_lim(2));
      
      x_tmp = obj.ice_x_mesh(mask_idx);
      y_tmp = obj.ice_y_mesh(mask_idx);
      
      [x_mesh,y_mesh] = meshgrid(sort(unique(x_tmp)),sort(unique(y_tmp),'descend'));
      
      [ice_in] = inpolygon(x_mesh,y_mesh,xv,yv);
      
      mask_tmp = obj.toggle_val * ones(size(find(ice_in)));
      
      if all(mask_tmp == obj.mask(mask_idx(ice_in)))
        return
      end
      
      cmd = obj.update_intersects(xv,yv,mask_idx(ice_in),mask_tmp);
      
      cmd{1}.undo.mask = obj.mask(mask_idx(ice_in));
      cmd{1}.redo.mask = mask_tmp;
      cmd{1}.undo.mask_idx = mask_idx(ice_in);
      cmd{1}.redo.mask_idx = mask_idx(ice_in);
      
      cmd{1}.type = 'ice_mask';
      
      if obj.local_undo_flag
        obj.local_undo_stack.push(cmd);
      else
        obj.cmd = cmd;
        notify(obj,'IceChange');
      end
      obj.cmd = [];
      
    end
    
    
    function change_slice(obj,slice)
      if isempty(obj.mdata_loaded) || ~obj.mdata_loaded
        %% load data
        % convert from FCS to proj
        origin_ecef = obj.mdata.param_array.array_param.fcs{1}{1}.origin(:,:);
        physical_constants;
        [origin_lat,origin_lon] = ecef2geodetic(origin_ecef(1,:),origin_ecef(2,:),origin_ecef(3,:),WGS84.ellipsoid);
        origin_lat = origin_lat*180/pi;
        origin_lon = origin_lon*180/pi;
        % Convert from geodetic to projection
        obj.flight_line = zeros(2,size(obj.mdata.twtt,2));
        [obj.flight_line(1,:),obj.flight_line(2,:)] = projfwd(obj.proj,origin_lat,origin_lon);
        
        obj.h_flight_dem_plot = plot(obj.flight_line(1,:)/1e3,obj.flight_line(2,:)/1e3,'b','Parent',obj.h_dem_axes);
        obj.h_flight_mask_plot = plot(obj.flight_line(1,:)/1e3,obj.flight_line(2,:)/1e3,'b','Parent',obj.h_mask_axes);
        obj.h_true_dem_plot = plot(NaN,NaN,'b.','Parent',obj.h_dem_axes);
        obj.h_false_dem_plot = plot(NaN,NaN,'r.','Parent',obj.h_dem_axes);
        obj.h_true_mask_plot = plot(NaN,NaN,'b.','Parent',obj.h_mask_axes);
        obj.h_false_mask_plot = plot(NaN,NaN,'r.','Parent',obj.h_mask_axes);
        
        Nr = size(obj.mdata.twtt,2);
        Nt = length(obj.mdata.theta);
        
        intersect_ecef_all = zeros([3,Nt,Nr]);
        for rline = 1:Nr
          
          Tfcs_ecef = [obj.mdata.param_array.array_param.fcs{1}{1}.x(:,rline), ...
            obj.mdata.param_array.array_param.fcs{1}{1}.y(:,rline), ...
            obj.mdata.param_array.array_param.fcs{1}{1}.z(:,rline)];
          
          dir = [zeros(Nt,1), sin(obj.mdata.theta), -cos(obj.mdata.theta)].';
          for row = 1:Nt
            dir(:,row) = dir(:,row)/norm(dir(:,row));
          end
          
          intersect =  dir .* repmat(obj.mdata.twtt(:,rline)',3,1) * 3e8/2;
          
          intersect_ecef = Tfcs_ecef*intersect;
          intersect_ecef(isnan(intersect_ecef)) = 0;
          intersect_ecef_all(1,:,rline) = intersect_ecef(1,:) + origin_ecef(1,rline);
          intersect_ecef_all(2,:,rline) = intersect_ecef(2,:) + origin_ecef(2,rline);
          intersect_ecef_all(3,:,rline) = intersect_ecef(3,:) + origin_ecef(3,rline);
          
        end
        
        [intersect_lat,intersect_lon] = ecef2geodetic(intersect_ecef_all(1,:,:),intersect_ecef_all(2,:,:),intersect_ecef_all(3,:,:),WGS84.ellipsoid);
        intersect_lat = intersect_lat*180/pi;
        intersect_lon = intersect_lon*180/pi;
        [intersect_x,intersect_y] = projfwd(obj.proj,intersect_lat,intersect_lon);
        
        obj.intersections = [intersect_x;intersect_y];
        
        obj.reduce_DEM();
        
        obj.mdata_loaded = 1;
        
        set(obj.h_dem_axes,'xlim',[min(min(obj.intersections(1,:,:)))/1e3 - 5, ...
          max(max(obj.intersections(1,:,:)))/1e3 + 5]);
        set(obj.h_dem_axes,'ylim',[min(min(obj.intersections(2,:,:)))/1e3 - 5, ...
          max(max(obj.intersections(2,:,:)))/1e3 + 5]);
        set(obj.h_mask_axes,'xlim',[min(min(obj.intersections(1,:,:)))/1e3 - 5, ...
          max(max(obj.intersections(1,:,:)))/1e3 + 5]);
        set(obj.h_mask_axes,'ylim',[min(min(obj.intersections(2,:,:)))/1e3 - 5, ...
          max(max(obj.intersections(2,:,:)))/1e3 + 5]);
        
      end
      
      if slice < 1
        slice = 1;
      elseif slice > size(obj.intersections,3)
        slice = size(obj.intersections,3);
      end
      
      obj.slice = slice;
      intersection = obj.intersections(:,:,slice);
      mask_tmp = logical(obj.mdata.ice_mask(:,slice));
      
      xlim = get(obj.h_dem_axes,'Xlim');
      ylim = get(obj.h_dem_axes,'Ylim');
      
      if xlim(1)>min(intersection(1,:))/1e3 || xlim(2)<max(intersection(1,:))/1e3 || ...
          ylim(1)>min(intersection(2,:))/1e3 || ylim(2)<max(intersection(2,:))/1e3
        x_len = abs(xlim(2)-xlim(1));
        y_len = abs(ylim(2)-ylim(1));
        x_center = intersection(1,floor((size(intersection,2))/2)+1)/1e3;
        y_center = intersection(2,floor((size(intersection,2))/2)+1)/1e3;
        set(obj.h_dem_axes,'XLim',x_center+[-x_len,x_len]/2);
        set(obj.h_mask_axes,'XLim',x_center+[-x_len,x_len]/2);
        set(obj.h_dem_axes,'YLim',y_center+[-y_len,y_len]/2);
        set(obj.h_mask_axes,'YLim',y_center+[-y_len,y_len]/2);
      end
      
      %       obj.h_slice_plot = plot(intersection(1,:),intersection(2,:),'m.','Parent',obj.h_dem_axes);
      set(obj.h_true_dem_plot,'XData',intersection(1,mask_tmp)/1e3,'YData',intersection(2,mask_tmp)/1e3);
      set(obj.h_false_dem_plot,'XData',intersection(1,~mask_tmp)/1e3,'YData',intersection(2,~mask_tmp)/1e3);
      set(obj.h_true_mask_plot,'XData',intersection(1,mask_tmp)/1e3,'YData',intersection(2,mask_tmp)/1e3);
      set(obj.h_false_mask_plot,'XData',intersection(1,~mask_tmp)/1e3,'YData',intersection(2,~mask_tmp)/1e3);
      
    end
    
    function getEventData(obj,src,~)
      obj.change_slice(src.slice);
    end
    
    function undo_sync(obj,src,~)
      [cmds_list,cmds_direction] =  src.get_synchronize_cmds();
      if strcmp(cmds_direction,'redo')
        for cmd_idx = 1:length(cmds_list)
          for subcmd_idx = 1:length(cmds_list{cmd_idx})
            if strcmp(cmds_list{cmd_idx}{subcmd_idx}.type,'ice_mask')
              if isfield(cmds_list{cmd_idx}{subcmd_idx}.redo,'mask')
                obj.mask(cmds_list{cmd_idx}{subcmd_idx}.redo.mask_idx) = ...
                  cmds_list{cmd_idx}{subcmd_idx}.redo.mask;
              end
              if isfield(cmds_list{cmd_idx}{subcmd_idx}.redo,'data_mask')
                obj.mdata.ice_mask(cmds_list{cmd_idx}{subcmd_idx}.redo.data_mask_idx) ...
                  = cmds_list{cmd_idx}{subcmd_idx}.redo.data_mask;
              end
            end
          end
        end
      else
        for cmd_idx = 1:length(cmds_list)
          for subcmd_idx = 1:length(cmds_list{cmd_idx})
            if strcmp(cmds_list{cmd_idx}{subcmd_idx}.type,'ice_mask')
              if isfield(cmds_list{cmd_idx}{subcmd_idx}.undo,'mask')
                obj.mask(cmds_list{cmd_idx}{subcmd_idx}.undo.mask_idx) = ...
                  cmds_list{cmd_idx}{subcmd_idx}.undo.mask;
              end
              if isfield(cmds_list{cmd_idx}{subcmd_idx}.undo,'data_mask')
                obj.mdata.ice_mask(cmds_list{cmd_idx}{subcmd_idx}.undo.data_mask_idx) ...
                  = cmds_list{cmd_idx}{subcmd_idx}.undo.data_mask;
              end
            end
          end
        end
      end
      
      set(obj.h_mask_plot,'CData',obj.mask,'XData',obj.ice_x/1e3,'YData',obj.ice_y/1e3);
      if ~isempty(obj.mdata_loaded) && obj.mdata_loaded
        intersection = obj.intersections(:,:,obj.slice);
        twtt_mask_tmp = logical(obj.mdata.ice_mask(:,obj.slice));
        set(obj.h_true_dem_plot,'XData',intersection(1,twtt_mask_tmp)/1e3,'YData',intersection(2,twtt_mask_tmp)/1e3);
        set(obj.h_false_dem_plot,'XData',intersection(1,~twtt_mask_tmp)/1e3,'YData',intersection(2,~twtt_mask_tmp)/1e3);
        set(obj.h_true_mask_plot,'XData',intersection(1,twtt_mask_tmp)/1e3,'YData',intersection(2,twtt_mask_tmp)/1e3);
        set(obj.h_false_mask_plot,'XData',intersection(1,~twtt_mask_tmp)/1e3,'YData',intersection(2,~twtt_mask_tmp)/1e3);
      end
    end
    
    function update_threshold_callback(obj,source,~)
      val = source.Value;
      obj.update_threshold(val);
    end
    
    function update_threshold(obj,val)
      
      if val < get(obj.gui.threshSlider,'Min')
        intensity = get(obj.gui.threshSlider,'Min');
      elseif val > get(obj.gui.threshSlider,'Max')
        intensity = get(obj.gui.threshSlider,'Max');
      else
        intensity = val;
      end
      
      obj.intensity_thresh = intensity;
      set(obj.gui.threshDisp,'String',sprintf('%0.0f',intensity));
      set(obj.gui.threshSlider,'Value',intensity);
    end
    
    function PB_default(obj,source,~)
      val = obj.intensity_thresh_default;
      set(obj.gui.threshSlider,'Value',val);
      set(obj.gui.threshDisp,'String',sprintf('%0.0f',val));
      obj.intensity_thresh = val;
    end
    
    function cmd = edit_twtt(obj,theta,slice,val,val_curr)
      x = obj.intersections(1,theta,slice);
      y = obj.intersections(2,theta,slice);
      
      ice_x = interp1(obj.ice_x,1:length(obj.ice_x),x,'nearest');
      ice_y = interp1(obj.ice_y,1:length(obj.ice_y),y,'nearest');
      ice_idx = sub2ind(size(obj.ice_x_mesh),ice_y,ice_x);
      
      ice_x_idx = [ice_x-1,ice_x,ice_x+1];
      ice_x_idx = ice_x_idx(ice_x_idx>0 & ice_x_idx<=length(obj.ice_x));
      ice_y_idx = [ice_y-1,ice_y,ice_y+1];
      ice_y_idx = ice_y_idx(ice_y_idx>0 & ice_y_idx<=length(obj.ice_y));
      [ice_x_idx,ice_y_idx] = meshgrid(ice_x_idx,ice_y_idx);
      ice_idx_exp = sub2ind(size(obj.ice_x_mesh),ice_y_idx,ice_x_idx);
      
      ice_x_mesh = obj.ice_x_mesh(ice_idx_exp);
      ice_y_mesh = obj.ice_y_mesh(ice_idx_exp);
      idx_mesh = reshape(1:numel(ice_x_mesh),size(ice_x_mesh));
      idx_match = griddata(ice_x_mesh,ice_y_mesh,idx_mesh,x,y,'nearest');
      
      inter_near_idx = find(obj.intersections(1,:,:) >= min(min(ice_x_mesh)) & ...
        obj.intersections(1,:,:) <= max(max(ice_x_mesh)) & ...
        obj.intersections(2,:,:) >= min(min(ice_y_mesh)) & ...
        obj.intersections(2,:,:) <= max(max(ice_y_mesh)));
      
      inter_tmp = obj.intersections(:,inter_near_idx);
      
      g = griddata(ice_x_mesh,ice_y_mesh,idx_mesh,inter_tmp(1,:),inter_tmp(2,:),'nearest');
      %           g = interp2(ice_x_mesh,ice_y_mesh,idx_mesh,inter_tmp(1,:),inter_tmp(2,:),'nearest');
      
      inter_eff_idx = inter_near_idx(ismember(g,idx_match));
      
      cmd{1}.redo.data_mask = val(1)*ones(1,length(inter_eff_idx));
      cmd{1}.undo.data_mask = obj.mdata.ice_mask(ones(1,length(inter_eff_idx)));
      cmd{1}.undo.data_mask_idx = inter_eff_idx;
      cmd{1}.redo.data_mask_idx = inter_eff_idx;
      
      cmd{1}.undo.mask = val_curr;
      cmd{1}.redo.mask = val;
      cmd{1}.undo.mask_idx = ice_idx;
      cmd{1}.redo.mask_idx = ice_idx;
      cmd{1}.type = 'ice_mask';
      
    end
    
    
    function cmd = update_intersects(obj,xv,yv,mask_idx,val)
      
      cmd{1}.redo.data_mask = [];
      cmd{1}.undo.data_mask = [];
      cmd{1}.undo.data_mask_idx = [];
      cmd{1}.redo.data_mask_idx = [];
      
      inter_idx = [];
      if ~isempty(obj.intersections)
        xq = obj.ice_x_mesh(mask_idx);
        yq = obj.ice_y_mesh(mask_idx);
        
        diff_x = abs(mean(diff(obj.ice_x)));
        diff_y = abs(mean(diff(obj.ice_y)));
        
        inter_idx = find(obj.intersections(2,:,:)>=min(yq)-diff_y/2 & obj.intersections(2,:,:)<=max(yq)+diff_y/2 &...
          obj.intersections(1,:,:)>=min(xq)-diff_x/2 & obj.intersections(1,:,:)<=max(xq)+diff_x/2);
        inter_idx = inter_idx(inpolygon(obj.intersections(1,inter_idx),obj.intersections(2,inter_idx),xv,yv));
      end
      if ~isempty(inter_idx)
        %         ice_in_buff = logical(conv2(double(ice_in),ones(3),'same'));
        %         inter_ice_val = griddata(ice_x_tmp(ice_in_buff),ice_y_tmp(ice_in_buff),double(mask_tmp),obj.intersections(1,inter_idx),obj.intersections(2,inter_idx),'nearest');
        inter_ice_val = griddata(xq,yq,double(val),obj.intersections(1,inter_idx),obj.intersections(2,inter_idx),'nearest');
        
        inter_tmp_idx = ~isnan(inter_ice_val);
        inter_diff_idx = inter_idx(inter_tmp_idx);
        inter_val = inter_ice_val(inter_tmp_idx);
        
        data_mask_tmp = obj.mdata.ice_mask;
        data_mask_tmp(inter_diff_idx) = inter_val;
        cmd{1}.redo.data_mask = data_mask_tmp(inter_diff_idx);
        cmd{1}.undo.data_mask = obj.mdata.ice_mask(inter_diff_idx);
        cmd{1}.undo.data_mask_idx = inter_diff_idx;
        cmd{1}.redo.data_mask_idx = inter_diff_idx;
      end
      
    end
    
    
    function toolPM_callback(obj,source,~)
      val = source.Value;
      obj.active_tool(val);
    end
    
    
    function toggleVal_callback(obj,source,~)
      cm = get(obj.h_mask_fig,'Colormap');
      if obj.toggle_val
        obj.toggle_val = 0;
        set(source,'String','No Ice');
        set(source,'BackgroundColor',cm(1,:));
      else
        obj.toggle_val = 1;
        set(source,'String','Ice');
        set(source,'BackgroundColor',cm(end,:));
      end
    end
    
    
    function save(obj)
      fprintf('Saving ice mask data (%s)...\n', datestr(now));
      [fid,msg] = fopen(obj.ice_mask_fn,'r+');
      if fid < 1
        fprintf('Could not open file %s\n', obj.ice_mask_fn);
        error('Could not save ice_mask: %s.', msg);
      end
        
      if isempty(obj.mask_all)
        mask_old = logical(fread(fid,size(obj.mask),'uint8=>uint8'));
        diff_idx = find(mask_old ~= obj.mask);
        for i = 1:numel(diff_idx)
          fseek(fid,diff_idx(i),'bof');
          fwrite(fid,obj.mask(i),'uint8');
        end
        
      else
        mask_old = logical(fread(fid,size(obj.mask_all),'uint8=>uint8'));
        idx_reduced = find(mask_old(obj.ice_y_idx,obj.ice_x_idx) ~= obj.mask);
        idx_block_y = find(obj.ice_y_idx);
        idx_block_x = find(obj.ice_x_idx);
        [idx_y,idx_x] = ind2sub(size(obj.mask),idx_reduced);
        idx_y_all = idx_block_y(idx_y);
        idx_x_all = idx_block_x(idx_x);
        idx = sub2ind(size(obj.mask_all),idx_y_all,idx_x_all);
        
        for i = 1:length(idx)
          fseek(fid,idx(i),'bof');
          fwrite(fid,obj.mask(idx_reduced(i)),'uint8');
        end
      end
      fprintf('  Done\n');
    
      fclose(fid);
    end
    
    function active_tool(obj,tool_idx)
      if isfield(obj.tools(tool_idx),'init_fh')
        obj.tools(tool_idx).init_fh(obj);
      end
      obj.active_tool_idx = tool_idx;
    end
    
    function set_mask_init(obj)
      set(obj.gui.toggleVal,'Visible','on');
    end
    
    function estimate_init(obj)
      set(obj.gui.toggleVal,'Visible','off');
    end
    
    function reduce_DEM(obj)
      
      if obj.reduce_flag
        dem_x_idx = obj.dem_x >= min(min(obj.intersections(1,:,:))) - 10000 & ...
          obj.dem_x <= max(max(obj.intersections(1,:,:))) + 10000;
        dem_y_idx = obj.dem_y >= min(min(obj.intersections(2,:,:))) - 10000 & ...
          obj.dem_y <= max(max(obj.intersections(2,:,:))) + 10000;
        
        obj.ice_x_idx = obj.ice_x >= min(min(obj.intersections(1,:,:))) - 10000 & ...
          obj.ice_x <= max(max(obj.intersections(1,:,:))) + 10000;
        obj.ice_y_idx = obj.ice_y >= min(min(obj.intersections(2,:,:))) - 10000 & ...
          obj.ice_y <= max(max(obj.intersections(2,:,:))) + 10000;
        
        obj.dem = obj.dem(dem_y_idx,dem_x_idx);
        obj.gray = obj.gray(dem_y_idx,dem_x_idx);
        obj.dem_x = obj.dem_x(dem_x_idx);
        obj.dem_y = obj.dem_y(dem_y_idx);
        obj.dem_x_mesh = repmat(obj.dem_x,length(obj.dem_y),1);
        obj.dem_y_mesh = repmat(obj.dem_y',1,length(obj.dem_x));
        
        obj.mask_all = obj.mask;
        obj.ice_x_all = obj.ice_x;
        obj.ice_y_all = obj.ice_y;
        
        obj.mask = obj.mask(obj.ice_y_idx,obj.ice_x_idx);
        obj.ice_x = obj.ice_x(obj.ice_x_idx);
        obj.ice_y = obj.ice_y(obj.ice_y_idx);
        obj.ice_x_mesh = repmat(obj.ice_x,length(obj.ice_y),1);
        obj.ice_y_mesh = repmat(obj.ice_y',1,length(obj.ice_x));
      end
      
    end
    
    function poly(obj,src,~)
      
      if obj.active_tool_idx ~= 0
        obj.actions.getting_polygon = 1;
        set(obj.gui.polyPB,'BackgroundColor',[0.8,0.8,0.8]);
        try
          poly_handle = impoly;
          position = wait(poly_handle);
          obj.actions.getting_polygon = 2;
          [polyPts] = getPosition(poly_handle);
          xPoly = polyPts(:,1);
          yPoly = polyPts(:,2);
          delete(poly_handle);
          obj.actions.getting_polygon = 0;
        catch
          set(obj.gui.polyPB,'BackgroundColor',[0.94,0.94,0.94]);
          obj.actions.getting_polygon = 0;
          return
        end
        obj.tools(obj.active_tool_idx).fh(obj,xPoly,yPoly);
        set(obj.gui.polyPB,'BackgroundColor',[0.94,0.94,0.94]);
      end
      
    end
    
    function force_mask(obj)
      if obj.mdata_loaded && ~isempty(obj.intersections)
        x = reshape(obj.intersections(1,:,:),size(obj.intersections,2),size(obj.intersections,3));
        y = reshape(obj.intersections(2,:,:),size(obj.intersections,2),size(obj.intersections,3));
        
        ice_x = interp1(obj.ice_x,1:length(obj.ice_x),x,'nearest');
        ice_y = interp1(obj.ice_y,1:length(obj.ice_y),y,'nearest');
        ice_idx = sub2ind(size(obj.ice_x_mesh),ice_y,ice_x);
        
        data_mask_tmp = obj.mask(ice_idx);
        data_mask_curr = obj.mdata.ice_mask;
        
        inter_diff_idx = find(data_mask_curr~=data_mask_tmp);
        
        cmd{1}.redo.data_mask = data_mask_tmp(inter_diff_idx);
        cmd{1}.undo.data_mask = data_mask_curr(inter_diff_idx);
        cmd{1}.undo.data_mask_idx = inter_diff_idx;
        cmd{1}.redo.data_mask_idx = inter_diff_idx;
        cmd{1}.type = 'ice_mask';
        
        if obj.local_undo_flag
          obj.local_undo_stack.push(cmd);
        else
          obj.cmd = cmd;
          notify(obj,'IceChange');
        end
        obj.cmd = [];
      end
    end
    
    function hold_estimate(obj,gray_int,mask_idx)
      
      obj.hold_flag = 1;
      
      set(obj.h_dem_fig,'WindowKeyPressFcn',@obj.hold_keypress)
      set(obj.h_mask_fig,'WindowKeyPressFcn',@obj.hold_keypress)
      
      f_names = fieldnames(obj.gui);
      
      for i = 1:length(f_names)
        if isa(obj.gui.(f_names{i}),'matlab.ui.control.UIControl') && ...
            ~strcmp(f_names{i},'threshSlider') && ~strcmp(f_names{i},'hold_CB') ...
            && ~strcmp(f_names{i},'threshDisp')
          set(obj.gui.(f_names{i}),'Enable','off');
        end
      end
      
      mask = obj.mask;
      
      fprintf('\nPress Enter/Return to escape\n');
      
      thresh_prev = obj.intensity_thresh;
      while obj.hold_flag
        if thresh_prev ~= obj.intensity_thresh
          mask(mask_idx) = gray_int >= obj.intensity_thresh;
          set(obj.h_mask_plot,'CData',mask,'XData',obj.ice_x/1e3,'YData',obj.ice_y/1e3);
          
          thres_prev = obj.intensity_thresh;
        end
        pause(0.1);
      end
      
      set(obj.h_dem_fig,'WindowKeyPressFcn',@obj.key_press)
      set(obj.h_mask_fig,'WindowKeyPressFcn',@obj.key_press)
      
      for i = 1:length(f_names)
        if isa(obj.gui.(f_names{i}),'matlab.ui.control.UIControl')
          set(obj.gui.(f_names{i}),'Enable','on');
        end
      end
      
    end
    
    
    function hold_keypress(obj,src,event)
      switch event.Key
        case 'return'
          obj.hold_flag = 0;
          
        case 'rightarrow'
          if obj.shift_pressed
            obj.update_threshold(obj.intensity_thresh+10);
          else
            obj.update_threshold(obj.intensity_thresh+1);
          end
          
        case 'period'
          if obj.shift_pressed
            obj.update_threshold(obj.intensity_thresh+10);
          else
            obj.update_threshold(obj.intensity_thresh+1);
          end
          
        case 'leftarrow'
          if obj.shift_pressed
            obj.update_threshold(obj.intensity_thresh-10);
          else
            obj.update_threshold(obj.intensity_thresh-1);
          end
          
        case 'comma'
          if obj.shift_pressed
            obj.update_threshold(obj.intensity_thresh-10);
          else
            obj.update_threshold(obj.intensity_thresh-1);
          end
      end
    end
    
    
    function hold_CB_callback(obj,src,event)
      val = get(src,'Value');
      if val
        obj.run_hold_flag = 1;
      else
        obj.run_hold_flag = 0;
        obj.hold_flag = 0;
      end
    end
    
    %% button_scroll
    function button_scroll(obj,h_obj,event)
      if h_obj == obj.h_dem_fig
        h_axes = obj.h_dem_axes;
        h_axes_alt = obj.h_mask_axes;
      else
        h_axes = obj.h_mask_axes;
        h_axes_alt = obj.h_dem_axes;
      end
      
      zoom_button_scroll(event,struct('h_fig',h_obj, ...
        'h_axes',h_axes,'xlims',[min(obj.dem_x),max(obj.dem_x)]/1e3,'ylims',[min(obj.dem_y),max(obj.dem_y)]/1e3));
      
      set(h_axes_alt,'xlim',get(h_axes,'xlim'));
      set(h_axes_alt,'ylim',get(h_axes,'ylim'));
    end
    
    function help_PB_callback(obj,src,event)
      fprintf('(E)stimate:\n');
      fprintf('\tUses color intensity thresholding to estimate ice mask values in selected area.\n');
      fprintf('(S)et:\n');
      fprintf('\tDirectly sets ice mask values in selected area.\n');
      fprintf('Default Button:\n');
      fprintf('\tReturns color intensity threshold to the default value.\n');
      fprintf('(P)oly Button:\n');
      fprintf('\tEnables finer selection of area for tool operation.\n')
      fprintf('\tPress Esc to cancel Poly.\n');
      fprintf('Hold Checkbox:\n');
      fprintf('\tHolds execution of (E)stimate tool so that effects of intensity thresholds on the mask can be viewed.\n');
      fprintf('\tUse Left Arrow/Right Arrow, '',''/''.'', or slider to change intensity threshold during hold.\n');
      fprintf('\tPress Enter/Return to end hold.\n');
      if isfield(obj.gui,'force_check')
        fprintf('Force Detect Checkbox:\n');
        fprintf('\tSlice Browser''s (D)etect tool is run on any changes made to ice mask from ice mask tool.\n');
      end
      fprintf('''t'' keyboard shortcut:\n');
      fprintf('\tWhen using (S)et tool toggle set value.\n');
      fprintf('''f'' keyboard shortcut:\n');
      fprintf('\tForces ice mask in ice mask tool on the slice data.\n');
      fprintf('\tUseful if slice data ice mask is not current with ice tool ice mask.\n');
    end
    
  end
  
end