classdef (HandleCompatible = true) slicetool_icemask < imb.slicetool
  
  properties
    ice
    cmd
    sb
    ice_mask_layer
    detect_flag
  end
  
  properties (SetAccess = protected, GetAccess = protected)
  end
  
  events
    IceChange
  end
  
  methods
    function obj = slicetool_icemask()
      obj.create_option_ui();
      obj.tool_name = 'Ice Mask';
      obj.tool_menu_name = 'Mask Editor';
      obj.tool_shortcut = '';
      obj.ctrl_pressed = 0;
      obj.shift_pressed = 0;
      obj.help_string = '';
      
      obj.detect_flag = 1;
    end
    
    function delete(obj)
      try; delete(obj.ice); end;
    end

    function set_custom_data(obj,custom_data)
      param.mdata.twtt = custom_data.mdata.twtt;
      if isfield(custom_data.mdata.Tomo,'theta_cal') && ~isempty(custom_data.mdata.Tomo.theta_cal)
        param.mdata.theta = custom_data.mdata.Tomo.theta_cal;
      else
        param.mdata.theta = custom_data.mdata.Tomo.theta;
      end
      param.mdata.ice_mask = custom_data.mdata.ice_mask;
      param.mdata.param_array = custom_data.mdata.param_array;
%       rmfield(param,'mdata');
      param.DEM = custom_data.DEM;
      param.R = custom_data.R;
      param.ice_mask_fn = custom_data.ice_mask_fn;
      param.ice_mask = custom_data.ice_mask;
      param.proj = custom_data.proj;
      obj.sb = custom_data.sb;
      obj.ice_mask_layer = custom_data.ice_mask_layer;
      addlistener(obj.sb,'SliceChange',@obj.runChangeSlice);
      addlistener(obj.sb,'SliceChange',@obj.sb_button_motion_cb);
      addlistener(obj.sb.undo_stack,'synchronize_event',@obj.run_undo_sync);
      obj.save_callback = @obj.save;
      
      obj.ice = imb.ice_mask_edit(param);
      addlistener(obj.ice,'IceChange',@obj.run_ice_change);
      addlistener(obj.ice,'SliceChange',@obj.run_slice_change);
      addlistener(obj.ice,'Undo',@obj.run_sb_undo);
      addlistener(obj.ice,'Redo',@obj.run_sb_redo);
      
      obj.ice.local_undo_flag = 0;
      obj.sb.fh_button_motion = @obj.sb_button_motion_cb;
      obj.ice.h_intersect_dem_fig = plot(NaN,NaN,'kx','Parent',obj.ice.h_dem_axes,'LineWidth',2,'MarkerSize',10);
      obj.ice.h_intersect_mask_fig = plot(NaN,NaN,'kx','Parent',obj.ice.h_mask_axes,'LineWidth',2,'MarkerSize',10);
      
      if custom_data.reduce_flag
        obj.ice.reduce_flag = 1;
        obj.ice.reduce_DEM();
      end
      
      % Additional ice_mask_edit UI
      obj.ice.gui.force_check= uicontrol('parent',obj.ice.gui.left_panel);
      set(obj.ice.gui.force_check,'style','checkbox')
      set(obj.ice.gui.force_check,'string','Force Detect')
      set(obj.ice.gui.force_check,'Callback',@obj.toggle_detect_flag)
      set(obj.ice.gui.force_check,'Units','Points');
      pos = get(obj.ice.gui.hold_CB,'Position');
      pos(2) = pos(2) - pos(4);
      set(obj.ice.gui.force_check,'Position',pos);
      set(obj.ice.gui.force_check,'Value',obj.detect_flag);
      
    end
    
    function cmd = apply_PB_callback(obj,sb,slices)
      % sb: slice browser object. Use the following fields to create
      %     commands, cmd, that use sb.data to operate on sb.sd. You 
      %     should not modify any fields of sb.
      %  .sd: surfdata .surf struct array containing surface information
      %  .data: 3D image
      %  .slice: current slice in 3D image (third index of .data)
      %  .surf_idx: active surface
      % slices: array of slices to operate on (overrides sb.slice)
      figure(obj.ice.h_mask_fig);
      figure(obj.ice.h_dem_fig);
      cmd = [];
    end
    
    function create_option_ui(obj)
    end
    
    function add_listener(obj,src)
      addlistener(src,'SliceChange',@obj.runChangeSlice);
      addlistener(src.undo_stack,'synchronize_event',@obj.run_undo_sync);
    end
    
    function evnts = get_events(obj)
      evnts.src = obj;
      evnts.evnts{1} = 'IceChange';
    end
    
    % Impose Slice Change from SliceBrowser --> IceEditor
    function runChangeSlice(obj,src,~)
      obj.ice.change_slice(src.slice);
    end
    
    function cmd = overlay_intersects(obj,cmd)
      
      thetas = [];
      slices = [];
      vals = [];
      val_olds = [];
      cmd_op_idxs = [];
      % get theta and slice idxs for changes
      for cmd_idx = 1:length(cmd)
        if strcmp(cmd{cmd_idx}.type,'standard') && ...
            cmd{cmd_idx}.redo.surf == obj.sb.sd.surf(cmd{cmd_idx}.redo.surf).mask
          thetas = [thetas , cmd{cmd_idx}.redo.x];
          slices = [slices , cmd{cmd_idx}.redo.slice];
          vals = [vals , cmd{cmd_idx}.redo.y];
          val_olds = [val_olds , cmd{cmd_idx}.undo.y];
          cmd_op_idxs = [cmd_op_idxs , cmd_idx];
        end
      end

      if isempty(thetas)
        return
      end

      cmd_ice = obj.ice.edit_twtt(thetas,slices,vals,val_olds);
      cmd_append = obj.form_sb_cmd(cmd_ice,cmd{1}.redo.surf);
      
      if 0
        % When an ice mask command from the slice browser is run, it can
        % cause a pixel to change in the ice mask editor which will cause a
        % another command in the slice browser to happen that is at least
        % partially redundant. This is okay and has no effect. This code
        % was originally written to remove these partially redundant
        % commands.
        del_cmd_idx = [];
        for i = 1:length(cmd_append)
          if strcmp(cmd_append{i}.type,'standard') ...
              && ismember(cmd_append{i}.redo.slice,slices)
            cmd{cmd_append{i}.redo.slice==slices} = cmd_append{i};
            del_cmd_idx = [del_cmd_idx,i];
          end
        end
        cmd_append(del_cmd_idx) = [];
      end
      
      cmd = [cmd,cmd_append];
    end 
    
    
    function cmd = push_request(obj,cmd)
      cmd_ice = {};
      for cmd_idx = 1:length(cmd)
        if strcmp(cmd{cmd_idx}.type,'ice_mask')
          return;
        end
      end
      
      if isempty(cmd_ice)
        for cmd_idx = 1:length(cmd)
          if strcmp(cmd{cmd_idx}.type,'standard') ...
              && ~isempty(obj.sb.sd.surf(cmd{cmd_idx}.redo.surf).mask) ...
              && cmd{cmd_idx}.redo.surf == obj.sb.sd.surf(cmd{cmd_idx}.redo.surf).mask            
            
              cmd = obj.overlay_intersects(cmd);
              return
          end
        end
      end
      
    end
    
    
    function run_undo_sync(obj,src,~)
      obj.ice.undo_sync(src,[]);
    end
    
    
    function cmd = form_sb_cmd(obj,cmd,layer)
      
      for i = 1:length(cmd)
        if strcmp(cmd{i}.type,'ice_mask')
          ice_cmd_idx = i;
        end
      end
      
      if isempty(cmd{1}.redo.data_mask_idx)
        return;
      end
      
      [theta_idx,slice_idx] = ind2sub([size(obj.ice.intersections,2),size(obj.ice.intersections,3)],cmd{1}.redo.data_mask_idx);
      unique_slices = unique(slice_idx);
      
      for s = 1:length(unique_slices)
        slice = unique_slices(s);
        
        cmd_idx = length(cmd)+1;
        
        s_idx = find(slice_idx==slice);
        theta = theta_idx(s_idx);
