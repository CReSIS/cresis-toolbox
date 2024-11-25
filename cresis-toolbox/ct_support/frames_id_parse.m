function [day_seg,frm] = frames_id_parse(frm_id)
% [day_seg,frm] = frames_id_parse(frm_id)
%
% Function for parsing a frame ID string ('YYYYMMDD_SS_FFF') into day
% segment and frame number.
%
% frm_id: string in the form 'YYYYMMDD_SS_FFF'.
%
% day_seg: string containing the day_seg string ('YYYYMMDD_SS')
% frm: numeric value for FFF part of string. If frame FFF part of string
% is missing, then the frm number returned in NaN.
%
% Example:
%   [day_seg,frm] = frames_id_parse('20140310_02_023')
%   [day_seg,frm] = frames_id_parse('20140310_02_023.mat')
%   [day_seg,frm] = frames_id_parse('20140310_02_02345')
%   [day_seg,frm] = frames_id_parse('20140310_02_2')
%   [day_seg,frm] = frames_id_parse('20140310_02')
%   [day_seg,frm] = frames_id_parse({'20140310_02_023','20140310_02_025'})
%   [day_seg,frm] = frames_id_parse({'20140310_02_023','20140310_0'}) % Error test
%
% Author: John Paden

if ischar(frm_id)
  if length(frm_id) < 11
    error('frame_id_parse:frm_id_too_short','The frm_id (%s) string is too short. Length 11 (''YYYYMMDD_SS'') is minimum length.', frm_id);
  end
  day_seg = frm_id(1:11);
  if length(frm_id) < 13
    frm = NaN;
  else
    frm = sscanf(frm_id(13:end),'%d');
  end
  
% elseif isstruct(frm_id)
  % Assume that this is a parameter structure
  
% elseif isnumeric(frm_id)

elseif iscell(frm_id)
  day_seg = cell(size(frm_id));
  frm = nan(size(frm_id));
  for idx = 1:length(frm_id)
    if length(frm_id{idx}) < 11
      error('frame_id_parse:frm_id_too_short','The frm_id{%d} (%s) string is too short. Length 11 (''YYYYMMDD_SS'') is minimum length.', idx, frm_id{idx});
    end
    day_seg{idx} = frm_id{idx}(1:11);
    if length(frm_id{idx}) < 13
      frm(idx) = NaN;
    else
      frm(idx) = sscanf(frm_id{idx}(13:end),'%d');
    end
  end
  
else
  error('frame_id_parse:invalid_frm_id_type','Invalid type of frm_id');
end
