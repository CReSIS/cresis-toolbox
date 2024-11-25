function [phase_center] = lever_arm(param, tx_weights, rxchannel)
% [phase_center] = lever_arm(param, tx_weights, rxchannel)
%
% Returns lever arm position for antenna phase center. See remarks below
% to understand the coordinate system for output "phase_center".
%
% =========================================================================
% INPUTS:
%
% param: parameter struct
%
%  .season_name: string containing the season name (e.g. 2011_Greenland_TO)
%
%  .radar_name: string containing the radar name (e.g. snow2)
%
%  .gps_source: string from GPS file using format SOURCE-VERSION (e.g.
%  ATM-final_20120303). The SOURCE portion is used to determine which lever
%  arm set to use for a particular dataset since some field seasons have
%  more than one GPS source.
%
% tx_weights: transmit amplitude weightings (from the radar worksheet of
% the parameter spreadsheet) These are amplitude weights, not power
% weights.
%
% rxchannel: receive channel to return phase_center for (scalar, positive
% integer) Setting rxchannel to 0, causes the "reference" position to be
% returned. This is usually the position of one of the center receive
% elements and equal weights on all transmitters.
%
% =========================================================================
% OUTPUTS:
%
% phase_center: lever arm to each phase center specified by tx_weights and
% rxchannel. See remarks below to understand the coordinate system for
% output "phase_center".
%
%
% =========================================================================
% REMARKS:
%
% 1). Lever arm refers to a (3 x 1) vector that expresses the position of
%     each phase center relative to the position that the GPS trajectory
%     was processed to (this is often the GPS antenna or IMU measurement
%     center).  The basis for the vector is the coordinate system of the
%     plane's body (Xb, Yb, Zb).  This is a righthanded, orthogonal system
%     that agrees with aerospace convention.  +Xb points from the plane's
%     center of gravity towards its nose.  +Yb points from the plane's
%     center of gravity along the right wing.  +Zb points from the plane's
%     center of gravity down towards the Earth's surface (i.e. increasing
%     Zb points downwards!).
%
% 2). The lever arm of the Nth receive channel is defined using the
%     following syntax:
%
%     LArx_N = [Xb_N; Yb_N; Zb_N]
%
% 3). There are two ways that the lever arm gets entered usually. The main
%     point is that LArx and LAtx need to contain the lever arms to each
%     of the receive and transmit antenna phase centers.  Each of these
%     matrices are 3xN where N is the number of antenna phase centers. N
%     can be different for LArx and LAtx.  The information that is passed
%     in is the GPS source, radar name, and the season name. This should
%     be enough to identify a unique lever arm to specify in this function.
%
%     Commonly, the GPS trajectory position is specified:
%       gps.x = 0;
%       gps.y = 0;
%       gps.z = 0;
%     And the LArx and LAtx are defined relative to the gps location as in
%       LArx = LArx_offset - gps;
%     This is not necessary, but is the convention because sometimes there
%     are multiple GPS sources used where gps.[xyz] are not all zero and
%     this makes the code more modular.
%     You could just specify LArx directly without defining gps.
%       LArx = LArx_offset;
% 
% ========================================================================
%
% Author: Theresa Stumpf, John Paden

if strcmpi(param.gps_source,'NA')
  error('Cannot call lever arm function with gps source of NA (no GPS data). Set param.radar.lever_arm to empty.');
end

LAtx = [];
LArx = [];
gps = [];

% =========================================================================
%% GPS Positions
% =========================================================================
gps_source = param.gps_source(1:find(param.gps_source == '-',1)-1);
radar_name = ct_output_dir(param.radar_name);

% For the full simulator, remove 'sim' at the end($) of param.season_name
param.season_name = regexprep(param.season_name,'sim$','','ignorecase');

if any(strcmpi(param.season_name,{'2022_Greenland_X6'}))
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if any(strcmpi(param.season_name,{'2022_Greenland_Vapor'}))
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if any(strcmpi(param.season_name,{'2021_Arctic_Vanilla'}))
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if any(strcmpi(param.season_name,{'2019_SouthDakota_N1KU','2020_SouthDakota_N1KU'}))
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if any(strcmpi(param.season_name,{'2019_Arctic_GV','2019_Antarctica_GV'})) %...
%     && any(strcmpi(gps_source,{'nmea'})) && any(strcmpi(gps_source,{'atm-field'}))
%   warning('ACTUAL LEVER ARM ACTUAL LEVER ARM NEEDS TO BE DETERMINED');
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2018_Antarctica_Ground') && any(strcmpi(gps_source,{'arena','trimble'})))
  % Platform: Ground based tracked vehicles, GPS antenna on top of tracked
  % vehicle
  %
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2019_Antarctica_Ground') && any(strcmpi(gps_source,{'arena','cresis'})))
  % Platform: Ground based sled
  %
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2022_Antarctica_BaslerMKB') && any(strcmpi(gps_source,{'arena','cresis','novatelraw','utig'})))
  % Platform: Airborne Radar Kenn Borek Air Basler call sign MKB (COLDEX 1, COLDEX 2, UTIG)
  %
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if any(strcmpi(param.season_name,{'2022_Antarctica_Ground','2023_Greenland_Ground'})) && any(strcmpi(gps_source,{'arena','cresis'}))
  % Platform: Ground based sled (EAGER 1, EAGER 2)
  %
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2022_Antarctica_GroundGHOST') && any(strcmpi(gps_source,{'arena','cresis'})))
  % Platform: Ground based sled (GHOST 1, GHOST 2)
  %
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if any(strcmpi(param.season_name,{'2019_Greenland_TO'})) %...
%     && any(strcmpi(gps_source,{'nmea'}))
%   warning('ACTUAL LEVER ARM ACTUAL LEVER ARM NEEDS TO BE DETERMINED');
% The positions of the rx and tx antennas of ku-band and ka-band
% alitimeters were measured relative to the rear GPS antenna
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if any(strcmpi(param.season_name,{'2018_Alaska_SO','2021_Alaska_SO'})) ...
    && any(strcmpi(gps_source,{'nmea','lidar'}))
  % The snow radar shared the same GPS antenna with the lidar of the univ. of Fairbanks
  % Emily measured the positions of the snow radar rx and tx antennas relative to the GPS antenna
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2017_Antarctica_TObas') && strcmpi(gps_source,'bas'))
  % Paden: Just an estimate
  %warning('Correct lever arms need to be entered.');
  gps.x = 0;
  gps.y = 0;
  gps.z = 1300;
end

if (any(strcmpi(param.season_name,{'2018_Antarctica_TObas'})) && any(strcmpi(gps_source,{'arena','bas'})))
  % 2018 Antarctica TObas (Jan-Feb 2019) GPS data are processed to the IMAR
  % gravimeter. The origin that we use here is the aft GPS antenna above
  % the radar system.
  %
  % From Tom Jordan at BAS:
  % My best solution is that the IMAR solution to the GPS above the radar is as follows (all in m):
  % X (positive forward) -2.9369
  % Y (Positive port)  0.1116
  % Z (Positive up) 1.4762
  %
  % Aircraft: British Antarctic Survey (BAS) VP-FBL
  %
  % Carl Robinson at BAS Aug 2018: Though we do have measurements for
  % various fits back to lidar and other sensors it will be easiest to
  % measure to antenna when installed.  Also we have a full point cloud
  % model of the exterior of the Twin Otter that shows the antennas.  We
  % have four antennas to choose from 3 around the wing area on the cabin
  % and one slightly further back over the centre of the camera bay we can
  % choose one to measure off. All the antennas have their TNC connectors
  % accessible in the cabin so can do a direct measurement to the chosen
  % one and use the datasheet to reference to the antenna centre. (Antenna
  % datasheet attached for reference) We will survey all the sensors (2 x
  % IMU, Lidar, radar antennas, GPS antenna) when we install at Rothera
  % also. We normally use the one over the camera bay as that is on the
  % centre line of the aircraft, the other GPS antennas are slightly offset
  % to avoid ribs, cables and other aircraft structure. Only the one over
  % the camera bay is on the centerline.
  %
  % GPS physical location leverarm measurements measured Sept 5, 2018
  % 	3+5/8" from back of antenna box
  % 	9+15/16" from right/starboard side of lid (used edge of lid)
  % 	64+1/16" below to the lid of the antenna
  % 	All measurements relative to the bottom center of the antenna connector
  % 	GPS antenna is not on center line (it is offset to the port side slightly)
  %     1.0625" port of center line
  %     1.25" aft of second to last rib in main cabin
  %     Rib is at 308" FS (although this may be wrong)
  %
  % 

  gps.x = 2.9369; % Gravimeter was in front of GPS antenna
  gps.y = 0.1116; % Gravimeter was on the right side of the plane/GPS
  gps.z = 1.4762; % Gravimeter was below (down is positive-z) the GPS
end

if (any(strcmpi(param.season_name,{'2019_Antarctica_TObas'})) && any(strcmpi(gps_source,{'bas','bas_imu_to_gps'})))
  % 2019 Antarctica TObas (Dec 2019-Jan 2020) GPS data are processed to the
  % IMAR gravimeter for some flights and forward GPS antenna for some
  % flights. This handles the data that are stored relative to the IMAR
  % gravimeter.
  %
  % From Tom Jordan at BAS.

  % T06 flight (before merging with GNSS only data), T07 flight
  gps.x = -0.0538; % Gravimeter was just behind the antenna
  gps.y = 0.349; % Gravimeter was on the right side of the plane/GPS
  gps.z = 1.4803; % Gravimeter was below (down is positive-z) the GPS
end

if (any(strcmpi(param.season_name,{'2019_Antarctica_TObas'})) && any(strcmpi(gps_source,{'arena','bas_gnss'})))
  % 2019 Antarctica TObas (Dec 2019-Jan 2020) GPS data are processed to the
  % IMAR gravimeter for some flights and forward GPS antenna for some
  % flights. This handles the data that are stored relative to the forward
  % GPS antenna.
  %
  % From Tom Jordan at BAS.

  % End of T06 flight when IMU failed, all January flights
  gps.x = 0; % Forward GPS antenna
  gps.y = 0; % Forward GPS antenna
  gps.z = 0; % Forward GPS antenna
end

if (any(strcmpi(param.season_name,{'2022_Greenland_Ground'})) && any(strcmpi(gps_source,{'arena','cresis'})))
  % GPS antenna is mounted almost on the radar antenna phase center
  % Need to update exactly what the vertical offset is.

  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2016_Greenland_TOdtu') && strcmpi(gps_source,'dtu'))
  % ===========================================================================
  % All antenna positions measurements are relative to GPS antenna
  % positions.
  
  % From Emily Arnold, Wed 5/17/2017 5:14 PM:
  % Below are my best guesses with regards to the lever arm. All dimensions are in inches. The one dimension I am least confident in is the z-location, but it?s my best guess.
  % 
  %  	       GPS	 HF	   Lever-Arm
  % FS (x) 357.8	468	  -110.2
  % BL (y)	 9.84	  0      9.84
  % WL (z)	42.1   -3.5	  45.6

  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2016_Greenland_P3') && strcmpi(gps_source,'ATM'))
  % ===========================================================================
  % All antenna positions measurements are relative to GPS antenna
  % positions(which has no absolut measurements), so set GPS antenna
  % positions to zeros 
  
  % From Linkswiler, Matthew A. <matthew.a.linkswiler@nasa.gov>,Wed 3/23/2016 7:09 AM
  % The center of the outside surface of lidar window is 1.355m aft, 0.045m starboard,
  % and 3.425m below GPS antenna. 
  
  % From Zach Burns,zachburns@ku.edu
  % The reference of snow, kuband and mcords antenna positions is the floor of the cabin
  % for (Z) and the front of the port of atm laser (X) which is accurately located to the gps.
  % Mcords:  X = [535.575",535.575"],Y = [12",-12"];Z = [27.83",27.83"];
  % Snow Tx: X = 297.75",Y = 0;Z = -26.81"; RX: X = 168.5",Y = 0;Z = -38.75" 
  % Kuband Tx: X = 291.25",Y = -1.5";Z = -26.31"; RX: X = 180.5",Y = 0.75;Z = -39.75" 
 
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2015_Alaska_TOnrl') && strcmpi(gps_source,'NRL'))
  warning('ACTUAL LEVER ARM NEEDS TO BE DETERMINED');
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2015_Greenland_C130') && strcmpi(gps_source,'ATM'))
  % ===========================================================================
  % Preliminary from WIDMYER, THOMAS R. (WFF-5480) <thomas.r.widmyer@nasa.gov>
  % Mar 11, 2015
  %
  % FS (flight station) is -x, BLR (butt line right) is +y, WL (water line) is -z
  %
  % Mcords centered on FS 93, BL 0, WL 160
  % Snow, KA  FS 637 to center of opening, BL 13 to both sides (centers of the windows), WL 140
  %   WL 127 is to the bottom surface
  % GPS, WL 285, FS245, BL 0
  %
  % GPS flight station "FS245,BL=0,top of aircraft" from Matt Link/Kyle Krabill Mar 10.
  %
  % 230 mm separation between mcords antennas from Stephen Yan Mar 11, 2015
  %
  % Fernando Mar 11, 2015: #1 RDS is right/starboard, #2 is left
  %
  % From Emily Arnold Mar 11, 2015 CAD models
  % 		BL (Y)	FS (X)	WL (Z)
  % GPS	0	245	285
  % MCoRDS	4.53	36.13	167.26
  % Tx Ka	11.82	638.78	129.1
  % Tx Ku	12.66	641.18	130.22
  % Tx Snow	1	11.51	629.88	130.81
  % 	2	12.92	629.88	130.81
  % 	3	14.32	629.88	130.81
  % 	4	15.72	629.88	130.81
  % 	5	17.12	629.88	130.81
  % 	6	18.52	629.88	130.81
  % 	7	19.92	629.88	130.81
  % 	8	21.33	629.88	130.81
  % 	9	22.73	629.88	130.81
  % 	10	24.13	629.88	130.81
  % 	11	25.53	629.88	130.81
  % 	12	26.93	629.88	130.81
  % ===========================================================================
  gps.x = -245;
  gps.y = 0;
  gps.z = -285;
