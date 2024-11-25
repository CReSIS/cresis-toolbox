function create_ui(obj)
% imagewin.create_ui(obj)
%
% Create the cross over figure and GUI

%% Get image information
clims = obj.get_limits();

%% Create Figure

if obj.hide_only
  obj.h_fig = figure('Visible','off');
else
  obj.h_fig = figure;
end

set(obj.h_fig,'DockControls','off');
set(obj.h_fig,'NumberTitle','off');
set(obj.h_fig,'Name',obj.img_title);
set(obj.h_fig,'ToolBar','none');
set(obj.h_fig,'MenuBar','none'); 
set(obj.h_fig,'CloseRequestFcn',@obj.close_win);
set(obj.h_fig,'Units','Points');
pos = get(obj.h_fig,'Position');
set(obj.h_fig,'Position',[pos(1:2) 361 230]);

%% Create GUI Objects

obj.h_gui.colormapPM = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.colormapPM,'Style','popupmenu');
set(obj.h_gui.colormapPM,'String',{'1-Gray Colormap','Jet Colormap'});
set(obj.h_gui.colormapPM,'Value',1);
set(obj.h_gui.colormapPM,'Callback',@obj.update_caxis);

obj.h_gui.caxis_autoCB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.caxis_autoCB,'Style','CheckBox');
set(obj.h_gui.caxis_autoCB,'String','Auto caxis');
set(obj.h_gui.caxis_autoCB,'Callback',@obj.update_caxis);

obj.h_gui.saveMatPB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.saveMatPB,'Style','PushButton');
set(obj.h_gui.saveMatPB,'String','Save Mat');
set(obj.h_gui.saveMatPB,'Callback',@obj.save_mat_callback);

obj.h_gui.savePB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.savePB,'Style','PushButton');
set(obj.h_gui.savePB,'String','Save');
set(obj.h_gui.savePB,'Callback',@obj.save_callback);

obj.h_gui.openPB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.openPB,'Style','PushButton');
set(obj.h_gui.openPB,'String','Open');
set(obj.h_gui.openPB,'Callback',@obj.open_callback);

obj.h_gui.min_slider = slider(obj.h_fig,'Min',clims,clims(1));

obj.h_gui.max_slider = slider(obj.h_fig,'Max',clims,clims(end));

obj.h_gui.hist_slider = slider(obj.h_fig,'Histogram',[-5 5],0);

addlistener(obj.h_gui.min_slider,'slider_changed',@obj.update_caxis);
addlistener(obj.h_gui.max_slider,'slider_changed',@obj.update_caxis);
addlistener(obj.h_gui.hist_slider,'slider_changed',@obj.update_caxis);

signal_filters = {'10*log10(X)', ...
  '10*log10(echo_filt(X,[param1 param2]))', ...
  'echo_xcorr(10*log10(echo_filt(X,[param1 param2])),echo_xcorr_profile('''',''h_filt_offset'',-4,''h_filt_len'',6))', ...
  'echo_xcorr(10*log10(echo_filt(X,[param1 param2])),echo_xcorr_profile('''',''h_filt_offset'',-16,''h_filt_len'',20))', ...
  'echo_xcorr(10*log10(echo_filt(X,[param1 param2])),echo_xcorr_profile('''',''h_filt_offset'',-40,''h_filt_len'',50))', ...
  };

obj.h_gui.signal_listbox = listbox(obj.h_fig,'Signal','listbox',signal_filters,1);

noise_filters = {'0', ...
  '10*log10(filter2(ones(50,250)/12500,X))', ...
  'repmat(10*log10(mean(X,2)),[1 size(X,2)])'};

obj.h_gui.noise_listbox = listbox(obj.h_fig,'Noise','listbox',noise_filters,1);

addlistener(obj.h_gui.signal_listbox,'list_changed',@obj.update_filter);
addlistener(obj.h_gui.noise_listbox,'list_changed',@obj.update_filter);

obj.h_gui.param1_slider = slider(obj.h_fig,'param1',[0 100],0);
obj.h_gui.param2_slider = slider(obj.h_fig,'param2',[0 100],0);

addlistener(obj.h_gui.param1_slider,'slider_changed',@obj.update_filter);
addlistener(obj.h_gui.param2_slider,'slider_changed',@obj.update_filter);

%% Create GUI Table
obj.h_gui.table.ui = obj.h_fig;
obj.h_gui.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
obj.h_gui.table.height_margin = NaN*zeros(30,30);
obj.h_gui.table.false_width = NaN*zeros(30,30);
obj.h_gui.table.false_height = NaN*zeros(30,30);
obj.h_gui.table.offset = [0 0];

row = 1;
col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.colormapPM;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 5;
col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.caxis_autoCB;
obj.h_gui.table.width(row,col)     = 80;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;
col = 3;
obj.h_gui.table.handles{row,col}   = obj.h_gui.saveMatPB;
obj.h_gui.table.width(row,col)     = 60;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;
col = 4;
obj.h_gui.table.handles{row,col}   = obj.h_gui.savePB;
obj.h_gui.table.width(row,col)     = 60;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;
col = 5;
obj.h_gui.table.handles{row,col}   = obj.h_gui.openPB;
obj.h_gui.table.width(row,col)     = 60;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1;
col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.min_slider.h_text;
obj.h_gui.table.width(row,col)     = 50;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 5;
col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.min_slider.h_slider;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;
col = 3;
obj.h_gui.table.handles{row,col}   = obj.h_gui.min_slider.h_LE;
obj.h_gui.table.width(row,col)     = 50;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1;
col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.max_slider.h_text;
obj.h_gui.table.width(row,col)     = 50;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 5;
col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.max_slider.h_slider;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;
col = 3;
obj.h_gui.table.handles{row,col}   = obj.h_gui.max_slider.h_LE;
obj.h_gui.table.width(row,col)     = 50;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1;
col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.hist_slider.h_text;
obj.h_gui.table.width(row,col)     = 50;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 5;
col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.hist_slider.h_slider;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;
col = 3;
obj.h_gui.table.handles{row,col}   = obj.h_gui.hist_slider.h_LE;
obj.h_gui.table.width(row,col)     = 50;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1;
col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.signal_listbox.h_text;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 5;
col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.noise_listbox.h_text;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 5;

row = row + 1;
col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.signal_listbox.h_list;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = inf;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;
col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.noise_listbox.h_list;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = inf;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1;
col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.signal_listbox.h_LE;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;
col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.noise_listbox.h_LE;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1;
col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.param1_slider.h_text;
obj.h_gui.table.width(row,col)     = 50;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 5;
col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.param1_slider.h_slider;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;
col = 3;
obj.h_gui.table.handles{row,col}   = obj.h_gui.param1_slider.h_LE;
obj.h_gui.table.width(row,col)     = 50;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1;
col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.param2_slider.h_text;
obj.h_gui.table.width(row,col)     = 50;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 5;
col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.param2_slider.h_slider;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;
col = 3;
obj.h_gui.table.handles{row,col}   = obj.h_gui.param2_slider.h_LE;
obj.h_gui.table.width(row,col)     = 50;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

clear row col
table_draw(obj.h_gui.table);

return

