function [clims] = fiddle(hf)

set(hf,'WindowKeyPressFcn',@PT_WindowKeyPressFcn);

function PT_WindowKeyPressFcn(hObj,event)

chldrn = get(hObj,'Children');
if isempty(event.Character)
  event.Character = event.Key;
end
switch event.Character
  case 'z'
    zoom;
  case 'pageup'
    CLim = get(get(hObj,'CurrentAxes'),'CLim');
    CLim(2) = CLim(2) + 3;
    set(get(hObj,'CurrentAxes'),'CLim',CLim);
  case 'pagedown'
    CLim = get(get(hObj,'CurrentAxes'),'CLim');
    if CLim(2) - 3 > CLim(1)
      CLim(2) = CLim(2) - 3;
      set(get(hObj,'CurrentAxes'),'CLim',CLim);
    end
  case 'home'
    CLim = get(get(hObj,'CurrentAxes'),'CLim');
    if CLim(1) + 3 < CLim(2)
      CLim(1) = CLim(1) + 3;
      set(get(hObj,'CurrentAxes'),'CLim',CLim);
    end
  case 'end'
    CLim = get(get(hObj,'CurrentAxes'),'CLim');
    CLim(1) = CLim(1) - 3;
    set(get(hObj,'CurrentAxes'),'CLim',CLim);
end

return

