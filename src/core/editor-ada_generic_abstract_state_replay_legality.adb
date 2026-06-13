with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Abstract_State_Replay_Legality is

   use type Abstract_Consumers.Abstract_State_Consumer_Row_Id;
   use type Backmap.Generic_Backmap_Row_Id;
   use type Closure.Shared_State_Stabilized_Closure_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Dispatching.Dispatching_Global_Row_Id;
   use type Nested.Nested_Generic_Closure_Row_Id;
   use type Shared.Shared_State_Row_Id;

   function Mix (Left, Right : Natural) return Natural is
      Modulus : constant Natural := 2 ** 30 - 35;
   begin
      return (Left * 131 + Right + 17) mod Modulus;
   end Mix;

   function Closure_Accepted
     (Status : Closure.Shared_State_Stabilized_Closure_Status) return Boolean is
   begin
      return Status in Closure.Shared_State_Stabilized_Closure_Accepted_Current |
                       Closure.Shared_State_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Is_Accepted (Status : Generic_Abstract_Replay_Status) return Boolean is
   begin
      return Status in Generic_Abstract_Replay_Legal_Global_Aspect_Accepted ..
                       Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted;
   end Is_Accepted;

   function Is_Blocked (Status : Generic_Abstract_Replay_Status) return Boolean is
   begin
      return Status in Generic_Abstract_Replay_Missing_Backmap_Row ..
                       Generic_Abstract_Replay_Multiple_Blockers;
   end Is_Blocked;

   function Is_Indeterminate (Status : Generic_Abstract_Replay_Status) return Boolean is
   begin
      return Status = Generic_Abstract_Replay_Indeterminate;
   end Is_Indeterminate;

   function Accepted_For (Kind : Generic_Abstract_Replay_Kind) return Generic_Abstract_Replay_Status is
   begin
      case Kind is
         when Generic_Abstract_Replay_Global_Aspect =>
            return Generic_Abstract_Replay_Legal_Global_Aspect_Accepted;
         when Generic_Abstract_Replay_Depends_Aspect =>
            return Generic_Abstract_Replay_Legal_Depends_Aspect_Accepted;
         when Generic_Abstract_Replay_Refined_State =>
            return Generic_Abstract_Replay_Legal_Refined_State_Accepted;
         when Generic_Abstract_Replay_Volatile_Effect =>
            return Generic_Abstract_Replay_Legal_Volatile_Effect_Accepted;
         when Generic_Abstract_Replay_Atomic_Effect =>
            return Generic_Abstract_Replay_Legal_Atomic_Effect_Accepted;
         when Generic_Abstract_Replay_Shared_Variable_Effect =>
            return Generic_Abstract_Replay_Legal_Shared_Variable_Effect_Accepted;
         when Generic_Abstract_Replay_Dispatching_Effect =>
            return Generic_Abstract_Replay_Legal_Dispatching_Effect_Accepted;
         when Generic_Abstract_Replay_Formal_Package_State =>
            return Generic_Abstract_Replay_Legal_Formal_Package_State_Accepted;
         when Generic_Abstract_Replay_Nested_Instance_State =>
            return Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted;
         when Generic_Abstract_Replay_Unknown =>
            return Generic_Abstract_Replay_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For
     (Status : Generic_Abstract_Replay_Status) return Generic_Abstract_Replay_Blocker_Family is
   begin
      case Status is
         when Generic_Abstract_Replay_Missing_Backmap_Row |
              Generic_Abstract_Replay_Backmap_Blocker =>
            return Generic_Abstract_Replay_Blocker_Source_Instance_Backmap;
         when Generic_Abstract_Replay_Missing_Nested_Closure_Row |
              Generic_Abstract_Replay_Nested_Closure_Blocker =>
            return Generic_Abstract_Replay_Blocker_Nested_Generic_Closure;
         when Generic_Abstract_Replay_Missing_Abstract_Consumer_Row |
              Generic_Abstract_Replay_Abstract_Consumer_Blocker =>
            return Generic_Abstract_Replay_Blocker_Abstract_State_Consumer;
         when Generic_Abstract_Replay_Missing_Shared_State_Row |
              Generic_Abstract_Replay_Shared_State_Blocker =>
            return Generic_Abstract_Replay_Blocker_Volatile_Atomic_Shared_State;
         when Generic_Abstract_Replay_Missing_Dispatching_Row |
              Generic_Abstract_Replay_Dispatching_Blocker =>
            return Generic_Abstract_Replay_Blocker_Dispatching_Global;
         when Generic_Abstract_Replay_Missing_Stabilized_Closure_Row |
              Generic_Abstract_Replay_Stabilized_Closure_Blocker =>
            return Generic_Abstract_Replay_Blocker_Stabilized_Shared_State_Closure;
         when Generic_Abstract_Replay_Formal_Actual_Missing |
              Generic_Abstract_Replay_Formal_Actual_Mode_Mismatch |
              Generic_Abstract_Replay_Formal_Actual_State_Mismatch =>
            return Generic_Abstract_Replay_Blocker_Formal_Actual_Substitution;
         when Generic_Abstract_Replay_Source_Fingerprint_Mismatch =>
            return Generic_Abstract_Replay_Blocker_Source_Fingerprint;
         when Generic_Abstract_Replay_Substitution_Fingerprint_Mismatch =>
            return Generic_Abstract_Replay_Blocker_Substitution_Fingerprint;
         when Generic_Abstract_Replay_Multiple_Blockers =>
            return Generic_Abstract_Replay_Blocker_Multiple;
         when Generic_Abstract_Replay_Indeterminate =>
            return Generic_Abstract_Replay_Blocker_Indeterminate;
         when others =>
            return Generic_Abstract_Replay_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Generic_Abstract_Replay_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Formal_Actual_Missing then Count := Count + 1; end if;
      if C.Formal_Actual_Mode_Mismatch then Count := Count + 1; end if;
      if C.Formal_Actual_State_Mismatch then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Generic_Abstract_Replay_Context) return Generic_Abstract_Replay_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Generic_Abstract_Replay_Multiple_Blockers;
      elsif C.Formal_Actual_Missing then
         return Generic_Abstract_Replay_Formal_Actual_Missing;
      elsif C.Formal_Actual_Mode_Mismatch then
         return Generic_Abstract_Replay_Formal_Actual_Mode_Mismatch;
      elsif C.Formal_Actual_State_Mismatch then
         return Generic_Abstract_Replay_Formal_Actual_State_Mismatch;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Generic_Abstract_Replay_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Generic_Abstract_Replay_Substitution_Fingerprint_Mismatch;
      elsif C.Backmap_Row = Backmap.No_Generic_Backmap_Row then
         return Generic_Abstract_Replay_Missing_Backmap_Row;
      elsif not Backmap.Is_Legal (C.Backmap_Status) then
         return Generic_Abstract_Replay_Backmap_Blocker;
      elsif C.Requires_Nested_Closure and then C.Nested_Row = Nested.No_Nested_Generic_Closure_Row then
         return Generic_Abstract_Replay_Missing_Nested_Closure_Row;
      elsif C.Requires_Nested_Closure and then not Nested.Is_Legal (C.Nested_Status) then
         return Generic_Abstract_Replay_Nested_Closure_Blocker;
      elsif C.Requires_Abstract_Consumer and then C.Abstract_Consumer_Row = Abstract_Consumers.No_Abstract_State_Consumer_Row then
         return Generic_Abstract_Replay_Missing_Abstract_Consumer_Row;
      elsif C.Requires_Abstract_Consumer and then not Abstract_Consumers.Is_Accepted (C.Abstract_Consumer_Status) then
         return Generic_Abstract_Replay_Abstract_Consumer_Blocker;
      elsif C.Requires_Shared_State and then C.Shared_State_Row = Shared.No_Shared_State_Row then
         return Generic_Abstract_Replay_Missing_Shared_State_Row;
      elsif C.Requires_Shared_State and then not Shared.Is_Legal (C.Shared_State_Status) then
         return Generic_Abstract_Replay_Shared_State_Blocker;
      elsif C.Requires_Dispatching and then C.Dispatching_Row = Dispatching.No_Dispatching_Global_Row then
         return Generic_Abstract_Replay_Missing_Dispatching_Row;
      elsif C.Requires_Dispatching and then not Dispatching.Is_Accepted (C.Dispatching_Status) then
         return Generic_Abstract_Replay_Dispatching_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Shared_State_Stabilized_Closure then
         return Generic_Abstract_Replay_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Closure_Status) then
         return Generic_Abstract_Replay_Stabilized_Closure_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Generic_Abstract_Replay_Status;
      Kind   : Generic_Abstract_Replay_Kind;
      Family : Generic_Abstract_Replay_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("generic abstract/refined-state replay " &
         Generic_Abstract_Replay_Status'Image (Status) &
         " kind=" & Generic_Abstract_Replay_Kind'Image (Kind) &
         " blocker=" & Generic_Abstract_Replay_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Generic_Abstract_Replay_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Generic_Abstract_Replay_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Generic_Abstract_Replay_Status'Pos (Row.Status) + 1);
      H := Mix (H, Generic_Abstract_Replay_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row (C : Generic_Abstract_Replay_Context; Index : Positive) return Generic_Abstract_Replay_Row is
      Status : constant Generic_Abstract_Replay_Status := Classify (C);
      Family : constant Generic_Abstract_Replay_Blocker_Family := Family_For (Status);
      Row : Generic_Abstract_Replay_Row;
   begin
      Row.Id := Generic_Abstract_Replay_Row_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.Formal_Name := C.Formal_Name;
      Row.Actual_Name := C.Actual_Name;
      Row.State_Name := C.State_Name;
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

   procedure Clear (Model : in out Generic_Abstract_Replay_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Generic_Abstract_Replay_Context_Model;
      Info  : Generic_Abstract_Replay_Context) is
   begin
      Model.Items.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Info.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Generic_Abstract_Replay_Kind'Pos (Info.Kind) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Info.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Source_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Substitution_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Expected_Source_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Expected_Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Generic_Abstract_Replay_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Generic_Abstract_Replay_Context_Model;
      Index : Positive) return Generic_Abstract_Replay_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Generic_Abstract_Replay_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Generic_Abstract_Replay_Context_Model) return Generic_Abstract_Replay_Model is
      Result : Generic_Abstract_Replay_Model;
   begin
      for I in 1 .. Natural (Contexts.Items.Length) loop
         declare
            Row : constant Generic_Abstract_Replay_Row := Make_Row (Contexts.Items.Element (I), I);
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
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Generic_Abstract_Replay_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Generic_Abstract_Replay_Model;
      Index : Positive) return Generic_Abstract_Replay_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Generic_Abstract_Replay_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Generic_Abstract_Replay_Set;
      Index : Positive) return Generic_Abstract_Replay_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : Generic_Abstract_Replay_Model;
      Status : Generic_Abstract_Replay_Status) return Generic_Abstract_Replay_Set is
      Result : Generic_Abstract_Replay_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family
     (Model  : Generic_Abstract_Replay_Model;
      Family : Generic_Abstract_Replay_Blocker_Family) return Generic_Abstract_Replay_Set is
      Result : Generic_Abstract_Replay_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Generic_Abstract_Replay_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Abstract_Replay_Set is
      Result : Generic_Abstract_Replay_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model              : Generic_Abstract_Replay_Model;
      Source_Fingerprint : Natural) return Generic_Abstract_Replay_Set is
      Result : Generic_Abstract_Replay_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Generic_Abstract_Replay_Model;
      Status : Generic_Abstract_Replay_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Generic_Abstract_Replay_Model;
      Family : Generic_Abstract_Replay_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Generic_Abstract_Replay_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Generic_Abstract_Replay_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Generic_Abstract_Replay_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Generic_Abstract_Replay_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Generic_Abstract_State_Replay_Legality;
