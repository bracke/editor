with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality is

   pragma Suppress (Overflow_Check);

   use type Access_Generic.Accessibility_Generic_Final_Row_Id;
   use type Closure.Shared_State_Stabilized_Closure_Id;
   use type Closure.Shared_State_Stabilized_Closure_Status;
   use type Cross_Generic.Cross_Unit_Generic_Final_Row_Id;
   use type Disc_Final.Discriminant_Consumer_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Elab_Generic.Elaboration_Generic_Final_Row_Id;
   use type Generic_Replay.Generic_Abstract_Replay_Row_Id;
   use type Overload_Generic.Overload_Generic_Final_Row_Id;
   use type Rep_Generic.Representation_Generic_Final_Row_Id;
   use type Tasking_Generic.Tasking_Generic_Final_Row_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right + 17) mod 2_147_483_647;
   end Mix;

   function Accepted_For (Kind : Discriminant_Generic_Final_Kind) return Discriminant_Generic_Final_Status is
   begin
      case Kind is
         when Discriminant_Generic_Final_Record_Layout => return Discriminant_Generic_Final_Legal_Record_Layout_Accepted;
         when Discriminant_Generic_Final_Variant_Record_Layout => return Discriminant_Generic_Final_Legal_Variant_Record_Layout_Accepted;
         when Discriminant_Generic_Final_Record_Aggregate => return Discriminant_Generic_Final_Legal_Record_Aggregate_Accepted;
         when Discriminant_Generic_Final_Extension_Aggregate => return Discriminant_Generic_Final_Legal_Extension_Aggregate_Accepted;
         when Discriminant_Generic_Final_Access_Discriminant => return Discriminant_Generic_Final_Legal_Access_Discriminant_Accepted;
         when Discriminant_Generic_Final_Private_Full_View => return Discriminant_Generic_Final_Legal_Private_Full_View_Accepted;
         when Discriminant_Generic_Final_Generic_Replay => return Discriminant_Generic_Final_Legal_Generic_Replay_Accepted;
         when Discriminant_Generic_Final_Generic_Formal_Type => return Discriminant_Generic_Final_Legal_Generic_Formal_Type_Accepted;
         when Discriminant_Generic_Final_Representation_Clause => return Discriminant_Generic_Final_Legal_Representation_Clause_Accepted;
         when Discriminant_Generic_Final_Task_Protected_Discriminant => return Discriminant_Generic_Final_Legal_Task_Protected_Discriminant_Accepted;
         when Discriminant_Generic_Final_Cross_Unit_Discriminant => return Discriminant_Generic_Final_Legal_Cross_Unit_Discriminant_Accepted;
         when Discriminant_Generic_Final_Assignment_Conversion => return Discriminant_Generic_Final_Legal_Assignment_Conversion_Accepted;
         when Discriminant_Generic_Final_Return_Allocator => return Discriminant_Generic_Final_Legal_Return_Allocator_Accepted;
         when Discriminant_Generic_Final_Unknown => return Discriminant_Generic_Final_Indeterminate;
      end case;
   end Accepted_For;

   function Is_Accepted (Status : Discriminant_Generic_Final_Status) return Boolean is
   begin
      return Status in Discriminant_Generic_Final_Legal_Record_Layout_Accepted .. Discriminant_Generic_Final_Legal_Return_Allocator_Accepted;
   end Is_Accepted;

   function Is_Blocked (Status : Discriminant_Generic_Final_Status) return Boolean is
   begin
      return Status in Discriminant_Generic_Final_Missing_Discriminant_Consumer_Row .. Discriminant_Generic_Final_Multiple_Blockers;
   end Is_Blocked;

   function Blocks_Downstream (Status : Discriminant_Generic_Final_Status) return Boolean is
   begin
      return Is_Blocked (Status) or else Status = Discriminant_Generic_Final_Indeterminate;
   end Blocks_Downstream;

   function Family_For (Status : Discriminant_Generic_Final_Status) return Discriminant_Generic_Final_Blocker_Family is
   begin
      case Status is
         when Discriminant_Generic_Final_Missing_Discriminant_Consumer_Row | Discriminant_Generic_Final_Discriminant_Consumer_Blocker => return Discriminant_Generic_Final_Blocker_Discriminant_Consumer;
         when Discriminant_Generic_Final_Missing_Cross_Unit_Generic_Row | Discriminant_Generic_Final_Cross_Unit_Generic_Blocker => return Discriminant_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State;
         when Discriminant_Generic_Final_Missing_Elaboration_Generic_Row | Discriminant_Generic_Final_Elaboration_Generic_Blocker => return Discriminant_Generic_Final_Blocker_Elaboration_Generic_Shared_State;
         when Discriminant_Generic_Final_Missing_Generic_Replay_Row | Discriminant_Generic_Final_Generic_Replay_Blocker => return Discriminant_Generic_Final_Blocker_Generic_Abstract_Replay;
         when Discriminant_Generic_Final_Missing_Overload_Generic_Row | Discriminant_Generic_Final_Overload_Generic_Blocker => return Discriminant_Generic_Final_Blocker_Overload_Generic_Shared_State;
         when Discriminant_Generic_Final_Missing_Representation_Generic_Row | Discriminant_Generic_Final_Representation_Generic_Blocker => return Discriminant_Generic_Final_Blocker_Representation_Generic_Shared_State;
         when Discriminant_Generic_Final_Missing_Tasking_Generic_Row | Discriminant_Generic_Final_Tasking_Generic_Blocker => return Discriminant_Generic_Final_Blocker_Tasking_Generic_Shared_State;
         when Discriminant_Generic_Final_Missing_Accessibility_Generic_Row | Discriminant_Generic_Final_Accessibility_Generic_Blocker => return Discriminant_Generic_Final_Blocker_Accessibility_Generic_Shared_State;
         when Discriminant_Generic_Final_Missing_Stabilized_Closure_Row | Discriminant_Generic_Final_Stabilized_Closure_Blocker => return Discriminant_Generic_Final_Blocker_Stabilized_Shared_State_Closure;
         when Discriminant_Generic_Final_Discriminant_Constraint_Blocker => return Discriminant_Generic_Final_Blocker_Discriminant_Constraint;
         when Discriminant_Generic_Final_Variant_Coverage_Blocker => return Discriminant_Generic_Final_Blocker_Variant_Coverage;
         when Discriminant_Generic_Final_Aggregate_Association_Blocker => return Discriminant_Generic_Final_Blocker_Aggregate_Association;
         when Discriminant_Generic_Final_Private_Full_View_Blocker => return Discriminant_Generic_Final_Blocker_Private_Full_View;
         when Discriminant_Generic_Final_Generic_Substitution_Blocker => return Discriminant_Generic_Final_Blocker_Generic_Substitution;
         when Discriminant_Generic_Final_Representation_Layout_Blocker => return Discriminant_Generic_Final_Blocker_Representation_Layout;
         when Discriminant_Generic_Final_Task_Protected_Effect_Blocker => return Discriminant_Generic_Final_Blocker_Task_Protected_Effect;
         when Discriminant_Generic_Final_Access_Discriminant_Lifetime_Blocker => return Discriminant_Generic_Final_Blocker_Access_Discriminant_Lifetime;
         when Discriminant_Generic_Final_Cross_Unit_Consistency_Blocker => return Discriminant_Generic_Final_Blocker_Cross_Unit_Consistency;
         when Discriminant_Generic_Final_Source_Fingerprint_Mismatch => return Discriminant_Generic_Final_Blocker_Source_Fingerprint;
         when Discriminant_Generic_Final_Substitution_Fingerprint_Mismatch => return Discriminant_Generic_Final_Blocker_Substitution_Fingerprint;
         when Discriminant_Generic_Final_Multiple_Blockers => return Discriminant_Generic_Final_Blocker_Multiple;
         when Discriminant_Generic_Final_Indeterminate => return Discriminant_Generic_Final_Blocker_Indeterminate;
         when others => return Discriminant_Generic_Final_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Discriminant_Generic_Final_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Discriminant_Constraint_Blocker then Count := Count + 1; end if;
      if C.Variant_Coverage_Blocker then Count := Count + 1; end if;
      if C.Aggregate_Association_Blocker then Count := Count + 1; end if;
      if C.Private_Full_View_Blocker then Count := Count + 1; end if;
      if C.Generic_Substitution_Blocker then Count := Count + 1; end if;
      if C.Representation_Layout_Blocker then Count := Count + 1; end if;
      if C.Task_Protected_Effect_Blocker then Count := Count + 1; end if;
      if C.Access_Discriminant_Lifetime_Blocker then Count := Count + 1; end if;
      if C.Cross_Unit_Consistency_Blocker then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Discriminant_Generic_Final_Context) return Discriminant_Generic_Final_Status is
   begin
      if Local_Blocker_Count (C) > 1 then return Discriminant_Generic_Final_Multiple_Blockers;
      elsif C.Discriminant_Constraint_Blocker then return Discriminant_Generic_Final_Discriminant_Constraint_Blocker;
      elsif C.Variant_Coverage_Blocker then return Discriminant_Generic_Final_Variant_Coverage_Blocker;
      elsif C.Aggregate_Association_Blocker then return Discriminant_Generic_Final_Aggregate_Association_Blocker;
      elsif C.Private_Full_View_Blocker then return Discriminant_Generic_Final_Private_Full_View_Blocker;
      elsif C.Generic_Substitution_Blocker then return Discriminant_Generic_Final_Generic_Substitution_Blocker;
      elsif C.Representation_Layout_Blocker then return Discriminant_Generic_Final_Representation_Layout_Blocker;
      elsif C.Task_Protected_Effect_Blocker then return Discriminant_Generic_Final_Task_Protected_Effect_Blocker;
      elsif C.Access_Discriminant_Lifetime_Blocker then return Discriminant_Generic_Final_Access_Discriminant_Lifetime_Blocker;
      elsif C.Cross_Unit_Consistency_Blocker then return Discriminant_Generic_Final_Cross_Unit_Consistency_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then return Discriminant_Generic_Final_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then return Discriminant_Generic_Final_Substitution_Fingerprint_Mismatch;
      elsif C.Discriminant_Consumer_Row = Disc_Final.No_Discriminant_Consumer_Row then return Discriminant_Generic_Final_Missing_Discriminant_Consumer_Row;
      elsif not Disc_Final.Is_Legal (C.Discriminant_Consumer_Status) then return Discriminant_Generic_Final_Discriminant_Consumer_Blocker;
      elsif C.Cross_Generic_Row = Cross_Generic.No_Cross_Unit_Generic_Final_Row then return Discriminant_Generic_Final_Missing_Cross_Unit_Generic_Row;
      elsif not Cross_Generic.Is_Accepted (C.Cross_Generic_Status) then return Discriminant_Generic_Final_Cross_Unit_Generic_Blocker;
      elsif C.Requires_Elaboration_Generic and then C.Elaboration_Generic_Row = Elab_Generic.No_Elaboration_Generic_Final_Row then return Discriminant_Generic_Final_Missing_Elaboration_Generic_Row;
      elsif C.Requires_Elaboration_Generic and then not Elab_Generic.Is_Accepted (C.Elaboration_Generic_Status) then return Discriminant_Generic_Final_Elaboration_Generic_Blocker;
      elsif C.Requires_Generic_Replay and then C.Generic_Replay_Row = Generic_Replay.No_Generic_Abstract_Replay_Row then return Discriminant_Generic_Final_Missing_Generic_Replay_Row;
      elsif C.Requires_Generic_Replay and then not Generic_Replay.Is_Accepted (C.Generic_Replay_Status) then return Discriminant_Generic_Final_Generic_Replay_Blocker;
      elsif C.Requires_Overload_Generic and then C.Overload_Generic_Row = Overload_Generic.No_Overload_Generic_Final_Row then return Discriminant_Generic_Final_Missing_Overload_Generic_Row;
      elsif C.Requires_Overload_Generic and then not Overload_Generic.Is_Accepted (C.Overload_Generic_Status) then return Discriminant_Generic_Final_Overload_Generic_Blocker;
      elsif C.Requires_Representation_Generic and then C.Representation_Generic_Row = Rep_Generic.No_Representation_Generic_Final_Row then return Discriminant_Generic_Final_Missing_Representation_Generic_Row;
      elsif C.Requires_Representation_Generic and then not Rep_Generic.Is_Accepted (C.Representation_Generic_Status) then return Discriminant_Generic_Final_Representation_Generic_Blocker;
      elsif C.Requires_Tasking_Generic and then C.Tasking_Generic_Row = Tasking_Generic.No_Tasking_Generic_Final_Row then return Discriminant_Generic_Final_Missing_Tasking_Generic_Row;
      elsif C.Requires_Tasking_Generic and then not Tasking_Generic.Is_Accepted (C.Tasking_Generic_Status) then return Discriminant_Generic_Final_Tasking_Generic_Blocker;
      elsif C.Requires_Accessibility_Generic and then C.Accessibility_Generic_Row = Access_Generic.No_Accessibility_Generic_Final_Row then return Discriminant_Generic_Final_Missing_Accessibility_Generic_Row;
      elsif C.Requires_Accessibility_Generic and then not Access_Generic.Is_Accepted (C.Accessibility_Generic_Status) then return Discriminant_Generic_Final_Accessibility_Generic_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Shared_State_Stabilized_Closure then return Discriminant_Generic_Final_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not (C.Stabilized_Closure_Status = Closure.Shared_State_Stabilized_Closure_Accepted_Current or else C.Stabilized_Closure_Status = Closure.Shared_State_Stabilized_Closure_Accepted_Not_Required) then return Discriminant_Generic_Final_Stabilized_Closure_Blocker;
      else return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Row_Fingerprint (Row : Discriminant_Generic_Final_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Discriminant_Generic_Final_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Discriminant_Generic_Final_Status'Pos (Row.Status) + 1);
      H := Mix (H, Discriminant_Generic_Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for Ch of Text loop H := Mix (H, Character'Pos (Ch)); end loop;
      return H;
   end Row_Fingerprint;

   function Build_Row (C : Discriminant_Generic_Final_Context) return Discriminant_Generic_Final_Row is
      Status : constant Discriminant_Generic_Final_Status := Classify (C);
      Family : constant Discriminant_Generic_Final_Blocker_Family := Family_For (Status);
      Row : Discriminant_Generic_Final_Row;
   begin
      Row.Id := C.Id;
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Type_Name := C.Type_Name;
      Row.Object_Name := C.Object_Name;
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
        ("discriminant/generic shared-state final legality " &
         Discriminant_Generic_Final_Status'Image (Status) &
         " kind=" & Discriminant_Generic_Final_Kind'Image (C.Kind) &
         " blocker=" & Discriminant_Generic_Final_Blocker_Family'Image (Family));
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Build_Row;

   procedure Clear (Model : in out Discriminant_Generic_Final_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Stable_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Discriminant_Generic_Final_Context_Model; Info : Discriminant_Generic_Final_Context) is
   begin
      Model.Items.Append (Info);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Id));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Node));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Source_Fingerprint);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Discriminant_Generic_Final_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Build (Contexts : Discriminant_Generic_Final_Context_Model) return Discriminant_Generic_Final_Model is
      Result : Discriminant_Generic_Final_Model;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Discriminant_Generic_Final_Row := Build_Row (C);
         begin
            Result.Rows.Append (Row);
            Result.Stable_Fingerprint := Mix (Result.Stable_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Discriminant_Generic_Final_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At (Model : Discriminant_Generic_Final_Model; Index : Positive) return Discriminant_Generic_Final_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Accepted_Count (Model : Discriminant_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Accepted then N := N + 1; end if; end loop;
      return N;
   end Accepted_Count;

   function Blocked_Count (Model : Discriminant_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Blocked then N := N + 1; end if; end loop;
      return N;
   end Blocked_Count;

   function Indeterminate_Count (Model : Discriminant_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Status = Discriminant_Generic_Final_Indeterminate then N := N + 1; end if; end loop;
      return N;
   end Indeterminate_Count;

   function Count_By_Status (Model : Discriminant_Generic_Final_Model; Status : Discriminant_Generic_Final_Status) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Status = Status then N := N + 1; end if; end loop;
      return N;
   end Count_By_Status;

   function Count_By_Blocker_Family (Model : Discriminant_Generic_Final_Model; Family : Discriminant_Generic_Final_Blocker_Family) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Blocker_Family = Family then N := N + 1; end if; end loop;
      return N;
   end Count_By_Blocker_Family;

   function Find_By_Node (Model : Discriminant_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Discriminant_Generic_Final_Set is
      Result : Discriminant_Generic_Final_Set;
   begin
      for R of Model.Rows loop if R.Node = Node then Result.Rows.Append (R); end if; end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint (Model : Discriminant_Generic_Final_Model; Fingerprint : Natural) return Discriminant_Generic_Final_Set is
      Result : Discriminant_Generic_Final_Set;
   begin
      for R of Model.Rows loop if R.Source_Fingerprint = Fingerprint then Result.Rows.Append (R); end if; end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Query_Blocker_Family (Model : Discriminant_Generic_Final_Model; Family : Discriminant_Generic_Final_Blocker_Family) return Discriminant_Generic_Final_Set is
      Result : Discriminant_Generic_Final_Set;
   begin
      for R of Model.Rows loop if R.Blocker_Family = Family then Result.Rows.Append (R); end if; end loop;
      return Result;
   end Query_Blocker_Family;

   function Query_Count (Set : Discriminant_Generic_Final_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At (Set : Discriminant_Generic_Final_Set; Index : Positive) return Discriminant_Generic_Final_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Stable_Fingerprint (Model : Discriminant_Generic_Final_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality;
