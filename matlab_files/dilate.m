function [spatnew] = dilate(SpatMap, d, radius)
% Inputs:
%   SpatMap: a matrix representing the rois where each column is one roi
%   and each row is a pixel
%   d: d1xd2 where d1 and d2 are the dimensions of the 2D image
%   radius: the number of pixels by which to dilate each roi
% Outputs:
%   spatnew: a binary matrix of the dilated rois in the same shape as
%   SpatMap

if ~exist('d','var')||isempty(d); d1=512; d2=512; else d1=d(1); d2 = d(2); end
if ~exist('radius','var')||isempty(radius); radius = 4; end
rois = size(SpatMap,2);
spatmask = SpatMap > 0;
spatmask = reshape(full(spatmask),d1,d2,rois);
spatnew = false(size(spatmask));
for i=1:rois
    inds = find(spatmask(:,:,i));
    for ind = inds'
        [r,c] = ind2sub([d1,d2], ind);
        dilateR = max(1,r-radius):min(r+radius,d1);
        dilateC = max(1,c-radius):min(c+radius,d2);
        spatnew(dilateR,dilateC,i) = true;
    end
end
spatnew = reshape(spatnew,[],rois);