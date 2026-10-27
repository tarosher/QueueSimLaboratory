function files = exportPolicyTables(result,outputFolder)
%EXPORTPOLICYTABLES Write long-form replication, CI, and paired CI CSVs.
% Plain CSV files can be checked without MATLAB, imported by spreadsheet tools.
if nargin<2 || isempty(outputFolder)
    outputFolder=fullfile(pwd,'outputs','benchmarkA');
end
if ~exist(outputFolder,'dir'), mkdir(outputFolder); end
keys=result.metrics;
nRep=result.options.nRep;
nArms=numel(result.scenarios);
rawRows=nRep*nArms;
reps=zeros(rawRows,1);
seeds=zeros(rawRows,1);
scenario=cell(rawRows,1);
vals=NaN(rawRows,numel(keys));
row=0;
for i=1:nRep
    for j=1:nArms
        row=row+1;
        reps(row)=i;
        seeds(row)=result.reproducibility.seeds(i);
        scenario{row}=result.scenarios(j).name;
        for m=1:numel(keys)
            v=result.raw.(keys{m});
            vals(row,m)=v(i,j);
        end
    end
end
rawTable=table(reps,seeds,scenario,'VariableNames',{'replication','seed','scenario'});
for m=1:numel(keys)
    rawTable.(keys{m})=vals(:,m);
end
files=struct();
files.raw=fullfile(outputFolder,'benchmarkA_replications.csv');
writetable(rawTable,files.raw);

n=numel(keys)*nArms;
names=cell(n,1); metric=cell(n,1);
meanValue=NaN(n,1); ciLower=NaN(n,1); ciUpper=NaN(n,1);
nValid=zeros(n,1); nMissing=zeros(n,1);
row=0;
for j=1:nArms
    for m=1:numel(keys)
        row=row+1;
        names{row}=result.scenarios(j).name;
        metric{row}=keys{m};
        ci=result.summary(j).metrics.(keys{m});
        meanValue(row)=ci.mean;
        ciLower(row)=ci.lower;
        ciUpper(row)=ci.upper;
        nValid(row)=ci.nValid;
        nMissing(row)=ci.nMissing;
    end
end
summaryTable=table(names,metric,meanValue,ciLower,ciUpper,nValid,nMissing, ...
    'VariableNames',{'scenario','metric','mean','ciLower','ciUpper','nValid','nMissing'});
files.summary=fullfile(outputFolder,'benchmarkA_summary.csv');
writetable(summaryTable,files.summary);

n=numel(keys)*numel(result.paired);
ref=cell(n,1); contrast=cell(n,1); metric=cell(n,1);
meanDifference=NaN(n,1); ciLower=NaN(n,1); ciUpper=NaN(n,1);
nValid=zeros(n,1); nMissing=zeros(n,1);
row=0;
for j=1:numel(result.paired)
    for m=1:numel(keys)
        row=row+1;
        ref{row}=result.paired(j).reference;
        contrast{row}=result.paired(j).name;
        metric{row}=keys{m};
        ci=result.paired(j).difference.(keys{m}).ci;
        meanDifference(row)=ci.mean;
        ciLower(row)=ci.lower;
        ciUpper(row)=ci.upper;
        nValid(row)=ci.nValid;
        nMissing(row)=ci.nMissing;
    end
end
pairedTable=table(ref,contrast,metric,meanDifference,ciLower,ciUpper,nValid,nMissing, ...
    'VariableNames',{'reference','contrast','metric','meanDifference','ciLower','ciUpper','nValid','nMissing'});
files.paired=fullfile(outputFolder,'benchmarkA_paired.csv');
writetable(pairedTable,files.paired);
end
