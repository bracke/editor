with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Overload_Generic_Shared_State_Final_Legality is
   use type Closure.Shared_State_Stabilized_Closure_Status;
   use type Overload.Overload_Shared_State_Row_Id;
   use type Generic_Replay.Generic_Abstract_Replay_Row_Id;
   use type Dispatching.Dispatching_Global_Row_Id;
   use type Volatile_Rep.Volatile_Atomic_Representation_Row_Id;
   use type Abstract_Consumers.Abstract_State_Consumer_Row_Id;
   use type Closure.Shared_State_Stabilized_Closure_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
      Modulus : constant Natural := 2 ** 30 - 35;
   begin
      return (A * 131 + B + 17) mod Modulus;
   end Mix;

   function Closure_Accepted
     (Status : Closure.Shared_State_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Closure.Shared_State_Stabilized_Closure_Accepted_Current
        or else Status = Closure.Shared_State_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Is_Accepted (Status : Overload_Generic_Final_Status) return Boolean is
   begin
      case Status is
         when Overload_Generic_Final_Legal_Prefixed_Call_Accepted |
              Overload_Generic_Final_Legal_Dispatching_Call_Accepted |
              Overload_Generic_Final_Legal_Access_Subprogram_Call_Accepted |
              Overload_Generic_Final_Legal_Class_Wide_Result_Accepted |
              Overload_Generic_Final_Legal_Inherited_Primitive_Accepted |
              Overload_Generic_Final_Legal_Renamed_Primitive_Accepted |
              Overload_Generic_Final_Legal_Generic_Formal_Subprogram_Accepted |
              Overload_Generic_Final_Legal_Universal_Numeric_Operator_Accepted |
              Overload_Generic_Final_Legal_Abstract_State_Effect_Accepted |
              Overload_Generic_Final_Legal_Volatile_Atomic_Effect_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Accepted;

   function Is_Indeterminate (Status : Overload_Generic_Final_Status) return Boolean is
   begin
      return Status = Overload_Generic_Final_Indeterminate;
   end Is_Indeterminate;

   function Is_Blocked (Status : Overload_Generic_Final_Status) return Boolean is
   begin
      return not Is_Accepted (Status)
        and then Status /= Overload_Generic_Final_Not_Checked
        and then not Is_Indeterminate (Status);
   end Is_Blocked;

   function Accepted_For (Kind : Overload_Generic_Final_Kind) return Overload_Generic_Final_Status is
   begin
      case Kind is
         when Overload_Generic_Final_Prefixed_Call =>
            return Overload_Generic_Final_Legal_Prefixed_Call_Accepted;
         when Overload_Generic_Final_Dispatching_Call =>
            return Overload_Generic_Final_Legal_Dispatching_Call_Accepted;
         when Overload_Generic_Final_Access_Subprogram_Call =>
            return Overload_Generic_Final_Legal_Access_Subprogram_Call_Accepted;
         when Overload_Generic_Final_Class_Wide_Result =>
            return Overload_Generic_Final_Legal_Class_Wide_Result_Accepted;
         when Overload_Generic_Final_Inherited_Primitive =>
            return Overload_Generic_Final_Legal_Inherited_Primitive_Accepted;
         when Overload_Generic_Final_Renamed_Primitive =>
            return Overload_Generic_Final_Legal_Renamed_Primitive_Accepted;
         when Overload_Generic_Final_Generic_Formal_Subprogram =>
            return Overload_Generic_Final_Legal_Generic_Formal_Subprogram_Accepted;
         when Overload_Generic_Final_Universal_Numeric_Operator =>
            return Overload_Generic_Final_Legal_Universal_Numeric_Operator_Accepted;
         when Overload_Generic_Final_Abstract_State_Effect =>
            return Overload_Generic_Final_Legal_Abstract_State_Effect_Accepted;
         when Overload_Generic_Final_Volatile_Atomic_Effect =>
            return Overload_Generic_Final_Legal_Volatile_Atomic_Effect_Accepted;
         when Overload_Generic_Final_Unknown =>
            return Overload_Generic_Final_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For (Status : Overload_Generic_Final_Status) return Overload_Generic_Final_Blocker_Family is
   begin
      case Status is
         when Overload_Generic_Final_Missing_Overload_Row |
              Overload_Generic_Final_Overload_Blocker =>
            return Overload_Generic_Final_Blocker_Overload_Shared_State;
         when Overload_Generic_Final_Missing_Generic_Replay_Row |
              Overload_Generic_Final_Generic_Replay_Blocker =>
            return Overload_Generic_Final_Blocker_Generic_Abstract_Replay;
         when Overload_Generic_Final_Missing_Dispatching_Row |
              Overload_Generic_Final_Dispatching_Blocker =>
            return Overload_Generic_Final_Blocker_Dispatching_Global;
         when Overload_Generic_Final_Missing_Volatile_Representation_Row |
              Overload_Generic_Final_Volatile_Representation_Blocker =>
            return Overload_Generic_Final_Blocker_Volatile_Atomic_Representation;
         when Overload_Generic_Final_Missing_Abstract_Consumer_Row |
              Overload_Generic_Final_Abstract_Consumer_Blocker =>
            return Overload_Generic_Final_Blocker_Abstract_State_Consumer;
         when Overload_Generic_Final_Missing_Stabilized_Closure_Row |
              Overload_Generic_Final_Stabilized_Closure_Blocker =>
            return Overload_Generic_Final_Blocker_Stabilized_Shared_State_Closure;
         when Overload_Generic_Final_Access_Profile_Effect_Mismatch =>
            return Overload_Generic_Final_Blocker_Access_Profile_Effect;
         when Overload_Generic_Final_Dispatching_Effect_Mismatch =>
            return Overload_Generic_Final_Blocker_Dispatching_Effect;
         when Overload_Generic_Final_Controlling_Result_State_Mismatch =>
            return Overload_Generic_Final_Blocker_Controlling_Result_State;
         when Overload_Generic_Final_Universal_Numeric_State_Ambiguous =>
            return Overload_Generic_Final_Blocker_Universal_Numeric_State;
         when Overload_Generic_Final_Source_Fingerprint_Mismatch =>
            return Overload_Generic_Final_Blocker_Source_Fingerprint;
         when Overload_Generic_Final_Substitution_Fingerprint_Mismatch =>
            return Overload_Generic_Final_Blocker_Substitution_Fingerprint;
         when Overload_Generic_Final_Multiple_Blockers =>
            return Overload_Generic_Final_Blocker_Multiple;
         when Overload_Generic_Final_Indeterminate =>
            return Overload_Generic_Final_Blocker_Indeterminate;
         when others =>
            return Overload_Generic_Final_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Overload_Generic_Final_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Access_Profile_Effect_Mismatch then Count := Count + 1; end if;
      if C.Dispatching_Effect_Mismatch then Count := Count + 1; end if;
      if C.Controlling_Result_State_Mismatch then Count := Count + 1; end if;
      if C.Universal_Numeric_State_Ambiguous then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Overload_Generic_Final_Context) return Overload_Generic_Final_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Overload_Generic_Final_Multiple_Blockers;
      elsif C.Access_Profile_Effect_Mismatch then
         return Overload_Generic_Final_Access_Profile_Effect_Mismatch;
      elsif C.Dispatching_Effect_Mismatch then
         return Overload_Generic_Final_Dispatching_Effect_Mismatch;
      elsif C.Controlling_Result_State_Mismatch then
         return Overload_Generic_Final_Controlling_Result_State_Mismatch;
      elsif C.Universal_Numeric_State_Ambiguous then
         return Overload_Generic_Final_Universal_Numeric_State_Ambiguous;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Overload_Generic_Final_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Overload_Generic_Final_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Overload and then C.Overload_Row = Overload.No_Overload_Shared_State_Row then
         return Overload_Generic_Final_Missing_Overload_Row;
      elsif C.Requires_Overload and then not Overload.Is_Legal (C.Overload_Status) then
         return Overload_Generic_Final_Overload_Blocker;
      elsif C.Requires_Generic_Replay and then C.Generic_Replay_Row = Generic_Replay.No_Generic_Abstract_Replay_Row then
         return Overload_Generic_Final_Missing_Generic_Replay_Row;
      elsif C.Requires_Generic_Replay and then not Generic_Replay.Is_Accepted (C.Generic_Replay_Status) then
         return Overload_Generic_Final_Generic_Replay_Blocker;
      elsif C.Requires_Dispatching and then C.Dispatching_Row = Dispatching.No_Dispatching_Global_Row then
         return Overload_Generic_Final_Missing_Dispatching_Row;
      elsif C.Requires_Dispatching and then not Dispatching.Is_Accepted (C.Dispatching_Status) then
         return Overload_Generic_Final_Dispatching_Blocker;
      elsif C.Requires_Volatile_Representation
        and then C.Volatile_Representation_Row = Volatile_Rep.No_Volatile_Atomic_Representation_Row
      then
         return Overload_Generic_Final_Missing_Volatile_Representation_Row;
      elsif C.Requires_Volatile_Representation
        and then not Volatile_Rep.Is_Accepted (C.Volatile_Representation_Status)
      then
         return Overload_Generic_Final_Volatile_Representation_Blocker;
      elsif C.Requires_Abstract_Consumer
        and then C.Abstract_Consumer_Row = Abstract_Consumers.No_Abstract_State_Consumer_Row
      then
         return Overload_Generic_Final_Missing_Abstract_Consumer_Row;
      elsif C.Requires_Abstract_Consumer
        and then not Abstract_Consumers.Is_Accepted (C.Abstract_Consumer_Status)
      then
         return Overload_Generic_Final_Abstract_Consumer_Blocker;
      elsif C.Requires_Stabilized_Closure
        and then C.Stabilized_Closure_Row = Closure.No_Shared_State_Stabilized_Closure
      then
         return Overload_Generic_Final_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Closure_Status) then
         return Overload_Generic_Final_Stabilized_Closure_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Overload_Generic_Final_Status;
      Kind   : Overload_Generic_Final_Kind;
      Family : Overload_Generic_Final_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("overload/generic shared-state final legality " &
         Overload_Generic_Final_Status'Image (Status) &
         " kind=" & Overload_Generic_Final_Kind'Image (Kind) &
         " blocker=" & Overload_Generic_Final_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Overload_Generic_Final_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Overload_Generic_Final_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Overload_Generic_Final_Status'Pos (Row.Status) + 1);
      H := Mix (H, Overload_Generic_Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row (C : Overload_Generic_Final_Context; Index : Positive) return Overload_Generic_Final_Row is
      Status : constant Overload_Generic_Final_Status := Classify (C);
      Family : constant Overload_Generic_Final_Blocker_Family := Family_For (Status);
      Row : Overload_Generic_Final_Row;
   begin
      Row.Id := Overload_Generic_Final_Row_Id (Index);
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
   end Make_Row;

   procedure Clear (Model : in out Overload_Generic_Final_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Overload_Generic_Final_Context_Model;
      Info  : Overload_Generic_Final_Context) is
   begin
      Model.Items.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Info.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Overload_Generic_Final_Kind'Pos (Info.Kind) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Info.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Source_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Substitution_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Expected_Source_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Expected_Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Overload_Generic_Final_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Overload_Generic_Final_Context_Model;
      Index : Positive) return Overload_Generic_Final_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Overload_Generic_Final_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Overload_Generic_Final_Context_Model) return Overload_Generic_Final_Model is
      Result : Overload_Generic_Final_Model;
   begin
      for I in 1 .. Natural (Contexts.Items.Length) loop
         declare
            Row : constant Overload_Generic_Final_Row := Make_Row (Contexts.Items.Element (I), I);
         begin
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Overload_Generic_Final_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Overload_Generic_Final_Model;
      Index : Positive) return Overload_Generic_Final_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Overload_Generic_Final_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Overload_Generic_Final_Set;
      Index : Positive) return Overload_Generic_Final_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : Overload_Generic_Final_Model;
      Status : Overload_Generic_Final_Status) return Overload_Generic_Final_Set is
      Result : Overload_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family
     (Model  : Overload_Generic_Final_Model;
      Family : Overload_Generic_Final_Blocker_Family) return Overload_Generic_Final_Set is
      Result : Overload_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Overload_Generic_Final_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Generic_Final_Set is
      Result : Overload_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model              : Overload_Generic_Final_Model;
      Source_Fingerprint : Natural) return Overload_Generic_Final_Set is
      Result : Overload_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Overload_Generic_Final_Model;
      Status : Overload_Generic_Final_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Overload_Generic_Final_Model;
      Family : Overload_Generic_Final_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Overload_Generic_Final_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Accepted then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Accepted_Count;

   function Blocked_Count (Model : Overload_Generic_Final_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocked then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Blocked_Count;

   function Indeterminate_Count (Model : Overload_Generic_Final_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Overload_Generic_Final_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
