#include <Wire.h>
#include "RTClib.h"
#include <FastLED.h>

RTC_DS3231 rtc;

#define lightButtonPin 13
#define teaButtonPin 12
#define fridgePin 25
#define teaPin 32
#define heaterPin 33
#define redChannel 0
#define greenChannel 1
#define blueChannel 2
#define skyButtonPin 34
#define posterButtonPin 35
#define maxBrightness 120
#define maxPosterBrightness 100
#define animationNum 2
#define numLEDs 58
#define posterPin1 15
#define posterPin2 4
#define clkPin 16  // CLK pin on the encoder
#define dtPin 17   // DT pin on the encoder
#define bounceDelay 50

CRGB leds1[numLEDs];
CRGB leds2[numLEDs];

// WS2815 - 220ns, 360ns, 220ns
template <uint8_t DATA_PIN, EOrder RGB_ORDER = RGB>
class WS2815Controller : public ClocklessController<DATA_PIN, C_NS(650), C_NS(1800), C_NS(650), RGB_ORDER> {};

template<uint8_t DATA_PIN, EOrder RGB_ORDER> class WS2815 : public WS2815Controller<DATA_PIN, RGB_ORDER> {};

long lastLightPressTime = 0;
long lastPosterPressTime = 0;
long posterBounce = 0;
long lightBounce = 0;
long teaBounce = 0;
long lastTeaPressTime = 0;
long lastSkyPressTime = 0;
long lastLightChange = 0;
long lastSkyChange = 0;
long lastManualBrightnessAdjust = 0;
long currentMillis = 0;
long lastPrint = 0;


bool lightRelayStatus = true; // Changed to boolean
bool teaRelayStatus = false;

bool lastLightButtonValue = false;
bool lightButtonValue = false;
bool lastPosterButtonValue = false;
bool posterButtonValue = false;
bool lastAnimationButtonValue = false;
bool animationButtonValue = false;
bool lastSkyButtonValue = false;
bool skyButtonValue = false;
bool teaButtonValue = false;
bool lastTeaButtonValue = false;

int hour;
int currentMinute;


const int ledPins[] = {14, 27, 26};  // GPIO pins
const int ledChannels[] = {0, 1, 2};  // Corresponding LEDC channels

int brightness = 0; 
int posterBrightness = 0;// Example value
int lastBrightness = 0; // Example value
int animationType = 0;
int lastAnimationType = 0;
int lastManualSet = 0;
int currentState;
int lastState;
int counter = 1;
int skyMode = 0;
int lastSkyMode = 0;
int posterType = 1;
int gHue = 0;


int colorArray2[] = {

50,111,88,
63,142,94,
87,146,115,
56,135,117,
38,137,114,
64,138,103,
40,139,122,
27,130,117,
38,116,103,
30,112,96,
13,108,100,
37,131,103,
46,152,89,
26,156,117,
54,140,100,
19,122,88,
18,111,76,
23,100,80,
2,77,98,
12,93,98,
11,116,118,
4,120,163,
1,128,182,
0,123,176,
3,145,189,
2,150,190,
0,175,204,
0,192,215,
0,203,223,
0,210,228,
10,212,229,
18,220,233,
22,222,234,
33,214,228,
21,214,228,
35,214,228,
33,215,228,
35,215,229,
53,220,230,
56,221,231,
43,216,229,
47,213,227,
39,220,234,
42,221,234,
45,215,231,
49,214,231,
52,216,232,
51,205,223,
51,195,216,
51,170,197,
51,154,187,
53,174,205,
52,153,195,
51,131,177,
50,130,176,
64,137,161,
69,134,123,
70,136,102,

};

int colorArray1[] = {

64,11,11,
62,10,10,
58,10,11,
55,10,11,
54,10,11,
54,10,12,
54,10,12,
53,11,11,
53,12,13,
57,15,16,
67,21,21,
88,29,28,
86,31,30,
106,39,38,
138,53,49,
122,51,48,
137,58,54,
136,59,57,
161,62,57,
177,92,88,
239,184,188,
252,179,168,
246,139,104,
246,176,165,
244,188,189,
243,188,190,
230,179,164,
201,165,147,
179,161,159,
159,158,168,
155,157,170,
150,156,170,
144,154,172,
138,153,172,
132,151,174,
125,150,175,
118,149,176,
112,148,178,
104,147,179,
96,145,182,
90,145,182,
86,145,187,
84,146,188,
77,145,190,
70,144,191,
65,144,193,
61,144,193,
97,145,180,
164,161,172,
218,179,183,
238,185,191,
235,184,190,
244,191,193,
234,181,185,
162,109,108,
192,121,114,
71,17,17,
61,8,8,


};




