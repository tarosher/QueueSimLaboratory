%RUN_RC_ACCEPTANCE Full end-to-end acceptance for the GitHub rc1 snapshot.
% From the repository root: run('tests/run_rc_acceptance.m')
% MATLAB R2022b, base MATLAB. Do not treat this as copyright approval.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'configs'));
import matlab.unittest.TestSuite
suite=TestSuite.fromFolder(fullfile(root,'tests'),'IncludingSubfolders',false);
expectedTests=89; % rc1 excludes the separate, legacy-dependent course test
if numel(suite)~=expectedTests
    error('qsim:ReleaseSuiteMismatch', ...
        'Expected %d rc1 MATLAB tests, found %d.',expectedTests,numel(suite));
end
fprintf('[RC1 1/4] Running %d MATLAB tests...\n',expectedTests);
testResults=run(suite);
passed=sum([testResults.Passed]);
failed=sum([testResults.Failed]);
incomplete=sum([testResults.Incomplete]);
if passed~=expectedTests || failed~=0 || incomplete~=0
    error('qsim:ReleaseTestsFailed', ...
        'Test results: %d passed, %d failed, %d incomplete.', ...
        passed,failed,incomplete);
end

fprintf('[RC1 2/4] Generating and validating integrated Benchmarks A-C...\n');
run(fullfile(root,'examples','run_m41_integrated.m'));
integratedFolder=fullfile(root,'outputs','m41_integrated');
metricsFile=fullfile(integratedFolder,'integrated_metrics.csv');
if exist(metricsFile,'file')~=2
    error('qsim:ReleaseExportFailed','Integrated metrics CSV missing.');
end
metrics=readtable(metricsFile);
requiredBenchmarks=["A","B","C"];
if ~all(ismember(requiredBenchmarks,unique(string(metrics.benchmark)))) || ...
        height(metrics)<19 || ~all(metrics.nValid>0)
    error('qsim:ReleaseExportFailed', ...
        'Integrated results are missing benchmark rows or valid replications.');
end

fprintf('[RC1 3/4] Running non-thresholded performance characterization...\n');
run(fullfile(root,'examples','run_m5_performance.m'));
perfFile=fullfile(root,'outputs','performance','m5_runtime_scaling.csv');
if exist(perfFile,'file')~=2
    error('qsim:ReleaseExportFailed','Performance CSV missing.');
end
perf=readtable(perfFile);
if height(perf)~=6 || ~all(isfinite(perf.medianWallSeconds)) || ...
        any(perf.medianWallSeconds<0)
    error('qsim:ReleaseExportFailed','Performance CSV is incomplete.');
end

fprintf('[RC1 4/4] Writing machine-specific acceptance evidence...\n');
acceptanceFolder=fullfile(root,'outputs','validation');
if ~exist(acceptanceFolder,'dir'), mkdir(acceptanceFolder); end
reportFile=fullfile(acceptanceFolder,'RC_ACCEPTANCE.md');
fid=fopen(reportFile,'w');
if fid<0
    error('qsim:ReleaseExportFailed','Cannot create acceptance report.');
end
cleaner=onCleanup(@()fclose(fid)); %#ok<NASGU>
commit=getenv('GITHUB_SHA');
if isempty(commit), commit='not supplied (local run)'; end
fprintf(fid,'# QueueSimLab v0.2.0-rc1 acceptance evidence\n\n');
fprintf(fid,'- Date: %s\n',datestr(now,31));
fprintf(fid,'- Commit: `%s`\n',commit);
fprintf(fid,'- MATLAB: %s\n',version);
fprintf(fid,'- Platform: %s\n',computer);
fprintf(fid,'- Regression tests: %d passed / %d expected; 0 failed, 0 incomplete\n',passed,expectedTests);
fprintf(fid,'- Benchmarks A, B and C: integrated export verified (%d metric rows)\n',height(metrics));
fprintf(fid,'- Performance: %d workload rows recorded (no speed threshold)\n',height(perf));
fprintf(fid,'- Publication rights and LICENSE: not evaluated by this script\n');
clear cleaner
fprintf('RC1 acceptance completed. Evidence: %s\n',reportFile);
