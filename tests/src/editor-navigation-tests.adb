with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.State;

package body Editor.Navigation.Tests is

   overriding function Name
     (T : Navigation_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Navigation");
   end Name;

   procedure Test_Clamp_Position
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Target : Navigation_Target;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "de");

      Target := Clamp_Position (S, 99, 99);
      Assert (Target.Row = 1, "clamp must clamp row to final document row");
      Assert (Target.Column = 2, "clamp must clamp column to final line length");
   end Test_Clamp_Position;

   procedure Test_Character_Movement_Crosses_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Navigation_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "ab" & ASCII.LF & "c");

      R := Move_Character (S, 0, 2, Forward);
      Assert (R.Target.Row = 1 and then R.Target.Column = 0,
              "character-forward at line end must move to next line start");

      R := Move_Character (S, 1, 0, Backward);
      Assert (R.Target.Row = 0 and then R.Target.Column = 2,
              "character-backward at line start must move to previous line end");
   end Test_Character_Movement_Crosses_Lines;


   procedure Test_Character_Movement_Within_Line_And_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Navigation_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "ab");

      R := Move_Character (S, 0, 0, Forward);
      Assert (R.Target.Row = 0 and then R.Target.Column = 1,
              "character-forward within a line must increment column");

      R := Move_Character (S, 0, 1, Backward);
      Assert (R.Target.Row = 0 and then R.Target.Column = 0,
              "character-backward within a line must decrement column");

      R := Move_Character (S, 0, 0, Backward);
      Assert (R.Target.Row = 0 and then R.Target.Column = 0,
              "character-backward at document start must stay at start");
      Assert (not R.Found,
              "character-backward at document start must report no movement found");

      R := Move_Character (S, 0, 2, Forward);
      Assert (R.Target.Row = 0 and then R.Target.Column = 2,
              "character-forward at document end must stay at end");
      Assert (not R.Found,
              "character-forward at document end must report no movement found");
   end Test_Character_Movement_Within_Line_And_Boundaries;

   procedure Test_Line_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Navigation_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "defg");

      R := Move_Line_Boundary (S, 1, 2, Backward);
      Assert (R.Target.Row = 1 and then R.Target.Column = 0,
              "line-start navigation must target column zero");

      R := Move_Line_Boundary (S, 1, 2, Forward);
      Assert (R.Target.Row = 1 and then R.Target.Column = 4,
              "line-end navigation must target line length");
   end Test_Line_Boundaries;

   procedure Test_Document_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Navigation_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "de");

      R := Move_Document_Boundary (S, Backward);
      Assert (R.Target.Row = 0 and then R.Target.Column = 0,
              "document-start navigation must target row 0 column 0");

      R := Move_Document_Boundary (S, Forward);
      Assert (R.Target.Row = 1 and then R.Target.Column = 2,
              "document-end navigation must target final row and final column");
   end Test_Document_Boundaries;

   procedure Test_Word_Movement
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Navigation_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "hello world,++again");

      R := Move_Word (S, 0, 0, Forward);
      Assert (R.Target.Row = 0 and then R.Target.Column = 6,
              "word-forward from word start must land at next word start");

      R := Move_Word (S, 0, 2, Forward);
      Assert (R.Target.Row = 0 and then R.Target.Column = 6,
              "word-forward from inside word must land at next word start");

      R := Move_Word (S, 0, 6, Backward);
      Assert (R.Target.Row = 0 and then R.Target.Column = 0,
              "word-backward from word start must land at previous word start");

      R := Move_Word (S, 0, 14, Backward);
      Assert (R.Target.Row = 0 and then R.Target.Column = 11,
              "word-backward must treat symbol runs separately from word runs");
   end Test_Word_Movement;


   procedure Test_Word_Movement_Whitespace_End_And_Line_Crossing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Navigation_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one   " & ASCII.LF & "two !! three");

      R := Move_Word (S, 0, 3, Forward);
      Assert (R.Target.Row = 1 and then R.Target.Column = 0,
              "word-forward from whitespace must skip to next non-whitespace across lines");

      R := Move_Word (S, 1, 0, Backward);
      Assert (R.Target.Row = 0 and then R.Target.Column = 0,
              "word-backward across a line break must find the previous word start");

      R := Move_Word (S, 1, 4, Forward);
      Assert (R.Target.Row = 1 and then R.Target.Column = 7,
              "word-forward on a symbol run must skip symbols and following whitespace");

      R := Move_Word (S, 1, 12, Forward);
      Assert (R.Target.Row = 1 and then R.Target.Column = 12,
              "word-forward at document end must stay at end");

      R := Move_Word (S, 0, 0, Backward);
      Assert (R.Target.Row = 0 and then R.Target.Column = 0,
              "word-backward at document start must stay at start");
   end Test_Word_Movement_Whitespace_End_And_Line_Crossing;

   procedure Test_Line_And_Page_Preserve_Virtual_Column
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Navigation_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abcdef" & ASCII.LF & "x" & ASCII.LF & "yz");

      R := Move_Line (S, 0, 5, Forward, 5);
      Assert (R.Target.Row = 1 and then R.Target.Column = 1,
              "line-down must clamp to shorter target line");
      Assert (R.Preserve_Virtual_Column,
              "line movement must preserve the preferred virtual column");

      R := Move_Page (S, 0, 5, Forward, 3, 5);
      Assert (R.Target.Row = 2 and then R.Target.Column = 2,
              "page-down must move by page row count minus one and clamp column");
      Assert (R.Preserve_Virtual_Column,
              "page movement must preserve the preferred virtual column");

      R := Move_Page (S, 2, 2, Backward, 3, 5);
      Assert (R.Target.Row = 0 and then R.Target.Column = 5,
              "page-up must retreat by page row count minus one and preserve column");
      Assert (R.Preserve_Virtual_Column,
              "page-up must preserve the preferred virtual column");
   end Test_Line_And_Page_Preserve_Virtual_Column;

   overriding procedure Register_Tests
     (T : in out Navigation_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clamp_Position'Access,
         "Phase 65 clamp position");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Movement_Crosses_Lines'Access,
         "Phase 65 character movement crosses lines");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Movement_Within_Line_And_Boundaries'Access,
         "Phase 65 character movement within line and boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Boundaries'Access,
         "Phase 65 line boundary movement");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Document_Boundaries'Access,
         "Phase 65 document boundary movement");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Movement'Access,
         "Phase 65 word movement");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Movement_Whitespace_End_And_Line_Crossing'Access,
         "Phase 65 word movement whitespace end and line crossing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_And_Page_Preserve_Virtual_Column'Access,
         "Phase 65 line and page virtual column policy");
   end Register_Tests;

end Editor.Navigation.Tests;
