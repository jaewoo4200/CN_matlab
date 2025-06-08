%% Module 2 Final Assignment Simulation
% This script runs simulations for various scenarios described in the
% assignment. All results are generated using the helper function
% simulateScheduler.m.

clear; clc;

%% Parameters
windowVals = [0 16 64 256 512 1024 2048 4096];
userCounts = [1 4 8 16 30 64];
speed = 30;          % km/h for part 1
prbMode = 2;         % 2PRB mode by default
T = 2000;            % number of TTIs

cellTp = zeros(length(windowVals), length(userCounts));
fairMat = zeros(length(windowVals), length(userCounts));

%% Part 1: Analyse cell throughput and fairness
for w = 1:length(windowVals)
    for u = 1:length(userCounts)
        res = simulateScheduler(userCounts(u), windowVals(w), prbMode, speed, T, 'basic', 0);
        cellTp(w,u) = res.cellThroughput;
        fairMat(w,u) = res.fairness;
    end
end

figure; hold on;
for u = 1:length(userCounts)
    plot(windowVals, cellTp(:,u), '-o', 'DisplayName', [num2str(userCounts(u)) ' users']);
end
xlabel('t_w'); ylabel('Cell Throughput (bps)');
title('Cell Throughput vs t_w');
legend; grid on;

figure; hold on;
for u = 1:length(userCounts)
    plot(windowVals, fairMat(:,u), '-o', 'DisplayName', [num2str(userCounts(u)) ' users']);
end
xlabel('t_w'); ylabel('Jain Fairness');
title('Fairness vs t_w');
legend; grid on;

%% Part 2: Modified PFRS scheduler for fairness (30 users)
numUsers = 30;
resBasic = simulateScheduler(numUsers, 256, prbMode, speed, T, 'basic', 0);
resMod = simulateScheduler(numUsers, 256, prbMode, speed, T, 'modified', 0);

figure;
plot(resBasic.cellBits, 'DisplayName', 'Basic'); hold on;
plot(resMod.cellBits, 'DisplayName', 'Modified');
legend; grid on;
xlabel('TTI'); ylabel('Cumulative Bits');
title('Cell Throughput: Basic vs Modified PFRS (30 users)');

%% Part 3: Scheduler with minimum required rate 128 kbps
minRate = 128e3; % bps
resMin = simulateScheduler(numUsers, 256, prbMode, speed, T, 'minrate', minRate);

figure; hold on;
for k=1:numUsers
    plot(resMin.cumBits(k,:), 'DisplayName', ['User ' num2str(k)]);
end
xlabel('TTI'); ylabel('Cumulative Bits');
title('Cumulative Bits with Minimum Rate Scheduler');
legend('show'); grid on;

%% Part 4: Speed and PRB mode comparison
speeds = [3 30 50 100];
prbModes = [2 10];
colors = lines(length(speeds));

for pm = 1:length(prbModes)
    figure; hold on;
    for s = 1:length(speeds)
        r = simulateScheduler(numUsers, 256, prbModes(pm), speeds(s), T, 'basic', 0);
        plot(r.cellBits, 'Color', colors(s,:), 'DisplayName', [num2str(speeds(s)) ' km/h']);
    end
    xlabel('TTI'); ylabel('Cumulative Bits');
    title(['Speed Comparison ' num2str(prbModes(pm)) 'PRB']);
    legend; grid on;
end

%% Part 5: Frequency comparison (850MHz, 1.9GHz, 28GHz)
freqs = [0.85 1.9 28];
labels = {'850MHz','1.9GHz','28GHz'};
colors = lines(length(freqs));
figure; hold on;
for f = 1:length(freqs)
    r = simulateScheduler(numUsers, 256, prbMode, speed, T, 'basic', 0, freqs(f));
    plot(r.cellBits, 'Color', colors(f,:), 'DisplayName', labels{f});
end
xlabel('TTI'); ylabel('Cumulative Bits');
title('Frequency Comparison (30 users)');
legend; grid on;

%% Example Graph Set for one scenario
res = simulateScheduler(numUsers, 256, prbMode, speed, T, 'basic', 0);

figure; plot(res.selected); xlabel('TTI'); ylabel('Selected User');
title('Selected user vs time'); grid on;

figure; imagesc(res.prb); xlabel('TTI'); ylabel('User'); colorbar;
title('PRB allocation');

figure; plot(res.rate'); xlabel('TTI'); ylabel('Instantaneous Rate (bps)');
title('User bit rate vs time'); grid on;

figure; plot(res.bits'); xlabel('TTI'); ylabel('Bits per TTI');
title('User bits vs time'); grid on;

figure; plot(res.cumBits'); xlabel('TTI'); ylabel('Cumulative Bits');
title('Cumulative bits per user'); grid on;

figure; plot(res.cellBits); xlabel('TTI'); ylabel('Cumulative Cell Bits');
title('Cell cumulative bits'); grid on;

figure; bar(res.throughput); xlabel('User'); ylabel('Average Throughput (bps)');
title('Average user throughput'); grid on;

