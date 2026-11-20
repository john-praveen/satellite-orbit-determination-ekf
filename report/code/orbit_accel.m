function a = orbit_accel(r, cfg, use_J2)
% Gravity acceleration at position r (3x1, km): two-body plus optional J2.

rn = norm(r);
a = -cfg.mu * r / rn^3;                     % two-body gravity

if use_J2
    k  = -1.5 * cfg.J2 * cfg.mu * cfg.Re^2 / rn^5;
    z2 = (r(3) / rn)^2;
    a_J2 = k * [r(1) * (1 - 5*z2);
                r(2) * (1 - 5*z2);
                r(3) * (3 - 5*z2)];
    a = a + a_J2;
end
end
