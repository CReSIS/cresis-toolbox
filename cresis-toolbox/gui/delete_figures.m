function delete_figures(max_fig_num)
% delete_figures(max_fig_num)
%
% Convenience function to delete all figures. This is useful when figures
% have on close callbacks or have visible set of "off".

if ~exist('max_fig_num','var')
  max_fig_num = 10000;
end

for delete_figures_idx = 1:max_fig_num
  try
    delete(delete_figures_idx);
  end
end
