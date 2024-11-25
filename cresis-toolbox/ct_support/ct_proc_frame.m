function proc_frm = ct_proc_frame(frm_type,frm_types_to_proc)
% proc_frm = ct_proc_frame(frm_type,frm_types_to_proc)
%
% Used by get_heights, csarp, etc. to determine if a frame should be
% processed or not.
%
% frm_type = The type of frame. Usually from frames file: frames.proc_mode(frame).
%   See frames file definition on wiki.  This scalar is broken into
%   a decimal mask:
%     U* | R4 | R3 | R2 | R1
%   Example: 87654321 --> U = 8765, R4 = 4, R3 = 3, R2 = 2, R1 = 1
% frm_types_to_proc = 5 element cell array of vectors. Each position of the
%   cell array corresponds to one of the frame type decimal digit masks.
%   Entering a negative number into a cell means that particular mask is
%   ignored. The 5 elements are:
%   R1: SAR/Doppler domain controls
%   R2: 0 = good frame/process, 1 = process but do not post, 2 = do not process or post
%   R3: Reserved
%   R4: Reserved
%   U: User defined
%
% proc_frm = boolean indicating whether or not to process this frame. Will
%   be an array of the same size as frm_type where each entry indicates the
%   validity of the corresponding entry in frm_type
%
% Examples:
%
% % Process R1 = 0, R2 = 0 or 1, R3 = 0, R4 = 0, U = 0
% proc_frm = ct_proc_frame(10,{0,[0 1],0,0,0})
% proc_frm = ct_proc_frame(10,{0,[0 1],0,0,1})
% proc_frm = ct_proc_frame(10010,{0,[0 1],0,0,1})
%
% % Process R1 = 0, R2 = 0 or 1, R3, R4, and U do not matter
% proc_frm = ct_proc_frame(55510,{0,[0 1],-1,-1,-1})
% proc_frm = ct_proc_frame(342310,{0,[0 1],-1,-1,-1})

proc_frm = logical(ones(size(frm_type)));
for idx = 1:numel(frm_type)
  for digit = 1:5
    frm_proc_mode_digit = mod(frm_type(idx),10);
    frm_type(idx) = floor(frm_type(idx)/10);
    if all(frm_types_to_proc{digit} >= 0) && ~any(frm_proc_mode_digit == frm_types_to_proc{digit})
      proc_frm(idx) = false;
      break;
    end
  end
end

end
