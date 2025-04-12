//+------------------------------------------------------------------+
//|                            MultiTimeframeDirectionalAnalysis.mq5 |
//|                                 Copyright 2025, Christophe Manzi |
//|                                    https://github.com/galileoChr |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Christophe Manzi"
#property link      "https://github.com/galileoChr"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 15
#property indicator_plots   11

// Plot indices
#define PLOT_COMPOSITE_PROB     0  // Composite probability
#define PLOT_M5_PROB            1  // M5 timeframe probability
#define PLOT_H1_PROB            2  // H1 timeframe probability
#define PLOT_D1_PROB            3  // D1 timeframe probability
#define PLOT_W1_PROB            4  // W1 timeframe probability
#define PLOT_STAT_CONF          5  // Statistical confidence
#define PLOT_UP_ARROW           6  // Up signal arrow
#define PLOT_DOWN_ARROW         7  // Down signal arrow
#define PLOT_AGREEMENT          8  // Timeframe agreement level
#define PLOT_SIGNIFICANCE       9  // Statistical significance
#define PLOT_MOMENTUM          10  // Cross-timeframe momentum

// Indicator buffers
double CompositeBuffer[];      // Composite probability
double M5ProbBuffer[];         // M5 timeframe probability
double H1ProbBuffer[];         // H1 timeframe probability
double D1ProbBuffer[];         // D1 timeframe probability
double W1ProbBuffer[];         // W1 timeframe probability
double StatConfBuffer[];       // Statistical confidence
double UpArrowBuffer[];        // Up signal arrow
double DownArrowBuffer[];      // Down signal arrow
double AgreementBuffer[];      // Timeframe agreement
double SignificanceBuffer[];   // Statistical significance
double MomentumBuffer[];       // Cross-timeframe momentum

// Service buffers (not plotted)
double M5DirectionBuffer[];    // Direction data for M5
double H1DirectionBuffer[];    // Direction data for H1
double D1DirectionBuffer[];    // Direction data for D1
double W1DirectionBuffer[];    // Direction data for W1

// Input parameters
input int    HistoryDays       = 30;      // Days of history to analyze
input double SignalThreshold   = 0.65;    // Signal threshold (0.5-1.0)
input double StatConfThreshold = 0.95;    // Statistical confidence threshold
input int    CommentRefreshBars = 1;      // Refresh dynamic comments every X bars

// Timeframe weights
input double M5Weight          = 0.15;    // M5 timeframe weight
input double H1Weight          = 0.25;    // H1 timeframe weight
input double D1Weight          = 0.35;    // D1 timeframe weight
input double W1Weight          = 0.25;    // W1 timeframe weight

// Visual settings
input color  CompositeProbColor = clrDodgerBlue;  // Composite probability color
input color  M5ProbColor       = clrAqua;         // M5 probability color
input color  H1ProbColor       = clrGreen;        // H1 probability color
input color  D1ProbColor       = clrBlue;         // D1 probability color
input color  W1ProbColor       = clrPurple;       // W1 probability color
input color  SignalTextColor   = clrWhite;        // Signal text color

// Statistical settings
input bool   ApplySignificanceFilter = true;   // Apply statistical significance filter
input double MinSampleSize     = 15;           // Minimum sample size for confidence calc
input double PValueThreshold   = 0.05;         // P-value threshold (statistical significance)

// Global variables
bool commentRefreshed;          // Flag to track comment refresh
int lastRefreshBar;             // Last bar where comment was refreshed
string indicatorComment;        // Current indicator comment

// Timeframe periods in minutes
const int TF_M5  = 5;           // 5-minute timeframe
const int TF_H1  = 60;          // 1-hour timeframe
const int TF_D1  = 1440;        // 1-day timeframe
const int TF_W1  = 10080;       // 1-week timeframe

// Data structures
struct TimeframeData
  {
   double            directionProb;        // Directional probability (>0.5 = up, <0.5 = down)
   double            significance;         // Statistical significance (p-value)
   double            sampleSize;           // Sample size
   double            confidenceInterval;   // 95% confidence interval
   string            bias;                 // Direction bias (UP, DOWN, NEUTRAL)
   bool              isRanging;              // Is market ranging in this timeframe
   double            momentum;             // Directional momentum
  };

