function [out] = read_param_xls_text(row,col,num,txt)
% [out] = read_param_xls_text(row,col,num,txt)
%
% Text Cell Read Function
%
% Support function for read_param_xls_*
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

if size(num,1) >= row && size(num,2) >= col && ~isnan(num(row,col))
  error('Cell (%d,%d)/(%d,%s) must be text (use '' before the number)\n', row, col, row, 'A'+col-1);
end
if size(txt,1) < row || size(txt,2) < col
  out = '';
else
  out = txt{row,col};
end


return
