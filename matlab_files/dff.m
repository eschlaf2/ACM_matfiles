function output = dff(im,spatmap,stim)
% Calculates DFF as described here:
% http://www.nature.com/nprot/journal/v6/n1/box/nprot.2010.169_BX1.html,
% but with baseline equal to the median fluorescence when there is no
% trigger.
% Parameters assume 30 Hz sampling rate.
% Inputs:
%   im: a d1xd2xT matrix of raw images
%   spatmap: a dxK matrix representing an roi mask (d = d1xd2, K=number of
%   rois)
%   stim: a binary vector representing whether or not the stimulus is being
%   shown

tau0 = 6;
tau1 = ceil(30*.75/2);
tau2 = 90;

[d1,d2,T] = size(im);
K = size(spatmap,2);
% Do medfilt to get rid of shotgun noise
im = arrayfun(@(t) medfilt2(im(:,:,t)),(1:T),'uniformoutput',false);
im = cat(3,im{:});
imR = reshape(im,d1*d2,T);
fluo = zeros(T,K);
for j = 1:K
    fluo(:,j) = smooth(mean(imR(spatmap(:,j)>0,:),1),tau1);
end
% baseline = ones(size(fluo));
% for t = 2:T
%     start = max(1,t-tau2);
%     baseline(t,:) = min(fluo(start:start+tau2-1,:));
% end
% baseline(1,:) = baseline(2,:);
baseline = repmat(quantile(fluo(stim(1:T)==0,:),.08),T,1);
inds = fluo < baseline;
fluo(inds) = baseline(inds);

R = (fluo - baseline)./baseline;
w = exp(-(1:tau0)/tau0);
output = filter(w,sum(w),R);

% baseline drop
output = output - repmat(quantile(output,.08),T,1);
output(output<0) = 0;