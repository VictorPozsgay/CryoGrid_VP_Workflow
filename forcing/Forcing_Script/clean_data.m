function [TTout] = clean_data(TT)
% resample_handle=1;
% path_to_data='D:\Dropbox (BGU)\Research2\WISPER\data\AdM_UGA\';
% fileame='UGA_Aiguille_du_midi_MetSt.mat';
% load([path_to_data fileame]) % load data

% TT=AIGUILLE1_timetable; % save data to variable

%% sort data an clear duplicates
natRowTimes = ismissing(TT.Properties.RowTimes); % find rows without time data
goodRowTimesTT = TT(~natRowTimes,:); % keep only rows with time data
goodValuesTT = rmmissing(goodRowTimesTT,'MinNumMissing',size(TT,2)); % remove rows with all data missing

clear natRowTimes goodRowTimesTT

if ~issorted(goodValuesTT) % check is table is sorted
    sortedTT = sortrows(goodValuesTT);
else
    sortedTT = goodValuesTT;
end

if ~isregular(sortedTT)
    sortedTT = unique(sortedTT); % remove duplicates (I assume that all duplicates have the same data. to check if time duplicates contain differen data additional action needs to be taken)
end

if min(diff(sortedTT.Properties.RowTimes))==0 % check if soretd 2nd time - if not ther are time duplicates with differen data
    
    uniqueRowsTT = unique(sortedTT);
    %     dupTimes = sort(uniqueRowsTT.Properties.RowTimes); % sort the row times
    %     tf = (diff(dupTimes) == 0); % find consecutive times that have no difference between them
    uniqueTimes = unique(uniqueRowsTT.Properties.RowTimes);
    remvdupTT = retime(uniqueRowsTT,uniqueTimes,'firstvalue'); % remov duplicate times
else
    remvdupTT=sortedTT;
    clear uniqueRowsTT uniqueTimes
end

% if resample_handle==0
    
    TTout=sortrows(remvdupTT);

% elseif resample_handle==1
%     %% analyze time gaps in data
%     
%     % analysis of time gaps
%     
%     
%     diffT=diff(remvdupTT.Properties.RowTimes);
%     longest_missing_time_gap = max(diffT);
%     number_of_time_gaps = sum(diffT~=mode(diffT));
%     total_missing_time = sum(diffT(diffT~=mode(diffT))) - number_of_time_gaps*mode(diffT);
%     total_time_of_measurement=range(sortedTT.Properties.RowTimes); % total_time_of_measurement.Format='dd:hh:mm:ss'
%     fraction_of_time_gaps_from_total=total_missing_time/total_time_of_measurement;
%     
%     %% resample data for different time steps
%     
%     dt = hours(3); % time step for resampling the data
%     
%     TT_mean=remvdupTT(:,{'AirTC_Avg','RH','WS_ms_Avg','WindDir','intensiteTR'}); % columns with data to be averaged on resampling
%     
%     TT_resampled = retime(sortrows(TT_mean),'regular','mean','TimeStep',dt); % create averaged timetable
%     TTout=TT_resampled;
%     if any(diff(TT_resampled.Properties.RowTimes) ~= mode(diff(TT_resampled.Properties.RowTimes))) % check if time spacing is constant
%         disp('time steps are not constant')
%     end
% end
end
