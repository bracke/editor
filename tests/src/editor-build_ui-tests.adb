with Editor.Test_Temp;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Build_Public_Request;
with Editor.Build_UI;
with Editor.Build_UI_Actions;
with Editor.Build_UI_Panel_Layout;
with Editor.Build_Candidates;
with Editor.Build_Candidate_Refresh;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Build_Working_Context;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.External_Producers;
with Editor.Feature_Diagnostics;
with Editor.Feature_Diagnostics.Fixtures; use Editor.Feature_Diagnostics.Fixtures;
with Editor.Feature_Panel;
with Editor.Commands;
with Editor.State;
with Editor.Executor;
with Editor.Command_Execution;
with Editor.Command_Route_Audit;
with Editor.Input_Bridge;
with Editor.Keybindings;
with Editor.Render_Model;

use type Editor.Build_UI.Public_Build_UI_Validation_Status;
use type Editor.Build_UI.Public_Build_Tool_Selection;
use type Editor.Build_Working_Context.Build_Working_Context_Kind;
use type Editor.Build_Working_Context.Build_Working_Context_Validation_Status;
use type Editor.Build_Working_Context.Working_Context_Source_Kind;
use type Editor.External_Producers.Build_Request_Provenance;
use type Editor.External_Producers.Build_Tool_Kind;
use type Editor.Commands.Command_Id;
use type Editor.Command_Execution.Command_Execution_Status;
use type Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Status;
use type Editor.Build_UI.Build_UI_Build_Mode;
use type Editor.Build_UI.Build_UI_Output_Capture_Limit;
use type Editor.Build_UI_Panel_Layout.Build_UI_Panel_Zone;