TimeframeData m5Data, h1Data, d1Data, w1Data, compositeData;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
// Composite probability
   SetIndexBuffer(PLOT_COMPOSITE_PROB, CompositeBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(PLOT_COMPOSITE_PROB, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(PLOT_COMPOSITE_PROB, PLOT_LABEL, "Composite Probability");
   PlotIndexSetInteger(PLOT_COMPOSITE_PROB, PLOT_LINE_COLOR, CompositeProbColor);
   PlotIndexSetInteger(PLOT_COMPOSITE_PROB, PLOT_LINE_WIDTH, 3);

// M5 probability
   SetIndexBuffer(PLOT_M5_PROB, M5ProbBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(PLOT_M5_PROB, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(PLOT_M5_PROB, PLOT_LABEL, "M5 Probability");
   PlotIndexSetInteger(PLOT_M5_PROB, PLOT_LINE_COLOR, M5ProbColor);
   PlotIndexSetInteger(PLOT_M5_PROB, PLOT_LINE_WIDTH, 1);

// H1 probability
   SetIndexBuffer(PLOT_H1_PROB, H1ProbBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(PLOT_H1_PROB, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(PLOT_H1_PROB, PLOT_LABEL, "H1 Probability");
   PlotIndexSetInteger(PLOT_H1_PROB, PLOT_LINE_COLOR, H1ProbColor);
   PlotIndexSetInteger(PLOT_H1_PROB, PLOT_LINE_WIDTH, 1);

// D1 probability
   SetIndexBuffer(PLOT_D1_PROB, D1ProbBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(PLOT_D1_PROB, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(PLOT_D1_PROB, PLOT_LABEL, "D1 Probability");
   PlotIndexSetInteger(PLOT_D1_PROB, PLOT_LINE_COLOR, D1ProbColor);
   PlotIndexSetInteger(PLOT_D1_PROB, PLOT_LINE_WIDTH, 1);

// W1 probability
   SetIndexBuffer(PLOT_W1_PROB, W1ProbBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(PLOT_W1_PROB, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(PLOT_W1_PROB, PLOT_LABEL, "W1 Probability");
   PlotIndexSetInteger(PLOT_W1_PROB, PLOT_LINE_COLOR, W1ProbColor);
   PlotIndexSetInteger(PLOT_W1_PROB, PLOT_LINE_WIDTH, 1);

// Statistical confidence
   SetIndexBuffer(PLOT_STAT_CONF, StatConfBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(PLOT_STAT_CONF, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(PLOT_STAT_CONF, PLOT_LABEL, "Statistical Confidence");
   PlotIndexSetInteger(PLOT_STAT_CONF, PLOT_LINE_COLOR, clrOrange);
   PlotIndexSetInteger(PLOT_STAT_CONF, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(PLOT_STAT_CONF, PLOT_LINE_STYLE, STYLE_DOT);

// Up arrow signal
   SetIndexBuffer(PLOT_UP_ARROW, UpArrowBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(PLOT_UP_ARROW, PLOT_DRAW_TYPE, DRAW_ARROW);
   PlotIndexSetInteger(PLOT_UP_ARROW, PLOT_ARROW, 233); // Up arrow symbol
   PlotIndexSetString(PLOT_UP_ARROW, PLOT_LABEL, "Upward Signal");
   PlotIndexSetInteger(PLOT_UP_ARROW, PLOT_LINE_COLOR, clrLimeGreen);
   PlotIndexSetInteger(PLOT_UP_ARROW, PLOT_LINE_WIDTH, 2);

// Down arrow signal
   SetIndexBuffer(PLOT_DOWN_ARROW, DownArrowBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(PLOT_DOWN_ARROW, PLOT_DRAW_TYPE, DRAW_ARROW);
   PlotIndexSetInteger(PLOT_DOWN_ARROW, PLOT_ARROW, 234); // Down arrow symbol
   PlotIndexSetString(PLOT_DOWN_ARROW, PLOT_LABEL, "Downward Signal");
   PlotIndexSetInteger(PLOT_DOWN_ARROW, PLOT_LINE_COLOR, clrRed);
   PlotIndexSetInteger(PLOT_DOWN_ARROW, PLOT_LINE_WIDTH, 2);

// Agreement
   SetIndexBuffer(PLOT_AGREEMENT, AgreementBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(PLOT_AGREEMENT, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(PLOT_AGREEMENT, PLOT_LABEL, "Timeframe Agreement");
   PlotIndexSetInteger(PLOT_AGREEMENT, PLOT_LINE_COLOR, clrYellow);
   PlotIndexSetInteger(PLOT_AGREEMENT, PLOT_LINE_WIDTH, 1);

// Significance
   SetIndexBuffer(PLOT_SIGNIFICANCE, SignificanceBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(PLOT_SIGNIFICANCE, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(PLOT_SIGNIFICANCE, PLOT_LABEL, "Statistical Significance");
   PlotIndexSetInteger(PLOT_SIGNIFICANCE, PLOT_LINE_COLOR, clrMagenta);
   PlotIndexSetInteger(PLOT_SIGNIFICANCE, PLOT_LINE_WIDTH, 1);

// Momentum
   SetIndexBuffer(PLOT_MOMENTUM, MomentumBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(PLOT_MOMENTUM, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(PLOT_MOMENTUM, PLOT_LABEL, "Cross-TF Momentum");
   PlotIndexSetInteger(PLOT_MOMENTUM, PLOT_LINE_COLOR, clrSilver);
   PlotIndexSetInteger(PLOT_MOMENTUM, PLOT_LINE_WIDTH, 1);

// Service buffers
   SetIndexBuffer(11, M5DirectionBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(12, H1DirectionBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(13, D1DirectionBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(14, W1DirectionBuffer, INDICATOR_CALCULATIONS);

// Initialize comment tracking
   commentRefreshed = false;
   lastRefreshBar = 0;
   indicatorComment = "";

// Set indicator name
   IndicatorSetString(INDICATOR_SHORTNAME, "Multi-Timeframe Directional Analysis");

// Set indicator levels
   IndicatorSetInteger(INDICATOR_LEVELS, 3);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 0.5);            // Neutral level
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, SignalThreshold);  // Upper signal threshold
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, 1.0 - SignalThreshold); // Lower signal threshold

   IndicatorSetString(INDICATOR_LEVELTEXT, 0, "Neutral");
   IndicatorSetString(INDICATOR_LEVELTEXT, 1, "Bullish Signal");
   IndicatorSetString(INDICATOR_LEVELTEXT, 2, "Bearish Signal");

   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, clrGray);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 1, clrGreen);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 2, clrRed);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
// Check for minimum bars required
   if(rates_total < 20)
      return(0);

// Calculate start position - process fewer bars for better performance
   int start = prev_calculated - 1;
   if(start < 0)
      start = 0;

// Limit the number of bars to process for better performance
   int limit = MathMin(rates_total - 1, start + 20);

// Process bars with limited scope
   for(int i = MathMax(rates_total - 20, start); i <= limit; i++)
     {
      // Skip calculations on every tick to improve performance
      if(prev_calculated > 0 && i < rates_total - 1)
         continue;

      // Analyze each timeframe
      AnalyzeTimeframe(PERIOD_M5, time[i], i, close, rates_total, m5Data);
      AnalyzeTimeframe(PERIOD_H1, time[i], i, close, rates_total, h1Data);
      AnalyzeTimeframe(PERIOD_D1, time[i], i, close, rates_total, d1Data);
      AnalyzeTimeframe(PERIOD_W1, time[i], i, close, rates_total, w1Data);

      // Store directional data
      M5DirectionBuffer[i] = m5Data.directionProb;
      H1DirectionBuffer[i] = h1Data.directionProb;
      D1DirectionBuffer[i] = d1Data.directionProb;
      W1DirectionBuffer[i] = w1Data.directionProb;

      // Calculate and store composite probability
      CalculateCompositeData(compositeData);

      // Set buffer values
      CompositeBuffer[i] = compositeData.directionProb;
      M5ProbBuffer[i] = m5Data.directionProb;
      H1ProbBuffer[i] = h1Data.directionProb;
      D1ProbBuffer[i] = d1Data.directionProb;
      W1ProbBuffer[i] = w1Data.directionProb;

      // Calculate statistical confidence
      double statConf = 1.0 - compositeData.significance;
      StatConfBuffer[i] = statConf;

      // Calculate timeframe agreement
      double agreement = CalculateTimeframeAgreement();
      AgreementBuffer[i] = agreement;

      // Store significance value (1 - p-value)
      SignificanceBuffer[i] = 1.0 - compositeData.significance;

      // Calculate and store cross-timeframe momentum
      MomentumBuffer[i] = compositeData.momentum;

      // Generate signals
      UpArrowBuffer[i] = EMPTY_VALUE;
      DownArrowBuffer[i] = EMPTY_VALUE;

      // Only generate signal if statistically significant
      bool isSignificant = (compositeData.significance < PValueThreshold);

      if(isSignificant && compositeData.directionProb > SignalThreshold)
        {
         // Upward signal
         UpArrowBuffer[i] = 0.4; // Position in the indicator window
        }
      else
         if(isSignificant && compositeData.directionProb < (1.0 - SignalThreshold))
           {
            // Downward signal
            DownArrowBuffer[i] = 0.6; // Position in the indicator window
           }

      // Update dynamic comments (only for recent bars)
      if(i >= limit - CommentRefreshBars && !commentRefreshed)
        {
         UpdateDynamicComment(time[i]);
         commentRefreshed = true;
         lastRefreshBar = i;
        }
     }

// Fill in other bars with previous values to maintain visualization
   for(int i = start; i < MathMax(rates_total - 20, start); i++)
     {
      if(i > 0)
        {
         CompositeBuffer[i] = CompositeBuffer[i-1];
         M5ProbBuffer[i] = M5ProbBuffer[i-1];
         H1ProbBuffer[i] = H1ProbBuffer[i-1];
         D1ProbBuffer[i] = D1ProbBuffer[i-1];
         W1ProbBuffer[i] = W1ProbBuffer[i-1];
         StatConfBuffer[i] = StatConfBuffer[i-1];
         AgreementBuffer[i] = AgreementBuffer[i-1];
         SignificanceBuffer[i] = SignificanceBuffer[i-1];
         MomentumBuffer[i] = MomentumBuffer[i-1];
        }
     }

// Reset comment refresh flag when needed
   if(rates_total > lastRefreshBar + CommentRefreshBars)
     {
      commentRefreshed = false;
     }

// Return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Analyze a specific timeframe                                     |
//+------------------------------------------------------------------+
void AnalyzeTimeframe(ENUM_TIMEFRAMES timeframe,
                      datetime currentTime,
                      int currentIndex,
                      const double &price[],
                      int rates_total,
                      TimeframeData &data)
  {
// Get historical data for this timeframe
   MqlRates rates[];
   MqlDateTime time_struct;
   TimeToStruct(currentTime, time_struct);

// Adjust bars needed based on timeframe to avoid excessive data requests
   int bars_needed = 50;  // Default value

   if(timeframe == PERIOD_W1)
      bars_needed = 30;    // ~7 months of weekly data
   else
      if(timeframe == PERIOD_D1)
         bars_needed = 60;  // ~3 months of daily data
      else
         if(timeframe == PERIOD_H1)
            bars_needed = 120;  // 5 days of hourly data
         else
            if(timeframe == PERIOD_M5)
               bars_needed = 288;  // 1 day of 5-min data

// Copy rates for the timeframe
   int copied = CopyRates(Symbol(), timeframe, 1, bars_needed, rates);

   if(copied > 0)
     {
      // Variables for statistical analysis
      int upCount = 0;
      int totalCount = 0;
      double directionSum = 0;
      double momentumSum = 0;

      // Calculate time pattern matching based on timeframe
      bool timeMatch = false;

      // Simplify the time matching to improve performance
      for(int i = 0; i < copied - 1; i++)
        {
         // Calculate direction (1 for up, 0 for down)
         if(rates[i].close > rates[i+1].close)
           {
            upCount++;
           }

         // Calculate momentum (normalized price change)
         double momentum = (rates[i].close - rates[i+1].close) / rates[i+1].close;

         directionSum += (rates[i].close > rates[i+1].close) ? 1.0 : 0.0;
         momentumSum += momentum;
         totalCount++;
        }

      // Calculate probability statistics
      if(totalCount >= MinSampleSize)
        {
         // Direction probability (percentage of up moves)
         data.directionProb = upCount / (double)totalCount;

         // Sample size
         data.sampleSize = totalCount;

         // Calculate p-value using simplified method to improve performance
         double deviation = MathAbs(data.directionProb - 0.5);
         data.significance = MathExp(-10.0 * deviation * MathSqrt(totalCount));

         // Calculate 95% confidence interval
         double standardError = MathSqrt((data.directionProb * (1 - data.directionProb)) / totalCount);
         data.confidenceInterval = 1.96 * standardError;

         // Average momentum
         data.momentum = totalCount > 0 ? momentumSum / totalCount : 0;

         // Determine bias
         if(data.directionProb > 0.55 && data.significance < PValueThreshold)
           {
            data.bias = "UP";
            data.isRanging = false;
           }
         else
            if(data.directionProb < 0.45 && data.significance < PValueThreshold)
              {
               data.bias = "DOWN";
               data.isRanging = false;
              }
            else
              {
               data.bias = "NEUTRAL";
               data.isRanging = true;
              }
        }
      else
        {
         // Not enough data
         data.directionProb = 0.5;
         data.significance = 1.0;
         data.sampleSize = totalCount;
         data.confidenceInterval = 0;
         data.bias = "INSUFFICIENT DATA";
         data.isRanging = true;
         data.momentum = 0;
        }
     }
   else
     {
      // Error copying data
      data.directionProb = 0.5;
      data.significance = 1.0;
      data.sampleSize = 0;
      data.confidenceInterval = 0;
      data.bias = "ERROR";
      data.isRanging = true;
      data.momentum = 0;

      Print("Failed to copy data for timeframe: ", EnumToString(timeframe), ", Error: ", GetLastError());
     }
  }

//+------------------------------------------------------------------+
//| Calculate composite data from all timeframes                     |
//+------------------------------------------------------------------+
void CalculateCompositeData(TimeframeData &data)
  {
// Calculate weighted probability
   double weightedProb =
      M5Weight * m5Data.directionProb +
      H1Weight * h1Data.directionProb +
      D1Weight * d1Data.directionProb +
      W1Weight * w1Data.directionProb;

// Normalize weights (in case they don't sum to 1)
   double totalWeight = M5Weight + H1Weight + D1Weight + W1Weight;
   if(totalWeight > 0)
      weightedProb /= totalWeight;

// Store composite probability
   data.directionProb = weightedProb;

// Calculate combined significance (Fisher's method for combining p-values)
   double combinedStat = -2 * (
                            MathLog(MathMax(m5Data.significance, 0.00001)) +
                            MathLog(MathMax(h1Data.significance, 0.00001)) +
                            MathLog(MathMax(d1Data.significance, 0.00001)) +
                            MathLog(MathMax(w1Data.significance, 0.00001))
                         );

// Chi-square with 2k degrees of freedom (simplified approximation)
// Lower value = more significant
   data.significance = MathExp(-0.1 * combinedStat);

// Clamp to valid range
   data.significance = MathMax(MathMin(data.significance, 1.0), 0.0);

// Determine bias
   if(data.directionProb > 0.55 && data.significance < PValueThreshold)
     {
      data.bias = "UP";
      data.isRanging = false;
     }
   else
      if(data.directionProb < 0.45 && data.significance < PValueThreshold)
        {
         data.bias = "DOWN";
         data.isRanging = false;
        }
      else
        {
         data.bias = "NEUTRAL";
         data.isRanging = true;
        }

// Weighted momentum
   data.momentum =
      M5Weight * m5Data.momentum +
      H1Weight * h1Data.momentum +
      D1Weight * d1Data.momentum +
      W1Weight * w1Data.momentum;

   if(totalWeight > 0)
      data.momentum /= totalWeight;

// Calculate combined sample size
   data.sampleSize = m5Data.sampleSize + h1Data.sampleSize + d1Data.sampleSize + w1Data.sampleSize;

// Combined confidence interval (weighted average)
   data.confidenceInterval =
      (m5Data.confidenceInterval * m5Data.sampleSize +
       h1Data.confidenceInterval * h1Data.sampleSize +
       d1Data.confidenceInterval * d1Data.sampleSize +
       w1Data.confidenceInterval * w1Data.sampleSize) / MathMax(data.sampleSize, 1);
  }

//+------------------------------------------------------------------+
//| Calculate binomial p-value                                       |
//+------------------------------------------------------------------+
double CalculateBinomialPValue(int successes, int trials, double expectedProb)
  {
   if(trials == 0)
      return 1.0;

// Calculate observed probability
   double observedProb = successes / (double)trials;

// Calculate standard deviation of binomial distribution
   double stdDev = MathSqrt(expectedProb * (1 - expectedProb) / trials);

// Calculate z-score
   double zScore = MathAbs(observedProb - expectedProb) / stdDev;

// Approximate p-value from z-score (two-tailed test)
// Using a simplified approximation of the normal CDF
   double pValue = MathExp(-0.5 * zScore * zScore);

   return pValue;
  }

//+------------------------------------------------------------------+
//| Calculate agreement between timeframes                           |
//+------------------------------------------------------------------+
double CalculateTimeframeAgreement()
  {
// Count how many timeframes agree on direction
   int upCount = 0;
   int downCount = 0;

// Check M5
   if(m5Data.directionProb > 0.55)
      upCount++;
   else
      if(m5Data.directionProb < 0.45)
         downCount++;

// Check H1
   if(h1Data.directionProb > 0.55)
      upCount++;
   else
      if(h1Data.directionProb < 0.45)
         downCount++;

// Check D1
   if(d1Data.directionProb > 0.55)
      upCount++;
   else
      if(d1Data.directionProb < 0.45)
         downCount++;

// Check W1
   if(w1Data.directionProb > 0.55)
      upCount++;
   else
      if(w1Data.directionProb < 0.45)
         downCount++;

// Calculate maximum agreement
   int maxCount = MathMax(upCount, downCount);

// Return agreement as a percentage (0 to 1)
   return maxCount / 4.0;
  }

//+------------------------------------------------------------------+
//| Get minutes for timeframe                                        |
//+------------------------------------------------------------------+
int GetMinutesForTimeframe(ENUM_TIMEFRAMES timeframe)
  {
   switch(timeframe)
     {
      case PERIOD_M1:
         return 1;
      case PERIOD_M2:
         return 2;
      case PERIOD_M3:
         return 3;
      case PERIOD_M4:
         return 4;
      case PERIOD_M5:
         return 5;
      case PERIOD_M6:
         return 6;
      case PERIOD_M10:
         return 10;
      case PERIOD_M12:
         return 12;
      case PERIOD_M15:
         return 15;
      case PERIOD_M20:
         return 20;
      case PERIOD_M30:
         return 30;
      case PERIOD_H1:
         return 60;
      case PERIOD_H2:
         return 120;
      case PERIOD_H3:
         return 180;
      case PERIOD_H4:
         return 240;
      case PERIOD_H6:
         return 360;
      case PERIOD_H8:
         return 480;
      case PERIOD_H12:
         return 720;
      case PERIOD_D1:
         return 1440;
      case PERIOD_W1:
         return 10080;
      case PERIOD_MN1:
         return 43200;
      default:
         return 1;
     }
  }

//+------------------------------------------------------------------+
//| Update dynamic comment with current analysis                     |
//+------------------------------------------------------------------+
void UpdateDynamicComment(datetime currentTime)
  {
// Format time
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);

// Create header
   indicatorComment = "=== MULTI-TIMEFRAME DIRECTIONAL ANALYSIS ===\n\n";

// Add composite probability info
   string direction = "NEUTRAL";
   if(compositeData.directionProb > SignalThreshold)
      direction = "UP";
   else
      if(compositeData.directionProb < (1.0 - SignalThreshold))
         direction = "DOWN";

   double pctProb = (compositeData.directionProb > 0.5) ?
                    compositeData.directionProb * 100 :
                    (1 - compositeData.directionProb) * 100;

   indicatorComment += StringFormat("COMPOSITE BIAS: %s (%.1f%% probability)\n",
                                    direction,
                                    pctProb);

   double confidenceLevel = (1.0 - compositeData.significance) * 100;

   indicatorComment += StringFormat("STATISTICAL CONFIDENCE: %.1f%%\n",
                                    confidenceLevel);

   double agreementPct = CalculateTimeframeAgreement() * 100;

   indicatorComment += StringFormat("TIMEFRAME AGREEMENT: %.1f%%\n\n",
                                    agreementPct);

// Add individual timeframe data
   indicatorComment += "--- TIMEFRAME DETAILS ---\n";

// M5 data
   double m5PctProb = (m5Data.directionProb > 0.5) ?
                      m5Data.directionProb * 100 :
                      (1 - m5Data.directionProb) * 100;

   indicatorComment += StringFormat("M5: %s (%.1f%%, p=%.3f, n=%d)\n",
                                    m5Data.bias,
                                    m5PctProb,
                                    m5Data.significance,
                                    (int)m5Data.sampleSize);

// H1 data
   double h1PctProb = (h1Data.directionProb > 0.5) ?
                      h1Data.directionProb * 100 :
                      (1 - h1Data.directionProb) * 100;

   indicatorComment += StringFormat("H1: %s (%.1f%%, p=%.3f, n=%d)\n",
                                    h1Data.bias,
                                    h1PctProb,
                                    h1Data.significance,
                                    (int)h1Data.sampleSize);

// D1 data
   double d1PctProb = (d1Data.directionProb > 0.5) ?
                      d1Data.directionProb * 100 :
                      (1 - d1Data.directionProb) * 100;

   indicatorComment += StringFormat("D1: %s (%.1f%%, p=%.3f, n=%d)\n",
                                    d1Data.bias,
                                    d1PctProb,
                                    d1Data.significance,
                                    (int)d1Data.sampleSize);

// W1 data
   double w1PctProb = (w1Data.directionProb > 0.5) ?
                      w1Data.directionProb * 100 :
                      (1 - w1Data.directionProb) * 100;

   indicatorComment += StringFormat("W1: %s (%.1f%%, p=%.3f, n=%d)\n\n",
                                    w1Data.bias,
                                    w1PctProb,
                                    w1Data.significance,
                                    (int)w1Data.sampleSize);

// Add recommendation
   if(confidenceLevel >= 90 && agreementPct >= 75)
     {
      if(direction == "UP")
        {
         indicatorComment += "STRONG BUY SIGNAL: High confidence with timeframe alignment";
        }
      else
         if(direction == "DOWN")
           {
            indicatorComment += "STRONG SELL SIGNAL: High confidence with timeframe alignment";
           }
     }
   else
      if(confidenceLevel >= 70)
        {
         if(direction == "UP")
           {
            indicatorComment += "MODERATE BUY SIGNAL: Statistical validation of upward bias";
           }
         else
            if(direction == "DOWN")
              {
               indicatorComment += "MODERATE SELL SIGNAL: Statistical validation of downward bias";
              }
        }
      else
        {
         indicatorComment += "NO CLEAR SIGNAL: Insufficient statistical confidence";
        }

   Comment(indicatorComment);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment(""); // Clear comment
  }
