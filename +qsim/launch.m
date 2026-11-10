function fig = launch()
%LAUNCH Interactive GUI for QueueSimLab single-node experiments.
%   qsim.launch opens a base-MATLAB R2022b-compatible parameter studio.
%   It calls the existing qsim.run engine without altering DES logic.
%   Supports one staffing scenario or a 5:10 staffing sweep.
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
left = uigridlayout(panel,[18 2]);
left.ColumnWidth = {155,'1x'};
left.RowHeight = [repmat({30},1,16),{52},{'1x'}];
left.RowSpacing = 6;
left.Padding = [10 10 10 10];

modeField = addDropdown(1,'Experiment', ...
    {'Single scenario','Compare 5-10 servers'},'Compare 5-10 servers');
lambdaField = addNumber(2,'Arrival rate (per min)',4.5,0,1000,0.1);
muField = addNumber(3,'Service rate / server',1,0.001,1000,0.1);
lawField = addDropdown(4,'Service distribution', ...
    {'exponential','deterministic'},'exponential');
serversField = addNumber(5,'Servers (single run)',5,1,100,1);
arrivalsField = addNumber(6,'Arrival horizon (min)',480,0.001,1e7,60);
observeField = addNumber(7,'Observation horizon',480,0.001,1e7,60);
repField = addNumber(8,'Independent runs',10,1,500,1);
seedField = addNumber(9,'First random seed',2026,0,1e8,1);
queueField = addDropdown(10,'Queue organization', ...
    {'separateFIFO','pooledFIFO'},'separateFIFO');
policyField = addDropdown(11,'Queue selection', ...
    {'shortestQueue','random','shortestExpectedWait'},'shortestQueue');
stopField = addDropdown(12,'Stop policy', ...
    {'drain','truncate'},'drain');

addLabel(13,'Max waiting (or Inf)');
maxWaitingField = uieditfield(left,'text','Value','Inf');
place(maxWaitingField,13,2);

metricField = addDropdown(14,'Chart metric', ...
    {'Mean wait','Mean sojourn','Mean queue length', ...
     'Mean utilization','Max wait'},'Mean wait');
metricField.ValueChangedFcn = @(~,~) renderChart();

buttons = uigridlayout(left,[1 2]);
buttons.Layout.Row = 15; buttons.Layout.Column = [1 2];
buttons.ColumnWidth = {'1x','1x'};
buttons.Padding = [0 0 0 0]; buttons.ColumnSpacing = 6;
runButton = uibutton(buttons,'push','Text','Run simulation', ...
    'ButtonPushedFcn',@runExperiment);
resetButton = uibutton(buttons,'push','Text','Reset defaults', ...
    'ButtonPushedFcn',@resetDefaults);

presetBtns = uigridlayout(left,[1 2]);
presetBtns.Layout.Row = 16; presetBtns.Layout.Column = [1 2];
presetBtns.ColumnWidth = {'1x','1x'};
presetBtns.Padding = [0 0 0 0]; presetBtns.ColumnSpacing = 6;
uibutton(presetBtns,'push','Text','Save preset', ...
    'ButtonPushedFcn',@savePreset);
uibutton(presetBtns,'push','Text','Load preset', ...
    'ButtonPushedFcn',@loadPreset);

exportButton = uibutton(left,'push', ...
    'Text','Export current results (CSV / MAT / PNG)', ...
    'ButtonPushedFcn',@exportResult,'Enable','off');
exportButton.Layout.Row = 17; exportButton.Layout.Column = [1 2];

leftNote = uilabel(left,'Text', ...
    'Uses the original qsim.run engine. No fixed 180-minute limit. ' + ...
    "The horizon sets when arrivals stop; drain may finish later.", ...
    'WordWrap','on','FontSize',11);
leftNote.Layout.Row = 18; leftNote.Layout.Column = [1 2];

right = uigridlayout(root,[3 1]);
right.Layout.Row = 1; right.Layout.Column = 2;
right.RowHeight = {'3x','2x',96};
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
resultTable.Layout.Row = 2;

statusArea = uitextarea(right,'Editable','off', ...
    'Value',{'Ready. Set parameters and click Run simulation.'});
