# Stereoacuity_Unity

Proof-of-concept project testing bidirectional communication between Unity and
MATLAB using [Lab Streaming Layer (LSL)](https://labstreaminglayer.org/).
Unity presents Random-Dot Stereogram (RDS) stereoacuity stimuli; MATLAB runs an
adaptive QUEST staircase that adjusts the disparity level trial-by-trial until
it converges on the observer's stereoacuity threshold.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                 MATLAB                          │
│                                                 │
│  QuestCreate ──► QuestQuantile ──► log10(disp)  │
│                                        │        │
│                  LSL outlet ◄──────────┘        │
│             "MATLABQuestDecisions" (1 ch)        │
└──────────────────────┬──────────────────────────┘
                       │  (log10 disparity)
                       ▼
┌─────────────────────────────────────────────────┐
│                  Unity                          │
│                                                 │
│  LSLManager ──► ExperimentController            │
│                        │                        │
│               StereoAcuityStimulus              │
│           (Random-Dot Stereogram at disparity)  │
│                        │                        │
│             Subject presses arrow key           │
│                        │                        │
│  LSL outlet ◄──────────┘                        │
│  "UnityTrialResults" (2 ch)                     │
│    ch0: log10(disparity shown)                  │
│    ch1: correct (1) / incorrect (0)             │
└──────────────────────┬──────────────────────────┘
                       │  (log10 disparity, correct)
                       ▼
┌─────────────────────────────────────────────────┐
│                 MATLAB                          │
│                                                 │
│  QuestUpdate ──► QuestMean ──► threshold        │
└─────────────────────────────────────────────────┘
```

### LSL Streams

| Stream | Direction | Channels | Content |
|--------|-----------|----------|---------|
| `MATLABQuestDecisions` | MATLAB → Unity | 1 | `log10(disparity_arcsec)` |
| `UnityTrialResults`    | Unity → MATLAB | 2 | `log10(disparity_arcsec)`, `correct` |

---

## Repository layout

```
Stereoacuity_Unity/
├── Assets/
│   ├── Plugins/
│   │   └── LSL/
│   │       ├── liblsl.cs       ← C# P/Invoke wrapper for liblsl
│   │       └── README.md       ← instructions for adding the native binary
│   └── Scripts/
│       ├── LSLManager.cs       ← manages LSL inlet + outlet in Unity
│       ├── StereoAcuityStimulus.cs  ← generates & renders RDS stimuli
│       └── ExperimentController.cs  ← trial-loop orchestrator
└── MATLAB/
    └── run_quest_lsl.m         ← QUEST adaptive staircase + LSL controller
```

---

## Prerequisites

### Unity side
1. **Unity 2021.3 LTS or later** (any render pipeline).
2. The **liblsl native binary** placed in `Assets/Plugins/LSL/` — see
   [`Assets/Plugins/LSL/README.md`](Assets/Plugins/LSL/README.md) for
   download and Inspector configuration instructions.

### MATLAB side
1. **MATLAB R2019b or later**.
2. The **[liblsl-Matlab toolbox](https://github.com/labstreaminglayer/liblsl-Matlab)**:
   ```matlab
   addpath(genpath('path/to/liblsl-Matlab'))
   ```
3. *(Optional)* **[Psychtoolbox-3](http://psychtoolbox.org/)** — if PTB is on
   the path, the script uses `QuestCreate` / `QuestUpdate` from PTB.
   Otherwise, a minimal QUEST implementation bundled inside
   `run_quest_lsl.m` is used automatically.

---

## Setup

### Unity scene
1. Open or create a Unity scene.
2. Add an **empty GameObject** (e.g. `ExperimentManager`) and attach:
   - `LSLManager`
   - `ExperimentController`
3. Add two **Quad** GameObjects (`LeftEyeQuad`, `RightEyeQuad`) as children,
   place them side by side to form a stereo pair.
4. Add `StereoAcuityStimulus` to the `ExperimentManager` object and wire up:
   - **Left Eye Renderer** → `LeftEyeQuad`'s MeshRenderer
   - **Right Eye Renderer** → `RightEyeQuad`'s MeshRenderer
5. Wire up the `ExperimentController`'s **Stimulus** field to the
   `StereoAcuityStimulus` component.
6. *(Optional)* Add a **UI Text** element and assign it to the
   `ExperimentController`'s **Status Text** field.

---

## Running an experiment

1. **Start Unity** — press Play in the Editor (or run the built application).
   Unity will log `[LSL] Outlet 'UnityTrialResults' created.` and then wait
   for MATLAB to connect.

2. **Start MATLAB** — in the MATLAB Command Window, run:
   ```matlab
   cd path/to/Stereoacuity_Unity/MATLAB
   run_quest_lsl
   ```
   MATLAB resolves Unity's stream, then the trial loop begins.

3. **During each trial**:
   - MATLAB sends the next disparity (log10 arcsec) to Unity.
   - Unity shows a fixation cross, then the RDS stimulus.
   - The observer presses an **arrow key** to indicate where the target
     appeared (Up / Right / Down / Left = top / right / bottom / left
     quadrant).
   - Unity sends the result back to MATLAB, which updates QUEST.

4. **After all trials**, MATLAB prints and plots:
   - The sequence of disparities tested.
   - The final QUEST posterior PDF.
   - The estimated stereoacuity threshold (arcseconds).

---

## Configuration

### Unity (`ExperimentController`)
| Parameter | Default | Description |
|-----------|---------|-------------|
| Max Trials | 50 | 0 = unlimited |
| Fixation Duration | 0.5 s | Pre-stimulus fixation |
| Response Timeout | 3.0 s | Max time for key press |
| Inter-Trial Interval | 0.5 s | Blank gap between trials |

### Unity (`StereoAcuityStimulus`)
| Parameter | Default | Description |
|-----------|---------|-------------|
| Viewing Distance | 57 cm | |
| Pixels Per Cm | 37.8 | Calibrate to your display |
| Field Size | 512 px | Total RDS area |
| Target Size | 128 px | Central disparate region |
| Dot Density | 0.25 | Fraction of field covered by dots |

### MATLAB (`run_quest_lsl.m` `cfg` struct)
| Parameter | Default | Description |
|-----------|---------|-------------|
| `numTrials` | 50 | Total adaptive trials |
| `tGuess` | log10(60) | Initial threshold guess (arcsec) |
| `tGuessSd` | 2.0 | SD of initial guess |
| `pThreshold` | 0.75 | Target proportion correct |
| `beta` | 3.5 | Psychometric function slope |
| `gamma` | 0.25 | Chance level (4AFC) |

---

## Stimulus details

The stereoacuity stimulus is a **4AFC Random-Dot Stereogram**:
- A field of randomly positioned dots is divided into a background (zero
  disparity) and a central target region.
- In the target region, dots are shifted horizontally by `±½ × disparityPx`
  between the left and right eye images (crossed disparity → target appears
  in front of the screen).
- The observer must indicate which of four quadrants the target occupies.
  Chance performance is 25 %.  QUEST assumes a Weibull psychometric function
  with γ = 0.25.

---

## References

- Watson, A. B. & Pelli, D. G. (1983). QUEST: A Bayesian adaptive
  psychometric method. *Perception & Psychophysics*, 33, 113–120.
- Julesz, B. (1971). *Foundations of Cyclopean Perception*. University of
  Chicago Press.
- Kothe, C. A. (2014). Lab Streaming Layer (LSL).
  https://github.com/sccn/liblsl
