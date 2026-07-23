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
   procedure Apply_Operator_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Symbol : constant String := Operator_Symbol_From_Text (To_String (Node.Label));
      Left_U : Ada.Strings.Unbounded.Unbounded_String :=
        To_Unbounded_String
          (Infer_Operand_Subtype (Tree, Regions, Visibility, Types, Static, Calls, Node, 1));
      Right_U : Ada.Strings.Unbounded.Unbounded_String :=
        To_Unbounded_String
          (Infer_Operand_Subtype (Tree, Regions, Visibility, Types, Static, Calls, Node, 2));
      NL     : Ada.Strings.Unbounded.Unbounded_String;
      NR     : Ada.Strings.Unbounded.Unbounded_String;
      Has_Right : Boolean := False;
   begin
      Info.Operator_Status := Operator_Type_Not_Operator;
      if Symbol = "" then
         return;
      end if;

      if To_String (Left_U) = "" or else To_String (Right_U) = "" then
         declare
            Text : constant String := To_String (Node.Label);
            NText : constant String := Normalize (Text);
            Mark : constant String := " " & Normalize (Symbol) & " ";
            Pos : constant Natural := Ada.Strings.Fixed.Index (NText, Mark);
         begin
            if Pos /= 0 then
               if To_String (Left_U) = "" and then Pos > Text'First then
                  Left_U := To_Unbounded_String
                    (Lookup_Operand_Subtype_Text
                       (Tree, Regions, Visibility, Static, Info.Region,
                        Text (Text'First .. Pos - 1)));
               end if;
               if To_String (Right_U) = "" and then Pos + Mark'Length <= Text'Last then
                  Right_U := To_Unbounded_String
                    (Lookup_Operand_Subtype_Text
                       (Tree, Regions, Visibility, Static, Info.Region,
                        Text (Pos + Mark'Length .. Text'Last)));
               end if;
            end if;
         end;
      end if;

      NL := To_Unbounded_String (Normalize (To_String (Left_U)));
      NR := To_Unbounded_String (Normalize (To_String (Right_U)));
      Has_Right := To_String (Right_U) /= "";

      Info.Operator_Status := Operator_Type_Not_Checked;
      Info.Operator_Symbol := To_Unbounded_String (Symbol);
      Info.Left_Operand_Subtype := Left_U;
      Info.Right_Operand_Subtype := Right_U;
      Info.Normalized_Left_Operand_Subtype := NL;
      Info.Normalized_Right_Operand_Subtype := NR;

      if To_String (Left_U) = "ambiguous" or else To_String (Right_U) = "ambiguous" then
         Info.Operator_Status := Operator_Type_Ambiguous;
         Info.Status := Expression_Type_Operator_Unknown;
         Info.Candidate_Count := 2;
         return;
      elsif To_String (Left_U) = "" and then not (Symbol = "+" or else Symbol = "-" or else Symbol = "not") then
         Info.Operator_Status := Operator_Type_Operand_Unknown;
         Info.Operator_Unknown_Operand_Count := 1;
         Info.Status := Expression_Type_Operator_Unknown;
         return;
      elsif Has_Right and then To_String (Right_U) = "" then
         Info.Operator_Status := Operator_Type_Operand_Unknown;
         Info.Operator_Unknown_Operand_Count := 1;
         Info.Status := Expression_Type_Operator_Unknown;
         return;
      end if;

      if Is_Boolean_Operator (Symbol) then
         if (To_String (Left_U) = "" or else To_String (NL) = "boolean") and then
           (not Has_Right or else To_String (NR) = "boolean" or else To_String (Right_U) = "")
         then
            Info.Operator_Status := Operator_Type_Resolved_Predefined;
            Info.Operator_Compatible_Operand_Count := (if Has_Right then 2 else 1);
            Info.Status := Expression_Type_Operator_Boolean;
            Info.Operator_Result_Subtype := To_Unbounded_String ("Boolean");
            Info.Normalized_Operator_Result_Subtype := To_Unbounded_String ("boolean");
            Info.Inferred_Subtype := Info.Operator_Result_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Operator_Result_Subtype;
         else
            Info.Operator_Status := Operator_Type_Operand_Mismatch;
            Info.Operator_Mismatched_Operand_Count := 1;
            Info.Status := Expression_Type_Operator_Unknown;
         end if;
      elsif Is_Relational_Operator (Symbol) then
         if Has_Right and then (To_String (NL) = To_String (NR) or else
           (Is_Numeric_Family (To_String (Left_U)) and then Is_Numeric_Family (To_String (Right_U))))
         then
            Info.Operator_Status := Operator_Type_Resolved_Predefined;
            Info.Operator_Compatible_Operand_Count := 2;
            Info.Status := Expression_Type_Operator_Boolean;
            Info.Operator_Result_Subtype := To_Unbounded_String ("Boolean");
            Info.Normalized_Operator_Result_Subtype := To_Unbounded_String ("boolean");
            Info.Inferred_Subtype := Info.Operator_Result_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Operator_Result_Subtype;
         elsif not Has_Right or else To_String (Right_U) = "" then
            Info.Operator_Status := Operator_Type_Operand_Unknown;
            Info.Operator_Unknown_Operand_Count := 1;
         else
            Info.Operator_Status := Operator_Type_Operand_Mismatch;
            Info.Operator_Mismatched_Operand_Count := 1;
            Info.Status := Expression_Type_Operator_Unknown;
         end if;
      elsif Is_Numeric_Operator (Symbol) then
         if (To_String (Left_U) = "" or else Is_Numeric_Family (To_String (Left_U))) and then
           (not Has_Right or else Is_Numeric_Family (To_String (Right_U)))
         then
            Info.Operator_Status := Operator_Type_Resolved_Predefined;
            Info.Operator_Compatible_Operand_Count := (if Has_Right then 2 else 1);
            if Is_Real_Family (To_String (Left_U)) or else Is_Real_Family (To_String (Right_U)) or else Looks_Real (To_String (Node.Label)) then
               Info.Operator_Result_Subtype := To_Unbounded_String ("Universal_Real");
               Info.Normalized_Operator_Result_Subtype := To_Unbounded_String ("universal_real");
            else
               Info.Operator_Result_Subtype := To_Unbounded_String ("Universal_Integer");
               Info.Normalized_Operator_Result_Subtype := To_Unbounded_String ("universal_integer");
            end if;
            Info.Status := Expression_Type_Operator_Numeric;
            Info.Inferred_Subtype := Info.Operator_Result_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Operator_Result_Subtype;
         else
            Info.Operator_Status := Operator_Type_Operand_Mismatch;
            Info.Operator_Mismatched_Operand_Count := 1;
            Info.Status := Expression_Type_Operator_Unknown;
         end if;
      else
         Info.Operator_Status := Operator_Type_Result_Unknown;
         Info.Operator_Unknown_Operand_Count := 1;
         Info.Status := Expression_Type_Operator_Unknown;
      end if;
   end Apply_Operator_Inference;
