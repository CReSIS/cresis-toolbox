function [params] = read_param_xls_generic(param_fn, generic_ws, params, read_param)
% [params] = read_param_xls_generic(param_fn, generic_ws, params, read_param)
%
% Support function for read_param_xls, generic worksheet reader.
%
% param_fn: MS Excel .xls parameter spreadsheet to load in
% generic_ws: worksheet name to load in
% params: add new fields to this structure
% read_param: structure containing read parameters
%  .update_existing_only: logical, default false, if true this function
%    only updates segments that already exist in params
% 
% Author: Theresa Stumpf, John Paden
%
% See also: ct_set_params, master, read_param_xls
%
% See also for spreadsheet cell loading:
%  read_param_xls_boolean.m, read_param_xls_general.m,
%  read_param_xls_text.m
%  
% See also for worksheet loading:
%  read_param_xls_generic.m, read_param_xls_radar.m: 
%
% See also for printing out spreadsheet to stdout:
%  read_param_xls_print, read_param_xls_print_headers.m

%% Input checks and setup
% =======================================================================

if ~exist('read_param','var') || isempty(read_param)
  read_param = [];
end
if ~isfield(read_param,'update_existing_only') || isempty(read_param.update_existing_only)
  read_param.update_existing_only = false;
end

  
%% Cell input: Recurse to load a list of worksheets
% =======================================================================
if iscell(generic_ws)
  for idx = 1:size(generic_ws,1)
    tmp = read_param_xls_generic(param_fn,generic_ws{idx,1},params,read_param);
    if size(generic_ws,2) > 1
      % Rename the worksheet variable
      [params.(generic_ws{idx,2})] = tmp.(generic_ws{idx,1});
    else
      params = tmp;
    end
  end
  return;
end

%% Create Generic Parameters
% =======================================================================
sheet_name = generic_ws;
fprintf('Reading sheet %s of xls file: %s\n', sheet_name, param_fn);

[~,~,param_fn_ext] = fileparts(param_fn);
matlab_ver = ver('matlab');
use_read_table = str2double(matlab_ver.Version) >= 9.10 || any(strcmpi(param_fn_ext,{'xlsx','ods'}));
clear('matlab_ver');
if use_read_table
  sheets = sheetnames(param_fn);
else
  warning off MATLAB:xlsfinfo:ActiveX
  [status, sheets] = xlsfinfo(param_fn);
  warning on MATLAB:xlsfinfo:ActiveX
end

sheet_idx = strmatch(generic_ws,sheets,'exact');
if isempty(sheet_idx)
  fprintf('  Sheet not found\n');
  return
end

if use_read_table
  read_table_opts = detectImportOptions(param_fn,'NumHeaderLines',0,'Sheet',sheet_name,'ReadVariableNames',false);
  read_table_opts.DataRange = 'A1';
  for var_idx = 1:length(read_table_opts.VariableTypes)
    read_table_opts.VariableTypes{var_idx} = 'char';
  end
  read_table_output = readtable(param_fn,read_table_opts);
  txt = table2cell(read_table_output);
  num = nan(size(txt));
  for element_idx = 1:numel(txt)
    num(element_idx) = str2double(txt{element_idx});
    if ~isnan(num(element_idx))
      txt{element_idx} = '';
    end
  end
  clear('read_table_opts','read_table_output','var_idx','element_idx');
else
  warning('off','MATLAB:xlsread:Mode');
  [num, txt] = xlsread(param_fn,sheet_name,'','basic');
  warning('on','MATLAB:xlsread:Mode');
end

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
% =======================================================================
if ~isfield(params,'day_seg')
  params = struct('day_seg',[]);
end
params(1).(generic_ws) = struct([]);

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
      params(1).(generic_ws) ...
        = struct_add_field(params(1).(generic_ws), field_names{col}, {[]});
    elseif array_type == 'a'
      paren_idx = find(field_types{col}(4:end) == '(');
      if ~isempty(paren_idx)
        % Fields of the struct array
        array_field_name = field_types{col}(4+(0:paren_idx-2));
        
        if ~isfield(params(1).(generic_ws),array_field_name)
          params(1).(generic_ws).(array_field_name) = [];
        end
        params(1).(generic_ws).(array_field_name) ...
          = struct_add_field(params(1).(generic_ws).(array_field_name), field_names{col}, {[]});
      end
    elseif array_type == 'c'
      paren_idx = find(field_types{col}(4:end) == '(');
      if ~isempty(paren_idx)
        % Fields of the struct array
        array_field_name = field_types{col}(4+(0:paren_idx-2));
        
        if ~isfield(params(1).(generic_ws),array_field_name)
          params(1).(generic_ws).(array_field_name) = {};
        end
      end
    end
  end
end

