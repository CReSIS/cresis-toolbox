%% tracker_sim_cluster


global gRadar;

param = gRadar;

ctrl = cluster_new_batch(param);
ctrl.cluster.type = 'debug';
% ctrl.cluster.type = 'torque';


% cluster_compile({'tracker_sim_task.m'},[],0,ctrl);% This would need input dependencies
cluster_compile({'tracker_sim_task.m'},ctrl.cluster.hidden_depend_funs,ctrl.cluster.force_compile,ctrl);


cpu_time = 10000;
mem = 10e9;
% find out mem_mult and incorporate here 

block = true;


% Create task 
% Confirm sparam from others (tomo, analysis, qlook etc)
sparam.argsin{1} = param;
sparam.task_function = 'tracker_sim_task';

sparam.num_args_out = 1;
sparam.argsin{1}.tracker_sim.num_layers = 10; % Number of layers
sparam.argsin{1}.tracker_sim.output_dir = 'fixedsnr_randomlayers'; % This should be changed

repeat_task = 1000;

dparam = [];

dparam.cpu_time = cpu_time ; % * sparam.argsin{1}.tracker_sim.num_layers;
dparam.mem = mem ;  

for tmp = 1:repeat_task
%   update dparam.argsin{tmp}
  dparam.argsin{1}.tracker_sim.num_layers = randi([5 12]);
  dparam.argsin{1}.tracker_sim.img_idx = tmp;  

  ctrl = cluster_new_task(ctrl,sparam,dparam,'dparam_save',0);
  
end

% cluster_save_dparam
ctrl = cluster_save_dparam(ctrl);
  
fprintf('Submitting %s \n', ctrl.batch_dir);
ctrl_chain = {{ctrl}};
ctrl_chain = cluster_run(ctrl_chain,block);
[in,out] = cluster_print(ctrl_chain{1}{1}.batch_id,1,0);
% cluster_cleanup(ctrl);


