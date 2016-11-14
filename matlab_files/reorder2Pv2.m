function [order] = reorder2Pv2(data,numOrienations,numTrials)

k = 1000;
StimCh = medfilt1(data.StimCh,k);
sampleRate = data.sampleRate;
counts = arrayfun(@(x) sum(StimCh == x)/numTrials,(0:numOrienations-1));
l = quantile(counts,.4);
order = StimCh(round((1:numTrials*numOrienations)*l)+sampleRate);

check = diff(sort(reshape(order, numOrienations,[]),1));
if min(check(:)) == 0
    error('Error in ordering')
end
end