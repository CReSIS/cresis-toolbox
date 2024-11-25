function H = tukeywin(N,R)
% H = tukeywin(N,R)
%
% Replacement for Matlab's tukeywin to reduce dependence on signal
% processing toolbox.

if nargin < 2 || isempty(R)
  R = 0.5;
end

T = N*R; % tail length
if ~rem(N,2)
  % Even length
  if 1
    H = .5*(1 - cos(2*pi/(T+1)*(1:T/2)'));
  else
    % Match Matlab
    if R <= 0 || N == 1
      H = ones(N,1);
      return
    elseif R >= 1
      H = hanning(N);
      return
    end
    per = R/2;
    tl = floor(per*(N-1))+1;
    H = .5*(1 - cos(pi/((N-1)*per)*(0:tl-1)'));
  end
  H = [H; ones(N-2*length(H),1); H(end:-1:1)];

else
  % Odd length
  if 1
    H = .5*(1 - cos(2*pi*(1:T/2)'/(T+1)));
  else
    % Match Matlab
    if R <= 0 || N == 1
      H = ones(N,1);
      return
    elseif R >= 1
      H = hanning(N);
      return
    end
    per = R/2;
    tl = floor(per*(N-1))+1;
    H = .5*(1 - cos(pi/((N-1)*per)*(0:tl-1)'));
  end
  H = [H; ones(N-2*length(H),1); H(end:-1:1)];
end
