with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffer_Types;
with Editor.Contextual_Help;

package body Editor.Tab_Bar is

   function Enabled
     (Config : Tab_Bar_Config) return Boolean
   is
   begin
      return Config.Enabled;
   end Enabled;

   function Height_In_Rows
     (Config : Tab_Bar_Config) return Natural
   is
   begin
      if Enabled (Config) then
         return 1;
      else
         return 0;
      end if;
   end Height_In_Rows;

   function Visual_State
     (Summary : Editor.Buffer_Types.Buffer_Summary) return Tab_Visual_State
   is
   begin
      if Summary.Is_Active and then Summary.Is_Dirty then
         return Dirty_Active_Tab;
      elsif Summary.Is_Active then
         return Active_Tab;
      elsif Summary.Is_Dirty then
         return Dirty_Inactive_Tab;
      else
         return Inactive_Tab;
      end if;
   end Visual_State;

   function Tab_Width
     (Config : Tab_Bar_Config;
      Cell_W : Positive) return Natural
   is
      Min_W : constant Natural := Config.Minimum_Tab_Width * Cell_W;
      Max_W : constant Natural := Config.Maximum_Tab_Width * Cell_W;
   begin
      if Max_W = 0 then
         return Cell_W;
      elsif Min_W > Max_W then
         return Min_W;
      else
         return Max_W;
      end if;
   end Tab_Width;

   function Rect_For_Index
     (Config         : Tab_Bar_Config;
      Index          : Positive;
      Viewport_Width : Natural;
      Cell_W         : Positive;
      Cell_H         : Positive;
      Origin_X       : Natural := 0;
      Origin_Y       : Natural := 0) return Tab_Rect
   is
      W : constant Natural := Tab_Width (Config, Cell_W);
      X : constant Natural := Origin_X + (Index - 1) * W;
      Result : Tab_Rect;
   begin
      if not Enabled (Config)
        or else Viewport_Width = 0
        or else W = 0
        or else X >= Origin_X + Viewport_Width
        or else X + W > Origin_X + Viewport_Width
      then
         return Result;
      end if;

      Result.Visible := True;
      Result.X := X;
      Result.Y := Origin_Y;
      Result.W := W;
      Result.H := Cell_H;

      if Config.Show_Close_Buttons and then W >= 3 * Cell_W then
         Result.Close_W := Cell_W;
         Result.Close_X := X + W - 2 * Cell_W;
      end if;

      return Result;
   end Rect_For_Index;

   function Hit_Test
     (Config         : Tab_Bar_Config;
      Buffers        : Tab_Buffer_Summary_Array;
      Viewport_Width : Natural;
      Cell_W         : Positive;
      Cell_H         : Positive;
      X              : Integer;
      Y              : Integer;
      Origin_X       : Natural := 0;
      Origin_Y       : Natural := 0) return Tab_Hit_Result
   is
      Count : constant Natural := Buffers'Length;
      Bar_H : constant Natural := Height_In_Rows (Config) * Cell_H;
      Left  : constant Integer := Integer (Origin_X);
      Right : constant Integer := Integer (Origin_X + Viewport_Width);
      Top   : constant Integer := Integer (Origin_Y);
      Bot   : constant Integer := Integer (Origin_Y + Bar_H);
   begin
      if not Enabled (Config)
        or else Bar_H = 0
        or else X < Left
        or else X >= Right
        or else Y < Top
        or else Y >= Bot
      then
         return (Zone => Outside_Tab_Bar,
                 Buffer_Id => Editor.Buffer_Types.No_Buffer);
      end if;

      for I in Buffers'Range loop
         declare
            Rect    : constant Tab_Rect :=
              Rect_For_Index
                (Config, I - Buffers'First + 1, Viewport_Width, Cell_W, Cell_H, Origin_X, Origin_Y);
            Summary : constant Editor.Buffer_Types.Buffer_Summary := Buffers (I);
         begin
            if Rect.Visible
              and then X >= Integer (Rect.X)
              and then X < Integer (Rect.X + Rect.W)
            then
               if Rect.Close_W > 0
                 and then X >= Integer (Rect.Close_X)
                 and then X < Integer (Rect.Close_X + Rect.Close_W)
               then
                  return (Zone => Tab_Close_Zone,
                          Buffer_Id => Summary.Id);
               else
                  return (Zone => Tab_Body_Zone,
                          Buffer_Id => Summary.Id);
               end if;
            end if;
         end;
      end loop;

      return (Zone => Tab_Bar_Background_Zone,
              Buffer_Id => Editor.Buffer_Types.No_Buffer);
   end Hit_Test;

   function Display_Text
     (Summary : Editor.Buffer_Types.Buffer_Summary;
      Columns : Natural) return String
   is
      Text : constant String := To_String (Summary.Display_Name);
   begin
      if Columns = 0 then
         return "";
      elsif Text'Length <= Columns then
         return Text;
      elsif Columns <= 3 then
         return Text (Text'First .. Text'First + Columns - 1);
      else
         return Text (Text'First .. Text'First + Columns - 4) & "...";
      end if;
   end Display_Text;

   function Empty_Display_Text
     (Columns : Natural) return String
   is
      Text : constant String := Editor.Contextual_Help.Empty_Open_Buffers_Text;
   begin
      if Columns = 0 then
         return "";
      elsif Text'Length <= Columns then
         return Text;
      elsif Columns <= 3 then
         return Text (Text'First .. Text'First + Columns - 1);
      else
         return Text (Text'First .. Text'First + Columns - 4) & "...";
      end if;
   end Empty_Display_Text;

end Editor.Tab_Bar;
