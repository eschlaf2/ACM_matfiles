function [ data ] = csvRead_2P(data, root)
%Input is output from 'preprocess_2P'
%   First run preprocess_2P

numTrials = length(data);
for i = 1:numTrials
    startID = data(i).startID;                              %start file ID for trial
    bName = data(i).basename;                               %file base name
    fluoDat{data(i).subTrials,2} = [];                      %initialize data store
    for ii = 1:data(i).subTrials
        fID = startID+ii-1;                                 %current fileID
        fName1 = sprintf('%s%.3d.tif_1.csv',bName,fID);     %Fluorescence data file from 2P
        fName1 = fullfile(root,fName1);
        fName2 = sprintf('%s%.3d.tif_2.csv',bName,fID);     %Trigger data file from 2P
        fName2 = fullfile(root,fName2);
        tempData = csvread(fName1,1,1);                     %Read Fluorescence data
        tempTrig = csvread(fName2,1,1);                     %Read Trigger data
        %Find trigger frame
        tempTrig = sign(tempTrig(:,1));
        tempTrig = diff(tempTrig);
        trigFrame = find(tempTrig>0);
        fluoDat{ii,1} = tempData;                           %Write fluorescence data into fluoDat
        fluoDat{ii,2} = trigFrame;                          %Write trigger data into fluoDat
    end
    data(i).fluoDat = fluoDat;
    clear fluoDat
end
disp('All csv files loaded')

end
