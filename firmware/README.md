# Firmware path

The slice runs in MATLAB. This sketch is the same command set the floor will speak when the parts in [docs/parts-list.md](../docs/parts-list.md) are on the bench.

Three ESP32 nodes share one serial protocol so a single host can fan the commands out later over Wi-Fi. Wi-Fi credentials are not in the sketch. Copy `secrets.example.h` to `secrets.h` (gitignored) only when you actually join a network. Until then the node listens on USB serial at 115200 and ignores the network.

## Command lines

One JSON object per line.

| Command | Body | Safe behaviour |
| --- | --- | --- |
| `estop` | `{}` | Motors off, arm locked, light amber |
| `light` | `{"target":"floor","color":"red"}` | `green`, `amber`, `red`, or `off` |
| `arm` | `{"pose":"lock"}` | `home`, `pick`, `place`, `lock` |
| `drive` | `{"left":40,"right":40,"ms":200}` | Clamped to -100..100, then motors off |

Unknown JSON is rejected and the node returns to the safe state.

## Pins (arm node)

| Function | GPIO |
| --- | --- |
| Servo base yaw | 13 |
| Servo shoulder | 12 |
| Servo elbow | 14 |
| Servo wrist | 27 |
| WS2812 data | 4 |
| E-stop (active low, internal pull-up) | 0 |

## Pins (each robot)

| Function | GPIO |
| --- | --- |
| Motor A IN1 / IN2 / PWM | 25 / 26 / 32 |
| Motor B IN1 / IN2 / PWM | 18 / 19 / 33 |
| E-stop | 0 |

The TB6612 STBY pin is held high only after a `drive` command and forced low on e-stop or boot.

```
Host (MATLAB) --USB serial--> ESP32 arm node --PCA9685--> 4 servos
                         \--> ESP32 robot A --> TB6612 --> TT motors
                         \--> ESP32 robot B --> TB6612 --> TT motors
```

Do not power servos from the ESP32 regulator. Do not connect any of this to a card terminal.
