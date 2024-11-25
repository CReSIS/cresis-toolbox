function collate_est_nz_records(params_en,param_override)
%
% function collate_est_nz_records
% 
% Updates old records using results from collate_est_nz_table
% Adds nyquist_zone_hw and records_mask to the settings fiels in records
%
% General order for processing:
% run_collate_est_nz, run_collate_est_nz_tables, run_collate_est_nz_records
%
% Authors: John Paden, Hara Madhav Talasila

%% General Setup
% =========================================================================

param = param_override;

fprintf('=============================================================\n');
fprintf('%s: (%s)\n', mfilename, datestr(now));
fprintf('=============================================================\n');

%% Input Checks
% =========================================================================
if ~isfield(param,'collate_est_nz_table') || isempty(param.collate_est_nz_table)
  param.collate_est_nz_table = [];
end

if ~isfield(param.collate_est_nz_table, 'enable_visible_plot')
  param.collate_est_nz_table.enable_visible_plot = 0;
end

param.collate_est_nz_table.in_dir = fileparts(ct_filename_ct_tmp(params_en{1},'','collate_est_nz',''));
if ~exist(param.collate_est_nz_table.in_dir, 'dir')
  fprintf('Empty directory --> run_analysis results (%s)\n',param.collate_est_nz_table.in_dir);
  return;
end

if ~isfield(param.(mfilename),'debug_out_dir') || isempty(param.(mfilename).debug_out_dir)
  param.collate_est_nz_table.debug_out_dir = mfilename;
end

param.collate_est_nz_table.out_dir = fileparts(ct_filename_ct_tmp(params_en{1},'',param.collate_est_nz_table.debug_out_dir,''));
if ~exist(param.collate_est_nz_table.out_dir, 'dir')
  mkdir(param.collate_est_nz_table.out_dir);
end

%% Collate the results
% =========================================================================

%%% Let this code thinks there is only one image [1 1];
wf = 1;
adc = 1;

for idx = 1:length(params_en)
  fprintf('%d >> %s\n',idx,params_en{idx}.day_seg);
  %% Load the nz_est and records file
  % =====================================================================
  %
  try
    fn = fullfile(param.collate_est_nz_table.in_dir, sprintf('collate_est_nz_wf_%d_adc_%d_%s.mat',wf,adc,params_en{idx}.day_seg));
    testt = load(fn);
  catch
    fprintf('Missing nz_est file: %s\n',fn);
    continue;
  end
  
  if ~exist(records_fn,'file')
    warning('Missing records file: %s',records_fn);
    continue;
  end
  recs_old = records_load(params_en{idx});
  
  if length(recs_old.settings.nyquist_zone) == length(testt.coh_wf.records_mask_set) && testt.coh_wf.sets == length(params_en{idx}.collate_nz_est.nz_table)
    nyquist_zone_hw = NaN(1,length(testt.coh_wf.records_mask_set));
    for set_idx = 1:testt.coh_wf.sets
      nyquist_zone_hw(testt.coh_wf.records_mask_set==set_idx) = params_en{idx}.collate_nz_est.nz_table(set_idx);
    end
  end
  
  bit_mask = zeros(1,length(testt.coh_wf.records_mask_set),'uint8');
  % isnan(nyquist_zone_hw) implies a bad record???
  bit_mask(isnan(nyquist_zone_hw)) = bitor(1,bit_mask(isnan(nyquist_zone_hw)));
  
  %% UPDATE RECORDS
  
  recs_old.nyquist_zone_hw = nyquist_zone_hw;
  recs_old.bit_mask = bit_mask;
  fprintf('Saving records file %s (%s)\n',records_fn,datestr(now));
  ct_save(records_fn,'-struct','recs_old','bit_mask','nyquist_zone_hw');
  
  %% FIGURES
  
  cur_fig = get_figures(1,param.collate_est_nz_table.enable_visible_plot);
  clf(cur_fig);
  if param.collate_est_nz_table.enable_visible_plot
    figure(cur_fig); % Brings the current figure to the top
  end
  h_axes = axes('parent',cur_fig);
  subplot(4,2,1,h_axes);
  plot(h_axes,testt.coh_wf.records_mask_set,'LineWidth',1);
  hold(h_axes,'on');
  xlabel(h_axes,sprintf('Records (%d) -->',length(testt.coh_wf.records_mask_set)));
  ylabel(h_axes,'Set ID');
  grid(h_axes,'on');
  axis(h_axes,'tight');
  ylim(h_axes,[0 max(testt.coh_wf.records_mask_set)+1]);
  title(h_axes,'Records classified into sets');
  hold(h_axes,'off');
  
  h_axes = axes('parent',cur_fig);
  subplot(4,2,3,h_axes);
  plot(h_axes,recs_old.settings.records_mask,'LineWidth',1);
  hold(h_axes,'on');
  xlabel(h_axes,sprintf('Records (%d) -->',length(testt.coh_wf.records_mask_set)));
  ylabel(h_axes,'mask');
  grid(h_axes,'on');
  axis(h_axes,'tight');
  ylim(h_axes,[-0.2 1.2]);
