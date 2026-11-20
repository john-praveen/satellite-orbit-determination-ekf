function [x, P] = ekf_predict(x, P, dt, cfg)
% EKF prediction step: propagate the state and grow the uncertainty.

[x, Phi] = propagate_state(x, dt, cfg, cfg.filter_uses_J2);

Q = process_noise(dt, cfg.q_accel);
P = Phi * P * Phi' + Q;
P = (P + P') / 2;                           % keep P symmetric
end

function Q = process_noise(dt, q)
% Random acceleration noise of strength q, integrated over dt.
I = eye(3);
Q = q * [dt^3/3 * I, dt^2/2 * I;
         dt^2/2 * I, dt     * I];
end
