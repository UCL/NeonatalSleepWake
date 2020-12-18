function [o1, o2] = merge_tables(t1, t2)

o1 = t1;
o2 = t2;

n1 = t1.Properties.VariableNames;
n2 = t2.Properties.VariableNames;

for i = 1:numel(n1)
    name = t1.Properties.VariableNames{i};
    if(any(strcmp(t2.Properties.VariableNames, name)))
        o2.(name) = t2.(name);
    else
        o2.(name) = NaN(height(t2),1);
    end
end

for i = 1:numel(n2)
    name = t2.Properties.VariableNames{i};
    if(any(strcmp(t1.Properties.VariableNames, name)))
        o1.(name) = t1.(name);
    else
        o1.(name) = NaN(height(t1),1);
    end
end

end