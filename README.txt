# System Architecture

The current stereoacuity platform uses a MATLAB + Unity architecture.

## Design Philosophy

MATLAB is the experiment controller ("the brain").

Unity is the presentation and participant interaction engine.

The guiding principle is:

MATLAB decides WHAT happens.
Unity decides HOW it is shown.

---

# MATLAB Responsibilities

MATLAB is the primary controller of the experiment.

Current responsibilities:

- Participant ID entry
- Trial generation
- Symbol selection
- Stimulus generation
- Image file creation
- Experimental sequencing
- TCP communication initiation
- Behavioural data logging
- CSV output generation
- Future QUEST/staircase control
- Future threshold estimation

MATLAB determines:

- which symbol will be presented
- which disparity level will be presented
- which stimulus file should be shown
- when a trial begins
- when the experiment ends

MATLAB acts as the experimental "brain".

---

# Unity Responsibilities

Unity is responsible for presentation and participant interaction.

Current responsibilities:

- Display instructions
- Display stimulus images
- Display response options
- Collect participant responses
- Record response timing
- Provide participant feedback
- Communicate trial results back to MATLAB

Unity does NOT currently decide:

- which symbol is presented
- which disparity is presented
- trial order
- adaptive staircase behaviour

Unity therefore acts as the experimental "display and response engine".

---

# Communication Flow

Current communication sequence:

MATLAB
    ↓
Generate stimulus image
    ↓
Save PNG
    ↓
Send TCP trial message
    ↓
Unity

Unity
    ↓
Display stimulus
    ↓
Collect response
    ↓
Send response result
    ↓
MATLAB

MATLAB
    ↓
Update trial history
    ↓
Save CSV
    ↓
Generate next trial

---

# Current TCP Commands

MATLAB → Unity

TRIAL_START
    Starts a new trial

EXPERIMENT_END
    Indicates all trials have completed

Unity → MATLAB

TRIAL_READY
    Unity is waiting for participant start

TRIAL_STARTED
    Stimulus presentation has begun

TRIAL_COMPLETE
    Participant has responded

ERROR
    Trial could not be executed

---

# Current Stimulus Pipeline

Current pipeline:

TAO Symbol
    ↓
MATLAB
    ↓
Noise Carrier Generation
    ↓
PNG Creation
    ↓
Unity Display

Future pipeline:

TAO Symbol
    ↓
MATLAB
    ↓
Left Eye Image
Right Eye Image
    ↓
Disparity Manipulation
    ↓
Unity Stereo Presentation
    ↓
Participant Response

---

# Future Development Roadmap

Stage 1 (Current)
✓ TCP communication
✓ Dynamic stimulus loading
✓ Response grid
✓ Behavioural logging

Stage 2
□ Left-eye/right-eye image generation
□ Stereo image presentation

Stage 3
□ QUEST adaptive threshold estimation
□ Disparity calibration

Stage 4
□ PICO eye-tracking integration
□ Event markers
□ Gaze data synchronization

---

# Source of Truth

For all experimental decisions, MATLAB is currently considered the source of truth.

Unity should be viewed as a stimulus presentation and response collection client.

If MATLAB and Unity disagree, MATLAB is considered authoritative.