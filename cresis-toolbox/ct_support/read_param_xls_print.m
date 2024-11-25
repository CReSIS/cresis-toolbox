function read_param_xls_print(param_fn, generic_ws, params, fid)
% read_param_xls_print(param_fn, generic_ws, params, fid)
%
% Support function for read_param_xls, generic worksheet reader.
%
% param_fn: MS Excel .xls parameter spreadsheet to load in
% generic_ws: worksheet name to load in
% params: add new fields from this cell array of structures. A cell array
%   is used to handle dissimilar structures.
%
% Author: John Paden
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
%  read_param_xls_print.m, read_param_xls_print_headers.m
%
% See also for printing matlab values:
%  mat2str_generic.m

if ~exist('fid','var')
  fid = 1; % stdout by default
end

%% Setup
% ======================================================================%
warning('off','MATLAB:xlsread:Mode');

% Get the headers from the parameter spreadsheet
try
  [headers] = read_param_xls_print_headers(param_fn, generic_ws);
catch ME
  warning('Could not read worksheet: %s', ME.getReport);
  return;
end

%% Print headers
% Print field names
fprintf(fid,'Day\t1');
for idx = 1:length(headers)
  fprintf(fid,'\t%s', headers(idx).field_names);
end
fprintf(fid,'\n');

% Print field types
fprintf(fid,'YYYYMMDD\tSegment');
for idx = 1:length(headers)
  fprintf(fid,'\t%s', headers(idx).field_types);
end
fprintf(fid,'\n');

%% Print values
for param_idx = 1:length(params)
  param = params{param_idx};
  
  % Print field values
  fprintf(fid,'%s\t%d', param.day_seg(1:8), str2double(param.day_seg(10:11)));
  for h_idx = 1:length(headers)
    if headers(h_idx).array_type == '0'
      try
        eval_str = sprintf('param.%s.%s',headers(h_idx).generic_ws,headers(h_idx).field_names);
        value = eval(eval_str);
        if isempty(value)
          fprintf(fid,'\t');
        elseif strcmpi(headers(h_idx).field_types,'t')
          fprintf(fid,'\t%s',value);
        elseif strcmpi(headers(h_idx).field_types,'r')
          fprintf(fid,'\t%s',mat2str_generic(value));
        elseif strcmpi(headers(h_idx).field_types,'b')
          if (value)
            fprintf(fid,'\t1');
          else
            fprintf(fid,'\t');
          end
        end
      catch
        fprintf(fid,'\t');
      end
      
    elseif headers(h_idx).array_type == 'a'
      try
        eval_str = sprintf('numel(param.%s.%s)',headers(h_idx).generic_ws,headers(h_idx).array_field_name);
        value = eval(eval_str);
        if headers(h_idx).array_field_idx <= value
          eval_str = sprintf('param.%s.%s(%d).%s',headers(h_idx).generic_ws,headers(h_idx).array_field_name,headers(h_idx).array_field_idx,headers(h_idx).field_names);
          value = eval(eval_str);
          if isempty(value)
            fprintf(fid,'\t');
          elseif strcmpi(headers(h_idx).field_types(2),'t')
            fprintf(fid,'\t%s',value);
          elseif strcmpi(headers(h_idx).field_types(2),'r')
            fprintf(fid,'\t%s',mat2str_generic(value));
          elseif strcmpi(headers(h_idx).field_types(2),'b')
            if (value)
              fprintf(fid,'\t1');
            else
              fprintf(fid,'\t');
            end
          else
            fprintf(fid,'\t');
          end
        end
      catch
        fprintf(fid,'\t');
      end
      
    elseif headers(h_idx).array_type == 'as'
      try
        eval_str = sprintf('numel(param.%s.%s)',headers(h_idx).generic_ws,headers(h_idx).array_field_name);
        value = eval(eval_str);
        fprintf(fid,'\t%d',value);
      catch
        fprintf(fid,'\t');
      end
      
    elseif headers(h_idx).array_type == 'c'
      try
        eval_str = sprintf('numel(param.%s.%s)',headers(h_idx).generic_ws,headers(h_idx).array_field_name);
        value = eval(eval_str);
        if headers(h_idx).array_field_idx <= value
          eval_str = sprintf('param.%s.%s{%d}.%s',headers(h_idx).generic_ws,headers(h_idx).array_field_name,headers(h_idx).array_field_idx,headers(h_idx).field_names);
          value = eval(eval_str);
          if isempty(value)
            fprintf(fid,'\t');
          elseif strcmpi(headers(h_idx).field_types(2),'t')
            fprintf(fid,'\t%s',value);
          elseif strcmpi(headers(h_idx).field_types(2),'r')
            fprintf(fid,'\t%s',mat2str_generic(value));
          elseif strcmpi(headers(h_idx).field_types(2),'b')
            if (value)
              fprintf(fid,'\t1');
            else
              fprintf(fid,'\t');
            end
          else
            fprintf(fid,'\t');
          end
        end
      catch
        fprintf(fid,'\t');
      end
      
    elseif headers(h_idx).array_type == 'cs'
      try
        eval_str = sprintf('numel(param.%s.%s)',headers(h_idx).generic_ws,headers(h_idx).array_field_name);
        value = eval(eval_str);
        fprintf(fid,'\t%d',value);
      catch
        fprintf(fid,'\t');
      end
      
    end
    
  end
  fprintf(fid,'\n');
end
