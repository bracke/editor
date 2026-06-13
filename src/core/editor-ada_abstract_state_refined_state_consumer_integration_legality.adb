with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality is

   use type Stabilized_State.Shared_State_Stabilized_Closure_Status;
   use type States.Abstract_State_Row_Id;
   use type Shared.Shared_State_Row_Id;
   use type Overload_State.Overload_Shared_State_Row_Id;
   use type Rep_State.Representation_Shared_State_Row_Id;
   use type Tasking_State.Tasking_Shared_State_Row_Id;
   use type Cross_Unit_State.Cross_Unit_Shared_State_Row_Id;
   use type Stabilized_State.Shared_State_Stabilized_Closure_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 131) + Right + 1224) mod 2_147_483_647;
   end Mix;

   function Stabilized_Accepted
     (Status : Stabilized_State.Shared_State_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Stabilized_State.Shared_State_Stabilized_Closure_Accepted_Current
        or else Status = Stabilized_State.Shared_State_Stabilized_Closure_Accepted_Not_Required;
   end Stabilized_Accepted;

   function Is_Accepted (Status : Abstract_State_Consumer_Status) return Boolean is
   begin
      return Status in Abstract_State_Consumer_Legal_Global_Refinement_Accepted |
                       Abstract_State_Consumer_Legal_Depends_Refinement_Accepted |
                       Abstract_State_Consumer_Legal_Dispatching_Effect_Accepted |
                       Abstract_State_Consumer_Legal_Generic_Replay_Accepted |
                       Abstract_State_Consumer_Legal_Representation_Freezing_Accepted |
                       Abstract_State_Consumer_Legal_Tasking_Protected_Accepted |
                       Abstract_State_Consumer_Legal_Volatile_Atomic_Accepted |
                       Abstract_State_Consumer_Legal_Cross_Unit_Closure_Accepted |
                       Abstract_State_Consumer_Legal_Shared_State_Stabilized_Closure_Accepted;
   end Is_Accepted;

   function Is_Blocked (Status : Abstract_State_Consumer_Status) return Boolean is
   begin
      return Status not in Abstract_State_Consumer_Not_Checked |
                           Abstract_State_Consumer_Indeterminate |
                           Abstract_State_Consumer_Legal_Global_Refinement_Accepted |
                           Abstract_State_Consumer_Legal_Depends_Refinement_Accepted |
                           Abstract_State_Consumer_Legal_Dispatching_Effect_Accepted |
                           Abstract_State_Consumer_Legal_Generic_Replay_Accepted |
                           Abstract_State_Consumer_Legal_Representation_Freezing_Accepted |
                           Abstract_State_Consumer_Legal_Tasking_Protected_Accepted |
                           Abstract_State_Consumer_Legal_Volatile_Atomic_Accepted |
                           Abstract_State_Consumer_Legal_Cross_Unit_Closure_Accepted |
                           Abstract_State_Consumer_Legal_Shared_State_Stabilized_Closure_Accepted;
   end Is_Blocked;

   function Is_Indeterminate (Status : Abstract_State_Consumer_Status) return Boolean is
   begin
      return Status = Abstract_State_Consumer_Indeterminate;
   end Is_Indeterminate;

   function Accepted_For
     (Kind : Abstract_State_Consumer_Kind) return Abstract_State_Consumer_Status is
   begin
      case Kind is
         when Abstract_State_Consumer_Global_Refinement =>
            return Abstract_State_Consumer_Legal_Global_Refinement_Accepted;
         when Abstract_State_Consumer_Depends_Refinement =>
            return Abstract_State_Consumer_Legal_Depends_Refinement_Accepted;
         when Abstract_State_Consumer_Dispatching_Effect =>
            return Abstract_State_Consumer_Legal_Dispatching_Effect_Accepted;
         when Abstract_State_Consumer_Generic_Replay =>
            return Abstract_State_Consumer_Legal_Generic_Replay_Accepted;
         when Abstract_State_Consumer_Representation_Freezing =>
            return Abstract_State_Consumer_Legal_Representation_Freezing_Accepted;
         when Abstract_State_Consumer_Tasking_Protected =>
            return Abstract_State_Consumer_Legal_Tasking_Protected_Accepted;
         when Abstract_State_Consumer_Volatile_Atomic =>
            return Abstract_State_Consumer_Legal_Volatile_Atomic_Accepted;
         when Abstract_State_Consumer_Cross_Unit_Closure =>
            return Abstract_State_Consumer_Legal_Cross_Unit_Closure_Accepted;
         when Abstract_State_Consumer_Shared_State_Stabilized_Closure =>
            return Abstract_State_Consumer_Legal_Shared_State_Stabilized_Closure_Accepted;
         when Abstract_State_Consumer_Unknown =>
            return Abstract_State_Consumer_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For (Status : Abstract_State_Consumer_Status) return Abstract_State_Consumer_Blocker_Family is
   begin
      case Status is
         when Abstract_State_Consumer_Missing_Abstract_State_Row |
              Abstract_State_Consumer_Abstract_State_Blocker |
              Abstract_State_Consumer_Global_Mode_Blocker |
              Abstract_State_Consumer_Depends_Edge_Blocker =>
            return Abstract_State_Consumer_Blocker_Abstract_State;
         when Abstract_State_Consumer_Missing_Shared_State_Row |
              Abstract_State_Consumer_Shared_State_Blocker |
              Abstract_State_Consumer_Volatile_Atomic_Blocker =>
            return Abstract_State_Consumer_Blocker_Shared_State;
         when Abstract_State_Consumer_Missing_Overload_State_Row |
              Abstract_State_Consumer_Overload_State_Blocker |
              Abstract_State_Consumer_Dispatching_Effect_Blocker =>
            return Abstract_State_Consumer_Blocker_Overload_Dispatching;
         when Abstract_State_Consumer_Missing_Representation_State_Row |
              Abstract_State_Consumer_Representation_State_Blocker |
              Abstract_State_Consumer_Representation_Freezing_Blocker =>
            return Abstract_State_Consumer_Blocker_Representation_Freezing;
         when Abstract_State_Consumer_Missing_Tasking_State_Row |
              Abstract_State_Consumer_Tasking_State_Blocker |
              Abstract_State_Consumer_Tasking_Effect_Blocker =>
            return Abstract_State_Consumer_Blocker_Tasking_Protected;
         when Abstract_State_Consumer_Missing_Cross_Unit_State_Row |
              Abstract_State_Consumer_Cross_Unit_State_Blocker |
              Abstract_State_Consumer_Cross_Unit_Visibility_Blocker =>
            return Abstract_State_Consumer_Blocker_Cross_Unit;
         when Abstract_State_Consumer_Missing_Stabilized_Closure_Row |
              Abstract_State_Consumer_Stabilized_Closure_Blocker =>
            return Abstract_State_Consumer_Blocker_Stabilized_Closure;
         when Abstract_State_Consumer_Source_Fingerprint_Mismatch =>
            return Abstract_State_Consumer_Blocker_Source_Fingerprint;
         when Abstract_State_Consumer_Multiple_Blockers =>
            return Abstract_State_Consumer_Blocker_Multiple;
         when Abstract_State_Consumer_Indeterminate =>
            return Abstract_State_Consumer_Blocker_Indeterminate;
         when others =>
            return Abstract_State_Consumer_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Abstract_State_Consumer_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Global_Mode_Error then Count := Count + 1; end if;
      if C.Depends_Edge_Error then Count := Count + 1; end if;
      if C.Dispatching_Effect_Error then Count := Count + 1; end if;
      if C.Generic_Replay_Error then Count := Count + 1; end if;
      if C.Representation_Freezing_Error then Count := Count + 1; end if;
      if C.Tasking_Effect_Error then Count := Count + 1; end if;
      if C.Volatile_Atomic_Error then Count := Count + 1; end if;
      if C.Cross_Unit_Visibility_Error then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Abstract_State_Consumer_Context) return Abstract_State_Consumer_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Abstract_State_Consumer_Multiple_Blockers;
      elsif C.Global_Mode_Error then
         return Abstract_State_Consumer_Global_Mode_Blocker;
      elsif C.Depends_Edge_Error then
         return Abstract_State_Consumer_Depends_Edge_Blocker;
      elsif C.Dispatching_Effect_Error then
         return Abstract_State_Consumer_Dispatching_Effect_Blocker;
      elsif C.Generic_Replay_Error then
         return Abstract_State_Consumer_Generic_Replay_Blocker;
      elsif C.Representation_Freezing_Error then
         return Abstract_State_Consumer_Representation_Freezing_Blocker;
      elsif C.Tasking_Effect_Error then
         return Abstract_State_Consumer_Tasking_Effect_Blocker;
      elsif C.Volatile_Atomic_Error then
         return Abstract_State_Consumer_Volatile_Atomic_Blocker;
      elsif C.Cross_Unit_Visibility_Error then
         return Abstract_State_Consumer_Cross_Unit_Visibility_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Abstract_State_Consumer_Source_Fingerprint_Mismatch;
      elsif C.Abstract_State_Row = States.No_Abstract_State_Row then
         return Abstract_State_Consumer_Missing_Abstract_State_Row;
      elsif not States.Is_Legal (C.Abstract_State_Status) then
         return Abstract_State_Consumer_Abstract_State_Blocker;
      elsif C.Requires_Shared_State and then C.Shared_State_Row = Shared.No_Shared_State_Row then
         return Abstract_State_Consumer_Missing_Shared_State_Row;
      elsif C.Requires_Shared_State and then not Shared.Is_Legal (C.Shared_State_Status) then
         return Abstract_State_Consumer_Shared_State_Blocker;
      elsif C.Requires_Overload_State and then C.Overload_State_Row = Overload_State.No_Overload_Shared_State_Row then
         return Abstract_State_Consumer_Missing_Overload_State_Row;
      elsif C.Requires_Overload_State and then not Overload_State.Is_Legal (C.Overload_State_Status) then
         return Abstract_State_Consumer_Overload_State_Blocker;
      elsif C.Requires_Representation_State and then C.Representation_State_Row = Rep_State.No_Representation_Shared_State_Row then
         return Abstract_State_Consumer_Missing_Representation_State_Row;
      elsif C.Requires_Representation_State and then not Rep_State.Is_Legal (C.Representation_State_Status) then
         return Abstract_State_Consumer_Representation_State_Blocker;
      elsif C.Requires_Tasking_State and then C.Tasking_State_Row = Tasking_State.No_Tasking_Shared_State_Row then
         return Abstract_State_Consumer_Missing_Tasking_State_Row;
      elsif C.Requires_Tasking_State and then not Tasking_State.Is_Legal (C.Tasking_State_Status) then
         return Abstract_State_Consumer_Tasking_State_Blocker;
      elsif C.Requires_Cross_Unit_State and then C.Cross_Unit_State_Row = Cross_Unit_State.No_Cross_Unit_Shared_State_Row then
         return Abstract_State_Consumer_Missing_Cross_Unit_State_Row;
      elsif C.Requires_Cross_Unit_State and then not Cross_Unit_State.Is_Legal (C.Cross_Unit_State_Status) then
         return Abstract_State_Consumer_Cross_Unit_State_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Stabilized_State.No_Shared_State_Stabilized_Closure then
         return Abstract_State_Consumer_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not Stabilized_Accepted (C.Stabilized_Closure_Status) then
         return Abstract_State_Consumer_Stabilized_Closure_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Abstract_State_Consumer_Status;
      Kind   : Abstract_State_Consumer_Kind;
      Family : Abstract_State_Consumer_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("abstract/refined-state consumer integration " &
         Abstract_State_Consumer_Status'Image (Status) &
         " kind=" & Abstract_State_Consumer_Kind'Image (Kind) &
         " blocker=" & Abstract_State_Consumer_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Abstract_State_Consumer_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Abstract_State_Consumer_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Abstract_State_Consumer_Status'Pos (Row.Status) + 1);
      H := Mix (H, Abstract_State_Consumer_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (C     : Abstract_State_Consumer_Context;
      Index : Positive) return Abstract_State_Consumer_Row is
      Status : constant Abstract_State_Consumer_Status := Classify (C);
      Family : constant Abstract_State_Consumer_Blocker_Family := Family_For (Status);
      Row : Abstract_State_Consumer_Row;
   begin
      Row.Id := Abstract_State_Consumer_Row_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.State_Name := C.State_Name;
      Row.Consumer_Name := C.Consumer_Name;
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

   procedure Add_Row
     (Model : in out Abstract_State_Consumer_Model;
      Row   : Abstract_State_Consumer_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
      if Row.Accepted then
         Model.Accepted_Total := Model.Accepted_Total + 1;
      end if;
      if Row.Blocked then
         Model.Blocked_Total := Model.Blocked_Total + 1;
      end if;
      if Is_Indeterminate (Row.Status) then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out Abstract_State_Consumer_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Abstract_State_Consumer_Context_Model;
      Info  : Abstract_State_Consumer_Context) is
   begin
      Model.Items.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Info.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Abstract_State_Consumer_Kind'Pos (Info.Kind) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Info.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Source_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Expected_Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Abstract_State_Consumer_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Abstract_State_Consumer_Context_Model;
      Index : Positive) return Abstract_State_Consumer_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Abstract_State_Consumer_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Abstract_State_Consumer_Context_Model) return Abstract_State_Consumer_Model is
      Result : Abstract_State_Consumer_Model;
   begin
      for I in 1 .. Natural (Contexts.Items.Length) loop
         Add_Row (Result, Make_Row (Contexts.Items.Element (I), I));
      end loop;
      return Result;
   end Build;

   function Count (Model : Abstract_State_Consumer_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Abstract_State_Consumer_Model;
      Index : Positive) return Abstract_State_Consumer_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Abstract_State_Consumer_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Abstract_State_Consumer_Set;
      Index : Positive) return Abstract_State_Consumer_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Abstract_State_Consumer_Set;
      Row : Abstract_State_Consumer_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Abstract_State_Consumer_Model;
      Status : Abstract_State_Consumer_Status) return Abstract_State_Consumer_Set is
      Result : Abstract_State_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family
     (Model  : Abstract_State_Consumer_Model;
      Family : Abstract_State_Consumer_Blocker_Family) return Abstract_State_Consumer_Set is
      Result : Abstract_State_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Abstract_State_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Abstract_State_Consumer_Set is
      Result : Abstract_State_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model              : Abstract_State_Consumer_Model;
      Source_Fingerprint : Natural) return Abstract_State_Consumer_Set is
      Result : Abstract_State_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Abstract_State_Consumer_Model;
      Status : Abstract_State_Consumer_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Abstract_State_Consumer_Model;
      Family : Abstract_State_Consumer_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Abstract_State_Consumer_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Abstract_State_Consumer_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Abstract_State_Consumer_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Abstract_State_Consumer_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
