function mdata = uncompress_echogram(mdata)
% mdata = uncompress_echogram(mdata)
%
% Undoes the affect of "compress_echogram.m" (currently this is only used
% with FMCW radar data).  If the mdata struct does not contain the
% "Truncate_Bins" field, nothings happens.
%
% Required and optional fields are:
% mdata.
%   Elevation_Correction: Read-only
%   Truncate_Bins: Read-only
%   Time: This field is uncompressed by the function
%   Elevation: optional (this field is uncompressed by the function)
%   Surface: optional (this field is uncompressed by the function)
%   Bottom: optional (this field is uncompressed by the function)
%   Data: optional (this field is uncompressed by the function)
%
% Example:
%  mdata = load('Data_20130101_001.mat');
%  mdata = uncompress_echogram(mdata);

if isfield(mdata,'Truncate_Bins')
  %% This is a compressed echogram, "uncompress" it
  
  c = 2.997924580003452e+08;
  
  Nz = max(mdata.Elevation_Correction);
  if ~isfield(mdata,'Time') && isfield(mdata,'fasttime') 
      mdata.Time = mdata.fasttime;
  end
  if ~isfield(mdata,'Data') && isfield(mdata,'amplitude') 
      mdata.Data = mdata.amplitude;
  end
  dt = mdata.Time(2)-mdata.Time(1);
  dr = dt * c/2;
  Nt = Nz + length(mdata.Truncate_Bins);
  if isfield(mdata,'Elevation')
    for rline = 1:length(mdata.Elevation_Correction)
      mdata.Elevation(rline) = mdata.Elevation(rline) - mdata.Elevation_Correction(rline)*dr;
    end
  end
  if isfield(mdata,'Surface')
    for rline = 1:length(mdata.Elevation_Correction)
      mdata.Surface(rline) = mdata.Surface(rline) - mdata.Elevation_Correction(rline)*dt;
    end
  end
  if isfield(mdata,'Bottom')
    for rline = 1:length(mdata.Elevation_Correction)
      mdata.Bottom(rline) = mdata.Bottom(rline) - mdata.Elevation_Correction(rline)*dt;
    end
  end
  if isfield(mdata,'Data')
    % Some times the Data is not loaded, so we have a special check for this
    mdata.Data = [nan(Nz,size(mdata.Data,2)); mdata.Data];
    for rline = 1:length(mdata.Elevation_Correction)
      mdata.Data(:,rline) = circshift(mdata.Data(:,rline),-mdata.Elevation_Correction(rline));
    end
  end
  if length(mdata.Time) == length(mdata.Truncate_Bins)
    t0 = mdata.Time(1) - Nz*dt;
  else
    t0 = mdata.Time(mdata.Truncate_Bins(1)) - Nz*dt;
  end
  mdata.Time = t0 + dt*(0:Nt-1).';
  if isfield(mdata,'fasttime') 
      mdata.fasttime = mdata.Time;
      mdata = rmfield(mdata,'Time');
  end
  if isfield(mdata,'amplitude') 
      mdata.amplitude = mdata.Data;
      mdata = rmfield(mdata,'Data');
  end
end
