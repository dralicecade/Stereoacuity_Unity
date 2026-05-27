function out = DefInput(prompt, defaultValue)
out = input([prompt ' '], 's');
if isempty(out)
    out = defaultValue;
else
    out = str2num(out); %#ok<ST2NM>
    if isempty(out)
        out = defaultValue;
    end
end
end