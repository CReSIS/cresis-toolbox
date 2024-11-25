function collate_snapshots(param,param_override)
% collate_snapshots(param,param_override)
%
% 
% THIS FUNCTION CULLS SNAPSHOTS CONTAINING SINGLE TARGETS - FIRST STEP OF
% LUT GENERATION
%
% Function that takes snapshots, pulls out calibration pixels and stores
% with corresponding surface ARRIVAL ANGLES (not surface intersection
% angles, i.e. roll-corrected).  Currently culls by number of targets and
% signal to clutter ratio.
%
% TO DO:  
%   1. ADD FUNCTIONALITY TO STORE MASK IN A MEANINGFULL WAY FOR BROWSING
%       IN THE PICKER,
%   2. Future capability may allow for MOE
%   3. Does it make more sense to store the outputs by rx?
%
% param: struct with processing parameters
%         -- OR --
%         function handle to script with processing parameters
% param_override: parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% Example:
%  See run_collate_snapshots.m for how to run this function directly.
%  This function may be called from the run_master.m script using the
%  param spreadsheet and the cmd.generic column.
%
% Authors: Theresa Moore
%
% See also: collate_snapshots.m, run_collate_snapshots.m, array_proc.m
%
%% General Setup
% =====================================================================

param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input checks
% =====================================================================
if ~isfield(param,mfilename) || isempty(param.(mfilename))
  param.(mfilename) = [];
end

if ~isfield(param.collate_snapshots,'scr_threshold') || isempty(param.collate_snapshots.scr_threshold)
  param.collate_snapshots.scr_threshold = 15;
end

if ~isfield(param.collate_snapshots,'out_path') || isempty(param.collate_snapshots.out_path)
  param.collate_snapshots.out_path = 'collate_snapshots';
end

if ~isfield(param.collate_snapshots,'in_path') || isempty(param.collate_snapshots.in_path)
  param.collate_snapshots.in_path = 'snapshot';
end

if ~isfield(param.collate_snapshots,'layer_params') || isempty(param.collate_snapshots.layer_params)
  param.collate_snapshots.layer_params.name = 'surface';
  param.collate_snapshots.layer_params.source = 'layerdata';
  param.collate_snapshots.layer_params.layer_path = 'layer';
end

if ~isfield(param.collate_snapshots.layer_params,'layer_path') || isempty(param.collate_snapshots.layer_params.layer_path)
  param.collate_snapshots.layer_params.layer_path = 'layer';
end

if ~isfield(param.collate_snapshots,'remove_multiple') || isempty(param.collate_snapshots.remove_multiple)
  param.collate_snapshots.remove_multiple = true;
  param.collate_snapshots.multiple_guard_bins = 2;
end

if ~isfield(param.collate_snapshots,'multiple_guard_bins') || isempty(param.collate_snapshots.multiple_guard_bins)
  param.collate_snapshots.multiple_guard_bins = 2;
end

if ~isfield(param.collate_snapshots,'img_list')
  param.collate_snapshots.img_list = [];
end

if ~isfield(param.collate_snapshots,'plot_enable') || isempty(param.collate_snapshots.plot_enable)
  param.collate_snapshots.dtheta = 1;
end

if ~isfield(param.collate_snapshots,'debug') || isempty(param.collate_snapshots.debug)
  param.collate_snapshots.debug = 0;
end

if ~isfield(param.collate_snapshots,'same_doa_guard') || isempty(param.collate_snapshots.same_doa_guard)
  param.collate_snapshots.same_doa_guard = 5; % degrees
end

%% collate_snapshots: load support files and loop on frames
% Load frames file
frames = frames_load(param);

param.cmd.frms = frames_param_cmd_frms(param,frames);

