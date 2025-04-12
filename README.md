# MultiTimeframe-Directional-Analysis-Indicator

## Overview
The Multi-Timeframe Directional Analysis Indicator is a powerful statistical tool for MetaTrader 5 that analyzes price direction patterns across multiple timeframes (M5, H1, D1, W1) to provide statistically validated directional bias prediction. Unlike conventional indicators that rely on lagging calculations, this indicator uses robust statistical methods to quantify the probability and confidence level of price movements.


![image](https://github.com/user-attachments/assets/8c60728c-4f33-4fa7-9d01-7789ce128d0f)

## Key Features

- **Statistical Directional Prediction**: Calculates precise probability values for price direction based on historical patterns at specific times
- **Multi-Timeframe Analysis**: Analyzes and integrates data from four separate timeframes (M5, H1, D1, W1)
- **Statistical Validation**: Uses binomial probability tests to verify that detected patterns are not random noise
- **Comprehensive Visual Display**: Shows individual timeframe probabilities, composite probability, and statistical confidence
- **Detailed Comments Display**: Provides precise numerical values for probabilities, p-values, and sample sizes
- **Timeframe Agreement Measurement**: Quantifies how many timeframes agree on direction
- **Automatic Signal Generation**: Generates clear signals when statistical confidence reaches threshold

## Understanding the Statistics

The indicator provides several key statistical metrics:

### Direction Probability (%)
Shows the probability of price moving in a specific direction. Values above 50% indicate an upward bias, while values below 50% indicate a downward bias. For example, 65% means there's a 65% probability of an upward move based on historical patterns.

### p-value (p)
The statistical significance of the directional bias. Lower values indicate stronger statistical evidence that the observed bias is not random chance. Generally:
- p < 0.01: Very strong evidence
- p < 0.05: Strong evidence
- p < 0.10: Moderate evidence
- p ≥ 0.10: Weak or insufficient evidence

### Sample Size (n)
The number of historical instances analyzed. Larger sample sizes provide more reliable statistics. Generally:
- n > 50: Excellent sample size
- n > 30: Good sample size
- n > 15: Adequate sample size
- n < 15: Limited reliability

### Statistical Confidence (%)
Calculated as (1 - p-value) × 100%. Represents the confidence level that the observed directional bias is not due to random chance.

### Timeframe Agreement (%)
Measures how many timeframes agree on the direction, expressed as a percentage. Higher agreement indicates stronger consensus across timeframes.

## Indicator Parameters

### Analysis Parameters
- **HistoryDays**: Number of days of historical data to analyze
- **SignalThreshold**: Threshold for generating directional signals (0.5-1.0)
- **StatConfThreshold**: Statistical confidence threshold
- **MinSampleSize**: Minimum sample size required for calculations
- **PValueThreshold**: P-value threshold for statistical significance

### Timeframe Weights
- **M5Weight**: Weight assigned to 5-minute timeframe (default: 0.15)
- **H1Weight**: Weight assigned to 1-hour timeframe (default: 0.25)
- **D1Weight**: Weight assigned to daily timeframe (default: 0.35)
- **W1Weight**: Weight assigned to weekly timeframe (default: 0.25)

### Visual Settings
- **CompositeProbColor**: Color for composite probability line
- **M5ProbColor**: Color for M5 probability line
- **H1ProbColor**: Color for H1 probability line
- **D1ProbColor**: Color for D1 probability line
- **W1ProbColor**: Color for W1 probability line

## How to Use

1. **Installation**: Copy the .mq5 file to your MetaTrader 5 indicators folder
2. **Apply to Chart**: Attach to any chart timeframe
3. **Interpret Results**: 
   - Check the composite probability and statistical confidence
   - Look for alignment between timeframes
   - Pay attention to the p-values to assess statistical reliability
   - Use the dynamic comments for detailed statistics

## Trading Applications

### Entry Signals
- Look for high statistical confidence (>90%) with strong directional bias
- Confirm with high timeframe agreement (>75%)
- Use when multiple timeframes show statistically significant bias in the same direction

### Exit Signals
- Watch for declining statistical confidence
- Monitor changes in directional bias
- Take notice when timeframe agreement begins to diverge

### Timeframe Harmony
Pay special attention when all timeframes align with statistically significant bias in the same direction. These "timeframe harmony" conditions often precede strong directional moves.

## Tips for Optimal Use

1. **Focus on Statistical Significance**: Always check the p-values to ensure patterns are not random
2. **Sample Size Matters**: Give more weight to signals with larger sample sizes
3. **Timeframe Agreement**: The best signals typically come when multiple timeframes agree
4. **Adjust Weights**: Consider increasing weights for timeframes that perform best for your specific instrument
5. **Combine with Price Action**: Use alongside support/resistance levels for optimal entry/exit points

## Creator

Copyright 2025, Christophe Manzi et al.

## Disclaimer

This indicator provides statistical analysis based on historical patterns. While it uses robust statistical methods, past performance is not indicative of future results. Always use proper risk management when trading.
