#include <WiFi.h>
#include <WebServer.h>
#include <WebSocketsServer.h>
#define ESP32_VIRTUAL_DRIVER true //To enable virtual pin driver for esp32
#define ESP_VIRTUAL_DRIVER_8 1 //to use the 8:1 ratio
#define NBIS2SERIALPINS 6 //number of esp32 pins you will use. the total number of strips available will be NBIS2SERIALPINS * 8 here 56 strips
#define NUM_LEDS_PER_STRIP 155 //the length of your strip if you have different strips size put here the longuest strip
#include "FS.h"
#include "SD_MMC.h"
#define STATIC_COLOR_RGB 1
#define maxBrightness 120
#include "FastLED.h"
#define LATCH_PIN 13
#define CLOCK_PIN 27
#define NUM_STRIPS NBIS2SERIALPINS * 8
#define NUM_LEDS NUM_LEDS_PER_STRIP * NUM_STRIPS

#define MAX_MESSAGE_SIZE 1000 
char globalPayload[MAX_MESSAGE_SIZE];

uint8_t buffer[155 * 24 * 3];
bool grid[48][155];
int alphaGrid[50][157];

CRGB leds[NUM_LEDS];

CRGB color = CRGB(100, 59, 48);

double radius = 10, radius2 = 100, fade = 10, total = 20, total2 = 400;

int Pins[NBIS2SERIALPINS]={25, 33, 32, 18, 19, 23};

int r, g, b, val, X, Y;

int ledIndex;

int bpm = 10;
int hueDelta = 10;
int hueOffset = 5;

int skyMode = 0;
int frame = 0;
int lastFrame = 5;
bool video = false;
int frameLimit = 400;
long animationStart = 0;
bool isRelayActive = true;
bool play = false;


int fadeFactor = 1;

bool lineTool = true;
bool rainbowLine = false;
bool rainbowFill = false;
bool rainbowRefresh = false;
bool age = false;
bool flag = true;

long lastShow = 0;


const char* ssid = "NETGEAR34";
const char* password = "unusualearth531";

int brightness = 0; 

WebServer server(80);
WebSocketsServer webSocket = WebSocketsServer(8080);

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("D");
      Serial.printf("[%u] Disconnected!\n", num);
      break;
    case WStype_CONNECTED: {
      Serial.println("C");
      IPAddress ip = webSocket.remoteIP(num);
      Serial.printf("[%u] Connected from %d.%d.%d.%d url: %s\n", num, ip[0], ip[1], ip[2], ip[3], payload);
      // Send a welcome message
      webSocket.sendTXT(num, "Hello from ESP32");
      break;
    }
    case WStype_TEXT:
      Serial.printf("[%u] Received Text: %s\n", num, payload);
      strncpy(globalPayload, reinterpret_cast<const char*>(payload), MAX_MESSAGE_SIZE);
      globalPayload[MAX_MESSAGE_SIZE - 1] = '\0'; // Ensure null termination
      Text(globalPayload);
      memset(globalPayload, 0, MAX_MESSAGE_SIZE);
      break;
    case WStype_BIN:
    Binary(payload, length);
    break;
  }
}


void Binary(uint8_t* data, size_t length) {
    if (length == 4) {
      uint8_t X100 = data[0];
      uint8_t X10 = data[1];
      uint8_t Y100 = data[2];
      uint8_t Y10 = data[3];

      X = X100 * 100 + X10;
      Y = Y100 * 100 + Y10;   
      flag = true;     
    }

    unsigned long startTime = millis(); // Store start time

    if (lineTool) {
      paint();
    } else if (rainbowLine) {
      rainbowRefresh = true;
      paintRainbow();
    }

    unsigned long endTime = millis(); // Store end time

    // Calculate and print the duration
    Serial.print("Time taken: ");
    Serial.print(endTime - startTime);
    Serial.println(" ms");
}


void Index(int row, int col, int &index) {
  if (row > 40 && col > 26) {
    index = row * 155 + col - 27;
  } else if (row > 40) {
    index = 7439;
  } else {
    index = row * 155 + col;
  }
}