%   title(h_axes,'Records classified into sets');
  hold(h_axes,'off');
  
  h_axes = axes('parent',cur_fig);
  subplot(4,2,5,h_axes);
  plot(h_axes,recs_old.settings.nyquist_zone,'LineWidth',1);
  hold(h_axes,'on');
  xlabel(h_axes,sprintf('Records (%d) -->',length(recs_old.settings.nyquist_zone)));
  ylabel(h_axes,'nz SIG');
  grid(h_axes,'on');
  axis(h_axes,'tight');
  ylim(h_axes,[-0.2 3.2]);
  %   title(h_axes,'OLD records');
  hold(h_axes,'off');
  
  h_axes = axes('parent',cur_fig);
  subplot(4,2,7,h_axes);
  plot(h_axes,recs_old.settings.nyquist_zone_hw,'LineWidth',2);
  hold(h_axes,'on');
  xlabel(h_axes,sprintf('Records (%d) -->',length(recs_old.settings.nyquist_zone_hw)));
  ylabel(h_axes,'nz HW');
  grid(h_axes,'on');
  axis(h_axes,'tight');
  ylim(h_axes,[-0.2 3.2]);
  %   title(h_axes,'NEW records');
  hold(h_axes,'off');
  
  h_axes = axes('parent',cur_fig);
  subplot(4,2,[2,4,6,8],h_axes);
  plot(h_axes,lp(testt.coh_wf.coh_noise));
  grid(h_axes,'on');
  axis(h_axes,'tight');
  ylim(h_axes,[-100 50]);
  leg={};
  for leg_idx=1:testt.coh_wf.sets
    leg=[leg sprintf('%d: block %d %0.3f us)',leg_idx,testt.coh_wf.block_idxs(leg_idx),testt.coh_wf.twtt(leg_idx)/1e-6)]; %#ok<AGROW>
  end
  legend(h_axes,leg);
  title(h_axes,'Coh noise for block in each set');
  
  try
    sgtitle(cur_fig,sprintf('%s : For [ %d-%d ] collate_est_nz_table',params_en{idx}.day_seg,wf,adc), 'Interpreter', 'none');
  catch
    suptitle(sprintf('%s : For [ %d-%d ] collate est nz table',strrep(params_en{idx}.day_seg,'_','-'),wf,adc));
  end
  
  fig_fn = [ct_filename_ct_tmp(params_en{idx},'',param.collate_est_nz_table.debug_out_dir,sprintf('%s_wf_%d_adc_%d',param.collate_est_nz_table.debug_out_dir,wf,adc)) '.fig'];
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(cur_fig,fig_fn);
  fig_fn = [ct_filename_ct_tmp(params_en{idx},'',param.collate_est_nz_table.debug_out_dir,sprintf('%s_wf_%d_adc_%d',param.collate_est_nz_table.debug_out_dir,wf,adc)) '.jpg'];
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(cur_fig,fig_fn);
  
  if ~param.collate_est_nz_table.enable_visible_plot
    try
      delete(cur_fig);
    catch
    end
  end
  
end



end