function [param,dout] = array_proc(param,din)
% [param,dout] = array_proc(param,din)
%
% Performs array processing on the input data (din) and writes the result
% to dout.
%
% Requires the optimization toolbox for fmincon (constrained optimization)
% when using DOA methods.
%
% INPUTS
% =========================================================================
%
% param: Structure from the parameter spreadsheets. Only a subset is used:
%  .array:
%    Structure controlling array processing (matches parameter
%    spreadsheet "array" worksheet). See details in the param.array input
%    check section.
%  .array_proc:
%    Additional array_proc input variables that are not supplied by the
%    "array" worksheet.
%
% param.array_proc:
% -------------------------------------------------------------------------
% .fc
%   center frequency in Hz, used during steering vector generation
% .time
%   Nt length time vector, used in DOA methods for creating the doa
%   constraints and for debug plots
% .chan_equal
%   Nc by 1 vector. Default is all ones (so no effect on din).
%   data_used_in_array_processing = din / chan_equal
% .imp_resp
%   Structure describing the radar's fast time impulse response. Main lobe
%   should be centered on zero time.
%    .vals
%       N by 1 vector of complex amplitudes
%    .time_vec
%       N by 1 vector of time
% .fcs:
%   Flight Coordinate System cell vector used by param.array.sv_fh. Only
%   requires the fields describing the sensor positions for each multilook
%   and snapshot. The roll must also be specified and will be read from the
%   first channel.
%
%   fcs{1...Ns}{1...Nc}.pos
%     Ns = snapshots
%     Nc = wf-adc pairs (i.e. sensors or channels)
%     pos(2,1...Nx): cross track with positive pointing to the left
%     pos(3,1...Nx): elevation with positive pointing up
%     roll
%   fcs{1...Ns}{1}.roll
%     Roll angle in degrees
%   .surface: Vector of time delays to the surface for each range-line. This
%     is used:
%      1. in the construction of DOA constraints for methods 7-9
%      2. for plotting debug results
%      Default is NaN.
% .lines
%   2 element vector which specifies the first and last output range-line.
%   This is optional and overrules the default output range-lines. It is
%   used by array_task.m to make sure all of the chunks of SAR data run
%   through array_proc can be seamlessly stitched in array_combine_task.
%
% din is complex Nt by Nx by Na by Nb by Nc matrix
% -------------------------------------------------------------------------
%   Nt is fast-time
%   Nx is slow-time
%   Na is subaperture
%   Nb is subband
%   Nc is channels/sensors in array
%
% =========================================================================
% OUTPUTS
% param: same as input, but with these additional fields added to
%   param.array_proc:
% .bins:
%   Nt_out element vector specifying the outputs range bins relative to the
%   input range bins (.bins is always numbers with decimal .0 or 0.5)
% .lines:
%   Nx_out element vector speciying the output range lines relative to the
%   input range lines (.lines is always numbers with decimal .0 or 0.5)

% dout is structure with array processed output data
%  BEAMFORMER METHOD:
%   .img: Nt_out by Nx_out output image. The largest value in the Nsv dimension
%   .theta: Same size as .img. The direction of arrival (deg) corresponding to the largest
%       value in the Nsv range.
%  DOA METHOD:
%   .img: Nt_out by Nx_out output image. The value of the largest source in the Nsrc dimension (i.e. tomo.img first entry)
%   .theta: direction of arrival (deg) to the largest theta (i.e. tomo.img first entry)
%  TOMOGRAPHY ENABLED
%   .tomo: tomography structure (only present if param.tomo_en is true)
%    DOA method:
%     .img: Nt_out by Nsrc by Nx_out : Signal voltage or power for each
%       source in a range-bin, NaN for no source when MOE enable. Order in
%       this and following matrix will always be largest to smallest theta
%       with NaN/no source at the end.
%     .theta: Nt_out by Nsrc by Nx_out: Direction of arrival of each source
%      in a range-bin (deg), NaN for no source when MOE enable
%     .cost: Nt_out by Nx_out cost function at maximum
%     .hessian: Nt_out by Nsrc by Nx_out cost function Hessian diagonal at
%       maximum (if MOE enabled, a smaller subset of the Nsrc
%       diagonal elements will be filled and the remainder will be NaN)
%    BEAMFORMER method
%     .img: Nt_out by Nsv by Nx_out: Signal voltage or power for each
%       source in a range-bin, NaN for no source
%     .theta: Nt_out by Nsv by Nx_out: Direction of arrival of each source
%      in a range-bin (deg), NaN for no source
%
% The units of the img fields depend on the multilooking. If no
% multilooking is enabled, then the param.complex field may be set to true,
% in which case the output is complex float32. If multilooking is enabled
% and the param.complex field is set to false, then the output is
% real-valued float32 linear power. In the case of MUSIC_METHOD, the img
% field is the cepstrum (inverted noise eigen space spectrum).
%
% See also: run_master.m, master.m, run_array.m, array.m, load_sar_data.m,
% array_proc.m, array_task.m, array_combine_task.m
%
% Also used in: sim.crosstrack.m


%% param.array Input Checks
% =========================================================================
% .bin_restriction:
%   Two element struct array for opsLoadLayers that loads two layers which
%   represent the start and stop bins for processing. Default is to leave
%   this field empty, in which case all range bins are processed.
if ~isfield(param.array,'bin_restriction') || isempty(param.array.bin_restriction)
  param.array.bin_restriction = [];
end

% .bin_rng:
%   Range of range-bins to use for snapshots, default is 0 bin_rng is
%   forced to be symmetrical about 0 and must be integers.
%
%   For example: [-2 -1 0 1 2].
%
%   bin_rng is also measured in narrowband samples so if Nsubband > 1,
%   bin_rng applies to the samples after subbanding.
if ~isfield(param.array,'bin_rng') || isempty(param.array.bin_rng)
  param.array.bin_rng = 0;
end
if mod(max(param.array.bin_rng),1) ~= 0
  error('param.array.bin_rng must only contain integers.');
end
param.array.bin_rng = -max(param.array.bin_rng):max(param.array.bin_rng);

% .dbin
%   Number of range-bins to decimate by on output, default is
%   round((length(param.array.bin_rng)-1)/2). This is without subbanding.
if ~isfield(param.array,'dbin') || isempty(param.array.dbin)
  param.array.dbin = round(length(param.array.bin_rng)/2);
end

% .dline:
%   Number of range-lines to decimate by on output, default is
%   round((length(param.array.line_rng)-1)/2)
if ~isfield(param.array,'dline') || isempty(param.array.dline)
  error('param.array.dline must be specified.')
end

% .diag_load:
%   Diagonal loading, defaults to 0, only used with MVDR methods. This is
%   especially relevant when length(bin_rng)*length(line_rng) < Nc Should
%   be a scalar, defaults to zero
if ~isfield(param.array,'diag_load') || isempty(param.array.diag_load)
  param.array.diag_load = 0;
end

% .doa_constraints: structure array restricting the DOA for each source
%   .method: string indicating the constraint method
%     'fixed': a fixed range of DOAs (default)
%     'surface-left': a fixed range of DOAs around a flat surface on the
%       left
%     'surface-right': a fixed range of DOAs around a flat surface on the
%       right
%     'layer-left': a fixed range of DOAs around a flat layer on the
%       left
%     'layer-right': a fixed range of DOAs around a flat layer on the
%       right
%     'er': dielectric to use for refraction to the layer
%   .init_src_limits: initialization source theta limits [min max] in degrees,
%      default is [-90 90]
%   .src_limits: optimization source theta limits [min max] in degrees,
%      default is [-90 90]
if ~isfield(param.array,'doa_constraints') || isempty(param.array.doa_constraints)
  for src_idx = 1:param.array.Nsrc
    param.array.doa_constraints(src_idx).method = 'fixed';
    param.array.doa_constraints(src_idx).init_src_limits = [-90 90];
    param.array.doa_constraints(src_idx).src_limits = [-90 90];
  end
end

% .doa_init:
%   String specifying the initialization method:
%   'ap': alternating projection (not global)
%   'grid': sparse grid search (slower, but global)
if ~isfield(param.array,'doa_init') || isempty(param.array.doa_init)
  param.array.doa_init = 'grid';
end

% .doa_seq:
%   DOA sequential mode (use the previous range bin and range line
%   estimates to inform a priori for current range bin)
if ~isfield(param.array,'doa_seq') || isempty(param.array.doa_seq)
  param.array.doa_seq = false;
end

% .doa_theta_guard:
%   The minimum source separation in degrees. Should be a positive number.
%   Used with DOA initialization and optimization methods. Default is 1.5
%   degrees, but should be set relative to the electrical size of the
%   array. This is important to prevent one strong source being represented
%   by two sources and to keep the steering vectors independent.
if ~isfield(param.array,'doa_theta_guard') || isempty(param.array.doa_theta_guard)
  param.array.doa_theta_guard = 1.5;
end

% .method
%   String or see array_proc_methods.m for scalar integer equivalent
%    BEAMFORMER Methods:
%    STANDARD_METHOD: Periodogram (aka Welch or DFT) method ('standard') [default]
%    MVDR_METHOD: Minimum Variance Distortionless Response ('mvdr')
%    MVDR_ROBUST_METHOD. Minimum Variance Distortionless Response ('mvdr_robust')
%    MUSIC_METHOD: Multiple Signal Classification ('music')
%    EIG_METHOD: Eigenvector method based on Matlab's peig ('eig') NOT WORKING
%    RISR_METHOD. Re-iterative super resolution, Blunt ('risr')
%
%    DOA Methods:
%    MUSIC_DOA_METHOD. Multiple Signal Classification ('music_doa')
%    MLE_METHOD. Maximum Likelihood Estimator ('mle')
%    DCM_METHOD. Wideband Data Covariance Matrix Correlation Method, Stumpf ('wbdcm')
array_proc_methods; % This script assigns the integer values for each method
if ~isfield(param.array,'method') || isempty(param.array.method)
  param.array.method = 0;
end
if ischar(param.array.method)
  % Convert array method string to integer
  switch (param.array.method)
    case {'standard','period'}
      param.array.method = STANDARD_METHOD;
    case 'mvdr'
      param.array.method = MVDR_METHOD;
    case 'mvdr_robust'
      param.array.method = MVDR_ROBUST_METHOD;
    case 'music'
      param.array.method = MUSIC_METHOD;
    case 'eig'
      param.array.method = EIG_METHOD;
    case 'risr'
      param.array.method = RISR_METHOD;
    case 'geonull'
      param.array.method = GEONULL_METHOD;
    case 'music_doa'
      param.array.method = MUSIC_DOA_METHOD;
    case 'mle'
      param.array.method = MLE_METHOD;
    case 'dcm'
      param.array.method = DCM_METHOD;
      if ~isfield(param.array,'Nsrc') || isempty(param.array.Nsrc)
        param.array.Nsrc = 1;
      end
    otherwise
      error('Invalid method %s', param.array.method);
  end
end
if ~any(param.array.method == [STANDARD_METHOD MVDR_METHOD MVDR_ROBUST_METHOD MUSIC_METHOD EIG_METHOD RISR_METHOD GEONULL_METHOD MUSIC_DOA_METHOD MLE_METHOD DCM_METHOD])
  error('Invalid method %d', param.array.method);
end

% .line_rng:
%   Range of range-lines to use for snapshots, default is -5:5. line_rng is
%   forced to be symmetrical about 0 and only contain integers.
%
%   For example: [-2 -1 0 1 2].
if ~isfield(param.array,'line_rng') || isempty(param.array.line_rng)
  param.array.line_rng = -5:1:5;
end
if mod(max(param.array.line_rng),1) ~= 0
  error('param.array.line_rng must only contain integers.');
