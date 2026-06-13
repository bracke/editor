with Ada.Strings.Unbounded;
with Editor.Buffer_Types;

package Editor.Tab_Bar is

   type Tab_Bar_Config is record
      Enabled            : Boolean := True;
      Show_Close_Buttons : Boolean := True;
      Minimum_Tab_Width  : Natural := 8;
      Maximum_Tab_Width  : Natural := 24;
   end record;

   type Tab_Bar_Zone is
     (Outside_Tab_Bar,
      Tab_Bar_Background_Zone,
      Tab_Body_Zone,
      Tab_Close_Zone,
      Tab_Overflow_Zone);

   type Tab_Hit_Result is record
      Zone      : Tab_Bar_Zone := Outside_Tab_Bar;
      Buffer_Id : Editor.Buffer_Types.Buffer_Id := Editor.Buffer_Types.No_Buffer;
   end record;

   type Tab_Visual_State is
     (Inactive_Tab,
      Active_Tab,
      Dirty_Inactive_Tab,
      Dirty_Active_Tab);

   type Tab_Buffer_Summary_Array is array (Natural range <>) of Editor.Buffer_Types.Buffer_Summary;

   type Tab_Rect is record
      Visible  : Boolean := False;
      X        : Natural := 0;
      Y        : Natural := 0;
      W        : Natural := 0;
      H        : Natural := 0;
      Close_X  : Natural := 0;
      Close_W  : Natural := 0;
   end record;

   function Enabled
     (Config : Tab_Bar_Config) return Boolean;

   function Height_In_Rows
     (Config : Tab_Bar_Config) return Natural;

   function Visual_State
     (Summary : Editor.Buffer_Types.Buffer_Summary) return Tab_Visual_State;

   function Tab_Width
     (Config : Tab_Bar_Config;
      Cell_W : Positive) return Natural;

   function Rect_For_Index
     (Config         : Tab_Bar_Config;
      Index          : Positive;
      Viewport_Width : Natural;
      Cell_W         : Positive;
      Cell_H         : Positive;
      Origin_X       : Natural := 0;
      Origin_Y       : Natural := 0) return Tab_Rect;

   function Hit_Test
     (Config         : Tab_Bar_Config;
      Buffers        : Tab_Buffer_Summary_Array;
      Viewport_Width : Natural;
      Cell_W         : Positive;
      Cell_H         : Positive;
      X              : Integer;
      Y              : Integer;
      Origin_X       : Natural := 0;
      Origin_Y       : Natural := 0) return Tab_Hit_Result;

   function Display_Text
     (Summary : Editor.Buffer_Types.Buffer_Summary;
      Columns : Natural) return String;

   function Empty_Display_Text
     (Columns : Natural) return String;

end Editor.Tab_Bar;
