function [x, Phi] = propagate_state(x, dt, cfg, use_J2)
% Move the state x = [r; v] forward by dt using RK4.
% Phi is the state transition matrix (the Jacobian F of the dynamics over dt).

n_steps = ceil(dt / cfg.max_step);
h = dt / n_steps;

z = [x; reshape(eye(6), 36, 1)];            % state and Phi stacked together
for i = 1:n_steps
    k1 = derivative(z,            cfg, use_J2);
    k2 = derivative(z + h/2 * k1, cfg, use_J2);
    k3 = derivative(z + h/2 * k2, cfg, use_J2);
    k4 = derivative(z + h   * k3, cfg, use_J2);
    z  = z + h/6 * (k1 + 2*k2 + 2*k3 + k4);
end

x   = z(1:6);
Phi = reshape(z(7:end), 6, 6);
end

function dz = derivative(z, cfg, use_J2)
% Rate of change of the state and of Phi:  dPhi/dt = A * Phi
r   = z(1:3);
v   = z(4:6);
Phi = reshape(z(7:end), 6, 6);

a = orbit_accel(r, cfg, use_J2);
A = [zeros(3), eye(3);
     accel_gradient(r, cfg, use_J2), zeros(3)];

dz = [v; a; reshape(A * Phi, 36, 1)];
end

function G = accel_gradient(r, cfg, use_J2)
% d(acceleration)/d(position), found by central finite differences.
d = 1e-3;                                   % small step (km)
G = zeros(3);
for i = 1:3
    dr = zeros(3, 1);
    dr(i) = d;
    G(:, i) = (orbit_accel(r + dr, cfg, use_J2) - orbit_accel(r - dr, cfg, use_J2)) / (2*d);
end
end
