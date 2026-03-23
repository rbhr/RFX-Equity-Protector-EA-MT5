//+------------------------------------------------------------------+
//|                                                    RFX_Panel.mqh |
//|                              RFX Equity Protector EA for MT5     |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "RFX Trading"
#property version   "1.00"

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Controls\SpinEdit.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Color scheme constants                                           |
//+------------------------------------------------------------------+
#define CLR_PANEL_BG        C'25,29,38'       // Dark navy background
#define CLR_PANEL_BORDER    C'45,55,72'       // Subtle border
#define CLR_HEADER_BG       C'30,64,115'      // Header blue gradient
#define CLR_HEADER_TEXT     C'220,230,255'     // Light header text
#define CLR_LABEL_TEXT      C'160,174,192'     // Muted label text
#define CLR_VALUE_TEXT      C'226,232,240'     // Bright value text
#define CLR_ACCENT_GREEN    C'72,199,142'      // Green accent
#define CLR_ACCENT_RED      C'245,101,101'     // Red accent
#define CLR_ACCENT_BLUE     C'99,179,237'      // Blue accent
#define CLR_ACCENT_YELLOW   C'246,224,94'      // Yellow/gold accent
#define CLR_BTN_BUY         C'34,139,94'       // Buy button green
#define CLR_BTN_BUY_HOVER   C'42,160,108'      // Buy hover
#define CLR_BTN_SELL        C'197,48,48'       // Sell button red
#define CLR_BTN_SELL_HOVER  C'220,60,60'       // Sell hover
#define CLR_BTN_CLOSE       C'55,65,81'        // Close button gray
#define CLR_BTN_CLOSE_HOVER C'75,85,99'        // Close hover
#define CLR_BTN_ACTION      C'49,46,129'       // Action button indigo
#define CLR_BTN_ACTION_HOVER C'67,56,202'      // Action hover
#define CLR_SECTION_BG      C'30,35,46'        // Section background
#define CLR_DIVIDER         C'45,55,72'        // Divider line
#define CLR_STATUS_ACTIVE   C'72,199,142'      // Active status
#define CLR_STATUS_PAUSED   C'246,224,94'      // Paused status
#define CLR_BALANCE_TEXT    C'72,199,142'       // Balance text green
#define CLR_EQUITY_TEXT     C'99,179,237'       // Equity text blue
#define CLR_DRAWDOWN_LOW    C'72,199,142'       // Low drawdown green
#define CLR_DRAWDOWN_MED    C'246,224,94'       // Medium drawdown yellow
#define CLR_DRAWDOWN_HIGH   C'245,101,101'      // High drawdown red
#define CLR_WHITE           C'255,255,255'

//+------------------------------------------------------------------+
//| Panel class                                                      |
//+------------------------------------------------------------------+
class CRFXPanel
{
private:
   // Panel state
   bool              m_is_working;
   bool              m_is_minimized;
   bool              m_show_panel;
   int               m_font_size;
   int               m_magic_number;
   double            m_order_lots;
   string            m_prefix;

   // Panel dimensions
   int               m_panel_x;
   int               m_panel_y;
   int               m_panel_width;
   int               m_panel_height;
   int               m_header_height;
   int               m_minimized_height;

   // Font settings
   string            m_font_name;
   string            m_font_bold;
   int               m_font_size_title;
   int               m_font_size_normal;
   int               m_font_size_small;
   int               m_font_size_value;

   // Chart corner labels (top-right)
   string            m_lbl_balance_title;
   string            m_lbl_balance_value;
   string            m_lbl_equity_title;
   string            m_lbl_equity_value;

   // Trade helper
   CTrade            m_trade;
   CPositionInfo     m_position;

   // Dragging
   bool              m_is_dragging;
   int               m_drag_offset_x;
   int               m_drag_offset_y;

   // Helper methods
   void              CreateRectLabel(string name, int x, int y, int w, int h, color bg, color border, int border_width=0);
   void              CreateLabel(string name, int x, int y, string text, color clr, int size, string font="", ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER);
   void              CreateButton(string name, int x, int y, int w, int h, string text, color bg, color text_clr, int font_size);
   void              CreateEdit(string name, int x, int y, int w, int h, string text, color bg, color text_clr, int font_size);
   void              CreateBitmapLabel(string name, int x, int y, int w, int h, color clr);

