with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Dispatching_Global_Refinement_Legality is

   pragma Suppress (Overflow_Check);

   use type Abstract_Consumers.Abstract_State_Consumer_Row_Id;
   use type Abstract_State.Abstract_State_Row_Id;
   use type Closure.Shared_State_Stabilized_Closure_Id;
   use type Closure.Shared_State_Stabilized_Closure_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Flow.Flow_Contract_Proof_Row_Id;
   use type Overload_State.Overload_Shared_State_Row_Id;
   use type Volatile_Rep.Volatile_Atomic_Representation_Row_Id;

   function Mix (Left, Right : Natural) return Natural is
      Modulus : constant Natural := 2 ** 30 - 35;
   begin
      return (Left * 131 + Right + 17) mod Modulus;
   end Mix;

   function Closure_Accepted
     (Status : Closure.Shared_State_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Closure.Shared_State_Stabilized_Closure_Accepted_Current
        or else Status = Closure.Shared_State_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Is_Accepted (Status : Dispatching_Global_Status) return Boolean is
   begin
      return Status in Dispatching_Global_Legal_Class_Wide_Call_Accepted ..
                       Dispatching_Global_Legal_Abstract_State_Join_Accepted;
   end Is_Accepted;

   function Is_Blocked (Status : Dispatching_Global_Status) return Boolean is
   begin
      return Status in Dispatching_Global_Missing_Flow_Proof_Row ..
                       Dispatching_Global_Multiple_Blockers;
   end Is_Blocked;

   function Is_Indeterminate (Status : Dispatching_Global_Status) return Boolean is
   begin
      return Status = Dispatching_Global_Indeterminate;
   end Is_Indeterminate;

   function Accepted_For (Kind : Dispatching_Global_Kind) return Dispatching_Global_Status is
   begin
      case Kind is
         when Dispatching_Global_Class_Wide_Call =>
            return Dispatching_Global_Legal_Class_Wide_Call_Accepted;
         when Dispatching_Global_Controlling_Operation =>
            return Dispatching_Global_Legal_Controlling_Operation_Accepted;
         when Dispatching_Global_Inherited_Primitive =>
            return Dispatching_Global_Legal_Inherited_Primitive_Accepted;
         when Dispatching_Global_Prefixed_Call =>
            return Dispatching_Global_Legal_Prefixed_Call_Accepted;
         when Dispatching_Global_Interface_Dispatch =>
            return Dispatching_Global_Legal_Interface_Dispatch_Accepted;
         when Dispatching_Global_Renamed_Primitive =>
            return Dispatching_Global_Legal_Renamed_Primitive_Accepted;
         when Dispatching_Global_Access_To_Class_Wide_Call =>
            return Dispatching_Global_Legal_Access_To_Class_Wide_Call_Accepted;
         when Dispatching_Global_Generic_Formal_Dispatch =>
            return Dispatching_Global_Legal_Generic_Formal_Dispatch_Accepted;
         when Dispatching_Global_Dynamic_Effect_Join =>
            return Dispatching_Global_Legal_Dynamic_Effect_Join_Accepted;
         when Dispatching_Global_Abstract_State_Join =>
            return Dispatching_Global_Legal_Abstract_State_Join_Accepted;
         when Dispatching_Global_Unknown =>
            return Dispatching_Global_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For (Status : Dispatching_Global_Status) return Dispatching_Global_Blocker_Family is
   begin
      case Status is
         when Dispatching_Global_Missing_Flow_Proof_Row |
              Dispatching_Global_Flow_Proof_Blocker =>
            return Dispatching_Global_Blocker_Flow_Contract;
         when Dispatching_Global_Missing_Abstract_State_Row |
              Dispatching_Global_Abstract_State_Blocker |
              Dispatching_Global_Abstract_State_Mode_Mismatch =>
            return Dispatching_Global_Blocker_Abstract_State;
         when Dispatching_Global_Missing_Abstract_Consumer_Row |
              Dispatching_Global_Abstract_Consumer_Blocker =>
            return Dispatching_Global_Blocker_Abstract_State_Consumer;
         when Dispatching_Global_Missing_Overload_Shared_State_Row |
              Dispatching_Global_Overload_Shared_State_Blocker =>
            return Dispatching_Global_Blocker_Overload_Shared_State;
         when Dispatching_Global_Missing_Volatile_Representation_Row |
              Dispatching_Global_Volatile_Representation_Blocker =>
            return Dispatching_Global_Blocker_Volatile_Atomic_Representation;
         when Dispatching_Global_Missing_Stabilized_Closure_Row |
              Dispatching_Global_Stabilized_Closure_Blocker =>
            return Dispatching_Global_Blocker_Stabilized_Shared_State_Closure;
         when Dispatching_Global_Mode_Mismatch =>
            return Dispatching_Global_Blocker_Global_Mode;
         when Dispatching_Global_Depends_Edge_Missing |
              Dispatching_Global_Depends_Edge_Extra =>
            return Dispatching_Global_Blocker_Depends_Edge;
         when Dispatching_Global_Dynamic_Effect_Join_Blocker =>
            return Dispatching_Global_Blocker_Dynamic_Effect_Join;
         when Dispatching_Global_Inherited_Primitive_Hiding_Blocker =>
            return Dispatching_Global_Blocker_Inherited_Primitive;
         when Dispatching_Global_Renamed_Primitive_Effect_Blocker =>
            return Dispatching_Global_Blocker_Renaming;
         when Dispatching_Global_Generic_Formal_Effect_Blocker =>
            return Dispatching_Global_Blocker_Generic_Formal;
         when Dispatching_Global_Source_Fingerprint_Mismatch =>
            return Dispatching_Global_Blocker_Source_Fingerprint;
         when Dispatching_Global_Multiple_Blockers =>
            return Dispatching_Global_Blocker_Multiple;
         when Dispatching_Global_Indeterminate =>
            return Dispatching_Global_Blocker_Indeterminate;
         when others =>
            return Dispatching_Global_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Dispatching_Global_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Global_Mode_Error then Count := Count + 1; end if;
      if C.Depends_Edge_Missing then Count := Count + 1; end if;
      if C.Depends_Edge_Extra then Count := Count + 1; end if;
      if C.Dynamic_Effect_Join_Error then Count := Count + 1; end if;
      if C.Abstract_State_Mode_Error then Count := Count + 1; end if;
      if C.Inherited_Primitive_Hiding_Error then Count := Count + 1; end if;
      if C.Renamed_Primitive_Effect_Error then Count := Count + 1; end if;
      if C.Generic_Formal_Effect_Error then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Dispatching_Global_Context) return Dispatching_Global_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Dispatching_Global_Multiple_Blockers;
      elsif C.Global_Mode_Error then
         return Dispatching_Global_Mode_Mismatch;
      elsif C.Depends_Edge_Missing then
         return Dispatching_Global_Depends_Edge_Missing;
      elsif C.Depends_Edge_Extra then
         return Dispatching_Global_Depends_Edge_Extra;
      elsif C.Dynamic_Effect_Join_Error then
         return Dispatching_Global_Dynamic_Effect_Join_Blocker;
      elsif C.Abstract_State_Mode_Error then
         return Dispatching_Global_Abstract_State_Mode_Mismatch;
      elsif C.Inherited_Primitive_Hiding_Error then
         return Dispatching_Global_Inherited_Primitive_Hiding_Blocker;
      elsif C.Renamed_Primitive_Effect_Error then
         return Dispatching_Global_Renamed_Primitive_Effect_Blocker;
      elsif C.Generic_Formal_Effect_Error then
         return Dispatching_Global_Generic_Formal_Effect_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Dispatching_Global_Source_Fingerprint_Mismatch;
      elsif C.Flow_Proof_Row = Flow.No_Flow_Contract_Proof_Row then
         return Dispatching_Global_Missing_Flow_Proof_Row;
      elsif not Flow.Is_Legal (C.Flow_Proof_Status) then
         return Dispatching_Global_Flow_Proof_Blocker;
      elsif C.Requires_Abstract_State and then C.Abstract_State_Row = Abstract_State.No_Abstract_State_Row then
         return Dispatching_Global_Missing_Abstract_State_Row;
      elsif C.Requires_Abstract_State and then not Abstract_State.Is_Legal (C.Abstract_State_Status) then
         return Dispatching_Global_Abstract_State_Blocker;
      elsif C.Requires_Abstract_Consumer and then C.Abstract_Consumer_Row = Abstract_Consumers.No_Abstract_State_Consumer_Row then
         return Dispatching_Global_Missing_Abstract_Consumer_Row;
      elsif C.Requires_Abstract_Consumer and then not Abstract_Consumers.Is_Accepted (C.Abstract_Consumer_Status) then
         return Dispatching_Global_Abstract_Consumer_Blocker;
      elsif C.Requires_Overload_Shared_State and then C.Overload_Shared_Row = Overload_State.No_Overload_Shared_State_Row then
         return Dispatching_Global_Missing_Overload_Shared_State_Row;
      elsif C.Requires_Overload_Shared_State and then not Overload_State.Is_Legal (C.Overload_Shared_Status) then
         return Dispatching_Global_Overload_Shared_State_Blocker;
      elsif C.Requires_Volatile_Representation and then C.Volatile_Representation_Row = Volatile_Rep.No_Volatile_Atomic_Representation_Row then
         return Dispatching_Global_Missing_Volatile_Representation_Row;
      elsif C.Requires_Volatile_Representation and then not Volatile_Rep.Is_Accepted (C.Volatile_Representation_Status) then
         return Dispatching_Global_Volatile_Representation_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Shared_State_Stabilized_Closure then
         return Dispatching_Global_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Closure_Status) then
         return Dispatching_Global_Stabilized_Closure_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Dispatching_Global_Status;
      Kind   : Dispatching_Global_Kind;
      Family : Dispatching_Global_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("dispatching Global/Depends refinement " &
         Dispatching_Global_Status'Image (Status) &
         " kind=" & Dispatching_Global_Kind'Image (Kind) &
         " blocker=" & Dispatching_Global_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Dispatching_Global_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Dispatching_Global_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Dispatching_Global_Status'Pos (Row.Status) + 1);
      H := Mix (H, Dispatching_Global_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row (C : Dispatching_Global_Context; Index : Positive) return Dispatching_Global_Row is
      Status : constant Dispatching_Global_Status := Classify (C);
      Family : constant Dispatching_Global_Blocker_Family := Family_For (Status);
      Row : Dispatching_Global_Row;
   begin
      Row.Id := Dispatching_Global_Row_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Operation_Name := C.Operation_Name;
      Row.Type_Name := C.Type_Name;
      Row.State_Name := C.State_Name;
      Row.Unit_Name := C.Unit_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Row.Blocked or else Is_Indeterminate (Status);
      Row.Blocker_Count := Local_Blocker_Count (C);
      if Row.Blocked and then Row.Blocker_Count = 0 then
         Row.Blocker_Count := 1;
      end if;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      Row.Message := Message_For (Status, C.Kind, Family);
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Dispatching_Global_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Dispatching_Global_Context_Model;
      Info  : Dispatching_Global_Context) is
   begin
      Model.Items.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Info.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Dispatching_Global_Kind'Pos (Info.Kind) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Info.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Source_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Expected_Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Dispatching_Global_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Dispatching_Global_Context_Model;
      Index : Positive) return Dispatching_Global_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Dispatching_Global_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Dispatching_Global_Context_Model) return Dispatching_Global_Model is
      Result : Dispatching_Global_Model;
      Index  : Positive := 1;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Dispatching_Global_Row := Make_Row (C, Index);
         begin
            Result.Rows.Append (Row);
            if Row.Accepted then
               Result.Accepted_Total := Result.Accepted_Total + 1;
            elsif Row.Blocked then
               Result.Blocked_Total := Result.Blocked_Total + 1;
            elsif Is_Indeterminate (Row.Status) then
               Result.Indeterminate_Total := Result.Indeterminate_Total + 1;
            end if;
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
            Index := Index + 1;
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Dispatching_Global_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Dispatching_Global_Model;
      Index : Positive) return Dispatching_Global_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Dispatching_Global_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Dispatching_Global_Set;
      Index : Positive) return Dispatching_Global_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Set_Fingerprint (Rows : Row_Vectors.Vector) return Natural is
      H : Natural := 0;
   begin
      for Row of Rows loop
         H := Mix (H, Row.Fingerprint);
      end loop;
      return H;
   end Set_Fingerprint;

   function Query_Status
     (Model  : Dispatching_Global_Model;
      Status : Dispatching_Global_Status) return Dispatching_Global_Set is
      Result : Dispatching_Global_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      Result.Fingerprint := Set_Fingerprint (Result.Rows);
      return Result;
   end Query_Status;

   function Query_Blocker_Family
     (Model  : Dispatching_Global_Model;
      Family : Dispatching_Global_Blocker_Family) return Dispatching_Global_Set is
      Result : Dispatching_Global_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
         end if;
      end loop;
      Result.Fingerprint := Set_Fingerprint (Result.Rows);
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Dispatching_Global_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Dispatching_Global_Set is
      Result : Dispatching_Global_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      Result.Fingerprint := Set_Fingerprint (Result.Rows);
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model              : Dispatching_Global_Model;
      Source_Fingerprint : Natural) return Dispatching_Global_Set is
      Result : Dispatching_Global_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      Result.Fingerprint := Set_Fingerprint (Result.Rows);
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Dispatching_Global_Model;
      Status : Dispatching_Global_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Dispatching_Global_Model;
      Family : Dispatching_Global_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Dispatching_Global_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Dispatching_Global_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Dispatching_Global_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Dispatching_Global_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Dispatching_Global_Refinement_Legality;
