function data = preprocEmily(root, numSubtrials)
% Get your own data

defaultNumSubtrials = 8;

if ~exist('numSubtrials','var')
    numSubtrials = defaultNumSubtrials;
end

files = dir([root '*Data*.mat']);

    
disp('Loading Data...')
% files = dir([root slash '*Data*.mat']);                                     %find correct files
files = rmfield(files,{'date','bytes','isdir','datenum'});                  %remove extra data
[files, check] = trialCheck(files,numSubtrials);                            %check that number of subtrials in trials line up
singleTrials = files(check==1);
nTrials = singleTrials;
multiTrials = files(check>1);
badTrials = files(check==0);
if ~isempty(badTrials)
    warning(['The following trials do not contain the correct '...
        'amount of subtrials. Attempts will be made to analyze data, '...
        'but please manualy check these trials.'])
    for ii = 1:length(badTrials)
        disp(badTrials(ii).name)
    end
end





%% Load and analyze data from SpeedTracker

%Start with single data
for ii = 1:length(singleTrials)
    singleTrials(ii).data = load(fullfile(root,singleTrials(ii).name));
    singleTrials(ii).subTrials = numSubtrials;
end
nTrials = singleTrials;
if varY
    why
end

%Next the multi data
for ii = 1:length(multiTrials)
    multiTrials(ii).data = load(fullfile(root,multiTrials(ii).name));
    singleTrials(ii).subTrials = numSubtrials;
end
%Find start triggers in data
if varY
    why
end






%% Reorganize data
if ~isempty(multiTrials)
    for ii = 1:length(multiTrials)
        count = multiTrials(ii).startID;
        multiTrials(ii).data.TrigCh(multiTrials(ii).data.TrigCh<1.5) = 0;
        multiTrials(ii).data.TrigCh(multiTrials(ii).data.TrigCh>1.5) = 1;
        trigs=find(diff(diff(multiTrials(ii).data.TrigCh)<0)>0);
        %Error Check 1
        check = find(diff(trigs)<(mean(diff(trigs))*.8))+1;
        trigs(check-1) = [];
        if length(trigs) ~= multiTrials(ii).loop*numSubtrials
            warning('Missing a trigger: attempting to fix automatically')
            % try to fix missing trigger, likely start trigger is missing
            meanSamp = mean(diff(trigs));
            stdSamp = std(diff(trigs));
            %Use stim ch to find trigger
            loc1 = find(diff(multiTrials(ii).data.StimCh));
            loc1 = loc1(find(loc1>(trigs(1)-meanSamp-stdSamp*5)));
            loc1 = loc1(find(loc1<(trigs(1)-meanSamp+stdSamp*5)));
            %Use photo channel to find trigger
            loc2 = multiTrials(ii).data.PhotCh;
            loc2(loc2<2.25) = 0;
            loc2(loc2>2.25) = 1;
            loc2 = find(diff(loc2)<0);
            loc2 = loc2(find(loc2>(trigs(1)-meanSamp-stdSamp*5)));
            loc2 = loc2(find(loc2<(trigs(1)-meanSamp+stdSamp*5)));
            if length(loc1) == 1 && length(loc2) == 1
                disp('Trigger successfuly found')
                trigs = [floor(mean([loc1 loc2])) trigs];
            elseif length(loc1) == 1
                disp('Trigger successfuly found')
                trigs = [loc1 trigs];
            elseif length(loc2) == 1
                disp('Trigger successfuly found')
                trigs = [loc2 trigs];
            else
                warning('Unable to detect first trigger: Setting start trigger to 1')
                trigs = [1 trigs];
            end
        end
            
        trigs = [0 trigs];
        %End Error Check
        startTrigs = trigs(mod(length(trigs),numSubtrials)+1:numSubtrials:end);
        trigs(1) = [];
        
        points = 0;
        for iii = 1:multiTrials(ii).loop
                tempTrigs = trigs(iii*numSubtrials-numSubtrials+1:iii*numSubtrials);
                tempTrigs = tempTrigs-startTrigs(iii)+1;
            baseN = multiTrials(ii).basename;
            startN = count;
            endN = count+numSubtrials-1;
            newName = sprintf('%s%.3dto_%s%.3d_Data.mat',...
                baseN,startN,baseN,endN);
            nTrials(end+1).name = newName;
            nTrials(end).basename = baseN;
            nTrials(end).startID = startN;
            nTrials(end).loop = 1;
            try
                nTrials(end).data.sampleRate = multiTrials(ii).data.sampleRate;
                nTrials(end).data.DataCh = multiTrials(ii).data.DataCh(...
                    startTrigs(iii)+1:startTrigs(iii+1));
                nTrials(end).data.PhotoCh = multiTrials(ii).data.PhotCh(...
                    startTrigs(iii)+1:startTrigs(iii+1));
                nTrials(end).data.TrigCh = multiTrials(ii).data.TrigCh(...
                    startTrigs(iii)+1:startTrigs(iii+1));
                nTrials(end).data.StimCh = multiTrials(ii).data.StimCh(...
                    startTrigs(iii)+1:startTrigs(iii+1))';
                nTrials(end).data.startTrig = tempTrigs;
            catch
                nTrials(end).data.sampleRate = multiTrials(ii).data.sampleRate;
                nTrials(end).data.DataCh = multiTrials(ii).data.DataCh(...
                    startTrigs(iii)+1:end);
                nTrials(end).data.PhotoCh = multiTrials(ii).data.PhotCh(...
                    startTrigs(iii)+1:end);
                nTrials(end).data.TrigCh = multiTrials(ii).data.TrigCh(...
                    startTrigs(iii)+1:end);
                nTrials(end).data.StimCh = multiTrials(ii).data.StimCh(...
                    startTrigs(iii)+1:end)';
                 nTrials(end).data.startTrig = tempTrigs;
            end
            nTrials(end).subTrials = numSubtrials;
            count = endN+1;
            points = points+length(nTrials(end).data.PhotoCh);
        end
        if varY && mod(ii,3)==0
            why
        end
    end
end





disp('All mat files loaded')








    function [files, check] = trialCheck(files,numSubtrials)
        %Check trial lengths
        check = zeros(1,length(files));
        for i = 1:length(files)
            fName = files(i).name;
            %find start file ID#
            delim = strfind(fName,'_to_')-1;
            [startF, base] = strtok(flip(fName(1:delim)),'_');
            files(i).basename = flip(base);
            startF = str2double(flip(startF));
            files(i).startID = startF;
            %find end file ID#
            delim = strfind(fName,'_Data.')-1;
            [endF, ~] = strtok(flip(fName(1:delim)),'_');
            endF = str2double(flip(endF));
            trials = endF-startF+1;
            if trials~=numSubtrials
                %Check if trials matches subtrials
                if rem(trials,numSubtrials)
                    check(i) = 0;
                    files(i).loop = check(i);
                else
                    check(i) = trials/numSubtrials;
                    files(i).loop = check(i);
                end
            else
                check(i) = 1;
                files(i).loop = check(i);
            end            
        end
    end
end
