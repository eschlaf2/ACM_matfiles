function [finalImage] = readTifStack(filename)
% reads in a .tif stack

N = length(imfinfo(filename));
t = Tiff(filename);

im = repmat(t.read(),1,1,N);
for i = 2:N
    t.nextDirectory;
    im(:,:,i) = t.read();
end