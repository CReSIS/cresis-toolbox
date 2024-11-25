function loc = project_locations
% loc = project_locations
%
% Common locations of interest
%
%  This function needs to be formalized better. It is a placeholder for a
%  better function right now.
%
% See Also: physical_constants.m, proj_load_standard.m, project_locations.m

loc.melt.gzds.lat = -(75+12.208/60);
loc.melt.gzds.lon = -(104+49.850/60);
loc.melt.gzds.notes = 'ApRES is located here, potential borehole location for NSF-NERC MELT project';

loc.melt.gzus.lat = -(75+14.017/60);
loc.melt.gzus.lon = -(104+46.639/60);
loc.melt.gzus.notes = 'Potential borehole location for NSF-NERC MELT project';

loc.neem.lat = 77.45;
loc.neem.lon = -51.06;

loc.camp_century.lat = 77+10/60;
loc.camp_century.lon = -(61+8/60);

loc.dye2.lat = 66+23/60;
loc.dye2.lon = -(46+11/60);

loc.dye3.lat = 65+11/60;
loc.dye3.lon = -(43+49/60);

loc.grip.lat = 72+34.74/60;
loc.grip.lon = -(37+33.92/60);

loc.gisp2.lat = 72+34/60+46.5/3600;
loc.gisp2.lon = -(38+27/60+33.07/3600);

loc.ngrip.lat = 75+1/60;
loc.ngrip.lon = -(42+32/60);

loc.egrip.lat = 75+38/60;
loc.egrip.lon = -(36+0/60);
