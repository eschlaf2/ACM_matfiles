function [data_sm] = expsmooth(data)
% smooths 2d columnwise data

WINDOW = 5;
[rows,cols] = size(data);
data_plus = [data; repmat(mean(data(end-10:end,:)),WINDOW,1)];

exp_mat = repmat(exp((0:-1:-WINDOW+1))',1,cols);
data_sm = zeros(size(data));

for r = 1:rows
    data_sm(r,:) = sum(data_plus(r:r+WINDOW-1,:) .* exp_mat)./WINDOW;
end
