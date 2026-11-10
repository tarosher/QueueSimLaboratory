function fig = launch()
%LAUNCH Interactive GUI for QueueSimLab single-node experiments.
%   qsim.launch opens a base-MATLAB R2022b-compatible parameter studio.
%   It calls the existing qsim.run engine without altering DES logic.
%   Supports a single scenario or a configurable staffing sweep.
%
%   Limits: Poisson arrivals; exponential/deterministic service;
%   single-node mode only. Full API remains available through qsim.run.

fig = uifigure('Name','QueueSimLab | Simulation Studio', ...
    'Position',[100 100 1100 720]);
root = uigridlayout(fig,[1 2]);
root.ColumnWidth = {365,'1x'};
root.RowHeight = {'1x'};
root.Padding = [12 12 12 12];
root.ColumnSpacing = 12;

panel = uipanel(root,'Title','Simulation parameters');
panel.Layout.Row = 1;
panel.Layout.Column = 1;
left = uigridlayout(panel,[19 2]);
left.ColumnWidth = {155,'1x'};
left.RowHeight = [repmat({30},1,17),{52},{'1x'}];
left.RowSpacing = 6;
left.Padding = [10 10 10 10];

modeField = addDropdown(1,'Experiment', ...
    {'Single scenario','Compare server range'},'Compare server range');
lambdaField = addNumber(2,'Arrival rate (per min)',4.5,0,1000,0.1);
muField = addNumber(3,'Service rate / server',1,0.001,1000,0.1);
lawField = addDropdown(4,'Service distribution', ...
    {'exponential','deterministic'},'exponential');
serversField = addNumber(5,'Servers (single run)',5,1,100,1);
rangeField = addText(6,'Compare servers','5:10');
arrivalsField = addNumber(7,'Arrival horizon (min)',480,0.001,1e7,60);
observeField = addNumber(8,'Observation horizon',480,0.001,1e7,60);
repField = addNumber(9,'Independent runs',10,1,500,1);
seedField = addNumber(10,'First random seed',2026,0,1e8,1);
queueField = addDropdown(11,'Queue organization', ...
    {'separateFIFO','pooledFIFO'},'separateFIFO');
policyField = addDropdown(12,'Queue selection', ...
    {'shortestQueue','random','shortestExpectedWait'},'shortestQueue');
stopField = addDropdown(13,'Stop policy', ...
    {'drain','truncate'},'drain');

addLabel(14,'Max waiting (or Inf)');
maxWaitingField = uieditfield(left,'text','Value','Inf');
place(maxWaitingField,14,2);

catalog = qsim.gui.metricCatalog();
metricField = addDropdown(15,'Chart metric', ...
    {catalog.name},'Avg. wait');
metricField.ValueChangedFcn = @(~,~) renderChart();

buttons = uigridlayout(left,[1 2]);
buttons.Layout.Row = 16; buttons.Layout.Column = [1 2];
buttons.ColumnWidth = {'1x','1x'};
buttons.Padding = [0 0 0 0]; buttons.ColumnSpacing = 6;
runButton = uibutton(buttons,'push','Text','Run simulation', ...
    'ButtonPushedFcn',@runExperiment);
resetButton = uibutton(buttons,'push','Text','Reset defaults', ...
    'ButtonPushedFcn',@resetDefaults);

presetBtns = uigridlayout(left,[1 2]);
presetBtns.Layout.Row = 17; presetBtns.Layout.Column = [1 2];
presetBtns.ColumnWidth = {'1x','1x'};
presetBtns.Padding = [0 0 0 0]; presetBtns.ColumnSpacing = 6;
uibutton(presetBtns,'push','Text','Save preset', ...
    'ButtonPushedFcn',@savePreset);
uibutton(presetBtns,'push','Text','Load preset', ...
    'ButtonPushedFcn',@loadPreset);

exportButton = uibutton(left,'push', ...
    'Text','Export current results (CSV / MAT / PNG)', ...
    'ButtonPushedFcn',@exportResult,'Enable','off');
exportButton.Layout.Row = 18; exportButton.Layout.Column = [1 2];

