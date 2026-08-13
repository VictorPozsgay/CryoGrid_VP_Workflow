function validate_svf_chunk( ...
    filename,expected,Rexpected,nodata)

% Read the temporary chunk.
[A,Ractual] = readgeoraster(filename);

A = single(A);

% -------------------------------------------------------------------------
% Raster size
% -------------------------------------------------------------------------

if ~isequal(size(A),size(expected))

    error("Temporary SVF chunk has incorrect raster size.")

end

% -------------------------------------------------------------------------
% Spatial reference
% -------------------------------------------------------------------------

tol = 1e-6;

if abs(Ractual.CellExtentInWorldX - ...
        Rexpected.CellExtentInWorldX) > tol || ...
        abs(Ractual.CellExtentInWorldY - ...
        Rexpected.CellExtentInWorldY) > tol

    error("Temporary SVF chunk has incorrect resolution.")

end

if any(abs(Ractual.XWorldLimits - ...
        Rexpected.XWorldLimits) > tol) || ...
        any(abs(Ractual.YWorldLimits - ...
        Rexpected.YWorldLimits) > tol)

    error("Temporary SVF chunk has incorrect spatial extent.")

end

% -------------------------------------------------------------------------
% Values
% -------------------------------------------------------------------------

expected = single(expected);

if ~isequal(A,expected)

    error("Temporary SVF chunk values failed validation.")

end

% -------------------------------------------------------------------------
% Physical range
% -------------------------------------------------------------------------

valid = A ~= nodata;

if any(A(valid) < 0 | A(valid) > 1)

    error("Temporary SVF chunk contains values outside [0,1].")

end

end
