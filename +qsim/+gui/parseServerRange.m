function counts = parseServerRange(input)
%PARSESERVERANGE Parse human-entered staffing comparisons without eval.
% Supported: '3:12', '3:2:13', '3,5,8,12', or one integer.
if isstring(input), input = char(input); end
if ~(ischar(input) && isrow(input))
    error('qsim:InvalidServerRange','Enter a text range such as 3:12.');
end
s = regexprep(strtrim(input),'\s+','');
if isempty(s)
    error('qsim:InvalidServerRange','Server range cannot be empty.');
end
if contains(s,':')
    parts = regexp(s,':','split');
    if numel(parts)<2 || numel(parts)>3
        error('qsim:InvalidServerRange','Use start:end or start:step:end.');
    end
    for k=1:numel(parts)
        if isempty(regexp(parts{k},'^\d+$','once'))
            error('qsim:InvalidServerRange','Server ranges require positive integers.');
        end
    end
    values = cellfun(@str2double,parts);
    if numel(values)==2
        counts = values(1):values(2);
    else
        counts = values(1):values(2):values(3);
    end
elseif contains(s,',')
    parts = regexp(s,',','split');
    for k=1:numel(parts)
        if isempty(regexp(parts{k},'^\d+$','once'))
            error('qsim:InvalidServerRange','Use comma-separated positive integers.');
        end
    end
    counts = cellfun(@str2double,parts);
else
    if isempty(regexp(s,'^\d+$','once'))
        error('qsim:InvalidServerRange','Use 3:12, 3:2:13, or 3,5,8,12.');
    end
    counts = str2double(s);
end
if isempty(counts) || any(~isfinite(counts)) || ...
        any(counts<1 | counts>100 | counts~=floor(counts))
    error('qsim:InvalidServerRange','Server counts must be integers from 1 to 100.');
end
counts = unique(counts(:)','sorted');
if numel(counts)>60
    error('qsim:InvalidServerRange','Compare no more than 60 configurations at once.');
end
end
