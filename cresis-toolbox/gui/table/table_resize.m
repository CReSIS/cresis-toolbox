function table_resize(hObject, eventdata, handles)
% table_resize(hObject, eventdata, handles)
%
% Part of table_* container functions. table_draw is the user interface to
% the container functions. All other functions should not be called
% directly.
% 
% Resize event handler for table container.
%
% Author: John Paden
%
% See also: table_draw, table_pos, table_resize, table_size

[hObject,figure] = gcbo;

table = get(hObject,'UserData');

table_draw(table);