end

if (strcmpi(param.season_name,'2014_Alaska_TOnrl') && strcmpi(gps_source,'NRL'))
  warning('ACTUAL LEVER ARM NEEDS TO BE DETERMINED');
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2013_Antarctica_Ground'))% && strcmpi(gps_source,'nmea'))
  % These need to be updated.
  % NMEA antenna was x = 0, y = 0, z = 6*2.54/100?
  % Nice antenna was X = -2?, y = 0?, z = 0?
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2013_Antarctica_Sled'))% && strcmpi(gps_source,'nmea'))
  % These need to be updated.
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if any(strcmpi(param.season_name,{'2015_Antarctica_Ground','2015_Greenland_Ground'}))
  % NMEA data only and unknown lever arm
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2013_Antarctica_Basler') && strcmpi(gps_source,'cresis'))
  % Absolute position of IMU for radar systems
  % For 2013:
  %  GPS data are processed to the IMU.
  %  The IMU is mounted on the floor (but reference point is above the floor).
  %  Floor has 12 deg slope
  %  GPS antenna phase center is 0.01303 m above the bottom of the antenna
  %    and approximately 0.0146 m above the bottom of the ceiling Aluminum
  %    assuming 1/16" Aluminum fuselage material
  %  Antenna: ACC42G1215A-XT-1-N, Antcom Corporation, Novatel (KBA owned)
  %  Location of radar IMU is:
  %   X = 0;
  %   Y = 0;
  %   Z = 0;
  %  Location of radar IMU box corner is:
  %   X = -0.0765
  %   Y = -0.106
  %   Z = 0.076
  %  Location of radar GPS antenna is:
  %   X = -18.25 * 2.54/100 - 0.0765 = -0.5401
  %   Y = -(80 - (10+10/16) - 82.625*sind(12)) * 2.54/100 + 0.106 = -1.2198
  %   Z = 82.625*cosd(12) * 2.54/100 - 0.076 + 0.0146 = 1.9914
  %  Location of camera GPS antenna is:
  %   X = -0.5401
  %   Y = -1.2198 - (38+15/16)*2.54/100 = -2.2088
  %   Z = 1.9914
  %  Location of camera IMU is:
  %   X = (22+3/8)*2.54/100 - 0.5401 = 0.0282
  %   Y = 0.106 -(193+10/16 - (10+10/16) - sind(12)*(8+7/8))*2.54/100 = -4.5891
  %   Z = -0.076 - cosd(12)*(8+7/8)*2.54/100 = -0.2965
  %  Location of camera is:
  %   X = 0.0282 - 5*2.54/100 = -0.0988
  %   Y = -4.5891 + 5*2.54/100 = -4.4621
  %   Z = -0.2965 - 4*2.54/100 = -0.3981
  %  Location of RDS antenna center is:
  %   X = -0.5401
  %   Y = -4.5891 + 37.5*2.54/100 = -3.6366
  %   Z = -0.076 - 23.5*2.54/100 = -0.6729
  %   ANTENNA SPACING: 0.48 m
  %  Location of Kuband/Snow tx (right) antenna is:
  %   X = 0.0282 - 5*2.54/100 = -0.0988
  %   Y = -4.5891 - 6*2.54/100 = -4.7415
  %   Z = -0.2965 - 6*2.54/100 = -0.4489
  %  Location of Kuband/Snow rx (left) antenna is:
  %   X = 0.0282 - 41*2.54/100 = -1.0132
  %   Y = -4.7415
  %   Z = -0.4489
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2017_Antarctica_Basler') && (strcmpi(gps_source,'cresis') || strcmpi(gps_source,NMEA')))
  warning('This file needs to be updated with actual values for 2017.');
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2022_Greenland_P3') && any(strcmpi(gps_source,{'ARENA','CReSIS_GNSS'})))
  % Trajectory is referenced to the GNSS antenna, so gps struct contains
  % the offset to the GNSS antenna
  %
  % Very rough sanity check:
  % GPS antenna connector is just aft of 305" flight station (308.5" flight
  % station).
  % IMU is aft of the GPS antenna by ~48". +308.5 = 356.5" flight station (IMU to GPS Y = +48")
  % IMU is ~24" (below floor) + 94" (above floor) = 118" (IMU to GPS Z = +118")
  % IMU is starboard of GPS antenna by about 24" (IMU to GPS X = -24")
  %
  % Inertial Explorer lever arm offset (IMU to GPS):
  % SETIMUTOANTOFFSET -0.430 1.310 3.498 0.2 0.2 0.2
  %
  % Coordinates from Emily Arnold/Brad Schroeder CAD model, Aaron Paden CAD model, John Paden
  % Name	FS (X)	BL (Y)	WL (Z)	Notes
  % GPS	  318.4	  0.0	214.0	w/ Inertial Explorer Flight Station Correction
  % IMU   370.0	 17.9	 77.9	This is the measurement center of the IMU
  % Viv 1	354.0	-19.4	 68.5	Antenna numbering F-B and L-R
  % Viv2	354.0	 -0.1	 68.5
  % Viv3	354.0	  4.9	 68.5
  % Viv4	354.0	 20.0	 68.5
  % Viv5	386.1	-19.4	 68.2
  % Viv6	386.1	-13.7	 68.2
  % Viv7	386.1	  9.2	 68.2
  % Viv8	386.1	 16.8	 68.2
  % Horn1	359.2	-12.3	 72.9
  % Horn2	391.2	 -2.4	 72.6
  gps.x = -318.4*2.54/100;
  gps.y = 0.0*2.54/100;
  gps.z = -214.0*2.54/100;
end

if (strcmpi(param.season_name,'2022_Greenland_P3') && any(strcmpi(gps_source,{'CReSIS'})))
  % Trajectory is of the IMU, so gps struct contains the offset to the IMU
  % See initial GPS entry for notes.
  gps.x = -370.0*2.54/100;
  gps.y = 17.9*2.54/100;
  gps.z = -77.9*2.54/100;
end

if (strcmpi(param.season_name,'2019_Greenland_P3') && any(strcmpi(gps_source,{'ATM','NMEA','DMS','novatel'}))) ...
    || (strcmpi(param.season_name,'2018_Greenland_P3') && any(strcmpi(gps_source,{'ATM','NMEA','DMS'}))) ...
    || (strcmpi(param.season_name,'2017_Antarctica_P3') && any(strcmpi(gps_source,{'ATM','NMEA','DMS'}))) ...
    || (strcmpi(param.season_name,'2017_Greenland_P3') && any(strcmpi(gps_source,{'ATM','NMEA','DMS'}))) ...
    || (strcmpi(param.season_name,'2014_Greenland_P3') && (strcmpi(gps_source,'ATM') || strcmpi(gps_source,'NMEA'))) ...
    || (strcmpi(param.season_name,'2013_Antarctica_P3') && strcmpi(gps_source,'ATM')) ...
    || (strcmpi(param.season_name,'2013_Greenland_P3') && strcmpi(gps_source,'ATM')) ...
    || (strcmpi(param.season_name,'2012_Greenland_P3') && strcmpi(gps_source,'ATM')) ...
    || (strcmpi(param.season_name,'2010_Greenland_P3') && strcmpi(gps_source,'ATM')) ...
    || (strcmpi(param.season_name,'2009_Greenland_P3') && strcmpi(gps_source,'ATM'))
  % Absolute position of ATM antenna
  % For 2009, 2010, 2012, and 2013:
  %  ATM data is processed to the GPS.
  %  The DGPS is located on the top of the aircraft, along the centerline, at fuselage station (FS) 752.75.
  %  Matt Linkswiler 20130923: Just to clarify, the position information (lat, lon, alt) is referenced to the GPS antenna.  The intertial measurements (pitch, roll, heading) are measured at the IMU sensor (directly attached to our T3 lidar below the floorboard, approximately 1m aft and 3m below the GPS antenna).
  %  Matt Linkswiler 20140306: Personal conversation verified that antenna position is not changing.
  %  Kyle Krabill 20180606: Email confirming antenna position not changed. IMU is from T6, near the middle of the aircraft, not the aft port
  %
  % For 2019 Greenland P3 only we have 3 other GPS/IMU units available. The
  % GPS antenna is the same, but the IMU lever arm from the GPS antenna to
  % each of the 3 IMU's is:
  % 
  % Linkswiler, Matthew A. <matthew.a.linkswiler@nasa.gov> Notes:
  % We measured from the bottom of the ATM GPS antenna connector to the top
  % of the floorboard (at the X marked on top of the floorboard) to be
  % 238cm.
  % We have also estimated the phase center of the GPS antenna (as
  % installed on the P3) to be 3.63cm above the bottom of the GPS antenna
  % connector, if you want to incorporate that as well.  We will be making
  % more measurements to repeat this measurement tomorrow, but probably
  % will not have those results for a month or so this estimate is probably
  % close enough.
  %
  % John Paden notes:
  % Lever arm offset from GPS antenna to the reference point on the GPS/IMU
  % plate:
  % Vertical offset: IMUs are 2.38+0.0363 - (11+8.5/16)*0.0254 = 2.1234 under GPS
  % Cross-track offset: IMUs are (15+15/16 - 2.5)*0.0254 = 0.3413 right/starboard of GPS
  % Along-track offset: IMUs are (75+13/16 - 10)*0.0254 = 1.6716 foreward of GPS
  %
  % Aaron Paden notes:
  % Lever arm offsets from the reference point on the GPS/IMU plate to each
  % of the individual IMUs:
  % Novatel IMU-CPT:
  %   Vertical offset: (1.65)*0.0254
  %   Cross-track offset: (-3.863995 - 6.66/2 + 4.55)*0.0254
  %   Along-track offset: (-23.392336 + 6/2 - 3.39 )*0.0254
  % Applanix APX-15:
  %   Vertical offset: (-13.231097)*0.0254
  %   Cross-track offset: (-4.407455)*0.0254
  %   Along-track offset: (0.451)*0.0254
  % Vector Nav:
  %   Vertical offset: 0*0.0254
  %   Cross-track offset: -4.123767*0.0254
  %   Along-track offset: -9.383399*0.0254
  
  if 0
    % APX-15 lever arm
    x = -1.6716 + -13.231097*0.0254
    y = -0.3413 + -4.407455*0.0254
    z = -2.1234 + 0.451*0.0254
  end
  
  if 0
    % Vector Nav lever arm
    x = -1.6716 + -9.383399*0.0254
    y = -0.3413 + -4.123767*0.0254
    z = -2.1234 + 0*0.0254
  end
  
  if 0
    % Novatel lever arm. Default coordinate system is different:
    %  X points to the right
    %  Y points forwards
    %  Z points up
    y = -1.6716 + (-23.392336 + 6/2 - 3.39 )*0.0254
    x = -0.3413 + (-3.863995 - 6.66/2 + 4.55)*0.0254
    z = +2.1234 + -(1.65)*0.0254
    % # DDV12350020 on IMU
    % 	FIX NONE 0 0 0
    % 	SETIMUTYPE IMU_KVH_COTS
    % # Set IMU Orientation, Z points up (default)
    % 	INSCOMMAND enable
    % 	SETIMUORIENTATION 5
    % # Set Vehicle to Body Rotation
    % 	VEHICLEBODYROTATION 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
    % 	APPLYVEHICLEBODYROTATION disable
    % # Set Lever Arm Offset
    % 	SETIMUTOANTOFFSET -0.408500 -2.275700 2.081500 0.010000 0.010000 0.010000
    % 	SETINSOFFSET 0.000000 0.000000 0.000000
    % # Stationary Alignment
    % 	ALIGNMENTMODE UNAIDED
    % # Save configuration
    % 	SAVECONFIG
  end

  gps.x = -752.75*0.0254;
  gps.y = 0*0.0254;
  gps.z = -217.4*0.0254;
end

if (strcmpi(param.season_name,'2011_Greenland_P3') && strcmpi(gps_source,'ATM'))
  % For 2011:
  %  ATM data is processed to the GPS.
  %  The DGPS is located on the top of the aircraft, along the centerline, at fuselage station (FS) 775.55 (or 22.8 inches aft of FS 752.75).
  %  Matt L. 20130923: Just to clarify, the position information (lat, lon, alt) is referenced to the GPS antenna.  The intertial measurements (pitch, roll, heading) are measured at the IMU sensor (directly attached to our T3 lidar below the floorboard, approximately 1m aft and 3m below the GPS antenna).
  gps.x = -775.55*0.0254;
  gps.y = 0*0.0254;
  gps.z = -217.4*0.0254;
