function meas = simulate_measurements(cfg, truth, stations)
% Noisy [range; range-rate] from each station, only while the satellite
% is above the minimum elevation. Missing measurements are NaN.

K  = numel(truth.t);
ns = numel(stations);
noise_std = [cfg.sigma_range; cfg.sigma_rrate];

meas.z       = nan(2, ns, K);
meas.visible = false(ns, K);

for k = 1:K
    x = truth.x(:, k);
    for s = 1:ns
        [rs, vs, up] = station_eci(stations(s), truth.t(k), cfg);

        d = x(1:3) - rs;
        elevation = asind(dot(d, up) / norm(d));
        if elevation < cfg.min_elev
            continue
        end

        h = range_model(x, rs, vs);
        meas.z(:, s, k)   = h + noise_std .* randn(2, 1);
        meas.visible(s, k) = true;
    end
end
end