end
param.array.line_rng = -max(param.array.line_rng):max(param.array.line_rng);
% .DCM:
%   For methods that use the data covariance matrix, DCM, the bin_rng and
%   line_rng may be set separately for the generation of the DCM than for
%   the multilooking/averaging of the snapshots or estimation of the
%   signal. These DCM fields will be used for the DCM estimate. For DOA,
%   this DCM is used to solve for the DOA. The default DCM.bin_rng and
%   DCM.line_rng are to match param.array.bin_rng and param.array.line_rng.
if ~isfield(param.array,'DCM') || isempty(param.array.DCM)
  param.array.DCM = [];
end
if ~isfield(param.array.DCM,'bin_rng') || isempty(param.array.DCM.bin_rng)
  param.array.DCM.bin_rng = param.array.bin_rng;
end
if ~isfield(param.array.DCM,'line_rng') || isempty(param.array.DCM.line_rng)
  param.array.DCM.line_rng = param.array.line_rng;
end
% Check to see if data covariance matrix (DCM) generation uses same
% snapshots/pixels as multilooking (ML).
if length(param.array.bin_rng) == length(param.array.DCM.bin_rng) && all(param.array.bin_rng == param.array.DCM.bin_rng) ...
    && length(param.array.line_rng) == length(param.array.DCM.line_rng) && all(param.array.line_rng == param.array.DCM.line_rng)
  DCM_ML_match = true;
else
  DCM_ML_match = false;
end

% .moe_en:
%   If enabled, the model order estimator will be run to estimate Nsrc for
%   each pixel. Estimated Nsrc will vary from 0 to param.Nsrc.
if ~isfield(param.array,'moe_en') || isempty(param.array.moe_en)
  param.array.moe_en = false;
end

% .moe_simulator_en:
%   If enabled, every model order estimator will be run and a new output
%   called dout.moe will be added.
if ~isfield(param.array,'moe_simulator_en') || isempty(param.array.moe_simulator_en)
  param.array.moe_simulator_en = false;
end
if param.array.moe_simulator_en
  param.array.moe_en = true;
end

% .Nsrc:
%   Number of signals/sources/targets per SAR image pixel, defaults to 1,
%   only used in modes that are based on the x = As + n signal model (e.g.
%   MUSIC_METHOD, MLE_METHOD, etc.). When model order estimation is
%   enabled, this represents the maximum number of targets.
if ~isfield(param.array,'Nsrc') || isempty(param.array.Nsrc)
  param.array.Nsrc = 1;
end

% .Nsv and .theta
%   Only Nsv or theta should be set, but not both. theta takes precedence.
%
%   theta should be a vector of DOA degrees, defaults to using Nsv, nadir
%   is 0 deg and left is positive degrees
%
%   Nsv should be a scalar, defaults to 1 with theta == 0 (nadir).
%
%   Beamforming Methods: The number of steering vectors that will be used
%   in the beamforming process. These are uniformly sampled in wavenumber
%   space and cover the nadir directed visible region from -90 and 90 deg.

%   DOA Methods: The number of steering vectors that will be used in the
%   grid/alternating projection initialization methods and in the
%   alternating projection optimization method.

% .sv_fh
%   Steering vector function handle. Defaults to array_proc_sv.m and should
%   generally not be changed.
if ~isfield(param.array,'sv_fh') || isempty(param.array.sv_fh)
  param.array.sv_fh = @array_proc_sv;
end
%   Steering vectors align with these spatial frequencies:
%     ifftshift(-floor(Nsv/2):floor((Nsv-1)/2))
if isfield(param.array,'theta') && ~isempty(param.array.theta)
  Nsv = length(param.array.theta);
  theta = param.array.theta/180*pi; % Theta input in degrees
else
  if ~isfield(param.array,'Nsv') || isempty(param.array.Nsv)
    param.array.Nsv = 1;
  end
  Nsv = param.array.Nsv;
  theta = fftshift(param.array.sv_fh(Nsv, 1));
end

% .Nsubband:
%   Number of subbands to form from din. This is in addition to the
%   subbanding din may already have in the Nb dimension. Default is 1.
%   Should be a positive integer.
if ~isfield(param.array,'Nsubband') || isempty(param.array.Nsubband)
  param.array.Nsubband = 1;
end

% .theta_rng
%   Two element vector containing the theta range that will be used to
%   form the dout.img matrix. Each dout.img pixel represents the maximum
%   value between theta_rng(1) and theta_rng(2) for that pixel.
if ~isfield(param.array,'theta_rng') || isempty(param.array.theta_rng)
  param.array.theta_rng = [0 0];
end

% .tomo_en:
%   If enabled, .tomo field will be included in output dout. Default is
%   false for beamforming methods and Nsv == 1, otherwise the default is
%   true.
if ~isfield(param.array,'tomo_en') || isempty(param.array.tomo_en)
  if param.array.method >= DOA_METHOD_THRESHOLD || param.array.Nsv > 1
    param.array.tomo_en = true;
  else
    param.array.tomo_en = false;
  end
end

% .window:
%   Window to apply in Nc dimension, defaults to @hanning, only used with
%   STANDARD_METHOD
if ~isfield(param.array,'window') || isempty(param.array.window)
  param.array.window = @hanning;
end

if nargin == 1
  % No input data provided so just checking input arguments
  return;
end

%% din and param.array_proc Input Checks
% =====================================================================

% Nt: Number of fast-time samples in the din
Nt = size(din{1},1);

% Nx: Number of slow-time/along-track samples in the data
Nx = size(din{1},2);

% Na: Number of subapertures
Na = size(din{1},3);

% Nb: Number of subbands
Nb = size(din{1},4);

% Nc: Number of cross-track channels in the din
Nc = size(din{1},5);

% .bin_restriction:
%   .start_bin: 1 by Nx vector of the start range-bin
%   .stop_bin: 1 by Nx vector of the stop range-bin
if ~isfield(param.array_proc,'bin_restriction') || isempty(param.array_proc.bin_restriction)
  param.array_proc.bin_restriction = [];
end
if ~isfield(param.array_proc.bin_restriction,'start_bin') || isempty(param.array_proc.bin_restriction.start_bin)
  param.array_proc.bin_restriction.start_bin = ones(1,Nx);
end
if ~isfield(param.array_proc.bin_restriction,'stop_bin') || isempty(param.array_proc.bin_restriction.stop_bin)
  param.array_proc.bin_restriction.stop_bin = Nt*ones(1,Nx);
end

% .chan_equal: Channel equalization, complex weights that are applied to
% each channel in the Nc dimension. Defaults to no equalization or
% ones(Nc,1).
if ~isfield(param.array_proc,'chan_equal') || isempty(param.array_proc.chan_equal)
  for ml_idx = 1:length(din)
    param.array_proc.chan_equal{ml_idx} = ones(Nc,1);
  end
end

% .bins: Output range bins. Defaults to starting at the first range-bin
% that would have full support and stopping at the last range bin with full
% support.
param.array_proc.bins = (1+(param.array.Nsubband-1)/2-min(param.array.bin_rng)*param.array.Nsubband : param.array.dbin ...
  : Nt-max(param.array.bin_rng)*param.array.Nsubband-(param.array.Nsubband-1)/2).';
Nt_out = length(param.array_proc.bins);

% .lines: Output range lines. Defaults to starting at the first range-line
% that would have full support from input and stopping at the last range
% line with full support
if ~isfield(param.array_proc,'lines') || isempty(param.array_proc.lines)
  param.array_proc.lines = 1-min(param.array.line_rng) : param.array.dline : Nx-max(param.array.line_rng);
else
  % Start/stop output range lines passed in (typical operation from
  % array_task.m)
  param.array_proc.lines = param.array_proc.lines(1) : param.array.dline : param.array_proc.lines(end);
end
Nx_out = length(param.array_proc.lines);

% Merge the two input structs into a shorter name for efficiency
cfg = merge_structs(param.array,param.array_proc);

%% Preallocate Outputs
% =====================================================================
dout.img ...
  = nan(Nt_out, Nx_out,'single');
Sarray = zeros(Nsv,Nt_out);
if cfg.tomo_en
  if cfg.method >= DOA_METHOD_THRESHOLD
    % Direction of Arrival Method
    dout.tomo.img = ...
      nan(Nt_out,cfg.Nsrc,Nx_out,'single');
    dout.tomo.theta = ...
      nan(Nt_out,cfg.Nsrc,Nx_out,'single');
    dout.tomo.cost = ...
      nan(Nt_out, Nx_out,'single');
    dout.tomo.hessian = ...
      nan(Nt_out,cfg.Nsrc,Nx_out,'single');
  else
    % Beam Forming Method
    dout.tomo.img = ...
      nan(Nt_out,cfg.Nsv,Nx_out,'single');
    dout.tomo.theta = theta(:); % Ensure a column vector on output
  end
end
if cfg.moe_simulator_en
  dout.moe.NT.doa = nan(length(array_proc_bin_idxs),cfg.Nsrc,Nx);
  dout.moe.AIC.doa = nan(length(array_proc_bin_idxs),cfg.Nsrc,Nx);
  dout.moe.HQ.doa = nan(length(array_proc_bin_idxs),cfg.Nsrc,Nx);
  dout.moe.MDL.doa = nan(length(array_proc_bin_idxs),cfg.Nsrc,Nx);
  dout.moe.AICc.doa = nan(length(array_proc_bin_idxs),cfg.Nsrc,Nx);
  dout.moe.KICvc.doa = nan(length(array_proc_bin_idxs),cfg.Nsrc,Nx);
  dout.moe.WIC.doa = nan(length(array_proc_bin_idxs),cfg.Nsrc,Nx);
end

%% Channel Equalization
% =====================================================================
% Also apply window if STANDARD_METHOD.
Hwindow = cfg.window(Nc);
Hwindow = Hwindow / sum(Hwindow);
for ml_idx = 1:length(din)
  for chan = 1:Nc
    if cfg.method == STANDARD_METHOD
      % Periodogram method
      din{ml_idx}(:,:,:,:,chan) = din{ml_idx}(:,:,:,:,chan) * (Hwindow(chan) / cfg.chan_equal{ml_idx}(chan));
    else
      % All other methods
      din{ml_idx}(:,:,:,:,chan) = din{ml_idx}(:,:,:,:,chan) / cfg.chan_equal{ml_idx}(chan);
    end
  end
end

%% Array Processing Setup
% =========================================================================

physical_constants; % c: speed of light

% DOA Setup
% -------------------------------------------------------------------------
if cfg.method >= DOA_METHOD_THRESHOLD
  doa_param.fc              = cfg.wfs.fc;
  doa_param.Nsrc            = cfg.Nsrc;
  doa_param.options         = optimoptions(@fmincon,'Display','off','Algorithm','sqp','TolX',1e-3);
  doa_param.doa_constraints = cfg.doa_constraints;
  doa_param.theta_guard     = cfg.doa_theta_guard/180*pi;
  doa_param.search_type     = cfg.doa_init;
  doa_param.theta           = theta;
  doa_param.seq             = cfg.doa_seq;
  % Setup cfgeterization for DCM
  if cfg.method == DCM_METHOD
    doa_param.h               = cfg.imp_resp.vals(:);
    doa_param.t0              = cfg.imp_resp.time_vec(1);
    doa_param.dt              = cfg.imp_resp.time_vec(2)-doa_param.t0;
  end
end

% Wideband Setup
% -------------------------------------------------------------------------
if cfg.Nsubband > 1
  doa_param.nb_filter_banks = cfg.Nsubband;
end

% dout_val_sv_idxs
% -------------------------------------------------------------------------
% The steering vector indices will be used in the max operation that is
% used to determine dout.img.
if cfg.method < DOA_METHOD_THRESHOLD
  dout_val_sv_idxs = find(theta >= cfg.theta_rng(1) & theta <= cfg.theta_rng(2));
  if isempty(dout_val_sv_idxs)
    [tmp dout_val_sv_idxs] = min(abs(theta-mean(cfg.theta_rng)));
  end