%% Read in each day_seg row
% =======================================================================
for idx = 1:rows
  row = idx + num_header_rows;
  if row > size(num,1)
    error('xls row %d error: There is content on this or a later row, but there is no day segment. No content should be placed below the last day segment row.', row);
  end
  if size(num,2) < 2 || ~isfinite(num(row,1)) || ~isfinite(num(row,2))
    error('xls row %d error: The day segment is not formed properly on this row.', row);
  end
  day_seg = sprintf('%08.0f_%02.0f',num(row,1),num(row,2));
  if strcmpi(generic_ws,'cmd')
    params(idx).day_seg = day_seg;
  elseif (idx > length(params) || ~strcmpi(params(idx).day_seg,day_seg))
    if read_param.update_existing_only
      % Try to find this segment in the existing list of segments
      idx = strmatch(day_seg, {params.day_seg});
      if isempty(idx)
        % Not found, so we skip this row
        continue;
      elseif length(idx) > 1
        error('xls row %d error: More than one matching segment to "%s" found in input params.', row, day_seg);
      end
    else
      error('The date segment order of sheets cmd and %s do not match at row %d in the excel spreadsheet. Each sheet must have the same date and segment list.',sheet_name,row);
    end
  end
  for col = 3:length(field_names)
    try
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
        if field_type == 'b'
          val = read_param_xls_boolean(row,col,num,txt);
        elseif field_type == 't'
          val = read_param_xls_text(row,col,num,txt);
        else
          val = read_param_xls_general(row,col,num,txt);
        end
        if array_type == '0'
          eval_str = sprintf('params(idx).(generic_ws).%s = val;',field_names{col});
          eval(eval_str);
        elseif array_type == 'a'
          paren_idx = find(field_types{col}(4:end) == '(');
          if isempty(paren_idx)
            % Size of the struct array field (the size field should go first)
            array_field_name = field_types{col}(4:end);
            params(idx).(generic_ws).(array_field_name) = rmfield(struct('size',cell(1,val)),'size');
          else
            % Fields of the struct array
            array_field_name = field_types{col}(4+(0:paren_idx-2));
            array_field_idx = str2double(field_types{col}(4+paren_idx:end-1));
            
            if ~isfield(params(idx).(generic_ws),array_field_name) ...
                || length(params(idx).(generic_ws).(array_field_name)) >= array_field_idx
              % Only include the field if we don't exceed the declared
              % size of the array
              if length(period_idxs) == 0
                params(idx).(generic_ws).(array_field_name)(array_field_idx).(field_names{col}) = val;
              elseif length(period_idxs) == 1
                params(idx).(generic_ws).(array_field_name)(array_field_idx).(field_names{col}(1:period_idxs-1)).(field_names{col}(period_idxs+1:end)) = val;
              elseif length(period_idxs) == 2
                params(idx).(generic_ws).(array_field_name)(array_field_idx).(field_names{col}(1:period_idxs(1)-1)).(field_names{col}(period_idxs(1)+1:period_idxs(2)-1)).(field_names{col}(period_idxs(2)+1:end)) = val;
              else
                error('read_param_xls_generic:toomanyperiods', ...
                  ' Fieldnames %s with more than 2 periods not supported', field_names{col})
              end
            else
              if ~isempty(val)
                fprintf('  Warning in row %d, column %s/%d (field %s)\n', row, char(65+mod(col-1,26)), col, field_names{col});
                fprintf('    Struct array %s should have %d elements, but has more (ignoring)\n', array_field_name, length(params(idx).(generic_ws).(array_field_name)));
              end
            end
          end
        elseif array_type == 'c'
          paren_idx = find(field_types{col}(4:end) == '(');
          if isempty(paren_idx)
            % Size of the struct array field (the size field should go first)
            array_field_name = field_types{col}(4:end);
            params(idx).(generic_ws).(array_field_name) = cell(1,val);
          else
            % Fields of the cell array
            array_field_name = field_types{col}(4+(0:paren_idx-2));
            array_field_idx = str2double(field_types{col}(4+paren_idx:end-1));
            
            if ~isfield(params(idx).(generic_ws),array_field_name) ...
                || length(params(idx).(generic_ws).(array_field_name)) >= array_field_idx
              % Only include the field if we don't exceed the declared
              % size of the array
              if length(period_idxs) == 0
                params(idx).(generic_ws).(array_field_name){array_field_idx}.(field_names{col}) = val;
              elseif length(period_idxs) == 1
                params(idx).(generic_ws).(array_field_name){array_field_idx}.(field_names{col}(1:period_idxs-1)).(field_names{col}(period_idxs+1:end)) = val;
              elseif length(period_idxs) == 2
                params(idx).(generic_ws).(array_field_name)(array_field_idx).(field_names{col}(1:period_idxs(1)-1)).(field_names{col}(period_idxs(1)+1:period_idxs(2)-1)).(field_names{col}(period_idxs(2)+1:end)) = val;
              else
                error('read_param_xls_generic:toomanyperiods', ...
                  ' Fieldnames %s with more than 2 periods not supported', field_names{col})
              end
            else
              if ~isempty(val)
                fprintf('  Warning in row %d, column %s/%d (field %s)\n', row, char(65+mod(col-1,26)), col, field_names{col});
                fprintf('    Cell array %s should have %d elements, but has more (ignoring)\n', array_field_name, length(params(idx).(generic_ws).(array_field_name)));
              end
            end
          end
        end
      end
    catch ME
      if ~strcmp(ME.identifier,'read_param_xls_generic:toomanyperiods')
        fprintf('  Error in row %d, column %s/%d (field %s)\n', row, char(65+mod(col-1,26)), col, field_names{col});
      end
      rethrow(ME)
    end
  end
  
end