statusArea.Layout.Row = 3;

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

    function place(h,r,c)
        h.Layout.Row = r;
        h.Layout.Column = c;
    end

    function refreshMode()
        if strcmp(modeField.Value,'Single scenario')
            serversField.Enable = 'on';
        else
            serversField.Enable = 'off';
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
                counts = 5:10;
            end
            nS = numel(counts);
            raw = nan(P.nRep,nS,5);
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
                    raw(k,j,1) = r.system.meanWaitStartedCohort;
                    raw(k,j,2) = r.system.meanSojournCompletedCohort;
                    raw(k,j,3) = r.system.meanQueueLength;
                    raw(k,j,4) = r.system.meanServerUtilization;
                    waits = r.entities.wait(r.entities.accepted & ...
                        isfinite(r.entities.wait));
                    if ~isempty(waits)
                        raw(k,j,5) = max(waits);
                    end
                end
            end
            close(dlg); dlg = [];
            nS = numel(counts);
            MeanWaitMin = nan(nS,1);
            WaitLower95 = nan(nS,1);
            WaitUpper95 = nan(nS,1);
            MeanSojournMin = nan(nS,1);
            MeanQueueLength = nan(nS,1);
            MeanUtilization = nan(nS,1);
            MaxWaitMin = nan(nS,1);
            for j = 1:nS
                ci = qsim.stats.meanCI(raw(:,j,1),0.95);
                MeanWaitMin(j) = ci.mean;
                WaitLower95(j) = ci.lower;
                WaitUpper95(j) = ci.upper;
                v = qsim.stats.meanCI(raw(:,j,2),0.95);
                MeanSojournMin(j) = v.mean;
                v = qsim.stats.meanCI(raw(:,j,3),0.95);
                MeanQueueLength(j) = v.mean;
                v = qsim.stats.meanCI(raw(:,j,4),0.95);
                MeanUtilization(j) = v.mean;
                v = qsim.stats.meanCI(raw(:,j,5),0.95);
                MaxWaitMin(j) = v.mean;
            end
            Servers = counts(:);
            lastTable = table(Servers,MeanWaitMin,WaitLower95,WaitUpper95, ...
                MeanSojournMin,MeanQueueLength,MeanUtilization,MaxWaitMin);
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
        if isempty(lastTable) || height(lastTable)==0
            return
        end
        switch metricField.Value
            case 'Mean wait'
                y = lastTable.MeanWaitMin;
                if lastPreset.nRep>=2
                    neg = y-lastTable.WaitLower95;
                    pos = lastTable.WaitUpper95-y;
                    errorbar(ax,lastTable.Servers,y,neg,pos, ...
                        '-o','LineWidth',1.6,'MarkerSize',7);
                else
                    plot(ax,lastTable.Servers,y,'-o','LineWidth',1.6);
                end
                ylabel(ax,'Mean waiting time (min)');
            case 'Mean sojourn'
                plot(ax,lastTable.Servers,lastTable.MeanSojournMin,'-o','LineWidth',1.6);
                ylabel(ax,'Mean checkout sojourn (min)');
            case 'Mean queue length'
                plot(ax,lastTable.Servers,lastTable.MeanQueueLength,'-o','LineWidth',1.6);
                ylabel(ax,'Time-average total waiting');
            case 'Mean utilization'
                plot(ax,lastTable.Servers,lastTable.MeanUtilization,'-o','LineWidth',1.6);
                ylabel(ax,'Fraction busy per server');
            otherwise
                plot(ax,lastTable.Servers,lastTable.MaxWaitMin,'-o','LineWidth',1.6);
                ylabel(ax,'Mean of replication maximum waits (min)');
        end
        title(ax,['QueueSimLab: ' metricField.Value]);
        xlabel(ax,'Number of servers');
        xticks(ax,lastTable.Servers');
        grid(ax,'on');
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
        modeField.Value = 'Compare 5-10 servers';
        lambdaField.Value = 4.5;
        muField.Value = 1;
        lawField.Value = 'exponential';
        serversField.Value = 5;
        arrivalsField.Value = 480;
        observeField.Value = 480;
        repField.Value = 10;
        seedField.Value = 2026;
        queueField.Value = 'separateFIFO';
        policyField.Value = 'shortestQueue';
        stopField.Value = 'drain';
        maxWaitingField.Value = 'Inf';
        metricField.Value = 'Mean wait';
        refreshMode();
        statusArea.Value = {'Default parameters restored. Run to update results.'};
    end
end
