function cmds_execute(obj,cmds_list,cmds_direction)
% cmds_execute(obj,cmds_list,cmds_direction)
%
% Executes tool commands

if strcmpi(cmds_direction,'redo')
  %% Redo commands
  for cmd_idx = 1:length(cmds_list)
    for sub_idx = 1:length(cmds_list{cmd_idx})
      if strcmpi(cmds_list{cmd_idx}(sub_idx).redo_cmd,'insert')
        cmds_execute_insert(obj,cmds_list{cmd_idx}(sub_idx).redo_args);
      elseif strcmpi(cmds_list{cmd_idx}(sub_idx).redo_cmd,'delete')
        cmds_execute_delete(obj,cmds_list{cmd_idx}(sub_idx).redo_args);
      elseif strcmpi(cmds_list{cmd_idx}(sub_idx).redo_cmd,'layer_new')
        cmds_execute_layer_new(obj,cmds_list{cmd_idx}(sub_idx).redo_args);
      elseif strcmpi(cmds_list{cmd_idx}(sub_idx).redo_cmd,'layer_delete')
        cmds_execute_layer_delete(obj,cmds_list{cmd_idx}(sub_idx).redo_args);
      elseif strcmpi(cmds_list{cmd_idx}(sub_idx).redo_cmd,'layer_edit')
        cmds_execute_layer_edit(obj,cmds_list{cmd_idx}(sub_idx).redo_args);
      end
    end
  end
  
else
  %% Undo commands (cmds_direction == 'undo')
  for cmd_idx = 1:length(cmds_list)
    for sub_idx = length(cmds_list{cmd_idx}):-1:1
      if strcmpi(cmds_list{cmd_idx}(sub_idx).undo_cmd,'insert')
        cmds_execute_insert(obj,cmds_list{cmd_idx}(sub_idx).undo_args);
      elseif strcmpi(cmds_list{cmd_idx}(sub_idx).undo_cmd,'delete')
        cmds_execute_delete(obj,cmds_list{cmd_idx}(sub_idx).undo_args);
      elseif strcmpi(cmds_list{cmd_idx}(sub_idx).undo_cmd,'layer_new')
        cmds_execute_layer_new(obj,cmds_list{cmd_idx}(sub_idx).undo_args);
      elseif strcmpi(cmds_list{cmd_idx}(sub_idx).undo_cmd,'layer_delete')
        cmds_execute_layer_delete(obj,cmds_list{cmd_idx}(sub_idx).undo_args);
      elseif strcmpi(cmds_list{cmd_idx}(sub_idx).undo_cmd,'layer_edit')
        cmds_execute_layer_edit(obj,cmds_list{cmd_idx}(sub_idx).undo_args);
      end
    end
  end
  
end

if 0
  fprintf('========================================================\n');
  fprintf('%d ', obj.eg.layers.lyr_id);
  fprintf('\n');
  fprintf('%d ', obj.eg.layers.lyr_order);
  fprintf('\n');
end

obj.update_layer_plots();

end

%% cmds_execute_insert
function args = cmds_execute_insert(obj,args)
% Execute the insert command on obj.eg.layers
% args{1} = database layer IDs
% args{2} = point IDs
% args{3} = twtt
% args{4} = layer type
% args{5} = layer quality

physical_constants;
vel_air = c/2;
vel_ice = c/(sqrt(er_ice)*2);

%% cmds_execute_insert: Convert layer ID's to layer indices
layer_idx = find(args{1} == obj.eg.layers.lyr_id);

if isempty(layer_idx)
  % This echowin does not have this layer shown, so no updates required
  return;
end

%% cmds_execute_insert: Convert point ID's to point indices
point_idxs = [];
point_id_mask = logical(zeros(size(args{2})));
for point_id_idx = 1:length(args{2})
  point_id = args{2}(point_id_idx);
  new_point = find(point_id == obj.eg.map_id);
  if ~isempty(new_point)
    point_id_mask(point_id_idx) = true;
    point_idxs(end+1) = new_point;
  end
