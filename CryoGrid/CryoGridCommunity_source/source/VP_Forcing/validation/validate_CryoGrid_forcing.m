function validate_CryoGrid_forcing(meteo_path,diagnostic_path)
%VALIDATE_CRYOGRID_FORCING Comprehensive CryoGrid forcing quality control.
%
% VALIDATE_CRYOGRID_FORCING(FORCING_FILE)
%
% Creates:
%   FORCING_validation_report.txt
%
% Performs:
%   - structural validation
%   - statistical diagnostics
%   - temporal diagnostics
%   - vertical atmospheric diagnostics
%   - physical consistency checks
%   - warning summary
%
% INPUT
%   meteo_path
%       Path to the CryoGrid-ready forcing directory containing:
%
%           FORCING_SAFRAN_ALL.mat
%
%   diagnostic_path
%       Output folder where the validation report will be written.
%
% OUTPUT
%   Creates:
%
%       <diagnostic_path>/
%
%           FORCING_validation_report.txt
%
%       The report contains:
%           - general dataset structure
%           - massif metadata
%           - variable dimensions and storage classes
%           - temporal consistency checks
%           - statistical summaries
%           - vertical atmospheric diagnostics
%           - physical consistency checks
%           - warning summary
% 

%% ========================================================================
% Initialisation
% ========================================================================

fprintf('\n')
fprintf('============================================================\n')
fprintf(' CryoGrid forcing validation\n')
fprintf('============================================================\n\n')

forcing_file = fullfile(meteo_path,"FORCING_SAFRAN_ALL.mat");
if ~isfile(forcing_file)
    error("File not found:\n%s",forcing_file)
end


%% Output file

report_file = fullfile(diagnostic_path,...
    "FORCING_validation_report.txt");

fid = fopen(report_file,'w');

if fid==-1
    error("Could not create report file.")
end

cleanup = onCleanup(@() fclose(fid));

%% Warning storage

warnings = {};
warning_id = 0;

%% Load forcing

fprintf(fid,...
"============================================================\n");
fprintf(fid,...
" CryoGrid forcing validation report\n");
fprintf(fid,...
"============================================================\n\n");

fprintf(fid,"Input file:\n%s\n\n",forcing_file);
fprintf('\nLoading:\n%s\n',forcing_file)
data = load(forcing_file);

if ~isfield(data,"FORCING")
    add_warning( ...
        "CRITICAL",...
        "Missing FORCING structure.",...
        "")
    error("FORCING structure missing.")
end

FORCING = data.FORCING;

%% ========================================================================
% General structure
% ========================================================================

fprintf(fid,...
"GENERAL STRUCTURE\n");
fprintf(fid,...
"-----------------\n");

Nm = numel(FORCING);

fprintf(fid,"Number of massifs : %d\n\n",Nm);
fprintf(fid,"Massifs:\n");

for i = 1:Nm
    name = FORCING(i).name;
    if isfield(FORCING(i),"data") && ...
            isfield(FORCING(i).data,"z")
        Nz = numel(FORCING(i).data.z);
    else
        Nz = NaN;
    end

    fprintf(fid,...
        "%3d : %-20s (%d levels)\n",...
        FORCING(i).massif_num,...
        name,...
        Nz);

end


%% ========================================================================
% Variable list
% ========================================================================

variables = [
    "Tair"
    "Lin"
    "Sin"
    "q"
    "wind"
    "p"
    "rainfall"
    "snowfall"
    "t_span"
    "S_TOA"
    "z"
];


%% ========================================================================
% Loop over massifs
% ========================================================================


