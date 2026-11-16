# Parts list (South Africa, ZAR)

Indicative retail prices checked on 16 November 2026. They are not a quote. The running prototype is the MATLAB floor; this is the build that replaces it. Low voltage only (5 V logic, 6 V servos, a small 2S pack or a 5 V supply for the arm). No mains, no connection to an ATM or a payment terminal.

The host laptop runs MATLAB and speaks newline-delimited JSON to three ESP32s. One ESP32 drives the arm and the counter light. Each robot has its own ESP32 and motor driver. See [firmware/README.md](../firmware/README.md).

| Qty | Part | Example source | Unit (ZAR) | Line (ZAR) |
| ---: | --- | --- | ---: | ---: |
| 3 | ESP32-WROOM-32 development board | Communica / Micro Robotics, typical R170–R250 | 199 | 597 |
| 4 | MG996R metal-gear servo (arm: base, shoulder, elbow, wrist) | Takealot / Communica, typical R90–R180 | 129 | 516 |
| 1 | PCA9685 16-channel servo driver | Typical module | 95 | 95 |
| 2 | 2WD acrylic robot chassis with TT motors, wheels, caster | Robofactory list price R165 on 16 Nov 2026 (sale price was R132) | 165 | 330 |
| 2 | TB6612FNG dual motor driver | Typical module | 85 | 170 |
| 2 | HC-SR04 ultrasonic sensor (optional obstacle sense) | Typical module | 35 | 70 |
| 1 | 5 V 5 A supply for the arm | Typical bench supply | 220 | 220 |
| 2 | 2S Li-ion pack or 4x AA holder plus cells, one per robot | Typical hobby cells | 140 | 280 |
| 1 | 1 m WS2812B strip for floor and counter lights | Typical strip | 160 | 160 |
| 1 | Breadboards, jumpers, USB cables, screws | Communica / local | 180 | 180 |
| 1 | Card-counter base and printed gold-bar props (plywood or acrylic) | Hardware store | 200 | 200 |

**Indicative total: R2,818.**

A single Acebott-style ESP32 robot kit (Robofactory listed the 4WD QD001 at R1,680) can replace one chassis plus an ESP32 if you would rather buy a kit than a bare frame. The arm stays four discrete servos so the joint model matches `vault.armFk`.

## Risks

- Servos and TT motors pinch and stall. The firmware boots with motors off and the arm locked. GPIO 0 is the e-stop (active low).
- Power the servos from the 5 V supply, not from the ESP32 3V3 pin.
- The MATLAB planner is the source of paths. The ESP32s do not decide to move money. A transfer still needs the on-screen `APPROVE`.
