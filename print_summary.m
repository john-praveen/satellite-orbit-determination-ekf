function print_summary(res)
% Print the main numbers of one simulation run.

cfg = res.cfg;
nis = res.est.nis(~isnan(res.est.nis));

fprintf('\n===== Orbit determination with EKF =====\n');
fprintf('Orbit: a = %.0f km, e = %.3f, i = %.0f deg\n', cfg.orbit.a, cfg.orbit.e, cfg.orbit.inc);
fprintf('Duration: %.0f h, time step: %.0f s\n', cfg.T / 3600, cfg.dt);
fprintf('Filter gravity model: %s\n', ternary(cfg.filter_uses_J2, 'two-body + J2', 'two-body only'));

fprintf('\nMeasurements per station:\n');
for s = 1:numel(res.stations)
    fprintf('  %-24s %4d steps visible\n', res.stations(s).name, sum(res.meas.visible(s, :)));
end

fprintf('\nInitial error:  position %.3f km, velocity %.3f m/s\n', ...
    res.pos_err(1), res.vel_err(1) * 1e3);
fprintf('RMS error after %.0f h:  position %.2f m, velocity %.2f mm/s\n', ...
    cfg.skip_time / 3600, res.rms_pos * 1e3, res.rms_vel * 1e6);
fprintf('Final error:    position %.2f m, velocity %.2f mm/s\n', ...
    res.pos_err(end) * 1e3, res.vel_err(end) * 1e6);

fprintf('\nConsistency checks:\n');
fprintf('  mean NEES = %.2f  (ideal is 6)\n', res.mean_nees);
fprintf('  mean NIS  = %.2f  (ideal is 2)\n', mean(nis));
fprintf('  NIS inside the 95%% bounds: %.1f %%\n\n', 100 * mean(nis > 0.0506 & nis < 7.378));
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
