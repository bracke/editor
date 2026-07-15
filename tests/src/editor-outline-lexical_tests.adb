with Editor.Test_Temp;
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

package body Editor.Outline.Lexical_Tests is

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

   function Name (T : Lexical_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Outline.Lexical.Tests");
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
      return Editor.Test_Temp.Base & "/editor_outline_" & Name;
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

   procedure Test_Ada_Outline_Ignores_Comments_And_Is_Case_Insensitive
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("-- package Commented is" & ASCII.LF &
           "   -- procedure Hidden;" & ASCII.LF &
           "PACKAGE Demo IS -- procedure Hidden_Trailing;" & ASCII.LF &
           "PrOcEdUrE Run; -- function Not_Seen return Boolean;" & ASCII.LF &
           "function Visible return Natural;");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "Ada scanner ignores full-line and trailing comments");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "Ada keyword matching is case-insensitive for packages");
      Assert (Item_Label (O, 2) = "procedure Run",
              "Ada keyword matching is case-insensitive for procedures");
      Assert (Item_Label (O, 3) = "function Visible",
              "trailing comments do not poison following declarations");
   end Test_Ada_Outline_Ignores_Comments_And_Is_Case_Insensitive;

   procedure Test_Ada_Outline_Label_Excludes_Profile_And_Comment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Editor.Outline is -- package Hidden is" & ASCII.LF &
           "procedure Refresh (Force : Boolean); -- function Hidden return Boolean" & ASCII.LF &
           "function Item_Count return Natural; -- trailing comment",
           "editor-outline.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "labels ignore profiles and trailing comments");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Editor.Outline",
              "package body label excludes trailing is and comment");
      Assert (Item_Label (O, 2) = "procedure Refresh",
              "procedure label excludes profile and comment");
      Assert (Item_Label (O, 3) = "function Item_Count",
              "function label excludes return type and comment");
   end Test_Ada_Outline_Label_Excludes_Profile_And_Comment;

   procedure Test_Ada_Outline_String_Comment_Marker_Is_Not_Comment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   Message : constant String := ""not -- a comment"";" & ASCII.LF &
           "   procedure Run; -- real comment" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "string literals containing comment markers do not break scanning");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "constant Message",
              "package constant row remains visible");
      Assert (Item_Label (O, 3) = "procedure Run",
              "real trailing comment is still ignored after string-literal line");
   end Test_Ada_Outline_String_Comment_Marker_Is_Not_Comment;

   procedure Test_Ada_Lexical_Sanitizer_Preserves_Columns
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String :=
        "X : String := ""-- procedure Fake""; C := 'P'; Y := Integer'Image (Value); -- end;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      String_Column  : constant Natural := Ada.Strings.Fixed.Index (Line, "procedure");
      Comment_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "-- end");
      Char_Column    : constant Natural := Ada.Strings.Fixed.Index (Line, "'P'");
      Attr_Column    : constant Natural := Ada.Strings.Fixed.Index (Line, "'Image");
      Unmatched_Line : constant String :=
        "Y := Integer'Image (Value); Z := Value + 1;";
      Z_Column       : constant Natural := Ada.Strings.Fixed.Index (Unmatched_Line, "Z :=");
   begin
      Assert (Sanitized'Length = Line'Length,
              "sanitized Ada line preserves length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure") = 0,
              "sanitized Ada line masks string declarations");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "--") = 0,
              "sanitized Ada line masks comments");
      Assert (Sanitized (Line'First) = 'X',
              "sanitized Ada line preserves code columns");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (String_Column)),
              "string text is non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Comment_Column)),
              "comment text is non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Char_Column)),
              "simple character literal is non-code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Attr_Column)),
              "Ada attribute apostrophe remains code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Unmatched_Line, Positive (Z_Column)),
              "unmatched apostrophe in attribute-like text does not suppress later code");
   end Test_Ada_Lexical_Sanitizer_Preserves_Columns;

   procedure Test_Ada_Outline_Ignores_Comments_Strings_And_Characters
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("-- package Fake is" & ASCII.LF &
           "-- procedure Hidden;" & ASCII.LF &
           "package Real is" & ASCII.LF &
           "   S1 : constant String := ""procedure Fake is"";" & ASCII.LF &
           "   S2 : constant String := ""quoted """" package Hidden is """" text"";" & ASCII.LF &
           "   C  : Character := 'P';" & ASCII.LF &
           "   Img : String := Integer'Image (42);" & ASCII.LF &
           "   procedure Run; -- function Fake return Integer;" & ASCII.LF &
           "end Real;",
           "real.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 6,
              "outline ignores fake declarations in comments and strings while keeping real objects");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "real package near comments extracts");
      Assert_Has_Label (O, "procedure Run",
              "real procedure with inline comment extracts");
      Assert (Item_Line (O, First_Label_Index (O, "procedure Run")) = 8,
              "original source target line is preserved");
   end Test_Ada_Outline_Ignores_Comments_Strings_And_Characters;

   procedure Test_Ada_Record_Range_Ignores_End_Record_In_Non_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           "   type State is record" & ASCII.LF &
           "      Text : String := ""end record;"";" & ASCII.LF &
           "      -- end record;" & ASCII.LF &
           "      Value : Integer;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "end Real;",
           "record_strings.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "record fixture extracts package, record type, and real fields only");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, First_Label_Index (O, "record type State")) = "record type State",
              "record label is based on real type declaration");
      Assert (Ada.Strings.Fixed.Index
                (Item_Detail (O, First_Label_Index (O, "record type State")), "lines 2-6") /= 0,
              "record range ignores end record inside strings and comments");
   end Test_Ada_Record_Range_Ignores_End_Record_In_Non_Code;

   procedure Test_Ada_Nested_Block_Range_Ignores_End_If_In_Non_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Real is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      if Ready then" & ASCII.LF &
           "         Put_Line (""end if; end Run;"");" & ASCII.LF &
           "         -- end if;" & ASCII.LF &
           "         null;" & ASCII.LF &
           "      end if;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Real;",
           "nested_if_strings.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "nested-block fixture extracts package body and procedure only");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "lines 1-10") /= 0,
              "package range ignores end text inside nested string/comment lines");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "lines 2-9") /= 0,
              "procedure range ignores end if/end procedure text inside strings/comments");
   end Test_Ada_Nested_Block_Range_Ignores_End_If_In_Non_Code;

   procedure Test_Ada_Unterminated_String_Is_Line_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           "   Broken : constant String := ""procedure Fake is" & ASCII.LF &
           "   procedure After_Broken;" & ASCII.LF &
           "end Real;",
           "real.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "unterminated string masks only its physical line while keeping real constants");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert_Has_Label (O, "procedure After_Broken",
              "valid declaration after unterminated string line extracts");
   end Test_Ada_Unterminated_String_Is_Line_Local;

   procedure Test_Ada_Doubled_Quotes_And_Comment_Markers_Are_Non_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String :=
        "S := ""quoted """" package Fake is -- end """" text""; X := 1;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Package_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "package");
      Marker_Column  : constant Natural := Ada.Strings.Fixed.Index (Line, "-- end");
      X_Column       : constant Natural := Ada.Strings.Fixed.Index (Line, "X := 1");
   begin
      Assert (Sanitized'Length = Line'Length,
              "doubled-quote sanitizer preserves line length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package") = 0,
              "doubled quotes do not expose fake package text");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "--") = 0,
              "comment marker inside a string is masked as string text");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Package_Column)),
              "package token inside doubled-quote string is non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Marker_Column)),
              "comment marker inside doubled-quote string is non-code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (X_Column)),
              "code after a closed doubled-quote string remains code");
   end Test_Ada_Doubled_Quotes_And_Comment_Markers_Are_Non_Code;

   procedure Test_Ada_Generic_Prelude_Ignores_Comment_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("-- generic" & ASCII.LF &
           "-- package Fake is" & ASCII.LF &
           "procedure Plain;" & ASCII.LF &
           "generic" & ASCII.LF &
           "procedure Real_Generic;",
           "generic_comments.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "generic prelude comments do not add fake rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "procedure Plain",
              "generic text inside comments does not mark next declaration generic");
      Assert (Item_Label (O, 2) = "generic procedure Real_Generic",
              "real generic prelude still applies to the following declaration");
   end Test_Ada_Generic_Prelude_Ignores_Comment_Text;

   procedure Test_Ada_Lexical_Scanner_Is_Bounded_And_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Ada.Strings.Unbounded;
      Big       : Unbounded_String := To_Unbounded_String ("package Real is ");
      Sanitized : Unbounded_String;
      Repeat    : Unbounded_String;
   begin
      for I in 1 .. 200 loop
         Append (Big, Character'Val (34) & "procedure Fake_" & Natural'Image (I) & " is" & Character'Val (34) & " ");
         Append (Big, "-- begin end package procedure function type");
      end loop;

      Sanitized := To_Unbounded_String
        (Editor.Ada_Syntax_Core.Sanitize_Line (To_String (Big)));
      Repeat := To_Unbounded_String
        (Editor.Ada_Syntax_Core.Sanitize_Line (To_String (Big)));

      Assert (Length (Sanitized) = Length (Big),
              "large lexical sanitization preserves line length");
      Assert (Sanitized = Repeat,
              "large lexical sanitization is deterministic for the same snapshot line");
      Assert (Ada.Strings.Fixed.Index (To_String (Sanitized), "procedure Fake_") = 0,
              "large string/comment-heavy line masks declaration-like text");
      Assert (Ada.Strings.Fixed.Index (To_String (Sanitized), "--") = 0,
              "large string/comment-heavy line masks comment markers");
      Assert (Ada.Strings.Fixed.Index (To_String (Sanitized), "package Real is") /= 0,
              "large string/comment-heavy line preserves leading code");
   end Test_Ada_Lexical_Scanner_Is_Bounded_And_Deterministic;

   procedure Test_Ada_Character_Quote_Literal_And_Spaces_Are_Masked
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Quote      : constant Character := Character'Val (16#27#);
      Line       : constant String :=
        "A : Character := " & Quote & " " & Quote &
        "; Q : Character := " & Quote & Quote & Quote & Quote &
        "; procedure Real;";
      Sanitized  : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Space_Lit  : constant Natural := Ada.Strings.Fixed.Index (Line, Quote & " " & Quote);
      Quote_Lit  : constant Natural := Ada.Strings.Fixed.Index (Line, Quote & Quote & Quote & Quote);
      Proc_Col   : constant Natural := Ada.Strings.Fixed.Index (Line, "procedure Real");
   begin
      Assert (Sanitized'Length = Line'Length,
              "quote/space character literal masking preserves columns");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Space_Lit)),
              "space character literal starts as non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Quote_Lit)),
              "quote character literal starts as non-code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Proc_Col)),
              "code after quote character literal remains code");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Real") /= 0,
              "declaration after character literals remains visible");
   end Test_Ada_Character_Quote_Literal_And_Spaces_Are_Masked;

   procedure Test_Ada_Valid_Declarations_After_Closed_Non_Code_Spans
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           "   S : constant String := ""function Fake return Integer"";" & ASCII.LF &
           "   procedure After_String;" & ASCII.LF &
           "   C : Character := 'P';" & ASCII.LF &
           "   function After_Char return Integer;" & ASCII.LF &
           "   I : String := Integer'Image (42);" & ASCII.LF &
           "   subtype Index is Natural;" & ASCII.LF &
           "end Real;",
           "after_non_code.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "inline declarations after closed strings/chars/attributes extract");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "package remains first real row");
      Assert_Has_Label (O, "procedure After_String",
              "declaration after closed string line extracts");
      Assert_Has_Label (O, "function After_Char",
              "declaration after simple character literal line extracts");
      Assert_Has_Label (O, "subtype Index",
              "declaration after attribute apostrophe line extracts");
   end Test_Ada_Valid_Declarations_After_Closed_Non_Code_Spans;

   procedure Test_Ada_Comment_Starts_After_Closed_String_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String :=
        "S := ""-- not a comment inside string""; I := Integer'Image (42); -- procedure Fake; end Real;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Inner_Marker : constant Natural := Ada.Strings.Fixed.Index (Line, "-- not");
      Attr_Column  : constant Natural := Ada.Strings.Fixed.Index (Line, "'Image");
      Comment_Col  : constant Natural := Ada.Strings.Fixed.Index (Line, "-- procedure");
   begin
      Assert (Sanitized'Length = Line'Length,
              "post-string comment sanitizer preserves line length");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Inner_Marker)),
              "- inside a closed string remains string text, not a comment boundary");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Attr_Column)),
              "attribute apostrophe between string and comment remains code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Comment_Col)),
              "- after a closed string starts the actual line comment");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "fake declaration after post-string comment marker is masked");
   end Test_Ada_Comment_Starts_After_Closed_String_Only;

   procedure Test_Ada_Generic_Prelude_Ignores_String_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           "   Marker : constant String := ""generic"";" & ASCII.LF &
           "   procedure Plain;" & ASCII.LF &
           "   Text : constant String := ""generic package Hidden is"";" & ASCII.LF &
           "   function Still_Plain return Integer;" & ASCII.LF &
           "end Real;",
           "generic_string.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "generic prelude text in strings does not create or decorate rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert_Has_Label (O, "procedure Plain",
              "string generic marker does not mark procedure generic");
      Assert_Has_Label (O, "function Still_Plain",
              "string generic package text does not affect later function");
   end Test_Ada_Generic_Prelude_Ignores_String_Text;

   procedure Test_Ada_Command_Metadata_And_Keybindings_Carry_No_Lexical_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Ada.Strings.Unbounded;
      Covered : constant array (Positive range 1 .. 5) of Editor.Commands.Command_Id :=
        (Editor.Commands.Command_Refresh_Outline,
         Editor.Commands.Command_Open_Selected_Outline_Item,
         Editor.Commands.Command_Next_Outline_Symbol,
         Editor.Commands.Command_Previous_Outline_Symbol,
         Editor.Commands.Command_Reveal_Current_Outline_Symbol);
      D    : Editor.Commands.Command_Descriptor;
      Bind : Editor.Keybindings.Command_Keybinding_Info;
      Name : Unbounded_String := Null_Unbounded_String;
   begin
      Editor.Keybindings.Reset_To_Defaults;

      for Id of Covered loop
         D := Editor.Commands.Descriptor (Id);
         Name := To_Unbounded_String (Editor.Commands.Stable_Command_Name (Id));
         Assert (D.Id = Id,
                 "descriptor keeps canonical outline command id");
         Assert (Editor.Commands.Is_Visible_In_Palette (Id),
                 "outline command remains palette-visible without scanner payload");
         Assert (Editor.Commands.Is_Bindable_Command (Id),
                 "outline command remains keybinding-addressable by command id only");
         Assert (not Contains_Lexical_State_Term (To_String (Name)),
                 "stable command name carries no lexical scanner payload");
         Assert (not Contains_Lexical_State_Term (To_String (D.Name)),
                 "command label carries no lexical scanner payload");
         Assert (not Contains_Lexical_State_Term (To_String (D.Description)),
                 "command description carries no lexical scanner payload");
         Assert (not Contains_Lexical_State_Term (To_String (D.Target_Prompt_Label)),
                 "command target prompt carries no lexical scanner payload");

         Bind := Editor.Keybindings.Primary_Binding_For_Command (Id);
         if Bind.Has_Binding then
            Assert (not Contains_Lexical_State_Term (To_String (Bind.Display)),
                    "keybinding display carries chord text only, not scanner state");
         end if;
      end loop;
   end Test_Ada_Command_Metadata_And_Keybindings_Carry_No_Lexical_State;

   procedure Test_Ada_Availability_And_Render_Do_Not_Run_Lexical_Scan
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S               : Editor.State.State_Type;
      Snap            : Editor.Render_Model.Render_Snapshot;
      A               : Editor.Commands.Command_Availability;
      Outline_Before  : Natural;
      Panel_Before    : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Messages_Before : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "package Real is" & ASCII.LF &
            "   procedure Old;" & ASCII.LF &
            "end Real;");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Item_Count (S.Outline) = 2,
              "boundary fixture starts from an explicit lexical-safe refresh");

      Outline_Before := Fingerprint (S.Outline);
      Panel_Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Messages_Before := Editor.Messages.Count (S.Messages);

      Editor.State.Load_Text
        (S, "-- procedure Fake_Comment;" & ASCII.LF &
            "package Changed is" & ASCII.LF &
            "   S : constant String := ""procedure Fake_String is"";" & ASCII.LF &
            "   procedure New_Real;" & ASCII.LF &
            "end Changed;");

      Outline_Before := Fingerprint (S.Outline);
      Panel_Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Messages_Before := Editor.Messages.Count (S.Messages);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Editor.Commands.Is_Available (A),
              "refresh availability remains available with an active buffer");
      Assert (Fingerprint (S.Outline) = Outline_Before,
              "availability does not scan changed Ada text");
      Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel) = Panel_Before,
              "availability does not reproject lexical-safe rows");
      Assert (Editor.Messages.Count (S.Messages) = Messages_Before,
              "availability emits no lexical scan feedback");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Fingerprint (S.Outline) = Outline_Before,
              "render snapshot does not run lexical scanning or refresh outline");
      Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel) = Panel_Before,
              "render snapshot observes existing feature-panel rows only");
      Assert (Snap.Length = Editor.State.Current_Text (S)'Length,
              "render snapshot still reflects current buffer text without sanitizer output");
   end Test_Ada_Availability_And_Render_Do_Not_Run_Lexical_Scan;

   procedure Test_Ada_Workspace_Snapshot_Excludes_Lexical_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary  : Ada.Strings.Unbounded.Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "package Real is" & ASCII.LF &
            "   S : constant String := ""procedure Fake_String is"";" & ASCII.LF &
            "   -- package Fake_Comment is" & ASCII.LF &
            "   procedure Run;" & ASCII.LF &
            "end Real;");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Item_Count (S.Outline) = 3,
              "persistence fixture has lexical-safe outline rows before snapshot");

      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Summary := Ada.Strings.Unbounded.To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snapshot));

      Assert (Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary), "lexical") = 0,
              "workspace debug summary excludes lexical scanner state");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary), "sanitized") = 0,
              "workspace debug summary excludes sanitized source text");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary), "token") = 0,
              "workspace debug summary excludes token masks");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary), "Fake_String") = 0,
              "workspace snapshot does not persist source or string-literal scanner text");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary), "Fake_Comment") = 0,
              "workspace snapshot does not persist comment scanner text");
   end Test_Ada_Workspace_Snapshot_Excludes_Lexical_State;

   procedure Test_Ada_Detection_Ignores_Non_Code_Only_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Fake_Only : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("-- package Fake is" & ASCII.LF &
           "Banner : constant String := ""procedure Hidden is"";" & ASCII.LF &
           "Text   : constant String := ""begin end package Fake;"";" & ASCII.LF &
           "-- function Hidden return Integer;",
           "scratch");
      Real_Ada : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("-- package Fake is" & ASCII.LF &
           "Banner : constant String := ""procedure Hidden is"";" & ASCII.LF &
           "package Real is" & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Real;",
           "scratch");
      Fake_Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Fake_Only);
      Real_Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Real_Ada);
      O : Outline_State;
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Fake_Result) = 0,
              "extensionless Ada detection ignores comment/string-only fake declarations");
      Assert (Editor.Outline_Extractor.Item_Count (Real_Result) = 3,
              "extensionless Ada detection still enables real declarations after non-code fakes");
      Editor.Outline_Extractor.Apply_To_Outline (Real_Result, O);
      Assert_Has_Label (O, "package Real",
              "real extensionless package survives sanitized Ada detection");
      Assert_Has_Label (O, "procedure Run",
              "real extensionless procedure survives sanitized Ada detection");
   end Test_Ada_Detection_Ignores_Non_Code_Only_Buffer;

   procedure Test_Ada_CRLF_And_Trailing_CR_Do_Not_Leak_Non_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.CR & ASCII.LF &
           "   S : constant String := ""end Real; procedure Fake is"";" & ASCII.CR & ASCII.LF &
           "   -- package Hidden is" & ASCII.CR & ASCII.LF &
           "   procedure Run; -- function Hidden return Integer;" & ASCII.CR & ASCII.LF &
           "end Real;" & ASCII.CR,
           "crlf.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "CRLF Ada input masks strings/comments without leaking fake declarations");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "CRLF package row remains real source only");
      Assert_Has_Label (O, "procedure Run",
              "CRLF inline comment fake function is ignored");
      Assert (Item_Line (O, First_Label_Index (O, "procedure Run")) = 4,
              "CRLF source line mapping remains original and stable");
   end Test_Ada_CRLF_And_Trailing_CR_Do_Not_Leak_Non_Code;

   procedure Test_Ada_Labelled_Loops_Ignore_Labels_In_Non_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Real is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      Outer : loop" & ASCII.LF &
           "         Put_Line (""end loop Outer; end Run;"");" & ASCII.LF &
           "         -- end loop Outer;" & ASCII.LF &
           "         exit;" & ASCII.LF &
           "      end loop Outer;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Real;",
           "labelled_loop.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "labelled-loop fixture extracts only real package/procedure rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "lines 2-9") /= 0,
              "labelled loop closes from real code, not string/comment label text");
   end Test_Ada_Labelled_Loops_Ignore_Labels_In_Non_Code;

   procedure Test_Ada_Tabs_And_Mixed_Case_Keywords_Remain_Lexically_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String := ASCII.HT & "Package Real is -- PrOcEdUrE Fake;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          (ASCII.HT & "-- PaCkAgE Hidden is" & ASCII.LF &
           ASCII.HT & "Package Real is" & ASCII.LF &
           ASCII.HT & "   Text : constant String := ""FuNcTiOn Hidden return Integer;"";" & ASCII.LF &
           ASCII.HT & "   PrOcEdUrE Run; -- TyPe Hidden is null record;" & ASCII.LF &
           ASCII.HT & "end Real;",
           "mixed_case.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized'Length = Line'Length,
              "tabbed mixed-case line preserves original length");
      Assert (Sanitized (Line'First) = ASCII.HT,
              "leading tab in code remains code, not sanitizer output");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Characters.Handling.To_Lower (Sanitized), "procedure fake") = 0,
              "mixed-case fake declaration after comment is masked");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "mixed-case real Ada declarations extract while non-code fakes are ignored");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "mixed-case package label normalizes from real code only");
      Assert_Has_Label (O, "procedure Run",
              "mixed-case procedure label normalizes from real code only");
   end Test_Ada_Tabs_And_Mixed_Case_Keywords_Remain_Lexically_Safe;

   procedure Test_Ada_Comment_After_Dash_Character_Literal_Is_Real_Comment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String := "C : Character := '-'; -- procedure Fake;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Dash_Column : constant Positive := Positive (Ada.Strings.Fixed.Index (Line, "'-'"));
      Comment_Column : constant Positive := Positive (Ada.Strings.Fixed.Index (Line, "--"));
   begin
      Assert (Sanitized'Length = Line'Length,
              "dash character/comment line preserves columns");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Dash_Column),
              "dash character literal is masked as non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Comment_Column),
              "comment after dash character literal starts a real comment");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "fake declaration after character-literal comment marker is masked");
   end Test_Ada_Comment_After_Dash_Character_Literal_Is_Real_Comment;

   procedure Test_Ada_String_Semicolon_Does_Not_Close_Multiline_Declaration
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           "   procedure Run" & ASCII.LF &
           "     (Name : String := ""; procedure Fake;"";" & ASCII.LF &
           "      Value : Integer);" & ASCII.LF &
           "   procedure After_Run;" & ASCII.LF &
           "end Real;",
           "string_semicolon.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "semicolon inside string does not close multi-line declaration or create fake row");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "procedure Run",
              "split procedure remains one real row despite string semicolon text");
      Assert (Item_Line (O, 2) = 2,
              "split procedure target remains original declaration line");
      Assert (Item_Label (O, 3) = "procedure After_Run",
              "declaration after string-semicolon window still extracts");
   end Test_Ada_String_Semicolon_Does_Not_Close_Multiline_Declaration;

   procedure Test_Ada_Operator_Functions_Remain_Code_While_Quoted_Fakes_Are_Masked
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Operators is" & ASCII.LF &
           "   Text : constant String := ""function """"+"""" return Integer;"";" & ASCII.LF &
           "   -- function ""-"" return Integer;" & ASCII.LF &
           "   function ""+"" (Left, Right : Integer) return Integer;" & ASCII.LF &
           "   function ""and"" (Left, Right : Boolean) return Boolean; -- function Fake return Boolean;" & ASCII.LF &
           "end Operators;",
           "operators.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "quoted operator fakes in comments/strings do not produce rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Operators",
              "operator fixture keeps real package body row");
      Assert_Has_Label (O, "function ""+""",
              "real quoted operator function remains code despite string masking elsewhere");
      Assert_Has_Label (O, "function ""and""",
              "alphabetic quoted operator function remains code");
      Assert (Item_Line (O, First_Label_Index (O, "function ""+""")) = 4,
              "operator target line maps to original real declaration");
   end Test_Ada_Operator_Functions_Remain_Code_While_Quoted_Fakes_Are_Masked;

   procedure Test_Ada_Null_And_Control_Characters_Do_Not_Break_Line_Scan
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Nul : constant Character := Character'Val (0);
      Line : constant String :=
        "Name : constant String := ""procedure" & Nul & "Fake is""; -- package Hidden is";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           Line & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Real;",
           "control.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized'Length = Line'Length,
              "control-character string/comment line preserves length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure") = 0,
              "declaration text before embedded control character inside string is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package Hidden") = 0,
              "declaration text after comment marker on control line is masked");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "embedded control characters in non-code spans do not create fake rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "control-character fixture keeps real package row");
      Assert_Has_Label (O, "procedure Run",
              "control-character fixture keeps later real procedure row");
   end Test_Ada_Null_And_Control_Characters_Do_Not_Break_Line_Scan;

   procedure Test_Ada_Adjacent_And_Empty_Strings_Do_Not_Leak_Comments
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Line_Empty : constant String :=
        "   Empty : constant String := """"; -- procedure Hidden;";
      Line_Adjacent : constant String :=
        "   Joined : constant String := ""package Hidden is"" & ""end Hidden;""; -- function Hidden return Integer;";
      Sanitized_Empty : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line_Empty);
      Sanitized_Adjacent : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line_Adjacent);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           Line_Empty & ASCII.LF &
           Line_Adjacent & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Real;",
           "adjacent_strings.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized_Empty'Length = Line_Empty'Length,
              "empty-string/comment line preserves columns");
      Assert (Sanitized_Adjacent'Length = Line_Adjacent'Length,
              "adjacent-string/comment line preserves columns");
      Assert (Ada.Strings.Fixed.Index (Sanitized_Empty, "procedure Hidden") = 0,
              "declaration after comment following empty string is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized_Adjacent, "package Hidden") = 0,
              "declaration text inside first adjacent string is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized_Adjacent, "end Hidden") = 0,
              "end text inside second adjacent string is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized_Adjacent, "function Hidden") = 0,
              "declaration after adjacent-string comment is masked");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "adjacent and empty strings do not leak fake outline rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "adjacent-string fixture keeps real package row");
      Assert_Has_Label (O, "procedure Run",
              "adjacent-string fixture keeps later real procedure row");
   end Test_Ada_Adjacent_And_Empty_Strings_Do_Not_Leak_Comments;

   procedure Test_Ada_Double_Quote_Character_Literal_Does_Not_Start_String
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Quote_Char : constant Character := Character'Val (16#22#);
      Quote_Literal : constant String := "'" & Quote_Char & "'";
      Line : constant String :=
        "   Quote : Character := " & Quote_Literal &
        "; -- procedure Hidden; package Also_Hidden is";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           Line & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Real;",
           "quote_character.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized'Length = Line'Length,
              "double-quote character literal preserves columns");
      Assert (Ada.Strings.Fixed.Index (Sanitized, Quote_Literal) = 0,
              "double-quote character literal span is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Hidden") = 0,
              "comment after double-quote character literal masks fake procedure");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package Also_Hidden") = 0,
              "comment after double-quote character literal masks fake package");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Ada.Strings.Fixed.Index (Line, "Quote")),
              "code before double-quote character literal remains code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Ada.Strings.Fixed.Index (Line, "procedure Hidden")),
              "fake declaration after character-literal comment is non-code");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "double-quote character literal does not leak fake outline rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "double-quote character fixture keeps real package row");
      Assert_Has_Label (O, "procedure Run",
              "double-quote character fixture keeps later real procedure row");
   end Test_Ada_Double_Quote_Character_Literal_Does_Not_Start_String;

   procedure Test_Ada_Token_Helpers_Use_Unified_Sanitized_View
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   function Semi" & ASCII.LF &
           "     return Character is (';'" & ASCII.LF &
           "     ); -- function Fake return Integer is (0);" & ASCII.LF &
           "   function Later return Integer;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "unified token helpers ignore semicolon inside character literal and fake comment expression");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "package remains the real root row");
      Assert (Item_Label (O, 2) = "expression function Semi",
              "character-literal semicolon does not end the split expression function early");
      Assert (Item_Label (O, 3) = "function Later",
              "scanner resumes after the real code semicolon on the continuation line");
      Assert (Item_Line (O, 2) = 2,
              "split expression-function target remains the declaration line");
   end Test_Ada_Token_Helpers_Use_Unified_Sanitized_View;

   procedure Test_Ada_Code_Column_Uses_Same_Mask_As_Sanitizer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String :=
        "   Gap : String := ""a b"";   procedure Real; -- package Fake is";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      String_Word_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "a b");
      String_Space_Column : constant Natural := String_Word_Column + 1;
      Code_Space_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, ";   procedure") + 1;
      Real_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "procedure Real");
      Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "package Fake");
   begin
      Assert (Sanitized'Length = Line'Length,
              "shared lexical mask preserves sanitized line length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "a b") = 0,
              "shared lexical mask hides string payload text");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package Fake") = 0,
              "shared lexical mask hides trailing comment text");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Real") = Real_Column,
              "shared lexical mask preserves real code columns");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (String_Word_Column)),
              "code-column helper agrees that string letters are non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (String_Space_Column)),
              "code-column helper agrees that string spaces are non-code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Code_Space_Column)),
              "code-column helper keeps ordinary code whitespace as code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Real_Column)),
              "code-column helper keeps real declaration text as code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Fake_Column)),
              "code-column helper masks fake declaration text in comments");
   end Test_Ada_Code_Column_Uses_Same_Mask_As_Sanitizer;

   procedure Test_Ada_Lexical_Public_Helpers_Handle_Slices_And_Empty_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Whole : constant String :=
        "prefix procedure Real; -- procedure Fake;";
      Line : constant String := Whole (8 .. Whole'Last);
      Empty : constant String := "";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Fake_Index : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "procedure Fake");
      Fake_Column : constant Positive :=
        Positive (Fake_Index - Line'First + 1);
   begin
      Assert (Sanitized'First = Line'First
                and then Sanitized'Last = Line'Last,
              "sanitizer preserves non-1-based slice bounds");
      Assert (Sanitized'Length = Line'Length,
              "sanitizer preserves non-1-based slice length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Real") = Line'First,
              "non-1-based sanitized slice keeps real code at original index");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "non-1-based sanitized slice masks comment fake declaration");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column (Line, 1),
              "code-column helper treats column one of a slice as source column one");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Fake_Column),
              "code-column helper masks fake declaration in non-1-based slices");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column (Empty, 1),
              "code-column helper returns false for empty lines");
      Assert (Editor.Ada_Syntax_Core.Sanitize_Line (Empty)'Length = 0,
              "sanitizer accepts empty lines without stored state");
   end Test_Ada_Lexical_Public_Helpers_Handle_Slices_And_Empty_Lines;

   procedure Test_Ada_Attribute_And_Qualified_Literal_Apostrophes_Remain_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String :=
        "   Image : constant String := Integer'Image (Value) & Character'Val (16#2D#); -- procedure Fake;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Attribute_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "Integer'Image");
      Qualified_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "Character'Val");
      Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "procedure Fake");
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          (Line & ASCII.LF &
           "procedure Real;" & ASCII.LF &
           "package Also_Real is end Also_Real;");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Assert (Ada.Strings.Fixed.Index (Sanitized, "Integer'Image") = Attribute_Column,
              "attribute apostrophe remains code in sanitized text");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "Character'Val") = Qualified_Column,
              "qualified-name apostrophe remains code in sanitized text");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "fake declaration after attribute/qualified expression comment is masked");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Attribute_Column)),
              "code-column helper keeps attribute prefix as code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Qualified_Column)),
              "code-column helper keeps qualified literal helper as code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Fake_Column)),
              "code-column helper masks comment text after qualified expression");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 3,
              "attribute/qualified expression comments do not create fake outline rows");
      Assert_Has_Label (O, "procedure Real",
              "real declaration after attribute/qualified expression still extracts");
      Assert_Has_Label (O, "package Also_Real",
              "following real package still extracts after apostrophe-heavy line");
      Assert (Item_Line (O, First_Label_Index (O, "procedure Real")) = 2,
              "real declaration target line remains mapped after apostrophe-heavy line");
   end Test_Ada_Attribute_And_Qualified_Literal_Apostrophes_Remain_Code;

   procedure Test_Ada_Adjacent_Character_Literals_Do_Not_Suppress_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String :=
        "   Pair : String := 'A' & 'B' & Character'Val (16#2D#); -- package Fake is";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      First_Char_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "'A'");
      Second_Char_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "'B'");
      Join_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "& 'B'");
      Qualified_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "Character'Val");
      Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "package Fake");
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          (Line & ASCII.LF &
           "procedure Real;" & ASCII.LF &
           "package Later is end Later;",
           "adjacent_character_literals.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Assert (Sanitized'Length = Line'Length,
              "adjacent character literals preserve line length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "'A'") = 0,
              "first adjacent character literal is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "'B'") = 0,
              "second adjacent character literal is masked independently");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "Character'Val") = Qualified_Column,
              "qualified attribute-like call remains code after character literals");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package Fake") = 0,
              "trailing comment after adjacent character literals is masked");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (First_Char_Column)),
              "first character literal is non-code by column helper");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Second_Char_Column)),
              "second character literal is non-code by column helper");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Join_Column)),
              "code between adjacent character literals remains code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Qualified_Column)),
              "qualified-name apostrophe remains code after adjacent literals");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Fake_Column)),
              "fake declaration in trailing comment remains non-code");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 3,
              "adjacent character literals and trailing comments do not create fake outline rows");
      Assert_Has_Label (O, "procedure Real",
              "real procedure after adjacent character literals still extracts");
      Assert_Has_Label (O, "package Later",
              "following package after adjacent character literals still extracts");
      Assert (Item_Line (O, First_Label_Index (O, "procedure Real")) = 2,
              "target mapping survives adjacent character literal line");
   end Test_Ada_Adjacent_Character_Literals_Do_Not_Suppress_Code;

   procedure Test_Ada_Character_String_Comment_Sequence_Uses_One_Line_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Quote_Char : constant Character := Character'Val (16#22#);
      Quote_Literal : constant String := "'" & Quote_Char & "'";
      Line : constant String :=
        "   Q : Character := " & Quote_Literal &
        "; S : constant String := ""procedure Fake is""; -- package Hidden is";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Character_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, Quote_Literal);
      String_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "procedure Fake");
      Comment_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "package Hidden");
      Second_Object_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "S : constant");
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           Line & ASCII.LF &
           "   procedure Real;" & ASCII.LF &
           "end Demo;",
           "character_string_comment_sequence.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized'Length = Line'Length,
              "character/string/comment sequence preserves line length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, Quote_Literal) = 0,
              "double-quote character literal is masked before later string");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "later string payload is masked after character literal");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package Hidden") = 0,
              "trailing comment is masked after character and string spans");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "S : constant") = Second_Object_Column,
              "scanner resumes code between character literal and string literal");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Character_Column)),
              "character literal remains non-code in mixed sequence");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (String_Column)),
              "string payload remains non-code in mixed sequence");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Comment_Column)),
              "trailing comment remains non-code in mixed sequence");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Second_Object_Column)),
              "object code between masked spans remains code");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 4,
              "mixed character/string/comment line does not create fake outline rows");
      Assert (Item_Label (O, 1) = "package Demo",
              "mixed sequence keeps real package row");
      Assert_Has_Label (O, "procedure Real",
              "mixed sequence keeps later real procedure row");
      Assert (Item_Line (O, First_Label_Index (O, "procedure Real")) = 3,
              "mixed sequence preserves later target line mapping");
   end Test_Ada_Character_String_Comment_Sequence_Uses_One_Line_State;

   procedure Test_Ada_Comment_Quotes_And_Chars_Are_Line_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Line : constant String :=
        "      Flag := True; -- ""end Run;"" 'P' procedure Fake;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Flag_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "Flag");
      Quote_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "end Run");
      Char_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "'P'");
      Fake_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "procedure Fake");
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           Line & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Demo;",
           "comment_quote_character_line_local.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized'Length = Line'Length,
              "comment with quotes/chars preserves line length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "Flag") = Flag_Column,
              "code before comment remains visible before quoted comment text");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "end Run") = 0,
              "quoted close text inside comments remains non-code");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "declaration-like text after quoted comment text remains masked");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Flag_Column)),
              "code-column helper preserves code before comment quote text");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Quote_Column)),
              "quote-delimited text inside a comment is not string-state code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Char_Column)),
              "character-looking text inside a comment remains comment text");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Fake_Column)),
              "fake declaration after comment quote/char text remains non-code");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "quoted/comment character text does not create fake outline rows");
      Assert (Item_Label (O, 1) = "package body Demo",
              "package body remains the first real row");
      Assert (Item_Label (O, 2) = "procedure body Run",
              "procedure body remains the only nested real row");
      Assert (Item_Detail (O, 2) = "lines 2-6 body",
              "commented quoted end text does not close the procedure range early");
   end Test_Ada_Comment_Quotes_And_Chars_Are_Line_Local;

   procedure Test_Ada_Public_Sanitizer_Does_Not_Carry_String_State_Across_Line_Break
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Multi_Line : constant String :=
        "S : constant String := ""procedure Fake" & ASCII.LF &
        "procedure Real; -- function Fake return Integer;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Multi_Line);
      String_Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "procedure Fake");
      Real_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "procedure Real");
      Comment_Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "function Fake");
   begin
      Assert (Sanitized'Length = Multi_Line'Length,
              "multi-line public sanitizer preserves length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "unterminated string text before embedded line break is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Real") = Real_Column,
              "public sanitizer resets string state after embedded line break");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "function Fake") = 0,
              "trailing comment after embedded line break remains masked");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (String_Fake_Column)),
              "string text before embedded line break is non-code by column helper");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Real_Column)),
              "code after embedded line break is code by column helper");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Comment_Fake_Column)),
              "comment text after embedded line break is non-code by column helper");
   end Test_Ada_Public_Sanitizer_Does_Not_Carry_String_State_Across_Line_Break;

   procedure Test_Ada_Public_Sanitizer_Treats_CRLF_As_Non_Code_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Multi_Line : constant String :=
        "S : constant String := ""procedure Fake" & ASCII.CR & ASCII.LF &
        "procedure Real; -- function Fake return Integer;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Multi_Line);
      CR_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, String'(1 => ASCII.CR));
      LF_Column : constant Natural := CR_Column + 1;
      Real_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "procedure Real");
      Comment_Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "function Fake");
   begin
      Assert (Sanitized'Length = Multi_Line'Length,
              "CRLF public sanitizer preserves length");
      Assert (CR_Column > 0 and then LF_Column <= Multi_Line'Length,
              "CRLF fixture contains adjacent CRLF boundary");
      Assert (Sanitized (Sanitized'First + CR_Column - 1) = ' ',
              "CR in direct helper input is non-code");
      Assert (Sanitized (Sanitized'First + LF_Column - 1) = ' ',
              "LF in direct helper input is non-code");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "pre-CRLF unterminated string text is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Real") = Real_Column,
              "scanning resumes after CRLF boundary");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "function Fake") = 0,
              "trailing comment after CRLF remains masked");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (CR_Column)),
              "CR boundary is non-code by column helper");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (LF_Column)),
              "LF boundary is non-code by column helper");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Real_Column)),
              "code after CRLF boundary is code by column helper");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Comment_Fake_Column)),
              "comment after CRLF boundary is non-code by column helper");
   end Test_Ada_Public_Sanitizer_Treats_CRLF_As_Non_Code_Boundary;

   procedure Test_Ada_Public_Sanitizer_Does_Not_Carry_Comment_State_Across_Line_Break
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Multi_Line : constant String :=
        "procedure Real; -- procedure Fake;" & ASCII.LF &
        "function Later return Integer; -- package Fake is";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Multi_Line);
      LF_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, String'(1 => ASCII.LF));
      Real_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "procedure Real");
      Comment_Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "procedure Fake");
      Later_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "function Later");
      Later_Comment_Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "package Fake");
   begin
      Assert (Sanitized'Length = Multi_Line'Length,
              "multi-line comment public sanitizer preserves length");
      Assert (LF_Column > 0,
              "comment-state fixture contains embedded LF boundary");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Real") = Real_Column,
              "code before first comment remains visible");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "comment before embedded line break is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "function Later") = Later_Column,
              "scanning resumes after comment-line LF boundary");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package Fake") = 0,
              "second-line trailing comment remains masked");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (LF_Column)),
              "LF after comment line is non-code by column helper");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Real_Column)),
              "first-line real declaration remains code by column helper");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Comment_Fake_Column)),
              "first-line comment declaration remains non-code by column helper");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Later_Column)),
              "second-line code is visible after comment reset");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Later_Comment_Fake_Column)),
              "second-line comment declaration remains non-code by column helper");
   end Test_Ada_Public_Sanitizer_Does_Not_Carry_Comment_State_Across_Line_Break;

   procedure Test_Ada_Objects_Discriminants_And_Character_Literals_Are_Extracted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Model is" & ASCII.LF &
           "   Count : Natural := 0;" & ASCII.LF &
           "   Alias : Natural renames Count;" & ASCII.LF &
           "   type Kind is (Small, Medium);" & ASCII.LF &
           "   type Item (K : Kind; Size : Natural := 0) is record" & ASCII.LF &
           "      Name : Natural;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "   type Token is ('A', 'Z');" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "object/discriminant/character-literal extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 13,
              "package, objects, enum literals, discriminants, field, and char literals are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "object Count",
              "package-level variable object row is extracted");
      Assert (Item_Label (O, 3) = "object Alias renames",
              "package-level object renaming row is extracted");
      Assert (Item_Detail (O, 2) = "line 2 object default-expression",
              "ordinary object detail identifies object form");
      Assert (Item_Detail (O, 3) = "line 3 renames",
              "object renaming detail identifies renames form");
      Assert (Item_Label (O, 7) = "record type Item",
              "discriminated record type row is preserved");
      Assert (Item_Label (O, 8) = "discriminant K",
              "first discriminant row is extracted");
      Assert (Item_Label (O, 9) = "discriminant Size",
              "second discriminant row is extracted");
      Assert (Item_Label (O, 10) = "field Name",
              "record component after discriminants is still extracted");
      Assert (Item_Kind (O, 8) = Outline_Discriminant,
              "discriminant row uses discriminant kind");
      Assert (Item_Depth (O, 8) = Item_Depth (O, 7) + 1,
              "discriminant depth is nested under record type");
      Assert (Item_Detail (O, 8) = "line 5 discriminant",
              "discriminant detail identifies declaration form");
      Assert (Item_Label (O, 11) = "enum type Token",
              "character literal enumeration type is extracted");
      Assert (Item_Label (O, 12) = "literal 'A'",
              "first character literal enumeration row is extracted");
      Assert (Item_Label (O, 13) = "literal 'Z'",
              "second character literal enumeration row is extracted");
   end Test_Ada_Objects_Discriminants_And_Character_Literals_Are_Extracted;

   overriding procedure Register_Tests (T : in out Lexical_Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Ada_Outline_Ignores_Comments_And_Is_Case_Insensitive'Access,
                        "Ada outline ignores comments and is case-insensitive");
      Register_Routine (T, Test_Ada_Outline_Label_Excludes_Profile_And_Comment'Access,
                        "Ada outline labels exclude profile and comment");
      Register_Routine (T, Test_Ada_Outline_String_Comment_Marker_Is_Not_Comment'Access,
                        "Ada outline ignores comment marker inside strings");
      Register_Routine
        (T, Test_Ada_Lexical_Sanitizer_Preserves_Columns'Access,
         "Ada lexical sanitizer preserves columns");
      Register_Routine
        (T, Test_Ada_Outline_Ignores_Comments_Strings_And_Characters'Access,
         "Ada outline ignores comments strings and characters");
      Register_Routine
        (T, Test_Ada_Record_Range_Ignores_End_Record_In_Non_Code'Access,
         "Ada record range ignores end record in non-code text");
      Register_Routine
        (T, Test_Ada_Nested_Block_Range_Ignores_End_If_In_Non_Code'Access,
         "Ada nested block range ignores end if in non-code text");
      Register_Routine
        (T, Test_Ada_Unterminated_String_Is_Line_Local'Access,
         "Ada unterminated string is line-local");
      Register_Routine
        (T, Test_Ada_Doubled_Quotes_And_Comment_Markers_Are_Non_Code'Access,
         "Ada doubled quotes and comment markers are non-code");
      Register_Routine
        (T, Test_Ada_Generic_Prelude_Ignores_Comment_Text'Access,
         "Ada generic prelude ignores comment text");
      Register_Routine
        (T, Test_Ada_Lexical_Scanner_Is_Bounded_And_Deterministic'Access,
         "Ada lexical scanner is bounded and deterministic");
      Register_Routine
        (T, Test_Ada_Character_Quote_Literal_And_Spaces_Are_Masked'Access,
         "Ada quote and space character literals are masked");
      Register_Routine
        (T, Test_Ada_Valid_Declarations_After_Closed_Non_Code_Spans'Access,
         "Ada valid declarations after closed non-code spans extract");
      Register_Routine
        (T, Test_Ada_Comment_Starts_After_Closed_String_Only'Access,
         "Ada comment starts only after closed string");
      Register_Routine
        (T, Test_Ada_Generic_Prelude_Ignores_String_Text'Access,
         "Ada generic prelude ignores string text");
      Register_Routine
        (T, Test_Ada_Command_Metadata_And_Keybindings_Carry_No_Lexical_State'Access,
         "Ada command metadata and keybindings carry no lexical state");
      Register_Routine
        (T, Test_Ada_Availability_And_Render_Do_Not_Run_Lexical_Scan'Access,
         "Ada availability and render do not run lexical scan");
      Register_Routine
        (T, Test_Ada_Workspace_Snapshot_Excludes_Lexical_State'Access,
         "Ada workspace snapshot excludes lexical state");
      Register_Routine
        (T, Test_Ada_Detection_Ignores_Non_Code_Only_Buffer'Access,
         "Ada detection ignores non-code only buffer");
      Register_Routine
        (T, Test_Ada_CRLF_And_Trailing_CR_Do_Not_Leak_Non_Code'Access,
         "Ada CRLF and trailing CR do not leak non-code");
      Register_Routine
        (T, Test_Ada_Labelled_Loops_Ignore_Labels_In_Non_Code'Access,
         "Ada labelled loops ignore labels in non-code");
      Register_Routine
        (T, Test_Ada_Tabs_And_Mixed_Case_Keywords_Remain_Lexically_Safe'Access,
         "Ada tabs and mixed-case keywords remain lexically safe");
      Register_Routine
        (T, Test_Ada_Comment_After_Dash_Character_Literal_Is_Real_Comment'Access,
         "Ada comment after dash character literal is real comment");
      Register_Routine
        (T, Test_Ada_String_Semicolon_Does_Not_Close_Multiline_Declaration'Access,
         "Ada string semicolon does not close multi-line declaration");
      Register_Routine
        (T, Test_Ada_Operator_Functions_Remain_Code_While_Quoted_Fakes_Are_Masked'Access,
         "Ada operator functions remain code while quoted fakes are masked");
      Register_Routine
        (T, Test_Ada_Null_And_Control_Characters_Do_Not_Break_Line_Scan'Access,
         "Ada null and control characters do not break line scan");
      Register_Routine
        (T, Test_Ada_Adjacent_And_Empty_Strings_Do_Not_Leak_Comments'Access,
         "Ada adjacent and empty strings do not leak comments");
      Register_Routine
        (T, Test_Ada_Double_Quote_Character_Literal_Does_Not_Start_String'Access,
         "Ada double-quote character literal does not start string");
      Register_Routine
        (T, Test_Ada_Token_Helpers_Use_Unified_Sanitized_View'Access,
         "Ada token helpers use unified sanitized view");
      Register_Routine
        (T, Test_Ada_Code_Column_Uses_Same_Mask_As_Sanitizer'Access,
         "Ada code-column helper uses the same mask as sanitizer");
      Register_Routine
        (T, Test_Ada_Lexical_Public_Helpers_Handle_Slices_And_Empty_Lines'Access,
         "Ada lexical helpers handle slices and empty lines");
      Register_Routine
        (T, Test_Ada_Attribute_And_Qualified_Literal_Apostrophes_Remain_Code'Access,
         "Ada attribute and qualified literal apostrophes remain code");
      Register_Routine
        (T, Test_Ada_Adjacent_Character_Literals_Do_Not_Suppress_Code'Access,
         "Ada adjacent character literals do not suppress code");
      Register_Routine
        (T, Test_Ada_Character_String_Comment_Sequence_Uses_One_Line_State'Access,
         "Ada character string comment sequence uses one-line state");
      Register_Routine
        (T, Test_Ada_Comment_Quotes_And_Chars_Are_Line_Local'Access,
         "Ada comment quotes and chars are line-local");
      Register_Routine
        (T, Test_Ada_Public_Sanitizer_Does_Not_Carry_String_State_Across_Line_Break'Access,
         "Ada public sanitizer resets string state across line breaks");
      Register_Routine
        (T, Test_Ada_Public_Sanitizer_Treats_CRLF_As_Non_Code_Boundary'Access,
         "Ada public sanitizer treats CRLF as non-code boundary");
      Register_Routine
        (T, Test_Ada_Public_Sanitizer_Does_Not_Carry_Comment_State_Across_Line_Break'Access,
         "Ada public sanitizer resets comment state across line breaks");
      Register_Routine
        (T, Test_Ada_Objects_Discriminants_And_Character_Literals_Are_Extracted'Access,
         "Ada objects discriminants and character literals are extracted");
   end Register_Tests;

end Editor.Outline.Lexical_Tests;