end
%% cmds_execute_insert: Apply insert
obj.eg.layers.y{layer_idx}(point_idxs) = args{3}(point_id_mask);
obj.eg.layers.type{layer_idx}(point_idxs) = args{4}(point_id_mask);
obj.eg.layers.qual{layer_idx}(point_idxs) = args{5}(point_id_mask);

%% cmds_execute_insert: Convert units from twtt to current units
yaxis_choice = get(obj.left_panel.yaxisPM,'Value');
if yaxis_choice == 1 % TWTT
  obj.eg.layers.y_curUnit{layer_idx}(point_idxs) = obj.eg.layers.y{layer_idx}(point_idxs) * 1e6;
  
elseif yaxis_choice == 2 % WGS_84 Elevation
  elevation = interp1(obj.eg.gps_time,...
    obj.eg.elev,...
    obj.eg.layers.x,'linear','extrap');
  surface = interp1(obj.eg.gps_time,...
    obj.eg.surf_twtt,...
    obj.eg.layers.x,'linear','extrap');
  for point_idx = point_idxs
    if isnan(obj.eg.layers.y{layer_idx}(point_idx))
      obj.eg.layers.y_curUnit{layer_idx}(point_idx) = NaN;
    else
      range = min(obj.eg.layers.y{layer_idx}(point_idx),surface(point_idx))*vel_air ...
        +max(0,obj.eg.layers.y{layer_idx}(point_idx)-surface(point_idx)) * vel_ice;
      obj.eg.layers.y_curUnit{layer_idx}(point_idx) = elevation(point_idx) - range;
    end
  end
  
elseif yaxis_choice == 3 % Depth/Range
  surface = interp1(obj.eg.gps_time,...
    obj.eg.surf_twtt,...
    obj.eg.layers.x,'linear','extrap');
  for point_idx = point_idxs
    if isnan(obj.eg.layers.y{layer_idx}(point_idx))
      obj.eg.layers.y_curUnit{layer_idx}(point_idx) = NaN;
    else
      obj.eg.layers.y_curUnit{layer_idx}(point_idx) = min(obj.eg.layers.y{layer_idx}(point_idx),surface(point_idx))*vel_air ...
        +max(0,obj.eg.layers.y{layer_idx}(point_idx)-surface(point_idx)) * vel_ice;
    end
  end
  
elseif yaxis_choice == 4 % Range bin
  obj.eg.layers.y_curUnit{layer_idx}(point_idxs) = interp1(obj.eg.time,...
    1:length(obj.eg.time),...
    obj.eg.layers.y{layer_idx}(point_idxs),'linear','extrap');
  
elseif yaxis_choice == 5 % Surface flat
  surface = interp1(obj.eg.gps_time,...
    obj.eg.surf_twtt,...
    obj.eg.layers.x,'linear','extrap');
  for point_idx = point_idxs
    if isnan(obj.eg.layers.y{layer_idx}(point_idx))
      obj.eg.layers.y_curUnit{layer_idx}(point_idx) = NaN;
    else
      obj.eg.layers.y_curUnit{layer_idx}(point_idx) = min(0,obj.eg.layers.y{layer_idx}(point_idx)-surface(point_idx))*vel_air ...
        +max(0,obj.eg.layers.y{layer_idx}(point_idx)-surface(point_idx)) * vel_ice;
    end
  end
  
end

end

%% cmds_execute_delete
function args = cmds_execute_delete(obj,args)
% Execute the delete command on obj.eg.layers and updates the layer handles
% obj.h_layer and obj.h_quality.
%
% args{1} = database layer IDs
% args{2} = [x_min x_max y_min y_max] with x in gps-time and y in twtt
%   units

% obj.eg.layers.x % gps-time
% obj.eg.layers.y{layer_idx} % twtt
% obj.eg.layers.qual{layer_idx} % integer 1-3
% obj.eg.layers.type{layer_idx} % this is either 1 (manual) or 2 (auto)
% obj.eg.layers.x_curUnit % current x-axis units (e.g. along-track km)
% obj.eg.layers.y_curUnit{layer_idx} % current y-axis units (e.g. WGS-84 m)


