with Editor.Test_Temp;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Buffers;
with Editor.External_Producers;
with Editor.Feature_Diagnostics;
with Editor.Feature_Messages;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Audit;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Search_Results;
with Editor.Outline;
with Editor.State;

use type Ada.Containers.Count_Type;
use type Editor.External_Producers.External_Producer_Kind;
use type Editor.External_Producers.Compiler_Diagnostic_Severity;
use type Editor.External_Producers.Diagnostic_Line_Parse_Status;
use type Editor.External_Producers.Diagnostic_Line_Parse_Reason;
use type Editor.External_Producers.Diagnostic_Line_Command_Outcome;
use type Editor.External_Producers.Build_Run_Status;
use type Editor.External_Producers.Process_Run_Status;
use type Editor.External_Producers.Process_Execution_Mode;
use type Editor.External_Producers.Process_Output_Capture_Mode;
use type Editor.External_Producers.Process_Diagnostic_Stream_Preference;
use type Editor.External_Producers.Process_Output_Stream;
use type Editor.External_Producers.Process_Fixture_Kind;
use type Editor.External_Producers.Process_Fixture_Validation_Status;
use type Editor.External_Producers.Real_Build_Tool_Fixture_Validation_Status;
use type Editor.External_Producers.Real_Build_Tool_Fixture_Kind;
use type Editor.External_Producers.Build_Request_Validation_Status;
use type Editor.External_Producers.Process_Request_Validation_Status;
use type Editor.External_Producers.User_Opt_In_Build_Command_Context_Status;
use type Editor.External_Producers.Build_Tool_Kind;
use type Editor.Feature_Diagnostics.Diagnostic_Source_Kind;
use type Editor.Feature_Diagnostics.Diagnostic_Severity;
use type Editor.Feature_Panel.Feature_Id;
use type Editor.Feature_Panel.Feature_Panel_Fingerprint;

