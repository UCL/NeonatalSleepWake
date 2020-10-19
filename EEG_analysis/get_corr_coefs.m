function [rc,pc] = get_corr_coefs(events, channels)
% function [rc,pc] = get_corr_coefs(events, channels)
%
% Calculate correlation r and p coefficients between sparsity of events and
% event power in selected channels.

n = numel(channels);
rc = zeros(n,1);
pc = zeros(n,1);

for i = 1:n
    channel = channels{i};
    if events.(channel).n > 3
        [r,p] = corrcoef(gradient(events.(channel).latency), ...
            events.(channel).power);
        assert(issymmetric(r), 'r matrix should be symmetric for two signals')
        assert(issymmetric(p), 'p matrix should be symmetric for two signals')
        rc(i) = r(1,2);
        pc(i) = p(1,2);
    else
        warning(['could not calculate correlation between sparsity and power for channel ',...
            channel,' because of too few events'])
        rc(i) = NaN;
        pc(i) = NaN;
    end
end

end