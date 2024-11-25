function save_default_params(obj)

cur_unit = get(obj.h_fig,'Units');
set(obj.h_fig,'Units','pixels')
mapwin_pos = get(obj.h_fig,'Position');
set(obj.h_fig,'Unit',cur_unit);
obj.default_params.mapwin.x = mapwin_pos(1);
obj.default_params.mapwin.y = mapwin_pos(2);
obj.default_params.mapwin.w = mapwin_pos(3);
obj.default_params.mapwin.h = mapwin_pos(4);

obj.default_params.prefwin = obj.map_pref.default_params;

if length(obj.echowin_list) >= 1
  idx = 1;
  cur_unit = get(obj.echowin_list(idx).h_fig,'Units');
  set(obj.echowin_list(idx).h_fig,'Units','pixels')
  echowin_pos = get(obj.echowin_list(idx).h_fig,'Position');
  set(obj.echowin_list(idx).h_fig,'Unit',cur_unit);
  obj.default_params.echowin.x = echowin_pos(1);
  obj.default_params.echowin.y = echowin_pos(2);
  obj.default_params.echowin.w = echowin_pos(3);
  obj.default_params.echowin.h = echowin_pos(4);
end

default_params = obj.default_params;

try
  fprintf('Saving user parameters file: %s\n', obj.default_params.picker_param_fn);
  ct_save(obj.default_params.picker_param_fn,'-append','-struct','default_params','mapwin','prefwin','echowin');
catch ME
  warning('Failed to save default parameters file %s', obj.default_params.picker_param_fn);
end
