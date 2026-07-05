with Ada.Characters.Handling;
with Editor.Test_Helper;
with Editor.Pending_Transitions;
with Editor.Buffers;
with Ada.Text_IO;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Outline.Fixtures; use Editor.Outline.Fixtures;
with Editor.Ada_Syntax_Core;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Outline_Commands;
with Editor.Feature_Panel;
with Editor.Feature_Panel.Fixtures; use Editor.Feature_Panel.Fixtures;
with Editor.Keybinding_Config;
with Editor.Keybindings;
with Editor.Messages;
with Editor.Outline_Extractor;
with Editor.Outline_Audit;
with Editor.Panel_Focus;
with Editor.State;
with Editor.Render_Model;
with Editor.Workspace_Persistence;

package body Editor.Outline.Structure_Range_Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Executor.Command_Execution_Status;
   use type Editor.Outline.Outline_Item_Kind;
   use type Editor.Outline.Outline_Target_Kind;
   use type Editor.Outline.Outline_Refresh_Status;
   use type Editor.Outline.Outline_Refresh_Failure_Kind;
   use type Editor.Cursors.Cursor_Index;
   use type Editor.Keybindings.Binding_Result;
   use type Editor.Keybindings.Keybinding_Validation_Status;
   use type Editor.Panel_Focus.Focus_Target;
   use type Editor.Outline.Outline_Source_Class;
   use type Editor.Outline.Outline_Freshness;
   use type Editor.Outline_Extractor.Extraction_Status;
   use type Editor.Outline_Extractor.Extraction_Failure_Kind;
   use type Editor.Feature_Panel.Feature_Panel_Row_Kind;
   use type Editor.Feature_Panel.Feature_Panel_Fingerprint;

   function Active_Message_Text (S : Editor.State.State_Type) return String is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (Msg);
      end if;
      return "";
   end Active_Message_Text;

   function Name (T : Structure_Range_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Outline.Structure_Range.Tests");
   end Name;

   procedure Populate_Synthetic_Outline
     (O : in out Outline_State)
   is
      Result : constant Outline_Refresh_Result := Editor.Outline.Fixtures.Populate_Synthetic_Outline (O);
   begin
      pragma Assert (Result.Status = Outline_Refresh_Ok,
                     "synthetic outline fixture refresh succeeds");
   end Populate_Synthetic_Outline;

   function First_Label_Index
     (O     : Outline_State;
      Label : String) return Natural
   is
   begin
      for I in 1 .. Item_Count (O) loop
         if Item_Label (O, I) = Label then
            return I;
         end if;
      end loop;

      return 0;
   end First_Label_Index;

   function Has_Label
     (O     : Outline_State;
      Label : String) return Boolean
   is
   begin
      return First_Label_Index (O, Label) /= 0;
   end Has_Label;

   procedure Assert_Has_Label
     (O       : Outline_State;
      Label   : String;
      Message : String)
   is
   begin
      Assert (Has_Label (O, Label), Message);
   end Assert_Has_Label;

   function Temp_Path (Name : String) return String is
   begin
      return "/tmp/editor_outline_" & Name;
   end Temp_Path;

   procedure Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_If_Exists;

   procedure Write_Text
     (Path : String;
      Text : String)
   is
      package Stream_IO renames Ada.Streams.Stream_IO;
      File  : Stream_IO.File_Type;
      Bytes : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Text'Length));
   begin
      for I in Text'Range loop
         Bytes (Ada.Streams.Stream_Element_Offset (I - Text'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Text (I)));
      end loop;

      Stream_IO.Create (File, Stream_IO.Out_File, Path);
      if Text'Length > 0 then
         Stream_IO.Write (File, Bytes);
      end if;
      Stream_IO.Close (File);
   exception
      when others =>
         if Stream_IO.Is_Open (File) then
            Stream_IO.Close (File);
         end if;
         raise;
   end Write_Text;


   function Contains_Lexical_State_Term (Text : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
   begin
      return Ada.Strings.Fixed.Index (Lower, "scanner") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "sanitized") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "token mask") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "lexical state") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "comment map") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "string map") /= 0;
   end Contains_Lexical_State_Term;

   procedure Test_Open_Selected_Rejects_Out_Of_Range_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "procedure Demo is" & ASCII.LF &
            "begin" & ASCII.LF &
            "null;" & ASCII.LF &
            "end Demo;");
      Replace_Items
        (S.Outline,
         (1 =>
            (Kind        => Outline_Procedure,
             Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Demo"),
             Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 99"),
             Depth       => 0,
             Target_Kind  => Buffer_Position_Target,
             Buffer_Token => S.Registry_Token,
             Line         => 99,
             Column       => 1)));
      Select_Item (S.Outline, 1);
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "out-of-range outline target is rejected before execution");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "failed out-of-range activation does not move caret");
   end Test_Open_Selected_Rejects_Out_Of_Range_Target;

   procedure Test_Ada_Structure_Ranges_Annotate_Outline_Details
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Demo;" & ASCII.LF,
           "demo.adb",
           77,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "structure extraction succeeds");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);

      Assert (Item_Count (O) = 2,
              "keeps ordinary Ada outline rows");
      Assert (Item_Label (O, 1) = "package body Demo",
              "package body row is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-6 body",
              "package body detail carries best-effort line range");
      Assert (Item_Label (O, 2) = "procedure body Run",
              "procedure body row is preserved");
      Assert (Item_Detail (O, 2) = "lines 2-5 body",
              "procedure body detail carries best-effort line range");
   end Test_Ada_Structure_Ranges_Annotate_Outline_Details;

   procedure Test_Current_Symbol_Uses_Smallest_Enclosing_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      if True then" & ASCII.LF &
           "         null;" & ASCII.LF &
           "      end if;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Demo;" & ASCII.LF,
           "demo.adb",
           88,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "current-symbol fixture has package/procedure rows");
      Assert (Item_Detail (O, 1) = "lines 1-8 body",
              "package range includes nested procedure");
      Assert (Item_Detail (O, 2) = "lines 2-7 body",
              "procedure range includes nested if block");

      Assert (Find_Current_Symbol_For_Cursor (O, 88, 5, 10) = 2,
              "current symbol uses smallest enclosing procedure range");
      Update_Current_Symbol_For_Cursor (O, 88, 5, 10);
      Assert (Current_Symbol_Label (O) = "procedure body Run",
              "passive current label reflects range-derived symbol");
      Assert (Find_Current_Symbol_For_Cursor (O, 88, 1, 1) = 1,
              "package line resolves to package body range");
   end Test_Current_Symbol_Uses_Smallest_Enclosing_Range;

   procedure Test_Structure_Ranges_Ignore_Comments_And_String_Keywords
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   -- procedure Fake is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "      Text : constant String := ""end Run;"";" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null; -- end Demo;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Demo;" & ASCII.LF,
           "demo.adb",
           99,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "comment/string safety does not fabricate outline rows");
      Assert (Item_Detail (O, 1) = "lines 1-8 body",
              "package range ignores commented end text");
      Assert (Item_Detail (O, 2) = "lines 3-7 body",
              "procedure range ignores string literal end text");
   end Test_Structure_Ranges_Ignore_Comments_And_String_Keywords;

   procedure Test_Begin_End_Blocks_Do_Not_Truncate_Enclosing_Body
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "   procedure Inner is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Inner;" & ASCII.LF &
           "begin" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end;" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "nested_begin.adb",
           101,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "nested begin/end fixture keeps outer and inner rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "outer procedure label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-10 body",
              "outer procedure range ignores nested anonymous block end");
      Assert (Item_Label (O, 2) = "procedure body Inner",
              "inner procedure label is preserved");
      Assert (Item_Detail (O, 2) = "lines 2-5 body",
              "inner procedure range closes at its own end");
      Assert (Find_Current_Symbol_For_Cursor (O, 101, 8, 7) = 1,
              "nested anonymous block still resolves to enclosing outer procedure");
   end Test_Begin_End_Blocks_Do_Not_Truncate_Enclosing_Body;

   procedure Test_Record_Task_And_Protected_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("type Item is record" & ASCII.LF &
           "   Value : Integer;" & ASCII.LF &
           "end record;" & ASCII.LF &
           "task body Worker is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Worker;" & ASCII.LF &
           "protected body Guard is" & ASCII.LF &
           "   procedure Touch is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Touch;" & ASCII.LF &
           "end Guard;" & ASCII.LF,
           "structures.adb",
           102,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 5,
              "record/task/protected fixture keeps expected outline rows");
      Assert (Item_Label (O, 1) = "record type Item",
              "record type label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-3 record",
              "record type receives a closed range");
      Assert (Item_Label (O, 2) = "field Value",
              "record component row is visible inside the record");
      Assert (Item_Label (O, 3) = "task body Worker",
              "task body label is preserved");
      Assert (Item_Detail (O, 3) = "lines 4-7 body",
              "task body receives a closed range");
      Assert (Item_Label (O, 4) = "protected body Guard",
              "protected body label is preserved");
      Assert (Item_Detail (O, 4) = "lines 8-13 body",
              "protected body receives a closed range over nested procedure");
      Assert (Item_Label (O, 5) = "procedure body Touch",
              "nested protected procedure label is preserved");
      Assert (Item_Detail (O, 5) = "lines 9-12 body",
              "nested protected procedure receives a closed range");
      Assert (Find_Current_Symbol_For_Cursor (O, 102, 11, 7) = 5,
              "current symbol prefers nested protected operation range");
   end Test_Record_Task_And_Protected_Ranges;

   procedure Test_Task_And_Protected_Type_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("task type Worker is" & ASCII.LF &
           "   entry Start;" & ASCII.LF &
           "end Worker;" & ASCII.LF &
           "protected type Guard is" & ASCII.LF &
           "   procedure Touch;" & ASCII.LF &
           "private" & ASCII.LF &
           "   Flag : Boolean := False;" & ASCII.LF &
           "end Guard;" & ASCII.LF,
           "task_protected_types.ads",
           106,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 5,
              "task/protected type fixture includes entry declaration row");
      Assert (Item_Label (O, 1) = "task type Worker",
              "task type label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-3 type",
              "task type receives a closed lexical range");
      Assert (Item_Label (O, 2) = "entry Start",
              "task entry declaration is exposed as a navigable outline row");
      Assert (Item_Detail (O, 2) = "line 2 declaration",
              "task entry declaration keeps declaration detail");
      Assert (Item_Depth (O, 2) = 1,
              "task entry declaration is nested under the task type");
      Assert (Item_Label (O, 3) = "protected type Guard",
              "protected type label is preserved");
      Assert (Item_Detail (O, 3) = "lines 4-8 type",
              "protected type receives a closed lexical range");
      Assert (Item_Label (O, 4) = "procedure Touch",
              "protected operation declaration is visible");
      Assert (Item_Label (O, 5) = "object Flag",
              "private protected object row is visible");
      Assert (Find_Current_Symbol_For_Cursor (O, 106, 7, 4) = 5,
              "current symbol prefers the private protected object row");
   end Test_Task_And_Protected_Type_Ranges;

   procedure Test_Named_End_Mismatch_Does_Not_Close_Root_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Wrong;" & ASCII.LF &
           "procedure Later is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Later;" & ASCII.LF,
           "mismatched_end.adb",
           103,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "mismatched named end fixture keeps both procedure rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "mismatched root end keeps outer row label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "line 1 body") /= 0,
              "mismatched named end does not fabricate a closed root range");
      Assert (Item_Label (O, 2) = "procedure body Later",
              "later procedure label is preserved after mismatch");
      Assert (Item_Detail (O, 2) = "lines 5-8 body",
              "later procedure range is not corrupted by earlier mismatch");
   end Test_Named_End_Mismatch_Does_Not_Close_Root_Range;

   procedure Test_Keyword_End_Forms_Close_Matching_Constructs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end package;" & ASCII.LF &
           "procedure Run is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end procedure;" & ASCII.LF,
           "keyword_end_forms.adb",
           104,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "keyword end fixture keeps package and procedure rows");
      Assert (Item_Label (O, 1) = "package body Demo",
              "keyword package end keeps package row label");
      Assert (Item_Detail (O, 1) = "lines 1-4 body",
              "end package closes package body range");
      Assert (Item_Label (O, 2) = "procedure body Run",
              "keyword procedure end keeps procedure row label");
      Assert (Item_Detail (O, 2) = "lines 5-8 body",
              "end procedure closes procedure body range");
   end Test_Keyword_End_Forms_Close_Matching_Constructs;

   procedure Test_Keyword_End_Mismatch_Does_Not_Close_Root_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end package;" & ASCII.LF &
           "package body Later is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end package;" & ASCII.LF,
           "keyword_end_mismatch.adb",
           105,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "keyword mismatch fixture keeps both rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "keyword mismatch keeps procedure row label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "line 1 body") /= 0,
              "end package does not close procedure body range");
      Assert (Item_Label (O, 2) = "package body Later",
              "later package row is preserved after mismatch");
      Assert (Item_Detail (O, 2) = "lines 5-8 body",
              "matching keyword end still closes later package range");
   end Test_Keyword_End_Mismatch_Does_Not_Close_Root_Range;

   procedure Test_Inline_Balanced_Blocks_Do_Not_Truncate_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   if Ready then null; end if;" & ASCII.LF &
           "   for I in 1 .. 2 loop null; end loop;" & ASCII.LF &
           "   procedure Local is begin null; end Local;" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "inline_balanced_blocks.adb",
           107,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "inline-balanced fixture keeps outer and local rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "inline-balanced outer procedure label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-7 body",
              "one-line if/loop/subprogram do not truncate outer range");
      Assert (Item_Label (O, 2) = "procedure body Local",
              "inline local procedure row is preserved");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "line 5 body") /= 0,
              "single-line local procedure remains start-only");
      Assert (Find_Current_Symbol_For_Cursor (O, 107, 6, 4) = 1,
              "current symbol still resolves inside outer after inline blocks");
   end Test_Inline_Balanced_Blocks_Do_Not_Truncate_Ranges;

   procedure Test_Multiline_Subprogram_Body_Header_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer" & ASCII.LF &
           "  (Value : Integer)" & ASCII.LF &
           "is" & ASCII.LF &
           "   procedure Local" & ASCII.LF &
           "     (Flag : Boolean)" & ASCII.LF &
           "   is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Local;" & ASCII.LF &
           "begin" & ASCII.LF &
           "   Local (True);" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "multiline_body_header.adb",
           108,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "multiline body fixture keeps outer and local rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "multiline body outer label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-12 body",
              "multiline body header receives closed range");
      Assert (Item_Label (O, 2) = "procedure body Local",
              "multiline nested body label is preserved");
      Assert (Item_Detail (O, 2) = "lines 4-9 body",
              "multiline nested body receives closed range");
      Assert (Find_Current_Symbol_For_Cursor (O, 108, 8, 7) = 2,
              "current symbol uses nested multiline body range");
      Assert (Find_Current_Symbol_For_Cursor (O, 108, 11, 4) = 1,
              "current symbol returns outer after nested multiline body");
   end Test_Multiline_Subprogram_Body_Header_Range;

   procedure Test_Split_Subprogram_Spec_Does_Not_Corrupt_Outer_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "   procedure Decl" & ASCII.LF &
           "     (Value : Integer);" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "split_subprogram_spec.adb",
           109,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "split spec fixture keeps outer and declaration rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "split spec outer label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-6 body",
              "split spec does not consume outer body range");
      Assert (Item_Label (O, 2) = "procedure Decl",
              "split spec declaration row is preserved");
      Assert (Item_Detail (O, 2) = "line 2 declaration (Value : Integer)",
              "split spec does not fabricate a body range");
   end Test_Split_Subprogram_Spec_Does_Not_Corrupt_Outer_Range;

   procedure Test_Separate_Body_Stubs_Do_Not_Get_Local_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo.Child is" & ASCII.LF &
           "   separate;" & ASCII.LF &
           "procedure Worker is" & ASCII.LF &
           "   separate;" & ASCII.LF &
           "function Make return Integer is separate;" & ASCII.LF &
           "procedure Real is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end;" & ASCII.LF,
           "separate_body_stubs.adb",
           110,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 4,
              "separate stub fixture keeps all body-like rows");
      Assert (Item_Label (O, 1) = "package body Demo.Child",
              "split separate package stub label is preserved");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "line 1 body") /= 0,
              "split separate package stub has no local range");
      Assert (Item_Label (O, 2) = "procedure body Worker",
              "split separate procedure stub label is preserved");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "line 3 body") /= 0,
              "split separate procedure stub has no local range");
      Assert (Item_Label (O, 3) = "function body Make",
              "same-line separate function stub label is preserved");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "line 5 body") /= 0,
              "same-line separate function stub has no local range");
      Assert (Item_Label (O, 4) = "procedure body Real",
              "following real body label is preserved");
      Assert (Item_Detail (O, 4) = "lines 6-9 body",
              "later real body still receives a closed local range");
   end Test_Separate_Body_Stubs_Do_Not_Get_Local_Ranges;

   procedure Test_String_Tokens_In_Split_Spec_Do_Not_Corrupt_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "   procedure Local" & ASCII.LF &
           "     (Message : String := ""is"");" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "split_spec_string_tokens.adb",
           111,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "split spec string-token fixture keeps outer and declaration rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "split spec string-token outer label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-6 body",
              "string literal is token does not corrupt outer body range");
      Assert (Item_Label (O, 2) = "procedure Local",
              "split spec with string default keeps declaration row");
      Assert (Item_Detail (O, 2) = "line 2 declaration (Message : String :=     )",
              "split spec string default does not fabricate body range");
   end Test_String_Tokens_In_Split_Spec_Do_Not_Corrupt_Ranges;

   procedure Test_Prefixed_Nested_Body_Does_Not_Hide_From_Range_Stack
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "   overriding procedure Inner is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      begin" & ASCII.LF &
           "         null;" & ASCII.LF &
           "      end;" & ASCII.LF &
           "   end Inner;" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "prefixed_nested_body.adb",
           112,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "prefixed nested-body fixture keeps outer and inner rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "prefixed nested-body outer label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-10 body",
              "prefixed nested body participates in enclosing range stack");
      Assert (Item_Label (O, 2) = "procedure body Inner",
              "prefixed nested-body inner label is preserved");
      Assert (Item_Detail (O, 2) = "lines 2-7 body",
              "prefixed nested body receives its own range");
   end Test_Prefixed_Nested_Body_Does_Not_Hide_From_Range_Stack;

   procedure Test_Mismatched_Nested_Block_End_Does_Not_Fabricate_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Bad is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   case Value is" & ASCII.LF &
           "      when others => null;" & ASCII.LF &
           "   end if;" & ASCII.LF &
           "end Bad;" & ASCII.LF &
           "procedure Later is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Later;" & ASCII.LF,
           "mismatched_nested_block.adb",
           113,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "mismatched nested-block fixture keeps both procedure rows");
      Assert (Item_Label (O, 1) = "procedure body Bad",
              "malformed block keeps bad procedure row label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "line 1 body") /= 0,
              "mismatched end if does not close a case block and fabricate a range");
      Assert (Item_Label (O, 2) = "procedure body Later",
              "later procedure label is preserved after malformed block");
      Assert (Item_Detail (O, 2) = "lines 7-10 body",
              "later procedure range survives earlier malformed block");
   end Test_Mismatched_Nested_Block_End_Does_Not_Fabricate_Range;

   procedure Test_Mismatched_Nested_Named_End_Does_Not_Close_Body
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "   procedure Inner is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Wrong;" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Outer;" & ASCII.LF &
           "procedure Later is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Later;" & ASCII.LF,
           "mismatched_nested_named_end.adb",
           114,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 3,
              "mismatched nested named-end fixture keeps all procedure rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "mismatched nested named-end keeps outer row label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "line 1 body") /= 0,
              "end Wrong does not close nested Inner and fabricate outer range");
      Assert (Item_Label (O, 2) = "procedure body Inner",
              "malformed nested body row is preserved");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "line 2 body") /= 0,
              "mismatched nested named end does not fabricate inner range");
      Assert (Item_Label (O, 3) = "procedure body Later",
              "later procedure label survives nested named mismatch");
      Assert (Item_Detail (O, 3) = "lines 9-12 body",
              "later range survives nested named mismatch");
   end Test_Mismatched_Nested_Named_End_Does_Not_Close_Body;

   procedure Test_Labeled_Blocks_Do_Not_Close_Enclosing_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   Demo : begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Demo;" & ASCII.LF &
           "end Demo;" & ASCII.LF &
           "procedure Run is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   Run : declare" & ASCII.LF &
           "      Value : Integer := 0;" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Run;" & ASCII.LF,
           "labeled_blocks.adb",
           115,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "labeled-block fixture keeps package and procedure rows");
      Assert (Item_Label (O, 1) = "package body Demo",
              "labeled block keeps package body label");
      Assert (Item_Detail (O, 1) = "lines 1-6 body",
              "labeled begin block does not close same-named package body");
      Assert (Item_Label (O, 2) = "procedure body Run",
              "labeled declare block keeps procedure body label");
      Assert (Item_Detail (O, 2) = "lines 7-14 body",
              "labeled declare block does not close same-named procedure body");
   end Test_Labeled_Blocks_Do_Not_Close_Enclosing_Range;

   procedure Test_Mismatched_Labeled_Loop_End_Does_Not_Close_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   Loop_Label : loop" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end loop Wrong_Label;" & ASCII.LF &
           "end Outer;" & ASCII.LF &
           "procedure Later is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Later;" & ASCII.LF,
           "mismatched_labeled_loop.adb",
           116,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "mismatched labeled loop fixture keeps both procedure rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "mismatched labeled loop keeps outer procedure label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "line 1 body") /= 0,
              "end loop Wrong_Label does not fabricate outer range");
      Assert (Item_Label (O, 2) = "procedure body Later",
              "later procedure survives labeled loop mismatch");
      Assert (Item_Detail (O, 2) = "lines 7-10 body",
              "later range survives labeled loop mismatch");
   end Test_Mismatched_Labeled_Loop_End_Does_Not_Close_Range;

   procedure Test_Entry_And_Accept_Bodies_Do_Not_Close_Enclosing_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("protected body Device is" & ASCII.LF &
           "   entry Device when Ready is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Device;" & ASCII.LF &
           "end Device;" & ASCII.LF &
           "task body Worker is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   accept Worker do" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Worker;" & ASCII.LF &
           "end Worker;" & ASCII.LF,
           "entry_accept_bodies.adb",
           117,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 3,
              "entry/accept body fixture keeps enclosing rows and entry declaration");
      Assert (Item_Label (O, 1) = "protected body Device",
              "protected body label is preserved across same-named entry body");
      Assert (Item_Detail (O, 1) = "lines 1-6 body",
              "same-named entry end does not close protected body early");
      Assert (Item_Label (O, 2) = "entry Device",
              "protected entry declaration remains navigable");
      Assert (Item_Label (O, 3) = "task body Worker",
              "task body label is preserved across same-named accept body");
      Assert (Item_Detail (O, 3) = "lines 7-12 body",
              "same-named accept end does not close task body early");
   end Test_Entry_And_Accept_Bodies_Do_Not_Close_Enclosing_Range;

   procedure Test_Select_Blocks_Do_Not_Close_Enclosing_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("task body Coordinator is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   select" & ASCII.LF &
           "      accept Start do" & ASCII.LF &
           "         null;" & ASCII.LF &
           "      end Start;" & ASCII.LF &
           "   or" & ASCII.LF &
           "      delay 1.0;" & ASCII.LF &
           "   end select;" & ASCII.LF &
           "end Coordinator;" & ASCII.LF &
           "procedure Later is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Later;" & ASCII.LF,
           "select_blocks.adb",
           118,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "select block fixture keeps enclosing task and later procedure rows");
      Assert (Item_Label (O, 1) = "task body Coordinator",
              "select block keeps task body label");
      Assert (Item_Detail (O, 1) = "lines 1-10 body",
              "end select closes select frame without closing task body early");
      Assert (Item_Label (O, 2) = "procedure body Later",
              "later procedure survives select block matching");
      Assert (Item_Detail (O, 2) = "lines 11-14 body",
              "later procedure range survives select block matching");
   end Test_Select_Blocks_Do_Not_Close_Enclosing_Range;

   procedure Test_Ada_Structure_Ranges_Use_Code_Only_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Real is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      Put_Line (""end Run; begin package Fake is"" );" & ASCII.LF &
           "      C := 'E';" & ASCII.LF &
           "      -- begin" & ASCII.LF &
           "      -- end Run;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Real;",
           "real.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "structure input still extracts real package body and procedure");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "lines 1-9") /= 0,
              "package body range ignores begin/end in strings and comments");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "lines 2-8") /= 0,
              "procedure body range ignores non-code close tokens");
   end Test_Ada_Structure_Ranges_Use_Code_Only_Text;

   overriding procedure Register_Tests (T : in out Structure_Range_Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Open_Selected_Rejects_Out_Of_Range_Target'Access,
         "outline open selected rejects out-of-range target");
      Register_Routine
        (T, Test_Ada_Structure_Ranges_Annotate_Outline_Details'Access,
         "Ada structure ranges annotate outline details");
      Register_Routine
        (T, Test_Current_Symbol_Uses_Smallest_Enclosing_Range'Access,
         "current symbol uses smallest enclosing range");
      Register_Routine
        (T, Test_Structure_Ranges_Ignore_Comments_And_String_Keywords'Access,
         "structure ranges ignore comments and string keywords");
      Register_Routine
        (T, Test_Begin_End_Blocks_Do_Not_Truncate_Enclosing_Body'Access,
         "begin/end blocks do not truncate enclosing body");
      Register_Routine
        (T, Test_Record_Task_And_Protected_Ranges'Access,
         "record task and protected ranges");
      Register_Routine
        (T, Test_Task_And_Protected_Type_Ranges'Access,
         "task and protected type ranges");
      Register_Routine
        (T, Test_Named_End_Mismatch_Does_Not_Close_Root_Range'Access,
         "mismatched named end does not close root range");
      Register_Routine
        (T, Test_Keyword_End_Forms_Close_Matching_Constructs'Access,
         "keyword end forms close matching constructs");
      Register_Routine
        (T, Test_Keyword_End_Mismatch_Does_Not_Close_Root_Range'Access,
         "keyword end mismatch does not close root range");
      Register_Routine
        (T, Test_Inline_Balanced_Blocks_Do_Not_Truncate_Ranges'Access,
         "inline balanced blocks do not truncate ranges");
      Register_Routine
        (T, Test_Multiline_Subprogram_Body_Header_Range'Access,
         "multiline subprogram body header range");
      Register_Routine
        (T, Test_Split_Subprogram_Spec_Does_Not_Corrupt_Outer_Range'Access,
         "split subprogram spec does not corrupt outer range");
      Register_Routine
        (T, Test_Separate_Body_Stubs_Do_Not_Get_Local_Ranges'Access,
         "separate body stubs do not get local ranges");
      Register_Routine
        (T, Test_String_Tokens_In_Split_Spec_Do_Not_Corrupt_Ranges'Access,
         "string tokens in split spec do not corrupt ranges");
      Register_Routine
        (T, Test_Prefixed_Nested_Body_Does_Not_Hide_From_Range_Stack'Access,
         "prefixed nested body does not hide from range stack");
      Register_Routine
        (T, Test_Mismatched_Nested_Block_End_Does_Not_Fabricate_Range'Access,
         "mismatched nested block end does not fabricate range");
      Register_Routine
        (T, Test_Mismatched_Nested_Named_End_Does_Not_Close_Body'Access,
         "mismatched nested named end does not fabricate range");
      Register_Routine
        (T, Test_Labeled_Blocks_Do_Not_Close_Enclosing_Range'Access,
         "labeled blocks do not close enclosing range");
      Register_Routine
        (T, Test_Mismatched_Labeled_Loop_End_Does_Not_Close_Range'Access,
         "mismatched labeled loop end does not fabricate range");
      Register_Routine
        (T, Test_Entry_And_Accept_Bodies_Do_Not_Close_Enclosing_Range'Access,
         "entry and accept bodies do not close enclosing range");
      Register_Routine
        (T, Test_Select_Blocks_Do_Not_Close_Enclosing_Range'Access,
         "select blocks do not close enclosing range");
      Register_Routine
        (T, Test_Ada_Structure_Ranges_Use_Code_Only_Text'Access,
         "Ada structure ranges use code-only text");
   end Register_Tests;

end Editor.Outline.Structure_Range_Tests;