for frm_idx = 1:length(param.cmd.frms)
  frm = param.cmd.frms(frm_idx);
  %   fprintf('Collate snapshots %s_%03d \n', param.day_seg,frm)
  fprintf('\n\n');
  fprintf('collate snapshots:  %s_%03d (%s)\n', param.day_seg,frm, datestr(now));
  fprintf('---------------------------------------------------------------------\n');
  
  % Building input and output directories for the frame
  snp_dir = ct_filename_out(param,param.collate_snapshots.in_path);
  sv_offset_dir = ct_filename_out(param,param.collate_snapshots.out_path);
  
  % Check for existence of layerdata
  layer_fn = fullfile(ct_filename_out(param,param.collate_snapshots.layer_params.layer_path,''),sprintf('Data_%s_%03d.mat', param.day_seg,frm));
  
  % If surface layer doesn't exist, disable the flag to remove the multiple
  if ~(exist(layer_fn,'file') == 2)
    param.collate_snapshots.remove_multiple = false;
    fprintf('Layer file does not exist: %s,\n', layer_fn);
    fprintf('Surface multiple not removed\n');
    layer = [];
  else
    % Load in surface
    surf_param = param.collate_snapshots.layer_params;
    fprintf('Loading surface:  %s (%s)\n', layer_fn, datestr(now));
    layer = opsLoadLayers(param,surf_param);
  end
  
  
  %% collate_snapthost: loop over images in the list
  for img_idx = 1:length(param.collate_snapshots.img_list)
    % Initialize variables
    Tomo = [];
    Time = [];
    Elevation = [];
    GPS_time = [];
    Heading = [];
    Latitude = [];
    Longitude = [];
    Roll = [];
    Heading =[];
    Latitude =[];
    Longitude =[];
    Pitch =[];
    Roll=[];
    param_array =[];
    param_records=[];
    param_sar = [];
    file_version=[];
    
    
    % Building the input filename
    img= param.collate_snapshots.img_list(img_idx);
    file = sprintf('Data_img_%02d_%s_%03d.mat',img,param.day_seg,frm);
    fn = fullfile(snp_dir,file);
    
    % Ensure file exists
    if exist(fn,'file') == 2
      fprintf('Loading snapshot file:  %s (%s)\n', fn, datestr(now));
      load(fn,'Tomo','Time','Elevation','GPS_time','Heading','Latitude','Longitude','Pitch','Roll','param_array','param_records','param_sar','file_version');
      [Nt, Nc, Nx]  = size(Tomo.img);
      
      %%  collate_snapshots: reformat raw snapshot outputs
      Tomo.img = permute(Tomo.img,[2 1 3]);
      Tomo.power = permute(Tomo.power,[2 1 3]);
      Tomo.surf_theta = permute(Tomo.surf_theta,[2 1 3]);
      Tomo.surf_ice_mask = permute(Tomo.surf_ice_mask,[2 1 3]);
      Tomo.two_src_mask = squeeze(sum(~isnan(Tomo.surf_theta),1))==2;
      Tomo.one_src_mask = squeeze(sum(~isnan(Tomo.surf_theta),1))==1;      
      Tomo.surf_ice_mask = squeeze(any(Tomo.surf_ice_mask,1));
      Tomo.surf_ice_mask = cumsum(Tomo.surf_ice_mask,1) >= 1;
      Tomo.surf_multiple_mask = true(size(Tomo.surf_ice_mask));
      Tomo.Nsrc = squeeze(sum(~isnan(Tomo.surf_theta)));
      Tomo.edge_mask = false(size(Tomo.Nsrc));
      %% collate_snapshots: create pixel culling 
      
      % Surface multiple mask
      if ~isempty(layer)
        surface = interp_finite(interp1(layer.gps_time,layer.twtt,GPS_time));
        multiple = 2*surface;
        rlines = 1:Nx;
        bad_rlines = rlines(multiple > Time(end));
        good_rlines = rlines(multiple < Time(end));
%         Tomo.surf_multiple_mask(:,multiple < Time(end)) = false;
        for rline_idx = 1:length(good_rlines)
          rline = good_rlines(rline_idx);
%           surf_bin = round(interp_finite(interp1(Time,1:Nt,surface(rline_idx))));
%           surf_bins = surf_bin + [-param.collate_snapshots.multiple_guard_bins:param.collate_snapshots.multiple_guard_bins];
          multiple_bin = round(interp_finite(interp1(Time,1:Nt,multiple(rline))));
          multiple_bins = multiple_bin + [-param.collate_snapshots.multiple_guard_bins:param.collate_snapshots.multiple_guard_bins];
          if min(multiple_bins) > 1 & max(multiple_bins) < Nt
            Tomo.surf_multiple_mask(multiple_bins,rline) = false;
          end
% 
%           if min(surf_bins) > 1 & max(surf_bins) < Nt
%             Tomo.surf_multiple_mask(surf_bins,rline_idx) = false;
%           end
        end
      end
      
      % Assign nans to -inf
      Tomo.power(isnan(Tomo.power)) = -inf;
      
      % Sort powers in descending order
      [Tomo.power,sort_idxs] = sort(Tomo.power,1,'descend');
%       Tomo.power = 10*log10(abs(Tomo.power));

      % Convert surface angle to DOA
      Tomo.surf_doa = bsxfun(@minus,Tomo.surf_theta,permute(Roll*180/pi,[1 3 2]));
      
      % Maximum number of sources
      Ndoa_max = size(Tomo.surf_doa,1);
      
      % Sort indexes for the sources
      doa_sort_idxs = bsxfun(@plus,bsxfun(@plus,sort_idxs,Ndoa_max*(0:Nt-1)),permute(Ndoa_max*Nt*(0:Nx-1),[1 3 2]));
      
      % Source incidence angles of clutter and calibration angles      
      Tomo.surf_theta = Tomo.surf_theta(doa_sort_idxs);      
      Tomo.surf_doa   = Tomo.surf_doa(doa_sort_idxs);
      
      Tomo.backlobe_mask = squeeze(sum(abs(Tomo.surf_doa) > 90,1) >=1);

      % Same doa mask
      Tomo.same_doa_mask = squeeze(abs(Tomo.surf_doa(1,:,:)-Tomo.surf_doa(2,:,:)) < param.collate_snapshots.same_doa_guard);
      
      % Fast time mask
      Tpd = param.radar.wfs(img).Tpd;
      Tomo.edge_mask = repmat(Time >= Time(end) - Tpd/2,1,Nx);
  
      % Final culling mask      
