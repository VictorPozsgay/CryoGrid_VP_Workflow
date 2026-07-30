function print_step(step_number, step_name)
%PRINT_STEP Print a formatted workflow step header.
%
% DESCRIPTION
%   Prints a standardized header identifying the current processing step of
%   the forcing workflow. This helper provides consistent console output
%   throughout the preprocessing pipeline.
%
% INPUTS
%   step_number
%       Integer identifying the processing step.
%
%   step_name
%       Short descriptive title displayed in the console.
%
% EXAMPLE
%   print_step(2,"Read ERA5 TOA")

fprintf("\n");
fprintf("============================================================\n");
fprintf(" STEP %d - %s\n", step_number, step_name);
fprintf("============================================================\n\n");

end