%% cmds_execute_delete: Convert layer ID's to layer indices
layer_idx = find(args{1} == obj.eg.layers.lyr_id);

if isempty(layer_idx)
  % This echowin does not have this layer shown, so no updates required
  return;
end

%% cmds_execute_delete: Determine which point indices need to be updated
point_idxs = find(obj.eg.layers.x > args{2}(1) & obj.eg.layers.x < args{2}(2) ...
  & obj.eg.layers.y{layer_idx} > args{2}(3) & obj.eg.layers.y{layer_idx} < args{2}(4));

obj.eg.layers.y{layer_idx}(point_idxs) = NaN;
obj.eg.layers.qual{layer_idx}(point_idxs) = 1;
obj.eg.layers.type{layer_idx}(point_idxs) = 1;
obj.eg.layers.y_curUnit{layer_idx}(point_idxs) = NaN;

end

%% cmds_execute_layer_new
function args = cmds_execute_layer_new(obj,args)

id = args{1};
age = args{2};
desc = args{3};
group_name = args{4};
name = args{5};
order = args{6};

% Put the layer in at the end
val = length(obj.eg.layers.lyr_id)+1;

obj.eg.layers.lyr_age = [obj.eg.layers.lyr_age(1:val-1) age obj.eg.layers.lyr_age(val:end)];
obj.eg.layers.lyr_age_source = [obj.eg.layers.lyr_age_source(1:val-1) age obj.eg.layers.lyr_age_source(val:end)];
obj.eg.layers.lyr_desc = [obj.eg.layers.lyr_desc(1:val-1) {desc} obj.eg.layers.lyr_desc(val:end)];
obj.eg.layers.lyr_group_name = [obj.eg.layers.lyr_group_name(1:val-1) {group_name} obj.eg.layers.lyr_group_name(val:end)];
obj.eg.layers.lyr_name = [obj.eg.layers.lyr_name(1:val-1) {name} obj.eg.layers.lyr_name(val:end)];
obj.eg.layers.lyr_id = [obj.eg.layers.lyr_id(1:val-1) id obj.eg.layers.lyr_id(val:end)];
obj.eg.layers.lyr_order = [obj.eg.layers.lyr_order(1:val-1) order obj.eg.layers.lyr_order(val:end)];

obj.eg.layers.selected_layers = false(1,length(obj.eg.layers.lyr_name));
obj.eg.layers.selected_layers(val) = true;
obj.eg.layers.visible_layers = [obj.eg.layers.visible_layers(1:val-1) true obj.eg.layers.visible_layers(val:end)];

obj.eg.layers.y = [obj.eg.layers.y(1:val-1) {nan(size(obj.eg.layers.x))} obj.eg.layers.y(val:end)];
obj.eg.layers.qual = [obj.eg.layers.qual(1:val-1) {ones(size(obj.eg.layers.x))} obj.eg.layers.qual(val:end)];
obj.eg.layers.type = [obj.eg.layers.type(1:val-1) {2*ones(size(obj.eg.layers.x))} obj.eg.layers.type(val:end)];
obj.eg.layers.y_curUnit = [obj.eg.layers.y_curUnit(1:val-1) {nan(size(obj.eg.layers.x_curUnit))} obj.eg.layers.y_curUnit(val:end)];

obj.h_layer = [obj.h_layer(1:2*(val-1)) nan(1,2) obj.h_layer(2*val-1:end)];
obj.h_quality = [obj.h_quality(1:6*(val-1)) nan(1,6) obj.h_quality(6*val-5:end)];

