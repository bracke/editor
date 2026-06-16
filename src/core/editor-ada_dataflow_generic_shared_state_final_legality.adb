with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality is

   pragma Suppress (Overflow_Check);

   use type Access_Generic.Accessibility_Generic_Final_Row_Id;
   use type Closure.Shared_State_Stabilized_Closure_Id;
   use type Closure.Shared_State_Stabilized_Closure_Status;
   use type Dataflow_Init.Dataflow_Init_Row_Id;
   use type Disc_Generic.Discriminant_Generic_Final_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Exception_Generic.Exception_Generic_Final_Row_Id;
   use type Generic_Replay.Generic_Abstract_Replay_Row_Id;
   use type Init.Initialization_Legality_Id;
   use type Predicate_Dataflow.Predicate_Dataflow_Row_Id;
   use type Predicate_Generic.Predicate_Generic_Final_Row_Id;
   use type Renaming_Generic.Renaming_Generic_Final_Row_Id;
   use type Rep_Generic.Representation_Generic_Final_Row_Id;
   use type Tasking_Generic.Tasking_Generic_Final_Row_Id;
   use type Volatile_Rep.Volatile_Atomic_Representation_Row_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 7) mod 2_147_483_647;
   end Mix;

   function Init_Is_Legal (Status : Init.Initialization_Legality_Status) return Boolean is
   begin
      case Status is
         when Init.Initialization_Legality_Definitely_Initialized |
              Init.Initialization_Legality_Default_Initialized |
              Init.Initialization_Legality_Explicitly_Initialized |
              Init.Initialization_Legality_Component_Initialized |
              Init.Initialization_Legality_Out_Parameter_Assigned |
              Init.Initialization_Legality_Return_Object_Initialized |
              Init.Initialization_Legality_Exception_Path_Preserved |
              Init.Initialization_Legality_Finalization_Path_Preserved =>
            return True;
         when others =>
            return False;
      end case;
   end Init_Is_Legal;

   function Predicate_Dataflow_Is_Legal
     (Status : Predicate_Dataflow.Predicate_Dataflow_Status) return Boolean is
   begin
      case Status is
         when Predicate_Dataflow.Predicate_Dataflow_Legal_Static_Predicate_Accepted |
              Predicate_Dataflow.Predicate_Dataflow_Legal_Dynamic_Predicate_Accepted |
              Predicate_Dataflow.Predicate_Dataflow_Legal_Invariant_Accepted |
              Predicate_Dataflow.Predicate_Dataflow_Legal_Dynamic_Invariant_Accepted |
              Predicate_Dataflow.Predicate_Dataflow_Legal_Generic_Substitution_Accepted |
              Predicate_Dataflow.Predicate_Dataflow_Legal_Derived_Invariant_Accepted |
              Predicate_Dataflow.Predicate_Dataflow_Legal_Private_Full_View_Accepted |
              Predicate_Dataflow.Predicate_Dataflow_Legal_Flow_Effect_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Predicate_Dataflow_Is_Legal;

   function Is_Accepted (Status : Dataflow_Generic_Final_Status) return Boolean is
   begin
      case Status is
         when Dataflow_Generic_Final_Legal_Read_Accepted |
              Dataflow_Generic_Final_Legal_Write_Accepted |
              Dataflow_Generic_Final_Legal_Read_Write_Accepted |
              Dataflow_Generic_Final_Legal_Out_Parameter_Accepted |
              Dataflow_Generic_Final_Legal_In_Out_Parameter_Accepted |
              Dataflow_Generic_Final_Legal_Return_Object_Accepted |
              Dataflow_Generic_Final_Legal_Variant_Component_Accepted |
              Dataflow_Generic_Final_Legal_Access_Escape_Accepted |
              Dataflow_Generic_Final_Legal_Controlled_Finalization_Accepted |
              Dataflow_Generic_Final_Legal_Generic_Formal_Object_Accepted |
              Dataflow_Generic_Final_Legal_Volatile_Object_Accepted |
              Dataflow_Generic_Final_Legal_Atomic_Object_Accepted |
              Dataflow_Generic_Final_Legal_Dispatching_Call_Accepted |
              Dataflow_Generic_Final_Legal_Cross_Unit_State_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Accepted;

   function Is_Blocked (Status : Dataflow_Generic_Final_Status) return Boolean is
   begin
      return Status /= Dataflow_Generic_Final_Not_Checked and then not Is_Accepted (Status);
   end Is_Blocked;

   function Blocks_Downstream (Status : Dataflow_Generic_Final_Status) return Boolean is
   begin
      return Is_Blocked (Status);
   end Blocks_Downstream;

   function Accepted_For (Kind : Dataflow_Generic_Final_Kind) return Dataflow_Generic_Final_Status is
   begin
      case Kind is
         when Dataflow_Generic_Final_Read => return Dataflow_Generic_Final_Legal_Read_Accepted;
         when Dataflow_Generic_Final_Write => return Dataflow_Generic_Final_Legal_Write_Accepted;
         when Dataflow_Generic_Final_Read_Write => return Dataflow_Generic_Final_Legal_Read_Write_Accepted;
         when Dataflow_Generic_Final_Out_Parameter => return Dataflow_Generic_Final_Legal_Out_Parameter_Accepted;
         when Dataflow_Generic_Final_In_Out_Parameter => return Dataflow_Generic_Final_Legal_In_Out_Parameter_Accepted;
         when Dataflow_Generic_Final_Return_Object => return Dataflow_Generic_Final_Legal_Return_Object_Accepted;
         when Dataflow_Generic_Final_Variant_Component => return Dataflow_Generic_Final_Legal_Variant_Component_Accepted;
         when Dataflow_Generic_Final_Access_Escape => return Dataflow_Generic_Final_Legal_Access_Escape_Accepted;
         when Dataflow_Generic_Final_Controlled_Finalization => return Dataflow_Generic_Final_Legal_Controlled_Finalization_Accepted;
         when Dataflow_Generic_Final_Generic_Formal_Object => return Dataflow_Generic_Final_Legal_Generic_Formal_Object_Accepted;
         when Dataflow_Generic_Final_Volatile_Object => return Dataflow_Generic_Final_Legal_Volatile_Object_Accepted;
         when Dataflow_Generic_Final_Atomic_Object => return Dataflow_Generic_Final_Legal_Atomic_Object_Accepted;
         when Dataflow_Generic_Final_Dispatching_Call => return Dataflow_Generic_Final_Legal_Dispatching_Call_Accepted;
         when Dataflow_Generic_Final_Cross_Unit_State => return Dataflow_Generic_Final_Legal_Cross_Unit_State_Accepted;
         when Dataflow_Generic_Final_Unknown => return Dataflow_Generic_Final_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For (Status : Dataflow_Generic_Final_Status) return Dataflow_Generic_Final_Blocker_Family is
   begin
      case Status is
         when Dataflow_Generic_Final_Not_Checked |
              Dataflow_Generic_Final_Legal_Read_Accepted |
              Dataflow_Generic_Final_Legal_Write_Accepted |
              Dataflow_Generic_Final_Legal_Read_Write_Accepted |
              Dataflow_Generic_Final_Legal_Out_Parameter_Accepted |
              Dataflow_Generic_Final_Legal_In_Out_Parameter_Accepted |
              Dataflow_Generic_Final_Legal_Return_Object_Accepted |
              Dataflow_Generic_Final_Legal_Variant_Component_Accepted |
              Dataflow_Generic_Final_Legal_Access_Escape_Accepted |
              Dataflow_Generic_Final_Legal_Controlled_Finalization_Accepted |
              Dataflow_Generic_Final_Legal_Generic_Formal_Object_Accepted |
              Dataflow_Generic_Final_Legal_Volatile_Object_Accepted |
              Dataflow_Generic_Final_Legal_Atomic_Object_Accepted |
              Dataflow_Generic_Final_Legal_Dispatching_Call_Accepted |
              Dataflow_Generic_Final_Legal_Cross_Unit_State_Accepted => return Dataflow_Generic_Final_Blocker_None;
         when Dataflow_Generic_Final_Missing_Initialization_Row | Dataflow_Generic_Final_Initialization_Blocker => return Dataflow_Generic_Final_Blocker_Definite_Initialization;
         when Dataflow_Generic_Final_Missing_Dataflow_Init_Row | Dataflow_Generic_Final_Dataflow_Init_Blocker => return Dataflow_Generic_Final_Blocker_Dataflow_Initialization;
         when Dataflow_Generic_Final_Missing_Predicate_Dataflow_Row | Dataflow_Generic_Final_Predicate_Dataflow_Blocker => return Dataflow_Generic_Final_Blocker_Predicate_Dataflow;
         when Dataflow_Generic_Final_Missing_Predicate_Generic_Row | Dataflow_Generic_Final_Predicate_Generic_Blocker => return Dataflow_Generic_Final_Blocker_Predicate_Generic_Shared_State;
         when Dataflow_Generic_Final_Missing_Generic_Replay_Row | Dataflow_Generic_Final_Generic_Replay_Blocker => return Dataflow_Generic_Final_Blocker_Generic_Abstract_Replay;
         when Dataflow_Generic_Final_Missing_Stabilized_Closure_Row | Dataflow_Generic_Final_Stabilized_Closure_Blocker => return Dataflow_Generic_Final_Blocker_Stabilized_Shared_State_Closure;
         when Dataflow_Generic_Final_Missing_Representation_Generic_Row | Dataflow_Generic_Final_Representation_Generic_Blocker => return Dataflow_Generic_Final_Blocker_Representation_Generic_Shared_State;
         when Dataflow_Generic_Final_Missing_Tasking_Generic_Row | Dataflow_Generic_Final_Tasking_Generic_Blocker => return Dataflow_Generic_Final_Blocker_Tasking_Generic_Shared_State;
         when Dataflow_Generic_Final_Missing_Accessibility_Generic_Row | Dataflow_Generic_Final_Accessibility_Generic_Blocker => return Dataflow_Generic_Final_Blocker_Accessibility_Generic_Shared_State;
         when Dataflow_Generic_Final_Missing_Discriminant_Generic_Row | Dataflow_Generic_Final_Discriminant_Generic_Blocker => return Dataflow_Generic_Final_Blocker_Discriminant_Generic_Shared_State;
         when Dataflow_Generic_Final_Missing_Exception_Generic_Row | Dataflow_Generic_Final_Exception_Generic_Blocker => return Dataflow_Generic_Final_Blocker_Exception_Finalization_Generic_Shared_State;
         when Dataflow_Generic_Final_Missing_Renaming_Generic_Row | Dataflow_Generic_Final_Renaming_Generic_Blocker => return Dataflow_Generic_Final_Blocker_Renaming_Generic_Shared_State;
         when Dataflow_Generic_Final_Missing_Volatile_Representation_Row | Dataflow_Generic_Final_Volatile_Representation_Blocker => return Dataflow_Generic_Final_Blocker_Volatile_Atomic_Representation;
         when Dataflow_Generic_Final_Read_Before_Write_Blocker => return Dataflow_Generic_Final_Blocker_Read_Before_Write;
         when Dataflow_Generic_Final_Partial_Component_Init_Blocker => return Dataflow_Generic_Final_Blocker_Partial_Component_Init;
         when Dataflow_Generic_Final_Out_Parameter_Blocker => return Dataflow_Generic_Final_Blocker_Out_Parameter;
         when Dataflow_Generic_Final_Return_Object_Blocker => return Dataflow_Generic_Final_Blocker_Return_Object;
         when Dataflow_Generic_Final_Branch_Loop_Merge_Blocker => return Dataflow_Generic_Final_Blocker_Branch_Loop_Merge;
         when Dataflow_Generic_Final_Exception_Path_Blocker => return Dataflow_Generic_Final_Blocker_Exception_Path;
         when Dataflow_Generic_Final_Finalization_Blocker => return Dataflow_Generic_Final_Blocker_Finalization;
         when Dataflow_Generic_Final_Access_Escape_Blocker => return Dataflow_Generic_Final_Blocker_Access_Escape;
         when Dataflow_Generic_Final_Variant_Component_Blocker => return Dataflow_Generic_Final_Blocker_Variant_Component;
         when Dataflow_Generic_Final_Volatile_Atomic_Effect_Blocker => return Dataflow_Generic_Final_Blocker_Volatile_Atomic_Effect;
         when Dataflow_Generic_Final_Generic_Substitution_Blocker => return Dataflow_Generic_Final_Blocker_Generic_Substitution;
         when Dataflow_Generic_Final_Source_Fingerprint_Mismatch => return Dataflow_Generic_Final_Blocker_Source_Fingerprint;
         when Dataflow_Generic_Final_Substitution_Fingerprint_Mismatch => return Dataflow_Generic_Final_Blocker_Substitution_Fingerprint;
         when Dataflow_Generic_Final_Multiple_Blockers => return Dataflow_Generic_Final_Blocker_Multiple;
         when Dataflow_Generic_Final_Indeterminate => return Dataflow_Generic_Final_Blocker_Indeterminate;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Dataflow_Generic_Final_Context) return Natural is
      N : Natural := 0;
   begin
      if C.Read_Before_Write_Blocker then N := N + 1; end if;
      if C.Partial_Component_Init_Blocker then N := N + 1; end if;
      if C.Out_Parameter_Blocker then N := N + 1; end if;
      if C.Return_Object_Blocker then N := N + 1; end if;
      if C.Branch_Loop_Merge_Blocker then N := N + 1; end if;
      if C.Exception_Path_Blocker then N := N + 1; end if;
      if C.Finalization_Blocker then N := N + 1; end if;
      if C.Access_Escape_Blocker then N := N + 1; end if;
      if C.Variant_Component_Blocker then N := N + 1; end if;
      if C.Volatile_Atomic_Effect_Blocker then N := N + 1; end if;
      if C.Generic_Substitution_Blocker then N := N + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then N := N + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then N := N + 1; end if;
      return N;
   end Local_Blocker_Count;

   function Classify (C : Dataflow_Generic_Final_Context) return Dataflow_Generic_Final_Status is
      Local_N : constant Natural := Local_Blocker_Count (C);
   begin
      if Local_N > 1 then return Dataflow_Generic_Final_Multiple_Blockers;
      elsif C.Read_Before_Write_Blocker then return Dataflow_Generic_Final_Read_Before_Write_Blocker;
      elsif C.Partial_Component_Init_Blocker then return Dataflow_Generic_Final_Partial_Component_Init_Blocker;
      elsif C.Out_Parameter_Blocker then return Dataflow_Generic_Final_Out_Parameter_Blocker;
      elsif C.Return_Object_Blocker then return Dataflow_Generic_Final_Return_Object_Blocker;
      elsif C.Branch_Loop_Merge_Blocker then return Dataflow_Generic_Final_Branch_Loop_Merge_Blocker;
      elsif C.Exception_Path_Blocker then return Dataflow_Generic_Final_Exception_Path_Blocker;
      elsif C.Finalization_Blocker then return Dataflow_Generic_Final_Finalization_Blocker;
      elsif C.Access_Escape_Blocker then return Dataflow_Generic_Final_Access_Escape_Blocker;
      elsif C.Variant_Component_Blocker then return Dataflow_Generic_Final_Variant_Component_Blocker;
      elsif C.Volatile_Atomic_Effect_Blocker then return Dataflow_Generic_Final_Volatile_Atomic_Effect_Blocker;
      elsif C.Generic_Substitution_Blocker then return Dataflow_Generic_Final_Generic_Substitution_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then return Dataflow_Generic_Final_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then return Dataflow_Generic_Final_Substitution_Fingerprint_Mismatch;
      elsif C.Initialization_Row = Init.No_Initialization_Legality then return Dataflow_Generic_Final_Missing_Initialization_Row;
      elsif not Init_Is_Legal (C.Initialization_Status) then return Dataflow_Generic_Final_Initialization_Blocker;
      elsif C.Dataflow_Init_Row = Dataflow_Init.No_Dataflow_Init_Row then return Dataflow_Generic_Final_Missing_Dataflow_Init_Row;
      elsif not Dataflow_Init.Is_Legal (C.Dataflow_Init_Status) then return Dataflow_Generic_Final_Dataflow_Init_Blocker;
      elsif C.Requires_Predicate_Dataflow and then C.Predicate_Dataflow_Row = Predicate_Dataflow.No_Predicate_Dataflow_Row then return Dataflow_Generic_Final_Missing_Predicate_Dataflow_Row;
      elsif C.Requires_Predicate_Dataflow and then not Predicate_Dataflow_Is_Legal (C.Predicate_Dataflow_Status) then return Dataflow_Generic_Final_Predicate_Dataflow_Blocker;
      elsif C.Requires_Predicate_Generic and then C.Predicate_Generic_Row = Predicate_Generic.No_Predicate_Generic_Final_Row then return Dataflow_Generic_Final_Missing_Predicate_Generic_Row;
      elsif C.Requires_Predicate_Generic and then not Predicate_Generic.Is_Accepted (C.Predicate_Generic_Status) then return Dataflow_Generic_Final_Predicate_Generic_Blocker;
      elsif C.Requires_Generic_Replay and then C.Generic_Replay_Row = Generic_Replay.No_Generic_Abstract_Replay_Row then return Dataflow_Generic_Final_Missing_Generic_Replay_Row;
      elsif C.Requires_Generic_Replay and then not Generic_Replay.Is_Accepted (C.Generic_Replay_Status) then return Dataflow_Generic_Final_Generic_Replay_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Shared_State_Stabilized_Closure then return Dataflow_Generic_Final_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not (C.Stabilized_Closure_Status = Closure.Shared_State_Stabilized_Closure_Accepted_Current or else C.Stabilized_Closure_Status = Closure.Shared_State_Stabilized_Closure_Accepted_Not_Required) then return Dataflow_Generic_Final_Stabilized_Closure_Blocker;
      elsif C.Requires_Representation_Generic and then C.Representation_Generic_Row = Rep_Generic.No_Representation_Generic_Final_Row then return Dataflow_Generic_Final_Missing_Representation_Generic_Row;
      elsif C.Requires_Representation_Generic and then not Rep_Generic.Is_Accepted (C.Representation_Generic_Status) then return Dataflow_Generic_Final_Representation_Generic_Blocker;
      elsif C.Requires_Tasking_Generic and then C.Tasking_Generic_Row = Tasking_Generic.No_Tasking_Generic_Final_Row then return Dataflow_Generic_Final_Missing_Tasking_Generic_Row;
      elsif C.Requires_Tasking_Generic and then not Tasking_Generic.Is_Accepted (C.Tasking_Generic_Status) then return Dataflow_Generic_Final_Tasking_Generic_Blocker;
      elsif C.Requires_Accessibility_Generic and then C.Accessibility_Generic_Row = Access_Generic.No_Accessibility_Generic_Final_Row then return Dataflow_Generic_Final_Missing_Accessibility_Generic_Row;
      elsif C.Requires_Accessibility_Generic and then not Access_Generic.Is_Accepted (C.Accessibility_Generic_Status) then return Dataflow_Generic_Final_Accessibility_Generic_Blocker;
      elsif C.Requires_Discriminant_Generic and then C.Discriminant_Generic_Row = Disc_Generic.No_Discriminant_Generic_Final_Row then return Dataflow_Generic_Final_Missing_Discriminant_Generic_Row;
      elsif C.Requires_Discriminant_Generic and then not Disc_Generic.Is_Accepted (C.Discriminant_Generic_Status) then return Dataflow_Generic_Final_Discriminant_Generic_Blocker;
      elsif C.Requires_Exception_Generic and then C.Exception_Generic_Row = Exception_Generic.No_Exception_Generic_Final_Row then return Dataflow_Generic_Final_Missing_Exception_Generic_Row;
      elsif C.Requires_Exception_Generic and then not Exception_Generic.Is_Accepted (C.Exception_Generic_Status) then return Dataflow_Generic_Final_Exception_Generic_Blocker;
      elsif C.Requires_Renaming_Generic and then C.Renaming_Generic_Row = Renaming_Generic.No_Renaming_Generic_Final_Row then return Dataflow_Generic_Final_Missing_Renaming_Generic_Row;
      elsif C.Requires_Renaming_Generic and then not Renaming_Generic.Is_Accepted (C.Renaming_Generic_Status) then return Dataflow_Generic_Final_Renaming_Generic_Blocker;
      elsif C.Requires_Volatile_Representation and then C.Volatile_Representation_Row = Volatile_Rep.No_Volatile_Atomic_Representation_Row then return Dataflow_Generic_Final_Missing_Volatile_Representation_Row;
      elsif C.Requires_Volatile_Representation and then not Volatile_Rep.Is_Accepted (C.Volatile_Representation_Status) then return Dataflow_Generic_Final_Volatile_Representation_Blocker;
      else return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Row_Fingerprint (Row : Dataflow_Generic_Final_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Dataflow_Generic_Final_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Dataflow_Generic_Final_Status'Pos (Row.Status) + 1);
      H := Mix (H, Dataflow_Generic_Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for Ch of Text loop H := Mix (H, Character'Pos (Ch)); end loop;
      return H;
   end Row_Fingerprint;

   function Build_Row (C : Dataflow_Generic_Final_Context) return Dataflow_Generic_Final_Row is
      Status : constant Dataflow_Generic_Final_Status := Classify (C);
      Family : constant Dataflow_Generic_Final_Blocker_Family := Family_For (Status);
      Row : Dataflow_Generic_Final_Row;
   begin
      Row.Id := C.Id;
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Object_Name := C.Object_Name;
      Row.Component_Name := C.Component_Name;
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
        ("dataflow generic shared-state final legality " &
         Dataflow_Generic_Final_Status'Image (Status) &
         " kind=" & Dataflow_Generic_Final_Kind'Image (C.Kind) &
         " blocker=" & Dataflow_Generic_Final_Blocker_Family'Image (Family));
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Build_Row;

   procedure Clear (Model : in out Dataflow_Generic_Final_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Stable_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Dataflow_Generic_Final_Context_Model; Info : Dataflow_Generic_Final_Context) is
   begin
      Model.Items.Append (Info);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Id));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Node));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Source_Fingerprint);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Dataflow_Generic_Final_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Build (Contexts : Dataflow_Generic_Final_Context_Model) return Dataflow_Generic_Final_Model is
      Result : Dataflow_Generic_Final_Model;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Dataflow_Generic_Final_Row := Build_Row (C);
         begin
            Result.Rows.Append (Row);
            Result.Stable_Fingerprint := Mix (Result.Stable_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Dataflow_Generic_Final_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At (Model : Dataflow_Generic_Final_Model; Index : Positive) return Dataflow_Generic_Final_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Accepted_Count (Model : Dataflow_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop if Row.Accepted then N := N + 1; end if; end loop;
      return N;
   end Accepted_Count;

   function Blocked_Count (Model : Dataflow_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop if Row.Blocked then N := N + 1; end if; end loop;
      return N;
   end Blocked_Count;

   function Indeterminate_Count (Model : Dataflow_Generic_Final_Model) return Natural is
   begin
      return Count_By_Status (Model, Dataflow_Generic_Final_Indeterminate);
   end Indeterminate_Count;

   function Count_By_Status (Model : Dataflow_Generic_Final_Model; Status : Dataflow_Generic_Final_Status) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop if Row.Status = Status then N := N + 1; end if; end loop;
      return N;
   end Count_By_Status;

   function Count_By_Blocker_Family (Model : Dataflow_Generic_Final_Model; Family : Dataflow_Generic_Final_Blocker_Family) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop if Row.Blocker_Family = Family then N := N + 1; end if; end loop;
      return N;
   end Count_By_Blocker_Family;

   function Find_By_Node (Model : Dataflow_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Dataflow_Generic_Final_Set is
      Result : Dataflow_Generic_Final_Set;
   begin
      for Row of Model.Rows loop if Row.Node = Node then Result.Rows.Append (Row); end if; end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint (Model : Dataflow_Generic_Final_Model; Fingerprint : Natural) return Dataflow_Generic_Final_Set is
      Result : Dataflow_Generic_Final_Set;
   begin
      for Row of Model.Rows loop if Row.Source_Fingerprint = Fingerprint then Result.Rows.Append (Row); end if; end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Query_Blocker_Family (Model : Dataflow_Generic_Final_Model; Family : Dataflow_Generic_Final_Blocker_Family) return Dataflow_Generic_Final_Set is
      Result : Dataflow_Generic_Final_Set;
   begin
      for Row of Model.Rows loop if Row.Blocker_Family = Family then Result.Rows.Append (Row); end if; end loop;
      return Result;
   end Query_Blocker_Family;

   function Query_Count (Set : Dataflow_Generic_Final_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_Row_At (Set : Dataflow_Generic_Final_Set; Index : Positive) return Dataflow_Generic_Final_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_Row_At;

   function Stable_Fingerprint (Model : Dataflow_Generic_Final_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
