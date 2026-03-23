//+------------------------------------------------------------------+
//|                                        RFX_Equity_Protector.mq5  |
//|                              RFX Equity Protector EA for MT5     |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright   "RFX Trading"
#property link        ""
#property version     "1.00"
#property description "RFX Equity Protector - Equity protection utility for MetaTrader 5"
#property description "Monitors account equity and takes protective actions when drawdown limits are reached."

#include "RFX_Panel.mqh"
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_SYMBOL_MODE
{
   SYMBOL_CURRENT = 0,    // Current Symbol
   SYMBOL_ALL     = 1     // All Symbols
};

enum ENUM_MAGIC_MODE
{
   MAGIC_ALL      = 0,    // All Magics
   MAGIC_SPECIFIC = 1     // Specific Magics
};

enum ENUM_LOSS_EA_ACTION
{
   EA_ACTION_NOTHING    = 0, // Do nothing
   EA_ACTION_REMOVE     = 1, // Remove other EAs
   EA_ACTION_DISABLE    = 2  // Disable autotrading
};

enum ENUM_ORDER_ACTION
{
   ORDER_ACTION_NOTHING    = 0, // Do nothing
   ORDER_ACTION_CLOSE_ALL  = 1, // Close all positions
   ORDER_ACTION_CLOSE_LOSS = 2, // Close losing positions
   ORDER_ACTION_CLOSE_PROF = 3  // Close profitable positions
};

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
//--- Main Settings
input string   inp_main_sep          = "=========> MAIN SETTINGS <==========";        // =========> MAIN SETTINGS <==========
input ENUM_SYMBOL_MODE inp_symbol_mode = SYMBOL_CURRENT;                               // Symbols for calculation Loss and Profit
input ENUM_MAGIC_MODE  inp_magic_mode  = MAGIC_ALL;                                    // Magic mode for calculation Loss and Profit
input string   inp_magic_numbers      = "12345,54321,0";                               // MagicNumbers for work(sep by comma ",")

//--- Loss Settings
input string   inp_loss_sep          = "=========> LOSS SETTINGS <==========";         // =========> LOSS SETTINGS SETTINGS <==========
input ENUM_LOSS_EA_ACTION inp_ea_action_at_loss = EA_ACTION_NOTHING;                   // Other EAs Action At Loss
input ENUM_ORDER_ACTION   inp_order_action      = ORDER_ACTION_NOTHING;                // Action with Orders at Loss
input bool     inp_delete_pending     = false;                                         // Delete Pending Orders
input bool     inp_delete_sltp        = false;                                         // Delete StopLoss and TakeProfit levels
input bool     inp_use_loss_money     = false;                                         // Use Loss action in money
input double   inp_loss_money_vol     = 500.0;                                         // Volume of Loss action in money
input bool     inp_use_loss_percent   = false;                                         // Use Loss action in percents
input double   inp_loss_percent_vol   = 25.5;                                          // Volume of Loss action in percents
input bool     inp_pause_after_close  = true;                                          // Pause after close action

//--- Notifications Settings
input string   inp_notif_sep         = "=========> NOTIFICATIONS SETTINGS <=====";     // NOTIFICATIONS SETTINGS
input bool     inp_send_push         = false;                                          // Send push notifications at Loss action
input bool     inp_send_mail         = false;                                          // Send mails at Loss action
input bool     inp_send_alert        = false;                                          // Send alerts at Loss action

//--- Panel Settings
input string   inp_panel_sep         = "=========> PANEL SETTINGS <==========";        // =========> PANEL SETTINGS <==========
input bool     inp_show_panel        = true;                                           // Show panel of advisor
input int      inp_font_size         = 5;                                              // Font size in panels
input int      inp_magic_number      = 6866;                                           // Orders Magic number
input double   inp_order_lots        = 0.01;                                           // Order Lots for Panel

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
CRFXPanel      g_panel;
CTrade         g_trade;
CPositionInfo  g_position;
COrderInfo     g_order;

bool           g_is_paused = false;
long           g_magic_list[];
double         g_initial_balance = 0;
datetime       g_last_action_time = 0;