package body Editor.External_Producers.Tests is

   overriding function Name
     (T : External_Producers_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.External_Producers");
   end Name;

   procedure Prepare_State
     (S : out Editor.State.State_Type)
   is
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF & "gamma");
   end Prepare_State;

   function Rec
     (Message : String;
      Severity : Editor.Feature_Diagnostics.Diagnostic_Severity :=
        Editor.Feature_Diagnostics.Diagnostic_Error;
      Source : String := "gnat";
      Has_Target : Boolean := False;
      Buffer : Natural := 0;
      Line : Natural := 0;
      Column : Natural := 0;
      Has_Edit : Boolean := False;
      Edit_Start_Line : Natural := 0;
      Edit_Start_Column : Natural := 0;
      Edit_End_Line : Natural := 0;
      Edit_End_Column : Natural := 0;
      Replacement_Text : String := "";
      Quick_Fix_Label : String := "";
      Quick_Fix_Detail : String := "")
      return Editor.External_Producers.External_Diagnostic_Record
   is
   begin
      return
        (Severity      => Severity,
         Message       => To_Unbounded_String (Message),
         Source_Label  => To_Unbounded_String (Source),
         Has_Target    => Has_Target,
         Target_Buffer => Buffer,
         Target_Line   => Line,
         Target_Column => Column,
         Has_Edit          => Has_Edit,
         Edit_Start_Line   => Edit_Start_Line,
         Edit_Start_Column => Edit_Start_Column,
         Edit_End_Line     => Edit_End_Line,
         Edit_End_Column   => Edit_End_Column,
         Replacement_Text  => To_Unbounded_String (Replacement_Text),
         Quick_Fix_Label   => To_Unbounded_String (Quick_Fix_Label),
         Quick_Fix_Detail  => To_Unbounded_String (Quick_Fix_Detail));
   end Rec;

   function CRec
     (Message : String;
      Severity : Editor.External_Producers.Compiler_Diagnostic_Severity :=
        Editor.External_Producers.Compiler_Error;
      File_Label : String := "main.adb";
      Has_Location : Boolean := False;
      Line : Natural := 0;
      Column : Natural := 0;
      Tool_Name : String := "gnat")
      return Editor.External_Producers.Compiler_Diagnostic_Record
   is
   begin
      return
        (Severity     => Severity,
         Message      => To_Unbounded_String (Message),
         File_Label   => To_Unbounded_String (File_Label),
         Has_Location => Has_Location,
         Line         => Line,
         Column       => Column,
         Tool_Name    => To_Unbounded_String (Tool_Name));
   end CRec;

   procedure Name_Current_Buffer
     (S            : in out Editor.State.State_Type;
      Path         : String := Editor.Test_Temp.Base & "/main.adb";
      Display_Name : String := "main.adb")
   is
      File : Editor.State.File_State := S.File_Info;
   begin
      File.Has_Path := True;
      File.Path := To_Unbounded_String (Path);
      File.Display_Name := To_Unbounded_String (Display_Name);
      Editor.State.Set_Current_File (S, File);
   end Name_Current_Buffer;

   function Compiler_Source return Editor.External_Producers.External_Producer_Source is
   begin
      return Editor.External_Producers.Build_Compiler_Diagnostics_Producer_Source;
   end Compiler_Source;

   function Build_Source return Editor.External_Producers.External_Producer_Source is
   begin
      return Editor.External_Producers.Build_External_Producer_Source
        (Editor.External_Producers.Build_Diagnostics_Producer);
   end Build_Source;

   procedure Test_External_Producer_Identity_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Build : constant Editor.External_Producers.External_Producer_Source :=
        Build_Source;
      Compiler : constant Editor.External_Producers.External_Producer_Source :=
        Editor.External_Producers.Build_External_Producer_Source
          (Editor.External_Producers.Compiler_Diagnostics_Producer);
      None : constant Editor.External_Producers.External_Producer_Source :=
        Editor.External_Producers.Build_External_Producer_Source
          (Editor.External_Producers.No_External_Producer);
   begin
      Assert (Editor.External_Producers.Producer_Source_Is_Valid (Build),
              "build diagnostics producer metadata is valid");
      Assert (Editor.External_Producers.Producer_Source_Is_Valid (Compiler),
              "compiler diagnostics producer metadata is valid");
      Assert (not Editor.External_Producers.Producer_Source_Is_Valid (None),
              "no external producer is rejected safely");
      Assert (To_String (Build.Stable_Name) /= To_String (Compiler.Stable_Name),
              "external producer stable names are distinct");
      Assert (Editor.External_Producers.Map_External_Producer_To_Diagnostic_Source
                (Build) = Editor.Feature_Diagnostics.External_Diagnostic_Source,
              "build producer maps explicitly to external diagnostic source");
   end Test_External_Producer_Identity_Is_Deterministic;

   procedure Test_External_Producer_Ingests_Diagnostics_Through_Diagnostics_API
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Items : Editor.External_Producers.External_Diagnostic_Record_Array;
      Result : Editor.External_Producers.Producer_Batch_Result;
   begin
      Prepare_State (S);
      Items.Append (Rec ("build failed", Source => "gprbuild", Has_Target => True,
                         Buffer => S.Registry_Token, Line => 2, Column => 1));
      Result := Editor.External_Producers.Ingest_Diagnostic_Batch
        (S, Build_Source, Items);
      Assert (Result.Accepted_Count = 1, "one external diagnostic is accepted");
      Assert (Result.Rejected_Count = 0, "valid external diagnostic is not rejected");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "Diagnostics owns the stored external row");
      Assert (Editor.Feature_Diagnostics.Item_Source_Kind (S.Feature_Diagnostics, 1) =
                Editor.Feature_Diagnostics.External_Diagnostic_Source,
              "external producer uses explicit external source kind");
      Assert (Editor.Feature_Diagnostics.Item_Has_Target (S.Feature_Diagnostics, 1),
              "valid external target is stored through Diagnostics target metadata");
   end Test_External_Producer_Ingests_Diagnostics_Through_Diagnostics_API;

   procedure Test_External_Producer_Ingests_Diagnostic_Edit_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Items : Editor.External_Producers.External_Diagnostic_Record_Array;
      Result : Editor.External_Producers.Producer_Batch_Result;
   begin
      Prepare_State (S);
      Items.Append
        (Rec
           ("missing semicolon",
            Source => "gnat",
            Has_Target => True,
            Buffer => S.Registry_Token,
            Line => 1,
            Column => 6,
            Has_Edit => True,
            Edit_Start_Line => 1,
            Edit_Start_Column => 6,
            Edit_End_Line => 1,
            Edit_End_Column => 6,
            Replacement_Text => " ; ",
            Quick_Fix_Label => "Insert semicolon",
            Quick_Fix_Detail => "Append a statement delimiter"));
      Items.Append
        (Rec
           ("bad target edit",
            Has_Target => True,
            Buffer => S.Registry_Token + 99,
            Line => 1,
            Column => 1,
            Has_Edit => True,
            Edit_Start_Line => 1,
            Edit_Start_Column => 1,
            Edit_End_Line => 1,
            Edit_End_Column => 1,
            Replacement_Text => "ignored"));
      Items.Append
        (Rec
           ("multi-line edit",
            Source => "gnat",
            Has_Target => True,
            Buffer => S.Registry_Token,
            Line => 2,
            Column => 1,
            Has_Edit => True,
            Edit_Start_Line => 2,
            Edit_Start_Column => 1,
            Edit_End_Line => 3,
            Edit_End_Column => 4,
            Replacement_Text => "begin" & ASCII.LF & "   null;"));

      Result := Editor.External_Producers.Ingest_Diagnostic_Batch
        (S, Compiler_Source, Items);

      Assert (Result.Accepted_Count = 3,
              "external edit diagnostics are accepted for review");
      Assert (Editor.Feature_Diagnostics.Item_Has_Edit (S.Feature_Diagnostics, 1),
              "valid external edit metadata is stored through Diagnostics");
      Assert (Editor.Feature_Diagnostics.Item_Edit_Start_Line
                (S.Feature_Diagnostics, 1) = 1,
              "external edit start line is preserved");
      Assert (Editor.Feature_Diagnostics.Item_Edit_Start_Column
                (S.Feature_Diagnostics, 1) = 6,
              "external edit start column is preserved");
      Assert (Editor.Feature_Diagnostics.Item_Edit_End_Column
                (S.Feature_Diagnostics, 1) = 6,
              "external edit end column is preserved");
      Assert (Editor.Feature_Diagnostics.Item_Replacement_Text
                (S.Feature_Diagnostics, 1) = " ; ",
              "external edit replacement text preserves significant whitespace");
      Assert (Editor.Feature_Diagnostics.Item_Quick_Fix_Label
                (S.Feature_Diagnostics, 1) = "Insert semicolon",
              "external edit quick-fix label is stored through Diagnostics");
      Assert (Editor.Feature_Diagnostics.Item_Quick_Fix_Detail
                (S.Feature_Diagnostics, 1) = "Append a statement delimiter",
              "external edit quick-fix detail is stored through Diagnostics");
      Assert (not Editor.Feature_Diagnostics.Item_Has_Edit
                (S.Feature_Diagnostics, 2),
              "external edit metadata is dropped for stale buffer targets");
      Assert (Editor.Feature_Diagnostics.Item_Has_Edit
                (S.Feature_Diagnostics, 3),
              "external multi-line edit metadata is stored through Diagnostics");
      Assert (Editor.Feature_Diagnostics.Item_Edit_End_Line
                (S.Feature_Diagnostics, 3) = 3,
              "external multi-line edit end line is preserved");
      Assert (Editor.Feature_Diagnostics.Item_Replacement_Text
                (S.Feature_Diagnostics, 3) =
              "begin" & ASCII.LF & "   null;",
              "external multi-line edit replacement text is preserved");
   end Test_External_Producer_Ingests_Diagnostic_Edit_Metadata;

   procedure Test_External_Producer_Batch_Preserves_Input_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Items : Editor.External_Producers.External_Diagnostic_Record_Array;
      Result : Editor.External_Producers.Producer_Batch_Result;
   begin
      Prepare_State (S);
      Items.Append (Rec ("first"));
      Items.Append (Rec ("second", Severity => Editor.Feature_Diagnostics.Diagnostic_Warning));
      Items.Append (Rec ("third", Severity => Editor.Feature_Diagnostics.Diagnostic_Info));
      Result := Editor.External_Producers.Ingest_Diagnostic_Batch (S, Build_Source, Items);
      Assert (Result.Accepted_Count = 3, "all ordered records are accepted");
      Assert (Editor.Feature_Diagnostics.Item_Message (S.Feature_Diagnostics, 1) = "first",
              "first record remains first");
      Assert (Editor.Feature_Diagnostics.Item_Message (S.Feature_Diagnostics, 2) = "second",
              "second record remains second");
      Assert (Editor.Feature_Diagnostics.Item_Message (S.Feature_Diagnostics, 3) = "third",
              "third record remains third");
   end Test_External_Producer_Batch_Preserves_Input_Order;

   procedure Test_External_Producer_Invalid_Target_Becomes_Untargeted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Items : Editor.External_Producers.External_Diagnostic_Record_Array;
      Result : Editor.External_Producers.Producer_Batch_Result;
   begin
      Prepare_State (S);
      Items.Append (Rec ("bad target", Has_Target => True,
                         Buffer => S.Registry_Token + 99, Line => 1, Column => 1));
      Result := Editor.External_Producers.Ingest_Diagnostic_Batch (S, Build_Source, Items);
      Assert (Result.Accepted_Count = 1, "invalid-target record is still accepted");
      Assert (Result.Accepted_Untargeted = 1,
              "invalid-target record is counted as untargeted");
      Assert (not Editor.Feature_Diagnostics.Item_Has_Target (S.Feature_Diagnostics, 1),
              "invalid target is not stored as activatable metadata");
   end Test_External_Producer_Invalid_Target_Becomes_Untargeted;

   procedure Test_External_Producer_Preserves_Diagnostics_Filter_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Items : Editor.External_Producers.External_Diagnostic_Record_Array;
      Result : Editor.External_Producers.Producer_Batch_Result;
   begin
      Prepare_State (S);
      Editor.Feature_Diagnostics.Toggle_Errors_Visible (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "warning");
      Items.Append (Rec ("hidden error", Severity => Editor.Feature_Diagnostics.Diagnostic_Error));
      Items.Append (Rec ("shown warning", Severity => Editor.Feature_Diagnostics.Diagnostic_Warning));
      Result := Editor.External_Producers.Ingest_Diagnostic_Batch (S, Build_Source, Items);
      Assert (Result.Accepted_Count = 2, "filter state does not block storage");
      Assert (Editor.Feature_Diagnostics.Filter_Text (S.Feature_Diagnostics) = "warning",
              "external ingestion preserves diagnostic text filter");
      Assert (not Editor.Feature_Diagnostics.Severity_Is_Visible
                (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Error),
              "external ingestion preserves severity visibility");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (S.Feature_Diagnostics) = 1,
              "existing filters compose with external row changes");
   end Test_External_Producer_Preserves_Diagnostics_Filter_State;

   procedure Test_External_Producer_Applies_Diagnostics_Retention
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Items : Editor.External_Producers.External_Diagnostic_Record_Array;
      Result : Editor.External_Producers.Producer_Batch_Result;
   begin
      Prepare_State (S);
      for I in 1 .. Editor.Feature_Diagnostics.Max_Diagnostics + 5 loop
         Items.Append (Rec ("diagnostic" & Natural'Image (I)));
      end loop;
      Result := Editor.External_Producers.Ingest_Diagnostic_Batch (S, Build_Source, Items);
      Assert (Result.Accepted_Count = Editor.Feature_Diagnostics.Max_Diagnostics + 5,
              "all oversized batch records are accepted before deterministic retention");
      Assert (Result.Evicted_Count = 5, "retention eviction count is deterministic");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) =
                Editor.Feature_Diagnostics.Max_Diagnostics,
              "Diagnostics retention cap is applied");
      Assert (Editor.Feature_Diagnostics.Item_Message (S.Feature_Diagnostics, 1) =
                "diagnostic 6",
              "oldest diagnostics are evicted first");
   end Test_External_Producer_Applies_Diagnostics_Retention;

   procedure Test_External_Producer_Does_Not_Switch_Active_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Items : Editor.External_Producers.External_Diagnostic_Record_Array;
      Result : Editor.External_Producers.Producer_Batch_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Outline_Feature),
              "test can activate Outline");
      Items.Append (Rec ("external diagnostic"));
      Result := Editor.External_Producers.Ingest_Diagnostic_Batch (S, Build_Source, Items);
      Assert (Result.Accepted_Count = 1, "external diagnostic accepted while Outline active");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Outline_Feature,
              "external producer must not switch active feature");
      Assert (not Result.Projection_Changed,
              "non-Diagnostics active feature projection is not reconciled");
   end Test_External_Producer_Does_Not_Switch_Active_Feature;

   procedure Test_External_Producer_Does_Not_Mutate_Unrelated_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Items : Editor.External_Producers.External_Diagnostic_Record_Array;
      Outline_Before : Natural;
      Messages_Before : Natural;
      Search_Before : Natural;
   begin
      Prepare_State (S);
      Outline_Before := Editor.Outline.Item_Count (S.Outline);
      Messages_Before := Editor.Feature_Messages.Row_Count (S.Feature_Messages);
      Search_Before := Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results);
      Items.Append (Rec ("external diagnostic"));
      declare
         Result : constant Editor.External_Producers.Producer_Batch_Result :=
           Editor.External_Producers.Ingest_Diagnostic_Batch (S, Build_Source, Items);
      begin
         Assert (Result.Accepted_Count = 1, "external diagnostic accepted");
      end;
      Assert (Editor.Outline.Item_Count (S.Outline) = Outline_Before,
              "external producer does not mutate Outline");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = Messages_Before,
              "external producer does not mutate Messages");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = Search_Before,
              "external producer does not mutate Search Results");
   end Test_External_Producer_Does_Not_Mutate_Unrelated_Features;

   procedure Test_External_Producer_Does_Not_Revive_Stale_Projection_Token
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Token : Editor.Feature_Panel.Feature_Projection_Token;
      Items : Editor.External_Producers.External_Diagnostic_Record_Array;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Messages_Feature),
              "test can activate Messages");
      Token := Editor.Feature_Panel.Build_Feature_Projection_Token (S.Feature_Panel);
      Editor.Feature_Panel.Clear_Rows (S.Feature_Panel);
      Assert (not Editor.Feature_Panel.Validate_Feature_Projection_Token
                (S.Feature_Panel, Token),
              "clearing rows makes token stale");
      Items.Append (Rec ("external diagnostic"));
      declare
         Result : constant Editor.External_Producers.Producer_Batch_Result :=
           Editor.External_Producers.Ingest_Diagnostic_Batch (S, Build_Source, Items);
      begin
         Assert (Result.Accepted_Count = 1, "external diagnostic accepted");
      end;
      Assert (not Editor.Feature_Panel.Validate_Feature_Projection_Token
                (S.Feature_Panel, Token),
              "external producer cannot revive stale projection token");
   end Test_External_Producer_Does_Not_Revive_Stale_Projection_Token;

   procedure Test_External_Producer_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Result : Editor.Feature_Panel_Audit.Feature_Panel_Audit_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Diagnostics_Feature),
              "test can activate Diagnostics");
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Result := Editor.Feature_Panel_Audit.Run_Feature_Panel_Audit;
      Assert (Result.Passed, Editor.Feature_Panel_Audit.Summary (Result));
      Assert (Editor.External_Producers.External_Producer_Audit_Passes,
              "external producer audit passes");
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Before = After,
              "external producer audit must not mutate feature-panel state");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "external producer audit must not ingest diagnostics");
   end Test_External_Producer_Audit_Is_Side_Effect_Free;

   procedure Test_External_Producer_Rejects_Invalid_Metadata_Without_Mutation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Items : Editor.External_Producers.External_Diagnostic_Record_Array;
      Bad : Editor.External_Producers.External_Producer_Source := Build_Source;
      Result : Editor.External_Producers.Producer_Batch_Result;
   begin
      Prepare_State (S);
      Bad.Stable_Name := To_Unbounded_String ("tampered");
      Items.Append (Rec ("should not store"));
      Result := Editor.External_Producers.Ingest_Diagnostic_Batch (S, Bad, Items);
      Assert (Result.Accepted_Count = 0, "tampered producer accepts no rows");
      Assert (Result.Rejected_Count = 1, "tampered producer rejects the input row");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "invalid producer metadata does not mutate Diagnostics");
   end Test_External_Producer_Rejects_Invalid_Metadata_Without_Mutation;

   procedure Test_Compiler_Diagnostic_Normalizes_Severity_Mapping
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.External_Producers.Map_Compiler_Severity_To_Diagnostic_Severity
                (Editor.External_Producers.Compiler_Info) =
              Editor.Feature_Diagnostics.Diagnostic_Info,
              "compiler info maps to diagnostic info");
      Assert (Editor.External_Producers.Map_Compiler_Severity_To_Diagnostic_Severity
                (Editor.External_Producers.Compiler_Warning) =
              Editor.Feature_Diagnostics.Diagnostic_Warning,
              "compiler warning maps to diagnostic warning");
      Assert (Editor.External_Producers.Map_Compiler_Severity_To_Diagnostic_Severity
                (Editor.External_Producers.Compiler_Error) =
              Editor.Feature_Diagnostics.Diagnostic_Error,
              "compiler error maps to diagnostic error");
      Assert (Editor.External_Producers.Map_Compiler_Severity_To_Diagnostic_Severity
                (Editor.External_Producers.Compiler_Fatal) =
              Editor.Feature_Diagnostics.Diagnostic_Error,
              "compiler fatal maps to diagnostic error");
      Assert (Editor.External_Producers.Map_Compiler_Severity_To_Diagnostic_Severity
                (Editor.External_Producers.Compiler_Note) =
              Editor.Feature_Diagnostics.Diagnostic_Note,
              "compiler note maps to first-class diagnostic note");
      Assert (Editor.External_Producers.Map_Compiler_Severity_To_Diagnostic_Severity
                (Editor.External_Producers.Compiler_Unknown) =
              Editor.Feature_Diagnostics.Diagnostic_Unknown,
              "unknown compiler severity maps to first-class unknown diagnostic severity");
   end Test_Compiler_Diagnostic_Normalizes_Severity_Mapping;

   procedure Test_Compiler_Diagnostic_Resolves_Live_Buffer_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.External_Diagnostic_Record;
   begin
      Prepare_State (S);
      Name_Current_Buffer (S);
      R := Editor.External_Producers.Normalize_Compiler_Diagnostic
        (S, Compiler_Source,
         CRec ("missing semicolon", File_Label => "main.adb",
               Has_Location => True, Line => 2, Column => 1));
      Assert (R.Has_Target, "live buffer display label resolves to target metadata");
      Assert (R.Target_Buffer = S.Registry_Token,
              "resolved compiler diagnostic target uses active buffer token");
      Assert (R.Target_Line = 2 and then R.Target_Column = 1,
              "resolved compiler diagnostic keeps validated location");
      Assert (To_String (R.Source_Label) = "gnat: main.adb",
              "compiler source label combines tool and file label deterministically");
   end Test_Compiler_Diagnostic_Resolves_Live_Buffer_Target;

   procedure Test_Compiler_Diagnostic_Unresolved_File_Becomes_Untargeted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.External_Diagnostic_Record;
   begin
      Prepare_State (S);
      Name_Current_Buffer (S, Path => Editor.Test_Temp.Base & "/main.adb", Display_Name => "main.adb");
      R := Editor.External_Producers.Normalize_Compiler_Diagnostic
        (S, Compiler_Source,
         CRec ("other file", File_Label => "other.adb",
               Has_Location => True, Line => 1, Column => 1));
      Assert (not R.Has_Target, "unresolved compiler file label is accepted as untargeted");
      Assert (R.Target_Buffer = Editor.Feature_Diagnostics.No_Buffer,
              "unresolved compiler diagnostic does not invent a target buffer");
   end Test_Compiler_Diagnostic_Unresolved_File_Becomes_Untargeted;

   procedure Test_Compiler_Diagnostic_Ambiguous_File_Becomes_Untargeted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      B1, B2 : Editor.Buffers.Buffer_Id;
      Resolution : Editor.External_Producers.Buffer_Target_Resolution;
   begin
      Prepare_State (S);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Buffers.Global_Add_File_Buffer ("/a/dup.adb", "dup.adb", "a", B1);
      Editor.Buffers.Global_Add_File_Buffer ("/b/dup.adb", "dup.adb", "b", B2);
      Resolution := Editor.External_Producers.Resolve_Diagnostic_File_Target
        (S, "dup.adb");
      Assert (not Resolution.Found,
              "ambiguous live buffer display label is treated as untargeted");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Compiler_Diagnostic_Ambiguous_File_Becomes_Untargeted;

   procedure Test_Compiler_Diagnostic_Invalid_Location_Becomes_Untargeted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Batch : Editor.External_Producers.Normalized_Diagnostic_Batch;
      Inputs : Editor.External_Producers.Compiler_Diagnostic_Record_Array;
   begin
      Prepare_State (S);
      Name_Current_Buffer (S);
      Inputs.Append
        (CRec ("bad line", File_Label => "main.adb",
               Has_Location => True, Line => 99, Column => 1));
      Batch := Editor.External_Producers.Normalize_Compiler_Diagnostic_Batch
        (S, Compiler_Source, Inputs);
      Assert (Batch.Input_Count = 1 and then Batch.Normalized_Count = 1,
              "invalid-location compiler diagnostic is still normalized");
      Assert (Batch.Untargeted_Count = 1,
              "invalid location is counted as untargeted");
      Assert (Batch.Invalid_Location_Count = 1,
              "invalid live-buffer location is counted deterministically");
      Assert (not Batch.Items.Element (Batch.Items.First_Index).Has_Target,
              "invalid location does not store activatable target metadata");
   end Test_Compiler_Diagnostic_Invalid_Location_Becomes_Untargeted;

   procedure Test_Compiler_Diagnostic_Batch_Preserves_Input_Order_And_Counts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Inputs : Editor.External_Producers.Compiler_Diagnostic_Record_Array;
      Batch : Editor.External_Producers.Normalized_Diagnostic_Batch;
   begin
      Prepare_State (S);
      Name_Current_Buffer (S);
      Inputs.Append (CRec ("first", Severity => Editor.External_Producers.Compiler_Info,
                           Has_Location => True, Line => 1, Column => 1));
      Inputs.Append (CRec ("second", Severity => Editor.External_Producers.Compiler_Unknown,
                           File_Label => "missing.adb", Has_Location => True,
                           Line => 1, Column => 1));
      Inputs.Append (CRec ("   ", Severity => Editor.External_Producers.Compiler_Warning,
                           File_Label => "main.adb"));
      Batch := Editor.External_Producers.Normalize_Compiler_Diagnostic_Batch
        (S, Compiler_Source, Inputs);
      Assert (Editor.External_Producers.Assert_Normalized_Batch_Consistent (Batch),
              "normalized compiler batch consistency audit passes");
      Assert (Batch.Input_Count = 3 and then Batch.Normalized_Count = 3,
              "compiler batch records input and normalized counts");
      Assert (To_String (Batch.Items.Element (Batch.Items.First_Index).Message) = "first",
              "compiler batch keeps first input first");
      Assert (To_String (Batch.Items.Element (Batch.Items.First_Index + 1).Message) = "second",
              "compiler batch keeps second input second");
      Assert (Length (Batch.Items.Element (Batch.Items.First_Index + 2).Message) = 0,
              "compiler batch preserves empty-message normalization for ingestion rejection");
      Assert (Batch.Untargeted_Count = 2,
              "compiler batch reports untargeted normalized records");
      Assert (Batch.Empty_Message_Count = 1,
              "compiler batch reports empty-message normalized records");
   end Test_Compiler_Diagnostic_Batch_Preserves_Input_Order_And_Counts;

   procedure Test_Compiler_Diagnostic_Ingestion_Uses_Diagnostics_API
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Inputs : Editor.External_Producers.Compiler_Diagnostic_Record_Array;
      Result : Editor.External_Producers.Producer_Batch_Result;
   begin
      Prepare_State (S);
      Name_Current_Buffer (S);
      Inputs.Append
        (CRec ("build failed", Severity => Editor.External_Producers.Compiler_Fatal,
               File_Label => "main.adb", Has_Location => True,
               Line => 3, Column => 1));
      Result := Editor.External_Producers.Ingest_Compiler_Diagnostic_Batch
        (S, Compiler_Source, Inputs);
      Assert (Result.Accepted_Count = 1 and then Result.Rejected_Count = 0,
              "structured compiler diagnostic is accepted through batch ingestion");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "combined compiler ingestion stores exactly one Diagnostics row");
      Assert (Editor.Feature_Diagnostics.Item_Severity (S.Feature_Diagnostics, 1) =
                Editor.Feature_Diagnostics.Diagnostic_Error,
              "compiler fatal stores as diagnostic error");
      Assert (Editor.Feature_Diagnostics.Item_Source_Kind (S.Feature_Diagnostics, 1) =
                Editor.Feature_Diagnostics.External_Diagnostic_Source,
              "compiler ingestion routes through external Diagnostics source kind");
      Assert (Editor.Feature_Diagnostics.Item_Has_Target (S.Feature_Diagnostics, 1),
              "compiler ingestion keeps validated target metadata");
   end Test_Compiler_Diagnostic_Ingestion_Uses_Diagnostics_API;

   procedure Test_Compiler_Diagnostic_Ingestion_Preserves_Filter_And_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Inputs : Editor.External_Producers.Compiler_Diagnostic_Record_Array;
      Result : Editor.External_Producers.Producer_Batch_Result;
   begin
      Prepare_State (S);
      Name_Current_Buffer (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Outline_Feature),
              "test can activate Outline");
      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "warn");
      Editor.Feature_Diagnostics.Toggle_Errors_Visible (S.Feature_Diagnostics);
      Inputs.Append
        (CRec ("warn from compiler", Severity => Editor.External_Producers.Compiler_Warning,
               File_Label => "main.adb", Has_Location => True,
               Line => 1, Column => 1));
      Result := Editor.External_Producers.Ingest_Compiler_Diagnostic_Batch
        (S, Compiler_Source, Inputs);
      Assert (Result.Accepted_Count = 1, "compiler diagnostic accepted while another feature is active");
      Assert (Editor.Feature_Diagnostics.Filter_Text (S.Feature_Diagnostics) = "warn",
              "compiler ingestion preserves Diagnostics filter text");
      Assert (not Editor.Feature_Diagnostics.Severity_Is_Visible
                (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Error),
              "compiler ingestion preserves Diagnostics severity visibility");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Outline_Feature,
              "compiler ingestion must not switch active feature");
      Assert (not Result.Projection_Changed,
              "compiler ingestion does not reconcile a non-Diagnostics active projection");
   end Test_Compiler_Diagnostic_Ingestion_Preserves_Filter_And_Feature;

   procedure Test_Compiler_Diagnostic_Ingestion_Does_Not_Mutate_Unrelated_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Inputs : Editor.External_Producers.Compiler_Diagnostic_Record_Array;
      Outline_Before : Natural;
      Messages_Before : Natural;
      Search_Before : Natural;
   begin
      Prepare_State (S);
      Name_Current_Buffer (S);
      Outline_Before := Editor.Outline.Item_Count (S.Outline);
      Messages_Before := Editor.Feature_Messages.Row_Count (S.Feature_Messages);
      Search_Before := Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results);
      Inputs.Append (CRec ("external compiler warning",
                           Severity => Editor.External_Producers.Compiler_Warning));
      declare
         Result : constant Editor.External_Producers.Producer_Batch_Result :=
           Editor.External_Producers.Ingest_Compiler_Diagnostic_Batch
             (S, Compiler_Source, Inputs);
      begin
         Assert (Result.Accepted_Count = 1, "compiler diagnostic accepted");
      end;
      Assert (Editor.Outline.Item_Count (S.Outline) = Outline_Before,
              "compiler ingestion does not mutate Outline");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = Messages_Before,
              "compiler ingestion does not mutate Messages");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = Search_Before,
              "compiler ingestion does not mutate Search Results");
   end Test_Compiler_Diagnostic_Ingestion_Does_Not_Mutate_Unrelated_Features;

   procedure Test_Producer_Audit_Covers_Compiler_Diagnostic_Normalization
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Editor.External_Producers.Compiler_Diagnostic_Normalization_Audit_Passes,
              "producer audit covers compiler diagnostic normalization boundary");
      Assert (Editor.External_Producers.Producer_Lifecycle_Audit_Passes,
              "producer lifecycle audit documents synchronous-only lifecycle state");
      Assert (Editor.External_Producers.External_Producer_Audit_Passes,
              "external producer audit includes compiler normalization checks");
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Before = After,
              "compiler producer audit is side-effect-free");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "compiler producer audit must not ingest diagnostic rows");
   end Test_Producer_Audit_Covers_Compiler_Diagnostic_Normalization;



   procedure Test_Diagnostic_Line_Parser_Accepts_Error_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      R : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:42:7: error: missing "";""", "gnat");
   begin
      Assert (R.Status = Editor.External_Producers.Parse_Accepted
              and then R.Reason = Editor.External_Producers.No_Parse_Reason,
              "error diagnostic line is accepted with no parse-failure reason");
      Assert (R.Has_Record, "accepted diagnostic has structured record");
      Assert (To_String (R.Diagnostic_Record.File_Label) = "src/main.adb",
              "file label is preserved exactly after trimming");
      Assert (R.Diagnostic_Record.Line = 42 and then R.Diagnostic_Record.Column = 7,
              "line and column are parsed as positive integers");
      Assert (R.Diagnostic_Record.Severity = Editor.External_Producers.Compiler_Error,
              "error severity token maps to compiler error");
      Assert (To_String (R.Diagnostic_Record.Message) = "missing "";""",
              "diagnostic message is preserved");
   end Test_Diagnostic_Line_Parser_Accepts_Error_Line;

   procedure Test_Diagnostic_Line_Parser_Accepts_Warning_Info_Fatal_And_Unknown
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      W : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/parser.adb:18:3: warning: unused variable ""X""", "gnat");
      I : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/editor.ads:5:1: info: style note", "gnat");
      F : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/build.adb:2:9: fatal: cannot continue", "gnat");
      U : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/other.adb:6:4: strange: explicit unknown token", "gnat");
   begin
      Assert (W.Status = Editor.External_Producers.Parse_Accepted
              and then W.Diagnostic_Record.Severity = Editor.External_Producers.Compiler_Warning,
              "warning diagnostic line is accepted");
      Assert (I.Status = Editor.External_Producers.Parse_Accepted
              and then I.Diagnostic_Record.Severity = Editor.External_Producers.Compiler_Info,
              "info diagnostic line is accepted");
      Assert (F.Status = Editor.External_Producers.Parse_Accepted
              and then F.Diagnostic_Record.Severity = Editor.External_Producers.Compiler_Fatal,
              "fatal diagnostic line is accepted");
      Assert (U.Status = Editor.External_Producers.Parse_Accepted
              and then U.Diagnostic_Record.Severity = Editor.External_Producers.Compiler_Unknown,
              "unknown severity token is accepted as Compiler_Unknown");
   end Test_Diagnostic_Line_Parser_Accepts_Warning_Info_Fatal_And_Unknown;

   procedure Test_Diagnostic_Line_Parser_Accepts_Note_And_GPRbuild_Tool_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Note : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:12:7: note: related declaration", "gnat");
      Tool : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("gprbuild: ""demo.gpr"" processing failed", "gprbuild");
   begin
      Assert (Note.Status = Editor.External_Producers.Parse_Accepted
              and then Note.Diagnostic_Record.Severity = Editor.External_Producers.Compiler_Note,
              "note severity is preserved distinctly before Diagnostics maps it to info");
      Assert (Tool.Status = Editor.External_Producers.Parse_Accepted
              and then Tool.Has_Record,
              "tool-level gprbuild failure is accepted as a source-less row");
      Assert (not Tool.Diagnostic_Record.Has_Location
              and then To_String (Tool.Diagnostic_Record.File_Label) = "",
              "tool-level gprbuild failure does not fabricate a source target");
      Assert (Tool.Diagnostic_Record.Severity = Editor.External_Producers.Compiler_Error,
              "tool-level gprbuild failure is an explicit build error row");
      Assert (To_String (Tool.Diagnostic_Record.Message) = """demo.gpr"" processing failed",
              "tool-level gprbuild message is bounded and preserved");
   end Test_Diagnostic_Line_Parser_Accepts_Note_And_GPRbuild_Tool_Line;

   procedure Test_Diagnostic_Line_Parser_Classifies_GPRbuild_Tool_Severity
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Warning_Line : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("gprbuild: warning: project file will be reparsed", "Build diagnostics");
      Info_Line : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("gprbuild: info: using project demo.gpr", "Build diagnostics");
   begin
      Assert (Warning_Line.Status = Editor.External_Producers.Parse_Accepted
              and then not Warning_Line.Diagnostic_Record.Has_Location
              and then Warning_Line.Diagnostic_Record.Severity =
                Editor.External_Producers.Compiler_Warning,
              "gprbuild warning line remains source-less but keeps warning severity");
      Assert (To_String (Warning_Line.Diagnostic_Record.Message) =
                "project file will be reparsed",
              "gprbuild severity token is not copied into the diagnostic message");
      Assert (To_String (Warning_Line.Diagnostic_Record.Tool_Name) = "gprbuild",
              "gprbuild-prefixed tool line keeps gprbuild as source label");
      Assert (Info_Line.Status = Editor.External_Producers.Parse_Accepted
              and then Info_Line.Diagnostic_Record.Severity =
                Editor.External_Producers.Compiler_Info
              and then To_String (Info_Line.Diagnostic_Record.Message) =
                "using project demo.gpr",
              "gprbuild info line maps deterministically to info severity");
   end Test_Diagnostic_Line_Parser_Classifies_GPRbuild_Tool_Severity;

   procedure Test_Diagnostic_Line_Parser_Ignores_Ordinary_GPRbuild_Tool_Chatter
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Chatter : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("gprbuild: compiling src/main.adb", "Build diagnostics");
      Missing_Message : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("gprbuild: warning:", "Build diagnostics");
   begin
      Assert (Chatter.Status = Editor.External_Producers.Parse_Ignored_Unrecognized
              and then not Chatter.Has_Record,
              "ordinary gprbuild chatter must not become a source-less error row");
      Assert (Missing_Message.Status = Editor.External_Producers.Parse_Rejected_Malformed
              and then Missing_Message.Reason = Editor.External_Producers.Missing_Message,
              "explicit gprbuild severity without message is rejected, not defaulted to error");
   end Test_Diagnostic_Line_Parser_Ignores_Ordinary_GPRbuild_Tool_Chatter;


   procedure Test_Diagnostic_Line_Parser_Is_Case_Insensitive
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.External_Producers.Parse_Compiler_Diagnostic_Severity ("NOTE") =
                Editor.External_Producers.Compiler_Note,
              "note maps case-insensitively to note");
      Assert (Editor.External_Producers.Parse_Compiler_Diagnostic_Severity ("Warn") =
                Editor.External_Producers.Compiler_Warning,
              "warn maps case-insensitively to warning");
      Assert (Editor.External_Producers.Parse_Compiler_Diagnostic_Severity ("ERROR") =
                Editor.External_Producers.Compiler_Error,
              "error maps case-insensitively to error");
   end Test_Diagnostic_Line_Parser_Is_Case_Insensitive;

   procedure Test_Diagnostic_Line_Parser_Preserves_Message_With_Extra_Colon
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      R : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:1:2: warning: value: still: valid", "gnat");
   begin
      Assert (R.Status = Editor.External_Producers.Parse_Accepted,
              "message containing extra colons is accepted");
      Assert (To_String (R.Diagnostic_Record.Message) = "value: still: valid",
              "remaining message text preserves extra colons");
   end Test_Diagnostic_Line_Parser_Preserves_Message_With_Extra_Colon;


   procedure Test_Diagnostic_Line_Parser_Accepts_Line_Only_And_Rejects_Bad_Column
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line_Only : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:12: warning: suspicious construct", "gnat");
      Unknown_Line_Only : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:13: advisory: unusual but accepted", "gnat");
      Bad_Column : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:14:x: error: bad column", "gnat");
   begin
      Assert (Line_Only.Status = Editor.External_Producers.Parse_Accepted
              and then Line_Only.Diagnostic_Record.Line = 12
              and then Line_Only.Diagnostic_Record.Column = 1
              and then Line_Only.Diagnostic_Record.Severity = Editor.External_Producers.Compiler_Warning,
              "line-only warning diagnostic maps to the retained line-start policy");
      Assert (To_String (Line_Only.Diagnostic_Record.Message) = "suspicious construct",
              "line-only diagnostic preserves message text after severity");
      Assert (Unknown_Line_Only.Status = Editor.External_Producers.Parse_Accepted
              and then Unknown_Line_Only.Diagnostic_Record.Severity =
                Editor.External_Producers.Compiler_Unknown
              and then Unknown_Line_Only.Diagnostic_Record.Column = 1,
              "line-only unknown severity remains deterministic and source-positioned");
      Assert (Bad_Column.Status = Editor.External_Producers.Parse_Rejected_Malformed
              and then Bad_Column.Reason = Editor.External_Producers.Nonnumeric_Column,
              "nonnumeric column before a known severity is not misread as line-only severity");
   end Test_Diagnostic_Line_Parser_Accepts_Line_Only_And_Rejects_Bad_Column;

   procedure Test_Diagnostic_Line_Batch_Attaches_Bounded_Continuations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Batch : Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result;
      First_Message : Unbounded_String;
   begin
      Lines.Append (To_Unbounded_String ("src/main.adb:12:7: error: invalid operand types"));
      Lines.Append (To_Unbounded_String ("   left operand has type ""Integer"""));
      Lines.Append (To_Unbounded_String ("   right operand has type ""String"""));
      Lines.Append (To_Unbounded_String ("src/other.adb:4:1: warning: next diagnostic"));
      Lines.Append (To_Unbounded_String ("orphan progress line"));
      Batch := Editor.External_Producers.Parse_Compiler_Diagnostic_Lines (Lines, "gnat");
      First_Message := Batch.Records.Element (Batch.Records.First_Index).Message;

      Assert (Natural (Batch.Records.Length) = 2,
              "continuation lines attach to the prior diagnostic rather than creating fake rows");
      Assert (Batch.Accepted_Count = 4
              and then Batch.Ignored_Unrecognized_Count = 1,
              "batch counts attached continuations and keeps unrelated output ignored");
      Assert (Ada.Strings.Fixed.Index (To_String (First_Message), "left operand") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (First_Message), "right operand") > 0,
              "bounded continuation text is appended to the first diagnostic message");
      Assert (To_String (Batch.Records.Element (Batch.Records.First_Index + 1).Message) =
                "next diagnostic",
              "next recognized diagnostic stops continuation capture");
   end Test_Diagnostic_Line_Batch_Attaches_Bounded_Continuations;

   procedure Test_Diagnostic_Line_Batch_Stops_Continuation_After_Gaps
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Batch : Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result;
      Message : Unbounded_String;
   begin
      Lines.Append (To_Unbounded_String ("src/main.adb:1:1: error: first"));
      Lines.Append (To_Unbounded_String ("ordinary build progress line"));
      Lines.Append (To_Unbounded_String ("   not a continuation after unrelated output"));
      Lines.Append (To_Unbounded_String ("src/next.adb:2:1: warning: second"));
      Lines.Append (To_Unbounded_String (""));
      Lines.Append (To_Unbounded_String ("   not a continuation after blank"));

      Batch := Editor.External_Producers.Parse_Compiler_Diagnostic_Lines (Lines, "gnat");
      Message := Batch.Records.Element (Batch.Records.First_Index).Message;

      Assert (Natural (Batch.Records.Length) = 2,
              "gap-separated indented lines do not create diagnostics");
      Assert (Batch.Accepted_Count = 2
              and then Batch.Ignored_Unrecognized_Count = 3
              and then Batch.Ignored_Blank_Count = 1,
              "gap-separated continuation-like lines are summarized as ignored output");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Message), "not a continuation") = 0,
              "unrelated output closes continuation capture for the prior diagnostic");
      Assert (To_String (Batch.Records.Element (Batch.Records.First_Index + 1).Message) =
                "second",
              "blank output closes continuation capture for the second diagnostic");
   end Test_Diagnostic_Line_Batch_Stops_Continuation_After_Gaps;

   procedure Test_Diagnostic_Line_Parser_Ignores_Blank_And_Unrecognized
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Blank : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line ("   ", "gnat");
      Other : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("this is not a diagnostic", "gnat");
   begin
      Assert (Blank.Status = Editor.External_Producers.Parse_Ignored_Blank
              and then Blank.Reason = Editor.External_Producers.Blank_Line
              and then not Blank.Has_Record,
              "blank line is ignored without a record and carries reason");
      Assert (Other.Status = Editor.External_Producers.Parse_Ignored_Unrecognized
              and then Other.Reason = Editor.External_Producers.Unrecognized_Format
              and then not Other.Has_Record,
              "unrecognized line is ignored without a record and carries reason");
   end Test_Diagnostic_Line_Parser_Ignores_Blank_And_Unrecognized;

   procedure Test_Diagnostic_Line_Parser_Rejects_Malformed_Locations_And_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Bad_Line : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:abc:7: error: bad line", "gnat");
      Bad_Column : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:42:x: error: bad column", "gnat");
      Zero_Line : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:0:7: error: bad line", "gnat");
      Zero_Column : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:42:0: error: bad column", "gnat");
      Missing_Severity : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:42:7: : bad severity", "gnat");
      Empty_Message : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:42:7: error:   ", "gnat");
   begin
      Assert (Bad_Line.Status = Editor.External_Producers.Parse_Rejected_Malformed
              and then Bad_Line.Reason = Editor.External_Producers.Nonnumeric_Line,
              "nonnumeric line is rejected with reason");
      Assert (Bad_Column.Status = Editor.External_Producers.Parse_Rejected_Malformed
              and then Bad_Column.Reason = Editor.External_Producers.Nonnumeric_Column,
              "nonnumeric column is rejected with reason");
      Assert (Zero_Line.Status = Editor.External_Producers.Parse_Rejected_Malformed
              and then Zero_Line.Reason = Editor.External_Producers.Zero_Line,
              "zero line is rejected with reason");
      Assert (Zero_Column.Status = Editor.External_Producers.Parse_Rejected_Malformed
              and then Zero_Column.Reason = Editor.External_Producers.Zero_Column,
              "zero column is rejected with reason");
      Assert (Missing_Severity.Status = Editor.External_Producers.Parse_Rejected_Malformed
              and then Missing_Severity.Reason = Editor.External_Producers.Missing_Severity,
              "missing severity token is rejected with reason");
      Assert (Empty_Message.Status = Editor.External_Producers.Parse_Rejected_Malformed
              and then Empty_Message.Reason = Editor.External_Producers.Missing_Message,
              "empty message is rejected with reason");
   end Test_Diagnostic_Line_Parser_Rejects_Malformed_Locations_And_Message;

   procedure Test_Diagnostic_Line_Parser_Windows_Drive_Label
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      R : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("C:\work\main.adb:10:2: error: windows path", "gnat");
   begin
      Assert (R.Status = Editor.External_Producers.Parse_Accepted,
              "Windows-style drive-letter path is accepted by skipping nonnumeric colon fields");
      Assert (To_String (R.Diagnostic_Record.File_Label) = "C:\work\main.adb",
              "Windows-style file label is preserved");
   end Test_Diagnostic_Line_Parser_Windows_Drive_Label;

   procedure Test_Diagnostic_Line_Batch_Preserves_Order_And_Counts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Batch : Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result;
   begin
      Lines.Append (To_Unbounded_String ("src/a.adb:1:1: error: first"));
      Lines.Append (To_Unbounded_String (""));
      Lines.Append (To_Unbounded_String ("not diagnostic"));
      Lines.Append (To_Unbounded_String ("src/b.adb:2:3: warning: second"));
      Lines.Append (To_Unbounded_String ("src/c.adb:0:3: error: rejected"));
      Batch := Editor.External_Producers.Parse_Compiler_Diagnostic_Lines (Lines, "gnat");
      Assert (Editor.External_Producers.Assert_Diagnostic_Line_Batch_Consistent (Batch),
              "batch parse counts are internally consistent");
      Assert (Batch.Input_Count = 5, "batch records full input count");
      Assert (Batch.Accepted_Count = 2, "batch reports accepted lines");
      Assert (Batch.Ignored_Blank_Count = 1, "batch reports blank lines separately");
      Assert (Batch.Ignored_Unrecognized_Count = 1,
              "batch reports unrecognized lines separately");
      Assert (Batch.Rejected_Malformed_Count = 1, "batch reports rejected malformed lines");
      Assert (To_String (Batch.Records.Element (Batch.Records.First_Index).Message) = "first",
              "first accepted record remains first");
      Assert (To_String (Batch.Records.Element (Batch.Records.First_Index + 1).Message) = "second",
              "second accepted record remains second");
   end Test_Diagnostic_Line_Batch_Preserves_Order_And_Counts;

   procedure Test_Diagnostic_Line_Batch_Empty_Input_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Batch : constant Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Lines (Lines, "gnat");
   begin
      Assert (Editor.External_Producers.Assert_Diagnostic_Line_Batch_Consistent (Batch),
              "empty batch is internally consistent");
      Assert (Batch.Input_Count = 0 and then Batch.Accepted_Count = 0,
              "empty batch has zero input and accepted counts");
      Assert (Batch.Ignored_Blank_Count = 0
              and then Batch.Ignored_Unrecognized_Count = 0
              and then Batch.Rejected_Malformed_Count = 0,
              "empty batch has zero ignored and rejected counts");
      Assert (Natural (Batch.Records.Length) = 0,
              "empty batch has no parsed records");
   end Test_Diagnostic_Line_Batch_Empty_Input_Is_Deterministic;

   procedure Test_Diagnostic_Line_Parser_Tool_Name_Is_Propagated_And_Clean
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      With_Tool : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("main.adb:1:1: warning: message", " gnat ");
      Empty_Tool : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("main.adb:1:1: warning: message", "   ");
      S : Editor.State.State_Type;
      Source : constant Editor.External_Producers.External_Producer_Source :=
        Compiler_Source;
      Normalized_With_Tool : Editor.External_Producers.External_Diagnostic_Record;
      Normalized_Empty_Tool : Editor.External_Producers.External_Diagnostic_Record;
   begin
      Prepare_State (S);
      Assert (To_String (With_Tool.Diagnostic_Record.Tool_Name) = "gnat",
              "parser trims and propagates non-empty tool name");
      Assert (To_String (Empty_Tool.Diagnostic_Record.Tool_Name) = "",
              "parser keeps empty tool name clean");
      Normalized_With_Tool := Editor.External_Producers.Normalize_Parsed_Compiler_Diagnostic
        (S, Source, With_Tool);
      Normalized_Empty_Tool := Editor.External_Producers.Normalize_Parsed_Compiler_Diagnostic
        (S, Source, Empty_Tool);
      Assert (To_String (Normalized_With_Tool.Source_Label) = "gnat: main.adb",
              "normalizer includes non-empty tool name in source label");
      Assert (To_String (Normalized_Empty_Tool.Source_Label) = "main.adb",
              "empty tool name does not create awkward source label punctuation");
   end Test_Diagnostic_Line_Parser_Tool_Name_Is_Propagated_And_Clean;

   procedure Test_Diagnostic_Line_Parser_Handles_Malformed_Edge_Cases
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Only_Colons : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line ("::::", "gnat");
      Missing_Column : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("main.adb:1:: error: message", "gnat");
      No_Message_Separator : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("main.adb:1:1: warning", "gnat");
      Warning_Separator_Only : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("main.adb:1:1: warning:", "gnat");
      Long_Message : constant String := (1 .. 1200 => 'x');
      Long_File_Label : constant String := (1 .. 900 => 'p');
      Many_Colons : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("main.adb:1:1: warning: one:two:three:four", "gnat");
      Long_Result : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("main.adb:1:1: warning: " & Long_Message, "gnat");
      Long_File_Result : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          (Long_File_Label & ":1:1: warning: long file", "gnat");
   begin
      Assert (Only_Colons.Status = Editor.External_Producers.Parse_Rejected_Malformed,
              "only-colons input is rejected without an exception");
      Assert (Missing_Column.Reason = Editor.External_Producers.Missing_Column,
              "missing column reason is deterministic");
      Assert (No_Message_Separator.Reason = Editor.External_Producers.Missing_Message,
              "line without message separator is missing message");
      Assert (Warning_Separator_Only.Reason = Editor.External_Producers.Missing_Message,
              "line with empty message after separator is missing message");
      Assert (Many_Colons.Status = Editor.External_Producers.Parse_Accepted
              and then To_String (Many_Colons.Diagnostic_Record.Message) = "one:two:three:four",
              "message with many colons is accepted and preserved");
      Assert (Long_Result.Status = Editor.External_Producers.Parse_Accepted
              and then Natural (Length (Long_Result.Diagnostic_Record.Message)) <= 512,
              "very long message is accepted and bounded without an exception");
      Assert (Long_File_Result.Status = Editor.External_Producers.Parse_Accepted
              and then Natural (Length (Long_File_Result.Diagnostic_Record.File_Label)) =
                Long_File_Label'Length,
              "very long file label is accepted without an exception");
   end Test_Diagnostic_Line_Parser_Handles_Malformed_Edge_Cases;

   procedure Test_Diagnostic_Line_Parser_Does_Not_Mutate_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Batch : Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Prepare_State (S);
      Lines.Append (To_Unbounded_String ("main.adb:1:1: error: parsed"));
      Lines.Append (To_Unbounded_String ("main.adb:0:1: error: malformed"));
      Lines.Append (To_Unbounded_String ("not a diagnostic"));
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Batch := Editor.External_Producers.Parse_Compiler_Diagnostic_Lines (Lines, "gnat");
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Batch.Accepted_Count = 1,
              "parser-only mixed batch still parses accepted record");
      Assert (Batch.Error_Count = 1
              and then Batch.Warning_Count = 0
              and then Batch.Info_Count = 0
              and then Batch.Note_Count = 0
              and then Batch.Unknown_Count = 0,
              "parser-only batch reports scalar severity counts");
      Assert (Before = After,
              "parser-only batch does not mutate feature panel state");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "parser-only batch does not add Diagnostics rows");
   end Test_Diagnostic_Line_Parser_Does_Not_Mutate_Diagnostics;

   procedure Test_Diagnostic_Line_Ingestion_Uses_Normalization_And_Diagnostics_API
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Result : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
   begin
      Prepare_State (S);
      Name_Current_Buffer (S);
      Lines.Append (To_Unbounded_String ("main.adb:2:1: error: parsed failure"));
      Result := Editor.External_Producers.Ingest_Compiler_Diagnostic_Lines
        (S, Compiler_Source, Lines);
      Assert (Result.Parse_Input_Count = 1 and then Result.Parse_Accepted_Count = 1,
              "line ingestion reports parser counts");
      Assert (Result.Ingestion_Result.Accepted_Count = 1,
              "line ingestion accepts normalized compiler record");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "line ingestion stores exactly one Diagnostics row");
      Assert (Editor.Feature_Diagnostics.Item_Has_Target (S.Feature_Diagnostics, 1),
              "line ingestion uses normalizer to resolve live buffer target");
      Assert (Editor.Feature_Diagnostics.Item_Source_Kind (S.Feature_Diagnostics, 1) =
                Editor.Feature_Diagnostics.External_Diagnostic_Source,
              "line ingestion routes through Diagnostics external source API");
   end Test_Diagnostic_Line_Ingestion_Uses_Normalization_And_Diagnostics_API;

   procedure Test_Diagnostic_Line_Ingestion_Result_Reports_Mixed_Batch_Counts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Result : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
   begin
      Prepare_State (S);
      Lines.Append (To_Unbounded_String (""));
      Lines.Append (To_Unbounded_String ("src/main.adb:42:7: error: missing "";"""));
      Lines.Append (To_Unbounded_String ("not a diagnostic"));
      Lines.Append (To_Unbounded_String ("src/parser.adb:x:3: warning: bad line number"));
      Lines.Append (To_Unbounded_String ("src/editor.ads:5:1: info: style note"));
      Result := Editor.External_Producers.Ingest_Compiler_Diagnostic_Lines
        (S, Compiler_Source, Lines);
      Assert (Result.Parse_Input_Count = 5,
              "mixed ingestion reports full raw input count");
      Assert (Result.Parse_Accepted_Count = 2,
              "mixed ingestion reports accepted raw diagnostic count");
      Assert (Result.Parse_Ignored_Blank_Count = 1,
              "mixed ingestion reports ignored blank count");
      Assert (Result.Parse_Ignored_Unrecognized_Count = 1,
              "mixed ingestion reports ignored unrecognized count");
      Assert (Result.Parse_Rejected_Malformed_Count = 1,
              "mixed ingestion reports rejected malformed count");
      Assert (Result.Normalized_Count = 2,
              "mixed ingestion reports normalized accepted count");
      Assert (Result.Parsed_Error_Count = 1
              and then Result.Parsed_Info_Count = 1
              and then Result.Parsed_Warning_Count = 0
              and then Result.Parsed_Note_Count = 0
              and then Result.Parsed_Unknown_Count = 0,
              "mixed ingestion carries scalar severity counts without owning rows");
      Assert (Result.Ingestion_Result.Accepted_Count = 2,
              "mixed ingestion reports Diagnostics ingestion accepted count");
   end Test_Diagnostic_Line_Ingestion_Result_Reports_Mixed_Batch_Counts;

   procedure Test_Diagnostic_Line_Ingestion_Result_Formatting
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Ingested : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
      Ignored : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
      Malformed : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
      Empty : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
      Is_Limited : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
   begin
      Ingested.Ingestion_Result.Accepted_Count := 3;
      Ignored.Ingestion_Result.Accepted_Count := 3;
      Ignored.Parse_Ignored_Blank_Count := 1;
      Ignored.Parse_Ignored_Unrecognized_Count := 1;
      Malformed.Parse_Input_Count := 2;
      Malformed.Parse_Rejected_Malformed_Count := 2;
      Is_Limited.Ingestion_Result.Accepted_Count := 3;
      Is_Limited.Ingestion_Result.Evicted_Count := 2;
      Assert (Editor.External_Producers.Format_Diagnostic_Line_Ingestion_Result (Ingested) =
                "Diagnostics: ingested 3 diagnostics",
              "format helper reports plain ingested count");
      Assert (Editor.External_Producers.Format_Diagnostic_Line_Ingestion_Result (Ignored) =
                "Diagnostics: ingested 3 diagnostics, ignored 2 lines",
              "format helper reports ingested count with ignored lines");
      Assert (Editor.External_Producers.Format_Diagnostic_Line_Ingestion_Result (Malformed) =
                "Diagnostics: 2 malformed diagnostic lines",
              "format helper reports malformed-only result");
      Assert (Editor.External_Producers.Format_Diagnostic_Line_Ingestion_Result (Is_Limited) =
                "Diagnostics: ingested 3 diagnostics, limit reached, evicted 2 older diagnostics",
              "format helper reports diagnostic retention limit pressure");
      Assert (Editor.External_Producers.Format_Diagnostic_Line_Ingestion_Result (Empty) =
                "Diagnostics: no diagnostic input",
              "format helper reports empty input distinctly");

      declare
         No_Parse : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
      begin
         No_Parse.Parse_Input_Count := 2;
         No_Parse.Parse_Ignored_Blank_Count := 1;
         No_Parse.Parse_Ignored_Unrecognized_Count := 1;
         Assert (Editor.External_Producers.Build_Diagnostic_Line_Command_Feedback (No_Parse) =
                   "Diagnostics: no diagnostics parsed, ignored 2 lines",
                 "command feedback reports ignored count for ignored-only input");
      end;
   end Test_Diagnostic_Line_Ingestion_Result_Formatting;

   procedure Test_Diagnostic_Line_Ingestion_Preserves_Filter_Retention_And_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Result : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Outline_Feature),
              "test can activate Outline");
      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "warning");
      Editor.Feature_Diagnostics.Toggle_Errors_Visible (S.Feature_Diagnostics);
      for I in 1 .. Editor.Feature_Diagnostics.Max_Diagnostics + 3 loop
         Lines.Append (To_Unbounded_String
           ("src/main.adb:1:1: warning: warning" & Natural'Image (I)));
      end loop;
      Result := Editor.External_Producers.Ingest_Compiler_Diagnostic_Lines
        (S, Compiler_Source, Lines);
      Assert (Result.Parse_Accepted_Count = Editor.Feature_Diagnostics.Max_Diagnostics + 3,
              "all raw lines are parsed before retention");
      Assert (Result.Ingestion_Result.Evicted_Count = 3,
              "line ingestion applies Diagnostics retention");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) =
                Editor.Feature_Diagnostics.Max_Diagnostics,
              "Diagnostics retention cap remains effective");
      Assert (Editor.Feature_Diagnostics.Filter_Text (S.Feature_Diagnostics) = "warning",
              "line ingestion preserves diagnostic filter text");
      Assert (not Editor.Feature_Diagnostics.Severity_Is_Visible
                (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Error),
              "line ingestion preserves severity visibility");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Outline_Feature,
              "line ingestion must not switch active feature");
   end Test_Diagnostic_Line_Ingestion_Preserves_Filter_Retention_And_Feature;

   procedure Test_Diagnostic_Line_Ingestion_Does_Not_Mutate_Unrelated_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Outline_Before : Natural;
      Messages_Before : Natural;
      Search_Before : Natural;
      Result : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
   begin
      Prepare_State (S);
      Outline_Before := Editor.Outline.Item_Count (S.Outline);
      Messages_Before := Editor.Feature_Messages.Row_Count (S.Feature_Messages);
      Search_Before := Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results);
      Lines.Append (To_Unbounded_String ("src/main.adb:1:1: warning: parsed warning"));
      Result := Editor.External_Producers.Ingest_Compiler_Diagnostic_Lines
        (S, Compiler_Source, Lines);
      Assert (Result.Ingestion_Result.Accepted_Count = 1,
              "line diagnostic is ingested");
      Assert (Editor.Outline.Item_Count (S.Outline) = Outline_Before,
              "line ingestion does not mutate Outline");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = Messages_Before,
              "line ingestion does not mutate Messages");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = Search_Before,
              "line ingestion does not mutate Search Results");
   end Test_Diagnostic_Line_Ingestion_Does_Not_Mutate_Unrelated_Features;


   procedure Test_Diagnostic_Line_Command_Feedback_Mixed_Rejected_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Mixed : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
   begin
      Mixed.Parse_Input_Count := 5;
      Mixed.Parse_Accepted_Count := 2;
      Mixed.Parse_Ignored_Blank_Count := 1;
      Mixed.Parse_Ignored_Unrecognized_Count := 1;
      Mixed.Parse_Rejected_Malformed_Count := 1;
      Mixed.Ingestion_Result.Accepted_Count := 2;
      Assert (Editor.External_Producers.Classify_Diagnostic_Line_Command_Outcome (Mixed) =
                Editor.External_Producers.Diagnostic_Line_Command_Succeeded,
              "mixed accepted input is a successful command outcome");
      Assert (Editor.External_Producers.Build_Diagnostic_Line_Command_Feedback (Mixed) =
                "Diagnostics: ingested 2 diagnostics, ignored 2 lines, rejected 1 malformed lines",
              "mixed feedback reports ingested count before ignored and rejected counts");
   end Test_Diagnostic_Line_Command_Feedback_Mixed_Rejected_Count;

   procedure Test_Diagnostic_Line_Command_Ingestion_Does_Not_Switch_Active_Feature_By_Default
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Messages_Feature),
              "test can activate Messages");
      Lines.Append (To_Unbounded_String ("main.adb:1:1: warning: from command"));
      Result := Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
        (S, Compiler_Source, Lines);
      Assert (Result.Outcome = Editor.External_Producers.Diagnostic_Line_Command_Succeeded,
              "command-facing ingestion succeeds for accepted line");
      Assert (To_String (Result.Command_Message) =
                "Diagnostics: ingested 1 diagnostics",
              "command-facing ingestion emits one deterministic message");
      Assert (not Result.Should_Show_Diagnostics,
              "state-only command-facing ingestion does not request a feature switch");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Messages_Feature,
              "command-facing ingestion preserves the active feature by default");
   end Test_Diagnostic_Line_Command_Ingestion_Does_Not_Switch_Active_Feature_By_Default;

   procedure Test_Diagnostic_Line_Command_Ingestion_Can_Show_Diagnostics_When_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Search_Results_Feature),
              "test can activate Search Results");
      Lines.Append (To_Unbounded_String ("main.adb:1:1: error: explicit show"));
      Result := Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
        (S, Compiler_Source, Lines, Show_Diagnostics => True);
      Assert (Result.Should_Show_Diagnostics,
              "explicit show command records that Diagnostics was shown");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Diagnostics_Feature,
              "explicit show command switches through normal feature-panel activation");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "explicit show command still ingests through Diagnostics-owned storage");
   end Test_Diagnostic_Line_Command_Ingestion_Can_Show_Diagnostics_When_Explicit;

   procedure Test_Diagnostic_Line_Command_Ingestion_Preserves_Diagnostics_Source_Visibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Editor.Feature_Diagnostics.Toggle_Source_Visible
        (S.Feature_Diagnostics, Editor.Feature_Diagnostics.External_Diagnostic_Source);
      Lines.Append (To_Unbounded_String ("main.adb:1:1: warning: hidden external source"));
      Result := Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
        (S, Compiler_Source, Lines);
      Assert (Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "source visibility does not block command-facing storage");
      Assert (not Editor.Feature_Diagnostics.Source_Is_Visible
                (S.Feature_Diagnostics, Editor.Feature_Diagnostics.External_Diagnostic_Source),
              "command-facing ingestion preserves Diagnostics source visibility filters");
   end Test_Diagnostic_Line_Command_Ingestion_Preserves_Diagnostics_Source_Visibility;

   procedure Test_Diagnostic_Line_Command_Ingestion_Safe_After_Project_And_Workspace_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Project_State : Editor.State.State_Type;
      Workspace_State : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Project_Result : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Workspace_Result : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Lines.Append (To_Unbounded_String ("missing.adb:1:1: warning: untargeted after close"));
      Prepare_State (Project_State);
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Project_Close (Project_State);
      Project_Result := Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
        (Project_State, Compiler_Source, Lines);
      Assert (Project_Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "command-facing ingestion is safe after project close lifecycle cleanup");
      Assert (not Editor.Feature_Diagnostics.Item_Has_Target
                (Project_State.Feature_Diagnostics, 1),
              "closed/unresolved targets remain untargeted after project close");

      Prepare_State (Workspace_State);
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Workspace_Close (Workspace_State);
      Workspace_Result := Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
        (Workspace_State, Compiler_Source, Lines);
      Assert (Workspace_Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "command-facing ingestion is safe after workspace close lifecycle cleanup");
   end Test_Diagnostic_Line_Command_Ingestion_Safe_After_Project_And_Workspace_Close;

   procedure Test_Diagnostic_Line_Ingestion_Result_Consistency_For_Mixed_Batch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Mixed : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
      Bad : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
   begin
      Mixed.Parse_Input_Count := 4;
      Mixed.Parse_Accepted_Count := 2;
      Mixed.Parse_Ignored_Blank_Count := 1;
      Mixed.Parse_Rejected_Malformed_Count := 1;
      Mixed.Normalized_Count := 2;
      Mixed.Parsed_Error_Count := 1;
      Mixed.Parsed_Warning_Count := 1;
      Mixed.Ingestion_Result.Accepted_Count := 2;
      Assert (Editor.External_Producers.Diagnostic_Line_Ingestion_Result_Is_Consistent (Mixed),
              "mixed command ingestion result is internally consistent");
      Editor.External_Producers.Assert_Diagnostic_Line_Ingestion_Result_Consistent (Mixed);

      Bad.Parse_Input_Count := 3;
      Bad.Parse_Accepted_Count := 1;
      Bad.Parse_Ignored_Blank_Count := 1;
      Bad.Normalized_Count := 2;
      Assert (not Editor.External_Producers.Diagnostic_Line_Ingestion_Result_Is_Consistent (Bad),
              "consistency helper rejects count sums and over-normalization");
   end Test_Diagnostic_Line_Ingestion_Result_Consistency_For_Mixed_Batch;

   procedure Test_Diagnostic_Line_Command_Feedback_Is_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      One_Malformed : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
      Mixed : Editor.External_Producers.Diagnostic_Line_Ingestion_Result;
   begin
      One_Malformed.Parse_Input_Count := 1;
      One_Malformed.Parse_Rejected_Malformed_Count := 1;
      Assert (Editor.External_Producers.Build_Diagnostic_Line_Command_Feedback (One_Malformed) =
                "Diagnostics: 1 malformed diagnostic line",
              "single malformed-only feedback uses stable singular command text");

      Mixed.Parse_Input_Count := 4;
      Mixed.Parse_Accepted_Count := 1;
      Mixed.Parse_Ignored_Blank_Count := 1;
      Mixed.Parse_Ignored_Unrecognized_Count := 1;
      Mixed.Parse_Rejected_Malformed_Count := 1;
      Mixed.Normalized_Count := 1;
      Mixed.Parsed_Error_Count := 1;
      Mixed.Ingestion_Result.Accepted_Count := 1;
      Assert (Editor.External_Producers.Format_Diagnostic_Line_Ingestion_Result (Mixed) =
                "Diagnostics: ingested 1 diagnostics, ignored 2 lines, rejected 1 malformed lines",
              "mixed command feedback keeps accepted, ignored, rejected ordering");
   end Test_Diagnostic_Line_Command_Feedback_Is_Stable;

   procedure Test_Diagnostic_Line_Ingestion_Repeated_Mixed_Batches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "warning");
      Lines.Append (To_Unbounded_String ("main.adb:1:1: warning: repeated warning"));
      Lines.Append (To_Unbounded_String (""));
      Lines.Append (To_Unbounded_String ("not a diagnostic"));
      Lines.Append (To_Unbounded_String ("main.adb:x:1: error: malformed"));

      for I in 1 .. 3 loop
         pragma Unreferenced (I);
         Result := Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
           (S, Compiler_Source, Lines);
         Assert (Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
                 "each repeated mixed command batch ingests accepted lines");
         Assert (Result.Ingestion.Parse_Ignored_Blank_Count = 1,
                 "each repeated mixed command batch reports blank line");
         Assert (Result.Ingestion.Parse_Ignored_Unrecognized_Count = 1,
                 "each repeated mixed command batch reports unrecognized line");
         Assert (Result.Ingestion.Parse_Rejected_Malformed_Count = 1,
                 "each repeated mixed command batch reports malformed line");
         Assert (Editor.External_Producers.Diagnostic_Line_Ingestion_Result_Is_Consistent
                   (Result.Ingestion),
                 "each repeated mixed command batch remains count-consistent");
      end loop;

      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 3,
              "repeated mixed command batches append accepted diagnostics only");
      Assert (Editor.Feature_Diagnostics.Filter_Text (S.Feature_Diagnostics) = "warning",
              "repeated mixed command batches preserve Diagnostics filter text");
   end Test_Diagnostic_Line_Ingestion_Repeated_Mixed_Batches;

   procedure Test_Diagnostic_Line_Ingestion_Repeated_Malformed_Only_Batches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Lines.Append (To_Unbounded_String ("main.adb:x:1: error: malformed"));
      Lines.Append (To_Unbounded_String ("main.adb:1:y: warning: malformed"));

      for I in 1 .. 3 loop
         pragma Unreferenced (I);
         Result := Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
           (S, Compiler_Source, Lines);
         Assert (Result.Outcome = Editor.External_Producers.Diagnostic_Line_Command_Malformed_Only,
                 "malformed-only batches keep malformed-only command outcome");
         Assert (Result.Ingestion.Ingestion_Result.Accepted_Count = 0,
                 "malformed-only batches do not add Diagnostics rows");
         Assert (To_String (Result.Command_Message) =
                   "Diagnostics: 2 malformed diagnostic lines",
                 "malformed-only batches use stable feedback");
      end loop;

      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "repeated malformed-only batches never mutate Diagnostics rows");
   end Test_Diagnostic_Line_Ingestion_Repeated_Malformed_Only_Batches;

   procedure Test_Diagnostic_Line_Ingestion_With_Filter_Active_Preserves_Filter
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
   begin
      Prepare_State (S);
      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "needle");
      Lines.Append (To_Unbounded_String ("main.adb:1:1: warning: haystack"));
      Assert (Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
                (S, Compiler_Source, Lines).Ingestion.Ingestion_Result.Accepted_Count = 1,
              "filter-active command ingestion stores accepted diagnostic");
      Assert (Editor.Feature_Diagnostics.Filter_Text (S.Feature_Diagnostics) = "needle",
              "filter-active command ingestion preserves filter");
   end Test_Diagnostic_Line_Ingestion_With_Filter_Active_Preserves_Filter;

   procedure Test_Diagnostic_Line_Ingestion_With_Severity_Hidden_Preserves_Visibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
   begin
      Prepare_State (S);
      Editor.Feature_Diagnostics.Toggle_Errors_Visible (S.Feature_Diagnostics);
      Lines.Append (To_Unbounded_String ("main.adb:1:1: error: hidden severity"));
      Assert (Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
                (S, Compiler_Source, Lines).Ingestion.Ingestion_Result.Accepted_Count = 1,
              "hidden-severity command ingestion stores accepted diagnostic");
      Assert (not Editor.Feature_Diagnostics.Severity_Is_Visible
                (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Error),
              "hidden-severity command ingestion preserves visibility");
   end Test_Diagnostic_Line_Ingestion_With_Severity_Hidden_Preserves_Visibility;

   procedure Test_Diagnostic_Line_Ingestion_After_Feature_Switch_Preserves_Active_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Outline_Feature),
              "test can switch to Outline before command ingestion");
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Messages_Feature),
              "test can switch to Messages before command ingestion");
      Lines.Append (To_Unbounded_String ("main.adb:1:1: warning: preserve feature"));
      Assert (Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
                (S, Compiler_Source, Lines).Ingestion.Ingestion_Result.Accepted_Count = 1,
              "feature-switch command ingestion stores accepted diagnostic");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Messages_Feature,
              "feature-switch command ingestion preserves active feature by default");
   end Test_Diagnostic_Line_Ingestion_After_Feature_Switch_Preserves_Active_Feature;

   procedure Test_Diagnostic_Line_Ingestion_After_Buffer_Close_Is_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Id : Editor.Buffers.Buffer_Id;
      Closed : Boolean := False;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Close_Buffer (Id, Closed);
      if Closed then
         Editor.Feature_Panel_Controller.Reset_All_Features_For_Buffer_Close
           (S, Natural (Id));
      end if;
      Lines.Append (To_Unbounded_String ("main.adb:1:1: warning: after buffer close"));
      Result := Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
        (S, Compiler_Source, Lines);
      Assert (Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "command ingestion after buffer close remains synchronous and safe");
      Assert (not Editor.Feature_Diagnostics.Item_Has_Target
                (S.Feature_Diagnostics, 1),
              "diagnostic after buffer close is stored without stale buffer target");
   end Test_Diagnostic_Line_Ingestion_After_Buffer_Close_Is_Safe;

   procedure Test_Diagnostic_Line_Ingestion_After_Workspace_Close_Is_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Workspace_Close (S);
      Editor.External_Producers.Reset_Diagnostic_Line_Command_State_For_Workspace_Close (S);
      Lines.Append (To_Unbounded_String ("missing.adb:1:1: warning: after workspace close"));
      Result := Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
        (S, Compiler_Source, Lines);
      Assert (Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "command ingestion after workspace close remains safe");
   end Test_Diagnostic_Line_Ingestion_After_Workspace_Close_Is_Safe;

   procedure Test_Producer_Audit_Passes_After_Repeated_Line_Ingestion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
   begin
      Prepare_State (S);
      Lines.Append (To_Unbounded_String ("main.adb:1:1: warning: audit after ingestion"));
      for I in 1 .. 2 loop
         Assert (Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command
                   (S, Compiler_Source, Lines).Ingestion.Ingestion_Result.Accepted_Count = 1,
                 "setup ingestion succeeds before producer audit");
      end loop;
      Assert (Editor.External_Producers.Diagnostic_Line_Layering_Audit_Passes,
              "layering audit passes after repeated line ingestion elsewhere");
      Assert (Editor.External_Producers.External_Producer_Audit_Passes,
              "external producer audit passes after repeated line ingestion");
   end Test_Producer_Audit_Passes_After_Repeated_Line_Ingestion;

   procedure Test_Producer_Audit_Covers_Diagnostic_Line_Command_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Editor.External_Producers.Diagnostic_Line_Command_Surface_Audit_Passes,
              "producer audit covers diagnostic-line command-surface feedback semantics");
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Before = After,
              "diagnostic-line command-surface audit is side-effect-free");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "diagnostic-line command-surface audit must not ingest rows");
   end Test_Producer_Audit_Covers_Diagnostic_Line_Command_Surface;

   procedure Test_Producer_Audit_Covers_Diagnostic_Line_Parser
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Editor.External_Producers.Diagnostic_Line_Parser_Audit_Passes,
              "producer audit covers diagnostic line parser boundary");
      Assert (Editor.External_Producers.External_Producer_Audit_Passes,
              "external producer audit includes line parser checks");
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Before = After,
              "line parser audit is side-effect-free");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "line parser audit must not ingest diagnostic rows");
   end Test_Producer_Audit_Covers_Diagnostic_Line_Parser;

   function Build_Request
     (Tool : Editor.External_Producers.Build_Tool_Kind :=
        Editor.External_Producers.GPRbuild_Tool;
      Command : String := "gprbuild";
      Provenance : Editor.External_Producers.Build_Request_Provenance :=
        Editor.External_Producers.Build_Request_From_Internal_Command)
      return Editor.External_Producers.Build_Run_Request
   is
   begin
      return
        (Tool          => Tool,
        Provenance    => Provenance,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String (Command),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments =>
           Editor.External_Producers.Build_Process_Argument_Vector ("-q"));
   end Build_Request;


   procedure Test_Build_Timeout_Policy_Is_Explicit_And_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Default_Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Real_Execution_Gate
          (Consent => Editor.External_Producers.Build_Consent_User_Confirmed);
      Disabled_Policy : constant Editor.External_Producers.Process_Execution_Policy :=
        (Mode                     => Editor.External_Producers.Process_Execution_Disabled,
         Allow_Real_Execution     => False,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      Unbounded_Policy : constant Editor.External_Producers.Process_Execution_Policy :=
        (Mode                     => Editor.External_Producers.Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 900_000);
   begin
      Assert (Default_Gate.Process_Policy.Timeout_Milliseconds =
                Editor.External_Producers.Build_Default_Timeout_Milliseconds,
              "real public build gate applies the default bounded timeout policy");
      Assert (Editor.External_Producers.Build_Timeout_Policy_Is_Bounded
                (Default_Gate.Process_Policy),
              "default runtime timeout policy is bounded");
      Assert (Editor.External_Producers.Build_Timeout_Policy_Is_Bounded
                (Disabled_Policy),
              "disabled timeout is accepted only on disabled/test policy shape");
      Assert (not Editor.External_Producers.Build_Timeout_Policy_Is_Bounded
                (Unbounded_Policy),
              "unbounded timeout policy is rejected deterministically");
   end Test_Build_Timeout_Policy_Is_Explicit_And_Bounded;

   procedure Test_Build_Timeout_Result_Maps_To_Canonical_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Build_Request,
         Editor.External_Producers.Build_Test_Fixture_Execution_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Timed_Out,
            Stderr_Text => "main.adb:1:1: error: partial before timeout"));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Timed_Out,
              "process timeout maps to canonical build timeout status");
      Assert (To_String (Result.Command_Message) = "Build failed: timed out",
              "timeout produces exactly one canonical primary message");
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "bounded output captured before timeout can be ingested through Diagnostics");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "timeout diagnostics are owned by Diagnostics, not the runner");
   end Test_Build_Timeout_Result_Maps_To_Canonical_Status;

   procedure Test_Build_Cancellation_Result_Maps_To_Canonical_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Cancelled : Editor.External_Producers.Build_Command_Result;
      Unsupported : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Cancelled := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Build_Request,
         Editor.External_Producers.Build_Test_Fixture_Execution_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Cancelled));
      Unsupported := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Build_Request,
         Editor.External_Producers.Build_Test_Fixture_Execution_Gate,
         Editor.External_Producers.Build_Cancellation_Unsupported_Process_Result);
      Assert (Cancelled.Build_Result.Status = Editor.External_Producers.Build_Run_Cancelled,
              "process cancellation maps to canonical build cancelled status");
      Assert (To_String (Cancelled.Command_Message) = "Build cancelled",
              "cancelled build produces one canonical primary message");
      Assert (Unsupported.Build_Result.Status =
                Editor.External_Producers.Build_Run_Cancellation_Unsupported,
              "unsupported cancellation maps to canonical unavailable status");
      Assert (To_String (Unsupported.Command_Message) =
                "Build unavailable: cancellation unsupported",
              "unsupported cancellation message is deterministic");
   end Test_Build_Cancellation_Result_Maps_To_Canonical_Status;

   procedure Test_Build_Request_Rejects_No_Tool
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (not Editor.External_Producers.Validate_Build_Run_Request
                (Build_Request (Tool => Editor.External_Producers.No_Build_Tool)),
              "build request rejects No_Build_Tool deterministically");
   end Test_Build_Request_Rejects_No_Tool;

   procedure Test_Build_Request_Rejects_Empty_Command_Label
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (not Editor.External_Producers.Validate_Build_Run_Request
                (Build_Request (Command => "   ")),
              "build request rejects an empty command label");
   end Test_Build_Request_Rejects_Empty_Command_Label;

   procedure Test_Build_Request_Validation_Status_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.External_Producers.Validate_Build_Run_Request_Status
                (Build_Request) = Editor.External_Producers.Build_Request_Valid,
              "supported build tool with command label validates");
      Assert (Editor.External_Producers.Validate_Build_Run_Request_Status
                (Build_Request (Tool => Editor.External_Producers.No_Build_Tool)) =
              Editor.External_Producers.Build_Request_Rejected_No_Tool,
              "No_Build_Tool has a specific rejection status");
      Assert (Editor.External_Producers.Validate_Build_Run_Request_Status
                (Build_Request (Command => "")) =
              Editor.External_Producers.Build_Request_Rejected_Empty_Command,
              "blank command label has a specific rejection status");
   end Test_Build_Request_Validation_Status_Is_Deterministic;

   procedure Test_Build_Request_Accepts_Supported_Tools
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.External_Producers.Validate_Build_Run_Request
                (Build_Request (Tool => Editor.External_Producers.GPRbuild_Tool)),
              "gprbuild request validates");
      Assert (Editor.External_Producers.Validate_Build_Run_Request
                (Build_Request (Tool => Editor.External_Producers.Alire_Build_Tool)),
              "alire build request validates");
      Assert (not Editor.External_Producers.Validate_Build_Run_Request
                (Build_Request (Tool => Editor.External_Producers.Custom_Build_Tool)),
              "custom build request remains rejected until structured command configuration exists");
   end Test_Build_Request_Accepts_Supported_Tools;

   procedure Test_Process_Request_Preparation_From_GPRbuild_Request
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool          => Editor.External_Producers.GPRbuild_Tool,
        Provenance    => Editor.External_Producers.Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q"),
         Structured_Arguments => Editor.External_Producers.Build_Process_Argument_Vector ("build"));
      Process : constant Editor.External_Producers.Process_Run_Request :=
        Editor.External_Producers.Prepare_Process_Request (Request);
   begin
      Assert (Editor.External_Producers.Validate_Build_Run_Request (Request),
              "gprbuild request validates before process preparation");
      Assert (To_String (Process.Program_Label) = "gprbuild",
              "gprbuild process preparation maps deterministic program metadata");
      Assert (To_String (Process.Working_Label) = "unit-test",
              "gprbuild process preparation preserves working label metadata");
      Assert (To_String (Process.Arguments) = "-q",
              "gprbuild process preparation preserves opaque argument metadata");
   end Test_Process_Request_Preparation_From_GPRbuild_Request;

   procedure Test_Process_Request_Preparation_From_Alire_Request
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool          => Editor.External_Producers.Alire_Build_Tool,
        Provenance    => Editor.External_Producers.Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Build_Process_Argument_Vector ("build"));
      Process : constant Editor.External_Producers.Process_Run_Request :=
        Editor.External_Producers.Prepare_Process_Request (Request);
   begin
      Assert (Editor.External_Producers.Validate_Build_Run_Request (Request),
              "alire request validates before process preparation");
      Assert (To_String (Process.Program_Label) = "alr",
              "alire process preparation maps deterministic program metadata");
      Assert (Length (Process.Arguments) = 0,
              "alire process preparation does not use opaque argument metadata");
      Assert (Process.Structured_Arguments.Length = 1
              and then To_String (Process.Structured_Arguments.First_Element) = "build",
              "alire process preparation preserves caller-supplied structured argv");
   end Test_Process_Request_Preparation_From_Alire_Request;

   procedure Test_Process_Request_Preparation_Rejects_Custom_Without_Config
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.External_Producers.Validate_Build_Run_Request_Status
                (Build_Request (Tool => Editor.External_Producers.Custom_Build_Tool)) =
              Editor.External_Producers.Build_Request_Rejected_Unsupported_Tool,
              "custom build tool is rejected before process preparation without structured configuration");
   end Test_Process_Request_Preparation_Rejects_Custom_Without_Config;

   procedure Test_Default_Process_Runner_Does_Not_Invoke_External_Tool
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Process : constant Editor.External_Producers.Process_Run_Request :=
        Editor.External_Producers.Prepare_Process_Request (Build_Request);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Default (Process);
   begin
      Assert (Result.Status = Editor.External_Producers.Process_Run_Not_Available,
              "default process runner remains non-executing and unavailable");
      Assert (not Result.Has_Exit_Code,
              "default process runner does not synthesize an exit code");
      Assert (To_String (Result.Stdout_Text)'Length = 0
              and then To_String (Result.Stderr_Text)'Length = 0,
              "default process runner does not produce process output");
   end Test_Default_Process_Runner_Does_Not_Invoke_External_Tool;

   procedure Test_Test_Fed_Process_Runner_Returns_Supplied_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Process : constant Editor.External_Producers.Process_Run_Request :=
        Editor.External_Producers.Prepare_Process_Request (Build_Request);
      Supplied : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Failed,
           Exit_Code => 3, Has_Exit_Code => True,
           Stderr_Text => "main.adb:1:1: error: process");
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Test_Fed_Process_Request
          (Process, Supplied);
   begin
      Assert (Result.Status = Editor.External_Producers.Process_Run_Failed,
              "test-fed process runner returns supplied status");
      Assert (Result.Has_Exit_Code and then Result.Exit_Code = 3,
              "test-fed process runner returns supplied exit code");
      Assert (To_String (Result.Stderr_Text) = "main.adb:1:1: error: process",
              "test-fed process runner preserves supplied stderr");
   end Test_Test_Fed_Process_Runner_Returns_Supplied_Result;

   procedure Test_Process_Result_Statuses_Map_To_Build_Statuses
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Request : constant Editor.External_Producers.Build_Run_Request := Build_Request;
   begin
      Assert (Editor.External_Producers.Build_Result_From_Process_Result
                (Request, Editor.External_Producers.Build_Process_Run_Result
                   (Editor.External_Producers.Process_Run_Succeeded)).Status =
              Editor.External_Producers.Build_Run_Succeeded,
              "process success maps to build success");
      Assert (Editor.External_Producers.Build_Result_From_Process_Result
                (Request, Editor.External_Producers.Build_Process_Run_Result
                   (Editor.External_Producers.Process_Run_Failed)).Status =
              Editor.External_Producers.Build_Run_Failed,
              "process failure maps to build failure");
      Assert (Editor.External_Producers.Build_Result_From_Process_Result
                (Request, Editor.External_Producers.Build_Process_Run_Result
                   (Editor.External_Producers.Process_Run_Not_Available)).Status =
              Editor.External_Producers.Build_Run_Not_Available,
              "process not available maps to build not available");
      Assert (Editor.External_Producers.Build_Result_From_Process_Result
                (Request, Editor.External_Producers.Build_Process_Run_Result
                   (Editor.External_Producers.Process_Run_Rejected)).Status =
              Editor.External_Producers.Build_Run_Rejected,
              "process rejected maps to build rejected");
      Assert (Editor.External_Producers.Build_Result_From_Process_Result
                (Request, Editor.External_Producers.Build_Process_Run_Result
                   (Editor.External_Producers.Process_Run_Execution_Error)).Status =
              Editor.External_Producers.Build_Run_Execution_Error,
              "process execution error maps to build execution error");
      Assert (Editor.External_Producers.Build_Result_From_Process_Result
                (Request, Editor.External_Producers.Build_Process_Run_Result
                   (Editor.External_Producers.Process_Run_Timed_Out)).Status =
              Editor.External_Producers.Build_Run_Timed_Out,
              "process timeout maps to build timeout");
      Assert (Editor.External_Producers.Build_Result_From_Process_Result
                (Request, Editor.External_Producers.Build_Process_Run_Result
                   (Editor.External_Producers.Process_Run_Cancelled)).Status =
              Editor.External_Producers.Build_Run_Cancelled,
              "process cancellation maps to build cancelled");
      Assert (Editor.External_Producers.Build_Result_From_Process_Result
                (Request, Editor.External_Producers.Build_Cancellation_Unsupported_Process_Result).Status =
              Editor.External_Producers.Build_Run_Cancellation_Unsupported,
              "unsupported cancellation maps to build cancellation unsupported");

      declare
         Truncated : constant Editor.External_Producers.Build_Run_Result :=
           Editor.External_Producers.Build_Result_From_Process_Result
             (Request,
              Editor.External_Producers.Build_Process_Run_Result
                (Editor.External_Producers.Process_Run_Output_Truncated,
                 Stdout_Text => "bounded",
                 Stdout_Truncated => True));
         Timed_Out : constant Editor.External_Producers.Build_Run_Result :=
           Editor.External_Producers.Build_Result_From_Process_Result
             (Request,
              Editor.External_Producers.Build_Process_Run_Result
                (Editor.External_Producers.Process_Run_Timed_Out,
                 Stdout_Text => "partial"));
      begin
         Assert (Truncated.Stdout_Truncated and then not Truncated.Output_Partial,
                 "process truncation does not imply partial build output");
         Assert (Timed_Out.Output_Partial,
                 "process timeout marks build output as partial");
      end;
   end Test_Process_Result_Statuses_Map_To_Build_Statuses;

   procedure Test_Process_Result_Stderr_Before_Stdout_Line_Extraction
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Process : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Failed,
           Stdout_Text => "main.adb:3:1: warning: stdout",
           Stderr_Text => "main.adb:1:1: error: stderr");
      Build : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Result_From_Process_Result
          (Build_Request, Process);
      Lines : constant Editor.External_Producers.Diagnostic_Text_Line_Array :=
        Editor.External_Producers.Extract_Diagnostic_Lines_From_Build_Result (Build);
   begin
      Assert (Lines.Length = 2,
              "process-originated build result extracts both output streams");
      Assert (To_String (Lines.First_Element) = "main.adb:1:1: error: stderr",
              "process-originated stderr lines are extracted before stdout lines");
      Assert (To_String (Lines.Last_Element) = "main.adb:3:1: warning: stdout",
              "process-originated stdout lines are preserved after stderr lines");
   end Test_Process_Result_Stderr_Before_Stdout_Line_Extraction;

   procedure Test_Build_Output_Stream_Capture_Mode_Is_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Separated : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Failed,
           Stdout_Text => "main.adb:3:1: warning: stdout",
           Stderr_Text => "main.adb:1:1: error: stderr");
      Merged : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Failed,
           Stdout_Text => "main.adb:1:1: error: merged",
           Output_Capture_Mode =>
             Editor.External_Producers.Process_Output_Capture_Merged_Stdout_Stderr);
      Stdout_Only : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Succeeded,
           Stdout_Text => "plain supplied stdout");
      Separated_Build : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Result_From_Process_Result
          (Build_Request, Separated);
      Merged_Build : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Result_From_Process_Result
          (Build_Request, Merged);
      Stdout_Only_Build : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Result_From_Process_Result
          (Build_Request, Stdout_Only);
   begin
      Assert (Editor.External_Producers.Real_Process_Runner_Output_Capture_Mode =
                Editor.External_Producers.Process_Output_Capture_Separated,
              "real process runner advertises separated stdout/stderr capture");
      Assert (Editor.External_Producers.Diagnostic_Stream_Preference (Separated) =
                Editor.External_Producers.Process_Diagnostics_Prefer_Stderr,
              "separated fixture/process results prefer stderr diagnostics");
      Assert (Editor.External_Producers.Diagnostic_Stream_Preference (Merged) =
                Editor.External_Producers.Process_Diagnostics_Merged_Output_Fallback,
              "supplied merged results parse captured stdout fallback");
      Assert (Editor.External_Producers.Build_Run_Diagnostic_Stream_Preference
                (Separated_Build) =
                Editor.External_Producers.Process_Diagnostics_Prefer_Stderr,
              "build result preserves stderr preference when stderr exists");
      Assert (Editor.External_Producers.Build_Run_Diagnostic_Stream_Preference
                (Merged_Build) =
                Editor.External_Producers.Process_Diagnostics_Merged_Output_Fallback,
              "build result exposes merged-output fallback for supplied merged results");
      Assert (Editor.External_Producers.Process_Result_Output_Stream (Merged) =
                Editor.External_Producers.Process_Output_Merged,
              "supplied merged result exposes merged stream provenance");
      Assert (Editor.External_Producers.Process_Result_Output_Stream (Separated) =
                Editor.External_Producers.Process_Output_Stderr,
              "separated supplied result exposes stderr provenance for diagnostics");
      Assert (Editor.External_Producers.Build_Result_Output_Stream (Merged_Build) =
                Editor.External_Producers.Process_Output_Merged,
              "build result carries merged stream provenance when stderr is absent");
      Assert (Editor.External_Producers.Process_Result_Output_Stream (Stdout_Only) =
                Editor.External_Producers.Process_Output_Stdout,
              "supplied stdout-only result remains stdout, not merged fallback");
      Assert (Editor.External_Producers.Build_Result_Output_Stream (Stdout_Only_Build) =
                Editor.External_Producers.Process_Output_Stdout,
              "build result preserves supplied stdout-only stream provenance");
      Assert (Editor.External_Producers.Audit_Build_Runner_Output_Stream_Capture,
              "stream-capture audit covers real separated capture and supplied merged extraction");
   end Test_Build_Output_Stream_Capture_Mode_Is_Explicit;

   function Disabled_Process_Policy return Editor.External_Producers.Process_Execution_Policy
   is
   begin
      return
        (Mode                     => Editor.External_Producers.Process_Execution_Disabled,
         Allow_Real_Execution     => False,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
   end Disabled_Process_Policy;

   function Fixture_Process_Policy
     (Max_Output_Bytes : Natural := 262_144)
      return Editor.External_Producers.Process_Execution_Policy
   is
   begin
      return
        (Mode                     => Editor.External_Producers.Process_Execution_Test_Fixture,
         Allow_Real_Execution     => False,
         Allow_Shell              => False,
         Max_Output_Bytes         => Max_Output_Bytes,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
   end Fixture_Process_Policy;

   function Real_Process_Policy
     (Allow_Shell              : Boolean := False;
      Timeout_Milliseconds     : Natural := 0;
      Require_Absolute_Program : Boolean := False)
      return Editor.External_Producers.Process_Execution_Policy
   is
   begin
      return
        (Mode                     => Editor.External_Producers.Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => Allow_Shell,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => Require_Absolute_Program,
         Timeout_Milliseconds     => Timeout_Milliseconds);
   end Real_Process_Policy;

   function Real_Fixture_Process_Policy
     (Allow_Shell          : Boolean := False;
      Max_Output_Bytes     : Natural := 262_144;
      Timeout_Milliseconds : Natural := 0)
      return Editor.External_Producers.Process_Execution_Policy
   is
   begin
      return
        (Mode                     => Editor.External_Producers.Process_Execution_Real_Fixture_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => Allow_Shell,
         Max_Output_Bytes         => Max_Output_Bytes,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => Timeout_Milliseconds);
   end Real_Fixture_Process_Policy;

   function Fixture_Request
     (Kind  : Editor.External_Producers.Process_Fixture_Kind :=
        Editor.External_Producers.Echo_Diagnostic_Fixture;
      First : String := "stdout";
      Second : String := "main.adb:1:1: error: fixture";
      Third : String := "")
      return Editor.External_Producers.Process_Fixture_Request
   is
   begin
      return Editor.External_Producers.Build_Process_Fixture_Request
        (Kind, First, Second, Third);
   end Fixture_Request;

   function Real_Build_Tool_Fixture_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144)
      return Editor.External_Producers.Build_Execution_Gate
   is
   begin
      return
        (Process_Policy              =>
           (Mode                     => Editor.External_Producers.Process_Execution_Real_Fixture_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => False,
            Max_Output_Bytes         => Max_Output_Bytes,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => 0),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => True,
         Consent                     => Editor.External_Producers.Build_Consent_Test_Only,
         Allow_Diagnostics_Ingestion => Allow_Diagnostics_Ingestion,
         Show_Diagnostics            => Show_Diagnostics);
   end Real_Build_Tool_Fixture_Gate;

   function Real_Build_Tool_Fixture_Request
     (Tool : Editor.External_Producers.Build_Tool_Kind :=
        Editor.External_Producers.GPRbuild_Tool;
      Provenance : Editor.External_Producers.Build_Request_Provenance :=
        Editor.External_Producers.Build_Request_From_User_Opt_In;
      Working_Label : String := "")
      return Editor.External_Producers.Build_Run_Request
   is
   begin
      return
        (Tool          => Tool,
         Provenance    => Provenance,
         Working_Label => To_Unbounded_String (Working_Label),
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
   end Real_Build_Tool_Fixture_Request;

   procedure Test_Real_Build_Tool_Fixture_Default_Gate_Disables_Execution
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Preflight : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_Real_Build_Tool_Fixture
          (Real_Build_Tool_Fixture_Request,
           Editor.External_Producers.GPRbuild_Version_Fixture,
           Editor.External_Producers.Build_Default_Execution_Gate);
   begin
      Assert (Preflight.Process_Request_Status =
                Editor.External_Producers.Process_Request_Rejected_Execution_Disabled,
              "default gate disables real build-tool fixture execution");
      Assert (not Preflight.Has_Process_Request,
              "disabled fixture preflight prepares no process request");
   end Test_Real_Build_Tool_Fixture_Default_Gate_Disables_Execution;

   procedure Test_Real_Build_Tool_Fixture_Requires_Explicit_Gate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.External_Producers.Validate_Real_Build_Tool_Fixture_Gate
                (Real_Build_Tool_Fixture_Gate),
              "explicit real build-tool fixture gate validates");
      Assert (not Editor.External_Producers.Validate_Real_Build_Tool_Fixture_Gate
                (Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed)),
              "general real build gate is not a real build-tool fixture gate");
   end Test_Real_Build_Tool_Fixture_Requires_Explicit_Gate;

   procedure Test_Real_Build_Tool_Fixture_Rejects_Unknown_Fixture
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Preflight : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_Real_Build_Tool_Fixture
          (Real_Build_Tool_Fixture_Request,
           Editor.External_Producers.No_Real_Build_Tool_Fixture,
           Real_Build_Tool_Fixture_Gate);
   begin
      Assert (Preflight.Process_Request_Status =
                Editor.External_Producers.Process_Request_Rejected_Empty_Program,
              "unknown real build-tool fixture kind is rejected deterministically");
      Assert (not Preflight.Has_Process_Request,
              "unknown fixture prepares no process request");
   end Test_Real_Build_Tool_Fixture_Rejects_Unknown_Fixture;

   procedure Test_Real_Build_Tool_Fixture_Rejects_Implicit_Source_Provenance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Preflight : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_Real_Build_Tool_Fixture
          (Real_Build_Tool_Fixture_Request
             (Provenance => Editor.External_Producers.Build_Request_From_Implicit_Source),
           Editor.External_Producers.GPRbuild_Version_Fixture,
           Real_Build_Tool_Fixture_Gate);
   begin
      Assert (Preflight.Build_Request_Status =
                Editor.External_Producers.Build_Request_Rejected_Implicit_Source,
              "implicit build source provenance remains unsupported for real build-tool fixtures");
      Assert (not Preflight.Has_Process_Request,
              "implicit build source rejection prepares no process request");
   end Test_Real_Build_Tool_Fixture_Rejects_Implicit_Source_Provenance;

   procedure Test_Real_Build_Tool_Fixture_Accepts_User_Opt_In_With_Explicit_Gate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Preflight : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_Real_Build_Tool_Fixture
          (Real_Build_Tool_Fixture_Request,
           Editor.External_Producers.GPRbuild_Version_Fixture,
           Real_Build_Tool_Fixture_Gate);
   begin
      Assert (Preflight.Build_Request_Status = Editor.External_Producers.Build_Request_Valid,
              "user opt-in provenance is accepted only with explicit fixture gate");
      Assert (Preflight.Process_Request_Status = Editor.External_Producers.Process_Request_Valid,
              "explicit fixture gate validates the prepared process request");
      Assert (To_String (Preflight.Process_Request.Program_Label) = "gprbuild",
              "gprbuild version fixture maps to explicit program metadata");
      Assert (Preflight.Process_Request.Structured_Arguments.Length = 1
              and then To_String (Preflight.Process_Request.Structured_Arguments.First_Element) = "--version",
              "gprbuild version fixture prepares only --version argv");
   end Test_Real_Build_Tool_Fixture_Accepts_User_Opt_In_With_Explicit_Gate;

   procedure Test_Real_Build_Tool_Fixture_Prepares_Alire_Version_Argv
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Preflight : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_Real_Build_Tool_Fixture
          (Real_Build_Tool_Fixture_Request
             (Tool => Editor.External_Producers.Alire_Build_Tool),
           Editor.External_Producers.Alire_Version_Fixture,
           Real_Build_Tool_Fixture_Gate);
   begin
      Assert (Preflight.Process_Request_Status = Editor.External_Producers.Process_Request_Valid,
              "alire version fixture validates with explicit gate");
      Assert (To_String (Preflight.Process_Request.Program_Label) = "alr",
              "alire version fixture maps to alr program metadata");
      Assert (Preflight.Process_Request.Structured_Arguments.Length = 1
              and then To_String (Preflight.Process_Request.Structured_Arguments.First_Element) = "--version",
              "alire version fixture prepares only --version argv");
   end Test_Real_Build_Tool_Fixture_Prepares_Alire_Version_Argv;

   procedure Test_Real_Build_Tool_Fixture_Rejects_Unsupported_Working_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Preflight : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_Real_Build_Tool_Fixture
          (Real_Build_Tool_Fixture_Request (Working_Label => "project-root"),
           Editor.External_Producers.GPRbuild_Version_Fixture,
           Real_Build_Tool_Fixture_Gate);
   begin
      Assert (Preflight.Process_Request_Status =
                Editor.External_Producers.Process_Request_Rejected_Unsupported_Working_Directory,
              "project-derived working context is rejected for real build-tool fixture preflight");
      Assert (not Preflight.Has_Process_Request,
              "working-context rejection prepares no process request");
   end Test_Real_Build_Tool_Fixture_Rejects_Unsupported_Working_Context;

   procedure Test_Real_Build_Tool_Fixture_Output_Uses_Diagnostic_Line_Pipeline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Real_Build_Tool_Fixture_With_Gate
        (S, Real_Build_Tool_Fixture_Request,
         Editor.External_Producers.Diagnostic_Output_Fixture,
         Real_Build_Tool_Fixture_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Exit_Code => 0, Has_Exit_Code => True,
            Stderr_Text => "main.adb:1:1: error: fixture"));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Succeeded,
              "real build-tool diagnostic fixture can return supplied process success");
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "fixture output routes through existing diagnostic-line ingestion pipeline");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "Diagnostics rows are created only by the established ingestion seam");
   end Test_Real_Build_Tool_Fixture_Output_Uses_Diagnostic_Line_Pipeline;

   procedure Test_Real_Build_Tool_Fixture_Version_Output_No_Diagnostics_Parsed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Real_Build_Tool_Fixture_With_Gate
        (S, Real_Build_Tool_Fixture_Request,
         Editor.External_Producers.GPRbuild_Version_Fixture,
         Real_Build_Tool_Fixture_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Exit_Code => 0, Has_Exit_Code => True,
            Stdout_Text => "GPRBUILD Pro 0.0"));
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Input_Count = 1,
              "version output is still routed as diagnostic-line input");
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Accepted_Count = 0,
              "version output does not parse as compiler diagnostics");
      Assert (To_String (Result.Command_Message) = "Build: succeeded, no diagnostics parsed",
              "feedback reports successful version fixture with no diagnostics parsed");
   end Test_Real_Build_Tool_Fixture_Version_Output_No_Diagnostics_Parsed;

   procedure Test_Real_Build_Tool_Fixture_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Editor.External_Producers.Audit_Real_Build_Tool_Fixture_Gates,
              "real build-tool fixture audit covers explicit gate and preflight checks");
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Before = After,
              "real build-tool fixture audit does not mutate feature-panel state");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "real build-tool fixture audit does not ingest diagnostics");
   end Test_Real_Build_Tool_Fixture_Audit_Is_Side_Effect_Free;


   procedure Test_Real_Build_Tool_Fixture_Validation_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Status : Editor.External_Producers.Real_Build_Tool_Fixture_Validation_Status;
   begin
      Prepare_State (S);
      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "warning");
      Assert (Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Outline_Feature),
        "feature panel show feature succeeds");
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Status := Editor.External_Producers.Validate_Real_Build_Tool_Fixture_Request
        (Real_Build_Tool_Fixture_Request,
         Editor.External_Producers.GPRbuild_Version_Fixture,
         Real_Build_Tool_Fixture_Gate);
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Status = Editor.External_Producers.Real_Build_Fixture_Valid,
              "central real build-tool fixture validation accepts explicit opt-in fixture");
      Assert (Before = After,
              "real build-tool fixture validation does not switch or rebuild features");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "real build-tool fixture validation does not ingest diagnostics");
      Assert (Editor.Feature_Diagnostics.Filter_Text (S.Feature_Diagnostics) = "warning",
              "real build-tool fixture validation preserves diagnostics filter text");
   end Test_Real_Build_Tool_Fixture_Validation_Is_Side_Effect_Free;

   procedure Test_Real_Build_Tool_Fixture_Rejected_Request_Does_Not_Call_Runner
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Real_Build_Tool_Fixture_With_Gate
        (S, Real_Build_Tool_Fixture_Request,
         Editor.External_Producers.No_Real_Build_Tool_Fixture,
         Real_Build_Tool_Fixture_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Exit_Code => 0, Has_Exit_Code => True,
            Stderr_Text => "main.adb:1:1: error: must not run"));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Rejected,
              "unknown fixture request is rejected before runner output can be consumed");
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0,
              "rejected real build-tool fixture does not ingest supplied runner diagnostics");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "rejected real build-tool fixture leaves Diagnostics unchanged");
      Assert (To_String (Result.Command_Message) = "Build: build fixture rejected",
              "rejected fixture feedback is normalized");
   end Test_Real_Build_Tool_Fixture_Rejected_Request_Does_Not_Call_Runner;

   procedure Test_Real_Build_Tool_Fixture_Preflight_Result_Consistency_Valid
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Preflight : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_Real_Build_Tool_Fixture
          (Real_Build_Tool_Fixture_Request,
           Editor.External_Producers.GPRbuild_Version_Fixture,
           Real_Build_Tool_Fixture_Gate);
   begin
      Assert (Editor.External_Producers.Real_Build_Tool_Fixture_Preflight_Is_Consistent
                (Preflight),
              "valid real build-tool fixture preflight has structured argv and process metadata");
   end Test_Real_Build_Tool_Fixture_Preflight_Result_Consistency_Valid;

   procedure Test_Real_Build_Tool_Fixture_Preflight_Result_Consistency_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Preflight : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_Real_Build_Tool_Fixture
          (Real_Build_Tool_Fixture_Request
             (Provenance => Editor.External_Producers.Build_Request_From_Implicit_Source),
           Editor.External_Producers.GPRbuild_Version_Fixture,
           Real_Build_Tool_Fixture_Gate);
   begin
      Assert (Editor.External_Producers.Real_Build_Tool_Fixture_Preflight_Is_Consistent
                (Preflight),
              "rejected project-metadata fixture preflight has no executable process request");
   end Test_Real_Build_Tool_Fixture_Preflight_Result_Consistency_Rejected;

   procedure Test_Real_Build_Tool_Fixture_Command_Result_Consistency_Succeeded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Real_Build_Tool_Fixture_With_Gate
        (S, Real_Build_Tool_Fixture_Request,
         Editor.External_Producers.GPRbuild_Version_Fixture,
         Real_Build_Tool_Fixture_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Exit_Code => 0, Has_Exit_Code => True,
            Stdout_Text => "GPRBUILD Pro 0.0"));
      Assert (Editor.External_Producers.Real_Build_Tool_Fixture_Command_Result_Is_Consistent
                (Result),
              "succeeded real build-tool fixture command result is internally consistent");
   end Test_Real_Build_Tool_Fixture_Command_Result_Consistency_Succeeded;

   procedure Test_Real_Build_Tool_Fixture_Command_Result_Consistency_Failed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Real_Build_Tool_Fixture_With_Gate
        (S, Real_Build_Tool_Fixture_Request,
         Editor.External_Producers.Diagnostic_Output_Fixture,
         Real_Build_Tool_Fixture_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Failed,
            Exit_Code => 1, Has_Exit_Code => True,
            Stderr_Text => "main.adb:1:1: error: fixture"));
      Assert (Editor.External_Producers.Real_Build_Tool_Fixture_Command_Result_Is_Consistent
                (Result),
              "failed real build-tool fixture command result with diagnostics is consistent");
      Assert (To_String (Result.Command_Message) = "Build: failed, ingested 1 diagnostics",
              "failed real build-tool fixture feedback reports ingestion count only after ingestion");
   end Test_Real_Build_Tool_Fixture_Command_Result_Consistency_Failed;

   procedure Test_Real_Build_Tool_Fixture_Command_Result_Consistency_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Real_Build_Tool_Fixture_With_Gate
        (S, Real_Build_Tool_Fixture_Request,
         Editor.External_Producers.GPRbuild_Version_Fixture,
         Real_Build_Tool_Fixture_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Not_Available));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Not_Available,
              "unavailable tool maps to deterministic build fixture unavailable");
      Assert (Editor.External_Producers.Real_Build_Tool_Fixture_Command_Result_Is_Consistent
                (Result),
              "unavailable real build-tool fixture command result is consistent");
      Assert (To_String (Result.Command_Message) = "Build: build fixture unavailable",
              "unavailable real build-tool fixture feedback is normalized");
   end Test_Real_Build_Tool_Fixture_Command_Result_Consistency_Unavailable;

   procedure Test_Real_Build_Tool_Fixture_Ingestion_Disabled_Preserves_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Real_Build_Tool_Fixture_With_Gate
        (S, Real_Build_Tool_Fixture_Request,
         Editor.External_Producers.Diagnostic_Output_Fixture,
         Real_Build_Tool_Fixture_Gate (Allow_Diagnostics_Ingestion => False),
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Exit_Code => 0, Has_Exit_Code => True,
            Stderr_Text => "main.adb:1:1: error: fixture"));
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0,
              "disabled ingestion reports no ingested fixture diagnostics");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "disabled ingestion preserves Diagnostics rows");
   end Test_Real_Build_Tool_Fixture_Ingestion_Disabled_Preserves_Diagnostics;

   procedure Test_Real_Build_Tool_Fixture_Repeated_Run_Preserves_Filter_And_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "warning");
      Assert (Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Outline_Feature),
        "feature panel show feature succeeds");
      for I in 1 .. 3 loop
         pragma Unreferenced (I);
         Result := Editor.External_Producers.Run_Real_Build_Tool_Fixture_With_Gate
           (S, Real_Build_Tool_Fixture_Request,
            Editor.External_Producers.Diagnostic_Output_Fixture,
            Real_Build_Tool_Fixture_Gate,
            Editor.External_Producers.Build_Process_Run_Result
              (Editor.External_Producers.Process_Run_Succeeded,
               Exit_Code => 0, Has_Exit_Code => True,
               Stderr_Text => "main.adb:1:1: warning: fixture"));
         Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Succeeded,
                 "repeated real build-tool fixture run succeeds deterministically");
      end loop;
      Assert (Editor.Feature_Diagnostics.Filter_Text (S.Feature_Diagnostics) = "warning",
              "repeated real build-tool fixture runs preserve Diagnostics filter text");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Outline_Feature,
              "repeated real build-tool fixture runs preserve active feature by default");
   end Test_Real_Build_Tool_Fixture_Repeated_Run_Preserves_Filter_And_Feature;

   procedure Test_Real_Build_Tool_Fixture_Show_Diagnostics_Uses_Normal_Feature_Switch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Outline_Feature),
        "feature panel show feature succeeds");
      Result := Editor.External_Producers.Run_Real_Build_Tool_Fixture_With_Gate
        (S, Real_Build_Tool_Fixture_Request,
         Editor.External_Producers.Diagnostic_Output_Fixture,
         Real_Build_Tool_Fixture_Gate (Show_Diagnostics => True),
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Exit_Code => 0, Has_Exit_Code => True,
            Stderr_Text => "main.adb:1:1: warning: fixture"));
      Assert (Result.Diagnostic_Result.Should_Show_Diagnostics,
              "real build-tool fixture show flag is reported through diagnostic command result");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Diagnostics_Feature,
              "real build-tool fixture show flag uses normal feature-panel switch");
   end Test_Real_Build_Tool_Fixture_Show_Diagnostics_Uses_Normal_Feature_Switch;

   procedure Test_Real_Build_Tool_Fixture_Audit_Passes_After_Repeated_Attempts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      for I in 1 .. 2 loop
         pragma Unreferenced (I);
         Result := Editor.External_Producers.Run_Real_Build_Tool_Fixture_With_Gate
           (S, Real_Build_Tool_Fixture_Request,
            Editor.External_Producers.GPRbuild_Version_Fixture,
            Real_Build_Tool_Fixture_Gate,
            Editor.External_Producers.Build_Process_Run_Result
              (Editor.External_Producers.Process_Run_Not_Available));
         Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Not_Available,
                 "repeated unavailable fixture attempts remain deterministic");
      end loop;
      Editor.External_Producers.Reset_Build_Run_State_For_Workspace_Close (S);
      Result := Editor.External_Producers.Run_Real_Build_Tool_Fixture_With_Gate
        (S, Real_Build_Tool_Fixture_Request,
         Editor.External_Producers.GPRbuild_Version_Fixture,
         Editor.External_Producers.Build_Default_Execution_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Exit_Code => 0, Has_Exit_Code => True,
            Stderr_Text => "main.adb:1:1: error: must not run"));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Not_Available,
              "disabled gate after workspace close cannot consume supplied runner output");
      Assert (Editor.External_Producers.Audit_Real_Build_Tool_Fixture_Gates,
              "real build-tool fixture audit passes after repeated attempts");
   end Test_Real_Build_Tool_Fixture_Audit_Passes_After_Repeated_Attempts;

   procedure Test_Process_Fixture_Default_Gate_Disables_Execution
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Fixture
          (Fixture_Request, Disabled_Process_Policy);
   begin
      Assert (Result.Status = Editor.External_Producers.Process_Run_Not_Available,
              "default disabled policy cannot execute a real fixture");
      Assert (Length (Result.Stdout_Text) = 0 and then Length (Result.Stderr_Text) = 0,
              "disabled fixture execution captures no output");
   end Test_Process_Fixture_Default_Gate_Disables_Execution;

   procedure Test_Process_Fixture_Requires_Explicit_Gate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Gated
          ((Program_Label => To_Unbounded_String ("fixture"),
            Working_Label => Null_Unbounded_String,
            Arguments     => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments),
           Real_Fixture_Process_Policy,
           Editor.External_Producers.Build_Process_Run_Result
             (Editor.External_Producers.Process_Run_Succeeded));
   begin
      Assert (Result.Status = Editor.External_Producers.Process_Run_Rejected,
              "ordinary process requests cannot enter fixture real-runner mode");
   end Test_Process_Fixture_Requires_Explicit_Gate;

   procedure Test_Process_Fixture_Build_Request_Does_Not_Select_Fixture
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Execute_Build_Request_With_Process_Policy
          (Build_Request, Real_Fixture_Process_Policy,
           Editor.External_Producers.Build_Process_Run_Result
             (Editor.External_Producers.Process_Run_Succeeded,
              Stdout_Text => "main.adb:1:1: error: should-not-run"));
   begin
      Assert (Result.Status = Editor.External_Producers.Build_Run_Not_Available,
              "normal build request cannot silently become a fixture request");
      Assert (Length (Result.Stdout_Text) = 0 and then Length (Result.Stderr_Text) = 0,
              "normal build path ignores supplied fixture output under real-fixture mode");
   end Test_Process_Fixture_Build_Request_Does_Not_Select_Fixture;

   procedure Test_Process_Fixture_Rejects_Unknown_Fixture
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Fixture
          (Fixture_Request (Kind => Editor.External_Producers.No_Process_Fixture),
           Real_Fixture_Process_Policy);
   begin
      Assert (Result.Status = Editor.External_Producers.Process_Run_Rejected,
              "unknown fixture identity is rejected deterministically");
   end Test_Process_Fixture_Rejects_Unknown_Fixture;

   procedure Test_Process_Fixture_Rejects_Shell_Mode
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Status : constant Editor.External_Producers.Process_Request_Validation_Status :=
        Editor.External_Producers.Validate_Process_Fixture_Request_Status
          (Fixture_Request, Real_Fixture_Process_Policy (Allow_Shell => True));
   begin
      Assert (Status = Editor.External_Producers.Process_Request_Rejected_Shell_Disallowed,
              "fixture validation rejects shell-enabled policy before execution");
   end Test_Process_Fixture_Rejects_Shell_Mode;

   procedure Test_Process_Fixture_Arguments_Preserve_Order_And_Quoting
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Fixture
          (Fixture_Request
             (First => "stdout",
              Second => "two words",
              Third => """quoted"" ; not interpreted"),
           Real_Fixture_Process_Policy);
   begin
      Assert (Result.Status = Editor.External_Producers.Process_Run_Succeeded,
              "approved echo fixture succeeds under explicit real-fixture gate");
      Assert (To_String (Result.Stdout_Text) =
                "two words" & ASCII.LF & """quoted"" ; not interpreted",
              "fixture argv preserves order, spaces, quotes, and shell metacharacters as inert text");
   end Test_Process_Fixture_Arguments_Preserve_Order_And_Quoting;

   procedure Test_Process_Fixture_Captures_Stderr_And_Exit_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Echo : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Fixture
          (Fixture_Request (First => "stderr", Second => "main.adb:1:1: error: stderr"),
           Real_Fixture_Process_Policy);
      Exit_Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Fixture
          (Fixture_Request
             (Kind => Editor.External_Producers.Exit_Code_Fixture,
              First => "7", Second => "main.adb:2:1: error: failed"),
           Real_Fixture_Process_Policy);
   begin
      Assert (Echo.Status = Editor.External_Producers.Process_Run_Succeeded,
              "stderr echo fixture succeeds");
      Assert (To_String (Echo.Stderr_Text) = "main.adb:1:1: error: stderr",
              "stderr fixture captures bounded stderr text");
      Assert (Exit_Result.Status = Editor.External_Producers.Process_Run_Failed,
              "nonzero fixture exit maps to process failure");
      Assert (Exit_Result.Has_Exit_Code and then Exit_Result.Exit_Code = 7,
              "exit-code fixture preserves explicit exit code");
   end Test_Process_Fixture_Captures_Stderr_And_Exit_Code;

   procedure Test_Process_Fixture_Output_Limit_Is_Enforced
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Fixture
          (Fixture_Request (First => "stdout", Second => "12345"),
           Real_Fixture_Process_Policy (Max_Output_Bytes => 4));
   begin
      Assert (Result.Status = Editor.External_Producers.Process_Run_Execution_Error,
              "real fixture output over the bound is rejected");
      Assert (Length (Result.Stdout_Text) = 0,
              "oversized fixture output is dropped before diagnostic ingestion");
   end Test_Process_Fixture_Output_Limit_Is_Enforced;

   procedure Test_Process_Fixture_Output_Uses_Diagnostic_Line_Pipeline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Fixture_Gate
        (S, Build_Request,
         Fixture_Request
           (First => "stderr",
            Second => "main.adb:1:1: error: fixture",
            Third => "not a diagnostic"),
         Editor.External_Producers.Build_Real_Fixture_Execution_Gate);
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Succeeded,
              "fixture command maps process success to build success");
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Input_Count = 2,
              "fixture output is extracted as diagnostic text lines");
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Accepted_Count = 1,
              "valid fixture diagnostic line is accepted by parser");
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Ignored_Unrecognized_Count = 1,
              "unrecognized fixture output remains inert and ignored");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "fixture command ingests only through Diagnostics ingestion seam");
   end Test_Process_Fixture_Output_Uses_Diagnostic_Line_Pipeline;

   procedure Test_Process_Fixture_Blank_Line_Is_Ignored
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Fixture_Gate
        (S, Build_Request,
         Fixture_Request
           (First => "stdout", Second => "", Third => "not a diagnostic"),
         Editor.External_Producers.Build_Real_Fixture_Execution_Gate);
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Input_Count = 2,
              "blank fixture line is still counted as parser input");
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Ignored_Blank_Count = 1,
              "blank fixture output line is ignored by parser");
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Ignored_Unrecognized_Count = 1,
              "non-diagnostic fixture output line is ignored separately");
   end Test_Process_Fixture_Blank_Line_Is_Ignored;

   procedure Test_Process_Fixture_Mixed_Output_And_Extra_Colons
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Fixture_Gate
        (S, Build_Request,
         Fixture_Request
           (First => "mixed",
            Second => "main.adb:1:1: error: stderr: extra: colon",
            Third => "main.adb:2:1: warning: stdout"),
         Editor.External_Producers.Build_Real_Fixture_Execution_Gate);
      Lines := Editor.External_Producers.Extract_Diagnostic_Lines_From_Build_Result
        (Result.Build_Result);
      Assert (Lines.Length = 2,
              "mixed fixture output extracts one stderr and one stdout line");
      Assert (To_String (Lines.First_Element) =
                "main.adb:1:1: error: stderr: extra: colon",
              "mixed fixture extracts stderr before stdout and preserves extra colons");
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Accepted_Count = 2,
              "mixed fixture valid stdout and stderr diagnostics are parsed");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 2,
              "mixed fixture diagnostics enter through the normal ingestion path");
   end Test_Process_Fixture_Mixed_Output_And_Extra_Colons;

   procedure Test_Process_Fixture_Malformed_Line_Is_Counted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Fixture_Gate
        (S, Build_Request,
         Fixture_Request
           (First => "stdout",
            Second => "main.adb:x:1: error: malformed"),
         Editor.External_Producers.Build_Real_Fixture_Execution_Gate);
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Rejected_Malformed_Count = 1,
              "malformed diagnostic-looking fixture line is counted by parser");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "malformed-only fixture output creates no fabricated diagnostic rows");
   end Test_Process_Fixture_Malformed_Line_Is_Counted;

   procedure Test_Process_Fixture_Preserves_Filter_And_Feature_Default
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Editor.Feature_Diagnostics.Toggle_Errors_Visible (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "warning");
      Assert (Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Outline_Feature),
        "feature panel show feature succeeds");
      Result := Editor.External_Producers.Run_Build_Command_With_Fixture_Gate
        (S, Build_Request,
         Fixture_Request
           (First => "stdout", Second => "main.adb:1:1: warning: visible"),
         Editor.External_Producers.Build_Real_Fixture_Execution_Gate);
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "fixture output can ingest a diagnostic while filters are active");
      Assert (Editor.Feature_Diagnostics.Filter_Text (S.Feature_Diagnostics) = "warning",
              "fixture diagnostic ingestion preserves diagnostic filter text");
      Assert (not Editor.Feature_Diagnostics.Severity_Is_Visible
                (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Error),
              "fixture diagnostic ingestion preserves severity visibility");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Outline_Feature,
              "fixture command does not switch active feature by default");
   end Test_Process_Fixture_Preserves_Filter_And_Feature_Default;

   procedure Test_Process_Fixture_Show_Diagnostics_Explicitly_Switches_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Outline_Feature),
        "feature panel show feature succeeds");
      Result := Editor.External_Producers.Run_Build_Command_With_Fixture_Gate
        (S, Build_Request, Fixture_Request,
         Editor.External_Producers.Build_Real_Fixture_Execution_Gate
           (Show_Diagnostics => True));
      Assert (Result.Diagnostic_Result.Should_Show_Diagnostics,
              "explicit fixture show flag is reported");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Diagnostics_Feature,
              "explicit fixture show flag switches to Diagnostics");
   end Test_Process_Fixture_Show_Diagnostics_Explicitly_Switches_Feature;

   procedure Test_Process_Fixture_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Editor.External_Producers.Audit_Process_Fixture_Gates,
              "fixture audit covers explicit gate, identity, argv, bounds, and line pipeline");
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Before = After,
              "fixture audit is side-effect-free for caller feature panel");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "fixture audit does not mutate caller Diagnostics");
   end Test_Process_Fixture_Audit_Is_Side_Effect_Free;

   procedure Test_Process_Fixture_Validation_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Status : Editor.External_Producers.Process_Fixture_Validation_Status;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Status := Editor.External_Producers.Validate_Process_Fixture_Request
        (Fixture_Request, Real_Fixture_Process_Policy);
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Status = Editor.External_Producers.Fixture_Request_Valid,
              "fixture validation accepts an explicit approved fixture request");
      Assert (Before = After,
              "fixture validation does not mutate feature-panel state");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "fixture validation does not ingest diagnostics");
   end Test_Process_Fixture_Validation_Is_Side_Effect_Free;

   procedure Test_Process_Fixture_Rejected_Request_Does_Not_Call_Runner
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Fixture_Gate
        (S, Build_Request,
         Fixture_Request (Kind => Editor.External_Producers.No_Process_Fixture),
         Editor.External_Producers.Build_Real_Fixture_Execution_Gate);
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Rejected,
              "unknown fixture request is rejected before runner execution");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "rejected fixture request does not ingest supplied or fabricated diagnostics");
      Assert (To_String (Result.Command_Message) = "Build: fixture rejected",
              "fixture rejection feedback is normalized and does not expose argv");
   end Test_Process_Fixture_Rejected_Request_Does_Not_Call_Runner;

   procedure Test_Process_Fixture_Output_Over_Limit_Does_Not_Fabricate_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Fixture_Gate
        (S, Build_Request,
         Fixture_Request
           (First => "stdout", Second => "main.adb:1:1: error: too-long"),
         Editor.External_Producers.Build_Real_Fixture_Execution_Gate
           (Max_Output_Bytes => 8));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Execution_Error,
              "fixture output beyond the bound maps to execution error");
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Input_Count = 0,
              "oversized fixture output is dropped before diagnostic parsing");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "oversized fixture output fabricates no diagnostic rows");
   end Test_Process_Fixture_Output_Over_Limit_Does_Not_Fabricate_Diagnostics;

   procedure Test_Process_Fixture_Nonzero_Exit_Can_Ingest_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Fixture_Gate
        (S, Build_Request,
         Fixture_Request
           (Kind => Editor.External_Producers.Exit_Code_Fixture,
            First => "4", Second => "main.adb:1:1: error: failed"),
         Editor.External_Producers.Build_Real_Fixture_Execution_Gate);
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Failed,
              "nonzero fixture exit maps to failed build result");
      Assert (Result.Build_Result.Has_Exit_Code and then Result.Build_Result.Exit_Code = 4,
              "fixture failed build preserves explicit exit code");
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "nonzero fixture output can still enter Diagnostics through normal ingestion");
   end Test_Process_Fixture_Nonzero_Exit_Can_Ingest_Diagnostics;

   procedure Test_Process_Fixture_Ingestion_Disabled_Preserves_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Fixture_Gate
        (S, Build_Request, Fixture_Request,
         Editor.External_Producers.Build_Real_Fixture_Execution_Gate
           (Allow_Diagnostics_Ingestion => False));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Succeeded,
              "fixture execution can succeed while diagnostics ingestion is disabled");
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Input_Count = 0,
              "diagnostics-disabled fixture command reports no parse/input count");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "diagnostics-disabled fixture command mutates no diagnostics rows");
      Assert (To_String (Result.Command_Message) =
                "Build: succeeded, diagnostics ingestion disabled",
              "feedback reports disabled ingestion without a diagnostic count");
   end Test_Process_Fixture_Ingestion_Disabled_Preserves_Diagnostics;

   procedure Test_Process_Fixture_Result_Consistency_Succeeded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Fixture
          (Fixture_Request, Real_Fixture_Process_Policy);
   begin
      Assert (Editor.External_Producers.Process_Fixture_Result_Is_Consistent
                (Result, Real_Fixture_Process_Policy),
              "successful fixture process result is internally consistent");
      Editor.External_Producers.Assert_Process_Fixture_Result_Consistent (Result);
   end Test_Process_Fixture_Result_Consistency_Succeeded;

   procedure Test_Process_Fixture_Result_Consistency_Failed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Fixture
          (Fixture_Request
             (Kind => Editor.External_Producers.Exit_Code_Fixture,
              First => "2", Second => "main.adb:1:1: error: failed"),
           Real_Fixture_Process_Policy);
   begin
      Assert (Editor.External_Producers.Process_Fixture_Result_Is_Consistent
                (Result, Real_Fixture_Process_Policy),
              "failed fixture process result preserves exit-code consistency");
   end Test_Process_Fixture_Result_Consistency_Failed;

   procedure Test_Process_Fixture_Result_Consistency_Not_Available
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Fixture
          (Fixture_Request, Disabled_Process_Policy);
   begin
      Assert (Editor.External_Producers.Process_Fixture_Result_Is_Consistent
                (Result, Disabled_Process_Policy),
              "not-available fixture result carries no exit code or captured output");
   end Test_Process_Fixture_Result_Consistency_Not_Available;

   procedure Test_Process_Fixture_Result_Consistency_Execution_Error
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Fixture
          (Fixture_Request (First => "stdout", Second => "12345"),
           Real_Fixture_Process_Policy (Max_Output_Bytes => 4));
   begin
      Assert (Editor.External_Producers.Process_Fixture_Result_Is_Consistent
                (Result, Real_Fixture_Process_Policy (Max_Output_Bytes => 4)),
              "execution-error fixture result drops output and reports no fabricated success");
   end Test_Process_Fixture_Result_Consistency_Execution_Error;

   procedure Test_Process_Fixture_Audit_Covers_Lifecycle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.External_Producers.Audit_Process_Fixture_Gates,
              "fixture audit covers lifecycle-safe explicit fixture execution gates");
      Assert (Editor.External_Producers.Process_Runner_Audit_Passes,
              "process runner test-seam audit includes fixture finalization checks");
   end Test_Process_Fixture_Audit_Covers_Lifecycle;

   procedure Test_Process_Fixture_Audit_Passes_After_Repeated_Runs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      for I in 1 .. 3 loop
         pragma Unreferenced (I);
         Result := Editor.External_Producers.Run_Build_Command_With_Fixture_Gate
           (S, Build_Request, Fixture_Request,
            Editor.External_Producers.Build_Real_Fixture_Execution_Gate);
         Assert (Editor.External_Producers.Gated_Build_Command_Result_Is_Consistent
                   (Result),
                 "repeated fixture command result remains consistent");
      end loop;
      Assert (Editor.External_Producers.Audit_Process_Fixture_Gates,
              "fixture audit still passes after repeated fixture runs");
   end Test_Process_Fixture_Audit_Passes_After_Repeated_Runs;

   procedure Test_Process_Execution_Default_Mode_Is_Disabled
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Policy : constant Editor.External_Producers.Process_Execution_Policy :=
        Disabled_Process_Policy;
   begin
      Assert (Editor.External_Producers.Validate_Process_Execution_Policy (Policy),
              "default disabled process policy is valid");
      Assert (not Policy.Allow_Real_Execution,
              "default process policy does not allow real execution");
      Assert (not Policy.Allow_Shell,
              "default process policy forbids shell execution");
   end Test_Process_Execution_Default_Mode_Is_Disabled;

   procedure Test_Process_Execution_Disabled_Mode_Does_Not_Run
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Gated
          ((Program_Label => To_Unbounded_String ("gprbuild"),
            Working_Label => Null_Unbounded_String,
            Arguments     => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments),
           Disabled_Process_Policy,
           Editor.External_Producers.Build_Process_Run_Result
             (Editor.External_Producers.Process_Run_Succeeded));
   begin
      Assert (Result.Status = Editor.External_Producers.Process_Run_Not_Available,
              "disabled policy returns not-available and ignores supplied success");
   end Test_Process_Execution_Disabled_Mode_Does_Not_Run;

   procedure Test_Process_Execution_Real_Mode_Must_Be_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Bad : constant Editor.External_Producers.Process_Execution_Policy :=
        (Mode                     => Editor.External_Producers.Process_Execution_Real_Allowed,
         Allow_Real_Execution     => False,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
   begin
      Assert (not Editor.External_Producers.Validate_Process_Execution_Policy (Bad),
              "real mode requires explicit Allow_Real_Execution");
   end Test_Process_Execution_Real_Mode_Must_Be_Explicit;

   procedure Test_Process_Execution_Rejects_Shell_Mode
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Gated
          ((Program_Label => To_Unbounded_String ("/bin/sh"),
            Working_Label => Null_Unbounded_String,
            Arguments     => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments),
           Real_Process_Policy (Allow_Shell => True));
   begin
      Assert (Result.Status = Editor.External_Producers.Process_Run_Rejected,
              "shell-enabled policy is rejected before execution");
   end Test_Process_Execution_Rejects_Shell_Mode;

   procedure Test_Process_Execution_Rejects_Opaque_Arguments_For_Real_Run
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Gated
          ((Program_Label => To_Unbounded_String ("gprbuild"),
            Working_Label => Null_Unbounded_String,
            Arguments     => To_Unbounded_String ("-q ; rm -rf ignored"),
            Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments),
           Real_Process_Policy);
   begin
      Assert (Result.Status = Editor.External_Producers.Process_Run_Rejected,
              "real runner rejects opaque argument strings instead of shell-parsing them");
   end Test_Process_Execution_Rejects_Opaque_Arguments_For_Real_Run;

   procedure Test_Process_Execution_Structured_Arguments_Preserve_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : constant Editor.External_Producers.Process_Argument_Vector :=
        Editor.External_Producers.Build_Process_Argument_Vector
          ("first", "", "third");
   begin
      Assert (Args.Length = 3,
              "structured argv builder preserves exact argument count including empty values");
      Assert (To_String (Args.First_Element) = "first",
              "structured argv preserves first argument");
      Assert (To_String (Args.Element (1)) = "",
              "structured argv preserves explicit empty argument text");
      Assert (To_String (Args.Last_Element) = "third",
              "structured argv preserves argument order");
   end Test_Process_Execution_Structured_Arguments_Preserve_Order;



   procedure Test_Process_Request_Real_Validation_Rejects_Relative_Program_When_Required
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Request : constant Editor.External_Producers.Process_Run_Request :=
        (Program_Label => To_Unbounded_String ("gprbuild"),
         Working_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
      Status : constant Editor.External_Producers.Process_Request_Validation_Status :=
        Editor.External_Producers.Validate_Process_Run_Request_For_Real_Execution_Status
          (Request,
           Real_Process_Policy (Require_Absolute_Program => True));
   begin
      Assert (Status = Editor.External_Producers.Process_Request_Rejected_Relative_Program,
              "real execution validation rejects relative program labels when required");
   end Test_Process_Request_Real_Validation_Rejects_Relative_Program_When_Required;

   procedure Test_Build_Preparation_Does_Not_Split_Opaque_Arguments
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool          => Editor.External_Producers.GPRbuild_Tool,
        Provenance    => Editor.External_Producers.Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q --RTS=two words ; ignored"),
         Structured_Arguments => Editor.External_Producers.Build_Process_Argument_Vector ("-q"));
      Process : constant Editor.External_Producers.Process_Run_Request :=
        Editor.External_Producers.Prepare_Process_Request (Request);
   begin
      Assert (To_String (Process.Arguments) = "-q --RTS=two words ; ignored",
              "opaque argument metadata is preserved exactly for display/testing");
      Assert (Process.Structured_Arguments.Length = 1
              and then To_String (Process.Structured_Arguments.First_Element) = "-q",
              "opaque argument metadata is not split; caller-supplied structured argv is preserved");
   end Test_Build_Preparation_Does_Not_Split_Opaque_Arguments;

   procedure Test_Preflight_Build_Request_Rejects_Invalid_Process_Request
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool          => Editor.External_Producers.GPRbuild_Tool,
        Provenance    => Editor.External_Producers.Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q"),
         Structured_Arguments => Editor.External_Producers.Build_Process_Argument_Vector ("-q"));
      Result : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_Build_Run_Request
          (Request, Real_Process_Policy);
   begin
      Assert (Editor.External_Producers.Build_Preflight_Result_Is_Consistent (Result),
              "preflight result remains internally consistent");
      Assert (Result.Build_Request_Status = Editor.External_Producers.Build_Request_Valid,
              "preflight validates the build request before process validation");
      Assert (Result.Process_Request_Status =
              Editor.External_Producers.Process_Request_Rejected_Opaque_Arguments,
              "preflight rejects opaque process arguments for real execution");
      Assert (not Result.Has_Process_Request,
              "rejected preflight does not expose an executable process request");
   end Test_Preflight_Build_Request_Rejects_Invalid_Process_Request;

   procedure Test_Preflight_Does_Not_Call_Runner
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool          => Editor.External_Producers.GPRbuild_Tool,
        Provenance    => Editor.External_Producers.Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q"),
         Structured_Arguments => Editor.External_Producers.Build_Process_Argument_Vector ("-q"));
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_Test_Seam_With_Runner
        (S, Request, Real_Process_Policy,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Stdout_Text => "main.adb:1:1: error: should-not-run"));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Rejected,
              "invalid preflight rejects before supplied runner output can succeed");
      Assert (To_String (Result.Command_Message) = "Build: structured arguments required",
              "command feedback reports structured argv requirement without raw command text");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "preflight rejection does not ingest diagnostics");
   end Test_Preflight_Does_Not_Call_Runner;

   procedure Test_Process_Execution_Output_Limit_Is_Enforced
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Gated
          ((Program_Label => To_Unbounded_String ("fixture"),
            Working_Label => Null_Unbounded_String,
            Arguments     => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments),
           Fixture_Process_Policy (Max_Output_Bytes => 4),
           Editor.External_Producers.Build_Process_Run_Result
             (Editor.External_Producers.Process_Run_Succeeded,
              Stdout_Text => "12345"));
   begin
      Assert (Result.Status = Editor.External_Producers.Process_Run_Execution_Error,
              "fixture output above the policy byte bound is rejected deterministically");
      Assert (Length (Result.Stdout_Text) = 0,
              "oversized output is not forwarded to diagnostics");
   end Test_Process_Execution_Output_Limit_Is_Enforced;

   procedure Test_Process_Execution_Timeout_Field_Uses_Native_Supervisor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Gated
          ((Program_Label => To_Unbounded_String ("/bin/echo"),
            Working_Label => To_Unbounded_String ("/"),
            Arguments     => Null_Unbounded_String,
            Structured_Arguments =>
              Editor.External_Producers.Build_Process_Argument_Vector ("ok")),
           Real_Process_Policy (Timeout_Milliseconds => 1));
   begin
      Assert (Result.Status =
                Editor.External_Producers.Process_Run_Succeeded
              or else Result.Status =
                Editor.External_Producers.Process_Run_Timed_Out,
              "nonzero timeout is handled by the native runner supervisor");
   end Test_Process_Execution_Timeout_Field_Uses_Native_Supervisor;

   procedure Test_Gated_Real_Runner_Not_Available_When_Platform_Runner_Missing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Gated
          ((Program_Label => To_Unbounded_String ("gprbuild"),
            Working_Label => Null_Unbounded_String,
            Arguments     => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments),
           Real_Process_Policy);
   begin
      Assert (Result.Status = Editor.External_Producers.Process_Run_Rejected,
              "real runner rejects requests without structured argv before any platform spawn attempt");
   end Test_Gated_Real_Runner_Not_Available_When_Platform_Runner_Missing;

   procedure Test_Build_Command_Selects_Test_Fed_Runner_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Execute_Build_Request_With_Process_Policy
          (Build_Request,
           Fixture_Process_Policy,
           Editor.External_Producers.Build_Process_Run_Result
             (Editor.External_Producers.Process_Run_Failed,
              Exit_Code => 9, Has_Exit_Code => True,
              Stderr_Text => "main.adb:1:1: error: fixture"));
   begin
      Assert (Result.Status = Editor.External_Producers.Build_Run_Failed,
              "build test seam can select test-fed process runner explicitly");
      Assert (Result.Has_Exit_Code and then Result.Exit_Code = 9,
              "test-fed process result maps through build result conversion");
   end Test_Build_Command_Selects_Test_Fed_Runner_Deterministically;

   procedure Test_Build_Command_Selects_Default_Non_Executing_Runner_By_Default
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Execute_Build_Request (Build_Request);
   begin
      Assert (Result.Status = Editor.External_Producers.Build_Run_Not_Available,
              "default build request still selects the disabled runner");
   end Test_Build_Command_Selects_Default_Non_Executing_Runner_By_Default;

   procedure Test_Build_Command_Does_Not_Call_Runner_For_Invalid_Request
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Execute_Build_Request_With_Process_Policy
          (Build_Request (Tool => Editor.External_Producers.No_Build_Tool),
           Fixture_Process_Policy,
           Editor.External_Producers.Build_Process_Run_Result
             (Editor.External_Producers.Process_Run_Succeeded));
   begin
      Assert (Result.Status = Editor.External_Producers.Build_Run_Rejected,
              "invalid build request is rejected before the selected runner can supply success");
   end Test_Build_Command_Does_Not_Call_Runner_For_Invalid_Request;

   procedure Test_Build_Command_Real_Runner_Output_Uses_Line_Pipeline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Execute_Build_Request_With_Process_Policy
          (Build_Request,
           Fixture_Process_Policy,
           Editor.External_Producers.Build_Process_Run_Result
             (Editor.External_Producers.Process_Run_Failed,
              Stderr_Text => "main.adb:1:1: error: gated fixture"));
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Command := Editor.External_Producers.Ingest_Build_Run_Diagnostics
        (S, Build_Source, Result);
      Assert (Command.Ingestion.Parse_Accepted_Count = 1,
              "gated runner output uses the existing diagnostic-line parser");
      Assert (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "gated runner output enters Diagnostics through ingestion seam");
   end Test_Build_Command_Real_Runner_Output_Uses_Line_Pipeline;

   procedure Test_Build_Gate_Default_Disables_Execution
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Default_Execution_Gate;
   begin
      Assert (Editor.External_Producers.Validate_Build_Execution_Gate (Gate),
              "default build execution gate is internally consistent");
      Assert (not Gate.Allow_Build_Run,
              "default build execution gate does not allow build execution");
      Assert (Gate.Process_Policy.Mode = Editor.External_Producers.Process_Execution_Disabled,
              "default build execution gate carries disabled process policy");
   end Test_Build_Gate_Default_Disables_Execution;

   procedure Test_Build_Gate_Disabled_Does_Not_Call_Runner
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Build_Request, Editor.External_Producers.Build_Default_Execution_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Stderr_Text => "main.adb:1:1: error: must-not-run"));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Not_Available,
              "disabled gate ignores supplied runner success");
      Assert (To_String (Result.Command_Message) = "Build: execution disabled",
              "disabled gate emits execution-disabled feedback");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "disabled gate cannot ingest supplied output");
   end Test_Build_Gate_Disabled_Does_Not_Call_Runner;

   procedure Test_Build_Gate_Test_Fixture_Selects_Test_Runner
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate;
   begin
      Assert (Editor.External_Producers.Select_Process_Runner_Mode
                (Gate, Gate.Process_Policy) = Editor.External_Producers.Process_Execution_Test_Fixture,
              "test fixture gate selects only the test-fed runner");
   end Test_Build_Gate_Test_Fixture_Selects_Test_Runner;

   procedure Test_Build_Gate_Real_Mode_Must_Be_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Real_Execution_Gate;
   begin
      Assert (Gate.Allow_Build_Run and then Gate.Process_Policy.Allow_Real_Execution,
              "real gate requires explicit command and process opt-in");
      Assert (Editor.External_Producers.Select_Process_Runner_Mode
                (Gate, Gate.Process_Policy) = Editor.External_Producers.Process_Execution_Real_Allowed,
              "explicit real gate selects real runner mode");
   end Test_Build_Gate_Real_Mode_Must_Be_Explicit;

   procedure Test_Build_Gate_Rejects_Ambiguous_Test_And_Real_Mode
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        (Process_Policy              =>
           (Mode                     => Editor.External_Producers.Process_Execution_Test_Fixture,
            Allow_Real_Execution     => True,
            Allow_Shell              => False,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => 0),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Editor.External_Producers.Build_Consent_Not_Provided,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
   begin
      Assert (not Editor.External_Producers.Validate_Build_Execution_Gate (Gate),
              "test-fed and real execution cannot be active ambiguously");
      Assert (Editor.External_Producers.Select_Process_Runner_Mode
                (Gate, Gate.Process_Policy) = Editor.External_Producers.Process_Execution_Disabled,
              "ambiguous gate deterministically selects no runner");
   end Test_Build_Gate_Rejects_Ambiguous_Test_And_Real_Mode;

   procedure Test_Build_Gate_Rejects_Shell_Mode
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        (Process_Policy              => Real_Process_Policy (Allow_Shell => True),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Editor.External_Producers.Build_Consent_Not_Provided,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
   begin
      Assert (not Editor.External_Producers.Validate_Build_Execution_Gate (Gate),
              "build gate rejects shell-enabled policy");
   end Test_Build_Gate_Rejects_Shell_Mode;

   procedure Test_Build_Gate_Rejects_Opaque_Arguments_For_Real
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool          => Editor.External_Producers.GPRbuild_Tool,
         Provenance    => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q --not-split"),
         Structured_Arguments => Editor.External_Producers.Build_Process_Argument_Vector ("-q"));
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Request, Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed),
         Editor.External_Producers.Build_Process_Run_Result (Editor.External_Producers.Process_Run_Succeeded));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Rejected,
              "real gate rejects opaque arguments before runner selection");
      Assert (To_String (Result.Command_Message) = "Build: structured arguments required",
              "opaque argument rejection does not expose shell quoting");
   end Test_Build_Gate_Rejects_Opaque_Arguments_For_Real;

   procedure Test_Build_Gate_Invalid_Build_Request_Does_Not_Call_Runner
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Build_Request (Tool => Editor.External_Producers.No_Build_Tool),
         Editor.External_Producers.Build_Test_Fixture_Execution_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Stderr_Text => "main.adb:1:1: error: must-not-run"));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Rejected,
              "invalid build request rejects before supplied runner result");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "invalid build request cannot ingest supplied output");
   end Test_Build_Gate_Invalid_Build_Request_Does_Not_Call_Runner;

   procedure Test_Build_Gate_Invalid_Process_Request_Does_Not_Call_Runner
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Build_Request (Command => ""),
         Editor.External_Producers.Build_Test_Fixture_Execution_Gate,
         Editor.External_Producers.Build_Process_Run_Result (Editor.External_Producers.Process_Run_Succeeded));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Rejected,
              "invalid process-preparation input rejects before supplied runner result");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "invalid process request cannot mutate Diagnostics");
   end Test_Build_Gate_Invalid_Process_Request_Does_Not_Call_Runner;

   procedure Test_Build_Gate_Allows_Test_Fed_Result_When_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Build_Request, Editor.External_Producers.Build_Test_Fixture_Execution_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Failed,
            Exit_Code => 2, Has_Exit_Code => True,
            Stderr_Text => "main.adb:1:1: error: explicit fixture"));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Failed,
              "explicit test gate maps supplied process failure");
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "explicit test gate routes output through diagnostics ingestion");
   end Test_Build_Gate_Allows_Test_Fed_Result_When_Explicit;

   procedure Test_Build_Gate_Real_Runner_Executes_Version_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S,
         (Tool          => Editor.External_Producers.GPRbuild_Tool,
          Provenance    => Editor.External_Producers.Build_Request_From_User_Opt_In,
          Working_Label => Null_Unbounded_String,
          Command_Label => To_Unbounded_String ("gprbuild --version"),
          Arguments     => Null_Unbounded_String,
          Structured_Arguments =>
            Editor.External_Producers.Build_Process_Argument_Vector ("--version")),
         Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed),
         Editor.External_Producers.Build_Process_Run_Result (Editor.External_Producers.Process_Run_Succeeded));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Succeeded,
              "validated real gate executes a bounded version command");
      Assert (Result.Build_Result.Has_Exit_Code
              and then Result.Build_Result.Exit_Code = 0,
              "real version command preserves successful exit code");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Result.Command_Message), "Build: succeeded") = 1,
              "real success feedback starts with successful status");
   end Test_Build_Gate_Real_Runner_Executes_Version_Command;

   procedure Test_Build_Gate_Diagnostics_Ingestion_Disabled_Does_Not_Mutate_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Build_Request,
         Editor.External_Producers.Build_Test_Fixture_Execution_Gate (Allow_Diagnostics_Ingestion => False),
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Failed,
            Stderr_Text => "main.adb:1:1: error: not-ingested"));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Failed,
              "disabling ingestion does not alter build status");
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Input_Count = 0,
              "disabled ingestion does not parse process output");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "disabled ingestion leaves Diagnostics unchanged");
      Assert (To_String (Result.Command_Message) = "Build: failed, diagnostics ingestion disabled",
              "disabled ingestion feedback reports status without count");
   end Test_Build_Gate_Diagnostics_Ingestion_Disabled_Does_Not_Mutate_Diagnostics;

   procedure Test_Build_Gate_Diagnostics_Ingestion_Enabled_Uses_Line_Pipeline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Build_Request, Editor.External_Producers.Build_Test_Fixture_Execution_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Failed,
            Stderr_Text => "main.adb:1:1: error: ingested"));
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Accepted_Count = 1,
              "enabled ingestion uses diagnostic-line parser");
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "enabled ingestion reaches Diagnostics through producer seam");
   end Test_Build_Gate_Diagnostics_Ingestion_Enabled_Uses_Line_Pipeline;

   procedure Test_Build_Gate_Default_Does_Not_Switch_Active_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Id;
      After : Editor.Feature_Panel.Feature_Id;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Editor.Feature_Panel.Outline_Feature),
        "feature panel show feature succeeds");
      Before := Editor.Feature_Panel.Active_Feature (S.Feature_Panel);
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Build_Request, Editor.External_Producers.Build_Test_Fixture_Execution_Gate,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Failed,
            Stderr_Text => "main.adb:1:1: error: hidden"));
      After := Editor.Feature_Panel.Active_Feature (S.Feature_Panel);
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "diagnostic was ingested for active-feature test");
      Assert (Before = After,
              "gated build command does not switch active feature by default");
   end Test_Build_Gate_Default_Does_Not_Switch_Active_Feature;

   procedure Test_Build_Gate_Show_Diagnostics_Explicitly_Switches_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Editor.Feature_Panel.Outline_Feature),
        "feature panel show feature succeeds");
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Build_Request,
         Editor.External_Producers.Build_Test_Fixture_Execution_Gate (Show_Diagnostics => True),
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Failed,
            Stderr_Text => "main.adb:1:1: error: visible"));
      Assert (Result.Diagnostic_Result.Should_Show_Diagnostics,
              "explicit show flag is reflected in command result");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) = Editor.Feature_Panel.Diagnostics_Feature,
              "explicit show flag switches to Diagnostics feature");
   end Test_Build_Gate_Show_Diagnostics_Explicitly_Switches_Feature;

   procedure Test_Build_Gate_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Editor.External_Producers.Audit_Build_Execution_Gates,
              "build gate audit covers default, fixture, real, shell, and ambiguous cases");
      Assert (Editor.External_Producers.Audit_Gated_Runner_Command_Path,
              "gated runner command audit covers disabled, invalid, fixture, no-ingest, unavailable, and opaque cases");
      Assert (Editor.External_Producers.Audit_Real_Build_Execution_Gates,
              "real build opt-in audit covers provenance, implicit source, working context, and gate rejection cases");
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Before = After,
              "gated build audits are side-effect-free for caller state");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "gated build audits do not mutate caller Diagnostics");
   end Test_Build_Gate_Audit_Is_Side_Effect_Free;

   procedure Test_Process_Runner_Audit_Covers_Execution_Gating
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.External_Producers.Audit_Process_Execution_Gates,
              "process execution gate audit covers disabled, real, fixture, output-bound, and invalid-build cases");
   end Test_Process_Runner_Audit_Covers_Execution_Gating;



   procedure Test_Process_Runner_Audit_Covers_Structured_Argv_And_Preflight
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Editor.External_Producers.Audit_Process_Argv_And_Preflight_Gates,
              "process audit covers structured argv and preflight gates");
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Before = After,
              "structured argv/preflight audit is side-effect-free");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "structured argv/preflight audit does not ingest diagnostics");
   end Test_Process_Runner_Audit_Covers_Structured_Argv_And_Preflight;

   procedure Test_Process_Runner_Audit_Covers_Default_Non_Execution
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.External_Producers.Process_Runner_Audit_Passes,
              "process-runner audit covers default non-execution, validation, conversion, and line extraction");
   end Test_Process_Runner_Audit_Covers_Default_Non_Execution;

   procedure Test_Build_Test_Fed_Executor_Returns_Supplied_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Supplied : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Exit_Code => 2, Has_Exit_Code => True,
           Stderr_Text => "main.adb:1:1: error: supplied");
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Execute_Test_Fed_Build_Request
          (Build_Request, Supplied);
   begin
      Assert (Result.Status = Editor.External_Producers.Build_Run_Failed,
              "test-fed executor returns the supplied status");
      Assert (Result.Has_Exit_Code and then Result.Exit_Code = 2,
              "test-fed executor returns the supplied exit code");
      Assert (To_String (Result.Stderr_Text) = "main.adb:1:1: error: supplied",
              "test-fed executor returns supplied output without execution");
   end Test_Build_Test_Fed_Executor_Returns_Supplied_Result;

   procedure Test_Build_Invalid_Request_Does_Not_Use_Test_Fed_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Supplied : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Succeeded,
           Stdout_Text => "main.adb:1:1: warning: should-not-appear");
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Execute_Test_Fed_Build_Request
          (Build_Request (Tool => Editor.External_Producers.No_Build_Tool),
           Supplied);
   begin
      Assert (Result.Status = Editor.External_Producers.Build_Run_Rejected,
              "invalid request is rejected before the test-fed executor result is used");
      Assert (To_String (Result.Stdout_Text)'Length = 0,
              "invalid request does not expose supplied stdout diagnostics");
   end Test_Build_Invalid_Request_Does_Not_Use_Test_Fed_Result;

   procedure Test_Build_Run_Result_Empty_Output_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Succeeded);
      Lines : constant Editor.External_Producers.Diagnostic_Text_Line_Array :=
        Editor.External_Producers.Extract_Diagnostic_Lines_From_Build_Result (Result);
   begin
      Assert (Result.Status = Editor.External_Producers.Build_Run_Succeeded,
              "build result stores the requested status");
      Assert (not Result.Has_Exit_Code,
              "empty result has no synthetic exit code");
      Assert (Lines.Length = 0,
              "empty build output extracts no diagnostic lines");
   end Test_Build_Run_Result_Empty_Output_Is_Deterministic;

   procedure Test_Build_Run_Result_Failed_Run_Can_Carry_Diagnostic_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Explicit : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Result : Editor.External_Producers.Build_Run_Result;
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
   begin
      Explicit.Append (To_Unbounded_String ("main.adb:1:1: error: explicit"));
      Result := Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Failed,
         Exit_Code => 1, Has_Exit_Code => True,
         Stderr_Text => "main.adb:2:1: warning: stderr",
         Diagnostic_Lines => Explicit);
      Lines := Editor.External_Producers.Extract_Diagnostic_Lines_From_Build_Result (Result);
      Assert (Lines.Length = 1,
              "explicit diagnostic lines take precedence over stream splitting");
      Assert (To_String (Lines.First_Element) = "main.adb:1:1: error: explicit",
              "explicit diagnostic line is preserved exactly");
   end Test_Build_Run_Result_Failed_Run_Can_Carry_Diagnostic_Lines;

   procedure Test_Build_Result_Splits_Stderr_Before_Stdout
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stdout_Text => "stdout.adb:2:1: warning: stdout" & ASCII.LF,
           Stderr_Text => "stderr.adb:1:1: error: stderr" & ASCII.LF);
      Lines : constant Editor.External_Producers.Diagnostic_Text_Line_Array :=
        Editor.External_Producers.Extract_Diagnostic_Lines_From_Build_Result (Result);
   begin
      Assert (Lines.Length = 2,
              "stderr and stdout diagnostic-looking output split into two lines");
      Assert (To_String (Lines.First_Element) = "stderr.adb:1:1: error: stderr",
              "stderr output is extracted before stdout output");
      Assert (To_String (Lines.Last_Element) = "stdout.adb:2:1: warning: stdout",
              "stdout output preserves order after stderr output");
   end Test_Build_Result_Splits_Stderr_Before_Stdout;

   procedure Test_Build_Result_Execution_Error_Can_Carry_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Execution_Error,
           Stderr_Text => "main.adb:1:1: error: execution diagnostic");
      Lines : constant Editor.External_Producers.Diagnostic_Text_Line_Array :=
        Editor.External_Producers.Extract_Diagnostic_Lines_From_Build_Result (Result);
   begin
      Assert (Lines.Length = 1,
              "execution-error result may carry explicitly supplied output diagnostics");
      Assert (To_String (Lines.First_Element) =
                "main.adb:1:1: error: execution diagnostic",
              "execution-error diagnostic output is not fabricated or discarded");
   end Test_Build_Result_Execution_Error_Can_Carry_Diagnostics;

   procedure Test_Build_Run_Test_Seam_Does_Not_Invoke_External_Tool_By_Default
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Execute_Build_Request (Build_Request);
   begin
      Assert (Result.Status = Editor.External_Producers.Build_Run_Not_Available,
              "default build executor seam does not run an external tool");
      Assert (Result.Diagnostic_Lines.Length = 0,
              "default not-available result carries no diagnostics");
   end Test_Build_Run_Test_Seam_Does_Not_Invoke_External_Tool_By_Default;

   procedure Test_Build_Run_Output_Ingests_Diagnostics_Through_Line_Pipeline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Run_Result;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Failed,
         Exit_Code => 1, Has_Exit_Code => True,
         Stderr_Text => "main.adb:1:1: error: build failed");
      Command := Editor.External_Producers.Ingest_Build_Run_Diagnostics
        (S, Build_Source, Result);
      Assert (Command.Ingestion.Parse_Accepted_Count = 1,
              "build output is parsed by the diagnostic-line parser");
      Assert (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "build output enters Diagnostics through line ingestion");
   end Test_Build_Run_Output_Ingests_Diagnostics_Through_Line_Pipeline;

   procedure Test_Build_Run_Output_Preserves_Diagnostics_Filter
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Run_Result;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "warning");
      Result := Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Succeeded,
         Stdout_Text => "main.adb:1:1: warning: preserved filter");
      Command := Editor.External_Producers.Ingest_Build_Run_Diagnostics
        (S, Build_Source, Result);
      Assert (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "build output diagnostic is ingested");
      Assert (Editor.Feature_Diagnostics.Filter_Text (S.Feature_Diagnostics) = "warning",
              "build output ingestion preserves diagnostic filter text");
   end Test_Build_Run_Output_Preserves_Diagnostics_Filter;

   procedure Test_Build_Run_Output_Preserves_Diagnostics_Severity_Visibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Run_Result;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Editor.Feature_Diagnostics.Toggle_Warnings_Visible
        (S.Feature_Diagnostics);
      Result := Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Succeeded,
         Stderr_Text => "main.adb:1:1: warning: hidden severity remains hidden");
      Command := Editor.External_Producers.Ingest_Build_Run_Diagnostics
        (S, Build_Source, Result);
      Assert (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "severity visibility does not block diagnostic storage");
      Assert (not Editor.Feature_Diagnostics.Severity_Is_Visible
                (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Warning),
              "build output ingestion preserves severity visibility");
   end Test_Build_Run_Output_Preserves_Diagnostics_Severity_Visibility;

   procedure Test_Build_Run_Output_Preserves_Diagnostics_Source_Visibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Run_Result;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Editor.Feature_Diagnostics.Toggle_Source_Visible
        (S.Feature_Diagnostics, Editor.Feature_Diagnostics.External_Diagnostic_Source);
      Result := Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Succeeded,
         Stderr_Text => "main.adb:1:1: warning: hidden source remains hidden");
      Command := Editor.External_Producers.Ingest_Build_Run_Diagnostics
        (S, Build_Source, Result);
      Assert (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "source visibility does not block storage");
      Assert (not Editor.Feature_Diagnostics.Source_Is_Visible
                (S.Feature_Diagnostics, Editor.Feature_Diagnostics.External_Diagnostic_Source),
              "build output ingestion preserves source visibility");
   end Test_Build_Run_Output_Preserves_Diagnostics_Source_Visibility;

   procedure Test_Build_Run_Output_Does_Not_Switch_Active_Feature_By_Default
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Run_Result;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Messages_Feature),
              "test can activate Messages");
      Result := Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Failed,
         Stderr_Text => "main.adb:1:1: error: no switch");
      Command := Editor.External_Producers.Ingest_Build_Run_Diagnostics
        (S, Build_Source, Result);
      Assert (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "build output diagnostic is ingested");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Messages_Feature,
              "build output ingestion preserves active feature by default");
   end Test_Build_Run_Output_Does_Not_Switch_Active_Feature_By_Default;

   procedure Test_Build_Run_Output_Can_Show_Diagnostics_When_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Run_Result;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Search_Results_Feature),
              "test can activate Search Results");
      Result := Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Succeeded,
         Stdout_Text => "main.adb:1:1: warning: explicit show");
      Command := Editor.External_Producers.Ingest_Build_Run_Diagnostics
        (S, Build_Source, Result, Show_Diagnostics => True);
      Assert (Command.Should_Show_Diagnostics,
              "explicit build-output ingestion can show Diagnostics");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Diagnostics_Feature,
              "explicit show uses existing feature-panel activation");
   end Test_Build_Run_Output_Can_Show_Diagnostics_When_Explicit;

   procedure Test_Build_Run_Output_Does_Not_Mutate_Unrelated_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Run_Result;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Outline_Before : Natural;
      Messages_Before : Natural;
      Search_Before : Natural;
   begin
      Prepare_State (S);
      Outline_Before := Editor.Outline.Item_Count (S.Outline);
      Messages_Before := Editor.Feature_Messages.Row_Count (S.Feature_Messages);
      Search_Before := Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results);
      Result := Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Failed,
         Stderr_Text => "main.adb:1:1: error: unrelated stable");
      Command := Editor.External_Producers.Ingest_Build_Run_Diagnostics
        (S, Build_Source, Result);
      Assert (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "build diagnostic is ingested");
      Assert (Editor.Outline.Item_Count (S.Outline) = Outline_Before,
              "build output ingestion does not mutate Outline");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = Messages_Before,
              "build output ingestion does not mutate Messages");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = Search_Before,
              "build output ingestion does not mutate Search Results");
   end Test_Build_Run_Output_Does_Not_Mutate_Unrelated_Features;

   procedure Test_Build_Command_Feedback_Succeeded_With_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diag : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Diag.Ingestion.Parse_Input_Count := 1;
      Diag.Ingestion.Parse_Accepted_Count := 1;
      Diag.Ingestion.Normalized_Count := 1;
      Diag.Ingestion.Ingestion_Result.Accepted_Count := 1;
      Assert (Editor.External_Producers.Build_Build_Command_Feedback
                (Editor.External_Producers.Build_Build_Run_Result
                   (Editor.External_Producers.Build_Run_Succeeded), Diag) =
                "Build: succeeded, ingested 1 diagnostics",
              "successful build feedback appends diagnostic count compactly");
   end Test_Build_Command_Feedback_Succeeded_With_Diagnostics;

   procedure Test_Build_Command_Feedback_Failed_With_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diag : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Diag.Ingestion.Parse_Input_Count := 3;
      Diag.Ingestion.Parse_Accepted_Count := 2;
      Diag.Ingestion.Normalized_Count := 2;
      Diag.Ingestion.Ingestion_Result.Accepted_Count := 2;
      Assert (Editor.External_Producers.Build_Build_Command_Feedback
                (Editor.External_Producers.Build_Build_Run_Result
                   (Editor.External_Producers.Build_Run_Failed,
                    Exit_Code => 1, Has_Exit_Code => True), Diag) =
                "Build: failed, ingested 2 diagnostics",
              "failed build feedback appends diagnostic count compactly");
   end Test_Build_Command_Feedback_Failed_With_Diagnostics;

   procedure Test_Build_Command_Feedback_No_Diagnostics_Parsed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diag : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Diag.Ingestion.Parse_Input_Count := 1;
      Assert (Editor.External_Producers.Build_Build_Command_Feedback
                (Editor.External_Producers.Build_Build_Run_Result
                   (Editor.External_Producers.Build_Run_Succeeded), Diag) =
                "Build: succeeded, no diagnostics parsed",
              "build feedback reports no parsed diagnostics for non-empty unparsed output");
   end Test_Build_Command_Feedback_No_Diagnostics_Parsed;

   procedure Test_Build_Command_Feedback_Execution_Error
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diag : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Assert (Editor.External_Producers.Build_Build_Command_Feedback
                (Editor.External_Producers.Build_Build_Run_Result
                   (Editor.External_Producers.Build_Run_Execution_Error), Diag) =
                "Build: execution error",
              "execution-error feedback is compact when no diagnostics are ingested");
      Diag.Ingestion.Parse_Input_Count := 1;
      Diag.Ingestion.Parse_Accepted_Count := 1;
      Diag.Ingestion.Normalized_Count := 1;
      Diag.Ingestion.Ingestion_Result.Accepted_Count := 1;
      Assert (Editor.External_Producers.Build_Build_Command_Feedback
                (Editor.External_Producers.Build_Build_Run_Result
                   (Editor.External_Producers.Build_Run_Execution_Error), Diag) =
                "Build: execution error, ingested 1 diagnostics",
              "execution-error feedback can append diagnostic ingestion count");
   end Test_Build_Command_Feedback_Execution_Error;

   procedure Test_Build_Command_Test_Seam_Rejected_Request_Is_Compact
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Command_Test_Seam
        (S, Build_Request (Tool => Editor.External_Producers.No_Build_Tool));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Rejected,
              "invalid build command test seam request is rejected safely");
      Assert (To_String (Result.Command_Message) = "Build: rejected",
              "rejected build test-seam command emits one compact primary message");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "rejected build test-seam command does not ingest diagnostics");
   end Test_Build_Command_Test_Seam_Rejected_Request_Is_Compact;

   procedure Test_Build_Command_Audit_Covers_Build_Run_Test_Seam
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.External_Producers.Build_Run_Test_Seam_Audit_Passes,
              "build-run test seam audit covers request, executor and extraction seams");
   end Test_Build_Command_Audit_Covers_Build_Run_Test_Seam;

   procedure Test_Producer_Audit_Covers_Build_Output_Ingestion_Seam
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Editor.External_Producers.Build_Run_Test_Seam_Audit_Passes,
              "producer audit includes build output diagnostic ingestion seam");
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Before = After,
              "build-run test seam audit is side-effect-free");
   end Test_Producer_Audit_Covers_Build_Output_Ingestion_Seam;

   function User_Request
     (Tool : Editor.External_Producers.Build_Tool_Kind :=
        Editor.External_Producers.GPRbuild_Tool;
      Program : String := "gprbuild";
      Working : String := "";
      Arg : String := "-q")
      return Editor.External_Producers.Build_Run_Request
   is
   begin
      if Arg'Length = 0 then
         return Editor.External_Producers.Build_User_Opt_In_Request
           (Tool, Program, Working,
            Editor.External_Producers.Empty_Process_Arguments);
      else
         return Editor.External_Producers.Build_User_Opt_In_Request
           (Tool, Program, Working,
            Editor.External_Producers.Build_Process_Argument_Vector (Arg));
      end if;
   end User_Request;

   procedure Test_User_Opt_In_Build_Default_Gate_Disables_Execution
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (User_Request, Editor.External_Producers.Build_Default_Execution_Gate);
   begin
      Assert (Result.Process_Request_Status =
                Editor.External_Producers.Process_Request_Rejected_Execution_Disabled,
              "default gate rejects user opt-in build execution");
      Assert (not Result.Has_Process_Request,
              "disabled user opt-in preflight exposes no process request");
      Assert (Result.Build_Request_Status =
                Editor.External_Producers.Build_Request_Rejected_Consent,
              "default user opt-in gate lacks execution consent");
      Assert (Editor.External_Producers.Build_User_Opt_In_Build_Feedback (Result) =
                "Build: execution consent required",
              "missing default consent feedback is deterministic");
   end Test_User_Opt_In_Build_Default_Gate_Disables_Execution;

   procedure Test_User_Opt_In_Build_Requires_User_Confirmed_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Missing : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (User_Request, Editor.External_Producers.Build_Real_Execution_Gate);
      Test_Only : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (User_Request,
           Editor.External_Producers.Build_Real_Execution_Gate
             (Consent => Editor.External_Producers.Build_Consent_Test_Only));
   begin
      Assert (Missing.Build_Request_Status =
                Editor.External_Producers.Build_Request_Rejected_Consent,
              "missing execution consent rejects user opt-in build preflight");
      Assert (not Missing.Has_Process_Request,
              "missing consent prepares no process request");
      Assert (Editor.External_Producers.Build_User_Opt_In_Build_Feedback (Missing) =
                "Build: execution consent required",
              "missing consent feedback is deterministic");
      Assert (Test_Only.Build_Request_Status =
                Editor.External_Producers.Build_Request_Rejected_Consent,
              "test-only consent cannot satisfy user opt-in real build preflight");
      Assert (not Test_Only.Has_Process_Request,
              "test-only consent prepares no user-build process request");
   end Test_User_Opt_In_Build_Requires_User_Confirmed_Consent;

   procedure Test_User_Opt_In_Build_Preflight_Returns_Process_Request_When_All_Gates_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (User_Request, Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed));
   begin
      Assert (Result.Build_Request_Status = Editor.External_Producers.Build_Request_Valid,
              "user opt-in provenance validates under explicit real gate");
      Assert (Result.Process_Request_Status = Editor.External_Producers.Process_Request_Valid,
              "structured user opt-in process request validates");
      Assert (Result.Has_Process_Request,
              "valid user opt-in preflight returns a process request");
      Assert (To_String (Result.Process_Request.Program_Label) = "gprbuild",
              "user opt-in process request preserves explicit program label");
      Assert (Result.Process_Request.Structured_Arguments.Length = 1,
              "user opt-in process request preserves structured argv");
   end Test_User_Opt_In_Build_Preflight_Returns_Process_Request_When_All_Gates_Pass;

   procedure Test_User_Opt_In_Build_Requires_User_Opt_In_Provenance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool          => Editor.External_Producers.GPRbuild_Tool,
         Provenance    => Editor.External_Producers.Build_Request_From_Internal_Command,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments =>
           Editor.External_Producers.Build_Process_Argument_Vector ("-q"));
      Result : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (Request, Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed));
   begin
      Assert (Result.Build_Request_Status =
                Editor.External_Producers.Build_Request_Rejected_Provenance,
              "internal command provenance cannot satisfy user opt-in preflight");
      Assert (Editor.External_Producers.Build_User_Opt_In_Build_Feedback (Result) =
                "Build: user opt-in required",
              "missing user opt-in provenance maps to compact feedback");
   end Test_User_Opt_In_Build_Requires_User_Opt_In_Provenance;

   procedure Test_User_Opt_In_Build_Rejects_Implicit_Source_Provenance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool          => Editor.External_Producers.Alire_Build_Tool,
         Provenance    => Editor.External_Producers.Build_Request_From_Implicit_Source,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("alr"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments =>
           Editor.External_Producers.Build_Process_Argument_Vector ("build"));
      Result : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (Request, Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed));
   begin
      Assert (Result.Build_Request_Status =
                Editor.External_Producers.Build_Request_Rejected_Implicit_Source,
              "implicit build source provenance remains rejected");
      Assert (Editor.External_Producers.Build_User_Opt_In_Build_Feedback (Result) =
                "Build: explicit build request required",
              "implicit build source rejection has deterministic feedback");
   end Test_User_Opt_In_Build_Rejects_Implicit_Source_Provenance;

   procedure Test_User_Opt_In_Build_Rejects_Unknown_Provenance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool          => Editor.External_Producers.GPRbuild_Tool,
         Provenance    => Editor.External_Producers.Build_Request_Unknown,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments =>
           Editor.External_Producers.Build_Process_Argument_Vector ("-q"));
      Result : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (Request, Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed));
   begin
      Assert (Result.Build_Request_Status =
                Editor.External_Producers.Build_Request_Rejected_Unknown_Provenance,
              "unknown provenance is rejected for user opt-in builds");
   end Test_User_Opt_In_Build_Rejects_Unknown_Provenance;

   procedure Test_User_Opt_In_Build_Rejects_Fixture_Provenance_Under_Real_Gate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool          => Editor.External_Producers.GPRbuild_Tool,
         Provenance    => Editor.External_Producers.Build_Request_From_Fixture,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments =>
           Editor.External_Producers.Build_Process_Argument_Vector ("-q"));
      Result : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (Request, Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed));
   begin
      Assert (Result.Build_Request_Status =
                Editor.External_Producers.Build_Request_Rejected_Provenance,
              "fixture provenance cannot satisfy user opt-in real gate");
   end Test_User_Opt_In_Build_Rejects_Fixture_Provenance_Under_Real_Gate;

   procedure Test_User_Opt_In_Build_Rejects_Custom_And_No_Tool
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Custom : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (User_Request (Tool => Editor.External_Producers.Custom_Build_Tool,
                         Program => "custom", Arg => "build"),
           Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed));
      None : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (User_Request (Tool => Editor.External_Producers.No_Build_Tool,
                         Program => "", Arg => ""),
           Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed));
   begin
      Assert (Custom.Build_Request_Status =
                Editor.External_Producers.Build_Request_Rejected_Unsupported_Tool,
              "custom build tool remains unsupported without structured configuration");
      Assert (Editor.External_Producers.Build_User_Opt_In_Build_Feedback (Custom) =
                "Build: custom build tool not supported",
              "custom tool feedback is deterministic");
      Assert (None.Build_Request_Status =
                Editor.External_Producers.Build_Request_Rejected_No_Tool,
              "No_Build_Tool remains rejected");
   end Test_User_Opt_In_Build_Rejects_Custom_And_No_Tool;

   procedure Test_User_Opt_In_Build_Rejects_Shell_Opaque_And_Working_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Shell_Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        (Process_Policy              => Real_Process_Policy (Allow_Shell => True),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => True,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Editor.External_Producers.Build_Consent_User_Confirmed,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
      Opaque_Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool          => Editor.External_Producers.GPRbuild_Tool,
         Provenance    => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q --not-split"),
         Structured_Arguments =>
           Editor.External_Producers.Build_Process_Argument_Vector ("-q"));
      Shell : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (User_Request, Shell_Gate);
      Opaque : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (Opaque_Request, Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed));
      Working : constant Editor.External_Producers.Build_Preflight_Result :=
        Editor.External_Producers.Preflight_User_Opt_In_Build_Request
          (User_Request (Working => "project-root"),
           Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed));
   begin
      Assert (Shell.Process_Request_Status =
                Editor.External_Producers.Process_Request_Rejected_Execution_Disabled,
              "shell-enabled gates do not pass user opt-in preflight");
      Assert (Opaque.Process_Request_Status =
                Editor.External_Producers.Process_Request_Rejected_Opaque_Arguments,
              "opaque argument text remains rejected");
      Assert (Editor.External_Producers.Build_User_Opt_In_Build_Feedback (Opaque) =
                "Build: structured arguments required",
              "opaque argument rejection does not expose argv or shell text");
      Assert (Working.Process_Request_Status =
                Editor.External_Producers.Process_Request_Rejected_Unsupported_Working_Directory,
              "unsupported working context rejects execution");
   end Test_User_Opt_In_Build_Rejects_Shell_Opaque_And_Working_Context;

   procedure Test_User_Opt_In_Build_Preflight_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Result : Editor.External_Producers.Build_Preflight_Result;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Result := Editor.External_Producers.Preflight_User_Opt_In_Build_Request
        (User_Request, Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed));
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Editor.External_Producers.User_Opt_In_Build_Preflight_Is_Consistent (Result),
              "user opt-in preflight consistency check passes");
      Assert (Before = After,
              "user opt-in preflight does not mutate feature panel state");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "user opt-in preflight does not ingest diagnostics");
   end Test_User_Opt_In_Build_Preflight_Is_Side_Effect_Free;

   procedure Test_User_Opt_In_Build_Preflight_Does_Not_Call_Runner
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_User_Opt_In_Build_Command_Test_Seam
        (S, User_Request (Working => "project-root"),
         Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed),
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Stderr_Text => "main.adb:1:1: error: must-not-run"));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Rejected,
              "invalid user opt-in preflight rejects before supplied runner result");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "rejected user opt-in command cannot ingest supplied output");
   end Test_User_Opt_In_Build_Preflight_Does_Not_Call_Runner;

   procedure Test_User_Opt_In_Build_Diagnostic_Output_Uses_Line_Pipeline_When_Test_Gated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_User_Opt_In_Build_Command_Test_Seam
        (S, User_Request, Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed),
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Failed,
            Exit_Code => 1, Has_Exit_Code => True,
            Stderr_Text => "main.adb:1:1: error: user opt-in diagnostic"));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Failed,
              "test-supplied user opt-in process failure maps to build failure");
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Input_Count = 1,
              "user opt-in output is parsed through diagnostic-line parser");
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "user opt-in output is ingested through Diagnostics API");
   end Test_User_Opt_In_Build_Diagnostic_Output_Uses_Line_Pipeline_When_Test_Gated;

   procedure Test_User_Opt_In_Build_Preserves_Unrelated_Features_And_Active_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Active_Before : Editor.Feature_Panel.Feature_Id;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Active_Before := Editor.Feature_Panel.Active_Feature (S.Feature_Panel);
      Result := Editor.External_Producers.Run_User_Opt_In_Build_Command_Test_Seam
        (S, User_Request, Editor.External_Producers.Build_Real_Execution_Gate (Consent => Editor.External_Producers.Build_Consent_User_Confirmed),
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Failed,
            Exit_Code => 1, Has_Exit_Code => True,
            Stderr_Text => "main.adb:1:1: warning: user opt-in"));
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "setup user opt-in diagnostic is accepted");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) = Active_Before,
              "user opt-in build command does not switch active feature by default");
      Assert (Editor.Outline.Item_Count (S.Outline) = 0,
              "user opt-in build command does not mutate Outline");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "user opt-in build command does not mutate Messages");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "user opt-in build command does not mutate Search Results");
   end Test_User_Opt_In_Build_Preserves_Unrelated_Features_And_Active_Feature;

   procedure Test_User_Opt_In_Build_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Editor.External_Producers.Audit_User_Opt_In_Build_Gates,
              "user opt-in build audit covers gates, provenance, argv, working context and feedback");
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Before = After,
              "user opt-in build audit does not mutate feature panel state");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "user opt-in build audit does not ingest diagnostics");
   end Test_User_Opt_In_Build_Audit_Is_Side_Effect_Free;

   procedure Test_User_Opt_In_Build_Command_Context_Constructs_Structured_Request
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        Editor.External_Producers.Build_User_Opt_In_Command_Context
          (Tool              => Editor.External_Producers.GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Editor.External_Producers.Build_Process_Argument_Vector ("-q"),
           Consent           => Editor.External_Producers.Build_Consent_User_Confirmed,
           Allow_Diagnostics => True,
           Show_Diagnostics  => False);
      Status : constant Editor.External_Producers.User_Opt_In_Build_Command_Context_Status :=
        Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
          (Context);
   begin
      Assert (Context.Has_Request,
              "user opt-in build command context records explicit structured request");
      Assert (Context.Request.Provenance =
                Editor.External_Producers.Build_Request_From_User_Opt_In,
              "command context sets explicit user opt-in provenance");
      Assert (Context.Gate.Consent =
                Editor.External_Producers.Build_Consent_User_Confirmed,
              "command context stores explicit user-confirmed consent");
      Assert (Length (Context.Request.Arguments) = 0,
              "command context stores no opaque shell arguments");
      Assert (Context.Request.Structured_Arguments.Length = 1,
              "command context preserves structured argv");
      Assert (Status = Editor.External_Producers.User_Build_Context_Valid,
              "command context validates through user opt-in command context classifier");
   end Test_User_Opt_In_Build_Command_Context_Constructs_Structured_Request;

   procedure Test_User_Opt_In_Build_Command_Rejects_Missing_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Execute_User_Opt_In_Build_Command
        (S, Editor.External_Producers.Empty_User_Opt_In_Build_Command_Context,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Stderr_Text => "main.adb:1:1: error: must-not-run"));
      Editor.External_Producers.Assert_User_Opt_In_Build_Command_Result_Consistent
        (Result);
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Rejected,
              "missing user opt-in command context rejects before runner result");
      Assert (To_String (Result.Command_Message) = "Build: user opt-in required",
              "missing context uses deterministic user opt-in feedback");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "missing context cannot ingest supplied diagnostic output");
   end Test_User_Opt_In_Build_Command_Rejects_Missing_Context;

   procedure Test_User_Opt_In_Build_Command_Context_Rejection_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Valid : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        Editor.External_Producers.Build_User_Opt_In_Command_Context
          (Tool              => Editor.External_Producers.GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Editor.External_Producers.Build_Process_Argument_Vector ("-q"),
           Consent           => Editor.External_Producers.Build_Consent_User_Confirmed,
           Allow_Diagnostics => True,
           Show_Diagnostics  => False);
      Missing_Request : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Editor.External_Producers.No_Build_Tool,
            Provenance           => Editor.External_Producers.Build_Request_Unknown,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => Null_Unbounded_String,
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments),
         Gate        => Valid.Gate);
      Missing_Gate : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        => Editor.External_Producers.Build_Default_Execution_Gate);
      Missing_Consent : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        => Editor.External_Producers.Build_Real_Execution_Gate
           (Consent => Editor.External_Producers.Build_Consent_Not_Provided));
      Test_Only_Consent : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        => Editor.External_Producers.Build_Real_Execution_Gate
           (Consent => Editor.External_Producers.Build_Consent_Test_Only));
      Project_Request : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Editor.External_Producers.GPRbuild_Tool,
            Provenance           => Editor.External_Producers.Build_Request_From_Implicit_Source,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      Fixture_Request : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Editor.External_Producers.GPRbuild_Tool,
            Provenance           => Editor.External_Producers.Build_Request_From_Fixture,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      Test_Request : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Editor.External_Producers.GPRbuild_Tool,
            Provenance           => Editor.External_Producers.Build_Request_From_Test,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      Custom_Tool : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Editor.External_Producers.Custom_Build_Tool,
            Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("custom"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      No_Tool : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Editor.External_Producers.No_Build_Tool,
            Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      Opaque : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Editor.External_Producers.GPRbuild_Tool,
            Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => To_Unbounded_String ("-q"),
            Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments),
         Gate        => Valid.Gate);
      Working : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Editor.External_Producers.GPRbuild_Tool,
            Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
            Working_Label        => To_Unbounded_String ("project-root"),
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
   begin
      Assert (Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
                (Editor.External_Producers.Empty_User_Opt_In_Build_Command_Context) =
              Editor.External_Producers.User_Build_Context_Rejected_Missing_Context,
              "missing context rejects before preflight");
      Assert (Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
                (Missing_Request) = Editor.External_Producers.User_Build_Context_Rejected_Missing_Request,
              "missing request rejects before preflight");
      Assert (Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
                (Missing_Gate) = Editor.External_Producers.User_Build_Context_Rejected_Missing_Gate,
              "missing gate rejects before runner selection");
      Assert (Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
                (Missing_Consent) = Editor.External_Producers.User_Build_Context_Rejected_Missing_Consent,
              "missing consent rejects before runner selection");
      Assert (Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
                (Test_Only_Consent) = Editor.External_Producers.User_Build_Context_Rejected_Missing_Consent,
              "test-only consent is not user-confirmed consent");
      Assert (Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
                (Project_Request) = Editor.External_Producers.User_Build_Context_Rejected_Implicit_Source,
              "implicit build source remains unreachable from command test seam");
      Assert (Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
                (Fixture_Request) = Editor.External_Producers.User_Build_Context_Rejected_Provenance,
              "fixture provenance cannot substitute for user opt-in provenance");
      Assert (Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
                (Test_Request) = Editor.External_Producers.User_Build_Context_Rejected_Provenance,
              "test provenance cannot substitute for user opt-in provenance");
      Assert (Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
                (Custom_Tool) = Editor.External_Producers.User_Build_Context_Rejected_Custom_Tool,
              "custom build tool remains rejected");
      Assert (Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
                (No_Tool) = Editor.External_Producers.User_Build_Context_Rejected_Custom_Tool,
              "missing concrete build tool remains rejected");
      Assert (Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
                (Opaque) = Editor.External_Producers.User_Build_Context_Rejected_Opaque_Arguments,
              "opaque arguments remain rejected");
      Assert (Editor.External_Producers.Validate_User_Opt_In_Build_Command_Context
                (Working) = Editor.External_Producers.User_Build_Context_Rejected_Working_Context,
              "project-derived working context remains rejected");
   end Test_User_Opt_In_Build_Command_Context_Rejection_Matrix;

   procedure Test_User_Opt_In_Build_Command_Invalid_Context_Does_Not_Mutate_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Result := Editor.External_Producers.Execute_User_Opt_In_Build_Command
        (S, Editor.External_Producers.Empty_User_Opt_In_Build_Command_Context,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Has_Exit_Code => True,
            Exit_Code     => 0,
            Stderr_Text   => "main.adb:1:1: error: must-not-ingest"));
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Editor.External_Producers.Assert_User_Opt_In_Build_Command_Result_Consistent
        (Result);
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Rejected,
              "invalid context returns a rejected command result");
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0,
              "invalid context does not ingest supplied output");
      Assert (Before = After,
              "invalid context does not switch or invalidate active feature state");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "invalid context leaves Diagnostics unchanged");
   end Test_User_Opt_In_Build_Command_Invalid_Context_Does_Not_Mutate_Features;

   procedure Test_User_Opt_In_Build_Command_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Empty_Result : constant Editor.External_Producers.Build_Command_Result :=
        (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
           (Editor.External_Producers.Build_Run_Rejected),
         Diagnostic_Result => Editor.External_Producers.Empty_Diagnostic_Line_Command_Result,
         Command_Message   => Null_Unbounded_String);
   begin
      Assert (Editor.External_Producers.Build_User_Opt_In_Command_Feedback
                (Editor.External_Producers.User_Build_Context_Rejected_Missing_Context,
                 Empty_Result) = "Build: user opt-in required",
              "missing context feedback is stable");
      Assert (Editor.External_Producers.Build_User_Opt_In_Command_Feedback
                (Editor.External_Producers.User_Build_Context_Rejected_Missing_Consent,
                 Empty_Result) = "Build: execution consent required",
              "missing consent feedback is stable");
      Assert (Editor.External_Producers.Build_User_Opt_In_Command_Feedback
                (Editor.External_Producers.User_Build_Context_Rejected_Opaque_Arguments,
                 Empty_Result) = "Build: structured arguments required",
              "opaque argument feedback does not expose argv");
      Assert (Editor.External_Producers.Build_User_Opt_In_Command_Feedback
                (Editor.External_Producers.User_Build_Context_Rejected_Working_Context,
                 Empty_Result) = "Build: working directory unsupported",
              "working-context feedback does not expose paths");
   end Test_User_Opt_In_Build_Command_Feedback_Is_Deterministic;

   procedure Test_Build_Execution_Consent_Audit_Passes_Default_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Execution_Consent_Audit_Result;
   begin
      Prepare_State (S);
      Result := Editor.External_Producers.Run_Build_Execution_Consent_Audit (S);
      Assert (Result.Passed,
              "build execution consent audit must pass default state");
      Assert (Result.Has_Public_Build_Command,
              "build.run public command is exposed through the guarded public surface");
      Assert (not Result.Has_Default_Build_Keybinding,
              "internal build test seam must not have a default keybinding");
      Assert (Result.Internal_Command_Requires_Context,
              "internal build test seam must require structured context");
      Assert (Result.Internal_Command_Requires_Provenance,
              "internal build test seam must require user opt-in provenance");
      Assert (Result.Internal_Command_Requires_Gate,
              "internal build test seam must require an explicit execution gate");
      Assert (Result.Internal_Command_Requires_Consent,
              "internal build test seam must require user-confirmed consent");
      Assert (Result.Rejects_Implicit_Source,
              "implicit build source requests must remain rejected");
      Assert (Result.Rejects_Custom_Tool,
              "custom build tool requests must remain rejected");
      Assert (Result.Rejects_Shell,
              "shell execution must remain rejected");
      Assert (Result.Rejects_Opaque_Arguments,
              "opaque argument strings must remain rejected");
      Assert (Result.Routes_Diagnostics_Through_Pipeline,
              "command-origin output must remain routed through diagnostic line pipeline");
   end Test_Build_Execution_Consent_Audit_Passes_Default_State;

   procedure Test_Build_Execution_Consent_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Panel : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After_Panel  : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Before_Diagnostics : Natural;
      After_Diagnostics  : Natural;
      Before_Messages : Natural;
      After_Messages  : Natural;
      Result : Editor.External_Producers.Build_Execution_Consent_Audit_Result;
   begin
      Prepare_State (S);
      Before_Panel := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Before_Diagnostics := Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Before_Messages := Editor.Feature_Messages.Row_Count (S.Feature_Messages);
      Result := Editor.External_Producers.Run_Build_Execution_Consent_Audit (S);
      After_Panel := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      After_Diagnostics := Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      After_Messages := Editor.Feature_Messages.Row_Count (S.Feature_Messages);

      Assert (Result.Passed,
              "side-effect audit must still pass");
      Assert (Before_Panel = After_Panel,
              "build execution consent audit must not mutate feature panel state");
      Assert (Before_Diagnostics = After_Diagnostics,
              "build execution consent audit must not ingest diagnostics");
      Assert (Before_Messages = After_Messages,
              "build execution consent audit must not post messages");
   end Test_Build_Execution_Consent_Audit_Is_Side_Effect_Free;

   procedure Test_Build_Command_Rejection_Matrix_Audit_Covers_Invalid_Cells
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.External_Producers.Audit_Build_Command_Rejection_Matrix,
              "rejection matrix audit must cover context, request, gate, consent, provenance, tool, argv, shell, working context, diagnostics policy, visibility policy, and execution ambiguity");
   end Test_Build_Command_Rejection_Matrix_Audit_Covers_Invalid_Cells;

   procedure Test_User_Opt_In_Build_Command_Surface_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Prepare_State (S);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Editor.External_Producers.Audit_User_Opt_In_Build_Command_Surface,
              "user opt-in build command audit covers context, gate, consent, argv and shell rejection");
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Before = After,
              "user opt-in build command audit is side-effect-free");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "user opt-in build command audit does not ingest diagnostics");
   end Test_User_Opt_In_Build_Command_Surface_Audit;

   overriding procedure Register_Tests
     (T : in out External_Producers_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_External_Producer_Identity_Is_Deterministic'Access,
                        "External producer identity is deterministic");
      Register_Routine (T, Test_External_Producer_Ingests_Diagnostics_Through_Diagnostics_API'Access,
                        "External producer ingests diagnostics through Diagnostics API");
      Register_Routine (T, Test_External_Producer_Ingests_Diagnostic_Edit_Metadata'Access,
                        "External producer ingests diagnostic edit metadata");
      Register_Routine (T, Test_External_Producer_Batch_Preserves_Input_Order'Access,
                        "External producer batch preserves input order");
      Register_Routine (T, Test_External_Producer_Invalid_Target_Becomes_Untargeted'Access,
                        "External producer invalid target becomes untargeted");
      Register_Routine (T, Test_External_Producer_Preserves_Diagnostics_Filter_State'Access,
                        "External producer preserves Diagnostics filter state");
      Register_Routine (T, Test_External_Producer_Applies_Diagnostics_Retention'Access,
                        "External producer applies Diagnostics retention");
      Register_Routine (T, Test_External_Producer_Does_Not_Switch_Active_Feature'Access,
                        "External producer does not switch active feature");
      Register_Routine (T, Test_External_Producer_Does_Not_Mutate_Unrelated_Features'Access,
                        "External producer does not mutate unrelated features");
      Register_Routine (T, Test_External_Producer_Does_Not_Revive_Stale_Projection_Token'Access,
                        "External producer does not revive stale projection token");
      Register_Routine (T, Test_External_Producer_Audit_Is_Side_Effect_Free'Access,
                        "External producer audit is side-effect-free");
      Register_Routine (T, Test_External_Producer_Rejects_Invalid_Metadata_Without_Mutation'Access,
                        "External producer rejects invalid metadata without mutation");
      Register_Routine (T, Test_Compiler_Diagnostic_Normalizes_Severity_Mapping'Access,
                        "Compiler diagnostic normalizes severity mapping");
      Register_Routine (T, Test_Compiler_Diagnostic_Resolves_Live_Buffer_Target'Access,
                        "Compiler diagnostic resolves live buffer target");
      Register_Routine (T, Test_Compiler_Diagnostic_Unresolved_File_Becomes_Untargeted'Access,
                        "Compiler diagnostic unresolved file becomes untargeted");
      Register_Routine (T, Test_Compiler_Diagnostic_Ambiguous_File_Becomes_Untargeted'Access,
                        "Compiler diagnostic ambiguous file becomes untargeted");
      Register_Routine (T, Test_Compiler_Diagnostic_Invalid_Location_Becomes_Untargeted'Access,
                        "Compiler diagnostic invalid location becomes untargeted");
      Register_Routine (T, Test_Compiler_Diagnostic_Batch_Preserves_Input_Order_And_Counts'Access,
                        "Compiler diagnostic batch preserves input order and counts");
      Register_Routine (T, Test_Compiler_Diagnostic_Ingestion_Uses_Diagnostics_API'Access,
                        "Compiler diagnostic ingestion uses Diagnostics API");
      Register_Routine (T, Test_Compiler_Diagnostic_Ingestion_Preserves_Filter_And_Feature'Access,
                        "Compiler diagnostic ingestion preserves filter and active feature");
      Register_Routine (T, Test_Compiler_Diagnostic_Ingestion_Does_Not_Mutate_Unrelated_Features'Access,
                        "Compiler diagnostic ingestion does not mutate unrelated features");
      Register_Routine (T, Test_Producer_Audit_Covers_Compiler_Diagnostic_Normalization'Access,
                        "Producer audit covers compiler diagnostic normalization");

      Register_Routine (T, Test_Diagnostic_Line_Parser_Accepts_Error_Line'Access,
                        "Diagnostic line parser accepts error line");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Accepts_Warning_Info_Fatal_And_Unknown'Access,
                        "Diagnostic line parser accepts warning info fatal and unknown");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Accepts_Note_And_GPRbuild_Tool_Line'Access,
                        "Diagnostic line parser accepts note and gprbuild tool line");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Classifies_GPRbuild_Tool_Severity'Access,
                        "Diagnostic line parser classifies gprbuild tool severity");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Ignores_Ordinary_GPRbuild_Tool_Chatter'Access,
                        "Diagnostic line parser ignores ordinary gprbuild chatter");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Is_Case_Insensitive'Access,
                        "Diagnostic line parser is case-insensitive");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Preserves_Message_With_Extra_Colon'Access,
                        "Diagnostic line parser preserves message with extra colon");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Accepts_Line_Only_And_Rejects_Bad_Column'Access,
                        "Diagnostic line parser accepts line-only and rejects bad column");
      Register_Routine (T, Test_Diagnostic_Line_Batch_Attaches_Bounded_Continuations'Access,
                        "Diagnostic line batch attaches bounded continuations");
      Register_Routine (T, Test_Diagnostic_Line_Batch_Stops_Continuation_After_Gaps'Access,
                        "Diagnostic line batch stops continuation after output gaps");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Ignores_Blank_And_Unrecognized'Access,
                        "Diagnostic line parser ignores blank and unrecognized lines");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Rejects_Malformed_Locations_And_Message'Access,
                        "Diagnostic line parser rejects malformed locations and empty message");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Windows_Drive_Label'Access,
                        "Diagnostic line parser accepts Windows drive-letter file label");
      Register_Routine (T, Test_Diagnostic_Line_Batch_Preserves_Order_And_Counts'Access,
                        "Diagnostic line batch preserves accepted order and counts");
      Register_Routine (T, Test_Diagnostic_Line_Batch_Empty_Input_Is_Deterministic'Access,
                        "Diagnostic line batch empty input is deterministic");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Tool_Name_Is_Propagated_And_Clean'Access,
                        "Diagnostic line parser tool name is propagated and clean");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Handles_Malformed_Edge_Cases'Access,
                        "Diagnostic line parser handles malformed edge cases");
      Register_Routine (T, Test_Diagnostic_Line_Parser_Does_Not_Mutate_Diagnostics'Access,
                        "Diagnostic line parser does not mutate Diagnostics");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_Uses_Normalization_And_Diagnostics_API'Access,
                        "Diagnostic line ingestion uses normalization and Diagnostics API");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_Result_Reports_Mixed_Batch_Counts'Access,
                        "Diagnostic line ingestion result reports mixed batch counts");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_Result_Formatting'Access,
                        "Diagnostic line ingestion result formatting");
      Register_Routine (T, Test_Diagnostic_Line_Command_Feedback_Mixed_Rejected_Count'Access,
                        "Diagnostic line command feedback mixed rejected count");
      Register_Routine (T, Test_Diagnostic_Line_Command_Ingestion_Does_Not_Switch_Active_Feature_By_Default'Access,
                        "Diagnostic line command ingestion does not switch active feature by default");
      Register_Routine (T, Test_Diagnostic_Line_Command_Ingestion_Can_Show_Diagnostics_When_Explicit'Access,
                        "Diagnostic line command ingestion can show Diagnostics when explicit");
      Register_Routine (T, Test_Diagnostic_Line_Command_Ingestion_Preserves_Diagnostics_Source_Visibility'Access,
                        "Diagnostic line command ingestion preserves Diagnostics source visibility");
      Register_Routine (T, Test_Diagnostic_Line_Command_Ingestion_Safe_After_Project_And_Workspace_Close'Access,
                        "Diagnostic line command ingestion safe after project and workspace close");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_Result_Consistency_For_Mixed_Batch'Access,
                        "Diagnostic line ingestion result consistency for mixed batch");
      Register_Routine (T, Test_Diagnostic_Line_Command_Feedback_Is_Stable'Access,
                        "Diagnostic line command feedback is stable");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_Repeated_Mixed_Batches'Access,
                        "Diagnostic line ingestion repeated mixed batches");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_Repeated_Malformed_Only_Batches'Access,
                        "Diagnostic line ingestion repeated malformed-only batches");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_With_Filter_Active_Preserves_Filter'Access,
                        "Diagnostic line ingestion with filter active preserves filter");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_With_Severity_Hidden_Preserves_Visibility'Access,
                        "Diagnostic line ingestion with severity hidden preserves visibility");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_After_Feature_Switch_Preserves_Active_Feature'Access,
                        "Diagnostic line ingestion after feature switch preserves active feature");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_After_Buffer_Close_Is_Safe'Access,
                        "Diagnostic line ingestion after buffer close is safe");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_After_Workspace_Close_Is_Safe'Access,
                        "Diagnostic line ingestion after workspace close is safe");
      Register_Routine (T, Test_Producer_Audit_Passes_After_Repeated_Line_Ingestion'Access,
                        "Producer audit passes after repeated line ingestion");
      Register_Routine (T, Test_Producer_Audit_Covers_Diagnostic_Line_Command_Surface'Access,
                        "Producer audit covers diagnostic line command surface");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_Preserves_Filter_Retention_And_Feature'Access,
                        "Diagnostic line ingestion preserves filter retention and active feature");
      Register_Routine (T, Test_Diagnostic_Line_Ingestion_Does_Not_Mutate_Unrelated_Features'Access,
                        "Diagnostic line ingestion does not mutate unrelated features");
      Register_Routine (T, Test_Producer_Audit_Covers_Diagnostic_Line_Parser'Access,
                        "Producer audit covers diagnostic line parser");
      Register_Routine (T, Test_Build_Timeout_Policy_Is_Explicit_And_Bounded'Access,
                        "build timeout policy is explicit and bounded");
      Register_Routine (T, Test_Build_Timeout_Result_Maps_To_Canonical_Status'Access,
                        "build timeout maps to canonical status");
      Register_Routine (T, Test_Build_Cancellation_Result_Maps_To_Canonical_Status'Access,
                        "build cancellation maps to canonical status");
      Register_Routine (T, Test_Build_Request_Rejects_No_Tool'Access,
                        "build request rejects no tool");
      Register_Routine (T, Test_Build_Request_Rejects_Empty_Command_Label'Access,
                        "build request rejects empty command label");
      Register_Routine (T, Test_Build_Request_Validation_Status_Is_Deterministic'Access,
                        "build request validation status is deterministic");
      Register_Routine (T, Test_Build_Request_Accepts_Supported_Tools'Access,
                        "build request accepts supported tools");
      Register_Routine (T, Test_Process_Request_Preparation_From_GPRbuild_Request'Access,
                        "process request preparation from gprbuild request");
      Register_Routine (T, Test_Process_Request_Preparation_From_Alire_Request'Access,
                        "process request preparation from alire request");
      Register_Routine (T, Test_Process_Request_Preparation_Rejects_Custom_Without_Config'Access,
                        "process request preparation rejects custom without config");
      Register_Routine (T, Test_Default_Process_Runner_Does_Not_Invoke_External_Tool'Access,
                        "default process runner does not invoke external tool");
      Register_Routine (T, Test_Test_Fed_Process_Runner_Returns_Supplied_Result'Access,
                        "test-fed process runner returns supplied result");
      Register_Routine (T, Test_Process_Result_Statuses_Map_To_Build_Statuses'Access,
                        "process result statuses map to build statuses");
      Register_Routine (T, Test_Process_Result_Stderr_Before_Stdout_Line_Extraction'Access,
                        "process result stderr before stdout line extraction");
      Register_Routine (T, Test_Build_Output_Stream_Capture_Mode_Is_Explicit'Access,
                        "build output stream capture mode is explicit");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Default_Gate_Disables_Execution'Access,
                        "real build-tool fixture default gate disables execution");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Requires_Explicit_Gate'Access,
                        "real build-tool fixture requires explicit gate");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Rejects_Unknown_Fixture'Access,
                        "real build-tool fixture rejects unknown fixture");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Rejects_Implicit_Source_Provenance'Access,
                        "real build-tool fixture rejects implicit build source provenance");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Accepts_User_Opt_In_With_Explicit_Gate'Access,
                        "real build-tool fixture accepts user opt-in with explicit gate");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Prepares_Alire_Version_Argv'Access,
                        "real build-tool fixture prepares alire version argv");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Rejects_Unsupported_Working_Context'Access,
                        "real build-tool fixture rejects unsupported working context");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Output_Uses_Diagnostic_Line_Pipeline'Access,
                        "real build-tool fixture output uses diagnostic line pipeline");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Version_Output_No_Diagnostics_Parsed'Access,
                        "real build-tool fixture version output no diagnostics parsed");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Audit_Is_Side_Effect_Free'Access,
                        "real build-tool fixture audit is side-effect-free");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Validation_Is_Side_Effect_Free'Access,
                        "real build-tool fixture validation is side-effect-free");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Rejected_Request_Does_Not_Call_Runner'Access,
                        "real build-tool fixture rejected request does not call runner");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Preflight_Result_Consistency_Valid'Access,
                        "real build-tool fixture valid preflight is consistent");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Preflight_Result_Consistency_Rejected'Access,
                        "real build-tool fixture rejected preflight is consistent");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Command_Result_Consistency_Succeeded'Access,
                        "real build-tool fixture succeeded command result is consistent");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Command_Result_Consistency_Failed'Access,
                        "real build-tool fixture failed command result is consistent");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Command_Result_Consistency_Unavailable'Access,
                        "real build-tool fixture unavailable command result is consistent");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Ingestion_Disabled_Preserves_Diagnostics'Access,
                        "real build-tool fixture disabled ingestion preserves Diagnostics");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Repeated_Run_Preserves_Filter_And_Feature'Access,
                        "real build-tool fixture repeated runs preserve filter and active feature");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Show_Diagnostics_Uses_Normal_Feature_Switch'Access,
                        "real build-tool fixture show diagnostics uses normal feature switch");
      Register_Routine (T, Test_Real_Build_Tool_Fixture_Audit_Passes_After_Repeated_Attempts'Access,
                        "real build-tool fixture audit passes after repeated attempts");
      Register_Routine (T, Test_Process_Fixture_Default_Gate_Disables_Execution'Access,
                        "process fixture default gate disables execution");
      Register_Routine (T, Test_Process_Fixture_Requires_Explicit_Gate'Access,
                        "process fixture requires explicit fixture request path");
      Register_Routine (T, Test_Process_Fixture_Build_Request_Does_Not_Select_Fixture'Access,
                        "process fixture mode does not convert build request to fixture");
      Register_Routine (T, Test_Process_Fixture_Rejects_Unknown_Fixture'Access,
                        "process fixture rejects unknown fixture");
      Register_Routine (T, Test_Process_Fixture_Rejects_Shell_Mode'Access,
                        "process fixture rejects shell mode");
      Register_Routine (T, Test_Process_Fixture_Arguments_Preserve_Order_And_Quoting'Access,
                        "process fixture argv preserves spaces quotes and metacharacters");
      Register_Routine (T, Test_Process_Fixture_Captures_Stderr_And_Exit_Code'Access,
                        "process fixture captures stderr and preserves exit code");
      Register_Routine (T, Test_Process_Fixture_Output_Limit_Is_Enforced'Access,
                        "process fixture output limit is enforced");
      Register_Routine (T, Test_Process_Fixture_Output_Uses_Diagnostic_Line_Pipeline'Access,
                        "process fixture output uses diagnostic-line pipeline");
      Register_Routine (T, Test_Process_Fixture_Blank_Line_Is_Ignored'Access,
                        "process fixture blank line is ignored");
      Register_Routine (T, Test_Process_Fixture_Mixed_Output_And_Extra_Colons'Access,
                        "process fixture mixed output preserves extra colons");
      Register_Routine (T, Test_Process_Fixture_Malformed_Line_Is_Counted'Access,
                        "process fixture malformed line is counted");
      Register_Routine (T, Test_Process_Fixture_Preserves_Filter_And_Feature_Default'Access,
                        "process fixture preserves filters and active feature by default");
      Register_Routine (T, Test_Process_Fixture_Show_Diagnostics_Explicitly_Switches_Feature'Access,
                        "process fixture explicit show diagnostics switches feature");
      Register_Routine (T, Test_Process_Fixture_Audit_Is_Side_Effect_Free'Access,
                        "process fixture audit is side-effect-free");
      Register_Routine (T, Test_Process_Fixture_Validation_Is_Side_Effect_Free'Access,
                        "process fixture validation is side-effect-free");
      Register_Routine (T, Test_Process_Fixture_Rejected_Request_Does_Not_Call_Runner'Access,
                        "process fixture rejected request does not call runner");
      Register_Routine (T, Test_Process_Fixture_Output_Over_Limit_Does_Not_Fabricate_Diagnostics'Access,
                        "process fixture output over limit fabricates no diagnostics");
      Register_Routine (T, Test_Process_Fixture_Nonzero_Exit_Can_Ingest_Diagnostics'Access,
                        "process fixture nonzero exit can ingest diagnostics");
      Register_Routine (T, Test_Process_Fixture_Ingestion_Disabled_Preserves_Diagnostics'Access,
                        "process fixture ingestion disabled preserves diagnostics state");
      Register_Routine (T, Test_Process_Fixture_Result_Consistency_Succeeded'Access,
                        "process fixture result consistency succeeded");
      Register_Routine (T, Test_Process_Fixture_Result_Consistency_Failed'Access,
                        "process fixture result consistency failed");
      Register_Routine (T, Test_Process_Fixture_Result_Consistency_Not_Available'Access,
                        "process fixture result consistency not available");
      Register_Routine (T, Test_Process_Fixture_Result_Consistency_Execution_Error'Access,
                        "process fixture result consistency execution error");
      Register_Routine (T, Test_Process_Fixture_Audit_Covers_Lifecycle'Access,
                        "process fixture audit covers lifecycle");
      Register_Routine (T, Test_Process_Fixture_Audit_Passes_After_Repeated_Runs'Access,
                        "process fixture audit passes after repeated runs");
      Register_Routine (T, Test_Process_Execution_Default_Mode_Is_Disabled'Access,
                        "process execution default mode is disabled");
      Register_Routine (T, Test_Process_Execution_Disabled_Mode_Does_Not_Run'Access,
                        "process execution disabled mode does not run");
      Register_Routine (T, Test_Process_Execution_Real_Mode_Must_Be_Explicit'Access,
                        "process execution real mode must be explicit");
      Register_Routine (T, Test_Process_Execution_Rejects_Shell_Mode'Access,
                        "process execution rejects shell mode");
      Register_Routine (T, Test_Process_Execution_Rejects_Opaque_Arguments_For_Real_Run'Access,
                        "process execution rejects opaque arguments for real run");
      Register_Routine (T, Test_Process_Execution_Structured_Arguments_Preserve_Order'Access,
                        "process execution structured arguments preserve order");
      Register_Routine (T, Test_Process_Request_Real_Validation_Rejects_Relative_Program_When_Required'Access,
                        "process request real validation rejects relative program when required");
      Register_Routine (T, Test_Build_Preparation_Does_Not_Split_Opaque_Arguments'Access,
                        "build preparation does not split opaque arguments");
      Register_Routine (T, Test_Preflight_Build_Request_Rejects_Invalid_Process_Request'Access,
                        "preflight rejects invalid process request");
      Register_Routine (T, Test_Preflight_Does_Not_Call_Runner'Access,
                        "preflight does not call runner");
      Register_Routine (T, Test_Process_Execution_Output_Limit_Is_Enforced'Access,
                        "process execution output limit is enforced");
      Register_Routine (T, Test_Process_Execution_Timeout_Field_Uses_Native_Supervisor'Access,
                        "process execution timeout field uses native supervisor");
      Register_Routine (T, Test_Gated_Real_Runner_Not_Available_When_Platform_Runner_Missing'Access,
                        "gated real runner not available when platform runner missing");
      Register_Routine (T, Test_Build_Command_Selects_Test_Fed_Runner_Deterministically'Access,
                        "build command selects test-fed runner deterministically");
      Register_Routine (T, Test_Build_Command_Selects_Default_Non_Executing_Runner_By_Default'Access,
                        "build command selects default disabled runner by default");
      Register_Routine (T, Test_Build_Command_Does_Not_Call_Runner_For_Invalid_Request'Access,
                        "build command does not call runner for invalid request");
      Register_Routine (T, Test_Build_Command_Real_Runner_Output_Uses_Line_Pipeline'Access,
                        "build command real runner output uses line pipeline");
      Register_Routine (T, Test_Build_Gate_Default_Disables_Execution'Access,
                        "build gate default disables execution");
      Register_Routine (T, Test_Build_Gate_Disabled_Does_Not_Call_Runner'Access,
                        "build gate disabled does not call runner");
      Register_Routine (T, Test_Build_Gate_Test_Fixture_Selects_Test_Runner'Access,
                        "build gate test fixture selects test runner");
      Register_Routine (T, Test_Build_Gate_Real_Mode_Must_Be_Explicit'Access,
                        "build gate real mode must be explicit");
      Register_Routine (T, Test_Build_Gate_Rejects_Ambiguous_Test_And_Real_Mode'Access,
                        "build gate rejects ambiguous test and real mode");
      Register_Routine (T, Test_Build_Gate_Rejects_Shell_Mode'Access,
                        "build gate rejects shell mode");
      Register_Routine (T, Test_Build_Gate_Rejects_Opaque_Arguments_For_Real'Access,
                        "build gate rejects opaque arguments for real execution");
      Register_Routine (T, Test_Build_Gate_Invalid_Build_Request_Does_Not_Call_Runner'Access,
                        "build gate invalid build request does not call runner");
      Register_Routine (T, Test_Build_Gate_Invalid_Process_Request_Does_Not_Call_Runner'Access,
                        "build gate invalid process request does not call runner");
      Register_Routine (T, Test_Build_Gate_Allows_Test_Fed_Result_When_Explicit'Access,
                        "build gate allows test-fed result when explicit");
      Register_Routine (T, Test_Build_Gate_Real_Runner_Executes_Version_Command'Access,
                        "build gate real runner executes version command");
      Register_Routine (T, Test_Build_Gate_Diagnostics_Ingestion_Disabled_Does_Not_Mutate_Diagnostics'Access,
                        "build gate diagnostics ingestion disabled does not mutate diagnostics");
      Register_Routine (T, Test_Build_Gate_Diagnostics_Ingestion_Enabled_Uses_Line_Pipeline'Access,
                        "build gate diagnostics ingestion enabled uses line pipeline");
      Register_Routine (T, Test_Build_Gate_Default_Does_Not_Switch_Active_Feature'Access,
                        "build gate default does not switch active feature");
      Register_Routine (T, Test_Build_Gate_Show_Diagnostics_Explicitly_Switches_Feature'Access,
                        "build gate show diagnostics explicitly switches feature");
      Register_Routine (T, Test_Build_Gate_Audit_Is_Side_Effect_Free'Access,
                        "build gate audit is side-effect-free");
      Register_Routine (T, Test_User_Opt_In_Build_Default_Gate_Disables_Execution'Access,
                        "user opt-in build default gate disables execution");
      Register_Routine (T, Test_User_Opt_In_Build_Requires_User_Confirmed_Consent'Access,
                        "user opt-in build requires user-confirmed consent");
      Register_Routine (T, Test_User_Opt_In_Build_Preflight_Returns_Process_Request_When_All_Gates_Pass'Access,
                        "user opt-in build preflight returns process request when all gates pass");
      Register_Routine (T, Test_User_Opt_In_Build_Requires_User_Opt_In_Provenance'Access,
                        "user opt-in build requires user opt-in provenance");
      Register_Routine (T, Test_User_Opt_In_Build_Rejects_Implicit_Source_Provenance'Access,
                        "user opt-in build rejects implicit build source provenance");
      Register_Routine (T, Test_User_Opt_In_Build_Rejects_Unknown_Provenance'Access,
                        "user opt-in build rejects unknown provenance");
      Register_Routine (T, Test_User_Opt_In_Build_Rejects_Fixture_Provenance_Under_Real_Gate'Access,
                        "user opt-in build rejects fixture provenance under real gate");
      Register_Routine (T, Test_User_Opt_In_Build_Rejects_Custom_And_No_Tool'Access,
                        "user opt-in build rejects custom and no tool");
      Register_Routine (T, Test_User_Opt_In_Build_Rejects_Shell_Opaque_And_Working_Context'Access,
                        "user opt-in build rejects shell opaque arguments and working context");
      Register_Routine (T, Test_User_Opt_In_Build_Preflight_Is_Side_Effect_Free'Access,
                        "user opt-in build preflight is side-effect-free");
      Register_Routine (T, Test_User_Opt_In_Build_Preflight_Does_Not_Call_Runner'Access,
                        "user opt-in build preflight does not call runner");
      Register_Routine (T, Test_User_Opt_In_Build_Diagnostic_Output_Uses_Line_Pipeline_When_Test_Gated'Access,
                        "user opt-in build diagnostic output uses line pipeline when test gated");
      Register_Routine (T, Test_User_Opt_In_Build_Preserves_Unrelated_Features_And_Active_Feature'Access,
                        "user opt-in build preserves unrelated features and active feature");
      Register_Routine (T, Test_User_Opt_In_Build_Audit_Is_Side_Effect_Free'Access,
                        "user opt-in build audit is side-effect-free");
      Register_Routine (T, Test_User_Opt_In_Build_Command_Context_Constructs_Structured_Request'Access,
                        "user opt-in build command context constructs structured request");
      Register_Routine (T, Test_User_Opt_In_Build_Command_Rejects_Missing_Context'Access,
                        "user opt-in build command rejects missing context");
      Register_Routine (T, Test_User_Opt_In_Build_Command_Context_Rejection_Matrix'Access,
                        "user opt-in build command context rejection matrix is complete");
      Register_Routine (T, Test_User_Opt_In_Build_Command_Invalid_Context_Does_Not_Mutate_Features'Access,
                        "user opt-in build command invalid context does not mutate features");
      Register_Routine (T, Test_User_Opt_In_Build_Command_Feedback_Is_Deterministic'Access,
                        "user opt-in build command feedback is deterministic");
      Register_Routine (T, Test_Build_Execution_Consent_Audit_Passes_Default_State'Access,
                        "build execution consent audit passes default state");
      Register_Routine (T, Test_Build_Execution_Consent_Audit_Is_Side_Effect_Free'Access,
                        "build execution consent audit is side-effect-free");
      Register_Routine (T, Test_Build_Command_Rejection_Matrix_Audit_Covers_Invalid_Cells'Access,
                        "build command rejection matrix audit covers invalid cells");
      Register_Routine (T, Test_User_Opt_In_Build_Command_Surface_Audit'Access,
                        "user opt-in build command surface audit is side-effect-free");
      Register_Routine (T, Test_Process_Runner_Audit_Covers_Execution_Gating'Access,
                        "process runner audit covers execution gating");
      Register_Routine (T, Test_Process_Runner_Audit_Covers_Structured_Argv_And_Preflight'Access,
                        "process runner audit covers structured argv and preflight");
      Register_Routine (T, Test_Process_Runner_Audit_Covers_Default_Non_Execution'Access,
                        "process runner audit covers default non-execution");
      Register_Routine (T, Test_Build_Test_Fed_Executor_Returns_Supplied_Result'Access,
                        "build test-fed executor returns supplied result");
      Register_Routine (T, Test_Build_Invalid_Request_Does_Not_Use_Test_Fed_Result'Access,
                        "invalid build request does not use test-fed result");
      Register_Routine (T, Test_Build_Run_Result_Empty_Output_Is_Deterministic'Access,
                        "build run result empty output is deterministic");
      Register_Routine (T, Test_Build_Run_Result_Failed_Run_Can_Carry_Diagnostic_Lines'Access,
                        "failed build run can carry diagnostic lines");
      Register_Routine (T, Test_Build_Result_Splits_Stderr_Before_Stdout'Access,
                        "build result splits stderr before stdout");
      Register_Routine (T, Test_Build_Result_Execution_Error_Can_Carry_Diagnostics'Access,
                        "build result execution error can carry diagnostics");
      Register_Routine (T, Test_Build_Run_Test_Seam_Does_Not_Invoke_External_Tool_By_Default'Access,
                        "build run test seam does not invoke external tool by default");
      Register_Routine (T, Test_Build_Run_Output_Ingests_Diagnostics_Through_Line_Pipeline'Access,
                        "build output ingests diagnostics through line pipeline");
      Register_Routine (T, Test_Build_Run_Output_Preserves_Diagnostics_Filter'Access,
                        "build output preserves diagnostic filter");
      Register_Routine (T, Test_Build_Run_Output_Preserves_Diagnostics_Severity_Visibility'Access,
                        "build output preserves diagnostic severity visibility");
      Register_Routine (T, Test_Build_Run_Output_Preserves_Diagnostics_Source_Visibility'Access,
                        "build output preserves diagnostic source visibility");
      Register_Routine (T, Test_Build_Run_Output_Does_Not_Switch_Active_Feature_By_Default'Access,
                        "build output does not switch active feature by default");
      Register_Routine (T, Test_Build_Run_Output_Can_Show_Diagnostics_When_Explicit'Access,
                        "build output can show Diagnostics when explicit");
      Register_Routine (T, Test_Build_Run_Output_Does_Not_Mutate_Unrelated_Features'Access,
                        "build output does not mutate unrelated features");
      Register_Routine (T, Test_Build_Command_Feedback_Succeeded_With_Diagnostics'Access,
                        "build command feedback succeeded with diagnostics");
      Register_Routine (T, Test_Build_Command_Feedback_Failed_With_Diagnostics'Access,
                        "build command feedback failed with diagnostics");
      Register_Routine (T, Test_Build_Command_Feedback_No_Diagnostics_Parsed'Access,
                        "build command feedback no diagnostics parsed");
      Register_Routine (T, Test_Build_Command_Feedback_Execution_Error'Access,
                        "build command feedback execution error");
      Register_Routine (T, Test_Build_Command_Test_Seam_Rejected_Request_Is_Compact'Access,
                        "build command test seam rejected request is compact");
      Register_Routine (T, Test_Build_Command_Audit_Covers_Build_Run_Test_Seam'Access,
                        "build command audit covers build-run test seam");
      Register_Routine (T, Test_Producer_Audit_Covers_Build_Output_Ingestion_Seam'Access,
                        "producer audit covers build-output ingestion seam");
   end Register_Tests;

end Editor.External_Producers.Tests;