for im = 1:Nm
    D = FORCING(im).data;

    massif_name = FORCING(im).name;
    massif_id = FORCING(im).massif_num;

    fprintf(fid,"\n\n");
    fprintf(fid,...
        "============================================================\n");
    fprintf(fid,...
        " MASSIF %d : %s\n",...
        massif_id,...
        massif_name);
    fprintf(fid,...
        "============================================================\n\n");

    %% ---------------------------------------------------------------
    % Metadata
    % ---------------------------------------------------------------

    fprintf(fid,"METADATA\n");
    fprintf(fid,"-----------------\n");

    if isfield(FORCING(im),"lat")
        fprintf(fid,...
            "Latitude  : %.6f\n",...
            FORCING(im).lat);
    end

    if isfield(FORCING(im),"lon")
        fprintf(fid,...
            "Longitude : %.6f\n",...
            FORCING(im).lon);
    end


    if isfield(D,"z")
        z = double(D.z(:));
        fprintf(fid,"Elevation levels:\n");
        fprintf(fid,"  Nz  = %d\n",numel(z));
        fprintf(fid,"  min = %.1f m\n",min(z));
        fprintf(fid,"  max = %.1f m\n",max(z));
        fprintf(fid,"  levels = ");
        fprintf(fid,"%.0f ",z);
        fprintf(fid,"\n");

        if any(diff(z)<=0)
            add_warning(...
                "CRITICAL",...
                sprintf(...
                "Massif %d: elevation levels are not strictly increasing.",...
                massif_id),...
                "")
        end
    else
        add_warning(...
            "CRITICAL",...
            sprintf(...
            "Massif %d: missing elevation vector z.",...
            massif_id),...
            "")
        z=[];
    end

    fprintf(fid,"\n");

    %% ---------------------------------------------------------------
    % Dimensions
    % ---------------------------------------------------------------

    fprintf(fid,"DIMENSIONS\n");
    fprintf(fid,"-----------------\n");

    for iv = 1:numel(variables)
        v = variables(iv);
        if isfield(D,v)
            sz = size(D.(v));
            fprintf(fid,"%15s : [%s]\n",v,num2str(sz));
        end
    end

    %% ---------------------------------------------------------------
    % Storage class
    % ---------------------------------------------------------------

    fprintf(fid,"\nSTORAGE CLASS\n");
    fprintf(fid,"-----------------\n");

    for iv = 1:numel(variables)
        v = variables(iv);
        if isfield(D,v)
            fprintf(fid,"%15s : %s\n",v,class(D.(v)));
        end
    end

    %% ---------------------------------------------------------------
    % Time diagnostics
    % ---------------------------------------------------------------

    fprintf(fid,"\nTIME\n");
    fprintf(fid,"-----------------\n");

    if isfield(D,"t_span")
        t = datetime(D.t_span,"ConvertFrom","datenum");
        dt = hours(diff(t));
        fprintf(fid,"Start : %s\n",datestr(t(1)));
        fprintf(fid,"End   : %s\n",datestr(t(end)));
        years = days(t(end)-t(1))/365.25;
        fprintf(fid,"Duration : %.3f years\n",years);
        fprintf(fid,"Timesteps : %d\n\n",numel(t));
        fprintf(fid,"Timestep statistics:\n");
        fprintf(fid,"  mean : %.6f hours\n",mean(dt));
        fprintf(fid,"  min  : %.6f hours\n",min(dt));
        fprintf(fid,"  max  : %.6f hours\n",max(dt));
        fprintf(fid,"\nUnique timestep values:\n");
        [u,~,ic] = unique(dt);
        for k = 1:numel(u)
            fprintf(fid,...
                "  %.6f hours : %d occurrences\n",...
                u(k),sum(ic==k));
        end

        if all(abs(dt-3)<1e-6)
            fprintf(fid,"\nPASS: perfectly 3-hourly forcing\n");
        else
            add_warning(...
                "WARNING",...
                sprintf(...
                "Massif %d: timestep is not perfectly 3-hourly.",...
                massif_id),...
                "")
        end
    else
        add_warning(...
            "CRITICAL",...
            sprintf(...
            "Massif %d: missing t_span.",...
            massif_id),...
            "")
    end

    %% ---------------------------------------------------------------
    % Variable statistics
    % ---------------------------------------------------------------

    fprintf(fid,"\n\n");
    fprintf(fid,...
        "VARIABLE STATISTICS\n");
    fprintf(fid,...
        "============================================================\n");

    stat_variables = [
        "Tair"
        "Lin"
        "Sin"
        "q"
        "wind"
        "p"
        "rainfall"
        "snowfall"
        "S_TOA"
    ];


    for iv = 1:numel(stat_variables)
        v = stat_variables(iv);
        if ~isfield(D,v)
            continue
        end
        X = double(D.(v));

        fprintf(fid,"\n%s\n",v);
        fprintf(fid,"-----------------\n");

        fprintf(fid,"Size      : [%s]\n",num2str(size(X)));
        fprintf(fid,"Class     : %s\n",class(D.(v)));
        fprintf(fid,"Min       : %.6g\n",min(X(:),[],'omitnan'));
        fprintf(fid,"Max       : %.6g\n",max(X(:),[],'omitnan'));
        fprintf(fid,"Mean      : %.6g\n",mean(X(:),'omitnan'));
        fprintf(fid,"Std       : %.6g\n",std(X(:),'omitnan'));

        n_nan = sum(isnan(X(:)));
        n_inf = sum(isinf(X(:)));
        n_zer = sum(X(:)==0);
        n_neg = sum(X(:)<0);

        fprintf(fid,"NaN       : %d (%.4f%%)\n",n_nan,100*n_nan/numel(X));
        fprintf(fid,"Inf       : %d\n",n_inf);
        fprintf(fid,"Zero      : %d (%.4f%%)\n",n_zer,100*n_zer/numel(X));
        fprintf(fid,"Negative  : %d (%.4f%%)\n",n_neg,100*n_neg/numel(X));

        q = prctile(X(:),[1 5 50 95 99]);
        fprintf(fid,"Percentiles:\n");
        fprintf(fid,"  1%%   %.6g\n",q(1));
        fprintf(fid,"  5%%   %.6g\n",q(2));
        fprintf(fid," 50%%   %.6g\n",q(3));
        fprintf(fid," 95%%   %.6g\n",q(4));
        fprintf(fid," 99%%   %.6g\n",q(5));

        %% ============================================================
        % Automated variable checks
        % ============================================================


        if n_nan>0
            add_warning(...
                "CRITICAL",...
                sprintf(...
                "Massif %d: variable %s contains NaN values.",...
                massif_id,v),...
                "")
        end

        if n_inf>0
            add_warning(...
                "CRITICAL",...
                sprintf(...
                "Massif %d: variable %s contains Inf values.",...
                massif_id,v),...
                "")
        end

        switch v
            case "Tair"
                if min(X(:)) < -60
                    add_warning(...
                        "WARNING",...
                        sprintf(...
                        "Massif %d: extremely low temperature (< -60 C).",...
                        massif_id),...
                        "")
                end

                if max(X(:)) > 50
                    add_warning(...
                        "WARNING",...
                        sprintf(...
                        "Massif %d: extremely high temperature (>50 C).",...
                        massif_id),...
                        "")
                end

            case "Lin"
                if any(X(:)<0) || max(X(:))>500
                    add_warning(...
                        "WARNING",...
                        sprintf(...
                        "Massif %d: suspicious longwave radiation range.",...
                        massif_id),...
                        "")
                end

            case "Sin"
                if any(X(:)<0)
                    add_warning(...
                        "CRITICAL",...
                        sprintf(...
                        "Massif %d: negative shortwave radiation.",...
                        massif_id),...
                        "")
                end

            case "S_TOA"
                if max(X(:))>1400
                    add_warning(...
                        "WARNING",...
                        sprintf(...
                        "Massif %d: TOA radiation exceeds solar constant.",...
                        massif_id),...
                        "")
                end

            case "q"
                if any(X(:)<0)
                    add_warning(...
                        "CRITICAL",...
                        sprintf(...
                        "Massif %d: negative specific humidity.",...
                        massif_id),...
                        "")
                end

                if max(X(:))>0.04
                    add_warning(...
                        "WARNING",...
                        sprintf(...
                        "Massif %d: unusually high humidity.",...
                        massif_id),...
                        "")
                end

            case "wind"
                if any(X(:)<0)
                    add_warning(...
                        "CRITICAL",...
                        sprintf(...
                        "Massif %d: negative wind speed.",...
                        massif_id),...
                        "")
                end

                if max(X(:))>60
                    add_warning(...
                        "WARNING",...
                        sprintf(...
                        "Massif %d: extreme wind speed (>60 m/s).",...
                        massif_id),...
                        "")
                end

            case {"rainfall","snowfall"}
                if any(X(:)<0)
                    add_warning(...
                        "CRITICAL",...
                        sprintf(...
                        "Massif %d: negative precipitation.",...
                        massif_id),...
                        "")
                end

                daily_max = max(X(:));
                if daily_max>500
                    add_warning(...
                        "WARNING",...
                        sprintf(...
                        "Massif %d: extreme precipitation event %.1f mm/day.",...
                        massif_id,...
                        daily_max),...
                        "")
                end
        end
    end


    %% ---------------------------------------------------------------
    % Radiation transmission diagnostic
    % ---------------------------------------------------------------

    if isfield(D,"Sin") && isfield(D,"S_TOA")
        ratio = double(D.Sin)./double(D.S_TOA);
        ratio = ratio(isfinite(ratio));

        fprintf(fid,"\n\nRadiation transmission\n");
        fprintf(fid,"-----------------\n");
        fprintf(fid,...
            "Mean Sin/S_TOA : %.3f\n",...
            mean(ratio(ratio>0),'omitnan'));

        if mean(ratio(ratio>0),'omitnan')>0.9
            add_warning(...
                "WARNING",...
                sprintf(...
                "Massif %d: atmospheric transmission suspiciously high.",...
                massif_id),...
                "")
        end

        if any(ratio>1.05)
            add_warning(...
                "WARNING",...
                sprintf(...
                "Massif %d: Sin exceeds TOA radiation.",...
                massif_id),...
                "")
        end
    end

    %% ---------------------------------------------------------------
    % Snow / temperature consistency
    % ---------------------------------------------------------------

    if isfield(D,"snowfall") && isfield(D,"Tair")
        warm_snow = D.snowfall>0 & D.Tair>5;
        if any(warm_snow(:))
            add_warning(...
                "WARNING",...
                sprintf(...
                "Massif %d: snowfall occurs above +5 C.",...
                massif_id),...
                "")
        end

        rain_cold = D.rainfall>0 & D.Tair<-10;
        if any(rain_cold(:))
            add_warning(...
                "WARNING",...
                sprintf(...
                "Massif %d: rainfall occurs below -10 C.",...
                massif_id),...
                "")
        end
    end

    %% ---------------------------------------------------------------
    % Vertical profile diagnostics
    % ---------------------------------------------------------------

    if ~isempty(z) && numel(z)>1
        fprintf(fid,"\n\n");
        fprintf(fid,"VERTICAL PROFILE DIAGNOSTICS\n");
        fprintf(fid,"-----------------------------\n\n");
        fprintf(fid,"Mean vertical profiles:\n\n");

        % Mean profiles

        Tm = mean(double(D.Tair),1,'omitnan');
        pm = mean(double(D.p),1,'omitnan');
        qm = mean(double(D.q),1,'omitnan');
        wm = mean(double(D.wind),1,'omitnan');
        lm = mean(double(D.Lin),1,'omitnan');
        sm = mean(double(D.Sin),1,'omitnan');

        snow_frac = mean(double(D.snowfall)>0,1);

        fprintf(fid,...
            "    z(m)      Tair(C)        p(Pa)     q(kg/kg)    wind(m/s)    Lin(W/m2)    Sin(W/m2)    snow_frac\n");

        for iz = 1:numel(z)
            fprintf(fid,...
                "%8.0f %12.3f %12.1f %12.5f %12.3f %12.2f %12.2f %12.3f\n",...
                z(iz),...
                Tm(iz),...
                pm(iz),...
                qm(iz),...
                wm(iz),...
                lm(iz),...
                sm(iz),...
                snow_frac(iz));
        end

        %% Temperature lapse rate

        lapse = (Tm(end)-Tm(1))/(z(end)-z(1))*1000;
        fprintf(fid,"\nTemperature lapse rate:\n");
        fprintf(fid,"  %.3f °C/km\n",lapse);

        if lapse < -8 || lapse > -3
            add_warning(...
                "WARNING",...
                sprintf(...
                "Massif %d: unrealistic lapse rate %.2f C/km.",...
                massif_id,lapse),...
                "")
        else
            fprintf(fid,"  PASS: realistic Alpine lapse rate\n");
        end

        %% Pressure scale height
        H = -(z(end)-z(1))/log(pm(end)/pm(1));
        fprintf(fid,"\nPressure profile:\n");
        fprintf(fid,"  Equivalent scale height: %.0f m\n",H);
        if H<7000 || H>9000
            add_warning(...
                "WARNING",...
                sprintf(...
                "Massif %d: unusual atmospheric scale height %.0f m.",...
                massif_id,H),...
                "")
        else
            fprintf(fid,"  PASS: realistic atmosphere\n");
        end

        %% Radiation gradients
        Lin_grad = (lm(end)-lm(1))/(z(end)-z(1))*1000;
        Sin_grad = (sm(end)-sm(1))/(z(end)-z(1))*1000;

        fprintf(fid,"\nRadiation gradients:\n");
        fprintf(fid,"  Lin gradient : %.3f W/m2/km\n",Lin_grad);
        fprintf(fid,"  Sin gradient : %.3f W/m2/km\n",Sin_grad);

        if Lin_grad>0
            add_warning(...
                "WARNING",...
                sprintf(...
                "Massif %d: longwave increases with altitude.",...
                massif_id),...
                "")
        else
            fprintf(fid,"  PASS: longwave decreases with altitude\n");
        end

        %% Humidity gradient

        q_grad = (qm(end)-qm(1))/(z(end)-z(1))*1000;

        fprintf(fid,"\nHumidity gradient:\n");
        fprintf(fid,"  dq/dz = %.3e kg/kg/km\n",q_grad);
        if q_grad>0
            add_warning(...
                "WARNING",...
                sprintf(...
                "Massif %d: humidity increases with altitude.",...
                massif_id),...
                "")
        else
            fprintf(fid,"  PASS: humidity decreases with altitude\n");
        end

        %% Wind gradient
        wind_grad = (wm(end)-wm(1))/(z(end)-z(1))*1000;

        fprintf(fid,"\nWind gradient:\n");
        fprintf(fid,"  %.3f m/s/km\n",wind_grad);

        %% Snow fraction

        fprintf(fid,"\nSnow fraction:\n");
        fprintf(fid,"  Lowest elevation : %.2f\n",snow_frac(1));
        fprintf(fid,"  Highest elevation: %.2f\n",snow_frac(end));
        if snow_frac(end)<snow_frac(1)
            add_warning(...
                "WARNING",...
                sprintf(...
                "Massif %d: snow fraction decreases with altitude.",...
                massif_id),...
                "")
        end

        %% Vertical inversions

        lapse_profile = diff(Tm)./diff(z)*1000;
        if any(lapse_profile>10)
            add_warning(...
                "WARNING",...
                sprintf(...
                "Massif %d: strong temperature inversion detected.",...
                massif_id),...
                "")
        end
    end
