function [out] = read_param_xls_general(row,col,num,txt)
% [out] = read_param_xls_general(row,col,num,txt)
% 
% General Cell Read Function
%
% Support function for read_param_xls_*
%
% Author: John Paden, Brady Maasen
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

if size(num,1) < row || size(num,2) < col
  if size(txt,1) >= row && size(txt,2) >= col && ~isempty(txt{row,col})
    out = eval(txt{row,col});
  else
    out = [];
  end
elseif isnan(num(row,col))
  if size(txt,1) < row || size(txt,2) < col || isempty(txt{row,col})
    out = [];
  else
    out = eval(txt{row,col});
  end
else
  out = num(row,col);
end


return
