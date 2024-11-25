function [mean_vals] = gmean()
% function [mean_vals] = gmean()
%
% Graphical interface for calculating the mean of data plotted in a figure
% window axis.  
%
% Author: Logan Smith


disp('Select upper-left and lower-right bounds...')
[x,y] = ginput(2);
x = round(x);
chldn = get(gca,'Children');
mean_vals = [];
for idx=1:length(chldn)
  chld_info = get(chldn(idx));
  if strcmp(chld_info.Type,'line')
    xl(1) = find(chld_info.XData >= x(1),1);
    xl(2) = find(chld_info.XData >= x(2),1);
    if chld_info.YData(round(mean(xl))) < max(y) && chld_info.YData(round(mean(xl))) > min(y)
      sprintf('Name: %s\nMean: %2.2f\n',...
        chld_info.DisplayName,...
        10*log10(mean(10.^(chld_info.YData(xl(1):xl(2))./10))))
      %         sprintf('Name: %s\nLinetype: %s\nColor: %s\nMarker: %s\nMean: %2.2f\n\n',...
      %       chld_info.DisplayName,...
      %       strrep(chld_info.LineStyle,'none',''),...
      %       num2str(chld_info.Color),...
      %       strrep(chld_info.Marker,'none',''),...
      %       mean(chld_info.YData(x(1):x(2))))
      mean_vals(end+1) = 10*log10(mean(10.^(chld_info.YData(xl(1):xl(2))./10)));
    end
  end
end

return
