function [t] = writeTif(img, filename)
% Writes a gray scale matrix to a .tif file as int16. Meant for writing 2P
% imaging results from .mat to .tif after registration

N = size(img,3);
[path, name, ~] = fileparts(filename);
wd = pwd;
if path; cd(path); end; path = pwd; cd(wd);
% try 
%     delete([path filesep name '.tif'])
% catch ME
% end
t = Tiff([path filesep name '.tif'],'w');

tagstruct.ImageLength = size(img,1);
tagstruct.ImageWidth = size(img,2);
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample = 16;
tagstruct.SamplesPerPixel = 1;
tagstruct.RowsPerStrip = 8;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Compression = Tiff.Compression.None;
tagstruct.SampleFormat = Tiff.SampleFormat.Int;
tagstruct.Software = 'MATLAB';
t.setTag(tagstruct)

t.write(int16(img(:,:,1)));
t.writeDirectory;

for n=2:N
    t.setTag(tagstruct);
    t.write(int16(img(:,:,n)));
    t.writeDirectory;
end

t.close;
end


