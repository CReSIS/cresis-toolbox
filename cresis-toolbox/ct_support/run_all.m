% script run_all
%
% Used by run_all scripts to select parameter spreadsheets to run

param_fns = {};

%% CReSIS Accumulation Radar
% param_fns{end+1} = 'accum_param_2010_Greenland_P3.xls';
% param_fns{end+1} = 'accum_param_2011_Greenland_P3.xls';
% param_fns{end+1} = 'accum_param_2012_Greenland_P3.xls';
% param_fns{end+1} = 'accum_param_2013_Greenland_P3.xls';
% param_fns{end+1} = 'accum_param_2013_Antarctica_P3.xls';
% param_fns{end+1} = 'accum_param_2013_Antarctica_Ground.xls'; % Sridar Anandakrishnan Ice Stream A/B
% param_fns{end+1} = 'accum_param_2014_Greenland_P3.xls';
% param_fns{end+1} = 'accum_param_2015_Greenland_Ground.xls'; % Bo Vinther Renland Ice Cap
% param_fns{end+1} = 'accum_param_2015_Antarctica_Ground.xls'; % Howard Conway Crary Ice Rise 
% param_fns{end+1} = 'accum_param_2017_Greenland_P3.xls';
% param_fns{end+1} = 'accum_param_2018_Greenland_P3.xls';
% param_fns{end+1} = 'accum_param_2018_Antarctica_TObas.xls';
% param_fns{end+1} = 'accum_param_2019_Antarctica_TObas.xls';
% param_fns{end+1} = 'accum_param_2022_Greenland_Ground.xls';
% param_fns{end+1} = 'accum_param_2022_Antarctica_Ground.xls';
% param_fns{end+1} = 'accum_param_2022_Antarctica_BaslerMKB.xls';
% param_fns{end+1} = 'accum_param_2023_Greenland_Ground.xls';

%% CReSIS Kuband Radar
% param_fns{end+1} = 'kuband_param_2009_Antarctica_DC8.xls';
% param_fns{end+1} = 'kuband_param_2010_Greenland_DC8.xls';
% param_fns{end+1} = 'kuband_param_2010_Greenland_P3.xls';
% param_fns{end+1} = 'kuband_param_2010_Antarctica_DC8.xls';
% param_fns{end+1} = 'kuband_param_2011_Greenland_P3.xls';
% param_fns{end+1} = 'kuband_param_2011_Antarctica_DC8.xls';
% param_fns{end+1} = 'kuband_param_2011_Antarctica_TO.xls';
% param_fns{end+1} = 'kuband_param_2012_Greenland_P3.xls';
% param_fns{end+1} = 'kuband_param_2012_Antarctica_DC8.xls';
% param_fns{end+1} = 'kuband_param_2013_Greenland_P3.xls';
% param_fns{end+1} = 'kuband_param_2013_Antarctica_P3.xls';
% param_fns{end+1} = 'kuband_param_2013_Antarctica_Basler.xls';
% param_fns{end+1} = 'kuband_param_2014_Antarctica_DC8.xls';
% param_fns{end+1} = 'kuband_param_2014_Greenland_P3.xls';
% param_fns{end+1} = 'kuband_param_2015_Greenland_C130.xls';
% param_fns{end+1} = 'kuband_param_2016_Greenland_P3.xls';
% param_fns{end+1} = 'kuband_param_2016_Antarctica_DC8.xls';
% param_fns{end+1} = 'kuband_param_2019_Greenland_TO.xls';

%% CReSIS Radar Depth Sounder (RDS)
% param_fns{end+1} = 'rds_param_2009_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2009_Antarctica_TO.xls';
% param_fns{end+1} = 'rds_param_2010_Greenland_DC8.xls';
% param_fns{end+1} = 'rds_param_2010_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2010_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2011_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2011_Antarctica_TO.xls';
% param_fns{end+1} = 'rds_param_2011_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2012_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2012_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2013_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2013_Antarctica_P3.xls';
% param_fns{end+1} = 'rds_param_2013_Antarctica_Basler.xls';
% param_fns{end+1} = 'rds_param_2014_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2014_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2015_Greenland_C130.xls';
% param_fns{end+1} = 'rds_param_2016_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2016_Greenland_G1XB.xls';
% param_fns{end+1} = 'rds_param_2016_Greenland_Polar6.xls';
% param_fns{end+1} = 'rds_param_2016_Greenland_TOdtu.xls';
% param_fns{end+1} = 'rds_param_2016_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2017_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2017_Antarctica_P3.xls';
% param_fns{end+1} = 'rds_param_2017_Antarctica_Basler.xls';
% param_fns{end+1} = 'rds_param_2018_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2018_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2018_Antarctica_Ground.xls';
% param_fns{end+1} = 'rds_param_2019_Antarctica_Ground.xls';
% param_fns{end+1} = 'rds_param_2019_Antarctica_GV.xls';
% param_fns{end+1} = 'rds_param_2019_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2022_Antarctica_GroundGHOST.xls';
% param_fns{end+1} = 'rds_param_2022_Antarctica_BaslerMKB.xls';

