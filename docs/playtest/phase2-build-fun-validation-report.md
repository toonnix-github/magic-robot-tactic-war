# Phase 2 Build-Fun Validation Report

Evidence: deterministic automated simulation; this report does not grant phase sign-off.
Human playtest: pending. No human experience or visual readability judgment is claimed.

Reproduce: `godot --headless --path . -s res://tools/run_phase2_validation.gd`.
Mission: `ancient_ruins`; original sides; activation limit: 150; seeds: `[42, 101, 777, 1337, 9999]`.
Enemy configuration is the mission default. Each run starts fresh; both squads are recorded below.

Damage dealt counts direct attack HP loss (including Shield); later Burn ticks cannot be attributed to their source by the existing log and are excluded. Damage taken includes all logged HP loss, counting Burn once. Intercepts count Mira's redirects, not the whole team's. Disables count arm and shield destruction events that disabled equipped arm gear.

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

| Seed | Winner | Activations | Mira survived | Damage dealt | Damage taken | Mira intercepts | Disables |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 42 | enemy | 70 | false | 129 | 223 | 0 | 1 |
| 101 | player | 32 | true | 171 | 0 | 0 | 0 |
| 777 | player | 43 | true | 158 | 0 | 0 | 0 |
| 1337 | player | 47 | true | 155 | 74 | 0 | 0 |
| 9999 | player | 43 | true | 204 | 0 | 0 | 0 |

Wins: 4; losses: 1; unfinished: 0. Average activations: 47.0; median: 43.0; Mira survival: 80.0%; average direct damage: 163.4; average damage taken: 59.4; average Mira intercepts: 0.0; average disables: 0.2.

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

| Seed | Winner | Activations | Mira survived | Damage dealt | Damage taken | Mira intercepts | Disables |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 42 | player | 31 | true | 132 | 114 | 0 | 1 |
| 101 | player | 28 | true | 129 | 114 | 0 | 1 |
| 777 | player | 41 | true | 110 | 114 | 0 | 1 |
| 1337 | player | 36 | true | 141 | 92 | 0 | 1 |
| 9999 | player | 45 | true | 129 | 73 | 0 | 1 |

Wins: 5; losses: 0; unfinished: 0. Average activations: 36.2; median: 36.0; Mira survival: 100.0%; average direct damage: 128.2; average damage taken: 101.4; average Mira intercepts: 0.0; average disables: 1.0.

