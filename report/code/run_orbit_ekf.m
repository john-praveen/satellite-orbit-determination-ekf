% Satellite orbit determination with an Extended Kalman Filter (EKF).
%
% A satellite is tracked from ground stations that measure range and
% range-rate. The EKF estimates the satellite position and velocity.
%
% Run this file to simulate, estimate, print a summary and plot results.
% Settings are in default_config.m.

clear; clc; close all;

cfg = default_config();
res = run_simulation(cfg);

print_summary(res);
plot_results(res);
