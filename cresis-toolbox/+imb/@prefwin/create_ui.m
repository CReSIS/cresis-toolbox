function create_ui(obj)

%% Reset preference and OPS fields
% =========================================================================
obj.systems = {};
obj.seasons = {};
obj.locations = {};

obj.ops = [];
obj.ops.profile = [];
obj.ops.layers = [];
obj.ops.layers.lyr_name = {};

if obj.map_toolbox
  layer_sources = {'layerdata','Connect to OPS'};
  flightlines = {'tracks files Flightlines','Connect to OPS'};
else
  layer_sources = {'layerdata'};
  flightlines = {'tracks files Flightlines'};
end

if obj.map_toolbox
  wms_maps = {'arctic:Blank Geodetic Map';'antarctic:Blank Geodetic Map';'arctic:Blank Stereographic Map';'antarctic:Blank Stereographic Map';'arctic:Google Map';'antarctic:Google Map';'Connect to OPS'};
else
  %error('Mapping toolbox is not available. Mapping toolbox must be available for projections and/or WMS service. Blank Geodetic Maps not supported yet.')
  wms_maps = {'arctic:Blank Geodetic Map';'antarctic:Blank Geodetic Map'};
end

%% Load tracks files
% =========================================================================

% Create tracks file paths
% -------------------------------------------------------------------------
track_fn_dir = ct_filename_support(struct('radar_name','rds'),'tracks',''); % Setting radar_name to rds is arbitrary
fprintf('Finding the csarp_support/tracks files in %s\n', track_fn_dir);
track_fns = get_filenames(track_fn_dir,'tracks','','.mat');

% Parse tracks filenames one at a time to populate
%   obj.systems
%   obj.seasons
%   obj.locations
% -------------------------------------------------------------------------
valid_file_count = 0;
for track_idx = 1:length(track_fns)
  track_fn = track_fns{track_idx};
  % Parse track_fn: layer_SYSTEM_SEASONNAME.mat
  [~,track_fn_name] = fileparts(track_fn);
  [file_type_str,remain] = strtok(track_fn_name,'_');
  if strcmpi(file_type_str,'tracks')
    [location_str,remain] = strtok(remain,'_');
    [sys_str,remain] = strtok(remain,'_');
    if any(strcmpi(location_str,{'arctic','antarctic'}))
      % sys_token: accum, kuband, rds, or snow string
      % remain: _YYYY_LOCATION_PLATFORM string
      obj.systems{end+1} = 'tracks';
      obj.seasons{end+1} = sprintf('%s_%s',sys_str,remain(2:end));
      obj.locations{end+1} = location_str;
      valid_file_count = valid_file_count+1;
    end
  end
end
if valid_file_count == 0
  warning('No tracks files found. Use imb.create_track_files.m to create tracks files. Continuing without tracks files.');
else
  fprintf('  Found %d tracks files.\n', valid_file_count);
end

%% Set Prefwin Figure
% =========================================================================
set(obj.h_fig,'Position',[obj.default_params.x obj.default_params.y obj.default_params.w obj.default_params.h]);
set(obj.h_fig,'DockControls','off')
set(obj.h_fig,'NumberTitle','off');
if strcmpi(class(obj.h_fig),'double')
  set(obj.h_fig,'Name',sprintf('%d: preference',obj.h_fig));
else
  set(obj.h_fig,'Name',sprintf('%d: preference',obj.h_fig.Number));
end
set(obj.h_fig,'ToolBar','none');
set(obj.h_fig,'MenuBar','none');
set(obj.h_fig,'CloseRequestFcn',@obj.close_win);

%% Create the widgets
% =========================================================================

% layer_source pop up menu (populate later from preference window)%%
obj.h_gui.layerSourcePM = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.layerSourcePM,'String',layer_sources);
set(obj.h_gui.layerSourcePM,'Value',1);
set(obj.h_gui.layerSourcePM,'Style','popupmenu');
set(obj.h_gui.layerSourcePM,'HorizontalAlignment','Center');
set(obj.h_gui.layerSourcePM,'FontName','fixed');
set(obj.h_gui.layerSourcePM,'TooltipString','Layer two way travel time data source (select one)');
set(obj.h_gui.layerSourcePM,'Callback',@obj.layerSourcePM_callback);

