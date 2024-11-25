function nums = arena_convert_range(str)
% Converts arena string from a list of ranges or a binary mask into a list
% of numbers.
%
% Examples
% =========================================================================
%
% List of ranges:
%
% arena_convert_range('0:2 4 5 7:10')
% ans =
%      0     1     2     4     5     7     8     9    10
% arena_convert_range('0:2,4,5,7:10')
% ans =
%      0     1     2     4     5     7     8     9    10
%
% Binary Mask:
%
% arena_convert_range('00000X0X')
% ans =
%      0     1     4     5
% arena_convert_range('0000010X')
% ans =
%      4     5
% arena_convert_range('000xx10x')
% ans =
%      4     5    12    13    20    21    28    29

str = upper(str(:).');

if any(str=='X') || all(str=='0' | str=='1' & length(str) > 1)
  % Binary mask
  num_X = length(str(str == 'X'));
  nums = zeros(1,2^num_X);
  for idx = 0:2^num_X-1
    tmp_str = str;
    tmp_str(str=='X') = dec2bin(idx,num_X);
    nums(1+idx) = bin2dec(tmp_str);
  end
  
else
  % Mode ranges
  nums = eval(['[' str ']']);
end
