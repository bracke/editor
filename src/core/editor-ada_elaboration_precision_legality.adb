with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Elaboration_Precision_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Status;
   use type Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_State;
   use type Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Policy_State;
   use type Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Status;
   use type Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Status;
   use type Editor.Ada_Overload_Preference_Legality.Preference_Legality_Status;
   use type Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 307) + (B * 53) + 1129) mod 1_000_000_007;
   end Mix;

   function Kind_Slot (Kind : Elaboration_Precision_Context_Kind) return Natural is
   begin
      return Elaboration_Precision_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Elaboration_Precision_Status) return Natural is
   begin
      return Elaboration_Precision_Status'Pos (Status) + 1;
   end Status_Slot;

   function Order_Slot (State : Elaboration_Order_State) return Natural is
   begin
      return Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_State'Pos (State) + 1;
   end Order_Slot;

   function Policy_Slot (State : Elaboration_Policy_State) return Natural is
   begin
      return Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Policy_State'Pos (State) + 1;
   end Policy_Slot;

   function Is_Legal_Status (Status : Elaboration_Precision_Status) return Boolean is
   begin
      return Status in
        Elaboration_Precision_Legal_Dependency_Order |
        Elaboration_Precision_Legal_Call_Order |
        Elaboration_Precision_Legal_Access_Order |
        Elaboration_Precision_Legal_Generic_Instance_Order |
        Elaboration_Precision_Legal_Body_Before_Use |
        Elaboration_Precision_Legal_Preelaborated_Unit |
        Elaboration_Precision_Legal_Pure_Unit |
        Elaboration_Precision_Legal_Remote_Types_Unit |
        Elaboration_Precision_Legal_Shared_Passive_Unit;
   end Is_Legal_Status;

   function Graph_Error (Status : Elaboration_Precision_Status) return Boolean is
   begin
      return Status in
        Elaboration_Precision_Circular_Elaboration_Graph |
        Elaboration_Precision_Missing_Graph_Edge |
        Elaboration_Precision_Ambiguous_Graph_Edge |
        Elaboration_Precision_Missing_Elaborate_All |
        Elaboration_Precision_Missing_Elaborate_Body |
        Elaboration_Precision_Body_Elaborated_After_Call |
        Elaboration_Precision_Access_Before_Elaboration;
   end Graph_Error;

   function Policy_Error (Status : Elaboration_Precision_Status) return Boolean is
   begin
      return Status in
        Elaboration_Precision_Preelaborate_Illegal_Call |
        Elaboration_Precision_Preelaborate_Illegal_Object |
        Elaboration_Precision_Pure_Illegal_State |
        Elaboration_Precision_Pure_Illegal_Dependency |
        Elaboration_Precision_Remote_Types_Illegal_Dependency |
        Elaboration_Precision_Shared_Passive_Illegal_Dependency;
   end Policy_Error;

   function Generic_Error (Status : Elaboration_Precision_Status) return Boolean is
   begin
      return Status in
        Elaboration_Precision_Generic_Instance_Body_Not_Elaborated |
        Elaboration_Precision_Generic_Instance_Formal_Body_Unresolved |
        Elaboration_Precision_Linked_Generic_Body_Error;
   end Generic_Error;

   function Dataflow_Error (Status : Elaboration_Precision_Status) return Boolean is
   begin
      return Status in
        Elaboration_Precision_Elaboration_Dataflow_Write |
        Elaboration_Precision_Elaboration_Dataflow_Read_Before_Write |
        Elaboration_Precision_Elaboration_Dataflow_Use_After_Finalization |
        Elaboration_Precision_Linked_Dataflow_Error;
   end Dataflow_Error;

   function Call_Error (Status : Elaboration_Precision_Status) return Boolean is
   begin
      return Status in
        Elaboration_Precision_Body_Elaborated_After_Call |
        Elaboration_Precision_Call_Overload_Unresolved |
        Elaboration_Precision_Linked_Overload_Preference_Error;
   end Call_Error;

   function Accessibility_Error (Status : Elaboration_Precision_Status) return Boolean is
   begin
      return Status in
        Elaboration_Precision_Access_Before_Elaboration |
        Elaboration_Precision_Accessibility_Risk |
        Elaboration_Precision_Linked_Accessibility_Error;
   end Accessibility_Error;

   function Linked_Error (Status : Elaboration_Precision_Status) return Boolean is
   begin
      return Status in
        Elaboration_Precision_Linked_Elaboration_Error |
        Elaboration_Precision_Linked_Generic_Body_Error |
        Elaboration_Precision_Linked_Dataflow_Error |
        Elaboration_Precision_Linked_Overload_Preference_Error |
        Elaboration_Precision_Linked_Accessibility_Error;
   end Linked_Error;

   function Base_Elaboration_Error (Status : Elaboration_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Not_Checked |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Dependency |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Elaborate_Pragma |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Elaborate_All_Pragma |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Elaborate_Body_Pragma |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Preelaborate |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Pure |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Body_Before_Use |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Generic_Instance;
   end Base_Elaboration_Error;

   function Generic_Status_Error (Status : Generic_Body_Expansion_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Not_Checked |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Legal_Substitution |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Legal_Default_Substitution |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Legal_Overload |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Legal_Accessibility |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Legal_Contract |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Legal_Dataflow |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Legal_Initialization |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Legal_Predicate_Invariant |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Legal_Representation;
   end Generic_Status_Error;

   function Dataflow_Status_Error (Status : Dataflow_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Not_Checked |
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Legal_Read |
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Legal_Write |
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Legal_Read_Write |
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Legal_Null_Effect |
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Legal_Depends_Edge |
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Legal_Refinement;
   end Dataflow_Status_Error;

   function Preference_Status_Error (Status : Preference_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Not_Checked |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Exact_Profile |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Direct_Visibility_Preferred |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Use_Visibility_Preferred |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Expected_Type_Profile_Preferred |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Primitive_Operator_Preferred |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Dispatching_Primitive_Preferred |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Universal_Integer_Preferred |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Universal_Real_Preferred |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Implicit_Conversion_Preferred |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Class_Wide_Preferred |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Access_Conversion_Preferred |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Named_Actual_Profile_Preferred |
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Legal_Defaulted_Formal_Profile_Preferred;
   end Preference_Status_Error;

   function Accessibility_Status_Error (Status : Accessibility_Precision_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Not_Checked |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Static_Level |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Dynamic_Check |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Allocator_Master |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Return_Level |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Access_Discriminant |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Generic_Substitution |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Aggregate_Discriminant;
   end Accessibility_Status_Error;

   function Classify (Info : Elaboration_Precision_Context_Info) return Elaboration_Precision_Status is
   begin
      if Base_Elaboration_Error (Info.Base_Elaboration_Status) then
         return Elaboration_Precision_Linked_Elaboration_Error;
      elsif Generic_Status_Error (Info.Generic_Status) then
         return Elaboration_Precision_Linked_Generic_Body_Error;
      elsif Info.Dataflow_Status = Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Read_Before_Write then
         return Elaboration_Precision_Elaboration_Dataflow_Read_Before_Write;
      elsif Info.Dataflow_Status = Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Use_After_Finalization then
         return Elaboration_Precision_Elaboration_Dataflow_Use_After_Finalization;
      elsif Dataflow_Status_Error (Info.Dataflow_Status) then
         return Elaboration_Precision_Linked_Dataflow_Error;
      elsif Preference_Status_Error (Info.Preference_Status) then
         if Info.Call_During_Elaboration then
            return Elaboration_Precision_Call_Overload_Unresolved;
         else
            return Elaboration_Precision_Linked_Overload_Preference_Error;
         end if;
      elsif Accessibility_Status_Error (Info.Accessibility_Status) then
         if Info.Access_During_Elaboration then
            return Elaboration_Precision_Accessibility_Risk;
         else
            return Elaboration_Precision_Linked_Accessibility_Error;
         end if;
      elsif Info.Graph_Cycle or else Info.Order_State = Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_Circular then
         return Elaboration_Precision_Circular_Elaboration_Graph;
      elsif Info.Graph_Edge_Ambiguous or else Info.Order_State = Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_Ambiguous_Dependency then
         return Elaboration_Precision_Ambiguous_Graph_Edge;
      elsif Info.Graph_Edge_Missing or else Info.Order_State = Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_Missing_Dependency then
         return Elaboration_Precision_Missing_Graph_Edge;
      elsif Info.Requires_Elaborate_All and then not Info.Has_Elaborate_All then
         return Elaboration_Precision_Missing_Elaborate_All;
      elsif Info.Requires_Elaborate_Body and then not Info.Has_Elaborate_Body then
         return Elaboration_Precision_Missing_Elaborate_Body;
      elsif Info.Call_During_Elaboration and then not Info.Body_Elaborated then
         return Elaboration_Precision_Body_Elaborated_After_Call;
      elsif Info.Access_During_Elaboration and then Info.Order_State = Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_Known_After then
         return Elaboration_Precision_Access_Before_Elaboration;
      elsif Info.Generic_Instance and then not Info.Generic_Body_Elaborated then
         return Elaboration_Precision_Generic_Instance_Body_Not_Elaborated;
      elsif Info.Generic_Instance and then Info.Order_State = Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_Unknown then
         return Elaboration_Precision_Generic_Instance_Formal_Body_Unresolved;
      elsif Info.Illegal_Preelaborate_Call then
         return Elaboration_Precision_Preelaborate_Illegal_Call;
      elsif Info.Illegal_Preelaborate_Object then
         return Elaboration_Precision_Preelaborate_Illegal_Object;
      elsif Info.Illegal_Pure_State then
         return Elaboration_Precision_Pure_Illegal_State;
      elsif Info.Illegal_Pure_Dependency then
         return Elaboration_Precision_Pure_Illegal_Dependency;
      elsif Info.Illegal_Remote_Types_Dependency then
         return Elaboration_Precision_Remote_Types_Illegal_Dependency;
      elsif Info.Illegal_Shared_Passive_Dependency then
         return Elaboration_Precision_Shared_Passive_Illegal_Dependency;
      elsif Info.Kind = Elaboration_Precision_Context_Generic_Instance then
         return Elaboration_Precision_Legal_Generic_Instance_Order;
      elsif Info.Kind = Elaboration_Precision_Context_Body_Before_Use then
         return Elaboration_Precision_Legal_Body_Before_Use;
      elsif Info.Kind = Elaboration_Precision_Context_Preelaborated_Unit then
         return Elaboration_Precision_Legal_Preelaborated_Unit;
      elsif Info.Kind = Elaboration_Precision_Context_Pure_Unit then
         return Elaboration_Precision_Legal_Pure_Unit;
      elsif Info.Kind = Elaboration_Precision_Context_Remote_Types_Unit then
         return Elaboration_Precision_Legal_Remote_Types_Unit;
      elsif Info.Kind = Elaboration_Precision_Context_Shared_Passive_Unit then
         return Elaboration_Precision_Legal_Shared_Passive_Unit;
      elsif Info.Access_During_Elaboration then
         return Elaboration_Precision_Legal_Access_Order;
      elsif Info.Call_During_Elaboration then
         return Elaboration_Precision_Legal_Call_Order;
      elsif Info.Order_State in
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_Known_Before |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_Same_Unit
      then
         return Elaboration_Precision_Legal_Dependency_Order;
      elsif Info.Order_State = Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_Unknown then
         return Elaboration_Precision_Indeterminate;
      else
         return Elaboration_Precision_Legal_Dependency_Order;
      end if;
   end Classify;

   function Message_For (Status : Elaboration_Precision_Status) return String is
   begin
      case Status is
         when Elaboration_Precision_Legal_Dependency_Order => return "elaboration dependency order is legal";
         when Elaboration_Precision_Legal_Call_Order => return "call during elaboration is covered by elaboration order";
         when Elaboration_Precision_Legal_Access_Order => return "access-before-elaboration risk is covered";
         when Elaboration_Precision_Legal_Generic_Instance_Order => return "generic instance elaboration order is legal";
         when Elaboration_Precision_Legal_Body_Before_Use => return "body is elaborated before use";
         when Elaboration_Precision_Legal_Preelaborated_Unit => return "preelaborated unit policy is satisfied";
         when Elaboration_Precision_Legal_Pure_Unit => return "pure unit policy is satisfied";
         when Elaboration_Precision_Legal_Remote_Types_Unit => return "remote types unit policy is satisfied";
         when Elaboration_Precision_Legal_Shared_Passive_Unit => return "shared passive unit policy is satisfied";
         when Elaboration_Precision_Body_Elaborated_After_Call => return "call may occur before callee body elaboration";
         when Elaboration_Precision_Access_Before_Elaboration => return "access value may designate entity before elaboration";
         when Elaboration_Precision_Generic_Instance_Body_Not_Elaborated => return "generic instance body is not elaborated before use";
         when Elaboration_Precision_Generic_Instance_Formal_Body_Unresolved => return "generic instance formal body elaboration is unresolved";
         when Elaboration_Precision_Missing_Elaborate_All => return "missing Elaborate_All dependency closure";
         when Elaboration_Precision_Missing_Elaborate_Body => return "missing Elaborate_Body/body-before-use closure";
         when Elaboration_Precision_Circular_Elaboration_Graph => return "circular elaboration dependency graph";
         when Elaboration_Precision_Missing_Graph_Edge => return "missing elaboration dependency graph edge";
         when Elaboration_Precision_Ambiguous_Graph_Edge => return "ambiguous elaboration dependency graph edge";
         when Elaboration_Precision_Preelaborate_Illegal_Call => return "preelaborated unit performs illegal call";
         when Elaboration_Precision_Preelaborate_Illegal_Object => return "preelaborated unit declares illegal object";
         when Elaboration_Precision_Pure_Illegal_State => return "pure unit has illegal state";
         when Elaboration_Precision_Pure_Illegal_Dependency => return "pure unit has illegal dependency";
         when Elaboration_Precision_Remote_Types_Illegal_Dependency => return "remote types unit has illegal dependency";
         when Elaboration_Precision_Shared_Passive_Illegal_Dependency => return "shared passive unit has illegal dependency";
         when Elaboration_Precision_Elaboration_Dataflow_Write => return "elaboration dataflow write is illegal";
         when Elaboration_Precision_Elaboration_Dataflow_Read_Before_Write => return "elaboration reads object before initialization";
         when Elaboration_Precision_Elaboration_Dataflow_Use_After_Finalization => return "elaboration uses object after finalization";
         when Elaboration_Precision_Call_Overload_Unresolved => return "call during elaboration has unresolved overload preference";
         when Elaboration_Precision_Accessibility_Risk => return "accessibility risk participates in elaboration order";
         when Elaboration_Precision_Linked_Elaboration_Error => return "linked elaboration/dependence legality blocks precision closure";
         when Elaboration_Precision_Linked_Generic_Body_Error => return "linked generic body semantic expansion blocks elaboration closure";
         when Elaboration_Precision_Linked_Dataflow_Error => return "linked Global/Depends dataflow legality blocks elaboration closure";
         when Elaboration_Precision_Linked_Overload_Preference_Error => return "linked overload preference legality blocks elaboration closure";
         when Elaboration_Precision_Linked_Accessibility_Error => return "linked accessibility precision legality blocks elaboration closure";
         when Elaboration_Precision_Indeterminate => return "elaboration precision legality is indeterminate";
         when others => return "elaboration precision legality was not checked";
      end case;
   end Message_For;

   function Fingerprint_Context (Info : Elaboration_Precision_Context_Info) return Natural is
      FP : Natural := 1129;
   begin
      FP := Mix (FP, Natural (Info.Id));
      FP := Mix (FP, Kind_Slot (Info.Kind));
      FP := Mix (FP, Natural (Info.Node));
      FP := Mix (FP, Natural (Info.Source_Unit_Node));
      FP := Mix (FP, Natural (Info.Target_Unit_Node));
      FP := Mix (FP, Order_Slot (Info.Order_State));
      FP := Mix (FP, Policy_Slot (Info.Policy_State));
      FP := Mix (FP, Info.Source_Fingerprint);
      return FP;
   end Fingerprint_Context;

   function Fingerprint_Row (Info : Elaboration_Precision_Legality_Info) return Natural is
      FP : Natural := 1129;
   begin
      FP := Mix (FP, Natural (Info.Id));
      FP := Mix (FP, Natural (Info.Context));
      FP := Mix (FP, Kind_Slot (Info.Kind));
      FP := Mix (FP, Status_Slot (Info.Status));
      FP := Mix (FP, Natural (Info.Node));
      FP := Mix (FP, Order_Slot (Info.Order_State));
      FP := Mix (FP, Policy_Slot (Info.Policy_State));
      FP := Mix (FP, Info.Source_Fingerprint);
      return FP;
   end Fingerprint_Row;

   procedure Clear (Model : in out Elaboration_Precision_Context_Model) is
   begin
      Model.Rows.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Elaboration_Precision_Context_Model;
      Info  : Elaboration_Precision_Context_Info)
   is
   begin
      Model.Rows.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Fingerprint_Context (Info));
   end Add_Context;

   function Context_Count (Model : Elaboration_Precision_Context_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Context_Count;

   function Context_At
     (Model : Elaboration_Precision_Context_Model;
      Index : Positive) return Elaboration_Precision_Context_Info
   is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Context_At;

   function Fingerprint (Model : Elaboration_Precision_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Elaboration_Precision_Context_Model) return Elaboration_Precision_Legality_Model
   is
      Result : Elaboration_Precision_Legality_Model;
      Next_Id : Natural := 1;
   begin
      for C of Contexts.Rows loop
         declare
            Status : constant Elaboration_Precision_Status := Classify (C);
            Row : Elaboration_Precision_Legality_Info;
         begin
            Row.Id := Elaboration_Precision_Legality_Id (Next_Id);
            Row.Context := C.Id;
            Row.Kind := C.Kind;
            Row.Node := C.Node;
            Row.Source_Unit_Node := C.Source_Unit_Node;
            Row.Target_Unit_Node := C.Target_Unit_Node;
            Row.Status := Status;
            Row.Unit_Name := C.Unit_Name;
            Row.Target_Name := C.Target_Name;
            Row.Message := To_Unbounded_String (Message_For (Status));
            Row.Detail := To_Unbounded_String ("Pass1129 elaboration precision closure");
            Row.Order_State := C.Order_State;
            Row.Policy_State := C.Policy_State;
            Row.Base_Elaboration_Status := C.Base_Elaboration_Status;
            Row.Generic_Status := C.Generic_Status;
            Row.Dataflow_Status := C.Dataflow_Status;
            Row.Preference_Status := C.Preference_Status;
            Row.Accessibility_Status := C.Accessibility_Status;
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

   function Legality_Count (Model : Elaboration_Precision_Legality_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Legality_Count;

   function Legality_At
     (Model : Elaboration_Precision_Legality_Model;
      Index : Positive) return Elaboration_Precision_Legality_Info
   is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Elaboration_Precision_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_Precision_Legality_Info
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
     (Model  : Elaboration_Precision_Legality_Model;
      Status : Elaboration_Precision_Status) return Elaboration_Precision_Result_Set
   is
      Result : Elaboration_Precision_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Elaboration_Precision_Legality_Model;
      Kind  : Elaboration_Precision_Context_Kind) return Elaboration_Precision_Result_Set
   is
      Result : Elaboration_Precision_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Unit
     (Model : Elaboration_Precision_Legality_Model;
      Name  : String) return Elaboration_Precision_Result_Set
   is
      Result : Elaboration_Precision_Result_Set;
   begin
      for Row of Model.Rows loop
         if To_String (Row.Unit_Name) = Name then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Unit;

   function Result_Count (Results : Elaboration_Precision_Result_Set) return Natural is
   begin
      return Natural (Results.Rows.Length);
   end Result_Count;

   function Result_At
     (Results : Elaboration_Precision_Result_Set;
      Index   : Positive) return Elaboration_Precision_Legality_Info
   is
   begin
      if Index > Natural (Results.Rows.Length) then
         return (others => <>);
      end if;
      return Results.Rows.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Elaboration_Precision_Legality_Model;
      Status : Elaboration_Precision_Status) return Natural
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
     (Model : Elaboration_Precision_Legality_Model;
      Kind  : Elaboration_Precision_Context_Kind) return Natural
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

   function Legal_Count (Model : Elaboration_Precision_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal_Status (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Has_Legality (Row) and then not Is_Legal_Status (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Graph_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Graph_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Graph_Error_Count;

   function Policy_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Policy_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Policy_Error_Count;

   function Generic_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Generic_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Generic_Error_Count;

   function Dataflow_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Dataflow_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Dataflow_Error_Count;

   function Call_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Call_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Call_Error_Count;

   function Accessibility_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Accessibility_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Accessibility_Error_Count;

   function Linked_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Linked_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Elaboration_Precision_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Elaboration_Precision_Indeterminate);
   end Indeterminate_Count;

   function Fingerprint (Model : Elaboration_Precision_Legality_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Elaboration_Precision_Legality_Info) return Boolean is
   begin
      return Info.Status /= Elaboration_Precision_Not_Checked;
   end Has_Legality;

end Editor.Ada_Elaboration_Precision_Legality;
