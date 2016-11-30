function [imgFixed,trigsFixed] = alignTrigs(im,trigs,maxlen,pad)
% Align all trials and subtrials around trigger onset

if ~exist('pad','var')||isempty(pad); pad = 0;end

numTrials = length(trigs);
imgFull = cat(3,im{:});
[d1,d2,~] = size(imgFull);
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
imgFixed = imgFull(:,:,inds);
imgFixed = reshape(imgFixed,d1,d2,[],numOrientations,numTrials);
imgFixed = padarray(imgFixed,[0,0,pad,0,0]);
imgFixed = reshape(imgFixed,d1,d2,[]);
% imgFixed = reshape(imgFixed,d1,d2,[],numTrials);
end