end % massif loop



%% ========================================================================
% Final summary
% ========================================================================


fprintf(fid,"\n\n");
fprintf(fid,...
    "============================================================\n");
fprintf(fid,...
    " VALIDATION SUMMARY\n");
fprintf(fid,...
    "============================================================\n\n");


if isempty(warnings)
    fprintf(fid, "STATUS:\n");
    fprintf(fid,"  PASS - No warnings detected.\n\n");
    fprintf(fid,"CryoGrid forcing appears physically consistent.\n");
else
    fprintf(fid,"STATUS:\n");
    fprintf(fid,"  WARNING - %d issues detected.\n\n",numel(warnings));
    fprintf(fid,"WARNINGS\n");
    fprintf(fid,...
        "------------------------------------------------------------\n\n");
    for i = 1:numel(warnings)
        fprintf(fid,"%s\n",warnings{i});
    end
end

fprintf(fid,"\n\n");
fprintf(fid,...
    "============================================================\n");
fprintf(fid,...
    " Validation finished\n");
fprintf(fid,...
    "============================================================\n");

fprintf('\nValidation report written:\n%s\n',report_file)

%% ========================================================================
% Nested warning handler
% ========================================================================


    function add_warning(level,message,~)
        warning_id = warning_id + 1;
        warnings{warning_id} = sprintf(...
            "[%s] %s",...
            level,...
            message);
    end
end