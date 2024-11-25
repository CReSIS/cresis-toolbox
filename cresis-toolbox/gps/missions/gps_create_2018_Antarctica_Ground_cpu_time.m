function correction = gps_create_2018_antarctica_Ground_cpu_time(in_base_path)

fns = get_filenames(fullfile(in_base_path,'CPU_TIME'),'cpu_time','','.csv',struct('recursive',true));
[gps_time,cpu_time] = read_cpu_time(fns);
gps_time_origin = gps_time(round(end/2));
pp = polyfit(gps_time-gps_time_origin, gps_time-cpu_time, 5);

correction.gps_time_min = min(gps_time);
correction.gps_time_max = max(gps_time);
correction.gps_time_origin = gps_time_origin;
correction.pp = pp;

if 0
  % Debug plots
  h_fig = figure;
  plot(gps_time-gps_time_origin, gps_time-cpu_time,'.');
  hold on;
  grid on;
  plot(gps_time-gps_time_origin, polyval(pp, gps_time-gps_time_origin));
  plot(gps_time-gps_time_origin, cpu_time + polyval(pp, cpu_time - gps_time_origin) - gps_time,'x');
  xlabel('Relative GPS time (sec)');
  ylabel('Drift (sec)');
  set(h_fig,'UserData',pp)
end
