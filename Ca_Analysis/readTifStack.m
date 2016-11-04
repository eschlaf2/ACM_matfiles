function [finalImage] = readTifStack(filename)
% reads in a .tif stack

infoIm = imfinfo(filename);
w = infoIm(1).Width;
h = infoIm(1).Height;
n = length(infoIm);

% t = Tiff(tifIn,'r');
% offsets = t.TagID.SubIFD;

finalImage = zeros(w, h, n, 'uint16');
% f = @(i) im2int16(imread(tifIn,'index',i));
% finalImage = arrayfun(f ,(1:n),'uniformoutput','false');
for i = 1:n
%     t.setSubDirectory(offsets(i));
%     finalImage(:,:,i) = t.read();
    finalImage(:,:,i) = im2int16(imread(filename,'index',i));
end