void Text(const char* text) {
    // Use strtok to split the string by newlines
    char* line = strtok(const_cast<char*>(text), "\n");

    while (line != NULL) {
        // Parse the line for led index and rgb values
        if (sscanf(line, "%d,%d,%d,%d", &ledIndex, &r, &g, &b)) {
            // Check if ledIndex is within the range
            if (ledIndex == 1) {
              fill_solid(leds, NUM_LEDS, CRGB::Black);
                for (int i = 0; i < 50; ++i){
                  for (int j = 0; j < 157; ++j){
                    alphaGrid[i][j] = 0;
                  }
                }
                for (int i = 0; i < 50; ++i){
                  for (int j = 0; j < 157; ++j){
                    grid[i][j] = false;
                  }
                }
                rainbowFill = false;
                flag = true;
            } else if (ledIndex == 2){
              fill_solid(leds, NUM_LEDS, CRGB(r,g,b));
                for (int i = 0; i < 50; ++i){
                  for (int j = 0; j < 157; ++j){
                    alphaGrid[i][j] = 0;
                  }
                }
                for (int i = 0; i < 50; ++i){
                  for (int j = 0; j < 157; ++j){
                    grid[i][j] = false;
                  }
                }
                flag = true;
            } else if (ledIndex == 3){
            } else if (ledIndex == 4){
            } else if (ledIndex == 5){
              uint8_t r2 = (uint8_t)r;
              uint8_t g2 = (uint8_t)g; 
              uint8_t b2 = (uint8_t)b; 
              color = CRGB(r2,g2,b2);
              for (int row = 0; row < 50; ++row){
                for (int col = 0; col < 157; ++col){
                  if (!grid[row][col]){
                    alphaGrid[row][col] = 0;
                  }
                }
              }
            } else if (ledIndex == 6){
              radius = r;
              radius2 = radius * radius;
              fade = g;
              total = radius + fade;
              total2 = total * total;
            } else if (ledIndex == 7){
               Life();
            } else if (ledIndex == 8){
              bpm = r;
              hueDelta = g;
              hueOffset = b;
            } else if (ledIndex == 9) {
              if (r == 1) {
                lineTool = true;
                rainbowLine = false;
                rainbowFill = false;
              } else if (r == 2) {
                rainbowLine = true;
                lineTool = false;
                rainbowFill = false;
              } else if (r == 3) {
                rainbowFill = true;
              }
            } else if (ledIndex == 10) {
              if(r == 1){
                age = true;
              } else {
                age = false;
              }
            } else if (ledIndex == 11) {
              fadeFactor = r;
            } else if (ledIndex == 12) {
              FastLED.setBrightness(r);
            } else if (ledIndex == 13) {
              skyMode = r;
              animationStart = millis();
              frame = 0;
              lastFrame = 5;
              frameLimit = g;
            } else if (ledIndex == 14) {
              if (r == 1) {
                video = true;
                Serial.println(" video set true");
              } else {
                video = false;
                play = false;
              }
            } else if (ledIndex == 15) {
              if (r == 1) {
                play = true;
                Serial.println(" play set true");
              } else {
                play = false;
              }
              if (play) {
                animationStart = millis() - (frame * 33.33333);
              }
            }
        }
        // Get the next line
        line = strtok(NULL, "\n");
    }
}


void Life() {

  for (int row = 0; row < 48; ++row) {
    for (int col = 0; col < 155; ++col){
      int index;
      Index(row, col, index);
      if (leds[index]) {
        grid[row][col] = 1;
      }
    }
  }

  calcalphaGrid();
  for (int row = 0; row < 48; ++row) {
    for (int col = 0; col < 155; ++col){
      int neighbors = alphaGrid[row + 1][col + 1];
      if ((neighbors < 2 || neighbors > 3) && grid[row][col] == 1) {
          grid[row][col] = false;
          int index;
          Index(row, col, index);
          leds[index] = CRGB::Black;
      } else if (neighbors == 3 && grid[row][col] == 0) {
          grid[row][col] = true;
          int index;
          Index(row, col, index);
          leds[index] = CRGB::White;
      }
    } 
  }
  
  for (int i = 0; i < 48; ++i){
    for (int j = 0; j < 155; ++j){
        grid[i][j] = false;
    }
  }
}


void calcalphaGrid() {
    // Initialize alphaGrid to zero
    for (int i = 0; i < 50; ++i){
        for (int j = 0; j < 157; ++j){
            alphaGrid[i][j] = 0;
        }
    }
    for (int row = 1; row < 49; ++row) {
        for (int col = 1; col < 156; ++col) {
            int cellVal = grid[row - 1][col - 1];
            for (int i = -1; i <= 1; ++i) {
                for (int j = -1; j <= 1; ++j) {
                    if (i == 0 && j == 0) {
                      continue;
                    } else {
                      alphaGrid[row + i][col + j] += cellVal;
                    }
                }
            }
        }
    }
}

