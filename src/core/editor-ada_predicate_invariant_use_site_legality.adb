with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Predicate_Invariant_Use_Site_Legality is

   pragma Suppress (Overflow_Check);
   use type Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Status;
   use type Editor.Ada_Assignment_Legality.Assignment_Legality_Status;
   use type Editor.Ada_Return_Legality.Return_Legality_Status;
   use type Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status;
   use type Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status;
   use type Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Status;

   use type Editor.Ada_Syntax_Tree.Node_Id;
   package SRP renames Editor.Ada_Staticness_Range_Predicate_Legality;
   package AL renames Editor.Ada_Assignment_Legality;
   package RL renames Editor.Ada_Return_Legality;
   package SL renames Editor.Ada_Conversion_Access_Aggregate_Legality;
   package OL renames Editor.Ada_Overload_Resolution_Legality;
   package GL renames Editor.Ada_Generic_Instance_Freezing_Representation_Legality;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 283) + (B * 43) + 1124) mod 1_000_000_007;
   end Mix;

   function Is_Legal (Status : Predicate_Use_Legality_Status) return Boolean is
   begin
      return Status in
        Predicate_Use_Legality_Legal_Static_Predicate |
        Predicate_Use_Legality_Legal_Dynamic_Predicate_Check |
        Predicate_Use_Legality_Legal_Invariant_Preserved |
        Predicate_Use_Legality_Legal_Dynamic_Invariant_Check |
        Predicate_Use_Legality_Legal_Static_Range_And_Predicate |
        Predicate_Use_Legality_Legal_Linked_Assignment |
        Predicate_Use_Legality_Legal_Linked_Return |
        Predicate_Use_Legality_Legal_Linked_Semantic |
        Predicate_Use_Legality_Legal_Linked_Overload |
        Predicate_Use_Legality_Legal_Linked_Generic_Actual;
   end Is_Legal;

   function Predicate_Error (Status : Predicate_Use_Legality_Status) return Boolean is
   begin
      return Status in
        Predicate_Use_Legality_Static_Predicate_Failure |
        Predicate_Use_Legality_Predicate_Unresolved |
        Predicate_Use_Legality_Predicate_Non_Static_Where_Static_Required;
   end Predicate_Error;

   function Invariant_Error (Status : Predicate_Use_Legality_Status) return Boolean is
   begin
      return Status in
        Predicate_Use_Legality_Invariant_Violation |
        Predicate_Use_Legality_Invariant_Unresolved |
        Predicate_Use_Legality_Invariant_Private_View_Barrier;
   end Invariant_Error;

   function Missing_Check (Status : Predicate_Use_Legality_Status) return Boolean is
   begin
      return Status in
        Predicate_Use_Legality_Missing_Check_At_Assignment |
        Predicate_Use_Legality_Missing_Check_At_Return |
        Predicate_Use_Legality_Missing_Check_At_Conversion |
        Predicate_Use_Legality_Missing_Check_At_Aggregate |
        Predicate_Use_Legality_Missing_Check_At_Call |
        Predicate_Use_Legality_Missing_Check_At_Generic_Actual;
   end Missing_Check;

   function Linked_Error (Status : Predicate_Use_Legality_Status) return Boolean is
   begin
      return Status in
        Predicate_Use_Legality_Linked_Staticness_Error |
        Predicate_Use_Legality_Linked_Assignment_Error |
        Predicate_Use_Legality_Linked_Return_Error |
        Predicate_Use_Legality_Linked_Semantic_Error |
        Predicate_Use_Legality_Linked_Overload_Error |
        Predicate_Use_Legality_Linked_Generic_Actual_Error;
   end Linked_Error;

   function Assignment_Legal (Status : Assignment_Legality_Status) return Boolean is
   begin
      return Status in
        AL.Assignment_Legality_Compatible |
        AL.Assignment_Legality_Class_Wide_Compatible |
        AL.Assignment_Legality_Static_Range_Compatible;
   end Assignment_Legal;

   function Return_Legal (Status : Return_Legality_Status) return Boolean is
   begin
      return Status in
        RL.Return_Legality_Procedure_Return_Compatible |
        RL.Return_Legality_Function_Return_Compatible |
        RL.Return_Legality_Extended_Return_Compatible;
   end Return_Legal;

   function Semantic_Legal (Status : Semantic_Legality_Status) return Boolean is
   begin
      return Status in
        SL.Semantic_Legality_Legal_Conversion |
        SL.Semantic_Legality_Legal_Qualified_Expression |
        SL.Semantic_Legality_Legal_Access_Conversion |
        SL.Semantic_Legality_Legal_Access_Parameter |
        SL.Semantic_Legality_Legal_Allocator |
        SL.Semantic_Legality_Legal_Aggregate |
        SL.Semantic_Legality_Legal_Container_Aggregate |
        SL.Semantic_Legality_Numeric_Conversion |
        SL.Semantic_Legality_Tagged_Conversion |
        SL.Semantic_Legality_Class_Wide_Conversion |
        SL.Semantic_Legality_Static_Range_Compatible;
   end Semantic_Legal;

   function Overload_Legal (Status : Overload_Legality_Status) return Boolean is
   begin
      return Status in
        OL.Overload_Legality_Legal_Exact |
        OL.Overload_Legality_Legal_Expected_Type_Preferred |
        OL.Overload_Legality_Legal_Universal_Integer_Preferred |
        OL.Overload_Legality_Legal_Universal_Real_Preferred |
        OL.Overload_Legality_Legal_Primitive_Operator_Preferred |
        OL.Overload_Legality_Legal_Implicit_Numeric_Conversion |
        OL.Overload_Legality_Legal_Class_Wide_Conversion |
        OL.Overload_Legality_Legal_Access_Conversion |
        OL.Overload_Legality_Legal_Named_Actual_Profile |
        OL.Overload_Legality_Legal_Defaulted_Formal_Profile;
   end Overload_Legal;

   function Instance_Legal (Status : Instance_Legality_Status) return Boolean is
   begin
      return Status in
        GL.Instance_Legality_Legal_Instance |
        GL.Instance_Legality_Legal_Body_Substitution |
        GL.Instance_Legality_Legal_Default_Substitution |
        GL.Instance_Legality_Legal_Formal_Package_Substitution |
        GL.Instance_Legality_Legal_Boxed_Formal_Package;
   end Instance_Legal;

   function Context_Fingerprint (Info : Predicate_Use_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Predicate_Use_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Use_Site_Check_Point'Pos (Info.Check_Point) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Expression_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Natural (Info.Subtype_Node) + 1);
      H := Mix (H, Length (Info.Subtype_Name) + 1);
      H := Mix (H, SRP.Predicate_Policy'Pos (Info.Predicate) + 1);
      H := Mix (H, Invariant_Policy'Pos (Info.Invariant) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Requires_Static_Predicate)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Requires_Predicate_Check)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Requires_Invariant_Check)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Check_Is_Inserted)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Cross_Unit_View_Resolved)) + 1);
      H := Mix (H, SRP.Static_Legality_Status'Pos (Info.Staticness_Status) + 1);
      H := Mix (H, AL.Assignment_Legality_Status'Pos (Info.Assignment_Status) + 1);
      H := Mix (H, RL.Return_Legality_Status'Pos (Info.Return_Status) + 1);
      H := Mix (H, SL.Semantic_Legality_Status'Pos (Info.Semantic_Status) + 1);
      H := Mix (H, OL.Overload_Legality_Status'Pos (Info.Overload_Status) + 1);
      H := Mix (H, GL.Instance_Legality_Status'Pos (Info.Instance_Status) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : Predicate_Use_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Predicate_Use_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Use_Site_Check_Point'Pos (Info.Check_Point) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Predicate_Use_Legality_Status'Pos (Info.Status) + 1);
      H := Mix (H, SRP.Predicate_Policy'Pos (Info.Predicate) + 1);
      H := Mix (H, Invariant_Policy'Pos (Info.Invariant) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      H := Mix (H, Length (Info.Message) + Length (Info.Detail) + 1);
      return H;
   end Row_Fingerprint;

   function Missing_Check_Status
     (Kind : Predicate_Use_Context_Kind) return Predicate_Use_Legality_Status is
   begin
      case Kind is
         when Predicate_Use_Assignment | Predicate_Use_Object_Initialization =>
            return Predicate_Use_Legality_Missing_Check_At_Assignment;
         when Predicate_Use_Return =>
            return Predicate_Use_Legality_Missing_Check_At_Return;
         when Predicate_Use_Conversion | Predicate_Use_Qualified_Expression =>
            return Predicate_Use_Legality_Missing_Check_At_Conversion;
         when Predicate_Use_Record_Aggregate | Predicate_Use_Array_Aggregate |
              Predicate_Use_Discriminant_Default | Predicate_Use_Component_Default =>
            return Predicate_Use_Legality_Missing_Check_At_Aggregate;
         when Predicate_Use_Call_Actual | Predicate_Use_Default_Expression =>
            return Predicate_Use_Legality_Missing_Check_At_Call;
         when Predicate_Use_Generic_Actual =>
            return Predicate_Use_Legality_Missing_Check_At_Generic_Actual;
         when Predicate_Use_Unknown =>
            return Predicate_Use_Legality_Indeterminate;
      end case;
   end Missing_Check_Status;

   function Message_For (Status : Predicate_Use_Legality_Status) return String is
   begin
      case Status is
         when Predicate_Use_Legality_Legal_Static_Predicate =>
            return "static predicate is satisfied at the use site";
         when Predicate_Use_Legality_Legal_Dynamic_Predicate_Check =>
            return "dynamic predicate check is preserved at the use site";
         when Predicate_Use_Legality_Legal_Invariant_Preserved =>
            return "type invariant is preserved at the use site";
         when Predicate_Use_Legality_Legal_Dynamic_Invariant_Check =>
            return "dynamic invariant check is preserved at the use site";
         when Predicate_Use_Legality_Legal_Static_Range_And_Predicate =>
            return "static range and predicate are both satisfied at the use site";
         when Predicate_Use_Legality_Legal_Linked_Assignment =>
            return "linked assignment legality is compatible with predicate checks";
         when Predicate_Use_Legality_Legal_Linked_Return =>
            return "linked return legality is compatible with predicate checks";
         when Predicate_Use_Legality_Legal_Linked_Semantic =>
            return "linked conversion or aggregate legality is compatible with predicate checks";
         when Predicate_Use_Legality_Legal_Linked_Overload =>
            return "linked call overload legality is compatible with predicate checks";
         when Predicate_Use_Legality_Legal_Linked_Generic_Actual =>
            return "linked generic actual legality is compatible with predicate checks";
         when Predicate_Use_Legality_Static_Predicate_Failure =>
            return "static predicate is known to fail at the use site";
         when Predicate_Use_Legality_Predicate_Unresolved =>
            return "predicate cannot be resolved at the use site";
         when Predicate_Use_Legality_Predicate_Non_Static_Where_Static_Required =>
            return "static predicate is required but only a dynamic predicate is available";
         when Predicate_Use_Legality_Invariant_Violation =>
            return "type invariant is known to be violated";
         when Predicate_Use_Legality_Invariant_Unresolved =>
            return "type invariant cannot be resolved";
         when Predicate_Use_Legality_Invariant_Private_View_Barrier =>
            return "private view hides the invariant needed for this use site";
         when Predicate_Use_Legality_Missing_Check_At_Assignment =>
            return "assignment or initialization lacks the required predicate/invariant check";
         when Predicate_Use_Legality_Missing_Check_At_Return =>
            return "return lacks the required predicate/invariant check";
         when Predicate_Use_Legality_Missing_Check_At_Conversion =>
            return "conversion lacks the required predicate/invariant check";
         when Predicate_Use_Legality_Missing_Check_At_Aggregate =>
            return "aggregate lacks the required predicate/invariant check";
         when Predicate_Use_Legality_Missing_Check_At_Call =>
            return "call actual/default lacks the required predicate/invariant check";
         when Predicate_Use_Legality_Missing_Check_At_Generic_Actual =>
            return "generic actual lacks the required predicate/invariant check";
         when Predicate_Use_Legality_Linked_Staticness_Error =>
            return "linked staticness/range/predicate legality failed";
         when Predicate_Use_Legality_Linked_Assignment_Error =>
            return "linked assignment legality failed";
         when Predicate_Use_Legality_Linked_Return_Error =>
            return "linked return legality failed";
         when Predicate_Use_Legality_Linked_Semantic_Error =>
            return "linked conversion/access/aggregate legality failed";
         when Predicate_Use_Legality_Linked_Overload_Error =>
            return "linked overload legality failed";
         when Predicate_Use_Legality_Linked_Generic_Actual_Error =>
            return "linked generic actual legality failed";
         when Predicate_Use_Legality_Universal_Numeric_Unresolved =>
            return "universal numeric expression remains unresolved before predicate checking";
         when Predicate_Use_Legality_Cross_Unit_Unresolved_View =>
            return "cross-unit view is unresolved for predicate/invariant checking";
         when Predicate_Use_Legality_Indeterminate =>
            return "predicate/invariant use-site legality is indeterminate";
         when Predicate_Use_Legality_Not_Checked =>
            return "predicate/invariant use-site legality was not checked";
      end case;
   end Message_For;

   function Classify (C : Predicate_Use_Context_Info) return Predicate_Use_Legality_Status is
   begin
      if not C.Cross_Unit_View_Resolved then
         return Predicate_Use_Legality_Cross_Unit_Unresolved_View;
      end if;

      if C.Staticness_Status in
        SRP.Static_Legality_Predicate_Static_Failure |
        SRP.Static_Legality_Predicate_Unresolved |
        SRP.Static_Legality_Predicate_Non_Static_Where_Static_Required |
        SRP.Static_Legality_Range_Violation |
        SRP.Static_Legality_Choice_Out_Of_Range |
        SRP.Static_Legality_Linked_Assignment_Error |
        SRP.Static_Legality_Linked_Return_Error |
        SRP.Static_Legality_Linked_Semantic_Error |
        SRP.Static_Legality_Linked_Overload_Error
      then
         return Predicate_Use_Legality_Linked_Staticness_Error;
      elsif C.Staticness_Status = SRP.Static_Legality_Universal_Numeric_Unresolved then
         return Predicate_Use_Legality_Universal_Numeric_Unresolved;
      end if;

      if C.Assignment_Status /= AL.Assignment_Legality_Not_Checked then
         if not Assignment_Legal (C.Assignment_Status) then
            if C.Assignment_Status = AL.Assignment_Legality_Universal_Numeric_Unresolved then
               return Predicate_Use_Legality_Universal_Numeric_Unresolved;
            end if;
            return Predicate_Use_Legality_Linked_Assignment_Error;
         elsif C.Kind in Predicate_Use_Assignment | Predicate_Use_Object_Initialization then
            null;
         end if;
      end if;

      if C.Return_Status /= RL.Return_Legality_Not_Checked then
         if not Return_Legal (C.Return_Status) then
            if C.Return_Status = RL.Return_Legality_Result_Universal_Numeric_Unresolved then
               return Predicate_Use_Legality_Universal_Numeric_Unresolved;
            end if;
            return Predicate_Use_Legality_Linked_Return_Error;
         end if;
      end if;

      if C.Semantic_Status /= SL.Semantic_Legality_Not_Checked then
         if not Semantic_Legal (C.Semantic_Status) then
            if C.Semantic_Status = SL.Semantic_Legality_Universal_Numeric_Unresolved then
               return Predicate_Use_Legality_Universal_Numeric_Unresolved;
            end if;
            return Predicate_Use_Legality_Linked_Semantic_Error;
         end if;
      end if;

      if C.Overload_Status /= OL.Overload_Legality_Not_Checked then
         if not Overload_Legal (C.Overload_Status) then
            return Predicate_Use_Legality_Linked_Overload_Error;
         end if;
      end if;

      if C.Instance_Status /= GL.Instance_Legality_Not_Checked then
         if not Instance_Legal (C.Instance_Status) then
            return Predicate_Use_Legality_Linked_Generic_Actual_Error;
         end if;
      end if;

      if (C.Requires_Predicate_Check or else C.Requires_Invariant_Check) and then
        not C.Check_Is_Inserted
      then
         return Missing_Check_Status (C.Kind);
      end if;

      case C.Predicate is
         when SRP.Predicate_Static_Known_False =>
            return Predicate_Use_Legality_Static_Predicate_Failure;
         when SRP.Predicate_Unresolved =>
            return Predicate_Use_Legality_Predicate_Unresolved;
         when SRP.Predicate_Non_Static_Required =>
            return Predicate_Use_Legality_Predicate_Non_Static_Where_Static_Required;
         when SRP.Predicate_Static_Known_True =>
            if C.Invariant = Invariant_Known_Preserved then
               return Predicate_Use_Legality_Legal_Static_Range_And_Predicate;
            end if;
            return Predicate_Use_Legality_Legal_Static_Predicate;
         when SRP.Predicate_Dynamic =>
            if C.Requires_Static_Predicate then
               return Predicate_Use_Legality_Predicate_Non_Static_Where_Static_Required;
            end if;
            return Predicate_Use_Legality_Legal_Dynamic_Predicate_Check;
         when others =>
            null;
      end case;

      case C.Invariant is
         when Invariant_Known_Violated =>
            return Predicate_Use_Legality_Invariant_Violation;
         when Invariant_Unresolved =>
            return Predicate_Use_Legality_Invariant_Unresolved;
         when Invariant_Private_View_Barrier =>
            return Predicate_Use_Legality_Invariant_Private_View_Barrier;
         when Invariant_Known_Preserved =>
            return Predicate_Use_Legality_Legal_Invariant_Preserved;
         when Invariant_Dynamic_Check_Required =>
            return Predicate_Use_Legality_Legal_Dynamic_Invariant_Check;
         when others =>
            null;
      end case;

      if C.Assignment_Status /= AL.Assignment_Legality_Not_Checked then
         return Predicate_Use_Legality_Legal_Linked_Assignment;
      elsif C.Return_Status /= RL.Return_Legality_Not_Checked then
         return Predicate_Use_Legality_Legal_Linked_Return;
      elsif C.Semantic_Status /= SL.Semantic_Legality_Not_Checked then
         return Predicate_Use_Legality_Legal_Linked_Semantic;
      elsif C.Overload_Status /= OL.Overload_Legality_Not_Checked then
         return Predicate_Use_Legality_Legal_Linked_Overload;
      elsif C.Instance_Status /= GL.Instance_Legality_Not_Checked then
         return Predicate_Use_Legality_Legal_Linked_Generic_Actual;
      end if;

      return Predicate_Use_Legality_Indeterminate;
   end Classify;

   procedure Clear (Model : in out Predicate_Use_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Predicate_Use_Context_Model;
      Info  : Predicate_Use_Context_Info)
   is
      Item : Predicate_Use_Context_Info := Info;
   begin
      if Item.Id = No_Predicate_Use_Context then
         Item.Id := Predicate_Use_Context_Id (Natural (Model.Contexts.Length) + 1);
      end if;
      if Item.Source_Fingerprint = 0 then
         Item.Source_Fingerprint := Context_Fingerprint (Item);
      end if;
      Model.Contexts.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Source_Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Predicate_Use_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Predicate_Use_Context_Model;
      Index : Positive) return Predicate_Use_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Predicate_Use_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Predicate_Use_Context_Model) return Predicate_Use_Legality_Model
   is
      Model : Predicate_Use_Legality_Model;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Predicate_Use_Context_Info := Contexts.Contexts.Element (I);
            Row : Predicate_Use_Legality_Info;
         begin
            Row.Id := Predicate_Use_Legality_Id (I);
            Row.Context := C.Id;
            Row.Kind := C.Kind;
            Row.Check_Point := C.Check_Point;
            Row.Node := C.Node;
            Row.Expression_Node := C.Expression_Node;
            Row.Target_Node := C.Target_Node;
            Row.Subtype_Name := C.Subtype_Name;
            Row.Status := Classify (C);
            Row.Message := To_Unbounded_String (Message_For (Row.Status));
            Row.Detail := To_Unbounded_String (Predicate_Use_Context_Kind'Image (C.Kind));
            Row.Predicate := C.Predicate;
            Row.Invariant := C.Invariant;
            Row.Staticness_Status := C.Staticness_Status;
            Row.Assignment_Status := C.Assignment_Status;
            Row.Return_Status := C.Return_Status;
            Row.Semantic_Status := C.Semantic_Status;
            Row.Overload_Status := C.Overload_Status;
            Row.Instance_Status := C.Instance_Status;
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
            if Predicate_Error (Row.Status) then
               Model.Predicate_Error_Total := Model.Predicate_Error_Total + 1;
            end if;
            if Invariant_Error (Row.Status) then
               Model.Invariant_Error_Total := Model.Invariant_Error_Total + 1;
            end if;
            if Missing_Check (Row.Status) then
               Model.Missing_Check_Total := Model.Missing_Check_Total + 1;
            end if;
            if Linked_Error (Row.Status) then
               Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
            end if;
            if Row.Status = Predicate_Use_Legality_Indeterminate then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Predicate_Use_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Predicate_Use_Legality_Model;
      Index : Positive) return Predicate_Use_Legality_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Predicate_Use_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Predicate_Use_Legality_Info is
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         declare
            Row : constant Predicate_Use_Legality_Info := Model.Items.Element (I);
         begin
            if Row.Node = Node or else Row.Expression_Node = Node or else Row.Target_Node = Node then
               return Row;
            end if;
         end;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Predicate_Use_Legality_Model;
      Status : Predicate_Use_Legality_Status) return Predicate_Use_Result_Set
   is
      Results : Predicate_Use_Result_Set;
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         declare
            Row : constant Predicate_Use_Legality_Info := Model.Items.Element (I);
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
     (Model : Predicate_Use_Legality_Model;
      Kind  : Predicate_Use_Context_Kind) return Predicate_Use_Result_Set
   is
      Results : Predicate_Use_Result_Set;
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         declare
            Row : constant Predicate_Use_Legality_Info := Model.Items.Element (I);
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
     (Model        : Predicate_Use_Legality_Model;
      Subtype_Name : String) return Predicate_Use_Result_Set
   is
      Results : Predicate_Use_Result_Set;
      Want : constant String := Ada.Characters.Handling.To_Lower (Subtype_Name);
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         declare
            Row : constant Predicate_Use_Legality_Info := Model.Items.Element (I);
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

   function Result_Count (Results : Predicate_Use_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Predicate_Use_Result_Set;
      Index   : Positive) return Predicate_Use_Legality_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Predicate_Use_Legality_Model;
      Status : Predicate_Use_Legality_Status) return Natural
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
     (Model : Predicate_Use_Legality_Model;
      Kind  : Predicate_Use_Context_Kind) return Natural
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

   function Legal_Count (Model : Predicate_Use_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Predicate_Use_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Predicate_Error_Count (Model : Predicate_Use_Legality_Model) return Natural is
   begin
      return Model.Predicate_Error_Total;
   end Predicate_Error_Count;

   function Invariant_Error_Count (Model : Predicate_Use_Legality_Model) return Natural is
   begin
      return Model.Invariant_Error_Total;
   end Invariant_Error_Count;

   function Missing_Check_Count (Model : Predicate_Use_Legality_Model) return Natural is
   begin
      return Model.Missing_Check_Total;
   end Missing_Check_Count;

   function Linked_Error_Count (Model : Predicate_Use_Legality_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Predicate_Use_Legality_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Predicate_Use_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Predicate_Use_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Predicate_Use_Legality;
   end Has_Legality;

end Editor.Ada_Predicate_Invariant_Use_Site_Legality;
