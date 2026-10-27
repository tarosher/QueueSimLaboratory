classdef TestM1Core < matlab.unittest.TestCase
    % TESTM1CORE Baseline correctness checks, no optional MATLAB toolbox.
    methods (Test)
        function zeroDemand(testCase)
            c=qsim.defaultConfig();
            c.source.type='schedule';
            c.source.times=[];
            r=qsim.run(c);
            testCase.verifyEqual(r.system.arrived,0);
            testCase.verifyEqual(r.system.backlog,0);
            testCase.verifyEqual(r.system.meanQueueLength,0);
            testCase.verifyTrue(isnan(r.system.meanWaitStartedCohort));
        end

        function zeroDemandWithEmptyServiceSequence(testCase)
            % Regression: MATLAB isvector([]) is false for 0-by-0 arrays.
            c=qsim.defaultConfig();
            c.source.type='schedule';
            c.source.times=[];
            c.network.nodes.serviceDistribution.type='sequence';
            c.network.nodes.serviceDistribution.values=[];
            r=qsim.run(c);
            testCase.verifyEqual(r.system.generated,0);
            testCase.verifyEqual(r.system.arrived,0);
            testCase.verifyEqual(r.system.completed,0);
            testCase.verifyEqual(r.system.meanServerUtilization,0);
            testCase.verifyEmpty(r.entities.id);
        end

        function zeroDemandWithPoissonRateZero(testCase)
            % A zero Poisson rate is a valid empty arrival process.
            c=qsim.defaultConfig();
            c.source.type='poisson';
            c.source.rate=0;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.generated,0);
            testCase.verifyEqual(r.system.arrived,0);
            testCase.verifyEqual(r.system.backlog,0);
            testCase.verifyEqual(r.system.meanQueueLength,0);
        end

        function knownSingleServerTrace(testCase)
            c=qsim.defaultConfig();
            c.simulation.arrivalHorizon=4.5;
            c.simulation.observationHorizon=12;
            c.source.type='schedule';
            c.source.times=[1.2;2.2;3.2;4.2];
            c.network.nodes.serviceDistribution.type='sequence';
            c.network.nodes.serviceDistribution.values=[2;1;0.5;1];
            r=qsim.run(c);
            testCase.verifyEqual(r.system.arrived,4);
            testCase.verifyEqual(r.system.completed,4);
            testCase.verifyEqual(r.system.backlog,0);
            testCase.verifyEqual(r.system.meanWaitStartedCohort,0.625,'AbsTol',1e-9);
            testCase.verifyEqual(r.system.totalQueueArea,2.5,'AbsTol',1e-9);
            testCase.verifyEqual(r.system.totalBusyArea,4.5,'AbsTol',1e-9);
            testCase.verifyEqual(r.entities.wait,[0;1;1;0.5],'AbsTol',1e-9);
            testCase.verifyEqual(r.entities.departure,[3.2;4.2;4.7;5.7],'AbsTol',1e-9);
        end

        function truncateKeepsUnfinished(testCase)
            c=qsim.defaultConfig();
            c.simulation.arrivalHorizon=2;
            c.simulation.observationHorizon=2;
            c.simulation.stopMode='truncate';
            c.source.type='schedule';
            c.source.times=[1;1.5];
            c.network.nodes.serviceDistribution.type='sequence';
            c.network.nodes.serviceDistribution.values=[4;2];
            r=qsim.run(c);
            testCase.verifyEqual(r.system.arrived,2);
            testCase.verifyEqual(r.system.completed,0);
            testCase.verifyEqual(r.system.backlog,2);
            testCase.verifyEqual(r.system.waitObservedCount,1);
            testCase.verifyTrue(isnan(r.entities.wait(2)));
            testCase.verifyEqual(r.system.meanQueueLength,0.25,'AbsTol',1e-9);
        end

        function seedIsReproducibleAndRestored(testCase)
            c=qsim.defaultConfig();
            prior=rng;
            r1=qsim.run(c);
            mid=rng;
            r2=qsim.run(c);
            after=rng;
            testCase.verifyEqual(r1.entities.arrivals,r2.entities.arrivals);
            testCase.verifyEqual(r1.entities.serviceRequirements,r2.entities.serviceRequirements);
            testCase.verifyEqual(mid.State,prior.State);
            testCase.verifyEqual(after.State,prior.State);
        end

        function extensionsAreRejectedUntilImplemented(testCase)
            c=qsim.defaultConfig();
            c.extensions.energy=true;
            testCase.verifyError(@()qsim.run(c),'qsim:UnsupportedExtension');
        end

        function erlangCExactBenchmarks(testCase)
            a=qsim.stats.erlangC(0.8,1,1);
            testCase.verifyEqual(a.Wq,4,'AbsTol',1e-12);
            testCase.verifyEqual(a.rho,0.8,'AbsTol',1e-12);
            testCase.verifyEqual(a.Lq,3.2,'AbsTol',1e-12);
            b=qsim.stats.erlangC(1,1,2);
            testCase.verifyEqual(b.probabilityWait,1/3,'AbsTol',1e-12);
            testCase.verifyEqual(b.Wq,1/3,'AbsTol',1e-12);
        end

        function monteCarloMM1Sanity(testCase)
            c=qsim.defaultConfig();
            c.source.rate=0.65;
            c.network.nodes.serviceDistribution.rate=1;
            c.simulation.arrivalHorizon=60000;
            c.simulation.observationHorizon=60000;
            c.simulation.seed=7813;
            r=qsim.run(c);
            t=qsim.stats.erlangC(0.65,1,1);
            testCase.verifyLessThan(abs(r.system.meanWaitStartedCohort/t.Wq-1),0.15);
            testCase.verifyLessThan(abs(r.system.meanServerUtilization-t.rho),0.025);
        end

        function monteCarloMM2Sanity(testCase)
            c=qsim.defaultConfig();
            c.source.rate=1;
            c.network.nodes.nServers=2;
            c.network.nodes.serviceDistribution.rate=1;
            c.simulation.arrivalHorizon=60000;
            c.simulation.observationHorizon=60000;
            c.simulation.seed=94213;
            r=qsim.run(c);
            t=qsim.stats.erlangC(1,1,2);
            testCase.verifyLessThan(abs(r.system.meanWaitStartedCohort/t.Wq-1),0.15);
            testCase.verifyLessThan(abs(r.system.meanServerUtilization-t.rho),0.025);
        end
    end
end
