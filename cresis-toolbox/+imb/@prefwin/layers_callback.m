function layers_callback(obj,status,event)

h_status = get(status);
if isfield(h_status,'Text')
  % Handle missing label field in newer versions of Matlab (R2017b+)
  h_status.Label = h_status.Text;
end
if isfield(h_status,'Label') && strcmp(get(status,'Label'),'New')
  h_fig = figure('NumberTitle','off','Name','New Layer','DockControls','off','NumberTitle','off','ToolBar','none','MenuBar','none');
  pos = get(h_fig,'Position');
  set(h_fig,'Position',[pos(1:2) 220 140]);
  
  h_nameT = uicontrol('Parent',h_fig,'Style','Text','String','Name');
  h_nameE = uicontrol('Parent',h_fig,'Style','Edit');
  h_groupT = uicontrol('Parent',h_fig,'Style','Text','String','Group');
  h_groupE = uicontrol('Parent',h_fig,'Style','Edit');
  h_descriptionT = uicontrol('Parent',h_fig,'Style','Text','String','Description');
  h_descriptionE = uicontrol('Parent',h_fig,'Style','Edit');
  
  h_okPB = uicontrol('Parent',h_fig,'Style','PushButton','String','Create New Layer','UserData',h_fig,'CallBack',@obj.layers_callback_new);
  h_cancelPB = uicontrol('Parent',h_fig,'Style','PushButton','String','Cancel','CallBack','uiresume(gcbf)');
  
  %% Create the table
  table.ui = h_fig;
  table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
  table.height_margin = NaN*zeros(30,30);
  table.false_width = NaN*zeros(30,30);
  table.false_height = NaN*zeros(30,30);
  table.offset = [0 0];
  
  row = 1; col = 1;
  table.handles{row,col}   = h_nameT;
  table.width(row,col)     = 75;
  table.height(row,col)    = 25;
  table.width_margin(row,col) = 1;
  table.height_margin(row,col) = 1;
  table.false_height(row,col) = 5;
  
  col = 2;
  table.handles{row,col}   = h_nameE;
  table.width(row,col)     = inf;
  table.height(row,col)    = 25;
  table.width_margin(row,col) = 1;
  table.height_margin(row,col) = 1;
  
  row = row + 1; col = 1;
  table.handles{row,col}   = h_groupT;
  table.width(row,col)     = 75;
  table.height(row,col)    = 25;
  table.width_margin(row,col) = 1;
  table.height_margin(row,col) = 1;
  table.false_height(row,col) = 5;
  
  col = 2;
  table.handles{row,col}   = h_groupE;
  table.width(row,col)     = inf;
  table.height(row,col)    = 25;
  table.width_margin(row,col) = 1;
  table.height_margin(row,col) = 1;
  
  row = row + 1; col = 1;
  table.handles{row,col}   = h_descriptionT;
  table.width(row,col)     = 75;
  table.height(row,col)    = 25;
  table.width_margin(row,col) = 1;
  table.height_margin(row,col) = 1;
  table.false_height(row,col) = 5;
  
  col = 2;
  table.handles{row,col}   = h_descriptionE;
  table.width(row,col)     = inf;
  table.height(row,col)    = 25;
  table.width_margin(row,col) = 1;
  table.height_margin(row,col) = 1;
  
  row = row + 1; col = 1;
  table.handles{row,col}   = h_okPB;
  table.width(row,col)     = inf;
  table.height(row,col)    = 22;
  table.width_margin(row,col) = 1;
  table.height_margin(row,col) = 1;
  
  col = 2;
  table.handles{row,col}   = h_cancelPB;
  table.width(row,col)     = inf;
  table.height(row,col)    = 22;
  table.width_margin(row,col) = 1;
  table.height_margin(row,col) = 1;
  
  clear row col
  table_draw(table);
  
  uiwait(h_fig);
  
  close(h_fig);

elseif isfield(h_status,'Label') && strcmp(get(status,'Label'),'Delete')
  
elseif isfield(h_status,'Label') && strcmp(get(status,'Label'),'Rename')
  
elseif isfield(h_status,'Label') && strcmp(get(status,'Label'),'Refresh')
  obj.layers_callback_refresh();
end

end
