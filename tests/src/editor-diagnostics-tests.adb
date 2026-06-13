with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Cursors;

package body Editor.Diagnostics.Tests is

   use type Editor.Diagnostics.Diagnostic_Index;

   function Name
     (T : Diagnostics_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Diagnostics.Tests");
   end Name;

   procedure Add_At
     (D        : in out Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Row      : Natural;
      Col      : Natural;
      Severity : Editor.Diagnostics.Diagnostic_Severity)
   is
      Start : constant Editor.Cursors.Cursor_Index := Editor.Cursors.Cursor_Index (Row * 100 + Col);
   begin
      Editor.Diagnostics.Add
        (D,
         Start_Index  => Start,
         End_Index    => Start + 1,
         Start_Row    => Row,
         Start_Column => Col,
         Severity     => Severity);
   end Add_At;

   procedure Test_Ordering
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Diagnostics.Diagnostic_Vectors.Vector;
   begin
      Add_At (D, 2, 1, Editor.Diagnostics.Warning);
      Add_At (D, 1, 9, Editor.Diagnostics.Warning);
      Add_At (D, 1, 9, Editor.Diagnostics.Error);
      Add_At (D, 1, 4, Editor.Diagnostics.Hint);

      Assert
        (Editor.Diagnostics.Ordered_Diagnostic_Index_At (D, 1) = 4,
         "ordering should prefer lower row/column before severity");
      Assert
        (Editor.Diagnostics.Ordered_Diagnostic_Index_At (D, 2) = 3,
         "same position should prefer higher severity");
      Assert
        (Editor.Diagnostics.Ordered_Diagnostic_Index_At (D, 3) = 2,
         "same position should then preserve insertion order");
      Assert
        (Editor.Diagnostics.Ordered_Diagnostic_Index_At (D, 4) = 1,
         "later row should sort last");
   end Test_Ordering;

   procedure Test_Next_Previous_Wrap
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D     : Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Found : Boolean := False;
   begin
      Add_At (D, 0, 5, Editor.Diagnostics.Warning);
      Add_At (D, 2, 3, Editor.Diagnostics.Error);

      Assert
        (Editor.Diagnostics.Next_Diagnostic_After (D, 0, 5, True, Found) = 2
         and then Found,
         "next diagnostic should find the first later diagnostic");
      Assert
        (Editor.Diagnostics.Next_Diagnostic_After (D, 9, 0, True, Found) = 1
         and then Found,
         "next diagnostic should wrap to first when requested");
      Assert
        (Editor.Diagnostics.Previous_Diagnostic_Before (D, 2, 3, True, Found) = 1
         and then Found,
         "previous diagnostic should find the first earlier diagnostic");
      Assert
        (Editor.Diagnostics.Previous_Diagnostic_Before (D, 0, 0, True, Found) = 2
         and then Found,
         "previous diagnostic should wrap to last when requested");
   end Test_Next_Previous_Wrap;

   procedure Test_Dominant_Row_And_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D      : Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Found  : Boolean := False;
      Target : Editor.Diagnostics.Diagnostic_Target;
   begin
      Add_At (D, 3, 9, Editor.Diagnostics.Warning);
      Add_At (D, 3, 5, Editor.Diagnostics.Warning);
      Add_At (D, 3, 7, Editor.Diagnostics.Error);

      Assert
        (Editor.Diagnostics.Dominant_Diagnostic_On_Row (D, 3, Found) = 3
         and then Found,
         "dominant row diagnostic should prefer error over warning");
      Assert
        (Editor.Diagnostics.Dominant_Diagnostic_On_Row (D, 4, Found) =
         Editor.Diagnostics.No_Diagnostic
         and then not Found,
         "row without diagnostics should not find a dominant diagnostic");

      Target := Editor.Diagnostics.Target_For_Diagnostic (D, 2);
      Assert
        (Target.Found and then Target.Row = 3 and then Target.Column = 5,
         "target should expose diagnostic start row and column");
      Target := Editor.Diagnostics.Target_For_Diagnostic (D, 99);
      Assert (not Target.Found, "invalid target index should not be found");
   end Test_Dominant_Row_And_Target;


   procedure Test_Note_And_Unknown_Ordering
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Diagnostics.Diagnostic_Vectors.Vector;
   begin
      Add_At (D, 1, 1, Editor.Diagnostics.Unknown);
      Add_At (D, 1, 1, Editor.Diagnostics.Note);
      Add_At (D, 1, 1, Editor.Diagnostics.Information);

      Assert
        (Editor.Diagnostics.Ordered_Diagnostic_Index_At (D, 1) = 2,
         "core Diagnostics supports first-class note severity before information");
      Assert
        (Editor.Diagnostics.Ordered_Diagnostic_Index_At (D, 3) = 1,
         "core Diagnostics supports first-class unknown severity as lowest priority");
   end Test_Note_And_Unknown_Ordering;

   procedure Register_Tests
     (T : in out Diagnostics_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Ordering'Access,
         "Phase 61 orders diagnostics by row, column, severity, insertion");
      Register_Routine
        (T, Test_Next_Previous_Wrap'Access,
         "Phase 61 navigates next/previous diagnostics with wrapping");
      Register_Routine
        (T, Test_Dominant_Row_And_Target'Access,
         "Phase 61 chooses dominant row diagnostics and targets");
      Register_Routine
        (T, Test_Note_And_Unknown_Ordering'Access,
         "Phase 557 core Diagnostics supports note and unknown severities");
   end Register_Tests;

end Editor.Diagnostics.Tests;
