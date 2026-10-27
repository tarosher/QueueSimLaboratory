function decision=staffingDecision(configs,comparison)
%STAFFINGDECISION Paired gains from one-server staffing alternatives.
% Positive gain = baseline mean end-to-end journey - alternative journey.
% Pairing requires identical exogenous laws (only nServers may change).
M=numel(configs);
if M<2 || numel(comparison.scenarioNames)~=M || ~comparison.arrivalMatched
    error('qsim:InvalidExperiment','Staffing requires matched configuration seeds.');
end
base=configs{1};
for a=2:M
    cfg=configs{a};
    if ~isequal(base.source,cfg.source) || ...
            ~isequal(base.simulation,cfg.simulation) || ...
            ~isequal(base.randomness,cfg.randomness) || ...
            ~isequal(base.output,cfg.output) || ...
            ~isequal(base.network.links,cfg.network.links) || ...
            numel(base.network.nodes)~=numel(cfg.network.nodes)
        error('qsim:InvalidExperiment','Staffing arms must share arrivals/routes.');
    end
    for v=1:numel(base.network.nodes)
        n1=base.network.nodes(v); n2=cfg.network.nodes(v);
        n1.nServers=0; n2.nServers=0; % only allowable difference
        % Node configurations contain NaN placeholders (e.g., inferred
        % routingServiceMean and unused distribution parameters). MATLAB
        % isequal returns false for NaN versus NaN, even for identical
        % configurations. isequaln treats matching NaNs as equal while
        % still rejecting changes to any non-staffing field.
        if ~isequaln(n1,n2)
            error('qsim:InvalidExperiment', ...
                'Non-staffing node attributes differ in scenario %d.',a);
        end
    end
end
baseline=comparison.raw.meanEndToEndSojourn(:,1);
name=cell(M,1); serverDelta=zeros(M,1); baselineMean=zeros(M,1);
journeyMean=nan(M,1); gainMean=nan(M,1); gainLower=nan(M,1);
gainUpper=nan(M,1); gainPerServer=nan(M,1); improvementPct=nan(M,1);
valid=zeros(M,1);
for a=1:M
    name{a}=comparison.scenarioNames{a};
    serverDelta(a)=sum([configs{a}.network.nodes.nServers])- ...
        sum([base.network.nodes.nServers]);
    baselineMean(a)=comparison.summary(1).metrics.meanEndToEndSojourn.mean;
    journeyMean(a)=comparison.summary(a).metrics.meanEndToEndSojourn.mean;
    diff=baseline-comparison.raw.meanEndToEndSojourn(:,a);
    ci=qsim.stats.meanCI(diff,comparison.options.confidence);
    gainMean(a)=ci.mean; gainLower(a)=ci.lower; gainUpper(a)=ci.upper;
    valid(a)=ci.nValid;
    if serverDelta(a)>0, gainPerServer(a)=ci.mean/serverDelta(a); end
    if baselineMean(a)>0
        improvementPct(a)=100*(baselineMean(a)-journeyMean(a))/baselineMean(a);
    end
end
decision=table(name,serverDelta,baselineMean,journeyMean,gainMean, ...
    gainLower,gainUpper,gainPerServer,improvementPct,valid, ...
    'VariableNames',{'scenario','additionalServers','baselineJourneyMin', ...
    'scenarioJourneyMin','pairedGainMin','gainCI_Lower', ...
    'gainCI_Upper','gainPerAdditionalServerMin', ...
    'pointImprovementPercent','nValidPairs'});
end
