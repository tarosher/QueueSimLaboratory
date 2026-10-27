classdef TestM3Experiments < matlab.unittest.TestCase
    %TESTM3EXPERIMENTS M3 statistics, coupling, benchmark invariants.
    methods (Test)
        function quantileType7AndMissing(testCase)
            testCase.verifyEqual(qsim.stats.empiricalQuantile([0;10;20],0.95),19,'AbsTol',1e-12);
            testCase.verifyEqual(qsim.stats.empiricalQuantile([5],0.95),5);
            testCase.verifyTrue(isnan(qsim.stats.empiricalQuantile([],0.95)));
        end

        function studentTCIAndZeroVariance(testCase)
            s=qsim.stats.meanCI([1;2;3],0.95);
            testCase.verifyEqual(s.mean,2,'AbsTol',1e-12);
            testCase.verifyEqual(s.halfWidth,4.30265273/sqrt(3),'RelTol',1e-6);
            testCase.verifyEqual(s.nValid,3);
            z=qsim.stats.meanCI([7;7;7]);
            testCase.verifyEqual([z.lower,z.upper],[7,7]);
        end

        function missingMetricsNotSilentlyZero(testCase)
            s=qsim.stats.meanCI([NaN;2;NaN;4]);
            testCase.verifyEqual(s.nValid,2);
            testCase.verifyEqual(s.nMissing,2);
            testCase.verifyEqual(s.mean,3);
            s=qsim.stats.meanCI([NaN;NaN]);
            testCase.verifyTrue(isnan(s.mean));
            testCase.verifyTrue(isnan(s.lower));
            emptyCI=qsim.stats.meanCI([]);
            testCase.verifyEqual(emptyCI.nValid,0);
            testCase.verifyTrue(isnan(emptyCI.mean));
        end

        function deterministicTraceAndEmpiricalP95(testCase)
            c=shortFixture();
            c.network.nodes.nServers=1;
            c.network.nodes.serverSpeedMultipliers=1;
            c.network.nodes.serviceDistribution.type='sequence';
            c.network.nodes.serviceDistribution.values=[2;2;2];
            c.source.times=[0;0;0];
            s=struct('name',{'Pooled','Dedicated'}, ...
                'queueMode',{'pooledFIFO','separateFIFO'}, ...
                'routingPolicy',{'shortestQueue','shortestQueue'});
            opts=struct('nRep',3,'seedStart',900,'confidence',0.95);
            result=qsim.experiments.comparePolicies(c,s,opts);
            testCase.verifyEqual(result.raw.meanWait,2*ones(3,2),'AbsTol',1e-12);
            testCase.verifyEqual(result.raw.p95Wait,3.8*ones(3,2),'AbsTol',1e-12);
            testCase.verifyEqual(result.paired(1).difference.meanWait.ci.mean,0);
            testCase.verifyEqual(result.paired(1).difference.meanWait.ci.halfWidth,0);
        end

        function crnPathEqualityAndRngRestoration(testCase)
            c=shortFixture();
            c.network.nodes.serviceDistribution=struct('type','exponential','rate',1, ...
                'value',NaN,'values',[]);
            scenarios=qsim.experiments.defaultPolicyScenarios();
            before=rng;
            r=qsim.experiments.comparePolicies(c,scenarios, ...
                struct('nRep',3,'seedStart',12400));
            after=rng;
            testCase.verifyEqual(after.State,before.State);
            testCase.verifyTrue(r.reproducibility.crnChecked);
            testCase.verifyEqual(r.reproducibility.seeds,[12400;12401;12402]);
            for i=1:3
                a=c;
                a.simulation.seed=12400+i-1;
                a.network.nodes.queueMode='pooledFIFO';
                x=qsim.run(a);
                a.network.nodes.queueMode='separateFIFO';
                a.network.nodes.routingPolicy='random';
                y=qsim.run(a);
                testCase.verifyEqual(x.entities.arrivals,y.entities.arrivals);
                testCase.verifyEqual(x.entities.serviceRequirements,y.entities.serviceRequirements);
            end
        end

        function scenarioOrderDoesNotChangeMetrics(testCase)
            c=shortFixture();
            scenarios=qsim.experiments.defaultPolicyScenarios();
            opts=struct('nRep',3,'seedStart',3400);
            forward=qsim.experiments.comparePolicies(c,scenarios,opts);
            reverse=qsim.experiments.comparePolicies(c,scenarios(end:-1:1),opts);
            testCase.verifyEqual(forward.raw.meanWait,reverse.raw.meanWait(:,end:-1:1));
            testCase.verifyEqual(forward.raw.p95Wait,reverse.raw.p95Wait(:,end:-1:1));
        end

        function emptyDemandRetainsMissingValueFlags(testCase)
            c=shortFixture();
            c.source.times=[];
            scenarios=qsim.experiments.defaultPolicyScenarios();
            r=qsim.experiments.comparePolicies(c,scenarios,struct('nRep',3));
            testCase.verifyTrue(all(isnan(r.raw.meanWait(:))));
            testCase.verifyEqual(r.summary(1).metrics.meanWait.nValid,0);
            testCase.verifyEqual(r.summary(1).metrics.meanWait.nMissing,3);
            testCase.verifyEqual(r.summary(1).metrics.rejectionRate.mean,0);
            testCase.verifyEqual(r.summary(1).metrics.throughput.mean,0);
        end

        function throughputExcludesDrainTail(testCase)
            c=shortFixture();
            c.source.times=[0;0;0];
            c.simulation.arrivalHorizon=1;
            c.simulation.observationHorizon=1;
            c.network.nodes.nServers=1;
            c.network.nodes.serverSpeedMultipliers=1;
            c.network.nodes.serviceDistribution.type='sequence';
            c.network.nodes.serviceDistribution.values=[2;2;2];
            scenarios=struct('name','Pooled','queueMode','pooledFIFO', ...
                'routingPolicy','shortestQueue');
            r=qsim.experiments.comparePolicies(c,scenarios,struct('nRep',2));
            testCase.verifyEqual(r.raw.throughput,zeros(2,1));
        end

        function rejectInvalidExperiment(testCase)
            c=shortFixture();
            scenarios=qsim.experiments.defaultPolicyScenarios();
            testCase.verifyError(@()qsim.experiments.comparePolicies(c,scenarios, ...
                struct('nRep',1)),'qsim:InvalidExperiment');
            testCase.verifyError(@()qsim.experiments.comparePolicies(c,scenarios, ...
                struct('nRep',3,'seedStart',2^32-2)),'qsim:InvalidExperiment');
            sc=scenarios;
            sc(2).name=sc(1).name;
            testCase.verifyError(@()qsim.experiments.comparePolicies(c,sc, ...
                struct('nRep',3)),'qsim:InvalidExperiment');
            c.output.retainEntityRecords=false;
            testCase.verifyError(@()qsim.experiments.comparePolicies(c,scenarios, ...
                struct('nRep',3)),'qsim:InvalidExperiment');
        end

        function pairedMeanDifferenceIsSampleWise(testCase)
            c=shortFixture();
            scenarios=qsim.experiments.defaultPolicyScenarios();
            r=qsim.experiments.comparePolicies(c,scenarios,struct('nRep',4));
            expected=r.raw.meanWait(:,2)-r.raw.meanWait(:,1);
            testCase.verifyEqual(r.paired(1).difference.meanWait.perReplication,expected);
        end
    end
end

function c=shortFixture()
c=qsim.defaultConfig();
c.simulation.arrivalHorizon=2;
c.simulation.observationHorizon=10;
c.source.type='schedule';
c.source.times=[0;0.1;0.2;0.3;0.4];
c.network.nodes.nServers=2;
c.network.nodes.serverSpeedMultipliers=[1,1.4];
c.network.nodes.serviceDistribution.type='deterministic';
c.network.nodes.serviceDistribution.value=2;
end
