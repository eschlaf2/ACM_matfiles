function [ data ] = reorder_2P( data )
%Reorders data into correct sequence
%   Input to reorder_2P is the output of csvRead_2P


for i = 1:length(data)
    stimIDs = (data(i).data.StimCh(data(i).data.startTrig+100));
    [~,order] = sort(stimIDs);
    %break data into subtrials
    startTrigs = [data(i).data.startTrig length(data(i).data.DataCh)];
    for ii = 1: length(startTrigs)-1
        tempData{ii} = data(i).data.DataCh(startTrigs(ii):startTrigs(ii+1));
        tempPhoto{ii} = data(i).data.PhotoCh(startTrigs(ii):startTrigs(ii+1));
        tempTrig{ii} = data(i).data.TrigCh(startTrigs(ii):startTrigs(ii+1));
        tempStim{ii} = data(i).data.StimCh(startTrigs(ii):startTrigs(ii+1));
    end
    data(i).data.DataCh = tempData(order);
    data(i).data.PhotoCh = tempPhoto(order);
    data(i).data.TrigCh = tempTrig(order);
    data(i).data.StimCh = tempStim(order);
    rawtemp = data(i).fluoDat(order,1);
    rawtrig = data(i).fluoDat(order,2);
    data(i).fluoDat = [];
    data(i).fluoDat.raw = rawtemp;
    data(i).fluoDat.trig = rawtrig;
end

disp('Trials rearranged into correct sequence')

end
