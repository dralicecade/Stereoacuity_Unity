# Unity–MATLAB LSL Message Schema

## MATLAB → Unity

### Trial start

Format:

```text
TRIAL_START,trial_id,disparity_arcsec
```

Example:

```text
TRIAL_START,1,40
```

---

## Unity → MATLAB

### Participant response

Format:

```text
RESPONSE,trial_id,response,rt_seconds
```

Example:

```text
RESPONSE,1,left,0.823
```