idx = val;
% Manual points (plot this way to handle empty XData or YData
obj.h_layer(2*(idx-1)+1) = plot(obj.h_axes,NaN,NaN,'bx');
% Auto and manual points
obj.h_layer(2*(idx-1)+2) = plot(obj.h_axes, ...
  NaN,NaN,'b--');

% Good manual points (plot this way to handle empty XData or YData
obj.h_quality(6*(idx-1)+1) = plot(obj.h_axes,1,1,'gx');

% Good auto points (plot this way to handle empty XData or YData
obj.h_quality(6*(idx-1)+2) = plot(obj.h_axes,1,1,'g--');

% Moderate manual points (plot this way to handle empty XData or YData
obj.h_quality(6*(idx-1)+3) = plot(obj.h_axes,1,1,'yx');

% Moderate auto points (plot this way to handle empty XData or YData
obj.h_quality(6*(idx-1)+4) = plot(obj.h_axes,1,1,'y--');

% Derived manual points (plot this way to handle empty XData or YData
obj.h_quality(6*(idx-1)+5) = plot(obj.h_axes,1,1,'rx');

% Derived auto points (plot this way to handle empty XData or YData
obj.h_quality(6*(idx-1)+6) = plot(obj.h_axes,1,1,'r--');

set(obj.h_quality(6*(idx-1)+(1:6)),'Visible','off');
set(obj.h_layer(2*(idx-1)+1),'Visible','on');  % manual

% Reorder layers based on new "order" field
Nlayers = length(obj.eg.layers.lyr_id);
[~,new_order] = sort(obj.eg.layers.lyr_order);
val = find(new_order==val);

obj.eg.layers.lyr_age = obj.eg.layers.lyr_age(new_order);
obj.eg.layers.lyr_age_source = obj.eg.layers.lyr_age_source(new_order);
obj.eg.layers.lyr_desc = obj.eg.layers.lyr_desc(new_order);
obj.eg.layers.lyr_group_name = obj.eg.layers.lyr_group_name(new_order);
obj.eg.layers.lyr_id = obj.eg.layers.lyr_id(new_order);
obj.eg.layers.lyr_name = obj.eg.layers.lyr_name(new_order);
obj.eg.layers.lyr_order = obj.eg.layers.lyr_order(new_order);
obj.eg.layers.selected_layers = obj.eg.layers.selected_layers(new_order);
obj.eg.layers.visible_layers = obj.eg.layers.visible_layers(new_order);
obj.eg.layers.y = obj.eg.layers.y(new_order);
obj.eg.layers.qual = obj.eg.layers.qual(new_order);
obj.eg.layers.type = obj.eg.layers.type(new_order);
obj.eg.layers.y_curUnit = obj.eg.layers.y_curUnit(new_order);

obj.h_layer = obj.h_layer(reshape(bsxfun(@plus,repmat(new_order,[2 1])*2,[-1:0].'),[1 Nlayers*2]));
obj.h_quality = obj.h_quality(reshape(bsxfun(@plus,repmat(new_order,[6 1])*6,[-5:0].'),[1 Nlayers*6]));

obj.plot_layers();
obj.set_visibility();

obj.layerLB_str(true);
set(obj.left_panel.layerLB,'Value',val);

end

%% cmds_execute_layer_delete
function args = cmds_execute_layer_delete(obj,args)

% Determine which layer to delete:
id = args{1};
val = find(id == obj.eg.layers.lyr_id);

obj.eg.layers.lyr_age = [obj.eg.layers.lyr_age(1:val-1) obj.eg.layers.lyr_age(val+1:end)];
obj.eg.layers.lyr_age_source = [obj.eg.layers.lyr_age_source(1:val-1) obj.eg.layers.lyr_age_source(val+1:end)];
obj.eg.layers.lyr_desc = [obj.eg.layers.lyr_desc(1:val-1) obj.eg.layers.lyr_desc(val+1:end)];
obj.eg.layers.lyr_group_name = [obj.eg.layers.lyr_group_name(1:val-1) obj.eg.layers.lyr_group_name(val+1:end)];
obj.eg.layers.lyr_id = [obj.eg.layers.lyr_id(1:val-1) obj.eg.layers.lyr_id(val+1:end)];
obj.eg.layers.lyr_name = [obj.eg.layers.lyr_name(1:val-1) obj.eg.layers.lyr_name(val+1:end)];
obj.eg.layers.lyr_order = [obj.eg.layers.lyr_order(1:val-1) obj.eg.layers.lyr_order(val+1:end)];
obj.eg.layers.selected_layers = false(1,length(obj.eg.layers.lyr_name));
obj.eg.layers.visible_layers = [obj.eg.layers.visible_layers(1:val-1) obj.eg.layers.visible_layers(val+1:end)];
obj.eg.layers.y = [obj.eg.layers.y(1:val-1) obj.eg.layers.y(val+1:end)];
obj.eg.layers.qual = [obj.eg.layers.qual(1:val-1) obj.eg.layers.qual(val+1:end)];
obj.eg.layers.type = [obj.eg.layers.type(1:val-1) obj.eg.layers.type(val+1:end)];
obj.eg.layers.y_curUnit = [obj.eg.layers.y_curUnit(1:val-1) obj.eg.layers.y_curUnit(val+1:end)];

delete(obj.h_layer((val-1)*2+(1:2)));
delete(obj.h_quality((val-1)*6+(1:6)));
obj.h_layer = [obj.h_layer(1:2*(val-1)) obj.h_layer(2*(val+1)-1:end)];
obj.h_quality = [obj.h_quality(1:6*(val-1)) obj.h_quality(6*(val+1)-5:end)];

obj.layerLB_str(true);
set(obj.left_panel.layerLB,'Value',[]);

end

%% cmds_execute_layer_edit
function args = cmds_execute_layer_edit(obj,args)

id = args{1};
age = args{2};
desc = args{3};
group_name = args{4};
name = args{5};
order = args{6};

% Determine which layer to edit:
id = args{1};
val = find(id == obj.eg.layers.lyr_id);

obj.eg.layers.lyr_age(val) = age;
obj.eg.layers.lyr_age_source{val} = struct('age',{},'source',{},'type',{});
obj.eg.layers.lyr_desc{val} = desc;
obj.eg.layers.lyr_group_name{val} = group_name;
obj.eg.layers.lyr_name{val} = name;
obj.eg.layers.lyr_order(val) = order;

% Reorder layers based on new "order" field
Nlayers = length(obj.eg.layers.lyr_id);
[~,new_order] = sort(obj.eg.layers.lyr_order);
val = find(new_order==val);

obj.eg.layers.lyr_age = obj.eg.layers.lyr_age(new_order);
obj.eg.layers.lyr_age_source = obj.eg.layers.lyr_age_source(new_order);
obj.eg.layers.lyr_desc = obj.eg.layers.lyr_desc(new_order);
obj.eg.layers.lyr_group_name = obj.eg.layers.lyr_group_name(new_order);
obj.eg.layers.lyr_id = obj.eg.layers.lyr_id(new_order);
obj.eg.layers.lyr_name = obj.eg.layers.lyr_name(new_order);
obj.eg.layers.lyr_order = obj.eg.layers.lyr_order(new_order);
obj.eg.layers.selected_layers = obj.eg.layers.selected_layers(new_order);
obj.eg.layers.visible_layers = obj.eg.layers.visible_layers(new_order);
obj.eg.layers.y = obj.eg.layers.y(new_order);
obj.eg.layers.qual = obj.eg.layers.qual(new_order);
obj.eg.layers.type = obj.eg.layers.type(new_order);
obj.eg.layers.y_curUnit = obj.eg.layers.y_curUnit(new_order);

obj.h_layer = obj.h_layer(reshape(bsxfun(@plus,repmat(new_order,[2 1])*2,[-1:0].'),[1 Nlayers*2]));
obj.h_quality = obj.h_quality(reshape(bsxfun(@plus,repmat(new_order,[6 1])*6,[-5:0].'),[1 Nlayers*6]));

obj.layerLB_str(true);
set(obj.left_panel.layerLB,'Value',val);

end
