% Prints every baseline number quoted in the report, so each one can be
% checked by running this file. Settings come from default_config.m.

clear; clc; close all;
warning('off', 'all');

cfg = default_config();
res = run_simulation(cfg);

t     = res.truth.t;
vis   = res.meas.visible;
any_v = any(vis, 1);
late  = t >= cfg.skip_time;
est   = res.est;
err   = res.err;

%% Measurements and passes
[starts, stops] = find_passes(any_v);
gap_h = (t(starts(2:end)) - t(stops(1:end-1))) / 3600;

fprintf('\n--- Measurements and passes ---\n');
for s = 1:numel(res.stations)
    fprintf('%-10s %4d station-epochs\n', res.stations(s).name, sum(vis(s, :)));
end
fprintf('Total station-epochs: %d, distinct time steps: %d (%.2f h = %.1f %% of 24 h)\n', ...
    sum(vis(:)), sum(any_v), sum(any_v) * cfg.dt / 3600, 100 * sum(any_v) / numel(t));
fprintf('Number of passes: %d, longest gap: %.2f h\n', numel(starts), max(gap_h));
fprintf('First pass: %.2f - %.2f h\n', t(starts(1)) / 3600, t(stops(1)) / 3600);
fprintf('Second pass: %.2f - %.2f h\n', t(starts(2)) / 3600, t(stops(2)) / 3600);

%% Error history
fprintf('\n--- Error history ---\n');
fprintf('Initial error: %.0f m, %.2f m/s\n', res.pos_err(1) * 1e3, res.vel_err(1) * 1e3);
fprintf('Position error at start of first pass: %.2f km\n', res.pos_err(starts(1)));
fprintf('End of first pass: %.2f m, %.2f mm/s\n', res.pos_err(stops(1)) * 1e3, res.vel_err(stops(1)) * 1e6);
fprintf('End of second pass: %.2f m\n', res.pos_err(stops(2)) * 1e3);
fprintf('Position error after 1 h: %.1f m\n', res.pos_err(t == 3600) * 1e3);
fprintf('Largest error between pass 1 and pass 2: %.1f m\n', max(res.pos_err(stops(1):starts(2))) * 1e3);
fprintf('After 2 h: RMS %.2f m / %.2f mm/s, median %.2f m, max %.2f m / %.2f mm/s\n', ...
    res.rms_pos * 1e3, res.rms_vel * 1e6, median(res.pos_err(late)) * 1e3, ...
    max(res.pos_err(late)) * 1e3, max(res.vel_err(late)) * 1e6);
fprintf('Final error: %.2f m, %.2f mm/s\n', res.pos_err(end) * 1e3, res.vel_err(end) * 1e6);

%% 3-sigma coverage
fprintf('\n--- 3-sigma coverage (after 2 h) ---\n');
for i = 1:6
    inside = abs(err(i, late)) <= 3 * est.sigma(i, late);
    fprintf('state %d: %.1f %% inside +-3 sigma\n', i, 100 * mean(inside));
end
fprintf('Mean 3-sigma bound (m) x, y, z: %.1f  %.1f  %.1f\n', 3e3 * mean(est.sigma(1:3, late), 2));

%% Innovations
fprintf('\n--- Normalised innovations ---\n');
names = {'range', 'range-rate'};
for m = 1:2
    y = squeeze(est.innov(m, :, :));
    sg = squeeze(est.innov_sigma(m, :, :));
    z = y(~isnan(y)) ./ sg(~isnan(y));
    fprintf('%-10s mean %.3f, std %.3f, outside +-3: %.2f %%\n', names{m}, mean(z), std(z), 100 * mean(abs(z) > 3));
end

%% NIS and NEES
nis = est.nis(~isnan(est.nis));
nees = est.nees(late);
fprintf('\n--- Consistency ---\n');
fprintf('Mean NIS: %.2f, inside 95%% bounds [0.0506, 7.378]: %.1f %%\n', mean(nis), 100 * mean(nis > 0.0506 & nis < 7.378));
fprintf('Per-station mean NIS: %s\n', mat2str(mean(est.nis, 2, 'omitnan')', 3));
fprintf('Mean NEES: %.2f, inside bounds [1.237, 14.449]: %.1f %%, below: %.1f %%, above: %.1f %%\n', ...
    mean(nees), 100 * mean(nees > 1.237 & nees < 14.449), 100 * mean(nees < 1.237), 100 * mean(nees > 14.449));

%% Number of stations (Table: effect of the number of stations)
fprintf('\n--- Number of stations ---\n');
sets = {1, 1:2, 1:3, 1:4, 1:5, 1:6};
for i = 1:numel(sets)
    c = cfg;  c.station_ids = sets{i};  r = run_simulation(c);
    v = any(r.meas.visible, 1);
    [a, b] = find_passes(v);
    g = (r.truth.t(a(2:end)) - r.truth.t(b(1:end-1))) / 3600;
    tl = r.truth.t >= cfg.skip_time;
    fprintf('%d stations: %2d passes, longest gap %.1f h, RMS %.2f m, max error %.1f m, RMS last 6 h %.1f m\n', ...
        numel(sets{i}), numel(a), max(g), r.rms_pos * 1e3, max(r.pos_err(tl)) * 1e3, ...
        sqrt(mean(r.pos_err(r.truth.t >= 18*3600).^2)) * 1e3);
end

function [a, b] = find_passes(visible)
% Start and end index of each run of consecutive visible steps.
d = diff([0, visible, 0]);
a = find(d == 1);
b = find(d == -1) - 1;
end
