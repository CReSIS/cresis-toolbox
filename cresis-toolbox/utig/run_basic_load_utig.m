fn = '/mnt/raid_ssdorange/UTIG/X53a_first_flight_clean/RADnh5/bxds.1000';
[hdr,data] = basic_load_utig(fn,struct('bxds_en',true));

% 50 MHz
% 52.5-67.5 MHz
% 2.5-17.5 MHz
fs = 50e6;
Nt = 3200;
dt = 1/fs;
df = fs/Nt;
time = dt*(0:Nt-1).';
freq = df*(-floor(Nt/2):floor((Nt-1)/2));

Nt_512 = 512;
df_512 = fs/Nt_512;
freq_512 = df_512*(-floor(Nt_512/2):floor((Nt_512-1)/2));

dt_x = 32*160e-6;
Nx = param.recs(2);
time_x = dt_x*(0:Nx-1);
BW_x = 1/dt_x;
df_x = BW_x/Nx;
freq_x = df_x*(-floor(Nx/2):floor((Nx-1)/2));

% figure(1); clf;
for chan = 1:4
  if 0
    h_fig = figure(chan); clf;
    set(h_fig,'WindowStyle','docked');
  else
    subplot(2,2,chan);
  end
  if 0
    imagesc(db(data{chan} - mean(data{chan},2)));
  elseif 0
    % range-doppler
    imagesc(db(fft(data{chan},[],2)));
  elseif 0
    % frequency-space
    imagesc([],freq_512/1e6,fftshift(db(fft(data{chan}(2500+(1:Nt_512),:))),1));
  elseif 1
    % frequency-space PSD
    plot(freq_512/1e6, db(mean(abs(fft(data{chan}(2500+(1:Nt_512),:),[],1)).^2,2),'power'));
    grid on;
    xlabel('Frequency (MHz)')
    ylabel('Relative power (dB)')
  elseif 0
    % range-doppler noise/late-record
    imagesc(fftshift(db(fft(data{chan}(2500+(1:Nt_512),:),[],2)),1));
  elseif 1
    % range-doppler noise/late-record PSD
    plot(freq_x, fftshift(db(mean(abs(fft(data{chan}(2500+(1:Nt_512),:),[],2).^2),1),'power'),2));
    grid on;
    xlabel('Spatial frequency (Hz)')
    ylabel('Relative power (dB)')
  elseif 1
    % f-k
    imagesc(freq_x,freq_512/1e6,fftshift(db(fft2(data{chan}(2500+(1:Nt_512),:)))));
    xlabel('Spatial frequency (Hz)')
    ylabel('Frequency (MHz)')
  end
  if chan == 1 || chan == 3
    title(sprintf('Chan %d (low gain)',chan-1))
  else
    title(sprintf('Chan %d (high gain)',chan-1))
  end
  colormap(1-gray(256))
  caxis([0 150])
  hold on;
end
link_figures;
xlim([-25 25]);
