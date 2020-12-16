function local_params = get_local_params(params, i, n)

f = fieldnames(params);

for ifield = 1:numel(f)
    field = f{ifield};
    if numel(params.(field)) == n
        local_params.(field) = params.(field)(i);
    else
        if numel(params.(field)) ~= 1
            warning(['Number of parameters for ' field ' does not'...
                ' match number of variables in data set. Using first'...
                ' value of ' field ' for all variables.']);
        end
        local_params.(field) = params.(field)(1);
    end
end

end
