function table_draw(table)
% table_draw(table)
%
% Part of table_* container functions. table_draw is the user interface to
% the container functions. All other functions should not be called
% directly.
% 
% Initializes table ui handles and sizes all ui elements in table. Also
% called for resizing.
%
% INPUTS:
% table: structure controlling table object
%
%  .width_margin: Nrow by Ncol matrix indicating margin from left, leave
%  undefined or set to NaN to use default value 0
%
%  .height_margin: Nrow by Ncol matrix indicating margin from top, leave
%  undefined or set to NaN to use default value 0
%
%  .false_width: Nrow by Ncol matrix indicating width adjustment for
%  contained object, leave undefined or set to NaN to use default value 0
%
%  .false_height: Nrow by Ncol matrix indicating height adjustment for
%  contained object, leave undefined or set to NaN to use default value 0
%
%  .width: Nrow by Ncol matrix indicating width of contained object, set to
%  inf to use the remaining space available, multiple inf entries in a row
%  will dividing the remaining space equally
%
%  .height: Nrow by Ncol matrix indicating height of contained object, set
%  to inf to use the remaining space available, multiple inf entries in a
%  row will dividing the remaining space equally
% 
%  .handles: Nrow by Ncol matrix of ui handles
%
%  .ui: ui object that the table is associated with
%
%  .origin: [0 0] by default
%
%  .offset: [0 0] by default
%
% Author: John Paden
%
% See also: table_draw, table_pos, table_resize, table_size

if ~isempty(table.ui)
  table.size = table_size(table);
end

table.rows = size(table.handles,1);
table.cols = size(table.handles,2);

if ~isfield(table,'width_margin')
  for row = 1:table.rows
    for col = 1:table.cols
      table.width_margin(row,col) = NaN;
    end
  end
end
if ~isfield(table,'height_margin')
  for row = 1:table.rows
    for col = 1:table.cols
      table.height_margin(row,col) = NaN;
    end
  end
end
if ~isfield(table,'false_width')
  for row = 1:table.rows
    for col = 1:table.cols
      table.false_width(row,col) = NaN;
    end
  end
end
if ~isfield(table,'false_height')
  for row = 1:table.rows
    for col = 1:table.cols
      table.false_height(row,col) = NaN;
    end
  end
end
default_height_margin = 3;
default_width_margin = 3;
default_false_height = 3;
default_false_width  = 3;
if size(table.width_margin,1) < table.rows || size(table.width_margin,2) < table.cols
  table.width_margin(table.rows,table.cols) = default_width_margin;
end
if size(table.height_margin,1) < table.rows || size(table.height_margin,2) < table.cols
  table.height_margin(table.rows,table.cols) = default_height_margin;
end
if size(table.false_height,1) < table.rows || size(table.false_height,2) < table.cols
  table.false_height(table.rows,table.cols) = default_false_height;
end
if size(table.false_width,1) < table.rows || size(table.false_width,2) < table.cols
  table.false_width(table.rows,table.cols) = default_false_width;
end
for row = 1:table.rows
  for col = 1:table.cols
    if isnan(table.width_margin(row,col))
      table.width_margin(row,col) = default_width_margin;
    end
    if isnan(table.height_margin(row,col))
      table.height_margin(row,col) = default_height_margin;
    end
    if isnan(table.false_height(row,col))
      table.false_height(row,col) = 0;
    end
    if isnan(table.false_width(row,col))
      table.false_width(row,col) = 0;
    end
  end
end

if ~isfield(table,'offset')
  table.offset = [0 0];
end

if ~isfield(table,'origin')
  table.origin = [0 0];
end

if ~isempty(table.ui)
  set(table.ui,'UserData',table);
  set(table.ui,'ResizeFcn',@table_resize);
end

curPos = [0 0];
for row = 1:table.rows
  curPos(1) = 0;
  heights = [];
  for col = 1:table.cols
    % Check to see if widget fills whole vertical space (inf size)
    if isinf(table.height(row,col))
      nonInfMask = ~isinf(table.height(:, col));
      % Sum up the margins
      %margins = 2*sum(table.height_margin(nonInfMask, col));
      % Sum up the other entries
      entries = sum(table.height(nonInfMask, col));
      % took out (-margins) from table.size(2) since this is accounted for
      % in entries
      height = (table.size(2) - entries - table.offset(2)) / sum(~nonInfMask);
    else
      height = table.height(row,col);
    end

    % Check to see if widget fills whole horizontal space (inf size)
    if isinf(table.width(row,col))
      nonInfMask = ~isinf(table.width(row,:));
      % Sum up the margins
      % margins = 2*sum(table.width_margin(row, nonInfMask));
      % Sum up the other entries
      entries = sum(table.width(row, nonInfMask));
      % took out (-margins) from table.size(1) since this is accounted for
      % in entries
      width = (table.size(1) - entries - table.offset(1)) / sum(~nonInfMask);
    else
      width = table.width(row,col);
    end

    % Compute the size
    if row == table.rows
      % Last row is always on the bottom
      newPos = [table_pos(table,row,col,curPos,height) width-2*table.width_margin(row,col)-table.false_width(row,col) height-2*table.height_margin(row,col)-table.false_height(row,col)];
      newPos(1) = newPos(1)-table.width_margin(row,col);
      newPos(2) = table.height_margin(row,col);
    else
      newPos = [table_pos(table,row,col,curPos,height) width-2*table.width_margin(row,col)-table.false_width(row,col) height-2*table.height_margin(row,col)-table.false_height(row,col)];
      newPos(1) = newPos(1)-table.width_margin(row,col);
      newPos(2) = newPos(2)-table.height_margin(row,col);
    end
    newPos(1:2) = newPos(1:2) + table.origin;
    if ~isempty(table.handles{row,col})
      % The width and height must be > 0
      if newPos(3) < 0
        %warning('Request width is %g than 0 for row %d col %d', newPos(3), row, col);
        newPos(3) = 1;
      elseif newPos(4) < 0
        %warning('Request height is %g than 0 for row %d col %d', newPos(4), row, col);
        newPos(4) = 1;
      end
    end
    try
      %table.false_width(row,col)
      %table.handles{row,col}
      %table.size
      %newPos
      if ishandle(table.handles{row,col})
        % This is a Matlab graphics object
        %try
        %  get(table.handles{row,col},'String')
        %end
        set(table.handles{row,col},'Units','Points');
        set(table.handles{row,col},'Position', newPos);
        set(table.handles{row,col},'Units','Normalized');
      elseif isstruct(table.handles{row,col})
        % This is a table container
        table.handles{row,col}.size = newPos(3:4);
        table.handles{row,col}.origin = newPos(1:2);
        table_draw(table.handles{row,col});
      end
    catch ME
      ME
      %keyboard
    end
    curPos(1) = curPos(1) + width;
    heights = [heights height];
  end
  curPos(2) = curPos(2) + max(heights);
end

return;
