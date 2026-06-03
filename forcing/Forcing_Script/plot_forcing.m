clc
clear all
close all

cd D:\Utilisateurs\lehmannb\Documents\0_Pro\16_PAPROG\2_Model\Grangettes\Cryogrid_Grangettes\CryoGridCommunity_forcing
load('FORCING_SAFRAN_elev_3200_slope_0_aspect_-1_01Aug1958_08Jun2023_added_TOA_albedo_0.1.mat')



%%
time = FORCING.data.t_span;

time = datetime(time,'ConvertFrom','datenum');
Lin= FORCING.data.Lin;
q = FORCING.data.q;
rainfall = FORCING.data.rainfall;
S_TOA = FORCING.data.S_TOA;
Sin = FORCING.data.Sin;
snowfall = FORCING.data.snowfall;
T = FORCING.data.Tair;
wind = FORCING.data.wind;
albedo = FORCING.data.albedo_foot;


%% Plotting

figure(1)

subplot(3,3,1)
plot(time,T)
xtickangle(45);
xticks('auto')
ylabel('Air Temp. [°C]')
axis tight

subplot(3,3,2)
plot(time,snowfall)
xtickangle(45);
xticks('auto')
ylabel('Snowfall rate [kg/m^2/s]')
axis tight

subplot(3,3,3)
plot(time,rainfall)
xtickangle(45);
xticks('auto')
ylabel('Rainfall rate [kg/m^2/s]')
axis tight

subplot(3,3,4)
plot(time,wind)
xtickangle(45);
xticks('auto')
ylabel('Wind [m/s]')
axis tight

subplot(3,3,5)
plot(time,q)
xtickangle(45);
xticks('auto')
ylabel('Specific humidity [kg/kg]')
axis tight

subplot(3,3,6)
plot(time,albedo)
xtickangle(45);
xticks('auto')
ylabel('albedo')
axis tight

subplot(3,3,7)
plot(time,S_TOA)
xtickangle(45);
xticks('auto')
ylabel('Inc. solar rad. TOA [J/m^2]')
axis tight

subplot(3,3,8)
plot(time,Sin)
xtickangle(45);
xticks('auto')
ylabel('Inc. Shortw. rad. [W/m^2]')
axis tight

subplot(3,3,9)
plot(time,Lin)
xtickangle(45);
xticks('auto')
ylabel('Inc. Long. rad. [W/m^2]')
axis tight


%%
%%
time = FORCING.data.t_span;
time = datetime(time, 'ConvertFrom', 'datenum'); % Convert time to datetime format

% Define the date range for the plot
start_date = datetime(2021, 10, 1); % 1st October 2021
end_date = datetime(2022, 11, 30);  % 30th November 2022

% Find the indices that match the time range
time_idx = (time >= start_date) & (time <= end_date);

% Filter the data based on the selected time range
time_filtered = time(time_idx);
Lin_filtered = FORCING.data.Lin(time_idx);
q_filtered = FORCING.data.q(time_idx);
rainfall_filtered = FORCING.data.rainfall(time_idx);
S_TOA_filtered = FORCING.data.S_TOA(time_idx);
Sin_filtered = FORCING.data.Sin(time_idx);
snowfall_filtered = FORCING.data.snowfall(time_idx);
T_filtered = FORCING.data.Tair(time_idx);
wind_filtered = FORCING.data.wind(time_idx);
albedo_filtered = FORCING.data.albedo_foot(time_idx);

%% Plotting

figure(2)

subplot(3,3,1)
plot(time_filtered, T_filtered)
xtickangle(45);
xticks('auto')
title('Air Temperature [°C]')
axis tight
set(gca,'XTick',[])

subplot(3,3,2)
plot(time_filtered, snowfall_filtered)
xtickangle(45);
xticks('auto')
title('Snowfall rate [kg/m^2/s]')
axis tight
set(gca,'XTick',[])

subplot(3,3,5)
plot(time_filtered, rainfall_filtered)
xtickangle(45);
xticks('auto')
title('Rainfall rate [kg/m^2/s]')
axis tight
set(gca,'XTick',[])

subplot(3,3,7)
plot(time_filtered, wind_filtered)
xtickangle(45);
xticks('auto')
title('Wind speed [m/s]')
axis tight

subplot(3,3,4)
plot(time_filtered, q_filtered)
xtickangle(45);
xticks('auto')
title('Specific humidity [kg/kg]')
axis tight
set(gca,'XTick',[])


subplot(3,3,8)
plot(time_filtered, albedo_filtered)
xtickangle(45);
xticks('auto')
title('Albedo')
axis tight

subplot(3,3,3)
plot(time_filtered, S_TOA_filtered)
xtickangle(45);
xticks('auto')
title('Incident solar rad. TOA [J/m^2]')
axis tight
set(gca,'XTick',[])

subplot(3,3,6)
plot(time_filtered, Sin_filtered)
xtickangle(45);
xticks('auto')
title('Incident Shortwave rad. [W/m^2]')
axis tight
set(gca,'XTick',[])

subplot(3,3,9)
plot(time_filtered, Lin_filtered)
xtickangle(45);
xticks('auto')
title('Incident Longwave rad. [W/m^2]')
axis tight
