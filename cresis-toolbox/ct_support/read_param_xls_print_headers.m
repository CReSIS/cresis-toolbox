function [headers] = read_param_xls_print_headers(param_fn, generic_ws)
% [headers] = read_param_xls_print_headers(param_fn, generic_ws)
%
% Support function for read_param_xls_print, generic worksheet printer.
%
% param_fn: MS Excel .xls parameter spreadsheet to load in
% generic_ws: worksheet name to load in
%
% Author: John Paden
%
% See also: ct_set_params, master, read_param_xls
%
% SUPPORT FUNCTIONS: read_param_xls_boolean.m, read_param_xls_general.m,
% read_param_xls_generic.m, read_param_xls_headers.m,
% read_param_xls_radar.m read_param_xls_text.m
%
% PRINT OUT XLS: read_param_xls_print

%% Setup
% ======================================================================%
warning('off','MATLAB:xlsread:Mode');

%% Create Generic Parameters
% =======================================================================
sheet_name = generic_ws;
warning off MATLAB:xlsfinfo:ActiveX
[status, sheets] = xlsfinfo(param_fn);
warning on MATLAB:xlsfinfo:ActiveX
sheet_idx = strmatch(generic_ws,sheets,'exact');
if isempty(sheet_idx)
  warning('  Sheet %s not found.', generic_ws);
  return
end

[num txt] = xlsread(param_fn,sheet_name,'','basic');

num_header_rows = find(strcmp( 'Date' , txt(1:end,1) )) + 1;
if isempty(num_header_rows)
  error('Could not find required "Date" field in first column.');
end

rows = max(size(num,1), size(txt,1)) - num_header_rows;
field_names = txt(num_header_rows-1,:);
field_types = txt(num_header_rows,:);

missing_types = find(cellfun('isempty',field_types) & ~cellfun('isempty',field_names));
if ~isempty(missing_types)
  for col = missing_types
    fprintf('  Field %s (column %s/%d) is missing type definition in row 2\n',field_names{col}, char(65+mod(col-1,26)), col);
  end
  error('Type definitions are missing');
end

%% Create an empty struct to assign parameters to
headers = [];

for col = 3:length(field_names)
  if ~isempty(field_names{col})
    period_idxs = find(field_names{col} == '.');
    
    if any(field_types{col}(1) == 'btr')
      field_type = field_types{col};
      array_type = '0';
    elseif field_types{col}(1) == 'a'
      field_type = field_types{col}(2);
      array_type = 'a';
    elseif field_types{col}(1) == 'c'
      field_type = field_types{col}(2);
      array_type = 'c';
    else
      error('Unsupported field type (%s)', field_types{col});
    end
    if array_type == '0'
      headers(end+1).array_type = array_type;
      headers(end).generic_ws = generic_ws;
      headers(end).field_names = field_names{col};
      headers(end).field_types = field_types{col};
      
    elseif array_type == 'a'
      paren_idx = find(field_types{col}(4:end) == '(');
      if isempty(paren_idx)
        % Size of the struct array field (the size field should go first)
        array_field_name = field_types{col}(4:end);
        array_type = 'as';
        
        headers(end+1).array_type = array_type;
        headers(end).generic_ws = generic_ws;
        headers(end).array_field_name = array_field_name;
        headers(end).field_names = field_names{col};
        headers(end).field_types = field_types{col};
        
      else
        % Fields of the cell array
        array_field_name = field_types{col}(4+(0:paren_idx-2));
        array_field_idx = str2double(field_types{col}(4+paren_idx:end-1));
        
        headers(end+1).array_type = array_type;
        headers(end).generic_ws = generic_ws;
        headers(end).array_field_name = array_field_name;
        headers(end).array_field_idx = array_field_idx;
        headers(end).field_names = field_names{col};
        headers(end).field_types = field_types{col};
        
      end
    elseif array_type == 'c'
      paren_idx = find(field_types{col}(4:end) == '(');
      if isempty(paren_idx)
        % Size of the struct array field (the size field should go first)
        array_field_name = field_types{col}(4:end);
        array_type = 'cs';
        
        headers(end+1).array_type = array_type;
        headers(end).generic_ws = generic_ws;
        headers(end).array_field_name = array_field_name;
        headers(end).field_names = field_names{col};
        headers(end).field_types = field_types{col};
        
      else
        % Fields of the cell array
        array_field_name = field_types{col}(4+(0:paren_idx-2));
        array_field_idx = str2double(field_types{col}(4+paren_idx:end-1));
        
        headers(end+1).array_type = array_type;
        headers(end).generic_ws = generic_ws;
        headers(end).array_field_name = array_field_name;
        headers(end).array_field_idx = array_field_idx;
        headers(end).field_names = field_names{col};
        headers(end).field_types = field_types{col};
        
      end
    end
  end
end
