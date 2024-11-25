GENERATE = true;
USE_ELEVATION = false;

physical_constants;
vel_air = c/2;


if ~GENERATE
    param = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140516_01');
    mdata = echo_load(param,'CSARP_post/standard',31);
    
    mdata.Data = real(10*log10(mdata.Data));
    
    max_val = max(max(mdata.Data));
    
    if USE_ELEVATION
        slope_type = 'Elevation with mirrored test layer';
        elevation = mdata.Elevation;
        time = mdata.Time;

        dt = time(2) - time(1);
        drange = dt * vel_air;
        bins = elevation / drange;
            
        % Insert test layer which mirrors elevation
        for i = 1:length(bins)
            mdata.Data(round(max(bins) - bins(i) + min(bins)), i) = max_val;
        end
    else
        slope_type = 'Surface';
        bins = interp1(mdata.Time, 1:length(mdata.Time), mdata.Surface);
    end

    
    along_track_slope  = zeros(1, size(mdata.Data, 2) - 1);
    along_track_weight = 1;
    upper_bounds       = ones(1, size(mdata.Data, 2)); 
    lower_bounds       = ones(1, size(mdata.Data, 2)) * size(mdata.Data, 1);
    
    figure(1);
    clf;
    hold on;
    imagesc(mdata.Data);
    colormap(1-gray);
    y_new = tomo.viterbi2(single(mdata.Data), along_track_slope, along_track_weight, upper_bounds, lower_bounds);
    plot(y_new);
    plot(bins);
    legend({'Viterbi', slope_type});
    title('Echo before shift');
    axis ij;
    
    bin_struct.mirror = USE_ELEVATION;
    bin_struct.slope = bins;
    
    flattened = echo_flatten(mdata, bin_struct);
    upper_bounds = flattened.Vertical_Bounds(1, :);
    lower_bounds = flattened.Vertical_Bounds(2, :);
    
    figure(2);
    clf;
    hold on;
    imagesc(flattened.Data);
    colormap(1-gray);
    y_new = tomo.viterbi2(single(flattened.Data), along_track_slope, along_track_weight, upper_bounds, lower_bounds);
    plot(y_new);
    plot(bins);
    plot(upper_bounds, '--');
    plot(lower_bounds, '--');
    legend({'Viterbi', sprintf('Original %s', slope_type), 'Upper Bounds', 'Lower Bounds'});
    title('Echo after shift');
    axis ij;
    
else
    rows = 20;
    cols = 100;

    % Create default matrix
    matrix = magic(max([rows cols]));
    matrix = matrix(1:rows, 1:cols);
    matrix = matrix ./ max(max(matrix)) .* 5;

    % Create borders
    matrix(1, : ) = 10;
    matrix(end, : ) = 10;

    slope = zeros(1, cols);
    third_width = floor(cols/3);
    half_height = rows/2;
    for i = 1:cols
        if i <= third_width
            per = (i-1)/third_width;
            row = per * half_height + half_height;
        elseif i < third_width * 2
            per = (i-third_width)/third_width;
            row = rows-per*rows + 1;
        else
            per = (i-third_width*2)/third_width;
            row = per*half_height + 1;
        end
        bin = [round(row), i];
        slope(i) = bin(1);
        matrix(bin(1), bin(2)) = 30;
    end
    
    slope_struct.mirror = false;
    if USE_ELEVATION
        slope_struct.mirror = true;
        slope = -slope + slope(1)*2;
    end

    along_track_slope  = zeros(1, size(matrix, 2) - 1);
    along_track_weight = 100;
    upper_bounds       = ones(1, size(matrix, 2)); 
    lower_bounds       = ones(1, size(matrix, 2)) * size(matrix, 1);
    
    figure(1);
    clf;
    hold on;
    imagesc(matrix);
    colormap(1-gray);
    y_new = tomo.viterbi2(single(matrix), along_track_slope, along_track_weight, upper_bounds, lower_bounds);
    plot(y_new);
    plot(slope);
    legend({'Viterbi', 'Slope'});
    title('Shifted layer in echogram');
    axis ij;

    slope_struct.slope = slope;
    flattened = echo_flatten(matrix, slope_struct);
    upper_bounds = flattened.Vertical_Bounds(1, :);
    lower_bounds = flattened.Vertical_Bounds(2, :);
    
    figure(2);
    clf;
    hold on;
    imagesc(flattened.Data);
    colormap(1-gray);
    y_new = tomo.viterbi2(single(flattened.Data), along_track_slope, along_track_weight, upper_bounds, lower_bounds);
    plot(y_new);
    plot(upper_bounds, '--');
    plot(lower_bounds, '--');
    legend({'Viterbi', 'Upper Bounds', 'Lower Bounds'});
    title('Echogram shifted to account for shift in layer');
    axis ij;
end


