classdef picktool_stat < imb.picktool
  % Print or plot statistics pick tool
  %
  % obj = picktool_stat(h_fig)
  % Constructer.
  %
  % Left click: Prints the value at the point clicked
  % Left click and drag: Action depends on the statistic selected:
  %   Line by Line Statistics
  %   Overall Statistics
  %   Histogram
  % Right click: No action
  % Right click and drag: Delete all points in range
  % Scroll: Zooms in/out
  % Ctrl + any click: Select layer
  % Ctrl + any click and drag: Zoom
  % Any double click: Nothing
  % Ctrl + double click: Zoom reset
  %
  % Author: Dhagash Kapadia, John Paden
  
  properties
    table
    panel
    
    h_fig_stat
  end
  
  properties (SetAccess = immutable, GetAccess = public) %constants
    w       % window's width
    h       % window's height
  end
  
  methods
    function obj = picktool_stat(h_fig)
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
      obj.w = 280;
      obj.h = 60;
      obj.tool_name = 's(t)at';
      obj.tool_name_title = 'enter';
      obj.tool_shortcut = 't';
      obj.help_string = sprintf('Left click: Print pixel value.\nAlt + Left click and drag: Run selected statistics command. Change stat mode in Tool Parameters window (p).\n\n');

      obj.h_fig_stat = [];
      
      obj.create_ui;
    end
    
    create_ui(obj);
    cmds = left_click(obj,h_image,layers,cur_layers,x,y,param);
    cmds = left_click_and_drag(obj,h_layer,h_image,layers,cur_layers,x,y,param);
    
    function close_stat_windows(obj,hObj,event)
      delete(obj.h_fig_stat);
      obj.h_fig_stat = [];
    end
    
    function delete(obj)
      obj.close_stat_windows();
    end
    
  end
  
end


