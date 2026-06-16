with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Overload_RM_Edge_Legality is

   pragma Suppress (Overflow_Check);

   package Preference renames Editor.Ada_Overload_Preference_Legality;
   package Replay renames Editor.Ada_Generic_Instance_Body_Semantic_Replay;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Preference.Preference_Legality_Status;
   use type Replay.Replay_Status;
   use type Gates.Enforcement_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 307) + (B * 47) + 1141) mod 1_000_000_007;
   end Mix;

   function Lower (S : String) return String is
      R : String := S;
   begin
      for I in R'Range loop
         R (I) := Ada.Characters.Handling.To_Lower (R (I));
      end loop;
      return R;
   end Lower;

   function Kind_Slot (Kind : RM_Edge_Context_Kind) return Natural is
   begin
      return RM_Edge_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : RM_Edge_Legality_Status) return Natural is
   begin
      return RM_Edge_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Preference_Is_Error
     (Status : Preference.Preference_Legality_Status) return Boolean is
   begin
      return Status in
        Preference.Preference_Legality_Ambiguous_Homograph_Tie |
        Preference.Preference_Legality_Ambiguous_Visibility_Tie |
        Preference.Preference_Legality_Ambiguous_Profile_Tie |
        Preference.Preference_Legality_Ambiguous_Expected_Type_Tie |
        Preference.Preference_Legality_Ambiguous_Universal_Numeric_Tie |
        Preference.Preference_Legality_Ambiguous_Conversion_Tie |
        Preference.Preference_Legality_Ambiguous_After_RM_Preferences |
        Preference.Preference_Legality_No_Legal_Overload_Input |
        Preference.Preference_Legality_Linked_Overload_Legality_Error |
        Preference.Preference_Legality_Unknown |
        Preference.Preference_Legality_Indeterminate;
   end Preference_Is_Error;

   function Replay_Is_Error (Status : Replay.Replay_Status) return Boolean is
   begin
      return Status in
        Replay.Replay_Generic_Expansion_Error |
        Replay.Replay_Overload_Preference_Error |
        Replay.Replay_Flow_Effect_Error |
        Replay.Replay_Predicate_Propagation_Error |
        Replay.Replay_Accessibility_Precision_Error |
        Replay.Replay_Representation_Freezing_Error |
        Replay.Replay_Coverage_Gate_Blocker |
        Replay.Replay_Source_Instance_Mapping_Missing |
        Replay.Replay_Formal_Actual_Mapping_Missing |
        Replay.Replay_Diagnostic_Backmap_Missing |
        Replay.Replay_Multiple_Blockers |
        Replay.Replay_Indeterminate;
   end Replay_Is_Error;

   function Gate_Is_Blocker (Status : Gates.Enforcement_Status) return Boolean is
   begin
      return Status in
        Gates.Enforcement_Degraded_To_Indeterminate |
        Gates.Enforcement_Cross_Unit_Closure_Required |
        Gates.Enforcement_Legal_Result_Suppressed |
        Gates.Enforcement_Derived_Result_Suppressed |
        Gates.Enforcement_Parser_AST_Blocker |
        Gates.Enforcement_Metadata_Blocker |
        Gates.Enforcement_Consumer_Integration_Blocker |
        Gates.Enforcement_Unsafe_Result_Blocked;
   end Gate_Is_Blocker;

   function Is_Legal (Status : RM_Edge_Legality_Status) return Boolean is
   begin
      return Status in
        RM_Edge_Legality_Legal_Universal_Integer |
        RM_Edge_Legality_Legal_Universal_Real |
        RM_Edge_Legality_Legal_Universal_Fixed |
        RM_Edge_Legality_Legal_Root_Numeric_Preferred |
        RM_Edge_Legality_Legal_Inherited_Primitive_Visible |
        RM_Edge_Legality_Legal_Homograph_Hidden |
        RM_Edge_Legality_Legal_Dispatching_Selected |
        RM_Edge_Legality_Legal_Nondispatching_Selected |
        RM_Edge_Legality_Legal_Access_Subprogram_Profile |
        RM_Edge_Legality_Legal_Generic_Formal_Subprogram |
        RM_Edge_Legality_Legal_Nested_Generic_Selected;
   end Is_Legal;

   function Is_Ambiguous (Status : RM_Edge_Legality_Status) return Boolean is
   begin
      return Status in
        RM_Edge_Legality_Universal_Fixed_Ambiguous |
        RM_Edge_Legality_Root_Numeric_Ambiguous |
        RM_Edge_Legality_Inherited_Primitive_Hiding_Ambiguous |
        RM_Edge_Legality_Dispatching_Nondispatching_Ambiguous |
        RM_Edge_Legality_Generic_Formal_Subprogram_Ambiguous |
        RM_Edge_Legality_Nested_Generic_Defaulted_Formal_Ambiguous |
        RM_Edge_Legality_Nested_Generic_Named_Actual_Ambiguous;
   end Is_Ambiguous;

   function Context_Fingerprint (Info : RM_Edge_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Length (Info.Designator) + 1);
      H := Mix (H, Info.Universal_Integer_Count + 1);
      H := Mix (H, Info.Universal_Real_Count + 1);
      H := Mix (H, Info.Universal_Fixed_Count + 1);
      H := Mix (H, Info.Root_Numeric_Count + 1);
      H := Mix (H, Info.Inherited_Primitive_Count + 1);
      H := Mix (H, Info.Hidden_Homograph_Count + 1);
      H := Mix (H, Info.Visible_Homograph_Count + 1);
      H := Mix (H, Info.Dispatching_Candidate_Count + 1);
      H := Mix (H, Info.Nondispatching_Candidate_Count + 1);
      H := Mix (H, Info.Access_Subprogram_Profile_Count + 1);
      H := Mix (H, Info.Access_Subprogram_Mode_Mismatch_Count + 1);
      H := Mix (H, Info.Access_Subprogram_Result_Mismatch_Count + 1);
      H := Mix (H, Info.Generic_Formal_Subprogram_Count + 1);
      H := Mix (H, Info.Nested_Generic_Defaulted_Formal_Tie_Count + 1);
      H := Mix (H, Info.Nested_Generic_Named_Actual_Tie_Count + 1);
      H := Mix (H, Info.Ambiguous_Candidate_Count + 1);
      H := Mix (H, Preference.Preference_Legality_Status'Pos (Info.Linked_Preference_Status) + 1);
      H := Mix (H, Replay.Replay_Status'Pos (Info.Linked_Replay_Status) + 1);
      H := Mix (H, Gates.Enforcement_Status'Pos (Info.Gate_Status) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : RM_Edge_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Preference.Preference_Legality_Status'Pos (Info.Linked_Preference_Status) + 1);
      H := Mix (H, Replay.Replay_Status'Pos (Info.Linked_Replay_Status) + 1);
      H := Mix (H, Gates.Enforcement_Status'Pos (Info.Gate_Status) + 1);
      H := Mix (H, Info.Selected_Candidate_Count + 1);
      H := Mix (H, Info.Ambiguous_Candidate_Count + 1);
      H := Mix (H, Info.Blocker_Count + 1);
      H := Mix (H, Length (Info.Designator) + Length (Info.Message) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : RM_Edge_Legality_Status) return String is
   begin
      case Status is
         when RM_Edge_Legality_Legal_Universal_Integer =>
            return "universal integer overload edge was resolved";
         when RM_Edge_Legality_Legal_Universal_Real =>
            return "universal real overload edge was resolved";
         when RM_Edge_Legality_Legal_Universal_Fixed =>
            return "universal fixed overload edge was resolved";
         when RM_Edge_Legality_Legal_Root_Numeric_Preferred =>
            return "root numeric preference selected the overload";
         when RM_Edge_Legality_Legal_Inherited_Primitive_Visible =>
            return "inherited primitive remains visible after homograph checks";
         when RM_Edge_Legality_Legal_Homograph_Hidden =>
            return "hidden homograph was excluded before overload selection";
         when RM_Edge_Legality_Legal_Dispatching_Selected =>
            return "dispatching primitive was selected";
         when RM_Edge_Legality_Legal_Nondispatching_Selected =>
            return "nondispatching candidate was selected";
         when RM_Edge_Legality_Legal_Access_Subprogram_Profile =>
            return "access-to-subprogram overload profile conforms";
         when RM_Edge_Legality_Legal_Generic_Formal_Subprogram =>
            return "generic formal subprogram overload conforms";
         when RM_Edge_Legality_Legal_Nested_Generic_Selected =>
            return "nested generic overload selected after named/defaulted formal checks";
         when RM_Edge_Legality_Universal_Fixed_Ambiguous =>
            return "universal fixed overload candidates remain ambiguous";
         when RM_Edge_Legality_Root_Numeric_Ambiguous =>
            return "root numeric overload preference remains ambiguous";
         when RM_Edge_Legality_Inherited_Primitive_Hiding_Ambiguous =>
            return "inherited primitive hiding leaves ambiguous candidates";
         when RM_Edge_Legality_Homograph_Hiding_Error =>
            return "homograph hiding does not exclude the illegal overload candidate";
         when RM_Edge_Legality_Dispatching_Nondispatching_Ambiguous =>
            return "dispatching and nondispatching candidates remain ambiguous";
         when RM_Edge_Legality_Access_Subprogram_Profile_Mismatch =>
            return "access-to-subprogram overload profile mismatch";
         when RM_Edge_Legality_Access_Subprogram_Mode_Mismatch =>
            return "access-to-subprogram parameter mode mismatch";
         when RM_Edge_Legality_Access_Subprogram_Result_Mismatch =>
            return "access-to-subprogram result subtype mismatch";
         when RM_Edge_Legality_Generic_Formal_Subprogram_Ambiguous =>
            return "generic formal subprogram overload remains ambiguous";
         when RM_Edge_Legality_Nested_Generic_Defaulted_Formal_Ambiguous =>
            return "nested generic defaulted formal ambiguity remains";
         when RM_Edge_Legality_Nested_Generic_Named_Actual_Ambiguous =>
            return "nested generic named actual ambiguity remains";
         when RM_Edge_Legality_Linked_Preference_Error =>
            return "linked overload preference error blocks RM edge refinement";
         when RM_Edge_Legality_Linked_Generic_Replay_Error =>
            return "generic replay error blocks overload edge refinement";
         when RM_Edge_Legality_Coverage_Gate_Blocker =>
            return "coverage gate blocks confident overload edge legality";
         when RM_Edge_Legality_Multiple_Blockers =>
            return "multiple overload edge blockers are present";
         when RM_Edge_Legality_Unknown =>
            return "RM overload edge legality is unknown";
         when RM_Edge_Legality_Indeterminate =>
            return "RM overload edge legality is indeterminate";
         when RM_Edge_Legality_Not_Checked =>
            return "RM overload edge legality was not checked";
      end case;
   end Message_For;

   function Classify (Context : RM_Edge_Context_Info) return RM_Edge_Legality_Status is
      Blockers : Natural := 0;
   begin
      if Gate_Is_Blocker (Context.Gate_Status) then
         Blockers := Blockers + 1;
      end if;
      if Preference_Is_Error (Context.Linked_Preference_Status) then
         Blockers := Blockers + 1;
      end if;
      if Replay_Is_Error (Context.Linked_Replay_Status) then
         Blockers := Blockers + 1;
      end if;

      if Blockers > 1 then
         return RM_Edge_Legality_Multiple_Blockers;
      elsif Blockers = 1 and then Gate_Is_Blocker (Context.Gate_Status) then
         if Context.Gate_Status = Gates.Enforcement_Degraded_To_Indeterminate then
            return RM_Edge_Legality_Indeterminate;
         else
            return RM_Edge_Legality_Coverage_Gate_Blocker;
         end if;
      elsif Blockers = 1 and then Preference_Is_Error (Context.Linked_Preference_Status) then
         return RM_Edge_Legality_Linked_Preference_Error;
      elsif Blockers = 1 then
         return RM_Edge_Legality_Linked_Generic_Replay_Error;
      elsif Context.Access_Subprogram_Mode_Mismatch_Count > 0 then
         return RM_Edge_Legality_Access_Subprogram_Mode_Mismatch;
      elsif Context.Access_Subprogram_Result_Mismatch_Count > 0 then
         return RM_Edge_Legality_Access_Subprogram_Result_Mismatch;
      elsif Context.Access_Subprogram_Profile_Count = 0
        and then Context.Kind = RM_Edge_Context_Access_To_Subprogram
      then
         return RM_Edge_Legality_Access_Subprogram_Profile_Mismatch;
      elsif Context.Nested_Generic_Defaulted_Formal_Tie_Count > 0 then
         return RM_Edge_Legality_Nested_Generic_Defaulted_Formal_Ambiguous;
      elsif Context.Nested_Generic_Named_Actual_Tie_Count > 0 then
         return RM_Edge_Legality_Nested_Generic_Named_Actual_Ambiguous;
      elsif Context.Generic_Formal_Subprogram_Count > 1
        and then Context.Ambiguous_Candidate_Count > 0
      then
         return RM_Edge_Legality_Generic_Formal_Subprogram_Ambiguous;
      elsif Context.Dispatching_Candidate_Count > 0
        and then Context.Nondispatching_Candidate_Count > 0
        and then Context.Ambiguous_Candidate_Count > 0
      then
         return RM_Edge_Legality_Dispatching_Nondispatching_Ambiguous;
      elsif Context.Inherited_Primitive_Count > 0
        and then Context.Visible_Homograph_Count > 0
        and then Context.Hidden_Homograph_Count = 0
      then
         return RM_Edge_Legality_Inherited_Primitive_Hiding_Ambiguous;
      elsif Context.Hidden_Homograph_Count > 0
        and then Context.Visible_Homograph_Count > 0
        and then Context.Ambiguous_Candidate_Count > 0
      then
         return RM_Edge_Legality_Homograph_Hiding_Error;
      elsif Context.Root_Numeric_Count > 1 then
         return RM_Edge_Legality_Root_Numeric_Ambiguous;
      elsif Context.Universal_Fixed_Count > 1 then
         return RM_Edge_Legality_Universal_Fixed_Ambiguous;
      elsif Context.Kind = RM_Edge_Context_Access_To_Subprogram
        and then Context.Access_Subprogram_Profile_Count = 1
      then
         return RM_Edge_Legality_Legal_Access_Subprogram_Profile;
      elsif Context.Kind = RM_Edge_Context_Generic_Formal_Subprogram
        and then Context.Generic_Formal_Subprogram_Count = 1
      then
         return RM_Edge_Legality_Legal_Generic_Formal_Subprogram;
      elsif Context.Kind = RM_Edge_Context_Nested_Generic_Call
        and then Context.Ambiguous_Candidate_Count = 0
      then
         return RM_Edge_Legality_Legal_Nested_Generic_Selected;
      elsif Context.Dispatching_Candidate_Count = 1
        and then Context.Nondispatching_Candidate_Count = 0
      then
         return RM_Edge_Legality_Legal_Dispatching_Selected;
      elsif Context.Nondispatching_Candidate_Count = 1
        and then Context.Dispatching_Candidate_Count = 0
      then
         return RM_Edge_Legality_Legal_Nondispatching_Selected;
      elsif Context.Hidden_Homograph_Count > 0
        and then Context.Visible_Homograph_Count = 0
      then
         return RM_Edge_Legality_Legal_Homograph_Hidden;
      elsif Context.Inherited_Primitive_Count = 1
        and then Context.Visible_Homograph_Count = 0
      then
         return RM_Edge_Legality_Legal_Inherited_Primitive_Visible;
      elsif Context.Root_Numeric_Count = 1 then
         return RM_Edge_Legality_Legal_Root_Numeric_Preferred;
      elsif Context.Universal_Fixed_Count = 1 then
         return RM_Edge_Legality_Legal_Universal_Fixed;
      elsif Context.Universal_Integer_Count = 1
        and then Context.Universal_Real_Count = 0
      then
         return RM_Edge_Legality_Legal_Universal_Integer;
      elsif Context.Universal_Real_Count = 1
        and then Context.Universal_Integer_Count = 0
      then
         return RM_Edge_Legality_Legal_Universal_Real;
      elsif Context.Ambiguous_Candidate_Count > 0 then
         return RM_Edge_Legality_Indeterminate;
      else
         return RM_Edge_Legality_Unknown;
      end if;
   end Classify;

   function Blocker_Count (Context : RM_Edge_Context_Info) return Natural is
      Result : Natural := 0;
   begin
      if Gate_Is_Blocker (Context.Gate_Status) then
         Result := Result + 1;
      end if;
      if Preference_Is_Error (Context.Linked_Preference_Status) then
         Result := Result + 1;
      end if;
      if Replay_Is_Error (Context.Linked_Replay_Status) then
         Result := Result + 1;
      end if;
      return Result;
   end Blocker_Count;

   procedure Clear (Model : in out RM_Edge_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out RM_Edge_Context_Model;
      Info  : RM_Edge_Context_Info) is
      Next : RM_Edge_Context_Info := Info;
   begin
      if Next.Id = No_RM_Edge_Context then
         Next.Id := RM_Edge_Context_Id (Natural (Model.Contexts.Length) + 1);
      end if;
      Model.Contexts.Append (Next);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Context_Fingerprint (Next));
   end Add_Context;

   function Context_Count (Model : RM_Edge_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : RM_Edge_Context_Model;
      Index : Positive) return RM_Edge_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : RM_Edge_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : RM_Edge_Context_Model) return RM_Edge_Legality_Model is
      Model : RM_Edge_Legality_Model;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant RM_Edge_Context_Info := Contexts.Contexts.Element (I);
            Row : RM_Edge_Legality_Info;
         begin
            Row.Id := RM_Edge_Legality_Id (I);
            Row.Context := C.Id;
            Row.Kind := C.Kind;
            Row.Node := C.Node;
            Row.Status := Classify (C);
            Row.Designator := C.Designator;
            Row.Message := To_Unbounded_String (Message_For (Row.Status));
            Row.Detail := To_Unbounded_String
              ("RM overload edge context=" & RM_Edge_Context_Kind'Image (C.Kind));
            Row.Linked_Preference_Status := C.Linked_Preference_Status;
            Row.Linked_Replay_Status := C.Linked_Replay_Status;
            Row.Gate_Status := C.Gate_Status;
            Row.Selected_Candidate_Count :=
              C.Universal_Integer_Count + C.Universal_Real_Count +
              C.Universal_Fixed_Count + C.Root_Numeric_Count +
              C.Access_Subprogram_Profile_Count + C.Generic_Formal_Subprogram_Count +
              C.Dispatching_Candidate_Count + C.Nondispatching_Candidate_Count;
            Row.Ambiguous_Candidate_Count := C.Ambiguous_Candidate_Count;
            Row.Blocker_Count := Blocker_Count (C);
            Row.Start_Line := C.Start_Line;
            Row.Start_Column := C.Start_Column;
            Row.End_Line := C.End_Line;
            Row.End_Column := C.End_Column;
            Row.Source_Fingerprint := C.Source_Fingerprint;
            Row.Fingerprint := Row_Fingerprint (Row);
            Model.Items.Append (Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);

            if Is_Legal (Row.Status) then
               Model.Legal_Total := Model.Legal_Total + 1;
            end if;
            if Is_Ambiguous (Row.Status) then
               Model.Ambiguous_Total := Model.Ambiguous_Total + 1;
            end if;
            if Row.Status = RM_Edge_Legality_Linked_Preference_Error then
               Model.Preference_Error_Total := Model.Preference_Error_Total + 1;
            elsif Row.Status = RM_Edge_Legality_Linked_Generic_Replay_Error then
               Model.Generic_Replay_Error_Total := Model.Generic_Replay_Error_Total + 1;
            elsif Row.Status = RM_Edge_Legality_Coverage_Gate_Blocker then
               Model.Coverage_Gate_Error_Total := Model.Coverage_Gate_Error_Total + 1;
            elsif Row.Status = RM_Edge_Legality_Multiple_Blockers then
               Model.Multiple_Blocker_Total := Model.Multiple_Blocker_Total + 1;
            elsif Row.Status = RM_Edge_Legality_Indeterminate then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : RM_Edge_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : RM_Edge_Legality_Model;
      Index : Positive) return RM_Edge_Legality_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : RM_Edge_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Edge_Legality_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : RM_Edge_Legality_Model;
      Status : RM_Edge_Legality_Status) return RM_Edge_Result_Set is
      Results : RM_Edge_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : RM_Edge_Legality_Model;
      Kind  : RM_Edge_Context_Kind) return RM_Edge_Result_Set is
      Results : RM_Edge_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Designator
     (Model      : RM_Edge_Legality_Model;
      Designator : String) return RM_Edge_Result_Set is
      Results : RM_Edge_Result_Set;
      Wanted : constant String := Lower (Designator);
   begin
      for Row of Model.Items loop
         if Lower (To_String (Row.Designator)) = Wanted then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Designator;

   function Result_Count (Results : RM_Edge_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : RM_Edge_Result_Set;
      Index   : Positive) return RM_Edge_Legality_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : RM_Edge_Legality_Model;
      Status : RM_Edge_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : RM_Edge_Legality_Model;
      Kind  : RM_Edge_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : RM_Edge_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Ambiguous_Count (Model : RM_Edge_Legality_Model) return Natural is
   begin
      return Model.Ambiguous_Total;
   end Ambiguous_Count;

   function Preference_Error_Count (Model : RM_Edge_Legality_Model) return Natural is
   begin
      return Model.Preference_Error_Total;
   end Preference_Error_Count;

   function Generic_Replay_Error_Count (Model : RM_Edge_Legality_Model) return Natural is
   begin
      return Model.Generic_Replay_Error_Total;
   end Generic_Replay_Error_Count;

   function Coverage_Gate_Error_Count (Model : RM_Edge_Legality_Model) return Natural is
   begin
      return Model.Coverage_Gate_Error_Total;
   end Coverage_Gate_Error_Count;

   function Multiple_Blocker_Count (Model : RM_Edge_Legality_Model) return Natural is
   begin
      return Model.Multiple_Blocker_Total;
   end Multiple_Blocker_Count;

   function Indeterminate_Count (Model : RM_Edge_Legality_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : RM_Edge_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : RM_Edge_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_RM_Edge_Legality
        and then Info.Status /= RM_Edge_Legality_Not_Checked;
   end Has_Legality;

end Editor.Ada_Overload_RM_Edge_Legality;
