function [imgFull,trigsFixed,Cfixed] = alignTrigs(im,trigs,C,maxlen,pad)
% Align all trials and subtrials around trigger onset

if ~exist('pad','var')||isempty(pad); pad = 0;end
if ~exist('C','var')||isempty(C); C = trigs; end
if ~exist('maxlen','var')||isempty(maxlen); maxlen = Inf; end

if iscell(trigs);
    numTrials = length(trigs);
    trigsFull = cat(1,trigs{:});
else 
    numTrials = 1;
    trigsFull = trigs;
end
if iscell(im); imgFull = cat(3,im{:}); else imgFull = im; end
if iscell(C); Cfull = cat(1,C{:}); else Cfull = C; end
clear im C
if ~isempty(imgFull); [d1,d2,~] = size(imgFull); end
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
if ~isempty(imgFull); imgFull(:,:,~inds) =[]; end
% imgFixed = imgFull(:,:,inds);
Cfixed = Cfull(inds,:);

if pad > 0
    rois = size(Cfull,2);
    if ~isempty(imgFull);
        imgFull = reshape(imgFull,d1,d2,[],numOrientations,numTrials);
        imgFull = padarray(imgFull,[0,0,pad,0,0]);
        imgFull = reshape(imgFull,d1,d2,[]);
    end
    Cfixed = reshape(Cfixed,[],numOrientations,numTrials,rois);
    trigsFixed = padarray(trigsFixed,[pad,0,0]);
    Cfixed = padarray(Cfixed,[pad,0,0,0]);
    Cfixed = reshape(Cfixed,[],rois);
end
trigsFixed = reshape(trigsFixed(:,:,1),[],1);

end
