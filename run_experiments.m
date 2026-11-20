% Parameter studies for the orbit determination EKF.
% Each study changes one setting and reports the RMS error after start-up.
% Cases where the filter diverges show up as very large errors.

clear; clc; close all;
warning('off', 'MATLAB:nearlySingularMatrix');        % expected when a filter diverges
warning('off', 'MATLAB:singularMatrix');
base = default_config();
base.save_figs = false;

%% 1. Number of ground stations
station_sets = {1, 1:2, 1:3, 1:4, 1:5, 1:6};
n_stations = cellfun(@numel, station_sets);
rms1 = nan(size(station_sets));
for i = 1:numel(station_sets)
    cfg = base;  cfg.station_ids = station_sets{i};
    rms1(i) = run_case(cfg);
end
print_table('Number of stations', n_stations, rms1);

%% 2. Process noise q (filter tuning)
q_values = [1e-18 1e-17 1e-16 1e-15 1e-14 1e-13];
rms2 = nan(size(q_values));  nees2 = nan(size(q_values));
for i = 1:numel(q_values)
    cfg = base;  cfg.q_accel = q_values(i);
    [rms2(i), nees2(i)] = run_case(cfg);
end
print_table('Process noise q (km^2/s^3)', q_values, rms2, nees2);

%% 3. Initial position error (velocity error scales with it)
p0_values = [0.1 1 5 20 50 100];
rms3 = nan(size(p0_values));
for i = 1:numel(p0_values)
    cfg = base;  cfg.P0_pos = p0_values(i);  cfg.P0_vel = p0_values(i) * 1e-3;
    rms3(i) = run_case(cfg);
end
print_table('Initial position error (km)', p0_values, rms3);

%% 4. Measurement noise (multiplier on the default sigmas)
noise_values = [0.1 1 5 10];
rms4 = nan(size(noise_values));
for i = 1:numel(noise_values)
    cfg = base;
    cfg.sigma_range = base.sigma_range * noise_values(i);
    cfg.sigma_rrate = base.sigma_rrate * noise_values(i);
    rms4(i) = run_case(cfg);
end
print_table('Measurement noise multiplier', noise_values, rms4);

%% 5. Filter dynamics model: with J2 or two-body only
rms5 = nan(1, 2);
for i = 1:2
    cfg = base;  cfg.filter_uses_J2 = (i == 1);
    cfg.q_accel = ternary(i == 1, 1e-16, 1e-9);       % two-body needs a lot more q
    rms5(i) = run_case(cfg);
end
print_table('Filter model (1 = two-body+J2, 2 = two-body only)', [1 2], rms5);

%% 6. Monte Carlo: 20 runs with different noise and initial guesses
n_runs = 20;
rms6 = nan(1, n_runs);  nees6 = nan(1, n_runs);
for i = 1:n_runs
    cfg = base;  cfg.seed = i;
    [rms6(i), nees6(i)] = run_case(cfg);
end
fprintf('\nMonte Carlo (%d runs): RMS position = %.2f +- %.2f m, mean NEES = %.2f (ideal 6)\n', ...
    n_runs, mean(rms6), std(rms6), mean(nees6));

%% Summary plot
figure('Position', [100 100 1000 700]);
subplot(2, 2, 1); semilogy(n_stations, rms1, 'o-', 'LineWidth', 1.5); grid on;
xlabel('Number of stations'); ylabel('RMS position error (m)');

subplot(2, 2, 2); loglog(q_values, rms2, 'o-', 'LineWidth', 1.5); grid on;
xlabel('Process noise q'); ylabel('RMS position error (m)');

subplot(2, 2, 3); loglog(p0_values, rms3, 'o-', 'LineWidth', 1.5); grid on;
xlabel('Initial position error (km)'); ylabel('RMS position error (m)');

subplot(2, 2, 4); loglog(noise_values, rms4, 'o-', 'LineWidth', 1.5); grid on;
xlabel('Measurement noise multiplier'); ylabel('RMS position error (m)');

sgtitle('EKF orbit determination: parameter studies');
folder = fullfile(fileparts(mfilename('fullpath')), 'results');
if ~exist(folder, 'dir'), mkdir(folder); end
exportgraphics(gcf, fullfile(folder, '6_parameter_studies.png'), 'Resolution', 150);

% ---------------------------------------------------------------------
function [rms_pos_m, mean_nees] = run_case(cfg)
% Run one simulation and return RMS position error (m) and mean NEES.
res = run_simulation(cfg);
rms_pos_m = res.rms_pos * 1e3;
mean_nees = res.mean_nees;
end

function print_table(name, values, rms_pos, nees)
fprintf('\n--- %s ---\n', name);
for i = 1:numel(values)
    if nargin > 3
        fprintf('  %-10g  RMS position = %12.2f m   mean NEES = %g\n', values(i), rms_pos(i), nees(i));
    else
        fprintf('  %-10g  RMS position = %12.2f m\n', values(i), rms_pos(i));
    end
end
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