end

if (strcmpi(param.season_name,'2013_Antarctica_P3') && strcmpi(gps_source,'gravimeter')) ...
    || (strcmpi(param.season_name,'2012_Greenland_P3') && strcmpi(gps_source,'gravimeter')) ...
    || (strcmpi(param.season_name,'2011_Greenland_P3') && strcmpi(gps_source,'gravimeter'))
  %  Gravity data is corrected to the center of the gravimeter (the large
  %  cylindrical INS).  Approximate measurements are:
  %    4" in front of FS 610
  %    32" left of center line
  %    18" above the cabin floor
  gps.x = -631.12*0.0254;
  gps.y = -32.6598*0.0254;
  gps.z = -136.782*0.0254;
end

if (strcmpi(param.season_name,'2009_Antarctica_DC8') && strcmpi(gps_source,'DMS')) ...
    || (strcmpi(param.season_name,'2010_Antarctica_DC8') && any(strcmpi(gps_source,{'DMSATM','DMSATM_20101026'}))) ...
  % Absolute position of ATM antenna
  % For 2009:
  %  DMS data are processed to the GPS antenna.
  %
  % The 510 (Antarctic) data you've pulled was processed using the data collected
  % via the "ATM" antenna.  This was one of the 3 antenna's mounted on a 18x16"
  % plate in the forward part of the aircraft (ref is FS330).
  %
  % This  antenna was along the "centerline" of the aircraft, 4 5/8" aft of
  % FS330 (per our tech's notes).
  %
  % For 2010:
  %   See notes from 2010_Antarctica_DC8/DMS section below, one day (Oct 26) was
  %   processed with this ATM antenna position.
  gps.x = -334.625*0.0254;
  gps.y = -0*0.0254;
  gps.z = -100.5*0.0254;
end

if (strcmpi(param.season_name,'2010_Antarctica_DC8') && strcmpi(gps_source,'DMS'))
  %   FILES FROM:
  % Dominguez, Roseanne T. (ARC-SG)[UNIV OF CALIFORNIA   SANTA CRUZ] <roseanne.dominguez@nasa.gov>
  %
  % FORMAT:
  % Applanix, sbet_20101XXX.out files
  %
  % LEVER ARMS:
  % MCoRDS Antenna Locations
  %                  Right-Left      Right-Left
  %                  Front Row     Back Row
  %     x (in)  -1190.7 -1190.7 -1190.7 -1209.3 -1209.3
  %     y (in)  31  0 -31 15.5  -15.5
  %     z (in)  69.5  69.5  69.5  69.5  69.5
  %
  % 2010 GPS
  %        ATM antenna       Applanix Active antenna
  % x (in)  -334.625           -325.625
  % y (in)  0                    -5.625
  % z (in)  -100.5             -100.5
  %
  %
  % The trajectory data are processed to the ?reference point? on the aircraft.
  %
  % Two reference points were used: one for 10-26 and one for everything else.
  %
  % Below are 2010 references.
  %
  % Lever Arm Distances (x, y and z):
  %
  % All flights except 10-26-2010 (References Applanix Active Antenna and following lever arms)
  %   Reference-IMU lever arm:                 -0.11  -0.03  -0.27
  %   Reference-primary GPS lever arm:     +2.19 +0.10  -4.07
  %
  % Data from 10-26-2010  (References ATM antenna and following lever arms)
  %   Reference-IMU lever arm:                +0.10  +0.38  -0.61
  %   Reference-primary GPS lever arm:    +1.94  +0.14  -4.09

  gps.x = -325.625*0.0254;
  gps.y = -5.625*0.0254;
  gps.z = -100.5*0.0254;
end

if (strcmpi(param.season_name,'2009_Antarctica_DC8') && strcmpi(gps_source,'ATM')) ...
    || (strcmpi(param.season_name,'2010_Antarctica_DC8') && strcmpi(gps_source,'ATM')) ...
    || (strcmpi(param.season_name,'2010_Greenland_DC8') && strcmpi(gps_source,'ATM')) ...
    || (strcmpi(param.season_name,'2011_Antarctica_DC8') && strcmpi(gps_source,'ATM')) ...
    || (strcmpi(param.season_name,'2012_Antarctica_DC8') && strcmpi(gps_source,'ATM'))
  % Absolute position of ATM antenna
  %  Matt L. 20130923: Just to clarify, the position information (lat, lon, alt) is referenced to the GPS antenna.  The intertial measurements (pitch, roll, heading) are measured at the IMU sensor (directly attached to our T3 lidar below the floorboard, approximately 1m aft and 3m below the GPS antenna).
  gps.x = -334.625*0.0254;
  gps.y = -0*0.0254;
  gps.z = -100.5*0.0254;
end

if (any(strcmpi(param.season_name,{'2014_Antarctica_DC8'})) && (strcmpi(gps_source,'ATM') || strcmpi(gps_source,'NMEA'))) 
  % Absolute position of ATM antenna
  %  Matt L. 20141005: The measured new antenna position is 8.75" (0.222m) forward of the GPS antenna used in 2012.
  gps.x = (-334.625+8.75)*0.0254;
  gps.y = -0*0.0254;
  gps.z = -100.5*0.0254;
end

if (any(strcmpi(param.season_name,{'2016_Antarctica_DC8','2018_Antarctica_DC8'})) && (strcmpi(gps_source,'ATM') || strcmpi(gps_source,'DMS') || strcmpi(gps_source,'NMEA'))) 
  % Absolute position of ATM antenna
  %  Matt L. 20141005: The measured new antenna position is 8.75" (0.222m) forward of the GPS antenna used in 2012.
  %
  %  Matt L and Dennis G: For 2016, DMS antenna was the same as ATM.
  gps.x = (-334.625+8.75)*0.0254;
  gps.y = -0*0.0254;
  gps.z = -100.5*0.0254;
end

if (strcmpi(param.season_name,'2011_Antarctica_TO') && (strcmpi(gps_source,'Novateldiff') || strcmpi(gps_source,'Novatelppp') || strcmpi(gps_source,'Novatel_SPAN'))) ...
    || (strcmpi(param.season_name,'2011_Greenland_TO') && strcmpi(gps_source,'Novatel')) ...
    || (strcmpi(param.season_name,'2009_Antarctica_TO') && strcmpi(gps_source,'Novatel')) ...
    || (strcmpi(param.season_name,'2009_Greenland_TO') && strcmpi(gps_source,'Novatel')) ...
    || (strcmpi(param.season_name,'2009_Greenland_TO') && strcmpi(gps_source,'NMEA')) ...
    || (strcmpi(param.season_name,'2008_Greenland_TO') && strcmpi(gps_source,'ATM'))
  % FROM JOHN PADEN:
  % It is unlikely that ATM data (2008_Greenland_TO) are processed to the same location as CReSIS Novatel GPS data (all other seasons)
  gps.x = -224*0.0254;
  gps.y = 16*0.0254;
  gps.z = -(48.5+15)*0.0254;
  %gps.z = -(48.5+13.8)*0.0254; % Original file had this for 2011_Greenland_TO...
end

if (strcmpi(param.season_name,'2008_Greenland_Ground'))
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2006_Greenland_TO') && strcmpi(gps_source,'ATM'))
  gps.x = -5*12*2.54/100;
  gps.y = 5.75;
  gps.z = 0;
end

if (strcmpi(param.season_name,'2005_Greenland_TO') && strcmpi(gps_source,'ATM'))
  % Notes from /cresis/snfs1/data/ACORDS/airborne2005/trajectory/antennaSpacing.txt
  % GPS antenna was 5 ft aft of radar antennas
  % GPS antenna was 5.75 in right of the center line
  % GPS antennas were approximately 24" above the antennas
  gps.x = -5*12*2.54/100;
  gps.y = 5.75*2.54/100;
  gps.z = 2*12*2.54/100;
end

if (strcmpi(param.season_name,'2003_Greenland_P3')) ...
    || (strcmpi(param.season_name,'2004_Antarctica_P3'))
  if strcmpi(gps_source,'ATM')
    % Based on GISMO antenna positions.doc (assumes same antenna and gps
    % setup as 2007 mission). THIS SHOULD BE VERIFIED!!!
    % GPS antenna was 127'' forward of radar antennas
    % GPS antenna was on the center line
    % GPS antennas were approximately 104'' above the antennas
    gps.x = -127*2.54/100;
    gps.y = 0*2.54/100;
    gps.z = -104.3*2.54/100;
  end
  
end

if (any(strcmpi(param.season_name, ...
    {'2015_Greenland_Polar6', ...
    '2016_Greenland_Polar6', ...
    '2017_Arctic_Polar5', ...
    '2017_Antarctica_Polar6', ...
    '2018_Greenland_Polar6', ...
    '2019_Antarctica_Polar6', ...
    '2019_Arctic_Polar6', ...
    '2020_Arctic_Polar6', ...
    '2021_Greenland_Polar5', ...
    '2022_Greenland_Polar5', ...
    '2022_Antarctica_Polar5', ...
    })) && any(strcmpi(gps_source,{'AWI','NMEA'})))
  % Measurements are from Richard Hale Aug 12, 2015 for RDS and Aug 15,
  % 2015 for Snow Radar. Measurements are made relative to the AWI Aft
  % Science GPS antenna known as ST5.
  %
  % RDS
  % Antenna spacing: 18.42" or 46.8 cm
  % Antenna spacing in Z on wings: 2.44" or 6.19 cm or 7.60 deg wing
  %   dihedral
  %
  % Snow Radar
  %  	         x	    y	     z	 	 	               x	   y	    z
  % snow-port	95.5	-20.2	-86.4	 	snow-starboard	95.5	20.0	-86.4
  %
  % From Fernando Aug 17, 2015: Snow transmit from right, snow receive from
  % left
  
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if strcmpi(param.season_name,'mcords_simulator')
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:4;
  end
  
  % absoulute value of components
  
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
   
  LArx(:,1)   = [0  0            0];    % m
  LArx(:,2)   = [0 -1.9986/2    -0.05]; % m
  LArx(:,3)   = [0 -1.9986      -0.1];  % m 
  LArx(:,4)   = [0 -3/2*1.9986  -0.15]; % m
    
  LAtx(:,1)   = [0 0           0];    % m
  LAtx(:,2)   = [0 1.9986/2   -0.05]; % m
  LAtx(:,3)   = [0 1.9986     -0.1];  % m
  LAtx(:,4)   = [0 3/2*1.9986 -0.15]; % m
  
  
  LArx(1,:)   = LArx(1,:) - gps.x; % m, gps corrected
  LArx(2,:)   = LArx(2,:) - gps.y; % m, gps corrected
  LArx(3,:)   = LArx(3,:) - gps.z; % m, gps corrected
  
  LAtx(1,:)   = LAtx(1,:) - gps.x; % m, gps corrected
  LAtx(2,:)   = LAtx(2,:) - gps.y; % m, gps corrected
  LAtx(3,:)   = LAtx(3,:) - gps.z; % m, gps corrected
 % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (any(strcmpi(param.season_name,{'2016_Greenland_G1XB'})) && strcmpi(gps_source,'postprocessed'))
  gps.x = 0;
  gps.y = 0;
  gps.z = 0;
end

if isempty(gps)
  error('param.season_name(%s) and gps.gps_source(%s) had no matching lever arm. If correct, an entry needs to be added to this function.',param.season_name,gps_source);
end

% =========================================================================
%% Accumulation Radar
% =========================================================================

if (any(strcmpi(param.season_name,{'2018_Antarctica_TObas'})) && strcmpi(radar_name,'accum'))
  % See GPS section for 2018_Antarctica_TObas for details:
  % 	3+5/8" from back/aft-side of antenna box
  % 	9+15/16" from right/starboard side of lid (used edge of lid)
  % 	64+1/16" below to the lid of the antenna
  %
  % The offset from the outer back right top corner of the box to the
  % center of the aperture of each of the antennas is:
  %   (reference is aft, starboard, top)
  %
  % With the box (outer surfaces) as reference, the measurements (in
  % inches) are the following:
  % Element 1 (starboard): (x,y,z) = (6.8125, 1.69885,10.04).
  % Element 2 (next to starboard): (x,y,z) = (6.8125, 6.44885, 10.04)
  % Element 3 (next to port): (x,y,z) = (6.8125,11.19885, 10.04)
  % Element 4 (port): (x,y,z) = (6.8125, 15.94885, 10.04)
  % The thickness of each antenna element is 0.125 in.
  %
  % The bars were 0.75 in. thick. This decreases the z-position of all
  % elements by 0.75 in.

  % Accumulation antenna
  LArx = [];
  LArx(1,:)   = ( (-(3+5/8) + 6.8125) + [0 0 0 0])*0.0254 - gps.x; % m
  LArx(2,:)   = ( (+(9+15/16)) - [15.9489   11.1989    6.4489    1.6988])*0.0254 - gps.y; % m
  LArx(3,:)   = ( (+(64+1/16) - 0.75 + 10.04) + [0 0 0 0])*0.0254 - gps.z; % m
  
  LArx = mean(LArx,2); % Combine all 4 elements into a single element
  
  LAtx = [];
  LAtx(1,:)   = ( (-(3+5/8) + 6.8125) + [0 0 0 0])*0.0254 - gps.x; % m
  LAtx(2,:)   = ( (+(9+15/16)) - [15.9489   11.1989    6.4489    1.6988])*0.0254 - gps.y; % m
  LAtx(3,:)   = ( (+(64+1/16) - 0.75 + 10.04) + [0 0 0 0])*0.0254 - gps.z; % m
  
  LAtx = mean(LAtx,2); % Combine all 4 elements into a single element
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (any(strcmpi(param.season_name,{'2019_Antarctica_TObas'})) && strcmpi(radar_name,'accum'))
  % See GPS section for 2019_Antarctica_TObas for details:
  % 	-2.8274 from forward-side of antenna box
  %   -0.1757 from right/starboard side of lid (used edge of lid)
  % 	-1.7068 below to the lid of the antenna
  %
  % The offset from the outer back right top corner of the box to the
  % center of the aperture of each of the antennas is:
  %   (reference is aft, starboard, top)
  %
  % With the box (outer surfaces) as reference, the measurements (in
  % inches) are the following:
  % Element 1 (starboard): (x,y,z) = (6.8125, 1.69885,10.04).
  % Element 2 (next to starboard): (x,y,z) = (6.8125, 6.44885, 10.04)
  % Element 3 (next to port): (x,y,z) = (6.8125,11.19885, 10.04)
  % Element 4 (port): (x,y,z) = (6.8125, 15.94885, 10.04)
  % The thickness of each antenna element is 0.125 in.
  %
  % The bars were 0.75 in. thick. This decreases the z-position of all
  % elements by 0.75 in.

  % Accumulation antenna
  LArx = [];
  LArx(1,:)   = ( (-2.8274/0.0254 - 6.8125) + [0 0 0 0])*0.0254 - gps.x; % m
  LArx(2,:)   = ( (+0.1757/0.0254) - [15.9489   11.1989    6.4489    1.6988])*0.0254 - gps.y; % m
  LArx(3,:)   = ( (+1.7068/0.0254 - 0.75 + 10.04) + [0 0 0 0])*0.0254 - gps.z; % m
  
  LArx = mean(LArx,2); % Combine all 4 elements into a single element
  
  LAtx = [];
  LAtx(1,:)   = ( (-2.8274/0.0254 - 6.8125) + [0 0 0 0])*0.0254 - gps.x; % m
  LAtx(2,:)   = ( (+0.1757/0.0254) - [15.9489   11.1989    6.4489    1.6988])*0.0254 - gps.y; % m
  LAtx(3,:)   = ( (+1.7068/0.0254 - 0.75 + 10.04) + [0 0 0 0])*0.0254 - gps.z; % m
  
  LAtx = mean(LAtx,2); % Combine all 4 elements into a single element
  
  if strcmpi(gps_source,'bas_imu_to_gps')
    % Special code for doing IMU to GPS lever arm rather than to radar
    LArx = [-gps.x; -gps.y; -gps.z];
    LAtx = [-gps.x; -gps.y; -gps.z];
  end
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (any(strcmpi(param.season_name,{'2022_Greenland_Ground'})) && strcmpi(radar_name,'accum'))

  % Accumulation antenna
  LArx = [];
  LArx(1,:)   = ( 0*0.0254 ) - gps.x; % m
  LArx(2,:)   = ( 0*0.0254 ) - gps.y; % m
  LArx(3,:)   = ( 0*0.0254 ) - gps.z; % m
  
  LArx = mean(LArx,2); % Combine all elements into a single element
  
  LAtx = [];
  LAtx(1,:)   = ( 0*0.0254 ) - gps.x; % m
  LAtx(2,:)   = ( 0*0.0254 ) - gps.y; % m
  LAtx(3,:)   = ( 0*0.0254 ) - gps.z; % m
  
  LAtx = mean(LAtx,2); % Combine all elements into a single element
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2009_antarctica_TO') && strcmpi(radar_name,'accum')) ...
    || (strcmpi(param.season_name,'2011_antarctica_TO') && strcmpi(radar_name,'accum'))
  % Accumulation antenna
  LArx(1,:)   = (-302.625*0.0254 + [0 0 0 0]) - gps.x; % m
  LArx(2,:)   = (0.75 + [-7.5 -3.75 3.75 7.5])*0.0254 - gps.y; % m
  LArx(3,:)   = (5*0.0254 + [0 0 0 0]) - gps.z; % m
  
  LAtx(1,:)   = (-302.625*0.0254 + [0 0 0 0]) - gps.x; % m
  LAtx(2,:)   = (0.75 + [-7.5 -3.75 3.75 7.5])*0.0254 - gps.y; % m
  LAtx(3,:)   = (5*0.0254 + [0 0 0 0]) - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2010_Greenland_P3') && strcmpi(radar_name,'accum')) ...
    || (strcmpi(param.season_name,'2011_Greenland_P3') && strcmpi(radar_name,'accum'))
  
  % Coordinates from Emily Arnold
  % Accumulation antenna
  LArx(1,:)   = [-433.3]*0.0254 - gps.x; % m
  LArx(2,:)   = [0]*0.0254 - gps.y; % m
  LArx(3,:)   = [-72]*0.0254 - gps.z; % m
  
  LAtx(1,:)   = [-433.3]*0.0254 - gps.x; % m
  LAtx(2,:)   = [0]*0.0254 - gps.y; % m
  LAtx(3,:)   = [-72]*0.0254 - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2018_Greenland_P3') && strcmpi(radar_name,'accum'))
  % Coordinates from Emily Arnold and offsets from Cameron
  % Accumulation antenna. X-offset is an estimate and needs to be measured.
  % The 8 elements are arranged in 2x4 array (2 in along-track). The
  % along-track elements are combined using in cabin power combiners.
  % Each of the four combined channels are individually transmitted and
  % received on.
  LArx(1,:)   = (-433.3*0.0254 + [0 0 0 0 0]) - gps.x; % m
  LArx(2,:)   = (0 + [-0.39 -0.13 0.13 0.39 0]) - gps.y; % m
  LArx(3,:)   = (-72.5*0.0254 + [0 0 0 0 0]) - gps.z; % m

  LAtx(1,:)   = (-433.3*0.0254 + [0 0 0 0 0]) - gps.x; % m
  LAtx(2,:)   = (0 + [-0.39 -0.13 0.13 0.39 0]) - gps.y; % m
  LAtx(3,:)   = (-72.5*0.0254 + [0 0 0 0 0]) - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:4;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 2;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2017_Antarctica_P3') && strcmpi(radar_name,'accum'))...
    || (strcmpi(param.season_name,'2017_Greenland_P3') && strcmpi(radar_name,'accum'))
  % Coordinates from Emily Arnold and offsets from Cameron
  % Accumulation antenna. X-offset is an estimate and needs to be measured.
  LArx(1,:)   = (-433.3*0.0254 - [0.2 0.2 0.2 0.2]) - gps.x; % m ESTIMATED
  LArx(2,:)   = (0 + [-0.39 -0.13 0.13 0.39]) - gps.y; % m
  LArx(3,:)   = (-72.5*0.0254 + [0 0 0 0]) - gps.z; % m

  LAtx(1,:)   = (-433.3*0.0254 + [0.2 0.2 0.2 0.2]) - gps.x; % m ESTIMATED
  LAtx(2,:)   = (0 + [-0.39 -0.13 0.13 0.39]) - gps.y; % m
  LAtx(3,:)   = (-72.5*0.0254 + [0 0 0 0]) - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:4;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 2;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2014_Greenland_P3') && strcmpi(radar_name,'accum')) ...
    || (strcmpi(param.season_name,'2013_Antarctica_P3') && strcmpi(radar_name,'accum')) ...
    || (strcmpi(param.season_name,'2013_Antarctica_P3') && strcmpi(radar_name,'accum')) ... 
    || (strcmpi(param.season_name,'2013_Greenland_P3') && strcmpi(radar_name,'accum')) ...
    || (strcmpi(param.season_name,'2012_Greenland_P3') && strcmpi(radar_name,'accum'))
  % Coordinates from Emily Arnold and offsets from Cameron
  % Accumulation antenna
  LArx(1,:)   = (-433.3*0.0254 + [0 0 0 0 0]) - gps.x; % m
  LArx(2,:)   = (0 + [-0.39 -0.13 0.13 0.39 0]) - gps.y; % m
  LArx(3,:)   = (-72.5*0.0254 + [0 0 0 0 0]) - gps.z; % m
%   LArx(3,:)   = (-72*0.0254 + [0 0 0 0 0]) - gps.z; % m

  LAtx(1,:)   = (-433.3*0.0254 + [0 0]) - gps.x; % m
  LAtx(2,:)   = (0 + [-0.39 0.39]) - gps.y; % m
  LAtx(3,:)   = (-72.5*0.0254 + [0 0]) - gps.z; % m
%   LAtx(3,:)   = (-72*0.0254 + [0 0]) - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:4;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 2;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if any(strcmpi(param.season_name,{'2015_Antarctica_Ground','2015_Greenland_Ground'})) && strcmpi(radar_name,'accum')
  % Accumulation antenna
  % NMEA data only and unknown lever arm
  LArx(1,:)   = ([0]) - gps.x; % m
  LArx(2,:)   = ([0]) - gps.y; % m
  LArx(3,:)   = ([0]) - gps.z; % m
  
  LAtx(1,:)   = ([0]) - gps.x; % m
  LAtx(2,:)   = ([0]) - gps.y; % m
  LAtx(3,:)   = ([0]) - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2013_Antarctica_Ground') && strcmpi(radar_name,'accum'))
  % Accumulation antenna
  LArx(1,:)   = ([0 0 0 0 0 0]) - gps.x; % m
  LArx(2,:)   = ([-75   -45   -15    15    45    75]/100) - gps.y; % m
  LArx(3,:)   = ([0 0 0 0 0 0]) - gps.z; % m
  
  LAtx(1,:)   = ([0 0]) - gps.x; % m
  LAtx(2,:)   = ([-135 135]/100) - gps.y; % m
  LAtx(3,:)   = ([0 0]) - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2013_Antarctica_Sled') && strcmpi(radar_name,'accum'))
  % Accumulation antenna
  LArx(1,:)   = ([0 0 0 0 0 0 0 0]) - gps.x; % m
  LArx(2,:)   = ([-105 -75 -45 -15 15 45 75 105]/100) - gps.y; % m
  LArx(3,:)   = ([0 0 0 0 0 0 0 0]) - gps.z; % m
  
  LAtx(1,:)   = ([0 0]) - gps.x; % m
  LAtx(2,:)   = ([-165 165]/100) - gps.y; % m
  LAtx(3,:)   = ([0 0]) - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2022_Antarctica_BaslerMKB') && strcmpi(radar_name,'accum'))
  % Platform: Airborne Radar Kenn Borek Air Basler call sign MKB (COLDEX 1, COLDEX 2, UTIG)
  % These values need to be updated with actual values.
    
  % Measurements, X,Y,Z are in aircraft coordinates, not IMU coordinates
  %LArx(1,1:16) = 1.5859;
  LArx(1,1:16) = -1.5; % GUESS
  LArx(2,1:16) = [-9.2102*(0:15)] * 2.54/100;
  LArx(2,1:16) = LArx(2,1:16) - mean(LArx(2,1:16));
  LArx(3,1:16) = -3.4609; % GUESS
  warning('This file needs to be updated with actual values for 2022.');
  
  LAtx = LArx(:,1:16);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:16;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 8;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if any(strcmpi(param.season_name,{'2022_Antarctica_Ground','2023_Greenland_Ground'})) && strcmpi(radar_name,'accum')
  % Sled antennas EAGER 1 and EAGER 2
  %
  % Primary GPS antenna: GPS positions are relative to primary which is in the center of the radar antenna array.
  % Secondary GPS antenna: 22.5" forward and 12" right of the primary. Align information will be relative to this.
  
  % GPS Antenna to Antenna phase center
  LArx = [0 0	-4 % along-track polarization/H-polarization
    0 0	-4 % cross-track polarization/V-polarization
    ].' * 2.54/100;
  
  LAtx = LArx(:,:);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end


% =========================================================================
%% Ka-band
% =========================================================================

if any(strcmpi(param.season_name,{'2019_Greenland_TO'})) ...
    && strcmpi(radar_name,'kaband')
  % X,Y,Z are in aircraft coordinates relative to rear GPS antenna
  LArx(1,1:2) = [NaN 2.86/100];
  LArx(2,1:2) = [NaN -36.5/100];
  LArx(3,1:2) = [NaN 160/100];
  
  LAtx(1,1) = 2.86/100;
  LAtx(2,1) = -43.5/100;
  LAtx(3,1) = 160/100;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 2;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 2;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2015_Greenland_C130') && strcmpi(radar_name,'kaband'))
  % X,Y,Z are in aircraft coordinates, not IMU
  LArx(1,1) = -638.78*2.54/100;
  LArx(2,1) = -11.82*2.54/100;
  LArx(3,1) = -129.1*2.54/100;
  
  LAtx(1,1) = -638.78*2.54/100;
  LAtx(2,1) = +11.82*2.54/100;
  LAtx(3,1) = -129.1*2.54/100;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

% =========================================================================
%% Ku-band
% =========================================================================

if any(strcmpi(param.season_name,{'2019_Greenland_TO'})) ...
    && strcmpi(radar_name,'kuband')
  % X,Y,Z are in aircraft coordinates relative to rear GPS antenna
  LArx(1,1) = -2.86/100;
  LArx(2,1) = -37/100;
  LArx(3,1) = 162.54/100;
  
  LAtx(1,1) = -2.86/100;
  LAtx(2,1) = -43/100;
  LAtx(3,1) = 162.54/100;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2016_Greenland_P3') && strcmpi(radar_name,'kuband'))
  % X,Y,Z are in aircraft coordinates relative to GPS antenna
  LArx(1,1) = -180.5*2.54/100 -1.355;
  LArx(2,1) = 0.75*2.54/100 + 0.045;
  LArx(3,1) = -39.75*2.54/100 + 3.425;
  
  LAtx(1,1) = -291.25*2.54/100 -1.355;
  LAtx(2,1) = -1.5*2.54/100 + 0.045;
  LAtx(3,1) = -26.31*2.54/100+ 3.425;
   
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2015_Greenland_C130') && strcmpi(radar_name,'kuband'))
  % X,Y,Z are in aircraft coordinates, not IMU
  LArx(1,1) = -641.18*2.54/100;
  LArx(2,1) = -12.66*2.54/100;
  LArx(3,1) = -130.22*2.54/100;
  
  LAtx(1,1) = -641.18*2.54/100;
  LAtx(2,1) = +12.66*2.54/100;
  LAtx(3,1) = -130.22*2.54/100;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2013_Antarctica_Basler') && strcmpi(radar_name,'kuband'))
  % See notes in GPS section
  LArx(1,1) = -1.0132;
  LArx(2,1) = -4.7415;
  LArx(3,1) = -0.4489;
  
  LAtx(1,1) = -0.0988;
  LAtx(2,1) = -4.7415;
  LAtx(3,1) = -0.4489;
  
  % Second measurements, X,Y,Z are in aircraft coordinates, not IMU
  LArx(1,1) = -4.7311;
  LArx(2,1) = -0.1003;
  LArx(3,1) = 0.4073;
  
  LAtx(1,1) = -4.7311;
  LAtx(2,1) = -0.9830;
  LAtx(3,1) = 0.4073;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2014_Greenland_P3') && strcmpi(radar_name,'kuband')) ... 
    || (strcmpi(param.season_name,'2013_Antarctica_P3') && strcmpi(radar_name,'kuband')) ... 
    || (strcmpi(param.season_name,'2013_Greenland_P3') && strcmpi(radar_name,'kuband')) ...
    || (strcmpi(param.season_name,'2012_Greenland_P3') && strcmpi(radar_name,'kuband')) ...
    || (strcmpi(param.season_name,'2011_Greenland_P3') && strcmpi(radar_name,'kuband')) ...
    || (strcmpi(param.season_name,'2010_Greenland_P3') && strcmpi(radar_name,'kuband'))
  % Coordinates from Emily Arnold
  % Ku-band on left, Snow on right, tx/rx are spaced forward/aft of each other by 36??? (i.e. same y/z coordinates and x coordinates differ by 36???).
  % I referenced the waveguide/antenna intersection.
  LArx(1,:)   = [-374.7]*0.0254 - gps.x; % m
  LArx(2,:)   = [-19.4]*0.0254 - gps.y; % m
  LArx(3,:)   = [-77.7]*0.0254 - gps.z; % m
  
  LAtx(1,:)   = [-358.2]*0.0254 - gps.x; % m
  LAtx(2,:)   = [-19.4]*0.0254 - gps.y; % m
  LAtx(3,:)   = [-77.7]*0.0254 - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2010_Antarctica_DC8') && strcmpi(radar_name,'kuband')) ...
    || (strcmpi(param.season_name,'2011_Antarctica_DC8') && strcmpi(radar_name,'kuband')) ...
    || (strcmpi(param.season_name,'2012_Antarctica_DC8') && strcmpi(radar_name,'kuband')) ...
    || (strcmpi(param.season_name,'2014_Antarctica_DC8') && strcmpi(radar_name,'kuband')) ...
    || (strcmpi(param.season_name,'2016_Antarctica_DC8') && strcmpi(radar_name,'kuband'))
  % FROM ADAM WEBSTER (~DC8 crew):
  % Lever Arm to ATM antenna (this is valid for 2010, 2011 Antarctica DC8):
  % 	Snow: 733.3??? aft, 141.4??? down, 0??? lateral
  % 	Ku-band: 740.9??? aft, 141.7??? down, 0??? lateral
  
  LArx(1,:)   = [-740.9]*0.0254; % m
  LArx(2,:)   = [0]*0.0254; % m
  LArx(3,:)   = [141.7]*0.0254; % m
  
  LAtx(1,:)   = [-740.9]*0.0254; % m
  LAtx(2,:)   = [0]*0.0254; % m
  LAtx(3,:)   = [141.7]*0.0254; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
  
end

if (strcmpi(param.season_name,'2009_Antarctica_DC8') && strcmpi(radar_name,'kuband')) ...
    || (strcmpi(param.season_name,'2010_greenland_DC8') && strcmpi(radar_name,'kuband'))
  % Nadir 9 port center of window (as measured in Emily Arnold???s coordinate system):
  % x= -1310"
  % y= 33.7"
  % z= 45.4" (i.e. below where the antenna phase center is)
  % There are actually two antennas for snow and ku-band, but each pair of
  % antennas is centered on the Nadir 9 port window... so rather than trying
  % to figure out the offset for the tx/rx we just the tx/rx positions
  % to be the midpoint between the two antennas.
  
  LArx(1,:)   = [-1310]*0.0254 - gps.x; % m
  LArx(2,:)   = [33.7]*0.0254 - gps.y; % m
  LArx(3,:)   = [45.4]*0.0254 - gps.z; % m
  
  LAtx(1,:)   = [-1310]*0.0254 - gps.x; % m
  LAtx(2,:)   = [33.7]*0.0254 - gps.y; % m
  LAtx(3,:)   = [45.4]*0.0254 - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2009_antarctica_TO') && strcmpi(radar_name,'kuband')) ...
    || (strcmpi(param.season_name,'2011_Greenland_TO') && strcmpi(radar_name,'kuband')) ...
    || (strcmpi(param.season_name,'2011_antarctica_TO') && strcmpi(radar_name,'kuband'))
  % There are two horn antennas for Ku-band radar. The one in front is for TX
  % The one behind is for Rx.
  LArx(1,:)   = [-310.125]*0.0254 - gps.x; % m
  LArx(2,:)   = [0.75]*0.0254 - gps.y; % m
  LArx(3,:)   = [5]*0.0254 - gps.z; % m
  
  LAtx(1,:)   = [-295.125]*0.0254 - gps.x; % m
  LAtx(2,:)   = [0.75]*0.0254 - gps.y; % m
  LAtx(3,:)   = [5]*0.0254 - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

% =========================================================================
%% Radar Depth Sounder
% =========================================================================
if any(strcmpi(param.season_name,{'2022_Greenland_X6'})) && strcmpi(radar_name,'rds')
  % X,Y,Z are in aircraft coordinates relative to GPS antenna
  % Undetermined, temporarily set to zeros
  LArx = [0	0	0].';
  LAtx = [0	0	0].';
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if any(strcmpi(param.season_name,{'2022_Greenland_Vapor'})) && strcmpi(radar_name,'rds')
  % X,Y,Z are in aircraft coordinates relative to GPS antenna
  % Undetermined, temporarily set to zeros
  LArx = [0	0	0].';
  LAtx = [0	0	0].';
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2022_Antarctica_BaslerMKB') && strcmpi(radar_name,'rds'))
  % Platform: Airborne Radar Kenn Borek Air Basler call sign MKB (COLDEX 1, COLDEX 2, UTIG)
  % These values need to be updated with actual values.
    
  % Measurements, X,Y,Z are in aircraft coordinates, not IMU coordinates
  LArx = [];
  LArx(1,1:2) = [-1.5 -1.5]; % GUESS
  LArx(2,1:2) = [-9 9]; % GUESS
  LArx(3,1:2) = [1.5 1.5]; % GUESS
  warning('This file needs to be updated with actual values for 2022.');
  
  LAtx = [-1.5; 0; 1.5];
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:2;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2022_Antarctica_GroundGHOST') && strcmpi(radar_name,'rds'))
  % Sled antennas GHOST 1
  %
  % Primary GPS antenna: GPS positions are relative to primary which is in the center of the radar antenna array.
  % Secondary GPS antenna: 6*30 = 180" (WILD GUESS!!!!) right of the primary. Align information will be relative to this.
  
  % GPS Antenna to Antenna phase center
  LArx = [zeros(1,6);
    28*[0 1 2 3 4 5];
    zeros(1,6)] * 2.54/100;
  
  LAtx = LArx(:,:);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 4;
  end
  
  if rxchannel == 0
    rxchannel = 4;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if any(strcmpi(param.season_name,{'2019_Antarctica_GV'})) ...
    && strcmpi(radar_name,'rds')
  % X,Y,Z are in aircraft coordinates relative to GPS antenna
  %
  % NOTE: From Rick's student Pedro. Metadata folder "Phase Center Location
  % Measurements - 18 Oct 19.xlsx"

  LArx = [12.714	-0.864	-2.537
          12.715	-0.399	-2.522
          12.716	0.388	-2.521
          12.716	0.852	-2.537].';
  LArx([1 3],:) = -LArx([1 3],:); % x and z are negated
  
  LAtx = LArx;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 2;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2017_Antarctica_TObas') && strcmpi(radar_name,'rds'))
  % Port - Belly - Starboard
  % mm
  % /cresis/snfs1/dataproducts/metadata/2018_Antarctica_TObas/Measurements of antenna locations on BL.pdf
  % Arenas Pingarron, Alvaro <alvaro.pingarron.15@ucl.ac.uk>
  %
  % (X,Y) x is pointing out right wing, y is pointing forward
  % 1: (-8375,10)
  % 2: (-6765,-10)
  % 3: (-5165,3)
  % 4: (-3540,0)
  % 5: (-1469,-2915)
  % 6: (-500,-2915)
  % 7: (505,-2915)
  % 8: (1469,-2915)
  % 9: (3510,0)
  % A: (5129,-5)
  % B: (6740,-3)
  % C: (8369, 5)
  % 
  % Height of aerials above ground - assumes ground was flat and port and starboard are the same.
  % Polaris pod: 650
  % P1 and SC: 2614
  % P2 and SB: 2548
  % P3 and SA: 2454
  % P4 and S9: 2356
  
  LArx(1,:)   = [10 -10 3 0 -2915 -2915 -2915 -2915 0 -5 -3 5]/1000 - gps.x; % m
  LArx(2,:)   = [-8375 -6765 -5165 -3540 -1469 -500 505 1469 3510 5129 6740 8369]/1000 - gps.y; % m
  LArx(3,:)   = [2614 2548 2454 2356 650 650 650 650 2356 2454 2548 2614]/1000 - gps.z; % m
  
  LAtx   = LArx; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 3;
  end
  
  if rxchannel == 0
    rxchannel = 3;
    tx_weights = [1 1 1 1 0 0 0 0 0 0 0 0];
  end
end

if (strcmpi(param.season_name,'2018_Alaska_SO') && strcmpi(radar_name,'rds'))
  % HF antenna
  LArx(1,:)   = 0 - gps.x; % m
  LArx(2,:)   = 0 - gps.y; % m
  LArx(3,:)   = 0 - gps.z; % m
  
  LAtx(1,:)   = 0 - gps.x; % m
  LAtx(2,:)   = 0 - gps.y; % m
  LAtx(3,:)   = 0 - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2018_Antarctica_Ground') && strcmpi(radar_name,'rds'))
  % Japanese National Institute of Polar Research/Japanese Antarctic
  % Research Expedition
  %
  % Log periodic antennas: Four antennas mounted on the left side and four
  % antennas mounted on the right side. The antennas were mounted from the
  % roof of the tracked vehicle.
  %
  % See NDF_Field_Report_BVL_v012.docx for details
  %
  % Report is missing z-offset between Trimbal GPS antenna phase center and
  % radar antenna phase centers.
  % Report is missing the location of  the radar antenna phase centers on
  % the antennas themselves. The model number of the antennas is not given.
  % Assume here that the z-offset is zero.
  %
  % Report gives distance of antennas off the ground of 4.1 m.
  %
  % Report does not give the y-offset of the Trimbal antenna from the side
  % of the vehicle. Assume here that the offset is 0.15 m.
  %
  % Distance from side of vehicle to first antenna is given as 250 cm and
  % 262 cm. By measuring pixels in the picture, 250 cm seems correct on
  % both sides of the vehicle.
  %
  % rx_paths are labeled from left to right in order:
  % rx_paths adc
  %    1      8 Rx only Antenna #8 in figure
  %    2      7 Rx only Antenna #7 in figure
  %    3      6 Rx only Antenna #6 in figure
  %    4      5 Rx only Antenna #5 in figure
  %    5      3 AWG0 T/R Antenna #1 in figure
  %    6      1 AWG1 T/R Antenna #2 in figure
  %    7      4 AWG2 T/R Antenna #3 in figure
  %    8      2 AWG3 T/R Antenna #4 in figure
  %
  % adc    rx_paths
  %    1      6
  %    2      8
  %    3      5
  %    4      7
  %    5      4
  %    6      3
  %    7      2
  %    8      1
  %
  % [6 8 5 7 4 3 2 1]
  
  LArx(1,:)   = (2.25+.60+2.00-1.00 + [0 0 0 0 0 0 0 0]) - gps.x; % m
  LArx(2,:)   = ([0.15-2.85-2.5 + (3:-1:0)*-1.05, 0.15+2.5 + [0:3]*1.05]) - gps.y; % m
  LArx(3,:)   = (0 + [0 0 0 0 0 0 0 0]) - gps.z; % m
  
  LAtx(1,:)   = (2.25+.60+2.00-1.00 + [0 0 0 0]) - gps.x; % m
  LAtx(2,:)   = (0.15+2.5 + [0:3]*1.05) - gps.y; % m
  LAtx(3,:)   = (0 + [0 0 0 0]) - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 5;
  end
  
  if rxchannel == 0
    rxchannel = 5;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2019_Antarctica_Ground') && strcmpi(radar_name,'rds'))
  % Sled antennas
  % Center elements left to right
  
  % GPS Antenna to Antenna ports (top side of antenna glass to bottom center of GPS antenna)
  LArx = [-18.475	-119.94 14.596
    -18.475	-101.57   14.596
    -18.475 -83.24	 14.596
    -18.475 -64.87  14.596
    -18.475 -46.54  14.596
    -18.475 -28.17  14.596
    -18.475 -9.84 14.596
    -18.475 8.53 14.596].' * 2.54/100;
  
  LAtx = LArx(:,[1 7 2 8]);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 4;
  end
  
  if rxchannel == 0
    rxchannel = 4;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2022_Antarctica_Ground') && strcmpi(radar_name,'rds'))
  % Sled antennas
  % Center elements left to right
  
  % GPS Antenna to Antenna ports (top side of antenna glass to bottom center of GPS antenna)
  LArx = [0 -83.24 0 % along-track polarization/H-polarization
    0 -64.87  0
    0 -46.54  0
    0 -28.17 0
    0 -9.84 0
    0 8.53 0
    0 -83.24 0 % cross-track polarization/V-polarization
    0 -64.87 0
    0 -46.54 0
    0 -28.17 0
    0 -9.84 0
    0 8.53 0].' * 2.54/100;
  
  LAtx = LArx(:,:);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 3;
  end
  
  if rxchannel == 0
    rxchannel = 3;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2016_Greenland_TOdtu') && strcmpi(radar_name,'rds'))
  % X,Y,Z are in aircraft coordinates relative to GPS antenna
  LArx(1,:) = [-110.2]*2.54/100;
  LArx(2,:) = [9.84]*2.54/100;
  LArx(3,:) = [45.6]*2.54/100;
  
  LAtx(1,:) = [-110.2]*2.54/100;
  LAtx(2,:) = [9.84]*2.54/100;
  LAtx(3,:) = [45.6]*2.54/100;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2016_Greenland_P3') && strcmpi(radar_name,'rds'))
  % X,Y,Z are in aircraft coordinates relative to GPS antenna
  LArx(1,:) = [-535.575 -535.575]*2.54/100 - 1.355;
  LArx(2,:) = [12 -12]*2.54/100 + 0.045; % need to determin
  LArx(3,:) = [27.83 27.83]*2.54/100 + 3.425;
  
  LAtx(1,:) = [-535.575 -535.575]*2.54/100 - 1.355;
  LAtx(2,:) = [12 -12]*2.54/100 + 0.045; % need to determin
  LAtx(3,:) = [27.83 27.83]*2.54/100 + 3.425;
 
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

% Only for 24ch configuration
if (any(strcmpi(param.season_name,{'2015_Greenland_Polar6', ...
    '2016_Greenland_Polar6', ...
    '2017_Antarctica_Polar6', ...
    })) && strcmpi(radar_name,'rds'))
  % See notes in GPS section
  
  % Center elements left to right
  Polar6_RDS = [-22.4509	-384.8185	-109.2042
    -22.4700	-366.6482	-111.6292
    -22.4892	-348.2920	-114.0790
    -22.5083	-330.1217	-116.5041
    -22.5276	-311.7655	-118.9539
    -22.5467	-293.5952	-121.3790
    -22.5659	-275.2390	-123.8288
    -22.5850	-257.0687	-126.2538
    -60.7213	-64.4623	-144.7008
    -60.7149	-46.0371	-144.7002
    -60.7086	-27.6119	-144.6996
    -60.7022	-9.1867	-144.6989
    -60.6959	9.2337	-144.6983
    -60.6895	27.6637	-144.6977
    -60.6832	46.0889	-144.6970
    -60.6768	64.5141	-144.6964
    -22.6447	256.6052	-126.2678
    -22.6448	274.7756	-123.8428
    -22.6450	293.1318	-121.3929
    -22.6451	311.3021	-118.9679
    -22.6452	329.6583	-116.5180
    -22.6453	347.8286	-114.0930
    -22.6454	366.1848	-111.6432
    -22.6456	384.3552	-109.2181] * 2.54/100;
  
  Polar6_RDS(:,1) = -Polar6_RDS(:,1);
  Polar6_RDS(:,3) = -Polar6_RDS(:,3);
  
  % NEED TO GET FROM RICHARD HALE
  LArx(1,1:24) = Polar6_RDS(:,1).';
  LArx(2,1:24) = Polar6_RDS(:,2).';
  LArx(3,1:24) = Polar6_RDS(:,3).';
  
  LAtx = LArx(:,9:16);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:24;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 12;
    tx_weights = ones(1,size(LAtx,2));
  end
end

% Only for 8ch configuration
if (any(strcmpi(param.season_name,{'2018_Greenland_Polar6', ...
    '2019_Antarctica_Polar6', ...
    '2021_Greenland_Polar5', ...
    '2022_Greenland_Polar5', ...
    })) && strcmpi(radar_name,'rds'))
  % See notes in GPS section
  
  % Center elements left to right
  Polar6_RDS = [-60.7213	-64.4623	-144.7008
    -60.7149	-46.0371	-144.7002
    -60.7086	-27.6119	-144.6996
    -60.7022	-9.1867	-144.6989
    -60.6959	9.2337	-144.6983
    -60.6895	27.6637	-144.6977
    -60.6832	46.0889	-144.6970
    -60.6768	64.5141	-144.6964] * 2.54/100;
  
  Polar6_RDS(:,1) = -Polar6_RDS(:,1);
  Polar6_RDS(:,3) = -Polar6_RDS(:,3);
  
  % NEED TO GET FROM RICHARD HALE
  LArx(1,1:8) = Polar6_RDS(:,1).';
  LArx(2,1:8) = Polar6_RDS(:,2).';
  LArx(3,1:8) = Polar6_RDS(:,3).';
  
  LAtx = LArx(:,1:8);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:8;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 4;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2015_Greenland_C130') && strcmpi(radar_name,'rds'))
  % X,Y,Z are in aircraft coordinates, not IMU
  LArx(1,:) = [-36.13 -36.13]*2.54/100;
  LArx(2,:) = [4.53 -4.53]*2.54/100;
  LArx(3,:) = [-167.26 -167.26]*2.54/100;
  
  LAtx(1,:) = [-36.13 -36.13]*2.54/100;
  LAtx(2,:) = [4.53 -4.53]*2.54/100;
  LAtx(3,:) = [-167.26 -167.26]*2.54/100;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2013_Antarctica_Basler') && strcmpi(radar_name,'rds'))
  % See notes in GPS section
  
  % Center elements left to right
  
  % First Measurements (Calgary, not as reliable)
  % LArx(1,1:8) = -3.6366;
  % LArx(3,1:8) = -0.6729;
  % LArx(2,1:8) = (-3.5:1:3.5) * 0.48;
  
  % Second measurements, X,Y,Z are in aircraft coordinates, not IMU coordinates
  LArx(1,1:8) = -3.6182;
  LArx(2,1:8) = (-3.5:1:3.5) * 0.48;
  LArx(3,1:8) = 0.8158;
  
  LAtx = LArx(:,1:8);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:8;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 4;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2017_Antarctica_Basler') && strcmpi(radar_name,'rds'))
  % These values need to be updated with actual values. They appear to not
  % be using the total station survey values that Craig from ATM provided
  % and the offsets from those that Richard Hale provided.
    
  % Measurements, X,Y,Z are in aircraft coordinates, not IMU coordinates
  LArx(1,1:8) = 1.5859;
  LArx(2,1:8) = [-64.4623 -46.0371 -27.6119 -9.1867 9.2337 27.6637 46.0889 64.5141] * 2.54/100;
  LArx(3,1:8) = -3.4609;
  warning('This file needs to be updated with actual values for 2017.');
  
  LAtx = LArx(:,1:8);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:8;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 4;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2019_Greenland_P3') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2018_Greenland_P3') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2017_Antarctica_P3') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2017_Greenland_P3') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2014_Greenland_P3') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2013_Antarctica_P3') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2013_Greenland_P3') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2012_Greenland_P3') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2011_Greenland_P3') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2010_Greenland_P3') && strcmpi(radar_name,'rds'))
  
  % Offsets from the ground plane (based on the CAD model)
  if 1
    XYZ_offset = ...
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; ...
      1.8, 0.4, 1.5, 0, -1.5, -0.4, -1.8, 2, 2, 2.1, 2.1, -2.1, -2.1, -2, -2; ...
      -15.4, -14.8, -16.5, -13.3, -16.5, -14.8, -15.4, -16.7, -16.7, -16.7, -16.7, -16.7, -16.7, -16.7, -16.7];
  else
    XYZ_offset = zeros(3,15);
  end
 
  % Center elements left to right (in inches)
  LArx(:,1) = [-587.7	-88.6	-72.8];
  LArx(:,2) = [-587.7	-58.7	-71];
  LArx(:,3) = [-587.7	-30.4	-69.2];
  LArx(:,4) = [-587.7	0	-68.1];
  LArx(:,5) = [-587.7	30.4	-69.2];
  LArx(:,6) = [-587.7	58.7	-71];
  LArx(:,7) = [-587.7	88.6	-72.8];
  % Left outer elements, left to right (in inches)
  LArx(:,8) = [-586.3	-549.2	-128.7];
  LArx(:,9) = [-586.3	-520.6	-125.2];
  LArx(:,10) = [-586.3	-491.2	-121.6];
  LArx(:,11) = [-586.3	-462.2	-118.1];
  % Right outer elements, left to right (in inches)
  LArx(:,12) = [-586.3	462.2	-118.1];
  LArx(:,13) = [-586.3	491.2	-121.6];
  LArx(:,14) = [-586.3	520.6	-125.2];
  LArx(:,15) = [-586.3	549.2	-128.7];
  
  % Add offsets from ground plane
  LArx = LArx + XYZ_offset;
  
  % Convert to meters units and add gps trajectory position
  LArx(1,:)   = LArx(1,:)*0.0254 - gps.x;
  LArx(2,:)   = LArx(2,:)*0.0254 - gps.y;
  LArx(3,:)   = LArx(3,:)*0.0254 - gps.z;
  
  LAtx = LArx(:,1:7);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:15;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 4;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2009_Antarctica_DC8') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2010_greenland_DC8') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2010_Antarctica_DC8') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2011_Antarctica_DC8') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2012_Antarctica_DC8') && strcmpi(radar_name,'rds'))
  
  LArx(1,:)   = [-30.2438 -30.7162 -30.2438 -30.7162 -30.2438 0 0 0] - gps.x; % m
  LArx(2,:)   = [  -0.7874   -0.3937   0.0000  0.3937  0.7874 0 0 0] - gps.y; % m
  LArx(3,:)   = [  1.7653   1.7653   1.7653   1.7653   1.7653 0 0 0] - gps.z; % m
  
  LAtx(1,:)   = [-30.2438 -30.7162 -30.2438 -30.7162 -30.2438] - gps.x; % m
  LAtx(2,:)   = [  -0.7874   -0.3937   0.0000  0.3937  0.7874] - gps.y; % m
  LAtx(3,:)   = [  1.7653   1.7653   1.7653   1.7653   1.7653] - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:5;
  end
  
  if rxchannel == 0
    rxchannel = 3;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (any(strcmpi(param.season_name,{'2014_Antarctica_DC8','2016_Antarctica_DC8','2018_Antarctica_DC8'})) && strcmpi(radar_name,'rds'))
  % NOTE: These come from Ali Mahmood's http://svn.cresis.ku.edu/cresis-toolbox/documents/Antenna Lever Arm GPS Report Support Files/2014_Antarctica_DC8_array_Schematic.pptx
  
  LArx(1,:)   = [-30.71368  -30.71368  -30.71368 -30.24632  -30.24632  -30.24632] - gps.x; % m
  LArx(2,:)   = [-27.9 2 27.9 -27.9 2 27.9]*0.0254 - gps.y; % m
  LArx(3,:)   = [  1.7653   1.7653   1.7653   1.7653   1.7653 1.7653] - gps.z; % m

  LAtx(1,:)   = [-30.71368  -30.71368  -30.71368 -30.24632  -30.24632  -30.24632] - gps.x; % m
  LAtx(2,:)   = [-27.9 2 27.9 -27.9 2 27.9]*0.0254 - gps.y; % m
  LAtx(3,:)   = [  1.7653   1.7653   1.7653   1.7653   1.7653 1.7653] - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:6;
  end
  
  if rxchannel == 0
    rxchannel = 2;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2011_Antarctica_TO') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2011_Greenland_TO') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2009_Antarctica_TO') && strcmpi(radar_name,'rds')) ...
    || (strcmpi(param.season_name,'2009_Greenland_TO') && strcmpi(radar_name,'rds'))
  
  % FROM EMILY ARNOLD'S THESIS and SVN:cresis-toolbox\documents\Antenna Lever Arm GPS Report Support Files\Field report_2011_Antarctica_TO.docx
  % EMILY ARNOLD THESIS HAS ERRORS: "The spacing between adjacent elements starting with the inboard most elements (R1 or L1) is 38.2", 37.0", 37.4", 34.0", and 39.0", respectively."
  % CORRECT SPACING FROM SVN:cresis-toolbox\documents\Antenna Lever Arm GPS Report Support Files\KBA TO 2008-2011 Drawings_OPS-08-10-00_s1__C-GCKB - Ice Radar Antennas.pdf
  %    Jilu Li confirmed that these spacings were confirmed during 2011 Antarctica TO mission
  % The distance between elements L1 and R1 is approximately 30 ft
  % The two elements are spaced 4.6 ft from the engine and 11.8 ft from the fuselage side wall.
  % The wing of the Twin Otter has a span of 65 ft
  % Three degree wing dihedral angle.
  % FERNANDO CONFIRMED: transmit on right and receive on left in 2008 and 2009
  
  LArx(1,:)   = -[  220    220    220    220    220   220      220    220    220    220    220   220 ]*0.0254 - gps.x; % m
  LArx(2,:)   =  [ -178.5 -216.5 -253.5 -291   -328  -367      178.5  216.5  253.5  291    328   367 ]*0.0254 - gps.y; % m
  LArx(3,:)   = -([ 44.432 46.424 48.363 50.328 52.267 54.319  44.432 46.424 48.363 50.328 52.267 54.319 ]+13.8)*0.0254 - gps.z; % m
  
  LAtx(1,:)   = -[ 220    220    220    220    220   220 ]*0.0254 - gps.x; % m
  LAtx(2,:)   = [ 178.5  216.5  253.5  291    328   367 ]*0.0254 - gps.y; % m
  LAtx(3,:)   = -([ 44.432 46.424 48.363 50.328 52.267 54.319 ]+13.8)*0.0254 - gps.z; % m
  
  % Wing Flexure EMILY ARNOLD AND RICHARD HALE personal communication
  % Details in SVN:cresis-toolbox\documents\Antenna Lever Arm GPS Report Support Files\Twin Otter wing flexure_Emily Arnold.msg
  % Adding in flight wing flexure from Richard Hale
  LArx(3,:)   = LArx(3,:) - [0.4 0.9 1.5 2.2 2.9 3.7 0.4 0.9 1.5 2.2 2.9 3.7]*0.0254;
  LAtx(3,:)   = LAtx(3,:) - [0.4 0.9 1.5 2.2 2.9 3.7]*0.0254;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:12;
  end
  
  if rxchannel == 0
    rxchannel = 4;
    tx_weights = ones(1,size(LAtx,2));
  end
  
