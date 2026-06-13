with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Input_Field;

package body Editor.Project_Search_Bar is

   procedure Clear (State : in out Project_Search_Bar_State) is
   begin
      State.Opened := False;
      State.Active := Project_Search_Query_Field;
      Editor.Input_Field.Clear (State.Query_Field);
      Editor.Input_Field.Clear (State.Replace_Field);
   end Clear;

   procedure Open (State : in out Project_Search_Bar_State) is
   begin
      State.Opened := True;
      case State.Active is
         when Project_Search_Query_Field =>
            Editor.Input_Field.Move_Cursor_End (State.Query_Field);
         when Project_Search_Replace_Field =>
            Editor.Input_Field.Move_Cursor_End (State.Replace_Field);
      end case;
   end Open;

   procedure Close (State : in out Project_Search_Bar_State) is
   begin
      State.Opened := False;
   end Close;

   function Is_Open (State : Project_Search_Bar_State) return Boolean is
   begin
      return State.Opened;
   end Is_Open;

   function Active_Field (State : Project_Search_Bar_State) return Project_Search_Bar_Field is
   begin
      return State.Active;
   end Active_Field;

   procedure Focus_Query_Field (State : in out Project_Search_Bar_State) is
   begin
      State.Active := Project_Search_Query_Field;
      Editor.Input_Field.Move_Cursor_End (State.Query_Field);
   end Focus_Query_Field;

   procedure Focus_Replace_Field (State : in out Project_Search_Bar_State) is
   begin
      State.Active := Project_Search_Replace_Field;
      Editor.Input_Field.Move_Cursor_End (State.Replace_Field);
   end Focus_Replace_Field;

   procedure Toggle_Active_Field (State : in out Project_Search_Bar_State) is
   begin
      case State.Active is
         when Project_Search_Query_Field =>
            Focus_Replace_Field (State);
         when Project_Search_Replace_Field =>
            Focus_Query_Field (State);
      end case;
   end Toggle_Active_Field;

   function Query_Text (State : Project_Search_Bar_State) return String is
   begin
      return Editor.Input_Field.Text (State.Query_Field);
   end Query_Text;

   procedure Set_Query_Text
     (State : in out Project_Search_Bar_State;
      Text  : String) is
   begin
      Editor.Input_Field.Set_Text (State.Query_Field, Text);
   end Set_Query_Text;

   function Replace_Text (State : Project_Search_Bar_State) return String is
   begin
      return Editor.Input_Field.Text (State.Replace_Field);
   end Replace_Text;

   procedure Set_Replace_Text
     (State : in out Project_Search_Bar_State;
      Text  : String) is
   begin
      Editor.Input_Field.Set_Text (State.Replace_Field, Text);
   end Set_Replace_Text;

   procedure Insert_Text
     (State : in out Project_Search_Bar_State;
      Text  : String) is
   begin
      case State.Active is
         when Project_Search_Query_Field =>
            Editor.Input_Field.Insert_Text (State.Query_Field, Text);
         when Project_Search_Replace_Field =>
            Editor.Input_Field.Insert_Text (State.Replace_Field, Text);
      end case;
   end Insert_Text;

   procedure Backspace (State : in out Project_Search_Bar_State) is
   begin
      case State.Active is
         when Project_Search_Query_Field =>
            Editor.Input_Field.Backspace (State.Query_Field);
         when Project_Search_Replace_Field =>
            Editor.Input_Field.Backspace (State.Replace_Field);
      end case;
   end Backspace;

   procedure Delete_Forward (State : in out Project_Search_Bar_State) is
   begin
      case State.Active is
         when Project_Search_Query_Field =>
            Editor.Input_Field.Delete_Forward (State.Query_Field);
         when Project_Search_Replace_Field =>
            Editor.Input_Field.Delete_Forward (State.Replace_Field);
      end case;
   end Delete_Forward;

   procedure Move_Cursor_Left (State : in out Project_Search_Bar_State) is
   begin
      case State.Active is
         when Project_Search_Query_Field =>
            Editor.Input_Field.Move_Cursor_Left (State.Query_Field);
         when Project_Search_Replace_Field =>
            Editor.Input_Field.Move_Cursor_Left (State.Replace_Field);
      end case;
   end Move_Cursor_Left;

   procedure Move_Cursor_Right (State : in out Project_Search_Bar_State) is
   begin
      case State.Active is
         when Project_Search_Query_Field =>
            Editor.Input_Field.Move_Cursor_Right (State.Query_Field);
         when Project_Search_Replace_Field =>
            Editor.Input_Field.Move_Cursor_Right (State.Replace_Field);
      end case;
   end Move_Cursor_Right;

   procedure Move_Cursor_Start (State : in out Project_Search_Bar_State) is
   begin
      case State.Active is
         when Project_Search_Query_Field =>
            Editor.Input_Field.Move_Cursor_Start (State.Query_Field);
         when Project_Search_Replace_Field =>
            Editor.Input_Field.Move_Cursor_Start (State.Replace_Field);
      end case;
   end Move_Cursor_Start;

   procedure Move_Cursor_End (State : in out Project_Search_Bar_State) is
   begin
      case State.Active is
         when Project_Search_Query_Field =>
            Editor.Input_Field.Move_Cursor_End (State.Query_Field);
         when Project_Search_Replace_Field =>
            Editor.Input_Field.Move_Cursor_End (State.Replace_Field);
      end case;
   end Move_Cursor_End;

   procedure Select_All (State : in out Project_Search_Bar_State) is
   begin
      case State.Active is
         when Project_Search_Query_Field =>
            Editor.Input_Field.Select_All (State.Query_Field);
         when Project_Search_Replace_Field =>
            Editor.Input_Field.Select_All (State.Replace_Field);
      end case;
   end Select_All;

   procedure Set_Cursor_From_Visible_Column
     (State           : in out Project_Search_Bar_State;
      Visible_Column  : Natural;
      Visible_Columns : Natural) is
   begin
      case State.Active is
         when Project_Search_Query_Field =>
            Editor.Input_Field.Set_Cursor_From_Visible_Column
              (State.Query_Field, Visible_Column, Visible_Columns);
         when Project_Search_Replace_Field =>
            Editor.Input_Field.Set_Cursor_From_Visible_Column
              (State.Replace_Field, Visible_Column, Visible_Columns);
      end case;
   end Set_Cursor_From_Visible_Column;

   function Cursor_Column (State : Project_Search_Bar_State) return Natural is
   begin
      case State.Active is
         when Project_Search_Query_Field =>
            return Editor.Input_Field.Cursor_Column (State.Query_Field);
         when Project_Search_Replace_Field =>
            return Editor.Input_Field.Cursor_Column (State.Replace_Field);
      end case;
   end Cursor_Column;

   function Query_Snapshot
     (State           : Project_Search_Bar_State;
      Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot is
   begin
      return Editor.Input_Field.Snapshot (State.Query_Field, Visible_Columns);
   end Query_Snapshot;

   function Replace_Snapshot
     (State           : Project_Search_Bar_State;
      Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot is
   begin
      return Editor.Input_Field.Snapshot (State.Replace_Field, Visible_Columns);
   end Replace_Snapshot;

   function Geometry
     (Body_Rect   : Editor.Layout.Rect;
      Config      : Project_Search_Bar_Config;
      Cell_Width  : Positive;
      Cell_Height : Positive) return Editor.Layout.Rect
   is
      Wanted_W : constant Natural := Config.Overlay_Width_In_Columns * Cell_Width;
      Margin   : constant Natural := 2 * Cell_Width;
      Width    : constant Natural :=
        (if Body_Rect.Width > 2 * Margin
         then Natural'Min (Wanted_W, Body_Rect.Width - 2 * Margin)
         else Body_Rect.Width);
      Height   : constant Natural := Natural'Max (3, Config.Height_In_Rows) * Cell_Height;
      X        : constant Integer :=
        Body_Rect.X + Integer ((if Body_Rect.Width > Width then (Body_Rect.Width - Width) / 2 else 0));
      Y        : constant Integer := Body_Rect.Y + Integer (Cell_Height);
   begin
      return (X => X, Y => Y, Width => Width, Height => Height);
   end Geometry;

   function Hit_Test
     (Body_Rect   : Editor.Layout.Rect;
      Config      : Project_Search_Bar_Config;
      State       : Project_Search_Bar_State;
      X           : Integer;
      Y           : Integer;
      Cell_Width  : Positive;
      Cell_Height : Positive) return Project_Search_Bar_Hit_Result
   is
      G : constant Editor.Layout.Rect := Geometry (Body_Rect, Config, Cell_Width, Cell_Height);
      Rel_X : Integer := 0;
      Col   : Natural := 0;
      Total_Cols : constant Natural := G.Width / Cell_Width;
      Close_Start : constant Natural := (if Total_Cols > 7 then Total_Cols - 7 else 0);
      Clear_Start : constant Natural := (if Total_Cols > 15 then Total_Cols - 15 else 0);
      Run_Start   : constant Natural := (if Total_Cols > 22 then Total_Cols - 22 else 0);
      Field_Start : constant Natural := 16;
      Field_End   : constant Natural := (if Run_Start > Field_Start then Run_Start - 1 else Total_Cols);
   begin
      if not State.Opened or else G.Width = 0 or else G.Height = 0
        or else X < G.X or else Y < G.Y
        or else X >= G.X + Integer (G.Width)
        or else Y >= G.Y + Integer (G.Height)
      then
         return (Zone => Outside_Project_Search_Bar);
      end if;

      Rel_X := X - G.X;
      Col := Natural (Rel_X) / Cell_Width;
      if Y >= G.Y + Integer (Cell_Height)
        and then Y < G.Y + Integer (2 * Cell_Height)
        and then Col >= Field_Start and then Col < Field_End
      then
         return (Zone => Project_Search_Replace_Field_Zone);
      end if;

      if Col >= Close_Start then
         return (Zone => Project_Search_Close_Button_Zone);
      elsif Col >= Clear_Start then
         return (Zone => Project_Search_Clear_Button_Zone);
      elsif Col >= Run_Start then
         return (Zone => Project_Search_Run_Button_Zone);
      elsif Col >= Field_Start and then Col < Field_End then
         return (Zone => Project_Search_Query_Field_Zone);
      else
         return (Zone => Project_Search_Bar_Background_Zone);
      end if;
   end Hit_Test;

end Editor.Project_Search_Bar;
