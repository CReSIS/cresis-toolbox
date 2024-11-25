function frm_strs = ct_get_frame_list(params,get_mode)
% frm_strs = ct_get_frame_list(params,get_mode)
%
% Returns a cell array of frame strings {'YYYYMMDD_SS_FFF', ...}
%
% params: this may be a struct or a filename. If a struct, it should be the
% parameter structure returned from read_param_xls. If a filename, it
% should be the parameter spreadsheet filename.
%
% get_mode: scalar numeric. Default is 0. If 0, then all segments without
% "do not process" in cmd.notes are returned. All frames will be included.
% If 1, then all segments are returned. All frames will be included. If 2,
% then only segments with cmd.generic enabled are listed. Only frames that
% are selected with cmd.frms.
%
% frm_strs: cell vector of frame strings {'YYYYMMDD_SS_FFF', ...}
%
% Examples:
%  frm_strs = ct_get_frame_list(ct_filename_param('kuband_param_2011_Greenland_P3.xls'));
%
%  params = read_param_xls(ct_filename_param('kuband_param_2011_Greenland_P3.xls'));
%  frm_strs = ct_get_frame_list(params);
%  frm_strs = ct_get_frame_list(params,1);
%  params = ct_set_params(params,'cmd.generic',1,'cmd.notes','do not process');
%  frm_strs = ct_get_frame_list(params,2);
%
% Author: John Paden
%
% See also: ct_get_segment_list, ct_get_frame_list

if ~exist('get_mode','var') || isempty(get_mode)
  get_mode = 0;
end

if ischar(params)
  % Parameter spreadsheet filename
  params = read_param_xls(params);
end

frm_strs = {};

for param_idx = 1:length(params)
  frames = frames_load(params(param_idx));
  if get_mode == 0
    if ~isfield(params(param_idx),'cmd') || ~isfield(params(param_idx).cmd,'notes') ...
        || isempty(regexpi(params(param_idx).cmd.notes,'do not process'))
      for frm = 1:length(frames.frame_idxs)
        frm_strs{end+1} = sprintf('%s_%03d',params(param_idx).day_seg, frm);
      end
    end
  elseif get_mode == 1
    day_segs{end+1} = params(param_idx).day_seg;
    for frm = 1:length(frames.frame_idxs)
      frm_strs{end+1} = sprintf('%s_%03d',params(param_idx).day_seg, frm);
    end
  else
    if ct_generic_en(params(param_idx))
      day_segs{end+1} = params(param_idx).day_seg;
      frms = frames_param_cmd_frms(params(param_idx),frames);
      for frm = frms
        frm_strs{end+1} = sprintf('%s_%03d',params(param_idx).day_seg, frm);
      end
    end
  end
  
end
