function x = kepler_to_state(orbit, mu)
% Convert Kepler elements to an inertial state x = [r; v] (km, km/s).

e  = orbit.e;
nu = deg2rad(orbit.nu);
p  = orbit.a * (1 - e^2);

% position and velocity in the orbital plane
r_pf = p / (1 + e*cos(nu)) * [cos(nu); sin(nu); 0];
v_pf = sqrt(mu / p) * [-sin(nu); e + cos(nu); 0];

% rotate to the inertial frame
R = rot_z(deg2rad(orbit.raan)) * rot_x(deg2rad(orbit.inc)) * rot_z(deg2rad(orbit.argp));
x = [R * r_pf; R * v_pf];
end

function R = rot_z(a)
R = [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1];
end

function R = rot_x(a)
R = [1 0 0; 0 cos(a) -sin(a); 0 sin(a) cos(a)];
end