## mira_agile_rifle

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
    "mech": "Longview-Volt",
    "off_hand": "",
    "orbs": {
      "Right Arm": "fire_sr"
    },
    "parts": {
      "Body": "volt_body",
      "Head": "volt_head",
      "Left Arm": "volt_left_arm",
      "Legs": "sprinter_legs",
      "Right Arm": "volt_right_arm"
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

| Seed | Winner | Activations | Mira survived | Damage dealt | Damage taken | Mira intercepts | Disables |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 42 | player | 24 | true | 220 | 0 | 0 | 0 |
| 101 | player | 24 | true | 208 | 0 | 0 | 0 |
| 777 | player | 24 | true | 208 | 0 | 0 | 0 |
| 1337 | player | 20 | true | 174 | 0 | 0 | 0 |
| 9999 | player | 29 | true | 251 | 0 | 0 | 0 |

Wins: 5; losses: 0; unfinished: 0. Average activations: 24.2; median: 24.0; Mira survival: 100.0%; average direct damage: 212.2; average damage taken: 0.0; average Mira intercepts: 0.0; average disables: 0.0.

## mira_accuracy_rifle

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
    "mech": "Longview-Optics",
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

| Seed | Winner | Activations | Mira survived | Damage dealt | Damage taken | Mira intercepts | Disables |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 42 | enemy | 67 | false | 230 | 223 | 0 | 1 |
| 101 | player | 32 | true | 181 | 0 | 0 | 0 |
| 777 | player | 39 | true | 202 | 0 | 0 | 0 |
| 1337 | player | 36 | true | 202 | 42 | 0 | 0 |
| 9999 | player | 43 | true | 217 | 0 | 0 | 0 |

Wins: 4; losses: 1; unfinished: 0. Average activations: 43.4; median: 39.0; Mira survival: 80.0%; average direct damage: 206.4; average damage taken: 53.0; average Mira intercepts: 0.0; average disables: 0.2.

## mira_durable_sniper

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
    "mech": "Longview-Bulwark",
    "off_hand": "",
    "orbs": {
      "Right Arm": "water_r"
    },
    "parts": {
      "Body": "bulwark_body",
      "Head": "bulwark_head",
      "Left Arm": "bulwark_left_arm",
      "Legs": "bulwark_legs",
      "Right Arm": "bulwark_right_arm"
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

| Seed | Winner | Activations | Mira survived | Damage dealt | Damage taken | Mira intercepts | Disables |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 42 | enemy | 70 | false | 70 | 478 | 0 | 1 |
| 101 | player | 22 | true | 0 | 64 | 0 | 0 |
| 777 | enemy | 137 | false | 105 | 606 | 0 | 2 |
| 1337 | player | 20 | true | 35 | 64 | 0 | 0 |
| 9999 | enemy | 100 | false | 67 | 488 | 0 | 1 |

Wins: 2; losses: 3; unfinished: 0. Average activations: 69.8; median: 70.0; Mira survival: 40.0%; average direct damage: 55.4; average damage taken: 340.0; average Mira intercepts: 0.0; average disables: 0.8.

## mira_mobile_spear

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
    "mech": "Longview-Striker",
    "off_hand": "",
    "orbs": {
      "Right Arm": "fire_n"
    },
    "parts": {
      "Body": "volt_body",
      "Head": "volt_head",
      "Left Arm": "volt_left_arm",
      "Legs": "sprinter_legs",
      "Right Arm": "volt_right_arm"
    },
    "pilot": "mira",
    "unit_id": "mira",
    "weapon": "Spear"
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

| Seed | Winner | Activations | Mira survived | Damage dealt | Damage taken | Mira intercepts | Disables |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 42 | player | 38 | true | 189 | 38 | 0 | 0 |
| 101 | player | 21 | true | 123 | 0 | 0 | 0 |
| 777 | player | 46 | true | 171 | 0 | 0 | 0 |
| 1337 | player | 31 | true | 156 | 0 | 0 | 0 |
| 9999 | player | 44 | true | 209 | 0 | 0 | 0 |

Wins: 5; losses: 0; unfinished: 0. Average activations: 36.0; median: 38.0; Mira survival: 100.0%; average direct damage: 169.6; average damage taken: 7.6; average Mira intercepts: 0.0; average disables: 0.0.

## mira_heavy_spear

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
    "mech": "Longview-Phalanx",
    "off_hand": "",
    "orbs": {
      "Right Arm": "fire_sr"
    },
    "parts": {
      "Body": "bulwark_body",
      "Head": "aegis_head",
      "Left Arm": "aegis_left_arm",
      "Legs": "aegis_legs",
      "Right Arm": "bulwark_right_arm"
    },
    "pilot": "mira",
    "unit_id": "mira",
    "weapon": "Spear"
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

| Seed | Winner | Activations | Mira survived | Damage dealt | Damage taken | Mira intercepts | Disables |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 42 | player | 27 | true | 24 | 116 | 0 | 0 |
| 101 | player | 27 | true | 57 | 94 | 0 | 0 |
| 777 | player | 48 | true | 57 | 168 | 0 | 0 |
| 1337 | player | 21 | true | 0 | 116 | 0 | 0 |
| 9999 | player | 41 | true | 54 | 138 | 0 | 0 |

Wins: 5; losses: 0; unfinished: 0. Average activations: 32.8; median: 27.0; Mira survival: 100.0%; average direct damage: 38.4; average damage taken: 126.4; average Mira intercepts: 0.0; average disables: 0.0.

## mira_sword_shield

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
    "mech": "Longview-Brawler",
    "off_hand": "Shield",
    "orbs": {
      "Left Arm": "earth_ssr"
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
    "weapon": "Sword"
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

| Seed | Winner | Activations | Mira survived | Damage dealt | Damage taken | Mira intercepts | Disables |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 42 | player | 33 | true | 94 | 105 | 0 | 1 |
| 101 | player | 35 | true | 47 | 39 | 0 | 0 |
| 777 | player | 28 | true | 0 | 0 | 0 | 0 |
| 1337 | player | 38 | true | 94 | 72 | 0 | 0 |
| 9999 | player | 47 | true | 47 | 0 | 0 | 0 |

Wins: 5; losses: 0; unfinished: 0. Average activations: 36.2; median: 35.0; Mira survival: 100.0%; average direct damage: 56.4; average damage taken: 43.2; average Mira intercepts: 0.0; average disables: 0.2.

## Interpretation and Limits

The loadouts change range, durability, Orb effects and arm dependencies together. Differences in these runs cannot be attributed to any one choice. Sniper requires both arms and range planning; Rifle permits Shield in the left arm. These are rule-based tactical implications, not observed human decisions. This sample does not establish universal build superiority or prove that preparation is fun.

See [review](../phase2-build-your-mech-progress-review.md) and [human playtest](phase2-human-playtest.md) for verification status and the remaining product review.
