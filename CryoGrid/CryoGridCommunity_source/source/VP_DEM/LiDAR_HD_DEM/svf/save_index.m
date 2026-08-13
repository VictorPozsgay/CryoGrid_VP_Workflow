function save_index(index,index_file)
%SAVE_INDEX Save the Alpine SVF restart index safely via a temporary file.
%
% PURPOSE
%   Saves the current Alpine SVF processing index to disk so that the
%   computation can be safely resumed after interruption.
%
% INPUTS
%   index         - current SVF processing index structure
%   index_file    - destination MAT-file
%
% METHOD
%   The index is first written to a temporary file and then moved to the
%   requested destination with overwrite enabled.
%
%   This prevents an interrupted save from directly replacing the last
%   valid restart index.
%
% WORKFLOW ROLE
%   Called by compute_skyview_factor_alps() after a chunk has been
%   successfully processed and its final TIFF tile has been verified.
%
% RESTART GUARANTEE
%   A chunk is marked "DONE" in the index only after all required
%   processing, writing and verification steps have succeeded.

temp_file = index_file + ".tmp";

if isfile(temp_file)
    delete(temp_file)
end

save(temp_file,"index","-v7.3")

movefile(temp_file,index_file,"f")

end
