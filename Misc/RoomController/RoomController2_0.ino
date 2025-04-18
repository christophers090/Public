#include <Arduino.h>
#include <Wire.h>
#include "RTClib.h"
#include <FastLED.h>
#include <math.h>

/*Pin definitions*/
constexpr uint8_t LIGHT_BTN_PIN   = 13;
constexpr uint8_t TEA_BTN_PIN     = 12;
constexpr uint8_t FRIDGE_PIN      = 25;
constexpr uint8_t TEA_PIN         = 32;
constexpr uint8_t HEATER_PIN      = 33;
constexpr uint8_t SKY_BTN_PIN     = 34;
constexpr uint8_t POSTER_BTN_PIN  = 35;
constexpr uint8_t POSTER_PIN1     = 15;
constexpr uint8_t POSTER_PIN2     = 4;
constexpr uint8_t CLK_PIN         = 16;   // Rotary encoder CLK
constexpr uint8_t DT_PIN          = 17;   // Rotary encoder DT

/* PWM LED channels for main RGB light */
constexpr uint8_t RED_CH   = 0;
constexpr uint8_t GREEN_CH = 1;
constexpr uint8_t BLUE_CH  = 2;
constexpr uint8_t LED_PINS[]     = {14, 27, 26};   // R, G, B pins
constexpr uint8_t LED_CHANNELS[] = {RED_CH, GREEN_CH, BLUE_CH};

/*Misc constants*/
constexpr uint8_t  NUM_LEDS              = 58;
constexpr uint8_t  MAX_BRIGHTNESS        = 120;
constexpr uint8_t  MAX_POSTER_BRIGHTNESS = 100;
constexpr uint8_t  NUM_POSTER_MODES      = 6;
constexpr uint8_t  NUM_SKY_MODES         = 3;
constexpr uint16_t BOUNCE_DELAY_MS       = 50;
constexpr uint32_t MANUAL_TIMEOUT_MS     = 3600000UL;   // 1 h
constexpr uint32_t TEA_ON_MS             = 270000UL;     // 4.5 min
constexpr uint32_t PRESS_GAP_MS          = 200;

/* Helper macro for current millis */
#define NOW (static_cast<uint32_t>(millis()))

/*Device wrappers*/
class Relay {
  public:
    Relay(uint8_t pin, bool activeHigh = true)
      : _pin(pin), _activeHigh(activeHigh) {
      pinMode(_pin, OUTPUT);
      off();
    }

    void on()  { digitalWrite(_pin, _activeHigh); _state = true; }
    void off() { digitalWrite(_pin, !_activeHigh); _state = false; }
    void toggle() { _state ? off() : on(); }
    bool state() const { return _state; }

  private:
    uint8_t _pin;
    bool    _activeHigh;
    bool    _state {false};
};

class DebouncedButton {
  public:
    DebouncedButton(uint8_t pin, bool pullup = false)
      : _pin(pin) {
      pinMode(_pin, pullup ? INPUT_PULLUP : INPUT);
    }

    bool update() {
      bool reading = digitalRead(_pin);
      if (reading != _lastStableState && (NOW - _lastChange) > BOUNCE_DELAY_MS) {
        _lastStableState = reading;
        _lastChange      = NOW;
        if (_lastStableState) {  
          return true;
        }
      }
      return false;
    }

  private:
    uint8_t   _pin;
    bool      _lastStableState {false};
    uint32_t  _lastChange {0};
};

class RotaryEncoder {
  public:
    RotaryEncoder(uint8_t clk, uint8_t dt, int minVal, int maxVal, int startVal)
      : _clk(clk), _dt(dt), _minVal(minVal), _maxVal(maxVal), _value(startVal) {
      pinMode(_clk, INPUT);
      pinMode(_dt , INPUT);
      _lastState = digitalRead(_clk);
    }

    bool update() {
      bool currentState = digitalRead(_clk);
      if (currentState != _lastState) {
        if (digitalRead(_dt) != currentState) {
          ++_value;           // Clockwise
        } else {
          --_value;           // Counter‑clockwise
        }
        _value = constrain(_value, _minVal, _maxVal);
        _lastState = currentState;
        _lastChange = NOW;
        return true;
      }
      return false;
    }

    int value() const { return _value; }
    uint32_t lastChange() const { return _lastChange; }

  private:
    uint8_t   _clk, _dt;
    bool      _lastState;
    int       _minVal, _maxVal, _value;
    uint32_t  _lastChange {0};
};

class RGBPWM {
  public:
    RGBPWM(const uint8_t (&pins)[3], const uint8_t (&channels)[3]) {
      for (int i = 0; i < 3; ++i) {
        ledcSetup(channels[i], 5000, 8);   // 5 kHz, 8‑bit
        ledcAttachPin(pins[i], channels[i]);
      }
      memcpy(_channels, channels, 3);
    }

