%% Basic json decoder by Seb Oct 2023
% This script will only work for already cleaned data folders with one file per task on each subject
close all; clear all;

% Turn this on and off to either show all figures or not
AllFigures = 1;

% Load demographic data from Excel file
Demodata = readtable('Demographics + HL.csv');
% Clean dataset from problematic PARTicipants
Demodata([4,11,21,27,29,31],:) = [];
% Extract numeric matrix
Demodatamat = table2array(Demodata); 
% Extract column labels
Demolabels = Demodata.Properties.VariableNames;

% Load your subject name/s here (1st dimension of data)
subjNami = {'VR001';'VR002';'VR003';'VR004';'VR005';'VR006';'VR007';'VR008';'VR009';'VR010';'VR011';'VR012';...
    'VR013';'VR014';'VR015';'VR016';'VR017';'VR018';'VR019';'VR020';'VR021';'VR022';'VR023';'VR024';'VR025';...
    'VR026';'VR027';'VR028';'VR029';'VR030';'VR031';'VR032';'VR033';'VR034';'VR035';'VR036';'VR037';'VR038';...
    'VR039';'VR040';'VR041';'VR042';'VR043';'VR044';'VR045';'VR046';'VR047';'VR048';'VR049';'VR050';'VR051';...
    'VR052';'VR053';'VR054';'VR055';'VR056';'VR057';'VR058';'VR059';'VR060';'VR061';'VR062';'VR063';'VR064';...
    'VR065';'VR066';'VR067';'VR068';'VR069';'VR070';'VR071';'VR072';'VR073';'VR074';'VR075';'VR076';'VR077';...
    'VR078';'VR079';'VR080';'VR081';'VR082';'VR083';'VR084';'VR085';'VR086';'VR087';'VR088';'VR089';'VR090';...
    'VR091';'VR092';'VR093'};

% Not sure why cant read these.... so they are excluded for now...
%excluded = {'VR004';'VR011';'VR021';'VR027';'VR029'};

subNum = length(subjNami);

% Load your tasks here (2nd dimension of data)
taskNami = {'DioticFM','DichoticFMAS','DioticFMRun2','DichoticFMASRun2',...
    'TemporalSensitivity','SpectralSensitivity','SpectroTemporalSensitivity',...
    'TemporalSensitivityRun2','SpectralSensitivityRun2','SpectroTemporalSensitivityRun2',...    
    'SR2Colocated', 'SR2Separated'};
taskNami_f = {'MFM','BFM','MFM2','BFM2','TM','SM','STM','TM2','SM2','STM2','SR2Col', 'SR2Sep'};
taskNum = length(taskNami);

% Set number of trials and data dimensions to register per trial
Max_noTrials = 200; % set the maximum number of trials possible
Dimensions = 2; %(1.parameter value, 2.iscorr)

% Pre-set the data matrices
Trialdata = NaN(length(subjNami),length(taskNami),Max_noTrials, Dimensions);
Threshdata = NaN(subNum,taskNum,2); % thresholds are estimates in first dimension and confidence of the estimate in the 2nd

% Decode the json files associated to the AS battery and store in data matrix
for s = 1:subNum
    for tk = 1:taskNum

        % Grab the file name (one per subject name per task)
        nami = dir([subjNami{s},'_','*_',taskNami{tk},'_*','.json']);

        if isempty(nami)
            disp([subjNami{s},'is missing',taskNami{tk}])
            continue;
        elseif length(nami)==1

            % Grab only the first subject-task combination (fix this to accomodate additional sessions of the same subject-test
            raw = fileread(nami(1).name);
            json = {jsondecode(raw)};

            % Grab relevant trial information
            for j = 1:length(json{1, 1}.data)
                Trialdata(s,tk,j,1) = str2double(json{1,1}.data(j).Parameters.Target(1).Value); % gets presented stimulus value
                Trialdata(s,tk,j,2) = json{1, 1}.data(j,:).CorrectResponse; % gets the response accuracy (correct = 1; incorrect = 0)
            end
        else
            disp(['There are ',num2str(length(nami)),' tasks completed in ',subjNami{s},taskNami{tk}, ', and ',num2str(length(nami)-1), ' will be ignored']);
        end
        clear nami raw json
    end
end

%% Data transformations
% FM tasks adapts on a logarithmic scale so it needs to be transformed to log2(ms) to be better visualized
Trialdata(:,1:4,:,1) = log2(Trialdata(:,1:4,:,1)); % Comment it out and find out :)
Trialdata(:,11:12,:,1) = 65 - Trialdata(:,11:12,:,1); % Comment it out and find out :)

%% Threshold calculations (they use SebStairs and SebASStairs functions)

