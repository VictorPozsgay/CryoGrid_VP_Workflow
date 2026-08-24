function plot_forcing_diagnostics(meteo_path,diagnostic_path)
%PLOT_FORCING_DIAGNOSTICS Comprehensive CryoGrid forcing diagnostics.
%
% Automatically analyses all massifs contained in a CryoGrid forcing file.
%
% Generates:
%   1) Vertical atmospheric state
%   2) Radiation profiles
%   3) Gradient diagnostics
%   4) Representative time series
%   5) Seasonal climatology
%
% INPUT
%   meteo_path
%       Path to the CryoGrid-ready forcing directory containing:
%
%           FORCING_SAFRAN_ALL.mat
%
%   diagnostic_path
%       Output folder where diagnostic figures will be saved.
%
% OUTPUT
%   Creates:
%
%       <diagnostic_path>/
%
%       massif_x_name/
%           vertical_state.png
%           radiation_profiles.png
%           gradients.png
%           time_series.png
%           seasonal_cycle.png
%
%   Each folder contains graphical diagnostics for one SAFRAN massif.
%

%% ========================================================================
% Load forcing
% ========================================================================

fprintf("\n")
fprintf("============================================================\n")
fprintf(" CryoGrid forcing diagnostics\n")
fprintf("============================================================\n\n")

forcing_file = fullfile(meteo_path,"FORCING_SAFRAN_ALL.mat");
fprintf("Loading:\n%s\n\n",forcing_file)

if ~isfile(forcing_file)
    error("Forcing file not found:\n%s",forcing_file)
end

S = load(forcing_file,"FORCING");
FORCING = S.FORCING;
Nm = numel(FORCING);

fprintf("Found %d massifs\n\n",Nm)


%% ========================================================================
% Output folder
% ========================================================================

output_folder = fullfile(diagnostic_path);

if ~isfolder(output_folder)
    mkdir(output_folder)
end


%% ========================================================================
% Loop over massifs
% ========================================================================

