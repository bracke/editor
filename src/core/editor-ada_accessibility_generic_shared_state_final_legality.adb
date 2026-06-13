with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality is

   use type Access_Final.Master_Scope_Final_Row_Id;
   use type Cross_Generic.Cross_Unit_Generic_Final_Row_Id;
   use type Elab_Generic.Elaboration_Generic_Final_Row_Id;
   use type Generic_Replay.Generic_Abstract_Replay_Row_Id;
   use type Overload_Generic.Overload_Generic_Final_Row_Id;
   use type Rep_Generic.Representation_Generic_Final_Row_Id;
   use type Tasking_Generic.Tasking_Generic_Final_Row_Id;
   use type Closure.Shared_State_Stabilized_Closure_Id;
   use type Closure.Shared_State_Stabilized_Closure_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16#10001# + Right + 97) mod 2_147_483_647;
   end Mix;

   function Is_Accepted (Status : Accessibility_Generic_Final_Status) return Boolean is
   begin
      case Status is
         when Accessibility_Generic_Final_Legal_Anonymous_Access_Result_Accepted
            | Accessibility_Generic_Final_Legal_Anonymous_Access_Parameter_Accepted
            | Accessibility_Generic_Final_Legal_Access_Discriminant_Accepted
            | Accessibility_Generic_Final_Legal_Allocator_Master_Accepted
            | Accessibility_Generic_Final_Legal_Access_Conversion_Accepted
            | Accessibility_Generic_Final_Legal_Return_Object_Accepted
            | Accessibility_Generic_Final_Legal_Return_Access_Accepted
            | Accessibility_Generic_Final_Legal_Generic_Access_Actual_Accepted
            | Accessibility_Generic_Final_Legal_Generic_Replay_Escape_Accepted
            | Accessibility_Generic_Final_Legal_Renaming_Accepted
            | Accessibility_Generic_Final_Legal_Controlled_Finalization_Accepted
            | Accessibility_Generic_Final_Legal_Private_Full_View_Accepted
            | Accessibility_Generic_Final_Legal_Cross_Unit_Lifetime_Accepted
            | Accessibility_Generic_Final_Legal_Task_Protected_Lifetime_Accepted
            | Accessibility_Generic_Final_Legal_Representation_Sensitive_Lifetime_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Accepted;

   function Is_Blocked (Status : Accessibility_Generic_Final_Status) return Boolean is
   begin
      return Status /= Accessibility_Generic_Final_Not_Checked and then not Is_Accepted (Status);
   end Is_Blocked;

   function Blocks_Downstream (Status : Accessibility_Generic_Final_Status) return Boolean is
   begin
      return Is_Blocked (Status);
   end Blocks_Downstream;

   function Accepted_For (Kind : Accessibility_Generic_Final_Kind) return Accessibility_Generic_Final_Status is
   begin
      case Kind is
         when Accessibility_Generic_Final_Anonymous_Access_Result =>
            return Accessibility_Generic_Final_Legal_Anonymous_Access_Result_Accepted;
         when Accessibility_Generic_Final_Anonymous_Access_Parameter =>
            return Accessibility_Generic_Final_Legal_Anonymous_Access_Parameter_Accepted;
         when Accessibility_Generic_Final_Access_Discriminant =>
            return Accessibility_Generic_Final_Legal_Access_Discriminant_Accepted;
         when Accessibility_Generic_Final_Allocator_Master =>
            return Accessibility_Generic_Final_Legal_Allocator_Master_Accepted;
         when Accessibility_Generic_Final_Access_Conversion =>
            return Accessibility_Generic_Final_Legal_Access_Conversion_Accepted;
         when Accessibility_Generic_Final_Return_Object =>
            return Accessibility_Generic_Final_Legal_Return_Object_Accepted;
         when Accessibility_Generic_Final_Return_Access =>
            return Accessibility_Generic_Final_Legal_Return_Access_Accepted;
         when Accessibility_Generic_Final_Generic_Access_Actual =>
            return Accessibility_Generic_Final_Legal_Generic_Access_Actual_Accepted;
         when Accessibility_Generic_Final_Generic_Replay_Escape =>
            return Accessibility_Generic_Final_Legal_Generic_Replay_Escape_Accepted;
         when Accessibility_Generic_Final_Renaming =>
            return Accessibility_Generic_Final_Legal_Renaming_Accepted;
         when Accessibility_Generic_Final_Controlled_Finalization =>
            return Accessibility_Generic_Final_Legal_Controlled_Finalization_Accepted;
         when Accessibility_Generic_Final_Private_Full_View =>
            return Accessibility_Generic_Final_Legal_Private_Full_View_Accepted;
         when Accessibility_Generic_Final_Cross_Unit_Lifetime =>
            return Accessibility_Generic_Final_Legal_Cross_Unit_Lifetime_Accepted;
         when Accessibility_Generic_Final_Task_Protected_Lifetime =>
            return Accessibility_Generic_Final_Legal_Task_Protected_Lifetime_Accepted;
         when Accessibility_Generic_Final_Representation_Sensitive_Lifetime =>
            return Accessibility_Generic_Final_Legal_Representation_Sensitive_Lifetime_Accepted;
         when Accessibility_Generic_Final_Unknown =>
            return Accessibility_Generic_Final_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For (Status : Accessibility_Generic_Final_Status) return Accessibility_Generic_Final_Blocker_Family is
   begin
      case Status is
         when Accessibility_Generic_Final_Missing_Final_Accessibility_Row
            | Accessibility_Generic_Final_Final_Accessibility_Blocker =>
            return Accessibility_Generic_Final_Blocker_Final_Accessibility;
         when Accessibility_Generic_Final_Missing_Cross_Unit_Generic_Row
            | Accessibility_Generic_Final_Cross_Unit_Generic_Blocker =>
            return Accessibility_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State;
         when Accessibility_Generic_Final_Missing_Elaboration_Generic_Row
            | Accessibility_Generic_Final_Elaboration_Generic_Blocker =>
            return Accessibility_Generic_Final_Blocker_Elaboration_Generic_Shared_State;
         when Accessibility_Generic_Final_Missing_Generic_Replay_Row
            | Accessibility_Generic_Final_Generic_Replay_Blocker =>
            return Accessibility_Generic_Final_Blocker_Generic_Abstract_Replay;
         when Accessibility_Generic_Final_Missing_Overload_Generic_Row
            | Accessibility_Generic_Final_Overload_Generic_Blocker =>
            return Accessibility_Generic_Final_Blocker_Overload_Generic_Shared_State;
         when Accessibility_Generic_Final_Missing_Representation_Generic_Row
            | Accessibility_Generic_Final_Representation_Generic_Blocker =>
            return Accessibility_Generic_Final_Blocker_Representation_Generic_Shared_State;
         when Accessibility_Generic_Final_Missing_Tasking_Generic_Row
            | Accessibility_Generic_Final_Tasking_Generic_Blocker =>
            return Accessibility_Generic_Final_Blocker_Tasking_Generic_Shared_State;
         when Accessibility_Generic_Final_Missing_Stabilized_Closure_Row
            | Accessibility_Generic_Final_Stabilized_Closure_Blocker =>
            return Accessibility_Generic_Final_Blocker_Stabilized_Shared_State_Closure;
         when Accessibility_Generic_Final_Access_Level_Blocker =>
            return Accessibility_Generic_Final_Blocker_Access_Level;
         when Accessibility_Generic_Final_Master_Escape_Blocker =>
            return Accessibility_Generic_Final_Blocker_Master_Escape;
         when Accessibility_Generic_Final_Return_Object_Blocker =>
            return Accessibility_Generic_Final_Blocker_Return_Object;
         when Accessibility_Generic_Final_Renaming_Lifetime_Blocker =>
            return Accessibility_Generic_Final_Blocker_Renaming_Lifetime;
         when Accessibility_Generic_Final_Finalization_Master_Blocker =>
            return Accessibility_Generic_Final_Blocker_Finalization_Master;
         when Accessibility_Generic_Final_Private_Full_View_Blocker =>
            return Accessibility_Generic_Final_Blocker_Private_Full_View;
         when Accessibility_Generic_Final_Cross_Unit_Lifetime_Blocker =>
            return Accessibility_Generic_Final_Blocker_Cross_Unit_Lifetime;
         when Accessibility_Generic_Final_Task_Protected_Lifetime_Blocker =>
            return Accessibility_Generic_Final_Blocker_Task_Protected_Lifetime;
         when Accessibility_Generic_Final_Representation_Sensitive_Lifetime_Blocker =>
            return Accessibility_Generic_Final_Blocker_Representation_Sensitive_Lifetime;
         when Accessibility_Generic_Final_Source_Fingerprint_Mismatch =>
            return Accessibility_Generic_Final_Blocker_Source_Fingerprint;
         when Accessibility_Generic_Final_Substitution_Fingerprint_Mismatch =>
            return Accessibility_Generic_Final_Blocker_Substitution_Fingerprint;
         when Accessibility_Generic_Final_Multiple_Blockers =>
            return Accessibility_Generic_Final_Blocker_Multiple;
         when Accessibility_Generic_Final_Indeterminate =>
            return Accessibility_Generic_Final_Blocker_Indeterminate;
         when others =>
            return Accessibility_Generic_Final_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Accessibility_Generic_Final_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Access_Level_Blocker then Count := Count + 1; end if;
      if C.Master_Escape_Blocker then Count := Count + 1; end if;
      if C.Return_Object_Blocker then Count := Count + 1; end if;
      if C.Renaming_Lifetime_Blocker then Count := Count + 1; end if;
      if C.Finalization_Master_Blocker then Count := Count + 1; end if;
      if C.Private_Full_View_Blocker then Count := Count + 1; end if;
      if C.Cross_Unit_Lifetime_Blocker then Count := Count + 1; end if;
      if C.Task_Protected_Lifetime_Blocker then Count := Count + 1; end if;
      if C.Representation_Sensitive_Lifetime_Blocker then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Accessibility_Generic_Final_Context) return Accessibility_Generic_Final_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Accessibility_Generic_Final_Multiple_Blockers;
      elsif C.Access_Level_Blocker then
         return Accessibility_Generic_Final_Access_Level_Blocker;
      elsif C.Master_Escape_Blocker then
         return Accessibility_Generic_Final_Master_Escape_Blocker;
      elsif C.Return_Object_Blocker then
         return Accessibility_Generic_Final_Return_Object_Blocker;
      elsif C.Renaming_Lifetime_Blocker then
         return Accessibility_Generic_Final_Renaming_Lifetime_Blocker;
      elsif C.Finalization_Master_Blocker then
         return Accessibility_Generic_Final_Finalization_Master_Blocker;
      elsif C.Private_Full_View_Blocker then
         return Accessibility_Generic_Final_Private_Full_View_Blocker;
      elsif C.Cross_Unit_Lifetime_Blocker then
         return Accessibility_Generic_Final_Cross_Unit_Lifetime_Blocker;
      elsif C.Task_Protected_Lifetime_Blocker then
         return Accessibility_Generic_Final_Task_Protected_Lifetime_Blocker;
      elsif C.Representation_Sensitive_Lifetime_Blocker then
         return Accessibility_Generic_Final_Representation_Sensitive_Lifetime_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Accessibility_Generic_Final_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Accessibility_Generic_Final_Substitution_Fingerprint_Mismatch;
      elsif C.Final_Accessibility_Row = Access_Final.No_Master_Scope_Final_Row then
         return Accessibility_Generic_Final_Missing_Final_Accessibility_Row;
      elsif not Access_Final.Is_Legal (C.Final_Accessibility_Status) then
         return Accessibility_Generic_Final_Final_Accessibility_Blocker;
      elsif C.Cross_Generic_Row = Cross_Generic.No_Cross_Unit_Generic_Final_Row then
         return Accessibility_Generic_Final_Missing_Cross_Unit_Generic_Row;
      elsif not Cross_Generic.Is_Accepted (C.Cross_Generic_Status) then
         return Accessibility_Generic_Final_Cross_Unit_Generic_Blocker;
      elsif C.Requires_Elaboration_Generic and then C.Elaboration_Generic_Row = Elab_Generic.No_Elaboration_Generic_Final_Row then
         return Accessibility_Generic_Final_Missing_Elaboration_Generic_Row;
      elsif C.Requires_Elaboration_Generic and then not Elab_Generic.Is_Accepted (C.Elaboration_Generic_Status) then
         return Accessibility_Generic_Final_Elaboration_Generic_Blocker;
      elsif C.Requires_Generic_Replay and then C.Generic_Replay_Row = Generic_Replay.No_Generic_Abstract_Replay_Row then
         return Accessibility_Generic_Final_Missing_Generic_Replay_Row;
      elsif C.Requires_Generic_Replay and then not Generic_Replay.Is_Accepted (C.Generic_Replay_Status) then
         return Accessibility_Generic_Final_Generic_Replay_Blocker;
      elsif C.Requires_Overload_Generic and then C.Overload_Generic_Row = Overload_Generic.No_Overload_Generic_Final_Row then
         return Accessibility_Generic_Final_Missing_Overload_Generic_Row;
      elsif C.Requires_Overload_Generic and then not Overload_Generic.Is_Accepted (C.Overload_Generic_Status) then
         return Accessibility_Generic_Final_Overload_Generic_Blocker;
      elsif C.Requires_Representation_Generic and then C.Representation_Generic_Row = Rep_Generic.No_Representation_Generic_Final_Row then
         return Accessibility_Generic_Final_Missing_Representation_Generic_Row;
      elsif C.Requires_Representation_Generic and then not Rep_Generic.Is_Accepted (C.Representation_Generic_Status) then
         return Accessibility_Generic_Final_Representation_Generic_Blocker;
      elsif C.Requires_Tasking_Generic and then C.Tasking_Generic_Row = Tasking_Generic.No_Tasking_Generic_Final_Row then
         return Accessibility_Generic_Final_Missing_Tasking_Generic_Row;
      elsif C.Requires_Tasking_Generic and then not Tasking_Generic.Is_Accepted (C.Tasking_Generic_Status) then
         return Accessibility_Generic_Final_Tasking_Generic_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Shared_State_Stabilized_Closure then
         return Accessibility_Generic_Final_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure
        and then C.Stabilized_Closure_Status /= Closure.Shared_State_Stabilized_Closure_Accepted_Current
        and then C.Stabilized_Closure_Status /= Closure.Shared_State_Stabilized_Closure_Accepted_Not_Required
      then
         return Accessibility_Generic_Final_Stabilized_Closure_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Accessibility_Generic_Final_Status;
      Kind   : Accessibility_Generic_Final_Kind;
      Family : Accessibility_Generic_Final_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("accessibility/generic shared-state final legality " &
         Accessibility_Generic_Final_Status'Image (Status) &
         " kind=" & Accessibility_Generic_Final_Kind'Image (Kind) &
         " blocker=" & Accessibility_Generic_Final_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Accessibility_Generic_Final_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Accessibility_Generic_Final_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Accessibility_Generic_Final_Status'Pos (Row.Status) + 1);
      H := Mix (H, Accessibility_Generic_Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Build_Row (C : Accessibility_Generic_Final_Context) return Accessibility_Generic_Final_Row is
      Status : constant Accessibility_Generic_Final_Status := Classify (C);
      Family : constant Accessibility_Generic_Final_Blocker_Family := Family_For (Status);
      Row : Accessibility_Generic_Final_Row;
   begin
      Row.Id := C.Id;
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Object_Name := C.Object_Name;
      Row.Type_Name := C.Type_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.State_Name := C.State_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Blocks_Downstream (Status);
      Row.Blocker_Count := Local_Blocker_Count (C);
      if Row.Blocked and then Row.Blocker_Count = 0 then
         Row.Blocker_Count := 1;
      end if;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Substitution_Fingerprint := C.Substitution_Fingerprint;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      Row.Message := Message_For (Status, C.Kind, Family);
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Build_Row;

   procedure Clear (Model : in out Accessibility_Generic_Final_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Stable_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Accessibility_Generic_Final_Context_Model; Info : Accessibility_Generic_Final_Context) is
   begin
      Model.Items.Append (Info);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Id));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Node));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Source_Fingerprint);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Accessibility_Generic_Final_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At (Model : Accessibility_Generic_Final_Context_Model; Index : Positive) return Accessibility_Generic_Final_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Build (Contexts : Accessibility_Generic_Final_Context_Model) return Accessibility_Generic_Final_Model is
      Result : Accessibility_Generic_Final_Model;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Accessibility_Generic_Final_Row := Build_Row (C);
         begin
            Result.Rows.Append (Row);
            Result.Stable_Fingerprint := Mix (Result.Stable_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Accessibility_Generic_Final_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At (Model : Accessibility_Generic_Final_Model; Index : Positive) return Accessibility_Generic_Final_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Accepted_Count (Model : Accessibility_Generic_Final_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Accepted then Result := Result + 1; end if;
      end loop;
      return Result;
   end Accepted_Count;

   function Blocked_Count (Model : Accessibility_Generic_Final_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocked then Result := Result + 1; end if;
      end loop;
      return Result;
   end Blocked_Count;

   function Indeterminate_Count (Model : Accessibility_Generic_Final_Model) return Natural is
   begin
      return Count_By_Status (Model, Accessibility_Generic_Final_Indeterminate);
   end Indeterminate_Count;

   function Count_By_Status (Model : Accessibility_Generic_Final_Model; Status : Accessibility_Generic_Final_Status) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then Result := Result + 1; end if;
      end loop;
      return Result;
   end Count_By_Status;

   function Count_By_Blocker_Family (Model : Accessibility_Generic_Final_Model; Family : Accessibility_Generic_Final_Blocker_Family) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then Result := Result + 1; end if;
      end loop;
      return Result;
   end Count_By_Blocker_Family;

   function Find_By_Node (Model : Accessibility_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Accessibility_Generic_Final_Query is
      Result : Accessibility_Generic_Final_Query;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then Result.Rows.Append (Row); end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint (Model : Accessibility_Generic_Final_Model; Fingerprint : Natural) return Accessibility_Generic_Final_Query is
      Result : Accessibility_Generic_Final_Query;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then Result.Rows.Append (Row); end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Query_Blocker_Family (Model : Accessibility_Generic_Final_Model; Family : Accessibility_Generic_Final_Blocker_Family) return Accessibility_Generic_Final_Query is
      Result : Accessibility_Generic_Final_Query;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then Result.Rows.Append (Row); end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Query_Count (Query : Accessibility_Generic_Final_Query) return Natural is
   begin
      return Natural (Query.Rows.Length);
   end Query_Count;

   function Query_Row_At (Query : Accessibility_Generic_Final_Query; Index : Positive) return Accessibility_Generic_Final_Row is
   begin
      return Query.Rows.Element (Index);
   end Query_Row_At;

   function Stable_Fingerprint (Model : Accessibility_Generic_Final_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
