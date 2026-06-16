with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality is

   pragma Suppress (Overflow_Check);
   use type Closure.Generic_Shared_State_Final_Stabilized_Closure_Status;
   use type Previous.Overload_Generic_Final_Row_Id;
   use type Closure.Generic_Shared_State_Final_Stabilized_Closure_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 1_000_000_007;
   end Mix;

   function Is_Accepted (Status : Overload_Generic_RM_Edge_Status) return Boolean is
   begin
      case Status is
         when Overload_Generic_RM_Edge_Legal_Renamed_Primitive_Accepted |
              Overload_Generic_RM_Edge_Legal_Inherited_Private_Extension_Primitive_Accepted |
              Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted |
              Overload_Generic_RM_Edge_Legal_Prefixed_Call_Side_Effect_Contract_Accepted |
              Overload_Generic_RM_Edge_Legal_Access_Subprogram_Effect_Profile_Accepted |
              Overload_Generic_RM_Edge_Legal_Generic_Formal_Subprogram_Effect_Accepted |
              Overload_Generic_RM_Edge_Legal_Universal_Numeric_Expected_State_Accepted |
              Overload_Generic_RM_Edge_Legal_Class_Wide_Controlling_Result_State_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Accepted;

   function Is_Indeterminate (Status : Overload_Generic_RM_Edge_Status) return Boolean is
   begin
      return Status = Overload_Generic_RM_Edge_Indeterminate;
   end Is_Indeterminate;

   function Is_Blocked (Status : Overload_Generic_RM_Edge_Status) return Boolean is
   begin
      return not Is_Accepted (Status)
        and then Status /= Overload_Generic_RM_Edge_Not_Checked
        and then not Is_Indeterminate (Status);
   end Is_Blocked;

   function Closure_Accepted
     (Status : Closure.Generic_Shared_State_Final_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Closure.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current
        or else Status = Closure.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Accepted_For (Kind : Overload_Generic_RM_Edge_Kind) return Overload_Generic_RM_Edge_Status is
   begin
      case Kind is
         when Overload_Generic_RM_Edge_Renamed_Primitive =>
            return Overload_Generic_RM_Edge_Legal_Renamed_Primitive_Accepted;
         when Overload_Generic_RM_Edge_Inherited_Private_Extension_Primitive =>
            return Overload_Generic_RM_Edge_Legal_Inherited_Private_Extension_Primitive_Accepted;
         when Overload_Generic_RM_Edge_Dispatching_Abstract_State_Effect =>
            return Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted;
         when Overload_Generic_RM_Edge_Prefixed_Call_Side_Effect_Contract =>
            return Overload_Generic_RM_Edge_Legal_Prefixed_Call_Side_Effect_Contract_Accepted;
         when Overload_Generic_RM_Edge_Access_Subprogram_Effect_Profile =>
            return Overload_Generic_RM_Edge_Legal_Access_Subprogram_Effect_Profile_Accepted;
         when Overload_Generic_RM_Edge_Generic_Formal_Subprogram_Effect =>
            return Overload_Generic_RM_Edge_Legal_Generic_Formal_Subprogram_Effect_Accepted;
         when Overload_Generic_RM_Edge_Universal_Numeric_Expected_State =>
            return Overload_Generic_RM_Edge_Legal_Universal_Numeric_Expected_State_Accepted;
         when Overload_Generic_RM_Edge_Class_Wide_Controlling_Result_State =>
            return Overload_Generic_RM_Edge_Legal_Class_Wide_Controlling_Result_State_Accepted;
         when Overload_Generic_RM_Edge_Unknown =>
            return Overload_Generic_RM_Edge_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For (Status : Overload_Generic_RM_Edge_Status) return Overload_Generic_RM_Edge_Blocker_Family is
   begin
      case Status is
         when Overload_Generic_RM_Edge_Missing_Previous_Overload_Row |
              Overload_Generic_RM_Edge_Previous_Overload_Blocker =>
            return Overload_Generic_RM_Edge_Blocker_Previous_Overload;
         when Overload_Generic_RM_Edge_Missing_Stabilized_Closure_Row |
              Overload_Generic_RM_Edge_Stabilized_Closure_Blocker =>
            return Overload_Generic_RM_Edge_Blocker_Stabilized_Closure;
         when Overload_Generic_RM_Edge_Renamed_Primitive_Visibility_Mismatch =>
            return Overload_Generic_RM_Edge_Blocker_Renaming_Visibility;
         when Overload_Generic_RM_Edge_Inherited_Primitive_Private_Extension_Hidden =>
            return Overload_Generic_RM_Edge_Blocker_Inherited_Primitive_Hiding;
         when Overload_Generic_RM_Edge_Dispatching_Abstract_State_Mismatch =>
            return Overload_Generic_RM_Edge_Blocker_Dispatching_Abstract_State;
         when Overload_Generic_RM_Edge_Prefixed_Call_Effect_Contract_Mismatch =>
            return Overload_Generic_RM_Edge_Blocker_Prefixed_Call_Effect;
         when Overload_Generic_RM_Edge_Access_Profile_Effect_Mismatch =>
            return Overload_Generic_RM_Edge_Blocker_Access_Profile_Effect;
         when Overload_Generic_RM_Edge_Generic_Formal_Effect_Mismatch =>
            return Overload_Generic_RM_Edge_Blocker_Generic_Formal_Effect;
         when Overload_Generic_RM_Edge_Universal_Numeric_State_Ambiguous =>
            return Overload_Generic_RM_Edge_Blocker_Universal_Numeric_State;
         when Overload_Generic_RM_Edge_Class_Wide_Result_State_Mismatch =>
            return Overload_Generic_RM_Edge_Blocker_Class_Wide_Result_State;
         when Overload_Generic_RM_Edge_Source_Fingerprint_Mismatch =>
            return Overload_Generic_RM_Edge_Blocker_Source_Fingerprint;
         when Overload_Generic_RM_Edge_Substitution_Fingerprint_Mismatch =>
            return Overload_Generic_RM_Edge_Blocker_Substitution_Fingerprint;
         when Overload_Generic_RM_Edge_Multiple_Blockers =>
            return Overload_Generic_RM_Edge_Blocker_Multiple;
         when Overload_Generic_RM_Edge_Indeterminate =>
            return Overload_Generic_RM_Edge_Blocker_Indeterminate;
         when others =>
            return Overload_Generic_RM_Edge_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Overload_Generic_RM_Edge_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Renamed_Primitive_Visibility_Mismatch then Count := Count + 1; end if;
      if C.Inherited_Primitive_Hidden_By_Private_Extension then Count := Count + 1; end if;
      if C.Dispatching_Abstract_State_Mismatch then Count := Count + 1; end if;
      if C.Prefixed_Call_Effect_Contract_Mismatch then Count := Count + 1; end if;
      if C.Access_Profile_Effect_Mismatch then Count := Count + 1; end if;
      if C.Generic_Formal_Effect_Mismatch then Count := Count + 1; end if;
      if C.Universal_Numeric_State_Ambiguous then Count := Count + 1; end if;
      if C.Class_Wide_Result_State_Mismatch then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Overload_Generic_RM_Edge_Context) return Overload_Generic_RM_Edge_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Overload_Generic_RM_Edge_Multiple_Blockers;
      elsif C.Renamed_Primitive_Visibility_Mismatch then
         return Overload_Generic_RM_Edge_Renamed_Primitive_Visibility_Mismatch;
      elsif C.Inherited_Primitive_Hidden_By_Private_Extension then
         return Overload_Generic_RM_Edge_Inherited_Primitive_Private_Extension_Hidden;
      elsif C.Dispatching_Abstract_State_Mismatch then
         return Overload_Generic_RM_Edge_Dispatching_Abstract_State_Mismatch;
      elsif C.Prefixed_Call_Effect_Contract_Mismatch then
         return Overload_Generic_RM_Edge_Prefixed_Call_Effect_Contract_Mismatch;
      elsif C.Access_Profile_Effect_Mismatch then
         return Overload_Generic_RM_Edge_Access_Profile_Effect_Mismatch;
      elsif C.Generic_Formal_Effect_Mismatch then
         return Overload_Generic_RM_Edge_Generic_Formal_Effect_Mismatch;
      elsif C.Universal_Numeric_State_Ambiguous then
         return Overload_Generic_RM_Edge_Universal_Numeric_State_Ambiguous;
      elsif C.Class_Wide_Result_State_Mismatch then
         return Overload_Generic_RM_Edge_Class_Wide_Result_State_Mismatch;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Overload_Generic_RM_Edge_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Overload_Generic_RM_Edge_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Previous_Overload
        and then C.Previous_Overload_Row = Previous.No_Overload_Generic_Final_Row
      then
         return Overload_Generic_RM_Edge_Missing_Previous_Overload_Row;
      elsif C.Requires_Previous_Overload
        and then not Previous.Is_Accepted (C.Previous_Overload_Status)
      then
         return Overload_Generic_RM_Edge_Previous_Overload_Blocker;
      elsif C.Requires_Stabilized_Closure
        and then C.Stabilized_Closure_Row = Closure.No_Generic_Shared_State_Final_Stabilized_Closure
      then
         return Overload_Generic_RM_Edge_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Closure_Status) then
         return Overload_Generic_RM_Edge_Stabilized_Closure_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Overload_Generic_RM_Edge_Status;
      Kind   : Overload_Generic_RM_Edge_Kind;
      Family : Overload_Generic_RM_Edge_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("overload/generic shared-state RM edge completion " &
         Overload_Generic_RM_Edge_Status'Image (Status) &
         " kind=" & Overload_Generic_RM_Edge_Kind'Image (Kind) &
         " blocker=" & Overload_Generic_RM_Edge_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Overload_Generic_RM_Edge_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_446;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Overload_Generic_RM_Edge_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Overload_Generic_RM_Edge_Status'Pos (Row.Status) + 1);
      H := Mix (H, Overload_Generic_RM_Edge_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (C     : Overload_Generic_RM_Edge_Context;
      Index : Positive) return Overload_Generic_RM_Edge_Row is
      Status : constant Overload_Generic_RM_Edge_Status := Classify (C);
      Family : constant Overload_Generic_RM_Edge_Blocker_Family := Family_For (Status);
      Row    : Overload_Generic_RM_Edge_Row;
   begin
      Row.Id := Overload_Generic_RM_Edge_Completion_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Operation_Name := C.Operation_Name;
      Row.Type_Name := C.Type_Name;
      Row.State_Name := C.State_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Row.Blocked or else Is_Indeterminate (Status);
      Row.Blocker_Count := Local_Blocker_Count (C);
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Substitution_Fingerprint := C.Substitution_Fingerprint;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      Row.Message := Message_For (Status, C.Kind, Family);
      Row.Row_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Overload_Generic_RM_Edge_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Overload_Generic_RM_Edge_Context_Model;
      Context : Overload_Generic_RM_Edge_Context) is
   begin
      Model.Items.Append (Context);
      Model.Fingerprint := Mix
        (Model.Fingerprint,
         Natural (Context.Id) + Overload_Generic_RM_Edge_Kind'Pos (Context.Kind) + Context.Source_Fingerprint);
   end Add_Context;

   function Build (Contexts : Overload_Generic_RM_Edge_Context_Model) return Overload_Generic_RM_Edge_Model is
      Model : Overload_Generic_RM_Edge_Model;
      Row   : Overload_Generic_RM_Edge_Row;
   begin
      for I in 1 .. Natural (Contexts.Items.Length) loop
         Row := Make_Row (Contexts.Items.Element (I), I);
         Model.Rows.Append (Row);
         Model.Fingerprint := Mix (Model.Fingerprint, Row.Row_Fingerprint);
         if Row.Accepted then
            Model.Accepted_Total := Model.Accepted_Total + 1;
         end if;
         if Row.Blocked then
            Model.Blocked_Total := Model.Blocked_Total + 1;
         end if;
         if Is_Indeterminate (Row.Status) then
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         end if;
      end loop;
      return Model;
   end Build;

   function Count (Model : Overload_Generic_RM_Edge_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Overload_Generic_RM_Edge_Model;
      Index : Positive) return Overload_Generic_RM_Edge_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Overload_Generic_RM_Edge_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Overload_Generic_RM_Edge_Set;
      Index : Positive) return Overload_Generic_RM_Edge_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : Overload_Generic_RM_Edge_Model;
      Status : Overload_Generic_RM_Edge_Status) return Overload_Generic_RM_Edge_Set is
      Result : Overload_Generic_RM_Edge_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family
     (Model  : Overload_Generic_RM_Edge_Model;
      Family : Overload_Generic_RM_Edge_Blocker_Family) return Overload_Generic_RM_Edge_Set is
      Result : Overload_Generic_RM_Edge_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Overload_Generic_RM_Edge_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Generic_RM_Edge_Set is
      Result : Overload_Generic_RM_Edge_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : Overload_Generic_RM_Edge_Model;
      Fingerprint : Natural) return Overload_Generic_RM_Edge_Set is
      Result : Overload_Generic_RM_Edge_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Overload_Generic_RM_Edge_Model;
      Status : Overload_Generic_RM_Edge_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Overload_Generic_RM_Edge_Model;
      Family : Overload_Generic_RM_Edge_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Overload_Generic_RM_Edge_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Overload_Generic_RM_Edge_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Overload_Generic_RM_Edge_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Overload_Generic_RM_Edge_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
