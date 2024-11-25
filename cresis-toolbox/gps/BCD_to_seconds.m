function seconds = BCD_to_seconds(seconds_BCD,BCD_order)
% seconds = BCD_to_seconds(seconds_BCD,BCD_order)
%
% Converts from 32 bit BCD encoded time to seconds of day
%
% BCD_order: Scalar integer. Default is -1. Defines the order of the
% decimal numbers in the 32 bit integer. -1 is reverse order. +1 is forward
% order.

if ~exist('BCD_order','var') || isempty(BCD_order)
    BCD_order = -1;
end

seconds_BCD = double(seconds_BCD);

if BCD_order == -1
    % BCD encoded into 32 bits as:
    % SSMMHH--
    % (reverse order so that least significant decimal digit comes first)
    seconds = ...
        3600*(10*mod(floor(seconds_BCD/2^8),2^4) + mod(floor(seconds_BCD/2^12),2^4)) ...
        + 60*(10*mod(floor(seconds_BCD/2^16),2^4) + mod(floor(seconds_BCD/2^20),2^4)) ...
        + (10*mod(floor(seconds_BCD/2^24),2^4) + mod(floor(seconds_BCD/2^28),2^4));
else
    % BCD encoded into 32 bits as:
    % --HHMMSS
    seconds = ...
        3600*(10*mod(floor(seconds_BCD/2^20),2^4) + mod(floor(seconds_BCD/2^16),2^4)) ...
        + 60*(10*mod(floor(seconds_BCD/2^12),2^4) + mod(floor(seconds_BCD/2^8),2^4)) ...
        + (10*mod(floor(seconds_BCD/2^4),2^4) + mod(floor(seconds_BCD/2^0),2^4));
end