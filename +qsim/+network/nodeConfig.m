function node=nodeConfig(id)
%NODECONFIG Fully shaped M4 service node, compatible with M2 node schema.
% For MATLAB struct arrays every node must have the same fields.
if nargin<1 || ~ischar(id) || isempty(id)
    error('qsim:InvalidNetwork','nodeConfig requires a nonempty char ID.');
end
c=qsim.defaultConfig();
node=c.network.nodes;
node.id=id;
end