    void set(uint8_t r, uint8_t g, uint8_t b) {
      ledcWrite(_channels[0], r);
      ledcWrite(_channels[1], g);
      ledcWrite(_channels[2], b);
    }

    void off() { set(0, 0, 0); }

  private:
    uint8_t _channels[3];
};

class PosterLED {
  public:
    PosterLED() {
      FastLED.addLeds<WS2812B, POSTER_PIN1, RGB>(_strip1, NUM_LEDS);
      FastLED.addLeds<WS2812B, POSTER_PIN2, RGB>(_strip2, NUM_LEDS);
      FastLED.setCorrection(TypicalLEDStrip);
      FastLED.clear();
      FastLED.show();
    }

    void setBrightness(uint8_t b) { FastLED.setBrightness(b); }

    void update(uint8_t mode) {
      uint8_t base = beat8(10);
      switch (mode) {
        case 0:   
          FastLED.clear();
          break;

        case 1:  
          fill_rainbow(_strip1, NUM_LEDS, base, 7);
          fill_rainbow(_strip2, NUM_LEDS, base, 7);
          break;

      case 2:  
        {
          uint8_t alt = (base * 2) % 255;
          fill_rainbow(_strip1, NUM_LEDS, alt, 3);
          fill_rainbow(_strip2, NUM_LEDS, alt, 3);
          if (random8() < 255) {
            _strip1[random16(NUM_LEDS)] += CRGB::White;
            _strip2[random16(NUM_LEDS)] += CRGB::White;
          }
        }
          break;

        case 3:  
          fadeToBlackBy(_strip1, NUM_LEDS, 10);
          fadeToBlackBy(_strip2, NUM_LEDS, 10);
          _strip1[random16(NUM_LEDS)] += CHSV(base + random8(20), 200, 255);
          _strip2[random16(NUM_LEDS)] += CHSV(base + random8(64), 200, 255);
          break;

        case 4: 
        {
          fadeToBlackBy(_strip1, NUM_LEDS, 20);
          fadeToBlackBy(_strip2, NUM_LEDS, 20);
          uint8_t dotHue = 0;
          for (int i = 0; i < 5; ++i) {
            _strip1[beatsin16(i + 4, 0, NUM_LEDS - 1)] |= CHSV(dotHue, 200, 255);
            _strip2[beatsin16(i + 4, 0, NUM_LEDS - 1)] |= CHSV(dotHue, 200, 255);
            dotHue += 32;
          }
        }
          break;
      }
      FastLED.show();
    }

  private:
    CRGB _strip1[NUM_LEDS];
    CRGB _strip2[NUM_LEDS];
};

class RoomController {
  public:
    void begin() {
      Serial.begin(115200);
      rtc.begin();

      /* Instantiate devices */
      _fridge = new Relay(FRIDGE_PIN, true);  // Active‑HIGH relay
      _heater = new Relay(HEATER_PIN, true);
      _tea    = new Relay(TEA_PIN,   true);

      _rgb    = new RGBPWM(LED_PINS, LED_CHANNELS);
      _poster = new PosterLED();

      _btnLight  = new DebouncedButton(LIGHT_BTN_PIN);
      _btnTea    = new DebouncedButton(TEA_BTN_PIN);
      _btnPoster = new DebouncedButton(POSTER_BTN_PIN);
      _btnSky    = new DebouncedButton(SKY_BTN_PIN);

      _enc = new RotaryEncoder(CLK_PIN, DT_PIN, 1, 60, 1);

      _lightOn = true;
    }

    void update() {
      DateTime now = rtc.now();

      /* Handle user inputs */
      handleButtons();
      handleEncoder();
      handleTeaTimer();

      applySchedule(now.hour(), now.minute());

      _poster->setBrightness(_posterBrightness);
      _poster->update(_posterMode);
    }

  private:
    /* ----- Input handling ----- */
    void handleButtons() {
      if (_btnLight->update()) {
        _lightOn = !_lightOn;
        _lastLightPress = NOW;
      }

      if (_btnTea->update()) {
        _tea->toggle();
        _teaToggleTime = NOW;
      }

      if (_btnPoster->update()) {
        ++_posterMode;
        if (_posterMode >= NUM_POSTER_MODES) _posterMode = 0;
        _lastPosterPress = NOW;
      }

      if (_btnSky->update()) {
        ++_skyMode;
        if (_skyMode >= NUM_SKY_MODES) _skyMode = 0;
        _lastSkyPress = NOW;
      }
    }

    void handleEncoder() {
      if (_enc->update()) {
        _brightness = map(_enc->value(), 1, 60, 1, MAX_BRIGHTNESS);
        _manualBrightnessTime = NOW;
        _lastManualSet        = _brightness;
      }
    }

    void handleTeaTimer() {
      if (_tea->state() && (NOW - _teaToggleTime) > TEA_ON_MS) {
        _tea->off();
      }
    }


