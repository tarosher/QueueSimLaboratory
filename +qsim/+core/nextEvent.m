function [event,calendar] = nextEvent(calendar,~)
%NEXTEVENT Event calendar: chronological first, then completion before arrival.
% Only EXACT timestamp ties are reordered. Tolerance must never bring a later
% completion before an earlier arrival and make the simulation clock regress.
t=[calendar.time];
tmin=min(t);
candidates=find(t==tmin);
priority=[calendar(candidates).kind]; % 1=completion, 2=arrival
best=candidates(priority==min(priority));
[~,j]=min([calendar(best).sequence]);
idx=best(j);
event=calendar(idx);
calendar(idx)=[];
end
