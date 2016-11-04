function [] = deinterleaveTif(filename,tot_chan)


[path,name,ext] = fileparts(which(filename));
filename = [path filesep name ext];
setenv('path',path);
setenv('filename',filename);

i=0;
while ~isempty(dir(sprintf('tmp%d*',i)))
    i=i+1;
end
pfx = sprintf('tmp%d',i);
setenv('pfx',pfx);
!tiffsplit $filename $pfx

N = length(dir([pfx '*.tif']));
assert(N<17576,'File has too many frames (max is 17576).')

for chan = 1:tot_chan
    file_inds = '';
    for i = chan:tot_chan:N
        o1 = char(97+floor((i-1)/676));
        o2 = char(97+mod(floor((i-1)/26),26));
        o3 = char(97+mod(i-1,26));
        file_inds = [file_inds sprintf(' %s%s%s%s.tif,',...
            pfx, o1, o2, o3)];
    end

    file_inds = file_inds(2:end-1);
%     if i > tot_chan
%         file_inds = ['{' file_inds '}'];
%     end

%     setenv('tfcp',[pfx file_inds '.tif']);
    setenv('outname',[name '_ch' num2str(chan) '.tif']);
    setenv('cpfiles',file_inds);
    !tiffcp $cpfiles $outname
end
!rm -rf $pfx*.tif
