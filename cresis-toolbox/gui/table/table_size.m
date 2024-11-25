function Tsize = table_size(table)
% Tsize = table_size(table)
%
% Part of table_* container functions. table_draw is the user interface to
% the container functions. All other functions should not be called
% directly.
% 
% Size of table's user interface control. Support function for table_draw.m.
%
% Author: John Paden
%
% See also: table_draw, table_pos, table_resize, table_size

set(table.ui,'ResizeFcn',[]);
set(table.ui,'Units','Points');
tmp = get(table.ui,'Position');
Tsize = tmp(3:4);

% Strange and unexplained correction factor:
%Tsize(2) = Tsize(2) * get(0,'ScreenPixelsPerInch')/72;

set(table.ui,'Units','Normalized');
set(table.ui,'ResizeFcn',@table_resize);