void paint() {

  int centerX = X/8;
  int centerY = Y/10;
  int dist = (total/8 + 1);
  int colmin = max(0, centerX - dist);
  int colmax = min(154, centerX + dist);
  int rowmin = max(0, centerY -  dist);
  int rowmax = min(47, centerY + dist);

  for (int col = colmin; col < colmax + 1; ++col){
    int colPow = (X - (col * 8 + 4));
    colPow = colPow * colPow;
      for (int row = rowmin; row < rowmax + 1; ++row){
        if (alphaGrid[row][col] != 255 || grid[row][col]) {
          int rowPow = (Y - (row * 10 + 5));
          rowPow = rowPow * rowPow * 2.8;
          int distance2 = colPow + rowPow;
          if (distance2 < total2) {
            if (distance2 > radius2) {
              double alpha = (1 - (sqrt(distance2) - radius) / fade);
              alpha = alpha * alpha * 255;
              if (alphaGrid[row][col] < alpha || grid[row][col]){
                alphaGrid[row][col] = alpha;
                int index;
                Index(row, col, index);
                leds[index] = color;
                leds[index].nscale8(alpha);
                grid[row][col] = false;
              }
            } else {
              int index;
              Index(row, col, index);
              alphaGrid[row][col] = 255;
              leds[index] = color;
              grid[row][col] = false;
            }
          }
        }
      }
  }
}

void paintRainbow() {

  int centerX = X/8;
  int centerY = Y/10;
  int dist = (total/8 + 1);
  int colmin = max(0, centerX - dist);
  int colmax = min(154, centerX + dist);
  int rowmin = max(0, centerY -  dist);
  int rowmax = min(47, centerY + dist);

  for (int col = colmin; col < colmax + 1; ++col){
    int colPow = (X - (col * 8 + 4));
    colPow = colPow * colPow;
      for (int row = rowmin; row < rowmax + 1; ++row){
        if (alphaGrid[row][col] != 255 || !grid[row][col]) {
          int rowPow = (Y - (row * 10 + 5));
          rowPow = rowPow * rowPow * 2.8;
          int distance2 = colPow + rowPow;
          if (distance2 < total2) {
            if (distance2 > radius2) {
              double alpha = (1 - (sqrt(distance2) - radius) / fade);
              alpha = alpha * alpha * 255;
              if (alphaGrid[row][col] < alpha){
                alphaGrid[row][col] = alpha;
                grid[row][col] = true;
              }
            } else {
              alphaGrid[row][col] = 255;
              grid[row][col] = true;
            }
          }
        }
      }
  }
}

void refreshRainbow(int hueDelta, int hueOffset, uint8_t initialHue) {

  int count = 0;

  for (int col = 0; col < 155; ++col){
    for (int row = 0; row < 48; ++row){ 
      if (grid[row][col]) {
        count++;
        int alpha;
        alpha = alphaGrid[row][col];
        rainbow(row, col, hueDelta, hueOffset, initialHue, alpha);
      }
    }
  }

  if (count == 0){
    rainbowRefresh = false;
  }
}

void rainbow(int row, int col, int hueDelta, int hueOffset, uint8_t initialHue, int alpha) {
  uint8_t hue = (initialHue + (col * hueDelta)) + (row * hueOffset);
  int index;
  Index(row, col, index);
  leds[index] = CHSV(hue, 255, 255);
  if (alpha != 255){
  leds[index].nscale8(alpha);
  }
}

void videoUpdate(uint8_t* buffer, int start) {

  int byteIndex = 0;

    for(int strip = start; strip < start + 24; ++strip) {
      int bank = strip/8;
      bank = 5 - bank;
      int baseStrip = bank * 8;
      int stripIndent = strip % 8;
      int newStrip = stripIndent + baseStrip;
      int ledIndex = newStrip * 155;

      if(strip == 0){
          for(int i = 0; i < 155; i++) {
          leds[ledIndex].r = buffer[byteIndex++];
          leds[ledIndex].g = buffer[byteIndex++];
          leds[ledIndex].b = buffer[byteIndex++];
          ledIndex++;
      }
      }else if(strip < 8) {
        byteIndex += (27 * 3);
        for(int i = 0; i < (155 - 27); i++) {
          leds[ledIndex].r = buffer[byteIndex++];
          leds[ledIndex].g = buffer[byteIndex++];
          leds[ledIndex].b = buffer[byteIndex++];
          ledIndex++;
        }
        ledIndex += 27;  // Push forward by 27 LEDs
      } else {
        for(int i = 0; i < 155; i++) {
          leds[ledIndex].r = buffer[byteIndex++];
          leds[ledIndex].g = buffer[byteIndex++];
          leds[ledIndex].b = buffer[byteIndex++];
          ledIndex++;
        }
      }
    }
}

