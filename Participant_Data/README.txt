# Participant Data Folder

This folder contains behavioural output data generated during stereoacuity testing sessions conducted using the Unity + MATLAB stereoacuity framework.

## Overview

The current system architecture consists of:

- **MATLAB**
  - Experimental controller
  - Trial sequencing
  - Trial condition generation
  - CSV data logging

- **Unity**
  - Stimulus presentation
  - Participant interaction
  - Response collection
  - Event timing and timestamps

Communication between MATLAB and Unity occurs via a TCP connection.

---

# File Naming Convention

Behavioural CSV files are automatically named using:

```text
participant_<ParticipantID>_tcp_trial_results_<Timestamp>.csv
```

Example:

```text
participant_P001_tcp_trial_results_20260518_140532.csv
```

---

# Participant IDs

Participant IDs should:

- be pseudonymised
- contain no directly identifiable information
- remain consistent across sessions where longitudinal tracking is required

Recommended format:

```text
P001
P002
P003
```

---

# Current Trial Structure

Each trial currently follows this sequence:

1. Unity displays general instructions
2. MATLAB sends trial information to Unity
3. Participant presses SPACE to begin
4. Stimulus is presented
5. Response panel appears
6. Participant selects perceived symbol
7. Unity sends trial completion data back to MATLAB
8. MATLAB writes trial data to CSV

---

# Current CSV Variables

| Variable | Description |
|---|---|
| participantId | Participant identifier entered at session start |
| trialId | Sequential trial number |
| value | Current placeholder stimulus value (to be replaced with disparity values in future versions) |
| targetSymbol | Correct symbol presented on the trial |
| response | Symbol selected by participant |
| accuracy | CORRECT or INCORRECT |
| rtSeconds | Response time recorded within Unity |
| unityStartTime | Unity elapsed time at stimulus onset (seconds since Play started) |
| unityResponseTime | Unity elapsed time at participant response |
| unityStartWallClock | Unity wall-clock timestamp at stimulus onset |
| unityResponseWallClock | Unity wall-clock timestamp at participant response |
| matlabSendTime | MATLAB wall-clock timestamp when trial trigger was sent |
| matlabReceiveTime | MATLAB wall-clock timestamp when trial completion message was received |

---

# Timing Notes

## Unity timestamps

Unity timestamps are currently considered the authoritative source for behavioural timing because:
- stimulus presentation occurs within Unity
- participant responses are collected within Unity
- Unity timing is frame-synchronous

## MATLAB timestamps

MATLAB timestamps are retained for:
- audit trail purposes
- TCP communication verification
- future synchronization debugging

MATLAB timestamps should not currently be interpreted as precise behavioural timing measurements.

---

# Future Planned Additions

Planned future additions include:

- true stereogram stimuli
- TAO/OpenOptotype integration
- adaptive staircase / QUEST threshold estimation
- VR controller interaction
- PICO eye-tracking synchronization
- fixation and gaze event markers
- session metadata files
- disparity-based stereo threshold estimation

---

# Data Management Notes

This repository currently stores:
- source code
- behavioural output CSV files

All participant data should remain:
- pseudonymised
- ethically approved
- stored in accordance with institutional data governance requirements

---

# Version Notes

Current project stage:

```text
v0.2 — Symbol-response stereoacuity prototype
```

Current implementation status:
- TCP communication functional
- trial sequencing functional
- timestamp logging functional
- clickable response UI functional
- correctness scoring functional
- stereogram pipeline not yet implemented