end

% sv_fh_arg1
% -------------------------------------------------------------------------
% First argument to sv_fh
sv_fh_arg1 = {'theta'};
sv_fh_arg1{2} = theta;

%% Array Processing
% =========================================================================
% Loop through each output range line and then through each output range
% bin for that range line.
for line_idx = 1:1:Nx_out
  %% Array: Setup
  rline = cfg.lines(line_idx);
  if ~mod(line_idx-1,10^floor(log10(Nx_out)-1))
    fprintf('    Record %.0f (%.0f of %.0f) (%s)\n', rline, line_idx, ...
      Nx_out, datestr(now));
  end
  
  %% Array: Edge Conditions
  % At the beginning and end of the data, we may need to restrict the range
  % lines that are used for DCM or ML.
  if rline+cfg.line_rng(1) < 1
    line_rng = 1-rline : cfg.line_rng(end);
  elseif  rline+cfg.line_rng(end) > Nx
    line_rng = cfg.line_rng(1) : Nx-rline;
  else
    line_rng = cfg.line_rng;
  end
  if ~DCM_ML_match
    if rline+cfg.DCM.line_rng(1) < 1
      DCM_line_rng = 1-rline : cfg.DCM.line_rng(end);
    elseif  rline+cfg.DCM.line_rng(end) > Nx
      DCM_line_rng = cfg.DCM.line_rng(1) : Nx-rline;
    else
      DCM_line_rng = cfg.DCM.line_rng;
    end
  end
  
  %% Array: Steering Vector Setup
  for ml_idx = 1:length(cfg.fcs)
    % Make column vectors of y and z-positions
    for wf_adc_idx = 1:length(cfg.fcs{ml_idx})
      y_pos{ml_idx}(wf_adc_idx,1) = cfg.fcs{ml_idx}{wf_adc_idx}.pos(2,rline);
      z_pos{ml_idx}(wf_adc_idx,1) = cfg.fcs{ml_idx}{wf_adc_idx}.pos(3,rline);
    end
    % Determine Steering Vector
    [~,sv{ml_idx}] = cfg.sv_fh(sv_fh_arg1,cfg.wfs.fc,y_pos{ml_idx},z_pos{ml_idx});
  end
  
  if 0
    % Debug: Check results against surface
    surface_bin = round(interp1(cfg.time,1:length(cfg.time),cfg.surface(rline)));
    
    %   Hdata = exp(1i*angle(squeeze(din{1}(surface_bin,rline,1,1,:))));
    %   sv{1} = bsxfun(@(x,y) x.*y, sv{1}, Hdata./exp(1i*angle(sv{1}(:,1))) );
    
    dataSample = din{1}(surface_bin+cfg.bin_rng,rline+line_rng,:,:,:);
    dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb, Nc]);
    dataSample = dataSample.';
    Rxx = 1/size(dataSample,1) * (dataSample * dataSample');
    
    Rxx_expected = sv{1}(:,1) * sv{1}(:,1)';
    
    angle(Rxx .* conj(Rxx_expected))
    exp(1i*angle(Rxx .* conj(Rxx_expected)));
    
    keyboard;
  end
  if 0
    % Debug: Plot steering vector correlation matrix
    ml_idx = 1;
    [theta_plot,sv{ml_idx}] = cfg.sv_fh(cfg.Nsv,cfg.fc,y_pos{ml_idx},z_pos{ml_idx});
    
    sv_table = fftshift(sv{ml_idx}.',1);
    theta_plot = fftshift(theta_plot);
    
    Rsv = sv_table * sv_table';
    h_fig = figure; clf;
    imagesc(lp(Rsv,2));
    
    ticks = [-90 -60 -40 -20 0 20 40 60];
    tick_labels = {};
    for idx=1:length(ticks)
      tick_labels{idx} = sprintf('%.0f',ticks(idx));
    end
    set(gca, 'XTick', interp1(theta_plot*180/pi,1:size(Rsv,1),ticks) );
    set(gca, 'XTickLabel',tick_labels);
    set(gca, 'YTick', interp1(theta_plot*180/pi,1:size(Rsv,1),ticks) );
    set(gca, 'YTickLabel',tick_labels);
    xlabel('Direction of arrival (deg)');
    ylabel('Direction of arrival (deg)');
    caxis([-6 0]);
    colormap(jet(256));
    h_colorbar = colorbar;
    set(get(h_colorbar,'YLabel'),'String','Correlation (dB)');
    
    keyboard
  end
  
  %% Array: DOA rangeline varying parameters
  if cfg.method >= DOA_METHOD_THRESHOLD
    doa_param.y_pc  = y_pos{1};
    doa_param.z_pc  = z_pos{1};
    doa_param.SV    = fftshift(sv{1},2);
  end
  
  if 0 && line_idx > 1
    % DEBUG CODE FOR TESTING DOA CONSTRAINTS
    warning off
    hist_bins = dout.tomo_top(rline)+(150:700).';
    hist_poly = polyfit(hist_bins,dout.doa(hist_bins,line_idx-1),2);
    warning on;
  end
  
  % Reference DoA to decide on the left and right portions of the
  % surface. Should be passed  as a field in cfg
  ref_doa = 0;
  prev_doa = [-0.1 ; +0.1]*pi/180;
  
  bin_idxs = find(cfg.bins >= cfg.bin_restriction.start_bin(rline) & cfg.bins <= cfg.bin_restriction.stop_bin(rline));
  for bin_idx = bin_idxs(:).'
    %% Array: Array Process Each Bin
    bin = cfg.bins(bin_idx);
    
    % Handle the case when the data covariance matrix support pixels and
    % pixel neighborhood multilooking do not match. Note that this is only
    % supported for MVDR.
    if ~DCM_ML_match
      if bin+cfg.DCM.bin_rng(1) < 1
        DCM_bin_rng = 1-bin : cfg.DCM.bin_rng(end);
      elseif  bin+cfg.DCM.bin_rng(end) > Nt
        DCM_bin_rng = cfg.DCM.bin_rng(1) : Nt-bin;
      else
        DCM_bin_rng = cfg.DCM.bin_rng;
      end
    end
    
    switch cfg.method
      case STANDARD_METHOD
        %% Array: Standard/Periodogram
        dataSample = din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
        dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb, Nc]);
        Sarray(:,bin_idx) = mean(abs(sv{1}(:,:)'*dataSample.').^2,2);
        for ml_idx = 2:length(din)
          dataSample = din{ml_idx}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
          dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
          Sarray(:,bin_idx) = Sarray(:,bin_idx) ...
            + mean(abs(sv{ml_idx}(:,:)'*dataSample.').^2,2);
        end
        Sarray(:,bin_idx) = Sarray(:,bin_idx) / length(din);
        
      case MVDR_METHOD
        %% Array: MVDR
        if DCM_ML_match
          % The data covariance matrix creation uses the same set of snapshots/pixels
          % than the multilook does. Implement efficient algorithm.
          
          dataSample = double(din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:));
          dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
          Rxx = 1/size(dataSample,1) * (dataSample' * dataSample);
          %         imagesc(lp(Rxx))
          %         pause;
          diagonal = sqrt(mean(mean(abs(Rxx).^2))) * diag(ones(Nc,1),0);
          Rxx_inv = inv(Rxx + cfg.diag_load*diagonal);
          for freqIdx = 1:size(sv{1},2)
            Sarray(freqIdx,bin_idx) = single(real(sv{1}(:,freqIdx).' * Rxx_inv * conj(sv{1}(:,freqIdx))));
          end
          for ml_idx = 2:length(din)
            dataSample = double(din{ml_idx}(bin+cfg.bin_rng,rline+line_rng,:,:,:));
            dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
            Rxx = 1/size(dataSample,1) * (dataSample' * dataSample);
            %         imagesc(lp(Rxx))
            %         pause;
            diagonal = sqrt(mean(mean(abs(Rxx).^2))) * diag(ones(Nc,1),0);
            Rxx_inv = inv(Rxx + cfg.diag_load*diagonal);
            for freqIdx = 1:size(sv{ml_idx},2)
              Sarray(freqIdx,bin_idx) = Sarray(freqIdx,bin_idx) ...
                + single(real(sv{ml_idx}(:,freqIdx).' * Rxx_inv * conj(sv{ml_idx}(:,freqIdx))));
            end
          end
          Sarray(:,bin_idx) = 1 ./ (Sarray(:,bin_idx) / length(din));
          
        else
          % The data covariance matrix creation uses a different set of snapshots/pixels
          % than the multilook does.
          dataSample = double(din{1}(bin+DCM_bin_rng,rline+DCM_line_rng,:,:,:));
          dataSample = reshape(dataSample,[length(DCM_bin_rng)*length(DCM_line_rng)*Na*Nb Nc]).';
          Rxx = 1/size(dataSample,2) * (dataSample * dataSample');
          
          %         imagesc(lp(Rxx))
          %         pause;
          diagonal = sqrt(mean(mean(abs(Rxx).^2))) * diag(ones(Nc,1),0);
          Rxx_inv = inv(Rxx + cfg.diag_load*diagonal);
          for freqIdx = 1:size(sv{1},2)
            w = sv{1}(:,freqIdx)' * Rxx_inv;
            dataSample = double(din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:));
            dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]).';
            
            Sarray(freqIdx,bin_idx) = mean(abs(w * dataSample).^2);
            Sarray(freqIdx,bin_idx) = Sarray(freqIdx,bin_idx) / abs(w * sv{1}(:,freqIdx)).^2;
          end
          for ml_idx = 2:length(din)
            dataSample = double(din{ml_idx}(bin+DCM_bin_rng,rline+DCM_line_rng,:,:,:));
            dataSample = reshape(dataSample,[length(DCM_bin_rng)*length(DCM_line_rng)*Na*Nb Nc]).';
            Rxx = 1/size(dataSample,2) * (dataSample * dataSample');
            %         imagesc(lp(Rxx))
            %         pause;
            
            diagonal = sqrt(mean(mean(abs(Rxx).^2))) * diag(ones(Nc,1),0);
            Rxx_inv = inv(Rxx + cfg.diag_load*diagonal);
            for freqIdx = 1:size(sv{ml_idx},2)
              w = sv{ml_idx}(:,freqIdx)' * Rxx_inv;
              dataSample = double(din{ml_idx}(bin+cfg.bin_rng,rline+line_rng,:,:,:));
              dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]).';
              
              Sarray(freqIdx,bin_idx) = Sarray(freqIdx,bin_idx) ...
                + mean(abs(w * dataSample).^2) / abs(w * sv{ml_idx}(:,freqIdx)).^2;
            end
            Sarray(freqIdx,bin_idx) = Sarray(freqIdx,bin_idx) / size(sv{1},2);
          end
        end
        
      case MUSIC_METHOD
        %% Array: MUSIC
        %  The music algorithm fIdxs the eigenvectors of the correlation
        %  matrix. The inverse of the incoherent average of the magnitude
        %  squared spectrums of the smallest eigenvectors are used.
        dataSample = din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
        dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
        
        if isempty(sv)
          Sarray(:,bin_idx) = fftshift(pmusic(dataSample,cfg.Nsrc,Nsv));
        else
          Rxx = 1/size(dataSample,1) * (dataSample' * dataSample);
          [V,D] = eig(Rxx);
          eigenVals = diag(D);
          [eigenVals noiseIdxs] = sort(eigenVals);
          
          % DEBUG CODE TO SLOWLY BUILD UP MUSIC SOLUTION, ONE EIGEN VECTOR
          % AT A TIME
          %           if 0
          %             if bin_idx >162
          %               figure(1); clf;
          %               acc = 0;
          %               Nsrc
          %               keyboard
          %               for sig_idx = 1:size(V,2)
          %                 acc = acc + abs(sv(:,:,line_idx)'*V(:,sig_idx)).^2;
          %                 plot(fftshift(lp(1./acc)),'r')
          %                 plot(fftshift(lp(1./acc)))
          %                 hold on
          %               end
          %             end
          %             SmusicEV(:,bin_idx) = eigenVals;
          %           end
          
          noiseIdxs = noiseIdxs(1:end-cfg.Nsrc);
          Sarray(:,bin_idx) = mean(abs(sv{1}(:,:).'*V(:,noiseIdxs)).^2,2);
        end
        for ml_idx = 2:length(din)
          dataSample = din{ml_idx}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
          dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
          
          if isempty(sv)
            Sarray(:,bin_idx) = pmusic(dataSample,cfg.Nsrc,Nsv);
          else
            Rxx = 1/size(dataSample,1) * (dataSample' * dataSample);
            [V,D] = eig(Rxx);
            eigenVals = diag(D);
            [eigenVals noiseIdxs] = sort(eigenVals);
            
            noiseIdxs = noiseIdxs(1:end-cfg.Nsrc);
            Sarray(:,bin_idx) = Sarray(:,bin_idx) ...
              + mean(abs(sv{ml_idx}(:,:).'*V(:,noiseIdxs)).^2,2);
          end
        end
        if isempty(sv)
          Sarray(:,bin_idx) = Sarray(:,bin_idx) / length(din);
        else
          Sarray(:,bin_idx) = 0.5 ./ (Sarray(:,bin_idx) / length(din));
        end
        
        
      case EIG_METHOD
        %% Array: EIG
        %  Same as MUSIC except the Idxividual noise subspace eigenvectors
        %  are weighted by the inverse of their corresponding eigenvalue
        %  when the incoherent averaging is done.
        error('Eigenvector not supported');
        dataSample = din(bin+eigmeth.bin_rng,rline+line_rng,:,:,:);
        dataSample = reshape(dataSample,[length(eigmeth.bin_rng)*length(line_rng)*Na*Nb Nchan]);
        if uniformSampled
          Sarray(:,Idx) = peig(dataSample,Nsrc,Ntheta);
        else
          Rxx = 1/size(dataSample,1) * (dataSample' * dataSample);
          [V,D] = eig(Rxx);
          eigenVals = diag(D).';
          [eigenVals noiseIdxs] = sort(eigenVals);
          noiseIdxs = noiseIdxs(1+Nsrc:end);
          Sarray(:,Idx) = 1./mean(repmat(1./eigenVals,[size(sv,1) 1]).*abs(sv(:,:,line_idx)'*V(:,noiseIdxs)).^2,2);
        end
        
      case RISR_METHOD
        %% Array: RISR
        %   See IEEE Transactions of Aerospace and Electronics Society
        %   2011,  (re-iterative super resolution)
        error('RISR not supported');
        dataSample = din(bin+cfg.bin_rng,rline+line_rng,:,:,:);
        dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
        
        M = size(sv,2);
        N = size(dataSample,2);
        cfg.num_iter = 15;
        cfg.alpha = 1;
        cfg.sigma_z = 0;
        cfg.R = diag([1 1 1 2 1 1 1]*1.25e-14);
        L = size(dataSample,2);
        
        dataS = dataSample.';
        W = sv(:,:);
        
        for iter = 1:cfg.num_iter
          %           fprintf('Iteration %d\n', iter);
          
          x_est = W'*dataS;
          SPD = zeros(M);
          for l = 1:L
            SPD = SPD + 1/L * (x_est(:,l) * x_est(:,l)');
          end
          SPD = SPD .* eye(M);
          
          if 0
            sig_est = sqrt(diag(SPD));
            if iter == 1
              figure(2); clf;
            else
              set(h_x_est,'Color','b');
              set(h_x_est,'Marker','none');
            end
            h_x_est = plot(lp(sig_est,2),'r.-');
            %ylim('manual');
            hold on;
            grid on;
            pause;
            %plot(lp(fftshift(fft(din,M)))); % DEBUG
          end
          
          AA = sv(:,:) * SPD * sv(:,:)';
          W = (AA + cfg.sigma_z*eye(N)*AA + cfg.alpha*cfg.R)^-1 * sv(:,:) * SPD;
        end
        sig_est = sqrt(diag(SPD));
        Sarray(:,bin_idx) = sig_est;
        
      case MVDR_ROBUST_METHOD
        %% Array: Robust MVDR
        % Shahram Shahbazpanahi, Alex B. Gershman, Zhi-Quan Luo,
        % Kon Max Wong, ???Robust Adaptive Beamforming for General-Rank
        % Signal Models????, IEEE Transactions on Signal Processing, vol 51,
        % pages 2257-2269, Sept 2003
        %
        % Isaac Tan Implementation
        
        % The data covariance matrix creation uses a different set of snapshots/pixels
        % than the multilook does.
        dataSample = double(din{1}(bin+DCM_bin_rng,rline+DCM_line_rng,:,:,:));
        dataSample = reshape(dataSample,[length(DCM_bin_rng)*length(DCM_line_rng)*Na*Nb Nc]).';
        Rxx = 1/size(dataSample,2) * (dataSample * dataSample');
        
        Rxx_inv = inv(Rxx);
        for freqIdx = 1:size(sv{1},2)
          sv_mat = sv{1}(:,freqIdx) * sv{1}(:,freqIdx)';
          sv_mat = sv_mat - 0.12*norm(sv_mat,'fro')*eye(size(sv_mat));
          
          % Get the biggest Eigenvector
          [eigen_vectors,eigen_values] = eig(Rxx*sv_mat);
          %           [~,max_idx] = max(real(diag(eigen_values)));
          [~,max_idx] = max(abs(diag(eigen_values)));
          w = eigen_vectors(:,max_idx)';
          dataSample = double(din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:));
          dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]).';
          
          Sarray(freqIdx,bin_idx) = mean(abs(w * dataSample).^2);
          Sarray(freqIdx,bin_idx) = Sarray(freqIdx,bin_idx) / abs(w * sv{1}(:,freqIdx)).^2;
        end
        for ml_idx = 2:length(din)
          dataSample = double(din{ml_idx}(bin+DCM_bin_rng,rline+DCM_line_rng,:,:,:));
          dataSample = reshape(dataSample,[length(DCM_bin_rng)*length(DCM_line_rng)*Na*Nb Nc]).';
          Rxx = 1/size(dataSample,2) * (dataSample * dataSample');
          
          Rxx_inv = inv(Rxx);
          for freqIdx = 1:size(sv{ml_idx},2)
            sv_mat = sv{ml_idx}(:,freqIdx) * sv{ml_idx}(:,freqIdx)';
            sv_mat = sv_mat - 0.25*norm(sv_mat,'fro')*eye(size(sv_mat));
            
            % Get the biggest Eigenvector
            [w,D] = eig(Rxx*sv_mat);
            w = w(:,1);
            dataSample = double(din{ml_idx}(bin+cfg.bin_rng,rline+line_rng,:,:,:));
            dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]).';
            
            Sarray(freqIdx,bin_idx) = Sarray(freqIdx,bin_idx) ...
              + mean(abs(w * dataSample).^2) / abs(w * sv{ml_idx}(:,freqIdx)).^2;
          end
          Sarray(freqIdx,bin_idx) = Sarray(freqIdx,bin_idx) / size(sv{1},2);
        end
        
        
      case MUSIC_DOA_METHOD
        %% Array: MUSIC
        %  The music algorithm fIdxs the eigenvectors of the correlation
        %  matrix. The inverse of the incoherent average of the magnitude
        %  squared spectrums of the smallest eigenvectors are used.
        % This section is used when MUSIC work as an estimator
        
        dataSample = din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
        dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
        
        array_data  = dataSample.';
        Rxx = 1/size(array_data,2) * (array_data * array_data');
        doa_param.Rxx = Rxx;
        if 1
          if isfield(cfg,'Nsig_true') && ~isempty(cfg.Nsig_true)
            if cfg.Nsig_true(bin_idx,line_idx) > 2
              cfg.Nsrc = 2;
            else
              cfg.Nsrc = cfg.Nsig_true(bin_idx,line_idx);
            end
          end
          if cfg.Nsrc == 0
            dout.doa(bin_idx,:,line_idx)     = NaN;
            dout.cost(bin_idx,line_idx)      = NaN;
            dout.hessian(bin_idx,:,line_idx) = NaN;
            dout.power(bin_idx,:,line_idx)   = NaN;
            continue
          end
          doa_param.Nsrc = cfg.Nsrc;
        end
        
        % Initialization
        doa_param.fs              = cfg.wfs.fs;
        doa_param.fc              = cfg.fc;
        doa_param.Nsrc            = cfg.Nsrc;
        doa_param.doa_constraints = cfg.doa_constraints;
        doa_param.theta_guard     = cfg.doa_theta_guard/180*pi;
        doa_param.search_type     = cfg.doa_init;
        doa_param.options         = optimoptions(@fmincon,'Display','off','Algorithm','sqp','TolX',1e-3);
        
        for src_idx = 1:cfg.Nsrc
          doa_param.src_limits{src_idx} = doa_param.doa_constraints(src_idx).init_src_limits/180*pi;
          %doa_param.src_limits{src_idx} = [-pi/2 pi/2]; % DEBUG
        end
        
        theta0 = music_initialization(Rxx,doa_param);
        
        % Lower/upper bounds
        for src_idx = 1:cfg.Nsrc
          doa_param.src_limits{src_idx} = doa_param.doa_constraints(src_idx).src_limits/180*pi;
          %doa_param.src_limits{src_idx} = [-pi/2 pi/2]; % DEBUG
          LB(src_idx) = doa_param.src_limits{src_idx}(1);
          UB(src_idx) = doa_param.src_limits{src_idx}(2);
        end
        
        % Run the optimizer
        doa_nonlcon_fh = eval(sprintf('@(x) doa_nonlcon(x,%f);', doa_param.theta_guard));
        
        [doa,Jval,exitflag,OUTPUT,~,~,HESSIAN] = ...
          fmincon(@(theta_hat) music_cost_function(theta_hat,doa_param), theta0,[],[],[],[],LB,UB,doa_nonlcon_fh,doa_param.options);
        
        
        % Apply pseudoinverse and estimate power for each source
        Nsv2{1} = 'theta';
        Nsv2{2} = doa(:)';
        [~,A] = cfg.sv_fh(Nsv2,doa_param.fc,doa_param.y_pc,doa_param.z_pc);
        Weights = (A'*A)\A';
        S_hat   = Weights*dataSample.';
        P_hat   = mean(abs(S_hat).^2,2);
        
        [doa,sort_idxs] = sort(doa,'ascend');
        for sig_i = 1:length(doa)
          % Negative/positive DOAs are on the left/right side of the surface
          if doa(sig_i)<0
            sig_idx = 1;
          elseif doa(sig_i)>=0
            sig_idx = 2;
          end
          dout.doa(bin_idx,sig_idx,line_idx)     = doa(sig_i);
          dout.hessian(bin_idx,sig_idx,line_idx) = HESSIAN(sort_idxs(sig_i) + length(sort_idxs)*(sort_idxs(sig_i)-1));
          dout.power(bin_idx,sig_idx,line_idx)   = P_hat(sig_i);
        end
        dout.cost(bin_idx,line_idx) = Jval;
        %
        %           dout.doa(bin_idx,:,line_idx)     = doa;
        %           dout.cost(bin_idx,line_idx)      = Jval;
        %           dout.hessian(bin_idx,:,line_idx) = diag(HESSIAN);
        %           dout.power(bin_idx,:,line_idx)   = P_hat;
        
      case MLE_METHOD
        %% Array: MLE
        % See Wax, Alternating projection maximum likelihood estimation for
        % direction of arrival, TSP 1983?
        dataSample  = din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
        dataSample  = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
        array_data  = dataSample.';
        Rxx         = (1/size(array_data,2)) * (array_data * array_data');
        doa_param.Rxx = Rxx; % put Rxx in doa_param (to pass to fminsearch)
        
        if isfield(cfg,'testing') && ~isempty(cfg.testing) && cfg.testing==1 ...
            && isfield(cfg,'optimal_test') && ~isempty(cfg.optimal_test) && cfg.optimal_test==1
          % MOE simulations
          cfg.Nsig_new = cfg.Nsrc;
        else
          if 1 && isfield(cfg,'Nsig_true') && ~isempty(cfg.Nsig_true)
            if cfg.Nsig_true(bin_idx,line_idx) > 2
              cfg.Nsig_new = 2;
            else
              cfg.Nsig_new = cfg.Nsig_true(bin_idx,line_idx);
            end
          else
            if cfg.Nsrc > 2
              cfg.Nsrc = 2;
            end
            cfg.Nsig_new = cfg.Nsrc;
          end
          cfg.Nsig_new = cfg.Nsrc;
        end
        if (cfg.Nsrc == 0) || ...
            (isfield(cfg,'Nsig_true') && ~isempty(cfg.Nsig_true) && cfg.Nsig_true(bin_idx,line_idx) == 0)
          dout.tomo.theta(bin_idx,:,line_idx) = NaN;
          dout.tomo.cost(bin_idx,line_idx) = NaN;
          dout.tomo.hessian(bin_idx,:,line_idx) = NaN;
          dout.tomo.img(bin_idx,:,line_idx) = NaN;
          continue
        end
        %           doa_param.Nsrc = cfg.Nsig_new;
        
        clear sources_number
        % Determine the possible number of DoAs
        % --------------------------------------
        if (isfield(cfg,'testing') && ~isempty(cfg.testing) && cfg.testing==1) ...
            || (~isfield(cfg,'testing'))
          % Model order estimation: optimal
          % ------------------------------
          if isfield(cfg,'optimal_test') && ~isempty(cfg.optimal_test) && cfg.optimal_test==1
            possible_Nsig_opt = [1 : max(cfg.Nsrc)];
          end
          
          % Model order estimation: suboptimal
          % ---------------------------------
          if isfield(cfg,'suboptimal_test') && ~isempty(cfg.suboptimal_test) && cfg.suboptimal_test==1
            % Determine the eigenvalues of Rxx
            eigval = eig(Rxx);
            eigval = sort(real(eigval),'descend');
            
            model_order_suboptimal_cfg.Nc         = Nc;
            model_order_suboptimal_cfg.Nsnap      = size(array_data,2);
            model_order_suboptimal_cfg.eigval     = eigval;
            model_order_suboptimal_cfg.penalty_NT = cfg.penalty_NT;
            
            cfg_MOE.norm_term_suboptimal = cfg.norm_term_suboptimal;
            cfg_MOE.norm_allign_zero     = cfg.norm_allign_zero;
            model_order_suboptimal_cfg.cfg_MOE = cfg_MOE;
            
            sources_number_all = [];
            for model_order_method = cfg.moe_methods
              model_order_suboptimal_cfg.method  = model_order_method;
              sources_number = sim.model_order_suboptimal(model_order_suboptimal_cfg);
              
              switch model_order_method
                case 0
                  model_order_results_suboptimal.NT.Nest(bin_idx,line_idx)    = sources_number;
                case 1
                  model_order_results_suboptimal.AIC.Nest(bin_idx,line_idx)   = sources_number;
                case 2
                  model_order_results_suboptimal.HQ.Nest(bin_idx,line_idx)    = sources_number;
                case 3
                  model_order_results_suboptimal.MDL.Nest(bin_idx,line_idx)   = sources_number;
                case 4
                  model_order_results_suboptimal.AICc.Nest(bin_idx,line_idx)  = sources_number;
                case 5
                  model_order_results_suboptimal.KICvc.Nest(bin_idx,line_idx) = sources_number;
                case 6
                  model_order_results_suboptimal.WIC.Nest(bin_idx,line_idx)   = sources_number;
                otherwise
                  error('Not supported')
              end
              sources_number_all(model_order_method+1) = sources_number;
            end
            
            possible_Nsig_subopt = max(sources_number_all);
            if possible_Nsig_subopt > cfg.Nsrc
              possible_Nsig_subopt = cfg.Nsrc;
            end
            
          end
        end
        
        if exist('possible_Nsig_opt','var')
          possible_Nsig = possible_Nsig_opt;
        elseif exist('possible_Nsig_subopt','var')
          possible_Nsig = possible_Nsig_subopt;
        else
          possible_Nsig = cfg.Nsig_new;
        end
        
        % Estimate DoA for all possible number of targets
        % -----------------------------------------------
        doa_mle = [];
        if ~isempty(possible_Nsig) && max(possible_Nsig) ~= 0
          % Don't process zero-targets case, which can happen, upto this
          % point, in the case of suboptimal MOE.
          for Nsrc_idx = possible_Nsig
            % Setup DOA Constraints
            for src_idx = 1:Nsrc_idx
              % Determine src_limits for each constraint
              doa_res = doa_param.doa_constraints(src_idx);
              switch (doa_res.method)
                case 'surfleft' % Incidence angle to surface clutter on left
                  mid_doa(src_idx) = acos(cfg.surface(rline) / cfg.time(bin));
                case 'surfright'% Incidence angle to surface clutter on right
                  mid_doa(src_idx) = -acos(cfg.surface(rline) / cfg.time(bin));
                case 'layerleft'
                  table_doa   = [0:89.75]/180*pi;
                  table_delay = cfg.surface(rline) ./ cos(table_doa) ...
                    + (doa_res.layer.twtt(rline)-cfg.surface(rline)) ./ cos(asin(sin(table_doa)/sqrt(er_ice)));
                  doa_res.layer.twtt(rline) = max(doa_res.layer.twtt(rline),cfg.surface(rline));
                  if cfg.time(bin) <= doa_res.layer.twtt(rline)
                    mid_doa(src_idx) = 0;
                  else
                    mid_doa(src_idx) = interp1(table_delay, table_doa, cfg.time(bin));
                  end
                case 'layerright'
                  table_doa = [0:89.75]/180*pi;
                  table_delay = cfg.surface(rline) ./ cos(table_doa) ...
                    + (doa_res.layer.twtt(rline)-cfg.surface(rline)) ./ cos(asin(sin(table_doa)/sqrt(er_ice)));
                  doa_res.layer.twtt(rline) = max(doa_res.layer.twtt(rline),cfg.surface(rline));
                  if cfg.time(bin) <= doa_res.layer.twtt(rline)
                    mid_doa(src_idx) = 0;
                  else
                    mid_doa(src_idx) = -interp1(table_delay, table_doa, cfg.time(bin));
                  end
                otherwise % 'fixed'
                  mid_doa(src_idx) = 0;
              end
            end
            
            % Sequential MLE (S-MLE) section
            % -----------------------------------------------------------
            % Calculate current and next DoAs using the flat
            % earth approximation. If not calculated, it still
            % work as MLE, but not sequential MLE
            
            if cfg.doa_seq
              % Prepare current and next DoAs uisng flat earth approximation
              if bin_idx == first_bin_idx
                tmp_doa = prev_doa;
                doa_flat_earth_curr = prev_doa;
                for doa_idx = 1:length(tmp_doa)
                  doa_flat_earth_next(doa_idx,1) = sign(prev_doa(doa_idx))*acos((R_bins_values(bin_idx)/R_bins_values(bin_idx+1)) * cos(prev_doa(doa_idx)));
                  if tmp_doa(doa_idx) < ref_doa
                    % Left DoA
                    sign_doa(doa_idx) = -1;
                  elseif tmp_doa(doa_idx) >= ref_doa
                    % Right DoA
                    sign_doa(doa_idx) = +1;
                  end
                end
                
              elseif bin_idx > first_bin_idx && bin_idx < Nt
                good_doa_idx = find(prev_doa(~isnan(prev_doa)));
                
                tmp_doa = doa_flat_earth_curr;
                tmp_doa(good_doa_idx) = prev_doa(good_doa_idx);
                tmp_doa = sort(tmp_doa,'ascend');
                for doa_idx = 1:length(tmp_doa)
                  if tmp_doa(doa_idx) < ref_doa
                    % Left DoA
                    sign_doa(doa_idx) = -1;
                  elseif tmp_doa(doa_idx) >= ref_doa
                    % Right DoA
                    sign_doa(doa_idx) = +1;
                  end
                  
                  doa_flat_earth_curr(doa_idx,1) = sign_doa(doa_idx)*acos((R_bins_values(bin_idx-1)/R_bins_values(bin_idx)) * cos(tmp_doa(doa_idx)));
                  doa_flat_earth_next(doa_idx,1) = sign_doa(doa_idx)*acos((R_bins_values(bin_idx-1)/R_bins_values(bin_idx+1)) * cos(tmp_doa(doa_idx)));
                end
                
              elseif bin_idx == Nt
                for doa_idx = 1:length(tmp_doa)
                  if tmp_doa(doa_idx) < ref_doa
                    % Left DoA
                    sign_doa(doa_idx) = -1;
                  elseif tmp_doa(doa_idx) > ref_doa
                    % Right DoA
                    sign_doa(doa_idx) = +1;
                  end
                  doa_flat_earth_curr(doa_idx,1) = sign_doa(doa_idx)*acos((R_bins_values(bin_idx-1)/R_bins_values(bin_idx)) * cos(tmp_doa(doa_idx)));
                  doa_flat_earth_next(doa_idx,1) = doa_flat_earth_curr(doa_idx,1) + delta_doa(doa_idx,1);
                end
                
                tmp_doa = sort(tmp_doa,'ascend');
              end
              
              % Change in DoA from current range-bin to the next
              delta_doa = doa_flat_earth_next-doa_flat_earth_curr;
              
              % Upper and lower DoA bounds and initial DoA
              mul_const = 2;
              for doa_idx = 1:length(tmp_doa)
                if sign_doa(doa_idx) == -1
                  % Left DoA
                  if bin_idx ~= first_bin_idx
                    UB(doa_idx,1) = tmp_doa(doa_idx) + sign_doa(doa_idx)*doa_param.theta_guard; %0.5*pi/180;
                  else
                    UB(doa_idx,1) = tmp_doa(doa_idx);
                  end
                  
                  mean_doa(doa_idx,1) = UB(doa_idx,1) + delta_doa(doa_idx,1);
                  
                  if 1
                    LB(doa_idx,1) = mean_doa(doa_idx,1) + mul_const*delta_doa(doa_idx,1);
                  elseif 0
                    if abs(delta_doa(doa_idx,1)) < 5*pi/180
                      LB(doa_idx,1) = mean_doa(doa_idx,1) + mul_const*delta_doa(doa_idx,1)*pi/180;
                    else
                      LB(doa_idx,1) = mean_doa(doa_idx,1) + mul_const/2*delta_doa(doa_idx,1);
                    end
                  end
                  
                  if UB(doa_idx,1)>ref_doa
                    UB(doa_idx,1) = ref_doa;
                  end
                  
                  if LB(doa_idx,1)>UB(doa_idx,1)
                    warning('Lower bound is greater than upper bound .. Consider loosening your DoA bounds')
                    keyboard;
                    % UB(doa_idx,1) = LB(doa_idx,1);
                  end
                else
                  % Right DoA
                  if bin_idx ~= first_bin_idx
                    LB(doa_idx,1) = tmp_doa(doa_idx) + sign_doa(doa_idx)*doa_param.theta_guard;%0.5*pi/180;
                  else
                    LB(doa_idx,1) = tmp_doa(doa_idx);
                  end
                  
                  mean_doa(doa_idx,1) = LB(doa_idx,1) + delta_doa(doa_idx,1);
                  
                  if 1
                    UB(doa_idx,1) = mean_doa(doa_idx,1) + mul_const*delta_doa(doa_idx,1);
                  elseif 0
                    if abs(delta_doa(doa_idx,1)) < 5*pi/180
                      UB(doa_idx,1) = mean_doa(doa_idx,1) + mul_const*delta_doa(doa_idx,1)*pi/180;
                    else
                      UB(doa_idx,1) = mean_doa(doa_idx,1) + mul_const/2*delta_doa(doa_idx,1);
                    end
                  end
                  
                  if LB(doa_idx,1)<ref_doa
                    LB(doa_idx,1) = ref_doa;
                  end
                  
                  if LB(doa_idx,1)>UB(doa_idx,1)
                    warning('Lower bound is greater than upper bound .. Consider loosening your DoA bounds')
                    keyboard;
                  end
                end
              end
              
              if 0
                theta0 = mean_doa;
                %                  theta0 = (LB+UB)./2;
              elseif 1
                % This needs to be checked more. It may lead to the case of LB > UB.
                for src_idx = 1:Nsrc_idx %cfg.Nsrc
                  doa_param.src_limits{src_idx} = [LB(src_idx)  UB(src_idx)];
                end
                % doa_nonlcon_fh = eval(sprintf('@(x) doa_nonlcon(x,%f);', doa_param.theta_guard));
                doa_param.Nsrc = Nsrc_idx;
                theta0 = mle_initialization(Rxx,doa_param);
              end
              
              % Choose the a priri pdf (pdf of the DOA before taking
              % measurements). There is Uniform and Gaussian only
              % at this point. In both case you should pass in variance
              % (mean is the same for both distributions).
              if 1
                % Gaussian a priori pdf: variance is small
                var_doa = delta_doa.^2;
              elseif 0
                % Uniform a priori pdf: variance if large (e.g. 5 or 10)
                var_doa = 10;
              end
              
              doa_param.apriori.mean_doa = mean_doa;
              doa_param.apriori.var_doa  = var_doa;
            end
            
            if ~exist('theta0','var')
              % Initialize search
              for src_idx = 1:Nsrc_idx %cfg.Nsrc
                doa_param.src_limits{src_idx} = mid_doa(src_idx) ...
                  + doa_param.doa_constraints(src_idx).init_src_limits/180*pi;
                %doa_param.src_limits{src_idx} = [-pi/2 pi/2]; % DEBUG
              end
              
              %                             doa_nonlcon_fh = eval(sprintf('@(x) doa_nonlcon(x,%f);', doa_param.theta_guard));
              doa_param.Nsrc = Nsrc_idx;
              theta0 = mle_initialization(Rxx,doa_param);
            end
            
            % Minimization of wb_cost_function
            % -------------------------------------------------------------
            doa_nonlcon_fh = eval(sprintf('@(x) doa_nonlcon(x,%f);', doa_param.theta_guard));
            % Set source limits
            lower_lim = zeros(Nsrc_idx,1);
            upper_lim = zeros(Nsrc_idx,1);
            for src_idx = 1:Nsrc_idx %cfg.Nsrc
              doa_param.src_limits{src_idx} = mid_doa(src_idx) ...
                + doa_param.doa_constraints(src_idx).src_limits/180*pi;
              %doa_param.src_limits{src_idx} = [-pi/2 pi/2]; % DEBUG
              lower_lim(src_idx) = doa_param.src_limits{src_idx}(1);
              upper_lim(src_idx) = doa_param.src_limits{src_idx}(2);
            end
            
            if ~exist('LB','var') && ~exist('UB','var')
              LB = lower_lim;
              UB = upper_lim;
            end
            
            doa = [];
            if max(theta0)>max(UB)
              keyboard;
            end
            
            warning off;
            if max(UB)<=max(upper_lim) && min(LB)>=min(lower_lim)
              if cfg.doa_seq && Nsrc_idx == 1
                % S-MLE is setup to handle 2 DOAs at a time (left and right)
                % So, if there is one DOA, then choose the one that his
                % lower cost (or larger log-likelihood)
                for tmp_doa_idx = 1:length(tmp_doa)
                  doa_param.apriori.mean_doa = mean_doa(tmp_doa_idx);
                  doa_param.apriori.var_doa  = var_doa(tmp_doa_idx);
                  [doa,Jval,exitflag,OUTPUT,~,~,HESSIAN] = ...
                    fmincon(@(theta_hat) mle_cost_function(theta_hat,doa_param), theta0,[],[],[],[],LB(tmp_doa_idx),UB(tmp_doa_idx),doa_nonlcon_fh,doa_param.options);
                  
                  tmp_DOA(tmp_doa_idx) = doa;
                  tmp_cost(tmp_doa_idx) = Jval;
                end
                [~, best_doa_idx] = nanmin(tmp_cost);
                doa = tmp_DOA(best_doa_idx);
              else
                [doa,Jval,exitflag,OUTPUT,~,~,HESSIAN] = ...
                  fmincon(@(theta_hat) mle_cost_function(theta_hat,doa_param), theta0,[],[],[],[],LB,UB,doa_nonlcon_fh,doa_param.options);
              end
              
              if 0
                % Set any repeated DoAs to NaN. Repeated DoAs makes
                % the projection matrix non-invertible (i.e. all NaN)
                doa_tol = 0.5*pi/180;
                for doa_idx = 1:length(doa)
                  doa_diff = abs(doa(doa_idx)-doa);
                  rep_doa_idx = find(doa_diff<=doa_tol);
                  if length(rep_doa_idx) > 1
                    doa(rep_doa_idx(2:end)) = NaN;
                  end
                end
              end
            else
              %                             keyboard
              doa = NaN(Nsrc_idx,1);
              HESSIAN = NaN(Nsrc_idx);
              Jval = NaN;
            end
            
            clear theta0 LB UB
            
            [doa,sort_idxs] = sort(doa);
            
            doa_mle{Nsrc_idx} = doa;
            
          end
        end
        
        % MOHANAD: Model order estimation: optimal
        % ----------------------------------------
        if ~isempty(doa_mle) && isfield(cfg,'testing') && ~isempty(cfg.testing) && cfg.testing==1 ...
            && isfield(cfg,'optimal_test') && ~isempty(cfg.optimal_test) && cfg.optimal_test==1
          % Determine the eigenvalues and eigenvectors of Rxx
          [eigvec,eigval] = eig(Rxx);
          [eigval,index]  = sort(real(diag(eigval)),'descend');
          eigvec          = eigvec(:,index);
          
          model_order_optimal_cfg.Nc         = Nc;
          model_order_optimal_cfg.Nsnap      = size(array_data,2);
          model_order_optimal_cfg.eigval     = eigval;
          model_order_optimal_cfg.eigvec     = eigvec;
          model_order_optimal_cfg.penalty_NT_opt = cfg.penalty_NT_opt;
          
          cfg_MOE.norm_term_optimal = cfg.norm_term_optimal;
          cfg_MOE.opt_norm_term     = cfg.opt_norm_term;
          cfg_MOE.norm_allign_zero  = cfg.norm_allign_zero;
          model_order_optimal_cfg.cfg_MOE  = cfg_MOE;
          model_order_optimal_cfg.doa_mle    = doa_mle;
          
          model_order_optimal_cfg.y_pc  = doa_param.y_pc;
          model_order_optimal_cfg.z_pc  = doa_param.z_pc;
          model_order_optimal_cfg.fc    = cfg.fc;
          
          for model_order_method = cfg.moe_methods
            model_order_optimal_cfg.method  = model_order_method;
            
            [sources_number,doa] = sim.model_order_optimal(model_order_optimal_cfg);
            
            switch model_order_method
              case 0
                dout.moe.NT.Nest(bin_idx,line_idx)    = sources_number;
                dout.moe.NT.doa(bin_idx,:,line_idx)     = doa;
              case 1
                dout.moe.AIC.Nest(bin_idx,line_idx)   = sources_number;
                dout.moe.AIC.doa(bin_idx,:,line_idx)    = doa;
              case 2
                dout.moe.HQ.Nest(bin_idx,line_idx)    = sources_number;
                dout.moe.HQ.doa(bin_idx,:,line_idx)     = doa;
              case 3
                dout.moe.MDL.Nest(bin_idx,line_idx)   = sources_number;
                dout.moe.MDL.doa(bin_idx,:,line_idx)    = doa;
              case 4
                dout.moe.AICc.Nest(bin_idx,line_idx)  = sources_number;
                dout.moe.AICc.doa(bin_idx,:,line_idx)   = doa;
              case 5
                dout.moe.KICvc.Nest(bin_idx,line_idx) = sources_number;
                dout.moe.KICvc.doa(bin_idx,:,line_idx)  = doa;
              case 6
                dout.moe.WIC.Nest(bin_idx,line_idx)   = sources_number;
                dout.moe.WIC.doa(bin_idx,:,line_idx)    = doa;
              otherwise
                error('Not supported')
            end
          end
        end
        
        % Store the DOAs of maximum possible targets
        %          dout.all_DOAs(bin_idx,:,line_idx) = doa_mle{end};
        
        if ~exist('sources_number','var')
          sources_number = length(doa_mle) ;%cfg.Nsrc;
        end
        
        if ~isempty(sources_number) && (sources_number ~= 0)
          doa = doa_mle{sources_number};
          % Apply pseudoinverse and estimate power for each source
          Nsv2{1} = 'theta';
          Nsv2{2} = doa(:)';
          [~,A] = cfg.sv_fh(Nsv2,doa_param.fc,doa_param.y_pc,doa_param.z_pc);
          %            k       = 4*pi*doa_param.fc/c;
          %            A       = sqrt(1/length(doa_param.y_pc))*exp(1i*k*(doa_param.y_pc*sin(doa(:)).' - doa_param.z_pc*cos(doa(:)).'));
          Weights = (A'*A)\A';
          %         Weights         = inv(A'*A)*A';
          S_hat           = Weights*array_data;
          P_hat           = mean(abs(S_hat).^2,2);
          warning on;
          
          % This loop is to handle the case where Nsrc<Nsig_max
          % (cfg.Nsrc)
          for sig_i = 1:sources_number
            % Negative/positive DOAs are on the left/right side of the surface
            if doa(sig_i)<0
              sig_idx = 1;
            elseif doa(sig_i)>=0
              sig_idx = 2;
            end
            dout.tomo.theta(bin_idx,sig_idx,line_idx)     = doa(sig_i);
            dout.tomo.hessian(bin_idx,sig_idx,line_idx) = HESSIAN(sort_idxs(sig_i) + length(sort_idxs)*(sort_idxs(sig_i)-1));
            dout.tomo.img(bin_idx,sig_idx,line_idx)   = P_hat(sig_i);
          end
          dout.tomo.cost(bin_idx,line_idx) = Jval;
        end
        
        if cfg.moe_en && all(~isnan(dout.moe.NT.doa(bin_idx,:,line_idx)))
          prev_doa = dout.moe.NT.doa(bin_idx,:,line_idx);
          prev_doa = sort(prev_doa(~isnan(prev_doa)),'ascend');
        else
          prev_doa = doa;
        end
        
        if 0
          %% Array: DEBUG code to plot cost function
          Ngrid     = 128;
          dNgrid    = 2/Ngrid;
          uy        = dNgrid*[0 : floor((Ngrid-1)/2), -floor(Ngrid/2) : -1];
          uz        = sqrt(1 - uy.^2);
          grid_vec  = atan2(uy,uz);
          grid_vec  = fftshift(grid_vec);
          switch cfg.Nsrc
            case 1 % 1 source
              cf_vals = zeros(Ngrid,1);
              for eval_idx = 1:length(grid_vec);
                eval_theta = grid_vec(eval_idx);
                eval_theta = eval_theta(:);
                cf_vals(eval_idx) = mle_cost_function(eval_theta,doa_param);
              end
              figure(700);clf
              plot(grid_vec.*180/pi,cf_vals)
              grid on
            case 2  % 2 sources
              [grid1,grid2] = meshgrid(grid_vec);
              cf_vals = zeros(Ngrid,Ngrid);
              for row_index = 1:Ngrid
                for col_index = 1:Ngrid
                  eval_theta = [grid1(row_index,col_index) grid2(row_index,col_index)];
                  cf_vals(row_index,col_index) = mle_cost_function(eval_theta,doa_param);
                end
              end
              figure(701);clf
              grid_mask = grid1 <= grid2;
              cf_vals(grid_mask) = NaN;
              figure(101);mesh(grid1.*180/pi,grid2.*180/pi,-1.*cf_vals)
              xlabel('\theta_1')
              ylabel('\theta_2')
            otherwise
              error('Not supported')
          end
        end
        
        if 0 %% DEBUG code for bin restriction
          hist_bins = cfg.bin_restriction.start_bin(rline)+(150:700).';
          hist_poly = polyfit(hist_bins,dout.tomo.theta(hist_bins,line_idx-1),2);
          plot(hist_bins,dout.tomo.theta(hist_bins,line_idx-1),'.');
          hist_val = polyval(hist_poly,hist_bins);
          hold on;
          plot(hist_bins, hist_val,'r');
          hold off;
          
          hist_bins = dout.bin_restriction.start_bin(rline)+(150:1700).';
          hist3([ hist_bins, dout.tomo.theta(hist_bins,line_idx-1)],[round(length(hist_bins)/20) 30])
          set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
        end
        
        
      case DCM_METHOD
        %% Array: DCM
        % Parametric, space-time doa estimator for wideband or wide aperture direction of arrival estimation
        % See Theresa Stumpf, MS Thesis 2015
        
        % Estimate space-time covariance matrix
        % ----------------------------------------------------------------
        dataSample = [];
        for W_offset = -floor((cfg.Nsubband-1)/2):floor((cfg.Nsubband-1)/2)
          offset_bin      = bin + W_offset;
          dataSample_tmp  = double(din{1}(offset_bin + cfg.bin_rng,rline+line_rng,:,:,:));
          dataSample_tmp  = reshape(dataSample_tmp,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]).';
          dataSample      = cat(1,dataSample,dataSample_tmp);
        end
        
        DCM             = (1/size(dataSample,2))*dataSample*dataSample';
        doa_param.DCM   = DCM;
        
        % Setup DOA Constraints
        for src_idx = 1:cfg.Nsrc
          % Determine src_limits for each constraint
          doa_res = doa_param.doa_constraints(src_idx);
          switch (doa_res.method)
            case 'surfleft' % Incidence angle to surface clutter on left
              mid_doa(src_idx) = acos(cfg.surface(rline) / cfg.time(bin));
            case 'surfright'% Incidence angle to surface clutter on right
              mid_doa(src_idx) = -acos(cfg.surface(rline) / cfg.time(bin));
            case 'layerleft'
              table_doa   = [0:89.75]/180*pi;
              table_delay = cfg.surface(rline) ./ cos(table_doa) ...
                + (doa_res.layer.twtt(rline)-cfg.surface(rline)) ./ cos(asin(sin(table_doa)/sqrt(er_ice)));
              doa_res.layer.twtt(rline) = max(doa_res.layer.twtt(rline),cfg.surface(rline));
              if cfg.time(bin) <= doa_res.layer.twtt(rline)
                mid_doa(src_idx) = 0;
              else
                mid_doa(src_idx) = interp1(table_delay, table_doa, cfg.time(bin));
              end
            case 'layerright'
              table_doa = [0:89.75]/180*pi;
              table_delay = cfg.surface(rline) ./ cos(table_doa) ...
                + (doa_res.layer.twtt(rline)-cfg.surface(rline)) ./ cos(asin(sin(table_doa)/sqrt(er_ice)));
              doa_res.layer.twtt(rline) = max(doa_res.layer.twtt(rline),cfg.surface(rline));
              if cfg.time(bin) <= doa_res.layer.twtt(rline)
                mid_doa(src_idx) = 0;
              else
                mid_doa(src_idx) = -interp1(table_delay, table_doa, cfg.time(bin));
              end
            otherwise % 'fixed'
              mid_doa(src_idx) = 0;
          end
        end
        
        % Initialize search
        for src_idx = 1:cfg.Nsrc
          doa_param.src_limits{src_idx} = mid_doa(src_idx) ...
            + doa_param.doa_constraints(src_idx).init_src_limits/180*pi;
          %doa_param.src_limits{src_idx} = [-pi/2 pi/2]; % DEBUG
        end
        theta0 = wb_initialization(DCM,doa_param);
        
        %% Minimization of wb_cost_function
        % Set source limits
        LB = zeros(cfg.Nsrc,1);
        UB = zeros(cfg.Nsrc,1);
        for src_idx = 1:cfg.Nsrc
          doa_param.src_limits{src_idx} = mid_doa(src_idx) ...
            + doa_param.doa_constraints(src_idx).src_limits/180*pi;
          %doa_param.src_limits{src_idx} = [-pi/2 pi/2]; % DEBUG
          LB(src_idx) = doa_param.src_limits{src_idx}(1);
          UB(src_idx) = doa_param.src_limits{src_idx}(2);
        end
        
        % Transform intputs into constrained domain (fminsearch only)
        % for src_idx = 1:cfg.Nsrc
        %   theta0(src_idx) = acos((theta0(src_idx) ...
        %     - sum(doa_param.src_limits{src_idx})/2)*2/diff(doa_param.src_limits{src_idx})); % fminsearch
        % end
        
        % Transform input out of constrained domain (fminsearch only)
        % for src_idx = 1:length(doa_param.src_limits)
        %   if ~isempty(doa_param.doa_constraints(src_idx).src_limits)
        %     doa(src_idx) = cos(doa(src_idx))*diff(doa_param.src_limits{src_idx})/2 ...
        %       + sum(doa_param.src_limits{src_idx})/2;
        %   end
        % end
        
        doa_nonlcon_fh = eval(sprintf('@(x) doa_nonlcon(x,%f);', doa_param.theta_guard));
        
        % Perform minimization
        %[doa,Jval,exitflag,OUTPUT] = ...
        %  fminsearch(@(theta_hat) wb_cost_function(theta_hat,doa_param), theta0,doa_param.options);
        [doa,Jval,exitflag,OUTPUT,~,~,HESSIAN] = ...
          fmincon(@(theta_hat) wb_cost_function(theta_hat,doa_param), theta0,[],[],[],[],LB,UB,doa_nonlcon_fh,doa_param.options);
        
        %% Estimate relative power for each source
        % -----------------------------------------------------------------
        % This section does the following:
        % 1) Creates an Nc x Nsnap complex valued matrix (where Nc is the
        % number of receive elements and Nsnap is the number of snapsots,
        % NOTE that Nsnap = length(cfg.bin_rng) +
        % length(cfg.line_rng) + Na + Nb), denoted by array_data
        %
        % 2) Computes the delays needed to registered to doas obtained for
        % a particular pixel and stores them in tau_reg,
        %
        % 3) Loops over sources and
        %       i.  Uses tau_reg to create sinc interpolation filters for
        %           each channel and tapers edges with Hamming weights,
        %       ii. Registers each channel to the particular source,
        %       iii.Applies pseudo-inverse to registered data,
        %       iv. Estimates signal and power,
        
        % Setup matrix of array data used to estimate relative power of
        % each source
        %
        %         array_data  = din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
        %         array_data  = reshape(array_data,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
        %         array_data  = array_data.';
        
        if strcmpi('layerleft',doa_res.method)
          source_indexes = 1;
        elseif strcmpi('layerright',doa_res.method)
          source_indexes = 2;
        else
          source_indexes = 1:cfg.Nsrc;
        end
        
        % S_hat: Nsrc by bin_snapshots*rline_snapshots
        S_hat       = nan(length(doa),length(cfg.bin_rng)*length(line_rng));
        % tau_reg: longer delay to sensor means more negative
        tau_reg     = (2/c)*(doa_param.y_pc*sin(doa(:)).' - doa_param.z_pc*cos(doa(:)).');
        for src_idx = source_indexes;
          
          % Do each fast time snapshot separately and accumulate the result
          % into array_data
          array_data = [];
          for nt_idx = cfg.bin_rng
            offset_bin = bin + nt_idx;
            
            % For each channel
            registered_data = zeros(Nc,length(line_rng)*Na*Nb);
            for nc_idx = 1:Nc
              tmp_chan_data = double(din{1}(offset_bin + cfg.reg_bins, rline + line_rng,:,:,nc_idx));
              tmp_chan_data = reshape(tmp_chan_data, [length(cfg.reg_bins) length(line_rng)*Na*Nb]);
              % Create sinc interpolation coefficients with hamming window
              % tapir
              %   E.g. tau_reg negative means this sensor is delayed relative to
              %   the others and therefore the sinc peak should show up at > 0.
              Hinterp       = sinc(tau_reg(nc_idx,src_idx).*doa_param.fs + cfg.reg_bins.') ...
                .* hamming(length(cfg.reg_bins));
              
              % Apply the sinc filter to the data
              registered_data(nc_idx,:) ...
                = sum(repmat(Hinterp, [1 size(tmp_chan_data,2)]) .* tmp_chan_data);
            end
            
            % Accumulate the result for each fast time snapshot
            array_data = cat(2,array_data,registered_data);
          end
          A               = (exp(1i*2*pi*doa_param.fc*tau_reg));
          Weights         = inv(A'*A)*A';
          Weights         = Weights(src_idx,:);
          S_hat(src_idx,:)= Weights*array_data;
          
        end
        
        if 0
          H_interp = [];
          for nc_idx = 1:Nc
            H_interp(:,nc_idx) = sinc(tau_reg(nc_idx,src_idx).*doa_param.fs + cfg.reg_bins.') ...
              .*hamming(length(cfg.reg_bins));
          end
          
          figure;imagesc(lp(H_interp));
          figure;imagesc(lp(squeeze(din{1}(bin + cfg.reg_bins,rline,1,1,:))))
          keyboard
        end
        
        
        if 0
          unreg_data = [];
          for debug_idx = cfg.bin_rng;
            tmp_unreg_data = double(din{1}(bin + debug_idx,rline + line_rng,:,:,:));
            tmp_unreg_data = reshape(tmp_unreg_data, [length(line_rng)*Na*Nb Nc]).';
            unreg_data = cat(2,unreg_data,tmp_unreg_data);
          end
          
          
          haxis_list = [];
          h_fig = src_idx*100;
          figure(h_fig);clf;
          haxis_list(end+1) = axes('Parent', h_fig);
          hold(haxis_list(end),'on');
          plot(lp(interpft(unreg_data.',10*size(unreg_data,2))),'parent',haxis_list(end))
          grid on
          title(sprintf('Source %d, Before Registration',src_idx))
          
          h_fig = src_idx*100 + 1;
          figure(h_fig);clf;
          haxis_list(end+1) = axes('Parent', h_fig);
          hold(haxis_list(end),'on');
          plot(lp(interpft(array_data.',10*size(array_data,2))),'parent',haxis_list(end))
          grid on
          title(sprintf('Source %d, After Registration',src_idx))
          linkaxes(haxis_list, 'xy')
          
        end
        
        P_hat = mean(abs(S_hat).^2,2);
        
        % Collect outputs
        dout.tomo.theta(bin_idx,:,line_idx)      = doa;
        dout.tomo.cost(bin_idx,line_idx)       = Jval;
        dout.tomo.hessian(bin_idx,:,line_idx)  = diag(HESSIAN); % Not available with fminsearch
        dout.tomo.img(bin_idx,:,line_idx)    = P_hat;
        
        if 0
          %% DEBUG code for bin restriction
          hist_bins = cfg.bin_restriction.start_bin(rline)+(150:700).';
          hist_poly = polyfit(hist_bins,dout.tomo.theta(hist_bins,line_idx-1),2);
          plot(hist_bins,dout.tomo.theta(hist_bins,line_idx-1),'.');
          hist_val = polyval(hist_poly,hist_bins);
          hold on;
          plot(hist_bins, hist_val,'r');
          hold off;
          
          hist_bins = cfg.bin_restriction.start_bin(rline)+(150:1700).';
          hist3([ hist_bins, dout.tomo.theta(hist_bins,line_idx-1)],[round(length(hist_bins)/20) 30])
          set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
        end
        
        if 0
          %% DEBUG code to plot cost function
          Ngrid     = 128;
          dNgrid    = 2/Ngrid;
          uy        = dNgrid*[0 : floor((Ngrid-1)/2), -floor(Ngrid/2) : -1];
          uz        = sqrt(1 - uy.^2);
          grid_vec  = atan2(uy,uz);
          grid_vec  = fftshift(grid_vec);
          switch cfg.Nsrc
            case 1 % 1 source
              cf_vals = zeros(Ngrid,1);
              for eval_idx = 1:length(grid_vec);
                eval_theta = grid_vec(eval_idx);
                eval_theta = eval_theta(:);
                cf_vals(eval_idx) = wb_cost_function(eval_theta,doa_param);
              end
              figure(700);clf
              plot(grid_vec.*180/pi,cf_vals)
              grid on
            case 2  % 2 sources
              [grid1,grid2] = meshgrid(grid_vec);
              cf_vals = zeros(Ngrid,Ngrid);
              for row_index = 1:Ngrid
                for col_index = 1:Ngrid
                  eval_theta = [grid1(row_index,col_index) grid2(row_index,col_index)];
                  cf_vals(row_index,col_index) = wb_cost_function(eval_theta,doa_param);
                end
              end
              figure(701);clf
              grid_mask = grid1 <= grid2;
              cf_vals(grid_mask) = NaN;
              figure(101);mesh(grid1.*180/pi,grid2.*180/pi,-1*cf_vals)
              xlabel('\theta_1')
              ylabel('\theta_2')
            otherwise
              error('Not supported')
          end
        end
        
        
      case inf
        %% WBMLE Wideband Maximum Likelihood Estimator algorithm
        
        % Create data covariance matrix (DCM)
        Nsnap_td = length(cfg.bin_rng);
        Nsnap_other = length(line_rng)*Na*Nb;
        %         NB = cfg.NB;
        NB = doa_param.nb_filter_banks;
        
        % Make sure that there are enough range bins (otherwisw, DCM will
        % be all zeros
        if Nsnap_td < NB
          error('length(cfg.bin_rng) MUST be >= doa_param.nb_filter_banks (i.e. cfg.NB)')
        end
        
        DCM_fd = complex(zeros(Nc*NB,Nc));
        array_data = [];
        % Perform DFT for each set of data samples
        for idx = 1:NB:Nsnap_td-NB+1
          % Mohanad: Each loop process one group of data. Each group of
          % data has represents the number of snapshots per subband. So,
          % the total number of fast-time snapshots is
          % length(1:NB:Nsnap_td-NB+1) * NB. To compare against MLE, the
          % number of fast-time snapshots in MLE must be equal to the
          % number of snapshots per subband, which is the n umber of data
          % groups length(1:NB:Nsnap_td-NB+1) or ceil((Nsnap_td-NB+1)/NB).
          x_nb = fft(din{1}(bin + cfg.bin_rng(idx + (0:NB-1)), ...
            rline+line_rng,:,:,:));
          for nb = 1:NB
            x_nb_snaps = reshape(x_nb(nb,:,:,:,:),[Nsnap_other Nc]);
            DCM_fd((nb-1)*Nc+(1:Nc),:) = DCM_fd((nb-1)*Nc+(1:Nc),:) + x_nb_snaps.'*conj(x_nb_snaps);
          end
          
          array_data_tmp = din{1}(bin + cfg.bin_rng(idx + (0:NB-1)), ...
            rline+line_rng,:,:,:);
          %           array_data = cat(2,array_data,reshape(array_data_tmp,[NB*Nsnap_other Nc]));
          array_data = cat(1,array_data,reshape(array_data_tmp,[NB*Nsnap_other Nc])); % Mohanad
          
        end
        %         DCM_fd = 1/(Nsnap_td*Nsnap_other) * DCM_fd;
        DCM_fd = 1/(ceil((Nsnap_td-NB+1)/NB)*Nsnap_other) * DCM_fd; % Mohanad: divide by number of data groups, not Nsnap_td
        doa_param.DCM  = DCM_fd;
        
        % DOA Constraints
        for src_idx = 1:cfg.Nsrc
          % Determine src_limits for each constraint
          doa_res = doa_param.doa_constraints(src_idx);
          switch (doa_res.method)
            case 'surfleft'
              mid_doa(src_idx) = acos(cfg.surface(rline) / cfg.time(bin));
            case 'surfright'
              mid_doa(src_idx) = -acos(cfg.surface(rline) / cfg.time(bin));
            case 'layerleft'
              table_doa = [0:89.75]/180*pi;
              table_delay = cfg.surface(rline) ./ cos(table_doa) ...
                + (doa_res.layer.twtt(rline)-cfg.surface(rline)) ./ cos(asin(sin(table_doa)/sqrt(er_ice)));
              doa_res.layer.twtt(rline) = max(doa_res.layer.twtt(rline),cfg.surface(rline));
              if cfg.time(bin) <= doa_res.layer.twtt(rline)
                mid_doa(src_idx) = 0;
              else
                mid_doa(src_idx) = interp1(table_delay, table_doa, cfg.time(bin));
              end
            case 'layerright'
              table_doa = [0:89.75]/180*pi;
              table_delay = cfg.surface(rline) ./ cos(table_doa) ...
                + (doa_res.layer.twtt(rline)-cfg.surface(rline)) ./ cos(asin(sin(table_doa)/sqrt(er_ice)));
              doa_res.layer.twtt(rline) = max(doa_res.layer.twtt(rline),cfg.surface(rline));
              if cfg.time(bin) <= doa_res.layer.twtt(rline)
                mid_doa(src_idx) = 0;
              else
                mid_doa(src_idx) = -interp1(table_delay, table_doa, cfg.time(bin));
              end
            otherwise % 'fixed'
              mid_doa(src_idx) = 0;
          end
        end
        
        % Initialize search
        for src_idx = 1:cfg.Nsrc
          doa_param.src_limits{src_idx} = mid_doa(src_idx) ...
            + doa_param.doa_constraints(src_idx).init_src_limits/180*pi;
        end
        theta0 = wbmle_initialization(DCM_fd,doa_param);
        
        %% Minimization of wb_cost_function
        % Set source limits
        LB = zeros(cfg.Nsrc,1);
        UB = zeros(cfg.Nsrc,1);
        for src_idx = 1:cfg.Nsrc
          doa_param.src_limits{src_idx} = mid_doa(src_idx) ...
            + doa_param.doa_constraints(src_idx).src_limits/180*pi;
          LB(src_idx) = doa_param.src_limits{src_idx}(1);
          UB(src_idx) = doa_param.src_limits{src_idx}(2);
        end
        
        % Perform minimization
        [doa,Jval,exitflag,OUTPUT,~,~,HESSIAN] = ...
          fmincon(@(theta_hat) wbmle_cost_function(theta_hat,doa_param), theta0,[],[],[],[],LB,UB,[],doa_param.options);
        
        % Collect outputs
        dout.tomo.theta(bin_idx,:,line_idx)  = doa;
        dout.tomo.cost(bin_idx,line_idx)   = Jval;
        %dout.func_counts(bin_idx,line_idx)  = OUTPUT.funcCount;
        dout.tomo.hessian(bin_idx,:,line_idx)  = diag(HESSIAN);
        
        % Apply pseudoinverse and estimate power for each source
        P_hat = 0;
        k       = 4*pi*(doa_param.fc + doa_param.fs*[0:floor((NB-1)/2), -floor(NB/2):-1]/NB)/c;
        for band_idx = 1:NB
          A       = sqrt(1/length(doa_param.y_pc)) *exp(1i*k(band_idx)*(doa_param.y_pc*sin(doa(:)).' - doa_param.z_pc*cos(doa(:)).'));
          Weights = inv(A'*A)*A';
          S_hat   = Weights*array_data.';
          P_hat   = P_hat + mean(abs(S_hat).^2,2);
        end
        dout.tomo.img(bin_idx,:,line_idx)  = P_hat;
    end
  end
  
  if 0 %SEARCH
    scatterPlot = search_range(xaxis)*180/pi;
    figure(2);clf;
    %     plot(scatterPlot,'*')
    plot(scatterPlot,1:size(scatterPlot,1),'b*')
    %     plot(scatterPlot(650:850,:),650:850,'b*')
    %     for row = 1:size(scatterPlot,1)
    %       plot(scatterPlot(row,:),row,'*')
    %       hold on
    %     end
    set(gca,'ydir','reverse')
    %     axis([-90 90 0 size(scatterPlot,1)])
    %     axis([-90 90 950 1150])
  end
  
  %% Array: Store outputs
  
  % Reformat output for this range-line into a single slice of a 3D echogram
  if cfg.method < DOA_METHOD_THRESHOLD
    % Beamforming Methods
    Sarray = Sarray.';
    % Find bin/DOA with maximum value
    % The echogram fields .img and .theta are filled with this value.
    dout.img(:,line_idx) = max(Sarray(:,dout_val_sv_idxs),[],2);
    % Reformat output to store full 3-D image (if enabled)
    if cfg.tomo_en
      dout.tomo.img(:,:,line_idx) = Sarray;
    end
  else
    % DOA Methods
    dout.img(:,line_idx) = max(dout.tomo.img .* ...
      (dout.tomo.theta >= cfg.theta_rng(1) & dout.tomo.theta >= cfg.theta_rng(2)),[],2);
  end
  
  if 0 && (~mod(line_idx,size(dout.img,2)) || line_idx == 1)
    %% Array: DEBUG
    % change 0&& to 1&& on line above to run it
    if cfg.method < DOA_METHOD_THRESHOLD
      figure(1); clf;
      imagesc(10*log10(Sarray));
      
    else
      figure(1); clf;
      plot(dout.tomo.theta(:,:,line_idx)*180/pi,'.')
      hold on;
      surf = interp1(cfg.time,1:length(cfg.time), ...
        cfg.surface);
      surf = interp1(cfg.bins, 1:Nt_out, surf);
      plot(surf(rline)*ones(1,2),[-90 90],'k')
      ylim([-90 90])
      surf_curve = acosd(cfg.surface(rline) ./ cfg.time(cfg.bins));
      bad_mask = cfg.time(cfg.bins) < cfg.surface(rline);
      surf_curve(bad_mask) = NaN;
      plot(surf_curve,'r')
      hold on
      plot(-1.*surf_curve,'r')
      
      if isfield(cfg.doa_constraints,'layer')
        table_doa = [0:89.75]/180*pi;
        table_delay = cfg.surface(rline) ./ cos(table_doa) ...
          + (cfg.doa_constraints(2).layer.twtt(rline)-cfg.surface(rline)) ./ cos(asin(sin(table_doa)/sqrt(er_ice)));
        plot(interp1(cfg.time(cfg.bins), 1:length(cfg.time(cfg.bins)), ...
          table_delay), table_doa*180/pi, 'k');
        plot(interp1(cfg.time(cfg.bins), 1:length(cfg.time(cfg.bins)), ...
          table_delay), table_doa*180/pi+doa_param.doa_constraints(1).src_limits(1), 'k');
        plot(interp1(cfg.time(cfg.bins), 1:length(cfg.time(cfg.bins)), ...
          table_delay), table_doa*180/pi+doa_param.doa_constraints(1).src_limits(2), 'k');
      end
    end
    
    keyboard
  end
  Sarray = reshape(Sarray,Nsv,Nt_out);
  
end
