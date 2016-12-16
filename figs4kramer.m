% filename = '/projectnb/cruzmartinlab/lab_data/WWY_080116_3/cell-bodies-1Hz/Results/WWY_080116_3_trial01.tif';
foldername = '/projectnb/cruzmartinlab/lab_data/WWY_080116_3/cell-bodies-1Hz/Results/';
roifile = '/projectnb/cruzmartinlab/lab_data/WWY_080116_3/cell-bodies-1Hz/Results/imagej/RoiSet.zip';
maxNeurons = [10;10];
estNeuronSize = [8;12];
refine_components = false;

segmentCa2P(foldername,[],[],'/projectnb/cruzmartinlab/emily/cellbodies_imgj_manualdff',[],roifile,false);
% segmentCa2P(foldername,[],[],'/projectnb/cruzmartinlab/emily/cellbodies_imgj_paninskidff',[],roifile,true);
% segmentCa2P(foldername,maxNeurons,estNeuronSize,'/projectnb/cruzmartinlab/emily/cellbodies_paninski_manualdff',[],[],false);
% segmentCa2P(foldername,maxNeurons,estNeuronSize,'/projectnb/cruzmartinlab/emily/cellbodies_paninski_paninskidff',[],[],true);

% [SpatMap,CaSignal,Spikes,width,height,Cn,P,options] = ...
%     CaImSegmentation(filename,maxNeurons,estNeuronSize,[],refine_components);
% savefig('cellbodies_size30')
% save('cellbodies_size30','-v7.3')

% fprintf('Working on cell bodies size 4\n')
% estNeuronSize=4;
% [SpatMap,CaSignal,Spikes,width,height,Cn,P,options] = ...
%     CaImSegmentation(filename,maxNeurons,estNeuronSize);
% savefig('cellbodies_size4')
% save('cellbodies_size4','-v7.3')
% 
% fprintf('Working on axons\n')
% filename = '/projectnb/cruzmartinlab/lab_data/WWY_080116_3/axons/Results/WWY_080116_3_trial01.tif';
% [SpatMap,CaSignal,Spikes,width,height,Cn,P,options] = ...
%     CaImSegmentation(filename,maxNeurons,estNeuronSize);
% savefig('axons')
% save('axons','-v7.3')