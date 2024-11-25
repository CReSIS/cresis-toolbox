function layers = smb_to_layers(smb)
% layers = smb_to_layers(smb)
%
% Converts a list of annual surface mass balances at a location into a list
% of layer thicknesses. Accounts for how negative mass balance (e.g. due to
% melting) would affect previous accumulation.
%
% smb: Numeric array. Surface mass balance with the most recent year first.
% Units of meters.
%
% layers: Numeric array. Layer thicknesses associated with the surface mass
% balances.
%
% Example:
%  smb = [1 -2 1 1 0.5 1 -2 2.1 1.5];
%  % This means the most recent year has 1 m of accumulation, the year
%  % before had 2 m of melt, the year before that had 1 m of accum, etc.
%  layers = smb_to_layers(smb)
% 
%  % Expected output explanation:
%  % layers = [1 0 0 0 0.5 1 0 0.1 1.5]
%  % The first -2 cancels out the two 1's that came before it.
%  % The second -2 only partially cancels out the 2.1 that came before it.

% How much melt has accumulated
cur_melt = 0;

% Starting from the most recent year, progress back through time to
% reconstruct the layers
layers = zeros(size(smb));
for idx = 1:length(smb)
  if smb(idx) < 0
    % Negative smb, so layer has zero thickness and we need to cumulate the
    % melt into cur_melt
    cur_melt = cur_melt - smb(idx);
    layers(idx) = 0;
  elseif cur_melt > 0
    % Positive smb, but there is unaccounted for melting from a previous
    % year
    cur_melt = cur_melt - smb(idx);
    if cur_melt < 0
      layers(idx) = -cur_melt;
      cut_melt = 0;
    end
  else
    % Simple case where there is no accumulated melt and the smb is
    % positive. The layer thickness is equal to the smb.
    layers(idx) = smb(idx);
  end
end
