function frms = frames_param_cmd_frms(param,frames)
% frms = frames_param_cmd_frms(param,frames)
% 
% Checks param.cmd.frms and removes any nonexistent frames. If
% param.cmd.frms is empty, then it is set to be all frames.
%
% param: radar parameter spreadsheet structure usually read from
%   read_param_xls.m. Only the param.cmd.frms field is used
% frames: frames file structure usually read with frames_load.m. Only the
%   frames.frame_idxs field is used.
%
% Example:
% frames = frames_load(param);
% param.cmd.frms = frames_param_cmd_frms(param,frames);

if ~isfield(param,'cmd') || ~isfield(param.cmd,'frms') || isempty(param.cmd.frms)
  param.cmd.frms = 1:length(frames.frame_idxs);
end
[valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
if length(valid_frms) ~= length(param.cmd.frms)
  bad_mask = ones(size(param.cmd.frms));
  bad_mask(keep_idxs) = 0;
  warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
    param.cmd.frms(find(bad_mask,1)));
  param.cmd.frms = valid_frms;
end

frms = param.cmd.frms;
