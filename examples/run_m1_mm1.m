% Run from repository root: addpath('configs'); run('examples/run_m1_mm1.m')
c=mm1_config();
r=qsim.run(c);
theory=qsim.stats.erlangC(c.source.rate,c.network.nodes.serviceDistribution.rate,1);
fprintf('Simulation Wq = %.4f min; theory = %.4f min\n',r.system.meanWaitStartedCohort,theory.Wq);
fprintf('Simulation rho = %.4f; theory = %.4f\n',r.system.meanServerUtilization,theory.rho);
fprintf('Conservation: arrived=%d, completed=%d, backlog=%d\n', ...
    r.system.arrived,r.system.completed,r.system.backlog);
