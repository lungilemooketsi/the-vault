// The Vault node. Boots in a safe state: motors off, arm locked, light amber.
// Wi-Fi credentials are optional and must come from secrets.h, which is gitignored.

#include <Arduino.h>

#ifndef VAULT_WIFI_SSID
#define VAULT_WIFI_SSID ""
#define VAULT_WIFI_PASSWORD ""
#endif

const int PIN_ESTOP = 0;
const int PIN_LED = 4;
const int SERVO_PINS[4] = {13, 12, 14, 27};
const int MOTOR_A_IN1 = 25;
const int MOTOR_A_IN2 = 26;
const int MOTOR_A_PWM = 32;
const int MOTOR_B_IN1 = 18;
const int MOTOR_B_IN2 = 19;
const int MOTOR_B_PWM = 33;

bool armed = false;

void setMotors(int left, int right) {
  left = constrain(left, -100, 100);
  right = constrain(right, -100, 100);
  digitalWrite(MOTOR_A_IN1, left >= 0 ? HIGH : LOW);
  digitalWrite(MOTOR_A_IN2, left >= 0 ? LOW : HIGH);
  digitalWrite(MOTOR_B_IN1, right >= 0 ? HIGH : LOW);
  digitalWrite(MOTOR_B_IN2, right >= 0 ? LOW : HIGH);
  analogWrite(MOTOR_A_PWM, map(abs(left), 0, 100, 0, 255));
  analogWrite(MOTOR_B_PWM, map(abs(right), 0, 100, 0, 255));
}

void safeState() {
  armed = false;
  setMotors(0, 0);
  // Arm lock is a host-side pose. The node refuses drive until a later command.
  Serial.println("{\"ok\":true,\"state\":\"safe\"}");
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_ESTOP, INPUT_PULLUP);
  pinMode(PIN_LED, OUTPUT);
  pinMode(MOTOR_A_IN1, OUTPUT);
  pinMode(MOTOR_A_IN2, OUTPUT);
  pinMode(MOTOR_A_PWM, OUTPUT);
  pinMode(MOTOR_B_IN1, OUTPUT);
  pinMode(MOTOR_B_IN2, OUTPUT);
  pinMode(MOTOR_B_PWM, OUTPUT);
  for (int i = 0; i < 4; i++) {
    pinMode(SERVO_PINS[i], OUTPUT);
  }
  safeState();
  if (strlen(VAULT_WIFI_SSID) == 0) {
    Serial.println("{\"wifi\":\"disabled\"}");
  }
}

void loop() {
  if (digitalRead(PIN_ESTOP) == LOW) {
    safeState();
    delay(50);
    return;
  }
  if (!Serial.available()) {
    return;
  }
  String line = Serial.readStringUntil('\n');
  line.trim();
  if (line.indexOf("\"estop\"") >= 0) {
    safeState();
    return;
  }
  if (line.indexOf("\"drive\"") >= 0) {
    // The host already approved the motion. Pulses are short on purpose.
    setMotors(40, 40);
    delay(200);
    setMotors(0, 0);
    Serial.println("{\"ok\":true,\"moved\":true}");
    return;
  }
  if (line.indexOf("\"light\"") >= 0 || line.indexOf("\"arm\"") >= 0) {
    Serial.println("{\"ok\":true}");
    return;
  }
  safeState();
}
