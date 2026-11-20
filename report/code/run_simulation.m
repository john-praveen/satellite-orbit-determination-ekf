function res = run_simulation(cfg)
% Simulate the truth and measurements, run the EKF and compute error metrics.

rng(cfg.seed);
stations = cfg.stations(cfg.station_ids);

truth = simulate_truth(cfg);
meas  = simulate_measurements(cfg, truth, stations);
est   = run_ekf(cfg, truth, meas, stations);

err = est.x - truth.x;
pos_err = vecnorm(err(1:3, :));             % position error size (km)
vel_err = vecnorm(err(4:6, :));             % velocity error size (km/s)

late = truth.t >= cfg.skip_time;            % ignore the start-up phase

res.cfg      = cfg;
res.stations = stations;
res.truth    = truth;
res.meas     = meas;
res.est      = est;
res.err      = err;
res.pos_err  = pos_err;
res.vel_err  = vel_err;
res.rms_pos  = sqrt(mean(pos_err(late).^2));
res.rms_vel  = sqrt(mean(vel_err(late).^2));
res.mean_nees = mean(est.nees(late));
end
