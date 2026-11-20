function cfg = default_config()
% All simulation and filter settings in one place.
% Units: km, km/s, seconds. Angles in degrees unless stated.

% ---- Earth constants ----
cfg.mu = 398600.4418;        % gravitational parameter (km^3/s^2)
cfg.Re = 6378.137;           % equatorial radius (km)
cfg.J2 = 1.08263e-3;         % oblateness coefficient
cfg.we = 7.2921159e-5;       % Earth rotation rate (rad/s)
cfg.e2 = 0.00669437999014;   % WGS84 eccentricity squared

% ---- Time ----
cfg.dt       = 10;           % time step (s)
cfg.T        = 24*3600;      % total simulated time (s)
cfg.max_step = 10;           % largest RK4 sub-step used in the filter (s)

% ---- True satellite orbit (Kepler elements, sun-synchronous LEO) ----
cfg.orbit.a    = 7000;       % semi-major axis (km)
cfg.orbit.e    = 0.001;      % eccentricity
cfg.orbit.inc  = 98;         % inclination (deg)
cfg.orbit.raan = 40;         % right ascension of ascending node (deg)
cfg.orbit.argp = 0;          % argument of perigee (deg)
cfg.orbit.nu   = 0;          % true anomaly at start (deg)
cfg.drag_accel = 1e-10;      % small drag deceleration, only in the truth (km/s^2)

% ---- Ground stations ----
cfg.stations = struct( ...
    'name', {'Moratuwa', 'London', 'New York', 'Tokyo', 'Sydney', 'Moscow'}, ...
    'lat',  {6.79,   51.51,  40.71,   35.68,  -33.87,  55.75}, ...
    'lon',  {79.90,  -0.13, -74.01,  139.69,  151.21,  37.62}, ...
    'alt',  {0.01,    0.01,   0.01,    0.04,    0.03,   0.15});
cfg.station_ids = 1:6;       % which stations are used
cfg.min_elev    = 10;        % minimum elevation to get a measurement (deg)

% ---- Measurement noise (1 sigma) ----
cfg.sigma_range = 0.010;     % range noise: 10 m
cfg.sigma_rrate = 1e-6;      % range-rate noise: 1 mm/s

% ---- Filter settings ----
cfg.filter_uses_J2 = true;   % false = filter only knows two-body gravity
cfg.q_accel = 1e-16;         % process noise strength (km^2/s^3)
cfg.P0_pos  = 1;             % initial position uncertainty (km)
cfg.P0_vel  = 0.001;         % initial velocity uncertainty (km/s)

% ---- Other ----
cfg.seed      = 1;           % random seed
cfg.skip_time = 2*3600;      % ignore the first 2 h when computing RMS errors (s)
cfg.save_figs = true;        % save plots to the results folder
end
