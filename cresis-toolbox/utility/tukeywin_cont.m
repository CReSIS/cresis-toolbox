function H = tukeywin_cont(L,r)
% H = tukeywin_cont(L,r)
%
% Continuous form of Matlab's tukey window
%
% H is window
% L is -0.5 to 0.5 returns nonzero H (zero outside this range)
% r is 0 to 1 (0 = boxcar, 1 = hann)
%
% Example:
% tukeywin_cont(linspace(-0.5,0.5,101),0.5)
% tukeywin(101,0.5).'

if nargin < 2
  r = 0.5;
end

L = L+0.5;
r = r/2;

H = zeros(size(L));

H(0 <= L & L <= r) = 0.5*(1 + cos(pi*(L(0 <= L & L <= r)/r - 1)));

H(1-r <= L & L <= 1) = 0.5*(1 + cos(pi*(L(1-r <= L & L <= 1)/r - 2/r + 1)));

H(r <= L & L <= 1-r) = 1;


end
