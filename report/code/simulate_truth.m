function truth = simulate_truth(cfg)
% Generate the true satellite trajectory (two-body + J2 + small drag) with a
% high-accuracy ODE solver, independent of the filter's own integrator.
% The drag is unknown to the filter, so the filter must handle it with process noise.

t  = 0:cfg.dt:cfg.T;
x0 = kepler_to_state(cfg.orbit, cfg.mu);

drag = @(v) -cfg.drag_accel * v / norm(v);  % opposes the velocity
f    = @(~, x) [x(4:6); orbit_accel(x(1:3), cfg, true) + drag(x(4:6))];
opts = odeset('RelTol', 1e-10, 'AbsTol', 1e-12);
[~, X] = ode45(f, t, x0, opts);

truth.t = t;
truth.x = X';                               % 6 x K
end