package body Editor.Build_UI.Tests is

   function Key
     (Code : Editor.Keybindings.Key_Code) return Editor.Keybindings.Key_Chord
   is
   begin
      return
        (Key       => Code,
         Modifiers => (Ctrl => False, Shift => False,
                       Alt => False, Meta => False));
   end Key;

   function Ctrl_Key
     (Code : Editor.Keybindings.Key_Code) return Editor.Keybindings.Key_Chord
   is
   begin
      return
        (Key       => Code,
         Modifiers => (Ctrl => True, Shift => False,
                       Alt => False, Meta => False));
   end Ctrl_Key;

   overriding function Name
     (T : Build_UI_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Build_UI");
   end Name;

   function Ready_UI return Editor.Build_UI.Public_Build_UI_State
   is
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "demo.gpr");
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
   begin
      Editor.Build_UI.Show (S);
      Candidates.Append (Candidate);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (Candidate.Candidate_Id));
      Editor.Build_UI.Set_Show_Diagnostics_On_Result (S, True);
      Editor.Build_UI.Acknowledge_Consent (S);
      return S;
   end Ready_UI;


   function Ready_Alire_UI return Editor.Build_UI.Public_Build_UI_State
   is
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Alire_Candidate ("current-project-root");
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
   begin
      Editor.Build_UI.Show (S);
      Candidates.Append (Candidate);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (Candidate.Candidate_Id));
      Editor.Build_UI.Set_Show_Diagnostics_On_Result (S, True);
      Editor.Build_UI.Acknowledge_Consent (S);
      return S;
   end Ready_Alire_UI;

   function Two_Candidate_Focused_UI return Editor.Build_UI.Public_Build_UI_State
   is
      S : Editor.Build_UI.Public_Build_UI_State;
      First : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "first.gpr");
      Second : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "second.gpr");
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
   begin
      Editor.Build_UI.Focus (S);
      Candidates.Append (First);
      Candidates.Append (Second);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "refresh succeeded: 2 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (First.Candidate_Id));
      return S;
   end Two_Candidate_Focused_UI;

   procedure Test_Build_UI_State_Is_Transient_And_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_UI;
   begin
      Assert (S.Build_UI_Visible, "public build UI is explicitly visible");
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_GPRbuild,
              "build tool selection is explicit and bounded");
      Assert (Editor.Build_UI.Argument_Count (S.Structured_Arguments) > 0,
              "arguments are structured tokens");
      Assert (S.Show_Diagnostics_On_Result,
              "diagnostics display preference is explicit and transient");
      Assert (Editor.Build_UI.Assert_Build_UI_State_Is_Transient (S),
              "build UI state carries no raw shell or remembered-consent field");
   end Test_Build_UI_State_Is_Transient_And_Explicit;

   procedure Test_Build_UI_Panel_Layout_Hit_Test_Covers_Actions_And_Suppressed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Geometry : constant Editor.Build_UI_Panel_Layout.Build_UI_Panel_Geometry :=
        Editor.Build_UI_Panel_Layout.Layout
          (Viewport_Width       => 800,
           Text_Viewport_Y      => 18,
           Text_Viewport_Height => 180,
           Cell_H               => 18,
           Action_Count         => 3,
           Suppressed_Count     => 2);
      Hit : Editor.Build_UI_Panel_Layout.Build_UI_Panel_Hit;
   begin
      Assert (Geometry.X = 380 and then Geometry.W = 420,
              "Build UI panel geometry anchors to the right edge");
      Assert (Geometry.Total_Rows = 8
              and then Geometry.Action_Start_Row = 5
              and then Geometry.Suppressed_Header_Row = 2
              and then Geometry.Suppressed_Start_Row = 3,
              "Build UI panel geometry assigns stable action and suppressed rows");

      Hit := Editor.Build_UI_Panel_Layout.Hit_Test
        (Geometry, 18, Geometry.X + 8, Geometry.Y + (3 * 18) + 4);
      Assert (Hit.Zone = Editor.Build_UI_Panel_Layout.Build_UI_Panel_Suppressed_Row
              and then Hit.Row = 1,
              "Build UI panel hit test maps suppressed rows through shared layout");

      Hit := Editor.Build_UI_Panel_Layout.Hit_Test
        (Geometry, 18, Geometry.X + 8, Geometry.Y + (6 * 18) + 4);
      Assert (Hit.Zone = Editor.Build_UI_Panel_Layout.Build_UI_Panel_Action_Row
              and then Hit.Row = 2,
              "Build UI panel hit test maps action rows through shared layout");
   end Test_Build_UI_Panel_Layout_Hit_Test_Covers_Actions_And_Suppressed;

   procedure Test_Build_UI_Action_Row_Scroll_Keeps_Selection_Visible
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State;
   begin
      Editor.Build_UI.Set_Selected_Action_Row (S, 6, 8);
      Editor.Build_UI.Ensure_Selected_Action_Row_Visible
        (S, Count => 8, Visible_Count => 3);
      Assert (Editor.Build_UI.Action_Top_Row (S, 8, 3) = 4,
              "Build UI action scroll keeps selected row inside visible window");

      Editor.Build_UI.Scroll_Action_Rows
        (S, Count => 8, Visible_Count => 3, Amount => 10);
      Assert (Editor.Build_UI.Action_Top_Row (S, 8, 3) = 6,
              "Build UI action scroll clamps to last valid top row");

      Editor.Build_UI.Scroll_Action_Rows
        (S, Count => 8, Visible_Count => 3, Amount => -10);
      Assert (Editor.Build_UI.Action_Top_Row (S, 8, 3) = 1,
              "Build UI action scroll clamps to first row");
   end Test_Build_UI_Action_Row_Scroll_Keeps_Selection_Visible;

   procedure Test_Focused_Build_UI_Keyboard_Routes_Through_Input_Bridge
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      After : Editor.State.State_Type;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
      First_Index : Natural;
      Last_Index  : Natural;
   begin
      S.Build_UI := Two_Candidate_Focused_UI;
      for I in 1 .. 2 loop
         Editor.Feature_Diagnostics.Add_Diagnostic
           (S.Feature_Diagnostics,
            Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
            Message      => "suppressed keyboard" & Natural'Image (I),
            Source_Label => "src/main.adb",
            Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source);
      end loop;
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Assert
        (Editor.Feature_Diagnostics.Suppress_Selected_Diagnostic
           (S.Feature_Diagnostics, S.Feature_Panel),
         "fixture can suppress first Build UI keyboard diagnostic");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Assert
        (Editor.Feature_Diagnostics.Suppress_Selected_Diagnostic
           (S.Feature_Diagnostics, S.Feature_Panel),
         "fixture can suppress second Build UI keyboard diagnostic");
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Down));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (After.Build_UI, After.Latest_Build_Result,
         After.Latest_Build_Output_Details);
      First_Index := Snapshot.Candidates.First_Index;
      Last_Index := Snapshot.Candidates.Last_Index;
      Assert (Snapshot.Candidate_Count = 2,
              "focused Build UI key route preserves candidates");
      Assert (Snapshot.Candidates (Last_Index).Selected,
              "Down selects the next Build UI candidate through Input_Bridge");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Up));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (After.Build_UI, After.Latest_Build_Result,
         After.Latest_Build_Output_Details);
      First_Index := Snapshot.Candidates.First_Index;
      Last_Index := Snapshot.Candidates.Last_Index;
      Assert (Snapshot.Candidates (First_Index).Selected,
              "Up selects the previous Build UI candidate through Input_Bridge");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Delete));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (After.Build_UI, After.Latest_Build_Result,
         After.Latest_Build_Output_Details);
      First_Index := Snapshot.Candidates.First_Index;
      Last_Index := Snapshot.Candidates.Last_Index;
      Assert (not Snapshot.Candidates (First_Index).Selected
              and then not Snapshot.Candidates (Last_Index).Selected,
              "Delete clears the focused Build UI candidate selection");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Tab));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (After);
      Assert (Natural (Snapshot.Actions.Length) > 0
              and then Snapshot.Actions.Element
                (Snapshot.Actions.First_Index).Selected,
              "Tab selects the first focused Build UI action row");

      Editor.Feature_Diagnostics.Select_Suppressed_Diagnostic
        (After.Feature_Diagnostics, 2);
      Editor.Build_UI.Focus (After.Build_UI);
      Editor.Input_Bridge.Set_State_For_Test (After);

      Editor.Input_Bridge.Handle_Key_Chord
        (Ctrl_Key (Editor.Keybindings.Key_Up));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.Feature_Diagnostics.Selected_Suppressed_Diagnostic
           (After.Feature_Diagnostics) = 1,
         "Ctrl+Up moves focused Build UI suppressed diagnostic selection");

      Editor.Input_Bridge.Handle_Key_Chord
        (Ctrl_Key (Editor.Keybindings.Key_Down));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.Feature_Diagnostics.Selected_Suppressed_Diagnostic
           (After.Feature_Diagnostics) = 2,
         "Ctrl+Down moves focused Build UI suppressed diagnostic selection");

      Editor.Input_Bridge.Handle_Key_Chord
        (Ctrl_Key (Editor.Keybindings.Key_Enter));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
           (After.Feature_Diagnostics) = 1,
         "Ctrl+Enter restores selected suppressed diagnostic from focused Build UI");

      Editor.Input_Bridge.Handle_Key_Chord
        (Ctrl_Key (Editor.Keybindings.Key_Delete));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
           (After.Feature_Diagnostics) = 0,
         "Ctrl+Delete clears remaining suppressed diagnostics from focused Build UI");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Escape));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (not After.Build_UI.Build_UI_Focused,
              "Escape returns focused Build UI keyboard workflow to editor text");
   end Test_Focused_Build_UI_Keyboard_Routes_Through_Input_Bridge;

   procedure Test_Request_Changes_Invalidate_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_UI;
      Args : Editor.Build_UI.Build_UI_Argument_Vector :=
        Editor.Build_UI.Empty_Arguments;
   begin
      Assert (S.Consent_Acknowledged, "setup starts consented");
      Editor.Build_UI.Select_Tool (S, Editor.Build_UI.Build_UI_Alire);
      Assert (not S.Consent_Acknowledged, "tool change invalidates consent");

      S := Ready_UI;
      Editor.Build_UI.Append_Argument (Args, "build");
      Editor.Build_UI.Set_Structured_Arguments (S, Args);
      Assert (not S.Consent_Acknowledged, "argument change invalidates consent");

      S := Ready_UI;
      Editor.Build_UI.Set_Working_Context_Label (S, "active-workspace-root");
      Assert (not S.Consent_Acknowledged, "working context change invalidates consent");
   end Test_Request_Changes_Invalidate_Consent;

   procedure Test_Structured_Request_Conversion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_UI.Public_Build_UI_State := Ready_UI;
      C : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S);
   begin
      Assert (C.Status = Editor.Build_UI.Build_UI_Valid,
              "complete consented UI validates");
      Assert (C.Request.Provenance =
                Editor.External_Producers.Build_Request_From_User_Opt_In,
              "conversion preserves user-opt-in provenance");
      Assert (C.Request.Tool = Editor.External_Producers.GPRbuild_Tool,
              "conversion preserves bounded tool selection");
      Assert (To_String (C.Request.Arguments)'Length = 0,
              "conversion does not create opaque shell arguments");
      Assert (Editor.External_Producers.Process_Argument_Count
                (C.Request.Structured_Arguments) > 0,
              "conversion preserves structured argv");
   end Test_Structured_Request_Conversion;

   procedure Test_Unsafe_Arguments_And_Missing_Consent_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_UI;
      Args : Editor.Build_UI.Build_UI_Argument_Vector :=
        Editor.Build_UI.Empty_Arguments;
   begin
      Editor.Build_UI.Clear_Consent (S);
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Missing_Consent,
              "missing consent prevents public build request");

      S := Ready_UI;
      Editor.Build_UI.Append_Argument (Args, "-q; rm -rf tmp");
      Editor.Build_UI.Set_Structured_Arguments (S, Args);
      Editor.Build_UI.Acknowledge_Consent (S);
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Unsafe_Arguments,
              "shell-like argument form is rejected before conversion");
   end Test_Unsafe_Arguments_And_Missing_Consent_Are_Rejected;


   procedure Test_Working_Context_Model_Is_Explicit_Structured_And_Transient
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Project_Context : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Current_Project_Root ("current-project-root");
      Missing_Context : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.None;
      Unavailable_Context : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Unavailable ("No canonical project/workspace context");
   begin
      Assert (Project_Context.Kind =
                Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root,
              "project root context is an explicit bounded kind");
      Assert (Project_Context.Source_Kind =
                Editor.Build_Working_Context.Working_Context_Source_Canonical_Project,
              "project root context comes only from canonical project state");
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context
                (Project_Context) =
              Editor.Build_Working_Context.Build_Working_Context_Valid,
              "canonical project context validates without filesystem probing");
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context
                (Missing_Context) =
              Editor.Build_Working_Context.Build_Working_Context_Rejected_None,
              "missing context has deterministic unavailable status");
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context
                (Unavailable_Context) =
              Editor.Build_Working_Context.Build_Working_Context_Rejected_Unavailable,
              "unavailable context remains explicit and non-probing");
      Assert (Editor.Build_Working_Context.Assert_Build_Working_Context_Is_Transient
                (Project_Context),
              "working context is transient metadata");
      Assert (Editor.Build_Working_Context.Assert_Build_Working_Context_Does_Not_Probe_Filesystem
                (Project_Context),
              "working context model does not use filesystem discovery");
   end Test_Working_Context_Model_Is_Explicit_Structured_And_Transient;

   procedure Test_Working_Context_Rejects_Forbidden_Sources
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Raw : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Unsafe_Context
          (Editor.Build_Working_Context.Build_Working_Context_Unavailable,
           Editor.Test_Temp.Base & "/build", Editor.Build_Working_Context.Working_Context_Source_Raw_Text,
           Editor.Test_Temp.Base & "/build");
      Shell : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Unsafe_Context
          (Editor.Build_Working_Context.Build_Working_Context_Unavailable,
           "cd /tmp && alr build",
           Editor.Build_Working_Context.Working_Context_Source_Shell_Derived,
           Editor.Test_Temp.Base & "");
      Metadata : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Unsafe_Context
          (Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root,
           "project:alire.toml",
           Editor.Build_Working_Context.Working_Context_Source_Implicit_Derived,
           "project:alire.toml");
      Persisted : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Unsafe_Context
          (Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root,
           "remembered-cwd",
           Editor.Build_Working_Context.Working_Context_Source_Persisted,
           "remembered-cwd");
   begin
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context (Raw) =
                Editor.Build_Working_Context.Build_Working_Context_Rejected_Raw_Text,
              "raw cwd text is rejected");
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context (Shell) =
                Editor.Build_Working_Context.Build_Working_Context_Rejected_Shell_Derived,
              "shell-derived cwd is rejected");
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context (Metadata) =
                Editor.Build_Working_Context.Build_Working_Context_Rejected_Implicit_Derived,
              "implicit-derived cwd is rejected");
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context (Persisted) =
                Editor.Build_Working_Context.Build_Working_Context_Rejected_Persisted,
              "persisted working context is rejected");
   end Test_Working_Context_Rejects_Forbidden_Sources;

   procedure Test_Request_Conversion_Requires_Valid_Working_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_UI;
      C : Editor.Build_Public_Request.Public_Build_Request_Conversion_Result;
   begin
      S.Selected_Working_Context := Editor.Build_Working_Context.None;
      Editor.Build_UI.Acknowledge_Consent (S);
      C := Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S);
      Assert (C.Status = Editor.Build_UI.Build_UI_Rejected_Working_Context_Required,
              "missing working context blocks conversion");

      S := Ready_UI;
      S.Selected_Working_Context :=
        Editor.Build_Working_Context.Unavailable
          ("No canonical project/workspace context");
      Editor.Build_UI.Acknowledge_Consent (S);
      C := Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S);
      Assert (C.Status = Editor.Build_UI.Build_UI_Rejected_Working_Context_Unavailable,
              "unavailable working context blocks conversion");

      S := Ready_UI;
      S.Selected_Working_Context :=
        Editor.Build_Working_Context.Unsafe_Context
          (Editor.Build_Working_Context.Build_Working_Context_Unavailable,
           Editor.Test_Temp.Base & "/build",
           Editor.Build_Working_Context.Working_Context_Source_Raw_Text,
           Editor.Test_Temp.Base & "/build");
      Editor.Build_UI.Acknowledge_Consent (S);
      C := Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S);
      Assert (C.Status = Editor.Build_UI.Build_UI_Rejected_Unsafe_Working_Context,
              "raw directory text blocks conversion");
   end Test_Request_Conversion_Requires_Valid_Working_Context;

   procedure Test_Working_Context_Consent_Binds_Request_Identity
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_UI;
   begin
      Assert (S.Consent_Acknowledged, "setup is consented");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Valid,
              "ready state validates before request identity changes");

      S.Working_Context_Canonical_Path_If_Available := To_Unbounded_String ("tampered");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Valid,
              "render snapshot fields do not participate as mutable authority");

      S.Selected_Working_Context := Editor.Build_Working_Context.Current_Project_Root
        ("different-canonical-token");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Stale_Consent,
              "changing request working context after consent requires renewed consent");
   end Test_Working_Context_Consent_Binds_Request_Identity;

   procedure Test_Public_Build_Working_Context_Foundation_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_UI.Public_Build_UI_State := Ready_UI;
   begin
      Assert (Editor.Build_Public_Request.Assert_Public_Build_Working_Context_Foundation_Coherent
                (S),
              "working-context foundation is coherent");
   end Test_Public_Build_Working_Context_Foundation_Coherent;

   procedure Test_Build_Run_Command_Is_Public_But_Non_Executing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      S.Build_UI := Ready_UI;
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Build_Run) = "build.run",
              "build.run has a stable public command name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Build_Refresh_Candidates) =
              "build.refresh-candidates",
              "build refresh has a stable public command name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Build_Select_First_Candidate) =
              "build.select-first-candidate",
              "build select-first has a stable public command name");
      Assert (Editor.Commands.Is_Public_Build_Command
                (Editor.Commands.Command_Build_Run),
              "build.run is classified as the public build command");
      Assert (Editor.Commands.Is_Public_Build_Command
                (Editor.Commands.Command_Build_Refresh_Candidates),
              "build refresh is classified as a public build command");
      Assert (Editor.Commands.Is_Public_Build_Command
                (Editor.Commands.Command_Build_Select_First_Candidate),
              "build select-first is classified as a public build command");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Run);
      Assert (Result.Status = Editor.Command_Execution.Command_Unavailable,
              "build.run remains unavailable while execution backend is disabled");
   end Test_Build_Run_Command_Is_Public_But_Non_Executing;


   procedure Test_Build_UI_Operability_Actions_And_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Alire_Candidate ("current-project-root");
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
      procedure Assert_Command_Name
        (Stable_Name : String;
         Expected    : Editor.Commands.Command_Id;
         Context     : String)
      is
         Found : Boolean := False;
         Actual : constant Editor.Commands.Command_Id :=
           Editor.Commands.Command_Id_From_Stable_Name (Stable_Name, Found);
      begin
         Assert (Found and then Actual = Expected,
                 Context & " must resolve through the command registry");
      end Assert_Command_Name;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);
      Assert (S.Build_UI.Build_UI_Visible, "Build UI can be shown");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "showing Build UI does not acknowledge consent");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) = 0,
              "showing Build UI does not auto-select or discover candidates");

      Candidates.Append (Candidate);
      Editor.Build_UI.Set_Build_Candidates
        (S.Build_UI, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI_Actions.Build_UI_Select_First_Candidate (S);
      Assert (S.Build_UI.Candidate_Applied_To_Request,
              "first candidate selection applies candidate-derived request mode");
      Editor.Build_UI_Actions.Build_UI_Clear_Selected_Candidate (S);
      Editor.Build_UI_Actions.Build_UI_Select_Candidate
        (S, To_String (Candidate.Candidate_Id));
      Assert (S.Build_UI.Candidate_Applied_To_Request,
              "candidate selection applies candidate-derived request mode");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "candidate selection invalidates prior consent and does not auto-consent");

      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (Snapshot.Visible, "snapshot exposes visible Build UI");
      Assert (Snapshot.Candidate_Count = 1,
              "snapshot exposes candidate list from transient state");
      Assert (To_String (Snapshot.Candidate_Count_Label) = "1 build candidate",
              "snapshot exposes readable candidate count");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Snapshot.Selected_Candidate_Summary_Label),
                 "Selected candidate: Alire project: current-project-root | alire |") = 1,
              "snapshot exposes selected candidate summary");
      Assert (To_String (Snapshot.Candidate_Refresh_Action_Label) =
                "Refresh build candidates",
              "selected candidate state still exposes refresh action");
      Assert (To_String (Snapshot.Candidate_Refresh_Action_Command_Name) =
                "build.refresh-candidates",
              "selected candidate refresh action exposes its command name");
      Assert_Command_Name
        (To_String (Snapshot.Candidate_Refresh_Action_Command_Name),
         Editor.Commands.Command_Build_Refresh_Candidates,
         "Build candidate refresh action");
      Assert (Natural (Snapshot.Actions.Length) >= 3,
              "Build UI exposes stable action rows");
      Assert (To_String (Snapshot.Actions.Element (0).Label) =
                "Refresh build candidates",
              "Build UI first action row exposes refresh/select");
      Assert (To_String (Snapshot.Actions.Element (0).Command_Name) =
                "build.refresh-candidates",
              "Build UI first action row exposes command name");
      Assert (Snapshot.Actions.Element (0).Enabled,
              "Build UI refresh action row is enabled while visible");
      Assert (To_String (Snapshot.Actions.Element (1).Command_Name) =
                "build.acknowledge-consent",
              "Build UI consent action row exposes command name");
      Assert (Snapshot.Actions.Element (1).Enabled,
              "Build UI consent action row is enabled before acknowledgement");
      Assert (To_String (Snapshot.Actions.Element (2).Command_Name) =
                "build.run",
              "Build UI run action row exposes command name");
      Assert (not Snapshot.Actions.Element (2).Enabled,
              "Build UI run action row is disabled before consent");
      Assert (To_String (Snapshot.Actions.Element (2).Disabled_Reason)'Length > 0,
              "Build UI disabled run row explains why it is unavailable");
      Assert (To_String (Snapshot.Request_Preview.Request_Mode_Label) =
                "candidate-derived",
              "snapshot exposes request mode");
      Assert (To_String (Snapshot.Request_Preview.Tool_Kind_Label) = "alire",
              "snapshot exposes structured tool kind");
      Assert (Editor.Build_UI.Argument_Count
                (Snapshot.Request_Preview.Argv_Tokens) = 1,
              "snapshot exposes structured argv tokens");
      Assert (Snapshot.Consent_Required,
              "snapshot exposes consent-required state");
      Assert (To_String (Snapshot.Run_Availability_Label)'Length > 0,
              "snapshot exposes build.run availability reason");
      Assert (To_String (Snapshot.Next_Action_Label) =
                "Next: review request and acknowledge consent",
              "snapshot exposes next action before consent");

      Editor.Build_UI_Actions.Build_UI_Acknowledge_Consent (S);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (Snapshot.Consent_Acknowledged,
              "explicit Build UI consent acknowledgement is visible");
      Assert (Snapshot.Request_Valid,
              "valid request state is exposed separately from command execution availability");
      Assert (not Snapshot.Run_Command_Available,
              "disabled execution backend is exposed separately from request validity");
      Assert (To_String (Snapshot.Request_Status_Label) = "Build request valid",
              "request status label is visible separately");
      Assert (To_String (Snapshot.Request_Action_Command_Name) =
                "build.acknowledge-consent",
              "request row exposes the consent action command name");
      Assert (To_String (Snapshot.Run_Action_Command_Name) = "build.run",
              "run row exposes the build.run action command name");
      Assert_Command_Name
        (To_String (Snapshot.Request_Action_Command_Name),
         Editor.Commands.Command_Build_Acknowledge_Consent,
         "Build request action");
      Assert_Command_Name
        (To_String (Snapshot.Run_Action_Command_Name),
         Editor.Commands.Command_Build_Run,
         "Build run action");
      Assert (Snapshot.Actions.Element (2).Enabled,
              "Build UI run action row is enabled once the request is valid");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Snapshot.Run_Command_Status_Label),
                 "Run command unavailable:") = 1,
              "run command status label explains executor availability separately");
      Assert (To_String (Snapshot.Next_Action_Label) = "Next: run build",
              "snapshot exposes run as next action after valid consented request");
      Editor.Build_UI_Actions.Build_UI_Clear_Consent (S);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (Snapshot.Consent_Required,
              "explicit Build UI consent clearing is visible");
   end Test_Build_UI_Operability_Actions_And_Snapshot;

   procedure Test_Build_UI_Refresh_And_Run_Use_Canonical_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.State.State_Type;
      Result : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Run_Result : Editor.Command_Execution.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);
      Before := S;
      Result := Editor.Build_UI_Actions.Build_UI_Refresh_Candidates
        (S, Editor.Build_Working_Context.Unavailable
              ("No canonical project/workspace context"));
      Assert (Result.Status =
                Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_No_Project_Context,
              "Build UI refresh calls canonical refresh path and reports no project");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Does_Not_Auto_Select
                (Before.Build_UI, S.Build_UI, Result),
              "Build UI refresh does not auto-select");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Does_Not_Auto_Consent
                (Before.Build_UI, S.Build_UI),
              "Build UI refresh does not auto-consent");

      Before := S;
      Run_Result := Editor.Build_UI_Actions.Build_UI_Run_Build (S);
      Assert (Run_Result.Status = Editor.Command_Execution.Command_Unavailable,
              "Build UI Run respects Executor availability");
      Assert (Editor.Build_UI_Actions.Assert_Build_UI_Run_Routes_Through_Executor
                (Before, S, Run_Result),
              "Build UI Run dispatches canonical build.run through Executor");
   end Test_Build_UI_Refresh_And_Run_Use_Canonical_Boundaries;

   procedure Test_Build_UI_Diagnostic_Actions_Are_UI_Routed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result;
   begin
      Editor.State.Init (S);

      Before := S;
      Result := Editor.Build_UI_Actions.Build_UI_Open_Diagnostic_Source (S);
      Assert (Result.Command = Editor.Commands.Command_Diagnostic_Open_Source,
              "Build UI open diagnostic source uses the diagnostic open-source command");
      Assert (Editor.Build_UI_Actions.Assert_Build_UI_Diagnostic_Action_Is_UI_Routed
                (Before, S, Result),
              "Build UI open diagnostic source routes through UI action facade");

      Before := S;
      Result := Editor.Build_UI_Actions.Build_UI_Suppress_Diagnostic (S);
      Assert (Result.Command = Editor.Commands.Command_Diagnostic_Suppress_Selected,
              "Build UI suppress diagnostic uses the diagnostic suppress command");
      Assert (Editor.Build_UI_Actions.Assert_Build_UI_Diagnostic_Action_Is_UI_Routed
                (Before, S, Result),
              "Build UI suppress diagnostic remains command-routed when unavailable");

      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "suppressed diagnostic",
         Source_Label  => "build",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => False,
         Target_Buffer => 0,
         Target_Line   => 0,
         Target_Column => 0);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "setup should create one suppressible diagnostic");

      Before := S;
      Result := Editor.Build_UI_Actions.Build_UI_Suppress_Diagnostic (S);
      Assert (Result.Command = Editor.Commands.Command_Diagnostic_Suppress_Selected
              and then Result.Status = Editor.Command_Execution.Command_Executed,
              "Build UI suppress diagnostic removes the selected diagnostic through Executor");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "suppressed diagnostic should be removed from session diagnostics");
      Assert (Editor.Build_UI_Actions.Assert_Build_UI_Diagnostic_Action_Is_UI_Routed
                (Before, S, Result),
              "Build UI suppress diagnostic keeps build result/output state isolated");

      Before := S;
      Result := Editor.Build_UI_Actions.Build_UI_Apply_Diagnostic_Quick_Fix (S);
      Assert (Result.Command = Editor.Commands.Command_Diagnostic_Apply_Quick_Fix,
              "Build UI quick fix uses the diagnostic quick-fix command");
      Assert (Editor.Build_UI_Actions.Assert_Build_UI_Diagnostic_Action_Is_UI_Routed
                (Before, S, Result),
              "Build UI quick fix remains routed and non-mutating");
   end Test_Build_UI_Diagnostic_Actions_Are_UI_Routed;

   procedure Test_Build_UI_Result_And_Output_Snapshot_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);
      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Summary_From_Unavailable_Message
          ("execution backend disabled");
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           To_Unbounded_String ("stdout excerpt"),
           To_Unbounded_String ("stderr excerpt"),
           Stdout_Truncated => True,
           Stderr_Truncated => False,
           Output_Partial => True);

      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (Snapshot.Latest_Result.Latest_Build_Result_Visible,
              "Build UI snapshot projects latest result summary");
      Assert (Snapshot.Output_Details.Output_Details_Available,
              "Build UI snapshot projects bounded output details");
      Assert (To_String (Snapshot.Output_Details.Stdout_Excerpt) =
                "stdout excerpt",
              "Build UI snapshot exposes bounded stdout excerpt");
      Assert (To_String (Snapshot.Output_Details.Stderr_Excerpt) =
                "stderr excerpt",
              "Build UI snapshot exposes bounded stderr excerpt");
      Assert (Editor.Build_UI_Actions.Assert_Build_UI_Does_Not_Persist_Transient_State
                (S),
              "Build UI projection preserves persistence exclusions");
   end Test_Build_UI_Result_And_Output_Snapshot_Projection;


   procedure Test_Render_Model_Projects_Build_UI_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);
      Editor.Build_UI.Select_Tool (S.Build_UI, Editor.Build_UI.Build_UI_GPRbuild);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Build_UI.Visible,
              "render model consumes Build UI snapshot");
      Assert (To_String (Snap.Build_UI.Request_Preview.Tool_Kind_Label) =
                "gprbuild",
              "render model projects Build UI request preview without mutation");
      Assert (To_String (Snap.Build_UI.Run_Recovery_Hint) =
                "Refresh build candidates and select one",
              "render model projects visible Build recovery guidance");
      Assert (Editor.Build_UI.Assert_Build_Diagnostics_Surface_Is_Renderable
                (Editor.Build_UI.Build_Diagnostics_Surface_For (Snap.Build_UI)),
              "render model projects renderable Build/Diagnostics surface");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "render snapshot does not acknowledge consent");
   end Test_Render_Model_Projects_Build_UI_Snapshot;

   procedure Test_Build_UI_Commands_Are_Public_And_Executor_Routed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result;
      Found : Boolean := False;
      Id : Editor.Commands.Command_Id;
   begin
      Editor.State.Init (S);
      Id := Editor.Commands.Command_Id_From_Stable_Name ("build.ui.show", Found);
      Assert (Found and then Id = Editor.Commands.Command_Build_UI_Show,
              "build.ui.show has a stable command id");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_UI_Show);
      Assert (Result.Status = Editor.Command_Execution.Command_Executed,
              "Build UI show is routed through Executor");
      Assert (S.Build_UI.Build_UI_Visible,
              "Build UI show command makes the Build UI visible");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "Build UI show command does not acknowledge consent");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) = 0,
              "Build UI show command does not discover or auto-select candidates");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_UI_Focus);
      Assert (Result.Status = Editor.Command_Execution.Command_Executed,
              "Build UI focus is routed through Executor");
      Assert (S.Build_UI.Build_UI_Visible and then S.Build_UI.Build_UI_Focused,
              "Build UI focus command shows and focuses the panel");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_UI_Hide);
      Assert (Result.Status = Editor.Command_Execution.Command_Executed,
              "Build UI hide is routed through Executor");
      Assert (not S.Build_UI.Build_UI_Visible,
              "Build UI hide command hides the panel");
   end Test_Build_UI_Commands_Are_Public_And_Executor_Routed;

   procedure Test_Build_UI_Row_Actions_Are_Route_Audited
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;

      procedure Check (Command : Editor.Commands.Command_Id) is
      begin
         Editor.Command_Route_Audit.Record_Command_UI_Route
           (Result                   => Audit,
            Source                   => Editor.Command_Route_Audit.Route_From_Feature_Panel,
            Command                  => Command,
            Dispatch_Count           => 1,
            Routed_Through_Executor  => True,
            Used_Stable_Command_Name => True,
            Availability_Checked     => True,
            Carried_Payload          => False);
      end Check;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Check (Editor.Commands.Command_Build_Refresh_Candidates);
      Check (Editor.Commands.Command_Build_Acknowledge_Consent);
      Check (Editor.Commands.Command_Build_Run);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "Build UI row actions should remain stable Executor routes: "
              & Editor.Command_Route_Audit.Summary (Audit));
   end Test_Build_UI_Row_Actions_Are_Route_Audited;


   procedure Test_Result_Output_Diagnostics_UI_Usability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
      Saw_Restore_Row : Boolean := False;
      Saw_Restore_Selected_Context : Boolean := False;
      Saw_Quick_Fix_Reason : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);
      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Candidate_Derived,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Exit_Code => 1,
           Has_Exit_Code => True,
           Stdout_Truncated => True,
           Output_Partial => False,
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 2,
           Has_Diagnostics_Count => True,
           Diagnostics_Error_Count => 1,
           Diagnostics_Warning_Count => 1,
           Has_Diagnostics_Severity_Counts => True,
           Duration_Milliseconds => 1250,
           Has_Duration => True);
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           To_Unbounded_String ("bounded stdout"),
           To_Unbounded_String ("bounded stderr"),
           Stdout_Truncated => True);

      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (To_String (Snapshot.Latest_Result.Latest_Build_Result_Status_Label) =
                "Build failed",
              "Build UI shows understandable latest result status");
      Assert (To_String (Snapshot.Latest_Result_Summary_Row_Label) =
                "Build failed | build.run | gprbuild | candidate-derived request | exit 1 | duration 1.3 s | diagnostics 2 | output truncated",
              "Build UI exposes the latest result as a panel summary row");
      Assert (To_String (Snapshot.Latest_Result.Latest_Build_Result_Command_Label) =
                "build.run",
              "Build UI exposes the command label");
      Assert (To_String (Snapshot.Latest_Result.Latest_Build_Result_Request_Mode_Label) =
                "candidate-derived request",
              "Build UI exposes the request mode");
      Assert (To_String (Snapshot.Latest_Result.Latest_Build_Result_Duration_Label) =
                "duration 1.3 s",
              "Build UI exposes build duration");
      Assert (To_String (Snapshot.Latest_Result.Latest_Build_Result_Runner_Status_Label) =
                "failed",
              "Build UI shows runner status");
      Assert (To_String (Snapshot.Latest_Result.Latest_Build_Result_Diagnostics_Label) =
                "Diagnostics produced: 2 (errors 1, warnings 1, info 0, notes 0, unknown 0)",
              "Build UI shows Diagnostics scalar count");
      Assert (To_String (Snapshot.Latest_Result.Latest_Build_Result_Error_Count_Label) =
                "errors 1"
              and then To_String
                (Snapshot.Latest_Result.Latest_Build_Result_Warning_Count_Label) =
                "warnings 1",
              "Build UI exposes separate error and warning counts");
      Assert (To_String (Snapshot.Output_Details.Stdout_Excerpt) =
                "bounded stdout"
              and then To_String (Snapshot.Output_Details.Stderr_Excerpt) =
                "bounded stderr",
              "Build UI exposes bounded stdout/stderr excerpts");
      Assert (To_String (Snapshot.Output_Details.Stdout_Truncation_Label) =
                "stdout truncated",
              "Build UI distinguishes stdout truncation");
      Assert (Snapshot.Diagnostics_View.Reveal_Available
              and then To_String (Snapshot.Diagnostics_View.Reveal_Command_Name) =
                "diagnostics.show"
              and then To_String (Snapshot.Diagnostics_View.Reveal_Label) =
                "Show 2 diagnostics",
              "Build UI reveal uses existing Diagnostics command with a jump label");
      Assert (To_String (Snapshot.Diagnostics_View.Open_Source_Command_Name) =
                "ada.diagnostic.open-source"
              and then To_String (Snapshot.Diagnostics_View.Suppress_Command_Name) =
                "ada.diagnostic.suppress"
              and then To_String (Snapshot.Diagnostics_View.Quick_Fix_Command_Name) =
                "ada.diagnostic.apply-quick-fix",
              "Build UI diagnostics actions use shared diagnostic command names");
      Assert (not Snapshot.Diagnostics_View.Open_Source_Available
              and then not Snapshot.Diagnostics_View.Suppress_Available,
              "Build UI diagnostic actions require live selectable diagnostics, not only a build summary count");
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "selected build diagnostic",
         Source_Label => "build",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Assert
        (Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
           (S.Feature_Diagnostics, S.Feature_Panel, 1,
            Editor.Feature_Panel.Projection_Generation (S.Feature_Panel)) = 1,
         "fixture diagnostic row should map to the first diagnostics source row");
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (Snapshot.Diagnostics_View.Suppress_Available
              and then not Snapshot.Diagnostics_View.Open_Source_Available,
              "Build UI suppress follows selected diagnostics while open source still requires a target");
      Assert (not Snapshot.Diagnostics_View.Quick_Fix_Available
              and then To_String
                (Snapshot.Diagnostics_View.Quick_Fix_Unavailable_Reason)'Length > 0,
              "Build UI quick-fix action exposes an unavailable reason until a fix is selected");
      Assert (To_String (Snapshot.Diagnostics_View.Action_Summary_Label) =
                "Actions: reveal, open source, suppress, restore, clear, quick fix",
              "Build UI diagnostics action summary should be product-facing");

      Assert
        (Editor.Feature_Diagnostics.Suppress_Selected_Diagnostic
           (S.Feature_Diagnostics, S.Feature_Panel),
         "fixture diagnostic can be suppressed for Build UI suppressed action rows");
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      for I in Snapshot.Actions.First_Index .. Snapshot.Actions.Last_Index loop
         declare
            Row : constant Editor.Build_UI.Build_UI_Action_Row :=
              Snapshot.Actions.Element (I);
         begin
            if To_String (Row.Command_Name) = "ada.diagnostic.restore-suppressed" then
               Saw_Restore_Row := True;
            elsif To_String (Row.Command_Name) =
              "ada.diagnostic.restore-selected-suppressed"
              and then Ada.Strings.Fixed.Index
                (To_String (Row.Label), "selected build diagnostic") > 0
            then
               Saw_Restore_Selected_Context := True;
            elsif To_String (Row.Command_Name) = "ada.diagnostic.apply-quick-fix"
              and then not Row.Enabled
              and then Length (Row.Disabled_Reason) > 0
            then
               Saw_Quick_Fix_Reason := True;
            end if;
         end;
      end loop;
      Assert (Saw_Restore_Row
              and then Saw_Restore_Selected_Context
              and then Saw_Quick_Fix_Reason,
              "Build UI action rows expose restore state and quick-fix disabled reasons");

      Editor.State.Load_Text
        (S,
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null" & ASCII.LF &
         "end Demo;" & ASCII.LF);
      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "missing semicolon",
         Source_Label => "semantic",
         Source_Kind  => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target   => True,
         Target_Buffer => 1,
         Target_Line   => 3,
         Target_Column => 8,
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic,
         Has_Edit          => True,
         Edit_Start_Line   => 3,
         Edit_Start_Column => 8,
         Edit_End_Line     => 3,
         Edit_End_Column   => 8,
         Replacement_Text  => ";");
      Assert (Editor.Feature_Diagnostics.Item_Has_Edit (S.Feature_Diagnostics, 1),
              "fixture diagnostic should retain edit metadata at ingestion");
      Assert (Editor.Feature_Diagnostics.Item_Quick_Fix_Label
                (S.Feature_Diagnostics, 1) = "",
              "fixture diagnostic should have no producer quick-fix label");
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Assert
        (Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
           (S.Feature_Diagnostics, S.Feature_Panel, 1,
            Editor.Feature_Panel.Projection_Generation (S.Feature_Panel)) = 1,
         "fixture diagnostic row should map to the first diagnostics source row");
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (To_String (Snapshot.Diagnostics_View.Quick_Fix_Label) =
                "Apply quick fix: Explain diagnostic"
              and then To_String (Snapshot.Diagnostics_View.Quick_Fix_Detail) =
                "Edit 3:8-3:8, replacement 1 chars",
              "Build UI quick-fix action exposes selected edit metadata");
      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "missing with clause",
         Source_Label => "semantic",
         Source_Kind  => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target   => True,
         Target_Buffer => 1,
         Target_Line   => 5,
         Target_Column => 1,
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic,
         Has_Edit          => True,
         Edit_Start_Line   => 5,
         Edit_Start_Column => 1,
         Edit_End_Line     => 5,
         Edit_End_Column   => 1,
         Replacement_Text  => "with Ada.Text_IO;",
         Quick_Fix_Label   => "Add missing context clause",
         Quick_Fix_Detail  => "Insert Ada.Text_IO dependency");
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Assert
        (Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Count
           (S.Feature_Diagnostics, 1) = 1,
         "Diagnostics exposes the selected quick-fix action explicitly");
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (To_String (Snapshot.Diagnostics_View.Quick_Fix_Label) =
                "Add missing context clause"
              and then To_String (Snapshot.Diagnostics_View.Quick_Fix_Detail) =
                "Insert Ada.Text_IO dependency",
              "Build UI prefers producer-provided quick-fix metadata");
      Assert (Editor.Build_UI_Actions.Assert_Public_Build_Result_Output_UI_Coherent
                (S),
              "result/output/diagnostics UI remains coherent and transient");
   end Test_Result_Output_Diagnostics_UI_Usability;

   procedure Test_No_Output_And_Partial_Output_Are_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);
      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Timed_Out,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_Alire_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "timed out",
           Primary_Message => "Build timed out",
           Timed_Out => True,
           Output_Partial => True,
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_No_Diagnostics);
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_No_Output_State
          (Editor.Build_Output_Details.Build_Output_Runner_Timed_Out);

      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (To_String (Snapshot.Output_Details.No_Output_Label) =
                "No build output captured.",
              "Build UI shows no-output state explicitly");
      Assert (To_String (Snapshot.Output_Details.Stdout_No_Output_Label) =
                "No stdout captured."
              and then To_String (Snapshot.Output_Details.Stderr_No_Output_Label) =
                "No stderr captured.",
              "Build UI does not reuse stale stream text");
      Assert (To_String (Snapshot.Output_Details.Partial_Output_Label) =
                "partial output: build timed out",
              "Build UI distinguishes partial timeout output from truncation");
      Assert (To_String (Snapshot.Latest_Result.Latest_Build_Result_Truncation_Label) =
                "output not truncated",
              "timeout partial output is not reported as truncation");
      Assert (not Snapshot.Diagnostics_View.Reveal_Available,
              "no diagnostics does not create a build-local diagnostics route");

      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 0,
           Has_Diagnostics_Count => True);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (not Snapshot.Diagnostics_View.Reveal_Available,
              "zero produced Diagnostics does not expose reveal action");
      Assert (not Snapshot.Diagnostics_View.Open_Source_Available
              and then To_String
                (Snapshot.Diagnostics_View.Open_Source_Unavailable_Reason)'Length > 0,
              "zero produced Diagnostics explains open-source unavailability");
      Assert (To_String (Snapshot.Diagnostics_View.Action_Summary_Label) =
                "Actions unavailable until diagnostics are produced",
              "Build UI explains unavailable diagnostic actions");
   end Test_No_Output_And_Partial_Output_Are_Clear;

   procedure Test_Reveal_Diagnostics_Routes_Through_Existing_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 1,
           Has_Diagnostics_Count => True);
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           To_Unbounded_String ("out"),
           To_Unbounded_String ("err"));
      Before := S;
      Result := Editor.Build_UI_Actions.Build_UI_Reveal_Diagnostics (S);
      Assert (Editor.Build_UI_Actions.Assert_Build_UI_Reveal_Diagnostics_Uses_Existing_Command
                (Before, S, Result),
              "reveal diagnostics invokes existing Diagnostics command without build payload");
   end Test_Reveal_Diagnostics_Routes_Through_Existing_Command;



   procedure Test_Candidate_Specific_Request_Configuration
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Alire : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Alire_Candidate ("current-project-root");
      GPR : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "editor.gpr");
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.Build_UI.Show (S);
      Candidates.Append (Alire);
      Candidates.Append (GPR);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "refresh succeeded: 2 candidates");

      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (Alire.Candidate_Id));
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (To_String (Snapshot.Request_Preview.Request_Mode_Label) =
                "candidate-derived",
              "selected candidate produces candidate-derived request mode");
      Assert (To_String (Snapshot.Request_Preview.Tool_Kind_Label) = "alire",
              "Alire candidate exposes alire tool label");
      Assert (Editor.Build_UI.Argument_Count
                (Snapshot.Request_Preview.Argv_Tokens) = 1,
              "Alire request preview exposes structured argv tokens");
      Assert (To_String (Snapshot.Request_Preview.Build_Mode_Label) = "default",
              "default mode is visible");
      Assert (To_String (Snapshot.Request_Preview.Diagnostics_Label) =
                "Diagnostics not requested after build",
              "diagnostics ingestion state is visible");
      Assert (To_String (Snapshot.Request_Preview.Output_Capture_Limit_Label) =
                "normal bounded output capture (262144 bytes)",
              "bounded output capture policy is visible");
      Assert (Natural (Snapshot.Request_Preview.Request_Option_Rows.Length) >= 5,
              "request option rows are projected into the Build UI snapshot");
      Assert (not S.Option_Verbose_Output and then not S.Option_Keep_Going,
              "Alire candidate starts with GPR-only flags disabled");
      Editor.Build_UI.Toggle_Verbose_Output (S);
      Assert (not S.Option_Verbose_Output,
              "unsupported Alire verbose flag is not applied");

      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (GPR.Candidate_Id));
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (To_String (Snapshot.Request_Preview.Tool_Kind_Label) = "gprbuild",
              "GPR candidate exposes gprbuild tool label");
      Assert (Editor.Build_UI.Argument_Count
                (Snapshot.Request_Preview.Argv_Tokens) = 2,
              "GPR request preview exposes -P and selected project token");
      Editor.Build_UI.Toggle_Verbose_Output (S);
      Editor.Build_UI.Toggle_Keep_Going (S);
      Assert (S.Option_Verbose_Output and then S.Option_Keep_Going,
              "supported GPR fixed flag toggles are structured state");
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (Editor.Build_UI.Argument_Count
                (Snapshot.Request_Preview.Argv_Tokens) = 4,
              "GPR fixed flag toggles append fixed argv tokens only");
      Assert (Editor.Build_UI.Assert_Build_Request_Options_Are_Candidate_Specific (S),
              "candidate-specific option assertion holds for GPR request");

      S.Option_Warnings_As_Errors := True;
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Unsupported_Request_Option,
              "rejects unavailable hidden warnings-as-errors flag even for GPR candidates");
      Assert (Ada.Strings.Fixed.Index
                (To_String (S.Candidate_Request_Preview), "warnings-as-errors") = 0,
              "preview omits unavailable hidden warnings-as-errors option");
      Assert (not Editor.Build_UI.Assert_Build_Request_Options_Are_Candidate_Specific (S),
              "coherence rejects hidden flags without fixed argv mappings");
      S.Option_Warnings_As_Errors := False;
      S.Option_Force_Rebuild := True;
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Unsupported_Request_Option,
              "rejects unavailable hidden force-rebuild flag even for GPR candidates");
   end Test_Candidate_Specific_Request_Configuration;

   procedure Test_Material_Changes_Invalidate_Exact_Request_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      GPR : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "editor.gpr");
      Original_Id : Unbounded_String;
   begin
      Editor.Build_UI.Show (S);
      Candidates.Append (GPR);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (GPR.Candidate_Id));
      Editor.Build_UI.Acknowledge_Consent (S);
      Assert (S.Consent_Acknowledged,
              "valid candidate request can be consented");
      Original_Id := S.Consent_Request_Identity;

      Editor.Build_UI.Toggle_Diagnostics_Ingestion (S);
      Assert (not S.Consent_Acknowledged,
              "diagnostics toggle invalidates request consent");
      Assert (To_String (Original_Id) /= Editor.Build_UI.Current_Request_Identity (S),
              "diagnostics toggle changes material request identity");

      Editor.Build_UI.Acknowledge_Consent (S);
      Assert (S.Consent_Acknowledged,
              "changed diagnostics request can be re-consented");
      Original_Id := S.Consent_Request_Identity;
      Editor.Build_UI.Cycle_Output_Capture_Limit (S);
      Assert (not S.Consent_Acknowledged,
              "output capture limit change invalidates consent");
      Assert (To_String (Original_Id) /= Editor.Build_UI.Current_Request_Identity (S),
              "output capture limit changes material identity");

      Editor.Build_UI.Acknowledge_Consent (S);
      Original_Id := S.Consent_Request_Identity;
      Editor.Build_UI.Toggle_Verbose_Output (S);
      Assert (not S.Consent_Acknowledged,
              "fixed flag change invalidates consent");
      Assert (To_String (Original_Id) /= Editor.Build_UI.Current_Request_Identity (S),
              "fixed flag change changes material identity");

      Editor.Build_UI.Acknowledge_Consent (S);
      Original_Id := S.Consent_Request_Identity;
      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Debug);
      Assert (not S.Consent_Acknowledged,
              "build mode change invalidates consent");
      Assert (To_String (Original_Id) /= Editor.Build_UI.Current_Request_Identity (S),
              "build mode change changes material identity");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Valid
              or else Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Missing_Consent,
              "GPR debug mode remains a supported request once consent is refreshed");
      Editor.Build_UI.Acknowledge_Consent (S);
      Assert (S.Consent_Acknowledged,
              "GPR debug request can be consented after review");
   end Test_Material_Changes_Invalidate_Exact_Request_Consent;


   procedure Test_Build_UI_GPR_Modes_Apply_Fixed_Arguments
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_UI;

      function Has_Arg (Token : String) return Boolean is
      begin
         for Arg of S.Structured_Arguments loop
            if To_String (Arg) = Token then
               return True;
            end if;
         end loop;
         return False;
      end Has_Arg;
   begin
      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Debug);
      Assert (Has_Arg ("-g"), "debug profile adds -g");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Missing_Consent,
              "debug profile is supported and only requires renewed consent");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Release);
      Assert (not Has_Arg ("-g"), "release profile removes debug flag");
      Assert (Has_Arg ("-O2"), "release profile adds -O2");
      Assert (Has_Arg ("-gnatp"), "release profile adds -gnatp");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Validation);
      Assert (not Has_Arg ("-O2"), "validation profile removes release optimization flag");
      Assert (not Has_Arg ("-gnatp"), "validation profile removes release assertion policy flag");
      Assert (Has_Arg ("-gnata"), "validation profile adds assertion checking flag");
      Assert (Has_Arg ("-gnatwa"), "validation profile adds warning profile flag");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Default);
      Assert (not Has_Arg ("-gnata") and then not Has_Arg ("-gnatwa"),
              "default profile removes validation flags");
   end Test_Build_UI_GPR_Modes_Apply_Fixed_Arguments;


   procedure Test_Build_UI_Alire_Modes_Apply_Profile_Switches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_Alire_UI;

      function Has_Arg (Token : String) return Boolean is
      begin
         for Arg of S.Structured_Arguments loop
            if To_String (Arg) = Token then
               return True;
            end if;
         end loop;
         return False;
      end Has_Arg;
   begin
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_Alire,
              "Alire profile test starts from an Alire candidate");
      Assert (not Has_Arg ("--development")
              and then not Has_Arg ("--release")
              and then not Has_Arg ("--validation"),
              "default Alire profile leaves alr build unqualified");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Debug);
      Assert (Has_Arg ("--development"),
              "debug build mode maps to Alire development profile");
      Assert (not Has_Arg ("--release") and then not Has_Arg ("--validation"),
              "Alire development profile is exclusive");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Missing_Consent,
              "Alire development profile is supported and only requires renewed consent");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Release);
      Assert (not Has_Arg ("--development"),
              "Alire release profile strips development switch");
      Assert (Has_Arg ("--release"),
              "release build mode maps to Alire release profile");
      Assert (not Has_Arg ("--validation"),
              "Alire release profile is exclusive");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Validation);
      Assert (not Has_Arg ("--release"),
              "Alire validation profile strips release switch");
      Assert (Has_Arg ("--validation"),
              "validation build mode maps to Alire validation profile");
      Assert (not Has_Arg ("-gnata") and then not Has_Arg ("-gnatwa"),
              "Alire profiles use alr profile switches rather than GPR compiler flags");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Default);
      Assert (not Has_Arg ("--development")
              and then not Has_Arg ("--release")
              and then not Has_Arg ("--validation"),
              "default build mode removes explicit Alire profile switches");
   end Test_Build_UI_Alire_Modes_Apply_Profile_Switches;


   procedure Test_Request_Preview_Validation_And_Persistence_Exclusion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      GPR : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "editor.gpr");
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.Build_UI.Show (S);
      Candidates.Append (GPR);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (GPR.Candidate_Id));
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (Snapshot.Consent_Required,
              "valid unconsented request reports consent required");
      Assert (not Snapshot.Run_Available,
              "build.run is unavailable before exact consent");
      Assert (To_String (Snapshot.Request_Preview.Selected_Candidate_Label)'Length > 0,
              "preview shows selected candidate label");
      Assert (To_String (Snapshot.Request_Preview.Working_Context_Label)'Length > 0,
              "preview shows working context label");
      Assert (To_String (Snapshot.Request_Preview.Request_Identity_Label)'Length > 0,
              "preview shows material request identity");
      Assert (Editor.Build_UI.Assert_Build_Request_Preview_Matches_Tokens (Snapshot),
              "preview is derived from structured argv tokens");

      Editor.Build_UI.Acknowledge_Consent (S);
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (Snapshot.Consent_Acknowledged,
              "exact request consent is visible in snapshot");
      Assert (Snapshot.Run_Available,
              "valid consented request makes build.run UI-available");
      Assert (Editor.Build_UI.Assert_Build_Consent_Tied_To_Request_Identity (S),
              "consent is tied to exact request identity");
      Assert (Editor.Build_UI.Assert_Build_Request_State_Not_Persisted (S),
              "request configuration remains persistence-excluded transient state");
      Assert (Editor.Build_UI.Assert_Build_Request_Configuration_Coherent
                (S, Editor.Build_Result_Summary.Empty_Summary,
                 Editor.Build_Output_Details.Empty_Output_Details),
              "request configuration coherence assertion passes");

      Editor.Build_UI.Set_Build_Candidates
        (S, Editor.Build_Candidates.Empty_Candidates,
         "refresh succeeded: no candidates");
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (not S.Consent_Acknowledged,
              "candidate refresh clearing selection invalidates consent");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "candidate refresh clears selected candidate identity from transient state");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected,
              "no selected candidate makes the configured build request invalid");
      Assert (To_String (Snapshot.Request_Preview.Request_Mode_Label) =
                "no selected candidate",
              "preview does not present removed manual request as runnable");
   end Test_Request_Preview_Validation_And_Persistence_Exclusion;


   procedure Test_Build_UI_Dogfood_Labels_Are_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.Build_UI.Public_Build_UI_State;
      Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details;
      View    : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.Build_UI.Show (S);
      View := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (To_String (View.Run_Availability_Label) =
              "Build run unavailable: no build candidate selected",
              "Build run availability explains the missing selected candidate");
      Assert (not View.Request_Valid
              and then not View.Run_Command_Available,
              "missing candidate keeps request and run command unavailable");
      Assert (To_String (View.Request_Status_Label) =
                "Build request invalid: Build run unavailable: no build candidate selected",
              "request status label explains invalid request");
      Assert (To_String (View.Run_Recovery_Hint) =
              "Refresh build candidates and select one",
              "Build run recovery hint explains how to fix missing candidate");
      Assert (To_String (View.Refresh_Status_Label) =
              "Build candidates not refreshed yet",
              "Build candidate refresh status is user-facing");
      Assert (To_String (View.Candidate_Refresh_Action_Command_Name) =
                "build.refresh-candidates",
              "missing-candidate state should expose refresh as the row action");

      S := Ready_UI;
      Editor.Build_UI.Clear_Consent (S);
      View := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (To_String (View.Run_Availability_Label) =
              "Build run unavailable: review the request and acknowledge consent first",
              "Build run labels missing consent with a next action");
      Assert (not View.Request_Valid
              and then not View.Run_Command_Available,
              "missing consent keeps request and run command unavailable");
      Assert (To_String (View.Run_Command_Status_Label) =
                "Run command unavailable: Build run unavailable: review the request and acknowledge consent first",
              "run command status label explains missing consent");
      Assert (To_String (View.Run_Recovery_Hint) =
              "Review the request and acknowledge consent",
              "Build run recovery hint names the consent action");
      Assert (To_String (View.Request_Preview.Consent_Label) =
              "Consent missing: review and acknowledge the build request",
              "Build request preview distinguishes missing consent");

      S := Ready_UI;
      Summary := Editor.Build_Result_Summary.Build_Summary
        (Editor.Build_Result_Summary.Build_Result_Summary_Unavailable,
         "build.run",
         Editor.Build_Result_Summary.Build_Result_No_Tool,
         Editor.Build_Result_Summary.Build_Result_Request_None,
         "",
         "not available",
         "Build run unavailable: execution backend is disabled",
         Diagnostics_Ingestion_Status =>
           Editor.Build_Result_Summary.Diagnostics_Ingestion_Not_Requested);
      Details := Editor.Build_Output_Details.Build_Output_Details_No_Output_State
        (Editor.Build_Output_Details.Build_Output_Runner_Not_Available);
      View := Editor.Build_UI.Build_Render_Snapshot (S, Summary, Details);
      Assert (View.Request_Valid
              and then View.Run_Command_Available,
              "valid consented request remains distinct from latest result status");
      Assert (To_String (View.Request_Status_Label) = "Build request valid"
              and then To_String (View.Run_Command_Status_Label) =
                "Run command available",
              "valid base snapshot exposes separate request and run labels");
      Assert (To_String
                (View.Latest_Result.Latest_Build_Result_Status_Label) =
              "Build unavailable: check the Build panel run availability reason.",
              "latest build result unavailable label points back to run availability");
      Assert (To_String (View.Output_Details.No_Output_Label) =
              "No build output captured.",
              "output details no-output state is clear");
      Assert (To_String (View.Diagnostics_View.Count_Label) =
              "Diagnostics not requested",
              "diagnostics count label distinguishes not-requested state");
   end Test_Build_UI_Dogfood_Labels_Are_Clear;

   procedure Test_Reveal_Diagnostics_Requires_Produced_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);

      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial,
           Diagnostics_Count => 0,
           Has_Diagnostics_Count => False);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (not Snapshot.Diagnostics_View.Reveal_Available,
              "partial diagnostics without produced count cannot reveal rows");
      Assert (To_String (Snapshot.Diagnostics_View.Reveal_Command_Name) = "",
              "Build UI does not fabricate a reveal command without rows");

      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial,
           Diagnostics_Count => 1,
           Has_Diagnostics_Count => True);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (Snapshot.Diagnostics_View.Reveal_Available
              and then To_String (Snapshot.Diagnostics_View.Reveal_Command_Name) =
                "diagnostics.show",
              "Build UI exposes reveal only when Diagnostics-owned rows exist");
      declare
         Surface : constant Editor.Build_UI.Build_Diagnostics_Surface :=
           Editor.Build_UI.Build_Diagnostics_Surface_For (Snapshot);
      begin
         Assert (Editor.Build_UI.Assert_Build_Diagnostics_Surface_Is_Renderable
                   (Surface),
                 "Build/Diagnostics render surface must be independently renderable");
         Assert (Surface.Reveal_Available
                 and then To_String (Surface.Reveal_Command_Name) =
                   "diagnostics.show",
                 "Build/Diagnostics surface exposes the Diagnostics reveal command");
      end;
   end Test_Reveal_Diagnostics_Requires_Produced_Count;

   procedure Test_Build_UI_Quick_Fix_Action_Rows_Execute_Selected_Action
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
      Render_Snapshot : Editor.Render_Model.Render_Snapshot;
      Result : Editor.Command_Execution.Command_Execution_Result;
      Quick_Fix_Row_Count : Natural := 0;
      Render_Quick_Fix_Row_Count : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null" & ASCII.LF &
         "end Demo;" & ASCII.LF);
      Editor.Build_UI_Actions.Show_Build_UI (S);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "missing semicolon",
         Source_Label  => "semantic",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 3,
         Target_Column => 8,
         Has_Edit          => True,
         Edit_Start_Line   => 3,
         Edit_Start_Column => 8,
         Edit_End_Line     => 3,
         Edit_End_Column   => 8,
         Replacement_Text  => ";",
         Quick_Fix_Label   => "Insert semicolon",
         Quick_Fix_Detail  => "Append statement delimiter");
      Editor.Feature_Diagnostics.Append_Diagnostic_Quick_Fix_Command
        (S.Feature_Diagnostics, 1,
         Label  => "Explain missing semicolon",
         Detail => "Open diagnostic explanation",
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic);
      Editor.Feature_Diagnostics.Append_Diagnostic_Quick_Fix_Unavailable
        (S.Feature_Diagnostics, 1,
         Label  => "Unavailable quick fix",
         Detail => "No edit or command");
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      for I in Snapshot.Actions.First_Index .. Snapshot.Actions.Last_Index loop
         if To_String (Snapshot.Actions.Element (I).Command_Name) =
           "ada.diagnostic.apply-quick-fix"
         then
            Quick_Fix_Row_Count := Quick_Fix_Row_Count + 1;
            Assert
              (Editor.Build_UI.Assert_Action_Row_Metadata
                 (Snapshot.Actions.Element (I),
                  Expected_Command_Name => "ada.diagnostic.apply-quick-fix",
                  Expected_Enabled => Quick_Fix_Row_Count /= 3,
                  Expected_Disabled_Reason =>
                    (if Quick_Fix_Row_Count = 3
                     then "Quick fix action has no valid edit or command"
                     else ""),
                  Expected_Diagnostic_Index => 1,
                  Expected_Quick_Fix_Action_Index => Quick_Fix_Row_Count),
               "Build UI quick-fix rows expose coherent action metadata");
            if Quick_Fix_Row_Count = 3 then
               Assert
                 (To_String (Snapshot.Actions.Element (I).Disabled_Reason) =
                  "Quick fix action has no valid edit or command",
                  "inert quick-fix action row explains why it is disabled");
            end if;
         end if;
      end loop;
      Assert (Quick_Fix_Row_Count = 3,
              "Build UI exposes every quick-fix action");

      Editor.Render_Model.Build_Render_Snapshot (S, Render_Snapshot);
      for I in Render_Snapshot.Build_UI.Actions.First_Index ..
        Render_Snapshot.Build_UI.Actions.Last_Index
      loop
         if To_String (Render_Snapshot.Build_UI.Actions.Element (I).Command_Name) =
           "ada.diagnostic.apply-quick-fix"
         then
            Render_Quick_Fix_Row_Count := Render_Quick_Fix_Row_Count + 1;
            Assert
              (Editor.Build_UI.Assert_Action_Row_Metadata
                 (Render_Snapshot.Build_UI.Actions.Element (I),
                  Expected_Command_Name => "ada.diagnostic.apply-quick-fix",
                  Expected_Enabled => Render_Quick_Fix_Row_Count /= 3,
                  Expected_Disabled_Reason =>
                    (if Render_Quick_Fix_Row_Count = 3
                     then "Quick fix action has no valid edit or command"
                     else ""),
                  Expected_Diagnostic_Index => 1,
                  Expected_Quick_Fix_Action_Index => Render_Quick_Fix_Row_Count),
               "render model preserves Build UI quick-fix row metadata");
         end if;
      end loop;
      Assert (Render_Quick_Fix_Row_Count = Quick_Fix_Row_Count,
              "render model exposes every Build UI quick-fix action row");

      Result := Editor.Build_UI_Actions.Build_UI_Apply_Diagnostic_Quick_Fix
        (S, Action_Index => 1, Diagnostic_Index => 1);
      Assert
        (Result.Command = Editor.Commands.Command_Diagnostic_Apply_Quick_Fix
         and then Result.Status = Editor.Command_Execution.Command_Executed,
         "Build UI executes the requested quick-fix action directly");
      Assert
        (Editor.State.Current_Text (S) =
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null;" & ASCII.LF &
         "end Demo;" & ASCII.LF,
         "direct Build UI quick-fix action applies the selected edit");
      Assert
        (not Editor.State.Has_Pending_Quick_Fix_Workflow (S)
         and then Editor.State.Pending_Quick_Fix_Action_Index (S) = 0,
         "direct Build UI quick-fix execution clears workflow state");
   end Test_Build_UI_Quick_Fix_Action_Rows_Execute_Selected_Action;

   procedure Test_Build_UI_Quick_Fix_Row_Disabled_Target_Reasons
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Assert_Row_Reason
        (Message       : String;
         Target_Buffer : Natural;
         Target_Line   : Natural;
         Target_Column : Natural;
         Mark_Stale    : Boolean;
         Expected      : String)
      is
         S : Editor.State.State_Type;
         Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
         Row : Natural := 0;
         Effective_Target_Buffer : Natural := Target_Buffer;
      begin
         Editor.State.Init (S);
         Editor.State.Load_Text (S, "line" & ASCII.LF);
         Editor.Build_UI_Actions.Show_Build_UI (S);
         if Effective_Target_Buffer = 0 then
            Effective_Target_Buffer := S.Active_Buffer_Token;
         end if;

         Editor.Feature_Diagnostics.Add_Diagnostic
           (S.Feature_Diagnostics,
            Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
            Message       => Message,
            Source_Label  => "semantic",
            Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
            Has_Target    => True,
            Target_Buffer => Effective_Target_Buffer,
            Target_Line   => Target_Line,
            Target_Column => Target_Column,
            Has_Edit          => True,
            Edit_Start_Line   => 1,
            Edit_Start_Column => 1,
            Edit_End_Line     => 1,
            Edit_End_Column   => 1,
            Replacement_Text  => "x",
            Quick_Fix_Label   => "Apply edit",
            Quick_Fix_Detail  => "Edit target");
         if Mark_Stale then
            Editor.Feature_Diagnostics.Mark_Diagnostics_For_Buffer_Stale
              (S.Feature_Diagnostics, S.Active_Buffer_Token);
         end if;
         Select_Diagnostic_By_Message (S, Message);

         Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
         Row := Editor.Build_UI.Find_Action_Row
           (Snapshot,
            "ada.diagnostic.apply-quick-fix",
            Diagnostic_Index       => 1,
            Quick_Fix_Action_Index => 1);
         Assert (Row > 0, "Build UI exposes disabled quick-fix row for " & Message);
         Assert
           (Editor.Build_UI.Assert_Action_Row_Metadata
              (Snapshot.Actions.Element (Row - 1),
               Expected_Command_Name => "ada.diagnostic.apply-quick-fix",
               Expected_Enabled => False,
               Expected_Disabled_Reason => Expected,
               Expected_Diagnostic_Index => 1,
               Expected_Quick_Fix_Action_Index => 1),
            "Build UI quick-fix disabled reason is specific for " & Message);
      end Assert_Row_Reason;
   begin
      Assert_Row_Reason
        ("stale quick fix row", 0, 1, 1, True,
         Editor.Commands.Reason_Target_Stale);
      Assert_Row_Reason
        ("missing buffer quick fix row", 9999, 1, 1, False,
         Editor.Commands.Reason_Target_Missing);
      Assert_Row_Reason
        ("invalid line quick fix row", 0, 99, 1, False,
         Editor.Commands.Reason_Diagnostic_Target_Line_Outside_Buffer);
      Assert_Row_Reason
        ("invalid column quick fix row", 0, 1, 99, False,
         Editor.Commands.Reason_Diagnostic_Target_Column_Outside_Line);
   end Test_Build_UI_Quick_Fix_Row_Disabled_Target_Reasons;

   procedure Test_Many_Diagnostics_With_Quick_Fix_Actions_Are_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
      Quick_Fix_Row_Count : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "procedure Demo is begin null; end Demo;");
      Editor.Build_UI_Actions.Show_Build_UI (S);

      for I in 1 .. 80 loop
         Editor.Feature_Diagnostics.Add_Diagnostic
           (S.Feature_Diagnostics,
            Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
            Message      => "bulk quick fix" & Natural'Image (I),
            Source_Label => "semantic",
            Source_Kind  => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
            Has_Target   => True,
            Target_Buffer => 1,
            Target_Line   => 1,
            Target_Column => 1,
            Has_Edit          => True,
            Edit_Start_Line   => 1,
            Edit_Start_Column => 1,
            Edit_End_Line     => 1,
            Edit_End_Column   => 1,
            Replacement_Text  => "with Ada.Text_IO;",
            Quick_Fix_Label   => "Insert dependency",
            Quick_Fix_Detail  => "Edit");
         for A in 2 .. Editor.Feature_Diagnostics.Max_Quick_Fix_Actions_Per_Diagnostic loop
            Editor.Feature_Diagnostics.Append_Diagnostic_Quick_Fix_Command
              (S.Feature_Diagnostics, I,
               Label  => "Alternative" & Natural'Image (A),
               Detail => "review",
               Primary_Action_Kind =>
                 Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic);
         end loop;
      end loop;

      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 80,
              "bulk quick-fix diagnostics should stay within row cap");
      Assert
        (Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Count
           (S.Feature_Diagnostics, 1) =
         Editor.Feature_Diagnostics.Max_Quick_Fix_Actions_Per_Diagnostic,
         "bulk diagnostics should retain bounded quick-fix action lists");
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      for I in Snapshot.Actions.First_Index .. Snapshot.Actions.Last_Index loop
         if To_String (Snapshot.Actions.Element (I).Command_Name) =
           "ada.diagnostic.apply-quick-fix"
         then
            Quick_Fix_Row_Count := Quick_Fix_Row_Count + 1;
         end if;
      end loop;
      Assert (Natural (Snapshot.Actions.Length) > 0
              and then To_String (Snapshot.Diagnostics_View.Quick_Fix_Label)'Length > 0,
              "Build UI snapshot remains bounded with many quick-fix actions");
      Assert
        (Quick_Fix_Row_Count =
         Editor.Feature_Diagnostics.Max_Quick_Fix_Actions_Per_Diagnostic,
         "Build UI exposes each bounded quick-fix action as an action row");
   end Test_Many_Diagnostics_With_Quick_Fix_Actions_Are_Bounded;

   overriding procedure Register_Tests
     (T : in out Build_UI_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Build_UI_State_Is_Transient_And_Explicit'Access,
         "build UI state is transient and explicit");
      Register_Routine
        (T, Test_Build_UI_Panel_Layout_Hit_Test_Covers_Actions_And_Suppressed'Access,
         "Build UI panel layout hit test covers actions and suppressed rows");
      Register_Routine
        (T, Test_Build_UI_Action_Row_Scroll_Keeps_Selection_Visible'Access,
         "Build UI action row scroll keeps selection visible");
      Register_Routine
        (T, Test_Focused_Build_UI_Keyboard_Routes_Through_Input_Bridge'Access,
         "focused Build UI keyboard routes through Input_Bridge");
      Register_Routine
        (T, Test_Request_Changes_Invalidate_Consent'Access,
         "request changes invalidate build consent");
      Register_Routine
        (T, Test_Structured_Request_Conversion'Access,
         "build UI converts to structured public request");
      Register_Routine
        (T, Test_Unsafe_Arguments_And_Missing_Consent_Are_Rejected'Access,
         "unsafe arguments and missing consent are rejected");
      Register_Routine
        (T, Test_Build_Run_Command_Is_Public_But_Non_Executing'Access,
         "build.run is public and non-executing while backend disabled");
      Register_Routine
        (T, Test_Working_Context_Model_Is_Explicit_Structured_And_Transient'Access,
         "working context model is explicit structured and transient");
      Register_Routine
        (T, Test_Working_Context_Rejects_Forbidden_Sources'Access,
         "working context rejects forbidden sources");
      Register_Routine
        (T, Test_Request_Conversion_Requires_Valid_Working_Context'Access,
         "request conversion requires valid working context");
      Register_Routine
        (T, Test_Working_Context_Consent_Binds_Request_Identity'Access,
         "working context consent binds request identity");
      Register_Routine
        (T, Test_Public_Build_Working_Context_Foundation_Coherent'Access,
         "public build working-context foundation coherent");
      Register_Routine
        (T, Test_Build_UI_Operability_Actions_And_Snapshot'Access,
         "build UI operability actions and snapshot");
      Register_Routine
        (T, Test_Build_UI_Refresh_And_Run_Use_Canonical_Boundaries'Access,
         "build UI refresh and run use canonical boundaries");
      Register_Routine
        (T, Test_Build_UI_Diagnostic_Actions_Are_UI_Routed'Access,
         "Build UI diagnostic actions are UI routed");
      Register_Routine
        (T, Test_Build_UI_Result_And_Output_Snapshot_Projection'Access,
         "build UI result and output snapshot projection");
      Register_Routine
        (T, Test_Render_Model_Projects_Build_UI_Snapshot'Access,
         "render model projects Build UI snapshot");
      Register_Routine
        (T, Test_Build_UI_Commands_Are_Public_And_Executor_Routed'Access,
         "build UI commands are public and Executor routed");
      Register_Routine
        (T, Test_Build_UI_Row_Actions_Are_Route_Audited'Access,
         "Build UI row actions are route-audited");
      Register_Routine
        (T, Test_Result_Output_Diagnostics_UI_Usability'Access,
         "result output diagnostics UI usability");
      Register_Routine
        (T, Test_No_Output_And_Partial_Output_Are_Clear'Access,
         "no-output and partial-output states are clear");
      Register_Routine
        (T, Test_Reveal_Diagnostics_Routes_Through_Existing_Command'Access,
         "reveal diagnostics routes through existing command");
      Register_Routine
        (T, Test_Candidate_Specific_Request_Configuration'Access,
         "candidate-specific request configuration");
      Register_Routine
        (T, Test_Material_Changes_Invalidate_Exact_Request_Consent'Access,
         "material changes invalidate exact request consent");
      Register_Routine
        (T, Test_Build_UI_GPR_Modes_Apply_Fixed_Arguments'Access,
         "Build UI GPR modes apply fixed structured arguments");
      Register_Routine
        (T, Test_Build_UI_Alire_Modes_Apply_Profile_Switches'Access,
         "Build UI Alire modes apply structured profile switches");
      Register_Routine
        (T, Test_Request_Preview_Validation_And_Persistence_Exclusion'Access,
         "request preview validation and persistence exclusion");
      Register_Routine
        (T, Test_Build_UI_Dogfood_Labels_Are_Clear'Access,
         "Build UI dogfood labels are clear");
      Register_Routine
        (T, Test_Reveal_Diagnostics_Requires_Produced_Count'Access,
         "reveal diagnostics requires produced count");
      Register_Routine
        (T, Test_Build_UI_Quick_Fix_Action_Rows_Execute_Selected_Action'Access,
         "Build UI quick-fix rows execute selected action");
      Register_Routine
        (T, Test_Build_UI_Quick_Fix_Row_Disabled_Target_Reasons'Access,
         "Build UI quick-fix rows preserve disabled target reasons");
      Register_Routine
        (T, Test_Many_Diagnostics_With_Quick_Fix_Actions_Are_Bounded'Access,
         "many diagnostics with quick-fix actions are bounded");

   end Register_Tests;

end Editor.Build_UI.Tests;