%       Tomo.mask = Tomo.two_src_mask & ~Tomo.surf_ice_mask & (Tomo.power_mask | Tomo.same_doa_mask) & Tomo.surf_multiple_mask;
%       Tomo.mask = Tomo.two_src_mask & ~Tomo.surf_ice_mask & Tomo.power_mask & ~Tomo.same_doa_mask & Tomo.surf_multiple_mask;
%       Tomo.mask = (Tomo.one_src_mask | Tomo.two_src_mask) & ~Tomo.surf_ice_mask &  ~Tomo.same_doa_mask & Tomo.surf_multiple_mask & ~Tomo.backlobe_mask;
            Tomo.mask = (Tomo.one_src_mask | Tomo.two_src_mask) & ~Tomo.surf_ice_mask &  ~Tomo.same_doa_mask & Tomo.surf_multiple_mask & ~Tomo.edge_mask;
      % If only one source (not likely) store nans
      if Ndoa_max == 1         
        Tomo.power(2,:,:) = nan(size(Tomo.mask));
        Tomo.surf_doa(2,:,:) = nan(size(Tomo.mask));
        Tomo.surf_theta(2,:,:) = nan(size(Tomo.mask));
      end
      
      Nsrc_max = min([2 Ndoa_max]);
           
      %% colate_snapshots: create simplified output
      
      % Create a list of the rxs
      wf = param_array.array_proc.imgs{1}(1,1);
      adc_list = param_array.array_proc.imgs{1}(:,2);
      rx_list = param.radar.wfs(wf).rx_paths(adc_list);
      
     
      % Pick out the snapshots, power, surface incidence angles, cal doas,
      % power of good pixels
      snapshots.sv_list = Tomo.img(:,Tomo.mask);     
      snapshots.surf_doas = Tomo.surf_doa(1:Nsrc_max,Tomo.mask);
      snapshots.surf_thetas = Tomo.surf_theta(1:Nsrc_max,Tomo.mask);
      snapshots.power = Tomo.power(1:Nsrc_max,Tomo.mask);   
      snapshots.Nsrc = Tomo.Nsrc(Tomo.mask).';
      
      % Pick out gps time and twtt of the culled pixels
      twtt_matrix     = repmat(Time,1,Nx);
      gps_time_matrix = repmat(GPS_time,Nt,1);
      elev_matrix     = repmat(Elevation,Nt,1);
      pitch_matrix    = repmat(Pitch,Nt,1);
      heading_matrix  = repmat(Heading,Nt,1);
      roll_matrix     = repmat(Roll,Nt,1);
      lat_matrix      = repmat(Latitude,Nt,1);
      lon_matrix      = repmat(Longitude,Nt,1);
      
      snapshots.twtt = twtt_matrix(Tomo.mask);
      snapshots.gps_time = gps_time_matrix(Tomo.mask);
      snapshots.elev = elev_matrix(Tomo.mask);
      snapshots.lat = lat_matrix(Tomo.mask);
      snapshots.lon = lon_matrix(Tomo.mask);
      snapshots.pitch = pitch_matrix(Tomo.mask);
      snapshots.heading = heading_matrix(Tomo.mask);
      snapshots.roll = roll_matrix(Tomo.mask);
     
      snapshots.twtt = snapshots.twtt(:).';
      snapshots.gps_time = snapshots.gps_time(:).';
      snapshots.elev = snapshots.elev(:).';
      snapshots.lat = snapshots.lat(:).';
      snapshots.lon = snapshots.lon(:).';
      snapshots.pitch = snapshots.pitch(:).';
      snapshots.heading = snapshots.heading(:).';
      snapshots.roll = snapshots.roll(:).';
      snapshots.rx_list = rx_list;
      
      snapshots.param_collate_snapshots = param.collate_snapshots;
      snapshots.param_array = param_array;
      snapshots.param_sar = param_sar;
      snapshots.param_records = param.records;
      snapshots.file_version = file_version;
      snapshots.file_type = 'snapshots';
      
      %% Save the result
      % =====================================================================
      out_fn_dir = ct_filename_out(param,param.collate_snapshots.out_path,'');
      if ~isdir(out_fn_dir)
        mkdir(out_fn_dir)
      end
      out_fn = fullfile(out_fn_dir,sprintf('snapshots_simp_img_%02d_%s_%03d.mat', img, param.day_seg, frm));
      fprintf('Saving %s (%s)\n', out_fn, datestr(now));
      ct_save(out_fn,'-struct','snapshots');
    end
  end
end

     % For more than one source, threshold highestst
%       if Ndoa_max > 1
%         % Threshold
%         Tomo.power_mask = squeeze(Tomo.power(1,:,:) > Tomo.power(2,:,:) + param.collate_snapshots.scr_threshold);
% %         Tomo.scr = nan(size(Tomo.power_mask));
% %         Tomo.scr = squeeze(Tomo.power(1,:,:) - Tomo.power(2,:,:));
%       else
%         Tomo.power_mask = true(size(squeeze(Tomo.power)));
% %         Tomo.scr = nan(size(Tomo.power_mask));
%       end      


