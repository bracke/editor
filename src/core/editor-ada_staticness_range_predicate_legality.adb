with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Staticness_Range_Predicate_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Assignment_Legality.Assignment_Legality_Id;
   use type Editor.Ada_Assignment_Legality.Assignment_Legality_Status;
   use type Editor.Ada_Return_Legality.Return_Legality_Id;
   use type Editor.Ada_Return_Legality.Return_Legality_Status;
   use type Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Id;
   use type Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status;
   use type Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 269) + (B * 37) + 1110) mod 1_000_000_007;
   end Mix;

   function Kind_Slot (Kind : Static_Context_Kind) return Natural is
   begin
      return Static_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Static_Legality_Status) return Natural is
   begin
      return Static_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Predicate_Slot (Predicate : Predicate_Policy) return Natural is
   begin
      return Predicate_Policy'Pos (Predicate) + 1;
   end Predicate_Slot;

   function Is_Legal (Status : Static_Legality_Status) return Boolean is
   begin
      return Status in
        Static_Legality_Static_Range_Compatible |
        Static_Legality_Static_Predicate_Compatible |
        Static_Legality_Dynamic_Predicate_Required |
        Static_Legality_Static_Discrete_Choice_Compatible |
        Static_Legality_Static_Constraint_Compatible |
        Static_Legality_Linked_Assignment_Compatible |
        Static_Legality_Linked_Return_Compatible |
        Static_Legality_Linked_Semantic_Compatible |
        Static_Legality_Linked_Overload_Compatible;
   end Is_Legal;

   function Is_Static_Error (Status : Static_Legality_Status) return Boolean is
   begin
      return Status in
        Static_Legality_Requires_Static_Expression |
        Static_Legality_Non_Static_Expression |
        Static_Legality_Unresolved_Static_Name |
        Static_Legality_Malformed_Static_Expression |
        Static_Legality_Static_Division_By_Zero |
        Static_Legality_Static_Cycle |
        Static_Legality_Unsupported_Static_Attribute;
   end Is_Static_Error;

   function Is_Range_Error (Status : Static_Legality_Status) return Boolean is
   begin
      return Status in
        Static_Legality_Range_Violation |
        Static_Legality_Null_Range |
        Static_Legality_Choice_Out_Of_Range |
        Static_Legality_Duplicate_Static_Choice |
        Static_Legality_Choice_Coverage_Gap;
   end Is_Range_Error;

   function Is_Predicate_Error (Status : Static_Legality_Status) return Boolean is
   begin
      return Status in
        Static_Legality_Predicate_Static_Failure |
        Static_Legality_Predicate_Unresolved |
        Static_Legality_Predicate_Non_Static_Where_Static_Required;
   end Is_Predicate_Error;

   function Is_Linked_Error (Status : Static_Legality_Status) return Boolean is
   begin
      return Status in
        Static_Legality_Linked_Assignment_Error |
        Static_Legality_Linked_Return_Error |
        Static_Legality_Linked_Semantic_Error |
        Static_Legality_Linked_Overload_Error;
   end Is_Linked_Error;

   function Assignment_Legal (Status : Assignment_Legality_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Assignment_Legality.Assignment_Legality_Compatible |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Class_Wide_Compatible |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Static_Range_Compatible;
   end Assignment_Legal;

   function Return_Legal (Status : Return_Legality_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Return_Legality.Return_Legality_Procedure_Return_Compatible |
        Editor.Ada_Return_Legality.Return_Legality_Function_Return_Compatible |
        Editor.Ada_Return_Legality.Return_Legality_Extended_Return_Compatible;
   end Return_Legal;

   function Semantic_Legal (Status : Semantic_Legality_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Legal_Conversion |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Legal_Qualified_Expression |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Legal_Access_Conversion |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Legal_Access_Parameter |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Legal_Allocator |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Legal_Aggregate |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Legal_Container_Aggregate |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Numeric_Conversion |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Tagged_Conversion |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Class_Wide_Conversion |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Static_Range_Compatible;
   end Semantic_Legal;

   function Overload_Legal (Status : Overload_Legality_Status) return Boolean is
   begin
      return Status in
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
   end Overload_Legal;

   function Context_Fingerprint (Info : Static_Legality_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Expression_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Length (Info.Subtype_Name) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Requires_Static)) + 1);
      H := Mix (H, Editor.Ada_Static_Expressions.Static_Value_Status'Pos (Info.Static_Status) + 1);
      H := Mix (H, Natural (abs Info.Static_Integer_Value mod 997) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Has_Static_Range)) + 1);
      H := Mix (H, Natural (abs Info.Static_First mod 997) + 1);
      H := Mix (H, Natural (abs Info.Static_Last mod 997) + 1);
      H := Mix (H, Info.Choice_Count + 1);
      H := Mix (H, Info.Duplicate_Choice_Count + 1);
      H := Mix (H, Info.Coverage_Gap_Count + 1);
      H := Mix (H, Predicate_Slot (Info.Predicate));
      H := Mix (H, Natural (Boolean'Pos (Info.Is_Universal_Numeric)) + 1);
      H := Mix (H, Natural (Info.Assignment) + 1);
      H := Mix (H, Editor.Ada_Assignment_Legality.Assignment_Legality_Status'Pos (Info.Assignment_Status) + 1);
      H := Mix (H, Natural (Info.Return_Item) + 1);
      H := Mix (H, Editor.Ada_Return_Legality.Return_Legality_Status'Pos (Info.Return_Status) + 1);
      H := Mix (H, Natural (Info.Semantic_Item) + 1);
      H := Mix (H, Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status'Pos (Info.Semantic_Status) + 1);
      H := Mix (H, Natural (Info.Overload_Item) + 1);
      H := Mix (H, Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status'Pos (Info.Overload_Status) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : Static_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Editor.Ada_Static_Expressions.Static_Value_Status'Pos (Info.Static_Status) + 1);
      H := Mix (H, Natural (abs Info.Static_Integer_Value mod 997) + 1);
      H := Mix (H, Natural (abs Info.Static_First mod 997) + 1);
      H := Mix (H, Natural (abs Info.Static_Last mod 997) + 1);
      H := Mix (H, Predicate_Slot (Info.Predicate));
      H := Mix (H, Editor.Ada_Assignment_Legality.Assignment_Legality_Status'Pos (Info.Assignment_Status) + 1);
      H := Mix (H, Editor.Ada_Return_Legality.Return_Legality_Status'Pos (Info.Return_Status) + 1);
      H := Mix (H, Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status'Pos (Info.Semantic_Status) + 1);
      H := Mix (H, Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status'Pos (Info.Overload_Status) + 1);
      H := Mix (H, Info.Choice_Count + 1);
      H := Mix (H, Info.Duplicate_Choice_Count + 1);
      H := Mix (H, Info.Coverage_Gap_Count + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      H := Mix (H, Length (Info.Message) + Length (Info.Detail) + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Static_Legality_Status) return String is
   begin
      case Status is
         when Static_Legality_Static_Range_Compatible =>
            return "static expression is within the target range";
         when Static_Legality_Static_Predicate_Compatible =>
            return "static predicate is known to be satisfied";
         when Static_Legality_Dynamic_Predicate_Required =>
            return "predicate check is dynamic and must be preserved";
         when Static_Legality_Static_Discrete_Choice_Compatible =>
            return "static discrete choice is legal";
         when Static_Legality_Static_Constraint_Compatible =>
            return "static constraint is legal";
         when Static_Legality_Linked_Assignment_Compatible =>
            return "linked assignment legality is compatible";
         when Static_Legality_Linked_Return_Compatible =>
            return "linked return legality is compatible";
         when Static_Legality_Linked_Semantic_Compatible =>
            return "linked conversion/access/aggregate legality is compatible";
         when Static_Legality_Linked_Overload_Compatible =>
            return "linked overload legality is compatible";
         when Static_Legality_Requires_Static_Expression =>
            return "Ada context requires a static expression";
         when Static_Legality_Non_Static_Expression =>
            return "expression is not static where staticness is required";
         when Static_Legality_Unresolved_Static_Name =>
            return "static expression references an unresolved name";
         when Static_Legality_Malformed_Static_Expression =>
            return "static expression is malformed";
         when Static_Legality_Static_Division_By_Zero =>
            return "static expression divides by zero";
         when Static_Legality_Static_Cycle =>
            return "static expression depends on a cyclic static binding";
         when Static_Legality_Unsupported_Static_Attribute =>
            return "static attribute is unsupported in this context";
         when Static_Legality_Range_Violation =>
            return "static value is outside the target range";
         when Static_Legality_Null_Range =>
            return "static range is null or reversed";
         when Static_Legality_Choice_Out_Of_Range =>
            return "static choice is outside the target range";
         when Static_Legality_Duplicate_Static_Choice =>
            return "duplicate static choice detected";
         when Static_Legality_Choice_Coverage_Gap =>
            return "static choices do not cover the required range";
         when Static_Legality_Predicate_Static_Failure =>
            return "static predicate is known to fail";
         when Static_Legality_Predicate_Unresolved =>
            return "predicate legality is unresolved";
         when Static_Legality_Predicate_Non_Static_Where_Static_Required =>
            return "predicate is non-static where a static predicate is required";
         when Static_Legality_Linked_Assignment_Error =>
            return "linked assignment legality failed";
         when Static_Legality_Linked_Return_Error =>
            return "linked return legality failed";
         when Static_Legality_Linked_Semantic_Error =>
            return "linked conversion/access/aggregate legality failed";
         when Static_Legality_Linked_Overload_Error =>
            return "linked overload legality failed";
         when Static_Legality_Universal_Numeric_Unresolved =>
            return "universal numeric expression has not been finally resolved";
         when Static_Legality_Indeterminate =>
            return "static/range/predicate legality is indeterminate";
         when Static_Legality_Not_Checked =>
            return "static/range/predicate legality was not checked";
      end case;
   end Message_For;

   function Classify (Context : Static_Legality_Context_Info) return Static_Legality_Status is
      use Editor.Ada_Static_Expressions;
   begin
      if Context.Assignment /= Editor.Ada_Assignment_Legality.No_Assignment_Legality then
         if Assignment_Legal (Context.Assignment_Status) then
            return Static_Legality_Linked_Assignment_Compatible;
         elsif Context.Assignment_Status = Editor.Ada_Assignment_Legality.Assignment_Legality_Universal_Numeric_Unresolved then
            return Static_Legality_Universal_Numeric_Unresolved;
         else
            return Static_Legality_Linked_Assignment_Error;
         end if;
      elsif Context.Return_Item /= Editor.Ada_Return_Legality.No_Return_Legality then
         if Return_Legal (Context.Return_Status) then
            return Static_Legality_Linked_Return_Compatible;
         elsif Context.Return_Status = Editor.Ada_Return_Legality.Return_Legality_Result_Universal_Numeric_Unresolved then
            return Static_Legality_Universal_Numeric_Unresolved;
         else
            return Static_Legality_Linked_Return_Error;
         end if;
      elsif Context.Semantic_Item /= Editor.Ada_Conversion_Access_Aggregate_Legality.No_Semantic_Legality then
         if Semantic_Legal (Context.Semantic_Status) then
            return Static_Legality_Linked_Semantic_Compatible;
         elsif Context.Semantic_Status = Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Universal_Numeric_Unresolved then
            return Static_Legality_Universal_Numeric_Unresolved;
         else
            return Static_Legality_Linked_Semantic_Error;
         end if;
      elsif Context.Overload_Item /= Editor.Ada_Overload_Resolution_Legality.No_Overload_Legality then
         if Overload_Legal (Context.Overload_Status) then
            return Static_Legality_Linked_Overload_Compatible;
         else
            return Static_Legality_Linked_Overload_Error;
         end if;
      elsif Context.Is_Universal_Numeric then
         return Static_Legality_Universal_Numeric_Unresolved;
      elsif Context.Requires_Static then
         case Context.Static_Status is
            when Static_Value_Integer | Static_Value_Enumeration_Literal |
                 Static_Value_Modular_Integer | Static_Value_Fixed_Point |
                 Static_Value_Static_Attribute =>
               null;
            when Static_Value_Unresolved_Name =>
               return Static_Legality_Unresolved_Static_Name;
            when Static_Value_Non_Static =>
               return Static_Legality_Non_Static_Expression;
            when Static_Value_Malformed =>
               return Static_Legality_Malformed_Static_Expression;
            when Static_Value_Division_By_Zero =>
               return Static_Legality_Static_Division_By_Zero;
            when Static_Value_Cycle =>
               return Static_Legality_Static_Cycle;
            when Static_Value_Unsupported_Attribute =>
               return Static_Legality_Unsupported_Static_Attribute;
            when others =>
               return Static_Legality_Requires_Static_Expression;
         end case;
      end if;

      if Context.Has_Static_Range and then Context.Static_First > Context.Static_Last then
         return Static_Legality_Null_Range;
      elsif Context.Has_Static_Range and then
        (Context.Static_Integer_Value < Context.Static_First or else
         Context.Static_Integer_Value > Context.Static_Last)
      then
         if Context.Kind in Static_Context_Discrete_Choice | Static_Context_Case_Choice then
            return Static_Legality_Choice_Out_Of_Range;
         end if;
         return Static_Legality_Range_Violation;
      elsif Context.Duplicate_Choice_Count > 0 then
         return Static_Legality_Duplicate_Static_Choice;
      elsif Context.Coverage_Gap_Count > 0 then
         return Static_Legality_Choice_Coverage_Gap;
      elsif Context.Predicate = Predicate_Static_Known_False then
         return Static_Legality_Predicate_Static_Failure;
      elsif Context.Predicate = Predicate_Unresolved then
         return Static_Legality_Predicate_Unresolved;
      elsif Context.Predicate = Predicate_Non_Static_Required then
         return Static_Legality_Predicate_Non_Static_Where_Static_Required;
      elsif Context.Predicate = Predicate_Static_Known_True then
         return Static_Legality_Static_Predicate_Compatible;
      elsif Context.Predicate = Predicate_Dynamic then
         return Static_Legality_Dynamic_Predicate_Required;
      elsif Context.Kind in Static_Context_Discrete_Choice | Static_Context_Case_Choice then
         return Static_Legality_Static_Discrete_Choice_Compatible;
      elsif Context.Kind in Static_Context_Range_Constraint |
        Static_Context_Discriminant_Constraint |
        Static_Context_Array_Index_Constraint
      then
         return Static_Legality_Static_Constraint_Compatible;
      elsif Context.Has_Static_Range then
         return Static_Legality_Static_Range_Compatible;
      else
         return Static_Legality_Indeterminate;
      end if;
   end Classify;

   procedure Clear (Model : in out Static_Legality_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Static_Legality_Context_Model;
      Info  : Static_Legality_Context_Info)
   is
      Item : Static_Legality_Context_Info := Info;
   begin
      if Item.Id = No_Static_Context then
         Item.Id := Static_Context_Id (Natural (Model.Contexts.Length) + 1);
      end if;
      if Item.Source_Fingerprint = 0 then
         Item.Source_Fingerprint := Context_Fingerprint (Item);
      end if;
      Model.Contexts.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Source_Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Static_Legality_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Static_Legality_Context_Model;
      Index : Positive) return Static_Legality_Context_Info
   is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Static_Legality_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Static_Legality_Context_Model) return Static_Legality_Model
   is
      Model : Static_Legality_Model;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Static_Legality_Context_Info := Contexts.Contexts.Element (I);
            Row : Static_Legality_Info;
         begin
            Row.Id := Static_Legality_Id (I);
            Row.Context := C.Id;
            Row.Kind := C.Kind;
            Row.Node := C.Node;
            Row.Expression_Node := C.Expression_Node;
            Row.Target_Node := C.Target_Node;
            Row.Status := Classify (C);
            Row.Message := To_Unbounded_String (Message_For (Row.Status));
            Row.Detail := To_Unbounded_String (Static_Context_Kind'Image (C.Kind));
            Row.Subtype_Name := C.Subtype_Name;
            Row.Static_Status := C.Static_Status;
            Row.Static_Integer_Value := C.Static_Integer_Value;
            Row.Static_First := C.Static_First;
            Row.Static_Last := C.Static_Last;
            Row.Predicate := C.Predicate;
            Row.Assignment_Status := C.Assignment_Status;
            Row.Return_Status := C.Return_Status;
            Row.Semantic_Status := C.Semantic_Status;
            Row.Overload_Status := C.Overload_Status;
            Row.Choice_Count := C.Choice_Count;
            Row.Duplicate_Choice_Count := C.Duplicate_Choice_Count;
            Row.Coverage_Gap_Count := C.Coverage_Gap_Count;
            Row.Start_Line := C.Start_Line;
            Row.Start_Column := C.Start_Column;
            Row.End_Line := C.End_Line;
            Row.End_Column := C.End_Column;
            Row.Source_Fingerprint := C.Source_Fingerprint;
            Row.Fingerprint := Row_Fingerprint (Row);
            Model.Items.Append (Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint + 1);

            if Is_Legal (Row.Status) then
               Model.Legal_Total := Model.Legal_Total + 1;
            else
               Model.Error_Total := Model.Error_Total + 1;
            end if;
            if Is_Static_Error (Row.Status) then
               Model.Static_Required_Total := Model.Static_Required_Total + 1;
            end if;
            if Is_Range_Error (Row.Status) then
               Model.Range_Error_Total := Model.Range_Error_Total + 1;
            end if;
            if Is_Predicate_Error (Row.Status) then
               Model.Predicate_Error_Total := Model.Predicate_Error_Total + 1;
            end if;
            if Is_Linked_Error (Row.Status) then
               Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
            end if;
            if Row.Status = Static_Legality_Universal_Numeric_Unresolved then
               Model.Universal_Numeric_Total := Model.Universal_Numeric_Total + 1;
            end if;
            if Row.Status = Static_Legality_Indeterminate then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Model;
   end Build;

   function Legality_Count (Model : Static_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Static_Legality_Model;
      Index : Positive) return Static_Legality_Info
   is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Static_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Static_Legality_Info
   is
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         declare
            Row : constant Static_Legality_Info := Model.Items.Element (I);
         begin
            if Row.Node = Node or else Row.Expression_Node = Node or else Row.Target_Node = Node then
               return Row;
            end if;
         end;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Static_Legality_Model;
      Status : Static_Legality_Status) return Static_Legality_Result_Set
   is
      Results : Static_Legality_Result_Set;
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         declare
            Row : constant Static_Legality_Info := Model.Items.Element (I);
         begin
            if Row.Status = Status then
               Results.Items.Append (Row);
               Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint + 1);
            end if;
         end;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Static_Legality_Model;
      Kind  : Static_Context_Kind) return Static_Legality_Result_Set
   is
      Results : Static_Legality_Result_Set;
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         declare
            Row : constant Static_Legality_Info := Model.Items.Element (I);
         begin
            if Row.Kind = Kind then
               Results.Items.Append (Row);
               Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint + 1);
            end if;
         end;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Subtype
     (Model        : Static_Legality_Model;
      Subtype_Name : String) return Static_Legality_Result_Set
   is
      Results : Static_Legality_Result_Set;
      Want : constant String := Ada.Characters.Handling.To_Lower (Subtype_Name);
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         declare
            Row : constant Static_Legality_Info := Model.Items.Element (I);
            Have : constant String := Ada.Characters.Handling.To_Lower (To_String (Row.Subtype_Name));
         begin
            if Have = Want then
               Results.Items.Append (Row);
               Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint + 1);
            end if;
         end;
      end loop;
      return Results;
   end Rows_For_Subtype;

   function Rows_For_Predicate
     (Model     : Static_Legality_Model;
      Predicate : Predicate_Policy) return Static_Legality_Result_Set
   is
      Results : Static_Legality_Result_Set;
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         declare
            Row : constant Static_Legality_Info := Model.Items.Element (I);
         begin
            if Row.Predicate = Predicate then
               Results.Items.Append (Row);
               Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint + 1);
            end if;
         end;
      end loop;
      return Results;
   end Rows_For_Predicate;

   function Result_Count (Results : Static_Legality_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Static_Legality_Result_Set;
      Index   : Positive) return Static_Legality_Info
   is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Static_Legality_Model;
      Status : Static_Legality_Status) return Natural
   is
      Total : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         if Model.Items.Element (I).Status = Status then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Status;

   function Count_Kind
     (Model : Static_Legality_Model;
      Kind  : Static_Context_Kind) return Natural
   is
      Total : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         if Model.Items.Element (I).Kind = Kind then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Kind;

   function Count_Predicate
     (Model     : Static_Legality_Model;
      Predicate : Predicate_Policy) return Natural
   is
      Total : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         if Model.Items.Element (I).Predicate = Predicate then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Predicate;

   function Legal_Count (Model : Static_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Static_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Static_Required_Error_Count (Model : Static_Legality_Model) return Natural is
   begin
      return Model.Static_Required_Total;
   end Static_Required_Error_Count;

   function Range_Error_Count (Model : Static_Legality_Model) return Natural is
   begin
      return Model.Range_Error_Total;
   end Range_Error_Count;

   function Predicate_Error_Count (Model : Static_Legality_Model) return Natural is
   begin
      return Model.Predicate_Error_Total;
   end Predicate_Error_Count;

   function Linked_Error_Count (Model : Static_Legality_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Error_Count;

   function Universal_Numeric_Unresolved_Count (Model : Static_Legality_Model) return Natural is
   begin
      return Model.Universal_Numeric_Total;
   end Universal_Numeric_Unresolved_Count;

   function Indeterminate_Count (Model : Static_Legality_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Static_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Static_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Static_Legality;
   end Has_Legality;

end Editor.Ada_Staticness_Range_Predicate_Legality;
