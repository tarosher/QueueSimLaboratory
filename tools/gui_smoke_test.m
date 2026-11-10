%GUI_SMOKE_TEST Lightweight QueueSimLab Studio validation (MATLAB R2022b+).
% From repository root: run('tools/gui_smoke_test.m')
% This script does not require opening the desktop GUI and does not alter
% the 89-test core acceptance suite.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
fprintf('[GUI 1/3] Checking custom server ranges...\n');
assert(isequal(qsim.gui.parseServerRange('3:12'),3:12));
assert(isequal(qsim.gui.parseServerRange('3:2:13'),3:2:13));
assert(isequal(qsim.gui.parseServerRange('3,5,8,12'),[3 5 8 12]));
badRangeRejected = false;
try
    qsim.gui.parseServerRange('0:3');
catch ME
    badRangeRejected = strcmp(ME.identifier,'qsim:InvalidServerRange');
end
assert(badRangeRejected,'Invalid server range should raise qsim:InvalidServerRange.');

fprintf('[GUI 2/3] Checking metric catalog...\n');
catalog = qsim.gui.metricCatalog();
assert(numel(catalog)==11,'Expected 11 GUI metrics.');
assert(numel(unique({catalog.field}))==numel(catalog), ...
    'Metric export keys must be unique.');
assert(strcmp(catalog(3).name,'Avg. total time (wait + service)'));

fprintf('[GUI 3/3] Checking deterministic 2-server event trace...\n');
cfg = qsim.defaultConfig();
cfg.simulation.arrivalHorizon = 10;
cfg.simulation.observationHorizon = 10;
cfg.source.type = 'schedule';
cfg.source.times = [0;0;0];
cfg.network.nodes.nServers = 2;
cfg.network.nodes.queueMode = 'pooledFIFO';
cfg.network.nodes.serviceDistribution.type = 'sequence';
cfg.network.nodes.serviceDistribution.values = [4;1;1];
r = qsim.run(cfg);
m = qsim.gui.singleNodeMetrics(r,10,5);
assert(r.system.arrived==3 && r.system.completed==3 && r.system.rejected==0);
assert(abs(m(1) - 1/3)<1e-10,'Average wait should be 1/3 minute.');
assert(abs(m(2) - 0.9)<1e-10,'P95 wait should be 0.9 minute (Type 7).');
assert(abs(m(3) - 7/3)<1e-10,'Average total time should be 7/3 minute.');
assert(abs(m(4) - 0.1)<1e-10,'Time-average queue should be 0.1 customer.');
assert(abs(m(5) - 30)<1e-10,'Server busy rate should be 30 percent.');
assert(abs(m(6))<1e-10,'No rejection expected.');
assert(abs(m(7) - 100/3)<1e-10,'One of three customers waits.');
assert(abs(m(8) - 0.3)<1e-10,'Throughput should be 0.3 customers/min.');
assert(m(9)==1 && m(10)==1 && m(11)==100);
fprintf('PASS: GUI helper checks and deterministic DES metrics.\n');
fprintf('Next: run qsim.launch to check desktop layout and buttons manually.\n');
