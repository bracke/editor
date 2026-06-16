with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Renaming_Alias_Visibility_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;

   Modulus : constant Natural := 2 ** 30 - 35;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 113) mod Modulus;
   end Mix;

   function Kind_Slot (Kind : Renaming_Context_Kind) return Natural is
   begin
      return Renaming_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Entity_Slot (Kind : Renamed_Entity_Kind) return Natural is
   begin
      return Renamed_Entity_Kind'Pos (Kind) + 1;
   end Entity_Slot;

   function Visibility_Slot (Visibility : Visibility_State) return Natural is
   begin
      return Visibility_State'Pos (Visibility) + 1;
   end Visibility_Slot;

   function Alias_Slot (Alias : Alias_State) return Natural is
   begin
      return Alias_State'Pos (Alias) + 1;
   end Alias_Slot;

   function Use_Slot (State : Use_Clause_State) return Natural is
   begin
      return Use_Clause_State'Pos (State) + 1;
   end Use_Slot;

   function Status_Slot (Status : Renaming_Legality_Status) return Natural is
   begin
      return Renaming_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

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

   function Completion_Error (Status : Completion_Legality_Status) return Boolean is
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

   function Is_Legal_Status (Status : Renaming_Legality_Status) return Boolean is
   begin
      return Status in
        Renaming_Legality_Legal_Object_Renaming |
        Renaming_Legality_Legal_Exception_Renaming |
        Renaming_Legality_Legal_Package_Renaming |
        Renaming_Legality_Legal_Subprogram_Renaming |
        Renaming_Legality_Legal_Generic_Renaming |
        Renaming_Legality_Legal_Use_Package |
        Renaming_Legality_Legal_Use_Type |
        Renaming_Legality_Legal_Selected_Alias;
   end Is_Legal_Status;

   function Is_Visibility_Error (Status : Renaming_Legality_Status) return Boolean is
   begin
      return Status in
        Renaming_Legality_Missing_Target |
        Renaming_Legality_Ambiguous_Target |
        Renaming_Legality_Visibility_Overflow |
        Renaming_Legality_Hidden_By_Homograph;
   end Is_Visibility_Error;

   function Is_Alias_Error (Status : Renaming_Legality_Status) return Boolean is
   begin
      return Status in
        Renaming_Legality_Self_Renaming |
        Renaming_Legality_Circular_Renaming |
        Renaming_Legality_Target_Not_Aliased |
        Renaming_Legality_Dangling_Rename_Risk |
        Renaming_Legality_Renames_Constant_As_Variable;
   end Is_Alias_Error;

   function Is_Use_Clause_Error (Status : Renaming_Legality_Status) return Boolean is
   begin
      return Status in
        Renaming_Legality_Use_Package_Target_Not_Package |
        Renaming_Legality_Use_Type_Target_Not_Type |
        Renaming_Legality_Duplicate_Use_Clause;
   end Is_Use_Clause_Error;

   function Is_Profile_Error (Status : Renaming_Legality_Status) return Boolean is
   begin
      return Status in
        Renaming_Legality_Subprogram_Profile_Mismatch |
        Renaming_Legality_Generic_Profile_Mismatch |
        Renaming_Legality_Object_Subtype_Mismatch |
        Renaming_Legality_Target_Kind_Mismatch;
   end Is_Profile_Error;

   function Is_View_Barrier (Status : Renaming_Legality_Status) return Boolean is
   begin
      return Status in
        Renaming_Legality_Private_View_Barrier |
        Renaming_Legality_Limited_View_Barrier;
   end Is_View_Barrier;

   function Is_Linked_Error (Status : Renaming_Legality_Status) return Boolean is
   begin
      return Status in
        Renaming_Legality_Linked_Accessibility_Error |
        Renaming_Legality_Linked_Overload_Error |
        Renaming_Legality_Linked_Cross_Unit_Error |
        Renaming_Legality_Linked_Completion_Order_Error;
   end Is_Linked_Error;

   function Classify (Info : Renaming_Context_Info) return Renaming_Legality_Status is
   begin
      if Accessibility_Error (Info.Accessibility_Status) then
         return Renaming_Legality_Linked_Accessibility_Error;
      elsif Overload_Error (Info.Overload_Status) then
         return Renaming_Legality_Linked_Overload_Error;
      elsif Cross_Unit_Error (Info.Cross_Unit_Status) then
         return Renaming_Legality_Linked_Cross_Unit_Error;
      elsif Completion_Error (Info.Completion_Status) then
         return Renaming_Legality_Linked_Completion_Order_Error;
      elsif Info.Visibility = Visibility_Limited_View
        or else Info.Use_State = Use_Clause_Limited_View_Barrier
      then
         return Renaming_Legality_Limited_View_Barrier;
      elsif Info.Visibility = Visibility_Private_View
        or else Info.Use_State = Use_Clause_Private_View_Barrier
      then
         return Renaming_Legality_Private_View_Barrier;
      elsif not Info.Target_Present
        or else Info.Visibility = Visibility_Missing
        or else Info.Use_State = Use_Clause_Missing_Target
      then
         return Renaming_Legality_Missing_Target;
      elsif Info.Target_Ambiguous
        or else Info.Visibility = Visibility_Ambiguous
        or else Info.Use_State = Use_Clause_Ambiguous_Target
      then
         return Renaming_Legality_Ambiguous_Target;
      elsif Info.Visibility = Visibility_Overflow
        or else Info.Use_State = Use_Clause_Overflow
      then
         return Renaming_Legality_Visibility_Overflow;
      elsif Info.Visibility = Visibility_Hidden_By_Homograph then
         return Renaming_Legality_Hidden_By_Homograph;
      elsif Info.Alias = Alias_Self_Rename then
         return Renaming_Legality_Self_Renaming;
      elsif Info.Alias = Alias_Circular_Rename then
         return Renaming_Legality_Circular_Renaming;
      elsif Info.Alias = Alias_Dangling_Risk then
         return Renaming_Legality_Dangling_Rename_Risk;
      elsif Info.Requires_Aliased_Target and then not Info.Target_Is_Aliased then
         return Renaming_Legality_Target_Not_Aliased;
      elsif Info.Alias = Alias_Target_Not_Aliased then
         return Renaming_Legality_Target_Not_Aliased;
      elsif Info.Renames_Constant_As_Variable then
         return Renaming_Legality_Renames_Constant_As_Variable;
      elsif Info.Target_Kind_Mismatch then
         return Renaming_Legality_Target_Kind_Mismatch;
      elsif Info.Profile_Mismatch then
         return Renaming_Legality_Subprogram_Profile_Mismatch;
      elsif Info.Generic_Profile_Mismatch then
         return Renaming_Legality_Generic_Profile_Mismatch;
      elsif Info.Object_Subtype_Mismatch then
         return Renaming_Legality_Object_Subtype_Mismatch;
      elsif Info.Use_State = Use_Clause_Duplicate then
         return Renaming_Legality_Duplicate_Use_Clause;
      elsif Info.Use_State = Use_Clause_Non_Package_Target then
         return Renaming_Legality_Use_Package_Target_Not_Package;
      elsif Info.Use_State = Use_Clause_Non_Type_Target then
         return Renaming_Legality_Use_Type_Target_Not_Type;
      end if;

      case Info.Kind is
         when Renaming_Context_Object | Renaming_Context_Formal_Object =>
            return Renaming_Legality_Legal_Object_Renaming;
         when Renaming_Context_Exception =>
            return Renaming_Legality_Legal_Exception_Renaming;
         when Renaming_Context_Package =>
            return Renaming_Legality_Legal_Package_Renaming;
         when Renaming_Context_Subprogram =>
            return Renaming_Legality_Legal_Subprogram_Renaming;
         when Renaming_Context_Generic_Package | Renaming_Context_Generic_Subprogram =>
            return Renaming_Legality_Legal_Generic_Renaming;
         when Renaming_Context_Use_Package =>
            return Renaming_Legality_Legal_Use_Package;
         when Renaming_Context_Use_Type =>
            return Renaming_Legality_Legal_Use_Type;
         when Renaming_Context_Selected_Name | Renaming_Context_Alias_View =>
            return Renaming_Legality_Legal_Selected_Alias;
         when Renaming_Context_Unknown =>
            return Renaming_Legality_Indeterminate;
      end case;
   end Classify;

   function Message_For (Status : Renaming_Legality_Status) return String is
   begin
      case Status is
         when Renaming_Legality_Legal_Object_Renaming => return "object renaming is legal";
         when Renaming_Legality_Legal_Exception_Renaming => return "exception renaming is legal";
         when Renaming_Legality_Legal_Package_Renaming => return "package renaming is legal";
         when Renaming_Legality_Legal_Subprogram_Renaming => return "subprogram renaming is legal";
         when Renaming_Legality_Legal_Generic_Renaming => return "generic renaming is legal";
         when Renaming_Legality_Legal_Use_Package => return "use package visibility is legal";
         when Renaming_Legality_Legal_Use_Type => return "use type visibility is legal";
         when Renaming_Legality_Legal_Selected_Alias => return "selected alias view is legal";
         when Renaming_Legality_Missing_Target => return "renaming or use target is missing";
         when Renaming_Legality_Ambiguous_Target => return "renaming or use target is ambiguous";
         when Renaming_Legality_Visibility_Overflow => return "visibility lookup overflowed its bounded result";
         when Renaming_Legality_Target_Kind_Mismatch => return "renamed entity kind does not match declaration";
         when Renaming_Legality_Subprogram_Profile_Mismatch => return "renamed subprogram profile does not conform";
         when Renaming_Legality_Generic_Profile_Mismatch => return "renamed generic profile does not conform";
         when Renaming_Legality_Object_Subtype_Mismatch => return "renamed object subtype is incompatible";
         when Renaming_Legality_Renames_Constant_As_Variable => return "constant is renamed as a variable view";
         when Renaming_Legality_Self_Renaming => return "renaming names itself";
         when Renaming_Legality_Circular_Renaming => return "renaming cycle detected";
         when Renaming_Legality_Target_Not_Aliased => return "renamed target is not aliased where required";
         when Renaming_Legality_Dangling_Rename_Risk => return "renaming may create a dangling view";
         when Renaming_Legality_Hidden_By_Homograph => return "renaming target is hidden by a homograph";
         when Renaming_Legality_Use_Package_Target_Not_Package => return "use clause target is not a package";
         when Renaming_Legality_Use_Type_Target_Not_Type => return "use type target is not a type";
         when Renaming_Legality_Duplicate_Use_Clause => return "duplicate use clause";
         when Renaming_Legality_Private_View_Barrier => return "private view blocks renaming visibility";
         when Renaming_Legality_Limited_View_Barrier => return "limited view blocks renaming visibility";
         when Renaming_Legality_Linked_Accessibility_Error => return "accessibility legality blocks renaming";
         when Renaming_Legality_Linked_Overload_Error => return "overload legality blocks renaming";
         when Renaming_Legality_Linked_Cross_Unit_Error => return "cross-unit semantic closure blocks renaming";
         when Renaming_Legality_Linked_Completion_Order_Error => return "completion/order legality blocks renaming";
         when Renaming_Legality_Indeterminate => return "renaming legality is indeterminate";
         when Renaming_Legality_Not_Checked => return "renaming legality was not checked";
      end case;
   end Message_For;

   function Detail_For (Info : Renaming_Context_Info; Status : Renaming_Legality_Status) return String is
      pragma Unreferenced (Info);
   begin
      return "renaming/alias/visibility status " & Renaming_Legality_Status'Image (Status);
   end Detail_For;

   function Row_Fingerprint (Row : Renaming_Legality_Info) return Natural is
      Value : Natural := Status_Slot (Row.Status);
   begin
      Value := Mix (Value, Natural (Row.Context));
      Value := Mix (Value, Kind_Slot (Row.Kind));
      Value := Mix (Value, Entity_Slot (Row.Renamed_Kind));
      Value := Mix (Value, Visibility_Slot (Row.Visibility));
      Value := Mix (Value, Alias_Slot (Row.Alias));
      Value := Mix (Value, Use_Slot (Row.Use_State));
      Value := Mix (Value, Natural (Row.Node));
      Value := Mix (Value, Natural (Row.Declaration_Node));
      Value := Mix (Value, Natural (Row.Target_Node));
      Value := Mix (Value, Natural (Row.Prefix_Node));
      Value := Mix (Value, Natural (Row.Selector_Node));
      Value := Mix (Value, Row.Start_Line);
      Value := Mix (Value, Row.Start_Column);
      Value := Mix (Value, Row.End_Line);
      Value := Mix (Value, Row.End_Column);
      Value := Mix (Value, Row.Source_Fingerprint);
      return Value;
   end Row_Fingerprint;

   procedure Clear (Model : in out Renaming_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Renaming_Context_Model;
      Info  : Renaming_Context_Info)
   is
      Value : Natural := Model.Fingerprint;
   begin
      Model.Contexts.Append (Info);
      Value := Mix (Value, Natural (Info.Id));
      Value := Mix (Value, Kind_Slot (Info.Kind));
      Value := Mix (Value, Entity_Slot (Info.Renamed_Kind));
      Value := Mix (Value, Visibility_Slot (Info.Visibility));
      Value := Mix (Value, Alias_Slot (Info.Alias));
      Value := Mix (Value, Use_Slot (Info.Use_State));
      Value := Mix (Value, Natural (Info.Node));
      Value := Mix (Value, Info.Source_Fingerprint);
      Model.Fingerprint := Value;
   end Add_Context;

   function Context_Count (Model : Renaming_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Renaming_Context_Model;
      Index : Positive) return Renaming_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Renaming_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Renaming_Context_Model) return Renaming_Legality_Model is
      Result : Renaming_Legality_Model;
      Next   : Natural := 1;
   begin
      for Info of Contexts.Contexts loop
         declare
            Status : constant Renaming_Legality_Status := Classify (Info);
            Row    : Renaming_Legality_Info;
         begin
            Row.Id := Renaming_Legality_Id (Next);
            Row.Context := Info.Id;
            Row.Kind := Info.Kind;
            Row.Renamed_Kind := Info.Renamed_Kind;
            Row.Visibility := Info.Visibility;
            Row.Alias := Info.Alias;
            Row.Use_State := Info.Use_State;
            Row.Node := Info.Node;
            Row.Declaration_Node := Info.Declaration_Node;
            Row.Target_Node := Info.Target_Node;
            Row.Prefix_Node := Info.Prefix_Node;
            Row.Selector_Node := Info.Selector_Node;
            Row.Name := Info.Name;
            Row.Normalized_Name := Info.Normalized_Name;
            Row.Target_Name := Info.Target_Name;
            Row.Status := Status;
            Row.Message := To_Unbounded_String (Message_For (Status));
            Row.Detail := To_Unbounded_String (Detail_For (Info, Status));
            Row.Accessibility_Status := Info.Accessibility_Status;
            Row.Overload_Status := Info.Overload_Status;
            Row.Cross_Unit_Status := Info.Cross_Unit_Status;
            Row.Completion_Status := Info.Completion_Status;
            Row.Start_Line := Info.Start_Line;
            Row.Start_Column := Info.Start_Column;
            Row.End_Line := Info.End_Line;
            Row.End_Column := Info.End_Column;
            Row.Source_Fingerprint := Info.Source_Fingerprint;
            Row.Fingerprint := Row_Fingerprint (Row);
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
            Next := Next + 1;
         end;
      end loop;
      return Result;
   end Build;

   function Legality_Count (Model : Renaming_Legality_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Legality_Count;

   function Legality_At
     (Model : Renaming_Legality_Model;
      Index : Positive) return Renaming_Legality_Info is
   begin
      return Model.Rows.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Renaming_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Renaming_Legality_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node
           or else Row.Declaration_Node = Node
           or else Row.Target_Node = Node
           or else Row.Prefix_Node = Node
           or else Row.Selector_Node = Node
         then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Renaming_Legality_Model;
      Status : Renaming_Legality_Status) return Renaming_Result_Set is
      Result : Renaming_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Renaming_Legality_Model;
      Kind  : Renaming_Context_Kind) return Renaming_Result_Set is
      Result : Renaming_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Renamed_Kind
     (Model : Renaming_Legality_Model;
      Kind  : Renamed_Entity_Kind) return Renaming_Result_Set is
      Result : Renaming_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Renamed_Kind = Kind then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Renamed_Kind;

   function Rows_For_Visibility
     (Model      : Renaming_Legality_Model;
      Visibility : Visibility_State) return Renaming_Result_Set is
      Result : Renaming_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Visibility = Visibility then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Visibility;

   function Rows_For_Alias
     (Model : Renaming_Legality_Model;
      Alias : Alias_State) return Renaming_Result_Set is
      Result : Renaming_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Alias = Alias then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Alias;

   function Rows_For_Use_State
     (Model : Renaming_Legality_Model;
      State : Use_Clause_State) return Renaming_Result_Set is
      Result : Renaming_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Use_State = State then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Use_State;

   function Rows_For_Name
     (Model : Renaming_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Renaming_Result_Set is
      Result : Renaming_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Normalized_Name = Name or else Row.Name = Name then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Name;

   function Result_Count (Set : Renaming_Result_Set) return Natural is
   begin
      return Natural (Set.Results.Length);
   end Result_Count;

   function Result_At
     (Set   : Renaming_Result_Set;
      Index : Positive) return Renaming_Legality_Info is
   begin
      return Set.Results.Element (Index);
   end Result_At;

   function Legal_Count (Model : Renaming_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal_Status (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Renaming_Legality_Model) return Natural is
   begin
      return Legality_Count (Model) - Legal_Count (Model);
   end Error_Count;

   function Visibility_Error_Count (Model : Renaming_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Visibility_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Visibility_Error_Count;

   function Alias_Error_Count (Model : Renaming_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Alias_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Alias_Error_Count;

   function Use_Clause_Error_Count (Model : Renaming_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Use_Clause_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Use_Clause_Error_Count;

   function Profile_Error_Count (Model : Renaming_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Profile_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Profile_Error_Count;

   function View_Barrier_Count (Model : Renaming_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_View_Barrier (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end View_Barrier_Count;

   function Linked_Error_Count (Model : Renaming_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Linked_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Renaming_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Renaming_Legality_Indeterminate);
   end Indeterminate_Count;

   function Count_Status
     (Model  : Renaming_Legality_Model;
      Status : Renaming_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Renaming_Legality_Model;
      Kind  : Renaming_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Kind;

   function Count_Renamed_Kind
     (Model : Renaming_Legality_Model;
      Kind  : Renamed_Entity_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Renamed_Kind = Kind then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Renamed_Kind;

   function Count_Visibility
     (Model      : Renaming_Legality_Model;
      Visibility : Visibility_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Visibility = Visibility then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Visibility;

   function Count_Alias
     (Model : Renaming_Legality_Model;
      Alias : Alias_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Alias = Alias then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Alias;

   function Count_Use_State
     (Model : Renaming_Legality_Model;
      State : Use_Clause_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Use_State = State then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Use_State;

   function Fingerprint (Model : Renaming_Legality_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Renaming_Alias_Visibility_Legality;
