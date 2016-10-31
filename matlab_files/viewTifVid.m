function [] = viewTifVid(tif_stack)
% Preview a tiff stack (matlab var - not file name)

figure
for i = 1:size(tif_stack,3)
    colormap('gray')
    imagesc(tif_stack(:,:,i))
    drawnow
end