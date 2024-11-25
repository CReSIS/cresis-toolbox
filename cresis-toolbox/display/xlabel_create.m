function [xtl] = create_standard_x_labels(lat,lon,elev,tick_num)
% [xtl] = create_standard_x_labels(lat,lon,elev,tick_num)
%
% Creates a vector of appropriate values for latitude, longitude, and
% elevation given a desired number of X-axis tick marks.
%
% Inputs:
%  lat,lon,elev: latitude, longitude, and elevation for the data set to be
%                plotted
%  tick_num: The desired number of X-axis tick marks in the final image
%
% Outputs:
%  xtl: A 3xtick_num vector of horizontal distance from local origin, 
%       latitude, and longitude
%
% Written by Logan Smith

if lat(1) > 0
    lat_dir = 'N';
    lat_mult   = 1;
else
    lat_dir = 'S';
    lat_mult   = -1;
end
if lon(1) > 0
    lon_dir = 'E';
    lon_mult   = 1;
else
    lon_dir = 'W';
    lon_mult   = -1;
end

[Distance] = geodetic_to_along_track(lat,lon,elev)/1e3;
label_spacing = Distance(end)/(tick_num-1);
labels = linspace(0,Distance(end),tick_num);

for idx_d = 1:tick_num
    if idx_d <= length(labels)
        location = find(Distance>=labels(idx_d),1,'first');
        xtl{idx_d} = {sprintf('%3.2f km',(round(100*Distance(location))/100)); ...
            sprintf('%3.3f %s',lat_mult*(round(1000*lat(location))/1000),lat_dir); ...
            sprintf('%3.3f %s',lon_mult*(round(1000*lon(location))/1000),lon_dir)};
    else
        xtl{idx_d} = {'';'';''};
    end
end

return