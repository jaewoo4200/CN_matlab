function results = simulateScheduler(numUsers, t_w, prbMode, speedKmph, totalTime, schedulerType, minRate, freqGHz)
%SIMULATESCHEDULER Simulate a simple cellular scheduler.
%
%   RESULTS = SIMULATESCHEDULER(NUMUSERS, T_W, PRBMODE, SPEEDKMPH, TOTALTIME,
%   SCHEDULERTYPE, MINRATE) runs a simplified LTE-like simulation for the
%   specified number of users and parameters. PRBMODE should be 2 or 10 to
%   indicate the number of PRBs available per TTI. SPEEDKMPH gives the user
%   speed in km/h. TOTALTIME is the number of TTIs to simulate. SCHEDULERTYPE
%   can be 'basic', 'modified', or 'minrate' for the three schedulers. MINRATE
%   is the minimum required rate in bps used only for the 'minrate' scheduler.
%
%   The function returns a structure RESULTS containing various metrics and
%   time series used for plotting.

% Constants
PRB_BW = 180e3;          % Bandwidth of one PRB (Hz)
TTI = 1e-3;              % Slot duration (s)
cellRadius = 250;        % Cell radius (m)
noisePower = 1e-13;      % Noise power (W)
txPower = 20;            % 43 dBm ~ 20 W
numPRB = prbMode;        % Available PRBs per TTI
userSpeed = speedKmph / 3.6;  % Speed in m/s

if nargin < 8
    freqGHz = 1.9;       % default 1.9 GHz if not specified
end

% Initialization
positions = (rand(numUsers,1) * cellRadius).*exp(1j*2*pi*rand(numUsers,1));
angles = rand(numUsers,1) * 2*pi;
avgRate = zeros(numUsers,1);
rateHistory = zeros(numUsers,totalTime);
prbHistory = zeros(numUsers,totalTime);
selectedHistory = zeros(totalTime,1);
bitHistory = zeros(numUsers,totalTime);
cumBits = zeros(numUsers,totalTime);
cellBits = zeros(1,totalTime);

for t = 1:totalTime
    % Update user positions
    positions = positions + userSpeed*TTI.*exp(1j*angles);
    out = abs(positions) > cellRadius;
    angles(out) = mod(pi - angles(out), 2*pi);
    positions(out) = (2*cellRadius - abs(positions(out))).*exp(1j*angle(positions(out)));

    % Channel effects
    d = abs(positions);
    plLin = pathLossModel(d, freqGHz);
    shadow = 10.^(0.1*randn(numUsers,1));    % log-normal shadowing
    fading = (raylrnd(1,numUsers,1)).^2;     % Rayleigh power
    rxPower = txPower * plLin .* shadow .* fading;
    sinr = rxPower ./ noisePower;

    instRate = numPRB * PRB_BW * log2(1 + sinr); % bps

    % Scheduler
    switch schedulerType
        case 'basic'
            weight = instRate ./ max(avgRate,eps);
            [~,idx] = max(weight);
        case 'modified'
            weight = sqrt(instRate ./ max(avgRate,eps));
            [~,idx] = max(weight);
        case 'minrate'
            below = avgRate < minRate;
            if any(below)
                candidates = find(below);
                [~,k] = max(instRate(candidates));
                idx = candidates(k);
            else
                weight = instRate ./ max(avgRate,eps);
                [~,idx] = max(weight);
            end
        otherwise
            error('Unknown scheduler type');
    end

    selectedHistory(t) = idx;
    prbHistory(idx,t) = numPRB;
    rateHistory(:,t) = instRate;
    bitHistory(idx,t) = instRate(idx)*TTI;

    % Update averages
    avgRate = avgRate - avgRate/t_w;
    avgRate(idx) = avgRate(idx) + instRate(idx)/t_w;

    % Cumulative counters
    if t==1
        cumBits(:,t) = bitHistory(:,t);
        cellBits(t) = sum(bitHistory(:,t));
    else
        cumBits(:,t) = cumBits(:,t-1) + bitHistory(:,t);
        cellBits(t) = cellBits(t-1) + sum(bitHistory(:,t));
    end
end

throughput = sum(bitHistory,2) ./ (totalTime*TTI);
cellThroughput = sum(throughput);
fairness = (sum(throughput)^2) / (numUsers*sum(throughput.^2));

results.throughput = throughput;
results.cellThroughput = cellThroughput;
results.fairness = fairness;
results.selected = selectedHistory;
results.prb = prbHistory;
results.rate = rateHistory;
results.bits = bitHistory;
results.cumBits = cumBits;
results.cellBits = cellBits;
results.avgRate = avgRate;
end

function pl = pathLossModel(d, freqGHz)
%PATHLOSSMODEL Return linear path loss for distance d (m) at freqGHz.
% Uses Okumura-Hata for 850 MHz, COST231-HATA for 1.9 GHz (urban), and
% 3GPP TR38.901 UMa NLOS for other frequencies (e.g. 28 GHz).

h_bs = 30;       % base station height (m)
h_ms = 1.5;      % mobile height (m)

if abs(freqGHz - 0.85) < 0.1
    % Okumura-Hata @ 850 MHz
    fMHz = 850;
    a = (1.1*log10(fMHz) - 0.7)*h_ms - (1.56*log10(fMHz) - 0.8);
    pl_dB = 69.55 + 26.16*log10(fMHz) - 13.82*log10(h_bs) - a + ...
        (44.9 - 6.55*log10(h_bs))*log10(d/1000);
elseif abs(freqGHz - 1.9) < 0.1
    % COST231-HATA (urban) @ 1.9 GHz
    fMHz = 1900;
    a = (1.1*log10(fMHz) - 0.7)*h_ms - (1.56*log10(fMHz) - 0.8);
    pl_dB = 46.3 + 33.9*log10(fMHz) - 13.82*log10(h_bs) - a + ...
        (44.9 - 6.55*log10(h_bs))*log10(d/1000) + 3;
else
    % 3GPP TR38.901 UMa NLOS
    fc = freqGHz;
    pl_los = 28 + 22*log10(d) + 20*log10(fc);
    pl_nlos = 13.54 + 39.08*log10(d) + 20*log10(fc) - 0.6*(h_bs - 1.5);
    pl_dB = max(pl_los, pl_nlos);
end

pl = 10.^(-pl_dB/10);
end

