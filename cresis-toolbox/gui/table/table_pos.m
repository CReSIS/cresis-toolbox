function pos = table_pos(table, row, col, in_pos, height)
% pos = table_pos(table, row, col, in_pos)
%
% Part of table_* container functions. table_draw is the user interface to
% the container functions. All other functions should not be called
% directly.
% 
% Convert from natural units to Matlab units. Support function for table_draw.m.
%
% Author: John Paden
%
% See also: table_draw, table_pos, table_resize, table_size

pos(1) = table.offset(1)+table.width_margin(row,col)+in_pos(1);
pos(2) = -table.offset(2)+table.height_margin(row,col)+table.size(2)-in_pos(2)-height;
