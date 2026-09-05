# Phase 2 Build-Fun Validation Report

Evidence: deterministic automated simulation; this report does not grant phase sign-off.
Human playtest: pending. No human experience or visual readability judgment is claimed.

Reproduce: `godot --headless --path . -s res://tools/run_phase2_validation.gd`.
Mission: `ancient_ruins`; original sides; activation limit: 150; seeds: `[42, 101, 777, 1337, 9999]`.
Enemy configuration is the mission default. Each run starts fresh; both squads are recorded below.

Damage dealt counts direct attack HP loss (including Shield); later Burn ticks cannot be attributed to their source by the existing log and are excluded. Damage taken includes all logged HP loss, counting Burn once. Intercepts count Mira's redirects, not the whole team's.

## mira_precision_fragile

Exact squad configuration:
```json
{
  "arlen": {
    "mech": "Aegis-07",
    "off_hand": "",
    "orbs": {
      "Right Arm": "fire_n"
    },
    "parts": {
      "Body": "aegis_body",
      "Head": "aegis_head",
      "Left Arm": "aegis_left_arm",
      "Legs": "aegis_legs",
      "Right Arm": "aegis_right_arm"
    },
    "pilot": "arlen",
    "unit_id": "arlen",
    "weapon": "Spear"
  },
  "brann": {
    "mech": "Bulwark-04",
    "off_hand": "Shield",
    "orbs": {
      "Left Arm": "earth_ssr"
    },
    "parts": {
      "Body": "bulwark_body",
      "Head": "bulwark_head",
      "Left Arm": "bulwark_left_arm",
      "Legs": "bulwark_legs",
      "Right Arm": "bulwark_right_arm"
    },
    "pilot": "brann",
    "unit_id": "brann",
    "weapon": "Sword"
  },
  "mira": {
    "mech": "Longview-02",
    "off_hand": "",
    "orbs": {
      "Head": "lightning_r",
      "Right Arm": "water_r"
    },
    "parts": {
      "Body": "longview_body",
      "Head": "longview_head",
      "Left Arm": "longview_left_arm",
      "Legs": "longview_legs",
      "Right Arm": "longview_right_arm"
    },
    "pilot": "mira",
    "unit_id": "mira",
    "weapon": "Sniper"
  },
  "sera": {
    "mech": "Volt-13",
    "off_hand": "",
    "orbs": {
      "Right Arm": "fire_sr"
    },
    "parts": {
      "Body": "volt_body",
      "Head": "volt_head",
      "Left Arm": "volt_left_arm",
      "Legs": "volt_legs",
      "Right Arm": "volt_right_arm"
    },
    "pilot": "sera",
    "unit_id": "sera",
    "weapon": "Rifle"
  }
}
```

| Seed | Winner | Activations | Mira survived | Damage dealt | Damage taken | Mira intercepts |
| --- | --- | --- | --- | --- | --- | --- |
| 42 | player | 60 | true | 218 | 77 | 0 |
| 101 | player | 46 | true | 210 | 0 | 0 |
| 777 | player | 72 | true | 208 | 41 | 0 |
| 1337 | player | 21 | true | 105 | 0 | 0 |
| 9999 | player | 46 | true | 197 | 0 | 0 |

Wins: 5; losses: 0; unfinished: 0. Average activations: 49.0; Mira survival: 100.0%; average direct damage: 187.6; average damage taken: 23.6; average Mira intercepts: 0.0.

## mira_durable_shield

Exact squad configuration:
```json
{
  "arlen": {
    "mech": "Aegis-07",
    "off_hand": "",
    "orbs": {
      "Right Arm": "fire_n"
    },
    "parts": {
      "Body": "aegis_body",
      "Head": "aegis_head",
      "Left Arm": "aegis_left_arm",
      "Legs": "aegis_legs",
      "Right Arm": "aegis_right_arm"
    },
    "pilot": "arlen",
    "unit_id": "arlen",
    "weapon": "Spear"
  },
  "brann": {
    "mech": "Bulwark-04",
    "off_hand": "Shield",
    "orbs": {
      "Left Arm": "earth_ssr"
    },
    "parts": {
      "Body": "bulwark_body",
      "Head": "bulwark_head",
      "Left Arm": "bulwark_left_arm",
      "Legs": "bulwark_legs",
      "Right Arm": "bulwark_right_arm"
    },
    "pilot": "brann",
    "unit_id": "brann",
    "weapon": "Sword"
  },
  "mira": {
    "mech": "Longview-Custom",
    "off_hand": "Shield",
    "orbs": {
      "Right Arm": "fire_sr"
    },
    "parts": {
      "Body": "bulwark_body",
      "Head": "aegis_head",
      "Left Arm": "bulwark_left_arm",
      "Legs": "aegis_legs",
      "Right Arm": "aegis_right_arm"
    },
    "pilot": "mira",
    "unit_id": "mira",
    "weapon": "Rifle"
  },
  "sera": {
    "mech": "Volt-13",
    "off_hand": "",
    "orbs": {
      "Right Arm": "fire_sr"
    },
    "parts": {
      "Body": "volt_body",
      "Head": "volt_head",
      "Left Arm": "volt_left_arm",
      "Legs": "volt_legs",
      "Right Arm": "volt_right_arm"
    },
    "pilot": "sera",
    "unit_id": "sera",
    "weapon": "Rifle"
  }
}
```

| Seed | Winner | Activations | Mira survived | Damage dealt | Damage taken | Mira intercepts |
| --- | --- | --- | --- | --- | --- | --- |
| 42 | player | 44 | true | 187 | 60 | 0 |
| 101 | player | 60 | true | 312 | 65 | 0 |
| 777 | player | 41 | true | 217 | 60 | 0 |
| 1337 | player | 21 | true | 88 | 65 | 0 |
| 9999 | player | 38 | true | 209 | 60 | 0 |

Wins: 5; losses: 0; unfinished: 0. Average activations: 40.8; Mira survival: 100.0%; average direct damage: 202.6; average damage taken: 62.0; average Mira intercepts: 0.0.

## Interpretation and Limits

The loadouts change range, durability, Orb effects and arm dependencies together. Differences in these runs cannot be attributed to any one choice. Sniper requires both arms and range planning; Rifle permits Shield in the left arm. These are rule-based tactical implications, not observed human decisions. This sample does not establish universal build superiority or prove that preparation is fun.

See [review](../phase2-build-your-mech-progress-review.md) and [human playtest](phase2-human-playtest.md) for verification status and the remaining product review.
