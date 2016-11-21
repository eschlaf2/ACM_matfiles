function order = reorder2Pv2(data,numOrientations,subTrials)

k = 1000;
StimCh = medfilt1(data.StimCh,k);
sampleRate = data.sampleRate;
N = floor(subTrials/numOrientations); % number of full trials
counts = arrayfun(@(x) sum(StimCh == x),(0:numOrientations-1));
lag = find(abs(diff(StimCh))>0); lag = lag(1);
l = (numel(StimCh)-sampleRate)/subTrials;%l = min(counts);
order = StimCh(round((1:subTrials)*l)+sampleRate);
check = diff(sort(reshape(order(1:N*numOrientations), numOrientations,[]),1));
if min(check(:)) == 0
    error('Error in ordering')
end
order = order(1:N*numOrientations);
end
