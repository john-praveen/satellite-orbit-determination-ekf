function est = run_ekf(cfg, truth, meas, stations)
% Run the EKF over the whole time line.
% Each step: predict, then correct once per visible station.

K  = numel(truth.t);
ns = numel(stations);

R  = diag([cfg.sigma_range, cfg.sigma_rrate].^2);
P  = diag([cfg.P0_pos * ones(1, 3), cfg.P0_vel * ones(1, 3)].^2);

% start from a wrong initial guess drawn from the initial uncertainty
x = truth.x(:, 1) + sqrt(diag(P)) .* randn(6, 1);

est.x           = zeros(6, K);
est.sigma       = zeros(6, K);              % filter's own 1-sigma values
est.nees        = zeros(1, K);              % state error consistency
est.innov       = nan(2, ns, K);
est.innov_sigma = nan(2, ns, K);
est.nis         = nan(ns, K);               % innovation consistency

for k = 1:K
    if k > 1
        [x, P] = ekf_predict(x, P, truth.t(k) - truth.t(k-1), cfg);
    end

    for s = 1:ns
        if ~meas.visible(s, k)
            continue
        end
        [x, P, y, S] = ekf_update(x, P, meas.z(:, s, k), stations(s), truth.t(k), R, cfg);

        est.innov(:, s, k)       = y;
        est.innov_sigma(:, s, k) = sqrt(diag(S));
        est.nis(s, k)            = y' / S * y;
    end

    e = x - truth.x(:, k);
    est.x(:, k)     = x;
    est.sigma(:, k) = sqrt(diag(P));
    est.nees(k)     = e' / P * e;
end
end
