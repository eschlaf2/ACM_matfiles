function [spatmap] = imgj2spatmap(roifile, d)
% Inputs:
%   roifile: a path to an ImageJ Roi file
%   d: in the form [d1,d2] - the dimensions of the image
% Outputs:
%   spatmap: binary dxk file where d is d1xd2 and k is the number of rois
% Note: assumes ROIs are Oval shaped or Freehand

%% Initialize variables
if ~exist('roifile','var'); roifile = '/projectnb/cruzmartinlab/lab_data/WWY_080116_3/axons/imagej/trial1_RoiSet.zip'; end
if ~exist('d','var') || isempty(d); d = [512,512]; end
if numel(d) == 1
    d1 = floor(sqrt(d)); d2 = d1;
    if d1*d2 ~= d; error('Enter d as [d1,d2]'); end
else
    d1 = d(1); d2 = d(2); 
    if numel(2) > 2; warning('Only the first two elements of d are assigned');end
end

%% Convert
imgjroi = ReadImageJROI(roifile);
numrois = length(imgjroi);
spatmap = false(d1,d2,numrois);
for i = 1:numrois
    roi = imgjroi{i};
    switch roi.strType
        case 'Freehand'
            inds = roi.mnCoordinates;
            spatmap(inds(:,2),inds(:,1),i) = true; 
        case 'Oval'
            bounds = roi.vnRectBounds;
            a = (bounds(3)-bounds(1))/2;
            b = (bounds(4)-bounds(2))/2;
            [x,y] = meshgrid((-a:a),(-b:b));
            oval = (x/a).^2 + (y/b).^2 <=1;
            spatmap(bounds(1):bounds(3),bounds(2):bounds(4),i) = oval';
    end
end
spatmap = reshape(spatmap,[],numrois);