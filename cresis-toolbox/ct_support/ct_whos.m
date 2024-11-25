function size_bytes = ct_whos(field)
% size_bytes = ct_whos(field)
%
% Convenience function to get the size in bytes of a variable. Useful in
% general to save a couple of lines of code.
%
% Example:
% S.A = ones(1,3);
% S.B = ones(4,4);
% ct_whos(S)
% ct_whos(S.A)
% ct_whos(S.B)
%
% Author: John Paden

s = whos('field');
size_bytes = s.bytes;