% layerdata sources pop up menu (populate later from preference window)%%
obj.h_gui.layerDataSourcePM = popupmenu_edit(obj.h_fig,{'layer','CSARP_post/layer'});
set(obj.h_gui.layerDataSourcePM.h_valuePM,'TooltipString',sprintf('Available layerdata filepath sources (select one). Right click to add, edit, or delete entries.\nThe entry "layer" will look in the CSARP_layer directory.\nThe entry "CSARP_post / layer" will look in the CSARP_post / CSARP_layer directory.'));

% Layer selection class (populate later from preference file)
obj.h_gui.h_layers = selectionbox(obj.h_fig,'Layers',[],1);
set(obj.h_gui.h_layers.h_text,'TooltipString','Select the layer two way travel time data source. If layerdata, then select the layerdata source. If OPS, then select layers to load.');
set(obj.h_gui.h_layers.h_list_available,'TooltipString','Available OPS layers (double or right click to select).');
set(obj.h_gui.h_layers.h_list_selected,'TooltipString','Selected OPS layers (double or right click to remove).');
obj.h_gui.h_layers.set_enable(false);

uimenu(obj.h_gui.h_layers.h_list_availableCM, 'Label', 'New', 'Callback', @obj.layers_callback);
uimenu(obj.h_gui.h_layers.h_list_availableCM, 'Label', 'Delete', 'Callback', @obj.layers_callback);
uimenu(obj.h_gui.h_layers.h_list_availableCM, 'Label', 'Rename', 'Callback', @obj.layers_callback);
uimenu(obj.h_gui.h_layers.h_list_availableCM, 'Label', 'Refresh', 'Callback', @obj.layers_callback);

% Season selection class (populate later from preference file)
obj.h_gui.h_seasons = selectionbox(obj.h_fig,'Seasons',[],1);
set(obj.h_gui.h_seasons.h_list_available,'TooltipString','Available seasons for the chosen map (double click or right click to select).');
set(obj.h_gui.h_seasons.h_list_selected,'TooltipString','Selected seasons for the chosen map (double click or right click to remove).');

% System list box label
obj.h_gui.systemsText = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.systemsText,'Style','Text');
set(obj.h_gui.systemsText,'String','Radar Systems');

% Source list box label
obj.h_gui.sourceText = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.sourceText,'Style','Text');
set(obj.h_gui.sourceText,'String','Echogram Sources');

% System list box
obj.h_gui.systemsLB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.systemsLB,'String',{'tracks'});
set(obj.h_gui.systemsLB,'Style','listbox');
set(obj.h_gui.systemsLB,'HorizontalAlignment','Center');
set(obj.h_gui.systemsLB,'FontName','fixed');
set(obj.h_gui.systemsLB,'Callback',@obj.systemsLB_callback);
set(obj.h_gui.systemsLB,'Min',1); % One must always be selected
set(obj.h_gui.systemsLB,'TooltipString','Radar systems (choose one)');

% Source list box (populate later from preference file)
obj.h_gui.sourceLB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.sourceLB,'String','');
set(obj.h_gui.sourceLB,'Style','listbox');
set(obj.h_gui.sourceLB,'HorizontalAlignment','Center');
set(obj.h_gui.sourceLB,'FontName','fixed');
set(obj.h_gui.sourceLB,'Callback',@obj.sourceLB_callback);
set(obj.h_gui.sourceLB,'TooltipString',...
  sprintf('List of echogram sources to load\n Left click to select\n Right click to add, remove, or adjust priority'));
set(obj.h_gui.sourceLB,'Min',1); % One must always be selected
set(obj.h_gui.sourceLB,'Max',1e9); % Allow multiple selections

