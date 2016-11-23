function [order,N] = reorder2P(data,N)

k=100;
trigs = medfilt1(data.TrigCh,k);
trigs = trigs>.5;

trig1 = find(data.PhotCh(:)>4,1);
% photCh = diff(find(abs(data.PhotCh(trig1:end)-3) > 1));
% assuming stim is off for at least .5s and stim rate is at least 2 Hz
% offtime = mean(photCh(photCh > data.sampleRate/2)); 
avtime = median(diff(find(diff(trigs) > 0)));
photFilt = double(data.PhotCh>4);
[~,trigStarts] = findpeaks(photFilt(trig1:end),...
    'minpeakdistance',.8*avtime);
trigStarts = trig1-1 + trigStarts;

% trigStarts = find(diff(trigs) < 0);

% if trigStarts(1) > trig1 + .5*avtime
%     warning('First trigger missing. Correcting.')
%     trigStarts = [trig1; trigStarts(:)];
% end
% if trigStarts(1) < data.sampleRate
%     trigStarts = trigStarts(2:end);
% end
if numel(trigStarts) ~= N
    newN = min(numel(trigStarts),N);
    warning(...
        'Found %d trigger starts for %d subtrials. Using first %d.',...
        numel(trigStarts),N, newN);
    trigStarts = trigStarts(1:newN);
end
order = data.StimCh(trigStarts);
N = min(N,numel(trigStarts));
end
