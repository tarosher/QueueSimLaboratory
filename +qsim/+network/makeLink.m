function link=makeLink(from,to,probability,delay)
%MAKELINK Directed conditional route, including optional travel delay.
if nargin<4, delay=0; end
link=struct('from',from,'to',to,'probability',probability,'delay',delay);
end