% Source list box context menu
obj.h_gui.sourceCM = uicontextmenu('Parent',obj.h_fig);
% Define the context menu items and install their callbacks
obj.h_gui.sourceCM_item1 = uimenu(obj.h_gui.sourceCM, 'Label', 'Add', 'Callback', @obj.sourceLB_callback);
obj.h_gui.sourceCM_item2 = uimenu(obj.h_gui.sourceCM, 'Label', 'Remove', 'Callback', @obj.sourceLB_callback);
obj.h_gui.sourceCM_item3 = uimenu(obj.h_gui.sourceCM, 'Label', 'Up', 'Callback', @obj.sourceLB_callback);
obj.h_gui.sourceCM_item4 = uimenu(obj.h_gui.sourceCM, 'Label', 'Down', 'Callback', @obj.sourceLB_callback);
obj.h_gui.sourceCM_item1 = uimenu(obj.h_gui.sourceCM, 'Label', 'Top', 'Callback', @obj.sourceLB_callback);
obj.h_gui.sourceCM_item1 = uimenu(obj.h_gui.sourceCM, 'Label', 'Bottom', 'Callback', @obj.sourceLB_callback);
set(obj.h_gui.sourceLB,'uicontextmenu',obj.h_gui.sourceCM)

% Map Popup Menu (populate later from preference file)
obj.h_gui.mapsPM = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.mapsPM,'String',wms_maps);
set(obj.h_gui.mapsPM,'Value',1);
set(obj.h_gui.mapsPM,'Style','popupmenu');
set(obj.h_gui.mapsPM,'HorizontalAlignment','Center');
set(obj.h_gui.mapsPM,'FontName','fixed');
set(obj.h_gui.mapsPM,'TooltipString','Available maps (select one which matches seasons'' location).');
set(obj.h_gui.mapsPM,'Callback',@obj.mapsPM_callback);

% Map flightline/vectors Popup Menu (populate later from preference file)
obj.h_gui.flightlinesPM = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.flightlinesPM,'String',flightlines);
set(obj.h_gui.flightlinesPM,'Value',1);
set(obj.h_gui.flightlinesPM,'Style','popupmenu');
set(obj.h_gui.flightlinesPM,'HorizontalAlignment','Center');
set(obj.h_gui.flightlinesPM,'FontName','fixed');
set(obj.h_gui.flightlinesPM,'TooltipString','Available flightlines.');
set(obj.h_gui.flightlinesPM,'Callback',@obj.flightlinesPM_callback);

% Okay Button
obj.h_gui.okPB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.okPB,'Style','PushButton');
set(obj.h_gui.okPB,'String','OK');
set(obj.h_gui.okPB,'Callback',@obj.okPB_callback);

%% Create the table
% =========================================================================
obj.h_gui.table.ui=obj.h_fig;
obj.h_gui.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
obj.h_gui.table.height_margin = NaN*zeros(30,30);
obj.h_gui.table.false_width = NaN*zeros(30,30);
obj.h_gui.table.false_height = NaN*zeros(30,30);
obj.h_gui.table.offset = [0 0];

row = 1; col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.h_layers.h_text;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.width(row,col)     = 0;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1; col = 1;%%
obj.h_gui.table.handles{row,col}   = obj.h_gui.layerSourcePM;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 25;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col =2;%%
obj.h_gui.table.handles{row,col}   = obj.h_gui.layerDataSourcePM.h_valuePM;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 25;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.h_layers.h_list_available;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 80;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.h_layers.h_list_selected;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 80;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.h_seasons.h_text;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.width(row,col)     = 0;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.h_seasons.h_list_available;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = inf;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.h_seasons.h_list_selected;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = inf;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.systemsText;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.sourceText;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.systemsLB;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 80;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.sourceLB;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 80;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.mapsPM;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 22;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.flightlinesPM;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 22;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 25;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.okPB;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 25;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

clear row col
table_draw(obj.h_gui.table);

%% Set Default Settings
% Default settings passed in by obj.default_params
% =========================================================================

% Check to see if default parameters require OPS
load_ops = false;
if obj.map_toolbox
  if ~strcmp(obj.default_params.system,'tracks')
    load_ops = true;
  end
  if strcmp(obj.default_params.layer_source,'OPS')
    load_ops = true;
  end
  if strcmp(obj.default_params.flightlines(1:3),'OPS')
    load_ops = true;
  end
  if all(~strcmp(obj.default_params.map_name,{'arctic:Blank Geodetic Map';'antarctic:Blank Geodetic  Map';'arctic:Blank Stereographic Map';'antarctic:Blank Stereographic Map';'arctic:Google Map';'antarctic:Google Map'}))
    load_ops = true;
  end
