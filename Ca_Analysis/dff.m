function [dff_data] = dff(data)
% calculate dff based on time points 5:35

fb = mean(data(5:35,:),1);
fb = repmat(fb,size(data,1),1);
dff_data = (data - fb)./fb;