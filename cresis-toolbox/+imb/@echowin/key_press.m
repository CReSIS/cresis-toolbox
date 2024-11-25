function key_press(obj,src,event)
% key_press(obj,src,event)
%
% Support function for mapwin class.
%
% KEY FUNCTIONS:
% -----------------------------------------------------------------------
% Space bar:
%   No mod:  cycles between all layers on or all layers off
%   Shift:   cycles between quality and regular coloring
%   Control: cycles between all layers on or only master layer on
% -----------------------------------------------------------------------
% ` (not-tilde):
%   No mod:  toggles point display and line display for all layers
%   Shift:   none
%   Control: none
% -----------------------------------------------------------------------

current_object = gco;
modifiers = get(event.Source,'CurrentModifier');
obj.shift_pressed = ismember('shift',   modifiers);  % true/false
obj.control_pressed  = ismember('control', modifiers);  % true/false
obj.alt_pressed   = ismember('alt',     modifiers);  % true/false

% Check to make sure that a key was pressed and not
% just a modifier (e.g. shift, ctrl, alt)
if ~isempty(event.Key) && ~strcmpi(event.Key,'shift') && ~strcmpi(event.Key,'alt') && ~strcmpi(event.Key,'control')
  
  % Switch layer number function (allows large numbers to be entered
  % as long as each number is entered within 0.5 seconds of the last
  % number).
  if length(event.Key) == 1 && event.Key >= '0' && event.Key <= '9'
    cur_time = now;
    done = false;
    if cur_time - obj.switch_layers.time < 1/86400
      % Accumulate event characters
      obj.switch_layers.accumulated_event_characters ...
        = [obj.switch_layers.accumulated_event_characters event.Key];
      desired_layer_num = str2double(obj.switch_layers.accumulated_event_characters);
      if desired_layer_num > 0 && desired_layer_num <= length(obj.eg.layers.lyr_id)
        done = true;
      end
    end
    if ~done
      % If the accumulated number does not exist OR no number was entered
      % in the last 0.5 seconds, then we start over.
      obj.switch_layers.accumulated_event_characters = event.Key;
      desired_layer_num = str2double(obj.switch_layers.accumulated_event_characters);
      if desired_layer_num > 0 && desired_layer_num <= length(obj.eg.layers.selected_layers)
        done = true;
      end
    end
    if done
      % If the number was valid, we update the selection
      if ~obj.shift_pressed
        obj.eg.layers.selected_layers(:)=false;
      end
      obj.eg.layers.selected_layers(desired_layer_num)=true;
      set(obj.left_panel.layerLB,'Value',find(obj.eg.layers.selected_layers));
      obj.set_visibility();
    end
    obj.switch_layers.time = cur_time;
  end
  
  
  % see event.Modifier for modifiers
  switch event.Key
    case 'f1'
      % Print out help for this window
      obj.status_text_set(sprintf('Printing help information to MATLAB console...'),'replace');
      fprintf('--------------------Echowin help--------------------\n\n');
      
      fprintf('Mouse controls:\n\n');
      fprintf('Always active regardless of mode:\n');
      fprintf('Mouse wheel scroll: Zooms in or out, centered at cursor position\n');
      fprintf('Ctrl + any click: Select closest layer and crossover\n');
      fprintf('Shift + any click: Set cursor\n');
      
      fprintf('Zoom mode active (press z to toggle zoom mode):\n');
      fprintf('Left click: Zoom in at point\n');
      fprintf('Left click and drag: select a region to zoom into\n');
      fprintf('Right click: Zoom out at point\n');
      fprintf('Double click: Full zoom out\n\n');
      
      fprintf('Tool mode active (zoom turned off):\n');
      fprintf('Left click: Appy tool to a point\n');
      fprintf('Right click and drag: Delete selected region\n');
      fprintf('Alt + Left click and drag: Apply tool to a region\n\n');
      tool_list = get(obj.left_panel.toolPM,'String');
      tool_idx = get(obj.left_panel.toolPM,'Value');
      fprintf('Currently selected tool (change in top left pulldown menu) is: %s\n',tool_list{tool_idx});
      fprintf('For this tool, the functions are...\n');
      switch tool_idx
        case 1 % interpolate
          fprintf('Left click: Enter point. Open param window (p) to set search range, enabling max point functionality (disabled by default)\n');
          fprintf('Alt + Left click and drag: Interpolate selected region. Change interpolate mode in param window (p)\n');
          fprintf('n.b. Leading edge tool (mentioned in param window) is not implemented. Leading edge and max track interpolation is not implemented\n\n');
        case 2 % quality
          fprintf('Left click: No function.\n');
          fprintf('Alt + Left click and drag: Change quality of layer points in selected region. Quality changes to the selection made in the quality pulldown menu in the left panel\n\n');
        case 3 % snake
          fprintf('Left click: Enter point. Open param window (p) to set search range, enabling max point functionality (enabled by default)\n');
          fprintf('Alt + Left click and drag: Snake selected region. Be sure ''basic'' mode is selected in the param window (p) pulldown menu\n');
          fprintf('n.b. Crandall tool (selectable in param window pulldown menu) is undocumented. Panton tool is not implemented\n\n');
        case 4 % browse
          fprintf('Left click: Open ascope window.\n');
          fprintf('Alt + Left click and drag: No function\n\n');
        case 5 % copy layers
          fprintf('Left click: No function\n');
          fprintf('Left click and drag: Copy layers from source layer specified in the param window (p) to the selected region of the selected layers\n\n');
         case 6 % HMM detection
          fprintf('Left click: Enter point.\n');
          fprintf('Left click and drag: Perform HMM detection on selected region.\n\n');
      end
      
      fprintf('Keyboard controls:\n\n');
      fprintf('F1: This help display\n');
      fprintf('0-9: Type a sequence of numbers to switch to that layer. See layers listbox in the left panel for numbering\n');
      fprintf('a: Select both surface and bottom layers\n');
      fprintf('b: Switch to [b]rowse tool\n');
      fprintf('c: Switch to [c]onvert layers tool\n');
      fprintf('ctrl-c: Copy status bar to clipboard\n');
      fprintf('shift-c: Toggle crossover visibility (load cross overs for the first time)\n');
      fprintf('e: Switch to interpolate tool\n');
      fprintf('f: [F]lip the horizontal axis direction\n');
      fprintf('i: Switch to [i]nterpolate tool\n');
      fprintf('p: Open [p]aram window for current tool. Press p again with the window selected to close it\n');
      fprintf('q: Switch to [q]uality tool\n');
      fprintf('Shift+q: Change currently selected [q]uality (cycles between good, moderate, derived\n');
      fprintf('r: [R]edo last operation\n');
      fprintf('s: Switch to [s]nake tool\n');
      fprintf('Ctrl+s: Save [s]creenshot of current echowin (BETA)\n');
      fprintf('Shift+s: [S]ave layers\n');      
      fprintf('u: [U]ndo last operation\n');      
      fprintf('z: Enable [z]oom mode\n');
      fprintf('Ctrl+z: [Z]oom all the way out\n');
      fprintf('`: Toggle between points between using dots and dots/lines\n');
      fprintf('shift-` (~): Toggle between manual points being displayed or hidden\n');
      fprintf('Spacebar: Toggle between all layers visible and no layers visible\n');
      fprintf('Ctrl+Spacebar: Toggle between all layers visible and only currently selected layer visible\n');
      fprintf('Shift+Spacebar: Enable or disable quality display mode\n');
      fprintf('Up: Pan view field up\n');
      fprintf('Left: Pan view field left. If at left edge of frame, advance to previous frame\n');
      fprintf('Down: Pan view field down\n');
      fprintf('Right: Pan view field right. If at right edge of frame, advance to next frame\n\n\n');
      
      fprintf('Layers listbox info:\n\n');
      fprintf('The layers listbox is located in the left panel below the picker push button controls.\n');
      fprintf('The first column in the layers listbox controls visibility for each layer listed.\n');
      fprintf('The second column controls which layer is currently selected for edits.\n');
      fprintf('Normally only one layer can be selected at a time, but both surface and bottom can be selected at once, too.\n');
      fprintf('These button controls synchronize with other key and mouse controls that change layer selection and visibility.\n\n');
      
      fprintf('https://wiki.cresis.ku.edu/cresis/Data_Picking_Tutorial\n');
      
      
    case 8 % Backspace
    case 127 % Delete
      
    case 'backquote' % Toggle display of manual points
      if any(strcmp('shift',event.Modifier))
        obj.eg.layers.show_manual_pts = ~obj.eg.layers.show_manual_pts;
        obj.status_text_set(sprintf('Toggling manual point visibility'),'replace');
        obj.set_visibility();
      else
        obj.eg.layers.show_dots_only = ~obj.eg.layers.show_dots_only;
        obj.status_text_set(sprintf('Toggling dots/lines and dots'),'replace');
        obj.set_visibility();
      end
      
    case 'a'
      obj.eg.layers.selected_layers = obj.eg.layers.visible_layers;
      set(obj.left_panel.layerLB,'Value',find(obj.eg.layers.selected_layers));
      obj.set_visibility();
      
    case 'b'
      set(obj.left_panel.toolPM,'Value',7);
      tmp = obj.tool.list{7}; obj.tool.left_click_fh = @tmp.left_click;
      tmp = obj.tool.list{7}; obj.tool.left_click_and_drag_fh = @tmp.left_click_and_drag;
      tmp = obj.tool.list{7}; obj.tool.right_click_fh = @tmp.right_click;
      tmp = obj.tool.list{7}; obj.tool.right_click_and_drag_fh = @tmp.right_click_and_drag;
      obj.toolPM_callback();      
      
    case 'c'
      if any(strcmp('control',event.Modifier))
        obj.status_text_copy_callback();
      elseif any(strcmp('shift',event.Modifier))
        if ~obj.crossovers.en && strcmp(obj.eg.layers.source,'OPS')
          % Cross overs can only be enabled when using OPS layer data
          obj.crossovers.en = true;
          obj.load_crossovers();
        end
        % enable or disable crossovers
        obj.crossovers.gui.visibility_toggle();
      else
        % copy layer tool hotkey
        set(obj.left_panel.toolPM,'Value',4);
        tmp = obj.tool.list{4}; obj.tool.left_click_fh = @tmp.left_click;
        tmp = obj.tool.list{4}; obj.tool.left_click_and_drag_fh = @tmp.left_click_and_drag;
        tmp = obj.tool.list{4}; obj.tool.right_click_fh = @tmp.right_click;
        tmp = obj.tool.list{4}; obj.tool.right_click_and_drag_fh = @tmp.right_click_and_drag;
        obj.toolPM_callback();      
      end
      
    case 'e'
      set(obj.left_panel.toolPM,'Value',1);
      tmp = obj.tool.list{1}; obj.tool.left_click_fh = @tmp.left_click;
      tmp = obj.tool.list{1}; obj.tool.left_click_and_drag_fh = @tmp.left_click_and_drag;
      tmp = obj.tool.list{1}; obj.tool.right_click_fh = @tmp.right_click;
      tmp = obj.tool.list{1}; obj.tool.right_click_and_drag_fh = @tmp.right_click_and_drag;
      obj.toolPM_callback();      
      
    case 'f'
      %% Flip the horizontal axis
      if strcmpi(get(obj.h_axes,'XDir'),'normal')
        set(obj.h_axes,'XDir','reverse');
      else
        set(obj.h_axes,'XDir','normal');
      end
      
    case 'i'
      set(obj.left_panel.toolPM,'Value',1);
      tmp = obj.tool.list{1}; obj.tool.left_click_fh = @tmp.left_click;
      tmp = obj.tool.list{1}; obj.tool.left_click_and_drag_fh = @tmp.left_click_and_drag;
      tmp = obj.tool.list{1}; obj.tool.right_click_fh = @tmp.right_click;
      tmp = obj.tool.list{1}; obj.tool.right_click_and_drag_fh = @tmp.right_click_and_drag;
      obj.toolPM_callback();
      
    case 'p'
      %% Toggle param window
      obj.paramPB_callback([],[]);
      
    case 'q'
      if isempty(event.Modifier)
        set(obj.left_panel.toolPM,'Value',5);
        tmp = obj.tool.list{5}; obj.tool.left_click_fh = @tmp.left_click;
        tmp = obj.tool.list{5}; obj.tool.left_click_and_drag_fh = @tmp.left_click_and_drag;
        tmp = obj.tool.list{5}; obj.tool.right_click_fh = @tmp.right_click;
        tmp = obj.tool.list{5}; obj.tool.right_click_and_drag_fh = @tmp.right_click_and_drag;
        obj.toolPM_callback();
      elseif obj.shift_pressed && ~obj.alt_pressed && ~obj.control_pressed
        new_quality = 1+mod(get(obj.left_panel.qualityPM,'Value'), ...
          length(get(obj.left_panel.qualityPM,'String')));
        set(obj.left_panel.qualityPM,'Value',new_quality);
      end
      
    case 'r'
      %% Redo last tool operation
      obj.undo_stack.redo();
      
    case 's'
      if isempty(event.Modifier)
        set(obj.left_panel.toolPM,'Value',3);
        tmp = obj.tool.list{3}; obj.tool.left_click_fh = @tmp.left_click;
        tmp = obj.tool.list{3}; obj.tool.left_click_and_drag_fh = @tmp.left_click_and_drag;
        tmp = obj.tool.list{3}; obj.tool.right_click_fh = @tmp.right_click;
        tmp = obj.tool.list{3}; obj.tool.right_click_and_drag_fh = @tmp.right_click_and_drag;
        obj.toolPM_callback();
        
      elseif ~obj.shift_pressed && ~obj.alt_pressed && obj.control_pressed
        %% Save screenshot of current echowin
        if ~exist('gRadar','var')
          global gRadar;
        end        
        if ~exist(sprintf('%spicker_screenshots/',gRadar.path_override),'dir')
          mkdir(sprintf('%spicker_screenshots/',gRadar.path_override));
        end
        fn = sprintf('%spicker_screenshots/%s_%s_%s_%s_%s.png',...
          gRadar.path_override,datestr(now,'yyyymmdd_HHMMSS'),...
          obj.eg.cur_sel.radar_name,...
          obj.eg.cur_sel.season_name,obj.eg.cur_sel.day_seg,...
          num2str([obj.eg.frms(1) obj.eg.frms(end)],'%d-%d'));
        obj.status_text_set(sprintf('Saving screenshot %s',fn),'replace');
        fprintf('Saving screenshot %s\n',fn);
        set(obj.h_fig,'paperpositionmode','auto');
        print('-dpng',sprintf('-f%d',obj.h_fig.Number),fn);
      elseif obj.shift_pressed && ~obj.alt_pressed && ~obj.control_pressed
        %% Save current layers
        obj.savePB_callback();
      end
      
    case 't'
      set(obj.left_panel.toolPM,'Value',6);
      tmp = obj.tool.list{6}; obj.tool.left_click_fh = @tmp.left_click;
      tmp = obj.tool.list{6}; obj.tool.left_click_and_drag_fh = @tmp.left_click_and_drag;
      tmp = obj.tool.list{6}; obj.tool.right_click_fh = @tmp.right_click;
      tmp = obj.tool.list{6}; obj.tool.right_click_and_drag_fh = @tmp.right_click_and_drag;
      obj.toolPM_callback();
      
    case 'v'
      set(obj.left_panel.toolPM,'Value',2);
      tmp = obj.tool.list{2}; obj.tool.left_click_fh = @tmp.left_click;
      tmp = obj.tool.list{2}; obj.tool.left_click_and_drag_fh = @tmp.left_click_and_drag;
      tmp = obj.tool.list{2}; obj.tool.right_click_fh = @tmp.right_click;
      tmp = obj.tool.list{2}; obj.tool.right_click_and_drag_fh = @tmp.right_click_and_drag;
      obj.toolPM_callback();
      
    case 'u'
      %% Undo last tool operation
      obj.undo_stack.pop();
      
    case 'z'
      if obj.control_pressed
        %% Zoom reset
        obj.redraw(-inf,inf,-inf,inf,struct('clipped',true));
      else
        %% Toggle Zoom mode
        obj.status_text_set(sprintf('Toggling zoom mode'),'replace');
        obj.zoom_mode = ~obj.zoom_mode;
        if obj.zoom_mode
          set(obj.h_fig,'Pointer','custom');
        else
          set(obj.h_fig,'Pointer','Arrow');
        end
      end
      
    case 'space'
      % Space bar cycles between "currently visible layers on" and "all
      %   layers off"
      % Shift-space bar cycles between quality and regular coloring
      %   Toggles obj.eg.layers.quality_en
      % Ctrl-Space bar cycles between "currently visible layers on" and "all
      %   layers on"
      if obj.shift_pressed
        % Toggle visibility of quality layers
        obj.eg.layers.quality_en = ~obj.eg.layers.quality_en;
      elseif obj.control_pressed
        % Toggle visibility between "currently visible layers on" and "all
        % layers on"
        if ~all(obj.eg.layers.visible_layers)
          % Save this visibility state for later
          obj.tool.old_visibility = obj.eg.layers.visible_layers;
          % Since not all layers are on, turn them all on
          obj.eg.layers.visible_layers(:) = 1;
        else
          if isfield(obj.tool,'old_visibility') ...
              && length(obj.tool.old_visibility) == length(obj.eg.layers.visible_layers)
            % If an old state exists, then just turn these layers on
            obj.eg.layers.visible_layers = obj.tool.old_visibility;
          else
            % Otherwise... just turn them all off
            obj.eg.layers.visible_layers(:) = 0;
          end
        end
      else
        % Toggle visibility between "currently visible layers on" and "all
        % layers off"
        if any(obj.eg.layers.visible_layers)
          % Save this visibility state for later
          obj.tool.old_visibility = obj.eg.layers.visible_layers;
          % Since some layers are on, turn them all off
          obj.eg.layers.visible_layers(:) = 0;
        else
          if isfield(obj.tool,'old_visibility') ...
              && length(obj.tool.old_visibility) == length(obj.eg.layers.visible_layers)
            % If an old state exists, then just turn these layers on
            obj.eg.layers.visible_layers = obj.tool.old_visibility;
          else
            % Otherwise... just turn them all back on
            obj.eg.layers.visible_layers(:) = 1;
          end
        end
      end
      obj.layerLB_str(true);
      obj.set_visibility();
      
    case 'downarrow' % Down-arrow: Move Echogram Down
      if ~isempty(current_object) && (current_object == obj.left_panel.layerLB || current_object == obj.left_panel.sourceLB)
        return
      end
      % check if echogram is selected
      cur_axis = [get(obj.h_axes,'Xlim') ...
        get(obj.h_axes,'YLim')];
      y_extent = cur_axis(4) - cur_axis(3);
      if strcmp(obj.eg.y_order,'reverse')
        cur_axis(3:4) = cur_axis(3:4) + y_extent*0.25;
      elseif strcmp(obj.eg.y_order,'normal')
        cur_axis(3:4) = cur_axis(3:4) - y_extent*0.25;
      end
      
      % Convert x_min, x_max to GPS time
      xlims = interp1(obj.eg.image_xaxis,obj.eg.image_gps_time,cur_axis(1:2),'linear','extrap');
      
      % Draw data with new axis, but do not allow new data to be loaded (i.e.
      % clip new axis to limits of loaded data
      obj.redraw(xlims(1),xlims(2),cur_axis(3),cur_axis(4),struct('clipped',true,'ylim_force',obj.shift_pressed));
      
      button_motion(obj);
      
    case 'uparrow' % Up-arrow: Move Echogram Up
      if ~isempty(current_object) && (current_object == obj.left_panel.layerLB || current_object == obj.left_panel.sourceLB)
        return
      end
      % check if echogram is selected
      cur_axis = [get(obj.h_axes,'Xlim') ...
        get(obj.h_axes,'YLim')];
      y_extent = cur_axis(4) - cur_axis(3);
      if strcmp(obj.eg.y_order,'reverse')
        cur_axis(3:4) = cur_axis(3:4) - y_extent*0.25;
      elseif strcmp(obj.eg.y_order,'normal')
        cur_axis(3:4) = cur_axis(3:4) + y_extent*0.25;
      end
      
      % Convert x_min, x_max to GPS time
      xlims = interp1(obj.eg.image_xaxis,obj.eg.image_gps_time,cur_axis(1:2),'linear','extrap');
      
      % Draw data with new axis, but do not allow new data to be loaded (i.e.
      % clip new axis to limits of loaded data
      obj.redraw(xlims(1),xlims(2),cur_axis(3),cur_axis(4),struct('clipped',true,'ylim_force',obj.shift_pressed));
      
      button_motion(obj);
      
    case 'rightarrow' % Right arrow
      cur_axis = [get(obj.h_axes,'Xlim') ...
        get(obj.h_axes,'YLim')];
      
      xlims_orig = interp1(obj.eg.image_xaxis,obj.eg.image_gps_time,cur_axis(1:2),'linear','extrap');
      x_extent = cur_axis(2) - cur_axis(1);
      cur_axis(1:2) = cur_axis(1:2) + x_extent*0.25;
      
      % Convert x_min, x_max to GPS time
      xlims = interp1(obj.eg.image_xaxis,obj.eg.image_gps_time,cur_axis(1:2),'linear','extrap');
      if xlims(2) > obj.eg.stop_gps_time(end)
        xlims = obj.eg.stop_gps_time(end) + [-diff(xlims_orig) 0];
      end
      
      % Draw data with new axis
      obj.redraw(xlims(1),xlims(2),cur_axis(3),cur_axis(4),struct('clipped',false,'ylim_force',obj.shift_pressed));
      
      button_motion(obj);
      
    case 'leftarrow' % Left arrow
      cur_axis = [get(obj.h_axes,'Xlim') ...
        get(obj.h_axes,'YLim')];
      
      x_extent = cur_axis(2) - cur_axis(1);
      xlims_orig = interp1(obj.eg.image_xaxis,obj.eg.image_gps_time,cur_axis(1:2),'linear','extrap');
      
      cur_axis(1:2) = cur_axis(1:2) - x_extent*0.25;
      % Convert x_min, x_max to GPS time
      xlims = interp1(obj.eg.image_xaxis,obj.eg.image_gps_time,cur_axis(1:2),'linear','extrap');
      if xlims(1) < obj.eg.start_gps_time(1)
        xlims = obj.eg.start_gps_time(1) + [0 diff(xlims_orig)];
      end
      
      % Draw data with new axis
      obj.redraw(xlims(1),xlims(2),cur_axis(3),cur_axis(4),struct('clipped',false,'ylim_force',obj.shift_pressed));
      
      button_motion(obj);
      
  end
end
