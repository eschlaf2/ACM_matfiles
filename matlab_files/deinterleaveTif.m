function [] = deinterleaveTif(filename,chan_names)
% separates .tif file into separate channels and saves results to folders
% corresponding to each channel

[path,name,ext] = fileparts(which(filename));
filename = [path filesep name ext];
% setenv('path',path);
setenv('filename',filename);
N = length(imfinfo(filename));
tot_chan = numel(chan_names);

for i = 1:tot_chan
    fname = sprintf('%s%s%s',path,filesep,chan_names{i});
    outname = [fname filesep name '_' chan_names{i} ext];
    if ~exist(fname,'dir')
        mkdir(fname);
    end
    inds = sprintf('%d,',(i:tot_chan:N));
    inds = inds(1:end-1);
    setenv('outname',outname);
    setenv('inds',inds);
    if ~exist(outname,'file')
        if i == 1
            display(sprintf('Deinterleaving %s',name));
        end
        if i == tot_chan % only save one pixel of the trigger channel
            !tiffcrop -N $inds -X 1 -Y 1 $filename $outname
        else
            !tiffcrop -N $inds $filename $outname
        end
    end
end

