function plot_results(res)
% Make the five result figures and save them in the "results" folder.

cfg    = res.cfg;
th     = res.truth.t / 3600;                          % time in hours
passes = find_passes(any(res.meas.visible, 1));       % start/end index of each pass

figs(1) = plot_ground_track(res);
figs(2) = plot_error_norms(res, th, passes);
figs(3) = plot_position_components(res, th, passes);
figs(4) = plot_innovations(res, th);
figs(5) = plot_consistency(res, th);

if cfg.save_figs
    folder = fullfile(fileparts(mfilename('fullpath')), 'results');
    if ~exist(folder, 'dir'), mkdir(folder); end
    names = {'1_ground_track', '2_error_norms', '3_position_components', ...
             '4_innovations', '5_consistency'};
    for i = 1:numel(figs)
        exportgraphics(figs(i), fullfile(folder, [names{i} '.png']), 'Resolution', 150);
    end
    fprintf('Figures saved in: %s\n', folder);
end
end

% ---------------------------------------------------------------------
function f = plot_ground_track(res)
cfg = res.cfg;
t = res.truth.t;
X = res.truth.x;

% rotate inertial positions into the Earth-fixed frame to get lat/lon
theta = cfg.we * t;
x_e =  cos(theta) .* X(1, :) + sin(theta) .* X(2, :);
y_e = -sin(theta) .* X(1, :) + cos(theta) .* X(2, :);
lon = atan2d(y_e, x_e);
lat = atan2d(X(3, :), hypot(x_e, y_e));

vis = any(res.meas.visible, 1);
lon_line = lon;  lon_line([false abs(diff(lon)) > 180]) = NaN;   % break line at +-180

f = figure('Name', 'Ground track', 'Position', [100 100 900 450]);
hold on; grid on;
plot(lon_line, lat, '-', 'Color', [0.7 0.7 0.7]);
plot(lon(vis), lat(vis), '.', 'Color', [0.85 0.33 0.1], 'MarkerSize', 8);
for s = 1:numel(res.stations)
    plot(res.stations(s).lon, res.stations(s).lat, '^k', 'MarkerFaceColor', 'k');
    text(res.stations(s).lon + 3, res.stations(s).lat + 4, res.stations(s).name, 'FontSize', 8);
end
xlim([-180 180]); ylim([-90 90]);
xlabel('Longitude (deg)'); ylabel('Latitude (deg)');
title('Ground track (orange = measurements available)');
end

% ---------------------------------------------------------------------
function f = plot_error_norms(res, th, passes)
est = res.est;
pos_sigma = vecnorm(est.sigma(1:3, :)) * 1e3;         % filter's own estimate (m)
vel_sigma = vecnorm(est.sigma(4:6, :)) * 1e6;         % (mm/s)

f = figure('Name', 'Error norms', 'Position', [100 100 900 600]);

subplot(2, 1, 1);
semilogy(th, res.pos_err * 1e3, 'b', th, pos_sigma, 'r--'); grid on;
shade_passes(th, passes);
ylabel('Position error (m)');
legend('Actual error', 'Filter 1-sigma (RSS)', 'Measurement passes', 'Location', 'northeast');
title('EKF estimation error');

subplot(2, 1, 2);
semilogy(th, res.vel_err * 1e6, 'b', th, vel_sigma, 'r--'); grid on;
shade_passes(th, passes);
xlabel('Time (hours)'); ylabel('Velocity error (mm/s)');
end

% ---------------------------------------------------------------------
function f = plot_position_components(res, th, passes)
cfg = res.cfg;
late = res.truth.t >= cfg.skip_time;
vis  = any(res.meas.visible, 1);
labels = {'x', 'y', 'z'};

err   = res.err(1:3, :) * 1e3;                        % metres
bound = 3 * res.est.sigma(1:3, :) * 1e3;              % 3-sigma bound
y_lim = 2 * max(bound(:, vis & late), [], 'all');     % ignore the large gaps

f = figure('Name', 'Position components', 'Position', [100 100 900 600]);
for i = 1:3
    subplot(3, 1, i);
    plot(th, err(i, :), 'b', th, bound(i, :), 'r--', th, -bound(i, :), 'r--');
    grid on; hold on;
    xlim([cfg.skip_time / 3600, th(end)]);
    ylim([-y_lim, y_lim]);
    shade_passes(th, passes);
    ylabel(['Error ' labels{i} ' (m)']);
    if i == 1, title('Position error with +-3 sigma bounds (after start-up)'); end
end
xlabel('Time (hours)');
end

% ---------------------------------------------------------------------
function f = plot_innovations(res, th)
ns = numel(res.stations);
colors = lines(ns);
titles = {'Range innovation', 'Range-rate innovation'};

f = figure('Name', 'Innovations', 'Position', [100 100 900 600]);
for m = 1:2
    subplot(2, 1, m); hold on; grid on;
    for s = 1:ns
        y = squeeze(res.est.innov(m, s, :))' ./ squeeze(res.est.innov_sigma(m, s, :))';
        plot(th, y, '.', 'Color', colors(s, :));
    end
    yline(3, 'r--'); yline(-3, 'r--');
    ylim([-5 5]);
    ylabel('Innovation / sigma'); title(titles{m});
end
xlabel('Time (hours)');
legend({res.stations.name}, 'Location', 'eastoutside');
end

% ---------------------------------------------------------------------
function f = plot_consistency(res, th)
f = figure('Name', 'Consistency', 'Position', [100 100 900 600]);

% 95% chi-square bounds: 6 degrees of freedom for NEES, 2 for NIS
subplot(2, 1, 1);
semilogy(th, res.est.nees, 'b'); hold on; grid on;
yline(1.237, 'r--'); yline(14.449, 'r--');
ylabel('NEES'); title('State error consistency (NEES, 95% bounds in red)');

subplot(2, 1, 2);
semilogy(th, res.est.nis', '.'); hold on; grid on;
yline(0.0506, 'r--'); yline(7.378, 'r--');
xlabel('Time (hours)'); ylabel('NIS'); title('Innovation consistency (NIS, 95% bounds in red)');
end

% ---------------------------------------------------------------------
function passes = find_passes(visible)
% Start and end index of each run of consecutive visible steps.
d = diff([0, visible, 0]);
passes = [find(d == 1)', find(d == -1)' - 1];
end

function shade_passes(th, passes)
% Grey bands showing when measurements were available.
yl = ylim;
for i = 1:size(passes, 1)
    t1 = th(passes(i, 1));  t2 = th(passes(i, 2));
    p = patch([t1 t2 t2 t1], [yl(1) yl(1) yl(2) yl(2)], [0.8 0.8 0.8], ...
        'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');
    uistack(p, 'bottom');
end
% one invisible entry so the legend can name the bands
patch(NaN, NaN, [0.8 0.8 0.8], 'EdgeColor', 'none', 'DisplayName', 'Measurement passes');
end
