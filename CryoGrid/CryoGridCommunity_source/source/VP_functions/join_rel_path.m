function p = join_rel_path(in,out,ext)
%JOIN_REL_PATH Construct a canonical path from directory, filename and extension.
%
%   P = JOIN_REL_PATH(IN, OUT, EXT)
%
%   Builds a path using FULLFILE and converts it to a canonical absolute
%   path using Java file utilities.
%
%   Inputs
%   ------
%   in : char
%       Input directory path.
%
%   out : char
%       File or subdirectory name.
%
%   ext : char, optional
%       File extension to append to OUT.
%       Default: "".
%
%   Output
%   ------
%   p : char
%       Canonical absolute path.
%

arguments
    in char
    out char = ""
    ext char = ""
end

p = fullfile(in, append(out,ext));
p = char(java.io.File(p).getCanonicalPath());

end
