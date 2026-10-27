function answer = erlangC(lambda,mu,c)
%ERLANGC Stationary M/M/c pooled FIFO, stable lambda<c*mu.
assert(isscalar(lambda) && isfinite(lambda) && lambda>=0,'Invalid lambda.');
assert(isscalar(mu) && isfinite(mu) && mu>0,'Invalid mu.');
assert(isscalar(c) && isfinite(c) && c>=1 && c==floor(c),'Invalid c.');
a=lambda/mu; rho=a/c;
assert(rho<1,'Erlang-C requires rho<1.');
term=1; partial=1;
for k=1:(c-1)
    term=term*a/k;
    partial=partial+term;
end
term=term*a/c;
tail=term/(1-rho);
pwait=tail/(partial+tail);
Wq=pwait/(c*mu-lambda);
answer=struct('rho',rho,'probabilityWait',pwait,'Wq',Wq, ...
    'Lq',lambda*Wq,'throughput',lambda);
end
