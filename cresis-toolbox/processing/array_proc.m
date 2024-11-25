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
%   .img: Nt_out by Nx_out output image. The value of the largest source in theta_rng (mode 1) OR
%         the source closest to the center of the theta_rng (mode 2) in the Nsrc dimension (i.e. tomo.img first entry)
%   .theta: direction of arrival (deg) to the source returned in .img.
%  TOMOGRAPHY (.tomo_en) ENABLED
%   .tomo: tomography structure (only present if param.tomo_en is true)
%    ALL methods:
%     .surf_theta
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
%    SNAPSHOT method
%     .snapshots: 
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

% .Nsrc:
%   Number of signals/sources/targets per SAR image pixel, defaults to 1,
%   only used in modes that are based on the x = As + n signal model (e.g.
%   MUSIC_METHOD, MLE_METHOD, etc.). When model order estimation is
%   enabled, this represents the maximum number of targets.
if ~isfield(param.array,'Nsrc') || isempty(param.array.Nsrc)
  param.array.Nsrc = 1;
end

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
%   Number of range-bins to decimate by on output, default is 1.
%   This is without subbanding.
if ~isfield(param.array,'dbin') || isempty(param.array.dbin)
  param.array.dbin = 1;
end

% .dline:
%   Number of range-lines to decimate by on output, default is
%   round((length(param.array.line_rng)-1)/2)
if ~isfield(param.array,'dline') || isempty(param.array.dline)
  param.array.dline = round(length(param.array.line_rng)/2);
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

% doa_theta_guard is needed only in the first range-bin if S-MAP is used.
if param.array.doa_seq && param.array.doa_theta_guard > 0.5
  param.array.doa_theta_guard = 1;
end