//+------------------------------------------------------------------+
//| Parse magic numbers from comma-separated string                  |
//+------------------------------------------------------------------+
void ParseMagicNumbers(string magic_str)
{
   string parts[];
   int count = StringSplit(magic_str, ',', parts);
   ArrayResize(g_magic_list, count);
   for(int i = 0; i < count; i++)
   {
      StringTrimLeft(parts[i]);
      StringTrimRight(parts[i]);
      g_magic_list[i] = StringToInteger(parts[i]);
   }
}

//+------------------------------------------------------------------+
//| Check if magic number matches filter                             |
//+------------------------------------------------------------------+
bool IsMagicAllowed(long magic)
{
   if(inp_magic_mode == MAGIC_ALL) return true;

   for(int i = 0; i < ArraySize(g_magic_list); i++)
   {
      if(g_magic_list[i] == magic) return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if symbol matches filter                                   |
//+------------------------------------------------------------------+
bool IsSymbolAllowed(string symbol)
{
   if(inp_symbol_mode == SYMBOL_ALL) return true;
   return (symbol == _Symbol);
}

//+------------------------------------------------------------------+
//| Calculate total profit/loss for filtered positions               |
//+------------------------------------------------------------------+
double CalculateTotalProfit()
{
   double total = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         if(!IsSymbolAllowed(g_position.Symbol())) continue;
         if(!IsMagicAllowed(g_position.Magic())) continue;
         total += g_position.Profit() + g_position.Swap() + g_position.Commission();
      }
   }
   return total;
}

//+------------------------------------------------------------------+
//| Check if loss threshold is reached                               |
//+------------------------------------------------------------------+
bool IsLossThresholdReached()
{
   double total_profit = CalculateTotalProfit();
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   // Check money-based loss
   if(inp_use_loss_money && total_profit < 0)
   {
      if(MathAbs(total_profit) >= inp_loss_money_vol)
         return true;
   }

   // Check percent-based loss
   if(inp_use_loss_percent && balance > 0 && total_profit < 0)
   {
      double loss_percent = (MathAbs(total_profit) / balance) * 100.0;
      if(loss_percent >= inp_loss_percent_vol)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Close positions based on action type                             |
//+------------------------------------------------------------------+
void ClosePositions(ENUM_ORDER_ACTION action)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_position.SelectByIndex(i)) continue;
      if(!IsSymbolAllowed(g_position.Symbol())) continue;
      if(!IsMagicAllowed(g_position.Magic())) continue;

      double profit = g_position.Profit() + g_position.Swap() + g_position.Commission();

      bool should_close = false;
      switch(action)
      {
         case ORDER_ACTION_CLOSE_ALL:
            should_close = true;
            break;
         case ORDER_ACTION_CLOSE_LOSS:
            should_close = (profit < 0);
            break;
         case ORDER_ACTION_CLOSE_PROF:
            should_close = (profit >= 0);
            break;
         default:
            break;
      }

      if(should_close)
      {
         if(!g_trade.PositionClose(g_position.Ticket()))
            PrintFormat("Failed to close position #%d: %s", g_position.Ticket(), g_trade.ResultComment());
      }
   }
}

//+------------------------------------------------------------------+
//| Delete pending orders                                            |
//+------------------------------------------------------------------+
void DeletePendingOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(g_order.SelectByIndex(i))
      {
         if(!IsSymbolAllowed(g_order.Symbol())) continue;
         if(!IsMagicAllowed(g_order.Magic())) continue;
         if(!g_trade.OrderDelete(g_order.Ticket()))
            PrintFormat("Failed to delete order #%d: %s", g_order.Ticket(), g_trade.ResultComment());
      }
   }
}

//+------------------------------------------------------------------+
//| Remove SL/TP from positions                                      |
//+------------------------------------------------------------------+
void RemoveStopLevels()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_position.SelectByIndex(i)) continue;
      if(!IsSymbolAllowed(g_position.Symbol())) continue;
      if(!IsMagicAllowed(g_position.Magic())) continue;

      if(g_position.StopLoss() != 0 || g_position.TakeProfit() != 0)
      {
         if(!g_trade.PositionModify(g_position.Ticket(), 0, 0))
            PrintFormat("Failed to remove SL/TP for position #%d: %s", g_position.Ticket(), g_trade.ResultComment());
      }
   }
}

