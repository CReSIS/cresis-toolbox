function key_press(obj,src,event)
% mapwin.key_press(obj,src,event)
%
% Support function for mapwin class.

if strcmpi(get(obj.map_panel.h_axes,'Visible'),'off')
  return;
end
current_object = gco;
modifiers = get(event.Source,'CurrentModifier');
obj.shift_pressed = ismember('shift',   modifiers);  % true/false
obj.control_pressed  = ismember('control', modifiers);  % true/false
obj.alt_pressed   = ismember('alt',     modifiers);  % true/false

% Check to make sure that a key was pressed and not
% just a modifier (e.g. shift, ctrl, alt)
if ~isempty(event.Key)
  
  if ~isempty(obj.cur_map_pref_settings.map_name)
    
    yaxis = get(obj.map_panel.h_axes,'YLim');
    % get updated y axis
    y_extent = diff(yaxis);
    xaxis = get(obj.map_panel.h_axes,'XLim');
    % get updated x axis
    x_extent = diff(xaxis);
    
    % see event.Modifier for modifiers
    switch event.Key
      case 'f1'
        % Print out help for this window
        fprintf('--------------------Mapwin help--------------------\n\n');
        
        fprintf('Mouse controls:\n\n');
        
        fprintf('Zoom Mode:\n');
        fprintf('Left click: Zoom in\n');
        fprintf('Left click and drag: Zoom into selection\n');
        fprintf('Right click: Zoom out\n');
        fprintf('Double click: Full zoom out\n');
        fprintf('Select Mode:\n');
        fprintf('Left click: Select closest frame\n');
        fprintf('Double click: Open currently selected frame\n');
        fprintf('All Modes:\n');
        fprintf('Shift + any click: Place a marker in each active selection at the closest point to your click\n');
        fprintf('Ctrl + any click: Select closest frame\n\n');
        
        fprintf('Keyboard controls:\n\n');
        fprintf('F1: This help display\n');
        fprintf('o: Open currently selected frame\n');
        fprintf('s: Make the frame search textbox active and highlight text. You can start typing straight away to clear the default string or previous searches.\n');
        fprintf('z: Toggle zoom mode\n');
        fprintf('ctrl-z: Full zoom out\n');
        fprintf('Up: Pan map up\n');
        fprintf('Down: Pan map down\n');
        fprintf('Left: Pan map left\n');
        fprintf('Right: Pan map right\n\n');
        
        fprintf('Frame search function:\n\n');
        fprintf('Type in the listbox on the left of the top toolbar to search for a frame.\n');
        fprintf('You can enter a date (YYYYMMDD), a day/seg combo (YYYYMMDD_##), or a day/seg/frame (YYYYMMDD_##_###) combo.\n');
        fprintf('If you enter a date, the search returns the first segment and the first frame for that date.\n');
        fprintf('If you enter a day/seg combo, the search returns the first frame for that day/seg combo.\n');
        fprintf('If you enter a day/seg/frame combo, the search will return exactly what you enter.\n');
        fprintf('A warning is issued if your search produces no results.\n\n');
        
        fprintf('Other notes:\n');
        fprintf('To view an echogram, select it with ctrl+click, then click the load button in the top right\n');
        fprintf('Open multiple pick windows by changing the pulldown menu in the toolbar to "New Window", then loading a frame\n\n');
        
        fprintf('https://wiki.cresis.ku.edu/cresis/Data_Picking_Tutorial\n');
      
      case 8 % Backspace
      case 127 % Delete
        
      case 'o'
        % open the currently selected frame
        obj.loadPB_callback;
        
      case 's'
        % highlight the search box string
        uicontrol(obj.top_panel.searchTB);
        
      case 'downarrow' % Down arrow
        % move plot down
        
        % break if already at the limit
        %if check_limits(obj,xaxis,yaxis,'d')
          %break;
        %else
          new_yaxis = [yaxis(1) - y_extent*0.4, yaxis(end) - y_extent*0.4];
          
          %if new_yaxis(1) < obj.map.yaxis_default(1)
          %  new_yaxis(1) = obj.map.yaxis_default(1);
          %  new_yaxis(end) = new_yaxis(1) + y_extent;
          %end
          
          % get a new map for these limits
          new_yaxis = sort(new_yaxis);
          % don't change the x limits in this case
          new_xaxis = obj.map.xaxis;
          obj.query_redraw_map(new_xaxis(1),new_xaxis(end),...
            new_yaxis(1),new_yaxis(end));
        %end
        
      case 'uparrow' % Up arrow
        % move plot up
        %yaxis = get(gca,'YLim');
        % get updated y axis
        %y_extent = diff(yaxis);
        
        % break if already at the limit
        %if check_limits(obj,xaxis,yaxis,'u')
        %else
          new_yaxis = [yaxis(1) + y_extent*0.4, yaxis(end) + y_extent*0.4];
          %if new_yaxis(end) > obj.map.yaxis_default(end)
          %  new_yaxis(end) = obj.map.yaxis_default(end);
          %  new_yaxis(1) = new_yaxis(end) - y_extent;
          %end
          
          % get a new map for these limits
          new_yaxis = sort(new_yaxis);
          % don't change the x limits in this case
          new_xaxis = obj.map.xaxis;
          obj.query_redraw_map(new_xaxis(1),new_xaxis(end),...
            new_yaxis(1),new_yaxis(end));
        %end
        
      case 'rightarrow' % Right arrow
        % move plot right
        if current_object == obj.top_panel.searchTB
          return;
        end
        
        % break if already at the limit
        %if check_limits(obj,xaxis,yaxis,'r')          %break;
        %else
          new_xaxis = [xaxis(1) + x_extent*0.4, xaxis(end) + x_extent*0.4];
          %if new_xaxis(end) > obj.map.xaxis_default(end)
          %  new_xaxis(end) = obj.map.xaxis_default(end);
          %  new_xaxis(1) = new_xaxis(end) - x_extent;
          %end
          
          % get a new map for these limits
          new_xaxis = sort(new_xaxis);
          % don't change the y limits in this case
          new_yaxis = obj.map.yaxis;
          obj.query_redraw_map(new_xaxis(1),new_xaxis(end),...
            new_yaxis(1),new_yaxis(end));
        %end
        
      case 'leftarrow' % Left arrow
        % move plot left
        if current_object == obj.top_panel.searchTB
          return;
        end
        
        % break if already at the limit
        %if check_limits(obj,xaxis,yaxis,'l')
          %break;
        %else
          new_xaxis = [xaxis(1) - x_extent*0.4, xaxis(end) - x_extent*0.4];
          %if new_xaxis(1) < obj.map.xaxis_default(1)
          %  new_xaxis(1) = obj.map.xaxis_default(1);
          %  new_xaxis(end) = new_xaxis(1) + x_extent;
          %end
          
          % get a new map for these limits
          new_xaxis = sort(new_xaxis);
          % don't change the y limits in this case
          new_yaxis = obj.map.yaxis;
          obj.query_redraw_map(new_xaxis(1),new_xaxis(end),...
            new_yaxis(1),new_yaxis(end));
        %end
        
      case 'z'
        if obj.control_pressed
          %% Zoom reset
          % ===================================================================
          % Double click: Zoom reset
          % Ctrl + double click: Select closest frame and load
          
          new_yaxis(1) = obj.map.yaxis_default(1);
          new_yaxis(2) = obj.map.yaxis_default(end);
          new_xaxis(1) = obj.map.xaxis_default(1);
          new_xaxis(2) = obj.map.yaxis_default(end);
          
          % get a new map for these limits
          obj.query_redraw_map(new_xaxis(1),new_xaxis(end),new_yaxis(1),new_yaxis(end));
        else
          %% Toggle Zoom mode
          obj.zoom_mode = ~obj.zoom_mode;
          if obj.zoom_mode
            set(obj.h_fig,'Pointer','custom');
          else
            set(obj.h_fig,'Pointer','Arrow');
          end
        end
      
    end
  end
end

return;


% % This code is for debugging
% if ischar(event.Key)
%   fprintf('x = %.2f, y = %.2f, key = %s %d\n', x, y, event.Key, event.Character);
% else
%   fprintf('x = %.2f, y = %.2f, key = %d %d\n', x, y, event.Key, event.Character);
% end
% if ~isempty(event.Modifier)
%   fprintf('  Modifiers ');
%   for ind = 1:length(event.Modifier)
%     fprintf('%s ', event.Modifier{ind});
%   end
%   fprintf('\n');
% end