    void applySchedule(int hr, int minute) {
      switch (hr) {
        case 1:
        case 2:
        case 3:
          _fridgeOff();
          _heaterOff();
          setRGBIfLight(255, 0, 0);
          break;

        case 4:
          _fridgeOff();
          if (minute < 30) {
            setRGBIfLight(255, 0, 15);
          } else {
            int rise = minute - 30;

            if (NOW - _lastPosterPress > MANUAL_TIMEOUT_MS) {
              _posterMode = 1;
              _skyMode    = 1;
              _posterBrightness = map(minute, 30, 59, 0, MAX_POSTER_BRIGHTNESS);
              _brightness  = map(rise, 0, 29, 0, MAX_BRIGHTNESS);
            }

            if (NOW - _manualBrightnessTime > MANUAL_TIMEOUT_MS) {
              _brightness = map(rise, 0, 29, 0, MAX_BRIGHTNESS);
            }

            if (NOW - _lastLightPress > 36000UL) {
              _lightOn = true;
            }

            setRGBIfLight(255, rise * 2 * 140 / 60, rise * 100 / 60);

            if (rise == 25) {
              _tea->on();
              _teaToggleTime = NOW;
            }
            _heater->on();
          }
          break;

        case 5:
          _heater->on();
          break;

        case 6:
          _fridgeOff();
          _heaterOff();
          _posterBrightness = MAX_POSTER_BRIGHTNESS;
          setRGBIfLight(255, 200, 50);
          break;

        case 7: case 8: case 9: case 10: case 11:
        case 12: case 13: case 14: case 15: case 16:
        case 17: case 18:
          _fridgeOff();
          _heaterOff();
          _posterBrightness = MAX_POSTER_BRIGHTNESS;
          setRGBIfLight(255, 200, 50);
          break;

        case 19: {
          _fridgeOff();
          _heaterOff();
          if (NOW - _manualBrightnessTime > MANUAL_TIMEOUT_MS) {
            _brightness = _lastManualSet - ((_lastManualSet - 10) * minute / 60);
          }
          _posterBrightness = MAX_POSTER_BRIGHTNESS - ((MAX_POSTER_BRIGHTNESS - 10) * (minute / 60));

          setRGBIfLight(255,
              200 - (139 / 4.094 * log(minute + 1)),
              50  - (49  / 4.094 * log(minute + 1)));
        }
          break;

        case 20:
          _fridgeOff();
          _heaterOff();
          setRGBIfLight(255, 60, 0);
          break;

        case 21: {
          _fridgeOff();
          _heaterOff();

          if (minute == 59) {
            _skyMode = 0;
          }

          if (NOW - _manualBrightnessTime > MANUAL_TIMEOUT_MS) {
            _brightness = 10 - (10 * (minute / 60));
          }
          if (NOW - _lastPosterPress > MANUAL_TIMEOUT_MS && minute == 59) {
            _posterMode = 0;
          }
          _posterBrightness = 10 - (10 * (minute / 60));

          setRGBIfLight(255, 60 - (59 / 4.094 * log(minute + 1)), 0);
        }
          break;

        case 22:
        case 23:
        case 0:
          _fridge->on();      // HIGH disables fridge power
          _heaterOff();
          setRGBIfLight(255, 0, 0);
          break;
      }
    }

    /* ----- Helper wrappers ----- */
    void setRGBIfLight(uint8_t r, uint8_t g, uint8_t b) {
      if (_lightOn) {
        _rgb->set(r, g, b);
      } else {
        _rgb->off();
      }
    }

    void _fridgeOff() { _fridge->off(); }
    void _heaterOff() { _heater->off(); }

    RTC_DS3231 rtc;

    Relay * _fridge{nullptr};
    Relay * _heater{nullptr};
    Relay * _tea{nullptr};

    RGBPWM *   _rgb{nullptr};
    PosterLED* _poster{nullptr};

    DebouncedButton * _btnLight{nullptr};
    DebouncedButton * _btnTea{nullptr};
    DebouncedButton * _btnPoster{nullptr};
    DebouncedButton * _btnSky{nullptr};

    RotaryEncoder * _enc{nullptr};


    bool    _lightOn {true};
    uint8_t _posterMode {1};
    uint8_t _skyMode    {0};
    int     _brightness {MAX_BRIGHTNESS};
    int     _posterBrightness {MAX_POSTER_BRIGHTNESS};
    int     _lastManualSet {MAX_BRIGHTNESS};


    uint32_t _lastLightPress       {0};
    uint32_t _lastPosterPress      {0};
    uint32_t _lastSkyPress         {0};
    uint32_t _manualBrightnessTime {0};
    uint32_t _teaToggleTime        {0};
};

RoomController controller;


void setup() {
  controller.begin();
}

void loop() {
  controller.update();
}