function validate_svf_chunk( ...
    filename,expected,Rexpected,nodata)
%VALIDATE_SVF_CHUNK Validate a temporary SVF chunk GeoTIFF.
%
% Verifies that a temporary SVF chunk written by the Alpine SVF workflow:
%
%   1. has the expected raster dimensions,
%   2. has the expected spatial resolution,
%   3. has the expected spatial extent,
%   4. contains exactly the expected values, and
%   5. contains no valid SVF values outside the physical range [0,1].
%
% Inputs:
%   filename  - Temporary SVF GeoTIFF to validate.
%   expected  - Expected SVF chunk values.
%   Rexpected - Expected spatial referencing object.
%   nodata    - NoData value used for invalid pixels.
%
% This validation is performed before the temporary chunk is inserted
% into the final Alpine SVF BigTIFF.

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
