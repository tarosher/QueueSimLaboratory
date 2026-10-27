function calendar = pushEvent(calendar,t,kind,id,server,seq)
%PUSHEVENT Future-event calendar. kind: 1 completion, 2 arrival.
e = struct('time',t,'kind',kind,'entityId',id,'serverId',server,'sequence',seq);
calendar(end+1) = e;
end