   void              UpdateValues();
   void              UpdateDrawdownColor(double dd);

   int               CountPositions(int type, double &lots, double &profit);
   void              DeleteObjects();

   string            N(string suffix) { return m_prefix + suffix; }

public:
                     CRFXPanel();
                    ~CRFXPanel();

   bool              Create(bool show_panel, int font_size, int magic_number, double order_lots);
   void              Destroy();
   void              Update();
   void              OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);

   void              SetWorking(bool working)  { m_is_working = working; }
   bool              IsWorking()                { return m_is_working; }
   bool              IsMinimized()              { return m_is_minimized; }
   double            GetOrderLots()             { return m_order_lots; }
   int               GetMagicNumber()           { return m_magic_number; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRFXPanel::CRFXPanel()
{
   m_is_working    = true;
   m_is_minimized  = false;
   m_show_panel    = true;
   m_font_size     = 5;
   m_magic_number  = 6866;
   m_order_lots    = 0.01;
   m_prefix        = "RFX_";
   m_is_dragging   = false;

   m_panel_x       = 20;
   m_panel_y       = 30;
   m_panel_width   = 320;
   m_panel_height  = 440;
   m_header_height = 50;
   m_minimized_height = 55;

   m_font_name     = "Segoe UI";
   m_font_bold     = "Segoe UI Semibold";
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRFXPanel::~CRFXPanel()
{
   Destroy();
}

//+------------------------------------------------------------------+
//| Create rounded rectangle label                                   |
//+------------------------------------------------------------------+
void CRFXPanel::CreateRectLabel(string name, int x, int y, int w, int h, color bg, color border, int border_width)
{
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, border_width);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
}

//+------------------------------------------------------------------+
//| Create text label                                                |
//+------------------------------------------------------------------+
void CRFXPanel::CreateLabel(string name, int x, int y, string text, color clr, int size, string font="", ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)
{
   if(font == "") font = m_font_name;
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 1);
}

//+------------------------------------------------------------------+
//| Create button                                                    |
//+------------------------------------------------------------------+
void CRFXPanel::CreateButton(string name, int x, int y, int w, int h, string text, color bg, color text_clr, int font_size)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, text_clr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetString(0, name, OBJPROP_FONT, m_font_bold);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
}

//+------------------------------------------------------------------+
//| Create edit box                                                  |
//+------------------------------------------------------------------+
void CRFXPanel::CreateEdit(string name, int x, int y, int w, int h, string text, color bg, color text_clr, int font_size)
{
   ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, text_clr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, CLR_PANEL_BORDER);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetString(0, name, OBJPROP_FONT, m_font_name);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, name, OBJPROP_READONLY, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
}

