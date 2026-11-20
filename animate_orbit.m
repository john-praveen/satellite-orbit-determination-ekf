function animate_orbit(res, step, video_file)
% 3D animation of the satellite, the rotating Earth, the ground stations and
% the EKF position error.
%   step       : draw every "step"-th time step (default 6 = 60 s)
%   video_file : optional .mp4 file name to record the animation

if nargin < 2, step = 6; end
if nargin < 3, video_file = ''; end

cfg = res.cfg;
st  = res.stations;
t   = res.truth.t;
X   = res.truth.x;
Xe  = res.est.x;
vis = res.meas.visible;
K   = numel(t);
ns  = numel(st);

period    = 2*pi * sqrt(cfg.orbit.a^3 / cfg.mu);
trail_len = round(period / cfg.dt);                   % trail = one orbit

%% Figure and axes
f   = figure('Color', 'k', 'Position', [50 50 1200 600], 'Name', 'Orbit animation');
ax3 = axes('Position', [0.01 0.03 0.62 0.90], 'Color', 'k');
ax2 = axes('Position', [0.69 0.15 0.28 0.68]);
ax3.Toolbar.Visible = 'off';                          % hide the hover toolbars
ax2.Toolbar.Visible = 'off';

%% 3D scene: Earth with the stations fixed on it
earth = hgtransform('Parent', ax3);
[xs, ys, zs] = sphere(36);
surf(cfg.Re*xs, cfg.Re*ys, cfg.Re*zs, 'Parent', earth, 'FaceColor', [0.1 0.3 0.6], ...
    'EdgeColor', [0.5 0.65 0.9], 'EdgeAlpha', 0.35);
hold(ax3, 'on');

for s = 1:ns
    p = station_eci(st(s), 0, cfg);                   % at t = 0 this is the Earth-fixed position
    plot3(p(1), p(2), p(3), '^', 'Parent', earth, 'MarkerFaceColor', 'y', ...
        'MarkerEdgeColor', 'w', 'MarkerSize', 8);
    text(1.08*p(1), 1.08*p(2), 1.08*p(3), st(s).name, 'Parent', earth, ...
        'Color', 'w', 'FontSize', 8);
end

h_trail = plot3(ax3, NaN, NaN, NaN, '-', 'Color', [0.7 0.7 0.7]);
h_sat   = plot3(ax3, NaN, NaN, NaN, 'o', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'y', 'MarkerSize', 7);
h_est   = plot3(ax3, NaN, NaN, NaN, 'o', 'MarkerEdgeColor', 'r', 'MarkerSize', 13, 'LineWidth', 1.5);
h_los   = gobjects(1, ns);
for s = 1:ns
    h_los(s) = plot3(ax3, NaN, NaN, NaN, '-', 'Color', [0.2 1 0.4], 'LineWidth', 1.5);
end

lim = 1.15 * cfg.orbit.a;
axis(ax3, 'equal', 'off');
set(ax3, 'XLim', [-lim lim], 'YLim', [-lim lim], 'ZLim', [-lim lim]);
view(ax3, 40, 25);
legend(ax3, [h_sat h_est h_los(1)], {'True satellite', 'EKF estimate', 'Station tracking'}, ...
    'TextColor', 'w', 'Color', 'none', 'EdgeColor', 'none', 'Location', 'southwest');

%% Error panel
pos_err_m = res.pos_err * 1e3;
th = t / 3600;
semilogy(ax2, th, pos_err_m, 'Color', [0.3 0.3 0.3]); hold(ax2, 'on');
h_done = semilogy(ax2, NaN, NaN, 'c');
h_now  = semilogy(ax2, NaN, NaN, 'ro', 'MarkerFaceColor', 'r');
grid(ax2, 'on');
set(ax2, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', 'w');
xlim(ax2, [0 th(end)]);
ylim(ax2, [min(pos_err_m)/2, max(pos_err_m)*2]);
xlabel(ax2, 'Time (hours)'); ylabel(ax2, 'Position error (m)');
text(ax2, 0, 1.04, 'EKF position error', 'Units', 'normalized', 'Color', 'w', ...
    'FontWeight', 'bold', 'FontSize', 11);          % left-aligned so it never hides behind the toolbar

%% Optional video
frame_size = [];
if ~isempty(video_file)
    vw = VideoWriter(video_file, 'MPEG-4');
    vw.FrameRate = 30;
    open(vw);
end

%% Animation loop
for k = 1:step:K
    if ~isvalid(f), break, end

    set(earth, 'Matrix', makehgtform('zrotate', cfg.we * t(k)));   % Earth spins

    i0 = max(1, k - trail_len);
    set(h_trail, 'XData', X(1, i0:k), 'YData', X(2, i0:k), 'ZData', X(3, i0:k));
    set(h_sat, 'XData', X(1, k),  'YData', X(2, k),  'ZData', X(3, k));
    set(h_est, 'XData', Xe(1, k), 'YData', Xe(2, k), 'ZData', Xe(3, k));

    for s = 1:ns
        if vis(s, k)
            rs = station_eci(st(s), t(k), cfg);
            set(h_los(s), 'XData', [rs(1) X(1, k)], 'YData', [rs(2) X(2, k)], 'ZData', [rs(3) X(3, k)]);
        else
            set(h_los(s), 'XData', NaN, 'YData', NaN, 'ZData', NaN);
        end
    end

    set(h_done, 'XData', th(1:k), 'YData', pos_err_m(1:k));
    set(h_now,  'XData', th(k),   'YData', pos_err_m(k));

    names = strjoin({st(vis(:, k)).name}, ', ');
    if isempty(names), names = 'none'; end
    title(ax3, sprintf('t = %5.2f h   |   tracking: %s   |   position error: %.1f m', ...
        th(k), names, pos_err_m(k)), 'Color', 'w');

    drawnow limitrate;
    if ~isempty(video_file)
        frame = getframe(f).cdata;
        if isempty(frame_size), frame_size = size(frame); end
        writeVideo(vw, match_size(frame, frame_size));
    end
end

if ~isempty(video_file)
    close(vw);
    fprintf('Video saved: %s\n', video_file);
end
end

function img = match_size(img, sz)
% Crop or pad a frame so that every video frame has the same size.
img = img(1:min(end, sz(1)), 1:min(end, sz(2)), :);
img(end+1:sz(1), :, :) = 0;
img(:, end+1:sz(2), :) = 0;
end
