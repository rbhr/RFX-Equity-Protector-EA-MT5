# RFX Equity Protector EA - MT5

## Project Overview
This is a MetaTrader 5 Expert Advisor (EA) that monitors account equity and takes protective actions when drawdown limits are reached. It includes a modern dark-themed UI panel for real-time monitoring and one-click trading.

## Architecture

### Files
- **`RFX_Equity_Protector.mq5`** — Main EA file with all input parameters, loss detection logic, and protective actions
- **`RFX_Panel.mqh`** — Include file containing the `CRFXPanel` class for the on-chart UI panel

### Design Reference
This EA is inspired by "AW Equity Protection MT5 1.20" but with a modernized UI. The settings/inputs mirror that EA's structure. The panel replicates its functionality with a dark navy color scheme and improved visual design.

## Input Parameters Structure

### Main Settings
- Symbol filter: Current Symbol or All Symbols
- Magic number filter: All Magics or Specific (comma-separated list)

### Loss Settings
- Other EAs action at loss (Do nothing / Remove / Disable autotrading)
- Order action at loss (Do nothing / Close all / Close losing / Close profitable)
- Delete pending orders toggle
- Delete SL/TP levels toggle
- Money-based loss threshold (e.g. $500)
- Percent-based loss threshold (e.g. 25.5%)
- Pause after close action toggle

### Notifications
- Push notifications, Email, Alert toggles

### Panel Settings
- Show/hide panel, font size, magic number for panel orders, lot size

## Panel Features
- Dark navy theme with color-coded elements (green=buy/profit, red=sell/loss, yellow=warning)
- Drawdown color coding: green (<5%), yellow (5-10%), red (>10%)
- Minimize/expand toggle
- Start/Stop work button
- Real-time: order count, lots, profit per side, spread, drawdown %
- Close Buy / Close Sell buttons
- Adjustable lot size with +/- buttons and manual edit
- Buy/Sell market order buttons
- Top-right corner: balance and equity display

## Development Notes
- MQL5 language (C++-like, compiled in MetaEditor)
- Uses MT5 standard library includes: `Controls`, `Trade`
- Panel objects use `RFX_` prefix for namespacing
- All chart objects are cleaned up in `OnDeinit`
- Timer-based panel updates at 500ms interval

## Coding Conventions
- Global variables prefixed with `g_`
- Member variables prefixed with `m_`
- Input parameters prefixed with `inp_`
- Enums prefixed with `ENUM_`
- Color constants defined as `CLR_` macros
- Use `PrintFormat` with `[RFX]` tag for logging
