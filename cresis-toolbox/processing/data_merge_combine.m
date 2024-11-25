function [hdr,data] = data_merge_combine(param,hdr,data)

physical_constants;

%% Combine wf-adc pairs into a single wf-adc pair
% =========================================================================

% Not supported yet

%% Motion compensation
% =========================================================================
if param.load.motion_comp
  % Remove elevation variations between each phase center and the reference
  % position of the array. The goal is to compensate for relative time
  % delays between each of the elements so that they can be constructively
  % added together.
  for img = 1:length(param.load.imgs)
    if ~all(hdr.bad_rec{img}(:))
      nanmask = isnan(data{img});
      data{img}(nanmask) = 0;
      data{img} = fft(data{img},[],1);
      for wf_adc = 1:size(param.load.imgs{img},1)
        dtime = (hdr.records{img,wf_adc}.elev-hdr.ref.elev) / (c/2);
        data{img}(:,:,wf_adc) = data{img}(:,:,wf_adc) .* exp(1j*2*pi*hdr.freq{img}*dtime);
      end
      data{img} = ifft(data{img},[],1);
      data{img}(nanmask) = NaN;
    end
  end
end

if param.load.combine_rx
  %% Create new trajectory for combined phase centers
  % =========================================================================
  for img = 1:length(param.load.imgs)
    x = zeros(size(param.load.imgs{img},1), size(hdr.ref.gps_time,2));
    y = zeros(size(param.load.imgs{img},1), size(hdr.ref.gps_time,2));
    z = zeros(size(param.load.imgs{img},1), size(hdr.ref.gps_time,2));
    for wf_adc = 1:size(param.load.imgs{img},1)
      [x(wf_adc,:),y(wf_adc,:),z(wf_adc,:)] = geodetic2ecef(hdr.records{img,wf_adc}.lat*pi/180, ...
        hdr.records{img,wf_adc}.lon*pi/180,hdr.records{img,wf_adc}.elev,WGS84.ellipsoid);
    end
    [hdr.records{img,1}.lat,hdr.records{img,1}.lon,hdr.records{img,1}.elev] ...
      = ecef2geodetic(mean(x,1),mean(y,1),mean(z,1),WGS84.ellipsoid);
    hdr.records{img,1}.lat = hdr.records{img,1}.lat*180/pi;
    hdr.records{img,1}.lon = hdr.records{img,1}.lon*180/pi;
  end
  % Only keep the first wf_adc entry since this is the one that has been
  % overwritten by the combined phase center.
  hdr.records = hdr.records(:,1);
  
  %% Combine images into a single image
  % =========================================================================
  for img = 1:length(param.load.imgs)
    data{img} = nanmean(data{img},3);
  end
end