// Define a function to set the LEDs based on an array of integers
void setPosterLEDs(int posterBrightness, int posterType) {

  uint8_t gHue = beat8(10,255);   

  if (posterType == 1){

  for (int i = 0; i < numLEDs; i++) {

    leds1[i] = CRGB(colorArray1[3 * i], colorArray1[3 * i + 1], colorArray1[3 * i + 2]);
    leds2[i] = CRGB(colorArray2[3 * i], colorArray2[3 * i + 1], colorArray2[3 * i + 2]);
  }

  }else if(posterType == 2){

    fill_rainbow( leds1, numLEDs, gHue, 7);
    fill_rainbow( leds2, numLEDs, gHue, 7);

  }else if(posterType == 3){

    int newHue = (gHue * 2)%255;

    fill_rainbow( leds1, numLEDs, newHue, 3);
    fill_rainbow( leds2, numLEDs, newHue, 3);

    if( random8() < 255) {
    leds1[ random16(numLEDs) ] += CRGB::White;
    leds2[ random16(numLEDs) ] += CRGB::White;
    }
    
  }else if(posterType == 4){

  fadeToBlackBy( leds1, numLEDs, 10);
  int pos1 = random16(numLEDs);
  leds1[pos1] += CHSV( gHue + random8(20), 200, 255);
    fadeToBlackBy( leds2, numLEDs, 10);
  int pos2 = random16(numLEDs);
  leds2[pos2] += CHSV( gHue + random8(64), 200, 255);
    
  }else if(posterType == 5){

      fadeToBlackBy( leds1, numLEDs, 20);
  uint8_t dothue = 0;
  for( int i = 0; i < 5; i++) {
    leds1[beatsin16( i+4, 0, numLEDs-1 )] |= CHSV(dothue, 200, 255);
    dothue += 32;
  }

      fadeToBlackBy( leds2, numLEDs, 20);
  uint8_t dothue2 = 0;
  for( int i = 0; i < 5; i++) {
    leds2[beatsin16( i+4, 0, numLEDs-1 )] |= CHSV(dothue2, 200, 255);
    dothue2 += 32;
  }
    
  }else if(posterType == 0){

  fill_solid(leds1, numLEDs, CRGB::Black);
  fill_solid(leds2, numLEDs, CRGB::Black);
    
  }

  FastLED.setBrightness(posterBrightness);

  FastLED.show();

}


void setup() {

  rtc.begin();

  pinMode(lightButtonPin, INPUT);
  pinMode(skyButtonPin, INPUT);
  pinMode(teaButtonPin, INPUT);
  pinMode(posterButtonPin, INPUT);
  pinMode(clkPin, INPUT);
  pinMode(dtPin, INPUT);
  pinMode(teaPin, OUTPUT);
  pinMode(heaterPin, OUTPUT);
  pinMode(fridgePin, OUTPUT);

  currentState = digitalRead(clkPin);
  lastState = currentState;

  for(int i = 0; i < 3; i++){
    ledcSetup(ledChannels[i], 5000, 8);  // 5000 Hz, 8-bit resolution
    ledcAttachPin(ledPins[i], ledChannels[i]);
  }

  FastLED.addLeds<WS2812B, posterPin1, RGB>(leds1, numLEDs);
  FastLED.addLeds<WS2812B, posterPin2, RGB>(leds2, numLEDs);


  Serial.begin(115200);

  delay(1500);
  Serial.println(hour);
  
}