for im = 1:Nm
    fprintf("Processing massif %d / %d\n",im,Nm)
    D = FORCING(im).data;

    %% ------------------------------------------------------------
    % Metadata
    %% ------------------------------------------------------------

    massif_name = string(FORCING(im).name);
    massif_num = FORCING(im).massif_num;

    massif_folder = fullfile( ...
        output_folder,...
        sprintf("massif_%d_%s",massif_num,massif_name));
    
    if ~isfolder(massif_folder)
        mkdir(massif_folder)
    end
    
    %% ------------------------------------------------------------
    % Existing diagnostic products
    %% ------------------------------------------------------------
    
    expected_files = [
        fullfile(massif_folder,"vertical_state.png")
        fullfile(massif_folder,"radiation_profiles.png")
        fullfile(massif_folder,"gradients.png")
        fullfile(massif_folder,"time_series.png")
        fullfile(massif_folder,"seasonal_cycle.png")
    ];
    
    if all(isfile(expected_files))
    
        fprintf("  All diagnostic plots already exist - skipping massif.\n\n")
        continue
    
    end

    z = double(D.z(:));
    Nz = numel(z);
    fprintf("  %s (%d elevations)\n",massif_name,Nz)

    %% ------------------------------------------------------------
    % Mean vertical quantities
    %% ------------------------------------------------------------

    Tmean = mean(D.Tair,1,'omitnan');
    qmean = mean(D.q,1,'omitnan');
    wmean = mean(D.wind,1,'omitnan');
    snowfrac = mean(D.snowfall>0,1);

    %% ------------------------------------------------------------
    % Figure 1: Vertical atmospheric state
    %% ------------------------------------------------------------

    fig = figure("Color","w","Position",[100 100 1200 800]);
    tl = tiledlayout(2,2,"TileSpacing","compact");
    title(tl,...
        sprintf("Vertical atmospheric state - %s",massif_name),...
        "Interpreter","none")

    % Temperature
    nexttile
    plot(Tmean,z,"-o","LineWidth",1.5)

    grid on

    xlabel("Temperature (°C)")
    ylabel("Elevation (m)")
    title("Mean temperature profile")

    % Humidity
    nexttile
    plot(qmean*1000,z,"-o","LineWidth",1.5)

    grid on

    xlabel("Specific humidity (g/kg)")
    ylabel("Elevation (m)")
    title("Mean humidity profile")

    % Wind
    nexttile
    plot(wmean,z,"-o","LineWidth",1.5)

    grid on

    xlabel("Wind speed (m/s)")
    ylabel("Elevation (m)")
    title("Mean wind profile")

    % Snow occurrence
    nexttile
    plot(snowfrac,z,"-o","LineWidth",1.5)

    grid on

    xlabel("Snowfall occurrence fraction")
    ylabel("Elevation (m)")
    xlim([0 1])
    title("Snow occurrence")

    saveas(fig,...
        fullfile(massif_folder,...
        "vertical_state.png"))

    close(fig)

    %% ------------------------------------------------------------
    % Radiation diagnostics
    %% ------------------------------------------------------------

    Linmean = mean(D.Lin,1,'omitnan');
    Sinmean = mean(D.Sin,1,'omitnan');
    S_TOA_mean = mean(D.S_TOA,'omitnan');

    fig = figure("Color","w","Position",[100 100 1000 700]);

    tl = tiledlayout(1,2,"TileSpacing","compact");
    title(tl,...
        sprintf("Radiation profiles - %s",massif_name),...
        "Interpreter","none")

    %% Longwave
    nexttile
    plot(Linmean,z,"-o","LineWidth",1.5)

    grid on

    xlabel("Lin (W/m^2)")
    ylabel("Elevation (m)")
    title("Atmospheric longwave radiation")

    %% Shortwave
    nexttile
    plot(Sinmean,z,"-o","LineWidth",1.5)

    hold on

    plot(ones(size(z))*S_TOA_mean,z,"--","LineWidth",1.2)
    legend(...
        "Surface incoming SW",...
        "TOA mean",...
        "Location","best")

    grid on

    xlabel("Radiation (W/m^2)")
    ylabel("Elevation (m)")
    title("Shortwave radiation")

    saveas(fig,...
        fullfile(massif_folder,...
        "radiation_profiles.png"))

    close(fig)


    %% ------------------------------------------------------------
    % Vertical gradients
    %% ------------------------------------------------------------

    % Temperature lapse rate
    fit_T = polyfit(z/1000,Tmean,1);
    lapse_rate = fit_T(1);

    % Pressure scale height
    pmean = mean(D.p,1,'omitnan');
    fit_p = polyfit(z,log(pmean),1);
    scale_height = -1/fit_p(1);

    % Humidity
    fit_q = polyfit(z/1000,qmean,1);
    q_gradient = fit_q(1);

    % Radiation
    fit_Lin = polyfit(z/1000,Linmean,1);
    Lin_gradient = fit_Lin(1);
    fit_Sin = polyfit(z/1000,Sinmean,1);
    Sin_gradient = fit_Sin(1);

    % Wind
    fit_wind = polyfit(z/1000,wmean,1);
    wind_gradient = fit_wind(1);

    % Snow occurrence
    fit_snow = polyfit(z/1000,snowfrac,1);
    snow_gradient = fit_snow(1);


    %% ------------------------------------------------------------
    % Gradient summary figure
    %% ------------------------------------------------------------


    fig = figure("Color","w","Position",[100 100 900 600]);
    axis off

    summary = {
        sprintf("Temperature lapse rate : %.2f °C/km",...
        lapse_rate)
        sprintf("Pressure scale height  : %.0f m",...
        scale_height)
        sprintf("Humidity gradient     : %.3e kg/kg/km",...
        q_gradient)
        sprintf("Longwave gradient     : %.2f W/m2/km",...
        Lin_gradient)
        sprintf("Shortwave gradient    : %.2f W/m2/km",...
        Sin_gradient)
        sprintf("Wind gradient         : %.2f m/s/km",...
        wind_gradient)
        sprintf("Snow occurrence slope : %.3f /km",...
        snow_gradient)
        ""
        "Physical expectations:"
        "  Tair  : negative lapse rate"
        "  Lin   : decreases with altitude"
        "  Sin   : increases with altitude"
        "  q     : decreases with altitude"
        "  wind  : usually increases"
        "  snow  : increases with altitude"
        };

    text(0.05,0.95,...
        summary,...
        "VerticalAlignment","top",...
        "FontSize",12)

    title(sprintf("Vertical gradient diagnostics - %s",...
        massif_name),...
        "Interpreter","none")

    saveas(fig,...
        fullfile(massif_folder,...
        "gradients.png"))

    close(fig)

    %% ------------------------------------------------------------
    % Representative time series
    %% ------------------------------------------------------------

    Nt = size(D.Tair,1);


    % Select lowest, middle, highest elevations automatically

    ind_levels = unique(round([1,ceil(Nz/2),Nz]));
    colors = lines(numel(ind_levels));


    % Last 5 years (if available)

    t = datetime(double(D.t_span),'ConvertFrom','datenum');
    t_end = t(end);
    t_start = t_end - calyears(5);
    ind_time = t >= t_start;

    fig = figure("Color","w","Position",[100 100 1200 900]);

    tl = tiledlayout(2,2,"TileSpacing","compact");

    title(tl,...
        sprintf("Recent forcing evolution - %s",massif_name),...
        "Interpreter","none")

    %% Temperature
    nexttile
    hold on

    for k = 1:numel(ind_levels)
        iz = ind_levels(k);
        plot(t(ind_time),...
            D.Tair(ind_time,iz),...
            "LineWidth",1.2,...
            "DisplayName",...
            sprintf("%.0f m",z(iz)))
    end

    grid on
    ylabel("Temperature (°C)")
    legend("Location","best")
    title("Air temperature")

    %% Shortwave
    nexttile
    hold on
        
    % Plot highest elevations first, lowest last
    for k = numel(ind_levels):-1:1
        iz = ind_levels(k);
        plot(t(ind_time), ...
            D.Sin(ind_time,iz), ...
            "Color", colors(k,:), ...
            "LineWidth", 1.2, ...
            "DisplayName", sprintf("%.0f m", z(iz)));
    end
    
    grid on
    ylabel("Sin (W/m^2)")
    title("Incoming shortwave")

    %% Snowfall
    nexttile
    hold on

    % Plot highest elevations first, lowest last
    for k = numel(ind_levels):-1:1
        iz = ind_levels(k);
        plot(t(ind_time),...
            D.snowfall(ind_time,iz), ...
            "Color", colors(k,:),...
            "LineWidth",1.2,...
            "DisplayName",...
            sprintf("%.0f m",z(iz)))
    end

    grid on
    ylabel("Snowfall")
    title("Snowfall forcing")

    %% Longwave
    nexttile
    hold on

    for k = 1:numel(ind_levels)
        iz = ind_levels(k);
        plot(t(ind_time),...
            D.Lin(ind_time,iz),...
            "LineWidth",1.2,...
            "DisplayName",...
            sprintf("%.0f m",z(iz)))
    end

    grid on
    ylabel("Lin (W/m^2)")
    title("Incoming longwave")

    saveas(fig,...
        fullfile(massif_folder,...
        "time_series.png"))

    close(fig)


    %% ------------------------------------------------------------
    % Seasonal climatology
    %% ------------------------------------------------------------


    if isdatetime(t)


        month_id = month(t);


        fig = figure(...
            "Color","w",...
            "Position",[100 100 1200 700]);


        tl = tiledlayout(1,3,...
            "TileSpacing","compact");


        title(tl,...
            sprintf("Seasonal cycle - %s",massif_name),...
            "Interpreter","none")



        variables = {
            D.Tair,...
            D.Sin,...
            D.snowfall};


        labels = {
            "Temperature (°C)",...
            "Sin (W/m^2)",...
            "Snowfall"};



        titles = {
            "Monthly temperature",...
            "Monthly shortwave",...
            "Monthly snowfall"};



        for iv = 1:3


            nexttile

            hold on


            for k = 1:numel(ind_levels)


                iz = ind_levels(k);


                monthly = zeros(12,1);


                for m = 1:12

                    monthly(m) = mean(...
                        variables{iv}(month_id==m,iz),...
                        "omitnan");

                end


                plot(1:12,...
                    monthly,...
                    "-o",...
                    "LineWidth",1.2,...
                    "DisplayName",...
                    sprintf("%.0f m",z(iz)))

            end


            grid on

            xlim([1 12])

            xticks(1:12)

            xlabel("Month")

            ylabel(labels{iv})

            title(titles{iv})

            legend("Location","best")


        end



        saveas(fig,...
            fullfile(massif_folder,...
            "seasonal_cycle.png"))


        close(fig)

    end





    %% ------------------------------------------------------------
    % Console summary
    %% ------------------------------------------------------------

    fprintf("  Finished %s\n",massif_name)
    fprintf("    lapse rate : %.2f °C/km\n",lapse_rate)
    fprintf("    Lin grad   : %.2f W/m2/km\n",Lin_gradient)
    fprintf("    Sin grad   : %.2f W/m2/km\n",Sin_gradient)
    fprintf("    wind grad  : %.2f m/s/km\n",wind_gradient)
    fprintf("\n")

end   % massif loop


fprintf("\n")
fprintf("============================================================\n")
fprintf(" Diagnostics completed successfully\n")
fprintf(" Output:\n%s\n",output_folder)
fprintf("============================================================\n")


end