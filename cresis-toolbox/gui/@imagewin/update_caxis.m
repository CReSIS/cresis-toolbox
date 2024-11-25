function update_caxis(obj,varargin)

if ~ishandle(obj.img)
  return;
end

cmap = get(obj.h_gui.colormapPM,'Value');
if cmap == 1
  base_cmap = 1-gray(256);
else
  base_cmap = jet(256);
end
hist_exp = obj.h_gui.hist_slider.get_value();
cmap = interp1(linspace(0,1,256).', base_cmap, linspace(0,1,256).^(10.^(hist_exp/10)));

if ~get(obj.h_gui.caxis_autoCB,'Value')
  clims = obj.h_gui.min_slider.get_value();
  clims(2) = obj.h_gui.max_slider.get_value();
  clims = sort(clims);
  
  caxis(get(obj.img,'parent'),clims);
  colormap(get(obj.img,'parent'),cmap);
  
else
  xlims = xlim(get(obj.img,'parent'));
  ylims = ylim(get(obj.img,'parent'));
  X = get(obj.img,'XData');
  Y = get(obj.img,'YData');
  C = get(obj.img,'CData');
  
  if isempty(X)
    return;
  end
  xbins = sort(interp1(X([1 end]), [1 size(C,2)], xlims, 'linear', 'extrap'));
  xbins(1) = max(1,floor(xbins(1)));
  xbins(2) = min(size(C,2),ceil(xbins(2)));
  
  ybins = sort(interp1(Y([1 end]), [1 size(C,1)], ylims, 'linear', 'extrap'));
  ybins(1) = max(1,floor(ybins(1)));
  ybins(2) = min(size(C,1),ceil(ybins(2)));

  clims = [finitemin(finitemin(C(ybins(1):ybins(end),xbins(1):xbins(end)))) finitemax(finitemax(C(ybins(1):ybins(end),xbins(1):xbins(end))))];
  
  if numel(clims) == 2 && all(isfinite(clims))
    caxis(get(obj.img,'parent'),clims);
    colormap(get(obj.img,'parent'),cmap);
    
    obj.h_gui.min_slider.set_value(clims(1));
    obj.h_gui.max_slider.set_value(clims(end));
  end
  
end
