classdef TestM41Diagnostics < matlab.unittest.TestCase
    %TESTM41DIAGNOSTICS Flow auditing, topology variation, paired decisions.
    methods (Test)
        function tandemFlowAuditsExactly(testCase)
            c=twoNodeFixture();
            c.source.times=[0;0;1];
            r=qsim.run(c);
            a=qsim.network.auditFlow(c,r);
            testCase.verifyEqual(a.maxAbsResidual,0);
            testCase.verifyEqual(a.arrived,[3 3]);
            testCase.verifyEqual(a.incoming,[0 3]);
            testCase.verifyEqual(a.outgoing,[3 0]);
            testCase.verifyEqual(a.sink,[0 3]);
        end
        function downstreamRejectionStillConservesEntities(testCase)
            c=twoNodeFixture();
            c.source.times=[0;0;0];
            c.network.nodes(1).nServers=3;
            c.network.nodes(2).maxSystemOccupancy=1;
            r=qsim.run(c);
            a=qsim.network.auditFlow(c,r);
            testCase.verifyEqual(a.maxAbsResidual,0);
            testCase.verifyEqual(r.system.rejected,2);
            testCase.verifyEqual(r.system.completed,1);
        end
        function corruptedLinkCountsAreDetected(testCase)
            c=twoNodeFixture(); c.source.times=0;
            r=qsim.run(c);
            r.network.linkTraversalCounts(1)=r.network.linkTraversalCounts(1)+1;
            testCase.verifyError(@()qsim.network.auditFlow(c,r), ...
                'qsim:NetworkInvariant');
        end
        function truncationNotMisrepresentedAsConserved(testCase)
            c=twoNodeFixture(); c.simulation.stopMode='truncate';
            r=qsim.run(c);
            testCase.verifyError(@()qsim.network.auditFlow(c,r), ...
                'qsim:InvalidExperiment');
        end
        function variableLinkCountsSupported(testCase)
            a=qsim.network.benchmarkCConfig('serial',.4);
            b=qsim.network.benchmarkCConfig('parallel-balanced',.4);
            a.simulation.arrivalHorizon=15; a.simulation.observationHorizon=15;
            b.simulation.arrivalHorizon=15; b.simulation.observationHorizon=15;
            res=qsim.network.compareConfigurations({a,b},{'S','P'}, ...
                struct('nRep',2,'seedStart',420));
            testCase.verifySize(res.flow.linkTraversals,[2 2]);
            testCase.verifyEqual(numel(res.flow.linkTraversals{1,1}),3);
            testCase.verifyEqual(numel(res.flow.linkTraversals{1,2}),4);
            d=qsim.network.experimentDiagnostics({a,b},res);
            testCase.verifyEqual(max(d.maxCountResidual),0);
            testCase.verifyEqual(height(d.nodes),8);
        end
        function identicalConfigHasZeroPairedGain(testCase)
            a=qsim.network.benchmarkBConfig();
            a.simulation.arrivalHorizon=12;
            a.simulation.observationHorizon=12;
            r=qsim.network.compareConfigurations({a,a},{'Baseline','Copy'}, ...
                struct('nRep',3,'seedStart',330));
            d=qsim.network.staffingDecision({a,a},r);
            testCase.verifyEqual(d.pairedGainMin,[0;0],'AbsTol',1e-12);
            testCase.verifyEqual(d.gainCI_Upper,[0;0],'AbsTol',1e-12);
            flow=qsim.network.experimentDiagnostics({a,a},r);
            testCase.verifyEqual(max(flow.maxCountResidual),0);
        end
        function serverCountOnlyIsAccepted(testCase)
            % A genuine staffing intervention may change nServers only.
            base=qsim.network.benchmarkBConfig();
            base.source.type='schedule';
            base.source.times=[0;1;2;3];
            base.simulation.arrivalHorizon=10;
            base.simulation.observationHorizon=10;
            alternative=base;
            alternative.network.nodes(4).nServers= ...
                alternative.network.nodes(4).nServers+1;
            comp=qsim.network.compareConfigurations( ...
                {base,alternative},{'Baseline','Add C server'}, ...
                struct('nRep',3,'seedStart',340));
            d=qsim.network.staffingDecision({base,alternative},comp);
            testCase.verifyEqual(d.additionalServers,[0;1]);
            testCase.verifyEqual(d.nValidPairs,[3;3]);
            testCase.verifyEqual(d.pairedGainMin(1),0,'AbsTol',1e-12);
        end
        function nanSentinelChangeIsRejected(testCase)
            % isequaln must not mistake NaN -> finite as an allowed change.
            base=qsim.network.benchmarkBConfig();
            base.source.type='schedule';
            base.source.times=[0;1;2];
            base.simulation.arrivalHorizon=10;
            base.simulation.observationHorizon=10;
            modified=base;
            modified.network.nodes(1).routingServiceMean=1;
            comp=qsim.network.compareConfigurations( ...
                {base,modified},{'Baseline','Changed routing mean'}, ...
                struct('nRep',2,'seedStart',350));
            testCase.verifyError( ...
                @()qsim.network.staffingDecision({base,modified},comp), ...
                'qsim:InvalidExperiment');
        end
        function staffingCannotChangeServiceLaws(testCase)
            a=qsim.network.benchmarkBConfig();
            a.simulation.arrivalHorizon=12;
            a.simulation.observationHorizon=12;
            b=a; b.network.nodes(2).serviceDistribution.rate=.99;
            r=qsim.network.compareConfigurations({a,b},{'Baseline','Different'}, ...
                struct('nRep',2,'seedStart',310));
            testCase.verifyError(@()qsim.network.staffingDecision({a,b},r), ...
                'qsim:InvalidExperiment');
        end
        function skewedMiddleNodeIsOverloaded(testCase)
            c=qsim.network.benchmarkCConfig('parallel-skewed',.85);
            flow=qsim.network.expectedVisitRates(c);
            testCase.verifyEqual(flow.nodeRates(2),.68,'AbsTol',1e-10);
            meanWork=qsim.core.expectedServiceMean(c.network.nodes(2));
            load=flow.nodeRates(2)*meanWork/c.network.nodes(2).nServers;
            testCase.verifyEqual(load,1.36,'AbsTol',1e-10);
        end
        function integratedReportWriterUsesRealInputs(testCase)
            c=qsim.network.benchmarkBConfig();
            c.simulation.arrivalHorizon=8;
            c.simulation.observationHorizon=8;
            compared=qsim.network.compareConfigurations({c,c}, ...
                {'Baseline','Copy'},struct('nRep',2,'seedStart',950));
            d=qsim.network.experimentDiagnostics({c,c},compared);
            staffing=qsim.network.staffingDecision({c,c},compared);
            a.summary=struct('name','Sample policy','metrics',struct( ...
                'meanWait',qsim.stats.meanCI([1;2],.95), ...
                'p95Wait',qsim.stats.meanCI([3;4],.95)));
            ct=d.nodes;
            ct.demandLevel=ones(height(ct),1);
            ct.arrivalRatePerMin=.63*ones(height(ct),1);
            folder=tempname; mkdir(folder);
            cleaner=onCleanup(@()rmdir(folder,'s'));
            path=qsim.reports.writeM41Report(folder,a,compared, ...
                {compared},d.nodes,ct,staffing);
            testCase.verifyTrue(exist(path,'file')==2);
            content=fileread(path);
            % Check each benchmark section, not just an incidental word.
            testCase.verifyTrue(contains(content,'### Benchmark A:'));
            testCase.verifyTrue(contains(content,'### Benchmark B:'));
            testCase.verifyTrue(contains(content,'### Benchmark C:'));
            % The report must contain results from the fixture, not only headings.
            testCase.verifyTrue(contains(content,'| Sample policy | 1.500 |'));
            testCase.verifyTrue(contains(content,'| Baseline |'));
            testCase.verifyTrue(contains(content,'Max node offered load'));
        end
        function demandTaggingHandlesUnequalNodeCounts(testCase)
            x=table({'serial';'parallel'}, {'A';'B'}, ...
                'VariableNames',{'scenario','node'});
            y=table({'serial';'parallel';'parallel'}, {'A';'B';'C'}, ...
                'VariableNames',{'scenario','node'});
            out=qsim.reports.tagDemandLevels({x,y},[.45,.85]);
            testCase.verifyEqual(height(out),5);
            testCase.verifyEqual(out.demandLevel,[1;1;2;2;2]);
            testCase.verifyEqual(out.arrivalRatePerMin, ...
                [.45;.45;.85;.85;.85],'AbsTol',1e-12);
        end
        function demandTaggingWorksWithColumnOrRowRates(testCase)
            x=table({'A';'B'},[1;2],'VariableNames',{'node','count'});
            y=table({'A'},3,'VariableNames',{'node','count'});
            row=qsim.reports.tagDemandLevels({x,y},[.4 .8]);
            col=qsim.reports.tagDemandLevels({x,y},[.4;.8]);
            testCase.verifyEqual(row,col);
            testCase.verifySize(row.arrivalRatePerMin,[3 1]);
        end
        function demandTaggingRejectsInvalidInputs(testCase)
            x=table({'A'},1,'VariableNames',{'node','count'});
            testCase.verifyError( ...
                @()qsim.reports.tagDemandLevels({x,x},.4), ...
                'qsim:InvalidExperiment');
            testCase.verifyError( ...
                @()qsim.reports.tagDemandLevels({x},NaN), ...
                'qsim:InvalidExperiment');
        end
        function taggedDemandCSVHasCorrectHeightAndValues(testCase)
            x=table({'A';'B'},[1;2],'VariableNames',{'node','count'});
            y=table({'C';'D';'E'},[3;4;5], ...
                'VariableNames',{'node','count'});
            t=qsim.reports.tagDemandLevels({x,y},[.45,.85]);
            path=[tempname '.csv'];
            cleaner=onCleanup(@()delete(path));
            writetable(t,path);
            back=readtable(path);
            testCase.verifyEqual(height(back),5);
            testCase.verifyEqual(back.demandLevel,[1;1;2;2;2]);
            testCase.verifyEqual(back.arrivalRatePerMin, ...
                [.45;.45;.85;.85;.85],'AbsTol',1e-12);
        end
        function normalizedTidyRow(testCase)
            ci=qsim.stats.meanCI([1 2 3],.95);
            row=qsim.reports.metricRow('A','FIFO','baseline','wait',ci,'min');
            testCase.verifyEqual(numel(row),9);
            testCase.verifyEqual(row{5},2,'AbsTol',1e-12);
            testCase.verifyEqual(row{8},3);
        end
    end
end
function c=twoNodeFixture()
c=qsim.defaultConfig();
c.extensions.network=true;
c.source.type='schedule';
c.source.times=[0;1];
c.source.entryNode='A';
c.simulation.arrivalHorizon=5;
c.simulation.observationHorizon=5;
c.simulation.stopMode='drain';
a=qsim.network.nodeConfig('A');
b=qsim.network.nodeConfig('B');
a.serviceDistribution.type='deterministic';
a.serviceDistribution.value=1;
b.serviceDistribution.type='deterministic';
b.serviceDistribution.value=1;
c.network.nodes=[a b];
c.network.links=qsim.network.makeLink('A','B',1);
end
