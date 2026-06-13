with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Representation_Layout_Stream_Integration_Legality is
   use type Representation_Status;
   use type Exact_Layout_Status;
   use type Stream_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   Modulus : constant Natural := 2 ** 30 - 35;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 113) mod Modulus;
   end Mix;

   function Kind_Slot (Kind : Representation_Integration_Context_Kind) return Natural is
   begin
      return Representation_Integration_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Representation_Integration_Status) return Natural is
   begin
      return Representation_Integration_Status'Pos (Status) + 1;
   end Status_Slot;

   function Layout_Slot (State : Layout_State) return Natural is
   begin
      return Layout_State'Pos (State) + 1;
   end Layout_Slot;

   function Stream_Slot (State : Stream_State) return Natural is
   begin
      return Stream_State'Pos (State) + 1;
   end Stream_Slot;

   function Representation_Error (Status : Representation_Status) return Boolean is
   begin
      return Status /= Editor.Ada_Representation_Legality.Representation_Legality_Ok;
   end Representation_Error;

   function Static_Error (Status : Staticness_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Not_Checked |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Static_Range_Compatible |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Static_Predicate_Compatible |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Dynamic_Predicate_Required |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Static_Discrete_Choice_Compatible |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Static_Constraint_Compatible |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Linked_Assignment_Compatible |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Linked_Return_Compatible |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Linked_Semantic_Compatible |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Linked_Overload_Compatible;
   end Static_Error;

   function Accessibility_Error (Status : Accessibility_Status) return Boolean is
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

   function Completion_Error (Status : Completion_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Not_Checked |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Unit_Body |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Subprogram_Body |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Task_Body |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Protected_Body |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Generic_Body |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Private_Type_Completion |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Deferred_Constant_Completion |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Incomplete_Type_Completion |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Body_Stub_Completion |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Declaration_Order;
   end Completion_Error;

   function Contract_Error (Status : Contract_Status) return Boolean is
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

   function Exception_Error (Status : Exception_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Not_Checked |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Raise_Statement |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Raise_Expression |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Reraise |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Handler |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Exception_Renaming |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Propagation |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Finalization |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_No_Return;
   end Exception_Error;

   function Generic_Error (Status : Generic_Instance_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Instance |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Body_Substitution |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Default_Substitution |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Formal_Package_Substitution |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Boxed_Formal_Package |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Instance_Freezing |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Representation_Item;
   end Generic_Error;

   function Is_Legal_Status (Status : Representation_Integration_Status) return Boolean is
   begin
      return Status in
        Representation_Integration_Legal_Representation_Item |
        Representation_Integration_Legal_Record_Layout |
        Representation_Integration_Legal_Stream_Attribute |
        Representation_Integration_Legal_Operational_Attribute |
        Representation_Integration_Legal_Convention |
        Representation_Integration_Legal_Generic_Instance_Effect |
        Representation_Integration_Legal_Finalization_Effect;
   end Is_Legal_Status;

   function Is_Layout_Error (Status : Representation_Integration_Status) return Boolean is
   begin
      return Status in
        Representation_Integration_Record_Size_Exceeded |
        Representation_Integration_Record_Alignment_Error |
        Representation_Integration_Record_Component_Error |
        Representation_Integration_Variant_Layout_Hole |
        Representation_Integration_Variant_Layout_Overlap |
        Representation_Integration_Discriminant_Layout_Error;
   end Is_Layout_Error;

   function Is_Stream_Error (Status : Representation_Integration_Status) return Boolean is
   begin
      return Status in
        Representation_Integration_Stream_Handler_Missing |
        Representation_Integration_Stream_Handler_Malformed |
        Representation_Integration_Stream_Handler_Ambiguous |
        Representation_Integration_Stream_Profile_Mismatch |
        Representation_Integration_Stream_Result_Mismatch |
        Representation_Integration_Stream_Mode_Mismatch |
        Representation_Integration_Stream_Profile_Unknown;
   end Is_Stream_Error;

   function Is_Linked_Error (Status : Representation_Integration_Status) return Boolean is
   begin
      return Status in
        Representation_Integration_Generic_Instance_Freezing_Error |
        Representation_Integration_Generic_Instance_Representation_Error |
        Representation_Integration_Accessibility_Error |
        Representation_Integration_Staticness_Error |
        Representation_Integration_Completion_Order_Error |
        Representation_Integration_Contract_Error |
        Representation_Integration_Exception_Finalization_Error;
   end Is_Linked_Error;

   function Classify (C : Representation_Integration_Context_Info)
      return Representation_Integration_Status
   is
   begin
      if C.Private_View_Barrier then
         return Representation_Integration_Private_View_Barrier;
      elsif C.Limited_View_Barrier then
         return Representation_Integration_Limited_View_Barrier;
      elsif C.Cross_Unit_Unresolved then
         return Representation_Integration_Cross_Unit_Unresolved;
      elsif C.Variant_Hole or else C.Layout = Layout_Variant_Hole then
         return Representation_Integration_Variant_Layout_Hole;
      elsif C.Variant_Overlap or else C.Layout = Layout_Variant_Overlap then
         return Representation_Integration_Variant_Layout_Overlap;
      elsif C.Discriminant_Error or else C.Layout = Layout_Discriminant_Error then
         return Representation_Integration_Discriminant_Layout_Error;
      elsif C.Representation = Editor.Ada_Representation_Legality.Representation_Legality_Target_Unresolved then
         return Representation_Integration_Target_Unresolved;
      elsif C.Representation = Editor.Ada_Representation_Legality.Representation_Legality_Target_Ambiguous then
         return Representation_Integration_Target_Ambiguous;
      elsif C.Representation in
        Editor.Ada_Representation_Legality.Representation_Legality_Target_Not_Freezable |
        Editor.Ada_Representation_Legality.Representation_Legality_Target_Kind_Mismatch |
        Editor.Ada_Representation_Legality.Representation_Legality_Size_Target_Incompatible |
        Editor.Ada_Representation_Legality.Representation_Legality_Alignment_Target_Incompatible |
        Editor.Ada_Representation_Legality.Representation_Legality_Storage_Size_Target_Incompatible |
        Editor.Ada_Representation_Legality.Representation_Legality_Stream_Target_Incompatible |
        Editor.Ada_Representation_Legality.Representation_Legality_Operational_Target_Incompatible
      then
         return Representation_Integration_Target_Kind_Mismatch;
      elsif C.Representation in
        Editor.Ada_Representation_Legality.Representation_Legality_After_Freezing |
        Editor.Ada_Representation_Legality.Representation_Legality_At_Freezing_Point
      then
         return Representation_Integration_After_Freezing;
      elsif C.Representation in
        Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Required |
        Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Malformed |
        Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Division_By_Zero |
        Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Not_Positive |
        Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Not_Integer
      then
         return Representation_Integration_Static_Value_Error;
      elsif C.Representation in
        Editor.Ada_Representation_Legality.Representation_Legality_Address_Target_Incompatible |
        Editor.Ada_Representation_Legality.Representation_Legality_Address_Value_Null_Not_Allowed |
        Editor.Ada_Representation_Legality.Representation_Legality_Address_Value_Not_Static_Address |
        Editor.Ada_Representation_Legality.Representation_Legality_Address_Value_Incompatible |
        Editor.Ada_Representation_Legality.Representation_Legality_Address_Value_Malformed
      then
         return Representation_Integration_Address_Error;
      elsif C.Representation in
        Editor.Ada_Representation_Legality.Representation_Legality_Interfacing_Target_Incompatible |
        Editor.Ada_Representation_Legality.Representation_Legality_Convention_Identifier_Required |
        Editor.Ada_Representation_Legality.Representation_Legality_Convention_Identifier_Unknown |
        Editor.Ada_Representation_Legality.Representation_Legality_Import_Export_Boolean_Value_Required |
        Editor.Ada_Representation_Legality.Representation_Legality_Link_Name_String_Value_Required |
        Editor.Ada_Representation_Legality.Representation_Legality_Import_Export_Conflict |
        Editor.Ada_Representation_Legality.Representation_Legality_Link_Name_Requires_Import_Export
      then
         return Representation_Integration_Convention_Error;
      elsif C.Representation in
        Editor.Ada_Representation_Legality.Representation_Legality_Operational_Boolean_Value_Required |
        Editor.Ada_Representation_Legality.Representation_Legality_Operational_Order_Value_Required
      then
         return Representation_Integration_Operational_Error;
      elsif C.Exact_Layout = Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Size_Clause_Exceeded then
         return Representation_Integration_Record_Size_Exceeded;
      elsif C.Exact_Layout = Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Size_Clause_Padded
        or else C.Layout = Layout_Padded
      then
         return Representation_Integration_Record_Padded;
      elsif C.Exact_Layout in
        Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Alignment_Not_Power_Of_Two |
        Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Alignment_Static_Error |
        Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Alignment_Target_Error
      then
         return Representation_Integration_Record_Alignment_Error;
      elsif C.Exact_Layout = Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Component_Error then
         return Representation_Integration_Record_Component_Error;
      elsif C.Stream_Profile = Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Handler_Missing
        or else C.Stream = Stream_Handler_Missing
      then
         return Representation_Integration_Stream_Handler_Missing;
      elsif C.Stream_Profile = Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Handler_Malformed
        or else C.Stream = Stream_Handler_Malformed
      then
         return Representation_Integration_Stream_Handler_Malformed;
      elsif C.Stream_Profile = Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Handler_Ambiguous
        or else C.Stream = Stream_Handler_Ambiguous
      then
         return Representation_Integration_Stream_Handler_Ambiguous;
      elsif C.Stream_Profile in
        Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Arity_Mismatch |
        Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Target_Error
      then
         return Representation_Integration_Stream_Profile_Mismatch;
      elsif C.Stream_Profile = Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Result_Mismatch then
         return Representation_Integration_Stream_Result_Mismatch;
      elsif C.Stream_Profile in
        Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Mode_Requires_Procedure |
        Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Mode_Requires_Function
      then
         return Representation_Integration_Stream_Mode_Mismatch;
      elsif C.Stream_Profile = Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Profile_Unknown
        or else C.Stream = Stream_Profile_Unknown
      then
         return Representation_Integration_Stream_Profile_Unknown;
      elsif Generic_Error (C.Generic_Instance) then
         if C.Generic_Instance in
           Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Instance_Freezes_Target |
           Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Representation_After_Instance_Freezing
         then
            return Representation_Integration_Generic_Instance_Freezing_Error;
         else
            return Representation_Integration_Generic_Instance_Representation_Error;
         end if;
      elsif Accessibility_Error (C.Accessibility) then
         return Representation_Integration_Accessibility_Error;
      elsif Static_Error (C.Staticness) then
         return Representation_Integration_Staticness_Error;
      elsif Completion_Error (C.Completion) then
         return Representation_Integration_Completion_Order_Error;
      elsif Contract_Error (C.Contract) then
         return Representation_Integration_Contract_Error;
      elsif Exception_Error (C.Exception_Finalization) then
         return Representation_Integration_Exception_Finalization_Error;
      elsif C.Kind in Representation_Context_Record_Layout | Representation_Context_Variant_Record_Layout then
         return Representation_Integration_Legal_Record_Layout;
      elsif C.Kind = Representation_Context_Stream_Attribute then
         return Representation_Integration_Legal_Stream_Attribute;
      elsif C.Kind = Representation_Context_Operational_Attribute then
         return Representation_Integration_Legal_Operational_Attribute;
      elsif C.Kind = Representation_Context_Convention_Import_Export then
         return Representation_Integration_Legal_Convention;
      elsif C.Kind = Representation_Context_Generic_Instance_Effect then
         return Representation_Integration_Legal_Generic_Instance_Effect;
      elsif C.Kind = Representation_Context_Controlled_Finalization_Effect then
         return Representation_Integration_Legal_Finalization_Effect;
      elsif C.Kind /= Representation_Context_Unknown then
         return Representation_Integration_Legal_Representation_Item;
      else
         return Representation_Integration_Indeterminate;
      end if;
   end Classify;

   procedure Clear (Model : in out Representation_Integration_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Representation_Integration_Context_Model;
      Info  : Representation_Integration_Context_Info)
   is
      C : Representation_Integration_Context_Info := Info;
   begin
      if C.Id = No_Representation_Integration_Context then
         C.Id := Representation_Integration_Context_Id (Natural (Model.Contexts.Length) + 1);
      end if;
      Model.Contexts.Append (C);
      Model.Fingerprint := Mix
        (Model.Fingerprint,
         Natural (C.Id) + Kind_Slot (C.Kind) + Natural (C.Node) + C.Source_Fingerprint);
   end Add_Context;

   function Context_Count
     (Model : Representation_Integration_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Representation_Integration_Context_Model;
      Index : Positive) return Representation_Integration_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint
     (Model : Representation_Integration_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Representation_Integration_Context_Model)
      return Representation_Integration_Model
   is
      Result : Representation_Integration_Model;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Representation_Integration_Context_Info := Contexts.Contexts.Element (I);
            R : Representation_Integration_Info;
         begin
            R.Id := Representation_Integration_Id (I);
            R.Context := C.Id;
            R.Kind := C.Kind;
            R.Status := Classify (C);
            R.Node := C.Node;
            R.Target_Node := C.Target_Node;
            R.Handler_Node := C.Handler_Node;
            R.Layout_Node := C.Layout_Node;
            R.Target_Name := C.Target_Name;
            R.Normalized_Target := C.Normalized_Target;
            R.Handler_Name := C.Handler_Name;
            R.Layout := C.Layout;
            R.Stream := C.Stream;
            R.Representation := C.Representation;
            R.Exact_Layout := C.Exact_Layout;
            R.Stream_Profile := C.Stream_Profile;
            R.Generic_Instance := C.Generic_Instance;
            R.Accessibility := C.Accessibility;
            R.Staticness := C.Staticness;
            R.Completion := C.Completion;
            R.Contract := C.Contract;
            R.Exception_Finalization := C.Exception_Finalization;
            R.Start_Line := C.Start_Line;
            R.Start_Column := C.Start_Column;
            R.End_Line := C.End_Line;
            R.End_Column := C.End_Column;
            R.Source_Fingerprint := C.Source_Fingerprint;
            R.Message := To_Unbounded_String (Representation_Integration_Status'Image (R.Status));
            R.Detail := To_Unbounded_String (Representation_Integration_Context_Kind'Image (R.Kind));
            R.Fingerprint := Mix
              (C.Source_Fingerprint,
               Natural (R.Id) + Status_Slot (R.Status) + Kind_Slot (R.Kind) +
               Layout_Slot (R.Layout) + Stream_Slot (R.Stream) + Natural (R.Node));
            Result.Rows.Append (R);
            Result.Fingerprint := Mix (Result.Fingerprint, R.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Legality_Count
     (Model : Representation_Integration_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Legality_Count;

   function Legality_At
     (Model : Representation_Integration_Model;
      Index : Positive) return Representation_Integration_Info is
   begin
      return Model.Rows.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Representation_Integration_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Integration_Info is
   begin
      for R of Model.Rows loop
         if R.Node = Node then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Representation_Integration_Model;
      Status : Representation_Integration_Status)
      return Representation_Integration_Result_Set
   is
      Set : Representation_Integration_Result_Set;
   begin
      for R of Model.Rows loop
         if R.Status = Status then
            Set.Results.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Representation_Integration_Model;
      Kind  : Representation_Integration_Context_Kind)
      return Representation_Integration_Result_Set
   is
      Set : Representation_Integration_Result_Set;
   begin
      for R of Model.Rows loop
         if R.Kind = Kind then
            Set.Results.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Rows_For_Target
     (Model  : Representation_Integration_Model;
      Target : Ada.Strings.Unbounded.Unbounded_String)
      return Representation_Integration_Result_Set
   is
      Set : Representation_Integration_Result_Set;
   begin
      for R of Model.Rows loop
         if R.Normalized_Target = Target or else R.Target_Name = Target then
            Set.Results.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Target;

   function Rows_For_Layout
     (Model : Representation_Integration_Model;
      State : Layout_State) return Representation_Integration_Result_Set
   is
      Set : Representation_Integration_Result_Set;
   begin
      for R of Model.Rows loop
         if R.Layout = State then
            Set.Results.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Layout;

   function Rows_For_Stream
     (Model : Representation_Integration_Model;
      State : Stream_State) return Representation_Integration_Result_Set
   is
      Set : Representation_Integration_Result_Set;
   begin
      for R of Model.Rows loop
         if R.Stream = State then
            Set.Results.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Stream;

   function Result_Count
     (Set : Representation_Integration_Result_Set) return Natural is
   begin
      return Natural (Set.Results.Length);
   end Result_Count;

   function Result_At
     (Set   : Representation_Integration_Result_Set;
      Index : Positive) return Representation_Integration_Info is
   begin
      return Set.Results.Element (Index);
   end Result_At;

   function Legal_Count (Model : Representation_Integration_Model) return Natural is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if Is_Legal_Status (R.Status) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Legal_Count;

   function Error_Count (Model : Representation_Integration_Model) return Natural is
   begin
      return Legality_Count (Model) - Legal_Count (Model) - Count_Status (Model, Representation_Integration_Not_Checked);
   end Error_Count;

   function Layout_Error_Count (Model : Representation_Integration_Model) return Natural is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if Is_Layout_Error (R.Status) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Layout_Error_Count;

   function Stream_Error_Count (Model : Representation_Integration_Model) return Natural is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if Is_Stream_Error (R.Status) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Stream_Error_Count;

   function Freezing_Error_Count (Model : Representation_Integration_Model) return Natural is
   begin
      return Count_Status (Model, Representation_Integration_After_Freezing) +
        Count_Status (Model, Representation_Integration_Generic_Instance_Freezing_Error);
   end Freezing_Error_Count;

   function View_Barrier_Count (Model : Representation_Integration_Model) return Natural is
   begin
      return Count_Status (Model, Representation_Integration_Private_View_Barrier) +
        Count_Status (Model, Representation_Integration_Limited_View_Barrier) +
        Count_Status (Model, Representation_Integration_Cross_Unit_Unresolved);
   end View_Barrier_Count;

   function Linked_Error_Count (Model : Representation_Integration_Model) return Natural is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if Is_Linked_Error (R.Status) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Representation_Integration_Model) return Natural is
   begin
      return Count_Status (Model, Representation_Integration_Indeterminate);
   end Indeterminate_Count;

   function Count_Status
     (Model  : Representation_Integration_Model;
      Status : Representation_Integration_Status) return Natural
   is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Status = Status then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Status;

   function Count_Kind
     (Model : Representation_Integration_Model;
      Kind  : Representation_Integration_Context_Kind) return Natural
   is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Kind = Kind then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Kind;

   function Count_Layout
     (Model : Representation_Integration_Model;
      State : Layout_State) return Natural
   is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Layout = State then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Layout;

   function Count_Stream
     (Model : Representation_Integration_Model;
      State : Stream_State) return Natural
   is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Stream = State then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Stream;

   function Fingerprint (Model : Representation_Integration_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Representation_Layout_Stream_Integration_Legality;
