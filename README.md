# CN MATLAB Assignment

This repository contains MATLAB scripts for a cellular network simulation used in the Computer Networks course (Module 2). The main entry point is `run_assignment.m` which demonstrates several schedulers and generates various plots required by the assignment.

## Files

- `simulateScheduler.m` – core function implementing a simple PFRS scheduler with options for modifications, minimum-rate enforcement, and selectable carrier frequency.
- `run_assignment.m` – example script that runs all required scenarios and produces the requested graphs. It includes a comparison across 850 MHz, 1.9 GHz and 28 GHz and generates the full graph set for each frequency. Additional plots compare the basic and modified schedulers, and the code now handles `t_w = 0` correctly.

## Usage

Open MATLAB in this directory and run:

```matlab
run run_assignment
```

The script will execute simulations for different configurations and display the graphs, including sets of plots for each carrier frequency.
