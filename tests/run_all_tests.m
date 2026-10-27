%RUN_ALL_TESTS Call from the repository root with MATLAB test framework.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'configs')); % legacy course sources not distributed
import matlab.unittest.TestSuite
suite=TestSuite.fromFolder(fullfile(root,'tests'),'IncludingSubfolders',false);
results=run(suite);
assert(all([results.Passed]),'At least one QueueSimLab regression test failed.');
disp(results);
