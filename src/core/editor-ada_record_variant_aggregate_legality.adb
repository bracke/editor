with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Record_Variant_Aggregate_Legality is


   use type Editor.Ada_Syntax_Tree.Node_Id;
   function Mix (A, B : Natural) return Natural is
   begin
      return (A * 131) + B + 17;
   end Mix;

   function Node_Fp (Node : Editor.Ada_Syntax_Tree.Node_Id) return Natural is
   begin
      return Natural (Node) mod 1_000_003;
   end Node_Fp;

   function Is_Legal_Aggregate
     (Status : Semantic_Legality_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Not_Checked |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Legal_Aggregate |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Legal_Container_Aggregate;
   end Is_Legal_Aggregate;

   function Is_Legal_Predicate
     (Status : Predicate_Use_Legality_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Not_Checked |
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Legal_Static_Predicate |
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Legal_Dynamic_Predicate_Check |
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Legal_Invariant_Preserved |
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Legal_Dynamic_Invariant_Check |
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Legal_Static_Range_And_Predicate |
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Legal_Linked_Assignment |
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Legal_Linked_Return |
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Legal_Linked_Semantic |
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Legal_Linked_Overload |
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Legal_Linked_Generic_Actual;
   end Is_Legal_Predicate;

   function Is_Legal_Representation
     (Status : Representation_Integration_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Not_Checked |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Representation_Item |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Record_Layout |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Stream_Attribute |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Operational_Attribute |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Convention |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Generic_Instance_Effect |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Finalization_Effect;
   end Is_Legal_Representation;

   function Classify
     (Info : Record_Aggregate_Context_Info) return Record_Aggregate_Legality_Status is
   begin
      if Info.Private_View_Barrier then
         return Record_Aggregate_Legality_Private_View_Barrier;
      elsif Info.Limited_View_Barrier then
         return Record_Aggregate_Legality_Limited_View_Barrier;
      elsif Info.Cross_Unit_Unresolved then
         return Record_Aggregate_Legality_Cross_Unit_Unresolved_View;
      elsif not Is_Legal_Aggregate (Info.Aggregate_Status) then
         return Record_Aggregate_Legality_Linked_Aggregate_Error;
      elsif not Is_Legal_Predicate (Info.Predicate_Status) then
         return Record_Aggregate_Legality_Linked_Predicate_Invariant_Error;
      elsif not Is_Legal_Representation (Info.Representation_Status) then
         case Info.Representation_Status is
            when Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Variant_Layout_Hole =>
               return Record_Aggregate_Legality_Variant_Layout_Hole;
            when Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Variant_Layout_Overlap =>
               return Record_Aggregate_Legality_Variant_Layout_Overlap;
            when Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Discriminant_Layout_Error =>
               return Record_Aggregate_Legality_Discriminant_Layout_Error;
            when others =>
               return Record_Aggregate_Legality_Linked_Representation_Error;
         end case;
      elsif Info.Positional_After_Named then
         return Record_Aggregate_Legality_Positional_After_Named;
      elsif Info.Missing_Component_Count > 0 or else
        (Info.Expected_Component_Count > 0 and then Info.Component_Count < Info.Expected_Component_Count)
      then
         return Record_Aggregate_Legality_Missing_Component;
      elsif Info.Duplicate_Component_Count > 0 then
         return Record_Aggregate_Legality_Duplicate_Component;
      elsif Info.Component_Type_Mismatch_Count > 0 then
         return Record_Aggregate_Legality_Component_Type_Mismatch;
      elsif Info.Missing_Discriminant_Count > 0 then
         return Record_Aggregate_Legality_Missing_Discriminant;
      elsif Info.Duplicate_Discriminant_Count > 0 then
         return Record_Aggregate_Legality_Duplicate_Discriminant;
      elsif Info.Discriminant_Type_Mismatch_Count > 0 then
         return Record_Aggregate_Legality_Discriminant_Type_Mismatch;
      elsif Info.Type_Is_Unconstrained
        and then not Info.Has_Defaulted_Discriminants
        and then Info.Discriminant_Count = 0
      then
         return Record_Aggregate_Legality_Unconstrained_Without_Discriminants;
      elsif Info.Duplicate_Variant_Choice_Count > 0 then
         return Record_Aggregate_Legality_Variant_Choice_Duplicate;
      elsif Info.Overlapping_Variant_Choice_Count > 0 then
         return Record_Aggregate_Legality_Variant_Choice_Overlap;
      elsif Info.Unreachable_Variant_Choice_Count > 0 then
         return Record_Aggregate_Legality_Variant_Choice_Unreachable;
      elsif not Info.Variant_Coverage_Complete or else
        (Info.Expected_Variant_Choice_Count > 0 and then
         Info.Variant_Choice_Count < Info.Expected_Variant_Choice_Count)
      then
         return Record_Aggregate_Legality_Variant_Coverage_Incomplete;
      elsif Info.Variant_Layout_Hole then
         return Record_Aggregate_Legality_Variant_Layout_Hole;
      elsif Info.Variant_Layout_Overlap then
         return Record_Aggregate_Legality_Variant_Layout_Overlap;
      elsif Info.Discriminant_Layout_Error then
         return Record_Aggregate_Legality_Discriminant_Layout_Error;
      elsif Info.Type_Is_Unconstrained and then Info.Has_Defaulted_Discriminants then
         return Record_Aggregate_Legality_Legal_Defaulted_Discriminants;
      else
         case Info.Kind is
            when Record_Aggregate_Context_Extension_Aggregate =>
               return Record_Aggregate_Legality_Legal_Extension_Aggregate;
            when Record_Aggregate_Context_Variant_Aggregate =>
               return Record_Aggregate_Legality_Legal_Variant_Aggregate;
            when Record_Aggregate_Context_Discriminant_Constraint =>
               return Record_Aggregate_Legality_Legal_Discriminant_Constraint;
            when Record_Aggregate_Context_Representation_Layout_Use =>
               return Record_Aggregate_Legality_Legal_Layout_Compatible;
            when Record_Aggregate_Context_Record_Aggregate |
                 Record_Aggregate_Context_Component_Association |
                 Record_Aggregate_Context_Array_Aggregate =>
               return Record_Aggregate_Legality_Legal_Record_Aggregate;
            when Record_Aggregate_Context_Unknown =>
               return Record_Aggregate_Legality_Indeterminate;
         end case;
      end if;
   end Classify;

   function Is_Legal
     (Status : Record_Aggregate_Legality_Status) return Boolean is
   begin
      return Status in
        Record_Aggregate_Legality_Legal_Record_Aggregate |
        Record_Aggregate_Legality_Legal_Extension_Aggregate |
        Record_Aggregate_Legality_Legal_Variant_Aggregate |
        Record_Aggregate_Legality_Legal_Discriminant_Constraint |
        Record_Aggregate_Legality_Legal_Defaulted_Discriminants |
        Record_Aggregate_Legality_Legal_Layout_Compatible;
   end Is_Legal;

   function Is_Variant_Error
     (Status : Record_Aggregate_Legality_Status) return Boolean is
   begin
      return Status in
        Record_Aggregate_Legality_Variant_Choice_Missing |
        Record_Aggregate_Legality_Variant_Choice_Duplicate |
        Record_Aggregate_Legality_Variant_Choice_Overlap |
        Record_Aggregate_Legality_Variant_Coverage_Incomplete |
        Record_Aggregate_Legality_Variant_Choice_Unreachable |
        Record_Aggregate_Legality_Variant_Layout_Hole |
        Record_Aggregate_Legality_Variant_Layout_Overlap;
   end Is_Variant_Error;

   function Is_Discriminant_Error
     (Status : Record_Aggregate_Legality_Status) return Boolean is
   begin
      return Status in
        Record_Aggregate_Legality_Missing_Discriminant |
        Record_Aggregate_Legality_Duplicate_Discriminant |
        Record_Aggregate_Legality_Discriminant_Type_Mismatch |
        Record_Aggregate_Legality_Unconstrained_Without_Discriminants |
        Record_Aggregate_Legality_Discriminant_Layout_Error;
   end Is_Discriminant_Error;

   function Is_Linked_Error
     (Status : Record_Aggregate_Legality_Status) return Boolean is
   begin
      return Status in
        Record_Aggregate_Legality_Linked_Aggregate_Error |
        Record_Aggregate_Legality_Linked_Predicate_Invariant_Error |
        Record_Aggregate_Legality_Linked_Representation_Error;
   end Is_Linked_Error;

   function Make_Message
     (Status : Record_Aggregate_Legality_Status) return Unbounded_String is
   begin
      case Status is
         when Record_Aggregate_Legality_Legal_Record_Aggregate =>
            return To_Unbounded_String ("record aggregate is structurally legal");
         when Record_Aggregate_Legality_Legal_Extension_Aggregate =>
            return To_Unbounded_String ("extension aggregate is structurally legal");
         when Record_Aggregate_Legality_Legal_Variant_Aggregate =>
            return To_Unbounded_String ("variant aggregate is covered and legal");
         when Record_Aggregate_Legality_Legal_Discriminant_Constraint =>
            return To_Unbounded_String ("discriminant constraint is legal");
         when Record_Aggregate_Legality_Legal_Defaulted_Discriminants =>
            return To_Unbounded_String ("defaulted discriminants make aggregate legal");
         when Record_Aggregate_Legality_Legal_Layout_Compatible =>
            return To_Unbounded_String ("aggregate is compatible with representation layout");
         when Record_Aggregate_Legality_Missing_Component =>
            return To_Unbounded_String ("record aggregate is missing required components");
         when Record_Aggregate_Legality_Duplicate_Component =>
            return To_Unbounded_String ("record aggregate has duplicate component associations");
         when Record_Aggregate_Legality_Component_Type_Mismatch =>
            return To_Unbounded_String ("record aggregate component expression is type-incompatible");
         when Record_Aggregate_Legality_Positional_After_Named =>
            return To_Unbounded_String ("record aggregate has positional associations after named associations");
         when Record_Aggregate_Legality_Missing_Discriminant =>
            return To_Unbounded_String ("unconstrained record aggregate is missing discriminants");
         when Record_Aggregate_Legality_Duplicate_Discriminant =>
            return To_Unbounded_String ("discriminant association is duplicated");
         when Record_Aggregate_Legality_Discriminant_Type_Mismatch =>
            return To_Unbounded_String ("discriminant value is type-incompatible");
         when Record_Aggregate_Legality_Unconstrained_Without_Discriminants =>
            return To_Unbounded_String ("unconstrained record aggregate has no discriminant constraint");
         when Record_Aggregate_Legality_Variant_Choice_Missing =>
            return To_Unbounded_String ("variant choice is missing");
         when Record_Aggregate_Legality_Variant_Choice_Duplicate =>
            return To_Unbounded_String ("variant choice is duplicated");
         when Record_Aggregate_Legality_Variant_Choice_Overlap =>
            return To_Unbounded_String ("variant choices overlap");
         when Record_Aggregate_Legality_Variant_Coverage_Incomplete =>
            return To_Unbounded_String ("variant coverage is incomplete");
         when Record_Aggregate_Legality_Variant_Choice_Unreachable =>
            return To_Unbounded_String ("variant choice is unreachable");
         when Record_Aggregate_Legality_Variant_Layout_Hole =>
            return To_Unbounded_String ("variant representation layout has holes");
         when Record_Aggregate_Legality_Variant_Layout_Overlap =>
            return To_Unbounded_String ("variant representation layout overlaps");
         when Record_Aggregate_Legality_Discriminant_Layout_Error =>
            return To_Unbounded_String ("discriminant representation layout is illegal");
         when Record_Aggregate_Legality_Linked_Aggregate_Error =>
            return To_Unbounded_String ("aggregate legality layer reports an error");
         when Record_Aggregate_Legality_Linked_Predicate_Invariant_Error =>
            return To_Unbounded_String ("predicate or invariant use-site legality reports an error");
         when Record_Aggregate_Legality_Linked_Representation_Error =>
            return To_Unbounded_String ("representation/layout legality reports an error");
         when Record_Aggregate_Legality_Private_View_Barrier =>
            return To_Unbounded_String ("private view prevents aggregate legality closure");
         when Record_Aggregate_Legality_Limited_View_Barrier =>
            return To_Unbounded_String ("limited view prevents aggregate legality closure");
         when Record_Aggregate_Legality_Cross_Unit_Unresolved_View =>
            return To_Unbounded_String ("cross-unit view is unresolved for aggregate legality");
         when Record_Aggregate_Legality_Indeterminate | Record_Aggregate_Legality_Not_Checked =>
            return To_Unbounded_String ("record/variant aggregate legality is indeterminate");
      end case;
   end Make_Message;

   function To_Legality
     (Id   : Record_Aggregate_Legality_Id;
      Info : Record_Aggregate_Context_Info) return Record_Aggregate_Legality_Info is
      Status : constant Record_Aggregate_Legality_Status := Classify (Info);
      FP     : Natural := Info.Source_Fingerprint;
      Result : Record_Aggregate_Legality_Info;
   begin
      FP := Mix (FP, Natural (Id));
      FP := Mix (FP, Natural (Info.Id));
      FP := Mix (FP, Node_Fp (Info.Node));
      FP := Mix (FP, Record_Aggregate_Legality_Status'Pos (Status));
      FP := Mix (FP, Info.Component_Count + Info.Discriminant_Count + Info.Variant_Choice_Count);

      Result.Id := Id;
      Result.Context := Info.Id;
      Result.Kind := Info.Kind;
      Result.Node := Info.Node;
      Result.Aggregate_Node := Info.Aggregate_Node;
      Result.Type_Name := Info.Type_Name;
      Result.Status := Status;
      Result.Message := Make_Message (Status);
      Result.Detail := To_Unbounded_String
        ("components=" & Natural'Image (Info.Component_Count) &
         ", expected_components=" & Natural'Image (Info.Expected_Component_Count) &
         ", discriminants=" & Natural'Image (Info.Discriminant_Count) &
         ", variant_choices=" & Natural'Image (Info.Variant_Choice_Count));
      Result.Aggregate_Status := Info.Aggregate_Status;
      Result.Predicate_Status := Info.Predicate_Status;
      Result.Representation_Status := Info.Representation_Status;
      Result.Component_Count := Info.Component_Count;
      Result.Expected_Component_Count := Info.Expected_Component_Count;
      Result.Discriminant_Count := Info.Discriminant_Count;
      Result.Expected_Discriminant_Count := Info.Expected_Discriminant_Count;
      Result.Variant_Choice_Count := Info.Variant_Choice_Count;
      Result.Expected_Variant_Choice_Count := Info.Expected_Variant_Choice_Count;
      Result.Start_Line := Info.Start_Line;
      Result.Start_Column := Info.Start_Column;
      Result.End_Line := Info.End_Line;
      Result.End_Column := Info.End_Column;
      Result.Source_Fingerprint := Info.Source_Fingerprint;
      Result.Fingerprint := FP;
      return Result;
   end To_Legality;

   procedure Clear (Model : in out Record_Aggregate_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Record_Aggregate_Context_Model;
      Info  : Record_Aggregate_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Node_Fp (Info.Node) + Info.Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Record_Aggregate_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Record_Aggregate_Context_Model;
      Index : Positive) return Record_Aggregate_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Record_Aggregate_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Record_Aggregate_Context_Model) return Record_Aggregate_Legality_Model is
      Model : Record_Aggregate_Legality_Model;
      Next  : Natural := 1;
   begin
      for C of Contexts.Contexts loop
         declare
            Row : constant Record_Aggregate_Legality_Info :=
              To_Legality (Record_Aggregate_Legality_Id (Next), C);
         begin
            Model.Items.Append (Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
            if Is_Legal (Row.Status) then
               Model.Legal_Total := Model.Legal_Total + 1;
            else
               Model.Error_Total := Model.Error_Total + 1;
            end if;
            if Is_Variant_Error (Row.Status) then
               Model.Variant_Error_Total := Model.Variant_Error_Total + 1;
            end if;
            if Is_Discriminant_Error (Row.Status) then
               Model.Discriminant_Error_Total := Model.Discriminant_Error_Total + 1;
            end if;
            if Is_Linked_Error (Row.Status) then
               Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
            end if;
            if Row.Status = Record_Aggregate_Legality_Indeterminate then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            end if;
         end;
         Next := Next + 1;
      end loop;
      return Model;
   end Build;

   function Legality_Count (Model : Record_Aggregate_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Record_Aggregate_Legality_Model;
      Index : Positive) return Record_Aggregate_Legality_Info is
   begin
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Record_Aggregate_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Record_Aggregate_Legality_Info is
   begin
      for Item of Model.Items loop
         if Item.Node = Node then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Record_Aggregate_Legality_Model;
      Status : Record_Aggregate_Legality_Status) return Record_Aggregate_Result_Set is
      Results : Record_Aggregate_Result_Set;
   begin
      for Item of Model.Items loop
         if Item.Status = Status then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Record_Aggregate_Legality_Model;
      Kind  : Record_Aggregate_Context_Kind) return Record_Aggregate_Result_Set is
      Results : Record_Aggregate_Result_Set;
   begin
      for Item of Model.Items loop
         if Item.Kind = Kind then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Type
     (Model     : Record_Aggregate_Legality_Model;
      Type_Name : String) return Record_Aggregate_Result_Set is
      Results : Record_Aggregate_Result_Set;
   begin
      for Item of Model.Items loop
         if To_String (Item.Type_Name) = Type_Name then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Type;

   function Result_Count (Results : Record_Aggregate_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Record_Aggregate_Result_Set;
      Index   : Positive) return Record_Aggregate_Legality_Info is
   begin
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Record_Aggregate_Legality_Model;
      Status : Record_Aggregate_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Item of Model.Items loop
         if Item.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Record_Aggregate_Legality_Model;
      Kind  : Record_Aggregate_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Item of Model.Items loop
         if Item.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Record_Aggregate_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Record_Aggregate_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Variant_Error_Count (Model : Record_Aggregate_Legality_Model) return Natural is
   begin
      return Model.Variant_Error_Total;
   end Variant_Error_Count;

   function Discriminant_Error_Count (Model : Record_Aggregate_Legality_Model) return Natural is
   begin
      return Model.Discriminant_Error_Total;
   end Discriminant_Error_Count;

   function Linked_Error_Count (Model : Record_Aggregate_Legality_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Record_Aggregate_Legality_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Record_Aggregate_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Record_Aggregate_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Record_Aggregate_Legality;
   end Has_Legality;

end Editor.Ada_Record_Variant_Aggregate_Legality;
