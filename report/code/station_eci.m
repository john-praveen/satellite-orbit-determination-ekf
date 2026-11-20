function [rs, vs, up] = station_eci(st, t, cfg)
% Ground station position, velocity and local "up" direction in the inertial
% frame at time t. The station moves because the Earth rotates.

lat = deg2rad(st.lat);
lon = deg2rad(st.lon);

% position in the Earth-fixed frame (WGS84 ellipsoid)
N = cfg.Re / sqrt(1 - cfg.e2 * sin(lat)^2);
r_ecef = [(N + st.alt) * cos(lat) * cos(lon);
          (N + st.alt) * cos(lat) * sin(lon);
          (N * (1 - cfg.e2) + st.alt) * sin(lat)];
up_ecef = [cos(lat)*cos(lon); cos(lat)*sin(lon); sin(lat)];

% rotate into the inertial frame by the Earth rotation angle
theta = cfg.we * t;
Rz = [cos(theta) -sin(theta) 0; sin(theta) cos(theta) 0; 0 0 1];

rs = Rz * r_ecef;
up = Rz * up_ecef;
vs = cross([0; 0; cfg.we], rs);             % velocity from Earth rotation
end
