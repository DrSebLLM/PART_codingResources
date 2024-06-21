% PART data extraction script with task examples from the online hearing study 
% written by E. Sebastian Lelo de Larrea-Mancera on June 2024
close all; clear all;

% Load your subjects here (1st dimension of data: rows). This is hard coded like
% this because the BGC data always comes with multiple participants that
% were testing the battery etc... It is not recommended to load files
% automatically unless you clean the data folders first.
subjNami = {'Esteban01';'Seb02';'whateverSubjName'};
subNum = length(subjNami);

% Load the name of your tasks here (2nd dimension of data: columns). The below
% examples are from the online study (ROHS). 
taskNami = {'GapAS','GapASr2','GapTask','DichoticFMAS','DichoticFMASr2','DichoticFM','DioticFMAS','DioticFMASr2','DioticFM',...
    'TMAS','TMASr2','TemporalSensitivity','SMAS','SMASr2','SpectralSensitivity','STMAS','STMASr2','SpectroTemporalSensitivity'...
    'CRMSingleAS','CRMSingleASr2','CRMSingleClassic','SR2ColAS','SR2ColASr2','SR2Colocated','SR2SepAS','SR2SepASr2','SR2Separated'};
taskNum = length(taskNami);

% Set number of trials and data dimensions to register per trial
Max_noTrials = 200; % set the maximum number of trials possible
Dimensions = 2; %(1.parameter value, 2.iscorr) %% more dimensions like RT could be added here

% Pre-set the data matrices
% dataAS has the trial by trial information
dataAS = NaN(length(subjNami),length(taskNami),Max_noTrials, Dimensions);

% thresholds are estimates in first dimension and confidence of the estimate in the 2nd
ThreshMat = NaN(subNum,taskNum,2); 


%% Decode the json files associated to the AS battery and store in data matrix
for s = 1:subNum
    for tk = 1:taskNum

        nami = dir([subjNami{s},'_','*_',taskNami{tk},'_*','.json']);
        if isempty(nami)
            disp([subjNami{s},'is missing',taskNami{tk}])
            continue;
        elseif length(nami)==1

            raw = fileread(nami(1).name);
            json = {jsondecode(raw)};

            for j = 1:length(json{1, 1}.data)
                dataAS(s,tk,j,1) = str2double(json{1,1}.data(j).Parameters.Target(1).Value);
                dataAS(s,tk,j,2) = json{1, 1}.data(j,:).CorrectResponse;
            end

        else
            disp(['There are ',num2str(length(nami)),' tasks completed in ',subjNami{s}])
        end
        clear nami raw json
    end
end

%% Threshold calculations

% Classic up-down staircases
for classic = 3:3:18
    for s = 1:subNum
        if ~isnan(dataAS(s,classic,1,1))
            vector = squeeze(dataAS(s,classic,:,1))';

            % My function to calculate threshold in staircases
            [temp_m, temp_sd] = sebStairs(vector); 
            ThreshMat(s,classic,1) = temp_m;
            ThreshMat(s,classic,2) = temp_sd;
        else
            continue;
        end
        clear temp_m temp_sd
    end
end

% Progressive tracks heuristic threshold calculation 
% (Lelo de Larrea-Mancera et al., 2024)
for s = 1:subNum
    if ~isnan(dataAS(s,21,1,1))
        iscorr = sum(squeeze(dataAS(s,21,:,2)),'omitnan');
        ThreshMat(s,21,1) = 67.5 - iscorr*2.5;
    end
    clear iscorr
end
for s = 1:subNum
    for task = [24 27]
        if ~isnan(dataAS(s,task,1,1))
            iscorr = sum(squeeze(dataAS(s,task,:,2)),'omitnan');
            ThreshMat(s,task,1) = 11 - iscorr;
        end
        clear iscorr
    end
end

% AS threshold calculation (everything except SRM because guess rate; adjust the guess rate for SRM tasks to .0312)
guessRate = .5;
for s = 1:subNum
    for task = [1:2 4:5 7:8 10:11 13:14 16:17]
        if ~isnan(dataAS(s,task,1,1))
            vector_a = squeeze(dataAS(s,task,:,1))';
            vector_b = squeeze(dataAS(s,task,:,2))';

            % My function to calculate threshold in AS
            [temp_m, temp_sd] = sebASStairs3(vector_a,vector_b,guessRate); 
            ThreshMat(s,task,1) = temp_m(3);
            ThreshMat(s,task,2) = temp_sd(3);
        else
            continue;
        end
        clear iscorr temp_m temp_sd
    end
end

%% Transform the exponentially adapting staircases

dataAS(:,1:9,:,1) = log2(dataAS(:,1:9,:,1));
ThreshMat(:,1:9,1) = log2(ThreshMat(:,1:9,1));
dataAS(:,22:27,:,1) = 65 - dataAS(:,22:27,:,1);

ThreshMat(ThreshMat == -Inf) = NaN;

%% Create the threshold matrix in csv

% Thresholds
% Combine labels and matrix data
dataToSave = [taskNami; num2cell(squeeze(ThreshMat(:,:,1)))];
% Specify the file name
fileName = 'ROHS_example_thresh.csv'; 
% Write data to CSV file
writetable(cell2table(dataToSave), fileName, 'WriteVariableNames', false);
disp(['CSV file "', fileName, '" saved successfully.']);
