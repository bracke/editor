with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers; use type Ada.Containers.Count_Type;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Build_Diagnostics;
with Editor.Build_Diagnostics_Review_Audit;
with Editor.Build_Output_Details;
with Editor.Build_UI_Actions;
with Editor.Build_Result_Summary;
with Editor.Commands;
with Editor.Command_Execution;
with Editor.Executor;
with Editor.External_Producers;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.State;

package body Editor.Build_Diagnostics_Review.Tests is

   use type Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.External_Producers.Diagnostic_Line_Command_Outcome;
   use type Editor.Feature_Diagnostics.Diagnostic_Source_Kind;
   use type Editor.Feature_Panel.Feature_Id;

   overriding function Name
     (T : Build_Diagnostics_Review_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Build_Diagnostics_Review");
   end Name;

   function Contains (Text, Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index
        (Ada.Characters.Handling.To_Lower (Text),
         Ada.Characters.Handling.To_Lower (Pattern)) /= 0;
   end Contains;


   function Active_Caret_Line (S : Editor.State.State_Type) return Natural is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      if S.Carets.Length = 0 then
         return 0;
      end if;
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      return Row + 1;
   end Active_Caret_Line;

   function Active_Caret_Column (S : Editor.State.State_Type) return Natural is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      if S.Carets.Length = 0 then
         return 0;
      end if;
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      return Col + 1;
   end Active_Caret_Column;

   function Request return Editor.External_Producers.Build_Run_Request is
   begin
      return
        (Tool                 => Editor.External_Producers.GPRbuild_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => To_Unbounded_String ("current-project-root"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
   end Request;

   function Result_With_Diagnostic
      return Editor.External_Producers.Build_Run_Result
   is
   begin
      return Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Failed,
         Exit_Code     => 1,
         Has_Exit_Code => True,
         Stderr_Text   => "main.adb:1:1: error: reviewable");
   end Result_With_Diagnostic;

   procedure Ingest_One_Build_Diagnostic
     (S       : in out Editor.State.State_Type;
      Command : out Editor.External_Producers.Diagnostic_Line_Command_Result)
   is
   begin
      Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Request, Result_With_Diagnostic,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);
   end Ingest_One_Build_Diagnostic;

   procedure Test_Build_Diagnostics_Appear_As_Diagnostics_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Ingest_One_Build_Diagnostic (S, Command);

      Assert
        (Command.Outcome = Editor.External_Producers.Diagnostic_Line_Command_Succeeded,
         "build output ingestion succeeds through Diagnostics seam");
      Assert
        (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
         "build diagnostic is stored only as a Diagnostics-owned row");
      Assert
        (Editor.Feature_Diagnostics.Item_Source_Kind (S.Feature_Diagnostics, 1) =
           Editor.Feature_Diagnostics.External_Diagnostic_Source,
         "build diagnostic row keeps external Diagnostics source metadata");
      Assert
        (Contains
           (Editor.Feature_Diagnostics.Item_Source_Label (S.Feature_Diagnostics, 1),
            "build"),
         "build diagnostic row exposes a Diagnostics-owned build source label");
      Assert
        (Assert_Build_Diagnostics_Are_Diagnostics_Owned (S),
         "review helper accepts only Diagnostics-owned build rows");
   end Test_Build_Diagnostics_Appear_As_Diagnostics_Rows;

   procedure Test_Review_Uses_Existing_Diagnostics_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Review  : Build_Diagnostics_Review_Result;
   begin
      Ingest_One_Build_Diagnostic (S, Command);
      Review := Run_Build_Diagnostics_Review (S);

      Assert (Review.Review_Uses_Existing_Diagnostics,
              "build diagnostics are reviewable through existing Diagnostics projection");
      Assert
        (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
           Editor.Feature_Panel.Diagnostics_Feature,
         "show request reveals existing Diagnostics feature, not a build table");
      Assert
        (Review.Output_Details_Stores_No_Diagnostics_Rows,
         "output details boundary predicate is evaluated");
   end Test_Review_Uses_Existing_Diagnostics_Projection;

   procedure Test_Navigation_Uses_Diagnostics_Routes_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Assert_Build_Diagnostics_Navigation_Uses_Diagnostics_Routes,
         "navigation remains on existing Diagnostics command routes");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Diagnostics_Open_Selected) =
           "diagnostics.open-selected",
         "open selected route is Diagnostics-owned");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Build_Run) = "build.run",
         "build.run does not become a diagnostics navigation command");
   end Test_Navigation_Uses_Diagnostics_Routes_Only;

   procedure Test_Summary_And_Output_Store_No_Diagnostic_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current-project-root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Exit_Code => 1,
           Has_Exit_Code => True,
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 1,
           Has_Diagnostics_Count => True);
      Details : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status =>
             Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => Null_Unbounded_String,
           Stderr_Text => To_Unbounded_String ("main.adb:1:1: error: raw"),
           Exit_Code => 1,
           Has_Exit_Code => True);
   begin
      Assert
        (Summary.Diagnostics_Ingestion_Status =
           Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded
         and then Summary.Has_Diagnostics_Count
         and then Summary.Diagnostics_Count_If_Available = 1,
         "summary may retain only scalar Diagnostics ingestion status/count");
      Assert
        (Assert_Build_Summary_Stores_No_Diagnostics_Rows (Summary),
         "latest result summary does not own Diagnostics rows");
      Assert
        (Assert_Build_Output_Details_Stores_No_Diagnostics_Rows (Details),
         "bounded output details do not own Diagnostics rows");
   end Test_Summary_And_Output_Store_No_Diagnostic_Rows;

   procedure Test_Output_Details_Do_Not_Create_Diagnostics_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status =>
             Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => Null_Unbounded_String,
           Stderr_Text => To_Unbounded_String ("main.adb:1:1: error: raw only"),
           Exit_Code => 1,
           Has_Exit_Code => True);

      Assert
        (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
         "raw output details alone do not create Diagnostics rows");
      Assert
        (Assert_Build_Output_Details_Stores_No_Diagnostics_Rows
           (S.Latest_Build_Output_Details),
         "output details remain bounded text inspection only");
   end Test_Output_Details_Do_Not_Create_Diagnostics_Rows;

   procedure Test_Audit_Is_Coherent_And_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Before  : Natural;
      Audit   : Editor.Build_Diagnostics_Review_Audit.Build_Diagnostics_Review_Audit_Result;
   begin
      Ingest_One_Build_Diagnostic (S, Command);
      Before := Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Audit := Editor.Build_Diagnostics_Review_Audit.Run_Build_Diagnostics_Review_Audit (S);

      Assert (Audit.Coherent, "review audit is coherent");
      Assert (Audit.Audit_Side_Effect_Free,
              "audit observes review boundaries without mutating state");
      Assert
        (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = Before,
         "audit does not clear, append, or replace Diagnostics rows");
   end Test_Audit_Is_Coherent_And_Side_Effect_Free;

   procedure Test_Milestone_Helper_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Assert
        (Assert_Public_Build_Diagnostics_Review_Foundation_Coherent (S),
         "build diagnostics review foundation is coherent");
   end Test_Milestone_Helper_Coherent;


   procedure Test_Source_Metadata_Reliable_And_Non_Executable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      GPR_Request : constant Editor.External_Producers.Build_Run_Request := Request;
      Alire_Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.Alire_Build_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => To_Unbounded_String ("current-project-root"),
         Command_Label        => To_Unbounded_String ("alr"),
         Arguments            => To_Unbounded_String ("build"),
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
   begin
      Assert
        (Assert_Build_Diagnostics_Source_Metadata_Reliable (GPR_Request),
         "gprbuild build diagnostics source metadata is Diagnostics-owned display metadata only");
      Assert
        (Assert_Build_Diagnostics_Source_Metadata_Reliable (Alire_Request),
         "alire build diagnostics source metadata is Diagnostics-owned display metadata only");
      Assert
        (Build_Diagnostic_Source_Label (GPR_Request) = "Build / gprbuild",
         "source label identifies the external gprbuild diagnostic producer");
      Assert
        (Build_Diagnostic_Source_Label (Alire_Request) = "Build / alr",
         "source label identifies the external alr diagnostic producer");
   end Test_Source_Metadata_Reliable_And_Non_Executable;

   procedure Test_Success_And_Failure_Build_Diagnostics_Reliable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S1 : Editor.State.State_Type;
      S2 : Editor.State.State_Type;
      Success_Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Succeeded,
           Stdout_Text => "main.adb:2:3: warning: success diagnostic");
      Failure_Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stderr_Text => "main.adb:4:5: error: failed diagnostic");
      Success_Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Failure_Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Success_Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S1, Request, Success_Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);
      Failure_Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S2, Request, Failure_Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);

      Assert
        (Success_Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
         "successful builds with diagnostics ingest through Diagnostics");
      Assert
        (Failure_Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
         "failed builds with diagnostics ingest through Diagnostics");
      Assert
        (Assert_Build_Diagnostics_Are_Diagnostics_Owned (S1)
         and then Assert_Build_Diagnostics_Are_Diagnostics_Owned (S2),
         "success and failure rows remain Diagnostics-owned");
      Assert
        (Assert_Build_Diagnostics_Not_Build_Owned (S1)
         and then Assert_Build_Diagnostics_Not_Build_Owned (S2),
         "success and failure rows are not copied into Build UI/summary/output state");
   end Test_Success_And_Failure_Build_Diagnostics_Reliable;

   procedure Test_Stdout_Stderr_And_Mixed_Stream_Reliable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Mixed_Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stdout_Text => "main.adb:7:1: warning: stdout diagnostic",
           Stderr_Text => "main.adb:8:1: error: stderr diagnostic");
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Request, Mixed_Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);

      Assert
        (Command.Ingestion.Ingestion_Result.Accepted_Count = 2,
         "stdout and stderr diagnostic lines are both ingested by Diagnostics");
      Assert
        (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 2,
         "mixed stream diagnostics produce ordinary Diagnostics rows only");
      Assert
        (Assert_Build_Diagnostics_Truncated_Or_Partial_Output_Reliable (S, Command),
         "mixed stream review remains bounded and Diagnostics-owned");
   end Test_Stdout_Stderr_And_Mixed_Stream_Reliable;

   procedure Test_Zero_Malformed_And_Disabled_Output_Reliable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Zero_State : Editor.State.State_Type;
      Malformed_State : Editor.State.State_Type;
      Disabled_State : Editor.State.State_Type;
      Zero_Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Succeeded,
           Stdout_Text => "build completed without diagnostic rows");
      Malformed_Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stderr_Text => "main.adb:x:y: error: malformed location");
      Zero_Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Malformed_Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Disabled_Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Zero_Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (Zero_State, Request, Zero_Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);
      Malformed_Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (Malformed_State, Request, Malformed_Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);
      Disabled_Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (Disabled_State, Request, Result_With_Diagnostic,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_Disabled,
         Request_Show_Diagnostics => True);

      Assert
        (Assert_Build_Diagnostics_Zero_Output_Reliable (Zero_State, Zero_Command),
         "zero diagnostic output creates no build-local fallback diagnostics table");
      Assert
        (Assert_Build_Diagnostics_Malformed_Output_Reliable
           (Malformed_State, Malformed_Command),
         "malformed diagnostic output creates no build-local fallback diagnostics table");
      Assert
        (Assert_Build_Diagnostics_Zero_Output_Reliable
           (Disabled_State, Disabled_Command),
         "disabled diagnostics ingestion creates no build-local diagnostics state");
   end Test_Zero_Malformed_And_Disabled_Output_Reliable;

   procedure Test_Truncated_Timeout_And_Cancelled_Partial_Output_Reliable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Truncated_State : Editor.State.State_Type;
      Timeout_State : Editor.State.State_Type;
      Cancelled_State : Editor.State.State_Type;
      Truncated_Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Timeout_Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Cancelled_Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      for I in 1 .. Editor.Build_Diagnostics.Max_Build_Diagnostic_Input_Lines + 5 loop
         Lines.Append (To_Unbounded_String ("main.adb:1:1: warning: bounded"));
      end loop;

      Truncated_Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (Truncated_State, Request,
         Editor.External_Producers.Build_Build_Run_Result
           (Editor.External_Producers.Build_Run_Output_Truncated,
            Stdout_Truncated => True,
            Diagnostic_Lines => Lines),
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);
      Timeout_Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (Timeout_State, Request,
         Editor.External_Producers.Build_Build_Run_Result
           (Editor.External_Producers.Build_Run_Timed_Out,
            Stderr_Text => "main.adb:9:1: error: timeout partial",
            Output_Partial => True),
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);
      Cancelled_Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (Cancelled_State, Request,
         Editor.External_Producers.Build_Build_Run_Result
           (Editor.External_Producers.Build_Run_Cancelled,
            Stderr_Text => "main.adb:10:1: warning: cancellation partial",
            Output_Partial => True),
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);

      Assert
        (Truncated_Command.Ingestion.Parse_Input_Count =
           Editor.Build_Diagnostics.Max_Build_Diagnostic_Input_Lines,
         "truncated diagnostic ingestion is bounded before Diagnostics review");
      Assert
        (Assert_Build_Diagnostics_Truncated_Or_Partial_Output_Reliable
           (Truncated_State, Truncated_Command)
         and then Assert_Build_Diagnostics_Truncated_Or_Partial_Output_Reliable
           (Timeout_State, Timeout_Command)
         and then Assert_Build_Diagnostics_Truncated_Or_Partial_Output_Reliable
           (Cancelled_State, Cancelled_Command),
         "truncated, timed-out, and cancelled partial output remain Diagnostics-owned");
   end Test_Truncated_Timeout_And_Cancelled_Partial_Output_Reliable;

   procedure Test_Mixed_Build_And_Non_Build_Diagnostics_Review_Reliable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "existing editor diagnostic",
         Source_Label => "Editor diagnostic",
         Source_Kind  => Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
      Ingest_One_Build_Diagnostic (S, Command);

      Assert
        (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 2,
         "mixed build and non-build diagnostics share the Diagnostics row model");
      Assert
        (Assert_Build_Diagnostics_Mixed_Source_Review_Reliable (S),
         "mixed diagnostics remain reviewable through existing Diagnostics projection");
   end Test_Mixed_Build_And_Non_Build_Diagnostics_Review_Reliable;

   procedure Test_Summary_Output_Render_And_Frontdoors_Do_Not_Own_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Review : Build_Diagnostics_Review_Result;
   begin
      Ingest_One_Build_Diagnostic (S, Command);
      S.Latest_Build_Result := Editor.Build_Result_Summary.Build_Summary
        (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
         Invocation_Label => "build.run",
         Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
         Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
         Working_Context_Label => "current-project-root",
         Runner_Status_Label => "failed",
         Primary_Message => "Build failed",
         Diagnostics_Ingestion_Status =>
           Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
         Diagnostics_Count => 1,
         Has_Diagnostics_Count => True);
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => Null_Unbounded_String,
           Stderr_Text => To_Unbounded_String ("main.adb:1:1: error: raw text only"));
      Review := Run_Build_Diagnostics_Review (S);

      Assert
        (Review.Summary_Stores_No_Diagnostics_Rows
         and then Review.Output_Details_Stores_No_Diagnostics_Rows
         and then Review.Build_UI_Stores_No_Diagnostics_Rows,
         "summary, output details, and Build UI do not own Diagnostics rows");
      Assert
        (Review.Render_Parses_No_Build_Output
         and then Review.Command_Frontdoors_Do_Not_Ingest,
         "render, Command Palette, and keybindings do not parse or ingest build diagnostics");
      Assert
        (Assert_Build_Diagnostics_Not_Build_Owned (S),
         "build-owned diagnostics review state remains absent");
   end Test_Summary_Output_Render_And_Frontdoors_Do_Not_Own_Rows;

   procedure Test_Reliability_Milestone_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Assert
        (Assert_Public_Build_Diagnostics_Review_Reliability_Coherent (S),
         "build diagnostics review reliability milestone is coherent");
   end Test_Reliability_Milestone_Coherent;


   procedure Test_Canonical_Cleanup_Milestone_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Assert
        (Assert_Public_Build_Diagnostics_Review_Canonical_Coherent (S),
         "build diagnostics review cleanup canonicalization is coherent");
   end Test_Canonical_Cleanup_Milestone_Coherent;


   procedure Test_Final_Ownership_And_Ingestion_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Ingest_One_Build_Diagnostic (S, Command);

      Assert
        (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
         "fixture creates exactly one build diagnostic through the retained seam");
      Assert
        (Assert_Build_Diagnostics_Final_Owned_By_Diagnostics (S),
         "freezes build diagnostics as Diagnostics-owned rows only");
      Assert
        (Assert_Build_Diagnostics_Final_Ingestion_Only_Row_Creation (S),
         "freezes Diagnostics ingestion as the only row creation path");
      Assert
        (Assert_Build_Diagnostics_Final_No_Build_Local_Table (S),
         "freezes absence of any Build-local diagnostics table");
   end Test_Final_Ownership_And_Ingestion_Freeze;

   procedure Test_Final_Source_Review_And_Navigation_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Ingest_One_Build_Diagnostic (S, Command);

      Assert
        (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
         "final freeze source/review fixture creates one Diagnostics row");
      Assert
        (Assert_Build_Diagnostics_Final_Source_Metadata_Boundary (Request),
         "freezes source metadata as non-rerunnable Diagnostics metadata");
      Assert
        (Assert_Build_Diagnostics_Final_Review_Boundary (S),
         "freezes review, selection, and rendering ownership in Diagnostics");
      Assert
        (Assert_Build_Diagnostics_Final_Navigation_Boundary,
         "freezes navigation onto existing Diagnostics commands only");
      Assert
        (Assert_Build_Diagnostics_Final_No_Build_Specific_Navigation,
         "forbids build-specific diagnostics navigation commands");
   end Test_Final_Source_Review_And_Navigation_Freeze;

   procedure Test_Final_Summary_Output_Render_And_Persistence_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      S.Latest_Build_Result := Editor.Build_Result_Summary.Build_Summary
        (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
         Invocation_Label => "build.run",
         Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
         Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
         Working_Context_Label => "current-project-root",
         Runner_Status_Label => "failed",
         Primary_Message => "Build failed",
         Diagnostics_Ingestion_Status =>
           Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
         Diagnostics_Count => 1,
         Has_Diagnostics_Count => True);
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => Null_Unbounded_String,
           Stderr_Text => To_Unbounded_String ("main.adb:1:1: error: bounded text only"));

      Assert
        (S.Latest_Build_Result.Diagnostics_Ingestion_Status =
           Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded
         and then S.Latest_Build_Result.Has_Diagnostics_Count
         and then S.Latest_Build_Result.Diagnostics_Count_If_Available = 1,
         "summary retains only scalar Diagnostics ingestion status/count");
      Assert
        (Assert_Build_Summary_Final_Stores_No_Diagnostics_Rows
           (S.Latest_Build_Result),
         "freezes summary as scalar-only and not a Diagnostics owner");
      Assert
        (Assert_Build_Output_Details_Final_Stores_No_Diagnostics_Rows
           (S.Latest_Build_Output_Details),
         "freezes output details as bounded text only");
      Assert
        (Assert_Render_Final_Does_Not_Parse_Build_Diagnostics,
         "freezes render-time diagnostics parsing as absent");
      Assert
        (Assert_Build_Diagnostics_Final_Persistence_Excluded (S),
         "freezes persistence exclusion for build-local diagnostics review state");
   end Test_Final_Summary_Output_Render_And_Persistence_Freeze;

   procedure Test_Final_Audit_And_Lifecycle_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Before_Row_Count : Natural;
      Before_Selected  : Natural;
      Audit : Editor.Build_Diagnostics_Review_Audit.Build_Diagnostics_Review_Audit_Result;
   begin
      Ingest_One_Build_Diagnostic (S, Command);
      Assert
        (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
         "final freeze audit fixture creates one Diagnostics row");
      Before_Row_Count := Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Before_Selected := Editor.Feature_Panel.Selected_Row (S.Feature_Panel);
      Audit := Editor.Build_Diagnostics_Review_Audit.Run_Build_Diagnostics_Review_Audit (S);

      Assert (Audit.Coherent, "review audit remains coherent at final freeze");
      Assert (Audit.Audit_Side_Effect_Free,
              "audit remains side-effect-free at final freeze");
      Assert
        (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = Before_Row_Count
         and then Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = Before_Selected,
         "audit does not mutate Diagnostics rows or selection");
      Assert
        (Assert_Build_Diagnostics_Final_No_Build_Local_Selection (S),
         "lifecycle has no Build-local diagnostics selection to restore or clean");
   end Test_Final_Audit_And_Lifecycle_Freeze;

   procedure Test_Final_Milestone_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Assert
        (Assert_Public_Build_Diagnostics_Review_Final_Freeze_Coherent (S),
         "final build diagnostics review freeze is coherent");
   end Test_Final_Milestone_Coherent;



   procedure Test_Build_Diagnostics_Label_And_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Ingest_One_Build_Diagnostic (S, Command);

      Assert
        (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
         "fixture creates one build-produced Diagnostics row");
      Assert
        (Contains
           (Editor.Feature_Diagnostics.Item_Source_Label (S.Feature_Diagnostics, 1),
            "Build")
         and then Contains
           (Editor.Feature_Diagnostics.Item_Source_Label (S.Feature_Diagnostics, 1),
            "gprbuild"),
         "build-produced row shows a readable build/tool source label");
      Assert
        (Assert_Build_Diagnostics_Reviewable_In_Diagnostics_Surface (S),
         "build-produced Diagnostics rows are reviewable in the existing surface");
   end Test_Build_Diagnostics_Label_And_Surface;

   procedure Test_Valid_Build_Diagnostic_Navigates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Result : Editor.Command_Execution.Command_Execution_Result;
      Build_Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stderr_Text => "Untitled:2:3: error: navigable");
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF);

      Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Request, Build_Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);

      Assert
        (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
         "valid build diagnostic target is ingested as one Diagnostics row");
      Assert
        (Editor.Feature_Diagnostics.Item_Has_Target (S.Feature_Diagnostics, 1),
         "diagnostic row keeps a Diagnostics-owned valid buffer target");
      Assert
        (Assert_Build_Diagnostics_Navigate_Through_Diagnostics (S),
         "build diagnostic target is navigable through Diagnostics commands");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);

      Assert
        (Result.Status = Editor.Command_Execution.Command_Executed,
         "diagnostics-open-selected navigates the build-produced row");
      Assert
        (Active_Caret_Line (S) = 2 and then Active_Caret_Column (S) = 3,
         "Diagnostics navigation moves to the build diagnostic line and column");
   end Test_Valid_Build_Diagnostic_Navigates;

   procedure Test_Invalid_Build_Diagnostic_Uses_Diagnostics_Failure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "only one line");
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "invalid build target",
         Source_Label => "Build / gprbuild: Untitled",
         Source_Kind => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target => True,
         Target_Buffer => S.Registry_Token,
         Target_Line => 99,
         Target_Column => 1);
      Editor.Feature_Diagnostics.Project_Rows (S.Feature_Diagnostics, S.Feature_Panel);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);

      Assert
        (Result.Status = Editor.Command_Execution.Command_Unavailable,
         "invalid build diagnostic target fails through Diagnostics open-selected");
      Assert
        (Active_Caret_Line (S) = 1,
         "invalid build diagnostic target does not navigate directly from Build UI");
      Assert
        (Assert_Build_Diagnostics_Final_No_Build_Specific_Navigation,
         "invalid target does not introduce build-specific diagnostics navigation");
   end Test_Invalid_Build_Diagnostic_Uses_Diagnostics_Failure;

   procedure Test_Build_UI_Reveal_Uses_Diagnostics_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Result : Editor.Command_Execution.Command_Execution_Result;
   begin
      Ingest_One_Build_Diagnostic (Before, Command);
      After := Before;
      Result := Editor.Build_UI_Actions.Build_UI_Reveal_Diagnostics (After);

      Assert
        (Assert_Build_UI_Reveal_Diagnostics_Uses_Existing_Command
           (Before, After, Result),
         "Build UI reveal invokes the existing Diagnostics command without row payload");
      Assert
        (Editor.Feature_Diagnostics.Row_Count (After.Feature_Diagnostics) =
           Editor.Feature_Diagnostics.Row_Count (Before.Feature_Diagnostics),
         "Build UI reveal does not copy, select, or navigate Diagnostics rows directly");
   end Test_Build_UI_Reveal_Uses_Diagnostics_Command;



   procedure Test_Source_Label_Fallbacks_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Alr_Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.Alire_Build_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => To_Unbounded_String ("/private/project"),
         Command_Label        => To_Unbounded_String ("alr"),
         Arguments            => To_Unbounded_String ("build --raw-argv-forbidden"),
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
      Build_Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stderr_Text => "Untitled:1:1: error: alr label");
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha");
      Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Alr_Request, Build_Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);

      Assert
        (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
         "alr build diagnostic is ingested through the Diagnostics API");
      Assert
        (Contains
           (Editor.Feature_Diagnostics.Item_Source_Label (S.Feature_Diagnostics, 1),
            "Build / alr"),
         "build-produced alr diagnostics show the bounded build/tool source label");
      Assert
        (not Contains
           (Editor.Feature_Diagnostics.Item_Source_Label (S.Feature_Diagnostics, 1),
            "argv")
         and then not Contains
           (Editor.Feature_Diagnostics.Item_Source_Label (S.Feature_Diagnostics, 1),
            "private")
         and then Editor.Build_Diagnostics.Assert_Build_Diagnostic_Source_Display_Labels_Bounded,
         "source labels exclude raw argv, working context, consent, shell, and rerun payloads");
      Assert
        (Assert_Build_Diagnostics_Source_Labels_Practical (S),
         "source-label helper accepts only practical Diagnostics-owned labels");
   end Test_Source_Label_Fallbacks_Bounded;

   procedure Test_Mixed_Rows_Share_Diagnostics_Model
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "non-build warning",
         Source_Label => "Editor",
         Source_Kind => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target => True,
         Target_Buffer => S.Registry_Token,
         Target_Line => 1,
         Target_Column => 1);
      Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Request,
         Editor.External_Producers.Build_Build_Run_Result
           (Editor.External_Producers.Build_Run_Failed,
            Stderr_Text => "Untitled:2:1: error: mixed build"),
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);

      Assert
        (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
         "build diagnostic is appended beside an existing non-build diagnostic");
      Assert
        (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 2,
         "mixed build and non-build diagnostics live in one Diagnostics row store");
      Assert
        (Assert_Mixed_Build_And_Non_Build_Diagnostics_Share_Model (S),
         "mixed Diagnostics rows share one ordering, selection, and navigation model");
      Assert
        (Assert_Build_Diagnostics_Navigate_Through_Diagnostics (S),
         "build rows in a mixed list remain navigable through existing Diagnostics routes");
   end Test_Mixed_Rows_Share_Diagnostics_Model;

   procedure Test_Command_Frontdoors_Carry_No_Payload
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Ingest_One_Build_Diagnostic (S, Command);

      Assert
        (Assert_Command_Frontdoors_Carry_No_Diagnostic_Payload (S),
         "Command Palette and keybinding frontdoors expose canonical Diagnostics commands only");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Diagnostics_Open_Selected) =
           "diagnostics.open-selected",
         "Diagnostics open-selected remains the canonical navigation command");
      Assert
        (not Contains
           (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Build_Run),
            "diagnostic"),
         "build.run does not become a build-specific diagnostic navigation route");
   end Test_Command_Frontdoors_Carry_No_Payload;

   procedure Test_Audit_Covers_Navigation_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Before_Count : Natural;
      Audit : Editor.Build_Diagnostics_Review_Audit.Build_Diagnostics_Review_Audit_Result;
   begin
      Ingest_One_Build_Diagnostic (S, Command);
      Before_Count := Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Audit := Editor.Build_Diagnostics_Review_Audit.Run_Build_Diagnostics_Review_Audit (S);

      Assert (Audit.Source_Labels_Practical,
              "audit covers build diagnostic source-label boundary");
      Assert (Audit.Command_Frontdoors_Carry_No_Payload,
              "audit covers command palette/keybinding no-payload boundary");
      Assert (Audit.Navigation_Workflow_Coherent,
              "audit covers the coherent navigation workflow");
      Assert
        (Audit.Coherent
         and then Audit.Audit_Side_Effect_Free
         and then Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = Before_Count,
         "audit remains coherent and side-effect-free");
   end Test_Audit_Covers_Navigation_Workflow;

   procedure Test_Navigation_Workflow_Milestone_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Assert
        (Assert_Public_Build_Diagnostics_Navigation_Workflow_Coherent (S),
         "build Diagnostics navigation workflow is coherent");
   end Test_Navigation_Workflow_Milestone_Coherent;

   overriding procedure Register_Tests
     (T : in out Build_Diagnostics_Review_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Build_Diagnostics_Appear_As_Diagnostics_Rows'Access,
         "build diagnostics appear as Diagnostics-owned rows");
      Register_Routine
        (T, Test_Review_Uses_Existing_Diagnostics_Projection'Access,
         "review uses existing Diagnostics projection");
      Register_Routine
        (T, Test_Navigation_Uses_Diagnostics_Routes_Only'Access,
         "navigation uses existing Diagnostics routes only");
      Register_Routine
        (T, Test_Summary_And_Output_Store_No_Diagnostic_Rows'Access,
         "summary and output details store no Diagnostics rows");
      Register_Routine
        (T, Test_Output_Details_Do_Not_Create_Diagnostics_Rows'Access,
         "output details do not create Diagnostics rows");
      Register_Routine
        (T, Test_Audit_Is_Coherent_And_Side_Effect_Free'Access,
         "review audit is coherent and side-effect-free");
      Register_Routine
        (T, Test_Milestone_Helper_Coherent'Access,
         "milestone helper is coherent");
      Register_Routine
        (T, Test_Source_Metadata_Reliable_And_Non_Executable'Access,
         "source metadata is stable and non-executable");
      Register_Routine
        (T, Test_Success_And_Failure_Build_Diagnostics_Reliable'Access,
         "success and failure build diagnostics are reliable");
      Register_Routine
        (T, Test_Stdout_Stderr_And_Mixed_Stream_Reliable'Access,
         "stdout stderr and mixed stream diagnostics are reliable");
      Register_Routine
        (T, Test_Zero_Malformed_And_Disabled_Output_Reliable'Access,
         "zero malformed and disabled diagnostics are reliable");
      Register_Routine
        (T, Test_Truncated_Timeout_And_Cancelled_Partial_Output_Reliable'Access,
         "truncated timeout and cancelled partial diagnostics are reliable");
      Register_Routine
        (T, Test_Mixed_Build_And_Non_Build_Diagnostics_Review_Reliable'Access,
         "mixed build and non-build diagnostics review is reliable");
      Register_Routine
        (T, Test_Summary_Output_Render_And_Frontdoors_Do_Not_Own_Rows'Access,
         "summary output render and frontdoors do not own rows");
      Register_Routine
        (T, Test_Reliability_Milestone_Coherent'Access,
         "reliability milestone is coherent");
      Register_Routine
        (T, Test_Canonical_Cleanup_Milestone_Coherent'Access,
         "canonical cleanup milestone is coherent");
      Register_Routine
        (T, Test_Final_Ownership_And_Ingestion_Freeze'Access,
         "final ownership and ingestion freeze");
      Register_Routine
        (T, Test_Final_Source_Review_And_Navigation_Freeze'Access,
         "final source review and navigation freeze");
      Register_Routine
        (T, Test_Final_Summary_Output_Render_And_Persistence_Freeze'Access,
         "final summary output render and persistence freeze");
      Register_Routine
        (T, Test_Final_Audit_And_Lifecycle_Freeze'Access,
         "final audit and lifecycle freeze");
      Register_Routine
        (T, Test_Final_Milestone_Coherent'Access,
         "final milestone is coherent");

      Register_Routine
        (T, Test_Build_Diagnostics_Label_And_Surface'Access,
         "build diagnostics label and surface");
      Register_Routine
        (T, Test_Valid_Build_Diagnostic_Navigates'Access,
         "valid build diagnostic navigates");
      Register_Routine
        (T, Test_Invalid_Build_Diagnostic_Uses_Diagnostics_Failure'Access,
         "invalid build diagnostic uses Diagnostics failure");
      Register_Routine
        (T, Test_Build_UI_Reveal_Uses_Diagnostics_Command'Access,
         "Build UI reveal uses Diagnostics command");
      Register_Routine
        (T, Test_Source_Label_Fallbacks_Bounded'Access,
         "source label fallbacks are bounded");
      Register_Routine
        (T, Test_Mixed_Rows_Share_Diagnostics_Model'Access,
         "mixed rows share Diagnostics model");
      Register_Routine
        (T, Test_Command_Frontdoors_Carry_No_Payload'Access,
         "command frontdoors carry no diagnostic payload");
      Register_Routine
        (T, Test_Audit_Covers_Navigation_Workflow'Access,
         "audit covers navigation workflow");
      Register_Routine
        (T, Test_Navigation_Workflow_Milestone_Coherent'Access,
         "navigation workflow milestone is coherent");
   end Register_Tests;

end Editor.Build_Diagnostics_Review.Tests;