% .method
%   String or integer array containing each method to run. Note that only
%   one beam forming and one DOA method can be output so enabling multiple
%   versions of these methods will only enable one method. See
%   array_proc_methods.m for scalar integer equivalent.
%
%   Multiple strings can be given (e.g. 'standard mle')
%   Multiple integers can be given (e.g. [STANDARD_METHOD MLE_METHOD]
%
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
  param.array.method = STANDARD_METHOD;
end
if ischar(param.array.method)
  % Convert array method string to integer
  method_integer = [];
  if regexpi(param.array.method,'standard|period')
    method_integer(end+1) = STANDARD_METHOD;
  end
  if regexpi(param.array.method,'mvdr')
    method_integer(end+1) = MVDR_METHOD;
  end
  if regexpi(param.array.method,'mvdr_robust')
    method_integer(end+1) = MVDR_ROBUST_METHOD;
  end
  if regexpi(param.array.method,'music')
    method_integer(end+1) = MUSIC_METHOD;
  end
  if regexpi(param.array.method,'eig')
    method_integer(end+1) = EIG_METHOD;
  end
  if regexpi(param.array.method,'risr')
    method_integer(end+1) = RISR_METHOD;
  end
  if regexpi(param.array.method,'geonull')
    method_integer(end+1) = GEONULL_METHOD;
  end
  if regexpi(param.array.method,'gslc')
    method_integer(end+1) = GSLC_METHOD;
  end
  if regexpi(param.array.method,'music_doa')
    method_integer(end+1) = MUSIC_DOA_METHOD;
  end
  if regexpi(param.array.method,'mle')
    method_integer(end+1) = MLE_METHOD;
  end
  if regexpi(param.array.method,'dcm')
    method_integer(end+1) = DCM_METHOD;
    if ~isfield(param.array,'Nsrc') || isempty(param.array.Nsrc)
      param.array.Nsrc = 1;
    end
  end
  if regexpi(param.array.method,'pf')
    method_integer(end+1) = PF_METHOD;
  end
  if regexpi(param.array.method,'snapshot')
    method_integer(end+1) = SNAPSHOT_METHOD;
    param.array.bin_rng   = 0;
    param.array.line_rng  = 0;
    param.array.Nsrc      = 1;
    param.array.array_proc.lut = [];
  end
  param.array.method = method_integer;
end
param.array.method = intersect(param.array.method, ...
  [STANDARD_METHOD MVDR_METHOD MVDR_ROBUST_METHOD MUSIC_METHOD EIG_METHOD RISR_METHOD GEONULL_METHOD GSLC_METHOD MUSIC_DOA_METHOD MLE_METHOD DCM_METHOD PF_METHOD SNAPSHOT_METHOD], ...
  'stable');
if isempty(param.array.method)
  error('No valid method selected in param.array.method');
end

% .last_fprintf_time_delay
%   The maximum amount of time in seconds since the last fprintf statement
%   was made. This is used to print out the progress. The default is 60
%   seconds.
if ~isfield(param.array,'last_fprintf_time_delay') || isempty(param.array.last_fprintf_time_delay)
  param.array.last_fprintf_time_delay = 60;
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

% .sv_dielectric
%   Scalar numeric containing relative dielectric (default is 1 for
%   vacuum).
if ~isfield(param.array,'sv_dielectric') || isempty(param.array.sv_dielectric)
  param.array.sv_dielectric = 1;
end

% .sv_fh
%   Steering vector function handle. Defaults to array_proc_sv.m and should
%   generally not be changed.
if ~isfield(param.array,'sv_fh') || isempty(param.array.sv_fh)
  param.array.sv_fh = @array_proc_sv;
end
%   Steering vectors align with these spatial frequencies:
%     ifftshift(-floor(Nsv/2):floor((Nsv-1)/2))
if isfield(param.array,'theta') && ~isempty(param.array.theta)
  param.array.Nsv = length(param.array.theta);
  theta = param.array.theta/180*pi; % Theta input in degrees
else
  if ~isfield(param.array,'Nsv') || isempty(param.array.Nsv)
    param.array.Nsv = 1;
  end
  theta = fftshift(param.array.sv_fh(1,[],[],param.array.Nsv, [],[]));
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
  param.array.window = @boxcar;
end

% .ignored_img_idx:
%  Scalar integer that tells array_proc which image to not process. The
%  default situation is to process all the images.
if ~isfield(param.array,'ignored_img_idx')
  param.array.ignored_img_idx = [];
end

% .ref_doa: Splits the furface into left and right portions
if param.array.doa_seq && isfield(param.array,'ref_doa') && ~isempty(param.array.ref_doa)
  ref_doa = param.array.ref_doa * pi/180;
else
  ref_doa = 0;
end

if ~isfield(param.array,'debug_plots') || isempty(param.array.debug_plots)
  param.array.debug_plots = 0;
end

if ~isfield(param.array,'layerData_folder') || isempty(param.array.layerData_folder)
  param.array.layerData_folder = '';
end

if ~isfield(param.array,'layer_name') || isempty(param.array.layer_name)
  param.array.layer_name = '';
end

if ~isfield(param.array,'sv_model') || isempty(param.array.sv_model)
  param.array.sv_model = 'ideal'; % 'ideal' or 'lookup_table'
end

if ~isfield(param.array,'process_training_override_flag') || isempty(param.array.process_training_override_flag)
  param.array.process_training_override_flag = false;
end
  

if strcmpi(param.array.sv_model,'lookup_table')
  if ~isfield(param.array,'lut_dayseg')|| isempty(param.array.lut_dayseg);
    param.array.lut_dayseg = param.day_seg;
    param.array.lut_type = 'process';
  end
end

if strcmpi(param.array.sv_model,'lookup_table')
  if ~isfield(param.array,'lut_type') || isempty(param.array.lut_type)
    if ~isempty(param.array.lut_dayseg)
      if strcmpi(param.array.lut_dayseg,param.day_seg)
        param.array.lut_type = 'process';
      elseif ~strcmpi(param.array.lut_dayseg,param.day_seg)
        param.array.lut_type = 'training';
      end
    end
  end
end

if strcmpi(param.array.sv_model,'lookup_table')
  if strcmpi(param.array.lut_type,'training') && strcmpi(param.array.lut_dayseg, param.day_seg) ...
      && ~param.array.process_training_override_flag
    param.array.sv_model = 'ideal';
    warning('Cannot use training data on processing from same day_seg. Converting manifold model to ideal');
  end
end

if strcmpi(param.array.sv_model,'lookup_table')
  if ~isfield(param.array,'lut_method') || isempty(param.array.lut_method)
    param.array.lut_method = 'evd';
  end
  if~isfield(param.array,'lut_path') || isempty(param.array.lut_path)
    param.array.lut_path = 'array_manifold';
  end
  if ~isfield(param.array,'lut_fn') || isempty(param.array.lut_fn)
    param.array.lut_fn = [];
  end
  
end

% 
% if ~strcmpi(param.array.sv_model,'ideal') && isempty(param.array.lut_path) || ~isfield(param.array,'lut_path')
%   param.array.lut_path = 'array_manifold';
% end

% if ~strcmpi(param.array.sv_model,'ideal') && isempty(param.array.sv_lut_path) 
%   param.array.sv_lut_path = [];
% end

% if ~isfield(param.array,'lut_path')
%   param.array.sv_lut_path = [];
% end
% 
% if strcmpi(param.array.sv_model,'lookup_table') 
%   if~isfield(param.array,'lut_path') || isempty(param.array.lut_path)
%   param.array.lut_path = 'array_manifold';  
%   end
% end


% User can specify lookup table full filename directly
if strcmpi(param.array.sv_model,'lookup_table') && ~isempty(param.array.lut_fn)
  if ~exist(param.array.lut_fn)==2
    warning('No valid lookup table found. Converting to ideal manifold');
    param.array.sv_model = 'ideal';
    param.array.lut_dayseg = [];
    param.array.lut_type = [];
    param.array.lut_path = [];
  end
end
  
% Check for the existence of the lut
if strcmpi(param.array.sv_model,'lookup_table') && isempty(param.array.lut_fn)
  if strcmpi(param.array.lut_type,'process')
    lut_path = ct_fileparts(ct_filename_out(param, param.array.lut_path,''));
    lut_fn = fullfile(lut_path,sprintf('lut_process_%s.mat',param.day_seg));
  elseif strcmpi(param.array.lut_type,'training')
    lut_path = fullfile(ct_fileparts(ct_filename_out(param, param.array.lut_path,'')),sprintf('%s',param.array.lut_dayseg));
    lut_fn = fullfile(lut_path,sprintf('lut_training_%s.mat',param.array.lut_dayseg));
  end
  
  if ~isdir(lut_path)
    warning('Lookup table path does not exist. Converting to ideal manifold');
    param.array.sv_model = 'ideal';
    param.array.lut_dayseg = [];
    param.array.lut_type = [];
    param.array.lut_path = [];
  elseif ~exist(lut_fn)==2
    warning('No valid lookup table found. Converting to ideal manifold');
    param.array.sv_model = 'ideal';
    param.array.lut_dayseg = [];
    param.array.lut_type = [];
    param.array.lut_path = [];
  else
    param.array.lut_fn = lut_fn;
  end
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

if ~isfield(param,'array_proc') || isempty(param.array_proc)
  param.array_proc = [];
end

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
% bin_dt_align_offset: number of bins to offset the output in order to
%   ensure that output bins are multiple of dt after decimation
bin_dt_align_offset = round(mod(param.array_proc.bin0+(param.array.Nsubband-1)/2-min(param.array.bin_rng)*param.array.Nsubband,param.array.dbin));
param.array_proc.bins = (bin_dt_align_offset+1+(param.array.Nsubband-1)/2-min(param.array.bin_rng)*param.array.Nsubband : param.array.dbin ...
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
for idx = 1:length(cfg.method)
  m = array_proc_method_str(cfg.method(idx));
  tout.(m).img ...
    = nan(Nt_out, Nx_out,'single');
  tout.(m).theta ...
    = nan(Nt_out, Nx_out,'single');
  if cfg.method(idx) >= DOA_METHOD_THRESHOLD && cfg.method(idx) < SNAPSHOT_METHOD_THRESHOLD
    % DOA Methods
    tout.(m).tomo.theta = ...
      nan(Nt_out,cfg.Nsrc,Nx_out,'single');
    tout.(m).tomo.cost = ...
      nan(Nt_out, Nx_out,'single');
    tout.(m).tomo.hessian = ...
      nan(Nt_out,cfg.Nsrc,Nx_out,'single');
    tout.(m).tomo.img = ...
      nan(Nt_out,cfg.Nsrc,Nx_out,'single');
  elseif cfg.method(idx) >= SNAPSHOT_METHOD_THRESHOLD
    % Snapshot method stores raw snapshots
    tout.(m).tomo.img = ...
      nan(Nt_out,Nc,Nx_out,'single');
    tout.(m).tomo.power = nan(Nt_out,0,Nx_out,'single');
  else
    % Beam Forming Method
    Sarray.(m) = zeros(cfg.Nsv,Nt_out);
  end
  if cfg.tomo_en && cfg.method(idx) < DOA_METHOD_THRESHOLD
    % Tomography with Beam Forming Method
    tout.(m).tomo.img = ...
      nan(Nt_out,cfg.Nsv,Nx_out,'single');
    tout.(m).tomo.theta = theta(:); % Ensure a column vector on output
  end
  if cfg.tomo_en 
    tout.(m).tomo.surf_theta = ...
      nan(Nt_out,0,Nx_out,'single');   
    tout.(m).tomo.surf_ice_mask = ...
      nan(Nt_out,0,Nx_out,'single');    
  end
end

% MOE output: simulation (for comparing different MOE methods)
if cfg.moe_simulator_en
  dout.moe.NT.doa = nan(Nt_out,cfg.Nsrc,Nx);
  dout.moe.AIC.doa = nan(Nt_out,cfg.Nsrc,Nx);
  dout.moe.HQ.doa = nan(Nt_out,cfg.Nsrc,Nx);
  dout.moe.MDL.doa = nan(Nt_out,cfg.Nsrc,Nx);
  dout.moe.AICc.doa = nan(Nt_out,cfg.Nsrc,Nx);
  dout.moe.KICvc.doa = nan(Nt_out,cfg.Nsrc,Nx);
  dout.moe.WIC.doa = nan(Nt_out,cfg.Nsrc,Nx);
  
  dout.moe.NT.Nest = nan(Nt_out,Nx);
  dout.moe.AIC.Nest = nan(Nt_out,Nx);
  dout.moe.HQ.Nest = nan(Nt_out,Nx);
  dout.moe.MDL.Nest = nan(Nt_out,Nx);
  dout.moe.AICc.Nest = nan(Nt_out,Nx);
  dout.moe.KICvc.Nest = nan(Nt_out,Nx);
  dout.moe.WIC.Nest = nan(Nt_out,Nx);
end

% MOE outpus: real data
if cfg.moe_en && isfield(cfg,'testing') && cfg.testing
  for model_order_method = cfg.moe_methods
    switch model_order_method
      case 0
        dout.moe.NT.Nest    = nan(Nt_out,Nx);
        dout.moe.NT.doa     = nan(Nt_out,cfg.Nsrc,Nx);
      case 1
        dout.moe.AIC.Nest   = nan(Nt_out,Nx);
        dout.moe.AIC.doa    = nan(Nt_out,cfg.Nsrc,Nx);
      case 2
        dout.moe.HQ.Nest    = nan(Nt_out,Nx);
        dout.moe.HQ.doa     = nan(Nt_out,cfg.Nsrc,Nx);
      case 3
        dout.moe.MDL.Nest   = nan(Nt_out,Nx);
        dout.moe.MDL.doa    = nan(Nt_out,cfg.Nsrc,Nx);
      case 4
        dout.moe.AICc.Nest  = nan(Nt_out,Nx);
        dout.moe.AICc.doa   = nan(Nt_out,cfg.Nsrc,Nx);
      case 5
        dout.moe.KICvc.Nest = nan(Nt_out,Nx);
        dout.moe.KICvc.doa  = nan(Nt_out,cfg.Nsrc,Nx);
      case 6
        dout.moe.WIC.Nest   = nan(Nt_out,Nx);
        dout.moe.WIC.doa    = nan(Nt_out,cfg.Nsrc,Nx);
      otherwise
        error('MOE method is not supported')
    end
  end
end

% MOE outputs: machine learning
if cfg.moe_en && (isfield(cfg,'moe_ml') && cfg.moe_ml)
  dout.moe.ML.Nest = nan(Nt_out,Nx);
  dout.moe.ML.doa  = nan(Nt_out,cfg.Nsrc,Nx);
  dout.moe.ML.prob = nan(Nt_out,Nx);
end

if cfg.doa_seq && cfg.debug_plots
  % These are for debugging only
  bounds_l = NaN(Nt_out,2);
  bounds_r = NaN(Nt_out,2);
  mean_l   = NaN(Nt_out,1);
  mean_r   = NaN(Nt_out,1);
end
%% Channel Equalization
% =====================================================================
for ml_idx = 1:length(din)
  for chan = 1:Nc
    % All other methods
    din{ml_idx}(:,:,:,:,chan) = din{ml_idx}(:,:,:,:,chan) / cfg.chan_equal{ml_idx}(chan);
  end
end
% Also prepare window for STANDARD_METHOD.
Hwindow = cfg.window(Nc);
Hwindow = Hwindow(:) / sum(Hwindow);

%% Array Processing Setup
% =========================================================================

physical_constants; % c: speed of light

% Change er_ice to 1 for ice top
if ~isempty(cfg.layer_name) && (strcmpi(cfg.layer_name,'top') || strcmpi(cfg.layer_name,'surface'))
  er_ice = 1;
end

% Null Steering Setup - Check to avoid mainlobe nulling 
if any(cfg.method == GEONULL_METHOD) || any(cfg.method == GSLC_METHOD) || any(cfg.method == SNAPSHOT_METHOD)
  % NOTE:  ASSUMPTION IS THAT EITHER USER PASSES IN DOA_THETA_GUARD OR
  % DOA_THETA_GAURD IS EMPTY
  % For geonull method and the sidelobe canceller, we define theta_guard to 
  % prevent mainlobe nulling.
  % 
  % Use a back of the envelope approximation of the mainLOBE width assuming
  % uniform weighting and the ELECTRICAL length of the aperture Nc*dy 
  % (NOT [Nc-1]*dy!)
  % Alternatively, user can plot the cross-track pattern and measure.
  
  % y position of the bistatic equivalent phase centers of an arbitrary
  % measurement
  y_positions   = cellfun(@(x) x.pos(2,1), cfg.fcs{1});
  % Cross-track sampling of measurements (note this is 2 way)
  dy            = abs(mean(diff(cellfun(@(x) x.pos(2,1), cfg.fcs{1}))));
  % Equivalent aperture length
  Lapt          = Nc*dy;  
  % Wavelength (two way)
  lambda        = 0.5*(c / cfg.wfs.fc);  
  % Width of the mainLOBE in degrees
  delta_Theta   = (0.866 * lambda/Lapt)*(180/pi);
  
  if ~isfield(cfg,'doa_theta_guard') || isempty(cfg.doa_theta_guard)
    cfg.doa_theta_guard = 1.5;
  elseif cfg.doa_theta_guard < delta_Theta
    cfg.doa_theta_guard = delta_Theta;
  end
  
end

% DOA Setup
% -------------------------------------------------------------------------
if any(cfg.method >= DOA_METHOD_THRESHOLD)
  doa_param.fc              = cfg.wfs.fc;
  doa_param.Nsrc            = cfg.Nsrc;
  doa_param.options         = optimoptions(@fmincon,'Display','off','Algorithm','sqp','TolX',1e-3);
  doa_param.doa_constraints = cfg.doa_constraints;
  doa_param.theta_guard     = cfg.doa_theta_guard/180*pi;
  doa_param.search_type     = cfg.doa_init;
  doa_param.theta           = theta; % This changes inside S-MAP loop
  theta_copy                = theta;
  doa_param.seq             = cfg.doa_seq;
  doa_param.lut             = cfg.lut;
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
if any(cfg.method < DOA_METHOD_THRESHOLD)
  dout_val_sv_idxs = find(theta >= cfg.theta_rng(1) & theta <= cfg.theta_rng(2));
  if isempty(dout_val_sv_idxs)
    [tmp dout_val_sv_idxs] = min(abs(theta-mean(cfg.theta_rng)));
  end
end

% sv_fh_arg1
% -------------------------------------------------------------------------
% First argument to sv_fh
% sv_fh_arg1 = {'theta'};
% sv_fh_arg1{2} = theta;
sv_fh_arg1.theta = theta;
sv_arg_opt.theta = theta;


% Set the output of any ignored image to NaN
% -------------------------------------------------------------------------
if ~isempty(cfg.ignored_img_idx) && (cfg.ignored_img_idx == cfg.imgs{1}(1,1))
  % Copy temporary outputs for first method to dout
  dout = tout.(array_proc_method_str(cfg.method(1)));
  return;
end

%% Load layerData: used to define the first range-bin and to skip bad-data range-line (those that have NAN/Inf in their layerData entry)
if ~isempty(cfg.layerData_folder) && ~isempty(cfg.layer_name)
  layerData_fn = fullfile(ct_filename_out(param, cfg.layerData_folder), ...
    sprintf('Data_%s_%03d', param.day_seg, param.load.frm));
  layer_name = cfg.layer_name;
  if strcmpi(layer_name,'surface')
    layer_name = 'top';
  end
  if strcmpi(layer_name,'top') || strcmpi(layer_name,'bottom')
    if strcmpi(layer_name,'top')
      layer_idx = 1;
    elseif strcmpi(layer_name,'bottom')
      layer_idx = 2;
    end
    
    % Load twtt to the ice-surface/bottom at the nadir DOA bin for each
    % range-line
    load(layerData_fn,'layerData');
    layerData = layerData{layer_idx}.value{2}.data;
  else
    warning('Invalid layer name')
  end
end

% Time: twtt that containts all possible time samples within the
% range gate for the current data chunk (each chunk of data is processed
% separately, then all chunks are combined using array_combine_task).
% This is fixed for all range-lines.
Time = cfg.wfs.time;
%   dt = Time(2)-Time(1); % Range-bin time

% Layer range-bin at nair DOA bin.
if exist('layerData','var') && ~isempty('layerData')
  layerData_rline = round(interp1(Time,1:length(Time),layerData));
end

%% Array Processing
% =========================================================================
% Loop through each output range line and then through each output range
% bin for that range line.
last_fprintf_time = -inf;
last_fprintf_time_bin = -inf;

% If the steering vector model is specified as a lookup table, then load
% if strcmpi(cfg.sv_model,'lookup_table')
%   
%   % Future paths after updated estimate_sv_lut (leaves off dayseg folder)
% %   lut_folder = ct_filename_out(param,cfg.sv_lut_path,[],1);
% %   lut_fn = fullfile(lut_folder,'sv_lut.mat');
% 
%   lut_folder = ct_filename_out(param,cfg.sv_lut_path);
%   lut_fn = fullfile(lut_folder, sprintf('sv_lut_%s.mat',param.day_seg));
%   load(lut_fn,'sv_rel_mag','sv_rel_phase','doa_bins');
%   cfg.lut.bins = doa_bins.'/180*pi;
%   cfg.lut.sv = ((sv_rel_mag) .* exp(1i*sv_rel_phase)).';
%   cfg.lut.sv_real = real(cfg.lut.sv);
%   cfg.lut.sv_imag = imag(cfg.lut.sv);
% else
%   cfg.lut = [];
% end

% if any(cfg.method == GEONULL_METHOD)
%   % HACK
%   LUT = load('/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/sv_LUT.mat');
%   LUT.bins = LUT.bins.'/180*pi;
%   LUT.sv = (sqrt(LUT.power_SVmean) .* exp(1i*LUT.angle_SVmean)).';
%   LUT.sv_real = real(LUT.sv);
%   LUT.sv_imag = imag(LUT.sv);
% end

for line_idx = 1:1:Nx_out
  %% Array: Setup
  rline = cfg.lines(line_idx);
  if now > last_fprintf_time+cfg.last_fprintf_time_delay/86400
    fprintf('    Record %.0f (%.0f of %.0f) bin start (%s)\n', rline, line_idx, ...
      Nx_out, datestr(now));
    last_fprintf_time = now;
    last_fprintf_time_bin = now;
  end
  
  % Bring the range-bin index stored in layerData vector (at the nadir DOA bin)
  nn = 15; % Number of range-bins before the initial that S-MAP starts from
  if exist('layerData','var') && ~isempty('layerData')
    % Skip this range-line if there is NaN/Inf in its layerData entry
    if ~isfinite(layerData_rline(line_idx))
      warning('No data ... Skipping range-line %0.f',rline)
      continue;
    else
      cfg.bin_restriction.start_bin(rline) = layerData_rline(line_idx) + max(cfg.bin_rng)- nn;
    end
  end
  
  % theta may change inside S-MAP for each range-bin. So, reset it here
  if any(cfg.method >= DOA_METHOD_THRESHOLD)
    doa_param.theta = theta_copy;
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
    
    sv_arg_opt = [];
    sv_arg_opt.theta = theta;
    
    % Arguments for array_proc_sv
    sv_arg = [];
    sv_arg = {cfg.wfs.fc.*sqrt(cfg.sv_dielectric), y_pos{ml_idx}, z_pos{ml_idx},sv_arg_opt, cfg.lut, cfg.fcs{1}{1}.roll(rline)};
    
    % Determine Steering Vector
    [~,sv{ml_idx}] = cfg.sv_fh(sv_arg{:});    
   
%     [~,sv{ml_idx}] = cfg.sv_fh(sv_fh_arg1,cfg.wfs.fc*sqrt(cfg.sv_dielectric),y_pos{ml_idx},z_pos{ml_idx});
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
    sv_arg_opt = [];
    sv_arg_opt = cfg.Nsv;
    sv_arg = [];
    sv_arg = {cfg.wfs.fc.*sqrt(cfg.sv_dielectric), y_pos{ml_idx}, z_pos{ml_idx}, sv_arg_opt, cfg.lut, cfg.fcs{1}{1}.roll(rline)};
    [theta_plot,sv{ml_idx}] = cfg.sv_fh(sv_arg{:});
    
%     [theta_plot,sv{ml_idx}] = cfg.sv_fh(cfg.Nsv,cfg.fc*sqrt(cfg.sv_dielectric),y_pos{ml_idx},z_pos{ml_idx});
    
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
  
  %% Array: DOA range line varying parameters
  if any(cfg.method >= DOA_METHOD_THRESHOLD)
    doa_param.y_pc  = y_pos{1};
    doa_param.z_pc  = z_pos{1};
    doa_param.SV    = fftshift(sv{1},2);
    doa_param.lut_roll = cfg.fcs{1}{1}.roll(rline);
  end
  
  %  .range: Range vector. It may have negative values. So, better to ignore
  %   those negative ranges.
  if cfg.doa_seq
    cfg.range = c*Time/2;
    negative_range_idxs = find(cfg.range<0);
    if ~isempty(negative_range_idxs) && cfg.bin_restriction.start_bin(rline)<max(negative_range_idxs)
      cfg.bin_restriction.start_bin(rline) = max(negative_range_idxs)+1;
      cfg.bin_restriction.start_bin(rline) = cfg.bin_restriction.start_bin(rline);
    end
  end
  
  clear first_rbin_idx
  max_Nsrc = cfg.Nsrc; % For S-MAP
  bin_idxs = find(cfg.bins >= cfg.bin_restriction.start_bin(rline) & cfg.bins <= cfg.bin_restriction.stop_bin(rline));
  early_stop = false;
  
  if any(cfg.method < DOA_METHOD_THRESHOLD)
    % Beam Forming Method
    m = array_proc_method_str(cfg.method(cfg.method < DOA_METHOD_THRESHOLD));
    Sarray.(m) = zeros(cfg.Nsv,Nt_out);
  end
  clear prev_active_rbin first_rbin_idx first_active_doa prev_rbin sources_number% For S-MAP tracker only
  % This is used with S-MAP, where the number of snapshots changes when the
  % change of DOA over range crosses some threshold.
  cfg.bin_rng = cfg.bin_rng;
  std_doa_accum = []; % For S-MAP to track stdev using Kalman filter
  std_doa_accum_new = [];
  
  
  % Interpolate twtt-dependant DOAs from the surfData onto the radar twtt
  % -----------------------------------------------------------------------
  if isfield(cfg,'surf_layer') && strcmpi(cfg.surf_layer.source, 'surf_sar') && strcmpi(cfg.surf_layer.name,'top twtt')
    
    % TWTT of radar
    radar_twtt = cfg.wfs.time;
    
    % Method 1
    % ---------------------------------------------------------------------
    %
    % We use the surfData to determine the interpolated values of the DOAs
    % associated with the surface clutter at the radar's twtt query points.
    %  When we plot surfData as a function of twtt, we see that it does not
    %  pass the vertical line test.  Thus we interpolate positive and
    %  negative arrival angles separately
    
    if 0
      %       % Faster but doesn't handle layover and case where more than 2
      %       corange targets.  Not fully supported.  If you need a speedup, this
      %       should be used over
      % TWTT of surfData evaluated over the cfg.surface_theta vector for rline
      surf_twtt = cfg.surface(:,rline);
      mask1 = cfg.surface_theta >= 0;
      mask2 = cfg.surface_theta < 0;
      
      theta1 = cfg.surface_theta(mask1);
      theta2 = cfg.surface_theta(mask2);
      
      surf_twtt_theta1 = surf_twtt(mask1);
      surf_twtt_theta2 = surf_twtt(mask2);
      
      % Interpolate the DOAs onto the radar twtt
      theta1_i = interp_finite(interp1(surf_twtt_theta1, theta1, radar_twtt));
      theta2_i = interp_finite(interp1(surf_twtt_theta2, theta2,radar_twtt));
      
%       theta1_i = (interp1(surf_twtt_theta1, theta1, radar_twtt));
%       theta2_i = (interp1(surf_twtt_theta2, theta2,radar_twtt));

      if cfg.debug_plots
        figure(1834);
        clf
        plot(surf_twtt*1e6,cfg.surface_theta,'x')
        grid on
        grid minor
        hold on
        plot(surf_twtt_theta1.*1e6,theta1,'csq')
        plot(surf_twtt_theta2.*1e6,theta2,'m*')
        plot(radar_twtt.*1e6,theta1_i,'rd','LineWidth',2)
        plot(radar_twtt.*1e6,theta2_i,'gs','LineWidth',2)
        xlabel('TWTT to surface (\mus)')
        ylabel('DOA (\circ)')
        text(4,0,'Function Does Not Pass the Vertical Line Test!','Color','red')
        set(gca,'FontName','Arial','FontSize',12)
        [day, rem] = strtok(param.day_seg, '_');
        seg = rem(2:end);
        tgps = datetime(1970,01,01,00,00,00,00) + seconds(cfg.fcs{1}{1}.gps_time(line_idx));
        titlestr = sprintf('%s %s CSARP surfData, %s',day,seg,datestr(tgps));
        title(titlestr)
        legend('surfData','\theta_1^D^E^M','\theta_2^D^E^M','\theta_1^I','\theta_2^I')
      end
    else
      % Method 2
      % -------------------------------------------------------------------
      % Loop over radar twtt and use intersections function to find the
      % intersections between two curves.  The first curve is the parabolic
      % surface propagation versus DOA.  The second curve is
      % a line that intersects the y axis at the radar twtt for that bin.
      x1 = cfg.surface_theta(:);
      y1 = cfg.surface(:,rline).';
      
      if cfg.debug_plots
        figure(2001);clf
        plot(x1,y1,'co','MarkerSize',3,'MarkerFaceColor','k','LineWidth',2);
        hold on
        grid on
        grid minor
        xlabel('DOA','FontName','Arial','FontSize',12,'FontWeight','Demi')
        ylabel('TWTT (s)','FontName','Arial','FontSize',12,'FontWeight','Demi')
      end

      % Loop over fast time bins and find intersections
      % If the curves don't intersect, intersections returns NaNs
      surf_theta = nan(Nt,0);
      surf_ice_mask = nan(Nt,0);
      for rbin_idx = 1:length(radar_twtt)
        x2 = x1;
        y2 = radar_twtt(rbin_idx).*ones(size(y1));
        [bin_theta,y0,~,~] = intersections(x1,y1,x2,y2);
              
        if length(bin_theta) > size(surf_theta,2)
          surf_theta = [surf_theta nan(size(surf_theta,1),length(bin_theta)-size(surf_theta,2))];
        end
        surf_theta(rbin_idx,1:length(bin_theta)) = bin_theta;
        
        % Interpolate icemask given doas interpolated on radar twtt
        bin_ice_mask   = interp1(cfg.surface_theta(:),cfg.ice_mask(:,rline),bin_theta,'nearest');
        
        if length(bin_ice_mask) > size(surf_ice_mask,2)
          surf_ice_mask = [surf_ice_mask nan(size(surf_ice_mask,1),length(bin_ice_mask)-size(surf_ice_mask,2))];
        end
        surf_ice_mask(rbin_idx,1:length(bin_ice_mask)) = bin_ice_mask;
        
        if cfg.debug_plots
          plot(bin_theta,y0,'mo','MarkerSize',4,'MarkerFaceColor','g','LineWidth',2)
        end
      end     
    end
    
  end
  
  for bin_idx = bin_idxs(:).'
    %% Array: Array Process Each Bin
    bin = cfg.bins(bin_idx);
    if now > last_fprintf_time_bin+2*cfg.last_fprintf_time_delay/86400
      fprintf('      Record %.0f (%.0f of %.0f) bin %d of %d (%s)\n', rline, line_idx, ...
        Nx_out, bin_idx, length(bin_idxs), datestr(now));
      last_fprintf_time_bin = now;
    end
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
    
    if any(cfg.method == STANDARD_METHOD)
      %% Array: Standard/Periodogram
      dataSample = din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
      dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb, Nc]);
      Sarray.standard(:,bin_idx) = mean(abs(sv{1}(:,:)'*bsxfun(@times,Hwindow,dataSample.')).^2,2);
      for ml_idx = 2:length(din)
        dataSample = din{ml_idx}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
        dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
        Sarray.standard(:,bin_idx) = Sarray.standard(:,bin_idx) ...
          + mean(abs(sv{ml_idx}(:,:)'*bsxfun(@times,Hwindow,dataSample.')).^2,2);
      end
      Sarray.standard(:,bin_idx) = Sarray.standard(:,bin_idx) / length(din);
    end
    
    if any(cfg.method == MVDR_METHOD)
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
          Sarray.mvdr(freqIdx,bin_idx) = single(real(sv{1}(:,freqIdx).' * Rxx_inv * conj(sv{1}(:,freqIdx))));
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
            Sarray.mvdr(freqIdx,bin_idx) = Sarray.mvdr(freqIdx,bin_idx) ...
              + single(real(sv{ml_idx}(:,freqIdx).' * Rxx_inv * conj(sv{ml_idx}(:,freqIdx))));
          end
        end
        Sarray.mvdr(:,bin_idx) = 1 ./ (Sarray.mvdr(:,bin_idx) / length(din));
        
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
          
          Sarray.mvdr(freqIdx,bin_idx) = mean(abs(w * dataSample).^2);
          Sarray.mvdr(freqIdx,bin_idx) = Sarray.mvdr(freqIdx,bin_idx) / abs(w * sv{1}(:,freqIdx)).^2;
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
            
            Sarray.mvdr(freqIdx,bin_idx) = Sarray.mvdr(freqIdx,bin_idx) ...
              + mean(abs(w * dataSample).^2) / abs(w * sv{ml_idx}(:,freqIdx)).^2;
          end
          Sarray.mvdr(freqIdx,bin_idx) = Sarray.mvdr(freqIdx,bin_idx) / size(sv{1},2);
        end
      end
      
    elseif any(cfg.method == MUSIC_METHOD)
      %% Array: MUSIC
      %  The music algorithm fIdxs the eigenvectors of the correlation
      %  matrix. The inverse of the incoherent average of the magnitude
      %  squared spectrums of the smallest eigenvectors are used.
      dataSample = din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
      dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
      
      if isempty(sv)
        Sarray.music(:,bin_idx) = fftshift(pmusic(dataSample,cfg.Nsrc,Nsv));
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
        Sarray.music(:,bin_idx) = mean(abs(sv{1}(:,:).'*V(:,noiseIdxs)).^2,2);
      end
      for ml_idx = 2:length(din)
        dataSample = din{ml_idx}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
        dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
        
        if isempty(sv)
          Sarray.music(:,bin_idx) = pmusic(dataSample,cfg.Nsrc,cfg.Nsv);
        else
          Rxx = 1/size(dataSample,1) * (dataSample' * dataSample);
          [V,D] = eig(Rxx);
          eigenVals = diag(D);
          [eigenVals noiseIdxs] = sort(eigenVals);
          
          noiseIdxs = noiseIdxs(1:end-cfg.Nsrc);
          Sarray.music(:,bin_idx) = Sarray.music(:,bin_idx) ...
            + mean(abs(sv{ml_idx}(:,:).'*V(:,noiseIdxs)).^2,2);
        end
      end
      if isempty(sv)
        Sarray.music(:,bin_idx) = Sarray.music(:,bin_idx) / length(din);
      else
        Sarray.music(:,bin_idx) = 0.5 ./ (Sarray.music(:,bin_idx) / length(din));
      end
      
      
    elseif any(cfg.method == EIG_METHOD)
      %% Array: EIG
      %  Same as MUSIC except the Idxividual noise subspace eigenvectors
      %  are weighted by the inverse of their corresponding eigenvalue
      %  when the incoherent averaging is done.
      error('Eigenvector not supported');
      dataSample = din(bin+eigmeth.bin_rng,rline+line_rng,:,:,:);
      dataSample = reshape(dataSample,[length(eigmeth.bin_rng)*length(line_rng)*Na*Nb Nchan]);
      if uniformSampled
        Sarray.eig(:,Idx) = peig(dataSample,Nsrc,Ntheta);
      else
        Rxx = 1/size(dataSample,1) * (dataSample' * dataSample);
        [V,D] = eig(Rxx);
        eigenVals = diag(D).';
        [eigenVals noiseIdxs] = sort(eigenVals);
        noiseIdxs = noiseIdxs(1+Nsrc:end);
        Sarray.eig(:,Idx) = 1./mean(repmat(1./eigenVals,[size(sv,1) 1]).*abs(sv(:,:,line_idx)'*V(:,noiseIdxs)).^2,2);
      end
      
    elseif any(cfg.method == RISR_METHOD)
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
      Sarray.risr(:,bin_idx) = sig_est;
      
      
    elseif any(cfg.method == GEONULL_METHOD)
      warning off
      %% Array: GEONULL
      % The geonull method is a non-adaptive beamformer that  steers nulls
      % towards predicted clutter angles from the air-ice interfaces
      dataSample = double(din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:));
      dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb, Nc]);

      % Desired thetas and constraints
      theta_desired   = theta;
      theta_desired   = theta_desired(:);
      
      % Interference thetas and constraints
      surf_doas       = surf_theta(bin,:);
      surf_doas       = surf_doas(~isnan(surf_doas));
      theta_int       = surf_doas;
      
      % DEBUG ONLY
      if 0
        surf_doas = -51;
        theta_int = -51;
      end
      
      % Loop over pointing directions and beamform
      for des_idx = 1:length(theta_desired)
        keep_out_mask = abs(theta_int - theta_desired(des_idx)) < cfg.doa_theta_guard;
        keep_surf_doas = theta_int(~keep_out_mask);
        keep_surf_doas = keep_surf_doas(:);
        g   = vertcat(1,zeros(size(keep_surf_doas)));
        
        surf_doas_rad = keep_surf_doas*pi/180;
%         sv_fh_arg_geonull = {'theta'};
%         sv_fh_arg_geonull{2} = [theta_desired(des_idx), surf_doas_rad(:)']; % array_proc_sv breaks if this is a column vector -- fix this!
        
        for ml_idx = 1:length(cfg.fcs)
          % Make column vectors of y and z-positions
          for wf_adc_idx = 1:length(cfg.fcs{ml_idx})
            y_pos{ml_idx}(wf_adc_idx,1) = cfg.fcs{ml_idx}{wf_adc_idx}.pos(2,rline);
            z_pos{ml_idx}(wf_adc_idx,1) = cfg.fcs{ml_idx}{wf_adc_idx}.pos(3,rline);
          end
          
          % Determine Steering Vectors for target and interference
          sv_opt_arg = [];
          sv_opt_arg.theta =  [theta_desired(des_idx), surf_doas_rad(:)'];
          sv_arg = [];
          sv_arg = {cfg.wfs.fc*sqrt(cfg.sv_dielectric), y_pos{ml_idx}, z_pos{ml_idx}, sv_opt_arg, cfg.lut, cfg.fcs{1}{1}.roll(rline)};
          [~,A] = cfg.sv_fh(sv_arg{:});
%           [~,A] = cfg.sv_fh(cfg.wfs.fc*sqrt(cfg.sv_dielectric), y_pos{ml_idx}, z_pos{ml_idx}, sv_opt_arg, cfg.lut, cfg.fcs{1}{1}.roll(rline));
%           [~,A] = cfg.sv_fh(sv_fh_arg_geonull,cfg.wfs.fc,y_pos{ml_idx},z_pos{ml_idx});
%           roll = cfg.fcs{1}{1}.roll(rline);
       
          % DEBUG ONLY bin 501-502, line 1308
          if 0
            sv_opt_arg = [];
            sv_opt_arg.theta = [theta_desired(des_idx)];
            sv_arg = [];
            sv_arg = {cfg.wfs.fc*sqrt(cfg.sv_dielectric), y_pos{ml_idx}, z_pos{ml_idx}, sv_opt_arg, cfg.lut, cfg.fcs{1}{1}.roll(rline)};
            [~,Atarget] = cfg.sv_fh(sv_arg{:});
            
            Atarget = Atarget ./ sqrt(Atarget'*Atarget);
            Aint = [0.3075 + 0.0000i, -0.3686 + 0.0469i, 0.4972 - 0.1680i, -0.4738 - 0.1331i, 0.2880 + 0.2123i, -0.2115 - 0.1632i, 0.0480 + 0.2192i];
%             Aint =  [0.2090 + 0.0000i, -0.2008 + 0.2626i, -0.2076 - 0.3079i, 0.4031 - 0.1203i, -0.0308 + 0.4104i, -0.3837 - 0.1338i, 0.3912 - 0.2112i];
            Aint = (Aint(:));
            A = [Atarget,Aint];
          end
          
          % Apply pseudoinverse to g
          w = A * inv(A'*A) *g;
          w = w ./ sqrt(w'*w);
          sv_gn{ml_idx} = w;
          
        end
        Hwindow = boxcar(Nc);
        Hwindow = Hwindow ./ sqrt(Hwindow'*Hwindow);
        wgeo    = sv_gn{1}.*Hwindow;
        wgeo    = wgeo ./ sqrt(wgeo'*wgeo);
        wgeo     = wgeo ./ length(wgeo);
        
        Sarray.geonull(des_idx,bin_idx) = mean(abs(dataSample*conj(wgeo)).^2);

        for ml_idx = 2:length(din)
          dataSample = din{ml_idx}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
          dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
          wgeo = sv_gn{ml_idx}.*Hwindow;
          wgeo = wgeo ./ sqrt(wgeo'*wgeo);
          wgeo = wgeo ./ length(wgeo);          
          Sarray.geonull(des_idx,bin_idx) = Sarray.geo(des_idx,bin_idx) ...
            + mean(abs(dataSample*conj(wgeo)).^2);
        end
             
      end
%         Sarray.geonull(des_idx,bin_idx) = mean(abs(sv_gn{1}(:,:)'*bsxfun(@times,Hwindow,dataSample.')).^2,2);
%         for ml_idx = 2:length(din)        
%           dataSample = double(din{ml_idx}(bin+cfg.bin_rng,rline+line_rng,:,:,:));
%           dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
%           Sarray.geonull(des_idx,bin_idx) =       Sarray.geonull(des_idx,bin_idx) ...
%             + mean(abs(sv_gn{ml_idx}(:,:)'*bsxfun(@times,Hwindow,dataSample.')).^2,2);
%         end
%         Sarray.geonull(des_idx,bin_idx) =       Sarray.geonull(des_idx,bin_idx) / length(din);
%         
%       end
      
      if cfg.debug_plots
        % Plot Geonull beamformer, normalized periodogram and normalize
        % Music pseudospectrum
        
        % Matrix of steering vectors
        theta_vec       = linspace(-pi/2,pi/2,256);
        sv_opt_arg = [];
        sv_opt_arg.theta = [theta_vec];
        sv_arg = [];
        sv_arg = {cfg.wfs.fc*sqrt(cfg.sv_dielectric), y_pos{1}, z_pos{1}, sv_opt_arg, cfg.lut, cfg.fcs{1}{1}.roll(rline)};
        [~,SV_lut]   = cfg.sv_fh(sv_arg{:});
        
        sv_arg = [];
        sv_arg = {cfg.wfs.fc*sqrt(cfg.sv_dielectric), y_pos{1}, z_pos{1}, sv_opt_arg, [], []};
        [~,SV_nom] = cfg.sv_fh(sv_arg{:});
        
        % Geonull beamformer        
        Wgeo_lut = wgeo'*SV_lut;
        Wgeo_nom = wgeo'*SV_nom;
        
        % Normalized periodogram
        Sp_lut = (1/size(dataSample,1))*abs(sum(conj(dataSample)*SV_lut,1)).^2;
        Sp_lut = Sp_lut./max(abs(Sp_lut));
        
        Sp_nom = (1/size(dataSample,1))*abs(sum(conj(dataSample)*SV_nom,1)).^2;
        Sp_nom = Sp_nom./max(abs(Sp_nom));
        
        % Music pseudospectrum
        Rxx = 1/size(dataSample,1) * (dataSample' * dataSample);
        [V,D] = eig(Rxx);
        eigenVals = diag(D);
        [eigenVals noiseIdxs] = sort(eigenVals);   
        Nsrc = length(g);
        noiseIdxs = noiseIdxs(1:end-Nsrc);
        
        Sm_lut = mean(abs(SV_lut(:,:).'*V(:,noiseIdxs)).^2,2);
        Sm_lut = Sm_lut ./ max(abs(Sm_lut));
        
        Sm_nom = mean(abs(SV_nom(:,:).'*V(:,noiseIdxs)).^2,2);
        Sm_nom = Sm_nom ./ max(abs(Sm_nom));
        
        colorvec = hsv(7);
        figure(97);clf;
        plot(theta_vec*180/pi,20*log10(abs(Wgeo_lut)),'LineWidth',2,'Color',colorvec(1,:))
        hold on
        grid on
        grid minor
        axis tight
        plot(theta_vec*180/pi,10*log10(abs(Sp_lut)),'LineWidth',2,'Color',colorvec(2,:))
        plot(theta_vec*180/pi,10*log10(abs(Sm_lut)),'LineWidth',2,'Color',colorvec(3,:))
        [day, rem] = strtok(param.day_seg, '_');
        seg = rem(2:end);
        tgps = datetime(1970,01,01,00,00,00,00) + seconds(cfg.fcs{1}{1}.gps_time(rline));
        titlestr = sprintf('%s %s Measured Manifold, %s',day,seg,datestr(tgps));
        title(titlestr)
        ylims = ylim;
        if ~isempty(surf_doas)
          DOAclutter = surf_doas;
          line([DOAclutter(1) DOAclutter(1)],[min(ylims) max(ylims)],'LineStyle','--','Color',[0.3 0.3 0.3])
          line([DOAclutter(2) DOAclutter(2)],[min(ylims) max(ylims)],'LineStyle','--','Color',[0.3 0.3 0.3])
          legend('Geonull Beamformer','Normalized Periodogram','Normalized MUSIC','Clutter','Clutter','Location','SouthWest')
        end
        
        figure(98);clf;
        plot(theta_vec*180/pi,20*log10(abs(Wgeo_nom)),'LineWidth',2,'Color',colorvec(1,:))
        hold on
        grid on
        grid minor
        axis tight
        plot(theta_vec*180/pi,10*log10(abs(Sp_nom)),'LineWidth',2,'Color',colorvec(2,:))
        plot(theta_vec*180/pi,10*log10(abs(Sm_nom)),'LineWidth',2,'Color',colorvec(3,:))
        [day, rem] = strtok(param.day_seg, '_');
        seg = rem(2:end);
        tgps = datetime(1970,01,01,00,00,00,00) + seconds(cfg.fcs{1}{1}.gps_time(rline));
        titlestr = sprintf('%s %s Nominal Manifold, %s',day,seg,datestr(tgps));
        title(titlestr)
        ylims = ylim;
        if ~isempty(surf_doas)
          DOAclutter = surf_doas;
          line([DOAclutter(1) DOAclutter(1)],[min(ylims) max(ylims)],'LineStyle','--','Color',[0.3 0.3 0.3])
          line([DOAclutter(2) DOAclutter(2)],[min(ylims) max(ylims)],'LineStyle','--','Color',[0.3 0.3 0.3])
          legend('Geonull Beamformer','Normalized Periodogram','Normalized MUSIC','Clutter','Clutter','Location','SouthWest')
        end
        keyboard
      end
      

      
    elseif any(cfg.method == GSLC_METHOD)
      %% Array: Generalized Sidelobe Canceller
%       dataSample = din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
%       dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb, Nc]);
      
      dataSample = double(din{1}(bin+DCM_bin_rng,rline+DCM_line_rng,:,:,:));
      dataSample = reshape(dataSample,[length(DCM_bin_rng)*length(DCM_line_rng)*Na*Nb Nc]).';
      Rxx = 1/size(dataSample,2) * (dataSample * dataSample');
      dataSample = dataSample.';
      
      % Desired thetas and constraints
      theta_desired   = theta;
      theta_desired   = theta_desired(:);
      
      % Interference thetas and constraints
      surf_doas       = surf_theta(bin,:);
      surf_doas       = surf_doas(~isnan(surf_doas));
      theta_int       = surf_doas;
      
      % Loop over pointing directions and beamform
      for des_idx = 1:length(theta_desired)
         keep_out_mask = abs(theta_int - theta_desired(des_idx)) < cfg.doa_theta_guard;
        keep_surf_doas = theta_int(~keep_out_mask);
        keep_surf_doas = keep_surf_doas(:);
        g   = vertcat(1,zeros(size(keep_surf_doas)));
        Nsrc = length(g);
        % Dimensionality of the orthogonal complement of C(A)
        dim_Aperp = Nc - Nsrc;
        
        surf_doas_rad = keep_surf_doas*pi/180;
%         sv_fh_arg_gslc = {'theta'};
%         sv_fh_arg_gslc{2} = [theta_desired(des_idx), surf_doas_rad(:)']; % array_proc_sv breaks if this is a column vector -- fix this!
        sv_opt_arg = [];
        sv_opt_arg.theta = [theta_desired(des_idx), surf_doas_rad(:)'];
        
        for ml_idx = 1:length(cfg.fcs)
          % Make column vectors of y and z-positions
          for wf_adc_idx = 1:length(cfg.fcs{ml_idx})
            y_pos{ml_idx}(wf_adc_idx,1) = cfg.fcs{ml_idx}{wf_adc_idx}.pos(2,rline);
            z_pos{ml_idx}(wf_adc_idx,1) = cfg.fcs{ml_idx}{wf_adc_idx}.pos(3,rline);
          end
          
          % Determine Steering Vectors for target and interference
          sv_arg = [];
          sv_arg = {cfg.wfs.fc*sqrt(cfg.sv_dielectric), y_pos{ml_idx}, z_pos{ml_idx}, sv_opt_arg, cfg.lut, cfg.fcs{1}{1}.roll(rline)};
          [~,A] = cfg.sv_fh(sv_arg{:});
          % Find orthonormal basis for the orthogonal complement of C(A)
          % (nullspace of A transpose)
          Ca  = zeros(Nc,dim_Aperp);
          [U,S,V] = svd(A);
          Ca = U(:,end-(Nc-Nsrc)+1:end);
          % Alternatively we can use Ca = null(A') here.
          % Quiescent vector - THE QUIESCENT VECTOR IS THE SAME AS THE 
          % GEONULL WEIGHT VECTOR
          wq = A*inv(A'*A)*g;
          
          % GSLC quantities
          R_tilda = Ca'*Rxx*Ca;
          p_tilda = Ca'*Rxx*wq;
          
          % Compute the adaptive portion of the weight vector
          wa      = Ca*inv(R_tilda)*p_tilda;
          w_gslc  = wq - wa;
          w_gslc  = w_gslc ./ sqrt(w_gslc'*w_gslc);
          w_gslc  = w_gscl ./ length(w_gslc);
          sv_gslc{ml_idx} = w_gslc;
          
        end
        Hwindow = boxcar(Nc);
        Sarray.gslc(des_idx,bin_idx) = mean(abs(sv_gslc{1}(:,:)'*bsxfun(@times,Hwindow,dataSample.')).^2,2);
        for ml_idx = 2:length(din)        
          dataSample = double(din{ml_idx}(bin+cfg.bin_rng,rline+line_rng,:,:,:));
          dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
          Sarray.gslc(des_idx,bin_idx) =       Sarray.gslc(des_idx,bin_idx) ...
            + mean(abs(sv_gslc{ml_idx}(:,:)'*bsxfun(@times,Hwindow,dataSample.')).^2,2);
        end
        Sarray.gslc(des_idx,bin_idx) =       Sarray.gslc(des_idx,bin_idx) / length(din);
      end
      
        % DEBUG GSLC ONLY
        % =================================================================
        % Plot GSLC and Nonadaptive MLE
        if ~isempty(surf_doas) && cfg.debug_plots
%         if debug
          
          % Determine weight vector for nonadaptive MLE
          g_geo                 = vertcat(1,zeros(Nsrc-1,1));  % Unity gain towards nadir, nulls in clutter directions
          sv_fh_arg_geonull     = {'theta'};
          sv_fh_arg_geonull{2}  = [theta, surf_doas_rad(:)']; % array_proc_sv breaks if this is a column vector -- fix this!
          sv_opt_arg = [];
          sv_opt_arg.theta = [theta, surf_doas_rad(:)']; % array_proc_sv breaks if this is a column vector -- fix this!
          
          % Determine Steering Vectors for target and interference
          sv_arg = [];
          sv_arg = {cfg.wfs.fc*sqrt(cfg.sv_dielectric), y_pos{ml_idx}, z_pos{ml_idx}, sv_opt_arg, cfg.lut, cfg.fcs{1}{1}.roll(rline)};
          [~,Aint] = cfg.sv_fh(sv_arg{:});
%           [~,Aint] = cfg.sv_fh(sv_fh_arg_geonull,cfg.wfs.fc*sqrt(cfg.sv_dielectric),y_pos{ml_idx},z_pos{ml_idx});
          
          % Apply pseudoinverse to g (project orthogonally to interference)
          wgeo = Aint * inv(Aint'*Aint) *g_geo;
        
          theta_vec       = linspace(-pi/2,pi/2,256);
%           sv_patt_arg     = sv_fh_arg_gslc;
%           sv_patt_arg{2}  = [theta_vec];
          sv_opt_arg = [];
          sv_opt_arg.theta = [theta_vec];
          sv_arg = [];
          sv_arg = {cfg.wfs.fc*sqrt(cfg.sv_dielectric), y_pos{ml_idx}, z_pos{ml_idx}, sv_opt_arg, cfg.lut, cfg.fcs{1}{1}.roll(rline)};
          [~,Amanifold]   = cfg.sv_fh(sv_arg{:});
%           [~,Amanifold]   = cfg.sv_fh(sv_patt_arg,cfg.wfs.fc*sqrt(cfg.sv_dielectric),y_pos{ml_idx},z_pos{ml_idx});
          
          % Constituent patterns of the sidelobe canceller
          Pattgslc          = w_gslc'*Amanifold;
          Pattq             = wq'*Amanifold;
          Patta             = (wa)'*Amanifold;
          Pattgeo           = wgeo'*Amanifold;
          
          figure(197);clf;plot(theta_vec*180/pi,20*log10(abs(Pattgslc)),'LineWidth',2)
          hold on
          grid on
          grid minor
          axis tight
          plot(theta_vec*180/pi, 20*log10(abs(Pattq)),'LineWidth',2)
          plot(theta_vec*180/pi, 20*log10(abs(Patta)),'LineWidth',2)
          [day, rem] = strtok(param.day_seg, '_');
          seg = rem(2:end);
          tgps = datetime(1970,01,01,00,00,00,00) + seconds(cfg.fcs{1}{1}.gps_time(line_idx));
          titlestr = sprintf('%s %s CSARP surfData, %s',day,seg,datestr(tgps));
          title(titlestr)
          if ~isempty(surf_doas)
            DOAclutter = surf_doas;
            ylims = ylim;
            line([DOAclutter(1) DOAclutter(1)],[min(ylims) max(ylims)],'LineStyle','--','Color',[0.3 0.3 0.3])
            line([DOAclutter(2) DOAclutter(2)],[min(ylims) max(ylims)],'LineStyle','--','Color',[0.3 0.3 0.3])
            legend('w_{gslc}','w_q','w_a','Clutter','Clutter')
          else
            legend('w_{gslc}','w_q','w_a')
          end

          figure(198);clf;plot(theta_vec*180/pi,20*log10(abs(Pattgslc)),'LineWidth',2)
          hold on
          grid on
          grid minor
          plot(theta_vec*180/pi, 20*log10(abs(Pattgeo)),'LineWidth',2)
          ylims = ylim;
          [day, rem] = strtok(param.day_seg, '_');
          seg = rem(2:end);
          tgps = datetime(1970,01,01,00,00,00,00) + seconds(cfg.fcs{1}{1}.gps_time(line_idx));
          titlestr = sprintf('%s %s CSARP surfData, %s',day,seg,datestr(tgps));
          title(titlestr)
          if ~isempty(surf_doas)
            DOAclutter = surf_doas;
            line([DOAclutter(1) DOAclutter(1)],[min(ylims) max(ylims)],'LineStyle','--','Color',[0.3 0.3 0.3])
            line([DOAclutter(2) DOAclutter(2)],[min(ylims) max(ylims)],'LineStyle','--','Color',[0.3 0.3 0.3])
            legend('w_{gslc}','w_{geo}','Clutter','Clutter')
          else
            legend('w_{gslc}','w_{geo}')
          end
          keyboard
        end

    elseif any(cfg.method == MVDR_ROBUST_METHOD)
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
          
          Sarray.mvdr_robust(freqIdx,bin_idx) = Sarray.mvdr_robust(freqIdx,bin_idx) ...
            + mean(abs(w * dataSample).^2) / abs(w * sv{ml_idx}(:,freqIdx)).^2;
        end
        Sarray.mvdr_robust(freqIdx,bin_idx) = Sarray.mvdr_robust(freqIdx,bin_idx) / size(sv{1},2);
      end
      
    end
    
    if any(cfg.method == MUSIC_DOA_METHOD)
      %% Array: MUSIC DOA
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
          tout.music_doa.tomo.doa(bin_idx,:,line_idx)     = NaN;
          tout.music_doa.tomo.cost(bin_idx,line_idx)      = NaN;
          tout.music_doa.tomo.hessian(bin_idx,:,line_idx) = NaN;
          tout.music_doa.tomo.power(bin_idx,:,line_idx)   = NaN;
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
      doa_param.lut_roll        = cfg.fcs{1}{1}.roll(rline);
      
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
      sv_opt_arg = [];
      sv_opt_arg.theta = doa(:);
      sv_arg = [];
      sv_arg = {cfg.wfs.fc*sqrt(cfg.sv_dielectric), y_pos{ml_idx}, z_pos{ml_idx}, sv_opt_arg, cfg.lut, cfg.fcs{1}{1}.roll(rline)};
      [~,A] = cfg.sv_fh(sv_arg{:});
%       [~,A] = cfg.sv_fh(Nsv2,doa_param.fc,doa_param.y_pc,doa_param.z_pc);
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
        tout.music_doa.tomo.doa(bin_idx,sig_idx,line_idx)     = doa(sig_i);
        tout.music_doa.tomo.hessian(bin_idx,sig_idx,line_idx) = HESSIAN(sort_idxs(sig_i) + length(sort_idxs)*(sort_idxs(sig_i)-1));
        tout.music_doa.tomo.power(bin_idx,sig_idx,line_idx)   = P_hat(sig_i);
      end
      tout.music_doa.tomo.cost(bin_idx,line_idx) = Jval;
      
    elseif any(cfg.method == MLE_METHOD)
      %% Array: MLE
      % See Wax, Alternating projection maximum likelihood estimation for
      % direction of arrival, TSP 1983?.
      % If S-MAP is used with layerData pointing to the first range-bin,
      % then S-MAP should find the ice-layer soon. Otherwise, the tracked
      % layer will appear way bellow the actual layer location.
      if cfg.doa_seq && (exist('layerData','var') && ~isempty('layerData')) ...
          && all(isnan(tout.mle.tomo.theta(:))) && (bin_idx == bin_idxs(10))
        break;
      end
      dataSample  = din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:);
      dataSample  = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
      array_data  = dataSample.';
      Rxx         = (1/size(array_data,2)) * (array_data * array_data');
      doa_param.Rxx = Rxx; % put Rxx in doa_param (to pass to fminsearch)
      doa_param.M = size(array_data,2);
      %         cfg.Nsig_true = [];
      if 1 && isfield(cfg,'Nsig_true') && ~isempty(cfg.Nsig_true)
        if cfg.Nsig_true(bin,line) > 2
          cfg.Nsrc = 2;
        else
          doa_param.Nsig = cfg.Nsig_true(bin,rline);
        end
      end
      
      if cfg.Nsrc == 0
        tout.mle.tomo.theta(bin_idx,:,line_idx) = NaN;
        tout.mle.tomo.cost(bin_idx,line_idx) = NaN;
        tout.mle.tomo.hessian(bin_idx,:,line_idx) = NaN;
        tout.mle.tomo.img(bin_idx,:,line_idx) = NaN;
        continue
      end
      
      % This is for S-MLE, if used
      if cfg.doa_seq && ~exist('first_rbin_idx','var')
        first_rbin_idx = bin;
      end
      
      clear sources_number
      % Determine the possible number of DoAs
      % --------------------------------------
      if cfg.moe_en && ((isfield(cfg,'testing') && ~isempty(cfg.testing) && cfg.testing) ...
          || (~isfield(cfg,'testing')))
        % Model order estimation: optimal
        % ------------------------------
        if isfield(cfg,'optimal_test') && ~isempty(cfg.optimal_test) && cfg.optimal_test
          possible_Nsig_opt = [1 : max(cfg.Nsrc)];
        end
        
        % Model order estimation: suboptimal
        % ---------------------------------
        if isfield(cfg,'suboptimal_test') && ~isempty(cfg.suboptimal_test) && cfg.suboptimal_test
          % Determine the eigenvalues of Rxx
          eigval = eig(Rxx);
          eigval = sort(real(eigval),'descend');
          
          model_order_suboptimal_cfg.Nc         = Nc;
          model_order_suboptimal_cfg.Nsnap      = size(array_data,2);
          model_order_suboptimal_cfg.eigval     = eigval;
          model_order_suboptimal_cfg.penalty_NT = cfg.penalty_NT;
          model_order_suboptimal_cfg.Nsrc       = cfg.Nsrc;
          
          cfg_MOE.norm_term_suboptimal = cfg.norm_term_suboptimal;
          cfg_MOE.norm_allign_zero     = cfg.norm_allign_zero;
          model_order_suboptimal_cfg.param_MOE = cfg_MOE;
          
          sources_number_all = [];
          for model_order_method = cfg.moe_methods
            model_order_suboptimal_cfg.method  = model_order_method;
            sources_number = sim.model_order_suboptimal(model_order_suboptimal_cfg);
            
            % If S-MAP is used, then force the first range-bin to have 2 targets in case it has 1.
            if cfg.doa_seq && exist('first_rbin_idx','var') && (first_rbin_idx == bin) && (sources_number>0)
              sources_number = 2;
            end
            
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
      
      % Model order estimation: machine learning
      % ----------------------------------------
      if cfg.moe_en && (isfield(cfg,'moe_ml') && cfg.moe_ml)
        possible_Nsig_ml = [1 : max(cfg.Nsrc)];
      end
      
      if exist('possible_Nsig_opt','var')
        possible_Nsig = possible_Nsig_opt;
      elseif exist('possible_Nsig_subopt','var')
        possible_Nsig = possible_Nsig_subopt;
      elseif exist('possible_Nsig_ml','var')
        possible_Nsig = possible_Nsig_ml;
      else
        possible_Nsig = cfg.Nsrc;
      end
      
      % In case of S-MLE, the first range-bin MUST have 2 targets, one
      % on each side of the surface
      if cfg.doa_seq && ...
          (exist('first_rbin_idx','var') && ~isempty(first_rbin_idx) && (bin == first_rbin_idx)) && ...
          ((length(possible_Nsig)>1) || (possible_Nsig ~= 2))
        possible_Nsig = 2;
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
          
          % Sequential MAP (or S-MAP) section
          % -----------------------------------------------------------
          % Calculate current and next DoAs using the flat earth approximation.
          %  If not calculated, it still work as MLE, but not sequential MAP
          if cfg.doa_seq && ...
              ((isfield(cfg,'Nsig_true') && ~isempty(cfg.Nsig_true)) || (exist('first_rbin_idx','var') && ~isempty(first_rbin_idx)))
            curr_rng = cfg.range(bin);
            
            % Determine the 'adaptive' DOA bounds
            if bin == first_rbin_idx
              prev_rbin = first_rbin_idx;
              prev_rng = cfg.range(prev_rbin);
              H_air = prev_rng; % May be needed for bounding later
              %                 first_rng = cfg.range(first_rbin_idx);
              
              for doa_idx = 1:Nsrc_idx %cfg.Nsig
                LB(doa_idx) = (mid_doa(doa_idx) ...
                  + doa_param.doa_constraints(doa_idx).init_src_limits(1))*pi/180;%doa_param.src_limits{doa_idx}(1);
                UB(doa_idx) = (mid_doa(doa_idx) ...
                  + doa_param.doa_constraints(doa_idx).init_src_limits(2))*pi/180;%doa_param.src_limits{doa_idx}(2);
              end
              
              if UB(1)>ref_doa
                UB(1) = ref_doa-0.5*pi/180;
              end
              
              if LB(2)<ref_doa
                LB(2) = ref_doa+0.5*pi/180;
              end
              
              doa_param.theta = fftshift([linspace(LB(1),UB(1),5) , linspace(LB(2),UB(2),5)]);
              
              if cfg.doa_seq && cfg.debug_plots
                % Debug
                bounds_l(bin_idx,:) = [LB(1) UB(1)]*180/pi;
                bounds_r(bin_idx,:) = [LB(2) UB(2)]*180/pi;
              end
              
              % These are used to track the stdev of the prior using
              % Kalman filter.
              nPriorPoints = 5; % User defined.
              Rc = [];
              a = [];
              for i = 1: possible_Nsig
                Rc{i}(:,:,1) = 0.1*eye(nPriorPoints); % Initial Riccati update matrix.
                Rc{i}(:,:,2) = 0.1*eye(nPriorPoints);
                a{i} = zeros(nPriorPoints,2); % Initial weighting vector.
                a{i}(1,:) = 0.9;
              end
            elseif bin > first_rbin_idx && bin < Nt
              prev_rng = cfg.range(prev_rbin);
              
              % Determine the 'adaptive' DOA bounds: choose one of these modes
              % -----------------------------------
              mu_L  = -acos((prev_rng/curr_rng)*cos(prev_doa(1)));
              mu_R  = +acos((prev_rng/curr_rng)*cos(prev_doa(2)));
              
              % doa_step may change based on the bounding model
              doa_step_L = abs(mu_L-prev_doa(1));
              doa_step_R = abs(mu_R-prev_doa(2));
              
              kk_st = 1;  % bounds expansion factor for the first few rbins.
              kk_end = kk_st; % Same, but for the remaining rbins
              
              kk_st_std = 1; % stdev expansion/compression factor
              kk_end_std = kk_st_std;
              
              if 0
                % 1) The default setting: from the proposed transition model
                % :::: Gives ~ perfectly flat surface ::::
                %                   kk = kk_st; % Fixed here
                if bin <= first_rbin_idx + 10
                  kk = kk_st;
                  kk_std = kk_st_std;
                else
                  kk = kk_end;
                  kk_std = kk_end_std;
                end
                
                
                if strcmp(cfg.prior.pdf,'Gaussian')
                  if 0
                    % This is based on eduacted guess
                    a1 = 0.1;
                    UB(1) = prev_doa(1) - a1*doa_step_L;
                    LB(2) = prev_doa(2) + a1*doa_step_R;
                    
                    p = [-0.5569    0.7878    0.0071]; % These from fitting a curve into some reasonable points
                    LB(1) = mu_L - (p(1)*doa_step_L^2+p(2)*doa_step_L+p(3));
                    UB(2) = mu_R + (p(1)*doa_step_R^2+p(2)*doa_step_R+p(3));
                  else
                    % Equal bound around the mean DOA
                    UB(1) = mu_L + kk*doa_step_L;
                    LB(2) = mu_R - kk*doa_step_R;
                    
                    LB(1) = mu_L - kk*doa_step_L;
                    UB(2) = mu_R + kk*doa_step_R;
                  end
                elseif strcmp(cfg.prior.pdf,'Uniform')
                  if 0
                    % This is based on eduacted guess
                    a1 = 0.1;
                    UB(1) = prev_doa(1) - a1*doa_step_L;
                    LB(2) = prev_doa(2) + a1*doa_step_R;
                    
                    p = [-0.5569    0.7878    0.0071]; % These from fitting a curve into some reasonable points
                    LB(1) = mu_L - (p(1)*doa_step_L^2+p(2)*doa_step_L+p(3));
                    UB(2) = mu_R + (p(1)*doa_step_R^2+p(2)*doa_step_R+p(3));
                  else
                    % Equal bound around the mean DOA
                    UB(1) = mu_L + kk*doa_step_L;
                    LB(2) = mu_R - kk*doa_step_R;
                    
                    LB(1) = mu_L - kk*doa_step_L;
                    UB(2) = mu_R + kk*doa_step_R;
                  end
                end
                
                tmp_doa_step_L = kk_std * doa_step_L;
                tmp_doa_step_R = kk_std * doa_step_R;
                
                cfg.prior.model = 1;
              elseif 0
                % 2) Fixed wide bounds
                % :::: May produce zigzagy curves ::::
                LB = [mu_L prev_doa(2)] - [5 5]*pi/180;
                UB = [prev_doa(1) mu_R] + [5 5]*pi/180;
                
                tmp_doa_step_L = 5*pi/pi;
                tmp_doa_step_R = 5*pi/180;
                
                cfg.prior.model = 2;
              elseif 0
                % 3) Looser bounds when doa_step < certain threshold
                % :::: One of the best options to use::::
                a1 = 0.1;
                a2_L = 1;
                a2_R = 1;
                theta_threshold = 0.5 * pi/180;
                if doa_step_L <= theta_threshold
                  a2_L = 3;
                end
                if doa_step_R <= theta_threshold
                  a2_R = 3;
                end
                UB(1) = prev_doa(1) - a1*doa_step_L;
                LB(2) = prev_doa(2) + a1*doa_step_R;
                
                kk = kk_st; % Fixed here
                if strcmp(cfg.prior.pdf,'Gaussian')
                  LB(1) = mu_L - kk*a2_L*doa_step_L;
                  UB(2) = mu_R + kk*a2_R*doa_step_R;
                elseif strcmp(cfg.prior.pdf,'Uniform')
                  LB(1) = mu_L - a2_L*doa_step_L;
                  UB(2) = mu_R + a2_R*doa_step_R;
                end
                
                tmp_doa_step_L = a2_L*doa_step_L;
                tmp_doa_step_R = a2_R*doa_step_R;
                
                cfg.prior.model = 3;
              elseif 0
                % 4) Continuous bounding replacemnt for 3) (John's idea 1)
                % :::: Similar to 3) ::::
                theta_threshold  = 0.5* pi/180;
                if (doa_step_L <= theta_threshold) || (doa_step_R <= theta_threshold)
                  theta_transition_deg = 0.9;
                  % C: compression factor
                  C = 4;
                  transition_speed = 3.5;
                  % theta_change: change in DOA over range-bins
                  theta_change_deg = linspace(0,2,101);
                  theta_change_bound = theta_change_deg.*(1 + (C-1)./(1+exp((theta_change_deg-theta_transition_deg)*transition_speed)) );
                  
                  [~,i_l] = min(abs(theta_change_deg*pi/180 - doa_step_L));
                  [~,i_r] = min(abs(theta_change_deg*pi/180 - doa_step_R));
                  new_doa_step_L = theta_change_bound(i_l)*pi/180;
                  new_doa_step_R = theta_change_bound(i_r)*pi/180;
                  if 0
                    % Debug plot
                    figure;
                    plot(theta_change_deg,theta_change_bound,'b')
                    hold on;
                    plot(theta_change_deg(i_l),new_doa_step_L*180/pi,'xr')
                    plot(theta_change_deg(i_l),doa_step_L*180/pi,'*r')
                    plot(theta_change_deg(i_r),new_doa_step_R*180/pi,'xk')
                    plot(theta_change_deg(i_r),doa_step_R*180/pi,'*k')
                    grid on
                    xlabel('\Delta\theta (deg)')
                    ylabel('Upper bound (deg)')
                  end
                end
                
                if doa_step_L <= theta_threshold
                  % If DOA change drops below theta_transition
                  doa_step_geom_L = new_doa_step_L;
                else
                  % Default
                  doa_step_geom_L = doa_step_L;
                end
                
                if doa_step_R <= theta_threshold
                  doa_step_geom_R = new_doa_step_R;
                else
                  doa_step_geom_R = doa_step_R;
                end
                
                a1 = 0.1;
                UB(1) = prev_doa(1) - a1*doa_step_geom_L;
                LB(2) = prev_doa(2) + a1*doa_step_geom_R;
                
                kk = kk_st; % Fixed here
                if strcmp(cfg.prior.pdf,'Gaussian')
                  LB(1) = mu_L - kk*doa_step_geom_L;
                  UB(2) = mu_R + kk*doa_step_geom_R;
                elseif strcmp(cfg.prior.pdf,'Uniform')
                  LB(1) = mu_L - doa_step_geom_L;
                  UB(2) = mu_R + doa_step_geom_R;
                end
                
                tmp_doa_step_L = doa_step_geom_L;
                tmp_doa_step_R = doa_step_geom_R;
                
                cfg.prior.model = 4;
              elseif 1
                % 5) Geomtry-based bounding (John's idea 2)
                % Here, bounds are set as a function of DOA.
                % :::: Produces good results too ::::
                theta_range = linspace(0,89,101)/180*pi;
                h = 20; % Typical height deviation
                if er_ice == 1
                  T = 0;
                else
                  T = 2000; % ice thickness .. SHOULD USE A FORMULA HERE
                end
                theta_ice = asin(sin(theta_range)/sqrt(er_ice));
                R = H_air./cos(theta_range) + T./cos(theta_ice);
                bound = pi/2 - theta_ice - asin( (R-h./cos(theta_ice))./R.*sin(pi/2+theta_ice));
                
                [~ , i_l] = min(abs(theta_range-abs(mu_L)));
                [~ , i_r] = min(abs(theta_range-abs(mu_R)));
                doa_step_L = bound(i_l);
                doa_step_R = bound(i_r);
                
                if bin <= first_rbin_idx + 10
                  kk = kk_st;
                  kk_std = kk_st_std;
                else
                  kk = kk_end;
                  kk_std = kk_end_std;
                end
                
                if 1
                  if strcmp(cfg.prior.pdf,'Gaussian')
                    %                       a1 = 0.1;
                    %                       UB(1) = prev_doa(1) - a1*doa_step_L;
                    %                       LB(2) = prev_doa(2) + a1*doa_step_R;
                    UB(1) = mu_L + kk*doa_step_L;
                    LB(2) = mu_R - kk*doa_step_R;
                    
                    LB(1) = mu_L - kk*doa_step_L;
                    UB(2) = mu_R + kk*doa_step_R;
                  elseif strcmp(cfg.prior.pdf,'Uniform')
                    %                       a1 = 0.1;
                    %                       UB(1) = prev_doa(1) - a1*doa_step_L;
                    %                       LB(2) = prev_doa(2) + a1*doa_step_R;
                    UB(1) = mu_L + kk*doa_step_L;
                    LB(2) = mu_R - kk*doa_step_R;
                    
                    LB(1) = mu_L - kk*doa_step_L;
                    UB(2) = mu_R + kk*doa_step_R;
                  end
                else
                  UB(1) = mu_L + 5*pi/180;
                  LB(2) = mu_R - 5*pi/180;
                  
                  LB(1) = mu_L - 5*pi/180;
                  UB(2) = mu_R + 5*pi/180;
                end
                
                tmp_doa_step_L = kk_std * doa_step_L;
                tmp_doa_step_R = kk_std * doa_step_R;
                
                cfg.prior.model = 5;
                if 0
                  figure;
                  plot(theta_range*180/pi,bound*180/pi,'b')
                  xlabel('Incidence angle (deg)');
                  ylabel('Upper bound (deg)');
                  grid on
                  xlim([0 ceil(max(theta_range*180/pi))])
                  ylim([0 ceil(max(bound*180/pi))])
                end
              end
              
              % Standard deviation of the prior pdf
              % ------------------------------------
              if strcmp(cfg.prior.pdf,'Gaussian')
                % 1) Gaussian prior pdf: from the proposed transition model
                std_doa = [tmp_doa_step_L  tmp_doa_step_R].';
                
                % Kalman filter to track the stdev.
                if 0
                  std_doa_accum(end+1,:) = [tmp_doa_step_L  tmp_doa_step_R];
                  for doa_i = 1:length(std_doa)
                    KF_param.nPriorPoints = nPriorPoints;
                    KF_param.Rc = Rc{Nsrc_idx}(:,:,doa_i);
                    KF_param.a = a{Nsrc_idx}(:,doa_i);
                    if nPriorPoints >= size(std_doa_accum,1)
                      KF_param.s_prev = flipud(std_doa_accum(1:size(std_doa_accum,1),doa_i));
                      KF_param.s_prev = [KF_param.s_prev ; zeros(nPriorPoints - length(KF_param.s_prev),1)];
                    else
                      KF_param.s_prev = flipud(std_doa_accum(size(std_doa_accum,1)-nPriorPoints+1:size(std_doa_accum,1),doa_i));
                    end
                    KF_param.s_curr = std_doa(doa_i);
                    
                    [a{Nsrc_idx}(:,doa_i) , Rc{Nsrc_idx}(:,:,doa_i)] = KF_track_stdev_for_SMAP(KF_param);
                    
                    % Update the stdev
                    std_doa(doa_i,1) = KF_param.s_prev.' * a{Nsrc_idx}(:,doa_i);
                  end
                end
              elseif strcmp(cfg.prior.pdf,'Uniform')
                % 2) Uniform prior pdf
                std_doa = [90 90].'*pi/180;
              end
              
              %                 std_doa_accum_new(end+1,:) = std_doa; % For debug only
              
              % This is used when Nsnaps change when the change in DOA
              % becomes bellow some threshold -- THIS IS ONLY A TEST
              if 0 && ((doa_step_L <= 0.5*pi/180) || (doa_step_R <= 0.5*pi/180))
                cfg.bin_rng = [-2:2];
                cfg.moe_methods = 6;
                cfg.norm_term_optimal = [-3.4672  269.5976  582.3269];
              end
              
              % Force bounds to always be between ref_doa and src_limits
              if UB(1)>ref_doa
                UB(1) = ref_doa-0.5*pi/180;
              end
              
              if LB(2)<ref_doa
                LB(2) = ref_doa+0.5*pi/180;
              end
              
              if LB(1)<doa_param.doa_constraints(1).src_limits(1)/180*pi
                LB(1) = doa_param.doa_constraints(1).src_limits(1)/180*pi;
              end
              
              if LB(2)>doa_param.doa_constraints(2).src_limits(2)/180*pi
                LB(2) = doa_param.doa_constraints(2).src_limits(2)/180*pi;
              end
              
              if cfg.doa_seq && cfg.debug_plots
                % Debug
                bounds_l(bin_idx,:) = [LB(1) UB(1)]*180/pi;
                bounds_r(bin_idx,:) = [LB(2) UB(2)]*180/pi;
                mean_l(bin_idx,:)   = mu_L*180/pi;
                mean_r(bin_idx,:)   = mu_R*180/pi;
              end
              
              % Set the number of grid points based on LB, UB, and Nc
              % -----------------------------------------------------
              My = 4;
              N_theta = 2*floor(My*Nc/2);
              search_rng = max(abs(abs(UB)-abs(LB)));
              if search_rng >= 10*pi/180
                N_theta = ceil(N_theta/1);
              elseif (search_rng >= 5*pi/180) && (search_rng < 10*pi/180)
                N_theta = ceil(N_theta/2);
              elseif (search_rng > 1*pi/180) && (search_rng < 5*pi/180)
                N_theta = 5;
              else
                N_theta = 1;
              end
              doa_param.theta = fftshift([linspace(LB(1),UB(1),N_theta) , linspace(LB(2),UB(2),N_theta)]);
              %                 doa_param.theta = fftshift(linspace(min([LB UB]),max([LB UB]),N_theta));
              clear N_theta
            elseif bin == Nt
              % Nothing to be done at this point
            end
            
            % Choose the prior pdf (pdf of the DOA before taking
            % measurements). There are Uniform (large variance) and
            % Gaussian (small variance) only at this point. In both
            % cases you should pass in the variance (mean can be the same
            % for both distributions).
            if bin == first_rbin_idx
              % Uniform a priri pdf (for initial state only)
              doa_param.apriori.en = 0;
              doa_param.doa_seq = 0;
              mean_doa = NaN(max_Nsrc,1);
              var_doa  = NaN(max_Nsrc,1);
            else
              % Gaussian a priori pdf (for all other states)
              if 1
                doa_param.apriori.en = 1;
                doa_param.doa_seq = 1;
                mean_doa = [mu_L  mu_R].';
                var_doa = std_doa.^2;
              else
                % DON'T USE IT .. NOT FINALIZED YET
                % Heuristic choice of the prior pdf (John's idea)
                % -----------------------------------------------
                % Range of DOA over which the prior pdf extends
                num_vals = 101;
                theta_range = repmat(linspace(-5,5,num_vals).',[1 2]);
                %                 theta_range = theta_range + [mu_L*ones(kk,1) mu_R*ones(kk,1)]*180/pi;
                % W: widening factor beyond the standard deviation
                W = 2;
                % C: compression factor for negative values
                C = 4;
                % f_prior: the prior pdf (not necessarily Gaussian
                f_prior = zeros(length(theta_range),2);
                
                % LEFT DOA
                % :::::::::
                doa_i = 1;
                theta_std = tmp_doa_step_L*180/pi;
                % mm: Logical mask
                mm = C*theta_range(:,doa_i)>=-3*theta_std & theta_range(:,doa_i)<0;
                f_prior(mm,doa_i) = exp(-(C*theta_range(mm,doa_i)).^2/(theta_std*W).^2);
                % mm: Logical mask
                mm = theta_range(:,doa_i) >= 0 & theta_range(:,doa_i)>-3*theta_std;
                f_prior(mm,doa_i) = exp(-theta_range(mm,doa_i).^2/(theta_std*W).^2);
                f_prior(theta_range(:,doa_i)>3*theta_std,doa_i) = 0;
                f_prior((theta_range(:,doa_i)+mu_L*180/pi) >= ref_doa,doa_i) = 0;
                
                % RIGHT DOA
                % ::::::::::
                doa_i = 2;
                theta_std = tmp_doa_step_R*180/pi;
                % mm: Logical mask
                mm = C*theta_range(:,doa_i)>=-3*theta_std & theta_range(:,doa_i)<0;
                f_prior(mm,doa_i) = exp(-(C*theta_range(mm,doa_i)).^2/(theta_std*W).^2);
                % mm: Logical mask
                mm = theta_range(:,doa_i) >= 0 & theta_range(:,doa_i)>-3*theta_std;
                f_prior(mm,doa_i) = exp(-theta_range(mm,doa_i).^2/(theta_std*W).^2);
                f_prior(theta_range(:,doa_i)>3*theta_std,doa_i) = 0;
                f_prior((theta_range(:,doa_i)+mu_R*180/pi) <= ref_doa,doa_i) = 0;
                
                doa_param.apriori.f_prior = f_prior;
                doa_param.apriori.theta_range = theta_range*pi/180 + [mu_L*ones(num_vals,1) mu_R*ones(num_vals,1)];
                
                if 0
                  % Debug plot
                  figure;clf
                  [~,i_l] = min(abs((theta_range(:,1)+mu_L*180/pi) - mu_L*180/pi));
                  [~,i_r] = min(abs((theta_range(:,2)+mu_R*180/pi) - mu_R*180/pi));
                  
                  plot(theta_range(:,1)+mu_L*180/pi,f_prior(:,1),'-b')
                  hold on
                  plot(theta_range(:,2)+mu_R*180/pi,f_prior(:,2),'-r')
                  
                  % Plot the mean DOA
                  plot(theta_range(i_l,1)+mu_L*180/pi,f_prior(i_l,2),'*k')
                  plot(theta_range(i_r,2)+mu_R*180/pi,f_prior(i_r,2),'*k')
                  grid on
                  xlabel('Incident angle (deg)')
                  ylabel('f_{prior} (\theta)')
                end
              end
            end
            
            % Estimate the initial DOA, theta0
            % ---------------------------------
            doa_param.Nsrc = Nsrc_idx;
            if (Nsrc_idx < max_Nsrc) %|| ~(isfield(cfg,'Nsrc_true') && ~isempty(cfg.Nsrc_true))
              % Case of 1/2 DOAs to 1 DOA
              theta0 = NaN(max_Nsrc,1);
              doa_param.src_limits = [];
              for sig_i = 1:max_Nsrc
                if ~exist('LB','var')
                  keyboard;
                end
                doa_param.src_limits{1} = [LB(sig_i)  UB(sig_i)];
                doa_param.apriori.mean_doa = mean_doa(sig_i);
                doa_param.apriori.var_doa  = var_doa(sig_i);
                theta0(sig_i) = mle_initialization(Rxx,doa_param);
              end
            else
              % Case of 1/2 DOAs to 2 DOA
              for src_idx = 1:Nsrc_idx %cfg.Nsrc
                doa_param.src_limits{src_idx} = [LB(src_idx)  UB(src_idx)];
              end
              
              doa_param.apriori.mean_doa = mean_doa;
              doa_param.apriori.var_doa  = var_doa;
              theta0 = mle_initialization(Rxx,doa_param);
            end
            
            % If theta0 is outside the bounds, which could happen due to
            % the bad choice of the grid points, set theta0 equal to the
            % center point between LB and UB
            
            for doa_idx = 1:length(theta0)
              if theta0(doa_idx) < LB(doa_idx) || theta0(doa_idx) > UB(doa_idx)
                theta0(doa_idx) = (LB(doa_idx) + UB(doa_idx))/2;
              end
            end
          end
          
          if ~exist('theta0','var')
            % MLE
            % Initialize search
            for src_idx = 1:Nsrc_idx %cfg.Nsrc
              doa_param.src_limits{src_idx} = mid_doa(src_idx) ...
                + doa_param.doa_constraints(src_idx).init_src_limits/180*pi;
              %doa_param.src_limits{src_idx} = [-pi/2 pi/2]; % DEBUG
            end
            
            %               doa_nonlcon_fh = eval(sprintf('@(x) doa_nonlcon(x,%f);', doa_param.theta_guard));
            doa_param.Nsrc = Nsrc_idx;
            doa_param.doa_seq = 0;
            theta0 = mle_initialization(Rxx,doa_param);
          end
          
          % Minimization of wb_cost_function
          % -------------------------------------------------------------
          if cfg.doa_seq ...
              && ((isfield(cfg,'Nsig_true') && ~isempty(cfg.Nsig_true)) || (exist('first_active_doa','var') && ~all(isnan(first_active_doa))))
            % In S-MAP, theta_guard is already part of the filter
            doa_nonlcon_fh = [];
          else
            doa_nonlcon_fh = eval(sprintf('@(x) doa_nonlcon(x,%f);', doa_param.theta_guard));
          end
          
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
          %             if (abs(min(UB-LB)) < 0.1*pi/180); keyboard;end
          warning off;
          if max(UB)<=max(upper_lim) && min(LB)>=min(lower_lim) && (abs(min(UB-LB)) >= 0.08*pi/180)
            if cfg.doa_seq ...
                && ((isfield(cfg,'Nsrc_true') && ~isempty(cfg.Nsrc_true)) || (exist('first_active_doa','var') && ~all(isnan(first_active_doa))))
              % S-MAP
              if Nsrc_idx < max_Nsrc
                % Unknown model order
                % S-MAP is setup to handle 2 DOAs at a time (left and right)
                % So, if there is one DOA, then choose the one that has
                % the lowest cost (or larger log-likelihood)
                tmp_DOA = [];
                tmp_cost = [];
                for tmp_doa_idx = 1:max_Nsrc % length(mean_doa)
                  doa_param.apriori.mean_doa = mean_doa(tmp_doa_idx);
                  doa_param.apriori.var_doa  = var_doa(tmp_doa_idx);
                  [tmp_doa,Jval,exitflag,OUTPUT,~,~,HESSIAN] = ...
                    fmincon(@(theta_hat) mle_cost_function(theta_hat,doa_param), theta0(tmp_doa_idx),[],[],[],[],LB(tmp_doa_idx),UB(tmp_doa_idx),doa_nonlcon_fh,doa_param.options);
                  
                  tmp_DOA(tmp_doa_idx) = tmp_doa;
                  tmp_cost(tmp_doa_idx) = Jval;
                end
                [~, best_doa_idx] = nanmin(tmp_cost);
                doa = tmp_DOA(best_doa_idx);
              else
                % Known model order
                [doa,Jval,exitflag,OUTPUT,~,~,HESSIAN] = ...
                  fmincon(@(theta_hat) mle_cost_function(theta_hat,doa_param), theta0,[],[],[],[],LB,UB,doa_nonlcon_fh,doa_param.options);
              end
            else
              
              [doa,Jval,exitflag,OUTPUT,~,~,HESSIAN] = ...
                fmincon(@(theta_hat) mle_cost_function(theta_hat,doa_param), theta0,[],[],[],[],LB,UB,doa_nonlcon_fh,doa_param.options);
            end
          else
            if cfg.doa_seq ...
                && ((isfield(cfg,'Nsrc_true') && ~isempty(cfg.Nsrc_true)) || (exist('first_active_doa','var') && ~all(isnan(first_active_doa))))
              % S-MAP
              % Remember: if you run MUSIC with S-MAP and S-MAP exits at
              % this point, then MUSIC will also exit.
              early_stop = true;
              break;
            else
              % MLE
              doa = NaN(Nsrc_idx,1);
              HESSIAN = NaN(Nsrc_idx);
              Jval = NaN;
            end
          end
          clear theta0 LB UB
          
          [doa,sort_idxs] = sort(doa);
          
          doa_mle{Nsrc_idx} = doa;
          tmp_Hessian{Nsrc_idx} = HESSIAN;
          tmp_Jval{Nsrc_idx} = Jval;
        end
      end
      if early_stop
        break;
      end
      
      % Model order estimation: machine learning
      % ----------------------------------------
      % MOE: Machine learning ...estimates the model order, model_order,
      % with probability prob.
      if cfg.moe_en && (isfield(cfg,'moe_ml') && cfg.moe_ml)
        eigval  = sort(real(eig(Rxx)),'descend');
        % model_order: estimated Nsrc
        [model_order, prob] = moe_ml_array_proc(eigval);
        
        % If S-MAP is used, then force the first range-bin to have 2 targets in case it has 1.
        if cfg.doa_seq && exist('first_rbin_idx','var') && (first_rbin_idx == bin) && (model_order>0)
          model_order = 2;
        end
        
        sources_number = model_order;
        if model_order > 0
          doa = doa_mle{model_order};
        else
          doa = NaN(cfg.Nsrc,1);
        end
        dout.moe.ML.Nest(bin_idx,line_idx)       = sources_number;
        dout.moe.ML.doa(bin_idx,:,line_idx)      = doa;
        dout.moe.ML.est_prob(bin_idx,:,line_idx) = prob;
      end
      
      % Model order estimation: optimal
      % --------------------------------
      if cfg.moe_en && ((~isempty(doa_mle)) && isfield(cfg,'testing') && ~isempty(cfg.testing) && cfg.testing ...
          && isfield(cfg,'optimal_test') && ~isempty(cfg.optimal_test) && cfg.optimal_test)
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
        model_order_optimal_cfg.param_MOE  = cfg_MOE;
        model_order_optimal_cfg.doa_mle    = doa_mle;
        
        model_order_optimal_cfg.y_pc  = doa_param.y_pc;
        model_order_optimal_cfg.z_pc  = doa_param.z_pc;
        model_order_optimal_cfg.fc    = doa_param.fc;
        
        for model_order_method = cfg.moe_methods
          model_order_optimal_cfg.method  = model_order_method;
          
          [sources_number,doa] = sim.model_order_optimal(model_order_optimal_cfg);
          
          % If S-MAP is used, then force the first range-bin to have 2 targets in case it has 1.
          if cfg.doa_seq && exist('first_rbin_idx','var') && (first_rbin_idx == bin) && (sources_number>0)
            sources_number = 2;
            doa = doa_mle{sources_number};
          end
          
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
              error('MOE method is not supported')
          end
        end
      end
      
      % Store the DOAs of maximum possible targets
      %         dout.all_DOAs(bin_idx,:,line_idx) = doa_mle{end};
      
      if ~exist('sources_number','var')
        sources_number = length(doa_mle) ;%cfg.Nsrc;
      end
      
      if ~isempty(sources_number) && (sources_number ~= 0)
        doa = doa_mle{sources_number};
        HESSIAN = tmp_Hessian{sources_number};
        Jval = tmp_Jval{sources_number};
        % Apply pseudoinverse and estimate power for each source
        Nsv2{1} = 'theta';
        Nsv2{2} = doa(:)';
        sv_opt_arg = [];
        sv_opt_arg.theta = doa(:);
        sv_arg = [];
        sv_arg = {cfg.wfs.fc*sqrt(cfg.sv_dielectric), y_pos{ml_idx}, z_pos{ml_idx}, sv_opt_arg, cfg.lut, cfg.fcs{1}{1}.roll(rline)};
        [~,A] = cfg.sv_fh(sv_arg{:});
%         [~,A] = cfg.sv_fh(Nsv2,doa_param.fc*sqrt(cfg.sv_dielectric),doa_param.y_pc,doa_param.z_pc);
        %           k       = 4*pi*doa_param.fc/c;
        %           A       = sqrt(1/length(doa_param.y_pc))*exp(1i*k*(doa_param.y_pc*sin(doa(:)).' - doa_param.z_pc*cos(doa(:)).'));
        Weights = (A'*A)\A';
        %           Weights         = inv(A'*A)*A';
        S_hat           = Weights*array_data;
        P_hat           = mean(abs(S_hat).^2,2);
        warning on;
        
        if sources_number == 1
          if doa <=0
            sig_idx = 1;
          else
            sig_idx = 2;
          end
          tout.mle.tomo.theta(bin_idx,sig_idx,line_idx)   = doa;
          tout.mle.tomo.hessian(bin_idx,sig_idx,line_idx) = HESSIAN;
          tout.mle.tomo.img(bin_idx,sig_idx,line_idx)     = P_hat;
          tout.mle.tomo.cost(bin_idx,line_idx)            = Jval;
          
        else
          tout.mle.tomo.theta(bin_idx,:,line_idx)     = doa;
          tout.mle.tomo.hessian(bin_idx,:,line_idx) = diag(HESSIAN);
          tout.mle.tomo.img(bin_idx,:,line_idx)   = P_hat;
          tout.mle.tomo.cost(bin_idx,line_idx)      = Jval;
        end
      end
      
      % These are for S-MAP, if used
      prev_doa = double(tout.mle.tomo.theta(bin_idx,:,line_idx));
      
      % Reset if no DOAs were found in the first range-bin
      if exist('first_rbin_idx','var') && (first_rbin_idx == bin) && all(isnan(prev_doa))
        clear first_rbin_idx;
      end
      
      if cfg.doa_seq && (sources_number > 0) ...
          && ~(exist('first_active_doa','var') && ~all(isnan(first_active_doa)))
        first_rbin_idx = bin; % For MOE
        first_active_doa = double(tout.mle.tomo.theta(bin_idx,:,line_idx));
        prev_active_doa = first_active_doa;
        if sources_number == 1
          first_active_doa(isnan(first_active_doa)) = -first_active_doa(~isnan(first_active_doa));
        end
        prev_active_rbin = bin;
      end
      
      % For S-MAP:Update the previous DOA based on either the DOA of the
      % previous state (if available) or approximate flat surface
      % assumption. This prev_doa will not be stored, but we need to keep
      % track of it to bound the DOAs of the next state (or range-bin).
      if cfg.doa_seq && ...
          ((isfield(cfg,'Nsrc_true') && ~isempty(cfg.Nsrc_true)) || (exist('first_active_doa','var') && ~all(isnan(first_active_doa)))) && ...
          (bin > first_rbin_idx && bin < Nt )
        prev_active_rng = cfg.range(prev_active_rbin);
        if all(isnan(prev_doa))
          % Both NaN
          prev_doa(1) = -acos(prev_active_rng/curr_rng * cos(prev_active_doa(1)));
          prev_doa(2) = +acos(prev_active_rng/curr_rng * cos(prev_active_doa(2)));
        elseif isnan(prev_doa(1))
          % No left DOA
          prev_doa(1) = -acos(prev_active_rng/curr_rng * cos(prev_active_doa(1)));
        elseif isnan(prev_doa(2))
          % No right DOA
          prev_doa(2) = +acos(prev_active_rng/curr_rng * cos(prev_active_doa(2)));
        end
        prev_active_doa = prev_doa;
        prev_active_rbin = bin;
      end
      
      prev_rbin = bin;
      
      if 0
        %% Array MLE: DEBUG code to plot cost function
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
      
      if 0
        %% Array MLE: DEBUG code for bin restriction
        %         hist_bins = cfg.bin_restriction.start_bin(rline)+(150:700).';
        %         hist_poly = polyfit(hist_bins,tout.tomo.mle.theta(hist_bins,line_idx-1),2);
        %         plot(hist_bins,tout.tomo.mle.theta(hist_bins,line_idx-1),'.');
        %         hist_val = polyval(hist_poly,hist_bins);
        %         hold on;
        %         plot(hist_bins, hist_val,'r');
        %         hold off;
        %
        %         hist_bins = dout.bin_restriction.start_bin(rline)+(150:1700).';
        %         hist3([ hist_bins, tout.tomo.mle.theta(hist_bins,line_idx-1)],[round(length(hist_bins)/20) 30])
        %         set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
      end
      
      
    elseif any(cfg.method == DCM_METHOD)
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
      
      %% Array DCM: Minimization of wb_cost_function
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
      
      %% Array DCM: Estimate relative power for each source
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
      tout.dcm.tomo.theta(bin_idx,:,line_idx)      = doa;
      tout.dcm.tomo.cost(bin_idx,line_idx)       = Jval;
      tout.dcm.tomo.hessian(bin_idx,:,line_idx)  = diag(HESSIAN); % Not available with fminsearch
      tout.dcm.tomo.img(bin_idx,:,line_idx)    = P_hat;
      
      if 0
        %% Array DCM: DEBUG code for bin restriction
        %         hist_bins = cfg.bin_restriction.start_bin(rline)+(150:700).';
        %         hist_poly = polyfit(hist_bins,tout.tomo.dcm.theta(hist_bins,line_idx-1),2);
        %         plot(hist_bins,tout.tomo.dcm.theta(hist_bins,line_idx-1),'.');
        %         hist_val = polyval(hist_poly,hist_bins);
        %         hold on;
        %         plot(hist_bins, hist_val,'r');
        %         hold off;
        %
        %         hist_bins = cfg.bin_restriction.start_bin(rline)+(150:1700).';
        %         hist3([ hist_bins, tout.tomo.dcm.theta(hist_bins,line_idx-1)],[round(length(hist_bins)/20) 30])
        %         set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
      end
      
      if 0
        %% Array DCM: DEBUG code to plot cost function
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
      
    elseif 0
      %% Array: WBMLE Wideband Maximum Likelihood Estimator algorithm
      
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
      
      %% Array WBMLE: Minimization of wb_cost_function
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
      tout.tomo.dcm.theta(bin_idx,:,line_idx)  = doa;
      tout.tomo.dcm.cost(bin_idx,line_idx)   = Jval;
      %dout.func_counts(bin_idx,line_idx)  = OUTPUT.funcCount;
      tout.tomo.dcm.hessian(bin_idx,:,line_idx)  = diag(HESSIAN);
      
      % Apply pseudoinverse and estimate power for each source
      P_hat = 0;
      k       = 4*pi*(doa_param.fc + doa_param.fs*[0:floor((NB-1)/2), -floor(NB/2):-1]/NB)/c;
      for band_idx = 1:NB
        A       = sqrt(1/length(doa_param.y_pc)) *exp(1i*k(band_idx)*(doa_param.y_pc*sin(doa(:)).' - doa_param.z_pc*cos(doa(:)).'));
        Weights = inv(A'*A)*A';
        S_hat   = Weights*array_data.';
        P_hat   = P_hat + mean(abs(S_hat).^2,2);
      end
      tout.tomo.dcm.img(bin_idx,:,line_idx)  = P_hat;
      
    elseif any(cfg.method == SNAPSHOT_METHOD)
      %% Array: SNAPSHOT
      
      % Store the snapshot
      % -------------------------------------------------------------------
      dataSample = double(din{1}(bin+cfg.bin_rng,rline+line_rng,:,:,:));
      dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb, Nc]);
      tout.snapshot.tomo.img(bin_idx,1:Nc,line_idx) = dataSample;
      
      % Estimate power from each source
      % -------------------------------------------------------------------
      surf_doas   = surf_theta(bin_idx,:);
      Nsrc_new    = length(surf_doas);
      
      if size(tout.snapshot.tomo.power,2) < Nsrc_new
        Ngrow       = Nsrc_new - size(tout.snapshot.tomo.power,2);
        tout.snapshot.tomo.power = cat(2,tout.snapshot.tomo.power,nan(size(tout.snapshot.tomo.power,1),Ngrow,size(tout.snapshot.tomo.power,3)));
      end
      
      surf_index = 1:length(surf_doas);
      theta_desired = surf_doas;
      surf_power = [];
      for des_idx = 1:length(theta_desired)
        
        if isnan(theta_desired(des_idx))
          surf_power(des_idx) = nan;
        else
          % Pull out doas not in desired direction
          temp_theta_int = surf_doas(surf_index ~= des_idx);
          % Only keep non-nan values
          theta_int = temp_theta_int(~isnan(temp_theta_int));
          % throw out doas in keepout zone
          keep_out_mask = abs(theta_int - theta_desired(des_idx)) < cfg.doa_theta_guard;
          keep_surf_doas = theta_int(~keep_out_mask);
          keep_surf_doas = keep_surf_doas(:);
          % Constraint vector
          g   = vertcat(1,zeros(size(keep_surf_doas)));
          % Convert to radians for array_proc_sv
          surf_doas_rad = keep_surf_doas*pi/180;
          theta_desired_rad = theta_desired(des_idx).*pi/180;
%           sv_fh_arg = {'theta'};
%           sv_fh_arg{2} = [theta_desired(des_idx), surf_doas_rad(:)']; % array_proc_sv breaks if this is a column vector -- fix this!
          sv_opt_arg = [];
          sv_opt_arg.theta = [theta_desired_rad, surf_doas_rad(:)']; % array_proc_sv breaks if this is a column vector -- fix this!
          
          % Estimate power
          for ml_idx = 1:length(cfg.fcs)
            % Make column vectors of y and z-positions
            for wf_adc_idx = 1:length(cfg.fcs{ml_idx})
              y_pos{ml_idx}(wf_adc_idx,1) = cfg.fcs{ml_idx}{wf_adc_idx}.pos(2,rline);
              z_pos{ml_idx}(wf_adc_idx,1) = cfg.fcs{ml_idx}{wf_adc_idx}.pos(3,rline);
            end
            % Determine Steering Vectors for target and interference
            sv_arg = [];
            sv_arg = {cfg.wfs.fc*sqrt(cfg.sv_dielectric), y_pos{ml_idx}, z_pos{ml_idx}, sv_opt_arg, cfg.lut, cfg.fcs{1}{1}.roll(rline)};
            [~,A] = cfg.sv_fh(sv_arg{:});
%             [~,A] = cfg.sv_fh(sv_fh_arg,cfg.wfs.fc*sqrt(cfg.sv_dielectric),y_pos{ml_idx},z_pos{ml_idx});
            % Apply pseudoinverse to g
            warning off
            w = A * inv(A'*A) *g;
            warning on
            w = w ./ sqrt(w'*w);
            sv_gn{ml_idx} = w;
            
          end
          
          Hwindow = boxcar(Nc);
          Hwindow = Hwindow ./ sqrt(Hwindow'*Hwindow);
          wgeo    = sv_gn{1}.*Hwindow;
          wgeo    = wgeo ./ sqrt(wgeo'*wgeo);
          wgeo     = wgeo ./ length(wgeo);
          
          surf_power(des_idx) = mean(abs(dataSample*conj(wgeo)).^2);
          
          for ml_idx = 2:length(din)
            dataSample = double(din{ml_idx}(bin+cfg.bin_rng,rline+line_rng,:,:,:));
            dataSample = reshape(dataSample,[length(cfg.bin_rng)*length(line_rng)*Na*Nb Nc]);
            surf_power(des_idx) =       surf_power(des_idx) ...
              + mean(abs(sv_gn{ml_idx}(:,:)'*bsxfun(@times,Hwindow,dataSample.')).^2,2);
            
            wgeo = sv_gn{ml_idx}.*Hwindow;
            wgeo = wgeo ./ sqrt(wgeo'*wgeo);
            wgeo = wgeo ./ length(wgeo);
            surf_power(des_idx) = surf_power(des_idx) ...
              + mean(abs(dataSample*conj(wgeo)).^2);
          end
          surf_power(des_idx) = surf_power(des_idx) / length(din);
        end
      end
      % Store the power estimated from each source
      tout.snapshot.tomo.power(bin_idx,1:length(surf_power),line_idx)=surf_power;
      
      
      if cfg.tomo_en
        % Collect source DOAs for the range bin and along-track position
        % Allow tout.(m).tomo.surf_theta to grow in 2nd dimension
        Nsrc_new    = length(surf_doas);
        Nsrc_old    = size(tout.snapshot.tomo.surf_theta,2);
        Ngrow       = Nsrc_new - Nsrc_old;
        
        if Nsrc_old < Nsrc_new
          Ngrow       = Nsrc_new - Nsrc_old;
          tout.snapshot.tomo.surf_theta = cat(2,tout.snapshot.tomo.surf_theta,nan(size(tout.snapshot.tomo.surf_theta,1),Ngrow,size(tout.snapshot.tomo.surf_theta,3)));
        end
        tout.snapshot.tomo.surf_theta(bin_idx,1:length(surf_doas),line_idx) = surf_doas;
        
        surf_mask   = surf_ice_mask(bin_idx,:);
        Nsrc_new    = length(surf_mask);
        Nsrc_old    = size(tout.snapshot.tomo.surf_ice_mask,2);
        Ngrow       = Nsrc_new - Nsrc_old;
        
        if Nsrc_old < Nsrc_new
          Ngrow       = Nsrc_new - Nsrc_old;
          tout.snapshot.tomo.surf_ice_mask = cat(2,tout.snapshot.tomo.surf_ice_mask,nan(size(tout.snapshot.tomo.surf_ice_mask,1),Ngrow,size(tout.snapshot.tomo.surf_ice_mask,3)));
        end
        tout.snapshot.tomo.surf_ice_mask(bin_idx,1:length(surf_mask),line_idx) = surf_mask;
      end

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
  
  %% Store outputs
  
  for idx = 1:length(cfg.method)
    m = array_proc_method_str(cfg.method(idx));
    % Reformat output for this range-line into a single slice of a 3D echogram
    if cfg.method(idx) < DOA_METHOD_THRESHOLD
      % Beamforming Methods
      Sarray.(m) = Sarray.(m).';
      % Find bin/DOA with maximum value
      % The echogram fields .img and .theta are filled with this value.
      [tout.(m).img(:,line_idx) tout.(m).theta(:,line_idx)] = max(Sarray.(m)(:,dout_val_sv_idxs),[],2);
      tout.(m).theta(:,line_idx) = theta(dout_val_sv_idxs(tout.(m).theta(:,line_idx)));
      % Reformat output to store full 3-D image (if enabled)
      if cfg.tomo_en
        tout.(m).tomo.img(:,:,line_idx) = Sarray.(m);
      end
    elseif cfg.method(idx) < SNAPSHOT_METHOD_THRESHOLD
      % DOA Methods
      
      if 1
        % Mode 1: The value of the largest source in theta_rng in the Nsrc dimension
        dout_img = tout.(m).tomo.img .* ...
          (tout.(m).tomo.theta >= cfg.theta_rng(1) & tout.(m).tomo.theta <= cfg.theta_rng(2));
        [tout.(m).img(:,line_idx) max_img_idx] = max(dout_img(:,:,line_idx),[],2);
        tout.(m).theta(:,line_idx) = tout.(m).tomo.theta(max_img_idx);
        %         [tout.(m).img(:,line_idx) tout.(m).theta(:,line_idx)] = max(dout_img(:,:,line_idx),[],2);
        %         tout.(m).theta(:,line_idx) = tout.(m).tomo.theta(tout.(m).theta(:,line_idx));
      else
        % Mode 2: the value of the source closest to the center of theta_rng in the Nsrc dimension
        dout_img = tout.(m).tomo.theta .* ...
          (tout.(m).tomo.theta >= cfg.theta_rng(1) & tout.(m).tomo.theta <= cfg.theta_rng(2));
        [tout.(m).theta(:,line_idx) nearest_theta_idx] = min(abs(dout_img(:,:,line_idx)),[],2);
        tout.(m).img(:,line_idx) = tout.(m).tomo.img(nearest_theta_idx);
      end
    end
  end
  
  if 0 && (~mod(line_idx,20) || line_idx == Nx_out || line_idx == 1)
    %% DEBUG outputs
    % change 0&& to 1&& on line above to run it
    m = array_proc_method_str(cfg.method(1));
    if cfg.method < DOA_METHOD_THRESHOLD
      figure(1); clf;
      imagesc(10*log10(tout.(m).img));
      keyboard;
      
    else
      figure(1); clf;
      plot(tout.(m).tomo.theta(:,:,line_idx)*180/pi,'.')
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
      keyboard
    end
  end
  for idx = 1:length(cfg.method)
    if cfg.method(idx) < DOA_METHOD_THRESHOLD
      m = array_proc_method_str(cfg.method(idx));
      Sarray.(m) = reshape(Sarray.(m),cfg.Nsv,Nt_out);
    end
  end
  
  if 0 && any(cfg.method(cfg.method == MUSIC_METHOD)) && any(cfg.method(cfg.method == MLE_METHOD))
    % Debug: plot MUSIC and MLE results
    figure(999);clf;
    uniform_theta = linspace(-60,60,501);
    img_plot = interp1(tout.music.tomo.theta*180/pi,tout.music.tomo.img(:,:,line_idx).',uniform_theta).';
    imagesc(uniform_theta,1:size(tout.music.tomo.img,1),10*log10(abs(img_plot)))
    hold on
    plot(tout.mle.tomo.theta(:,:,line_idx)*180/pi,1:size(tout.mle.tomo.theta,1),'-y','LineWidth',1.5)
    %     plot(tout.mle.tomo.theta(:,1,line_idx)*180/pi,1:size(tout.mle.tomo.theta,1),'*y')
    %     plot(tout.mle.tomo.theta(:,2,line_idx)*180/pi,1:size(tout.mle.tomo.theta,1),'*y')
    set(gca,'YDir','reverse')
    xlabel('Est. DOA (degrees)')
    ylabel('Range-bin')
    %     title(sprintf('MUSIC beamformer vs MLE estimator'))
    title(sprintf('MUSIC beamformer vs MLE estimator (No MOE)'))
    legend('MLE: DOA 1','MLE: DOA 2')
  end
end
% Copy temporary outputs for first method to dout
dout = tout.(array_proc_method_str(cfg.method(1)));

% Save: for simulation
if cfg.moe_simulator_en
  cfg.theta = theta;
  
  if isfield(cfg,'testing') && ~isempty(cfg.testing) && cfg.testing ...
      && isfield(cfg,'optimal_test') && ~isempty(cfg.optimal_test) && cfg.optimal_test
    % Already saved
    %       dout.moe = dout.moe;
  else
    dout.moe.NT.Nest    = -999*ones(bin_idx,line_idx);
    dout.moe.AIC.Nest   = -999*ones(bin_idx,line_idx);
    dout.moe.HQ.Nest    = -999*ones(bin_idx,line_idx);
    dout.moe.MDL.Nest   = -999*ones(bin_idx,line_idx);
    dout.moe.AICc.Nest  = -999*ones(bin_idx,line_idx);
    dout.moe.KICvc.Nest = -999*ones(bin_idx,line_idx);
    dout.moe.WIC.Nest   = -999*ones(bin_idx,line_idx);
  end
  dout.moe.optimal = dout.moe;
  
  if isfield(cfg,'testing') && ~isempty(cfg.testing) && cfg.testing ...
      && isfield(cfg,'suboptimal_test') && ~isempty(cfg.suboptimal_test) && cfg.suboptimal_test
    % Already saved
    %       dout.model_order_results_suboptimal = model_order_results_suboptimal;
  else
    model_order_results_suboptimal.NT.Nest    = -999*ones(bin_idx,line_idx);
    model_order_results_suboptimal.AIC.Nest   = -999*ones(bin_idx,line_idx);
    model_order_results_suboptimal.HQ.Nest    = -999*ones(bin_idx,line_idx);
    model_order_results_suboptimal.MDL.Nest   = -999*ones(bin_idx,line_idx);
    model_order_results_suboptimal.AICc.Nest  = -999*ones(bin_idx,line_idx);
    model_order_results_suboptimal.KICvc.Nest = -999*ones(bin_idx,line_idx);
    model_order_results_suboptimal.WIC.Nest   = -999*ones(bin_idx,line_idx);
  end
  dout.moe.suboptimal = model_order_results_suboptimal;
end

if 0
  % Debug plots for S-MAP
  figure
  plot(tout.mle.tomo.theta(:,1,line_idx)*180/pi,1:size(tout.mle.tomo.theta(:,1,line_idx),1),'-*b')
  hold on
  plot(tout.mle.tomo.theta(:,2,line_idx)*180/pi,1:size(tout.mle.tomo.theta(:,2,line_idx),1),'-*r')
  set(gca,'YDir','reverse')
  grid on
end

if 0
  % Degug (for S-MAP only): plot lower/upper bound and left/rignt mean
  figure();clf;
  uniform_theta = linspace(cfg.doa_constraints(1).src_limits(1),cfg.doa_constraints(1).src_limits(2),501);
  img_plot = interp1(tout.music.tomo.theta*180/pi,tout.music.tomo.img(:,:,line_idx).',uniform_theta).';
  imagesc(uniform_theta,1:size(tout.music.tomo.img,1),10*log10(abs(img_plot)))
  hold on
  
  theta_plot = tout.mle.tomo.theta(:,:,line_idx)*180/pi;
  
  first_NoNaN_rbin_l = find(~isnan(theta_plot(:,1)),1);
  first_NoNaN_rbin_r = find(~isnan(theta_plot(:,2)),1);
  first_NoNaN_rbin = min(first_NoNaN_rbin_l,first_NoNaN_rbin_r);
  
  last_NoNaN_rbin_l = find(~isnan(theta_plot(:,1)),1,'last');
  last_NoNaN_rbin_r = find(~isnan(theta_plot(:,2)),1,'last');
  last_NoNaN_rbin = max(last_NoNaN_rbin_l,last_NoNaN_rbin_r);
  
  % h1 = plot(actual_doa,1:size(actual_doa,1),'+b','LineWidth',n);
  
  % mean_l(isnan(theta_plot(:,1))) = NaN;
  % mean_r(isnan(theta_plot(:,2))) = NaN;
  %
  % bounds_l((isnan(theta_plot(:,1))),1) = NaN;
  % bounds_l((isnan(theta_plot(:,1))),2) = NaN;
  % bounds_r((isnan(theta_plot(:,2))),1) = NaN;
  % bounds_r((isnan(theta_plot(:,2))),2) = NaN;
  
  h3 = plot([mean_l mean_r],1:length(mean_l),'--r','LineWidth',1.5);
  h4 = plot([bounds_l(:,1) bounds_r(:,1)],1:size(bounds_l,1),'-.m','LineWidth',1.5);
  h5 = plot([bounds_l(:,2) bounds_r(:,2)],1:size(bounds_l,1),'-.g','LineWidth',1.5);
  h2 = plot(theta_plot,1:size(theta_plot,1),'-y','LineWidth',1.5);
  
  xlim([cfg.doa_constraints(1).src_limits(1)  cfg.doa_constraints(1).src_limits(2)])
  ylim([first_NoNaN_rbin last_NoNaN_rbin] + [-5 +5])
  % ylim([first_NoNaN_rbin-5 3105])
  % ylim([first_NoNaN_rbin-5 1970])
  ylim([500 800])
  % set(gca,'YDir','reverse')
  xlabel('Elevation angle (deg)')
  ylabel('Range-bin')
  % desc = '+/-5 deg';
  % title(sprintf('SMAP-Opt. MOE: Slice# %d -- %s',line_idx,desc))
  title({'SMAP-Opt. MOE: Ice-top - Gaussian prior - Geometry based bounds'})
  % title('MLE-Opt. MOE: Ice-top')
  
  legend([h2(1) h3(1) h4(1) h5(1)],{'Est. DOA','Mean DOA','Lower bound','Upper bound'},'Location','south')
  
  % out_fn_name = 'SMAP_OptMOE_IceBottom_Uniform_Continuous3DeltaThetaBounds_BadExample'; % Figure name
  % out_fn_name = 'SMAP_OptMOE_IceTop_Gaussian_GeometryBasedBounds'; % Figure name
  % out_fn_name = 'SMAP_OptMOE_Gaussian_IceBottom_WideBounds_WideStdev'; % Figure name
  out_fn_name = 'SMAP_OptMOE_Uniform_IceBottom_WideBounds'; % Figure name
  
  out_fn_dir = '/users/mohanad/IceSheetProject/MLE tracker work/Sequential MLE/Results/testing bounds_S-MAP/tracked slices-GeometryBased';
  out_fn = fullfile(out_fn_dir,out_fn_name);
  % saveas(999,[out_fn '.fig']);
  
  saveas(8,[out_fn '.fig']);
  
  % title('Geometry-based: \pm 10^\circ, kk\_st\_std=1, kk\_end\_std=1/2 nn=15')
end

if 0
  % Plot uniform pdf: example for slice 520 ice-bottom
  % Gaussian
  %   mu = [-8.6940    8.2419]*pi/180;
  %   sigma = [3.2998    3.5102]*pi/180;
  %   lb = [-15.2936    6.2552]*pi/180;
  %   ub = [-6.8524   15.2624]*pi/180;
  %
  %   % Uniform
  %   mu = [-11.62  11.35]*pi/180;
  %   sigma = [90  90]*pi/180;
  %   lb = [-14.4  10.07]*pi/180;
  %   ub = [-10.39  14.13]*pi/180;
  %
  %   doa_i = 2;
  %   theta_test = linspace(lb(doa_i),ub(doa_i),101);
  % %   theta_test = linspace(-pi/2,pi/2,101);
  %
  %   [vv,i] = min(abs(theta_test-mu(doa_i)));
  %
  %   f_Gaussian = normpdf(theta_test,mu(doa_i),sigma(doa_i));
  % %   f_Gaussian = 1/sqrt(2*pi*sigma(doa_i)^2) * exp( -1/2*((theta_test - mu(doa_i)).^2)./(sigma(doa_i)^2) );
  %   f_Gaussian([1 end]) = 0;
  %
  %   figure;
  %   plot([theta_test(1)-1*pi/180 theta_test theta_test(end)+1*pi/180]*180/pi,[0 f_Gaussian 0],'-b','LineWidth',1.5)
  %   hold on
  %   plot(mu(doa_i)*180/pi,f_Gaussian(i),'xr','LineWidth',2,'LineWidth',1.5)
  % %   xlim([theta_test(1) theta_test(end)]*180/pi)
  %
  %   grid on
  %   xlabel('Elevation angle (deg)')
  %   ylabel('f_{Gaussian}')
  %   title('Ice-bottom - rbin#520 - Gaussian prior - Both DOAs')
end
