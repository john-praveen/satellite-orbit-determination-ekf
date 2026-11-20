% Play a 3D animation of the satellite orbit, the ground stations and the
% EKF position error.
%
% Green line = a station is tracking the satellite.
% Yellow dot = true satellite, red ring = EKF estimate.

clear; clc; close all;

cfg = default_config();
res = run_simulation(cfg);

animate_orbit(res, 6);                      % draw every 6th step (every 60 s)

% To also record an .mp4 video, use this line instead:
% animate_orbit(res, 6, 'results/orbit_animation.mp4');
