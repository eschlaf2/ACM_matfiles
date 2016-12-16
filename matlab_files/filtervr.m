function vrInds = filtervr(activity,trigs,method,maxlag,mindiff)
% Filters for visually responsive (VR) cells.
% Inputs:
%   activity: time series of each roi (Txk matrix where T is the number of
%   time steps and k is the number of rois)
%   trigs: indicates when stimulus is present (logical vector of length T)
%   method: one of 'corr' or 'diff' (default: 'diff'). 
%       - corr: looks for lag between trigs and activity. If the lag is
%       between 0 and maxlag and the correlation is positive, the cell is
%       considered VR
%       - spiketime: looks for peaks at least 3 standard deviations away
%       from zero (activity in this case should be DFF). If a peak occurs
%       within maxlag of stimulus onset for any stimulus, the cells is
%       considered VR.
%       - diff: compares mean activity during presence and absense of
%       stimulus. If mean activity during stimulus is greater than mindiff
%       times mean activity when stimulus is absent, then the cells
%       considered VR
% Outputs:
%   vrInds: a logical vector of length k indicating which ROIs are VR

if ~exist('method','var')||isempty(method); method = 'diff'; end
if ~exist('maxlag','var')||isempty(maxlag); maxlag = 60; end
if ~exist('mindiff','var')||isempty(mindiff); mindiff = 1.25; end

switch lower(method)
    case 'corr'
        acor = nan(numRois,1); lag = nan(numRois,1);
        for i = 1:numRois
            [cc, loc] = xcorr((activity(:,i)),(trigs),maxlag+10,'unbiased');
            [acor(i), mxind] = max((cc));
            lag(i) = loc(mxind);
        end
        vrInds = (lag > 0) & (lag < LAGMAX) & (acor > 0);
    case 'spiketime'
        actStd = repmat(std(activity),size(activity,1),1);
        spikes = activity > 3*actStd;
        spikes = spikes(trigs,:);
        spikesR = reshape(spikes,[],sum(diff(trigs)>0),size(spikes,2));
        vrInds = sum(squeeze(sum(spikesR(1:maxlag,:,:))))>0;
    otherwise
        if ~strcmpi(method,'diff')
            warning('Method not recognized. Defaulting to method ''diff''.')
        end
        % difference in activity
        baseAct = activity(trigs==0,:);
        stimAct = activity(trigs==1,:);
        vrInds = (mindiff*mean(baseAct)) < mean(stimAct);
end
vrInds = vrInds(:);