with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Contract_Aspect_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;

   Modulus : constant Natural := 2 ** 30 - 35;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 97) mod Modulus;
   end Mix;

   function Kind_Slot (Kind : Contract_Context_Kind) return Natural is
   begin
      return Contract_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Subject_Slot (Subject : Contract_Subject_Kind) return Natural is
   begin
      return Contract_Subject_Kind'Pos (Subject) + 1;
   end Subject_Slot;

   function Placement_Slot (Placement : Aspect_Placement) return Natural is
   begin
      return Aspect_Placement'Pos (Placement) + 1;
   end Placement_Slot;

   function Bool_Slot (State : Boolean_Expression_State) return Natural is
   begin
      return Boolean_Expression_State'Pos (State) + 1;
   end Bool_Slot;

   function Flow_Slot (State : Flow_Contract_State) return Natural is
   begin
      return Flow_Contract_State'Pos (State) + 1;
   end Flow_Slot;

   function Status_Slot (Status : Contract_Legality_Status) return Natural is
   begin
      return Contract_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Is_Legal_Status (Status : Contract_Legality_Status) return Boolean is
   begin
      return Status in
        Contract_Legality_Legal_Precondition |
        Contract_Legality_Legal_Postcondition |
        Contract_Legality_Legal_Invariant |
        Contract_Legality_Legal_Predicate |
        Contract_Legality_Legal_Assertion |
        Contract_Legality_Legal_Contract_Case |
        Contract_Legality_Legal_Flow_Aspect;
   end Is_Legal_Status;

   function Is_Boolean_Error (Status : Contract_Legality_Status) return Boolean is
   begin
      return Status in
        Contract_Legality_Non_Boolean_Condition |
        Contract_Legality_Unresolved_Condition |
        Contract_Legality_Contract_Case_Result_Non_Boolean;
   end Is_Boolean_Error;

   function Is_Static_Error (Status : Contract_Legality_Status) return Boolean is
   begin
      return Status in
        Contract_Legality_Static_Predicate_Non_Static |
        Contract_Legality_Static_Predicate_Failed |
        Contract_Legality_Predicate_Range_Error |
        Contract_Legality_Linked_Staticness_Error;
   end Is_Static_Error;

   function Is_Flow_Error (Status : Contract_Legality_Status) return Boolean is
   begin
      return Status in
        Contract_Legality_Flow_Duplicate_Item |
        Contract_Legality_Flow_Unknown_Global |
        Contract_Legality_Flow_Unknown_Dependency |
        Contract_Legality_Flow_Mode_Mismatch |
        Contract_Legality_Flow_Missing_Refinement |
        Contract_Legality_Flow_Illegal_Refinement;
   end Is_Flow_Error;

   function Is_View_Barrier (Status : Contract_Legality_Status) return Boolean is
   begin
      return Status in
        Contract_Legality_Private_View_Barrier |
        Contract_Legality_Limited_View_Barrier |
        Contract_Legality_Cross_Unit_Unresolved;
   end Is_View_Barrier;

   function Is_Linked_Error (Status : Contract_Legality_Status) return Boolean is
   begin
      return Status in
        Contract_Legality_Linked_Assignment_Error |
        Contract_Legality_Linked_Return_Error |
        Contract_Legality_Linked_Accessibility_Error |
        Contract_Legality_Linked_Overload_Error |
        Contract_Legality_Linked_Cross_Unit_Error;
   end Is_Linked_Error;

   function Assignment_Error (Status : Assignment_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Compatible |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Class_Wide_Compatible |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Static_Range_Compatible;
   end Assignment_Error;

   function Return_Error (Status : Return_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked |
        Editor.Ada_Return_Legality.Return_Legality_Procedure_Return_Compatible |
        Editor.Ada_Return_Legality.Return_Legality_Function_Return_Compatible |
        Editor.Ada_Return_Legality.Return_Legality_Extended_Return_Compatible;
   end Return_Error;

   function Static_Error (Status : Static_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Not_Checked |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Static_Range_Compatible |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Static_Discrete_Choice_Compatible |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Static_Constraint_Compatible |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Dynamic_Predicate_Required;
   end Static_Error;

   function Accessibility_Error (Status : Accessibility_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Static_Compatible |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Dynamic_Check_Required |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Null_Exclusion_Checked |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Aliased_Object_Compatible |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Allocator_Compatible |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Access_Conversion_Compatible |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Return_Access_Compatible;
   end Accessibility_Error;

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

   function Cross_Unit_Error (Status : Cross_Unit_Semantic_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Not_Checked |
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Closed |
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Local_Only |
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_With_Visible |
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Use_Visible;
   end Cross_Unit_Error;

   function Context_Fingerprint (Info : Contract_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Subject_Slot (Info.Subject));
      H := Mix (H, Placement_Slot (Info.Placement));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Subject_Node) + 1);
      H := Mix (H, Natural (Info.Expression_Node) + 1);
      H := Mix (H, Bool_Slot (Info.Boolean_State));
      H := Mix (H, Flow_Slot (Info.Flow_State));
      H := Mix (H, Natural (Boolean'Pos (Info.Requires_Static)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Static_Expression)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Predicate_Known_False)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Range_Error)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Duplicate_Aspect)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Illegal_Placement)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Private_View_Barrier)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Limited_View_Barrier)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Cross_Unit_Unresolved)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Contract_Case_Overlap)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Contract_Case_Incomplete)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Contract_Case_Result_Boolean)) + 1);
      H := Mix (H, Editor.Ada_Assignment_Legality.Assignment_Legality_Status'Pos (Info.Assignment_Status) + 1);
      H := Mix (H, Editor.Ada_Return_Legality.Return_Legality_Status'Pos (Info.Return_Status) + 1);
      H := Mix (H, Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Status'Pos (Info.Static_Status) + 1);
      H := Mix (H, Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Status'Pos (Info.Accessibility_Status) + 1);
      H := Mix (H, Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status'Pos (Info.Overload_Status) + 1);
      H := Mix (H, Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Status'Pos (Info.Cross_Unit_Status) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.Start_Column);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.End_Column);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : Contract_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Subject_Slot (Info.Subject));
      H := Mix (H, Placement_Slot (Info.Placement));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Subject_Node) + 1);
      H := Mix (H, Natural (Info.Expression_Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Bool_Slot (Info.Boolean_State));
      H := Mix (H, Flow_Slot (Info.Flow_State));
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Contract_Legality_Status) return String is
   begin
      case Status is
         when Contract_Legality_Legal_Precondition => return "legal precondition";
         when Contract_Legality_Legal_Postcondition => return "legal postcondition";
         when Contract_Legality_Legal_Invariant => return "legal invariant";
         when Contract_Legality_Legal_Predicate => return "legal predicate";
         when Contract_Legality_Legal_Assertion => return "legal assertion";
         when Contract_Legality_Legal_Contract_Case => return "legal contract case";
         when Contract_Legality_Legal_Flow_Aspect => return "legal flow aspect";
         when Contract_Legality_Non_Boolean_Condition => return "contract expression is not Boolean";
         when Contract_Legality_Unresolved_Condition => return "contract expression type is unresolved";
         when Contract_Legality_Static_Predicate_Non_Static => return "static predicate is not static";
         when Contract_Legality_Static_Predicate_Failed => return "static predicate is known false";
         when Contract_Legality_Predicate_Range_Error => return "predicate expression violates static range";
         when Contract_Legality_Invariant_Subject_Illegal => return "invariant subject is illegal";
         when Contract_Legality_Postcondition_Subject_Illegal => return "postcondition subject is illegal";
         when Contract_Legality_Precondition_Subject_Illegal => return "precondition subject is illegal";
         when Contract_Legality_Contract_Case_Choice_Overlap => return "contract case choices overlap";
         when Contract_Legality_Contract_Case_Choice_Incomplete => return "contract case choices are incomplete";
         when Contract_Legality_Contract_Case_Result_Non_Boolean => return "contract case result is not Boolean";
         when Contract_Legality_Aspect_Placement_Error => return "contract aspect placement is illegal";
         when Contract_Legality_Duplicate_Aspect => return "duplicate contract aspect";
         when Contract_Legality_Private_View_Barrier => return "private view blocks contract legality";
         when Contract_Legality_Limited_View_Barrier => return "limited view blocks contract legality";
         when Contract_Legality_Cross_Unit_Unresolved => return "cross-unit contract dependency unresolved";
         when Contract_Legality_Flow_Duplicate_Item => return "duplicate flow aspect item";
         when Contract_Legality_Flow_Unknown_Global => return "unknown global aspect item";
         when Contract_Legality_Flow_Unknown_Dependency => return "unknown dependency aspect item";
         when Contract_Legality_Flow_Mode_Mismatch => return "flow aspect mode mismatch";
         when Contract_Legality_Flow_Missing_Refinement => return "missing flow aspect refinement";
         when Contract_Legality_Flow_Illegal_Refinement => return "illegal flow aspect refinement";
         when Contract_Legality_Linked_Assignment_Error => return "linked assignment legality error";
         when Contract_Legality_Linked_Return_Error => return "linked return legality error";
         when Contract_Legality_Linked_Staticness_Error => return "linked staticness legality error";
         when Contract_Legality_Linked_Accessibility_Error => return "linked accessibility legality error";
         when Contract_Legality_Linked_Overload_Error => return "linked overload legality error";
         when Contract_Legality_Linked_Cross_Unit_Error => return "linked cross-unit legality error";
         when Contract_Legality_Indeterminate => return "contract legality is indeterminate";
         when Contract_Legality_Not_Checked => return "contract legality not checked";
      end case;
   end Message_For;

   function Determine_Status (Info : Contract_Context_Info) return Contract_Legality_Status is
   begin
      if Info.Duplicate_Aspect then
         return Contract_Legality_Duplicate_Aspect;
      elsif Info.Illegal_Placement then
         return Contract_Legality_Aspect_Placement_Error;
      elsif Info.Private_View_Barrier then
         return Contract_Legality_Private_View_Barrier;
      elsif Info.Limited_View_Barrier then
         return Contract_Legality_Limited_View_Barrier;
      elsif Info.Cross_Unit_Unresolved then
         return Contract_Legality_Cross_Unit_Unresolved;
      elsif Cross_Unit_Error (Info.Cross_Unit_Status) then
         return Contract_Legality_Linked_Cross_Unit_Error;
      elsif Assignment_Error (Info.Assignment_Status) then
         return Contract_Legality_Linked_Assignment_Error;
      elsif Return_Error (Info.Return_Status) then
         return Contract_Legality_Linked_Return_Error;
      elsif Static_Error (Info.Static_Status) then
         return Contract_Legality_Linked_Staticness_Error;
      elsif Accessibility_Error (Info.Accessibility_Status) then
         return Contract_Legality_Linked_Accessibility_Error;
      elsif Overload_Error (Info.Overload_Status) then
         return Contract_Legality_Linked_Overload_Error;
      elsif Info.Boolean_State = Boolean_Expression_Non_Boolean then
         return Contract_Legality_Non_Boolean_Condition;
      elsif Info.Boolean_State = Boolean_Expression_Unresolved then
         return Contract_Legality_Unresolved_Condition;
      elsif Info.Requires_Static and then not Info.Static_Expression then
         return Contract_Legality_Static_Predicate_Non_Static;
      elsif Info.Predicate_Known_False then
         return Contract_Legality_Static_Predicate_Failed;
      elsif Info.Range_Error then
         return Contract_Legality_Predicate_Range_Error;
      elsif Info.Contract_Case_Overlap then
         return Contract_Legality_Contract_Case_Choice_Overlap;
      elsif Info.Contract_Case_Incomplete then
         return Contract_Legality_Contract_Case_Choice_Incomplete;
      elsif not Info.Contract_Case_Result_Boolean then
         return Contract_Legality_Contract_Case_Result_Non_Boolean;
      end if;

      case Info.Flow_State is
         when Flow_Contract_Duplicate_Item =>
            return Contract_Legality_Flow_Duplicate_Item;
         when Flow_Contract_Unknown_Global =>
            return Contract_Legality_Flow_Unknown_Global;
         when Flow_Contract_Unknown_Dependency =>
            return Contract_Legality_Flow_Unknown_Dependency;
         when Flow_Contract_Mode_Mismatch =>
            return Contract_Legality_Flow_Mode_Mismatch;
         when Flow_Contract_Missing_Refinement =>
            return Contract_Legality_Flow_Missing_Refinement;
         when Flow_Contract_Illegal_Refinement =>
            return Contract_Legality_Flow_Illegal_Refinement;
         when Flow_Contract_Unresolved =>
            return Contract_Legality_Indeterminate;
         when others =>
            null;
      end case;

      case Info.Kind is
         when Contract_Context_Precondition =>
            if Info.Subject not in Contract_Subject_Subprogram |
              Contract_Subject_Task | Contract_Subject_Protected |
              Contract_Subject_Generic
            then
               return Contract_Legality_Precondition_Subject_Illegal;
            end if;
            return Contract_Legality_Legal_Precondition;
         when Contract_Context_Postcondition =>
            if Info.Subject not in Contract_Subject_Subprogram |
              Contract_Subject_Task | Contract_Subject_Protected |
              Contract_Subject_Generic
            then
               return Contract_Legality_Postcondition_Subject_Illegal;
            end if;
            return Contract_Legality_Legal_Postcondition;
         when Contract_Context_Type_Invariant |
              Contract_Context_Default_Initial_Condition |
              Contract_Context_Initial_Condition =>
            if Info.Subject not in Contract_Subject_Type |
              Contract_Subject_Package | Contract_Subject_Task |
              Contract_Subject_Protected
            then
               return Contract_Legality_Invariant_Subject_Illegal;
            end if;
            return Contract_Legality_Legal_Invariant;
         when Contract_Context_Static_Predicate |
              Contract_Context_Dynamic_Predicate =>
            return Contract_Legality_Legal_Predicate;
         when Contract_Context_Assertion =>
            return Contract_Legality_Legal_Assertion;
         when Contract_Context_Contract_Case =>
            return Contract_Legality_Legal_Contract_Case;
         when Contract_Context_Global_Aspect |
              Contract_Context_Depends_Aspect |
              Contract_Context_Refined_Global |
              Contract_Context_Refined_Depends =>
            return Contract_Legality_Legal_Flow_Aspect;
         when others =>
            return Contract_Legality_Indeterminate;
      end case;
   end Determine_Status;

   procedure Clear (Model : in out Contract_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Contract_Context_Model;
      Info  : Contract_Context_Info)
   is
      Normalized : Contract_Context_Info := Info;
   begin
      if Normalized.Id = No_Contract_Context then
         Normalized.Id := Contract_Context_Id (Natural (Model.Contexts.Length) + 1);
      end if;
      Model.Contexts.Append (Normalized);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint,
                                       Context_Fingerprint (Normalized));
   end Add_Context;

   function Context_Count (Model : Contract_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Contract_Context_Model;
      Index : Positive) return Contract_Context_Info
   is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Contract_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Contract_Context_Model) return Contract_Legality_Model is
      Model : Contract_Legality_Model;
   begin
      for Index in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Contract_Context_Info := Contexts.Contexts.Element (Index);
            Status : constant Contract_Legality_Status := Determine_Status (C);
            Row : Contract_Legality_Info;
         begin
            Row.Id := Contract_Legality_Id (Index);
            Row.Context := C.Id;
            Row.Kind := C.Kind;
            Row.Subject := C.Subject;
            Row.Placement := C.Placement;
            Row.Node := C.Node;
            Row.Subject_Node := C.Subject_Node;
            Row.Expression_Node := C.Expression_Node;
            Row.Status := Status;
            Row.Message := To_Unbounded_String (Message_For (Status));
            Row.Detail := To_Unbounded_String ("contract/aspect legality row");
            Row.Boolean_State := C.Boolean_State;
            Row.Flow_State := C.Flow_State;
            Row.Assignment_Status := C.Assignment_Status;
            Row.Return_Status := C.Return_Status;
            Row.Static_Status := C.Static_Status;
            Row.Accessibility_Status := C.Accessibility_Status;
            Row.Overload_Status := C.Overload_Status;
            Row.Cross_Unit_Status := C.Cross_Unit_Status;
            Row.Start_Line := C.Start_Line;
            Row.Start_Column := C.Start_Column;
            Row.End_Line := C.End_Line;
            Row.End_Column := C.End_Column;
            Row.Source_Fingerprint := C.Source_Fingerprint;
            Row.Fingerprint := Row_Fingerprint (Row);
            Model.Items.Append (Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);

            if Is_Legal_Status (Status) then
               Model.Legal_Total := Model.Legal_Total + 1;
            else
               Model.Error_Total := Model.Error_Total + 1;
            end if;

            if Is_Boolean_Error (Status) then
               Model.Boolean_Error_Total := Model.Boolean_Error_Total + 1;
            end if;
            if Is_Static_Error (Status) then
               Model.Static_Error_Total := Model.Static_Error_Total + 1;
            end if;
            if Is_Flow_Error (Status) then
               Model.Flow_Error_Total := Model.Flow_Error_Total + 1;
            end if;
            if Is_View_Barrier (Status) then
               Model.View_Barrier_Total := Model.View_Barrier_Total + 1;
            end if;
            if Is_Linked_Error (Status) then
               Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
            end if;
            if Status = Contract_Legality_Indeterminate then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Model;
   end Build;

   function Legality_Count (Model : Contract_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Contract_Legality_Model;
      Index : Positive) return Contract_Legality_Info
   is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Contract_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Contract_Legality_Info
   is
   begin
      for Row of Model.Items loop
         if Row.Node = Node or else Row.Subject_Node = Node or else Row.Expression_Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Contract_Legality_Model;
      Status : Contract_Legality_Status) return Contract_Result_Set
   is
      Results : Contract_Result_Set;
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
     (Model : Contract_Legality_Model;
      Kind  : Contract_Context_Kind) return Contract_Result_Set
   is
      Results : Contract_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Subject
     (Model   : Contract_Legality_Model;
      Subject : Contract_Subject_Kind) return Contract_Result_Set
   is
      Results : Contract_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Subject = Subject then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Subject;

   function Rows_For_Placement
     (Model     : Contract_Legality_Model;
      Placement : Aspect_Placement) return Contract_Result_Set
   is
      Results : Contract_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Placement = Placement then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Placement;

   function Rows_For_Flow_State
     (Model : Contract_Legality_Model;
      State : Flow_Contract_State) return Contract_Result_Set
   is
      Results : Contract_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Flow_State = State then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Flow_State;

   function Result_Count (Results : Contract_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Contract_Result_Set;
      Index   : Positive) return Contract_Legality_Info
   is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Contract_Legality_Model;
      Status : Contract_Legality_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Contract_Legality_Model;
      Kind  : Contract_Context_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Count_Subject
     (Model   : Contract_Legality_Model;
      Subject : Contract_Subject_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Subject = Subject then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Subject;

   function Count_Placement
     (Model     : Contract_Legality_Model;
      Placement : Aspect_Placement) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Placement = Placement then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Placement;

   function Count_Flow_State
     (Model : Contract_Legality_Model;
      State : Flow_Contract_State) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Flow_State = State then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Flow_State;

   function Legal_Count (Model : Contract_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Contract_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Boolean_Error_Count (Model : Contract_Legality_Model) return Natural is
   begin
      return Model.Boolean_Error_Total;
   end Boolean_Error_Count;

   function Static_Error_Count (Model : Contract_Legality_Model) return Natural is
   begin
      return Model.Static_Error_Total;
   end Static_Error_Count;

   function Flow_Error_Count (Model : Contract_Legality_Model) return Natural is
   begin
      return Model.Flow_Error_Total;
   end Flow_Error_Count;

   function View_Barrier_Count (Model : Contract_Legality_Model) return Natural is
   begin
      return Model.View_Barrier_Total;
   end View_Barrier_Count;

   function Linked_Error_Count (Model : Contract_Legality_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Contract_Legality_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Contract_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Contract_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Contract_Legality and then
        Info.Status /= Contract_Legality_Not_Checked;
   end Has_Legality;

end Editor.Ada_Contract_Aspect_Legality;
