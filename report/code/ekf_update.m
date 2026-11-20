function [x, P, y, S] = ekf_update(x, P, z, station, t, R, cfg)
% EKF correction step using one station's [range; range-rate] measurement z.
% Returns the innovation y and its covariance S for consistency checks.

[rs, vs] = station_eci(station, t, cfg);
[h, H]   = range_model(x, rs, vs);

y = z - h;                                  % innovation
S = H * P * H' + R;                         % innovation covariance
K = P * H' / S;                             % Kalman gain

x = x + K * y;

I_KH = eye(6) - K * H;
P = I_KH * P * I_KH' + K * R * K';          % Joseph form (numerically safe)
end
