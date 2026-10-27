classdef TestM5ReleaseQuality < matlab.unittest.TestCase
    % Small independent smoke checks for release-readiness integration.
    methods (Test)
        function configValidationAndRngPreservation(testCase)
            cfg=qsim.defaultConfig();
            cfg.source.type='schedule';
            cfg.source.times=[0;1;2];
            cfg.simulation.arrivalHorizon=3;
            cfg.simulation.observationHorizon=3;
            rngBefore=rng;
            r=qsim.run(cfg);
            rngAfter=rng;
            testCase.verifyEqual(r.system.arrived,3);
            testCase.verifyEqual(rngAfter.State,rngBefore.State);
        end
        function networkSeedIsDeterministic(testCase)
            cfg=qsim.network.benchmarkBConfig();
            cfg.source.type='schedule';
            cfg.source.times=(0:5)';
            cfg.simulation.arrivalHorizon=6;
            cfg.simulation.observationHorizon=6;
            cfg.simulation.seed=10101;
            r1=qsim.run(cfg);
            r2=qsim.run(cfg);
            testCase.verifyEqual(r1.entities.departure,r2.entities.departure);
            testCase.verifyEqual(r1.network.linkTraversalCounts, ...
                r2.network.linkTraversalCounts);
        end
        function drainedNetworkFlowConservation(testCase)
            cfg=qsim.network.benchmarkBConfig();
            cfg.source.type='schedule';
            cfg.source.times=[0;1;2;3;4];
            cfg.simulation.arrivalHorizon=5;
            cfg.simulation.observationHorizon=5;
            r=qsim.run(cfg);
            audit=qsim.network.auditFlow(cfg,r);
            testCase.verifyEqual(audit.maxAbsResidual,0);
            testCase.verifyEqual(r.system.completed+r.system.rejected,5);
        end
        function exportedDataHasStableRows(testCase)
            cfg=qsim.network.benchmarkBConfig();
            cfg.source.type='schedule';
            cfg.source.times=[0;1;2];
            cfg.simulation.arrivalHorizon=4;
            cfg.simulation.observationHorizon=4;
            r=qsim.run(cfg);
            ids={r.nodes.id}';
            arrivals=[r.nodes.arrived]';
            t=table(ids,arrivals,'VariableNames',{'node','arrived'});
            path=[tempname '.csv'];
            cleaner=onCleanup(@()delete(path)); %#ok<NASGU>
            writetable(t,path);
            back=readtable(path);
            testCase.verifyEqual(height(back),numel(r.nodes));
            testCase.verifyEqual(back.arrived,arrivals);
        end
        function futureExtensionsRemainNonExecutable(testCase)
            names={'resources','traffic','energy'};
            for k=1:numel(names)
                cfg=qsim.defaultConfig();
                cfg.extensions.(names{k})=true;
                testCase.verifyError(@()qsim.run(cfg), ...
                    'qsim:UnsupportedExtension');
            end
        end
    end
end