void setup() {

  Serial.begin(115200);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  webSocket.begin();
  webSocket.onEvent(webSocketEvent);

  server.begin();

  FastLED.addLeds<VIRTUAL_DRIVER,Pins,CLOCK_PIN, LATCH_PIN>(leds,NUM_LEDS_PER_STRIP);
  //FastLED.addLeds<VIRTUAL_DRIVER,Pins,CLOCK_PIN, LATCH_PIN,GRB>(leds,NUM_LEDS_PER_STRIP); //to set color order by default GRB
  FastLED.setBrightness(100);

  FastLED.setCorrection(TypicalLEDStrip);
  FastLED.setMaxPowerInVoltsAndMilliamps(12, 75000);

  if(!SD_MMC.begin("/sdcard",true)){
        Serial.println("Card Mount Failed");
        return;
  }

}

void loop() {
  webSocket.loop();

  if (!video) {
    uint8_t gHue = beat8(bpm, 255);
    if(millis() - lastShow > 25 && (flag || age || rainbowFill || rainbowRefresh)) {
      lastShow = millis();


      if (rainbowFill){
        for (int col = 0; col < 155; ++col){
          for (int row = 0; row < 48; ++row){ 
            int alpha = 255;
            rainbow(row, col, hueDelta, hueOffset, gHue, alpha);
          }
        }
      } else if (rainbowRefresh){
        refreshRainbow(hueDelta, hueOffset, gHue);
      }


      if (age) {
        for (int col = 0; col < 155; ++col) {
            for (int row = 0; row < 48; ++row) { 
              if (alphaGrid[row][col] != 0) {
                alphaGrid[row][col] = max(0, alphaGrid[row][col] - fadeFactor);
              }
              int index;
              Index(row, col, index);
              leds[index].fadeToBlackBy(fadeFactor);
            }
        }
      }
      FastLED.show();
      flag = false;
    }
  }

  if (video && play) {


    frame = (millis() - animationStart)/33.3333;

    if(frame != lastFrame && isRelayActive) {

      Serial.println("trying");

      lastShow = millis();

      if(frame == 12700) {
        frame = 0;
        animationStart = millis();
      } else if (frame == 0){
        animationStart = millis();
      }

      lastFrame = frame;

      char filePath[MAX_INPUT];

      int T = (frame / 10) % 10;
      int H = (frame / 100) % 10;
      int TH = (frame / 1000) % 10;
      int TTH = (frame / 10000) % 10;

      snprintf(filePath, sizeof(filePath), "/A%d/TTH%d/TH%d/H%d/T%d/F%d.bin", skyMode, TTH, TH, H, T, frame);

      File file = SD_MMC.open(filePath);

      size_t fileSize = file.size();

      const size_t splitSize = 155 * 24 * 3;

      file.read(buffer, splitSize);

      int ledIndex = 0;

      videoUpdate(buffer, 0);

      file.read(buffer, splitSize);

      ledIndex = 155 * 24;

      videoUpdate(buffer, 24);

      file.close();

      isRelayActive = false;
    }

    if(millis() - lastShow > 25) {
      FastLED.show();
      isRelayActive = true;
    }
  }


}

/*
Cool rainbowish effect
    if (age) {
      for (int col = 0; col < 155; ++col) {
          for (int row = 0; row < 48; ++row) { 
              if (alphaGrid[row][col] != 0) {
                  // Decrement the alpha value to simulate aging
                  alphaGrid[row][col] = max(0, alphaGrid[row][col] - fadeFactor);
                  int index;
                  Index(row, col, index);

                  leds[index].r = leds[index].r - fadeFactor;
                  leds[index].g = leds[index].g - fadeFactor;
                  leds[index].b = leds[index].b - fadeFactor;
              }
          }
      }
    }

*/






