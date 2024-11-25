classdef picktool_interpolate < imb.picktool
  % Enter points pick tool
  %
  % Left click: Enters a point based on parameters
  %   Find max in range (specify range line/bin extent to search)
  %   Find leading edge in range
  %   Recomputes interp if point is within last interpolation range
  % Left click and drag: Interpolates between manual points based on paramaters
  %   Deletes all previous automated points in range
  %   Interpolation tools: linear, spline, max-track, leading-edge-track
  % Right click: Set cursor point
  % Right click and drag: Delete all points in range
  % Scroll: Zooms in/out
  % Ctrl + any click: Select layer
  % Ctrl + any click and drag: Zoom
  % Any double click: Nothing
  % Ctrl + double click: Zoom reset
  %
  properties
    table
    panel
    % panel components
    max_rbin_rng_label
    max_rbin_rng_tbox
    leading_edge_thresh_label
    leading_edge_thresh_tbox
    interp_mode_label
    interp_mode_pdmenu
    reinterp_mode_label
    reinterp_mode_cbox
    
    last_tool
    last_layers
    last_range_gps
  end
  
  properties (SetAccess = immutable, GetAccess = public) %constants
    w       % window's width
    h       % window's height
  end
  
  methods
    function obj = picktool_interpolate(h_fig)
      %%% Pre Initialization %%%
      % Any code not using output argument (obj)
      if nargin == 0 || isempty(h_fig)
        h_fig = figure('Visible','off');
      else
        %figure(h_fig,'Visible','off');
      end
      
      %%% Post Initialization %%%
      % Any code, including access to object
      % This is the first tool initialized by a new echowin
      obj.h_fig = h_fig;
      obj.w = 200;
      obj.h = 120;
      obj.tool_name = '(i)nterp';
      obj.tool_name_title = 'enter';
      obj.tool_shortcut = 'e';
      obj.help_string = sprintf('Left click: Enter point. Open param window (p) to set search range, enabling max point functionality (disabled by default)\nAlt + Left click and drag: Interpolate selected region. Change interpolate mode in param window (p)\nn.b. Leading edge tool (mentioned in param window) is not implemented. Leading edge and max track interpolation is not implemented\n\n');

      
      obj.create_ui;
    end
    
    create_ui(obj);
    cmds = left_click(obj,h_image,layers,cur_layers,x,y,param);
    cmds = left_click_and_drag(obj,h_layer,h_image,layers,cur_layers,x,y,param);
    [vals] = interpolate(obj,x_old,y_old,x_new)
  end
  
end


