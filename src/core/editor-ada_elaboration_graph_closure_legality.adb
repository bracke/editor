with Ada.Characters.Handling;

package body Editor.Ada_Elaboration_Graph_Closure_Legality is

   pragma Suppress (Overflow_Check);

   use Ada.Strings.Unbounded;

   use type Base.Elaboration_Order_State;
   use type Base.Elaboration_Policy_State;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16_777_619 + Right + 97) mod 2_147_483_647;
   end Mix;

   function Kind_Slot (Kind : Elaboration_Graph_Context_Kind) return Natural is
   begin
      return Elaboration_Graph_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Elaboration_Graph_Closure_Status) return Natural is
   begin
      return Elaboration_Graph_Closure_Status'Pos (Status) + 1;
   end Status_Slot;

   function Order_Slot (State : Base.Elaboration_Order_State) return Natural is
   begin
      return Base.Elaboration_Order_State'Pos (State) + 1;
   end Order_Slot;

   function Policy_Slot (State : Base.Elaboration_Policy_State) return Natural is
   begin
      return Base.Elaboration_Policy_State'Pos (State) + 1;
   end Policy_Slot;

   function Lower (Value : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Value);
   end Lower;

   function Is_Legal_Status (Status : Elaboration_Graph_Closure_Status) return Boolean is
   begin
      return Status in
        Graph_Closure_Legal_Library_Edge |
        Graph_Closure_Legal_Transitive_Elaborate_All |
        Graph_Closure_Legal_Body_Before_Use |
        Graph_Closure_Legal_Direct_Call_Order |
        Graph_Closure_Legal_Indirect_Call_Order |
        Graph_Closure_Legal_Dispatching_Call_Order |
        Graph_Closure_Legal_Access_Order |
        Graph_Closure_Legal_Generic_Instance_Order |
        Graph_Closure_Legal_Default_Expression_Order |
        Graph_Closure_Legal_Aspect_Expression_Order |
        Graph_Closure_Legal_Representation_Item_Order |
        Graph_Closure_Legal_Preelaboration_Policy |
        Graph_Closure_Legal_Pure_Policy;
   end Is_Legal_Status;

   function Gate_Blocker (Status : Gates.Enforcement_Status) return Boolean is
   begin
      return Status in
        Gates.Enforcement_Legal_Result_Suppressed |
        Gates.Enforcement_Derived_Result_Suppressed |
        Gates.Enforcement_Parser_AST_Blocker |
        Gates.Enforcement_Metadata_Blocker |
        Gates.Enforcement_Consumer_Integration_Blocker |
        Gates.Enforcement_Unsafe_Result_Blocked;
   end Gate_Blocker;

   function Base_Error (Status : Base.Elaboration_Legality_Status) return Boolean is
   begin
      return Status not in
        Base.Elaboration_Legality_Not_Checked |
        Base.Elaboration_Legality_Legal_Dependency |
        Base.Elaboration_Legality_Legal_Elaborate_Pragma |
        Base.Elaboration_Legality_Legal_Elaborate_All_Pragma |
        Base.Elaboration_Legality_Legal_Elaborate_Body_Pragma |
        Base.Elaboration_Legality_Legal_Preelaborate |
        Base.Elaboration_Legality_Legal_Pure |
        Base.Elaboration_Legality_Legal_Body_Before_Use |
        Base.Elaboration_Legality_Legal_Generic_Instance;
   end Base_Error;

   function Precision_Error (Status : Precision.Elaboration_Precision_Status) return Boolean is
   begin
      return Status not in
        Precision.Elaboration_Precision_Not_Checked |
        Precision.Elaboration_Precision_Legal_Dependency_Order |
        Precision.Elaboration_Precision_Legal_Call_Order |
        Precision.Elaboration_Precision_Legal_Access_Order |
        Precision.Elaboration_Precision_Legal_Generic_Instance_Order |
        Precision.Elaboration_Precision_Legal_Body_Before_Use |
        Precision.Elaboration_Precision_Legal_Preelaborated_Unit |
        Precision.Elaboration_Precision_Legal_Pure_Unit |
        Precision.Elaboration_Precision_Legal_Remote_Types_Unit |
        Precision.Elaboration_Precision_Legal_Shared_Passive_Unit;
   end Precision_Error;

   function Replay_Error (Status : Replay.Replay_Status) return Boolean is
   begin
      return Status not in
        Replay.Replay_Not_Checked |
        Replay.Replay_Legal_Substituted_Declaration |
        Replay.Replay_Legal_Substituted_Statement |
        Replay.Replay_Legal_Substituted_Expression |
        Replay.Replay_Legal_Call |
        Replay.Replay_Legal_Flow_Effect |
        Replay.Replay_Legal_Predicate_Invariant |
        Replay.Replay_Legal_Accessibility |
        Replay.Replay_Legal_Representation_Freezing |
        Replay.Replay_Legal_Nested_Instance;
   end Replay_Error;

   function Flow_Error (Status : Flow.Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status not in
        Flow.Flow_Graph_Not_Checked |
        Flow.Flow_Graph_Legal_Read_Edge |
        Flow.Flow_Graph_Legal_Write_Edge |
        Flow.Flow_Graph_Legal_Read_Write_Edge |
        Flow.Flow_Graph_Legal_Depends_Edge |
        Flow.Flow_Graph_Legal_Call_Propagation |
        Flow.Flow_Graph_Legal_Generic_Substitution |
        Flow.Flow_Graph_Legal_Protected_State_Effect |
        Flow.Flow_Graph_Legal_Task_Activation_Effect |
        Flow.Flow_Graph_Legal_Refined_Global |
        Flow.Flow_Graph_Legal_Refined_Depends |
        Flow.Flow_Graph_Legal_Null_Effect;
   end Flow_Error;

   function Scope_Error (Status : Scope.Scope_Legality_Status) return Boolean is
   begin
      return Status not in
        Scope.Scope_Legality_Not_Checked |
        Scope.Scope_Legality_Legal_Master_Hierarchy |
        Scope.Scope_Legality_Legal_Static_Level |
        Scope.Scope_Legality_Legal_Dynamic_Check |
        Scope.Scope_Legality_Legal_Allocator_Master |
        Scope.Scope_Legality_Legal_Return_Object_Master |
        Scope.Scope_Legality_Legal_Return_Access_Master |
        Scope.Scope_Legality_Legal_Access_Discriminant_Master |
        Scope.Scope_Legality_Legal_Access_Conversion |
        Scope.Scope_Legality_Legal_Generic_Substitution |
        Scope.Scope_Legality_Legal_Discriminant_Aggregate;
   end Scope_Error;

   function Blocker_Count (Info : Elaboration_Graph_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if Gate_Blocker (Info.Gate_Status) then Count := Count + 1; end if;
      if Base_Error (Info.Base_Status) then Count := Count + 1; end if;
      if Precision_Error (Info.Precision_Status) then Count := Count + 1; end if;
      if Replay_Error (Info.Replay_Status) then Count := Count + 1; end if;
      if Flow_Error (Info.Flow_Status) then Count := Count + 1; end if;
      if Scope_Error (Info.Scope_Status) then Count := Count + 1; end if;
      if Info.Cycle_Detected then Count := Count + 1; end if;
      if Info.Missing_Edge then Count := Count + 1; end if;
      if Info.Ambiguous_Edge then Count := Count + 1; end if;
      if Info.Requires_Elaborate_All and then not Info.Has_Transitive_Elaborate_All then Count := Count + 1; end if;
      if Info.Requires_Body_Before_Use and then not Info.Body_Elaborated_Before_Use then Count := Count + 1; end if;
      if Info.Generic_Instance and then not Info.Generic_Body_Elaborated then Count := Count + 1; end if;
      if Info.Generic_Instance and then not Info.Formal_Body_Resolved then Count := Count + 1; end if;
      if Info.Illegal_Preelaborate_Effect then Count := Count + 1; end if;
      if Info.Illegal_Pure_Effect then Count := Count + 1; end if;
      if Info.Illegal_Remote_Types_Effect then Count := Count + 1; end if;
      if Info.Illegal_Shared_Passive_Effect then Count := Count + 1; end if;
      return Count;
   end Blocker_Count;

   function Classify (Info : Elaboration_Graph_Context_Info) return Elaboration_Graph_Closure_Status is
      Blockers : constant Natural := Blocker_Count (Info);
   begin
      if Blockers > 1 then
         return Graph_Closure_Multiple_Blockers;
      elsif Gate_Blocker (Info.Gate_Status) then
         return Graph_Closure_Coverage_Gate_Blocker;
      elsif Base_Error (Info.Base_Status) then
         return Graph_Closure_Linked_Base_Elaboration_Error;
      elsif Precision_Error (Info.Precision_Status) then
         return Graph_Closure_Linked_Precision_Error;
      elsif Replay_Error (Info.Replay_Status) then
         return Graph_Closure_Linked_Generic_Replay_Error;
      elsif Flow_Error (Info.Flow_Status) then
         return Graph_Closure_Flow_Effect_Blocker;
      elsif Scope_Error (Info.Scope_Status) then
         return Graph_Closure_Accessibility_Scope_Blocker;
      elsif Info.Cycle_Detected or else Info.Order_State = Base.Elaboration_Order_Circular then
         if not Info.Cycle_Path_Known or else Length (Info.Path_Text) = 0 then
            return Graph_Closure_Cycle_Path_Missing_Source;
         else
            return Graph_Closure_Circular_Library_Elaboration;
         end if;
      elsif Info.Ambiguous_Edge or else Info.Order_State = Base.Elaboration_Order_Ambiguous_Dependency then
         return Graph_Closure_Ambiguous_Dependency_Edge;
      elsif Info.Missing_Edge or else Info.Order_State = Base.Elaboration_Order_Missing_Dependency then
         return Graph_Closure_Missing_Dependency_Edge;
      elsif Info.Requires_Elaborate_All and then not Info.Has_Transitive_Elaborate_All then
         return Graph_Closure_Missing_Transitive_Elaborate_All;
      elsif Info.Requires_Body_Before_Use and then not Info.Body_Elaborated_Before_Use then
         return Graph_Closure_Missing_Body_Before_Use;
      elsif Info.Dispatching_Call and then not Info.Body_Elaborated_Before_Use then
         return Graph_Closure_Dispatching_Call_Before_Body;
      elsif Info.Indirect_Call and then not Info.Body_Elaborated_Before_Use then
         return Graph_Closure_Indirect_Call_Before_Body;
      elsif Info.Direct_Call and then not Info.Body_Elaborated_Before_Use then
         return Graph_Closure_Direct_Call_Before_Body;
      elsif Info.Access_During_Elaboration and then Info.Order_State = Base.Elaboration_Order_Known_After then
         return Graph_Closure_Access_Before_Elaboration;
      elsif Info.Generic_Instance and then not Info.Generic_Body_Elaborated then
         return Graph_Closure_Generic_Instance_Body_Not_Elaborated;
      elsif Info.Generic_Instance and then not Info.Formal_Body_Resolved then
         return Graph_Closure_Generic_Instance_Formal_Body_Unresolved;
      elsif Info.Illegal_Preelaborate_Effect then
         return Graph_Closure_Preelaboration_Illegal_Effect;
      elsif Info.Illegal_Pure_Effect then
         return Graph_Closure_Pure_Illegal_Effect;
      elsif Info.Illegal_Remote_Types_Effect then
         return Graph_Closure_Remote_Types_Illegal_Effect;
      elsif Info.Illegal_Shared_Passive_Effect then
         return Graph_Closure_Shared_Passive_Illegal_Effect;
      elsif Info.Order_State = Base.Elaboration_Order_Unknown then
         return Graph_Closure_Indeterminate;
      elsif Info.Requires_Elaborate_All and then Info.Has_Transitive_Elaborate_All then
         return Graph_Closure_Legal_Transitive_Elaborate_All;
      elsif Info.Requires_Body_Before_Use then
         return Graph_Closure_Legal_Body_Before_Use;
      elsif Info.Dispatching_Call then
         return Graph_Closure_Legal_Dispatching_Call_Order;
      elsif Info.Indirect_Call then
         return Graph_Closure_Legal_Indirect_Call_Order;
      elsif Info.Direct_Call then
         return Graph_Closure_Legal_Direct_Call_Order;
      elsif Info.Access_During_Elaboration then
         return Graph_Closure_Legal_Access_Order;
      elsif Info.Generic_Instance then
         return Graph_Closure_Legal_Generic_Instance_Order;
      elsif Info.Default_Expression_Edge then
         return Graph_Closure_Legal_Default_Expression_Order;
      elsif Info.Aspect_Expression_Edge then
         return Graph_Closure_Legal_Aspect_Expression_Order;
      elsif Info.Representation_Item_Edge then
         return Graph_Closure_Legal_Representation_Item_Order;
      elsif Info.Policy_State = Base.Elaboration_Policy_Preelaborated then
         return Graph_Closure_Legal_Preelaboration_Policy;
      elsif Info.Policy_State = Base.Elaboration_Policy_Pure then
         return Graph_Closure_Legal_Pure_Policy;
      else
         return Graph_Closure_Legal_Library_Edge;
      end if;
   end Classify;

   function Message_For (Status : Elaboration_Graph_Closure_Status) return String is
   begin
      case Status is
         when Graph_Closure_Legal_Library_Edge => return "library elaboration edge is closed";
         when Graph_Closure_Legal_Transitive_Elaborate_All => return "transitive Elaborate_All closure is satisfied";
         when Graph_Closure_Legal_Body_Before_Use => return "body-before-use closure is satisfied";
         when Graph_Closure_Legal_Direct_Call_Order => return "direct call elaboration order is legal";
         when Graph_Closure_Legal_Indirect_Call_Order => return "indirect call elaboration order is legal";
         when Graph_Closure_Legal_Dispatching_Call_Order => return "dispatching call elaboration order is legal";
         when Graph_Closure_Legal_Access_Order => return "access elaboration order is legal";
         when Graph_Closure_Legal_Generic_Instance_Order => return "generic instance elaboration order is legal";
         when Graph_Closure_Legal_Default_Expression_Order => return "default expression elaboration edge is legal";
         when Graph_Closure_Legal_Aspect_Expression_Order => return "aspect expression elaboration edge is legal";
         when Graph_Closure_Legal_Representation_Item_Order => return "representation item elaboration edge is legal";
         when Graph_Closure_Legal_Preelaboration_Policy => return "preelaboration graph policy is satisfied";
         when Graph_Closure_Legal_Pure_Policy => return "pure unit graph policy is satisfied";
         when Graph_Closure_Missing_Transitive_Elaborate_All => return "missing transitive Elaborate_All closure";
         when Graph_Closure_Missing_Body_Before_Use => return "missing body-before-use closure";
         when Graph_Closure_Direct_Call_Before_Body => return "direct call may precede callee body elaboration";
         when Graph_Closure_Indirect_Call_Before_Body => return "indirect call may precede callee body elaboration";
         when Graph_Closure_Dispatching_Call_Before_Body => return "dispatching call may precede target body elaboration";
         when Graph_Closure_Access_Before_Elaboration => return "access value may designate entity before elaboration";
         when Graph_Closure_Generic_Instance_Body_Not_Elaborated => return "generic instance body is not elaborated before use";
         when Graph_Closure_Generic_Instance_Formal_Body_Unresolved => return "generic instance formal body elaboration is unresolved";
         when Graph_Closure_Circular_Library_Elaboration => return "circular library elaboration dependency";
         when Graph_Closure_Cycle_Path_Missing_Source => return "elaboration cycle lacks source path";
         when Graph_Closure_Missing_Dependency_Edge => return "missing elaboration dependency edge";
         when Graph_Closure_Ambiguous_Dependency_Edge => return "ambiguous elaboration dependency edge";
         when Graph_Closure_Preelaboration_Illegal_Effect => return "preelaborated unit has illegal elaboration effect";
         when Graph_Closure_Pure_Illegal_Effect => return "pure unit has illegal elaboration effect";
         when Graph_Closure_Remote_Types_Illegal_Effect => return "remote types unit has illegal elaboration effect";
         when Graph_Closure_Shared_Passive_Illegal_Effect => return "shared passive unit has illegal elaboration effect";
         when Graph_Closure_Flow_Effect_Blocker => return "flow-effect graph blocks elaboration closure";
         when Graph_Closure_Accessibility_Scope_Blocker => return "accessibility scope graph blocks elaboration closure";
         when Graph_Closure_Linked_Base_Elaboration_Error => return "base elaboration legality blocks graph closure";
         when Graph_Closure_Linked_Precision_Error => return "elaboration precision legality blocks graph closure";
         when Graph_Closure_Linked_Generic_Replay_Error => return "generic body replay blocks elaboration graph closure";
         when Graph_Closure_Coverage_Gate_Blocker => return "coverage gate blocks elaboration graph conclusion";
         when Graph_Closure_Multiple_Blockers => return "multiple elaboration graph blockers are present";
         when Graph_Closure_Indeterminate => return "elaboration graph closure is indeterminate";
         when others => return "elaboration graph closure was not checked";
      end case;
   end Message_For;

   function Fingerprint_Context (Info : Elaboration_Graph_Context_Info) return Natural is
      FP : Natural := 1_144;
   begin
      FP := Mix (FP, Natural (Info.Id));
      FP := Mix (FP, Kind_Slot (Info.Kind));
      FP := Mix (FP, Base.Elaboration_Dependence_Kind'Pos (Info.Dependence) + 1);
      FP := Mix (FP, Order_Slot (Info.Order_State));
      FP := Mix (FP, Policy_Slot (Info.Policy_State));
      FP := Mix (FP, Natural (Info.Node));
      FP := Mix (FP, Natural (Info.Source_Unit_Node));
      FP := Mix (FP, Natural (Info.Target_Unit_Node));
      FP := Mix (FP, Info.Edge_Depth);
      FP := Mix (FP, Info.Source_Fingerprint);
      return FP;
   end Fingerprint_Context;

   function Fingerprint_Row (Info : Elaboration_Graph_Closure_Info) return Natural is
      FP : Natural := 1_144;
   begin
      FP := Mix (FP, Natural (Info.Id));
      FP := Mix (FP, Kind_Slot (Info.Kind));
      FP := Mix (FP, Status_Slot (Info.Status));
      FP := Mix (FP, Base.Elaboration_Dependence_Kind'Pos (Info.Dependence) + 1);
      FP := Mix (FP, Order_Slot (Info.Order_State));
      FP := Mix (FP, Policy_Slot (Info.Policy_State));
      FP := Mix (FP, Natural (Info.Node));
      FP := Mix (FP, Natural (Info.Source_Unit_Node));
      FP := Mix (FP, Natural (Info.Target_Unit_Node));
      FP := Mix (FP, Info.Edge_Depth);
      FP := Mix (FP, Info.Blocker_Count);
      FP := Mix (FP, Info.Source_Fingerprint);
      return FP;
   end Fingerprint_Row;

   procedure Clear (Model : in out Elaboration_Graph_Context_Model) is
   begin
      Model.Rows.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Elaboration_Graph_Context_Model;
      Info  : Elaboration_Graph_Context_Info)
   is
   begin
      Model.Rows.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Fingerprint_Context (Info));
   end Add_Context;

   function Context_Count (Model : Elaboration_Graph_Context_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Context_Count;

   function Context_At
     (Model : Elaboration_Graph_Context_Model;
      Index : Positive) return Elaboration_Graph_Context_Info
   is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Context_At;

   function Fingerprint (Model : Elaboration_Graph_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Elaboration_Graph_Context_Model) return Elaboration_Graph_Closure_Model
   is
      Result  : Elaboration_Graph_Closure_Model;
      Next_Id : Natural := 1;
   begin
      for C of Contexts.Rows loop
         declare
            Status : constant Elaboration_Graph_Closure_Status := Classify (C);
            Row    : Elaboration_Graph_Closure_Info;
         begin
            Row.Id := Elaboration_Graph_Edge_Id (Next_Id);
            Row.Kind := C.Kind;
            Row.Dependence := C.Dependence;
            Row.Status := Status;
            Row.Node := C.Node;
            Row.Source_Unit_Node := C.Source_Unit_Node;
            Row.Target_Unit_Node := C.Target_Unit_Node;
            Row.Source_Unit_Name := C.Source_Unit_Name;
            Row.Target_Unit_Name := C.Target_Unit_Name;
            Row.Path_Text := C.Path_Text;
            Row.Message := To_Unbounded_String (Message_For (Status));
            Row.Detail := To_Unbounded_String ("Case 1144 elaboration graph closure");
            Row.Edge_Depth := C.Edge_Depth;
            Row.Order_State := C.Order_State;
            Row.Policy_State := C.Policy_State;
            Row.Base_Status := C.Base_Status;
            Row.Precision_Status := C.Precision_Status;
            Row.Replay_Status := C.Replay_Status;
            Row.Flow_Status := C.Flow_Status;
            Row.Scope_Status := C.Scope_Status;
            Row.Gate_Status := C.Gate_Status;
            Row.Blocker_Count := Blocker_Count (C);
            Row.Start_Line := C.Start_Line;
            Row.Start_Column := C.Start_Column;
            Row.End_Line := C.End_Line;
            Row.End_Column := C.End_Column;
            Row.Source_Fingerprint := C.Source_Fingerprint;
            Row.Fingerprint := Fingerprint_Row (Row);
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Elaboration_Graph_Closure_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Elaboration_Graph_Closure_Model;
      Index : Positive) return Elaboration_Graph_Closure_Info
   is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Elaboration_Graph_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_Graph_Closure_Info
   is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Elaboration_Graph_Closure_Model;
      Status : Elaboration_Graph_Closure_Status) return Elaboration_Graph_Result_Set
   is
      Result : Elaboration_Graph_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Elaboration_Graph_Closure_Model;
      Kind  : Elaboration_Graph_Context_Kind) return Elaboration_Graph_Result_Set
   is
      Result : Elaboration_Graph_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Unit
     (Model : Elaboration_Graph_Closure_Model;
      Name  : String) return Elaboration_Graph_Result_Set
   is
      Result : Elaboration_Graph_Result_Set;
      Query  : constant String := Lower (Name);
   begin
      for Row of Model.Rows loop
         if Lower (To_String (Row.Source_Unit_Name)) = Query
           or else Lower (To_String (Row.Target_Unit_Name)) = Query
         then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Unit;

   function Result_Count (Results : Elaboration_Graph_Result_Set) return Natural is
   begin
      return Natural (Results.Rows.Length);
   end Result_Count;

   function Result_At
     (Results : Elaboration_Graph_Result_Set;
      Index   : Positive) return Elaboration_Graph_Closure_Info
   is
   begin
      if Index > Natural (Results.Rows.Length) then
         return (others => <>);
      end if;
      return Results.Rows.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Elaboration_Graph_Closure_Model;
      Status : Elaboration_Graph_Closure_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Elaboration_Graph_Closure_Model;
      Kind  : Elaboration_Graph_Context_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Elaboration_Graph_Closure_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal_Status (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Has_Legality (Row) and then not Is_Legal_Status (Row.Status)
           and then Row.Status /= Graph_Closure_Indeterminate
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Transitive_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Graph_Closure_Missing_Transitive_Elaborate_All);
   end Transitive_Error_Count;

   function Body_Before_Use_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Graph_Closure_Missing_Body_Before_Use)
        + Count_Status (Model, Graph_Closure_Direct_Call_Before_Body)
        + Count_Status (Model, Graph_Closure_Indirect_Call_Before_Body)
        + Count_Status (Model, Graph_Closure_Dispatching_Call_Before_Body);
   end Body_Before_Use_Error_Count;

   function Call_Order_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Graph_Closure_Direct_Call_Before_Body)
        + Count_Status (Model, Graph_Closure_Indirect_Call_Before_Body)
        + Count_Status (Model, Graph_Closure_Dispatching_Call_Before_Body)
        + Count_Status (Model, Graph_Closure_Access_Before_Elaboration);
   end Call_Order_Error_Count;

   function Generic_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Graph_Closure_Generic_Instance_Body_Not_Elaborated)
        + Count_Status (Model, Graph_Closure_Generic_Instance_Formal_Body_Unresolved)
        + Count_Status (Model, Graph_Closure_Linked_Generic_Replay_Error);
   end Generic_Error_Count;

   function Cycle_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Graph_Closure_Circular_Library_Elaboration)
        + Count_Status (Model, Graph_Closure_Cycle_Path_Missing_Source);
   end Cycle_Error_Count;

   function Policy_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Graph_Closure_Preelaboration_Illegal_Effect)
        + Count_Status (Model, Graph_Closure_Pure_Illegal_Effect)
        + Count_Status (Model, Graph_Closure_Remote_Types_Illegal_Effect)
        + Count_Status (Model, Graph_Closure_Shared_Passive_Illegal_Effect);
   end Policy_Error_Count;

   function Linked_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Graph_Closure_Flow_Effect_Blocker)
        + Count_Status (Model, Graph_Closure_Accessibility_Scope_Blocker)
        + Count_Status (Model, Graph_Closure_Linked_Base_Elaboration_Error)
        + Count_Status (Model, Graph_Closure_Linked_Precision_Error)
        + Count_Status (Model, Graph_Closure_Linked_Generic_Replay_Error)
        + Count_Status (Model, Graph_Closure_Multiple_Blockers);
   end Linked_Error_Count;

   function Coverage_Gate_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Graph_Closure_Coverage_Gate_Blocker);
   end Coverage_Gate_Error_Count;

   function Indeterminate_Count (Model : Elaboration_Graph_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Graph_Closure_Indeterminate);
   end Indeterminate_Count;

   function Fingerprint (Model : Elaboration_Graph_Closure_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Elaboration_Graph_Closure_Info) return Boolean is
   begin
      return Info.Status /= Graph_Closure_Not_Checked;
   end Has_Legality;

end Editor.Ada_Elaboration_Graph_Closure_Legality;