% AS threshold calculation (STM & FM tasks)
guessRate = .5;
for s = 1:subNum
    for task = 1:10 
        if ~isnan(Trialdata(s,task,1,1))
            vector_a = squeeze(Trialdata(s,task,:,1))';
            vector_b = squeeze(Trialdata(s,task,:,2))';
            [temp_thresh, temp_confidence] = sebASStairs3(vector_a,vector_b,guessRate); % This is the weighted threshold function for AS with 3 scans only
            Threshdata(s,task,1:20) = temp_thresh;
            Threshdata(s,task,21:40) = temp_confidence;
        else
            continue;
        end
        clear temp_thresh temp_confidence
    end
end

% Up down staircase threshold calculation
for task = 11:12
    for s = 1:subNum
        if ~isnan(Trialdata(s,task,1,1))
            vector = squeeze(Trialdata(s,task,:,1))';
            [temp_thresh, temp_confidence] = sebStairs(vector); % This is a simple average of the last 6 reversals. Robust to cases with only 4 or 5 revs.
            Threshdata(s,task,1) = temp_thresh;
            Threshdata(s,task,2) = temp_confidence;
        else
            continue;
        end
        clear temp_thresh temp_confidence
    end
end

Threshdata_thresh3rd = squeeze(Threshdata(:,:,3));
Threshdata_conf3rd = squeeze(Threshdata(:,:,23));


%% Extract data from PART summaries (CAP)

% Not currently working because of Reading Speed Task doesnt have a task Name

% % Summary file names
% SumNami = {'BatteryLog'};
% 
% % Pre-set the data matrix
% PARTthresh_data = NaN(length(subjNami),length(taskNami));
% 
% % Decode the json files associated to the AS battery and store in data matrix
% for s = 1:subNum
% 
%     nami = dir([subjNami{s},'_','*_',SumNami{1},'_*','.json']);
%     if isempty(nami)
%         disp([subjNami{s},'is missing',SumNami{1}])
%         continue;
%     elseif length(nami)==1
% 
%         raw = fileread(nami(1).name);
%         json = {jsondecode(raw)};
% 
%         for j = 1:length(taskNami)
%             for jj = 1:length(json{1,1}.data)
% 
%                     if strcmp(taskNami,tempString)
%                         PARTthresh_data(s,j) = str2double(json{1,1}.data{jj,1}.Thresholds(1).Threshold);
%                     else
%                         continue;
%                     end
%                 
%             end
% 
%         end
%     else
%         disp(['There are ',num2str(length(nami)),' tasks completed in ',subjNami{s}])
%     end
%     clear nami raw json
% 
% end

%% Visualize the data

displayTrialIncorrData = 0; % Change to 1 to show markers for correct/incorrect trials. Might use a lot of time to perform.
if AllFigures == 1
     figure(13);
    for tk = 1:taskNum
       subplot(3,4,tk);
        for s = 1:subNum

            plot(1:Max_noTrials,squeeze(Trialdata(s,tk,:,1)), 'LineWidth',3); hold on;

            % Comment out the section below to get rid of correct/incorrect markers
            %         for j = 1:length(Trialdata(s,tk,:,2))
            %             if Trialdata(s,tk,j,2) == 0
            %                 scatter(j,Trialdata(s,tk,j,1),40,'mo', 'filled');
            %             else
            %                 scatter(j,Trialdata(s,tk,j,1),40,'bo', 'filled');
            %             end
            %         end

            title(taskNami_f{tk});

            % Comment out the line below to get rid of the threshold visualization
            % yline(Threshdata_thresh3rd(s,tk),'-.','lineWidth',2,'color',[.1 .8 .8]);

            xlabel('Trial');
            ylabel('stimulus magnitude');
            set(gca,'fontsize',18); box on; grid on;

        end
    end

end

%%

% Load your tasks here (2nd dimension of data)
taskNami_p = {'PipesCarlileSeparated', 'PipesCarlileColocated', 'PipesCRMSeparated', 'PipesCRMColocated'};
tasknum_p = length(taskNami_p);

% Set number of trials and data dimensions to register per trial
Max_noTrials_p = 200; % set the maximum number of trials possible
Dimensions_p = 2; %(1.parameter value, 2.iscorr)

% Pre-set the data matrix
dataAS_p = NaN(length(subjNami),length(taskNami_p),Max_noTrials_p, Dimensions_p);
threshAS_p=NaN(length(subjNami),length(taskNami_p));
Threshdata_p=NaN(length(subjNami),length(taskNami_p),30,2);

% Decode the json files associated to the AS battery and store in data matrix
for s = 1:subNum
    for tk = 1:tasknum_p

        nami = dir([subjNami{s},'_','*_',taskNami_p{tk},'_*','.json']);
        if isempty(nami)
            disp([subjNami{s},'is missing',taskNami_p{tk}])
            continue;
        elseif length(nami)==1

            raw = fileread(nami(1).name);
            json = {jsondecode(raw)};

            for j = 2:length(json{1, 1}.data)-1
                if strcmp(json{1, 1}.data{j,:}.EventType,'Trial')
                    dataAS_p(s,tk,j,1) = str2double(json{1,1}.data{j,1}.Parameters.Target(1).Value);
                    dataAS_p(s,tk,j,2) = json{1, 1}.data{j,:}.CorrectResponse;
                elseif strcmp(json{1, 1}.data{j,:}.EventType,'AlgorithmComplete')
                    threshAS_p(s,tk) = str2double(json{1, 1}.data{j,:}.Thresholds(1).Threshold);
                else
                    continue
                end
            end
        else
            disp(['There are ',num2str(length(nami)),' tasks completed in ',subjNami{s}])
        end
        clear nami raw json
    end