leftNote = uilabel(left,'Text', ...
    ['Uses the original qsim.run engine. No fixed 180-minute limit. ' ...
    'The horizon sets when arrivals stop; drain may finish later.'], ...
    'WordWrap','on','FontSize',11);
leftNote.Layout.Row = 19; leftNote.Layout.Column = [1 2];

right = uigridlayout(root,[4 1]);
right.Layout.Row = 1; right.Layout.Column = 2;
right.RowHeight = {'3x',52,'2x',96};
right.RowSpacing = 10;
right.Padding = [0 0 0 0];
ax = uiaxes(right);
ax.Layout.Row = 1;
title(ax,'Run a scenario to see results');
xlabel(ax,'Number of servers');
ylabel(ax,'Mean wait (min)');
grid(ax,'on');

resultTable = uitable(right,'Data',table(), ...
    'ColumnSortable',true);
resultTable.Layout.Row = 3;
metricInfo = uilabel(right,'Text','', 'WordWrap','on','FontSize',12);
metricInfo.Layout.Row = 2;

statusArea = uitextarea(right,'Editable','off', ...
    'Value',{'Ready. Set parameters and click Run simulation.'});
statusArea.Layout.Row = 4;

lastTable = table();
lastRaw = [];
lastPreset = struct();

modeField.ValueChangedFcn = @(~,~) refreshMode();
queueField.ValueChangedFcn = @(~,~) refreshMode();
refreshMode();

    function addLabel(row,titleText)
        label = uilabel(left,'Text',titleText,'FontSize',12);
        place(label,row,1);
    end

    function h = addDropdown(row,titleText,items,initial)
        addLabel(row,titleText);
        h = uidropdown(left,'Items',items,'Value',initial);
        place(h,row,2);
    end

    function h = addNumber(row,titleText,value,lower,upper,step)
        addLabel(row,titleText);
        h = uispinner(left,'Value',value,'Limits',[lower upper], ...
            'Step',step);
        place(h,row,2);
    end

    function h = addText(row,titleText,value)
        addLabel(row,titleText);
        h = uieditfield(left,'text','Value',value);
        place(h,row,2);
    end

    function place(h,r,c)
        h.Layout.Row = r;
        h.Layout.Column = c;
    end

    function refreshMode()
        if strcmp(modeField.Value,'Single scenario')
            serversField.Enable = 'on';
            rangeField.Enable = 'off';
        else
            serversField.Enable = 'off';
            rangeField.Enable = 'on';
        end
        if strcmp(queueField.Value,'pooledFIFO')
            policyField.Enable = 'off';
        else
            policyField.Enable = 'on';
        end
    end

    function P = readPreset()
        P = struct('mode',modeField.Value, ...
            'lambda',lambdaField.Value,'mu',muField.Value, ...
            'serviceLaw',lawField.Value,'servers',serversField.Value, ...
            'serverRange',rangeField.Value, ...
            'arrivalHorizon',arrivalsField.Value, ...
            'observationHorizon',observeField.Value, ...
            'nRep',repField.Value,'seed',seedField.Value, ...
            'queueMode',queueField.Value, ...
            'routingPolicy',policyField.Value, ...
            'stopMode',stopField.Value, ...
            'maxWaiting',str2double(maxWaitingField.Value));
        if P.observationHorizon < P.arrivalHorizon
            error('qsim:GUIInvalidInput', ...
                'Observation horizon must be >= arrival horizon.');
        end
        if isnan(P.maxWaiting) || P.maxWaiting<0 || ...
                (isfinite(P.maxWaiting) && P.maxWaiting~=floor(P.maxWaiting))
            error('qsim:GUIInvalidInput', ...
                'Max waiting must be Inf or a nonnegative integer.');
        end
        if P.nRep~=floor(P.nRep) || P.servers~=floor(P.servers) || ...
                P.seed~=floor(P.seed) || ...
                P.seed+P.nRep-1>2^32-1
            error('qsim:GUIInvalidInput','Invalid integer or seed range.');
        end
    end

    function cfg = makeConfig(P,nServers,seed)
        cfg = qsim.defaultConfig();
        cfg.simulation.arrivalHorizon = P.arrivalHorizon;
        cfg.simulation.observationHorizon = P.observationHorizon;
        cfg.simulation.stopMode = P.stopMode;
        cfg.simulation.seed = seed;
        cfg.source.type = 'poisson';
        cfg.source.rate = P.lambda;
        cfg.network.nodes.nServers = nServers;
        cfg.network.nodes.queueMode = P.queueMode;
        cfg.network.nodes.routingPolicy = P.routingPolicy;
        cfg.network.nodes.maxWaiting = P.maxWaiting;
        cfg.network.nodes.serviceDistribution.type = P.serviceLaw;
        cfg.network.nodes.serviceDistribution.rate = P.mu;
        if strcmp(P.serviceLaw,'deterministic')
            cfg.network.nodes.serviceDistribution.value = 1/P.mu;
        end
        qsim.validateConfig(cfg);
    end

    function runExperiment(~,~)
        runButton.Enable = 'off';
        buttonGuard = onCleanup(@()restoreButton()); %#ok<NASGU>
        dlg = [];
        try
            P = readPreset();
            if strcmp(P.mode,'Single scenario')
                counts = P.servers;
            else
                counts = qsim.gui.parseServerRange(P.serverRange);
            end
            nS = numel(counts);
            raw = nan(P.nRep,nS,numel(catalog));
            dlg = uiprogressdlg(fig,'Title','QueueSimLab running', ...
                'Message','Initializing...','Cancelable','on');
            for j = 1:nS
                for k = 1:P.nRep
                    if dlg.CancelRequested
                        statusArea.Value = {'Experiment cancelled; previous results retained.'};
                        close(dlg);
                        return
                    end
                    dlg.Value = ((j-1)*P.nRep+k-1)/(nS*P.nRep);
                    dlg.Message = sprintf('Servers: %d; replicate: %d / %d', ...
                        counts(j),k,P.nRep);
                    drawnow limitrate
                    cfg = makeConfig(P,counts(j),P.seed+k-1);
                    r = qsim.run(cfg);
                    raw(k,j,:) = reshape(qsim.gui.singleNodeMetrics( ...
                        r,P.observationHorizon,5),1,1,[]);
                end
            end
            close(dlg); dlg = [];
            summaryData = nan(nS,numel(catalog));
            waitLower95 = nan(nS,1);
            waitUpper95 = nan(nS,1);
            for j = 1:nS
                for m = 1:numel(catalog)
                    ci = qsim.stats.meanCI(raw(:,j,m),0.95);
                    summaryData(j,m) = ci.mean;
                    if m==1
                        waitLower95(j) = ci.lower;
                        waitUpper95(j) = ci.upper;
                    end
                end
            end
            metricNames = {catalog.field};
            lastTable = array2table(summaryData,'VariableNames',metricNames);
            lastTable = addvars(lastTable,counts(:), ...
                'Before',1,'NewVariableNames','Servers');
            lastTable.WaitLower95 = waitLower95;
            lastTable.WaitUpper95 = waitUpper95;
            lastRaw = raw;
            lastPreset = P;
            resultTable.Data = lastTable;
            exportButton.Enable = 'on';
            renderChart();
            statusArea.Value = {sprintf('%d configurations x %d independent runs completed.',nS,P.nRep), ...
                'All scenarios use matching arrival/service seeds within each replication.', ...
                sprintf('Arrivals end at %.2f min; observation ends at %.2f min.', ...
                    P.arrivalHorizon,P.observationHorizon), ...
                '95% intervals are across independent replications, not customers.'};
        catch ME
            if ~isempty(dlg) && isvalid(dlg)
                close(dlg);
            end
            uialert(fig,ME.message,'QueueSimLab simulation error');
            statusArea.Value = {['Error: ' ME.message]};
        end
    end

    function restoreButton()
        if isvalid(runButton)
            runButton.Enable = 'on';
        end
    end

    function renderChart()
        if isempty(lastTable) || height(lastTable)==0, return; end
        idx = find(strcmp({catalog.name},metricField.Value),1);
        if isempty(idx), return; end
        x = lastTable.Servers;
        y = lastTable.(catalog(idx).field);
        if idx==1 && lastPreset.nRep>=2
            neg = y-lastTable.WaitLower95;
            pos = lastTable.WaitUpper95-y;
            errorbar(ax,x,y,neg,pos,'-o','LineWidth',1.6,'MarkerSize',7);
        else
            plot(ax,x,y,'-o','LineWidth',1.6,'MarkerSize',7);
        end
        title(ax,['QueueSimLab: ' catalog(idx).name]);
        ylabel(ax,[catalog(idx).name ' (' catalog(idx).unit ')']);
        xlabel(ax,'Number of servers');
        xticks(ax,x');
        grid(ax,'on');
        metricInfo.Text = catalog(idx).help;
    end

    function savePreset(~,~)
        try
            Preset = readPreset(); %#ok<NASGU>
            [name,folder] = uiputfile('*.mat','Save QueueSimLab preset','qsim_preset.mat');
            if isequal(name,0), return; end
            save(fullfile(folder,name),'Preset');
            statusArea.Value = {['Saved parameter preset: ' fullfile(folder,name)]};
        catch ME
            uialert(fig,ME.message,'Save preset failed');
        end
    end

    function loadPreset(~,~)
        [name,folder] = uigetfile('*.mat','Load QueueSimLab preset');
        if isequal(name,0), return; end
        try
            S = load(fullfile(folder,name),'Preset');
            if ~isfield(S,'Preset') || ~isstruct(S.Preset)
                error('qsim:GUIInvalidPreset','File contains no QueueSimLab Preset struct.');
            end
            P = S.Preset;
            modeField.Value = P.mode;
            lambdaField.Value = P.lambda;
            muField.Value = P.mu;
            lawField.Value = P.serviceLaw;
            serversField.Value = P.servers;
            if isfield(P,'serverRange')
                rangeField.Value = P.serverRange;
            end
            arrivalsField.Value = P.arrivalHorizon;
            observeField.Value = P.observationHorizon;
            repField.Value = P.nRep;
            seedField.Value = P.seed;
            queueField.Value = P.queueMode;
            policyField.Value = P.routingPolicy;
            stopField.Value = P.stopMode;
            maxWaitingField.Value = num2str(P.maxWaiting);
            refreshMode();
            statusArea.Value = {['Loaded preset: ' fullfile(folder,name)]};
        catch ME
            uialert(fig,ME.message,'Load preset failed');
        end
    end

    function exportResult(~,~)
        if isempty(lastTable) || height(lastTable)==0, return; end
        folder = uigetdir(pwd,'Select folder to export results');
        if isequal(folder,0), return; end
        try
            writetable(lastTable,fullfile(folder,'qsim_staffing_summary.csv'));
            Results = lastTable; %#ok<NASGU>
            Replications = lastRaw; %#ok<NASGU>
            Preset = lastPreset; %#ok<NASGU>
            save(fullfile(folder,'qsim_experiment.mat'), ...
                'Results','Replications','Preset');
            exportgraphics(ax,fullfile(folder,'qsim_staffing_chart.png'), ...
                'Resolution',180);
            statusArea.Value = {['Export complete: ' folder], ...
                'CSV summary / MAT raw replications and preset / PNG chart'};
        catch ME
            uialert(fig,ME.message,'Export failed');
        end
    end

    function resetDefaults(~,~)
        modeField.Value = 'Compare server range';
        lambdaField.Value = 4.5;
        muField.Value = 1;
        lawField.Value = 'exponential';
        serversField.Value = 5;
        rangeField.Value = '5:10';
        arrivalsField.Value = 480;
        observeField.Value = 480;
        repField.Value = 10;
        seedField.Value = 2026;
        queueField.Value = 'separateFIFO';
        policyField.Value = 'shortestQueue';
        stopField.Value = 'drain';
        maxWaitingField.Value = 'Inf';
        metricField.Value = 'Avg. wait';
        refreshMode();
        statusArea.Value = {'Default parameters restored. Run to update results.'};
    end
end