end

if (strcmpi(param.season_name,'2008_Greenland_TO') && strcmpi(radar_name,'rds'))
  LArx(1,:)   = -[  220    220    220    220    220   220      220    220    220    220    220   220 ]*0.0254 - gps.x; % m
  LArx(2,:)   =  [ -178.5 -216.5 -253.5 -291   -328  -367      178.5  216.5  253.5  291    328   367 ]*0.0254 - gps.y; % m
  LArx(3,:)   = -([ 44.432 46.424 48.363 50.328 52.267 54.319  44.432 46.424 48.363 50.328 52.267 54.319 ]+13.8)*0.0254 - gps.z; % m
  
  LAtx(1,:)   = -[ 220    220    220    220    220   220  220    220 ]*0.0254 - gps.x; % m
  LAtx(2,:)   = [ 178.5  216.5  253.5  291    328   367  -178.5 -216.5 ]*0.0254 - gps.y; % m
  LAtx(3,:)   = -([ 44.432 46.424 48.363 50.328 52.267 54.319  44.432 46.424 ]+13.8)*0.0254 - gps.z; % m
  
  % Wing Flexure EMILY ARNOLD AND RICHARD HALE personal communication
  % Details in SVN:cresis-toolbox\documents\Antenna Lever Arm GPS Report Support Files\Twin Otter wing flexure_Emily Arnold.msg
  % Adding in flight wing flexure from Richard Hale
  LArx(3,:)   = LArx(3,:) - [0.4 0.9 1.5 2.2 2.9 3.7 0.4 0.9 1.5 2.2 2.9 3.7]*0.0254;
  LAtx(3,:)   = LAtx(3,:) - [0.4 0.9 1.5 2.2 2.9 3.7 0.4 0.9 ]*0.0254;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:12;
  end
  
  if rxchannel == 0
    rxchannel = 4;
    tx_weights = [1 1 1 1 1 1 0 0];
  end
  