end

%% Transform the staircases to SNR

dataAS_p(:,:,:,1) = 65 - dataAS_p(:,:,:,1);
threshAS_p = 65 - threshAS_p;


%% Threshold calculations (they use SebASStairs3 functions)

% AS threshold calculation (Pipes)
guessRate = .0312;
for task = 1:tasknum_p
    for s = 1:subNum

        if ~isnan(dataAS_p(s,task,3,1))
            vector_a = squeeze(dataAS_p(s,task,:,1))';
            vector_b = squeeze(dataAS_p(s,task,:,2))';
            [t1, c1] = sebASStairs3(vector_a,vector_b,guessRate); % This is the weighted threshold function for AS with 3 scans only
            Threshdata_p(s,task,1:length(t1),1) = t1;
            Threshdata_p(s,task,1:length(t1),2) = c1;
            
        else
            continue;
        end
        clear vector_a vector_b iscorr t1 t2 t3 t4 t5 t6 t7 t8 c1 c2 c3 c4 c5 c6 c7 c8 Avg3 Avg8 Std3 Std8
    end
end

Threshdata_p_thresh = squeeze(Threshdata_p(:,:,:,1));
Threshdata_p_conf = squeeze(Threshdata_p(:,:,:,2));

for i = 1:subNum
    for ii = 1:tasknum_p
        if ~isnan(Threshdata_p_thresh(i,ii,1))
            lastVal = find(~isnan(Threshdata_p_thresh(i,ii,:)),1,'last');
            TotalAScans(i,ii) = lastVal; 
        else
            lastVal = 1;
        end
        Pipes_Sebthresh(i,ii) = Threshdata_p_thresh(i,ii,lastVal);
        Pipes_Sebconf(i,ii) = Threshdata_p_conf(i,ii,lastVal);
        clear lastVal
    end
end


%% Visualize the data

figure;
for s = 1:subNum
    for tk = 1:tasknum_p
        subplot(2,2,tk);

        plot(1:Max_noTrials_p,squeeze(dataAS_p(s,tk,:,1)), 'LineWidth',3); hold on;

%         % Comment out the section below to get rid of correct/incorrect markers
%         for j = 1:length(dataAS_p(s,tk,:,2))
%             if dataAS_p(s,tk,j,2) == 0
%                 scatter(j,dataAS_p(s,tk,j,1),40,'mo', 'filled');
%             else
%                 scatter(j,dataAS_p(s,tk,j,1),40,'bo', 'filled');
%             end
%         end

        title(taskNami_p{tk});
        xlim([0 120]);
        ylim([-30 20]);
        xticks(0:5:100);
        xlabel('Trial');
        ylabel('TMR dB');        
        set(gca,'fontsize',18); box on; grid on;

         % Comment out the line below to get rid of the threshold visualization
%         yline(threshAS_p(s,tk),'-.','lineWidth',3,'color',[.1 .8 .8]);
          yline(Pipes_Sebthresh(s,tk),'-.','lineWidth',3,'color',[.1 .1 .1]);

 

    end
end

%% Threshold is the (cumulative) threshold of the last scan
Threshdata_p_threshAVG = NaN(subNum,tasknum_p);
for i = 1:subNum
    for k = 1:tasknum_p
        goku = sum(~isnan(Threshdata_p_thresh(i,k,:)));
        if goku > 2
            Threshdata_p_threshAVG(i,k) = Threshdata_p_thresh(i,k,goku);
        end
    end
end

%%
figure(66);
subplot(2,2,1);
stem(1:subNum, TotalAScans(:,1),'color', 'b');
subplot(2,2,2);
stem(1.1:subNum+.1, TotalAScans(:,2),'color', 'r');
subplot(2,2,3);
stem(1.2:subNum+.2, TotalAScans(:,3),'color', 'm');
subplot(2,2,4);
stem(1.3:subNum+.3, TotalAScans(:,4),'color', 'k');

figure(66);
for i =1:4
    subplot(2,2,i)
    title(taskNami_p{i});
    xlabel('PARTicipant');
    ylabel('no. of cases');
    set(gca,'fontsize',18); box on; grid on;
    ylim([0 20]);
end
 
%%
figure(67);
for i=1:4;
    subplot(2,2,i);
    scatter(TotalAScans(:,i),Pipes_Sebthresh(:,i),30,Pipes_Sebconf(:,i));
    lsline;
    title(taskNami_p{i});
    xlabel('No. AScans');
    ylabel('TMR dB');
    set(gca,'fontsize',18); box on; grid on; 
end

