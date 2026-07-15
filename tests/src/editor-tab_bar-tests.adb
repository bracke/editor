with Editor.Test_Temp;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Layout;
with Editor.State;

package body Editor.Tab_Bar.Tests is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Tab_Bar.Tab_Bar_Zone;
   use type Editor.Tab_Bar.Tab_Visual_State;

   function Snapshot
     (Registry : Editor.Buffers.Buffer_Registry) return Tab_Buffer_Summary_Array
   is
      Count : constant Natural := Editor.Buffers.Buffer_Count (Registry);
      Result : Tab_Buffer_Summary_Array (1 .. Count);
   begin
      for I in Result'Range loop
         Result (I) := Editor.Buffers.Summary_At (Registry, I);
      end loop;
      return Result;
   end Snapshot;

   overriding function Name
     (T : Tab_Bar_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Tab_Bar");
   end Name;

   procedure Build_Three_Buffers
     (Registry : in out Editor.Buffers.Buffer_Registry;
      First    : out Editor.Buffers.Buffer_Id;
      Second   : out Editor.Buffers.Buffer_Id;
      Third    : out Editor.Buffers.Buffer_Id)
   is
   begin
      First := Editor.Buffers.Add_Buffer_From_File
        (Registry, Editor.Test_Temp.Base & "/alpha.adb", "alpha.adb", "alpha");
      Second := Editor.Buffers.Add_Buffer_From_File
        (Registry, Editor.Test_Temp.Base & "/beta.adb", "beta.adb", "beta");
      Third := Editor.Buffers.Add_Buffer_From_File
        (Registry, Editor.Test_Temp.Base & "/gamma.adb", "gamma.adb", "gamma");
   end Build_Three_Buffers;

   procedure Test_Height_Follows_Config
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Enabled_Config  : constant Tab_Bar_Config :=
        (Enabled => True, Show_Close_Buttons => True,
         Minimum_Tab_Width => 8, Maximum_Tab_Width => 24);
      Disabled_Config : constant Tab_Bar_Config :=
        (Enabled => False, Show_Close_Buttons => True,
         Minimum_Tab_Width => 8, Maximum_Tab_Width => 24);
   begin
      Assert (Height_In_Rows (Enabled_Config) = 1,
              "Enabled tab bar must reserve one row");
      Assert (Height_In_Rows (Disabled_Config) = 0,
              "Disabled tab bar must reserve zero rows");
   end Test_Height_Follows_Config;

   procedure Test_Hit_Test_Tab_Bodies_And_Close_Zone
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      First    : Editor.Buffers.Buffer_Id;
      Second   : Editor.Buffers.Buffer_Id;
      Third    : Editor.Buffers.Buffer_Id;
      Layout   : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Cell_W   : constant Positive := Editor.Layout.Cell_W;
      Cell_H   : constant Positive := Editor.Layout.Cell_H;
      Width    : constant Natural := 800;
      Hit      : Tab_Hit_Result;
      Tab_W    : constant Natural := Tab_Width (Layout.Tab_Bar, Cell_W);
   begin
      Build_Three_Buffers (Registry, First, Second, Third);

      Hit := Hit_Test
        (Layout.Tab_Bar, Snapshot (Registry), Width, Cell_W, Cell_H,
         X => Integer (Cell_W), Y => Integer (Cell_H / 2));
      Assert (Hit.Zone = Tab_Body_Zone,
              "Click inside first tab must hit the tab body");
      Assert (Hit.Buffer_Id = First,
              "First tab body must map to first buffer id");

      Hit := Hit_Test
        (Layout.Tab_Bar, Snapshot (Registry), Width, Cell_W, Cell_H,
         X => Integer (Tab_W + Cell_W), Y => Integer (Cell_H / 2));
      Assert (Hit.Zone = Tab_Body_Zone,
              "Click inside second tab must hit the tab body");
      Assert (Hit.Buffer_Id = Second,
              "Second tab body must map to second buffer id");

      Hit := Hit_Test
        (Layout.Tab_Bar, Snapshot (Registry), Width, Cell_W, Cell_H,
         X => Integer (Tab_W - 2 * Cell_W), Y => Integer (Cell_H / 2));
      Assert (Hit.Zone = Tab_Close_Zone,
              "Click inside close cell must hit the close zone");
      Assert (Hit.Buffer_Id = First,
              "Close zone must carry its tab buffer id");
   end Test_Hit_Test_Tab_Bodies_And_Close_Zone;

   procedure Test_Hit_Test_Outside_And_Background
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      First    : Editor.Buffers.Buffer_Id;
      Second   : Editor.Buffers.Buffer_Id;
      Third    : Editor.Buffers.Buffer_Id;
      Layout   : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Cell_W   : constant Positive := Editor.Layout.Cell_W;
      Cell_H   : constant Positive := Editor.Layout.Cell_H;
      Width    : constant Natural := 800;
      Hit      : Tab_Hit_Result;
   begin
      Build_Three_Buffers (Registry, First, Second, Third);

      Hit := Hit_Test
        (Layout.Tab_Bar, Snapshot (Registry), Width, Cell_W, Cell_H,
         X => 0, Y => Integer (Cell_H + 1));
      Assert (Hit.Zone = Outside_Tab_Bar,
              "Y below the tab bar must be outside");

      Hit := Hit_Test
        (Layout.Tab_Bar, Snapshot (Registry), Width, Cell_W, Cell_H,
         X => Integer (Width - Cell_W), Y => Integer (Cell_H / 2));
      Assert (Hit.Zone = Tab_Bar_Background_Zone,
              "Blank tab bar space must be a handled background zone");
      Assert (Hit.Buffer_Id = Editor.Buffers.No_Buffer,
              "Blank tab bar space must not carry a buffer id");
   end Test_Hit_Test_Outside_And_Background;

   procedure Test_Summary_Visual_State_And_Truncation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      First    : Editor.Buffers.Buffer_Id;
      Second   : Editor.Buffers.Buffer_Id;
      Third    : Editor.Buffers.Buffer_Id;
      State    : access Editor.Buffers.Buffer_State;
      Summary  : Editor.Buffers.Buffer_Summary;
   begin
      Build_Three_Buffers (Registry, First, Second, Third);
      State := Editor.Buffers.Buffer_Access (Registry, Third);
      Editor.State.Set_Dirty (State.all, True);
      Summary := Editor.Buffers.Summary_For (Registry, Third);

      Assert (Summary.Is_Active,
              "Most recently added buffer is active in registry order setup");
      Assert (Visual_State (Summary) = Dirty_Active_Tab,
              "Dirty active summary must map to dirty active visual state");
      Assert (Display_Text (Summary, 6) = "gam...",
              "Tab display text must truncate deterministically with ellipsis");
   end Test_Summary_Visual_State_And_Truncation;

   procedure Test_Overflow_Tab_Is_Not_Hit_Testable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      First    : Editor.Buffers.Buffer_Id;
      Second   : Editor.Buffers.Buffer_Id;
      Third    : Editor.Buffers.Buffer_Id;
      Layout   : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Cell_W   : constant Positive := Editor.Layout.Cell_W;
      Cell_H   : constant Positive := Editor.Layout.Cell_H;
      Width    : constant Natural := Tab_Width (Layout.Tab_Bar, Cell_W) * 2;
      Hit      : Tab_Hit_Result;
   begin
      Build_Three_Buffers (Registry, First, Second, Third);

      Hit := Hit_Test
        (Layout.Tab_Bar, Snapshot (Registry), Width, Cell_W, Cell_H,
         X => Integer (Width - Cell_W), Y => Integer (Cell_H / 2));
      Assert (Hit.Zone /= Tab_Body_Zone or else Hit.Buffer_Id /= Third,
              "Third tab hidden by overflow must not be hit-testable");
   end Test_Overflow_Tab_Is_Not_Hit_Testable;


   procedure Test_Duplicate_Display_Names_Are_Disambiguated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      First    : Editor.Buffers.Buffer_Id;
      Second   : Editor.Buffers.Buffer_Id;
      First_Summary  : Editor.Buffers.Buffer_Summary;
      Second_Summary : Editor.Buffers.Buffer_Summary;
   begin
      First := Editor.Buffers.Add_Buffer_From_File
        (Registry, Editor.Test_Temp.Base & "/one/main.adb", "main.adb", "one");
      Second := Editor.Buffers.Add_Buffer_From_File
        (Registry, Editor.Test_Temp.Base & "/two/main.adb", "main.adb", "two");

      First_Summary := Editor.Buffers.Summary_For (Registry, First);
      Second_Summary := Editor.Buffers.Summary_For (Registry, Second);

      Assert (To_String (First_Summary.Display_Name) = "main.adb — one",
              "duplicate tab labels should include the first buffer parent");
      Assert (To_String (Second_Summary.Display_Name) = "main.adb — two",
              "duplicate tab labels should include the second buffer parent");
   end Test_Duplicate_Display_Names_Are_Disambiguated;

   procedure Test_Empty_Registry_Hit_Test_Is_Background
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Layout   : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Hit      : Tab_Hit_Result;
   begin
      Hit := Hit_Test
        (Layout.Tab_Bar, Snapshot (Registry), 800, Editor.Layout.Cell_W, Editor.Layout.Cell_H,
         X => Integer (Editor.Layout.Cell_W),
         Y => Integer (Editor.Layout.Cell_H / 2));

      Assert (Hit.Zone = Tab_Bar_Background_Zone,
              "empty tab bar should still consume tab-row background clicks");
      Assert (Hit.Buffer_Id = Editor.Buffers.No_Buffer,
              "empty tab bar background must not carry a buffer id");
      Assert (Empty_Display_Text (7) = "No o...",
              "empty tab label should truncate deterministically");
   end Test_Empty_Registry_Hit_Test_Is_Background;

   overriding procedure Register_Tests
     (T : in out Tab_Bar_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Height_Follows_Config'Access,
         "tab bar height follows enabled config");
      Register_Routine
        (T, Test_Hit_Test_Tab_Bodies_And_Close_Zone'Access,
         "tab hit-test maps tab bodies and close zones to buffer ids");
      Register_Routine
        (T, Test_Hit_Test_Outside_And_Background'Access,
         "tab hit-test distinguishes outside and blank background");
      Register_Routine
        (T, Test_Summary_Visual_State_And_Truncation'Access,
         "tab visual state and text truncation are deterministic");
      Register_Routine
        (T, Test_Overflow_Tab_Is_Not_Hit_Testable'Access,
         "overflow tabs are not hit-testable");
      Register_Routine
        (T, Test_Duplicate_Display_Names_Are_Disambiguated'Access,
         "duplicate tab labels are disambiguated");
      Register_Routine
        (T, Test_Empty_Registry_Hit_Test_Is_Background'Access,
         "empty tab row is a safe background target");
   end Register_Tests;

end Editor.Tab_Bar.Tests;
