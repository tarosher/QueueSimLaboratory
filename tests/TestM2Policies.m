classdef TestM2Policies < matlab.unittest.TestCase
    %TESTM2POLICIES Deterministic traces, conservation, limits and policies.
    methods (Test)
        function pooledVsDedicatedDeterministic(testCase)
            c=sampleConfig();
            pooled=qsim.run(c);
            testCase.verifyEqual(pooled.entities.wait,[0;0;1],'AbsTol',1e-12);
            testCase.verifyEqual(pooled.entities.departure,[4;1;2],'AbsTol',1e-12);
            c.network.nodes.queueMode='separateFIFO';
            c.network.nodes.routingPolicy='shortestQueue';
            dedicated=qsim.run(c);
            testCase.verifyEqual(dedicated.entities.wait,[0;0;4],'AbsTol',1e-12);
            testCase.verifyEqual(dedicated.entities.departure,[4;1;5],'AbsTol',1e-12);
            testCase.verifyGreaterThan(dedicated.system.meanWaitStartedCohort, ...
                pooled.system.meanWaitStartedCohort);
        end

        function randomRoutingReproducibleAndValid(testCase)
            c=sampleConfig();
            c.network.nodes.queueMode='separateFIFO';
            c.network.nodes.routingPolicy='random';
            prior=rng;
            a=qsim.run(c);
            b=qsim.run(c);
            testCase.verifyEqual(a.entities.line,b.entities.line);
            testCase.verifyEqual(a.entities.departure,b.entities.departure);
            testCase.verifyTrue(all(a.entities.line>=1 & a.entities.line<=2));
            after=rng;
            testCase.verifyEqual(after.State,prior.State);
        end

        function expectedWaitRespectsSpeedNotFutureWork(testCase)
            c=sampleConfig();
            c.network.nodes.queueMode='separateFIFO';
            c.network.nodes.serverSpeedMultipliers=[1,3];
            c.network.nodes.serviceDistribution.values=[6;6;6];
            c.network.nodes.routingPolicy='shortestQueue';
            s=qsim.run(c);
            c.network.nodes.routingPolicy='shortestExpectedWait';
            c.network.nodes.routingServiceMean=6;
            f=qsim.run(c);
            testCase.verifyEqual(s.entities.line,[1;2;1]);
            testCase.verifyEqual(f.entities.line,[1;2;2]);
            testCase.verifyEqual(s.entities.wait(3),6,'AbsTol',1e-12);
            testCase.verifyEqual(f.entities.wait(3),2,'AbsTol',1e-12);
        end

        function finiteSystemCapacityRejects(testCase)
            c=sampleConfig();
            c.network.nodes.nServers=1;
            c.network.nodes.serverSpeedMultipliers=1;
            c.network.nodes.maxSystemOccupancy=2;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.arrived,3);
            testCase.verifyEqual(r.system.accepted,2);
            testCase.verifyEqual(r.system.rejected,1);
            testCase.verifyEqual(r.system.rejectedSystemCapacity,1);
            testCase.verifyEqual(r.system.completed,2);
            testCase.verifyEqual(r.system.backlog,0);
            testCase.verifyFalse(r.entities.accepted(3));
            testCase.verifyTrue(isnan(r.entities.wait(3)));
            testCase.verifyEqual(r.entities.rejectionReason{3},'systemCapacity');
        end

        function noWaitingRejectsWhenBusy(testCase)
            c=sampleConfig();
            c.network.nodes.nServers=1;
            c.network.nodes.serverSpeedMultipliers=1;
            c.network.nodes.maxWaiting=0;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.accepted,1);
            testCase.verifyEqual(r.system.rejectedWaitingCapacity,2);
            testCase.verifyEqual(r.system.maxQueue,0);
        end

        function totalWaitingCapacityWithDedicatedLines(testCase)
            c=sampleConfig();
            c.network.nodes.queueMode='separateFIFO';
            c.network.nodes.routingPolicy='shortestQueue';
            c.network.nodes.maxWaiting=0;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.accepted,2);
            testCase.verifyEqual(r.system.rejected,1);
            testCase.verifyEqual(r.system.rejectedWaitingCapacity,1);
        end

        function eventTieCompletionBeforeArrival(testCase)
            c=sampleConfig();
            c.network.nodes.nServers=1;
            c.network.nodes.serverSpeedMultipliers=1;
            c.source.times=[1;3];
            c.simulation.arrivalHorizon=3; % Both scheduled arrivals must be in scope.
            c.network.nodes.serviceDistribution.values=[2;1];
            c.network.nodes.maxSystemOccupancy=1;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.rejected,0);
            testCase.verifyEqual(r.system.completed,2);
            testCase.verifyEqual(r.entities.wait,[0;0]);
        end

        function rejectScheduledArrivalBeyondHorizon(testCase)
            % Invalid user configurations must still be rejected; the tie
            % regression fixture above must not weaken source validation.
            c=sampleConfig();
            c.source.times=[1;3];
            c.simulation.arrivalHorizon=2;
            testCase.verifyError(@()qsim.run(c),'qsim:InvalidConfig');
        end

        function scheduledArrivalExactlyAtHorizonIsAllowed(testCase)
            c=sampleConfig();
            c.source.times=[1;3];
            c.simulation.arrivalHorizon=3;
            c.network.nodes.serviceDistribution.values=[1;1];
            r=qsim.run(c);
            testCase.verifyEqual(r.system.arrived,2);
            testCase.verifyEqual(r.system.completed,2);
        end

        function finiteCapacityTruncationConserves(testCase)
            c=sampleConfig();
            c.simulation.stopMode='truncate';
            c.simulation.arrivalHorizon=0.5;
            c.simulation.observationHorizon=0.5;
            c.network.nodes.nServers=1;
            c.network.nodes.serverSpeedMultipliers=1;
            c.network.nodes.maxSystemOccupancy=2;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.arrived, ...
                r.system.completed+r.system.rejected+r.system.backlog);
            testCase.verifyEqual(r.system.backlog,2);
            testCase.verifyEqual(r.system.meanQueueLength,1,'AbsTol',1e-12);
        end

        function emptyArrivalFiniteCap(testCase)
            c=sampleConfig();
            c.source.times=[];
            c.network.nodes.maxSystemOccupancy=1;
            c.network.nodes.maxWaiting=0;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.arrived,0);
            testCase.verifyEqual(r.system.rejected,0);
            testCase.verifyEqual(r.system.meanServerUtilization,0);
        end

        function renewalDeterministicArrivals(testCase)
            c=qsim.defaultConfig();
            c.source.type='renewal';
            c.source.interarrivalDistribution=struct('type','deterministic','value',2);
            c.simulation.arrivalHorizon=6;
            c.simulation.observationHorizon=9;
            c.network.nodes.serviceDistribution.type='deterministic';
            c.network.nodes.serviceDistribution.value=0.5;
            r=qsim.run(c);
            testCase.verifyEqual(r.entities.arrivals,[2;4;6],'AbsTol',1e-12);
            testCase.verifyEqual(r.system.completed,3);
        end

        function serviceUniformAndLognormalReproducible(testCase)
            c=sampleConfig();
            c.network.nodes.serviceDistribution=struct('type','uniform','min',1,'max',3);
            a=qsim.run(c);
            b=qsim.run(c);
            testCase.verifyEqual(a.entities.serviceRequirements,b.entities.serviceRequirements);
            testCase.verifyTrue(all(a.entities.serviceRequirements>=1 & a.entities.serviceRequirements<=3));
            c.network.nodes.serviceDistribution=struct('type','lognormal','muLog',0,'sigmaLog',0);
            d=qsim.run(c);
            testCase.verifyEqual(d.entities.serviceRequirements,ones(3,1),'AbsTol',1e-12);
        end

        function requireExplicitMeanForSequenceSmartPolicy(testCase)
            c=sampleConfig();
            c.network.nodes.queueMode='separateFIFO';
            c.network.nodes.routingPolicy='shortestExpectedWait';
            testCase.verifyError(@()qsim.run(c),'qsim:InvalidConfig');
            c.network.nodes.routingServiceMean=2;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.completed,3);
        end

        function dedicatedMayQueueWhileOtherServerIdle(testCase)
            % Exposes a legitimate independent-line effect rather than
            % silently redirecting to an idle server after assignment.
            c=sampleConfig();
            c.network.nodes.queueMode='separateFIFO';
            c.network.nodes.routingPolicy='random';
            c.network.nodes.nServers=2;
            % A seed-independent explicit router fixture is tested via policy
            % function: server 1 busy while server 2 is free.
            s=qsim.core.selectServer('shortestQueue',[1 0],[0 0],[1 1],2);
            testCase.verifyEqual(s,2);
            r=qsim.run(c);
            testCase.verifyEqual(r.system.arrived,3);
            testCase.verifyEqual(sum(r.system.acceptedByLine),3);
        end

        function metricsSumAcrossLinesAndServers(testCase)
            c=sampleConfig();
            c.network.nodes.queueMode='separateFIFO';
            c.network.nodes.routingPolicy='shortestQueue';
            r=qsim.run(c);
            testCase.verifyEqual(sum(r.system.meanQueueLengthByLine), ...
                r.system.meanQueueLength,'AbsTol',1e-12);
            testCase.verifyEqual(sum(r.system.completedByServer),r.system.completed);
            testCase.verifyEqual(mean(r.system.perServerUtilization), ...
                r.system.meanServerUtilization,'AbsTol',1e-12);
        end

        function rejectUnsupportedTopology(testCase)
            c=sampleConfig();
            c.extensions.network=true;
            testCase.verifyError(@()qsim.run(c),'qsim:UnsupportedExtension');
        end

        function validateInvalidInputs(testCase)
            c=sampleConfig();
            c.network.nodes.maxWaiting=-1;
            testCase.verifyError(@()qsim.run(c),'qsim:InvalidConfig');
            c=sampleConfig();
            c.network.nodes.queueMode='separateFIFO';
            c.network.nodes.routingPolicy='not-a-policy';
            testCase.verifyError(@()qsim.run(c),'qsim:InvalidConfig');
        end
    end
end

function c=sampleConfig()
c=qsim.defaultConfig();
c.simulation.arrivalHorizon=0.5;
c.simulation.observationHorizon=10;
c.source.type='schedule';
c.source.times=[0;0;0];
c.network.nodes.nServers=2;
c.network.nodes.serverSpeedMultipliers=[1,1];
c.network.nodes.serviceDistribution.type='sequence';
c.network.nodes.serviceDistribution.values=[4;1;1];
end