void loop() {


DateTime now = rtc.now();
hour = now.hour();
currentMinute = now.minute();
currentMillis = millis();

  // Serial.print(now.hour(), DEC);
  // Serial.print(':');
  // Serial.print(now.minute(), DEC);
  // Serial.print(':');
  // Serial.print(now.second(), DEC);
  // Serial.println();


skyButtonValue = digitalRead(skyButtonPin);
lightButtonValue = digitalRead(lightButtonPin);
teaButtonValue = digitalRead(teaButtonPin);
posterButtonValue = digitalRead(posterButtonPin);
currentState = digitalRead(clkPin);

  if (currentState != lastState) {
    if (digitalRead(dtPin) != currentState) {
      counter++;  // Clockwise rotation
    } else {
      counter--;  // Counterclockwise rotation
    }
    // Constrain and map counter to LED brightness
    counter = constrain(counter, 1, 60);

    brightness = map(counter, 1, 60, 1, maxBrightness);
    lastManualBrightnessAdjust = currentMillis;
    lastManualSet = brightness;
  }

  if (lightButtonValue && !lastLightButtonValue) {
      lightBounce = currentMillis;
  }

  if ((currentMillis - lightBounce) > bounceDelay && (currentMillis - lastLightPressTime) > 200 && lightButtonValue) {
      lightRelayStatus = !lightRelayStatus;
      lastLightPressTime = currentMillis;
  }
  lastLightButtonValue = lightButtonValue;


  if (posterButtonValue != lastPosterButtonValue) {
      posterBounce = currentMillis;
  }

  if ((currentMillis - posterBounce) > bounceDelay && (currentMillis - lastPosterPressTime) > 200 && posterButtonValue) {
      posterType++;
      if(posterType == 6){
        posterType = 0;
      }
      lastPosterPressTime = currentMillis;
  }

  lastPosterButtonValue = posterButtonValue;

  setPosterLEDs(posterBrightness, posterType);


  if (!skyButtonValue && lastSkyButtonValue) {
      skyMode++;
      if (skyMode == 3){
        skyMode = 0;
      }
      lastSkyPressTime = currentMillis;
  }
  lastSkyButtonValue = skyButtonValue;


  if (teaButtonValue && !lastTeaButtonValue) {
      teaBounce = currentMillis;
  }

  if ((currentMillis - teaBounce) > bounceDelay && teaButtonValue && (currentMillis - lastTeaPressTime) > 200) {
      teaRelayStatus = !teaRelayStatus;
      lastTeaPressTime = currentMillis;
  }
  lastTeaButtonValue = teaButtonValue;

  if (teaRelayStatus){
    digitalWrite(teaPin, HIGH);
    if((currentMillis - lastTeaPressTime) > 270000){
      teaRelayStatus = false;
    }
  } else {
    digitalWrite(teaPin, LOW);
  }


  switch (hour) {

  case 1:
  case 2:
  case 3:

   digitalWrite(fridgePin, LOW);
   digitalWrite(heaterPin, LOW);

    if (lightRelayStatus) {
        ledcWrite(redChannel, 255);
        ledcWrite(greenChannel, 0);
        ledcWrite(blueChannel, 0);
    }
    
    else {
        ledcWrite(redChannel, 0);
        ledcWrite(greenChannel, 0);
        ledcWrite(blueChannel, 0);
      }
  break;

  case 4:

     digitalWrite(fridgePin, LOW);

        if (currentMinute < 30) {

        if (lightRelayStatus) {
        ledcWrite(redChannel, 255);
        ledcWrite(greenChannel, 0);
        ledcWrite(blueChannel, 15);
          } else {
        ledcWrite(redChannel, 0);
        ledcWrite(greenChannel, 0);
        ledcWrite(blueChannel, 0);
         }
        }

    else if(currentMinute > 29){

    long rise = currentMinute - 30;

    if(currentMillis - lastPosterPressTime > 3600000){
      posterType = 1;
          skyMode = 1;
          brightness = (rise * 2 * maxBrightness/60);
          animationType = 1;
    }

    posterBrightness =  maxPosterBrightness * currentMinute/30;

            if(currentMillis - lastManualBrightnessAdjust > 3600000){
          brightness = maxBrightness * rise/30;
             }


          if (currentMillis - lastLightPressTime > 36000) {
              lightRelayStatus = true;
          }

        if (lightRelayStatus) {

        ledcWrite(redChannel, 255);
        ledcWrite(greenChannel, rise * 2 * 140 / 60);
        ledcWrite(blueChannel, rise * 100 / 60);
        } else {
        ledcWrite(redChannel, 0);
        ledcWrite(greenChannel, 0);
        ledcWrite(blueChannel, 0);
         }

        if(rise == 25){
          teaRelayStatus = true;
          lastTeaPressTime = currentMillis;
        }

        digitalWrite(heaterPin, HIGH);

      }
      
  break;

  case 5:
    digitalWrite(heaterPin, HIGH);
  break;


  case 6:

    digitalWrite(fridgePin, LOW);
    digitalWrite(heaterPin, LOW);
    posterBrightness = maxPosterBrightness;

    if (lightRelayStatus) {
      ledcWrite(redChannel, 255);
      ledcWrite(greenChannel, 200);
      ledcWrite(blueChannel, 50);
    } else {
        ledcWrite(redChannel, 0);
        ledcWrite(greenChannel, 0);
        ledcWrite(blueChannel, 0);
      }

    break;

  case 7:
  case 8:
  case 9:
  case 10:
  case 11:
  case 12:
  case 13:
  case 14:
  case 15:
  case 16:
  case 17:
  case 18:

     digitalWrite(fridgePin, LOW);
     digitalWrite(heaterPin, LOW);
    posterBrightness = maxPosterBrightness;

    if (lightRelayStatus) {
      ledcWrite(redChannel, 255);
      ledcWrite(greenChannel, 200);
      ledcWrite(blueChannel, 50);
    } else {
        ledcWrite(redChannel, 0);
        ledcWrite(greenChannel, 0);
        ledcWrite(blueChannel, 0);
      }


  break;


  case 19:

    digitalWrite(fridgePin, LOW);
    digitalWrite(heaterPin, LOW);

    if(currentMillis - lastManualBrightnessAdjust > 3600000){
      brightness = lastManualSet - ((lastManualSet - 10) * currentMinute/60);
    }

   posterBrightness = maxPosterBrightness - ((maxPosterBrightness - 10) * (currentMinute/60));

    if (lightRelayStatus) {
      ledcWrite(redChannel, 255);
      ledcWrite(greenChannel, 200 - (139 / 4.094 * log(currentMinute + 1)));
      ledcWrite(blueChannel, 50 - (49 / 4.094 * log(currentMinute + 1)));
    }    else {
        ledcWrite(redChannel, 0);
        ledcWrite(greenChannel, 0);
        ledcWrite(blueChannel, 0);
      }
     
    break; // Add break

  case 20:

     digitalWrite(fridgePin, LOW);
     digitalWrite(heaterPin, LOW);

    if (lightRelayStatus) {
      ledcWrite(redChannel, 255);
      ledcWrite(greenChannel, 60);
      ledcWrite(blueChannel, 0);

    }  else {
        ledcWrite(redChannel, 0);
        ledcWrite(greenChannel, 0);
        ledcWrite(blueChannel, 0);
      }
   
    break;


  case 21:

   digitalWrite(fridgePin, LOW);
   digitalWrite(heaterPin, LOW);

    if(currentMinute == 59){
        skyMode = 0;
    }

    if(currentMillis - lastManualBrightnessAdjust > 3600000){
      brightness = 10 - (10 * (currentMinute/60));
    }

    if(currentMillis - lastPosterPressTime > 3600000 && currentMinute == 59){
      posterType = 0;
    }

    posterBrightness = 10 - (10 * (currentMinute/60));


    if (lightRelayStatus) {
      ledcWrite(redChannel, 255);
      ledcWrite(greenChannel, 60 - (59 / 4.094 * log(currentMinute + 1)));
      ledcWrite(blueChannel, 0);

    }  else {
        ledcWrite(redChannel, 0);
        ledcWrite(greenChannel, 0);
        ledcWrite(blueChannel, 0);
    }

    break; // Add break


  case 22:
  case 23:
  case 0:

   digitalWrite(fridgePin, HIGH);
   digitalWrite(heaterPin, LOW);

    if (lightRelayStatus) {
        ledcWrite(redChannel, 255);
        ledcWrite(greenChannel, 0);
        ledcWrite(blueChannel, 0);
    }
    
    else {
        ledcWrite(redChannel, 0);
        ledcWrite(greenChannel, 0);
        ledcWrite(blueChannel, 0);
      }

  break;

}

if(brightness > maxBrightness ){
  brightness = maxBrightness;
}


if (lastBrightness != brightness || 
lastAnimationType != animationType || 
lastSkyMode != skyMode){
  //Serial.print(skyMode);
  //Serial.print(",");   
  //Serial.println(brightness);     
}



lastBrightness = brightness;
lastSkyMode = skyMode;


}
