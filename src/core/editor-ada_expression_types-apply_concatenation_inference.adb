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
   procedure Apply_Concatenation_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Info       : in out Expression_Type_Info)
   is
      Symbol : constant String := To_String (Info.Operator_Symbol);
      Left_Text_U : Ada.Strings.Unbounded.Unbounded_String;
      Right_Text_U : Ada.Strings.Unbounded.Unbounded_String;
      Left_U : Ada.Strings.Unbounded.Unbounded_String := Info.Left_Operand_Subtype;
      Right_U : Ada.Strings.Unbounded.Unbounded_String := Info.Right_Operand_Subtype;
      Expected : constant String := To_String (Info.Expected_Subtype);
      NExpected : constant String := To_String (Info.Normalized_Expected_Subtype);
   begin
      Info.Concatenation_Status := Concatenation_Type_Not_Concatenation;
      if Symbol /= "&" then
         Split_Concatenation_Text (To_String (Info.Expression_Text), Left_Text_U, Right_Text_U);
         if To_String (Left_Text_U) = "" or else To_String (Right_Text_U) = "" then
            return;
         end if;
         Info.Operator_Symbol := To_Unbounded_String ("&");
      end if;

      if To_String (Left_U) = "" or else To_String (Right_U) = "" then
         if To_String (Left_Text_U) = "" and then To_String (Right_Text_U) = "" then
            Split_Concatenation_Text (To_String (Info.Expression_Text), Left_Text_U, Right_Text_U);
         end if;
         if To_String (Left_U) = "" then
           Left_U := To_Unbounded_String
              (Lookup_Operand_Subtype_Text
                 (Tree, Regions, Visibility, Static, Info.Region, To_String (Left_Text_U)));
         end if;
         if To_String (Right_U) = "" then
           Right_U := To_Unbounded_String
              (Lookup_Operand_Subtype_Text
                 (Tree, Regions, Visibility, Static, Info.Region, To_String (Right_Text_U)));
         end if;
      end if;

      declare
         Left   : constant String := To_String (Left_U);
         Right  : constant String := To_String (Right_U);
         NL     : constant String := Normalize (Left);
         NR     : constant String := Normalize (Right);
         Left_String : constant Boolean := Is_String_Family (NL);
         Right_String : constant Boolean := Is_String_Family (NR);
         Left_Char : constant Boolean := Is_Character_Family (NL);
         Right_Char : constant Boolean := Is_Character_Family (NR);
         Left_Array : constant Boolean := Is_Array_Family (Types, Info.Region, Left);
         Right_Array : constant Boolean := Is_Array_Family (Types, Info.Region, Right);
      begin
         Info.Concatenation_Status := Concatenation_Type_Result_Unknown;
         Info.Concatenation_Left_Subtype := Left_U;
         Info.Concatenation_Right_Subtype := Right_U;
         Info.Normalized_Concatenation_Left_Subtype := To_Unbounded_String (NL);
         Info.Normalized_Concatenation_Right_Subtype := To_Unbounded_String (NR);

      if Left = "" or else Right = "" or else Left = "ambiguous" or else Right = "ambiguous" then
         Info.Concatenation_Status := Concatenation_Type_Operand_Unknown;
         Info.Concatenation_Unknown_Count := 1;
         Info.Operator_Status := Operator_Type_Operand_Unknown;
         Info.Status := Expression_Type_Operator_Unknown;
         return;
      elsif (Left_String and then Right_String) or else
        (Left_String and then Right_Char) or else
        (Left_Char and then Right_String) or else
        (Left_Char and then Right_Char and then NExpected /= "")
      then
         if Left_Char and then Right_Char and then Is_String_Family (NExpected) then
            Info.Concatenation_Status := Concatenation_Type_Expected_Context_Result;
            Info.Concatenation_Result_Subtype := To_Unbounded_String (Expected);
            Info.Normalized_Concatenation_Result_Subtype := To_Unbounded_String (NExpected);
         else
            Info.Concatenation_Status :=
              (if Left_Char or else Right_Char then
                  Concatenation_Type_Character_String_Compatible
               else
                  Concatenation_Type_String_Compatible);
            Info.Concatenation_Result_Subtype := To_Unbounded_String ("String");
            Info.Normalized_Concatenation_Result_Subtype := To_Unbounded_String ("string");
         end if;
         Info.Concatenation_Compatible_Count := 1;
         Info.Operator_Status := Operator_Type_Resolved_Predefined;
         Info.Operator_Compatible_Operand_Count := 2;
         Info.Status := Expression_Type_Operator_Concatenation;
         Info.Operator_Result_Subtype := Info.Concatenation_Result_Subtype;
         Info.Normalized_Operator_Result_Subtype := Info.Normalized_Concatenation_Result_Subtype;
         Info.Inferred_Subtype := Info.Concatenation_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Concatenation_Result_Subtype;
      elsif Left_Array and then Right_Array and then
        (NL = NR or else NExpected /= "")
      then
         Info.Concatenation_Status :=
           (if NExpected /= "" then Concatenation_Type_Expected_Context_Result
            else Concatenation_Type_Array_Compatible);
         if NExpected /= "" then
            Info.Concatenation_Result_Subtype := To_Unbounded_String (Expected);
            Info.Normalized_Concatenation_Result_Subtype := To_Unbounded_String (NExpected);
         else
            Info.Concatenation_Result_Subtype := Left_U;
            Info.Normalized_Concatenation_Result_Subtype := To_Unbounded_String (NL);
         end if;
         Info.Concatenation_Compatible_Count := 1;
         Info.Operator_Status := Operator_Type_Resolved_Predefined;
         Info.Operator_Compatible_Operand_Count := 2;
         Info.Status := Expression_Type_Operator_Concatenation;
         Info.Operator_Result_Subtype := Info.Concatenation_Result_Subtype;
         Info.Normalized_Operator_Result_Subtype := Info.Normalized_Concatenation_Result_Subtype;
         Info.Inferred_Subtype := Info.Concatenation_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Concatenation_Result_Subtype;
      else
         Info.Concatenation_Status := Concatenation_Type_Operand_Mismatch;
         Info.Concatenation_Mismatch_Count := 1;
         Info.Operator_Status := Operator_Type_Operand_Mismatch;
         Info.Operator_Mismatched_Operand_Count := 1;
         Info.Status := Expression_Type_Operator_Unknown;
      end if;
      end;
   end Apply_Concatenation_Inference;
