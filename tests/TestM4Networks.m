classdef TestM4Networks < matlab.unittest.TestCase
    %TESTM4NETWORKS DAG routes, deterministic timing, capacities, reporting.
    methods (Test)
        function deterministicTandemVisits(testCase)
            c=fixture();
            c.source.times=[0;0];
            c.network.nodes(1).serviceDistribution.value=2;
            c.network.nodes(2).serviceDistribution.value=3;
            c.simulation.observationHorizon=10;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.completed,2);
            testCase.verifyEqual(r.system.totalVisits,4);
            testCase.verifyEqual(r.entities.departure,[5;8],'AbsTol',1e-12);
            testCase.verifyEqual(r.system.meanEndToEndSojournCompletedCohort,6.5, ...
                'AbsTol',1e-12);
            testCase.verifyEqual(r.nodes(2).meanQueueLength,1/10,'AbsTol',1e-12);
            testCase.verifyEqual([r.nodes.completed],[2 2]);
            testCase.verifyEqual(numel(r.visits),4);
            testCase.verifyEqual(r.network.linkTraversalCounts,2);
        end

        function transferDelayIsCountedInJourney(testCase)
            c=fixture(); c.source.times=0;
            c.network.links.delay=3;
            r=qsim.run(c);
            testCase.verifyEqual(r.entities.departure,5,'AbsTol',1e-12);
            testCase.verifyEqual(r.system.meanEndToEndSojournCompletedCohort,5, ...
                'AbsTol',1e-12);
            testCase.verifyEqual(r.visits(2).arrival,4,'AbsTol',1e-12);
            testCase.verifyEqual(r.visits(2).fromNode,'A');
        end

        function noDemandNoVisit(testCase)
            c=fixture(); c.source.times=[];
            r=qsim.run(c);
            testCase.verifyEqual(r.system.generated,0);
            testCase.verifyEqual(r.system.completed,0);
            testCase.verifyEmpty(r.visits);
            testCase.verifyEqual([r.nodes.meanServerUtilization],[0 0]);
        end

        function simultaneousCompletionPrecedesTransfer(testCase)
            c=fixture(); c.source.times=[0;1];
            r=qsim.run(c);
            testCase.verifyEqual(r.entities.departure,[2;3],'AbsTol',1e-12);
            testCase.verifyEqual([r.visits.wait],[0 0 0 0],'AbsTol',1e-12);
        end

        function branchMergeConservesFlow(testCase)
            c=qsim.network.benchmarkBConfig();
            c.simulation.arrivalHorizon=12;
            c.simulation.observationHorizon=12;
            c.source.type='schedule';
            c.source.times=(0:.5:10)';
            r=qsim.run(c);
            N=numel(c.source.times);
            testCase.verifyEqual(r.system.completed,N);
            testCase.verifyEqual(r.system.rejected,0);
            testCase.verifyEqual([r.nodes(1).arrived,r.nodes(4).arrived],[N N]);
            testCase.verifyEqual(r.nodes(2).arrived+r.nodes(3).arrived,N);
            testCase.verifyEqual(sum(r.network.linkTraversalCounts),2*N);
            testCase.verifyEqual(r.network.sinkExitsByNode,[0 0 0 N]);
            testCase.verifyEqual(sum([r.nodes.completed]),3*N);
        end

        function downstreamLossCountsOnce(testCase)
            c=fixture(); c.source.times=[0;0;0];
            c.network.nodes(1).nServers=3;
            c.network.nodes(2).maxSystemOccupancy=1;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.completed,1);
            testCase.verifyEqual(r.system.rejected,2);
            testCase.verifyEqual(r.system.accepted,3);
            testCase.verifyEqual(r.nodes(2).arrived,3);
            testCase.verifyEqual(r.nodes(2).rejected,2);
            testCase.verifyEqual(r.nodes(1).completed,3);
            testCase.verifyEqual(sum(r.entities.rejected),2);
        end

        function dedicatedNodeUsesExistingRoutingPolicy(testCase)
            c=fixture(); c.source.times=[0;0;0;0];
            c.network.nodes(2).nServers=2;
            c.network.nodes(2).queueMode='separateFIFO';
            c.network.nodes(2).routingPolicy='shortestExpectedWait';
            c.network.nodes(2).serviceDistribution.value=2;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.completed,4);
            testCase.verifyEqual(r.nodes(2).queueMode,'separateFIFO');
            testCase.verifyEqual(numel(r.nodes(2).perServerUtilization),2);
        end

        function noEntityRecordsStillProducesNodeMetrics(testCase)
            c=fixture(); c.output.retainEntityRecords=false;
            r=qsim.run(c);
            testCase.verifyEmpty(r.entities);
            testCase.verifyEmpty(r.visits);
            testCase.verifyEqual(r.system.completed,2);
            testCase.verifyEqual([r.nodes.completed],[2 2]);
        end

        function sourceRejectionAndDrain(testCase)
            c=fixture(); c.source.times=[0;0];
            c.network.nodes(1).maxSystemOccupancy=1;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.accepted,1);
            testCase.verifyEqual(r.system.rejected,1);
            testCase.verifyEqual(r.system.completed,1);
        end

        function truncateKeepsNodeBacklog(testCase)
            c=fixture(); c.source.times=0;
            c.simulation.arrivalHorizon=2;
            c.simulation.observationHorizon=2;
            c.network.nodes(2).serviceDistribution.value=9;
            c.simulation.stopMode='truncate';
            r=qsim.run(c);
            testCase.verifyEqual(r.system.completed,0);
            testCase.verifyEqual(r.system.backlog,1);
            testCase.verifyEqual(r.nodes(2).accepted,1);
            testCase.verifyEqual(r.nodes(2).completed,0);
        end

        function probabilityDeficitExitsAtNode(testCase)
            c=fixture(); c.source.times=(0:9)';
            c.network.links.probability=.25;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.completed,10);
            testCase.verifyEqual(r.system.rejected,0);
            testCase.verifyEqual(sum(r.network.sinkExitsByNode),10);
            testCase.verifyEqual(r.nodes(2).arrived, ...
                r.network.linkTraversalCounts);
        end

        function scheduledAndSeededNetworkReproducible(testCase)
            c=fixture(); c.source.type='poisson'; c.source.rate=.9;
            prior=rng;
            x=qsim.run(c); mid=rng; y=qsim.run(c); after=rng;
            testCase.verifyEqual(x.entities.arrivals,y.entities.arrivals);
            testCase.verifyEqual([x.visits.serviceRequirements], ...
                [y.visits.serviceRequirements]);
            testCase.verifyEqual(x.entities.departure,y.entities.departure);
            testCase.verifyEqual(prior.State,mid.State);
            testCase.verifyEqual(prior.State,after.State);
        end

        function invalidGraphsAreRejected(testCase)
            c=fixture(); c.network.links(2)=qsim.network.makeLink('B','A',1);
            testCase.verifyError(@()qsim.run(c),'qsim:InvalidNetwork');
            c=fixture(); c.network.links(2)=qsim.network.makeLink('A','B',.7);
            testCase.verifyError(@()qsim.run(c),'qsim:InvalidNetwork');
            c=fixture(); c.network.links(2)=qsim.network.makeLink('A','C',.1);
            testCase.verifyError(@()qsim.run(c),'qsim:InvalidNetwork');
            c=fixture(); c.network.links.delay=-1;
            testCase.verifyError(@()qsim.run(c),'qsim:InvalidNetwork');
            c=fixture(); c.network.nodes(2).id='A';
            testCase.verifyError(@()qsim.run(c),'qsim:InvalidNetwork');
            c=fixture(); c.extensions.energy=true;
            testCase.verifyError(@()qsim.run(c),'qsim:UnsupportedExtension');
        end

        function networkModeIsExplicitAndOriginalM2Stable(testCase)
            c=fixture(); c.extensions.network=false;
            testCase.verifyError(@()qsim.run(c),'qsim:InvalidConfig');
            c=qsim.defaultConfig(); c.source.type='schedule';
            c.source.times=0;
            c.simulation.arrivalHorizon=3;
            c.simulation.observationHorizon=3;
            r=qsim.run(c);
            testCase.verifyEqual(r.system.completed,1);
            testCase.verifyFalse(isfield(r,'visits'));
        end

        function observationHorizonBeforeArrivalHorizonIsRejected(testCase)
            % Reject inconsistent input in both original and network modes.
            c=fixture();
            c.simulation.observationHorizon=2; % arrivalHorizon remains 10
            testCase.verifyError(@()qsim.run(c),'qsim:InvalidConfig');

            c=qsim.defaultConfig();
            c.simulation.observationHorizon=2; % arrivalHorizon remains 1000
            testCase.verifyError(@()qsim.run(c),'qsim:InvalidConfig');
        end

        function theoreticalRouteFlowBalance(testCase)
            c=qsim.network.benchmarkBConfig();
            f=qsim.network.expectedVisitRates(c);
            testCase.verifyEqual(f.nodeRates,[.63;.4095;.2205;.63], ...
                'AbsTol',1e-10);
            testCase.verifyEqual(f.totalExitRate,.63,'AbsTol',1e-10);
        end

        function benchmarkBuildersAndExperimentComparison(testCase)
            a=qsim.network.benchmarkBConfig();
            qsim.validateConfig(a);
            b=qsim.network.benchmarkCConfig('serial',.5);
            qsim.validateConfig(b);
            c=qsim.network.benchmarkCConfig('parallel-balanced',.5);
            qsim.validateConfig(c);
            d=qsim.network.benchmarkCConfig('parallel-skewed',.5);
            qsim.validateConfig(d);
            a.source.type='schedule'; a.source.times=[0;1;2];
            a.simulation.arrivalHorizon=4; a.simulation.observationHorizon=4;
            configs={a,a}; names={'Base','Copy'};
            r=qsim.network.compareConfigurations(configs,names, ...
                struct('nRep',2,'seedStart',100));
            testCase.verifyTrue(r.arrivalMatched);
            testCase.verifyEqual(r.raw.meanEndToEndSojourn(:,1), ...
                r.raw.meanEndToEndSojourn(:,2));
            testCase.verifySize(r.nodeWait,[2 2 4]);
        end
    end
end

function c=fixture()
c=qsim.defaultConfig();
c.extensions.network=true;
c.simulation.arrivalHorizon=10;
c.simulation.observationHorizon=10;
c.simulation.stopMode='drain';
c.source.type='schedule';
c.source.times=[0;1];
c.source.entryNode='A';
a=qsim.network.nodeConfig('A');
b=qsim.network.nodeConfig('B');
a.serviceDistribution.type='deterministic'; a.serviceDistribution.value=1;
b.serviceDistribution.type='deterministic'; b.serviceDistribution.value=1;
c.network.nodes=[a,b];
c.network.links=qsim.network.makeLink('A','B',1);
end
