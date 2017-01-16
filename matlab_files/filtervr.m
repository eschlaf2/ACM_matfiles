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
%       - spiketime: looks for peaks at least 2.5 standard deviations away
%       from zero (activity in this case should be DFF). If a peak occurs
%       within maxlag of stimulus onset for any stimulus, the cell is
%       considered VR.
%       - diff: compares mean activity during presence and absence of
%       stimulus. If mean activity during stimulus is greater than mindiff
%       times mean activity when stimulus is absent, then the cells are
%       considered VR
%       - ddt: looks for sharp increases in activity within maxlag of
%       stimulus onset for any stimulus.
%   maxlag: lag window (optional, default: 60)
%   mindiff: minimum ratio of activity during stim to no stim (optional,
%   default: 1.5);
% Outputs:
%   vrInds: a logical vector of length k indicating which ROIs are VR

if ~exist('method','var')||isempty(method); method = 'diff'; end
if ~exist('maxlag','var')||isempty(maxlag); maxlag = 60; end
if ~exist('mindiff','var')||isempty(mindiff); mindiff = 1.5; end

[T,k] = size(activity);
st = sum(diff(trigs)>0);

% find window for spikes in spiketime and ddt methods
trigsR = reshape(trigs(:),[],st);
offtime = sum(trigsR(:,1)==0);
trigsR(offtime+1:offtime+maxlag,:) = 2;

switch lower(method)
    case 'corr'
        acor = nan(k,1); lag = nan(k,1);
        for i = 1:k
            [cc, loc] = xcorr((activity(:,i)),(trigs),maxlag+10,'unbiased');
            [acor(i), mxind] = max((cc));
            lag(i) = loc(mxind);
        end
        vrInds = (lag > 0) & (lag < maxlag) & (acor > 0);
    case 'spiketime'
        vrInds = false(k,1);
        for i = 1:k
            ti = activity(:,i);
            if false
                figure(2); findpeaks(ti,'minpeakheight',2.5*std(ti),...
                    'minpeakprominence',std(ti));
                x = 1:T;
                hold on; plot(x(trigsR==2),ti(trigsR==2),'r.','linewidth',2); hold off;
                title(num2str(i));
                pause
            end
            [~, locs] = findpeaks(ti,'minpeakheight',2.5*std(ti),...
                'minpeakprominence',std(ti));
            vrInds(i) = sum(trigsR(locs)==2)>0;
        end
           
    case 'ddt'
        dt = floor(maxlag/2);
        ddt = [zeros(dt,k); activity(dt+1:end,:) - activity(1:end-dt,:)];
        stdDiff = repmat(std(ddt(dt+1:end,:)),T,1);
        vrInds = any((ddt > 2.5*stdDiff) & (repmat(trigsR(:),1,k) == 2));
    otherwise
        if ~strcmpi(method,'diff')
            warning('Method ''%s'' not recognized. Defaulting to method ''diff''.',method)
        end
        % difference in activity
        actR = reshape(activity,[],st,k);
        baseAct = actR(trigs(1:T/st)==0,:,:);
        stimAct = actR(trigs(1:T/st)==1,:,:);
        vrInds = squeeze(sum(mean(stimAct) > mindiff*mean(baseAct),2))>0;
%         baseAct = activity(trigs==0,:);
%         stimAct = activity(trigs==1,:);
%         vrInds = (mindiff*mean(baseAct)) < mean(stimAct);
end
vrInds = vrInds(:);