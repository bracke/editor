with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases; use AUnit.Test_Cases.Registration;
with Editor.Layout;
with Editor.Project_Search_Bar;

package body Editor.Project_Search_Bar.Tests is

   use type Editor.Project_Search_Bar.Project_Search_Bar_Zone;
   use type Editor.Project_Search_Bar.Project_Search_Bar_Field;

   function Name
     (T : Project_Search_Bar_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Project_Search_Bar");
   end Name;

   procedure Test_Open_Close_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.Project_Search_Bar.Project_Search_Bar_State;
   begin
      Assert (not Editor.Project_Search_Bar.Is_Open (S),
              "new project-search bar state must be closed");
      Editor.Project_Search_Bar.Open (S);
      Assert (Editor.Project_Search_Bar.Is_Open (S),
              "Open must open project-search bar");
      Editor.Project_Search_Bar.Set_Query_Text (S, "needle");
      Editor.Project_Search_Bar.Set_Replace_Text (S, "hay");
      Editor.Project_Search_Bar.Close (S);
      Assert (not Editor.Project_Search_Bar.Is_Open (S),
              "Close must close project-search bar");
      Assert (Editor.Project_Search_Bar.Query_Text (S) = "needle",
              "Close must preserve query text");
      Assert (Editor.Project_Search_Bar.Replace_Text (S) = "hay",
              "Close must preserve transient replace text while bar state is openable");
      Editor.Project_Search_Bar.Clear (S);
      Assert (Editor.Project_Search_Bar.Query_Text (S) = "",
              "Clear must reset query text");
      Assert (Editor.Project_Search_Bar.Replace_Text (S) = "",
              "Clear must reset replace text");
      Assert (Editor.Project_Search_Bar.Cursor_Column (S) = 0,
              "Clear must reset cursor column");
   end Test_Open_Close_Clear;

   procedure Test_Query_Editing
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.Project_Search_Bar.Project_Search_Bar_State;
   begin
      Editor.Project_Search_Bar.Open (S);
      Editor.Project_Search_Bar.Insert_Text (S, "ab");
      Assert (Editor.Project_Search_Bar.Query_Text (S) = "ab",
              "Insert_Text must append at end cursor");
      Editor.Project_Search_Bar.Move_Cursor_Left (S);
      Editor.Project_Search_Bar.Insert_Text (S, "X");
      Assert (Editor.Project_Search_Bar.Query_Text (S) = "aXb",
              "Insert_Text must insert at cursor");
      Assert (Editor.Project_Search_Bar.Cursor_Column (S) = 2,
              "cursor must advance after insertion");
      Editor.Project_Search_Bar.Backspace (S);
      Assert (Editor.Project_Search_Bar.Query_Text (S) = "ab",
              "Backspace must remove character before cursor");
      Editor.Project_Search_Bar.Delete_Forward (S);
      Assert (Editor.Project_Search_Bar.Query_Text (S) = "a",
              "Delete_Forward must remove character at cursor");
      Editor.Project_Search_Bar.Move_Cursor_Left (S);
      Editor.Project_Search_Bar.Move_Cursor_Left (S);
      Assert (Editor.Project_Search_Bar.Cursor_Column (S) = 0,
              "Move_Cursor_Left must clamp at start");
      Editor.Project_Search_Bar.Move_Cursor_Right (S);
      Editor.Project_Search_Bar.Move_Cursor_Right (S);
      Assert (Editor.Project_Search_Bar.Cursor_Column (S) = 1,
              "Move_Cursor_Right must clamp at end");
   end Test_Query_Editing;

   procedure Test_Replace_Field_Editing
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.Project_Search_Bar.Project_Search_Bar_State;
   begin
      Editor.Project_Search_Bar.Open (S);
      Editor.Project_Search_Bar.Insert_Text (S, "needle");
      Editor.Project_Search_Bar.Toggle_Active_Field (S);
      Assert
        (Editor.Project_Search_Bar.Active_Field (S) =
           Editor.Project_Search_Bar.Project_Search_Replace_Field,
         "Tab/toggle must focus the replace field");
      Editor.Project_Search_Bar.Insert_Text (S, "replacement");
      Assert (Editor.Project_Search_Bar.Query_Text (S) = "needle",
              "replace-field typing must not alter query text");
      Assert (Editor.Project_Search_Bar.Replace_Text (S) = "replacement",
              "replace-field typing must update replace text");
      Editor.Project_Search_Bar.Backspace (S);
      Assert (Editor.Project_Search_Bar.Replace_Text (S) = "replacemen",
              "replace-field backspace must edit replace text");
      Editor.Project_Search_Bar.Toggle_Active_Field (S);
      Editor.Project_Search_Bar.Insert_Text (S, "s");
      Assert (Editor.Project_Search_Bar.Query_Text (S) = "needles",
              "returning to query field must edit query text");
   end Test_Replace_Field_Editing;

   procedure Test_Hit_Test_Zones
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.Project_Search_Bar.Project_Search_Bar_State;
      Config : constant Editor.Project_Search_Bar.Project_Search_Bar_Config := (others => <>);
      Message_Body : constant Editor.Layout.Rect := (X => 0, Y => 0, Width => 800, Height => 400);
      Cell_W : constant Positive := 10;
      Cell_H : constant Positive := 20;
      G : constant Editor.Layout.Rect :=
        Editor.Project_Search_Bar.Geometry (Message_Body, Config, Cell_W, Cell_H);
      Hit : Editor.Project_Search_Bar.Project_Search_Bar_Hit_Result;
   begin
      Hit := Editor.Project_Search_Bar.Hit_Test
        (Message_Body, Config, S, G.X, G.Y, Cell_W, Cell_H);
      Assert (Hit.Zone = Editor.Project_Search_Bar.Outside_Project_Search_Bar,
              "closed bar must hit-test as outside");

      Editor.Project_Search_Bar.Open (S);
      Hit := Editor.Project_Search_Bar.Hit_Test
        (Message_Body, Config, S, G.X - 1, G.Y, Cell_W, Cell_H);
      Assert (Hit.Zone = Editor.Project_Search_Bar.Outside_Project_Search_Bar,
              "point outside overlay must hit-test outside");
      Hit := Editor.Project_Search_Bar.Hit_Test
        (Message_Body, Config, S, G.X + 17 * Cell_W, G.Y, Cell_W, Cell_H);
      Assert (Hit.Zone = Editor.Project_Search_Bar.Project_Search_Query_Field_Zone,
              "field column must hit-test query field");
      Hit := Editor.Project_Search_Bar.Hit_Test
        (Message_Body, Config, S, G.X + 17 * Cell_W, G.Y + Cell_H, Cell_W, Cell_H);
      Assert (Hit.Zone = Editor.Project_Search_Bar.Project_Search_Replace_Field_Zone,
              "second-row field column must hit-test replace field");
      Hit := Editor.Project_Search_Bar.Hit_Test
        (Message_Body, Config, S, G.X + Integer (G.Width) - 21 * Cell_W, G.Y, Cell_W, Cell_H);
      Assert (Hit.Zone = Editor.Project_Search_Bar.Project_Search_Run_Button_Zone,
              "run-button columns must hit-test run button");
      Hit := Editor.Project_Search_Bar.Hit_Test
        (Message_Body, Config, S, G.X + Integer (G.Width) - 14 * Cell_W, G.Y, Cell_W, Cell_H);
      Assert (Hit.Zone = Editor.Project_Search_Bar.Project_Search_Clear_Button_Zone,
              "clear-button columns must hit-test clear button");
      Hit := Editor.Project_Search_Bar.Hit_Test
        (Message_Body, Config, S, G.X + Integer (G.Width) - 6 * Cell_W, G.Y, Cell_W, Cell_H);
      Assert (Hit.Zone = Editor.Project_Search_Bar.Project_Search_Close_Button_Zone,
              "close-button columns must hit-test close button");
      Hit := Editor.Project_Search_Bar.Hit_Test
        (Message_Body, Config, S, G.X + Cell_W, G.Y, Cell_W, Cell_H);
      Assert (Hit.Zone = Editor.Project_Search_Bar.Project_Search_Bar_Background_Zone,
              "non-field/control overlay area must hit-test background");
   end Test_Hit_Test_Zones;

   procedure Register_Tests (T : in out Project_Search_Bar_Test_Case) is
   begin
      Register_Routine (T, Test_Open_Close_Clear'Access, "open close clear");
      Register_Routine (T, Test_Query_Editing'Access, "query editing");
      Register_Routine (T, Test_Replace_Field_Editing'Access, "replace field editing");
      Register_Routine (T, Test_Hit_Test_Zones'Access, "hit-test zones");
   end Register_Tests;

end Editor.Project_Search_Bar.Tests;
