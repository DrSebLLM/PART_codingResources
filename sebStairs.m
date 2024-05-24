function [Sebthresh, confidence] = sebStairs(Seb)

Seb = Seb(~isnan(Seb));
differenceTest = ( Seb(1:end-1) ~= Seb(2:end) ) & ~isnan(Seb(2:end)); %this variable detects if a trial value is different than the previous and is not NaN
uniqueValues = Seb(differenceTest);
paramDecreased = uniqueValues(1:end-1) > uniqueValues(2:end);
paramIncreased = uniqueValues(1:end-1) < uniqueValues(2:end);
reversals = [true paramIncreased(1:end-1) ~= paramIncreased(2:end)];
SebRev = uniqueValues(reversals);

if length(SebRev) >= 6
    Sebthresh = mean(SebRev(end-5:end),'omitnan');
    confidence = std(SebRev(end-5:end),'omitnan');
elseif length(SebRev) == 5
    Sebthresh = mean(SebRev(end-4:end),'omitnan');
    confidence = std(SebRev(end-4:end),'omitnan');
elseif length(SebRev) == 4
    Sebthresh = mean(SebRev(end-3:end),'omitnan');
    confidence = std(SebRev(end-3:end),'omitnan');
elseif length(SebRev) < 4
    Sebthresh = NaN;
    confidence = NaN;
end

end