function [finalImage] = readTifStack(tifIn)
% reads in a .tif stack

infoIm = imfinfo(tifIn);
w = infoIm(1).Width;
h = infoIm(1).Height;
n = length(infoIm);

t = Tiff(tifIn,'r');
offsets = t.getTag('SubIFD');

finalImage = zeros(w, h, n, 'uint16');
for i = 1:n
    t.setSubDirectory(offsets(i));
    finalImage(:,:,i) = t.read();
%     finalImage(:,:,i) = im2int16(imread(tifIn,'index',i));
end

end