%           ind = sub2ind([size(obj.intersections,2),size(obj.intersections,3)],theta,s_idx);

        cmd{cmd_idx}.undo.surf = layer;
        cmd{cmd_idx}.redo.surf = layer;
        cmd{cmd_idx}.undo.x = theta;
        cmd{cmd_idx}.redo.x = theta;
        cmd{cmd_idx}.undo.y = obj.sb.sd.surf(layer).y(theta,slice);
        cmd{cmd_idx}.redo.y = logical(cmd{1}.redo.data_mask(s_idx));
        cmd{cmd_idx}.undo.slice = slice;
        cmd{cmd_idx}.redo.slice = slice;
        cmd{cmd_idx}.type = 'standard';
      end
      
      slice_prev = obj.sb.slice;
      if 0 && obj.detect_flag
        for tool_idx = 1:length(obj.sb.slice_tool.list)
          if isa(obj.sb.slice_tool.list{tool_idx},'imb.slicetool_detect')
            for slice_idx = 1:length(unique_slices)
              slice = unique_slices(slice_idx);
              obj.sb.slice = slice;
              obj.sb.surf_idx = obj.sb.sd.surf(layer).active;
              mask_prev = obj.sb.sd.surf(obj.sb.sd.surf(obj.sb.surf_idx).mask).y(:,slice);
              for cmd_idx = 1:length(cmd)
                if isfield(cmd{cmd_idx}.redo,'slice') && cmd{cmd_idx}.redo.slice == slice
                  break;
                end
              end
              obj.sb.sd.surf(obj.sb.sd.surf(obj.sb.surf_idx).mask).y( ...
                cmd{cmd_idx}.redo.x,slice) = cmd{cmd_idx}.redo.y;
              cmd(end+1) = obj.sb.slice_tool.list{tool_idx}.apply_PB_callback(obj.sb);
              obj.sb.sd.surf(obj.sb.sd.surf(obj.sb.surf_idx).mask).y(:,slice) = mask_prev;
            end
            break
          end
        end
      end
      
      cmd{end+1}.redo.slice = slice_prev;
      cmd{end}.undo.slice = slice_prev;
      cmd{end}.type = 'slice_dummy';
        
    end
    
    
    function run_ice_change(obj,cmd,~)
      cmd = obj.form_sb_cmd(obj.ice.cmd,obj.ice_mask_layer);
      obj.sb.push(cmd);
    end
    
    
    % Impose Slice Change from IceEditor --> SliceBrowser
    function run_slice_change(obj,src,~)
      obj.sb.change_slice(src.slice, false)
    end
    
    
    function run_sb_redo(obj,src,~)
      obj.sb.undo_stack.redo();
    end
    
    
    function run_sb_undo(obj,src,~)
      obj.sb.undo_stack.pop();
    end
    
    function save(obj)
      obj.ice.save();
    end
    
    function toggle_detect_flag(obj,src,~)
      val = get(src,'Value');
      if val
        obj.detect_flag = 1;
      else
        obj.detect_flag = 0;
      end
    end
    
    function status = sb_button_motion_cb(obj,sb,~,~)
      if ~isempty(obj.ice.intersections)
        [x,y,~] = get_mouse_info(sb.h_fig,sb.h_axes);
        theta = round(x);
        slice = sb.slice;
        if theta > 0 && theta <= size(obj.ice.intersections,2) ...
            && y <= size(obj.sb.data,1) && y > 0 
          set(obj.ice.h_intersect_dem_fig,'XData',obj.ice.intersections(1,theta,slice)/1e3, ...
            'YData',obj.ice.intersections(2,theta,slice)/1e3);
          set(obj.ice.h_intersect_mask_fig,'XData',obj.ice.intersections(1,theta,slice)/1e3, ...
            'YData',obj.ice.intersections(2,theta,slice)/1e3);
        else
          set(obj.ice.h_intersect_dem_fig,'XData',NaN,'YData',NaN);
          set(obj.ice.h_intersect_mask_fig,'XData',NaN,'YData',NaN);
        end
      end
      status = 1;
    end
    
  end
  
end