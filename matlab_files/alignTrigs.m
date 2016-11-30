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
    r = minOn/(minOn+minOff);
    d = minOn + minOff - maxlen;
    minOn = minOn - floor(d*r);
    minOff = minOff - floor(d*(1-r));
end
inds = false(size(trigsFull));
for i = 1:numel(trigsOn) % get indices surrounding trigger onset
    inds(trigsOn(i)-minOff+1:trigsOn(i)+minOn) = true;
end
trigsFixed = padarray(reshape(trigsFull(inds),[],numTrials),[pad,0]);
trigsFixed = trigsFixed(:,1);
imgFixed = reshape(imgFull(:,:,inds),d1,d2,[],numTrials);
imgFixed = reshape(padarray(imgFixed,[0,0,pad,0]),d1,d2,[]);
% imgFixed = reshape(imgFixed,d1,d2,[],numTrials);
end
