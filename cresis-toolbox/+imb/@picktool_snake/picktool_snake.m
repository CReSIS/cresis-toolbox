classdef picktool_snake < imb.picktool
  
  properties
    top_panel
    bottom_panel
    table
    last_tool;
    last_layers;
    last_range_gps;
    first_time;    
    cur_mode;    
    
    % properties to preserve tool values across deletions
    in_rng_sv;
    sn_rng_sv;
    top_sm_sv;
    bot_sm_sv;
    top_pk_sv;
    bot_pk_sv;
    rep_sv;
  end
  
  properties (SetAccess = immutable, GetAccess = public) %constants
    w           % window's width
    h           % window's height
    crandall_h  % window's height when crandall mode selected
  end
  
  methods
    function obj = picktool_snake(h_fig)
      %%% Pre Initialization %%%
      % Any code not using output argument (obj)
      if nargin == 0 || isempty(h_fig)
        h_fig = figure('Visible','off');
      else
        figure(h_fig,'Visible','off');
      end
      
      %%% Post Initialization %%%
      % Any code, including access to object
      obj.h_fig = h_fig;
      obj.tool_name = '(s)nake';
      obj.tool_name_title = 'snake';
      obj.tool_shortcut = 's';
      obj.help_string = sprintf('Left click: Enter point. Open param window (p) to set search range, enabling max point functionality (enabled by default)\nAlt + Left click and drag: Snake selected region. Be sure ''basic'' mode is selected in the param window (p) pulldown menu\nn.b. Crandall tool (selectable in param window pulldown menu) is undocumented. Panton tool is not implemented\n\n');

      obj.bottom_panel = [];
      obj.top_panel = [];
      obj.table = [];
      obj.w = 200;
      obj.h = 125;
      obj.crandall_h = 250;   
      obj.first_time = true;
      
      obj.in_rng_sv = 5;
      obj.sn_rng_sv = 5;
      obj.top_sm_sv = .5;
      obj.bot_sm_sv = .5;
      obj.top_pk_sv = .5;
      obj.bot_pk_sv = .5;
      obj.rep_sv = .5;
      obj.cur_mode = 1;      
      
      obj.create_ui();
    end
    
    create_ui(obj);
    cmds = left_click(obj,param);
    cmds = left_click_and_drag(obj,param);
    vals = snake(obj,image_c,image_x,image_y,x_old,y_old,x_new);
  end
  
end


