#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>

// Initialize PCA9685 Servo Driver
Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x40);

// Servo channel assignments
#define BASE_SERVO 0
#define ARM_SERVO 1
#define FOREARM_SERVO 2
#define WRIST_SERVO 3
#define GRIPPER_SERVO 4

// Servo min/max pulse values
#define SERVO_MIN 150
#define SERVO_MAX 600

// Ultrasonic Sensor Pins
#define FRONT_TRIG 22
#define FRONT_ECHO 23
#define BOTTOM_TRIG 24
#define BOTTOM_ECHO 25

// Servo Angles
int baseAngle = 90, armAngle = 90, forearmAngle = 90, wristAngle = 90, gripperAngle = 90;

// Movement Flags
bool baseLeftMoving = false, baseRightMoving = false;
bool armUpMoving = false, armDownMoving = false;
bool forearmForwardMoving = false, forearmBackwardMoving = false;
bool wristLeftMoving = false, wristRightMoving = false;
bool gripperOpenMoving = false, gripperCloseMoving = false;

// Obstacle Avoidance Mode
bool isAutoMode = false;

// Function to Move Servo Smoothly
void moveServo(int channel, int targetAngle) {
    pwm.setPWM(channel, 0, map(targetAngle, 0, 180, SERVO_MIN, SERVO_MAX));
}

// Function to Get Distance from Ultrasonic Sensor
long getDistance(int trigPin, int echoPin) {
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);
    long duration = pulseIn(echoPin, HIGH);
    return duration * 0.034 / 2;  // Convert to cm
}

void setup() {
    Serial.begin(115200);
    Serial1.begin(115200);

    pwm.begin();
    pwm.setPWMFreq(50);

    pinMode(FRONT_TRIG, OUTPUT);
    pinMode(FRONT_ECHO, INPUT);
    pinMode(BOTTOM_TRIG, OUTPUT);
    pinMode(BOTTOM_ECHO, INPUT);

    // Initialize Servo Positions
    moveServo(BASE_SERVO, baseAngle);
    moveServo(ARM_SERVO, armAngle);
    moveServo(FOREARM_SERVO, forearmAngle);
    moveServo(WRIST_SERVO, wristAngle);
    moveServo(GRIPPER_SERVO, gripperAngle);

    Serial.println("✅ Arduino Mega Ready. Waiting for commands...");
}

void loop() {
    // 🔹 Check for Incoming Commands
    if (Serial1.available()) {
        String command = Serial1.readStringUntil('\n');
        command.trim();
        Serial.print("📩 Received Command: ");
        Serial.println(command);

        // Handle Auto Mode
        if (command == "AUTO_ON") {
            isAutoMode = true;
            Serial.println("🚀 Auto Mode Activated!");
        } else if (command == "AUTO_OFF") {
            isAutoMode = false;
            Serial.println("🛑 Auto Mode Deactivated!");
        }

        // Base Movement
        else if (command == "BASE_LEFT_START") baseLeftMoving = true;
        else if (command == "BASE_LEFT_STOP") baseLeftMoving = false;
        else if (command == "BASE_RIGHT_START") baseRightMoving = true;
        else if (command == "BASE_RIGHT_STOP") baseRightMoving = false;

        // Arm Movement
        else if (command == "ARM_UP_START") armUpMoving = true;
        else if (command == "ARM_UP_STOP") armUpMoving = false;
        else if (command == "ARM_DOWN_START") armDownMoving = true;
        else if (command == "ARM_DOWN_STOP") armDownMoving = false;

        // Forearm Movement
        else if (command == "FOREARM_FORWARD_START") forearmForwardMoving = true;
        else if (command == "FOREARM_FORWARD_STOP") forearmForwardMoving = false;
        else if (command == "FOREARM_BACKWARD_START") forearmBackwardMoving = true;
        else if (command == "FOREARM_BACKWARD_STOP") forearmBackwardMoving = false;

        // Wrist Movement
        else if (command == "WRIST_ROTATE_LEFT_START") wristLeftMoving = true;
        else if (command == "WRIST_ROTATE_LEFT_STOP") wristLeftMoving = false;
        else if (command == "WRIST_ROTATE_RIGHT_START") wristRightMoving = true;
        else if (command == "WRIST_ROTATE_RIGHT_STOP") wristRightMoving = false;

        // Gripper Movement
        else if (command == "GRIP_OPEN_START") gripperOpenMoving = true;
        else if (command == "GRIP_OPEN_STOP") gripperOpenMoving = false;
        else if (command == "GRIP_CLOSE_START") gripperCloseMoving = true;
        else if (command == "GRIP_CLOSE_STOP") gripperCloseMoving = false;
    }

    // 🔹 Continuous Movement Logic
    if (baseLeftMoving && baseAngle > 0) { baseAngle -= 1; moveServo(BASE_SERVO, baseAngle); delay(20); }
    if (baseRightMoving && baseAngle < 180) { baseAngle += 1; moveServo(BASE_SERVO, baseAngle); delay(20); }

    if (armUpMoving && armAngle < 180) { armAngle += 1; moveServo(ARM_SERVO, armAngle); delay(20); }
    if (armDownMoving && armAngle > 0) { armAngle -= 1; moveServo(ARM_SERVO, armAngle); delay(20); }

    if (forearmForwardMoving && forearmAngle < 180) { forearmAngle += 1; moveServo(FOREARM_SERVO, forearmAngle); delay(20); }
    if (forearmBackwardMoving && forearmAngle > 0) { forearmAngle -= 1; moveServo(FOREARM_SERVO, forearmAngle); delay(20); }

    if (wristLeftMoving && wristAngle > 0) { wristAngle -= 1; moveServo(WRIST_SERVO, wristAngle); delay(20); }
    if (wristRightMoving && wristAngle < 180) { wristAngle += 1; moveServo(WRIST_SERVO, wristAngle); delay(20); }

    if (gripperOpenMoving && gripperAngle < 180) { gripperAngle += 1; moveServo(GRIPPER_SERVO, gripperAngle); delay(20); }
    if (gripperCloseMoving && gripperAngle > 0) { gripperAngle -= 1; moveServo(GRIPPER_SERVO, gripperAngle); delay(20); }

    // 🔹 Read Ultrasonic Sensor Data
    long frontDistance = getDistance(FRONT_TRIG, FRONT_ECHO);
    long bottomDistance = getDistance(BOTTOM_TRIG, BOTTOM_ECHO);
    Serial.print("Front: "); Serial.print(frontDistance); Serial.print(" cm | Bottom: "); Serial.println(bottomDistance);

    // 🚨 Send Data to ESP32
    Serial1.print("DIST:"); 
    Serial1.print(frontDistance);
    Serial1.print(",");
    Serial1.println(bottomDistance);

    delay(500);
}
