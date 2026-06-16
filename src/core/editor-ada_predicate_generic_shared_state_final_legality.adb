with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Predicate_Generic_Shared_State_Final_Legality is

   pragma Suppress (Overflow_Check);
   use type PIU.Predicate_Use_Legality_Id;
   use type PIP.Propagation_Row_Id;
   use type Cross_Generic.Cross_Unit_Generic_Final_Row_Id;
   use type Generic_Replay.Generic_Abstract_Replay_Row_Id;
   use type Overload_Generic.Overload_Generic_Final_Row_Id;
   use type Rep_Generic.Representation_Generic_Final_Row_Id;
   use type Tasking_Generic.Tasking_Generic_Final_Row_Id;
   use type Access_Generic.Accessibility_Generic_Final_Row_Id;
   use type Disc_Generic.Discriminant_Generic_Final_Row_Id;
   use type Exception_Generic.Exception_Generic_Final_Row_Id;
   use type Renaming_Generic.Renaming_Generic_Final_Row_Id;
   use type Dispatching_Global.Dispatching_Global_Row_Id;
   use type Closure.Shared_State_Stabilized_Closure_Id;
   use type Closure.Shared_State_Stabilized_Closure_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 7) mod 2_147_483_647;
   end Mix;

   function Predicate_Use_Is_Legal (Status : PIU.Predicate_Use_Legality_Status) return Boolean is
   begin
      case Status is
         when PIU.Predicate_Use_Legality_Legal_Static_Predicate |
              PIU.Predicate_Use_Legality_Legal_Dynamic_Predicate_Check |
              PIU.Predicate_Use_Legality_Legal_Invariant_Preserved |
              PIU.Predicate_Use_Legality_Legal_Dynamic_Invariant_Check |
              PIU.Predicate_Use_Legality_Legal_Static_Range_And_Predicate |
              PIU.Predicate_Use_Legality_Legal_Linked_Assignment |
              PIU.Predicate_Use_Legality_Legal_Linked_Return |
              PIU.Predicate_Use_Legality_Legal_Linked_Semantic |
              PIU.Predicate_Use_Legality_Legal_Linked_Overload |
              PIU.Predicate_Use_Legality_Legal_Linked_Generic_Actual =>
            return True;
         when others =>
            return False;
      end case;
   end Predicate_Use_Is_Legal;

   function Propagation_Is_Legal (Status : PIP.Propagation_Status) return Boolean is
   begin
      case Status is
         when PIP.Propagation_Legal_Static_Predicate_Preserved |
              PIP.Propagation_Legal_Dynamic_Predicate_Propagated |
              PIP.Propagation_Legal_Invariant_Preserved |
              PIP.Propagation_Legal_Dynamic_Invariant_Propagated |
              PIP.Propagation_Legal_Generic_Substitution_Propagated |
              PIP.Propagation_Legal_Derived_Invariant_Propagated |
              PIP.Propagation_Legal_Private_Full_View_Propagated |
              PIP.Propagation_Legal_Flow_Effect_Propagated =>
            return True;
         when others =>
            return False;
      end case;
   end Propagation_Is_Legal;

   function Is_Accepted (Status : Predicate_Generic_Final_Status) return Boolean is
   begin
      case Status is
         when Predicate_Generic_Final_Legal_Assignment_Accepted |
              Predicate_Generic_Final_Legal_Object_Initialization_Accepted |
              Predicate_Generic_Final_Legal_Return_Accepted |
              Predicate_Generic_Final_Legal_Conversion_Accepted |
              Predicate_Generic_Final_Legal_Aggregate_Accepted |
              Predicate_Generic_Final_Legal_Call_Actual_Accepted |
              Predicate_Generic_Final_Legal_Call_Result_Accepted |
              Predicate_Generic_Final_Legal_Generic_Actual_Accepted |
              Predicate_Generic_Final_Legal_Derived_Type_Accepted |
              Predicate_Generic_Final_Legal_Private_View_Accepted |
              Predicate_Generic_Final_Legal_Dispatching_Call_Accepted |
              Predicate_Generic_Final_Legal_Renamed_Object_Accepted |
              Predicate_Generic_Final_Legal_Controlled_Finalization_Accepted |
              Predicate_Generic_Final_Legal_Discriminant_Dependent_Object_Accepted |
              Predicate_Generic_Final_Legal_Cross_Unit_State_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Accepted;

   function Is_Blocked (Status : Predicate_Generic_Final_Status) return Boolean is
   begin
      return Status /= Predicate_Generic_Final_Not_Checked and then not Is_Accepted (Status);
   end Is_Blocked;

   function Blocks_Downstream (Status : Predicate_Generic_Final_Status) return Boolean is
   begin
      return Is_Blocked (Status);
   end Blocks_Downstream;

   function Accepted_For (Kind : Predicate_Generic_Final_Kind) return Predicate_Generic_Final_Status is
   begin
      case Kind is
         when Predicate_Generic_Final_Assignment => return Predicate_Generic_Final_Legal_Assignment_Accepted;
         when Predicate_Generic_Final_Object_Initialization => return Predicate_Generic_Final_Legal_Object_Initialization_Accepted;
         when Predicate_Generic_Final_Return => return Predicate_Generic_Final_Legal_Return_Accepted;
         when Predicate_Generic_Final_Conversion => return Predicate_Generic_Final_Legal_Conversion_Accepted;
         when Predicate_Generic_Final_Aggregate => return Predicate_Generic_Final_Legal_Aggregate_Accepted;
         when Predicate_Generic_Final_Call_Actual => return Predicate_Generic_Final_Legal_Call_Actual_Accepted;
         when Predicate_Generic_Final_Call_Result => return Predicate_Generic_Final_Legal_Call_Result_Accepted;
         when Predicate_Generic_Final_Generic_Actual => return Predicate_Generic_Final_Legal_Generic_Actual_Accepted;
         when Predicate_Generic_Final_Derived_Type => return Predicate_Generic_Final_Legal_Derived_Type_Accepted;
         when Predicate_Generic_Final_Private_View => return Predicate_Generic_Final_Legal_Private_View_Accepted;
         when Predicate_Generic_Final_Dispatching_Call => return Predicate_Generic_Final_Legal_Dispatching_Call_Accepted;
         when Predicate_Generic_Final_Renamed_Object => return Predicate_Generic_Final_Legal_Renamed_Object_Accepted;
         when Predicate_Generic_Final_Controlled_Finalization => return Predicate_Generic_Final_Legal_Controlled_Finalization_Accepted;
         when Predicate_Generic_Final_Discriminant_Dependent_Object => return Predicate_Generic_Final_Legal_Discriminant_Dependent_Object_Accepted;
         when Predicate_Generic_Final_Cross_Unit_State => return Predicate_Generic_Final_Legal_Cross_Unit_State_Accepted;
         when Predicate_Generic_Final_Unknown => return Predicate_Generic_Final_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For (Status : Predicate_Generic_Final_Status) return Predicate_Generic_Final_Blocker_Family is
   begin
      case Status is
         when Predicate_Generic_Final_Not_Checked | Predicate_Generic_Final_Legal_Assignment_Accepted |
              Predicate_Generic_Final_Legal_Object_Initialization_Accepted | Predicate_Generic_Final_Legal_Return_Accepted |
              Predicate_Generic_Final_Legal_Conversion_Accepted | Predicate_Generic_Final_Legal_Aggregate_Accepted |
              Predicate_Generic_Final_Legal_Call_Actual_Accepted | Predicate_Generic_Final_Legal_Call_Result_Accepted |
              Predicate_Generic_Final_Legal_Generic_Actual_Accepted | Predicate_Generic_Final_Legal_Derived_Type_Accepted |
              Predicate_Generic_Final_Legal_Private_View_Accepted | Predicate_Generic_Final_Legal_Dispatching_Call_Accepted |
              Predicate_Generic_Final_Legal_Renamed_Object_Accepted | Predicate_Generic_Final_Legal_Controlled_Finalization_Accepted |
              Predicate_Generic_Final_Legal_Discriminant_Dependent_Object_Accepted | Predicate_Generic_Final_Legal_Cross_Unit_State_Accepted =>
            return Predicate_Generic_Final_Blocker_None;
         when Predicate_Generic_Final_Missing_Predicate_Use_Row | Predicate_Generic_Final_Predicate_Use_Blocker => return Predicate_Generic_Final_Blocker_Predicate_Use_Site;
         when Predicate_Generic_Final_Missing_Predicate_Propagation_Row | Predicate_Generic_Final_Predicate_Propagation_Blocker => return Predicate_Generic_Final_Blocker_Predicate_Propagation;
         when Predicate_Generic_Final_Missing_Cross_Unit_Generic_Row | Predicate_Generic_Final_Cross_Unit_Generic_Blocker => return Predicate_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State;
         when Predicate_Generic_Final_Missing_Generic_Replay_Row | Predicate_Generic_Final_Generic_Replay_Blocker => return Predicate_Generic_Final_Blocker_Generic_Abstract_Replay;
         when Predicate_Generic_Final_Missing_Overload_Generic_Row | Predicate_Generic_Final_Overload_Generic_Blocker => return Predicate_Generic_Final_Blocker_Overload_Generic_Shared_State;
         when Predicate_Generic_Final_Missing_Representation_Generic_Row | Predicate_Generic_Final_Representation_Generic_Blocker => return Predicate_Generic_Final_Blocker_Representation_Generic_Shared_State;
         when Predicate_Generic_Final_Missing_Tasking_Generic_Row | Predicate_Generic_Final_Tasking_Generic_Blocker => return Predicate_Generic_Final_Blocker_Tasking_Generic_Shared_State;
         when Predicate_Generic_Final_Missing_Accessibility_Generic_Row | Predicate_Generic_Final_Accessibility_Generic_Blocker => return Predicate_Generic_Final_Blocker_Accessibility_Generic_Shared_State;
         when Predicate_Generic_Final_Missing_Discriminant_Generic_Row | Predicate_Generic_Final_Discriminant_Generic_Blocker => return Predicate_Generic_Final_Blocker_Discriminant_Generic_Shared_State;
         when Predicate_Generic_Final_Missing_Exception_Generic_Row | Predicate_Generic_Final_Exception_Generic_Blocker => return Predicate_Generic_Final_Blocker_Exception_Finalization_Generic_Shared_State;
         when Predicate_Generic_Final_Missing_Renaming_Generic_Row | Predicate_Generic_Final_Renaming_Generic_Blocker => return Predicate_Generic_Final_Blocker_Renaming_Generic_Shared_State;
         when Predicate_Generic_Final_Missing_Dispatching_Global_Row | Predicate_Generic_Final_Dispatching_Global_Blocker => return Predicate_Generic_Final_Blocker_Dispatching_Global_Refinement;
         when Predicate_Generic_Final_Missing_Stabilized_Closure_Row | Predicate_Generic_Final_Stabilized_Closure_Blocker => return Predicate_Generic_Final_Blocker_Stabilized_Shared_State_Closure;
         when Predicate_Generic_Final_Static_Predicate_Blocker => return Predicate_Generic_Final_Blocker_Static_Predicate;
         when Predicate_Generic_Final_Dynamic_Predicate_Check_Blocker => return Predicate_Generic_Final_Blocker_Dynamic_Predicate_Check;
         when Predicate_Generic_Final_Invariant_Blocker => return Predicate_Generic_Final_Blocker_Invariant;
         when Predicate_Generic_Final_Private_View_Blocker => return Predicate_Generic_Final_Blocker_Private_View;
         when Predicate_Generic_Final_Derived_Invariant_Blocker => return Predicate_Generic_Final_Blocker_Derived_Invariant;
         when Predicate_Generic_Final_Generic_Substitution_Blocker => return Predicate_Generic_Final_Blocker_Generic_Substitution;
         when Predicate_Generic_Final_Discriminant_Predicate_Blocker => return Predicate_Generic_Final_Blocker_Discriminant_Predicate;
         when Predicate_Generic_Final_Controlled_Finalization_Blocker => return Predicate_Generic_Final_Blocker_Controlled_Finalization;
         when Predicate_Generic_Final_Renamed_Predicate_Source_Blocker => return Predicate_Generic_Final_Blocker_Renamed_Predicate_Source;
         when Predicate_Generic_Final_Dispatching_Effect_Blocker => return Predicate_Generic_Final_Blocker_Dispatching_Effect;
         when Predicate_Generic_Final_Source_Fingerprint_Mismatch => return Predicate_Generic_Final_Blocker_Source_Fingerprint;
         when Predicate_Generic_Final_Substitution_Fingerprint_Mismatch => return Predicate_Generic_Final_Blocker_Substitution_Fingerprint;
         when Predicate_Generic_Final_Multiple_Blockers => return Predicate_Generic_Final_Blocker_Multiple;
         when Predicate_Generic_Final_Indeterminate => return Predicate_Generic_Final_Blocker_Indeterminate;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Predicate_Generic_Final_Context) return Natural is
      N : Natural := 0;
   begin
      if C.Static_Predicate_Blocker then N := N + 1; end if;
      if C.Dynamic_Predicate_Check_Blocker then N := N + 1; end if;
      if C.Invariant_Blocker then N := N + 1; end if;
      if C.Private_View_Blocker then N := N + 1; end if;
      if C.Derived_Invariant_Blocker then N := N + 1; end if;
      if C.Generic_Substitution_Blocker then N := N + 1; end if;
      if C.Discriminant_Predicate_Blocker then N := N + 1; end if;
      if C.Controlled_Finalization_Blocker then N := N + 1; end if;
      if C.Renamed_Predicate_Source_Blocker then N := N + 1; end if;
      if C.Dispatching_Effect_Blocker then N := N + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then N := N + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then N := N + 1; end if;
      return N;
   end Local_Blocker_Count;

   function Classify (C : Predicate_Generic_Final_Context) return Predicate_Generic_Final_Status is
      Local_N : constant Natural := Local_Blocker_Count (C);
   begin
      if Local_N > 1 then return Predicate_Generic_Final_Multiple_Blockers;
      elsif C.Static_Predicate_Blocker then return Predicate_Generic_Final_Static_Predicate_Blocker;
      elsif C.Dynamic_Predicate_Check_Blocker then return Predicate_Generic_Final_Dynamic_Predicate_Check_Blocker;
      elsif C.Invariant_Blocker then return Predicate_Generic_Final_Invariant_Blocker;
      elsif C.Private_View_Blocker then return Predicate_Generic_Final_Private_View_Blocker;
      elsif C.Derived_Invariant_Blocker then return Predicate_Generic_Final_Derived_Invariant_Blocker;
      elsif C.Generic_Substitution_Blocker then return Predicate_Generic_Final_Generic_Substitution_Blocker;
      elsif C.Discriminant_Predicate_Blocker then return Predicate_Generic_Final_Discriminant_Predicate_Blocker;
      elsif C.Controlled_Finalization_Blocker then return Predicate_Generic_Final_Controlled_Finalization_Blocker;
      elsif C.Renamed_Predicate_Source_Blocker then return Predicate_Generic_Final_Renamed_Predicate_Source_Blocker;
      elsif C.Dispatching_Effect_Blocker then return Predicate_Generic_Final_Dispatching_Effect_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then return Predicate_Generic_Final_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then return Predicate_Generic_Final_Substitution_Fingerprint_Mismatch;
      elsif C.Predicate_Use_Row = PIU.No_Predicate_Use_Legality then return Predicate_Generic_Final_Missing_Predicate_Use_Row;
      elsif not Predicate_Use_Is_Legal (C.Predicate_Use_Status) then return Predicate_Generic_Final_Predicate_Use_Blocker;
      elsif C.Requires_Propagation and then C.Propagation_Row = PIP.No_Propagation_Row then return Predicate_Generic_Final_Missing_Predicate_Propagation_Row;
      elsif C.Requires_Propagation and then not Propagation_Is_Legal (C.Propagation_Status) then return Predicate_Generic_Final_Predicate_Propagation_Blocker;
      elsif C.Requires_Cross_Generic and then C.Cross_Generic_Row = Cross_Generic.No_Cross_Unit_Generic_Final_Row then return Predicate_Generic_Final_Missing_Cross_Unit_Generic_Row;
      elsif C.Requires_Cross_Generic and then not Cross_Generic.Is_Accepted (C.Cross_Generic_Status) then return Predicate_Generic_Final_Cross_Unit_Generic_Blocker;
      elsif C.Requires_Generic_Replay and then C.Generic_Replay_Row = Generic_Replay.No_Generic_Abstract_Replay_Row then return Predicate_Generic_Final_Missing_Generic_Replay_Row;
      elsif C.Requires_Generic_Replay and then not Generic_Replay.Is_Accepted (C.Generic_Replay_Status) then return Predicate_Generic_Final_Generic_Replay_Blocker;
      elsif C.Requires_Overload_Generic and then C.Overload_Generic_Row = Overload_Generic.No_Overload_Generic_Final_Row then return Predicate_Generic_Final_Missing_Overload_Generic_Row;
      elsif C.Requires_Overload_Generic and then not Overload_Generic.Is_Accepted (C.Overload_Generic_Status) then return Predicate_Generic_Final_Overload_Generic_Blocker;
      elsif C.Requires_Representation_Generic and then C.Representation_Generic_Row = Rep_Generic.No_Representation_Generic_Final_Row then return Predicate_Generic_Final_Missing_Representation_Generic_Row;
      elsif C.Requires_Representation_Generic and then not Rep_Generic.Is_Accepted (C.Representation_Generic_Status) then return Predicate_Generic_Final_Representation_Generic_Blocker;
      elsif C.Requires_Tasking_Generic and then C.Tasking_Generic_Row = Tasking_Generic.No_Tasking_Generic_Final_Row then return Predicate_Generic_Final_Missing_Tasking_Generic_Row;
      elsif C.Requires_Tasking_Generic and then not Tasking_Generic.Is_Accepted (C.Tasking_Generic_Status) then return Predicate_Generic_Final_Tasking_Generic_Blocker;
      elsif C.Requires_Accessibility_Generic and then C.Accessibility_Generic_Row = Access_Generic.No_Accessibility_Generic_Final_Row then return Predicate_Generic_Final_Missing_Accessibility_Generic_Row;
      elsif C.Requires_Accessibility_Generic and then not Access_Generic.Is_Accepted (C.Accessibility_Generic_Status) then return Predicate_Generic_Final_Accessibility_Generic_Blocker;
      elsif C.Requires_Discriminant_Generic and then C.Discriminant_Generic_Row = Disc_Generic.No_Discriminant_Generic_Final_Row then return Predicate_Generic_Final_Missing_Discriminant_Generic_Row;
      elsif C.Requires_Discriminant_Generic and then not Disc_Generic.Is_Accepted (C.Discriminant_Generic_Status) then return Predicate_Generic_Final_Discriminant_Generic_Blocker;
      elsif C.Requires_Exception_Generic and then C.Exception_Generic_Row = Exception_Generic.No_Exception_Generic_Final_Row then return Predicate_Generic_Final_Missing_Exception_Generic_Row;
      elsif C.Requires_Exception_Generic and then not Exception_Generic.Is_Accepted (C.Exception_Generic_Status) then return Predicate_Generic_Final_Exception_Generic_Blocker;
      elsif C.Requires_Renaming_Generic and then C.Renaming_Generic_Row = Renaming_Generic.No_Renaming_Generic_Final_Row then return Predicate_Generic_Final_Missing_Renaming_Generic_Row;
      elsif C.Requires_Renaming_Generic and then not Renaming_Generic.Is_Accepted (C.Renaming_Generic_Status) then return Predicate_Generic_Final_Renaming_Generic_Blocker;
      elsif C.Requires_Dispatching_Global and then C.Dispatching_Global_Row = Dispatching_Global.No_Dispatching_Global_Row then return Predicate_Generic_Final_Missing_Dispatching_Global_Row;
      elsif C.Requires_Dispatching_Global and then not Dispatching_Global.Is_Accepted (C.Dispatching_Global_Status) then return Predicate_Generic_Final_Dispatching_Global_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Shared_State_Stabilized_Closure then return Predicate_Generic_Final_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not (C.Stabilized_Closure_Status = Closure.Shared_State_Stabilized_Closure_Accepted_Current or else C.Stabilized_Closure_Status = Closure.Shared_State_Stabilized_Closure_Accepted_Not_Required) then return Predicate_Generic_Final_Stabilized_Closure_Blocker;
      else return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Row_Fingerprint (Row : Predicate_Generic_Final_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Predicate_Generic_Final_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Predicate_Generic_Final_Status'Pos (Row.Status) + 1);
      H := Mix (H, Predicate_Generic_Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for Ch of Text loop H := Mix (H, Character'Pos (Ch)); end loop;
      return H;
   end Row_Fingerprint;

   function Build_Row (C : Predicate_Generic_Final_Context) return Predicate_Generic_Final_Row is
      Status : constant Predicate_Generic_Final_Status := Classify (C);
      Family : constant Predicate_Generic_Final_Blocker_Family := Family_For (Status);
      Row : Predicate_Generic_Final_Row;
   begin
      Row.Id := C.Id;
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Subtype_Name := C.Subtype_Name;
      Row.Object_Name := C.Object_Name;
      Row.Type_Name := C.Type_Name;
      Row.Operation_Name := C.Operation_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.State_Name := C.State_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Blocks_Downstream (Status);
      Row.Blocker_Count := Local_Blocker_Count (C);
      if Row.Blocked and then Row.Blocker_Count = 0 then Row.Blocker_Count := 1; end if;
      Row.Start_Line := C.Start_Line; Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line; Row.End_Column := C.End_Column;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Substitution_Fingerprint := C.Substitution_Fingerprint;
      Row.Message := To_Unbounded_String
        ("predicate/invariant generic shared-state final legality " &
         Predicate_Generic_Final_Status'Image (Status) &
         " kind=" & Predicate_Generic_Final_Kind'Image (C.Kind) &
         " blocker=" & Predicate_Generic_Final_Blocker_Family'Image (Family));
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Build_Row;

   procedure Clear (Model : in out Predicate_Generic_Final_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Stable_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Predicate_Generic_Final_Context_Model; Info : Predicate_Generic_Final_Context) is
   begin
      Model.Items.Append (Info);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Id));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Node));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Source_Fingerprint);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Predicate_Generic_Final_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Build (Contexts : Predicate_Generic_Final_Context_Model) return Predicate_Generic_Final_Model is
      Result : Predicate_Generic_Final_Model;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Predicate_Generic_Final_Row := Build_Row (C);
         begin
            Result.Rows.Append (Row);
            Result.Stable_Fingerprint := Mix (Result.Stable_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Predicate_Generic_Final_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At (Model : Predicate_Generic_Final_Model; Index : Positive) return Predicate_Generic_Final_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Accepted_Count (Model : Predicate_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop if Row.Accepted then N := N + 1; end if; end loop;
      return N;
   end Accepted_Count;

   function Blocked_Count (Model : Predicate_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop if Row.Blocked then N := N + 1; end if; end loop;
      return N;
   end Blocked_Count;

   function Indeterminate_Count (Model : Predicate_Generic_Final_Model) return Natural is
   begin
      return Count_By_Status (Model, Predicate_Generic_Final_Indeterminate);
   end Indeterminate_Count;

   function Count_By_Status (Model : Predicate_Generic_Final_Model; Status : Predicate_Generic_Final_Status) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop if Row.Status = Status then N := N + 1; end if; end loop;
      return N;
   end Count_By_Status;

   function Count_By_Blocker_Family (Model : Predicate_Generic_Final_Model; Family : Predicate_Generic_Final_Blocker_Family) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop if Row.Blocker_Family = Family then N := N + 1; end if; end loop;
      return N;
   end Count_By_Blocker_Family;

   function Find_By_Node (Model : Predicate_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Predicate_Generic_Final_Set is
      Result : Predicate_Generic_Final_Set;
   begin
      for Row of Model.Rows loop if Row.Node = Node then Result.Rows.Append (Row); end if; end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint (Model : Predicate_Generic_Final_Model; Fingerprint : Natural) return Predicate_Generic_Final_Set is
      Result : Predicate_Generic_Final_Set;
   begin
      for Row of Model.Rows loop if Row.Source_Fingerprint = Fingerprint then Result.Rows.Append (Row); end if; end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Query_Blocker_Family (Model : Predicate_Generic_Final_Model; Family : Predicate_Generic_Final_Blocker_Family) return Predicate_Generic_Final_Set is
      Result : Predicate_Generic_Final_Set;
   begin
      for Row of Model.Rows loop if Row.Blocker_Family = Family then Result.Rows.Append (Row); end if; end loop;
      return Result;
   end Query_Blocker_Family;

   function Query_Count (Set : Predicate_Generic_Final_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_Row_At (Set : Predicate_Generic_Final_Set; Index : Positive) return Predicate_Generic_Final_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_Row_At;

   function Stable_Fingerprint (Model : Predicate_Generic_Final_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Predicate_Generic_Shared_State_Final_Legality;
