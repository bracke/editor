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

package body Editor.Outline.Ada_Extraction_Tests is

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

   function Name (T : Ada_Extraction_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Outline.Ada_Extraction.Tests");
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

   procedure Test_Command_Refresh_Uses_Buffer_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Outline_First : Natural := 0;
      Panel_First   : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Result        : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package One" & ASCII.LF & "package One is end One;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "first refresh executes through executor");
      Outline_First := Fingerprint (S.Outline);
      Panel_First := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);

      Editor.State.Load_Text
        (S, "@outline procedure Totally_Different" & ASCII.LF &
            "procedure Totally_Different is begin null; end Totally_Different;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "second refresh executes through executor");
      Assert (Fingerprint (S.Outline) /= Outline_First,
              "buffer extractor refresh inspects explicit active-buffer snapshot");
      Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel).Row_Labels_Hash /=
                Panel_First.Row_Labels_Hash,
              "buffer extractor projection labels follow markers");
      Assert (Active_Message_Text (S) = Editor.Outline.Message_Outline_Refreshed,
              "executor maps refresh ok to one canonical message");
   end Test_Command_Refresh_Uses_Buffer_Markers;

   procedure Test_Extractor_Marker_Grammar
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("ignored" & ASCII.LF &
           "   @outline package Demo" & ASCII.LF &
           "@outline type State" & ASCII.LF &
           "not an outline row");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "marker extraction succeeds for ordinary text");
      Assert (Editor.Outline_Extractor.Failure (Result) =
                Editor.Outline_Extractor.No_Failure,
              "successful marker extraction has no failure kind");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "only @outline marker rows become outline items");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2, "apply replaces outline with extracted items");
      Assert (Item_Label (O, 1) = "package Demo",
              "marker label removes @outline prefix");
      Assert (Item_Kind (O, 1) = Outline_Package,
              "package marker derives package kind");
      Assert (Item_Line (O, 1) = 2 and then Item_Column (O, 1) = 4,
              "extracted target stores one-based line and first non-space column");
      Assert (Item_Target_Kind (O, 1) = Buffer_Position_Target,
              "extracted target metadata is stored but remains inert");
   end Test_Extractor_Marker_Grammar;

   procedure Test_Outline_Marker_Fallback_Is_Marker_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("not a declaration" & ASCII.LF &
           "   @outline procedure Manual_Run" & ASCII.LF &
           "still not a declaration" & ASCII.LF,
           "manual.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "marker-only fallback extraction succeeds for Ada-like labels");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 1,
              "parser-empty fallback keeps only explicit @outline rows");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "procedure Manual_Run",
              "manual marker label is preserved without Ada fallback scanning");
      Assert (Item_Line (O, 1) = 2 and then Item_Column (O, 1) = 4,
              "manual marker target remains snapshot-owned");
   end Test_Outline_Marker_Fallback_Is_Marker_Only;

   procedure Test_Marker_Grammar_Freeze_And_Edge_Cases
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("@outline" & ASCII.LF &
           "@outline    " & ASCII.LF &
           "   @outline section Setup   " & ASCII.CR & ASCII.LF &
           "@outline field Value" & ASCII.LF &
           "@Outline package Wrong_Case" & ASCII.LF &
           "@outline frobnicate Future" & ASCII.LF &
           "@outline procedure No_Final_Newline");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "edge-case marker extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "empty labels and wrong-case markers are ignored");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);

      Assert (Item_Label (O, 1) = "section Setup",
              "excess marker and label whitespace is trimmed");
      Assert (Item_Kind (O, 1) = Outline_Section,
              "section marker derives section kind");
      Assert (Item_Line (O, 1) = 3 and then Item_Column (O, 1) = 4,
              "CRLF line and leading whitespace column are deterministic");
      Assert (Item_Kind (O, 2) = Outline_Field,
              "field marker derives field kind");
      Assert (Item_Kind (O, 3) = Outline_Unknown,
              "unknown marker kinds are accepted as unknown outline items");
      Assert (Item_Label (O, 4) = "procedure No_Final_Newline",
              "final line without newline is extracted normally");
   end Test_Marker_Grammar_Freeze_And_Edge_Cases;

   procedure Test_Ada_Outline_Extracts_Common_Declarations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Editor.Outline is" & ASCII.LF &
           "package body Editor.Outline is" & ASCII.LF &
           "procedure Refresh;" & ASCII.LF &
           "function Item_Count return Natural;" & ASCII.LF &
           "type Outline_Source_Class is" & ASCII.LF &
           "task Worker;" & ASCII.LF &
           "protected Guard is");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "Ada lexical extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "Ada lexical extraction recognizes common declarations");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Source_Class (O) = Extracted_Outline,
              "Ada declarations apply as extracted outline rows");
      Assert (Item_Label (O, 1) = "package Editor.Outline",
              "package spec label is stable");
      Assert (Item_Kind (O, 1) = Outline_Package,
              "package spec kind is stable");
      Assert (Item_Label (O, 2) = "package body Editor.Outline",
              "package body label is stable");
      Assert (Item_Kind (O, 2) = Outline_Package_Body,
              "package body kind is stable");
      Assert (Item_Label (O, 3) = "procedure Refresh",
              "procedure label is stable");
      Assert (Item_Kind (O, 3) = Outline_Procedure,
              "procedure kind is stable");
      Assert (Item_Label (O, 4) = "function Item_Count",
              "function label is stable");
      Assert (Item_Kind (O, 4) = Outline_Function,
              "function kind is stable");
      Assert (Item_Label (O, 5) = "type Outline_Source_Class",
              "type label is stable");
      Assert (Item_Kind (O, 5) = Outline_Type,
              "type kind is stable");
      Assert (Item_Kind (O, 6) = Outline_Task,
              "task kind is stable");
      Assert (Item_Kind (O, 7) = Outline_Protected,
              "protected kind is stable");
   end Test_Ada_Outline_Extracts_Common_Declarations;

   procedure Test_Ada_Outline_Empty_And_Non_Ada_Are_Unsupported
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Empty_Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract
          (Editor.Outline_Extractor.Make_Snapshot (""));
      Non_Ada_Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract
          (Editor.Outline_Extractor.Make_Snapshot
             ("# heading" & ASCII.LF & "plain text without declarations"));
      Non_Ada_Extension_Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract
          (Editor.Outline_Extractor.Make_Snapshot
             ("function Visible return Natural;", "demo.js"));
   begin
      Populate_Synthetic_Outline (O);
      Editor.Outline_Extractor.Apply_To_Outline (Empty_Result, O);
      Assert (Item_Count (O) = 0,
              "empty extraction clears previous placeholder rows");
      Assert (Source_Class (O) = Unsupported_Content,
              "empty extraction is a deterministic unsupported state");

      Populate_Synthetic_Outline (O);
      Editor.Outline_Extractor.Apply_To_Outline (Non_Ada_Result, O);
      Assert (Item_Count (O) = 0,
              "non-Ada text does not retain stale Ada or placeholder rows");
      Assert (Source_Class (O) = Unsupported_Content,
              "non-Ada text is classified as unsupported content");

      Populate_Synthetic_Outline (O);
      Editor.Outline_Extractor.Apply_To_Outline (Non_Ada_Extension_Result, O);
      Assert (Item_Count (O) = 0,
              "non-Ada file extensions disable Ada content sniffing");
      Assert (Source_Class (O) = Unsupported_Content,
              "non-Ada file extensions are classified as unsupported content");
   end Test_Ada_Outline_Empty_And_Non_Ada_Are_Unsupported;

   procedure Test_Ada_Outline_Rows_Open_To_Target_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "package Demo is" & ASCII.LF &
            "   procedure Run;" & ASCII.LF &
            "end Demo;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Ada outline refresh executes through the command path");
      Assert (Item_Count (S.Outline) = 2,
              "Ada command refresh extracts package and procedure rows");

      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Editor.Feature_Panel.Select_Next (S.Feature_Panel);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "opening an Ada outline row executes");
      Editor.State.Row_Col_For_Index (S, S.Carets (0).Pos, Row, Col);
      Assert (Row = 1 and then Col = 3,
              "opening an Ada outline row navigates to captured line/column");
   end Test_Ada_Outline_Rows_Open_To_Target_Line;

   procedure Test_Ada_Outline_Result_Still_Rejected_When_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Old_Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      New_Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Old_Result   : Editor.Outline_Extractor.Extraction_Result;
   begin
      Old_Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Old_Buffer is" & ASCII.LF,
         Active_Buffer_Token  => 1,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Old_Snapshot));
      Old_Result := Editor.Outline_Extractor.Extract (Old_Snapshot);

      New_Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package New_Buffer is" & ASCII.LF,
         Active_Buffer_Token  => 2,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (New_Snapshot));

      Editor.Outline_Extractor.Apply_To_Outline (Old_Result, O);
      Assert (Item_Count (O) = 0,
              "stale Ada extraction result does not create rows");
      Assert (Source_Class (O) = Stale_Extracted_Outline,
              "stale Ada extraction result keeps stale classification");
   end Test_Ada_Outline_Result_Still_Rejected_When_Stale;

   procedure Test_Ada_Outline_Extracts_Multiline_Procedure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   procedure Refresh" & ASCII.LF &
           "     (State : in out Outline_State;" & ASCII.LF &
           "      Force : Boolean := False);" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "multi-line procedure extraction emits package and procedure only");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "procedure Refresh",
              "multi-line procedure label excludes profile");
      Assert (Item_Depth (O, 2) = 1,
              "multi-line procedure inside package receives member depth");
   end Test_Ada_Outline_Extracts_Multiline_Procedure;

   procedure Test_Ada_Outline_Extracts_Multiline_Function
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   function Item_Count" & ASCII.LF &
           "     (State : Outline_State)" & ASCII.LF &
           "      return Natural;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "multi-line function extraction emits package and function only");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "function Item_Count",
              "multi-line function label excludes profile and return type");
      Assert (Item_Kind (O, 2) = Outline_Function,
              "multi-line function preserves function kind");
   end Test_Ada_Outline_Extracts_Multiline_Function;

   procedure Test_Ada_Outline_Does_Not_Duplicate_Continuation_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Refresh" & ASCII.LF &
           "  (Procedure_Name : String;" & ASCII.LF &
           "   Function_Name  : String);" & ASCII.LF &
           "function Done return Boolean;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "continuation lines do not become duplicate outline symbols");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "procedure Refresh",
              "first row is the multi-line procedure declaration");
      Assert (Item_Label (O, 2) = "function Done",
              "scanner resumes after the multi-line declaration boundary");
   end Test_Ada_Outline_Does_Not_Duplicate_Continuation_Lines;

   procedure Test_Ada_Outline_Extracts_Generic_Package
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "package Generic_Map is" & ASCII.LF &
           "end Generic_Map;",
           "generic_map.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 1,
              "generic package extraction emits one outline row");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "generic package Generic_Map",
              "generic package label is compact and stable");
      Assert (Item_Kind (O, 1) = Outline_Package,
              "generic package uses package outline kind without enum churn");
   end Test_Ada_Outline_Extracts_Generic_Package;

   procedure Test_Ada_Outline_Extracts_Generic_Procedure_And_Function
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element_Type is private;" & ASCII.LF &
           "procedure Swap" & ASCII.LF &
           "  (Left  : in out Element_Type;" & ASCII.LF &
           "   Right : in out Element_Type);" & ASCII.LF &
           "generic" & ASCII.LF &
           "   with function ""<""" & ASCII.LF &
           "     (Left, Right : Key_Type) return Boolean;" & ASCII.LF &
           "function Minimum" & ASCII.LF &
           "  (Left, Right : Key_Type)" & ASCII.LF &
           "   return Key_Type;",
           "generic_ops.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "generic formal declarations and generic units are extracted");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element_Type",
              "generic formal type row is extracted");
      Assert (Item_Label (O, 2) = "generic procedure Swap",
              "generic procedure label is compact");
      Assert (Item_Label (O, 3) = "formal function ""<""",
              "generic formal operator function row is extracted");
      Assert (Item_Label (O, 4) = "generic function Minimum",
              "generic function label is compact");
   end Test_Ada_Outline_Extracts_Generic_Procedure_And_Function;

   procedure Test_Ada_Outline_Clears_Pending_Generic_After_Use
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element_Type is private;" & ASCII.LF &
           "procedure Swap" & ASCII.LF &
           "  (Left, Right : in out Element_Type);" & ASCII.LF &
           "procedure Plain;",
           "generic_ops.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "generic marker applies to the following declaration after formals");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element_Type",
              "generic formal type row is extracted");
      Assert (Item_Label (O, 2) = "generic procedure Swap",
              "generic marker applies to the generic procedure");
      Assert (Item_Label (O, 3) = "procedure Plain",
              "generic marker does not leak into later declarations");
   end Test_Ada_Outline_Clears_Pending_Generic_After_Use;

   procedure Test_Ada_Outline_Assigns_Depth_For_Package_Members
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Top is" & ASCII.LF &
           "      procedure Nested;" & ASCII.LF &
           "   end Top;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "depth test extracts package body, member, and nested declaration");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Depth (O, 1) = 0,
              "package body starts at top-level depth");
      Assert (Item_Depth (O, 2) = 1,
              "subprogram body inside package body has member depth");
      Assert (Item_Depth (O, 3) = 2,
              "nested declaration inside subprogram has nested depth");
   end Test_Ada_Outline_Assigns_Depth_For_Package_Members;

   procedure Test_Ada_Outline_Depth_Remains_Stable_On_Unmatched_End
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("end Stray;" & ASCII.LF &
           "package Demo is" & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "unmatched end line does not prevent later extraction");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Depth (O, 1) = 0,
              "unmatched end does not underflow depth");
      Assert (Item_Depth (O, 2) = 1,
              "member depth remains stable after unmatched end");
   end Test_Ada_Outline_Depth_Remains_Stable_On_Unmatched_End;

   procedure Test_Ada_Outline_Distinguishes_Package_Spec_And_Body
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Editor.Outline is" & ASCII.LF &
           "end Editor.Outline;" & ASCII.LF &
           "package body Editor.Outline is" & ASCII.LF &
           "end Editor.Outline;",
           "editor-outline.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "package spec/body distinction extracts two package rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Kind (O, 1) = Outline_Package,
              "package spec keeps package kind");
      Assert (Item_Kind (O, 2) = Outline_Package_Body,
              "package body keeps package-body kind");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "spec") /= 0,
              "package spec detail records spec classification");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "body") /= 0,
              "package body detail records body classification");
   end Test_Ada_Outline_Distinguishes_Package_Spec_And_Body;

   procedure Test_Ada_Outline_Distinguishes_Procedure_Declaration_And_Body
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Declared;" & ASCII.LF &
           "   procedure Implemented is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Implemented;" & ASCII.LF &
           "   procedure Multiline" & ASCII.LF &
           "     (Flag : Boolean)" & ASCII.LF &
           "   is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Multiline;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "procedure declaration/body distinction keeps all rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "declaration") /= 0,
              "procedure declaration detail records declaration classification");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "body") /= 0,
              "single-line procedure body header records body classification");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 4), "body") /= 0,
              "multi-line procedure body header is upgraded after accumulated is line");
   end Test_Ada_Outline_Distinguishes_Procedure_Declaration_And_Body;

   procedure Test_Ada_Outline_Still_Rejects_Stale_Multiline_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Old_Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      New_Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Old_Result   : Editor.Outline_Extractor.Extraction_Result;
   begin
      Old_Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Old_Buffer is" & ASCII.LF &
         "   procedure Refresh" & ASCII.LF &
         "     (Force : Boolean);" & ASCII.LF &
         "end Old_Buffer;",
         Active_Buffer_Token  => 1,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Old_Snapshot));
      Old_Result := Editor.Outline_Extractor.Extract (Old_Snapshot);

      New_Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package New_Buffer is" & ASCII.LF,
         Active_Buffer_Token  => 2,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (New_Snapshot));

      Editor.Outline_Extractor.Apply_To_Outline (Old_Result, O);
      Assert (Item_Count (O) = 0,
              "stale multi-line Ada extraction result does not create rows");
      Assert (Source_Class (O) = Stale_Extracted_Outline,
              "stale multi-line Ada extraction result keeps stale classification");
   end Test_Ada_Outline_Still_Rejects_Stale_Multiline_Result;

   procedure Test_Ada_Outline_Unsupported_Buffer_Clears_Previous_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Visible;", "demo.js");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Populate_Synthetic_Outline (O);
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 0,
              "unsupported buffer clears previous rows instead of keeping stale Ada rows");
      Assert (Source_Class (O) = Unsupported_Content,
              "unsupported buffer receives deterministic unsupported classification");
   end Test_Ada_Outline_Unsupported_Buffer_Clears_Previous_Rows;

   procedure Test_Ada_Outline_Extracts_Renames_And_Expression_Functions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo renames Root.Demo;" & ASCII.LF &
           "procedure Run renames Other_Run;" & ASCII.LF &
           "function Compute return Integer renames Other_Compute;" & ASCII.LF &
           "function Ready return Boolean is (True);",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "extracts package, procedure, function renames and expression functions");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo renames",
              "package rename label is explicit");
      Assert (Item_Label (O, 2) = "procedure Run renames",
              "procedure rename label is explicit");
      Assert (Item_Label (O, 3) = "function Compute renames",
              "function rename label is explicit");
      Assert (Item_Label (O, 4) = "expression function Ready",
              "expression function label is explicit when the pattern is clear");
      Assert (Item_Line (O, 3) = 3 and then Item_Column (O, 3) = 1,
              "rename target stays on the renaming declaration line");
   end Test_Ada_Outline_Extracts_Renames_And_Expression_Functions;

   procedure Test_Ada_Outline_Extracts_Type_Forms
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   type State is private;" & ASCII.LF &
           "   type Cursor is limited private;" & ASCII.LF &
           "   type Node is record" & ASCII.LF &
           "      Value : Integer;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "   type Mode is (Insert, Normal);" & ASCII.LF &
           "   subtype Index is Natural range 1 .. 10;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 9,
              "extracts common type and subtype forms with parser-owned child rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "private type State",
              "private type label is kind-aware");
      Assert (Item_Label (O, 3) = "private type Cursor",
              "limited private type remains compact");
      Assert (Item_Label (O, 4) = "record type Node",
              "record type label is kind-aware");
      Assert (Item_Label (O, 6) = "enum type Mode",
              "enumeration type label is kind-aware");
      Assert (Item_Label (O, 9) = "subtype Index",
              "subtype label includes subtype name");
      Assert (Item_Depth (O, 6) = 1,
              "record type scanning does not corrupt following package-member depth");
   end Test_Ada_Outline_Extracts_Type_Forms;

   procedure Test_Ada_Outline_Extracts_Task_And_Protected_Forms
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   task Worker;" & ASCII.LF &
           "   task type Job is" & ASCII.LF &
           "   end Job;" & ASCII.LF &
           "   task body Worker is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Worker;" & ASCII.LF &
           "   protected Lock is" & ASCII.LF &
           "   end Lock;" & ASCII.LF &
           "   protected type Gate is" & ASCII.LF &
           "   end Gate;" & ASCII.LF &
           "   protected body Lock is" & ASCII.LF &
           "   end Lock;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "extracts task/protected declarations, types, and bodies");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "task Worker",
              "task declaration label is stable");
      Assert (Item_Label (O, 3) = "task type Job",
              "task type label is stable");
      Assert (Item_Label (O, 4) = "task body Worker",
              "task body label is stable");
      Assert (Item_Label (O, 5) = "protected Lock",
              "protected declaration label is stable");
      Assert (Item_Label (O, 6) = "protected type Gate",
              "protected type label is stable");
      Assert (Item_Label (O, 7) = "protected body Lock",
              "protected body label is stable");
      Assert (Item_Kind (O, 7) = Outline_Protected,
              "protected body uses protected outline kind without enum churn");
   end Test_Ada_Outline_Extracts_Task_And_Protected_Forms;

   procedure Test_Ada_Outline_Generic_Marker_Is_Bounded_Across_Formals
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is private;" & ASCII.LF &
           "   with procedure Visit (Value : Element);" & ASCII.LF &
           "package Containers is" & ASCII.LF &
           "   procedure Plain;" & ASCII.LF &
           "end Containers;" & ASCII.LF &
           "procedure Later;",
           "containers.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "keeps generic formals and the marker for the unit");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element",
              "generic formal type is visible as parser-owned metadata");
      Assert (Item_Label (O, 2) = "formal procedure Visit",
              "generic formal procedure is visible as parser-owned metadata");
      Assert (Item_Label (O, 3) = "generic package Containers",
              "generic marker applies to the following package declaration");
      Assert (Item_Label (O, 4) = "procedure Plain",
              "generic marker does not leak into package members");
      Assert (Item_Label (O, 5) = "procedure Later",
              "generic marker does not leak beyond the generic unit");
   end Test_Ada_Outline_Generic_Marker_Is_Bounded_Across_Formals;

   procedure Test_Ada_Outline_Handles_Multiline_Renames_And_Operators
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Run" & ASCII.LF &
           "     renames Other_Run;" & ASCII.LF &
           "   function Compute return Integer" & ASCII.LF &
           "     renames Other_Compute;" & ASCII.LF &
           "   function ""+"" (Left, Right : Integer) return Integer;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "extracts package, multi-line renames, and operator functions");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "procedure Run renames",
              "multi-line procedure rename upgrades the original declaration row");
      Assert (Item_Label (O, 3) = "function Compute renames",
              "multi-line function rename upgrades the original declaration row");
      Assert (Item_Label (O, 4) = "function ""+""",
              "operator-symbol function name is preserved compactly");
      Assert (Item_Line (O, 2) = 2 and then Item_Column (O, 2) = 4,
              "multi-line rename target remains the first declaration line");
   end Test_Ada_Outline_Handles_Multiline_Renames_And_Operators;

   procedure Test_Ada_Outline_Coverage_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is private;" & ASCII.LF &
           "package Demo is" & ASCII.LF &
           "   type State is record" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "   subtype Index is Natural;" & ASCII.LF &
           "   procedure Run" & ASCII.LF &
           "     (Value : Index);" & ASCII.LF &
           "   function Ready return Boolean is (True);" & ASCII.LF &
           "   task Worker;" & ASCII.LF &
           "   protected Lock is" & ASCII.LF &
           "   end Lock;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) >= 7,
              "coherent coverage extracts common Ada outline rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert_Has_Label (O, "generic package Demo",
              "coherent coverage keeps generic package label");
      Assert_Has_Label (O, "record type State",
              "coherent coverage includes record type label");
      Assert_Has_Label (O, "subtype Index",
              "coherent coverage includes subtype label");
      Assert_Has_Label (O, "procedure Run",
              "coherent coverage keeps multi-line procedure label compact");
      Assert_Has_Label (O, "expression function Ready",
              "coherent coverage includes clear expression function label");
      Assert (Item_Kind (O, First_Label_Index (O, "task Worker")) = Outline_Task,
              "coherent coverage includes task kind");
      Assert (Item_Kind (O, First_Label_Index (O, "protected Lock")) = Outline_Protected,
              "coherent coverage includes protected kind");
      Assert (Item_Line (O, First_Label_Index (O, "procedure Run")) = 7,
              "coherent coverage preserves first-line target for multi-line procedure");
   end Test_Ada_Outline_Coverage_Coherent;

   procedure Test_Completeness_Multiline_Type_And_Expression_Functions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   type State is" & ASCII.LF &
           "      record" & ASCII.LF &
           "         Value : Integer;" & ASCII.LF &
           "      end record;" & ASCII.LF &
           "   subtype After_Record is Natural;" & ASCII.LF &
           "   function Ready return Boolean is" & ASCII.LF &
           "      (True);" & ASCII.LF &
           "   function Split return Boolean" & ASCII.LF &
           "      is" & ASCII.LF &
           "      (False);" & ASCII.LF &
           "   function Build return Integer" & ASCII.LF &
           "      is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      return 1;" & ASCII.LF &
           "   end Build;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "completeness extracts multiline record type, following subtype, and split function forms");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "record type State",
              "record type split across the is/record lines is still classified as a record type");
      Assert (Item_Line (O, 2) = 2 and then Item_Column (O, 2) = 4,
              "multiline record target remains on the type declaration start");
      Assert (Item_Label (O, 4) = "subtype After_Record",
              "split record pending state ends at end record and preserves following declarations");
      Assert (Item_Depth (O, 4) = 1,
              "following subtype remains at the package-member depth after split record completion");
      Assert (Item_Label (O, 5) = "expression function Ready",
              "expression function split after is is classified conservatively when the next line is the expression");
      Assert (Item_Label (O, 6) = "expression function Split",
              "expression function with is on a separate line remains classified as expression");
      Assert (Item_Label (O, 7) = "function body Build",
              "ordinary function body split after is is not mistaken for an expression function");
      Assert (Item_Line (O, 5) = 7
                and then Item_Line (O, 6) = 9
                and then Item_Line (O, 7) = 12,
              "multiline function targets remain on their first declaration lines");
   end Test_Completeness_Multiline_Type_And_Expression_Functions;

   procedure Test_Completeness_Split_Generic_Formals_Keep_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is" & ASCII.LF &
           "      private;" & ASCII.LF &
           "   type Cursor is" & ASCII.LF &
           "      range <>;" & ASCII.LF &
           "   with function ""<""" & ASCII.LF &
           "     (Left, Right : Element) return Boolean is <>;" & ASCII.LF &
           "package Ordered_Sets is" & ASCII.LF &
           "   function Empty return Boolean;" & ASCII.LF &
           "end Ordered_Sets;",
           "ordered_sets.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "completeness keeps generic marker through split formal declarations");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element",
              "split generic formal type is visible without opening depth");
      Assert (Item_Label (O, 2) = "formal type Cursor",
              "second split generic formal type is visible without opening depth");
      Assert (Item_Label (O, 3) = "formal function ""<""",
              "split generic formal function is visible");
      Assert (Item_Label (O, 4) = "generic package Ordered_Sets",
              "split generic formal type declarations do not clear the generic marker");
      Assert (Item_Label (O, 5) = "function Empty",
              "generic marker still clears after the associated package declaration");
   end Test_Completeness_Split_Generic_Formals_Keep_Marker;

   procedure Test_Completeness_Split_Generic_Package_Formal_Keep_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   with package Formal is" & ASCII.LF &
           "      new Ada.Containers.Vectors (Positive, Element);" & ASCII.LF &
           "   Default_Count : Natural :=" & ASCII.LF &
           "      0;" & ASCII.LF &
           "package Demo is" & ASCII.LF &
           "   procedure Use_Formal;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "completeness keeps marker through split generic package and object formals");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal package Formal",
              "split formal package is visible");
      Assert (Item_Label (O, 2) = "formal object Default_Count",
              "split formal object is visible without a duplicate object row");
      Assert (Item_Label (O, 3) = "generic package Demo",
              "split formal package continuation does not clear or consume the generic marker");
      Assert (Item_Line (O, 3) = 6,
              "generic package target remains on the real declaration, not the formal package");
      Assert (Item_Label (O, 4) = "procedure Use_Formal",
              "generic marker clears after the associated package declaration");
   end Test_Completeness_Split_Generic_Package_Formal_Keep_Marker;

   procedure Test_Completeness_Comments_Strings_And_Generic_Task_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   Text : constant String := ""procedure Fake; -- not a comment"";" & ASCII.LF &
           "   -- function Hidden return Boolean;" & ASCII.LF &
           "   procedure Visible; -- function Also_Hidden return Boolean;" & ASCII.LF &
           "   generic" & ASCII.LF &
           "      type Element is private;" & ASCII.LF &
           "   task Worker;" & ASCII.LF &
           "   function Later return Boolean;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 6,
              "completeness ignores obvious comments/strings and clears unsupported generic marker targets");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "package still extracts near strings and comments");
      Assert (Item_Label (O, 3) = "procedure Visible",
              "inline comment content after a declaration does not fabricate a second row");
      Assert (Item_Label (O, 5) = "task Worker",
              "generic marker does not attach to unsupported task declarations");
      Assert (Item_Label (O, 6) = "function Later",
              "generic marker cleared before the following supported function");
   end Test_Completeness_Comments_Strings_And_Generic_Task_Boundary;

   procedure Test_Completeness_Split_Package_Forms_Do_Not_Open_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo" & ASCII.LF &
           "is" & ASCII.LF &
           "   package Int_Vectors is new Ada.Containers.Vectors" & ASCII.LF &
           "     (Positive, Integer);" & ASCII.LF &
           "   package Renamed" & ASCII.LF &
           "     renames Ada.Text_IO;" & ASCII.LF &
           "   subtype After_Instantiation is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "completeness handles split package spec, instantiation, and rename forms");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "split package spec keeps compact package label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "spec") /= 0,
              "split package spec is not misclassified as a body");
      Assert (Item_Label (O, 2) = "package Int_Vectors",
              "split package instantiation keeps the instantiated package target row");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "instantiation") /= 0,
              "split package instantiation is classified without opening lexical depth");
      Assert (Item_Label (O, 3) = "package Renamed renames",
              "split package rename updates the original declaration row");
      Assert (Item_Label (O, 4) = "subtype After_Instantiation",
              "following declaration is not nested under a split instantiation");
      Assert (Item_Depth (O, 2) = 1 and then Item_Depth (O, 4) = 1,
              "split instantiation does not corrupt package-member depth");
      Assert (Item_Line (O, 2) = 3 and then Item_Line (O, 3) = 5,
              "split package forms keep targets on their first declaration lines");
   end Test_Completeness_Split_Package_Forms_Do_Not_Open_Depth;

   procedure Test_Completeness_Null_And_Separate_Subprogram_Bodies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Reset is null;" & ASCII.LF &
           "   procedure Deferred" & ASCII.LF &
           "      is separate;" & ASCII.LF &
           "   function External return Integer is separate;" & ASCII.LF &
           "   function Abstract_Value return Integer is abstract;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "completeness extracts null/separate subprogram bodies without opening depth");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "procedure body Reset",
              "null procedure is classified as a body-like outline target");
      Assert (Item_Label (O, 3) = "procedure body Deferred",
              "split separate procedure is classified as a body-like outline target");
      Assert (Item_Label (O, 4) = "function body External",
              "separate function is classified as a body-like outline target");
      Assert (Item_Label (O, 5) = "function Abstract_Value",
              "abstract function remains a declaration, not a function body");
      Assert (Item_Line (O, 2) = 2
                and then Item_Line (O, 3) = 3
                and then Item_Line (O, 4) = 5,
              "null/separate subprogram targets stay on their declaration starts");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1
                and then Item_Depth (O, 5) = 1,
              "null/separate/abstract forms do not corrupt following package-member depth");
   end Test_Completeness_Null_And_Separate_Subprogram_Bodies;

   procedure Test_Completeness_Record_Named_Types_Are_Not_Records
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   type Record_Node is private;" & ASCII.LF &
           "   type Node_Access is access Record_Node;" & ASCII.LF &
           "   type Split_Access is" & ASCII.LF &
           "      access Record_Node;" & ASCII.LF &
           "   type Record_Table is array" & ASCII.LF &
           "      (Positive range <>) of Record_Node;" & ASCII.LF &
           "   subtype After_Types is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 6,
              "completeness keeps record-named access/array types as plain types");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "private type Record_Node",
              "actual private type remains private even when its name contains Record");
      Assert (Item_Label (O, 3) = "access type Node_Access",
              "access type to Record_Node is not mislabeled as a record type");
      Assert (Item_Label (O, 4) = "type Split_Access",
              "split access type to Record_Node does not wait for end record");
      Assert (Item_Label (O, 5) = "array type Record_Table",
              "array type mentioning Record_Node is not mislabeled as a record type");
      Assert (Item_Label (O, 6) = "subtype After_Types",
              "following subtype is still extracted after split record-named types");
      Assert (Item_Line (O, 4) = 4 and then Item_Line (O, 5) = 6,
              "split access/array targets stay on their first declaration lines");
      Assert (Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1
                and then Item_Depth (O, 5) = 1
                and then Item_Depth (O, 6) = 1,
              "record-named type references do not corrupt package-member depth");
   end Test_Completeness_Record_Named_Types_Are_Not_Records;

   procedure Test_Completeness_Private_Named_Types_Are_Not_Private
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   type Private_Data is private;" & ASCII.LF &
           "   type Data_Access is access Private_Data;" & ASCII.LF &
           "   type Split_Access is" & ASCII.LF &
           "      access Private_Data;" & ASCII.LF &
           "   type Data_Table is array" & ASCII.LF &
           "      (Positive range <>) of Private_Data;" & ASCII.LF &
           "   package Data_Maps is new Ada.Containers.Vectors" & ASCII.LF &
           "      (Positive, Private_Data);" & ASCII.LF &
           "   subtype After_Types is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "completeness keeps private-named access/array/instantiation forms precise");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "private type Private_Data",
              "actual private type remains classified as private");
      Assert (Item_Label (O, 3) = "access type Data_Access",
              "access type to Private_Data is not mislabeled as a private type");
      Assert (Item_Label (O, 4) = "type Split_Access",
              "split access type to Private_Data remains a plain type");
      Assert (Item_Label (O, 5) = "array type Data_Table",
              "array type mentioning Private_Data remains a plain type");
      Assert (Item_Label (O, 6) = "package Data_Maps",
              "split package instantiation remains a package row");
      Assert (Item_Label (O, 7) = "subtype After_Types",
              "following subtype is still extracted after private-named forms");
      Assert (Item_Line (O, 4) = 4
                and then Item_Line (O, 5) = 6
                and then Item_Line (O, 6) = 8,
              "split private-named forms keep first-line source targets");
      Assert (Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1
                and then Item_Depth (O, 5) = 1
                and then Item_Depth (O, 6) = 1
                and then Item_Depth (O, 7) = 1,
              "private-named references do not corrupt package-member depth");
   end Test_Completeness_Private_Named_Types_Are_Not_Private;

   procedure Test_Completeness_Is_Followed_By_Uses_Code_Tokens
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo with Annotation => ""is new"" is" & ASCII.LF &
           "   procedure Logged with Note => ""is null"";" & ASCII.LF &
           "   function Remote return Boolean with Note => ""is separate"";" & ASCII.LF &
           "   procedure Actual_Null is null;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "completeness keeps is-followed-by tests outside string literals");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "package aspect string containing is new is not treated as an instantiation");
      Assert (Item_Label (O, 2) = "procedure Logged",
              "procedure aspect string containing is null is not treated as a null body");
      Assert (Item_Label (O, 3) = "function Remote",
              "function aspect string containing is separate is not treated as a separate body");
      Assert (Item_Label (O, 4) = "procedure body Actual_Null",
              "real null procedure body remains body-classified");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1,
              "string-literal token suppression does not corrupt package-member depth");
   end Test_Completeness_Is_Followed_By_Uses_Code_Tokens;

   procedure Test_Completeness_Code_Tokens_Ignore_Strings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   procedure Quoted_Rename with Note => ""renames"";" & ASCII.LF &
           "   function Quoted_Is return Boolean with Note => ""is"";" & ASCII.LF &
           "   type Access_Record_Name is access String with Note => ""record"";" & ASCII.LF &
           "   type Access_Private_Name is access String with Note => ""private"";" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "completeness ignores declaration keywords inside strings");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "package remains a package spec");
      Assert (Item_Label (O, 2) = "procedure Quoted_Rename",
              "renames inside string literal does not change procedure label");
      Assert (Item_Label (O, 3) = "function Quoted_Is",
              "is inside string literal does not make function a body");
      Assert (Item_Label (O, 4) = "access type Access_Record_Name",
              "record inside string literal does not make access type a record type");
      Assert (Item_Label (O, 5) = "access type Access_Private_Name",
              "private inside string literal does not make access type a private type");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1
                and then Item_Depth (O, 5) = 1,
              "string keyword suppression preserves package-member depth");
   end Test_Completeness_Code_Tokens_Ignore_Strings;

   procedure Test_Completeness_Expression_Function_Is_Open_Paren
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   function Compact return Boolean is(True);" & ASCII.LF &
           "   function Spaced return Boolean is (True);" & ASCII.LF &
           "   function Quoted return Boolean with Note => ""is("";" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "completeness handles expression functions without requiring space before open paren");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Demo",
              "package body remains first item");
      Assert (Item_Label (O, 2) = "expression function Compact",
              "is immediately followed by open paren is classified as expression function");
      Assert (Item_Label (O, 3) = "expression function Spaced",
              "spaced expression function remains classified as expression function");
      Assert (Item_Label (O, 4) = "function Quoted",
              "quoted is-open-paren text does not classify declaration as expression function");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1,
              "expression-function punctuation handling preserves package-member depth");
   end Test_Completeness_Expression_Function_Is_Open_Paren;

   procedure Test_Completeness_Overriding_Subprograms
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   overriding procedure Adjust (Object : in out Controlled);" & ASCII.LF &
           "   not overriding function Create" & ASCII.LF &
           "      return Controlled" & ASCII.LF &
           "   is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      return Result : Controlled;" & ASCII.LF &
           "   end Create;" & ASCII.LF &
           "   overriding function Ready return Boolean is (True);" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "completeness extracts overriding/not overriding subprogram declarations");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Demo",
              "package body still extracts before overriding subprograms");
      Assert (Item_Label (O, 2) = "procedure Adjust",
              "overriding procedure keeps compact procedure label");
      Assert (Item_Label (O, 3) = "function body Create",
              "not overriding multi-line function body is classified after prefix stripping");
      Assert (Item_Label (O, 4) = "expression function Ready",
              "overriding expression function remains expression-classified");
      Assert (Item_Line (O, 2) = 2
                and then Item_Line (O, 3) = 3
                and then Item_Line (O, 4) = 9,
              "overriding subprogram targets stay on the prefixed declaration line");
      Assert (Item_Column (O, 2) = 15
                and then Item_Column (O, 3) = 19
                and then Item_Column (O, 4) = 15,
              "overriding subprogram target columns point to declaration keywords");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1,
              "overriding prefix handling does not corrupt package-member depth");
   end Test_Completeness_Overriding_Subprograms;

   procedure Test_Completeness_Separate_Subunit_Bodies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("separate (Demo)" & ASCII.LF &
           "procedure Worker is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Worker;" & ASCII.LF &
           "separate (Demo) function Ready return Boolean is (True);" & ASCII.LF &
           "separate (Demo) overriding function Flag return Boolean is (True);" & ASCII.LF &
           "separate (Demo)" & ASCII.LF &
           "package body Child is" & ASCII.LF &
           "end Child;",
           "demo-worker.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "completeness extracts same-line and split separate subunit bodies");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "procedure body Worker",
              "split separate procedure subunit is classified as a procedure body");
      Assert (Item_Label (O, 2) = "expression function Ready",
              "same-line separate expression function keeps expression classification");
      Assert (Item_Label (O, 3) = "expression function Flag",
              "same-line separate overriding expression function strips both prefixes");
      Assert (Item_Label (O, 4) = "package body Child",
              "split separate package body is extracted after separate prefix line");
      Assert (Item_Line (O, 1) = 2
                and then Item_Line (O, 2) = 6
                and then Item_Line (O, 3) = 7
                and then Item_Line (O, 4) = 9,
              "separate subunit targets stay on the real declaration/body line");
      Assert (Item_Column (O, 2) = 17
                and then Item_Column (O, 3) = 28,
              "same-line separate subunit target columns point to function keywords");
      Assert (Item_Depth (O, 1) = 0
                and then Item_Depth (O, 2) = 0
                and then Item_Depth (O, 3) = 0
                and then Item_Depth (O, 4) = 0,
              "separate subunits do not inherit fabricated package nesting depth");
   end Test_Completeness_Separate_Subunit_Bodies;

   procedure Test_Completeness_End_Name_Keyword_Prefixes_Close_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Record_Type is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Record_Type;" & ASCII.LF &
           "   function If_State return Boolean is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      return True;" & ASCII.LF &
           "   end If_State;" & ASCII.LF &
           "   subtype Index is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "completeness extracts declarations around end-name keyword prefixes");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Demo",
              "package body remains first item");
      Assert (Item_Label (O, 2) = "procedure body Record_Type",
              "procedure whose name begins with record is classified as a body");
      Assert (Item_Label (O, 3) = "function body If_State",
              "function whose name begins with if is classified as a body");
      Assert (Item_Label (O, 4) = "subtype Index",
              "following subtype is still extracted");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1,
              "end name prefixes such as end Record_Type and end If_State close block depth");
   end Test_Completeness_End_Name_Keyword_Prefixes_Close_Depth;

   procedure Test_Completeness_Subprogram_Instantiations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Run is new Generic_Run;" & ASCII.LF &
           "   function Make is new Generic_Make" & ASCII.LF &
           "     (Integer);" & ASCII.LF &
           "   subtype After_Instantiation is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "completeness extracts subprogram instantiations without depth drift");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Demo",
              "package body remains first item before subprogram instantiations");
      Assert (Item_Label (O, 2) = "procedure Run",
              "procedure instantiation keeps compact procedure label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "instantiation") /= 0,
              "same-line procedure instantiation is classified as an instantiation");
      Assert (Item_Label (O, 3) = "function Make",
              "split function instantiation keeps compact function label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "instantiation") /= 0,
              "split function instantiation waits for the terminating semicolon");
      Assert (Item_Label (O, 4) = "subtype After_Instantiation",
              "following subtype still extracts after subprogram instantiations");
      Assert (Item_Line (O, 2) = 2 and then Item_Line (O, 3) = 3,
              "subprogram instantiation targets stay on first declaration lines");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1,
              "subprogram instantiations do not open package-member depth");
   end Test_Completeness_Subprogram_Instantiations;

   procedure Test_Completeness_Split_Is_New_Instantiations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   package Int_Vectors is" & ASCII.LF &
           "      new Ada.Containers.Vectors" & ASCII.LF &
           "        (Positive, Integer);" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "      new Generic_Run;" & ASCII.LF &
           "   function Make is" & ASCII.LF &
           "      new Generic_Make" & ASCII.LF &
           "        (Integer);" & ASCII.LF &
           "   subtype After_Instantiation is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "completeness extracts split is/new instantiations without extra rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Demo",
              "package body remains first item before split instantiations");
      Assert (Item_Label (O, 2) = "package Int_Vectors",
              "split package instantiation keeps compact package label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "instantiation") /= 0,
              "split package instantiation is classified as instantiation");
      Assert (Item_Label (O, 3) = "procedure Run",
              "split procedure instantiation removes provisional body label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "instantiation") /= 0,
              "split procedure instantiation is classified as instantiation");
      Assert (Item_Label (O, 4) = "function Make",
              "split function instantiation keeps compact function label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 4), "instantiation") /= 0,
              "split function instantiation is classified as instantiation");
      Assert (Item_Label (O, 5) = "subtype After_Instantiation",
              "following subtype still extracts after split is/new instantiations");
      Assert (Item_Line (O, 2) = 2
                and then Item_Line (O, 3) = 5
                and then Item_Line (O, 4) = 7,
              "split is/new instantiation targets stay on first declaration lines");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1
                and then Item_Depth (O, 5) = 1,
              "split is/new instantiations do not open package-member depth");
   end Test_Completeness_Split_Is_New_Instantiations;

   procedure Test_Completeness_Completed_Split_Instantiation_Clears_Candidate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   function Make is" & ASCII.LF &
           "      new Generic_Make;" & ASCII.LF &
           "   new Unexpected;" & ASCII.LF &
           "   subtype After_Instantiation is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "completeness ignores malformed new line after completed split instantiation");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "function Make",
              "split function instantiation keeps compact function label after completion");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "instantiation") /= 0,
              "split function instantiation finalizes through pending declaration state");
      Assert (Item_Label (O, 3) = "subtype After_Instantiation",
              "following subtype still extracts after malformed new continuation");
      Assert (Item_Depth (O, 2) = 1 and then Item_Depth (O, 3) = 1,
              "completed split instantiation clears candidate state before later new-prefixed text");
   end Test_Completeness_Completed_Split_Instantiation_Clears_Candidate;

   procedure Test_Completeness_Private_Child_Package_Specs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("private package Demo.Hidden is" & ASCII.LF &
           "   subtype Index is Natural;" & ASCII.LF &
           "end Demo.Hidden;" & ASCII.LF &
           "package body Demo.Hidden is" & ASCII.LF &
           "end Demo.Hidden;",
           "demo-hidden.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "completeness extracts private child package specs and bodies");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo.Hidden",
              "private child package spec uses compact package label");
      Assert (Item_Line (O, 1) = 1 and then Item_Column (O, 1) = 9,
              "private child package target points to package keyword, not private prefix");
      Assert (Item_Label (O, 2) = "subtype Index",
              "private child package contents still extract in source order");
      Assert (Item_Depth (O, 2) = 1,
              "private child package spec opens package-member depth");
      Assert (Item_Label (O, 3) = "package body Demo.Hidden",
              "ordinary package body after private spec remains recognized");
      Assert (Item_Depth (O, 3) = 0,
              "private child package close restores top-level depth before body");
   end Test_Completeness_Private_Child_Package_Specs;

   procedure Test_Completeness_Generic_Private_Child_Package_Specs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is private;" & ASCII.LF &
           "private package Demo.Hidden is" & ASCII.LF &
           "   subtype Index is Natural;" & ASCII.LF &
           "end Demo.Hidden;" & ASCII.LF &
           "package body Demo.Hidden is" & ASCII.LF &
           "end Demo.Hidden;",
           "demo-hidden.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "completeness extracts generic private child package specs");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element",
              "generic private child package formal type is visible");
      Assert (Item_Label (O, 2) = "generic package Demo.Hidden",
              "generic marker applies to private child package spec, not to formal private type");
      Assert (Item_Line (O, 2) = 3 and then Item_Column (O, 2) = 9,
              "generic private child package target points to package keyword");
      Assert (Item_Label (O, 3) = "subtype Index",
              "generic private child package contents still extract");
      Assert (Item_Depth (O, 3) = 1,
              "generic private child package opens package-member depth");
      Assert (Item_Label (O, 4) = "package body Demo.Hidden",
              "following package body does not inherit the generic marker");
      Assert (Item_Depth (O, 4) = 0,
              "generic private child package close restores top-level depth");
   end Test_Completeness_Generic_Private_Child_Package_Specs;

   procedure Test_Completeness_Split_Is_Separate_Body_Stubs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo.Child is" & ASCII.LF &
           "   separate;" & ASCII.LF &
           "procedure Worker is" & ASCII.LF &
           "   separate;" & ASCII.LF &
           "function Make return Integer is" & ASCII.LF &
           "   separate;" & ASCII.LF &
           "subtype After_Stub is Natural;",
           "demo-child.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "completeness extracts split is/separate body stubs without stale depth");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Demo.Child",
              "split package body stub remains a package body row");
      Assert (Item_Depth (O, 1) = 0,
              "split package body stub stays at top-level depth");
      Assert (Item_Label (O, 2) = "procedure body Worker",
              "split procedure body stub remains a body row");
      Assert (Item_Depth (O, 2) = 0,
              "split procedure body stub does not keep depth open");
      Assert (Item_Label (O, 3) = "function body Make",
              "split function body stub remains a body row");
      Assert (Item_Depth (O, 3) = 0,
              "split function body stub does not keep depth open");
      Assert (Item_Label (O, 4) = "subtype After_Stub",
              "following subtype remains visible after split body stubs");
      Assert (Item_Depth (O, 4) = 0,
              "following subtype is not nested under a split body stub");
   end Test_Completeness_Split_Is_Separate_Body_Stubs;

   procedure Test_Completeness_Semicolons_In_Strings_Do_Not_End_Declarations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   procedure With_Aspect" & ASCII.LF &
           "     with Note => ""not; done""" & ASCII.LF &
           "     is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end With_Aspect;" & ASCII.LF &
           "   function Expr return Boolean" & ASCII.LF &
           "     with Note => ""not; an end""" & ASCII.LF &
           "     is" & ASCII.LF &
           "     (True);" & ASCII.LF &
           "   subtype After_String_Semicolon is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "completeness ignores semicolons inside strings while ending declarations");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "package row remains first with string-semicolon declarations");
      Assert (Item_Label (O, 2) = "procedure body With_Aspect",
              "string semicolon in aspect does not prematurely finalize procedure declaration");
      Assert (Item_Depth (O, 2) = 1,
              "procedure body remains a package member");
      Assert (Item_Label (O, 3) = "expression function Expr",
              "string semicolon in aspect does not hide split expression function classification");
      Assert (Item_Depth (O, 3) = 1,
              "expression function remains a package member");
      Assert (Item_Label (O, 4) = "subtype After_String_Semicolon",
              "following subtype remains visible after string semicolon declarations");
      Assert (Item_Depth (O, 4) = 1,
              "following subtype remains at package-member depth");
   end Test_Completeness_Semicolons_In_Strings_Do_Not_End_Declarations;

   procedure Test_Completeness_Protected_Type_Label_Branch_Compiles
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   protected type Lock is" & ASCII.LF &
           "      procedure Enter;" & ASCII.LF &
           "   end Lock;" & ASCII.LF &
           "   protected body Lock is" & ASCII.LF &
           "      procedure Enter is null;" & ASCII.LF &
           "   end Lock;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) >= 4,
              "completeness extracts protected type/body rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "package remains first around protected declarations");
      Assert (Item_Label (O, 2) = "protected type Lock",
              "protected type label branch is present and deterministic");
      Assert (Item_Label (O, 3) = "procedure Enter",
              "protected type operation remains nested under protected type");
      Assert (Item_Depth (O, 3) = 2,
              "protected type operation keeps deterministic lexical depth");
      Assert (Item_Label (O, 4) = "protected body Lock",
              "protected body label branch remains deterministic");
   end Test_Completeness_Protected_Type_Label_Branch_Compiles;

   procedure Test_Completeness_Character_Literal_Semicolons_Do_Not_End_Declarations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   procedure With_Aspect" & ASCII.LF &
           "     with Note => ';'" & ASCII.LF &
           "     is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end With_Aspect;" & ASCII.LF &
           "   function Ready return Boolean" & ASCII.LF &
           "     with Note => ';'" & ASCII.LF &
           "     is" & ASCII.LF &
           "     (True);" & ASCII.LF &
           "   subtype After_Character_Aspect is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) >= 4,
              "completeness keeps declarations open across character-literal semicolons");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "procedure body With_Aspect",
              "semicolon character literal does not finalize split procedure as declaration");
      Assert (Item_Label (O, 3) = "expression function Ready",
              "semicolon character literal does not hide split expression function");
      Assert (Item_Label (O, 4) = "subtype After_Character_Aspect",
              "following subtype remains visible after character-literal aspect declarations");
      Assert (Item_Depth (O, 4) = 1,
              "following subtype keeps package-member depth after character-literal aspects");
   end Test_Completeness_Character_Literal_Semicolons_Do_Not_End_Declarations;

   procedure Test_Ada_Outline_Extracts_Subtype_And_Navigates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "package Demo is" & ASCII.LF &
            "   subtype Count is Natural;" & ASCII.LF &
            "   procedure Run;" & ASCII.LF &
            "end Demo;");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Ada outline refresh remains command-owned");
      Assert (Item_Count (S.Outline) = 3,
              "Ada outline extracts package, subtype, and procedure rows");
      Assert (Item_Label (S.Outline, 2) = "subtype Count",
              "subtype row has a compact Ada symbol label");
      Assert (Item_Kind (S.Outline, 2) = Outline_Type,
              "subtype reuses the existing type outline kind");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 2) = "subtype Count",
              "Feature Panel projection displays the subtype row");

      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "activating a real Ada outline row navigates");
      Editor.State.Row_Col_For_Index (S, S.Carets (0).Pos, Row, Col);
      Assert (Row = 1 and then Col = 3,
              "outline navigation uses the stored target line and column");
   end Test_Ada_Outline_Extracts_Subtype_And_Navigates;

   procedure Test_Ada_Multiline_Declaration_Window_Uses_Sanitized_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           "   procedure Run" & ASCII.LF &
           "     (Name : String := ""procedure Fake; end Real;""; -- function Hidden return Integer" & ASCII.LF &
           "      Value : Integer);" & ASCII.LF &
           "   function After return Integer;" & ASCII.LF &
           "end Real;",
           "multiline_sanitized.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "multi-line declaration windows ignore fake text in strings/comments");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "package row survives multi-line declaration fixture");
      Assert (Item_Label (O, 2) = "procedure Run",
              "split procedure row survives inline comment/string text");
      Assert (Item_Label (O, 3) = "function After",
              "following declaration proves pending window closed on code semicolon");
   end Test_Ada_Multiline_Declaration_Window_Uses_Sanitized_Text;

   procedure Test_Ada_Sanitized_View_Is_Transient_And_Derived
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line_A : constant String := "procedure Real; -- procedure Fake;";
      Line_B : constant String := "procedure Real;";
      A1 : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line_A);
      A2 : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line_A);
      B1 : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line_B);
   begin
      Assert (A1 = A2,
              "sanitized view is derived deterministically from the supplied line");
      Assert (A1'Length = Line_A'Length and then B1'Length = Line_B'Length,
              "sanitized views preserve each source line shape independently");
      Assert (Ada.Strings.Fixed.Index (A1, "Fake") = 0,
              "sanitized view masks comment-only fake text");
      Assert (Ada.Strings.Fixed.Index (B1, "Real") /= 0,
              "separate derived view has no retained mask from previous line");
      Assert (Line_A /= A1,
              "sanitizer returns a transient code view and never rewrites caller text");
   end Test_Ada_Sanitized_View_Is_Transient_And_Derived;

   procedure Test_Ada_Generic_Formals_And_Case_Loop_Use_Code_Only_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   Name : constant String := ""package Fake is; procedure Hidden;"";" & ASCII.LF &
           "   -- function Hidden return Integer;" & ASCII.LF &
           "package Real is" & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Real;" & ASCII.LF &
           "package body Real is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      for I in 1 .. 2 loop" & ASCII.LF &
           "         case I is" & ASCII.LF &
           "            when 1 => Put_Line (""end case; end loop; end Run;"");" & ASCII.LF &
           "            when others => null; -- end case; end loop;" & ASCII.LF &
           "         end case;" & ASCII.LF &
           "      end loop;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Real;",
           "generic_case_loop.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "generic formals and case/loop strings do not create fake rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert_Has_Label (O, "generic package Real",
              "real generic package survives sanitized formal defaults");
      Assert_Has_Label (O, "procedure Run",
              "package-spec procedure survives sanitized generic formal lines");
      Assert_Has_Label (O, "package body Real",
              "real package body is not confused by prior string/comment fakes");
      Assert_Has_Label (O, "procedure body Run",
              "real procedure body is extracted after generic spec");
      Assert (Ada.Strings.Fixed.Index
                (Item_Detail (O, First_Label_Index (O, "procedure body Run")), "lines 8-16") /= 0,
              "case/loop end tokens inside strings/comments do not truncate procedure range");
   end Test_Ada_Generic_Formals_And_Case_Loop_Use_Code_Only_Text;

   procedure Test_Ada_Structure_Normalization_Reapplies_Code_Only_View
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Line : constant String :=
        "      Text : constant String := ""Inner: begin""; -- Hidden: loop";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      String_Label_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "Inner: begin");
      Comment_Label_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "Hidden: loop");
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           Line & ASCII.LF &
           "      Inner : declare" & ASCII.LF &
           "      begin" & ASCII.LF &
           "         null;" & ASCII.LF &
           "      end Inner;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Demo;",
           "structure_normalization_code_only.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized'Length = Line'Length,
              "structure-normalization fixture preserves line length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "Inner: begin") = 0,
              "label-like begin text inside strings is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "Hidden: loop") = 0,
              "label-like loop text inside comments is masked");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (String_Label_Column)),
              "string label-like structure text is non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Comment_Label_Column)),
              "comment label-like structure text is non-code");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "label-like non-code structure text creates no fake outline rows");
      Assert (Item_Label (O, 1) = "package body Demo",
              "structure-normalization fixture keeps package body row");
      Assert (Item_Label (O, 2) = "procedure body Run",
              "structure-normalization fixture keeps procedure body row");
      Assert (Item_Detail (O, 2) = "lines 2-9 body",
              "normalized structure scan ignores label-like string/comment text");
   end Test_Ada_Structure_Normalization_Reapplies_Code_Only_View;

   procedure Test_Ada_Record_Component_Fields_Are_Extracted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Model is" & ASCII.LF &
           "   type Point is record" & ASCII.LF &
           "      X : Integer;" & ASCII.LF &
           "      Y, Z : Integer := 0;" & ASCII.LF &
           "      case Has_Label is" & ASCII.LF &
           "         when True =>" & ASCII.LF &
           "            Label : Natural;" & ASCII.LF &
           "         when False =>" & ASCII.LF &
           "            null;" & ASCII.LF &
           "      end case;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "record field extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 6,
              "package, variant record type, and component rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Model", "package row remains first");
      Assert (Item_Label (O, 2) = "variant record type Point", "variant record type row is preserved");
      Assert (Item_Label (O, 3) = "field X", "single component row extracted");
      Assert (Item_Label (O, 4) = "field Y", "first multi-name component row extracted");
      Assert (Item_Label (O, 5) = "field Z", "second multi-name component row extracted");
      Assert (Item_Label (O, 6) = "field Label", "variant component row extracted");
      Assert (Item_Kind (O, 3) = Outline_Field, "component uses field kind");
      Assert (Item_Depth (O, 3) = Item_Depth (O, 2) + 1,
              "component depth is nested under record type");
      Assert (Item_Detail (O, 3) = "line 3 component",
              "component detail identifies record component form");
      Assert (Item_Target_Kind (O, 3) = Buffer_Position_Target,
              "component row navigates to source position");
   end Test_Ada_Record_Component_Fields_Are_Extracted;

   procedure Test_Ada_Record_Field_Scanner_Ignores_Non_Component_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Model is" & ASCII.LF &
           "   type Choice is record" & ASCII.LF &
           "      -- Fake : Integer;" & ASCII.LF &
           "      Text : String := ""not : a field;"";" & ASCII.LF &
           "      when_flag : Boolean;" & ASCII.LF &
           "      case Kind is" & ASCII.LF &
           "         when others =>" & ASCII.LF &
           "            null;" & ASCII.LF &
           "      end case;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "record field extraction with non-code fakes succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "only package, record type, and real component rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 3) = "field Text",
              "field with string-literal punctuation is extracted once");
      Assert (Item_Label (O, 4) = "field when_flag",
              "identifier containing keyword text is still a component");
   end Test_Ada_Record_Field_Scanner_Ignores_Non_Component_Lines;

   procedure Test_Ada_Enumeration_Literals_Are_Extracted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Model is" & ASCII.LF &
           "   type Color is (Red, Green, Blue);" & ASCII.LF &
           "   type Mode is" & ASCII.LF &
           "     (Fast," & ASCII.LF &
           "      Slow);" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "enumeration literal extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 8,
              "package, enum types, and literal rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "enum type Color",
              "single-line enumeration type label is explicit");
      Assert (Item_Label (O, 3) = "literal Red",
              "first literal row is extracted");
      Assert (Item_Label (O, 5) = "literal Blue",
              "last single-line literal row is extracted");
      Assert (Item_Label (O, 6) = "enum type Mode",
              "split enumeration type label is explicit");
      Assert (Item_Label (O, 7) = "literal Fast",
              "split first literal row is extracted");
      Assert (Item_Label (O, 8) = "literal Slow",
              "split final literal row is extracted");
      Assert (Item_Kind (O, 3) = Outline_Enum_Literal,
              "literal row uses enum literal kind");
      Assert (Item_Depth (O, 3) = Item_Depth (O, 2) + 1,
              "literal depth is nested under enumeration type");
      Assert (Item_Detail (O, 3) = "line 2 enumeration",
              "literal detail identifies enumeration form");
   end Test_Ada_Enumeration_Literals_Are_Extracted;

   procedure Test_Ada_Package_Exception_And_Constant_Declarations_Are_Extracted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Model is" & ASCII.LF &
           "   Limit : constant Natural := 10;" & ASCII.LF &
           "   Parse_Error, Read_Error : exception;" & ASCII.LF &
           "   type Point is record" & ASCII.LF &
           "      X : Integer;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "package exception and constant extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 6,
              "package, constant, split exceptions, record, and field rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "constant Limit",
              "package constant row is extracted");
      Assert (Item_Label (O, 3) = "exception Parse_Error",
              "first exception declaration row is extracted");
      Assert (Item_Label (O, 4) = "exception Read_Error",
              "second exception declaration row is extracted");
      Assert (Item_Kind (O, 2) = Outline_Object,
              "constant row uses object kind");
      Assert (Item_Kind (O, 3) = Outline_Exception,
              "exception row uses exception kind");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "constant") /= 0,
              "constant detail identifies declaration form");
      Assert (Item_Detail (O, 3) = "line 3 exception",
              "exception detail identifies declaration form");
   end Test_Ada_Package_Exception_And_Constant_Declarations_Are_Extracted;

   procedure Test_Ada_Object_Scanner_Ignores_Local_And_Non_Object_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Model is" & ASCII.LF &
           "   Public_State : Natural;" & ASCII.LF &
           "   for Public_State'Address use System'To_Address (0);" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "      Local_State : Natural := 0;" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "object scanner with local and representation lines succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "only package body, package-level object, and procedure body rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Model",
              "package body row remains first");
      Assert (Item_Label (O, 2) = "object Public_State",
              "package-body declarative object row is extracted");
      Assert (Item_Label (O, 3) = "procedure body Run",
              "procedure body row remains extracted");
   end Test_Ada_Object_Scanner_Ignores_Local_And_Non_Object_Lines;

   procedure Test_Ada_Representation_Clauses_Are_Detail_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Model is" & ASCII.LF &
           "   type R is record" & ASCII.LF &
           "      A : Integer;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "   for R use record" & ASCII.LF &
           "      A at 0 range 0 .. 31;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "   State : Integer;" & ASCII.LF &
           "   for State'Address use System'To_Address (0);" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "representation metadata extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "representation clauses do not create standalone outline rows");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "record type R",
              "record type row remains parser-owned");
      Assert (Item_Detail (O, 2) = "lines 2-4 record",
              "record type detail carries its source range");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "representation") /= 0,
              "record component detail carries representation metadata");
      Assert (Item_Label (O, 4) = "object State",
              "object row remains extracted after representation record");
      Assert (Item_Detail (O, 4) = "line 8 object representation",
              "object detail carries address representation metadata");
   end Test_Ada_Representation_Clauses_Are_Detail_Metadata;

   procedure Test_Ada_Generic_Formals_Are_Extracted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is private;" & ASCII.LF &
           "   Capacity : Positive := 10;" & ASCII.LF &
           "   with function ""<"" (Left, Right : Element) return Boolean;" & ASCII.LF &
           "   with procedure Visit (Item : Element);" & ASCII.LF &
           "   with package IO is new Ada.Text_IO.Integer_IO (Integer);" & ASCII.LF &
           "package Model.Generic_Box is" & ASCII.LF &
           "end Model.Generic_Box;" & ASCII.LF,
           "model-generic.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "generic formal extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 6,
              "formal type/object/subprogram/package rows and generic package row are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element",
              "formal type row is extracted");
      Assert (Item_Label (O, 2) = "formal object Capacity",
              "formal object row is extracted");
      Assert (Item_Label (O, 3) = "formal function ""<""",
              "formal operator function row is extracted");
      Assert (Item_Label (O, 4) = "formal procedure Visit",
              "formal procedure row is extracted");
      Assert (Item_Label (O, 5) = "formal package IO",
              "formal package row is extracted");
      Assert (Item_Label (O, 6) = "generic package Model.Generic_Box",
              "generic package row still follows formals");
      Assert (Item_Kind (O, 1) = Outline_Generic_Formal,
              "formal rows use generic formal kind");
      Assert (Item_Detail (O, 1) = "line 2 generic formal type",
              "formal type detail identifies generic-formal type");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "generic formal function") /= 0,
              "formal function detail identifies generic-formal function");
   end Test_Ada_Generic_Formals_Are_Extracted;

   procedure Test_Ada_Generic_Formal_Continuations_Are_Not_Duplicated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is" & ASCII.LF &
           "      private;" & ASCII.LF &
           "   with function Render" & ASCII.LF &
           "     (Item : Element) return String;" & ASCII.LF &
           "package Model.Box is" & ASCII.LF &
           "end Model.Box;" & ASCII.LF,
           "box.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "split generic formal extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "only first formal lines and the generic package row are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element",
              "split formal type is represented by its leading line");
      Assert (Item_Label (O, 2) = "formal function Render",
              "split formal function is represented by its leading line");
      Assert (Item_Label (O, 3) = "generic package Model.Box",
              "generic package row is preserved after split formals");
   end Test_Ada_Generic_Formal_Continuations_Are_Not_Duplicated;

   procedure Test_Ada_Outline_Extracts_Subunits_Abstract_Null_And_Operators
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   abstract procedure Hook;" & ASCII.LF &
           "   overriding procedure Run;" & ASCII.LF &
           "   not overriding function Make return Natural;" & ASCII.LF &
           "   procedure Stop is null;" & ASCII.LF &
           "   function ""+"" (Left, Right : Natural) return Natural;" & ASCII.LF &
           "   separate (Demo) procedure Worker is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Worker;" & ASCII.LF &
           "end Demo;" & ASCII.LF,
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "Ada abstract/null/operator/subunit extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "package body, abstract/overriding/null/operator/subunit rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "procedure Hook",
              "abstract procedure prefix does not hide the procedure row");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "abstract") /= 0,
              "abstract procedure metadata is retained in outline details");
      Assert (Item_Label (O, 3) = "procedure Run",
              "overriding procedure prefix is stripped from the outline label");
      Assert (Item_Label (O, 4) = "function Make",
              "not-overriding function prefix is stripped from the outline label");
      Assert (Item_Label (O, 5) = "procedure body Stop",
              "null procedure declaration is retained as a body-like procedure row");
      Assert (Item_Label (O, 6) = "function ""+""",
              "operator function names are retained as quoted operator labels");
      Assert (Item_Label (O, 7) = "procedure body Worker",
              "same-line separate subprogram body is extracted as a body row");
      Assert (Item_Kind (O, 6) = Outline_Function,
              "operator function row uses function kind");
      Assert (Item_Detail (O, 7) = "lines 7-10 body",
              "separate subprogram body receives a closed body range");
   end Test_Ada_Outline_Extracts_Subunits_Abstract_Null_And_Operators;

   procedure Test_Ada_Outline_Extracts_Entries_Instantiations_And_Child_Packages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("private package A.B.C is" & ASCII.LF &
           "   task type Worker is" & ASCII.LF &
           "      entry Start;" & ASCII.LF &
           "   end Worker;" & ASCII.LF &
           "   protected type Guard is" & ASCII.LF &
           "      entry Lock;" & ASCII.LF &
           "   end Guard;" & ASCII.LF &
           "   package Numbers is new Ada.Text_IO.Integer_IO (Integer);" & ASCII.LF &
           "   procedure Visit is new Generic_Visit;" & ASCII.LF &
           "end A.B.C;" & ASCII.LF,
           "a-b-c.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "Ada child package/task/protected/instantiation extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "child package, task/protected entries, and instantiation rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package A.B.C",
              "private child package declaration keeps its qualified package name");
      Assert (Item_Label (O, 2) = "task type Worker",
              "task type row is extracted");
      Assert (Item_Label (O, 3) = "entry Start",
              "task entry declaration row is extracted");
      Assert (Item_Label (O, 4) = "protected type Guard",
              "protected type row is extracted");
      Assert (Item_Label (O, 5) = "entry Lock",
              "protected entry declaration row is extracted");
      Assert (Item_Label (O, 6) = "package Numbers",
              "generic package instantiation row is extracted");
      Assert (Item_Label (O, 7) = "procedure Visit",
              "generic procedure instantiation row is extracted");
      Assert (Item_Detail (O, 6) = "line 8 instantiation generic-actuals",
              "package instantiation detail is explicit");
      Assert (Item_Detail (O, 7) = "line 9 instantiation is new Generic_Visit",
              "procedure instantiation detail is explicit");
      Assert (Item_Depth (O, 3) = Item_Depth (O, 2) + 1,
              "task entry is nested under the task type");
      Assert (Item_Depth (O, 5) = Item_Depth (O, 4) + 1,
              "protected entry is nested under the protected type");
   end Test_Ada_Outline_Extracts_Entries_Instantiations_And_Child_Packages;

   procedure Test_Ada_Outline_Precision_For_Expanded_Constructs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   with package Formal is new Generic_Formal (<>);" & ASCII.LF &
           "package Demo is" & ASCII.LF &
           "   type Shape (Kind : Natural) is record" & ASCII.LF &
           "      case Kind is" & ASCII.LF &
           "         when 0 => null;" & ASCII.LF &
           "         when others => Value : Integer;" & ASCII.LF &
           "      end case;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "   protected type Gate is" & ASCII.LF &
           "      entry Slot (Positive range <>) when Ready;" & ASCII.LF &
           "   end Gate;" & ASCII.LF &
           "   Local_Error : exception;" & ASCII.LF &
           "end Demo;" & ASCII.LF &
           "package body Demo is separate;" & ASCII.LF,
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "pass 707 outline extraction succeeds for expanded Ada constructs");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 9,
              "pass 707 outline keeps formal package, variant record, variant field, entry family, exception, and stub rows");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal package Formal",
              "formal package rows remain first-class generic formal outline rows");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "generic formal package") /= 0,
              "formal package detail is specific rather than a generic formal blob");
      Assert (Item_Label (O, 3) = "variant record type Shape",
              "variant record type label exposes variant-record metadata");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "variant-record") /= 0,
              "variant record detail retains structural metadata");
      Assert (Item_Label (O, 7) = "entry family Slot",
              "entry-family declarations are distinct from ordinary entries in Outline");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 7), "entry-family") /= 0,
              "entry-family detail is retained for filtering and inspection");
      Assert (Item_Label (O, 8) = "exception Local_Error",
              "exception declarations remain visible outline rows");
      Assert (Item_Label (O, 9) = "package body Demo",
              "body stubs keep the package-body label instead of degrading to unknown");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 9), "body-stub") /= 0,
              "body-stub detail is visible to Outline without semantic compilation");
   end Test_Ada_Outline_Precision_For_Expanded_Constructs;

   procedure Test_Ada_Outline_Type_Family_Label_Precision
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   with type Formal_Vector is array (Positive range <>) of Integer;" & ASCII.LF &
           "   with type Formal_Callback is access function return Integer;" & ASCII.LF &
           "package Demo is" & ASCII.LF &
           "   type Vector is array (Positive range <>) of Integer;" & ASCII.LF &
           "   type Link is access all Integer;" & ASCII.LF &
           "   type Callback is access function return Integer;" & ASCII.LF &
           "   type Child is new Parent with private;" & ASCII.LF &
           "end Demo;" & ASCII.LF,
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "pass 721 outline extraction succeeds for expanded type families");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "pass 721 outline keeps formal type rows and package type rows");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal array type Formal_Vector",
              "formal array type label exposes array metadata");
      Assert (Item_Label (O, 2) = "formal access subprogram type Formal_Callback",
              "formal access-to-subprogram type label exposes callable access metadata");
      Assert (Item_Label (O, 4) = "array type Vector",
              "array type label exposes array metadata");
      Assert (Item_Label (O, 5) = "access type Link",
              "access object type label exposes access metadata");
      Assert (Item_Label (O, 6) = "access subprogram type Callback",
              "access-to-subprogram type label exposes callable access metadata");
      Assert (Item_Label (O, 7) = "private extension type Child",
              "private extension type label exposes derived private-extension metadata");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 4), "array") /= 0,
              "array metadata remains in detail for filtering");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 6), "access-subprogram") /= 0,
              "access-subprogram metadata remains in detail for filtering");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 7), "private-extension") /= 0,
              "private-extension metadata remains in detail for filtering");
   end Test_Ada_Outline_Type_Family_Label_Precision;

   overriding procedure Register_Tests (T : in out Ada_Extraction_Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Command_Refresh_Uses_Buffer_Markers'Access,
                        "command refresh uses buffer marker extraction");
      Register_Routine (T, Test_Extractor_Marker_Grammar'Access,
                        "extractor marker grammar is deterministic");
      Register_Routine
        (T, Test_Outline_Marker_Fallback_Is_Marker_Only'Access,
         "outline fallback is marker-only");
      Register_Routine (T, Test_Marker_Grammar_Freeze_And_Edge_Cases'Access,
                        "marker grammar and edge cases are frozen");
      Register_Routine (T, Test_Ada_Outline_Extracts_Common_Declarations'Access,
                        "Ada outline extracts common declarations");
      Register_Routine (T, Test_Ada_Outline_Empty_And_Non_Ada_Are_Unsupported'Access,
                        "Ada outline empty and non-Ada are unsupported");
      Register_Routine (T, Test_Ada_Outline_Rows_Open_To_Target_Line'Access,
                        "Ada outline rows open to target line");
      Register_Routine (T, Test_Ada_Outline_Result_Still_Rejected_When_Stale'Access,
                        "Ada outline stale result rejection");
      Register_Routine (T, Test_Ada_Outline_Extracts_Multiline_Procedure'Access,
                        "Ada outline extracts multi-line procedure");
      Register_Routine (T, Test_Ada_Outline_Extracts_Multiline_Function'Access,
                        "Ada outline extracts multi-line function");
      Register_Routine (T, Test_Ada_Outline_Does_Not_Duplicate_Continuation_Lines'Access,
                        "Ada outline avoids continuation duplicates");
      Register_Routine (T, Test_Ada_Outline_Extracts_Generic_Package'Access,
                        "Ada outline extracts generic package");
      Register_Routine (T, Test_Ada_Outline_Extracts_Generic_Procedure_And_Function'Access,
                        "Ada outline extracts generic subprograms");
      Register_Routine (T, Test_Ada_Outline_Clears_Pending_Generic_After_Use'Access,
                        "Ada outline clears pending generic marker");
      Register_Routine (T, Test_Ada_Outline_Assigns_Depth_For_Package_Members'Access,
                        "Ada outline assigns depth for package members");
      Register_Routine (T, Test_Ada_Outline_Depth_Remains_Stable_On_Unmatched_End'Access,
                        "Ada outline depth remains stable on unmatched end");
      Register_Routine (T, Test_Ada_Outline_Distinguishes_Package_Spec_And_Body'Access,
                        "Ada outline distinguishes package spec and body");
      Register_Routine (T, Test_Ada_Outline_Distinguishes_Procedure_Declaration_And_Body'Access,
                        "Ada outline distinguishes procedure declaration and body");
      Register_Routine (T, Test_Ada_Outline_Still_Rejects_Stale_Multiline_Result'Access,
                        "Ada outline rejects stale multi-line result");
      Register_Routine (T, Test_Ada_Outline_Unsupported_Buffer_Clears_Previous_Rows'Access,
                        "unsupported buffer clears previous rows");
      Register_Routine
        (T, Test_Ada_Outline_Extracts_Renames_And_Expression_Functions'Access,
         "Ada outline extracts renames and expression functions");
      Register_Routine
        (T, Test_Ada_Outline_Extracts_Type_Forms'Access,
         "Ada outline extracts type forms");
      Register_Routine
        (T, Test_Ada_Outline_Extracts_Task_And_Protected_Forms'Access,
         "Ada outline extracts task and protected forms");
      Register_Routine
        (T, Test_Ada_Outline_Generic_Marker_Is_Bounded_Across_Formals'Access,
         "Ada outline generic marker is bounded across formals");
      Register_Routine
        (T, Test_Ada_Outline_Handles_Multiline_Renames_And_Operators'Access,
         "Ada outline handles multiline renames and operator functions");
      Register_Routine
        (T, Test_Ada_Outline_Coverage_Coherent'Access,
         "Ada outline coverage coherent");
      Register_Routine
        (T, Test_Completeness_Multiline_Type_And_Expression_Functions'Access,
         "completeness handles multiline type and expression functions");
      Register_Routine
        (T, Test_Completeness_Split_Generic_Formals_Keep_Marker'Access,
         "completeness keeps marker through split generic formals");
      Register_Routine
        (T, Test_Completeness_Split_Generic_Package_Formal_Keep_Marker'Access,
         "completeness keeps marker through split generic package formals");
      Register_Routine
        (T, Test_Completeness_Comments_Strings_And_Generic_Task_Boundary'Access,
         "completeness preserves comment/string and generic boundaries");
      Register_Routine
        (T, Test_Completeness_Split_Package_Forms_Do_Not_Open_Depth'Access,
         "completeness handles split package instantiation/rename depth");
      Register_Routine
        (T, Test_Completeness_Null_And_Separate_Subprogram_Bodies'Access,
         "completeness handles null/separate subprogram bodies");
      Register_Routine
        (T, Test_Completeness_Record_Named_Types_Are_Not_Records'Access,
         "completeness keeps record-named access/array types as plain types");
      Register_Routine
        (T, Test_Completeness_Private_Named_Types_Are_Not_Private'Access,
         "completeness keeps private-named references as plain types");
      Register_Routine
        (T, Test_Completeness_Is_Followed_By_Uses_Code_Tokens'Access,
         "completeness keeps is-followed-by checks outside strings");
      Register_Routine
        (T, Test_Completeness_Code_Tokens_Ignore_Strings'Access,
         "completeness keeps code-token checks outside strings");
      Register_Routine
        (T, Test_Completeness_Expression_Function_Is_Open_Paren'Access,
         "completeness handles expression functions with is followed by open paren");
      Register_Routine
        (T, Test_Completeness_Overriding_Subprograms'Access,
         "completeness handles overriding subprogram declarations");
      Register_Routine
        (T, Test_Completeness_Separate_Subunit_Bodies'Access,
         "completeness handles separate subunit bodies");
      Register_Routine
        (T, Test_Completeness_End_Name_Keyword_Prefixes_Close_Depth'Access,
         "completeness closes depth for end names that prefix Ada keywords");
      Register_Routine
        (T, Test_Completeness_Subprogram_Instantiations'Access,
         "completeness handles subprogram instantiations");
      Register_Routine
        (T, Test_Completeness_Split_Is_New_Instantiations'Access,
         "completeness handles split is/new instantiations");
      Register_Routine
        (T, Test_Completeness_Completed_Split_Instantiation_Clears_Candidate'Access,
         "completeness clears completed split instantiation candidates");
      Register_Routine
        (T, Test_Completeness_Private_Child_Package_Specs'Access,
         "completeness handles private child package specs");
      Register_Routine
        (T, Test_Completeness_Generic_Private_Child_Package_Specs'Access,
         "completeness handles generic private child package specs");
      Register_Routine
        (T, Test_Completeness_Split_Is_Separate_Body_Stubs'Access,
         "completeness handles split is/separate body stubs");
      Register_Routine
        (T, Test_Completeness_Semicolons_In_Strings_Do_Not_End_Declarations'Access,
         "completeness ignores string semicolons in declaration windows");
      Register_Routine
        (T, Test_Completeness_Protected_Type_Label_Branch_Compiles'Access,
         "completeness keeps protected type label branch compile-clean");
      Register_Routine
        (T, Test_Completeness_Character_Literal_Semicolons_Do_Not_End_Declarations'Access,
         "completeness ignores character literal semicolons in declaration windows");
      Register_Routine
        (T, Test_Ada_Outline_Extracts_Subtype_And_Navigates'Access,
         "Ada outline extracts subtype and navigates");
      Register_Routine
        (T, Test_Ada_Multiline_Declaration_Window_Uses_Sanitized_Text'Access,
         "Ada multi-line declaration windows use sanitized text");
      Register_Routine
        (T, Test_Ada_Sanitized_View_Is_Transient_And_Derived'Access,
         "Ada sanitized view is transient and derived");
      Register_Routine
        (T, Test_Ada_Generic_Formals_And_Case_Loop_Use_Code_Only_Text'Access,
         "Ada generic formals and case loop use code-only text");
      Register_Routine
        (T, Test_Ada_Structure_Normalization_Reapplies_Code_Only_View'Access,
         "Ada structure normalization reapplies code-only view");
      Register_Routine
        (T, Test_Ada_Record_Component_Fields_Are_Extracted'Access,
         "Ada record component fields are extracted");
      Register_Routine
        (T, Test_Ada_Record_Field_Scanner_Ignores_Non_Component_Lines'Access,
         "Ada record field scanner ignores non-component lines");
      Register_Routine
        (T, Test_Ada_Enumeration_Literals_Are_Extracted'Access,
         "Ada enumeration literals are extracted");
      Register_Routine
        (T, Test_Ada_Package_Exception_And_Constant_Declarations_Are_Extracted'Access,
         "Ada package exception and constant declarations are extracted");
      Register_Routine
        (T, Test_Ada_Object_Scanner_Ignores_Local_And_Non_Object_Lines'Access,
         "Ada object scanner ignores local and non-object lines");
      Register_Routine
        (T, Test_Ada_Representation_Clauses_Are_Detail_Metadata'Access,
         "Ada representation clauses are outline detail metadata");
      Register_Routine
        (T, Test_Ada_Generic_Formals_Are_Extracted'Access,
         "Ada generic formals are extracted");
      Register_Routine
        (T, Test_Ada_Generic_Formal_Continuations_Are_Not_Duplicated'Access,
         "Ada generic formal continuations are not duplicated");
      Register_Routine
        (T, Test_Ada_Outline_Extracts_Subunits_Abstract_Null_And_Operators'Access,
         "Ada outline extracts subunits abstract null and operators");
      Register_Routine
        (T, Test_Ada_Outline_Extracts_Entries_Instantiations_And_Child_Packages'Access,
         "Ada outline extracts entries instantiations and child packages");
      Register_Routine
        (T, Test_Ada_Outline_Precision_For_Expanded_Constructs'Access,
         "pass 707 Ada outline precision for expanded constructs");
      Register_Routine
        (T, Test_Ada_Outline_Type_Family_Label_Precision'Access,
         "pass 721 Ada outline type family label precision");
   end Register_Tests;

end Editor.Outline.Ada_Extraction_Tests;