end

if (strcmpi(param.season_name,'2006_Greenland_TO') && strcmpi(radar_name,'rds'))
  % Notes from VN:cresis-toolbox\documents\Antenna Lever Arm GPS Report Support Files\2006_antennaSpacing.txt
  % GPS antenna was 5 ft aft of radar antennas
  % GPS antenna was 5.75 in right of the center line
  % GPS antennas were approximately 24" above the antennas
  
  % Wing Flexure (see 2008_Greenland_TO wing flexure from Emily Arnold and Richard Hale)
  z = [0.4 0.9 1.5 2.2 2.9 3.7];
  y = [178.5 216.5 253.5 291 328 367];
  z_2006 = polyval(polyfit(y,z,3),[153.9 203.1 253.1 290.6 328])*0.0254;

  LArx(1,:) = [0 0 0 0 0]*0.0254 - gps.x; % meters
  LArx(2,:) = [153.9 203.1 253.1 290.6 328]*0.0254 - gps.y; % m
  % LArx(3,:) = ([ 25.5 23 20.875 19.5 18.125])*0.0254 - gps.z; % m % Measured on the ground in 2006 in Calgary
  
  % Assumption of 3 deg dihedral wing, 24" below GPS antenna on inner element, and wing flexure from Richard Hale
  LArx(3,:) = (32.0656-[153.9 203.1 253.1 290.6 328]*tand(3))*0.0254 - gps.z - z_2006;
  
  LAtx(1,:) = LArx(3,:);
  LAtx(2,:) = -LArx(2,:);
  %LAtx(3,:)   = [24 21.75 19.5 17.625 15.75]*0.0254 - gps.z; % Measured on the ground in 2006 in Calgary
  LAtx(3,:) = LArx(3,:);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:4;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 3;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2005_Greenland_TO') && strcmpi(radar_name,'rds'))
  % Notes from /cresis/snfs1/data/ACORDS/airborne2005/trajectory/antennaSpacing.txt
  
  % Wing Flexure
  z = [0.4 0.9 1.5 2.2 2.9 3.7];
  y = [178.5 216.5 253.5 291 328 367];
  z_2005 = polyval(polyfit(y,z,3),[153.9 229.13 290.66 353.66 mean([153.9 229.13 290.66 353.66])])*0.0254;

  LArx(1,:) = [0 0 0 0 0]*0.0254 - gps.x; % meters
  LArx(2,:) = [153.9 229.13 290.66 353.66 mean([153.9 229.13 290.66 353.66])]*0.0254 - gps.y; % m
  
  % Assumption of 3 deg dihedral wing, 24" below GPS antenna on inner element, and wing flexure from Richard Hale
  LArx(3,:) = (32.0656-[153.9 229.13 290.66 353.66 mean([153.9 229.13 290.66 353.66])]*tand(3))*0.0254 - gps.z - z_2005;
  
  LAtx(1,:) = LArx(3,:);
  LAtx(2,:) = -LArx(2,:);
  %LAtx(3,:)   = [24 21.75 19.5 17.625 15.75]*0.0254 - gps.z; % Measured on the ground in 2006 in Calgary
  LAtx(3,:) = LArx(3,:);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:4;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 3;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2004_Antarctica_P3') && strcmpi(radar_name,'rds'))
  % Based on GISMO antenna positions.doc (assumes same antenna and gps
  % setup as 2007 mission).  THIS ACTUAL LEVER ARM NEEDS TO BE VERIFIED!!!
    LArx(1,:) = [630 630 630 630 630]*0.0254 - gps.x; % meters
  LArx(2,:) = [448.6 481.6 515.1 549.1 mean([448.6 481.6 515.1 549.1])]*0.0254 - gps.y; % m
  
  % Assumption of 3 deg dihedral wing, 24" below GPS antenna on inner element, and wing flexure from Richard Hale
  LArx(3,:) = (([448.6 481.6 515.1 549.1 mean([448.6 481.6 515.1 549.1])]*tand(6)) - 448.6)*0.0254 - gps.z;
  
  LAtx(1,:) = LArx(3,:);
  LAtx(2,:) = -LArx(2,:);
  %LAtx(3,:)   = [24 21.75 19.5 17.625 15.75]*0.0254 - gps.z; % Measured on the ground in 2006 in Calgary
  LAtx(3,:) = LArx(3,:);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:5;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 3;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2003_Greenland_P3') && strcmpi(radar_name,'rds'))
  % Based on GISMO antenna positions.doc (assumes same antenna and gps
  % setup as 2007 mission).  THIS ACTUAL LEVER ARM NEEDS TO BE VERIFIED!!!
  LArx(1,:) = [630]*0.0254 - gps.x; % meters
  LArx(2,:) = [mean([448.6 481.6 515.1 549.1])]*0.0254 - gps.y; % m
  
  % Assumption of 3 deg dihedral wing, 24" below GPS antenna on inner element, and wing flexure from Richard Hale
  LArx(3,:) = (([mean([448.6 481.6 515.1 549.1])]*tand(6)) - 448.6)*0.0254 - gps.z;
  
  LAtx(1,:) = LArx(3,:);
  LAtx(2,:) = -LArx(2,:);
  %LAtx(3,:)   = [24 21.75 19.5 17.625 15.75]*0.0254 - gps.z; % Measured on the ground in 2006 in Calgary
  LAtx(3,:) = LArx(3,:);
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2009_Antarctica_TO_Gambit') && strcmpi(radar_name,'rds'))
  gps.x = 0*0.0254;
  gps.y = 4*0.0254;
  gps.z = 0*0.0254;
  
  LArx(1,:)   = [ 28    28    28    28 ]*0.0254 - gps.x;  % m
  LArx(2,:)   = [ 153.9 203.1 253.1 290.6 ]*0.0254 - gps.y; % m
  LArx(3,:)   = -[ 25.5 23 20.875 19.5 ]*0.0254 - gps.z; % m
  
  LAtx(1,:)   = [ 28    28    28    28 ]*0.0254 - gps.x; % m
  LAtx(2,:)   = -[ 153.9 203.1 253.1 290.6 ]*0.0254 - gps.y; % m
  LAtx(3,:)   = -[ 24 21.75 19.5 17.625 ]*0.0254 - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:4;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 2;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2008_Greenland_Ground') && strcmpi(radar_name,'rds'))
  % NEEM Field Season. See metadata directory for information and pictures.
  % First 8 receive are regular HH antenna positions 
  % Last 4 receive are antennas 5-8 in polarimetric V configuration
  % First 2 transmits are regular HH antenna positions
  % Third transmit is V antenna position for antenna 2

  LArx(1,:)   = -[ 4.365 4.365 4.365 4.365 4.365 4.365 4.365 4.365 4.365-0.857 4.365+0.857 4.365-0.857 4.365+0.857]/2 - gps.x;  % m
  LArx(2,:)   = [[ -3.5 -2.5 -1.5 -0.5 0.5 1.5 2.5 3.5]*0.857 0.8975 0.8975 1.9995 1.9995]  - gps.y; % m
  LArx(3,:)   = [ 0 0 0 0 0 0 0 0 0 0 0 0 ] - gps.z; % m
  
  LAtx(1,:)   =  [ 4.365 4.365 4.365 ]/2 - gps.x; % m
  LAtx(2,:)   =  [ -3.658/2 3.658/2 1.737 ] - gps.y; % m
  LAtx(3,:)   =  [ 0 0 0] - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:8;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 4;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2016_Greenland_G1XB') && strcmpi(radar_name,'rds'))
  % X,Y,Z are in aircraft coordinates, not IMU
  LArx(1,:) = [0]*2.54/100;
  LArx(2,:) = [0]*2.54/100;
  LArx(3,:) = [0]*2.54/100;
  
  LAtx(1,:) = [0]*2.54/100;
  LAtx(2,:) = [0]*2.54/100;
  LAtx(3,:) = [0]*2.54/100;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

