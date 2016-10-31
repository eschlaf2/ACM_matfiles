% Pick out vr cells by diff

DIFFWINDOW = 5;
THRESH = 3;
supermat = makeSuperDff();

[tsteps,num_cells, num_orientations, ~] = size(supermat);

super_med = median(supermat,4);
super_stacked = zeros(tsteps*num_orientations,num_cells);
for orn = 1:num_orientations
    indstart = (orn-1)*tsteps+1;
    indend = orn*tsteps;
    super_stacked(indstart:indend,:) = squeeze(super_med(:,:,orn));
end

super_smoothed = expsmooth(super_stacked);
fig(2) = stackedTraces(super_smoothed);

stds = std(super_smoothed);
baselines = mean(super_smoothed);

thresh_mat = repmat(THRESH*stds+baselines,tsteps*num_orientations,1);
figure(3)
% vr_inds = super_smoothed(1:end-DIFFWINDOW,:) - ...
%     super_smoothed(DIFFWINDOW+1:end,:) > thresh_mat;
vr_inds = super_smoothed > thresh_mat;
imagesc(vr_inds);

good_cells = find(max(vr_inds) > 0);
