function [ax, data_stacked, yticks] = stackedTraces(data, spread, s)
% spreads 2D columnwise data so it's easier to see when plotting

m = 1.5;
if ~exist('s','var')
    s = '-';
end
if (~exist('spread', 'var') || isempty(spread))
    spread = m*mean(max(data) - mode(data));
end

[rows,cols] = size(data);
yticks = spread*(2:cols+1); % works w imagesc
data_stacked = data + repmat(yticks,rows,1);

figure(gcf);
ax = plot(data_stacked,s);
set(gca, 'ytick', yticks, 'yticklabels', num2str((1:cols)'))
