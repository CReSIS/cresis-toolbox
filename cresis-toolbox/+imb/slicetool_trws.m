classdef (HandleCompatible = true) slicetool_trws < imb.slicetool
  % Slice_browser tool which calls detect.cpp (HMM)
  
  properties (SetAccess = protected, GetAccess = public)
  end
  
  properties (SetAccess = protected, GetAccess = protected)
  end
  
  events
  end
  
  methods
    function obj = slicetool_trws()
      obj.create_option_ui();
      obj.tool_name = 'trws';
      obj.tool_menu_name = 'TR(W)S';
      obj.tool_shortcut = 'w';
      obj.ctrl_pressed = 0;
      obj.shift_pressed = 0;
      obj.help_string = 'w: tracking tool which runs TRWS solution to HMM inference model to find best surface. Neighboring slices effect cost function to improve solution.';
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
      if sb.surf_idx < 1 || sb.surf_idx > length(sb.sd.surf)
        return
      end
      control_idx = sb.sd.surf(sb.surf_idx).gt;
      active_idx = sb.sd.surf(sb.surf_idx).active;
      surf_idx = sb.sd.surf(sb.surf_idx).top;
      mask_idx = sb.sd.surf(sb.surf_idx).mask;
      
      physical_constants;
      
      try
        max_loops = eval(get(obj.gui.max_loopsLE,'String'));
      catch ME
        error('Error in number of loops: %s', ME.getReport);
      end
      max_loops = uint32(max_loops);
      try
        eval_cmd = get(obj.gui.slice_rangeLE,'String');
        slice_range = eval(eval_cmd);
      catch ME
        error('%s\nError in slice range "%s":\n %s\n', repmat('=',[1 80]), ...
          eval_cmd, ME.message);
      end
      try
        normalization = eval(get(obj.gui.normalizationLE,'String'));
      catch ME
        error('Error in normalization: %s', ME.getReport);
      end
      try
        gt_range = eval(get(obj.gui.gt_rangeLE,'String'));
        gt_range = gt_range(1);
      catch ME
        error('Error in ground truth range: %s', ME.getReport);
      end
      try
        ct_weight_max = eval(get(obj.gui.ct_weightLE,'String'));
        ct_weight_max = ct_weight_max(1);
      catch ME
        error('Error in cross-track smoothness weight: %s', ME.getReport);
      end
      try
        at_weight = eval(get(obj.gui.at_weightLE,'String'));
        at_weight = single(at_weight(1));
      catch ME
        error('Error in along-track smoothness weight: %s', ME.getReport);
      end
      try
        eval_cmd = get(obj.gui.tomo_layersLE,'String');
        if isempty(eval_cmd)
          tomo_params = [];
        else
          tomo_params = eval(eval_cmd);
        end
      catch ME
        error('Error in tomography layers: %s', ME.getReport);
      end
      if get(obj.gui.select_maskCB,'Value')
        cols = find(sb.select_mask);
        if isempty(cols)
          % Nothing to be done
          cmd = [];
          return;
        end
      else
        cols = 1:size(sb.data,2);
      end
      left_edge_en = get(obj.gui.leftEdgeCB,'Value');
      right_edge_en = get(obj.gui.rightEdgeCB,'Value');
      top_edge_en = get(obj.gui.topEdgeCB,'Value');
      bottom_edge_en = get(obj.gui.bottomEdgeCB,'Value');
      
      if ~exist('slices','var') || isempty(slices)
        slice_range = min(slice_range):max(slice_range);
        slices = sb.slice+slice_range;
      end
      slices = intersect(slices,1:size(sb.data,3));
      if ~left_edge_en
        start_slice_idx = 1;
      else
        start_slice_idx = 2;
      end
      if ~right_edge_en
        end_slice_idx = length(slices);
      else
        end_slice_idx = length(slices)-1;
      end
      fprintf('Apply %s to surface %d slices %d - %d\n', obj.tool_name, active_idx, slices(1), slices(end));
      
      % Get 3D image data
      % -------------------------------------------------------------------
      trws_data = single(sb.data(:,:,slices));
      Nt = size(trws_data,1);
      Nsv = size(trws_data,2);
      Nx = size(trws_data,3);
      
      theta = sb.sd.theta;
      
      % Find the bin closest to nadir
      [min_nadir,nadir_col] = min(abs(theta));
      if theta(nadir_col)~=0
        warning('Nadir steering vector column (theta == 0) not present, closest steering vector is theta = %.3f.', theta(nadir_col));
      end
      
      % Get surfaces needed to apply tool
      % -------------------------------------------------------------------
      if isempty(control_idx)
        gt_bins = NaN*sb.sd.surf(control_idx).y(:,slices);
      else
        gt_bins = round(sb.sd.surf(control_idx).y(:,slices));
      end
      if isempty(surf_idx)
        surf_bins = NaN*sb.sd.surf(active_idx).y(:,slices);
        Surface = ones(1,Nt);
      else
        surf_bins = round(sb.sd.surf(surf_idx).y(:,slices));
        Surface = interp_finite(sb.sd.surf(surf_idx).y(nadir_col,:),1);
        Surface = round(Surface(slices));
      end
      if isempty(active_idx)
        active_bins = NaN*sb.sd.surf(active_idx).y(:,slices);
        Bottom = Surface;
      else
        active_bins = (sb.sd.surf(active_idx).y(:,slices));
        Bottom = interp_finite(sb.sd.surf(active_idx).y(nadir_col,:),NaN);
        Bottom = round(Bottom(slices));
        Bottom(isnan(Bottom)) = Surface(isnan(Bottom));
      end
      if isempty(mask_idx)
        ice_mask = ones(size(sb.data,2),length(slices));
      else
        ice_mask = sb.sd.surf(mask_idx).y(:,slices);
      end

      theta_ice = asin(sin(theta(:))/sqrt(er_ice));
      
      master.GPS_time = sb.sd.gps_time(slices);
      [master.Latitude,master.Longitude,master.Elevation] = ecef2geodetic(sb.sd.fcs.origin(1,slices),sb.sd.fcs.origin(2,slices),sb.sd.fcs.origin(3,slices),WGS84.ellipsoid);
      master.Latitude = master.Latitude/180*pi;
      master.Longitude = master.Longitude/180*pi;

      dt = sb.sd.time(2)-sb.sd.time(1);
      dr = dt*c/2;
      at_slope = single([diff(master.Elevation / dr) 0]);
      
      H = interp_finite(sb.sd.time(Surface))*c/2;
      T = interp_finite(sb.sd.time(Bottom))*c/2/sqrt(er_ice);
      theta_threshold = theta(:);
      %theta_threshold(theta_threshold > pi/2*0.75) = pi/2*0.75;
      %theta_threshold(theta_threshold < -pi/2*0.75) = -pi/2*0.75;
      theta_threshold(theta_threshold > pi/2*0.75) = NaN;
      theta_threshold(theta_threshold < -pi/2*0.75) = NaN;
      R = 1./cos(theta_threshold) * H(:).' + 1./cos(theta_ice) * T(:).';
      %ct_slope = single([zeros(1,Nx); diff(R)/dr]+[diff(R)/dr; zeros(1,Nx)]);
      %ct_slope(2:end-1,:) = ct_slope(2:end-1,:)/2;
      ct_slope = [diff(R)/dr; nan(1,Nx)];
      %ct_slope = interp_finite(ct_slope,0,@(x,y,z) interp1(x,y,z,'linear','extrap'),[],'interp');
      ct_slope = single(interp_finite(ct_slope,0));
      
      ct_weight = 1./(3+mean(abs(ct_slope),2));
      ct_weight = ct_weight_max*ct_weight./max(ct_weight);
      ct_weight = single(ct_weight);
      
      if isempty(tomo_params)
        bounds = uint32([ones(1,Nx); Nt*ones(1,Nx)]);
        
      else
        for lay_idx = 1:length(tomo_params)
          tomo_params(lay_idx).existence_check = false;
        end
        tomo_layers = opsLoadLayers(sb.sd.param,tomo_params);
        
        %% Interpolate tomo_layers information to mdata
        for lay_idx = 1:length(tomo_layers)
          ops_layer = [];
          ops_layer{1}.gps_time = tomo_layers(lay_idx).gps_time;
          
          ops_layer{1}.type = tomo_layers(lay_idx).type;
          ops_layer{1}.quality = tomo_layers(lay_idx).quality;
          ops_layer{1}.twtt = tomo_layers(lay_idx).twtt;
          ops_layer{1}.type(isnan(ops_layer{1}.type)) = 2;
          ops_layer{1}.quality(isnan(ops_layer{1}.quality)) = 1;
          lay = opsInterpLayersToMasterGPSTime(master,ops_layer,[300 60]);
          tomo_layers(lay_idx).twtt_ref = lay.layerData{1}.value{2}.data;
        end
        tomo_top_bin = round(interp_finite(interp1(sb.sd.time,1:length(sb.sd.time),tomo_layers(1).twtt_ref),NaN));
        tomo_bottom_bin = round(interp_finite(interp1(sb.sd.time,1:length(sb.sd.time),tomo_layers(2).twtt_ref),NaN));
        
        tomo_top_bin(isnan(tomo_top_bin)) = 1;
        tomo_bottom_bin(isnan(tomo_bottom_bin)) = Nt;
        bounds = uint32([tomo_top_bin; tomo_bottom_bin]);
        bounds(bounds<1) = 1;
        bounds(bounds>Nt) = Nt;
        bounds = bounds - 1;
      end
      
      % Apply ground truth, surface, surface suppression and ice mask
      % -------------------------------------------------------------------
      begin_slice = max(1, min(slices)-1);
      end_slice = min(size(sb.data,3), max(slices)+1);
      surf_bins = round(sb.sd.surf(surf_idx).y(:,slices));
      surf_weight = 30;
      surf_range = 110;
      for idx = 1:Nx
        slice = slices(idx);
        for col = 1:Nsv
          if idx == 1 && left_edge_en && isfinite(active_bins(col,idx)) ...
            || idx == Nx && right_edge_en && isfinite(active_bins(col,idx)) ...
            || col ~= 1 && col == cols(1) && top_edge_en && isfinite(active_bins(col,idx)) ...
            || col ~= Nsv && col == cols(end) && bottom_edge_en && isfinite(active_bins(col,idx))
            % No change for edge
            trws_data([1:active_bins(col,idx)-1 active_bins(col,idx)+1:end], col, idx) = -10e9;
          elseif ice_mask(col,idx)
            if isfinite(gt_bins(col,idx))
              % Ground truth
              trws_data([1:gt_bins(col,idx)-gt_range, gt_bins(col,idx)+gt_range:end], col, idx) = -10e9;
            end
            if isfinite(surf_bins(col,idx))
              if surf_bins(col,idx) < Nt
                % Bottom below top
                trws_data(1:surf_bins(col,idx), col, idx) = -10e9;
                % Surface suppression
                cur_surf_range = max(0,min(surf_range,Nt-surf_bins(col,idx)));
                trws_data(surf_bins(col,idx) + (1:cur_surf_range), col, idx) ...
                  = trws_data(surf_bins(col,idx) + (1:cur_surf_range), col, idx) ...
                  -surf_weight/surf_range * (cur_surf_range:-1:1).';
              elseif surf_bins(col,idx) >= Nt
                % Handle special case when surface is more than the last row
                trws_data(1:Nt-1, col, idx) = -10e9;
              end
            end
          elseif isfinite(surf_bins(col,idx))
            % Bottom equals top because there is no ice here
            trws_data([1:surf_bins(col,idx)-1 surf_bins(col,idx)+1:end], col, idx) = -10e9;
          end
        end
      end
      
      % TRW-S
      % -------------------------------------------------------------------
      tic;
      correct_surface = tomo.trws2(trws_data,at_slope,at_weight,ct_slope,ct_weight,max_loops,bounds);
      fprintf('  %.2f sec per slice\n', toc/size(trws_data,3));
      
      % Create cmd for surface change
      % -------------------------------------------------------------------
      cmd = [];
      for idx = start_slice_idx:end_slice_idx
        slice = slices(idx);
        cmd{end+1}.undo.slice = slice;
        cmd{end}.redo.slice = slice;
        cmd{end}.undo.surf = active_idx;
        cmd{end}.redo.surf = active_idx;
        cmd{end}.undo.x = cols;
        cmd{end}.undo.y = sb.sd.surf(active_idx).y(cols,slice);
        cmd{end}.redo.x = cols;
        cmd{end}.redo.y = correct_surface(cols,idx);
        cmd{end}.type = 'standard';
      end
      if any(sb.slice == slices(start_slice_idx:end_slice_idx))
        % Current slice in slice browser is one of the affected slices, my
        % placing it first in the list this is the one the viewer will jump
        % to when the undo or redo operation are run
        cmd{end+1}.redo.slice = [sb.slice slices(start_slice_idx:end_slice_idx)];
        cmd{end}.undo.slice = [sb.slice slices(start_slice_idx:end_slice_idx)];
      else
        % Current slice in slice browser is NOT one of the affected slices.
        % During the undo or redo operation, the browser will now jump to
        % the first affected slice.
        cmd{end+1}.redo.slice = slices(start_slice_idx:end_slice_idx);
        cmd{end}.undo.slice = slices(start_slice_idx:end_slice_idx);
      end
      cmd{end}.type = 'slice_dummy';
      
    end
    
    function set_custom_data(obj,custom_data)
      obj.custom_data.mu = mean(custom_data.mu);
      obj.custom_data.sigma = mean(custom_data.sigma);
    end
    
    function create_option_ui(obj)
      obj.h_fig = figure('Visible','off','DockControls','off', ...
        'NumberTitle','off','ToolBar','none','MenuBar','none','Resize','off');
      if strcmpi(class(obj.h_fig),'double')
        set(obj.h_fig,'Name',sprintf('%d: trws tool prefs',obj.h_fig));
      else
        set(obj.h_fig,'Name',sprintf('%d: trws tool prefs',obj.h_fig.Number));
      end
      set(obj.h_fig,'CloseRequestFcn',@obj.close_win);
      pos = get(obj.h_fig,'Position');
      pos(3) = 220;
      pos(4) = 215;
      set(obj.h_fig,'Position',pos);
      
      % Number of loops
      obj.gui.max_loopsTXT = uicontrol('Style','text','string','Max Loops');
      set(obj.gui.max_loopsTXT,'TooltipString','Maximum number of iterations that TRW-S will run. Default is 10.');
      
      obj.gui.max_loopsLE = uicontrol('parent',obj.h_fig);
      set(obj.gui.max_loopsLE,'style','edit')
      set(obj.gui.max_loopsLE,'string','10')
      set(obj.gui.max_loopsLE,'TooltipString',get(obj.gui.max_loopsTXT,'TooltipString'));
      
      % Slice range
      obj.gui.slice_rangeTXT = uicontrol('Style','text','string','Slice range');
      set(obj.gui.slice_rangeTXT,'TooltipString','Enter a vector specifying relative range in slices. E.g. "-5:7".');
      
      obj.gui.slice_rangeLE = uicontrol('parent',obj.h_fig);
      set(obj.gui.slice_rangeLE,'style','edit')
      set(obj.gui.slice_rangeLE,'string','-5:6')
      set(obj.gui.slice_rangeLE,'TooltipString','Enter a vector specifying relative range in slices. Default is -5:6.');
      set(obj.gui.slice_rangeLE,'TooltipString',get(obj.gui.slice_rangeTXT,'TooltipString'));
      
      % Normalization
      obj.gui.normalizationTXT = uicontrol('Style','text','string','Normalization');
      set(obj.gui.normalizationTXT,'TooltipString','Specify image thresholds for echo_norm function. First number is the minimum noise value. Second number is the maximum signal value. Default is [-inf inf] which allows the noise floor and maximum signal level to be estimated from the data.');
      
      obj.gui.normalizationLE = uicontrol('parent',obj.h_fig);
      set(obj.gui.normalizationLE,'style','edit')
      set(obj.gui.normalizationLE,'string','[-inf inf]')
      set(obj.gui.normalizationLE,'TooltipString',get(obj.gui.normalizationTXT,'TooltipString'));
      
      % Ground truth row range
      obj.gui.gt_rangeTXT = uicontrol('Style','text','string','GT Range');
      set(obj.gui.gt_rangeTXT,'TooltipString','Specify a number of rows around the ground truth to search. Default is 5 bins.');
      
      obj.gui.gt_rangeLE = uicontrol('parent',obj.h_fig);
      set(obj.gui.gt_rangeLE,'style','edit')
      set(obj.gui.gt_rangeLE,'string','5')
      set(obj.gui.gt_rangeLE,'TooltipString',get(obj.gui.gt_rangeTXT,'TooltipString'));
      
      % Crosstrack Smoothness
      obj.gui.ct_weightTXT = uicontrol('Style','text','string','CT Smooth');
      set(obj.gui.ct_weightTXT,'TooltipString','Specify weight for surface smoothness in cross-track dimension. Default is 0.01.');
      
      obj.gui.ct_weightLE = uicontrol('parent',obj.h_fig);
      set(obj.gui.ct_weightLE,'style','edit')
      set(obj.gui.ct_weightLE,'string','0.01')
      set(obj.gui.ct_weightLE,'TooltipString',get(obj.gui.ct_weightTXT,'TooltipString'));
      
      % Alongtrack Smoothness
      obj.gui.at_weightTXT = uicontrol('Style','text','string','AT Smooth');
      set(obj.gui.at_weightTXT,'TooltipString','Specify weight for surface smoothness in along-track dimension. Default is 0.01.');
      
      obj.gui.at_weightLE = uicontrol('parent',obj.h_fig);
      set(obj.gui.at_weightLE,'style','edit')
      set(obj.gui.at_weightLE,'string','0.01')
      set(obj.gui.at_weightLE,'TooltipString',get(obj.gui.at_weightTXT,'TooltipString'));
      
      % Tomography layers
      obj.gui.tomo_layersTXT = uicontrol('Style','text','string','Tomo Layers');
      set(obj.gui.tomo_layersTXT,'TooltipString','Specify layers to constrain the top row and bottom row of the surface. Default is struct(''name'',{''tomo_top'',''tomo_bottom''}).');
      
      obj.gui.tomo_layersLE = uicontrol('parent',obj.h_fig);
      set(obj.gui.tomo_layersLE,'style','edit')
      set(obj.gui.tomo_layersLE,'string','struct(''name'',{''tomo_top'',''tomo_bottom''})')
      set(obj.gui.tomo_layersLE,'TooltipString',get(obj.gui.tomo_layersTXT,'TooltipString'));
      
      % Select mask
      obj.gui.select_maskCB = uicontrol('parent',obj.h_fig);
      set(obj.gui.select_maskCB,'style','checkbox')
      set(obj.gui.select_maskCB,'string','Select')
      set(obj.gui.select_maskCB,'value',1)
      set(obj.gui.select_maskCB,'TooltipString','Check to operate only on the selected cross-track bins.');
      
      % Left edge
      obj.gui.leftEdgeCB = uicontrol('parent',obj.h_fig);
      set(obj.gui.leftEdgeCB,'style','checkbox')
      set(obj.gui.leftEdgeCB,'string','L')
      set(obj.gui.leftEdgeCB,'value',1)
      set(obj.gui.leftEdgeCB,'TooltipString','Check to force a left edge boundary condition.');
      
      % Right edge
      obj.gui.rightEdgeCB = uicontrol('parent',obj.h_fig);
      set(obj.gui.rightEdgeCB,'style','checkbox')
      set(obj.gui.rightEdgeCB,'string','R')
      set(obj.gui.rightEdgeCB,'value',1)
      set(obj.gui.rightEdgeCB,'TooltipString','Check to force a right edge boundary condition.');
      
      % Top edge
      obj.gui.topEdgeCB = uicontrol('parent',obj.h_fig);
      set(obj.gui.topEdgeCB,'style','checkbox')
      set(obj.gui.topEdgeCB,'string','T')
      set(obj.gui.topEdgeCB,'value',1)
      set(obj.gui.topEdgeCB,'TooltipString','Check to force a top edge boundary condition.');
      
      % Bottom edge
      obj.gui.bottomEdgeCB = uicontrol('parent',obj.h_fig);
      set(obj.gui.bottomEdgeCB,'style','checkbox')
      set(obj.gui.bottomEdgeCB,'string','B')
      set(obj.gui.bottomEdgeCB,'value',1)
      set(obj.gui.bottomEdgeCB,'TooltipString','Check to force a bottom edge boundary condition.');
      
      % GUI container table
      obj.gui.table.ui = obj.h_fig;
      obj.gui.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
      obj.gui.table.height_margin = NaN*zeros(30,30);
      obj.gui.table.false_width = NaN*zeros(30,30);
      obj.gui.table.false_height = NaN*zeros(30,30);
      obj.gui.table.offset = [0 0];
      row = 1;
      col = 1;
      obj.gui.table.handles{row,col}   = obj.gui.max_loopsTXT;
      obj.gui.table.width(row,col)     = 70;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      col = 2;
      obj.gui.table.handles{row,col}   = obj.gui.max_loopsLE;
      obj.gui.table.width(row,col)     = inf;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      
      row = row + 1;
      col = 1;
      obj.gui.table.handles{row,col}   = obj.gui.slice_rangeTXT;
      obj.gui.table.width(row,col)     = 70;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      col = 2;
      obj.gui.table.handles{row,col}   = obj.gui.slice_rangeLE;
      obj.gui.table.width(row,col)     = inf;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      
      row = row + 1;
      col = 1;
      obj.gui.table.handles{row,col}   = obj.gui.normalizationTXT;
      obj.gui.table.width(row,col)     = 70;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      col = 2;
      obj.gui.table.handles{row,col}   = obj.gui.normalizationLE;
      obj.gui.table.width(row,col)     = inf;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      row = row + 1;
      
      col = 1;
      obj.gui.table.handles{row,col}   = obj.gui.gt_rangeTXT;
      obj.gui.table.width(row,col)     = 70;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      col = 2;
      obj.gui.table.handles{row,col}   = obj.gui.gt_rangeLE;
      obj.gui.table.width(row,col)     = inf;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      
      row = row + 1;
      col = 1;
      obj.gui.table.handles{row,col}   = obj.gui.ct_weightTXT;
      obj.gui.table.width(row,col)     = 70;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      col = 2;
      obj.gui.table.handles{row,col}   = obj.gui.ct_weightLE;
      obj.gui.table.width(row,col)     = inf;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      
      row = row + 1;
      col = 1;
      obj.gui.table.handles{row,col}   = obj.gui.at_weightTXT;
      obj.gui.table.width(row,col)     = 70;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      col = 2;
      obj.gui.table.handles{row,col}   = obj.gui.at_weightLE;
      obj.gui.table.width(row,col)     = inf;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      
      row = row + 1;
      col = 1;
      obj.gui.table.handles{row,col}   = obj.gui.tomo_layersTXT;
      obj.gui.table.width(row,col)     = 70;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      col = 2;
      obj.gui.table.handles{row,col}   = obj.gui.tomo_layersLE;
      obj.gui.table.width(row,col)     = inf;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      
      row = row + 1;
      col = 1;
      obj.gui.table.handles{row,col}   = obj.gui.select_maskCB;
      obj.gui.table.width(row,col)     = inf;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      col = col+1;
      obj.gui.table.handles{row,col}   = obj.gui.leftEdgeCB;
      obj.gui.table.width(row,col)     = 25;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      col = col+1;
      obj.gui.table.handles{row,col}   = obj.gui.rightEdgeCB;
      obj.gui.table.width(row,col)     = 25;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      col = col+1;
      obj.gui.table.handles{row,col}   = obj.gui.topEdgeCB;
      obj.gui.table.width(row,col)     = 25;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      col = col+1;
      obj.gui.table.handles{row,col}   = obj.gui.bottomEdgeCB;
      obj.gui.table.width(row,col)     = 25;
      obj.gui.table.height(row,col)    = 20;
      obj.gui.table.width_margin(row,col) = 1;
      obj.gui.table.height_margin(row,col) = 1;
      
      clear row col
      table_draw(obj.gui.table);
      
    end
    
  end
  
end


