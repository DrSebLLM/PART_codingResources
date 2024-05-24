function [thresh, confidence] = sebASStairs3(StimVector,ResponseVector,guessRate) %by Seb Oct 2023

% StimVect is a vector with stimulus values
% RespVect is a vector with correct/incorrect responses
% last is the guess rate of behavioral paradigm used to elicit the data

MaxScan = 20; % sets max number of scans possible
thresh = NaN(1,MaxScan); % will store a vector of thresholds
confidence = NaN(1,MaxScan); % will store confidence of the threshold estimation

% Grab only non-NaN values for analysis
StimVector = squeeze(StimVector(~isnan(StimVector)));
ResponseVector = squeeze(ResponseVector(~isnan(ResponseVector)));

% Make sure input vectors are the same size after NaNs are removed
if length(StimVector) ~= length(ResponseVector)
    disp('warning: length of stimulus vector and response vector is not same');
end
if guessRate > .5
    disp('error guessRate should be <= .5');
end

% Find the start of each new scan (after the first)
biggerTest = squeeze(( StimVector(1:end-1) < StimVector(2:end) ) & ~isnan(StimVector(2:end))); %this variable detects if a trial value is larger than the previous and is not NaN
ScanStart_i = find(biggerTest==1); % This actually find scan starts after the first scan
% This transforms the extracted scanStart to the ScanEnd (previous trial)
ScanEnd_i = ScanStart_i - 1;

% Add the end of the last scan to the list
ScanEnd_i(end+1) = length(StimVector);

% Add the start of the first scan to the list
ScanStart_i = [1,ScanStart_i];

% Determine the total number of scans
ScanNum = length(ScanEnd_i);

% Establish the trial-ranges for each scan
if ScanNum > 1 % only if there is scan data to be processed...
    for scn = 1:ScanNum % for each scan...

        % Sum all hits for the range of the current scan
        hits1(scn) = sum(ResponseVector(1:ScanEnd_i(scn)));
        % Calculate number of trials (range) for the current scan (cumulative)
        nTrials1(scn) = length(1:ScanEnd_i(scn));
        % create a matrix with both stimulus and response values
        matrix = [StimVector(1:ScanEnd_i(scn)); ResponseVector(1:ScanEnd_i(scn))];

        % Sort both rows according to the numerical values of the first row (Stim values)
        [~, indices] = sort(matrix(1, :),'descend');
        sorted_matrix = matrix(:, indices);

        % Calculate threshold based on simple heuristic detailed in Lelo de Larrea-Mancera et al., 2023 AP&P
        stepThresh = round((hits1(scn) - nTrials1(scn) * (guessRate))/(1 - (guessRate)));

        if stepThresh > 0 % if hits are above chance level
            thresh(scn) = sorted_matrix(1,stepThresh); % calculate threshold using simple heuristic
        else % if performance at chance level
            thresh(scn) = StimVector(ScanStart_i(scn)); % calculate threshold at the beginning of current scan
        end
        % After the first scan, confidence is calculated from the std of consecutive threshold estimates
        if scn > 1
            confidence(scn) = std(thresh,'omitnan');
        end

    end

end