%% CReSIS Snow Radar
% param_fns{end+1} = 'snow_param_2009_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2009_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2010_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2010_Greenland_DC8.xls';
% param_fns{end+1} = 'snow_param_2010_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2011_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2011_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2012_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2012_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2013_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2013_Antarctica_P3.xls';
% param_fns{end+1} = 'snow_param_2013_Antarctica_Basler.xls';
% param_fns{end+1} = 'snow_param_2014_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2014_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2015_Greenland_C130.xls';
% param_fns{end+1} = 'snow_param_2016_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2016_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2017_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2017_Antarctica_P3.xls';
% param_fns{end+1} = 'snow_param_2018_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2018_Alaska_SO.xls';
% param_fns{end+1} = 'snow_param_2018_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2019_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2019_Arctic_GV.xls';
% param_fns{end+1} = 'snow_param_2019_Antarctica_GV.xls';
% param_fns{end+1} = 'snow_param_2019_SouthDakota_N1KU.xls';
% param_fns{end+1} = 'snow_param_2020_SouthDakota_N1KU.xls';
% param_fns{end+1} = 'snow_param_2022_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2022_Antarctica_GroundGHOST.xls';

%% CReSIS RDS (data products only)
% param_fns{end+1} = 'rds_param_2009_Greenland_TO_wise.xls'; % Data outputs only
% param_fns{end+1} = 'rds_param_2010_Greenland_TO_wise.xls'; % Data outputs only

%% CReSIS Accumulation Radar (not complete)

%% CReSIS Kuband (not complete)
% param_fns{end+1} = 'kuband_param_2014_Alaska_TOnrl.xls'; % Season not complete/NOT CREATED

%% CReSIS RDS (not complete)
% param_fns{end+1} = 'rds_param_1993_Greenland_P3.xls'; % ICARDS not supported
% param_fns{end+1} = 'rds_param_1995_Greenland_P3.xls'; % ICARDS not supported
% param_fns{end+1} = 'rds_param_1996_Greenland_P3.xls'; % ICARDS not supported
% param_fns{end+1} = 'rds_param_1997_Greenland_P3.xls'; % ICARDS not supported
% param_fns{end+1} = 'rds_param_1998_Greenland_P3.xls'; % ICARDS not supported
% param_fns{end+1} = 'rds_param_1999_Greenland_P3.xls'; % ICARDS not supported
% param_fns{end+1} = 'rds_param_2001_Greenland_P3.xls'; % ICARDS not supported
% param_fns{end+1} = 'rds_param_2002_Antarctica_P3chile.xls';  % ICARDS not supported
% param_fns{end+1} = 'rds_param_2002_Greenland_P3.xls'; % ICARDS not supported
% param_fns{end+1} = 'rds_param_2003_Greenland_P3.xls';  % ACORDS not supported
% param_fns{end+1} = 'rds_param_2004_Antarctica_P3chile.xls'; % ACORDS not supported
% param_fns{end+1} = 'rds_param_2005_Greenland_TO.xls'; % ACORDS not supported/NOT CREATED
% param_fns{end+1} = 'rds_param_2006_Greenland_TO.xls'; % MCRDS not supported
% param_fns{end+1} = 'rds_param_2007_Greenland_P3.xls'; % MCRDS not supported/NOT CREATED
% param_fns{end+1} = 'rds_param_2008_Greenland_Ground.xls'; % SAR not supported
% param_fns{end+1} = 'rds_param_2008_Greenland_TO.xls'; % MCRDS not supported
% param_fns{end+1} = 'rds_param_2009_Greenland_TO.xls'; % MCRDS not supported
% param_fns{end+1} = 'rds_param_2011_Greenland_TO.xls'; % Season not completed

%% CReSIS Snow Radar (not complete)
% param_fns{end+1} = 'snow_param_2013_Greenland_Ground.xls'; % Season not complete/NOT CREATED
% param_fns{end+1} = 'snow_param_2014_Alaska_TOnrl.xls'; % Season not complete/NOT CREATED
% param_fns{end+1} = 'snow_param_2015_Alaska_TOnrl.xls'; % Season not complete/NOT CREATED
% param_fns{end+1} = 'snow_param_2016_Alaska_TOnrl.xls'; % Season not complete/NOT CREATED
% param_fns{end+1} = 'snow_param_2021_Alaska_SO.xls'; % Season not complete/NOT CREATED

%% AWI Radar Depth Sounder
% rds_param_2015_Greenland_Polar6 % No good data from this season
% rds_param_2016_Greenland_Polar6 % Listed under CReSIS RDS
% param_fns{end+1} = 'rds_param_2017_Antarctica_Polar6.xls';
% param_fns{end+1} = 'rds_param_2018_Greenland_Polar6.xls';
% param_fns{end+1} = 'rds_param_2019_Antarctica_Polar6.xls';
% param_fns{end+1} = 'rds_param_2021_Greenland_Polar5.xls';
% param_fns{end+1} = 'rds_param_2022_Greenland_Polar5.xls';

%% AWI Snow Radar
% param_fns{end+1} = 'snow_param_2016_Greenland_Polar6.xls'; % Season not completed
% param_fns{end+1} = 'snow_param_2017_Arctic_Polar5.xls';
% param_fns{end+1} = 'snow_param_2019_Arctic_Polar6.xls';
% param_fns{end+1} = 'snow_param_2020_Arctic_Polar6.xls';
