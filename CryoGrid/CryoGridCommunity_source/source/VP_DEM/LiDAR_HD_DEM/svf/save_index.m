function save_index(index,index_file)
%SAVE_INDEX Save restart index.

temp_file = index_file + ".tmp";

if isfile(temp_file)
    delete(temp_file)
end

save(temp_file,"index","-v7.3")

movefile(temp_file,index_file,"f")

end
