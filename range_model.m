function [h, H] = range_model(x, rs, vs)
% Measurement model: h = [range; range-rate] seen from a station.
% H is the 2x6 Jacobian of h with respect to the state [r; v].

d  = x(1:3) - rs;                           % station-to-satellite vector
dv = x(4:6) - vs;                           % relative velocity
rho = norm(d);
u   = d / rho;                              % line-of-sight unit vector
rho_dot = u' * dv;

h = [rho; rho_dot];

H = [u',                          zeros(1, 3);
     (dv - rho_dot * u)' / rho,   u'];
end