% =========================================================================
%% Snow Radar
% =========================================================================
if any(strcmpi(param.season_name,{'2021_Arctic_Vanilla'})) && strcmpi(radar_name,'snow')
  % X,Y,Z are in aircraft coordinates relative to GPS antenna
  % Undetermined, temporarily set to zeros
  LArx = [0	0	0].';
  LAtx = [0	0	0].';
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if any(strcmpi(param.season_name,{'2019_SouthDakota_N1KU'})) ...
    && strcmpi(radar_name,'snow')
  % X,Y,Z are in aircraft coordinates relative to GPS antenna
  LArx = [0.3827 -1.2155 -0.9425].';

  LAtx = [0.3771 1.7367 -0.9409].';
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if any(strcmpi(param.season_name,{'2020_SouthDakota_N1KU'})) ...
    && strcmpi(radar_name,'snow')
  % X,Y,Z are in aircraft coordinates relative to GPS antenna
  %
  LAtx = [0.5486 0.2423 -1.6352].';

  LArx = [0.2952 -2.1810 0.7222].';
  LArx(:,2) = [0.3836 -1.6054 1.0586].';
  LArx(:,3) = [0.4637  -1.0808 1.3995].';
  LArx(:,4) = [0.4647  0.5980 1.3891].';
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if any(strcmpi(param.season_name,{'2019_Arctic_GV','2019_Antarctica_GV'})) ...
    && strcmpi(radar_name,'snow')
  % X,Y,Z are in aircraft coordinates relative to GPS antenna
  % From Rick Hale's student Pedro Toledo: Lever_arm_for_snow_antennas.msg
  % x pointing aft, y pointing right, z pointing up so need to negate x and
  % z to match the lever_arm.m standard which has x forward and z down.
  LArx = [12.475	0.463	-2.327].';
  LArx([1 3]) = -LArx([1 3]); % x and z are negated

  LAtx = [12.474	-0.470	-2.328].';
  LAtx([1 3]) = -LAtx([1 3]); % x and z are negated
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if any(strcmpi(param.season_name,{'2018_Alaska_SO','2021_Alaska_SO'})) ...
    && strcmpi(radar_name,'snow')
  % X,Y,Z are in aircraft coordinates relative to GPS antenna
  LArx(1,1) = -0.288;
  LArx(2,1) = -0.094;
  LArx(3,1) = 1.289;
  
  LAtx(1,1) = 4.991;
  LAtx(2,1) = -0.094;
  LAtx(3,1) = 1.815;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2016_Greenland_P3') && strcmpi(radar_name,'snow'))
    % Snow Tx: X = 297.75",Y = 0;Z = -26.81"; RX: X = 168.5",Y = 0;Z = -38.75" 
    % X,Y,Z are in aircraft coordinates relatively to GPS antenna
  LArx(1,1) = -168.5*2.54/100  - 1.355;
  LArx(2,1) = 0.045;
  LArx(3,1) = -38.75*2.54/100 + 3.425;
  
  LAtx(1,1) = -297.75*2.54/100  - 1.355;
  LAtx(2,1) = 0.045;
  LAtx(3,1) = -26.81*2.54/100 + 3.425;

  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (any(strcmpi(param.season_name,{ ...
    '2015_Greenland_Polar6', ...
    '2016_Greenland_Polar6', ...
    '2017_Arctic_Polar5', ...
    '2018_Greenland_Polar6', ...
    '2019_Arctic_Polar6', ...
    '2020_Arctic_Polar6', ...
    '2022_Antarctica_Polar5'})) && strcmpi(radar_name,'snow'))
  % See notes in GPS section
  
  LArx(1,1:2) = -[95.5 95.5]*2.54/100;
  LArx(2,1:2) = [-20.2 -20.2]*2.54/100;
  LArx(3,1:2) = -[-86.4 -86.4]*2.54/100;
  
  LAtx(1,1:2) = -[95.5 95.5]*2.54/100;
  LAtx(2,1:2) = [20 20]*2.54/100;
  LAtx(3,1:2) = -[-86.4 -86.4]*2.54/100;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1:2;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2015_Alaska_TOnrl') && strcmpi(radar_name,'snow'))
  % X,Y,Z are in aircraft coordinates, not IMU
  warning('ACTUAL LEVER ARM NEEDS TO BE DETERMINED');
  LArx(1,1) = 0*2.54/100;
  LArx(2,1) = 0*2.54/100;
  LArx(3,1) = 0*2.54/100;
  
  LAtx(1,1) = 0*2.54/100;
  LAtx(2,1) = 0*2.54/100;
  LAtx(3,1) = 0*2.54/100;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2015_Greenland_C130') && strcmpi(radar_name,'snow'))
  % X,Y,Z are in aircraft coordinates, not IMU
  LArx(1,1) = -629.88*2.54/100;
  LArx(2,1) = -19.22*2.54/100;
  LArx(3,1) = -130.81*2.54/100;
  
  LAtx(1,1) = -629.88*2.54/100;
  LAtx(2,1) = +19.22*2.54/100;
  LAtx(3,1) = -130.81*2.54/100;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2014_Alaska_TOnrl') && strcmpi(radar_name,'snow'))
  % X,Y,Z are in aircraft coordinates, not IMU
  %Masud measured
  LArx(1,1) = -21.6*2.54/100;
  LArx(2,1) = -7*2.54/100;
  LArx(3,1) = 13.7*2.54/100;
  
  LAtx(1,1) = -268.77*2.54/100;
  LAtx(2,1) = -3.25*2.54/100;
  LAtx(3,1) = 70.875*2.54/100;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2013_Antarctica_Basler') && strcmpi(radar_name,'snow'))
  % See notes in GPS section
  LArx(1,1) = -1.0132;
  LArx(2,1) = -4.7415;
  LArx(3,1) = -0.4489;
  
  LAtx(1,1) = -0.0988;
  LAtx(2,1) = -4.7415;
  LAtx(3,1) = -0.4489;
  
  % Second measurements, X,Y,Z are in aircraft coordinates, not IMU
  LArx(1,1) = -4.7311;
  LArx(2,1) = -0.1003;
  LArx(3,1) = 0.4073;
  
  LAtx(1,1) = -4.7311;
  LAtx(2,1) = -0.9830;
  LAtx(3,1) = 0.4073;
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  % Amplitude (not power) weightings for transmit side.
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2022_Greenland_P3') && strcmpi(radar_name,'snow'))
  % See initial GPS entry for notes.
  %
  % General layout (forward antennas first):
  %     Tx1 TxHV   Rx3 Rx4        Tx2
  %     Rx1 Rx2       RxHV   Rx5 Rx6
  
  % Vivaldi Rx (left to right) followed by rx horn antenna V/H
  % Vivaldi antennas 3 and 4 are in the front row, all other receive
  % antennas are in the back row.
  % rx_path order:
  % [Rx1 Rx2 Rx3 Rx4 Rx5 Rx6 RxV RxH]
  LArx(1,:)   = [-386.1 -386.1 -354.0 -354.0 -386.1 -386.1 -391.2 -391.2]*0.0254 - gps.x; % m
  LArx(2,:)   = [ -19.4  -13.7   -0.1    4.9    9.2   16.8   -2.4   -2.4]*0.0254 - gps.y; % m
  LArx(3,:)   = [ -68.2  -68.2  -68.5  -68.5  -68.2  -68.2  -72.6  -72.6]*0.0254 - gps.z; % m
  
  % Vivaldi Tx (left to right) followed by tx horn antenna V/H
  % All transmitters are in the front row
  % tx_path order:
  % [Tx1 Tx2 TxV TxH]
  LAtx(1,:)   = [-354.0 -354.0 -359.2 -359.2]*0.0254 - gps.x; % m
  LAtx(2,:)   = [ -19.4   20.0  -12.3  -12.3]*0.0254 - gps.y; % m
  LAtx(3,:)   = [ -68.5  -68.5  -72.9  -72.9]*0.0254 - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = [1 0 0 0];
  end
