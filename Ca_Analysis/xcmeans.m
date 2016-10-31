function [xc_means] = xcmeans(supermat, norm_std)
% Calculates mean correlation between trials for each cell. Variable data
% should be 4D of the form [t, cells, orientations, trials].

WINDOW = 10;

if ~exist('norm_std','var')
    norm_std = 1;
end

[~, num_cells, num_orientations, num_trials] = size(supermat);

xc_means = zeros(num_orientations,num_cells);
for cell = 1:num_cells
    for orientation = 1:num_orientations
        xc = squeeze(max(reshape(xcorr(meancenter(squeeze(...
            supermat(:,cell,orientation,:)),norm_std),WINDOW),...
            21, num_trials, num_trials),[],1));
        xc_normed = normxc(xc);
        xc_means(orientation,cell) = mean(xc_normed(:),'omitnan');
    end
end 

end

function [xc_normed] = normxc(xc)
% Normalize xcorr so that xc of n,n is max

xc_max = diag(xc);
xc_normed = tril(xc ./ repmat(xc_max,1,length(xc_max))) - eye(size(xc));
xc_normed(xc_normed == 0) = NaN;

end

function [mc_mat] = meancenter(mat,norm_std)

if ~exist('norm_std','var')
    norm_std = 0;
end

means = mean(mat,1);
mc_mat = mat - repmat(means,length(mat),1);

if norm_std
    stddevs = std(mc_mat,[],1);
    mc_mat = mc_mat ./ repmat(stddevs, length(mat),1);
end

end
