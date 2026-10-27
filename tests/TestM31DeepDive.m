classdef TestM31DeepDive < matlab.unittest.TestCase
    %TESTM31DEEPDIVE M3.1 reconstruction, pairs, diagnostics, sweeps & plots.
    methods (Test)
        function reconstructExactQueueArea(testCase)
            c=fixture();
            c.source.times=[0;0];
            c.network.nodes.nServers=1;
            c.network.nodes.serverSpeedMultipliers=1;
            c.network.nodes.serviceDistribution.type='sequence';
            c.network.nodes.serviceDistribution.values=[2;2];
            r=qsim.run(c);
            t=qsim.analysis.reconstructTrace(r);
            testCase.verifyEqual(t.time,[0;2;4;6]);
            testCase.verifyEqual(t.queueTotal,[1;0;0;0]);
            testCase.verifyEqual(t.busyTotal,[1;1;0;0]);
            testCase.verifyEqual(t.meanQueueLength,2/6,'AbsTol',1e-12);
            testCase.verifyEqual(t.meanUtilization,4/6,'AbsTol',1e-12);
            testCase.verifyEqual(t.strandedTimeFraction,0,'AbsTol',1e-12);
            testCase.verifyEqual(t.meanQueueLength,r.system.meanQueueLength,'AbsTol',1e-12);
        end

        function exactTieNoPhantomQueue(testCase)
            c=fixture();
            c.network.nodes.nServers=1;
            c.network.nodes.serverSpeedMultipliers=1;
            c.source.times=[0;2];
            c.network.nodes.serviceDistribution.type='sequence';
            c.network.nodes.serviceDistribution.values=[2;2];
            r=qsim.run(c);
            t=qsim.analysis.reconstructTrace(r);
            testCase.verifyEqual(t.queueTotal,zeros(size(t.queueTotal)));
            testCase.verifyEqual(t.meanQueueLength,0);
        end

        function zeroDemandIsAValidTrace(testCase)
            c=fixture();
            c.source.times=[];
            r=qsim.run(c);
            t=qsim.analysis.reconstructTrace(r);
            testCase.verifyEqual(t.time,[0;6]);
            testCase.verifyEqual(t.queueTotal,[0;0]);
            testCase.verifyEqual(t.busyTotal,[0;0]);
        end

        function dedicatedLineTraceConservesArea(testCase)
            c=fixture();
            c.source.times=[0;0;0;1;2];
            c.network.nodes.queueMode='separateFIFO';
            c.network.nodes.routingPolicy='shortestQueue';
            r=qsim.run(c);
            t=qsim.analysis.reconstructTrace(r);
            testCase.verifyEqual(sum(t.queueByLine,2),t.queueTotal);
            testCase.verifyEqual(sum(t.busyByServer,2),t.busyTotal);
            testCase.verifyEqual(t.meanQueueLength,r.system.meanQueueLength,'AbsTol',1e-10);
        end

        function pooledCannotStrandIdleCapacity(testCase)
            c=fixture();
            c.source.times=[0;0;0;0];
            c.network.nodes.serviceDistribution.type='sequence';
            c.network.nodes.serviceDistribution.values=[100;1;2;1];
            c.network.nodes.queueMode='pooledFIFO';
            r=qsim.run(c);
            t=qsim.analysis.reconstructTrace(r);
            testCase.verifyEqual(t.strandedTimeFraction,0,'AbsTol',1e-12);
        end

        function dedicatedLinesCanStrandCapacity(testCase)
            c=fixture();
            c.source.times=[0;0;0;0];
            c.network.nodes.serviceDistribution.type='sequence';
            c.network.nodes.serviceDistribution.values=[100;1;2;1];
            c.network.nodes.queueMode='separateFIFO';
            c.network.nodes.routingPolicy='shortestQueue';
            r=qsim.run(c);
            t=qsim.analysis.reconstructTrace(r);
            testCase.verifyEqual(t.strandedTimeFraction,4/6,'AbsTol',1e-12);
        end

        function traceRequiresEntityRecords(testCase)
            c=fixture();
            c.output.retainEntityRecords=false;
            r=qsim.run(c);
            testCase.verifyError(@()qsim.analysis.reconstructTrace(r),'qsim:InvalidTrace');
        end

        function empiricalCDFHandlesTiesAndEmpty(testCase)
            [x,y]=qsim.analysis.empiricalCDF([1;1;3;5;NaN]);
            testCase.verifyEqual(x,[1;3;5]);
            testCase.verifyEqual(y,[.5;.75;1],'AbsTol',1e-12);
            [x,y]=qsim.analysis.empiricalCDF([]);
            testCase.verifyEmpty(x); testCase.verifyEmpty(y);
        end

        function allPairwiseDifferenceSign(testCase)
            c=fixture(); sc=qsim.experiments.defaultPolicyScenarios();
            r=qsim.experiments.comparePolicies(c,sc,struct('nRep',3,'seedStart',7210));
            d=qsim.analysis.pairwiseMeanWait(r);
            testCase.verifyEqual(numel(d),3);
            testCase.verifyEqual(d(3).scenarioA,'Pooled FIFO');
            testCase.verifyEqual(d(3).scenarioB,'Dedicated Smart');
            vals=r.raw.meanWait(:,3)-r.raw.meanWait(:,2);
            valid=vals(isfinite(vals));
            testCase.verifyEqual(d(3).ci.mean,mean(valid),'AbsTol',1e-12);
        end

        function diagnosticsUseCorrectServerShape(testCase)
            c=fixture(); sc=qsim.experiments.defaultPolicyScenarios();
            r=qsim.analysis.collectDiagnostics(c,sc,[14;15]);
            testCase.verifySize(r.perServerUtilization,[2,2,3]);
            testCase.verifySize(r.meanServerUtilization,[3,2]);
            testCase.verifySize(r.strandedTimeFraction,[2,3]);
            testCase.verifyGreaterThanOrEqual(r.strandedTimeFraction,0);
            testCase.verifyLessThanOrEqual(r.strandedTimeFraction,1);
            testCase.verifyGreaterThanOrEqual(r.perServerUtilization,0);
            testCase.verifyLessThanOrEqual(r.perServerUtilization,1);
        end

        function independentLoadAndStaffSweeps(testCase)
            c=fixture(); c.source.type='poisson'; c.source.rate=0.6;
            sc=qsim.experiments.defaultPolicyScenarios();
            opt=struct('nRep',2,'seedStart',9100);
            s=struct('kind','arrivalRate','values',[0.4,0.6]);
            a=qsim.experiments.sweepPolicySensitivity(c,sc,s,opt);
            testCase.verifySize(a.mean,[2,3,5]);
            testCase.verifyEqual(a.offeredLoad,[0.4;0.6],'AbsTol',1e-12);
            testCase.verifyEqual(a.nServers,[2;2]);
            s=struct('kind','serverCount','values',[2,3], ...
                'serverSpeeds',[1,1,1.2]);
            b=qsim.experiments.sweepPolicySensitivity(c,sc,s,opt);
            testCase.verifySize(b.mean,[2,3,5]);
            testCase.verifyEqual(b.nServers,[2;3]);
            testCase.verifyLessThan(b.offeredLoad(2),b.offeredLoad(1));
        end

        function invalidSweepRejected(testCase)
            c=fixture(); sc=qsim.experiments.defaultPolicyScenarios();
            bad=struct('kind','serverCount','values',[2,3],'serverSpeeds',[1,1]);
            testCase.verifyError(@()qsim.experiments.sweepPolicySensitivity(c,sc,bad), ...
                'qsim:InvalidSweep');
        end

        function plotExportSmoke(testCase)
            % Minimal graphics test: should run on desktop MATLAB R2022b.
            c=fixture(); sc=qsim.experiments.defaultPolicyScenarios();
            opt=struct('nRep',2,'seedStart',6100);
            baseline=qsim.experiments.comparePolicies(c,sc,opt);
            for j=1:3
                cc=c;
                cc.simulation.seed=6100;
                cc.network.nodes.queueMode=sc(j).queueMode;
                cc.network.nodes.routingPolicy=sc(j).routingPolicy;
                one=qsim.run(cc);
                trace=qsim.analysis.reconstructTrace(one);
                if j==1
                    runOne=repmat(one,1,3);
                    tr=repmat(trace,1,3);
                end
                runOne(j)=one;
                tr(j)=trace;
            end
            diag=qsim.analysis.collectDiagnostics(c,sc,[22;23]);
            cs=c; cs.source.type='poisson'; cs.source.rate=.6;
            a=qsim.experiments.sweepPolicySensitivity(cs,sc, ...
                struct('kind','arrivalRate','values',[.4,.6]),opt);
            b=qsim.experiments.sweepPolicySensitivity(cs,sc, ...
                struct('kind','serverCount','values',[2,3], ...
                    'serverSpeeds',[1,1,1]),opt);
            folder=tempname; mkdir(folder);
            cleanup=onCleanup(@()rmdir(folder,'s')); %#ok<NASGU>
            images=qsim.plots.plotDeepDive(baseline,runOne,tr,diag,a,b,folder);
            paths=struct2cell(images);
            testCase.verifyEqual(numel(paths),4);
            for i=1:numel(paths), testCase.verifyTrue(exist(paths{i},'file')==2); end
            csvs=qsim.experiments.exportDeepDiveTables(baseline,diag,a,b,folder);
            p=struct2cell(csvs);
            for i=1:numel(p), testCase.verifyTrue(exist(p{i},'file')==2); end
        end
    end
end

function c=fixture()
c=qsim.defaultConfig();
c.simulation.arrivalHorizon=3;
c.simulation.observationHorizon=6;
c.source.type='schedule';
c.source.times=[0;.25;.50;1;2];
c.network.nodes.nServers=2;
c.network.nodes.serverSpeedMultipliers=[1,1];
c.network.nodes.serviceDistribution.type='deterministic';
c.network.nodes.serviceDistribution.value=2;
end
