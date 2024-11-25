% Create fast-time gain compensation files for 2022_Greenland_Ground 
%   accum/2022_Greenland_Ground/CSARP_analysis/gain_wf_[1-4]_adc_1.mat
%
% Created manually since there were no measurements of fast-time gain.

param = read_param_xls(ct_filename_param('accum_param_2022_Greenland_Ground.xls'),'20220607_04',{'analysis_noise','analysis'});
global gRadar;
param = merge_structs(gRadar,param);
fn_dir = ct_filename_out(param,'analysis',[],true);

for wf = 1:4
  fn = fullfile(fn_dir, sprintf('/gain_wf_%d_adc_1.mat',wf));
  ftg = struct();
  ftg.param_collate_gain.radar.wfs(wf).Tadc_adjust = -3.065000000000000e-07;
  ftg.param_collate_gain.radar.wfs(wf).time_correction = 0;
  if wf == 1
    t0 = -1.266500000000000e-06;
    Nt = 5008;
    dt = 1.999999999999938e-09;
    ftg.param_collate_gain.radar.wfs(wf).time = t0 + (0:Nt-1)*dt;
    
    ftg.Gain_raw = zeros(Nt,1);
    ftg.Gain_raw(1:1370) = 10.^((42-9.6+22/2+4/2)/20);
    ftg.Gain_raw(1460:1590) = 10.^((32-9.6+22/2)/20);
    ftg.Gain_raw(1620:end) = 10.^(0/20);
  elseif wf == 2
    t0 = -1.266500000000000e-06;
    Nt = 5008;
    dt = 1.999999999999938e-09;
    ftg.param_collate_gain.radar.wfs(wf).time = t0 + (0:Nt-1)*dt;
    
    ftg.Gain_raw = zeros(Nt,1);
    ftg.Gain_raw(1:1370) = 10.^((0+57)/20);
    ftg.Gain_raw(1460:1590) = 10.^((0+42)/20);
    ftg.Gain_raw(1650:end) = 10.^(0/20);
  elseif wf == 3
    t0 = -1.266500000000000e-06;
    Nt = 19504;
    dt = 1.999999999999938e-09;
    ftg.param_collate_gain.radar.wfs(wf).time = t0 + (0:Nt-1)*dt;
    
    ftg.Gain_raw = zeros(Nt,1);
    ftg.Gain_raw(1:3380) = 10.^((32+13)/20);
    ftg.Gain_raw(3460:3590) = 10.^((29+13)/20);
    ftg.Gain_raw(3630:end) = 10.^(0/20);
  elseif wf == 4
    t0 = -1.266500000000000e-06;
    Nt = 19504;
    dt = 1.999999999999938e-09;
    ftg.param_collate_gain.radar.wfs(wf).time = t0 + (0:Nt-1)*dt;
    
    ftg.Gain_raw = zeros(Nt,1);
    ftg.Gain_raw(1:3380) = 10.^((39+7/2)/20);
    ftg.Gain_raw(3460:3585) = 10.^((32+4/2)/20);
    ftg.Gain_raw(3820:end) = 10.^(0/20);
  end
  
  fprintf('Saving: %s\n', fn);
  ftg.file_version = '1';
  ftg.file_type = 'gain';
  ftg.param_collate_gain.sw_version = current_software_version;
  save(fn,'-v7.3','-struct','ftg');
end


% wf =
%      1
% dd =
%   struct with fields:
%
%         Tadc_adjust: -3.065000000000000e-07
%     time_correction: 2.266500000000071e-06
%                  t0: -1.266500000000000e-06
%                  Nt: 5008
%                  dt: 1.999999999999938e-09
% 933           if wf == 1
% Applying fast time gain compensation 2-1
% wf =
%      2
% dd =
%   struct with fields:
%
%         Tadc_adjust: -3.065000000000000e-07
%     time_correction: 2.266500000000071e-06
%                  t0: -1.266500000000000e-06
%                  Nt: 5008
%                  dt: 1.999999999999938e-09
% Applying fast time gain compensation 3-1
% wf =
%      3
% dd =
%   struct with fields:
%
%         Tadc_adjust: -3.065000000000000e-07
%     time_correction: 6.266500000000168e-06
%                  t0: -1.266500000000000e-06
%                  Nt: 19504
%                  dt: 1.999999999999938e-09
% Applying fast time gain compensation 4-1
% wf =
%      4
% dd =
%   struct with fields:
%
%         Tadc_adjust: -3.065000000000000e-07
%     time_correction: 6.266500000000168e-06
%                  t0: -1.266500000000000e-06
%                  Nt: 19504
%                  dt: 1.999999999999938e-09













% 2022_Greenland_Ground