//+------------------------------------------------------------------+
//| Count positions by type                                          |
//+------------------------------------------------------------------+
int CRFXPanel::CountPositions(int type, double &lots, double &profit)
{
   int count = 0;
   lots = 0.0;
   profit = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() != _Symbol) continue;
         if(m_magic_number > 0 && m_position.Magic() != m_magic_number) continue;

         if((type == POSITION_TYPE_BUY && m_position.PositionType() == POSITION_TYPE_BUY) ||
            (type == POSITION_TYPE_SELL && m_position.PositionType() == POSITION_TYPE_SELL))
         {
            count++;
            lots += m_position.Volume();
            profit += m_position.Profit() + m_position.Swap() + m_position.Commission();
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Create panel                                                     |
//+------------------------------------------------------------------+
bool CRFXPanel::Create(bool show_panel, int font_size, int magic_number, double order_lots)
{
   m_show_panel   = show_panel;
   m_font_size    = font_size;
   m_magic_number = magic_number;
   m_order_lots   = order_lots;

   // Scale font sizes based on input
   m_font_size_title  = m_font_size + 7;   // 12
   m_font_size_normal = m_font_size + 4;   // 9
   m_font_size_small  = m_font_size + 3;   // 8
   m_font_size_value  = m_font_size + 5;   // 10

   if(!m_show_panel) return true;

   m_trade.SetExpertMagicNumber(m_magic_number);

   int px = m_panel_x;
   int py = m_panel_y;
   int pw = m_panel_width;

   // --- Main panel background with border ---
   CreateRectLabel(N("bg"), px, py, pw, m_panel_height, CLR_PANEL_BG, CLR_PANEL_BORDER, 1);

   // --- Header background ---
   CreateRectLabel(N("header_bg"), px, py, pw, m_header_height, CLR_HEADER_BG, CLR_HEADER_BG, 0);

   // --- Title ---
   CreateLabel(N("title"), px + 15, py + 8, "RFX Equity Protector", CLR_WHITE, m_font_size_title, m_font_bold);
   CreateLabel(N("subtitle"), px + 15, py + 30, "MetaTrader 5 Utility", CLR_HEADER_TEXT, m_font_size_small);

   // --- Minimize button ---
   CreateButton(N("btn_minimize"), px + pw - 60, py + 5, 22, 22, "\x2013", CLR_BTN_CLOSE, CLR_LABEL_TEXT, m_font_size_normal);

   // --- Status indicator ---
   CreateRectLabel(N("status_dot"), px + pw - 30, py + 10, 12, 12, CLR_STATUS_ACTIVE, CLR_STATUS_ACTIVE, 0);

   // --- Start/Stop Button ---
   int y_offset = py + m_header_height + 10;
   CreateButton(N("btn_toggle"), px + 15, y_offset, pw - 30, 32, "Click to Stop Work", CLR_BTN_ACTION, CLR_WHITE, m_font_size_normal);

   // --- Info Section ---
   y_offset += 42;
   CreateRectLabel(N("info_bg"), px + 10, y_offset, pw - 20, 150, CLR_SECTION_BG, CLR_DIVIDER, 1);

   int info_x = px + 20;
   int info_y = y_offset + 10;
   int line_h = 20;

   CreateLabel(N("lbl_orders"), info_x, info_y, "Orders:", CLR_LABEL_TEXT, m_font_size_normal);
   CreateLabel(N("val_orders"), info_x + 100, info_y, "0", CLR_VALUE_TEXT, m_font_size_normal, m_font_bold);
   info_y += line_h;

   CreateLabel(N("lbl_buys"), info_x, info_y, "BUYS:", CLR_ACCENT_GREEN, m_font_size_value, m_font_bold);
   CreateLabel(N("val_buys"), info_x + 100, info_y, "0 (0.00 Lots)", CLR_VALUE_TEXT, m_font_size_normal);
   info_y += line_h;

   CreateLabel(N("lbl_sells"), info_x, info_y, "SELLS:", CLR_ACCENT_RED, m_font_size_value, m_font_bold);
   CreateLabel(N("val_sells"), info_x + 100, info_y, "0 (0.00 Lots)", CLR_VALUE_TEXT, m_font_size_normal);
   info_y += line_h;

   CreateLabel(N("lbl_profit_buy"), info_x, info_y, "Profit buys:", CLR_LABEL_TEXT, m_font_size_small);
   CreateLabel(N("val_profit_buy"), info_x + 100, info_y, "0.00", CLR_ACCENT_GREEN, m_font_size_small);
   info_y += line_h - 2;

   CreateLabel(N("lbl_profit_sell"), info_x, info_y, "Profit sells:", CLR_LABEL_TEXT, m_font_size_small);
   CreateLabel(N("val_profit_sell"), info_x + 100, info_y, "0.00", CLR_ACCENT_RED, m_font_size_small);
   info_y += line_h - 2;

   CreateLabel(N("lbl_spread"), info_x, info_y, "Spread:", CLR_LABEL_TEXT, m_font_size_small);
   CreateLabel(N("val_spread"), info_x + 100, info_y, "0 Points", CLR_ACCENT_YELLOW, m_font_size_small);
   info_y += line_h;

   CreateLabel(N("lbl_dd"), info_x, info_y, "Drawdown:", CLR_LABEL_TEXT, m_font_size_value, m_font_bold);
   CreateLabel(N("val_dd"), info_x + 100, info_y, "0.00 %", CLR_DRAWDOWN_LOW, m_font_size_value, m_font_bold);

   // --- Close Buttons ---
   y_offset += 160;
   int btn_w = (pw - 40) / 2;
   CreateButton(N("btn_close_buy"), px + 15, y_offset, btn_w, 30, "Close Buy", CLR_BTN_BUY, CLR_WHITE, m_font_size_normal);
   CreateButton(N("btn_close_sell"), px + 20 + btn_w, y_offset, btn_w, 30, "Close Sell", CLR_BTN_SELL, CLR_WHITE, m_font_size_normal);

   // --- Divider ---
   y_offset += 40;
   CreateRectLabel(N("divider1"), px + 15, y_offset, pw - 30, 1, CLR_DIVIDER, CLR_DIVIDER, 0);

   // --- Order Section ---
   y_offset += 10;
   CreateLabel(N("lbl_order_size"), px + 15, y_offset + 5, "Order Size", CLR_LABEL_TEXT, m_font_size_small);
   CreateEdit(N("edit_lots"), px + 100, y_offset, 80, 28, DoubleToString(m_order_lots, 2), CLR_SECTION_BG, CLR_VALUE_TEXT, m_font_size_normal);
   CreateLabel(N("lbl_lots"), px + 188, y_offset + 5, "Lots", CLR_LABEL_TEXT, m_font_size_small);

   // Lot +/- buttons
   CreateButton(N("btn_lot_minus"), px + 215, y_offset, 28, 28, "-", CLR_BTN_CLOSE, CLR_WHITE, m_font_size_value);
   CreateButton(N("btn_lot_plus"), px + 247, y_offset, 28, 28, "+", CLR_BTN_CLOSE, CLR_WHITE, m_font_size_value);

   // --- Buy/Sell Buttons ---
   y_offset += 38;
   btn_w = (pw - 40) / 2;
   string buy_text = "Buy " + DoubleToString(m_order_lots, 2);
   string sell_text = "Sell " + DoubleToString(m_order_lots, 2);
   CreateButton(N("btn_buy"), px + 15, y_offset, btn_w, 34, buy_text, CLR_BTN_BUY, CLR_WHITE, m_font_size_value);
   CreateButton(N("btn_sell"), px + 20 + btn_w, y_offset, btn_w, 34, sell_text, CLR_BTN_SELL, CLR_WHITE, m_font_size_value);

   // --- Status Bar ---
   y_offset += 44;
   CreateRectLabel(N("status_bar"), px, y_offset, pw, 24, CLR_SECTION_BG, CLR_PANEL_BORDER, 1);
   CreateLabel(N("status_text"), px + pw/2, y_offset + 4, "Utility is working", CLR_STATUS_ACTIVE, m_font_size_small, m_font_name, ANCHOR_UPPER);

   // Update panel height
   m_panel_height = y_offset + 24 - py;
   ObjectSetInteger(0, N("bg"), OBJPROP_YSIZE, m_panel_height);

   // --- Top-right corner: Balance & Equity ---
   CreateLabel(N("corner_bal_title"), 0, 0, "Current balance:", CLR_LABEL_TEXT, m_font_size_small, m_font_name, ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0, N("corner_bal_title"), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, N("corner_bal_title"), OBJPROP_XDISTANCE, 15);
   ObjectSetInteger(0, N("corner_bal_title"), OBJPROP_YDISTANCE, 30);

   CreateLabel(N("corner_bal_value"), 0, 0, DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), CLR_BALANCE_TEXT, m_font_size_title, m_font_bold, ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0, N("corner_bal_value"), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, N("corner_bal_value"), OBJPROP_XDISTANCE, 15);
   ObjectSetInteger(0, N("corner_bal_value"), OBJPROP_YDISTANCE, 48);

   CreateLabel(N("corner_eq_title"), 0, 0, "Current equity:", CLR_LABEL_TEXT, m_font_size_small, m_font_name, ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0, N("corner_eq_title"), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, N("corner_eq_title"), OBJPROP_XDISTANCE, 15);
   ObjectSetInteger(0, N("corner_eq_title"), OBJPROP_YDISTANCE, 70);

   CreateLabel(N("corner_eq_value"), 0, 0, DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2), CLR_EQUITY_TEXT, m_font_size_title, m_font_bold, ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0, N("corner_eq_value"), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, N("corner_eq_value"), OBJPROP_XDISTANCE, 15);
   ObjectSetInteger(0, N("corner_eq_value"), OBJPROP_YDISTANCE, 88);

   ChartRedraw();
   return true;
}

