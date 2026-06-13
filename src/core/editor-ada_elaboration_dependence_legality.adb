with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Elaboration_Dependence_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;

   Modulus : constant Natural := 2 ** 30 - 35;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 113) mod Modulus;
   end Mix;

   function Kind_Slot (Kind : Elaboration_Context_Kind) return Natural is
   begin
      return Elaboration_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Dependence_Slot (Dependence : Elaboration_Dependence_Kind) return Natural is
   begin
      return Elaboration_Dependence_Kind'Pos (Dependence) + 1;
   end Dependence_Slot;

   function Pragma_Slot (State : Elaboration_Pragma_State) return Natural is
   begin
      return Elaboration_Pragma_State'Pos (State) + 1;
   end Pragma_Slot;

   function Order_Slot (State : Elaboration_Order_State) return Natural is
   begin
      return Elaboration_Order_State'Pos (State) + 1;
   end Order_Slot;

   function Policy_Slot (State : Elaboration_Policy_State) return Natural is
   begin
      return Elaboration_Policy_State'Pos (State) + 1;
   end Policy_Slot;

   function Status_Slot (Status : Elaboration_Legality_Status) return Natural is
   begin
      return Elaboration_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Is_Legal_Status (Status : Elaboration_Legality_Status) return Boolean is
   begin
      return Status in
        Elaboration_Legality_Legal_Dependency |
        Elaboration_Legality_Legal_Elaborate_Pragma |
        Elaboration_Legality_Legal_Elaborate_All_Pragma |
        Elaboration_Legality_Legal_Elaborate_Body_Pragma |
        Elaboration_Legality_Legal_Preelaborate |
        Elaboration_Legality_Legal_Pure |
        Elaboration_Legality_Legal_Body_Before_Use |
        Elaboration_Legality_Legal_Generic_Instance;
   end Is_Legal_Status;

   function Is_Pragma_Error (Status : Elaboration_Legality_Status) return Boolean is
   begin
      return Status in
        Elaboration_Legality_Duplicate_Pragma |
        Elaboration_Legality_Conflicting_Pragma |
        Elaboration_Legality_Pragma_Target_Unresolved |
        Elaboration_Legality_Pragma_Target_Ambiguous |
        Elaboration_Legality_Missing_Elaborate_All |
        Elaboration_Legality_Missing_Elaborate_Body;
   end Is_Pragma_Error;

   function Is_Order_Error (Status : Elaboration_Legality_Status) return Boolean is
   begin
      return Status in
        Elaboration_Legality_Call_Before_Body_Elaboration |
        Elaboration_Legality_Access_Before_Elaboration |
        Elaboration_Legality_Circular_Elaboration_Dependence |
        Elaboration_Legality_Missing_Dependency |
        Elaboration_Legality_Ambiguous_Dependency;
   end Is_Order_Error;

   function Is_Policy_Error (Status : Elaboration_Legality_Status) return Boolean is
   begin
      return Status in
        Elaboration_Legality_Preelaborate_Illegal_Construct |
        Elaboration_Legality_Pure_Illegal_State |
        Elaboration_Legality_Remote_Types_Illegal_Dependency |
        Elaboration_Legality_Shared_Passive_Illegal_Dependency;
   end Is_Policy_Error;

   function Is_Body_Error (Status : Elaboration_Legality_Status) return Boolean is
   begin
      return Status in
        Elaboration_Legality_Body_Required_But_Missing |
        Elaboration_Legality_Generic_Instance_Body_Not_Elaborated |
        Elaboration_Legality_Call_Before_Body_Elaboration |
        Elaboration_Legality_Missing_Elaborate_Body;
   end Is_Body_Error;

   function Is_Linked_Error (Status : Elaboration_Legality_Status) return Boolean is
   begin
      return Status in
        Elaboration_Legality_Linked_Cross_Unit_Error |
        Elaboration_Legality_Linked_Contract_Error |
        Elaboration_Legality_Linked_Overload_Error;
   end Is_Linked_Error;

   function Cross_Unit_Error (Status : Cross_Unit_Semantic_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Not_Checked |
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Closed |
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Local_Only |
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_With_Visible |
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Use_Visible;
   end Cross_Unit_Error;

   function Contract_Error (Status : Contract_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Precondition |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Postcondition |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Invariant |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Predicate |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Assertion |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Contract_Case |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Flow_Aspect;
   end Contract_Error;

   function Overload_Error (Status : Overload_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked |
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Legal_Exact |
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Legal_Expected_Type_Preferred |
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Legal_Universal_Integer_Preferred |
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Legal_Universal_Real_Preferred |
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Legal_Primitive_Operator_Preferred |
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Legal_Implicit_Numeric_Conversion |
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Legal_Class_Wide_Conversion |
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Legal_Access_Conversion |
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Legal_Named_Actual_Profile |
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Legal_Defaulted_Formal_Profile;
   end Overload_Error;

   function Classify (Info : Elaboration_Context_Info) return Elaboration_Legality_Status is
   begin
      if Cross_Unit_Error (Info.Cross_Unit_Status) then
         return Elaboration_Legality_Linked_Cross_Unit_Error;
      elsif Contract_Error (Info.Contract_Status) then
         return Elaboration_Legality_Linked_Contract_Error;
      elsif Overload_Error (Info.Overload_Status) then
         return Elaboration_Legality_Linked_Overload_Error;
      elsif Info.Duplicate_Pragma or else Info.Pragma_State = Elaboration_Pragma_Duplicate then
         return Elaboration_Legality_Duplicate_Pragma;
      elsif Info.Conflicting_Pragma or else Info.Pragma_State = Elaboration_Pragma_Conflicting then
         return Elaboration_Legality_Conflicting_Pragma;
      elsif Info.Pragma_State = Elaboration_Pragma_Unresolved then
         return Elaboration_Legality_Pragma_Target_Unresolved;
      elsif Info.Order_State = Elaboration_Order_Ambiguous_Dependency then
         return Elaboration_Legality_Ambiguous_Dependency;
      elsif Info.Order_State = Elaboration_Order_Missing_Dependency then
         return Elaboration_Legality_Missing_Dependency;
      elsif Info.Order_State = Elaboration_Order_Circular then
         return Elaboration_Legality_Circular_Elaboration_Dependence;
      elsif Info.Call_During_Elaboration
        and then Info.Order_State = Elaboration_Order_Known_After
      then
         return Elaboration_Legality_Call_Before_Body_Elaboration;
      elsif Info.Access_During_Elaboration
        and then Info.Order_State = Elaboration_Order_Known_After
      then
         return Elaboration_Legality_Access_Before_Elaboration;
      elsif Info.Requires_Elaborate_All and then not Info.Has_Elaborate_All then
         return Elaboration_Legality_Missing_Elaborate_All;
      elsif Info.Requires_Body and then not Info.Body_Available then
         return Elaboration_Legality_Body_Required_But_Missing;
      elsif Info.Illegal_Preelaborate_Construct
        or else (Info.Policy_State = Elaboration_Policy_Preelaborated
                 and then Info.Call_During_Elaboration)
      then
         return Elaboration_Legality_Preelaborate_Illegal_Construct;
      elsif Info.Illegal_Pure_State then
         return Elaboration_Legality_Pure_Illegal_State;
      elsif Info.Illegal_Remote_Types_Dependency then
         return Elaboration_Legality_Remote_Types_Illegal_Dependency;
      elsif Info.Illegal_Shared_Passive_Dependency then
         return Elaboration_Legality_Shared_Passive_Illegal_Dependency;
      end if;

      case Info.Kind is
         when Elaboration_Context_Elaborate_Pragma =>
            return Elaboration_Legality_Legal_Elaborate_Pragma;
         when Elaboration_Context_Elaborate_All_Pragma =>
            return Elaboration_Legality_Legal_Elaborate_All_Pragma;
         when Elaboration_Context_Elaborate_Body_Pragma =>
            return Elaboration_Legality_Legal_Elaborate_Body_Pragma;
         when Elaboration_Context_Preelaborate_Unit =>
            return Elaboration_Legality_Legal_Preelaborate;
         when Elaboration_Context_Pure_Unit =>
            return Elaboration_Legality_Legal_Pure;
         when Elaboration_Context_Body_Before_Use =>
            return Elaboration_Legality_Legal_Body_Before_Use;
         when Elaboration_Context_Generic_Instance =>
            if Info.Requires_Body and then not Info.Body_Available then
               return Elaboration_Legality_Generic_Instance_Body_Not_Elaborated;
            else
               return Elaboration_Legality_Legal_Generic_Instance;
            end if;
         when others =>
            if Info.Order_State = Elaboration_Order_Unknown
              and then Info.Kind = Elaboration_Context_Unknown
            then
               return Elaboration_Legality_Indeterminate;
            else
               return Elaboration_Legality_Legal_Dependency;
            end if;
      end case;
   end Classify;

   function Message_For (Status : Elaboration_Legality_Status) return String is
   begin
      case Status is
         when Elaboration_Legality_Legal_Dependency =>
            return "elaboration dependency is legal";
         when Elaboration_Legality_Legal_Elaborate_Pragma =>
            return "Elaborate pragma is legal";
         when Elaboration_Legality_Legal_Elaborate_All_Pragma =>
            return "Elaborate_All pragma is legal";
         when Elaboration_Legality_Legal_Elaborate_Body_Pragma =>
            return "Elaborate_Body pragma is legal";
         when Elaboration_Legality_Legal_Preelaborate =>
            return "preelaborated unit policy is legal";
         when Elaboration_Legality_Legal_Pure =>
            return "pure unit policy is legal";
         when Elaboration_Legality_Legal_Body_Before_Use =>
            return "body-before-use requirement is satisfied";
         when Elaboration_Legality_Legal_Generic_Instance =>
            return "generic instance elaboration is legal";
         when Elaboration_Legality_Call_Before_Body_Elaboration =>
            return "call may occur before body elaboration";
         when Elaboration_Legality_Access_Before_Elaboration =>
            return "access may occur before elaboration";
         when Elaboration_Legality_Missing_Elaborate_All =>
            return "Elaborate_All requirement is missing";
         when Elaboration_Legality_Missing_Elaborate_Body =>
            return "Elaborate_Body requirement is missing";
         when Elaboration_Legality_Duplicate_Pragma =>
            return "duplicate elaboration pragma";
         when Elaboration_Legality_Conflicting_Pragma =>
            return "conflicting elaboration pragmas";
         when Elaboration_Legality_Pragma_Target_Unresolved =>
            return "elaboration pragma target is unresolved";
         when Elaboration_Legality_Pragma_Target_Ambiguous =>
            return "elaboration pragma target is ambiguous";
         when Elaboration_Legality_Circular_Elaboration_Dependence =>
            return "circular elaboration dependency";
         when Elaboration_Legality_Missing_Dependency =>
            return "elaboration dependency is missing";
         when Elaboration_Legality_Ambiguous_Dependency =>
            return "elaboration dependency is ambiguous";
         when Elaboration_Legality_Preelaborate_Illegal_Construct =>
            return "illegal construct in preelaborated unit";
         when Elaboration_Legality_Pure_Illegal_State =>
            return "illegal state in pure unit";
         when Elaboration_Legality_Remote_Types_Illegal_Dependency =>
            return "illegal remote-types dependency";
         when Elaboration_Legality_Shared_Passive_Illegal_Dependency =>
            return "illegal shared-passive dependency";
         when Elaboration_Legality_Body_Required_But_Missing =>
            return "required body is missing before use";
         when Elaboration_Legality_Generic_Instance_Body_Not_Elaborated =>
            return "generic instance body may not be elaborated before use";
         when Elaboration_Legality_Linked_Cross_Unit_Error =>
            return "linked cross-unit semantic closure error blocks elaboration legality";
         when Elaboration_Legality_Linked_Contract_Error =>
            return "linked contract/aspect legality error blocks elaboration legality";
         when Elaboration_Legality_Linked_Overload_Error =>
            return "linked overload legality error blocks elaboration legality";
         when Elaboration_Legality_Indeterminate =>
            return "elaboration legality is indeterminate";
         when Elaboration_Legality_Not_Checked =>
            return "elaboration legality not checked";
      end case;
   end Message_For;

   function Fingerprint_For (Info : Elaboration_Legality_Info) return Natural is
      F : Natural := 29;
   begin
      F := Mix (F, Natural (Info.Id));
      F := Mix (F, Natural (Info.Context));
      F := Mix (F, Kind_Slot (Info.Kind));
      F := Mix (F, Dependence_Slot (Info.Dependence));
      F := Mix (F, Pragma_Slot (Info.Pragma_State));
      F := Mix (F, Order_Slot (Info.Order_State));
      F := Mix (F, Policy_Slot (Info.Policy_State));
      F := Mix (F, Natural (Info.Node));
      F := Mix (F, Natural (Info.Source_Unit_Node));
      F := Mix (F, Natural (Info.Target_Unit_Node));
      F := Mix (F, Status_Slot (Info.Status));
      F := Mix (F, Info.Start_Line);
      F := Mix (F, Info.Start_Column);
      F := Mix (F, Info.End_Line);
      F := Mix (F, Info.End_Column);
      F := Mix (F, Info.Source_Fingerprint);
      return F;
   end Fingerprint_For;

   function Context_Fingerprint (Info : Elaboration_Context_Info) return Natural is
      F : Natural := 31;
   begin
      F := Mix (F, Natural (Info.Id));
      F := Mix (F, Kind_Slot (Info.Kind));
      F := Mix (F, Dependence_Slot (Info.Dependence));
      F := Mix (F, Pragma_Slot (Info.Pragma_State));
      F := Mix (F, Order_Slot (Info.Order_State));
      F := Mix (F, Policy_Slot (Info.Policy_State));
      F := Mix (F, Natural (Info.Node));
      F := Mix (F, Natural (Info.Source_Unit_Node));
      F := Mix (F, Natural (Info.Target_Unit_Node));
      F := Mix (F, Info.Source_Fingerprint);
      if Info.Requires_Elaborate_All then F := Mix (F, 3); end if;
      if Info.Has_Elaborate_All then F := Mix (F, 5); end if;
      if Info.Requires_Body then F := Mix (F, 7); end if;
      if Info.Body_Available then F := Mix (F, 11); end if;
      return F;
   end Context_Fingerprint;

   procedure Append_Row
     (Model : in out Elaboration_Legality_Model;
      Row   : Elaboration_Legality_Info)
   is
      Stored : Elaboration_Legality_Info := Row;
   begin
      Stored.Fingerprint := Fingerprint_For (Stored);
      Model.Items.Append (Stored);
      if Is_Legal_Status (Stored.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      elsif Stored.Status /= Elaboration_Legality_Not_Checked then
         Model.Error_Total := Model.Error_Total + 1;
      end if;
      if Is_Pragma_Error (Stored.Status) then
         Model.Pragma_Error_Total := Model.Pragma_Error_Total + 1;
      end if;
      if Is_Order_Error (Stored.Status) then
         Model.Order_Error_Total := Model.Order_Error_Total + 1;
      end if;
      if Is_Policy_Error (Stored.Status) then
         Model.Policy_Error_Total := Model.Policy_Error_Total + 1;
      end if;
      if Is_Body_Error (Stored.Status) then
         Model.Body_Error_Total := Model.Body_Error_Total + 1;
      end if;
      if Is_Linked_Error (Stored.Status) then
         Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
      end if;
      if Stored.Status = Elaboration_Legality_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Stored.Fingerprint);
   end Append_Row;

   procedure Clear (Model : in out Elaboration_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Elaboration_Context_Model;
      Info  : Elaboration_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Context_Fingerprint (Info));
   end Add_Context;

   function Context_Count (Model : Elaboration_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Elaboration_Context_Model;
      Index : Positive) return Elaboration_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Elaboration_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Elaboration_Context_Model) return Elaboration_Legality_Model is
      Model : Elaboration_Legality_Model;
   begin
      for Index in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Elaboration_Context_Info := Contexts.Contexts.Element (Index);
            Status : constant Elaboration_Legality_Status := Classify (C);
            Row : Elaboration_Legality_Info;
         begin
            Row.Id := Elaboration_Legality_Id (Index);
            Row.Context := C.Id;
            Row.Kind := C.Kind;
            Row.Dependence := C.Dependence;
            Row.Pragma_State := C.Pragma_State;
            Row.Order_State := C.Order_State;
            Row.Policy_State := C.Policy_State;
            Row.Node := C.Node;
            Row.Source_Unit_Node := C.Source_Unit_Node;
            Row.Target_Unit_Node := C.Target_Unit_Node;
            Row.Status := Status;
            Row.Message := To_Unbounded_String (Message_For (Status));
            Row.Detail := To_Unbounded_String ("Pass1113 elaboration/dependence legality classification");
            Row.Cross_Unit_Status := C.Cross_Unit_Status;
            Row.Contract_Status := C.Contract_Status;
            Row.Overload_Status := C.Overload_Status;
            Row.Start_Line := C.Start_Line;
            Row.Start_Column := C.Start_Column;
            Row.End_Line := C.End_Line;
            Row.End_Column := C.End_Column;
            Row.Source_Fingerprint := C.Source_Fingerprint;
            Append_Row (Model, Row);
         end;
      end loop;
      return Model;
   end Build;

   function Legality_Count (Model : Elaboration_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Elaboration_Legality_Model;
      Index : Positive) return Elaboration_Legality_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Elaboration_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_Legality_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Elaboration_Legality_Model;
      Status : Elaboration_Legality_Status) return Elaboration_Result_Set is
      Results : Elaboration_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Elaboration_Legality_Model;
      Kind  : Elaboration_Context_Kind) return Elaboration_Result_Set is
      Results : Elaboration_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Dependence
     (Model      : Elaboration_Legality_Model;
      Dependence : Elaboration_Dependence_Kind) return Elaboration_Result_Set is
      Results : Elaboration_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Dependence = Dependence then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Dependence;

   function Rows_For_Pragma_State
     (Model : Elaboration_Legality_Model;
      State : Elaboration_Pragma_State) return Elaboration_Result_Set is
      Results : Elaboration_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Pragma_State = State then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Pragma_State;

   function Rows_For_Order_State
     (Model : Elaboration_Legality_Model;
      State : Elaboration_Order_State) return Elaboration_Result_Set is
      Results : Elaboration_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Order_State = State then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Order_State;

   function Rows_For_Policy_State
     (Model : Elaboration_Legality_Model;
      State : Elaboration_Policy_State) return Elaboration_Result_Set is
      Results : Elaboration_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Policy_State = State then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Policy_State;

   function Result_Count (Results : Elaboration_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Elaboration_Result_Set;
      Index   : Positive) return Elaboration_Legality_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Elaboration_Legality_Model;
      Status : Elaboration_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Elaboration_Legality_Model;
      Kind  : Elaboration_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Kind;

   function Count_Dependence
     (Model      : Elaboration_Legality_Model;
      Dependence : Elaboration_Dependence_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Dependence = Dependence then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Dependence;

   function Count_Pragma_State
     (Model : Elaboration_Legality_Model;
      State : Elaboration_Pragma_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Pragma_State = State then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Pragma_State;

   function Count_Order_State
     (Model : Elaboration_Legality_Model;
      State : Elaboration_Order_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Order_State = State then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Order_State;

   function Count_Policy_State
     (Model : Elaboration_Legality_Model;
      State : Elaboration_Policy_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Policy_State = State then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Policy_State;

   function Legal_Count (Model : Elaboration_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Elaboration_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Pragma_Error_Count (Model : Elaboration_Legality_Model) return Natural is
   begin
      return Model.Pragma_Error_Total;
   end Pragma_Error_Count;

   function Order_Error_Count (Model : Elaboration_Legality_Model) return Natural is
   begin
      return Model.Order_Error_Total;
   end Order_Error_Count;

   function Policy_Error_Count (Model : Elaboration_Legality_Model) return Natural is
   begin
      return Model.Policy_Error_Total;
   end Policy_Error_Count;

   function Body_Error_Count (Model : Elaboration_Legality_Model) return Natural is
   begin
      return Model.Body_Error_Total;
   end Body_Error_Count;

   function Linked_Error_Count (Model : Elaboration_Legality_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Elaboration_Legality_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Elaboration_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Elaboration_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Elaboration_Legality
        and then Info.Status /= Elaboration_Legality_Not_Checked;
   end Has_Legality;

end Editor.Ada_Elaboration_Dependence_Legality;
