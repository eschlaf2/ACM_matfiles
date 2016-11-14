function [order,N] = reorder2P(data,N)

k=10;
trigs = medfilt1(data.TrigCh(data.sampleRate:end),k);
trigs = trigs>.5;
% trigs(:) = 0; 
% trigs(hi_inds) = 1;
trig1 = find(data.PhotCh(:)>4,1);

trigStarts = find(diff(trigs) < 0)+data.sampleRate;

if trigStarts(1) - trig1 > 0
    warning('First trigger missing. Correcting.')
    trigStarts = [trig1; trigStarts(:)];
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