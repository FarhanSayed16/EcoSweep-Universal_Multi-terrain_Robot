// First Motor Driver (Front Motors)
#define RPWM_1 6  
#define LPWM_1 7  
#define R_EN_1 8  
#define L_EN_1 9  

// Second Motor Driver (Rear Motors)
#define RPWM_2 10  
#define LPWM_2 11  
#define R_EN_2 12  
#define L_EN_2 13  

void setup() {
  // Set all motor driver pins as OUTPUT
  pinMode(RPWM_1, OUTPUT);
  pinMode(LPWM_1, OUTPUT);
  pinMode(R_EN_1, OUTPUT);
  pinMode(L_EN_1, OUTPUT);

  pinMode(RPWM_2, OUTPUT);
  pinMode(LPWM_2, OUTPUT);
  pinMode(R_EN_2, OUTPUT);
  pinMode(L_EN_2, OUTPUT);
  
  // Enable both motor drivers
  digitalWrite(R_EN_1, HIGH);  
  digitalWrite(L_EN_1, HIGH);
  digitalWrite(R_EN_2, HIGH);  
  digitalWrite(L_EN_2, HIGH);
}

void loop() {
  // Move Forward
  analogWrite(RPWM_1, 150);  
  analogWrite(LPWM_1, 0);    
  analogWrite(RPWM_2, 150);  
  analogWrite(LPWM_2, 0);  
  delay(2000);  

  // Stop
  stopMotors();
  delay(1000);  

  // Move Backward
  analogWrite(RPWM_1, 0);  
  analogWrite(LPWM_1, 150);  
  analogWrite(RPWM_2, 0);  
  analogWrite(LPWM_2, 150);  
  delay(2000);

  // Stop
  stopMotors();
  delay(1000);
}

// Function to Stop All Motors
void stopMotors() {
  analogWrite(RPWM_1, 0);
  analogWrite(LPWM_1, 0);
  analogWrite(RPWM_2, 0);
  analogWrite(LPWM_2, 0);
}
