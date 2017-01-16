% Compare which cells are VR using different filtering methods

% run with defaults
maxlag = [];
mindiff = []; 
fignum = 21;
titlestr = {'VR cells';'XL011-10\_0914';'Day 15';'Area 0'};

vrIndscorr = filtervr(dffM,trigs,'corr',maxlag);
vrIndsdiff = filtervr(dffM,trigs,'diff',[],mindiff);
vrIndsspike = filtervr(dffM,trigs,'spiketime',maxlag);
vrIndsddt = filtervr(dffM,trigs,'ddt',maxlag);

figure(fignum); 
imagesc([vrIndscorr vrIndsdiff vrIndsspike vrIndsddt]);
set(gcf,'units','normalized','position',[0.06 0.4 0.16 0.47]);
set(gca,'xticklabels',{'corr';'diff';'spike';'ddt'})
colormap([.5 .5 .5; 1 1 .5])
title(titlestr);
