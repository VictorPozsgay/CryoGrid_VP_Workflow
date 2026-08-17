function build_full_validation(meteo_path,diagnostic_path)
%BUILD_FULL_VALIDATION Run complete CryoGrid forcing validation workflow.
%
% DESCRIPTION
%   Runs the complete validation and diagnostic workflow for a generated
%   CryoGrid-ready forcing dataset.
%
%   The workflow performs two complementary analyses:
%
%     1. Text-based validation:
%        - checks the structure of the forcing dataset
%        - validates dimensions, classes, and time axis
%        - computes variable statistics
%        - performs vertical atmospheric diagnostics
%        - checks physical consistency
%        - collects and summarizes potential warnings
%
%     2. Graphical diagnostics:
%        - generates vertical atmospheric profiles
%        - evaluates radiation profiles and gradients
%        - produces representative forcing time series
%        - computes seasonal climatologies
%
% INPUT
%   meteo_path
%       Path to the CryoGrid-ready forcing directory containing:
%
%           CryoGrid_ready/
%               FORCING_SAFRAN_ALL.mat
%
%       This file must contain the complete forcing collection generated
%       by BUILD_COMBINED_FORCING.
%
%   diagnostic_path
%       Path to the output directory where all validation results will
%       be saved.
%
% OUTPUT
%   Creates:
%
%       <diagnostic_path>/
%
%           FORCING_validation_report.txt
%               Complete text-based validation report including:
%                   - dataset summary
%                   - variable statistics
%                   - vertical diagnostics
%                   - physical checks
%                   - warning summary
%
%           massif_x_name/
%               Diagnostic figures for each massif:
%
%                   vertical_state.png
%                       Mean atmospheric profiles:
%                       temperature, pressure, humidity, wind
%
%                   radiation_profiles.png
%                       Mean incoming longwave and shortwave radiation
%                       profiles
%
%                   gradients.png
%                       Vertical gradients and lapse-rate diagnostics
%
%                   time_series.png
%                       Representative forcing time series
%
%                   seasonal_cycle.png
%                       Seasonal climatological forcing cycles
%
% SEE ALSO
%   VALIDATE_CRYOGRID_FORCING,
%   PLOT_FORCING_DIAGNOSTICS

validate_CryoGrid_forcing(meteo_path,diagnostic_path)
plot_forcing_diagnostics(meteo_path,diagnostic_path)