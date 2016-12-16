function [actFixed,trigsFixed] = alignActivity(acty,trigs,maxlen,pad)
% Align all trials and subtrials around trigger onset
% trigs needs to be a cell variable with one cell per trial

if ~exist('pad','var')||isempty(pad); pad = 0;end
if ~exist('maxlen','var')||isempty(maxlen); maxlen = Inf; end

numTrials = length(trigs);
if iscell(acty); actFull = cat(2,acty{:}); else actFull = acty; end
[~,rois] = size(actFull);
trigsFull = cat(1,trigs{:});
trigsOn = find(diff(trigsFull) == 1); % triggers switch on
trigsOff = find(diff(trigsFull) == -1); % triggers switch off
minOff = min(trigsOn(:) - [0; trigsOff(:)]); % min length of 'off' interval
minOn = min([trigsOff(:); numel(trigsFull)] - trigsOn(:)); % min 'on' interval
if minOn + minOff > maxlen
    r = minOn/(minOn+minOff); % retain ratio of time on to time off
    d = minOn + minOff - maxlen; % find difference
    minOn = minOn - floor(d*r);
    minOff = minOff - floor(d*(1-r));
end
inds = false(size(trigsFull));
for i = 1:numel(trigsOn) % get indices surrounding trigger onset
    inds(trigsOn(i)-minOff+1:trigsOn(i)+minOn) = true;
end
numOrientations = length(trigsOn)/numTrials;
trigsFixed = trigsFull(inds);
trigsFixed = reshape(trigsFixed,[],numOrientations,numTrials);
trigsFixed = padarray(trigsFixed,[pad,0,0]);
trigsFixed = reshape(trigsFixed(:,:,1),[],1);
actFixed = actFull(inds,:);
if pad > 0
    actFixed = reshape(actFixed,[],numOrientations,numTrials,rois);
    actFixed = padarray(actFixed,[pad,0,0,0]);
    actFixed = reshape(actFixed,[],rois);
end
% imgFixed = reshape(imgFixed,d1,d2,[],numTrials);
end
