function [ data ] = analyze_2P( data )
%Analysis of 2P calcium imaging
%   Input to this function is the output of csvRead_2P

for i = 1:length(data)
    numSub = data(i).subTrials; %number of subtrials
    for ii = 1:numSub
        fluo = data(i).fluoDat.raw{ii}(:,1:3:end); %modify this later for different input formats
        dimY = length(fluo(:,1));
        dimX = length(fluo(1,:));
        fluo = reshape(smooth(fluo,3,'moving'),dimY,dimX); % smooth to get rid of one point outliers
        numCell = length(fluo(1,:)); %number of cells (ROIs)
        trig = data(i).fluoDat.trig{ii};
        %Calculate baseline fluorescence for each cell
        for iii = 1:numCell
            tempMean = mean(fluo(1:trig,iii));
            %Also calculate dF/F at the same time
            data(i).fluoDat.dFF{ii,iii} = (fluo(:,iii)-tempMean)./tempMean;
            data(i).fluoDat.baseF{ii,iii} = mean(data(i).fluoDat.dFF{ii,iii}(1:trig));
            data(i).fluoDat.stdBaseF{ii,iii} = std(data(i).fluoDat.dFF{ii,iii}(1:trig));
        end
    end
    %calculate std for averaged signal too
    data(i).fluoDat.stdBaseF = cell2mat(data(i).fluoDat.stdBaseF);
    data(i).fluoDat.stdBaseF = [data(i).fluoDat.stdBaseF;...
        mean(data(i).fluoDat.stdBaseF)]; 
    %and th base fluorescence... I keep forgetting things
    data(i).fluoDat.baseF = cell2mat(data(i).fluoDat.baseF);
    data(i).fluoDat.baseF = [data(i).fluoDat.baseF;...
        mean(data(i).fluoDat.baseF)];
        
    
    %Concatenate all trials together
    nextLine = numSub+1;
    for ii = 1:numCell
        data(i).fluoDat.dFF{nextLine,ii} = data(i).fluoDat.dFF{1,ii};
        for iii = 2:numSub
            data(i).fluoDat.dFF{nextLine,ii} =...
                [data(i).fluoDat.dFF{nextLine,ii};...
                data(i).fluoDat.dFF{iii,ii}];
        end
    end
    
    %{
    %Concatenate all speedTracker data together
    %NOTE: must trim data first -- still need to code that
    for ii = 1:numSub
        if ii == 1
            data(i).data.DataCh{nextLine} = data(i).data.DataCh{ii};
            data(i).data.PhotoCh{nextLine} = data(i).data.PhotoCh{ii};
            data(i).data.TrigCh{nextLine} = data(i).data.TrigCh{ii};
            data(i).data.StimCh{nextLine} = data(i).data.StimCh{ii};
        else
            data(i).data.DataCh{nextLine} =...
                [data(i).data.DataCh{nextLine} ...
                data(i).data.DataCh{ii}];
            data(i).data.PhotoCh{nextLine} =...
                [data(i).data.PhotoCh{nextLine} ...
                data(i).data.PhotoCh{ii}];    
            data(i).data.TrigCh{nextLine} =...
                [data(i).data.TrigCh{nextLine} ...
                data(i).data.TrigCh{ii}];
            data(i).data.StimCh{nextLine} =...
                [data(i).data.StimCh{nextLine} ...
                data(i).data.StimCh{ii}];
        end
    end
    %}    
    
    %Calculate trigger locations
    currFrame = 0;
    triggers = zeros(numSub,1);
    for ii = 1:numSub
        frames = length(data(i).fluoDat.raw{ii}(:,1));
        triggers(ii) = data(i).fluoDat.trig{ii}+currFrame;
        currFrame = currFrame + frames;
    end
    data(i).fluoDat.totTrig = triggers;   
    
end

disp('Fluorescence converted into dF/F and concatenated')

           
            
            



end

