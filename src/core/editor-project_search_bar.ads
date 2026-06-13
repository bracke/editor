with Ada.Strings.Unbounded;
with Editor.Input_Field;
with Editor.Layout;

package Editor.Project_Search_Bar is

   type Project_Search_Bar_State is private;

   type Project_Search_Bar_Config is record
      Enabled_By_Default       : Boolean := False;
      Height_In_Rows           : Natural := 2;
      Overlay_Width_In_Columns : Natural := 80;
      Query_Field_Min_Columns  : Natural := 24;
      Field_Padding_Columns    : Natural := 1;
      Button_Padding_Columns   : Natural := 1;
      Show_Status_Text         : Boolean := True;
   end record;

   type Project_Search_Bar_Zone is
     (Outside_Project_Search_Bar,
      Project_Search_Bar_Background_Zone,
      Project_Search_Query_Field_Zone,
      Project_Search_Replace_Field_Zone,
      Project_Search_Run_Button_Zone,
      Project_Search_Clear_Button_Zone,
      Project_Search_Close_Button_Zone);

   type Project_Search_Bar_Hit_Result is record
      Zone : Project_Search_Bar_Zone := Outside_Project_Search_Bar;
   end record;

   procedure Clear (State : in out Project_Search_Bar_State);
   procedure Open (State : in out Project_Search_Bar_State);
   procedure Close (State : in out Project_Search_Bar_State);
   function Is_Open (State : Project_Search_Bar_State) return Boolean;

   type Project_Search_Bar_Field is
     (Project_Search_Query_Field,
      Project_Search_Replace_Field);

   function Active_Field (State : Project_Search_Bar_State) return Project_Search_Bar_Field;
   procedure Focus_Query_Field (State : in out Project_Search_Bar_State);
   procedure Focus_Replace_Field (State : in out Project_Search_Bar_State);
   procedure Toggle_Active_Field (State : in out Project_Search_Bar_State);

   function Query_Text (State : Project_Search_Bar_State) return String;
   procedure Set_Query_Text
     (State : in out Project_Search_Bar_State;
      Text  : String);
   function Replace_Text (State : Project_Search_Bar_State) return String;
   procedure Set_Replace_Text
     (State : in out Project_Search_Bar_State;
      Text  : String);
   procedure Insert_Text
     (State : in out Project_Search_Bar_State;
      Text  : String);
   procedure Backspace (State : in out Project_Search_Bar_State);
   procedure Delete_Forward (State : in out Project_Search_Bar_State);
   procedure Move_Cursor_Left (State : in out Project_Search_Bar_State);
   procedure Move_Cursor_Right (State : in out Project_Search_Bar_State);
   procedure Move_Cursor_Start (State : in out Project_Search_Bar_State);
   procedure Move_Cursor_End (State : in out Project_Search_Bar_State);
   procedure Select_All (State : in out Project_Search_Bar_State);
   procedure Set_Cursor_From_Visible_Column
     (State           : in out Project_Search_Bar_State;
      Visible_Column  : Natural;
      Visible_Columns : Natural);
   function Cursor_Column (State : Project_Search_Bar_State) return Natural;
   function Query_Snapshot
     (State           : Project_Search_Bar_State;
      Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot;
   function Replace_Snapshot
     (State           : Project_Search_Bar_State;
      Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot;

   function Geometry
     (Body_Rect   : Editor.Layout.Rect;
      Config      : Project_Search_Bar_Config;
      Cell_Width  : Positive;
      Cell_Height : Positive) return Editor.Layout.Rect;

   function Hit_Test
     (Body_Rect   : Editor.Layout.Rect;
      Config      : Project_Search_Bar_Config;
      State       : Project_Search_Bar_State;
      X           : Integer;
      Y           : Integer;
      Cell_Width  : Positive;
      Cell_Height : Positive) return Project_Search_Bar_Hit_Result;

private
   type Project_Search_Bar_State is record
      Opened        : Boolean := False;
      Active        : Project_Search_Bar_Field := Project_Search_Query_Field;
      Query_Field   : Editor.Input_Field.Input_Field_State;
      Replace_Field : Editor.Input_Field.Input_Field_State;
   end record;

end Editor.Project_Search_Bar;
