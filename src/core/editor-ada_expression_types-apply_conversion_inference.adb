with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Expression_Types.Cross_Unit_Selected_Subtype_Refinement;
with Editor.Ada_Expression_Types.Access_Text_Helpers;
with Editor.Ada_Expression_Types.Inference_Support;
with Editor.Ada_Expression_Types.Call_Inference;
with Editor.Ada_Expression_Types.Call_Text_Helpers;
with Editor.Ada_Expression_Types.Model_Accessors;
with Editor.Ada_Expression_Types.Operator_Helpers;
with Editor.Ada_Expression_Types.Statistics;
with Editor.Ada_Use_Type_Operators;
with Editor.Ada_Expression_Types.Status_Helpers;

separate (Editor.Ada_Expression_Types)
   procedure Apply_Conversion_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      pragma Unreferenced (Tree);
      Text : constant String := To_String (Node.Label);
      Target_U : Ada.Strings.Unbounded.Unbounded_String;
      Operand_Text_U : Ada.Strings.Unbounded.Unbounded_String;
      Operand_U : Ada.Strings.Unbounded.Unbounded_String;
      Region : constant Editor.Ada_Declarative_Regions.Region_Id := Info.Region;
      Target_Type : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Lookup : Editor.Ada_Direct_Visibility.Lookup_Result;
   begin
      Info.Conversion_Status := Conversion_Type_Not_Conversion;
      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Qualified_Expression then
         Target_U := To_Unbounded_String (Prefix_Before (Text, Character'Val (39)));
         Operand_Text_U := To_Unbounded_String (Suffix_After (Text, Character'Val (39)));
      elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call then
         Target_U := To_Unbounded_String (Extract_Designator_Before_Call (Text));
         Operand_Text_U := To_Unbounded_String (Extract_First_Actual_Text (Text));
      else
         return;
      end if;

      declare
         Target : constant String := To_String (Target_U);
         Operand_Text : constant String := To_String (Operand_Text_U);
      begin
      if Target = "" then
         Info.Conversion_Status := Conversion_Type_Malformed;
         return;
      end if;

      Info.Conversion_Target_Subtype := To_Unbounded_String (Target);
      Info.Normalized_Conversion_Target_Subtype := To_Unbounded_String (Normalize (Target));
      Target_Type := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Target);
      if Target_Type /= Editor.Ada_Type_Graph.No_Type then
         Info.Type_Id := Target_Type;
         Info.Status := (if Node.Kind = Editor.Ada_Syntax_Tree.Node_Qualified_Expression then
                            Expression_Type_Qualified else Expression_Type_Conversion);
         Info.Inferred_Subtype := To_Unbounded_String (Target);
         Info.Normalized_Subtype := To_Unbounded_String (Normalize (Target));
         Info.Conversion_Status := Conversion_Type_Target_Resolved;
      else
         Lookup := Editor.Ada_Direct_Visibility.Lookup_Visible
           (Visibility, Regions, Region, Target);
         Info.Candidate_Count := Lookup.Match_Count;
         if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
            Info.Conversion_Status := Conversion_Type_Target_Ambiguous;
            Info.Status := Expression_Type_Name_Ambiguous;
            return;
         elsif Lookup.Status /= Editor.Ada_Direct_Visibility.Lookup_Found then
            Info.Conversion_Status := Conversion_Type_Target_Unresolved;
            return;
         else
            Info.Declaration := Lookup.Declaration;
            Info.Type_Id := Editor.Ada_Type_Graph.Type_For_Declaration (Types, Lookup.Declaration);
            Info.Status := (if Node.Kind = Editor.Ada_Syntax_Tree.Node_Qualified_Expression then
                               Expression_Type_Qualified else Expression_Type_Conversion);
            Info.Inferred_Subtype := To_Unbounded_String (Target);
            Info.Normalized_Subtype := To_Unbounded_String (Normalize (Target));
            Info.Conversion_Status := Conversion_Type_Target_Resolved;
         end if;
      end if;

      Operand_U := To_Unbounded_String (Operand_Subtype_From_Text (Static, Region, Operand_Text));
      declare
         Operand : constant String := To_String (Operand_U);
      begin
      if Operand = "" and then Node.Kind = Editor.Ada_Syntax_Tree.Node_Qualified_Expression then
         --  Qualified expressions are context carriers; retain the resolved target even when
         --  the operand type is not locally derivable in this pass.
         Info.Conversion_Status := Conversion_Type_Target_Resolved;
         return;
      elsif Operand = "" then
         Info.Conversion_Status := Conversion_Type_Operand_Unknown;
         Info.Conversion_Unknown_Operand_Count := 1;
         return;
      end if;

      Info.Conversion_Operand_Subtype := To_Unbounded_String (Operand);
      Info.Normalized_Conversion_Operand_Subtype := To_Unbounded_String (Normalize (Operand));
      if Subtype_Compatible_By_Graph (Types, Region, Target, Operand) or else
        Normalize (Target) = Normalize (Operand) or else
        Is_Universal_Compatible (Normalize (Operand), Normalize (Target)) or else
        Universal_Compatible_By_Category (Types, Region, Operand, Target)
      then
         Info.Conversion_Status := Conversion_Type_Operand_Compatible;
         Info.Conversion_Compatible_Operand_Count := 1;
      elsif Is_Numeric_Family (Target) and then Is_Numeric_Family (Operand) then
         Info.Conversion_Status := Conversion_Type_Operand_Requires_Explicit_Conversion;
         Info.Conversion_Explicit_Operand_Count := 1;
      else
         Info.Conversion_Status := Conversion_Type_Operand_Mismatch;
         Info.Conversion_Mismatched_Operand_Count := 1;
      end if;
      end;
      end;
   end Apply_Conversion_Inference;
