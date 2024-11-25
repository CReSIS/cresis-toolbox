%% Setup

% run_example_str = 'demo_new_file';
% run_example_str = 'demo_exist_file';
run_example_str = 'demo_update_file';

if strcmpi(run_example_str,'demo_new_file')
  % Demonstrate creation of a new surf file
  param = read_param_xls(ct_filename_param('rds_param_2019_Antarctica_Ground.xls'),'20200107_01');
  mdata = echo_load(param,'music3D_paden',1);
  surf = tomo.surfdata(mdata,'surfData_paden');
end

if strcmpi(run_example_str,'demo_exist_file')
  % Demonstrate loading an existing surf file and manipulating it
  
  param = read_param_xls(ct_filename_param('rds_param_2009_Antarctica_TO.xls'),'20091224_01'); frm = 1;
  fn_original = fullfile(ct_filename_out(param,'surfData',''),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
  fn_new = [tempname '.mat'];
  % Ensure that example file is using the most up to date format
  echogram_fn = fullfile(ct_filename_out(param,'music3D',''),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
  tomo.surfdata.update_file(fn_original,fn_new,echogram_fn);
  
  surf = tomo.surfdata(fn_new);
  
  %% get surf
  surf.get_surf('bottom') % get the bottom surface
  surf.get_surf({'top','bottom'}) % get the top and bottom surfaces
  surf.get_surf([1 2 3])
  try
    surf.get_surf('123') % surface does not exist;
  catch ME
    warning(ME.getReport);
  end
  try
    surf.get_surf(20) % invalid index
  catch ME
    warning(ME.getReport);
  end
  try
    surf.get_surf(0) % invalid index
  catch ME
    warning(ME.getReport);
  end
  
  %% insert_surf
  
  % Create a test surf structure from an existing surface
  test_surf = surf.get_surf('bottom');
  test_surf.name = 'my_test_surf';
  
  % Insert test surface
  surf.insert_surf(test_surf);
  surf
  
  % create a test_surf structure where (size of x) != (size of y)
  test_surf = surf.get_surf('bottom');
  test_surf.x = test_surf.x(:,1:round(end/2));
  test_surf.name = 'test';
  try
    surf.insert_surf(test_surf);
  catch ME
    warning(ME.getReport);
  end
  
  % create a test_surf which does not match existing surf x and y sizes
  test_surf = surf.get_surf('bottom');
  test_surf.x = test_surf.x(1:round(end/2),1:round(end/2));
  test_surf.y = test_surf.y(1:round(end/2),1:round(end/2));
  test_surf.name = 'test';
  try
    surf.insert_surf(test_surf);
  catch ME
    warning(ME.getReport);
  end
  
  % insert an invalid struct
  test_surf = struct();
  try
    surf.insert_surf(test_surf);
  catch ME
    warning(ME.getReport);
  end
  
  % insert surf struct with invalid name
  test_surf = surf.surf(1);
  test_surf.name = 123;
  try
    surf.insert_surf(test_surf);
  catch ME
    warning(ME.getReport);
  end
  
  % insert a duplicate
  test_surf = surf.surf(2);
  try
    surf.insert_surf(test_surf);
  catch ME
    warning(ME.getReport);
  end
  
  %% set_name
  surf.set('bottom', 'name', 'bottom2');
  surf.get_surf('bottom2')
  surf.set('bottom2', 'name', 'bottom');
  
  try
    surf.set('123','name','1234'); % surf not exist
  catch ME
    warning(ME.getReport);
  end
  
  %% set_surf and clear_references
  test_surf = surf.get_surf('bottom')
  test_surf = surf.clear_references(test_surf)
  
  surf.set_surf(test_surf);
  surf.get_surf('bottom') % after; check result
  
  % set a surf that is not valid
  try
    surf.set_surf(struct());
  catch ME
    warning(ME.getReport);
  end
  
  % set a surface where the surface name does not match an existing surface
  try
    test_surf = surf.get_surf('bottom');
    test_surf.name = 'other';
    surf.set_surf(test_surf);
  catch ME
    warning(ME.getReport);
  end
  
  %% remove_surf
  test_surf = surf.get_surf('bottom');
  test_surf.name = 'test';
  surf.insert_surf(test_surf);
  surf
  surf.remove_surf('test');
  surf
  
  % See the index changes
  v_names = {'name', 'index', 'top', 'active', 'mask', 'gt', 'quality'};
  
  surf_name = {surf.surf.name}';
  indices = (1:length(surf.surf))';
  surf_top = {surf.surf.top}';
  surf_active = {surf.surf.active}';
  surf_mask = {surf.surf.mask}';
  surf_gt = {surf.surf.gt}';
  surf_quality = {surf.surf.quality}';
  
  table(surf_name, indices, surf_top, ...
    surf_active, surf_mask, ...
    surf_gt, surf_quality, ...
    'VariableNames', v_names)
  
  surf.remove_surf('bottom');
  
  surf_name = {surf.surf.name}';
  indices = (1:length(surf.surf))';
  surf_top = {surf.surf.top}';
  surf_active = {surf.surf.active}';
  surf_mask = {surf.surf.mask}';
  surf_gt = {surf.surf.gt}';
  surf_quality = {surf.surf.quality}';
  
  table(surf_name, indices, surf_top, ...
    surf_active, surf_mask, ...
    surf_gt, surf_quality, ...
    'VariableNames', v_names)
  
  test_surf.name = 'bottom';
  surf.insert_surf(test_surf);
  surf.set({'bottom','ice mask','bottom gt','bottom quality'}, ...
    'top','top','active','bottom','mask','ice mask','gt','bottom gt','quality','bottom quality');
  
  surf_name = {surf.surf.name}';
  indices = (1:length(surf.surf))';
  surf_top = {surf.surf.top}';
  surf_active = {surf.surf.active}';
  surf_mask = {surf.surf.mask}';
  surf_gt = {surf.surf.gt}';
  surf_quality = {surf.surf.quality}';
  
  table(surf_name, indices, surf_top, ...
    surf_active, surf_mask, ...
    surf_gt, surf_quality, ...
    'VariableNames', v_names)
  
  try;
    surf.remove_surf('123'); % error
  catch ME
    warning(ME.getReport)
  end
  
  %% save_surfdata
  surf.save_surfdata(fn_new);
end

% Demonstrate updating a file to the newest format
if strcmpi(run_example_str,'demo_update_file')
  
  param = read_param_xls(ct_filename_param('rds_param_2009_Antarctica_TO.xls'),'20091224_01');
  fn_original = fullfile(ct_filename_out(param,'surfData',''),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
  fn_new = [tempname '.mat'];
  
  echogram_fn = fullfile(ct_filename_out(param,'music3D',''),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
  
  tomo.surfdata.update_file(fn_original,fn_new,echogram_fn);
  
  surf = tomo.surfdata(fn_new);

end