end

if (strcmpi(param.season_name,'2019_Greenland_P3') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2018_Greenland_P3') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2017_Antarctica_P3') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2017_Greenland_P3') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2014_Greenland_P3') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2013_Antarctica_P3') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2013_Greenland_P3') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2012_Greenland_P3') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2011_Greenland_P3') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2010_Greenland_P3') && strcmpi(radar_name,'snow'))
  % Coordinates from Emily Arnold
  % Ku-band on left, Snow on right, tx/rx are spaced forward/aft of each other by 36" (i.e. same y/z coordinates and x coordinates differ by 36").
  % I referenced the waveguide/antenna intersection.
  LArx(1,:)   = [-384.4]*0.0254 - gps.x; % m
  LArx(2,:)   = [10]*0.0254 - gps.y; % m
  LArx(3,:)   = [-80.6]*0.0254 - gps.z; % m
  
  LAtx(1,:)   = [-348.4]*0.0254 - gps.x; % m
  LAtx(2,:)   = [10]*0.0254 - gps.y; % m
  LAtx(3,:)   = [-80.6]*0.0254 - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2009_Greenland_P3') && strcmpi(radar_name,'snow'))
  % The Snow Radar antennas were separated by 36" in the cross-track (this is different from 2010 and beyond) on the aft bomb-bay play (also
  % different from         2010 and beyond).
  %
  % Dimensions in inches and rounded to the nearest tenth.
  %
  % Left antenna - (X,Y,Z) - (335.6, -17.1, 146)
  % Right antenna - (X,Y,Z) - (335.6, 18.9, 146)
  %
  % These are to the 3 offset distances to the center of each horn cutout.
  
  LArx(1,:)   = [335.6]*0.0254; % m
  LArx(2,:)   = [-17.8]*0.0254; % m
  LArx(3,:)   = [146]*0.0254; % m
  
  LAtx(1,:)   = [335.6]*0.0254; % m
  LAtx(2,:)   = [18.9]*0.0254; % m
  LAtx(3,:)   = [146]*0.0254; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

