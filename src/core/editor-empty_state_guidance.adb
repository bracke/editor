with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Project;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Quick_Open;
with Editor.Project_Search;
with Editor.Outline;
with Editor.Diagnostics;
with Editor.Recent_Projects;
with Editor.Build_UI;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Executor;
with Editor.Command_Execution;
with Editor.Command_Palette;
with Editor.Empty_State_Guidance.Guided_Actions;
with Editor.Configuration_Audit;
with Editor.Configuration_Recovery;
with Editor.Commands.Workflow_Messages;
with Editor.Feature_Diagnostics;
with Editor.Keybindings;
with Editor.Messages;
with Editor.Empty_State_Guidance.Audits;
with Editor.Empty_State_Guidance.Surfaces;

with Editor.Commands.Name_Metadata;


package body Editor.Empty_State_Guidance is

   use type Editor.File_Tree.File_Tree_Node_Id;

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Descriptors.Command_Visibility;
   use type Editor.Executor.Command_Execution_Status;
   use type Editor.File_Tree.File_Tree_Scan_Status;
   use type Editor.Project_Search.Project_Search_Status;
   use type Editor.Project_Search.Project_Replace_Preview_Status;
   use type Editor.Outline.Outline_Source_Class;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.Build_UI.Build_Candidate_Refresh_Status;
   use type Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status;
   use type Editor.Build_Output_Details.Build_Output_Details_Kind;
   use type Editor.Feature_Diagnostics.Diagnostic_Severity;
   function Command_Suggestion_From_Descriptor
     (S       : Editor.State.State_Type;
      Command : Editor.Commands.Command_Id)
      return Empty_State_Suggested_Command
     renames Editor.Empty_State_Guidance.Guided_Actions.Command_Suggestion_From_Descriptor;

   function Stable_Name_Is_Display_Only
     (Name : String) return Boolean
     renames Editor.Empty_State_Guidance.Guided_Actions.Stable_Name_Is_Display_Only;

   function Suggestion_Is_Descriptor_Consistent
     (Suggestion : Empty_State_Suggested_Command) return Boolean
     renames Editor.Empty_State_Guidance.Guided_Actions.Suggestion_Is_Descriptor_Consistent;

   function Suggestion_Is_Activation_Safe
     (Suggestion : Empty_State_Suggested_Command) return Boolean
     renames Editor.Empty_State_Guidance.Guided_Actions.Suggestion_Is_Activation_Safe;

   function Suggested_Action_Availability_Label
     (Suggestion : Empty_State_Suggested_Command) return String
     renames Editor.Empty_State_Guidance.Guided_Actions.Suggested_Action_Availability_Label;

   function Suggested_Action_Select_Next
     (Snapshot      : Empty_State_Snapshot;
      Current_Index : Natural) return Natural
     renames Editor.Empty_State_Guidance.Guided_Actions.Suggested_Action_Select_Next;

   function Suggested_Action_Select_Previous
     (Snapshot      : Empty_State_Snapshot;
      Current_Index : Natural) return Natural
     renames Editor.Empty_State_Guidance.Guided_Actions.Suggested_Action_Select_Previous;

   function Suggested_Action_Selected_Index
     (Snapshot : Empty_State_Snapshot) return Natural
     renames Editor.Empty_State_Guidance.Guided_Actions.Suggested_Action_Selected_Index;

   procedure Mark_Selected_Suggestion
     (Snapshot : in out Empty_State_Snapshot;
      Index    : Natural)
     renames Editor.Empty_State_Guidance.Guided_Actions.Mark_Selected_Suggestion;

   function Open_Suggested_Command_In_Command_Palette
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean
     renames Editor.Empty_State_Guidance.Guided_Actions.Open_Suggested_Command_In_Command_Palette;

   function Open_Selected_Suggested_Command_In_Command_Palette
     (Snapshot : Empty_State_Snapshot) return Boolean
     renames Editor.Empty_State_Guidance.Guided_Actions.Open_Selected_Suggested_Command_In_Command_Palette;

   function Execute_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Index    : Positive)
      return Editor.Executor.Command_Execution_Result
     renames Editor.Empty_State_Guidance.Guided_Actions.Execute_Suggested_Command;

   function Activate_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Index    : Positive)
      return Editor.Executor.Command_Execution_Result
     renames Editor.Empty_State_Guidance.Guided_Actions.Activate_Suggested_Command;

   function Execute_Selected_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot)
      return Editor.Executor.Command_Execution_Result
     renames Editor.Empty_State_Guidance.Guided_Actions.Execute_Selected_Suggested_Command;

   function Activate_Selected_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot)
      return Editor.Executor.Command_Execution_Result
     renames Editor.Empty_State_Guidance.Guided_Actions.Activate_Selected_Suggested_Command;

   function Assert_Guided_Action_Routing_Coherent
     (S : Editor.State.State_Type) return Boolean
     renames Editor.Empty_State_Guidance.Guided_Actions.Assert_Guided_Action_Routing_Coherent;

   function Safe_Stable_Command_Name (Name : String) return Boolean is
   begin
      return Name'Length > 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), " ") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), ":") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "/") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "\") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "?") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "=") = 0;
   end Safe_Stable_Command_Name;

   function Command_Is_Visible_In_Guidance
     (Command : Editor.Commands.Command_Id) return Boolean
   is
      D : constant Editor.Commands.Descriptors.Command_Descriptor :=
        Editor.Commands.Descriptors.Descriptor (Command);
   begin
      return D.Visibility = Editor.Commands.Descriptors.Palette_Command
        or else Command = Editor.Commands.Command_Open_Command_Palette;
   end Command_Is_Visible_In_Guidance;

   function Suggestion_Is_Selectable
     (Suggestion : Empty_State_Suggested_Command) return Boolean
   is
   begin
      return Suggestion_Is_Activation_Safe (Suggestion)
        and then Suggestion.Activation_Mode /= Suggestion_Display_Only;
   end Suggestion_Is_Selectable;



   function Empty_State_Surface_Count return Natural
   is
      Count : Natural := 0;
   begin
      for Surface in Empty_State_Surface loop
         Count := Count + 1;
      end loop;
      return Count;
   end Empty_State_Surface_Count;

   function Empty_State_Surface_For_Slot
     (Index : Positive) return Empty_State_Surface
   is
   begin
      case Index is
         when 1 => return Main_Surface;
         when 2 => return File_Tree_Surface;
         when 3 => return Quick_Open_Surface;
         when 4 => return Project_Search_Surface;
         when 5 => return Outline_Surface;
         when 6 => return Diagnostics_Surface;
         when 7 => return Build_Surface;
         when 8 => return Recent_Projects_Surface;
         when others => return Configuration_Recovery_Surface;
      end case;
   end Empty_State_Surface_For_Slot;

   function Empty_State_Slot_For_Surface
     (Surface : Empty_State_Surface) return Positive
   is
   begin
      case Surface is
         when Main_Surface => return 1;
         when File_Tree_Surface => return 2;
         when Quick_Open_Surface => return 3;
         when Project_Search_Surface => return 4;
         when Outline_Surface => return 5;
         when Diagnostics_Surface => return 6;
         when Build_Surface => return 7;
         when Recent_Projects_Surface => return 8;
         when Configuration_Recovery_Surface => return 9;
      end case;
   end Empty_State_Slot_For_Surface;

   function Assert_Empty_State_Surface_Model_Is_Closed return Boolean
   is
      Count : Natural := 0;
      Seen  : array (Positive range 1 .. Max_Empty_State_Surfaces) of Boolean :=
        (others => False);
   begin
      --  Keep the enum, the aggregate slot count, and the two mapping helpers
      --  locked together.  This catches future surface additions that update
      --  one representation but forget the render-facing aggregate contract.
      for Surface in Empty_State_Surface loop
         declare
            Slot : constant Positive := Empty_State_Slot_For_Surface (Surface);
         begin
            Count := Count + 1;
            if Slot not in 1 .. Max_Empty_State_Surfaces
              or else Seen (Slot)
              or else Empty_State_Surface_For_Slot (Slot) /= Surface
            then
               return False;
            end if;
            Seen (Slot) := True;
         end;
      end loop;

      if Count /= Max_Empty_State_Surfaces
        or else Empty_State_Surface_Count /= Max_Empty_State_Surfaces
      then
         return False;
      end if;

      for Slot in 1 .. Max_Empty_State_Surfaces loop
         if not Seen (Slot)
           or else Empty_State_Slot_For_Surface
             (Empty_State_Surface_For_Slot (Slot)) /= Slot
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Empty_State_Surface_Model_Is_Closed;

   function Empty_State_Surface_Label
     (Surface : Empty_State_Surface) return String
   is
   begin
      case Surface is
         when Main_Surface =>
            return "Main";
         when File_Tree_Surface =>
            return "File Tree";
         when Quick_Open_Surface =>
            return "Quick Open";
         when Project_Search_Surface =>
            return "Project Search";
         when Outline_Surface =>
            return "Outline";
         when Diagnostics_Surface =>
            return "Diagnostics";
         when Build_Surface =>
            return "Build";
         when Recent_Projects_Surface =>
            return "Recent Projects";
         when Configuration_Recovery_Surface =>
            return "Configuration Recovery";
      end case;
   end Empty_State_Surface_Label;

   function Empty_State_Kind_Label
     (Kind : Empty_State_Kind) return String
   is
   begin
      case Kind is
         when First_Run_State => return "first run";
         when Ready_State => return "ready";
         when No_Project_State => return "no project";
         when No_Active_Buffer_State => return "no active buffer";
         when Unsupported_Buffer_State => return "unsupported buffer";
         when Different_Buffer_State => return "different buffer";
         when No_Files_State => return "no files";
         when Not_Refreshed_State => return "not refreshed";
         when Refresh_Required_State => return "refresh required";
         when No_Results_State => return "no results";
         when No_Candidates_State => return "no candidates";
         when No_Recent_Projects_State => return "no recent projects";
         when No_Diagnostics_State => return "no diagnostics";
         when Filtered_None_State => return "filtered none";
         when Source_Less_Selected_State => return "source-less selected";
         when No_Build_Diagnostics_State => return "no build diagnostics";
         when No_Query_State => return "no query";
         when No_Matches_State => return "no matches";
         when No_Symbols_State => return "no symbols";
         when Stale_State => return "stale";
         when Missing_Target_State => return "missing target";
         when Missing_Root_State => return "missing root";
         when Empty_Project_State => return "empty project";
         when Limit_Reached_State => return "limit reached";
         when Replace_Preview_Empty_State => return "replace preview empty";
         when Consent_Required_State => return "consent required";
         when No_Selected_Candidate_State => return "no selected candidate";
         when Request_Invalid_State => return "request invalid";
         when No_Result_State => return "no result";
         when No_Output_State => return "no output";
         when Diagnostics_Disabled_State => return "diagnostics disabled";
         when Selected_Unavailable_State => return "selected unavailable";
         when Only_Missing_Projects_State => return "only missing projects";
         when Clean_State => return "clean";
         when Configuration_Warning_State => return "configuration warning";
         when Safe_Defaults_State => return "safe defaults";
         when Audit_Not_Run_State => return "audit not run";
         when Unavailable_State => return "unavailable";
      end case;
   end Empty_State_Kind_Label;

   function Empty_State_Severity_Label
     (Severity : Empty_State_Severity) return String
   is
   begin
      case Severity is
         when Empty_Info => return "info";
         when Empty_Warning => return "warning";
         when Empty_Error => return "error";
      end case;
   end Empty_State_Severity_Label;

   function Empty_State_Should_Render
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      --  Ready surfaces are normal UI state, not empty-state guidance cards.
      --  The snapshot may still contain side-effect-free status details for
      --  diagnostics/debug assertions, but renderers should only draw guidance
      --  cards for explicit first-use, empty, stale, warning, or unavailable
      --  states.
      return Snapshot.Kind /= Ready_State;
   end Empty_State_Should_Render;

   function Empty_State_Renderable_Count
     (Snapshots : Empty_State_Snapshot_Array) return Natural
   is
      Count : Natural := 0;
   begin
      for I in Snapshots'Range loop
         if Empty_State_Should_Render (Snapshots (I)) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Empty_State_Renderable_Count;


   function Empty_State_Snapshots_Equivalent
     (Left  : Empty_State_Snapshot;
      Right : Empty_State_Snapshot) return Boolean
   is
   begin
      if Left.Surface /= Right.Surface
        or else Left.Kind /= Right.Kind
        or else Left.Severity /= Right.Severity
        or else To_String (Left.Primary_Message) /= To_String (Right.Primary_Message)
        or else To_String (Left.Secondary_Explanation) /=
          To_String (Right.Secondary_Explanation)
        or else Left.Suggestion_Count /= Right.Suggestion_Count
      then
         return False;
      end if;

      for I in 1 .. Max_Empty_State_Suggestions loop
         if Left.Suggestions (I).Command /= Right.Suggestions (I).Command
           or else To_String (Left.Suggestions (I).Stable_Name) /=
             To_String (Right.Suggestions (I).Stable_Name)
           or else To_String (Left.Suggestions (I).Title) /=
             To_String (Right.Suggestions (I).Title)
           or else To_String (Left.Suggestions (I).Short_Explanation) /=
             To_String (Right.Suggestions (I).Short_Explanation)
           or else To_String (Left.Suggestions (I).Surface_Source_Label) /=
             To_String (Right.Suggestions (I).Surface_Source_Label)
           or else To_String (Left.Suggestions (I).Availability_Label) /=
             To_String (Right.Suggestions (I).Availability_Label)
           or else Left.Suggestions (I).Activation_Mode /=
             Right.Suggestions (I).Activation_Mode
           or else Left.Suggestions (I).Selected /= Right.Suggestions (I).Selected
           or else Left.Suggestions (I).Available /= Right.Suggestions (I).Available
           or else To_String (Left.Suggestions (I).Unavailable_Reason) /=
             To_String (Right.Suggestions (I).Unavailable_Reason)
           or else Left.Suggestions (I).Visible /= Right.Suggestions (I).Visible
           or else Left.Suggestions (I).Carries_Payload /=
             Right.Suggestions (I).Carries_Payload
         then
            return False;
         end if;
      end loop;

      return True;
   end Empty_State_Snapshots_Equivalent;

   function Assert_Empty_State_Severity_Is_Semantic
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      case Snapshot.Kind is
         when Configuration_Warning_State
            | Safe_Defaults_State
            | Stale_State
            | Different_Buffer_State
            | Missing_Target_State
            | Missing_Root_State
            | Limit_Reached_State
            | Request_Invalid_State
            | Selected_Unavailable_State
            | Only_Missing_Projects_State
            | Unavailable_State =>
            return Snapshot.Severity = Empty_Warning
              or else Snapshot.Severity = Empty_Error;

         when Ready_State
            | First_Run_State
            | No_Project_State
            | No_Active_Buffer_State
            | Unsupported_Buffer_State
            | No_Files_State
            | Not_Refreshed_State
            | Refresh_Required_State
            | No_Results_State
            | No_Candidates_State
            | No_Recent_Projects_State
            | No_Diagnostics_State
            | Filtered_None_State
            | Source_Less_Selected_State
            | No_Build_Diagnostics_State
            | No_Query_State
            | No_Matches_State
            | No_Symbols_State
            | Empty_Project_State
            | Replace_Preview_Empty_State
            | Consent_Required_State
            | No_Selected_Candidate_State
            | No_Result_State
            | No_Output_State
            | Diagnostics_Disabled_State
            | Clean_State
            | Audit_Not_Run_State =>
            return Snapshot.Severity = Empty_Info;
      end case;
   end Assert_Empty_State_Severity_Is_Semantic;

   function Empty_State_Display_Line
     (Snapshot : Empty_State_Snapshot) return String
   is
      Surface : constant String := Empty_State_Surface_Label (Snapshot.Surface);
      Kind    : constant String := Empty_State_Kind_Label (Snapshot.Kind);
      Primary : constant String := To_String (Snapshot.Primary_Message);
      Secondary : constant String := To_String (Snapshot.Secondary_Explanation);
      Severity : constant String := Empty_State_Severity_Label (Snapshot.Severity);
      Prefix : constant String := Surface & " [" & Severity & "; " & Kind & "]: ";
   begin
      if Secondary'Length = 0 then
         return Prefix & Primary;
      end if;
      return Prefix & Primary & " " & Secondary;
   end Empty_State_Display_Line;

   function Suggestion_Display_Line
     (Suggestion : Empty_State_Suggested_Command) return String
   is
      Title : constant String := To_String (Suggestion.Title);
      Stable : constant String := To_String (Suggestion.Stable_Name);
      Reason : constant String := To_String (Suggestion.Unavailable_Reason);
      Prefix : constant String := Title & " [" & Stable & "]";
   begin
      if not Suggestion.Visible then
         return "";
      elsif Suggestion.Available then
         return Prefix;
      elsif Reason'Length > 0 then
         declare
            Available_Reason_Chars : constant Natural :=
              (if Prefix'Length >= 140 then 0 else 140 - Prefix'Length);
            Max_Reason : constant Natural :=
              Natural'Min (Reason'Length, Available_Reason_Chars);
         begin
            if Max_Reason = 0 then
               return Prefix & " unavailable";
            else
               return Prefix & " unavailable: " &
                 Reason (Reason'First .. Reason'First + Max_Reason - 1);
            end if;
         end;
      else
         return Prefix & " unavailable";
      end if;
   end Suggestion_Display_Line;

   function Assert_Empty_State_Text_Is_Deterministic_And_Compact
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      Surface_Label : constant String := Empty_State_Surface_Label (Snapshot.Surface);
      Kind_Label    : constant String := Empty_State_Kind_Label (Snapshot.Kind);
      Severity_Label : constant String := Empty_State_Severity_Label (Snapshot.Severity);
      Display_Line : constant String := Empty_State_Display_Line (Snapshot);
   begin
      if Surface_Label'Length = 0
        or else Kind_Label'Length = 0
        or else Severity_Label'Length = 0
        or else Display_Line'Length = 0
        or else Display_Line'Length > 280
        or else Length (Snapshot.Primary_Message) = 0
        or else Length (Snapshot.Primary_Message) > 80
        or else Length (Snapshot.Secondary_Explanation) > 180
      then
         return False;
      end if;

      for I in 1 .. Snapshot.Suggestion_Count loop
         declare
            Line : constant String := Suggestion_Display_Line (Snapshot.Suggestions (I));
         begin
            if Line'Length = 0 or else Line'Length > 160 then
               return False;
            end if;
         end;
      end loop;

      return True;
   end Assert_Empty_State_Text_Is_Deterministic_And_Compact;

   function Assert_Empty_State_Display_Line_Is_Labelled
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      Line     : constant Unbounded_String :=
        To_Unbounded_String (Empty_State_Display_Line (Snapshot));
      Surface  : constant String := Empty_State_Surface_Label (Snapshot.Surface);
      Kind     : constant String := Empty_State_Kind_Label (Snapshot.Kind);
      Severity : constant String := Empty_State_Severity_Label (Snapshot.Severity);
   begin
      --  Render-facing display text must carry all classification fields so a
      --  backend can render deterministic compact guidance without consulting
      --  mutable editor state or guessing which surface/kind produced it.
      return Index (Line, Surface) /= 0
        and then Index (Line, Kind) /= 0
        and then Index (Line, Severity) /= 0;
   end Assert_Empty_State_Display_Line_Is_Labelled;

   function Assert_Empty_State_Display_Line_Has_No_Target_Text
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      Line : constant String := Empty_State_Display_Line (Snapshot);
   begin
      --  The final render-facing line is the string most likely to be copied
      --  into backends and snapshots.  Keep it free of path, URI, query, and
      --  payload delimiters as an explicit guard in addition to checking the
      --  individual fields.
      return Ada.Strings.Unbounded.Index (To_Unbounded_String (Line), "/") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Line), "\") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Line), ":/") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Line), "?path=") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Line), "=") = 0;
   end Assert_Empty_State_Display_Line_Has_No_Target_Text;


   function Assert_Empty_State_Suggestion_Display_Lines_Have_No_Target_Text
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      function Text_Is_Target_Free (Text : String) return Boolean is
      begin
         return Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "/") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "\") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), ":/") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "?path=") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "=") = 0;
      end Text_Is_Target_Free;
   begin
      --  Suggestions are rendered separately from the card line by several UI
      --  surfaces.  Guard those final render-facing strings too, not only the
      --  raw snapshot fields, so unavailable reasons cannot smuggle target or
      --  payload-looking text into an empty-state card.
      for I in 1 .. Snapshot.Suggestion_Count loop
         if not Text_Is_Target_Free
           (Suggestion_Display_Line (Snapshot.Suggestions (I)))
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Empty_State_Suggestion_Display_Lines_Have_No_Target_Text;

   function Assert_Empty_State_Array_Suggestion_Budget
     (Snapshots : Empty_State_Snapshot_Array) return Boolean
   is
      Total : Natural := 0;
   begin
      --  Aggregate guidance must remain compact at the array level, not just
      --  per surface.  This prevents a first-use screen from becoming a dense
      --  command list while preserving the bounded per-card suggestion limit.
      for I in Snapshots'Range loop
         if Snapshots (I).Suggestion_Count > Max_Empty_State_Suggestions then
            return False;
         end if;
         Total := Total + Snapshots (I).Suggestion_Count;
      end loop;

      return Total <= Max_Empty_State_Surfaces * Max_Empty_State_Suggestions;
   end Assert_Empty_State_Array_Suggestion_Budget;

   function Assert_Empty_State_Snapshot_Has_No_Target_Text
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      function Text_Is_Target_Free (Text : String) return Boolean is
      begin
         return Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "/") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "\") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), ":/") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "?path=") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "=") = 0;
      end Text_Is_Target_Free;
   begin
      if not Text_Is_Target_Free (To_String (Snapshot.Primary_Message))
        or else not Text_Is_Target_Free (To_String (Snapshot.Secondary_Explanation))
      then
         return False;
      end if;

      for I in 1 .. Snapshot.Suggestion_Count loop
         if not Text_Is_Target_Free (To_String (Snapshot.Suggestions (I).Stable_Name))
           or else not Text_Is_Target_Free (To_String (Snapshot.Suggestions (I).Title))
           or else not Text_Is_Target_Free (To_String (Snapshot.Suggestions (I).Unavailable_Reason))
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Empty_State_Snapshot_Has_No_Target_Text;

   function Contains_Command_Suggestion
     (Snapshot : Empty_State_Snapshot;
      Command  : Editor.Commands.Command_Id) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Command = Command then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Command_Suggestion;

   function Canonical_Surface_Suggestion
     (S       : Editor.State.State_Type;
      Surface : Empty_State_Surface;
      Command : Editor.Commands.Command_Id)
      return Empty_State_Suggested_Command
   is
      Suggestion : Empty_State_Suggested_Command :=
        Command_Suggestion_From_Descriptor (S, Command);
   begin
      if Suggestion.Visible then
         Suggestion.Surface_Source_Label :=
           To_Unbounded_String (Empty_State_Surface_Label (Surface));
      end if;
      return Suggestion;
   end Canonical_Surface_Suggestion;

   function Assert_Empty_State_Is_Display_Only (Snapshot : Empty_State_Snapshot) return Boolean is
   begin
      return Snapshot.Suggestion_Count <= Max_Empty_State_Suggestions
        and then Assert_Empty_State_Suggestions_Have_No_Payloads (Snapshot)
        and then Assert_Empty_State_Suggestion_Source_Labels_Are_Surface_Owned (Snapshot)
        and then Assert_Empty_State_Suggestions_Are_Unique_And_Tail_Clean (Snapshot)
        and then Assert_Empty_State_Suggestion_Tail_Is_Clean (Snapshot)
        and then Assert_Non_Ready_Empty_State_Is_Actionable (Snapshot)
        and then Assert_Ready_Empty_State_Is_Suppressed (Snapshot)
        and then Assert_Empty_State_Suggestions_Are_Visible_Descriptor_Matches (Snapshot)
        and then Assert_Selected_Suggested_Action_Is_Actionable (Snapshot)
        and then Assert_Empty_State_Severity_Is_Semantic (Snapshot)
        and then Assert_Empty_State_Display_Line_Is_Labelled (Snapshot)
        and then Assert_Empty_State_Display_Line_Has_No_Target_Text (Snapshot)
        and then Assert_Empty_State_Suggestion_Display_Lines_Have_No_Target_Text (Snapshot)
        and then Assert_Empty_State_Text_Is_Deterministic_And_Compact (Snapshot)
        and then Assert_Empty_State_Snapshot_Has_No_Target_Text (Snapshot);
   end Assert_Empty_State_Is_Display_Only;

   function Assert_Empty_State_Array_Is_Display_Only
     (Snapshots : Empty_State_Snapshot_Array) return Boolean
   is
      Renderable : Natural := 0;
   begin
      --  Aggregate guidance is the render-facing contract for .  The
      --  array must be canonical, complete, bounded, and each member must obey
      --  the same no-payload/display-only invariants as an individual card.
      if Snapshots'Length /= Max_Empty_State_Surfaces
        or else not Assert_Empty_State_Surface_Model_Is_Closed
        or else not Assert_All_Empty_State_Surfaces_Are_Present_Once (Snapshots)
        or else not Assert_All_Empty_State_Surfaces_In_Canonical_Order (Snapshots)
        or else not Assert_Empty_State_Array_Uses_Canonical_Slots (Snapshots)
        or else not Assert_Empty_State_Array_Suggestion_Budget (Snapshots)
      then
         return False;
      end if;

      for I in Snapshots'Range loop
         if not Assert_Empty_State_Is_Display_Only (Snapshots (I)) then
            return False;
         end if;

         if Empty_State_Should_Render (Snapshots (I)) then
            Renderable := Renderable + 1;
         end if;
      end loop;

      return Renderable = Empty_State_Renderable_Count (Snapshots)
        and then Renderable <= Max_Empty_State_Surfaces;
   end Assert_Empty_State_Array_Is_Display_Only;

   function Assert_Empty_State_Suggestions_Have_No_Payloads (Snapshot : Empty_State_Snapshot) return Boolean is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Carries_Payload
           or else Length (Snapshot.Suggestions (I).Stable_Name) = 0
           or else Length (Snapshot.Suggestions (I).Title) = 0
           or else not Suggestion_Is_Descriptor_Consistent
             (Snapshot.Suggestions (I))
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Empty_State_Suggestions_Have_No_Payloads;

   function Assert_Suggested_Actions_Store_Command_Names_Only
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Command = Editor.Commands.No_Command
           or else not Safe_Stable_Command_Name
             (To_String (Snapshot.Suggestions (I).Stable_Name))
           or else To_String (Snapshot.Suggestions (I).Stable_Name) /=
             Editor.Commands.Name_Metadata.Stable_Command_Name (Snapshot.Suggestions (I).Command)
           or else Snapshot.Suggestions (I).Carries_Payload
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Suggested_Actions_Store_Command_Names_Only;

   function Assert_Suggested_Action_Open_Palette_Carries_No_Payload
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean
   is
   begin
      if Index > Snapshot.Suggestion_Count
        or else Index > Max_Empty_State_Suggestions
      then
         return False;
      end if;

      return Suggestion_Is_Activation_Safe (Snapshot.Suggestions (Index))
        and then not Snapshot.Suggestions (Index).Carries_Payload
        and then Safe_Stable_Command_Name
          (To_String (Snapshot.Suggestions (Index).Stable_Name));
   end Assert_Suggested_Action_Open_Palette_Carries_No_Payload;

   function Assert_Suggested_Action_Activation_Mode_Is_Coherent
     (Suggestion : Empty_State_Suggested_Command) return Boolean
   is
   begin
      if not Suggestion.Visible then
         return True;
      end if;

      if not Suggestion_Is_Activation_Safe (Suggestion)
        or else Suggestion.Carries_Payload
        or else Length (Suggestion.Availability_Label) = 0
      then
         return False;
      end if;

      case Suggestion.Activation_Mode is
         when Suggestion_Display_Only =>
            return not Suggestion.Selected;
         when Suggestion_Open_In_Command_Palette
            | Suggestion_Execute_Through_Executor =>
            return True;
      end case;
   end Assert_Suggested_Action_Activation_Mode_Is_Coherent;

   function Assert_Suggested_Action_Source_Label_Is_Surface_Owned
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean
   is
   begin
      if Index > Snapshot.Suggestion_Count
        or else Index > Max_Empty_State_Suggestions
      then
         return False;
      end if;

      return Length (Snapshot.Suggestions (Index).Surface_Source_Label) > 0
        and then To_String (Snapshot.Suggestions (Index).Surface_Source_Label) =
          Empty_State_Surface_Label (Snapshot.Surface);
   end Assert_Suggested_Action_Source_Label_Is_Surface_Owned;

   function Assert_Suggested_Action_Metadata_Is_Current
     (Suggestion : Empty_State_Suggested_Command) return Boolean
   is
      Found    : Boolean := False;
      Resolved : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Name     : constant String := To_String (Suggestion.Stable_Name);
   begin
      if not Suggestion.Visible then
         return True;
      end if;

      if not Safe_Stable_Command_Name (Name) then
         return False;
      end if;

      Resolved := Editor.Commands.Name_Metadata.Command_Id_From_Stable_Name (Name, Found);
      if not Found
        or else Resolved /= Suggestion.Command
        or else Suggestion.Command = Editor.Commands.No_Command
      then
         return False;
      end if;

      declare
         D : constant Editor.Commands.Descriptors.Command_Descriptor :=
           Editor.Commands.Descriptors.Descriptor (Suggestion.Command);
      begin
         return Command_Is_Visible_In_Guidance (Suggestion.Command)
           and then Name = Editor.Commands.Name_Metadata.Stable_Command_Name (Suggestion.Command)
           and then To_String (Suggestion.Title) = To_String (D.Name)
           and then To_String (Suggestion.Short_Explanation) = To_String (D.Description)
           and then not Suggestion.Carries_Payload;
      end;
   end Assert_Suggested_Action_Metadata_Is_Current;

   function Assert_Suggested_Action_Availability_Label_Is_Current
     (S          : Editor.State.State_Type;
      Suggestion : Empty_State_Suggested_Command) return Boolean
   is
      Current : Empty_State_Suggested_Command;
   begin
      if not Suggestion.Visible then
         return True;
      end if;

      if Suggestion.Command = Editor.Commands.No_Command then
         return False;
      end if;

      Current := Command_Suggestion_From_Descriptor (S, Suggestion.Command);
      return Current.Visible
        and then Current.Available = Suggestion.Available
        and then To_String (Current.Unavailable_Reason) =
          To_String (Suggestion.Unavailable_Reason)
        and then Suggested_Action_Availability_Label (Current) =
          Suggested_Action_Availability_Label (Suggestion);
   end Assert_Suggested_Action_Availability_Label_Is_Current;

   function Assert_Suggested_Action_Is_Canonical_Surface_Projection
     (S          : Editor.State.State_Type;
      Surface    : Empty_State_Surface;
      Suggestion : Empty_State_Suggested_Command) return Boolean
   is
      Canonical : Empty_State_Suggested_Command;
   begin
      if not Suggestion.Visible then
         return True;
      end if;

      if Suggestion.Command = Editor.Commands.No_Command then
         return False;
      end if;

      Canonical := Canonical_Surface_Suggestion
        (S, Surface, Suggestion.Command);

      return Canonical.Visible
        and then Canonical.Command = Suggestion.Command
        and then To_String (Canonical.Stable_Name) =
          To_String (Suggestion.Stable_Name)
        and then To_String (Canonical.Title) = To_String (Suggestion.Title)
        and then To_String (Canonical.Short_Explanation) =
          To_String (Suggestion.Short_Explanation)
        and then To_String (Canonical.Surface_Source_Label) =
          To_String (Suggestion.Surface_Source_Label)
        and then To_String (Canonical.Availability_Label) =
          To_String (Suggestion.Availability_Label)
        and then Canonical.Activation_Mode = Suggestion.Activation_Mode
        and then Canonical.Available = Suggestion.Available
        and then To_String (Canonical.Unavailable_Reason) =
          To_String (Suggestion.Unavailable_Reason)
        and then Canonical.Visible = Suggestion.Visible
        and then Canonical.Carries_Payload = Suggestion.Carries_Payload;
   end Assert_Suggested_Action_Is_Canonical_Surface_Projection;

   function Assert_Empty_State_Suggestions_Are_Canonical_Surface_Projections
     (S        : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if not Assert_Suggested_Action_Is_Canonical_Surface_Projection
           (S, Snapshot.Surface, Snapshot.Suggestions (I))
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Empty_State_Suggestions_Are_Canonical_Surface_Projections;

   function Assert_Empty_State_Suggestion_Source_Labels_Are_Surface_Owned
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if not Assert_Suggested_Action_Source_Label_Is_Surface_Owned
           (Snapshot, Positive (I))
         then
            return False;
         end if;
      end loop;

      for I in Snapshot.Suggestion_Count + 1 .. Max_Empty_State_Suggestions loop
         if Length (Snapshot.Suggestions (I).Surface_Source_Label) > 0
           or else Snapshot.Suggestions (I).Selected
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Empty_State_Suggestion_Source_Labels_Are_Surface_Owned;

   function Assert_Selected_Suggested_Action_Is_Actionable
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      Selected : constant Natural := Suggested_Action_Selected_Index (Snapshot);
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Selected then
            return Selected = I
              and then Suggestion_Is_Selectable (Snapshot.Suggestions (I));
         end if;
      end loop;

      return Selected = 0;
   end Assert_Selected_Suggested_Action_Is_Actionable;

   function Assert_Suggested_Action_Index_Is_Activatable
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean
   is
      Selected : constant Natural := Suggested_Action_Selected_Index (Snapshot);
      Markers  : Natural := 0;
   begin
      if Index > Snapshot.Suggestion_Count
        or else Index > Max_Empty_State_Suggestions
      then
         return False;
      end if;

      for I in 1 .. Max_Empty_State_Suggestions loop
         if Snapshot.Suggestions (I).Selected then
            Markers := Markers + 1;
         end if;
      end loop;

      if Markers > 1 then
         return False;
      elsif Markers = 1 and then Selected /= Index then
         return False;
      end if;

      return Suggestion_Is_Activation_Safe (Snapshot.Suggestions (Index))
        and then not Snapshot.Suggestions (Index).Carries_Payload
        and then Length (Snapshot.Suggestions (Index).Availability_Label) > 0
        and then Assert_Suggested_Action_Activation_Mode_Is_Coherent
          (Snapshot.Suggestions (Index));
   end Assert_Suggested_Action_Index_Is_Activatable;

   function Assert_Empty_State_Suggestion_Tail_Is_Clean
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      if Snapshot.Suggestion_Count > Max_Empty_State_Suggestions then
         return False;
      end if;

      for I in Snapshot.Suggestion_Count + 1 .. Max_Empty_State_Suggestions loop
         if Snapshot.Suggestions (I).Command /= Editor.Commands.No_Command
           or else Length (Snapshot.Suggestions (I).Stable_Name) /= 0
           or else Length (Snapshot.Suggestions (I).Title) /= 0
           or else Length (Snapshot.Suggestions (I).Short_Explanation) /= 0
           or else Length (Snapshot.Suggestions (I).Surface_Source_Label) /= 0
           or else Length (Snapshot.Suggestions (I).Availability_Label) /= 0
           or else Snapshot.Suggestions (I).Activation_Mode /=
             Empty_Command_Suggestion.Activation_Mode
           or else Snapshot.Suggestions (I).Selected
           or else Snapshot.Suggestions (I).Available
           or else Length (Snapshot.Suggestions (I).Unavailable_Reason) /= 0
           or else Snapshot.Suggestions (I).Visible
           or else Snapshot.Suggestions (I).Carries_Payload
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Empty_State_Suggestion_Tail_Is_Clean;

   function Assert_Unavailable_Suggested_Action_Does_Not_Execute
     (Suggestion : Empty_State_Suggested_Command;
      Result     : Editor.Executor.Command_Execution_Result) return Boolean
   is
   begin
      if Suggestion.Available then
         return True;
      end if;

      return Result.Command = Suggestion.Command
        and then Result.Status = Editor.Executor.Command_Unavailable;
   end Assert_Unavailable_Suggested_Action_Does_Not_Execute;

   function Assert_Keybindings_Have_No_Suggestion_Payloads return Boolean
   is
   begin
      --  Keybindings expose command ids and chords only.  A suggestion cannot
      --  inject file/project/result/candidate context because no such field
      --  exists in the keybinding lookup contract.  Lock this to the absence
      --  of dedicated suggestion commands in the currently bound command set.
      for I in 1 .. Editor.Keybindings.Bound_Command_Count loop
         declare
            Command : constant Editor.Commands.Command_Id :=
              Editor.Keybindings.Bound_Command_At (Positive (I));
            Stable : constant String := Editor.Commands.Name_Metadata.Stable_Command_Name (Command);
         begin
            if Stable'Length = 0
              or else Ada.Strings.Unbounded.Index
                (To_Unbounded_String (Stable), "suggestion.") /= 0
            then
               return False;
            end if;
         end;
      end loop;

      return True;
   end Assert_Keybindings_Have_No_Suggestion_Payloads;

   function Assert_First_Run_Guidance_Fabricates_No_Project
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Project.Has_Project (Before.Project) =
        Editor.Project.Has_Project (After.Project)
        and then Before.Active_Buffer_Token = After.Active_Buffer_Token
        and then Before.File_Info.Has_Path = After.File_Info.Has_Path
        and then Editor.Recent_Projects.Count (Before.Recent_Projects) =
          Editor.Recent_Projects.Count (After.Recent_Projects);
   end Assert_First_Run_Guidance_Fabricates_No_Project;

   function Assert_Render_Empty_State_Construction_Is_Observational
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Empty_State_Guidance.Audits.Assert_Render_Empty_State_Construction_Is_Observational
        (Before, After);
   end Assert_Render_Empty_State_Construction_Is_Observational;

   function Assert_Empty_State_Not_Persisted
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Empty_State_Guidance.Audits.Assert_Empty_State_Not_Persisted
        (Before, After);
   end Assert_Empty_State_Not_Persisted;

   function Assert_Empty_State_Suggestions_Are_Descriptor_Derived
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      D : Editor.Commands.Descriptors.Command_Descriptor;
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if not Snapshot.Suggestions (I).Visible
           or else Snapshot.Suggestions (I).Command = Editor.Commands.No_Command
         then
            return False;
         end if;

         D := Editor.Commands.Descriptors.Descriptor (Snapshot.Suggestions (I).Command);
         if not Command_Is_Visible_In_Guidance (Snapshot.Suggestions (I).Command)
           or else To_String (Snapshot.Suggestions (I).Title) /= To_String (D.Name)
           or else To_String (Snapshot.Suggestions (I).Stable_Name) /=
             Editor.Commands.Name_Metadata.Stable_Command_Name (Snapshot.Suggestions (I).Command)
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Empty_State_Suggestions_Are_Descriptor_Derived;

   function Assert_Empty_State_Suggestions_Are_Stable_Names_Only
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         declare
            Name : constant String := To_String (Snapshot.Suggestions (I).Stable_Name);
         begin
            if Snapshot.Suggestions (I).Carries_Payload
              or else not Stable_Name_Is_Display_Only (Name)
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Assert_Empty_State_Suggestions_Are_Stable_Names_Only;

   function Assert_Empty_State_Suggestions_Resolve_From_Stable_Names
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      Found    : Boolean := False;
      Resolved : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         Resolved := Editor.Commands.Name_Metadata.Command_Id_From_Stable_Name
           (To_String (Snapshot.Suggestions (I).Stable_Name), Found);
         if not Found
           or else Resolved = Editor.Commands.No_Command
           or else Resolved /= Snapshot.Suggestions (I).Command
           or else not Suggestion_Is_Descriptor_Consistent
             (Snapshot.Suggestions (I))
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Empty_State_Suggestions_Resolve_From_Stable_Names;

   function Assert_Empty_State_Suggestions_Are_Visible_Descriptor_Matches
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if not Suggestion_Is_Descriptor_Consistent (Snapshot.Suggestions (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Empty_State_Suggestions_Are_Visible_Descriptor_Matches;

   function Assert_Empty_State_Suggestions_Are_Unique_And_Tail_Clean
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      if Snapshot.Suggestion_Count > Max_Empty_State_Suggestions then
         return False;
      end if;

      for I in 1 .. Snapshot.Suggestion_Count loop
         for J in I + 1 .. Snapshot.Suggestion_Count loop
            if Snapshot.Suggestions (I).Command = Snapshot.Suggestions (J).Command
              or else To_String (Snapshot.Suggestions (I).Stable_Name) =
                To_String (Snapshot.Suggestions (J).Stable_Name)
            then
               return False;
            end if;
         end loop;
      end loop;

      if Snapshot.Suggestion_Count < Max_Empty_State_Suggestions then
         for I in Snapshot.Suggestion_Count + 1 .. Max_Empty_State_Suggestions loop
            if Snapshot.Suggestions (I).Command /= Editor.Commands.No_Command
              or else Snapshot.Suggestions (I).Visible
              or else Snapshot.Suggestions (I).Carries_Payload
              or else Length (Snapshot.Suggestions (I).Stable_Name) /= 0
              or else Length (Snapshot.Suggestions (I).Title) /= 0
              or else Length (Snapshot.Suggestions (I).Unavailable_Reason) /= 0
            then
               return False;
            end if;
         end loop;
      end if;

      return True;
   end Assert_Empty_State_Suggestions_Are_Unique_And_Tail_Clean;

   function Assert_Non_Ready_Empty_State_Is_Actionable
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      --  Ready snapshots may legitimately be pure status. Every other Phase
      --  569 guidance card should point at at least one descriptor-derived
      --  command, even if that command is currently unavailable and shows its
      --  normal availability reason. This keeps empty states useful without
      --  adding payloads or implicit actions.
      if Snapshot.Kind = Ready_State then
         return True;
      end if;

      if Snapshot.Suggestion_Count = 0 then
         return False;
      end if;

      for I in 1 .. Snapshot.Suggestion_Count loop
         if Suggestion_Is_Descriptor_Consistent (Snapshot.Suggestions (I)) then
            return True;
         end if;
      end loop;

      return False;
   end Assert_Non_Ready_Empty_State_Is_Actionable;

   function Assert_Ready_Empty_State_Is_Suppressed
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      if Snapshot.Kind = Ready_State then
         return not Empty_State_Should_Render (Snapshot);
      end if;

      return Empty_State_Should_Render (Snapshot);
   end Assert_Ready_Empty_State_Is_Suppressed;

   function Assert_All_Empty_State_Surfaces_In_Canonical_Order
     (Snapshots : Empty_State_Snapshot_Array) return Boolean
   is
   begin
      if Snapshots'Length /= Max_Empty_State_Surfaces
        or else not Assert_Empty_State_Surface_Model_Is_Closed
      then
         return False;
      end if;

      for I in Snapshots'Range loop
         if Snapshots (I).Surface /= Empty_State_Surface_For_Slot (I) then
            return False;
         end if;
      end loop;

      return True;
   end Assert_All_Empty_State_Surfaces_In_Canonical_Order;

   function Assert_Empty_State_Array_Uses_Canonical_Slots
     (Snapshots : Empty_State_Snapshot_Array) return Boolean
   is
   begin
      if Snapshots'Length /= Max_Empty_State_Surfaces
        or else not Assert_Empty_State_Surface_Model_Is_Closed
      then
         return False;
      end if;

      for I in Snapshots'Range loop
         if Snapshots (I).Surface /= Empty_State_Surface_For_Slot (I)
           or else Empty_State_Slot_For_Surface (Snapshots (I).Surface) /= I
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Empty_State_Array_Uses_Canonical_Slots;

   function Assert_Empty_State_Activation_Uses_Executor
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Command : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Editor.Empty_State_Guidance.Audits.Assert_Empty_State_Activation_Uses_Executor
        (Before, After, Result, Command);
   end Assert_Empty_State_Activation_Uses_Executor;

   function Assert_Major_Empty_State_Surface_Coverage
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Empty_State_Guidance.Audits.Assert_Major_Empty_State_Surface_Coverage (S);
   end Assert_Major_Empty_State_Surface_Coverage;

   function Assert_All_Empty_State_Surfaces_Are_Present_Once
     (Snapshots : Empty_State_Snapshot_Array) return Boolean
   is
      Seen : array (Empty_State_Surface) of Boolean := (others => False);
   begin
      if Snapshots'Length /= Max_Empty_State_Surfaces then
         return False;
      end if;

      for I in Snapshots'Range loop
         if Seen (Snapshots (I).Surface) then
            return False;
         end if;
         Seen (Snapshots (I).Surface) := True;
      end loop;

      for Surface in Empty_State_Surface loop
         if not Seen (Surface) then
            return False;
         end if;
      end loop;

      return True;
   end Assert_All_Empty_State_Surfaces_Are_Present_Once;

   function Assert_First_Use_Empty_State_Guidance_Coherent return Boolean is
   begin
      return Editor.Empty_State_Guidance.Audits.Assert_First_Use_Empty_State_Guidance_Coherent;
   end Assert_First_Use_Empty_State_Guidance_Coherent;

end Editor.Empty_State_Guidance;
