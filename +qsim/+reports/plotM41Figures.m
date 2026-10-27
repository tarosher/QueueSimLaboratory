function plotM41Figures(folder,bConfig,bDiag,staffing,loads,cRuns)
%PLOTM41FIGURES Three decision-relevant M4.1 figures, no decorative charts.
figdir=fullfile(folder,'figures');
if ~exist(figdir,'dir'), mkdir(figdir); end
% B: paired staffing improvements. An unpaired CI is not a CI for a gain.
fig=figure('Visible','off','Color','w','Position',[90 90 980 490]);
x=1:height(staffing);
errorbar(x,staffing.pairedGainMin, ...
    staffing.pairedGainMin-staffing.gainCI_Lower, ...
    staffing.gainCI_Upper-staffing.pairedGainMin, ...
    'o','LineWidth',1.6,'MarkerSize',8);
hold on; plot([0.6,height(staffing)+.4],[0 0],'k--','LineWidth',1);
xticks(x); xticklabels(staffing.scenario); xlim([.65,height(staffing)+.35]);
ylabel('Reduction in mean journey vs baseline (min)');
title('Benchmark B | paired resource-allocation benefit (95% CI)');
grid on; hold off;
exportgraphics(fig,fullfile(figdir,'B_paired_staffing_gain.png'),'Resolution',170);
close(fig);
% B: physical network with offered load and observed node wait.
ids={bConfig.network.nodes.id}; V=numel(ids);
xy=nan(V,2);
for v=1:V
    switch ids{v}
        case 'A', xy(v,:)=[0 0];
        case 'B1', xy(v,:)=[1 0.8];
        case 'B2', xy(v,:)=[1 -0.8];
        case 'C', xy(v,:)=[2 0];
        otherwise, xy(v,:)=[v-1 0];
    end
end
fig=figure('Visible','off','Color','w','Position',[80 80 1040 480]);
hold on; axis equal; axis off;
for e=1:numel(bConfig.network.links)
    lk=bConfig.network.links(e);
    i=find(strcmp(ids,lk.from),1); j=find(strcmp(ids,lk.to),1);
    p1=xy(i,:); p2=xy(j,:);
    dp=p2-p1; s=p1+.18*dp; d=.65*dp;
    quiver(s(1),s(2),d(1),d(2),0,'Color',[.4 .4 .4], ...
        'LineWidth',1.4,'MaxHeadSize',.17);
    center=p1+.5*dp;
    text(center(1),center(2)+.10,sprintf('p=%.2f',lk.probability), ...
        'FontSize',10,'HorizontalAlignment','center', ...
        'BackgroundColor','w');
end
for v=1:V
    ix=strcmp(bDiag.nodes.scenario,'Baseline') & ...
        strcmp(bDiag.nodes.node,ids{v});
    load=bDiag.nodes.offeredLoad(ix);
    wait=bDiag.nodes.meanNodeWaitMin(ix);
    if load>=1, shade=[1 .84 .80]; else, shade=[.84 .92 1]; end
    rectangle('Position',[xy(v,1)-.18,xy(v,2)-.24,.36,.48], ...
        'Curvature',.15,'FaceColor',shade,'EdgeColor',[.2 .3 .4], ...
        'LineWidth',1.2);
    text(xy(v,1),xy(v,2),sprintf('%s\nload %.2f\nWq %.2f min',ids{v},load,wait), ...
        'FontSize',10,'HorizontalAlignment','center', ...
        'VerticalAlignment','middle');
end
xlim([-.42 2.42]); ylim([-1.32 1.32]);
title('Benchmark B | expected node load and simulated baseline queue wait');
text(1,-1.17,'Arrows: routing probabilities; load = expected arrival rate / nominal service capacity', ...
    'HorizontalAlignment','center','FontSize',9);
hold off;
exportgraphics(fig,fullfile(figdir,'B_network_diagnostics.png'),'Resolution',170);
close(fig);
% C: original end-to-end performance relationship, reproducible from results.
patterns=cRuns{1}.scenarioNames;
fig=figure('Visible','off','Color','w','Position',[90 90 900 520]);
hold on;
for j=1:numel(patterns)
    mu=zeros(numel(loads),1); lo=mu; hi=mu;
    for i=1:numel(loads)
        ci=cRuns{i}.summary(j).metrics.meanEndToEndSojourn;
        mu(i)=ci.mean; lo(i)=ci.lower; hi(i)=ci.upper;
    end
    errorbar(loads,mu,mu-lo,hi-mu,'o-','LineWidth',1.6);
end
xlabel('External arrival rate (entities/min)');
ylabel('Mean end-to-end sojourn (minutes)');
title('Benchmark C | routing / topology and external demand (95% CI)');
legend({'Serial','Parallel balanced','Parallel skewed'},'Location','northwest');
grid on; hold off;
exportgraphics(fig,fullfile(figdir,'C_demand_response.png'),'Resolution',170);
close(fig);
end
