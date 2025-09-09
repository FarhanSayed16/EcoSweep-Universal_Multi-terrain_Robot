// =================================================================
//      Step 1.2: Servo + DC Motor Sketch (with Auto-Stop)
// =================================================================

#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>

Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x40);

// --- PIN DEFINITIONS ---
#define L_RPWM 5
#define L_LPWM 6
#define R_RPWM 9
#define R_LPWM 10

// Servo Channels
#define BASE_SERVO 0
#define ARM_SERVO 1
#define FOREARM_SERVO 2
#define WRIST_SERVO 3
#define GRIPPER_SERVO 4

// --- GLOBAL VARIABLES ---
#define SERVO_MIN_PULSE 150
#define SERVO_MAX_PULSE 600
#define SERVO_FREQ 50
int baseAngle = 90, armAngle = 90, forearmAngle = 90, wristAngle = 90, gripperAngle = 90;

bool baseLeftMoving = false, baseRightMoving = false;
bool armUpMoving = false, armDownMoving = false;
bool forearmForwardMoving = false, forearmBackwardMoving = false;
bool wristLeftMoving = false, wristRightMoving = false;
bool gripperOpenMoving = false, gripperCloseMoving = false;

// --- NEW --- Timeout for safety stop
unsigned long lastCommandTime = 0;      // Stores the time of the last move command
const int COMMAND_TIMEOUT = 250;        // Timeout in milliseconds (1/4 second)

void setup() {
  Serial.begin(9600);
  Serial.println("Servo + Motor Test Initializing...");

  pinMode(L_RPWM, OUTPUT);
  pinMode(L_LPWM, OUTPUT);
  pinMode(R_RPWM, OUTPUT);
  pinMode(R_LPWM, OUTPUT);
  stopMotors();

  pwm.begin();
  pwm.setPWMFreq(SERVO_FREQ);
  moveServo(BASE_SERVO, baseAngle);
  moveServo(ARM_SERVO, armAngle);
  moveServo(FOREARM_SERVO, forearmAngle);
  moveServo(WRIST_SERVO, wristAngle);
  moveServo(GRIPPER_SERVO, gripperAngle);
  
  Serial.println("✅ Ready. Test arm and joystick.");
}

void loop() {
  handleCommands();
  
  // --- NEW --- Check for command timeout
  // If no move command has been received recently, stop the motors.
  if (millis() - lastCommandTime > COMMAND_TIMEOUT) {
    stopMotors();
  }

  runManualMode();
}

void handleCommands() {
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();

    // --- DC Motor Movement ---
    if (command == "FORWARD") {
      moveForward(200);
      lastCommandTime = millis(); // <-- NEW: Update timestamp
    } else if (command == "BACKWARD") {
      moveBackward(200);
      lastCommandTime = millis(); // <-- NEW: Update timestamp
    } else if (command == "LEFT") {
      turnLeft(180);
      lastCommandTime = millis(); // <-- NEW: Update timestamp
    } else if (command == "RIGHT") {
      turnRight(180);
      lastCommandTime = millis(); // <-- NEW: Update timestamp
    } else if (command == "STOP") {
      stopMotors();
    }
    
    // --- Servo Arm Movement ---
    else if (command == "BASE_LEFT_START") baseLeftMoving = true;
    else if (command == "BASE_LEFT_STOP") baseLeftMoving = false;
    else if (command == "BASE_RIGHT_START") baseRightMoving = true;
    else if (command == "BASE_RIGHT_STOP") baseRightMoving = false;
    else if (command == "ARM_UP_START") armUpMoving = true;
    else if (command == "ARM_UP_STOP") armUpMoving = false;
    else if (command == "ARM_DOWN_START") armDownMoving = true;
    else if (command == "ARM_DOWN_STOP") armDownMoving = false;
    else if (command == "FOREARM_FORWARD_START") forearmForwardMoving = true;
    else if (command == "FOREARM_FORWARD_STOP") forearmForwardMoving = false;
    else if (command == "FOREARM_BACKWARD_START") forearmBackwardMoving = true;
    else if (command == "FOREARM_BACKWARD_STOP") forearmBackwardMoving = false;
    else if (command == "WRIST_ROTATE_LEFT_START") wristLeftMoving = true;
    else if (command == "WRIST_ROTATE_LEFT_STOP") wristLeftMoving = false;
    else if (command == "WRIST_ROTATE_RIGHT_START") wristRightMoving = true;
    else if (command == "WRIST_ROTATE_RIGHT_STOP") wristRightMoving = false;
    else if (command == "GRIP_OPEN_START") gripperOpenMoving = true;
    else if (command == "GRIP_OPEN_STOP") gripperOpenMoving = false;
    else if (command == "GRIP_CLOSE_START") gripperCloseMoving = true;
    else if (command == "GRIP_CLOSE_STOP") gripperCloseMoving = false;
  }
}

void runManualMode() {
  if (baseLeftMoving && baseAngle > 0) { baseAngle--; moveServo(BASE_SERVO, baseAngle); }
  if (baseRightMoving && baseAngle < 180) { baseAngle++; moveServo(BASE_SERVO, baseAngle); }
  if (armUpMoving && armAngle > 0) { armAngle--; moveServo(ARM_SERVO, armAngle); }
  if (armDownMoving && armAngle < 180) { armAngle++; moveServo(ARM_SERVO, armAngle); }
  if (forearmForwardMoving && forearmAngle < 180) { forearmAngle++; moveServo(FOREARM_SERVO, forearmAngle); }
  if (forearmBackwardMoving && forearmAngle > 0) { forearmAngle--; moveServo(FOREARM_SERVO, forearmAngle); }
  if (wristLeftMoving && wristAngle > 0) { wristAngle--; moveServo(WRIST_SERVO, wristAngle); }
  if (wristRightMoving && wristAngle < 180) { wristAngle++; moveServo(WRIST_SERVO, wristAngle); }
  if (gripperOpenMoving && gripperAngle < 90) { gripperAngle++; moveServo(GRIPPER_SERVO, gripperAngle); }
  if (gripperCloseMoving && gripperAngle > 0) { gripperAngle--; moveServo(GRIPPER_SERVO, gripperAngle); }
  
  delay(15);
}

// --- No changes to the functions below ---

void moveServo(int channel, int angle) {
  angle = constrain(angle, 0, 180);
  int pulse = map(angle, 0, 180, SERVO_MIN_PULSE, SERVO_MAX_PULSE);
  pwm.setPWM(channel, 0, pulse);
}

void moveForward(int speed) {
  analogWrite(L_RPWM, speed);
  analogWrite(L_LPWM, 0);
  analogWrite(R_RPWM, speed);
  analogWrite(R_LPWM, 0);
}

void moveBackward(int speed) {
  analogWrite(L_RPWM, 0);
  analogWrite(L_LPWM, speed);
  analogWrite(R_RPWM, 0);
  analogWrite(R_LPWM, speed);
}

void turnLeft(int speed) {
  analogWrite(L_RPWM, 0);
  analogWrite(L_LPWM, speed);
  analogWrite(R_RPWM, speed);
  analogWrite(R_LPWM, 0);
}

void turnRight(int speed) {
  analogWrite(L_RPWM, speed);
  analogWrite(L_LPWM, 0);
  analogWrite(R_RPWM, 0);
  analogWrite(R_LPWM, speed);
}

void stopMotors() {
  analogWrite(L_RPWM, 0);
  analogWrite(L_LPWM, 0);
  analogWrite(R_RPWM, 0);
  analogWrite(R_LPWM, 0);
}