end
if load_ops
  obj.ops_connect();
end

% Set default layer source
% -------------------------------------------------------------------------
if isfield(obj.default_params,'layer_source') && ischar(obj.default_params.layer_source)
  match_idx = find(strcmp(obj.default_params.layer_source,get(obj.h_gui.layerSourcePM,'String')));
else
  match_idx = [];
end
if isempty(match_idx)
  set(obj.h_gui.layerSourcePM,'Value',1);
else
  set(obj.h_gui.layerSourcePM,'Value',match_idx);
end

% Set default layerdata source
% -------------------------------------------------------------------------
if isfield(obj.default_params,'layer_data_source') && ischar(obj.default_params.layer_data_source)
  layer_data_sources = get(obj.h_gui.layerDataSourcePM,'String');
  match_idx = find(strcmp(obj.default_params.layer_data_source,layer_data_sources));
else
  match_idx = [];
end
if isempty(match_idx)
  layer_data_sources{end+1} = obj.default_params.layer_data_source;
  set(obj.h_gui.layerDataSourcePM,'String',layer_data_sources);
  set(obj.h_gui.layerDataSourcePM,'Value',length(layer_data_sources));
  temp = get(obj.h_gui.layerSourcePM,'String');
  layer_source = temp{get(obj.h_gui.layerSourcePM,'Value')};
  if strcmpi(layer_source,'OPS')
    set(obj.h_gui.layerDataSourcePM,'Enable','off');
  elseif strcmpi(layer_source,'layerdata')
    set(obj.h_gui.layerDataSourcePM,'Enable','on');
  end
else
  temp = get(obj.h_gui.layerSourcePM,'String');
  layer_source = temp{get(obj.h_gui.layerSourcePM,'Value')};
  if strcmpi(layer_source,'OPS')
    set(obj.h_gui.layerDataSourcePM,'Enable','off');
    set(obj.h_gui.layerDataSourcePM,'Value',match_idx);
  elseif strcmpi(layer_source,'layerdata')
    set(obj.h_gui.layerDataSourcePM,'Enable','on');
    set(obj.h_gui.layerDataSourcePM,'Value',match_idx);
  end
end

% Set default flightlines
% -------------------------------------------------------------------------
if isfield(obj.default_params,'flightlines') && ischar(obj.default_params.flightlines)
  match_idx = find(strcmp(obj.default_params.flightlines,get(obj.h_gui.flightlinesPM,'String')));
else
  match_idx = [];
end
if isempty(match_idx)
  set(obj.h_gui.flightlinesPM,'Value',1);
else
  set(obj.h_gui.flightlinesPM,'Value',match_idx);
end
obj.season_update();

% Set default system
% -------------------------------------------------------------------------
if isfield(obj.default_params,'system') && ischar(obj.default_params.system)
  match_idx = find(strcmp(obj.default_params.system,get(obj.h_gui.systemsLB,'String')));
else
  match_idx = [];
end
if isempty(match_idx)
  set(obj.h_gui.systemsLB,'Value',1);
else
  set(obj.h_gui.systemsLB,'Value',match_idx);
end

% Set default map
% -------------------------------------------------------------------------
if isfield(obj.default_params,'map_name') && ischar(obj.default_params.map_name)
  match_idx = find(strcmp(obj.default_params.map_name,get(obj.h_gui.mapsPM,'String')));
else
  match_idx = [];
end
if isempty(match_idx)
  set(obj.h_gui.mapsPM,'Value',1);
else
  set(obj.h_gui.mapsPM,'Value',match_idx);
end
obj.season_update();

% Select the default seasons
% -------------------------------------------------------------------------
obj.h_gui.h_seasons.set_selected(obj.default_params.season_names,true);

% Select the default layers
% -------------------------------------------------------------------------
obj.h_gui.h_layers.set_selected(obj.default_params.layer_names,true);

% Set default echogram sources
% -------------------------------------------------------------------------
if isfield(obj.default_params,'sources')
  set(obj.h_gui.sourceLB,'String',obj.default_params.sources);
end