%  corr_Time = ftg.param_analysis.radar.wfs(wf).time... % Actual Time axis
%             + (ftg.param_analysis.radar.wfs(wf).Tadc_adjust - 1*param.radar.wfs(wf).Tadc_adjust)... % Difference in Tadc_adjust
%             -1*ftg.param_analysis.radar.wfs(wf).time_correction;
%           %             +-ftg.param_analysis.radar.wfs(wf).time(1);
%           %           plot(wfs(wf).time_raw(1:hdr.Nt{img}(1))/1e-6,data{img}(:,1,wf_adc));
%           %           temp_data = bsxfun(@times,data{img}(:,:,wf_adc),interp1(corr_Time, 1./ftg.Gain_raw, wfs(wf).time_raw(1:hdr.Nt{img}(1)), 'linear','extrap'));
%           %           hold on; plot(wfs(wf).time_raw(1:hdr.Nt{img}(1))/1e-6,temp_data(:,1),'--');
%           if wf == 1
%             corr_Time = wfs(wf).time_raw(1:hdr.Nt{img}(1));
%             ftg.Gain_raw = zeros(hdr.Nt{img}(1),1);
%             ftg.Gain_raw(1:1370) = 10.^((42-9.6)/20);
%             ftg.Gain_raw(1460:1590) = 10.^((32-9.6)/20);
%             ftg.Gain_raw(1620:end) = 10.^(0/20);
%           elseif wf == 2
%             corr_Time = wfs(wf).time_raw(1:hdr.Nt{img}(1));
%             ftg.Gain_raw = zeros(hdr.Nt{img}(1),1);
%             ftg.Gain_raw(1:1370) = 10.^(57/20);
%             ftg.Gain_raw(1460:1590) = 10.^(42/20);
%             ftg.Gain_raw(1650:end) = 10.^(0/20);
%           elseif wf == 3
%             corr_Time = wfs(wf).time_raw(1:hdr.Nt{img}(1));
%             ftg.Gain_raw = zeros(hdr.Nt{img}(1),1);
%             ftg.Gain_raw(1:3380) = 10.^(32/20);
%             ftg.Gain_raw(3460:3590) = 10.^(29/20);
%             ftg.Gain_raw(3630:end) = 10.^(0/20);
%           elseif wf == 4
%             corr_Time = wfs(wf).time_raw(1:hdr.Nt{img}(1));
%             ftg.Gain_raw = zeros(hdr.Nt{img}(1),1);
%             ftg.Gain_raw(1:3380) = 10.^(39/20);
%             ftg.Gain_raw(3460:3585) = 10.^(32/20);
%             ftg.Gain_raw(3820:end) = 10.^(0/20);
%           end
%           if 0
%             figure(1); clf;
%             plot(lp(mean(abs(data{img}(:,:,wf_adc)).^2,2)));
%             grid on;
%             keyboard
%           end
%           data{img}(:,:,wf_adc) = bsxfun(@times,data{img}(:,:,wf_adc),interp1(corr_Time, ftg.Gain_raw, wfs(wf).time_raw(1:hdr.Nt{img}(1)), 'linear','extrap'));







          %             +-ftg.param_analysis.radar.wfs(wf).time(1);
          %           plot(wfs(wf).time_raw(1:hdr.Nt{img}(1))/1e-6,data{img}(:,1,wf_adc));
          %           temp_data = bsxfun(@times,data{img}(:,:,wf_adc),interp1(corr_Time, 1./ftg.Gain_raw, wfs(wf).time_raw(1:hdr.Nt{img}(1)), 'linear','extrap'));
          %           hold on; plot(wfs(wf).time_raw(1:hdr.Nt{img}(1))/1e-6,temp_data(:,1),'--');
          
%           wf
%           dd.Tadc_adjust = param.radar.wfs(wf).Tadc_adjust;
%           dd.time_correction = ftg.param_analysis.radar.wfs(wf).time_correction;
%           dd.t0 = wfs(wf).time_raw(1);
%           dd.Nt = hdr.Nt{img}(1);
%           dd.dt = wfs(wf).time_raw(2)-wfs(wf).time_raw(1);
%           dd
          
%           if wf == 1
%             corr_Time = wfs(wf).time_raw(1:hdr.Nt{img}(1));
%             ftg.Gain_raw = zeros(hdr.Nt{img}(1),1);
%             ftg.Gain_raw(1:1370) = 10.^((42-9.6)/20);
%             ftg.Gain_raw(1460:1590) = 10.^((32-9.6)/20);
%             ftg.Gain_raw(1620:end) = 10.^(0/20);
%           elseif wf == 2
%             corr_Time = wfs(wf).time_raw(1:hdr.Nt{img}(1));
%             ftg.Gain_raw = zeros(hdr.Nt{img}(1),1);
%             ftg.Gain_raw(1:1370) = 10.^(57/20);
%             ftg.Gain_raw(1460:1590) = 10.^(42/20);
%             ftg.Gain_raw(1650:end) = 10.^(0/20);
%           elseif wf == 3
%             corr_Time = wfs(wf).time_raw(1:hdr.Nt{img}(1));
%             ftg.Gain_raw = zeros(hdr.Nt{img}(1),1);
%             ftg.Gain_raw(1:3380) = 10.^(32/20);
%             ftg.Gain_raw(3460:3590) = 10.^(29/20);
%             ftg.Gain_raw(3630:end) = 10.^(0/20);
%           elseif wf == 4
%             corr_Time = wfs(wf).time_raw(1:hdr.Nt{img}(1));
%             ftg.Gain_raw = zeros(hdr.Nt{img}(1),1);
%             ftg.Gain_raw(1:3380) = 10.^(39/20);
%             ftg.Gain_raw(3460:3585) = 10.^(32/20);
%             ftg.Gain_raw(3820:end) = 10.^(0/20);
%           end