if (strcmpi(param.season_name,'2010_Antarctica_DC8') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2011_Antarctica_DC8') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2012_Antarctica_DC8') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2014_Antarctica_DC8') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2016_Antarctica_DC8') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2018_Antarctica_DC8') && strcmpi(radar_name,'snow'))
  
  % FROM ADAM WEBSTER (~DC8 crew):
  % Lever Arm to ATM antenna (this is valid for 2010, 2011 Antarctica DC8):
  % 	Snow: 733.3??? aft, 141.4??? down, 0??? lateral
  % 	Ku-band: 740.9??? aft, 141.7??? down, 0??? lateral
  
  LArx(1,:)   = [-733.3]*0.0254; % m
  LArx(2,:)   = [0]*0.0254; % m
  LArx(3,:)   = [141.4]*0.0254; % m
  
  LAtx(1,:)   = [-733.3]*0.0254; % m
  LAtx(2,:)   = [0]*0.0254; % m
  LAtx(3,:)   = [141.4]*0.0254; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
  
end

if (strcmpi(param.season_name,'2009_Antarctica_DC8') && strcmpi(radar_name,'snow')) ...
    || (strcmpi(param.season_name,'2010_greenland_DC8') && strcmpi(radar_name,'snow'))
  
  % Nadir 9 port center of window (as measured in Emily Arnold???s coordinate system):
  % x= -1310"
  % y= 33.7"
  % z= 45.4" (i.e. below where the antenna phase center is)
  % There are actually two antennas for snow and ku-band, but each pair of
  % antennas is centered on the Nadir 9 port window... so rather than trying
  % to figure out the offset for the tx/rx we just the tx/rx positions
  % to be the midpoint between the two antennas.
  
  LArx(1,:)   = [-1310]*0.0254 - gps.x; % m
  LArx(2,:)   = [33.7]*0.0254 - gps.y; % m
  LArx(3,:)   = [45.4]*0.0254 - gps.z; % m
  
  LAtx(1,:)   = [-1310]*0.0254 - gps.x; % m
  LAtx(2,:)   = [33.7]*0.0254 - gps.y; % m
  LAtx(3,:)   = [45.4]*0.0254 - gps.z; % m
  
  if ~exist('rxchannel','var') || isempty(rxchannel)
    rxchannel = 1;
  end
  
  if rxchannel == 0
    rxchannel = 1;
    tx_weights = ones(1,size(LAtx,2));
  end
end

% =========================================================================
%% Compute Phase Centers
% =========================================================================

if isempty(LAtx)
  error('param.season_name(%s) and param.radar_name(%s) had no matching lever arm. If correct, an entry needs to be added to this function.',param.season_name,param.radar_name);
end



% Amplitude (not power) weightings for transmit side.
A = tx_weights(~isnan(tx_weights));
magsum       = sum(A);
if magsum == 0
  % A == 0 meaning transmitters are disabled, technically no transmit phase
  % center in this case (e.g. if collecting noise data). Handle this
  % special case by just taking the average of all the transmitter
  % locations in order to avoid getting NaN positions.
  LAtx_pc(1,1)    = mean(LAtx(1,:),2);
  LAtx_pc(2,1)    = mean(LAtx(2,:),2);
  LAtx_pc(3,1)    = mean(LAtx(3,:),2);
else
  % Weighted average of Xb, Yb and Zb components
  LAtx_pc(1,1)    = dot(LAtx(1,:),A)/magsum;
  LAtx_pc(2,1)    = dot(LAtx(2,:),A)/magsum;
  LAtx_pc(3,1)    = dot(LAtx(3,:),A)/magsum;
end

phase_center = (mean(LArx(:,rxchannel),2) + LAtx_pc)./2;

return

