function runs = sc_load_conditioning_data(directory)

% collects the conditioning data of a singel subject
% directory must contain four 
    
if ~exist('directory', 'var')
    directory = cd;
else
    cd(directory);
end

for r = 1:4
    fname = dir(sprintf('%s%d%s','*run_',r,'*'));
    d = load(strcat(directory,filesep,fname.name));
    runs{r} = d.data;
end
clear d

end