//+------------------------------------------------------------------+
//| Destroy panel                                                    |
//+------------------------------------------------------------------+
void CRFXPanel::Destroy()
{
   DeleteObjects();
}

//+------------------------------------------------------------------+
//| Delete all panel objects                                          |
//+------------------------------------------------------------------+
void CRFXPanel::DeleteObjects()
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, m_prefix) == 0)
         ObjectDelete(0, name);
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Update drawdown color based on severity                          |
//+------------------------------------------------------------------+
void CRFXPanel::UpdateDrawdownColor(double dd)
{
   color clr = CLR_DRAWDOWN_LOW;
   if(dd >= 10.0)
      clr = CLR_DRAWDOWN_HIGH;
   else if(dd >= 5.0)
      clr = CLR_DRAWDOWN_MED;

   ObjectSetInteger(0, N("val_dd"), OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
//| Update panel values                                              |
//+------------------------------------------------------------------+
void CRFXPanel::Update()
{
   if(!m_show_panel) return;
   if(m_is_minimized)
   {
      // Still update corner values
      ObjectSetString(0, N("corner_bal_value"), OBJPROP_TEXT, DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
      ObjectSetString(0, N("corner_eq_value"), OBJPROP_TEXT, DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
      ChartRedraw();
      return;
   }

   double buy_lots = 0, sell_lots = 0, buy_profit = 0, sell_profit = 0;
   int buy_count = CountPositions(POSITION_TYPE_BUY, buy_lots, buy_profit);
   int sell_count = CountPositions(POSITION_TYPE_SELL, sell_lots, sell_profit);
   int total_orders = buy_count + sell_count;

   // Update order info
   ObjectSetString(0, N("val_orders"), OBJPROP_TEXT, IntegerToString(total_orders));
   ObjectSetString(0, N("val_buys"), OBJPROP_TEXT, IntegerToString(buy_count) + " (" + DoubleToString(buy_lots, 2) + " Lots)");
   ObjectSetString(0, N("val_sells"), OBJPROP_TEXT, IntegerToString(sell_count) + " (" + DoubleToString(sell_lots, 2) + " Lots)");

   // Profit coloring
   ObjectSetString(0, N("val_profit_buy"), OBJPROP_TEXT, DoubleToString(buy_profit, 2));
   ObjectSetInteger(0, N("val_profit_buy"), OBJPROP_COLOR, buy_profit >= 0 ? CLR_ACCENT_GREEN : CLR_ACCENT_RED);

   ObjectSetString(0, N("val_profit_sell"), OBJPROP_TEXT, DoubleToString(sell_profit, 2));
   ObjectSetInteger(0, N("val_profit_sell"), OBJPROP_COLOR, sell_profit >= 0 ? CLR_ACCENT_GREEN : CLR_ACCENT_RED);

   // Spread
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   ObjectSetString(0, N("val_spread"), OBJPROP_TEXT, IntegerToString(spread) + " Points");

   // Drawdown
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double dd = 0;
   if(balance > 0) dd = ((balance - equity) / balance) * 100.0;
   if(dd < 0) dd = 0;
   ObjectSetString(0, N("val_dd"), OBJPROP_TEXT, DoubleToString(dd, 2) + " %");
   UpdateDrawdownColor(dd);

   // Corner balance/equity
   ObjectSetString(0, N("corner_bal_value"), OBJPROP_TEXT, DoubleToString(balance, 2));
   ObjectSetString(0, N("corner_eq_value"), OBJPROP_TEXT, DoubleToString(equity, 2));

   // Color equity based on relation to balance
   if(equity >= balance)
      ObjectSetInteger(0, N("corner_eq_value"), OBJPROP_COLOR, CLR_EQUITY_TEXT);
   else
      ObjectSetInteger(0, N("corner_eq_value"), OBJPROP_COLOR, CLR_ACCENT_RED);

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Handle chart events                                              |
//+------------------------------------------------------------------+
void CRFXPanel::OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(!m_show_panel) return;

   // Button click events
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // Toggle work button
      if(sparam == N("btn_toggle"))
      {
         m_is_working = !m_is_working;
         ObjectSetInteger(0, N("btn_toggle"), OBJPROP_STATE, false);

         if(m_is_working)
         {
            ObjectSetString(0, N("btn_toggle"), OBJPROP_TEXT, "Click to Stop Work");
            ObjectSetInteger(0, N("btn_toggle"), OBJPROP_BGCOLOR, CLR_BTN_ACTION);
            ObjectSetInteger(0, N("btn_toggle"), OBJPROP_BORDER_COLOR, CLR_BTN_ACTION);
            ObjectSetInteger(0, N("status_dot"), OBJPROP_BGCOLOR, CLR_STATUS_ACTIVE);
            ObjectSetInteger(0, N("status_dot"), OBJPROP_BORDER_COLOR, CLR_STATUS_ACTIVE);
            ObjectSetString(0, N("status_text"), OBJPROP_TEXT, "Utility is working");
            ObjectSetInteger(0, N("status_text"), OBJPROP_COLOR, CLR_STATUS_ACTIVE);
         }
         else
         {
            ObjectSetString(0, N("btn_toggle"), OBJPROP_TEXT, "Click to Start Work");
            ObjectSetInteger(0, N("btn_toggle"), OBJPROP_BGCOLOR, CLR_BTN_SELL);
            ObjectSetInteger(0, N("btn_toggle"), OBJPROP_BORDER_COLOR, CLR_BTN_SELL);
            ObjectSetInteger(0, N("status_dot"), OBJPROP_BGCOLOR, CLR_STATUS_PAUSED);
            ObjectSetInteger(0, N("status_dot"), OBJPROP_BORDER_COLOR, CLR_STATUS_PAUSED);
            ObjectSetString(0, N("status_text"), OBJPROP_TEXT, "Utility is paused");
            ObjectSetInteger(0, N("status_text"), OBJPROP_COLOR, CLR_STATUS_PAUSED);
         }
         ChartRedraw();
         return;
      }

      // Minimize button
      if(sparam == N("btn_minimize"))
      {
         ObjectSetInteger(0, N("btn_minimize"), OBJPROP_STATE, false);
         m_is_minimized = !m_is_minimized;

         if(m_is_minimized)
         {
            // Hide everything except header
            ObjectSetInteger(0, N("bg"), OBJPROP_YSIZE, m_minimized_height);
            ObjectSetString(0, N("btn_minimize"), OBJPROP_TEXT, "+");

            // Hide all non-header objects
            string hide_list[];
            int hide_count = 0;
            int total = ObjectsTotal(0, 0, -1);
            for(int i = 0; i < total; i++)
            {
               string name = ObjectName(0, i);
               if(StringFind(name, m_prefix) != 0) continue;
               if(name == N("bg") || name == N("header_bg") || name == N("title") ||
                  name == N("subtitle") || name == N("btn_minimize") || name == N("status_dot") ||
                  StringFind(name, "corner_") >= 0)
                  continue;
               ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
            }
         }
         else
         {
            ObjectSetInteger(0, N("bg"), OBJPROP_YSIZE, m_panel_height);
            ObjectSetString(0, N("btn_minimize"), OBJPROP_TEXT, "\x2013");

            // Show all objects
            int total = ObjectsTotal(0, 0, -1);
            for(int i = 0; i < total; i++)
            {
               string name = ObjectName(0, i);
               if(StringFind(name, m_prefix) != 0) continue;
               ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
            }
         }
         ChartRedraw();
         return;
      }

      // Close Buy
      if(sparam == N("btn_close_buy"))
      {
         ObjectSetInteger(0, N("btn_close_buy"), OBJPROP_STATE, false);
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(m_position.SelectByIndex(i))
            {
               if(m_position.Symbol() != _Symbol) continue;
               if(m_magic_number > 0 && m_position.Magic() != m_magic_number) continue;
               if(m_position.PositionType() == POSITION_TYPE_BUY)
                  m_trade.PositionClose(m_position.Ticket());
            }
         }
         return;
      }

      // Close Sell
      if(sparam == N("btn_close_sell"))
      {
         ObjectSetInteger(0, N("btn_close_sell"), OBJPROP_STATE, false);
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(m_position.SelectByIndex(i))
            {
               if(m_position.Symbol() != _Symbol) continue;
               if(m_magic_number > 0 && m_position.Magic() != m_magic_number) continue;
               if(m_position.PositionType() == POSITION_TYPE_SELL)
                  m_trade.PositionClose(m_position.Ticket());
            }
         }
         return;
      }

      // Buy button
      if(sparam == N("btn_buy"))
      {
         ObjectSetInteger(0, N("btn_buy"), OBJPROP_STATE, false);
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         m_trade.Buy(m_order_lots, _Symbol, ask, 0, 0, "RFX Panel Buy");
         return;
      }

      // Sell button
      if(sparam == N("btn_sell"))
      {
         ObjectSetInteger(0, N("btn_sell"), OBJPROP_STATE, false);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         m_trade.Sell(m_order_lots, _Symbol, bid, 0, 0, "RFX Panel Sell");
         return;
      }

      // Lot plus
      if(sparam == N("btn_lot_plus"))
      {
         ObjectSetInteger(0, N("btn_lot_plus"), OBJPROP_STATE, false);
         double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
         double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
         m_order_lots = MathMin(m_order_lots + step, max_lot);
         m_order_lots = NormalizeDouble(m_order_lots, 2);
         ObjectSetString(0, N("edit_lots"), OBJPROP_TEXT, DoubleToString(m_order_lots, 2));
         ObjectSetString(0, N("btn_buy"), OBJPROP_TEXT, "Buy " + DoubleToString(m_order_lots, 2));
         ObjectSetString(0, N("btn_sell"), OBJPROP_TEXT, "Sell " + DoubleToString(m_order_lots, 2));
         ChartRedraw();
         return;
      }

      // Lot minus
      if(sparam == N("btn_lot_minus"))
      {
         ObjectSetInteger(0, N("btn_lot_minus"), OBJPROP_STATE, false);
         double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
         double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
         m_order_lots = MathMax(m_order_lots - step, min_lot);
         m_order_lots = NormalizeDouble(m_order_lots, 2);
         ObjectSetString(0, N("edit_lots"), OBJPROP_TEXT, DoubleToString(m_order_lots, 2));
         ObjectSetString(0, N("btn_buy"), OBJPROP_TEXT, "Buy " + DoubleToString(m_order_lots, 2));
         ObjectSetString(0, N("btn_sell"), OBJPROP_TEXT, "Sell " + DoubleToString(m_order_lots, 2));
         ChartRedraw();
         return;
      }
   }

   // Handle edit box changes (lot size manual input)
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
   {
      if(sparam == N("edit_lots"))
      {
         string text = ObjectGetString(0, N("edit_lots"), OBJPROP_TEXT);
         double new_lots = StringToDouble(text);
         double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
         double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
         double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

         if(new_lots < min_lot) new_lots = min_lot;
         if(new_lots > max_lot) new_lots = max_lot;

         // Round to step
         new_lots = MathRound(new_lots / step) * step;
         m_order_lots = NormalizeDouble(new_lots, 2);

         ObjectSetString(0, N("edit_lots"), OBJPROP_TEXT, DoubleToString(m_order_lots, 2));
         ObjectSetString(0, N("btn_buy"), OBJPROP_TEXT, "Buy " + DoubleToString(m_order_lots, 2));
         ObjectSetString(0, N("btn_sell"), OBJPROP_TEXT, "Sell " + DoubleToString(m_order_lots, 2));
         ChartRedraw();
      }
   }
}
