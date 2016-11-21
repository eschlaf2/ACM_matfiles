function [order,N] = reorder2P(data,N)

k=100;
trigs = medfilt1(data.TrigCh,k);
trigs = trigs>.5;
% trigs(:) = 0; 
% trigs(hi_inds) = 1;
trig1 = find(data.PhotCh(:)>4,1);

trigStarts = find(diff(trigs) < 0);

if trigStarts(1) > trig1
    warning('First trigger missing. Correcting.')
    trigStarts = [trig1; trigStarts(:)];
end
if trigStarts(1) < data.sampleRate
    trigStarts = trigStarts(2:end);
end
if numel(trigStarts) ~= N
    newN = min(numel(trigStarts),N);
    warning(...
        'Found %d trigger starts for %d subtrials. Using first %d.',...
        numel(trigStarts),N, newN);
    trigStarts = trigStarts(1:newN);
end
order = data.StimCh(trigStarts + 100);
N = min(N,numel(trigStarts));
end