//+------------------------------------------------------------------+
//| Send notifications                                               |
//+------------------------------------------------------------------+
void SendNotifications(string message)
{
   if(inp_send_push)
      SendNotification(message);

   if(inp_send_mail)
      SendMail("RFX Equity Protector Alert", message);

   if(inp_send_alert)
      Alert(message);
}

//+------------------------------------------------------------------+
//| Execute loss protection actions                                  |
//+------------------------------------------------------------------+
void ExecuteLossProtection()
{
   string msg = StringFormat("RFX Equity Protector: Loss threshold reached on %s. Balance: %.2f, Equity: %.2f",
                             _Symbol,
                             AccountInfoDouble(ACCOUNT_BALANCE),
                             AccountInfoDouble(ACCOUNT_EQUITY));

   PrintFormat("[RFX] %s", msg);

   // Send notifications
   SendNotifications(msg);

   // Close positions based on action setting
   if(inp_order_action != ORDER_ACTION_NOTHING)
      ClosePositions(inp_order_action);

   // Delete pending orders if enabled
   if(inp_delete_pending)
      DeletePendingOrders();

   // Remove SL/TP if enabled
   if(inp_delete_sltp)
      RemoveStopLevels();

   // Handle other EAs action
   if(inp_ea_action_at_loss == EA_ACTION_DISABLE)
   {
      // Disable autotrading via terminal
      // Note: MQL5 cannot directly disable other EAs, but we can log it
      Print("[RFX] Autotrading disable requested - please disable manually or use terminal settings");
   }

   // Record action time
   g_last_action_time = TimeCurrent();

   // Pause if enabled
   if(inp_pause_after_close)
   {
      g_is_paused = true;
      g_panel.SetWorking(false);
      Print("[RFX] Utility paused after loss protection action");
   }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Parse magic numbers
   ParseMagicNumbers(inp_magic_numbers);

   // Set magic number for trade operations
   g_trade.SetExpertMagicNumber(inp_magic_number);

   // Record initial balance
   g_initial_balance = AccountInfoDouble(ACCOUNT_BALANCE);

   // Create panel
   if(!g_panel.Create(inp_show_panel, inp_font_size, inp_magic_number, inp_order_lots))
   {
      Print("[RFX] Failed to create panel");
      return INIT_FAILED;
   }

   // Set timer for panel updates
   EventSetMillisecondTimer(500);

   Print("[RFX] RFX Equity Protector initialized successfully");
   PrintFormat("[RFX] Symbol mode: %s | Magic mode: %s",
               EnumToString(inp_symbol_mode), EnumToString(inp_magic_mode));

   if(inp_use_loss_money)
      PrintFormat("[RFX] Money loss threshold: %.2f", inp_loss_money_vol);
   if(inp_use_loss_percent)
      PrintFormat("[RFX] Percent loss threshold: %.2f%%", inp_loss_percent_vol);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   g_panel.Destroy();
   Print("[RFX] RFX Equity Protector deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Skip if paused or panel says not working
   if(g_is_paused || !g_panel.IsWorking()) return;

   // Check loss thresholds
   if(inp_use_loss_money || inp_use_loss_percent)
   {
      if(IsLossThresholdReached())
      {
         ExecuteLossProtection();
      }
   }
}

//+------------------------------------------------------------------+
//| Timer function - update panel                                    |
//+------------------------------------------------------------------+
void OnTimer()
{
   g_panel.Update();
}

//+------------------------------------------------------------------+
//| Chart event handler                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   g_panel.OnChartEvent(id, lparam, dparam, sparam);

   // Sync panel working state with pause state
   if(!g_panel.IsWorking() && !g_is_paused)
   {
      // User manually paused via panel
   }
   else if(g_panel.IsWorking() && g_is_paused)
   {
      // User resumed from pause
      g_is_paused = false;
      Print("[RFX] Utility resumed by user");
   }
}
