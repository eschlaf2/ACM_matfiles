function [] = concatTif(foldername)
% concatenates all .tif files in a folder and saves the result to
% concat.tif in your current directory

setenv('foldername',foldername);
!tiffcp $foldername/*.tif concat.tif
