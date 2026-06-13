with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Discriminant_Variant_AST_Repair_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 2_147_483_647;
   end Mix;

   function Map_Construct
     (Construct : Audit.Ada_Construct_Kind) return Discriminant_Variant_AST_Construct_Kind is
   begin
      case Construct is
         when Audit.Construct_Discriminant_Specification =>
            return Discriminant_Variant_AST_Discriminant_Specification;
         when Audit.Construct_Variant_Part =>
            return Discriminant_Variant_AST_Variant_Part;
         when Audit.Construct_Record_Aggregate | Audit.Construct_Extension_Aggregate =>
            return Discriminant_Variant_AST_Discriminant_Dependent_Aggregate;
         when Audit.Construct_Conversion | Audit.Construct_Qualified_Expression =>
            return Discriminant_Variant_AST_Private_Full_View;
         when others =>
            return Discriminant_Variant_AST_Unknown;
      end case;
   end Map_Construct;

   function Is_Discriminant_Variant_Construct
     (Construct : Audit.Ada_Construct_Kind) return Boolean is
   begin
      return Map_Construct (Construct) /= Discriminant_Variant_AST_Unknown;
   end Is_Discriminant_Variant_Construct;

   function Legal_Status
     (Construct : Discriminant_Variant_AST_Construct_Kind)
      return Discriminant_Variant_AST_Repair_Status is
   begin
      case Construct is
         when Discriminant_Variant_AST_Discriminant_Specification =>
            return Discriminant_Variant_AST_Legal_Discriminant_Specification_Repaired;
         when Discriminant_Variant_AST_Variant_Part =>
            return Discriminant_Variant_AST_Legal_Variant_Part_Repaired;
         when Discriminant_Variant_AST_Discriminant_Dependent_Aggregate =>
            return Discriminant_Variant_AST_Legal_Discriminant_Dependent_Aggregate_Repaired;
         when Discriminant_Variant_AST_Private_Full_View =>
            return Discriminant_Variant_AST_Legal_Private_Full_View_Repaired;
         when Discriminant_Variant_AST_Unknown =>
            return Discriminant_Variant_AST_Indeterminate;
      end case;
   end Legal_Status;

   function Needs_Staticness_Metadata
     (Construct : Discriminant_Variant_AST_Construct_Kind) return Boolean is
   begin
      return Construct in Discriminant_Variant_AST_Discriminant_Specification | Discriminant_Variant_AST_Variant_Part;
   end Needs_Staticness_Metadata;

   function Needs_Contract_Metadata
     (Construct : Discriminant_Variant_AST_Construct_Kind) return Boolean is
   begin
      return Construct in
        Discriminant_Variant_AST_Discriminant_Dependent_Aggregate |
        Discriminant_Variant_AST_Private_Full_View;
   end Needs_Contract_Metadata;

   function Classify
     (Info : Discriminant_Variant_AST_Repair_Context_Info)
      return Discriminant_Variant_AST_Repair_Status is
      Missing_Core : Natural := 0;
   begin
      if Info.Construct = Discriminant_Variant_AST_Unknown then
         return Discriminant_Variant_AST_Indeterminate;
      end if;

      if not Info.Parser_Node_Repaired then
         Missing_Core := Missing_Core + 1;
      end if;
      if not Info.Structural_AST_Repaired then
         Missing_Core := Missing_Core + 1;
      end if;
      if not Info.Source_Span_Repaired then
         Missing_Core := Missing_Core + 1;
      end if;
      if not Info.Name_Binding_Repaired then
         Missing_Core := Missing_Core + 1;
      end if;
      if not Info.Type_Metadata_Repaired then
         Missing_Core := Missing_Core + 1;
      end if;
      if Needs_Staticness_Metadata (Info.Construct)
        and then not Info.Staticness_Metadata_Repaired
      then
         Missing_Core := Missing_Core + 1;
      end if;
      if Needs_Contract_Metadata (Info.Construct)
        and then not Info.Contract_Metadata_Repaired
      then
         Missing_Core := Missing_Core + 1;
      end if;
      if not Info.Flow_Metadata_Repaired then
         Missing_Core := Missing_Core + 1;
      end if;
      if not Info.Representation_Metadata_Repaired then
         Missing_Core := Missing_Core + 1;
      end if;
      if not Info.Consumer_Integrated then
         Missing_Core := Missing_Core + 1;
      end if;

      if Missing_Core > 1 then
         return Discriminant_Variant_AST_Multiple_Repair_Blockers;
      end if;

      if not Info.Parser_Node_Repaired then
         return Discriminant_Variant_AST_Parser_Node_Still_Missing;
      elsif not Info.Structural_AST_Repaired then
         return Discriminant_Variant_AST_Structural_AST_Still_Missing;
      elsif not Info.Source_Span_Repaired then
         return Discriminant_Variant_AST_Source_Span_Still_Missing;
      elsif not Info.Token_Only_Replaced then
         return Discriminant_Variant_AST_Token_Only_Parse_Still_Present;
      elsif not Info.Degradation_Replaced then
         return Discriminant_Variant_AST_Degradation_Only_Path_Still_Present;
      elsif not Info.Name_Binding_Repaired then
         return Discriminant_Variant_AST_Name_Binding_Still_Missing;
      elsif not Info.Type_Metadata_Repaired then
         return Discriminant_Variant_AST_Type_Metadata_Still_Missing;
      elsif Needs_Staticness_Metadata (Info.Construct)
        and then not Info.Staticness_Metadata_Repaired
      then
         return Discriminant_Variant_AST_Staticness_Metadata_Still_Missing;
      elsif Needs_Contract_Metadata (Info.Construct)
        and then not Info.Contract_Metadata_Repaired
      then
         return Discriminant_Variant_AST_Contract_Metadata_Still_Missing;
      elsif not Info.Flow_Metadata_Repaired then
         return Discriminant_Variant_AST_Flow_Metadata_Still_Missing;
      elsif not Info.Representation_Metadata_Repaired then
         return Discriminant_Variant_AST_Representation_Metadata_Still_Missing;
      elsif not Info.Cross_Unit_Metadata_Repaired then
         return Discriminant_Variant_AST_Cross_Unit_Metadata_Still_Missing;
      elsif not Info.Consumer_Repaired then
         return Discriminant_Variant_AST_Consumer_Still_Missing;
      elsif not Info.Consumer_Integrated then
         return Discriminant_Variant_AST_Consumer_Still_Not_Integrated;
      else
         return Legal_Status (Info.Construct);
      end if;
   end Classify;

   function Message_For (Status : Discriminant_Variant_AST_Repair_Status) return String is
   begin
      case Status is
         when Discriminant_Variant_AST_Legal_Discriminant_Specification_Repaired =>
            return "discriminant specification AST coverage repaired";
         when Discriminant_Variant_AST_Legal_Variant_Part_Repaired =>
            return "variant part AST coverage repaired";
         when Discriminant_Variant_AST_Legal_Discriminant_Dependent_Aggregate_Repaired =>
            return "discriminant-dependent aggregate AST coverage repaired";
         when Discriminant_Variant_AST_Legal_Private_Full_View_Repaired =>
            return "private/full-view discriminant view AST coverage repaired";
         when Discriminant_Variant_AST_Parser_Node_Still_Missing =>
            return "discriminant/variant parser node is still missing";
         when Discriminant_Variant_AST_Structural_AST_Still_Missing =>
            return "discriminant/variant structural AST shape is still missing";
         when Discriminant_Variant_AST_Source_Span_Still_Missing =>
            return "discriminant/variant source span is still missing";
         when Discriminant_Variant_AST_Name_Binding_Still_Missing =>
            return "discriminant/variant name-binding metadata is still missing";
         when Discriminant_Variant_AST_Type_Metadata_Still_Missing =>
            return "discriminant/variant type metadata is still missing";
         when Discriminant_Variant_AST_Staticness_Metadata_Still_Missing =>
            return "discriminant/variant staticness metadata is still missing";
         when Discriminant_Variant_AST_Contract_Metadata_Still_Missing =>
            return "discriminant/variant contract metadata is still missing";
         when Discriminant_Variant_AST_Flow_Metadata_Still_Missing =>
            return "discriminant/variant flow metadata is still missing";
         when Discriminant_Variant_AST_Representation_Metadata_Still_Missing =>
            return "discriminant/variant representation/freezing metadata is still missing";
         when Discriminant_Variant_AST_Cross_Unit_Metadata_Still_Missing =>
            return "discriminant/variant cross-unit metadata is still missing";
         when Discriminant_Variant_AST_Consumer_Still_Missing =>
            return "discriminant/variant semantic consumer is still missing";
         when Discriminant_Variant_AST_Consumer_Still_Not_Integrated =>
            return "discriminant/variant semantic consumer is still not integrated";
         when Discriminant_Variant_AST_Token_Only_Parse_Still_Present =>
            return "discriminant/variant token-only parse is still present";
         when Discriminant_Variant_AST_Degradation_Only_Path_Still_Present =>
            return "discriminant/variant graceful degradation path is still the only path";
         when Discriminant_Variant_AST_Repair_Mismatch =>
            return "discriminant/variant AST repair is mismatched";
         when Discriminant_Variant_AST_Multiple_Repair_Blockers =>
            return "discriminant/variant AST repair has multiple blockers";
         when Discriminant_Variant_AST_Indeterminate =>
            return "discriminant/variant AST repair is indeterminate";
         when Discriminant_Variant_AST_Not_Checked =>
            return "discriminant/variant AST repair not checked";
      end case;
   end Message_For;

   function Make_Row
     (Info : Discriminant_Variant_AST_Repair_Context_Info)
      return Discriminant_Variant_AST_Repair_Info is
      Status : constant Discriminant_Variant_AST_Repair_Status := Classify (Info);
      Row    : Discriminant_Variant_AST_Repair_Info;
      FP     : Natural := Info.Source_Fingerprint;
   begin
      FP := Mix (FP, Discriminant_Variant_AST_Construct_Kind'Pos (Info.Construct));
      FP := Mix (FP, Discriminant_Variant_AST_Repair_Status'Pos (Status));
      FP := Mix (FP, Audit.Semantic_Consumer_Family'Pos (Info.Consumer));
      FP := Mix (FP, Natural (Info.Node));
      FP := Mix (FP, Natural (Info.Id));

      Row.Id := Info.Id;
      Row.Construct := Info.Construct;
      Row.Audit_Construct := Info.Audit_Construct;
      Row.Consumer := Info.Consumer;
      Row.Node := Info.Node;
      Row.Parent_Node := Info.Parent_Node;
      Row.Status := Status;
      Row.Construct_Name := Info.Construct_Name;
      Row.Normalized_Construct_Name := Info.Normalized_Construct_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String
        ("construct=" & To_String (Info.Construct_Name) &
         "; normalized=" & To_String (Info.Normalized_Construct_Name));
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      Row.Fingerprint := FP;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Discriminant_Variant_AST_Repair_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Discriminant_Variant_AST_Repair_Context_Model;
      Context : Discriminant_Variant_AST_Repair_Context_Info) is
      C : Discriminant_Variant_AST_Repair_Context_Info := Context;
   begin
      if C.Id = No_Discriminant_Variant_AST_Repair_Row then
         C.Id := Discriminant_Variant_AST_Repair_Row_Id (Natural (Model.Contexts.Length) + 1);
      end if;
      if C.Construct = Discriminant_Variant_AST_Unknown then
         C.Construct := Map_Construct (C.Audit_Construct);
      end if;
      Model.Contexts.Append (C);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (C.Id));
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint, Discriminant_Variant_AST_Construct_Kind'Pos (C.Construct));
   end Add_Context;

   procedure Apply_Repair_Row
     (Context : in out Discriminant_Variant_AST_Repair_Context_Info;
      Row     : Repair.Repair_Info) is
   begin
      Context.Source_Fingerprint := Mix
        (Context.Source_Fingerprint, Row.Source_Fingerprint);

      case Row.Kind is
         when Repair.Repair_Parser_Node =>
            Context.Parser_Node_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Structural_AST =>
            Context.Structural_AST_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Source_Span =>
            Context.Source_Span_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Name_Binding_Metadata =>
            Context.Name_Binding_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Type_Metadata =>
            Context.Type_Metadata_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Staticness_Metadata =>
            Context.Staticness_Metadata_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Contract_Metadata =>
            Context.Contract_Metadata_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Flow_Metadata =>
            Context.Flow_Metadata_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Representation_Metadata =>
            Context.Representation_Metadata_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Cross_Unit_Metadata =>
            Context.Cross_Unit_Metadata_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Semantic_Consumer =>
            Context.Consumer_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Consumer_Integration =>
            Context.Consumer_Integrated := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Token_Only_Replacement =>
            Context.Token_Only_Replaced := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Degradation_Replacement =>
            Context.Degradation_Replaced := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Combined_Construct_Coverage =>
            if Repair.Is_Repaired (Row.Status) then
               Context.Parser_Node_Repaired := True;
               Context.Structural_AST_Repaired := True;
               Context.Source_Span_Repaired := True;
               Context.Name_Binding_Repaired := True;
               Context.Type_Metadata_Repaired := True;
               Context.Staticness_Metadata_Repaired := True;
               Context.Contract_Metadata_Repaired := True;
               Context.Flow_Metadata_Repaired := True;
               Context.Representation_Metadata_Repaired := True;
               Context.Cross_Unit_Metadata_Repaired := True;
               Context.Consumer_Repaired := True;
               Context.Consumer_Integrated := True;
               Context.Token_Only_Replaced := True;
               Context.Degradation_Replaced := True;
            end if;
         when Repair.Repair_Unknown =>
            null;
      end case;
   end Apply_Repair_Row;

   function Build_From_Repairs
     (Repairs : Repair.Repair_Model) return Discriminant_Variant_AST_Repair_Model is
      Contexts : Discriminant_Variant_AST_Repair_Context_Model;
   begin
      for I in 1 .. Repair.Repair_Count (Repairs) loop
         declare
            Row : constant Repair.Repair_Info := Repair.Repair_At (Repairs, I);
            Found : Boolean := False;
         begin
            if Is_Discriminant_Variant_Construct (Row.Construct) then
               for J in 1 .. Natural (Contexts.Contexts.Length) loop
                  declare
                     C : Discriminant_Variant_AST_Repair_Context_Info := Contexts.Contexts.Element (J);
                  begin
                     if C.Node = Row.Node then
                        Apply_Repair_Row (C, Row);
                        Contexts.Contexts.Replace_Element (J, C);
                        Found := True;
                        exit;
                     end if;
                  end;
               end loop;

               if not Found then
                  declare
                     C : Discriminant_Variant_AST_Repair_Context_Info;
                  begin
                     C.Id := Discriminant_Variant_AST_Repair_Row_Id (Natural (Contexts.Contexts.Length) + 1);
                     C.Construct := Map_Construct (Row.Construct);
                     C.Audit_Construct := Row.Construct;
                     C.Consumer := Row.Consumer;
                     C.Node := Row.Node;
                     C.Parent_Node := Row.Parent_Node;
                     C.Construct_Name := Row.Construct_Name;
                     C.Normalized_Construct_Name := Row.Normalized_Construct_Name;
                     C.Start_Line := Row.Start_Line;
                     C.Start_Column := Row.Start_Column;
                     C.End_Line := Row.End_Line;
                     C.End_Column := Row.End_Column;
                     Apply_Repair_Row (C, Row);
                     Contexts.Contexts.Append (C);
                  end;
               end if;
            end if;
         end;
      end loop;
      return Build (Contexts);
   end Build_From_Repairs;

   function Build
     (Contexts : Discriminant_Variant_AST_Repair_Context_Model)
      return Discriminant_Variant_AST_Repair_Model is
      Model : Discriminant_Variant_AST_Repair_Model;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            Row : constant Discriminant_Variant_AST_Repair_Info :=
              Make_Row (Contexts.Contexts.Element (I));
         begin
            Model.Items.Append (Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
            if Is_Accepted (Row.Status) then
               Model.Accepted_Total := Model.Accepted_Total + 1;
            elsif Row.Status = Discriminant_Variant_AST_Indeterminate then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            else
               Model.Blocker_Total := Model.Blocker_Total + 1;
            end if;
         end;
      end loop;
      return Model;
   end Build;

   function Context_Count (Model : Discriminant_Variant_AST_Repair_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Row_Count (Model : Discriminant_Variant_AST_Repair_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Discriminant_Variant_AST_Repair_Model;
      Index : Positive) return Discriminant_Variant_AST_Repair_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Discriminant_Variant_AST_Repair_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Discriminant_Variant_AST_Repair_Info is
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         if Model.Items.Element (I).Node = Node then
            return Model.Items.Element (I);
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Discriminant_Variant_AST_Repair_Model;
      Status : Discriminant_Variant_AST_Repair_Status) return Discriminant_Variant_AST_Repair_Result_Set is
      Results : Discriminant_Variant_AST_Repair_Result_Set;
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         if Model.Items.Element (I).Status = Status then
            Results.Items.Append (Model.Items.Element (I));
            Results.Result_Fingerprint := Mix
              (Results.Result_Fingerprint, Model.Items.Element (I).Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Construct
     (Model     : Discriminant_Variant_AST_Repair_Model;
      Construct : Discriminant_Variant_AST_Construct_Kind) return Discriminant_Variant_AST_Repair_Result_Set is
      Results : Discriminant_Variant_AST_Repair_Result_Set;
   begin
      for I in 1 .. Natural (Model.Items.Length) loop
         if Model.Items.Element (I).Construct = Construct then
            Results.Items.Append (Model.Items.Element (I));
            Results.Result_Fingerprint := Mix
              (Results.Result_Fingerprint, Model.Items.Element (I).Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Construct;

   function Result_Count (Results : Discriminant_Variant_AST_Repair_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Discriminant_Variant_AST_Repair_Result_Set;
      Index   : Positive) return Discriminant_Variant_AST_Repair_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model : Discriminant_Variant_AST_Repair_Model;
      Status : Discriminant_Variant_AST_Repair_Status) return Natural is
   begin
      return Result_Count (Rows_For_Status (Model, Status));
   end Count_Status;

   function Count_Construct
     (Model : Discriminant_Variant_AST_Repair_Model;
      Construct : Discriminant_Variant_AST_Construct_Kind) return Natural is
   begin
      return Result_Count (Rows_For_Construct (Model, Construct));
   end Count_Construct;

   function Accepted_Count (Model : Discriminant_Variant_AST_Repair_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocker_Count (Model : Discriminant_Variant_AST_Repair_Model) return Natural is
   begin
      return Model.Blocker_Total;
   end Blocker_Count;

   function Indeterminate_Count (Model : Discriminant_Variant_AST_Repair_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Discriminant_Variant_AST_Repair_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Is_Accepted (Status : Discriminant_Variant_AST_Repair_Status) return Boolean is
   begin
      return Status in
        Discriminant_Variant_AST_Legal_Discriminant_Specification_Repaired |
        Discriminant_Variant_AST_Legal_Variant_Part_Repaired |
        Discriminant_Variant_AST_Legal_Discriminant_Dependent_Aggregate_Repaired |
        Discriminant_Variant_AST_Legal_Private_Full_View_Repaired;
   end Is_Accepted;

   function Has_Error (Info : Discriminant_Variant_AST_Repair_Info) return Boolean is
   begin
      return not Is_Accepted (Info.Status)
        and then Info.Status /= Discriminant_Variant_AST_Not_Checked;
   end Has_Error;

end Editor.Ada_Discriminant_Variant_AST_Repair_Legality;
