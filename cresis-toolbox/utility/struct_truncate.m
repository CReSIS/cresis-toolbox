function records = struct_truncate(records,rec_len,start_idx,stop_idx,depth)
% function records = struct_truncate(records,rec_len,start_idx,stop_idx,depth)
% Truncate fields of length rec_len to start_idx:stop_idx
% Recursively looks up to depth levels in the  parent struct
% Written for use with full simulator's flightline_extract.m
%
% Usage:
%   records = struct_truncate(records,rec_len,start_idx,stop_idx,0);
%
% Author: Hara Madhav Talasila
%
% See also: 

rec_fields = fieldnames(records);

if depth >= 0
  for idx = 1:length(rec_fields)
    if eval(sprintf('length(records.%s)',rec_fields{idx})) == rec_len
      eval(sprintf('records.%s = records.%s(start_idx:stop_idx);',rec_fields{idx},rec_fields{idx}));
    elseif eval(sprintf('isstruct(records.%s)',rec_fields{idx})) && eval(sprintf('length(records.%s)',rec_fields{idx})) == 1
      eval(sprintf('records.%s = struct_truncate(records.%s,rec_len,start_idx,stop_idx,depth-1);',rec_fields{idx},rec_fields{idx}));
    end
  end
end

end