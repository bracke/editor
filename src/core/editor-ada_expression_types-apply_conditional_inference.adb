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
   procedure Apply_Conditional_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Text      : constant String := To_String (Node.Label);
      Normal    : constant String := Normalize (Text);
      Expected  : constant String := To_String (Info.Expected_Subtype);
      NExpected : constant String := To_String (Info.Normalized_Expected_Subtype);
      Childs    : constant Natural := Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id);
      Known     : Natural := 0;
      Unknown   : Natural := 0;
      Mismatch  : Natural := 0;
      First_Subtype : Ada.Strings.Unbounded.Unbounded_String;

      function Branch_Subtype (Child_Index : Positive) return String is
         Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
           Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, Child_Index);
         Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
           Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
      begin
         return Infer_Operand_Subtype
           (Tree, Regions, Visibility, Types, Static, Calls, Child, 1);
      end Branch_Subtype;
   begin
      if not (Node.Kind = Editor.Ada_Syntax_Tree.Node_Conditional_Expression or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Case_Expression or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Quantified_Expression or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Declare_Expression or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Reduction_Expression)
      then
         Info.Conditional_Status := Conditional_Type_Not_Conditional;
         return;
      end if;

      Info.Status := Expression_Type_Indeterminate;
      Info.Conditional_Status := Conditional_Type_Branch_Unknown;
      Info.Conditional_Branch_Count := Childs;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Quantified_Expression then
         Info.Conditional_Status := Conditional_Type_Boolean_Result;
         Info.Inferred_Subtype := To_Unbounded_String ("Boolean");
         Info.Normalized_Subtype := To_Unbounded_String ("boolean");
         Info.Conditional_Result_Subtype := Info.Inferred_Subtype;
         Info.Normalized_Conditional_Result_Subtype := Info.Normalized_Subtype;
         Info.Conditional_Compatible_Branch_Count := 1;
         return;
      elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Reduction_Expression then
         Info.Conditional_Status := Conditional_Type_Reduction_Result;
         if NExpected /= "" then
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
         elsif Contains (Normal, "parallel_reduce") or else Contains (Normal, "reduce") then
            Info.Inferred_Subtype := To_Unbounded_String ("reduction_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("reduction_result_unknown");
            Info.Conditional_Unknown_Branch_Count := 1;
         end if;
         Info.Conditional_Result_Subtype := Info.Inferred_Subtype;
         Info.Normalized_Conditional_Result_Subtype := Info.Normalized_Subtype;
         return;
      elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Declare_Expression then
         Info.Conditional_Status := Conditional_Type_Declare_Result;
         if NExpected /= "" then
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            Info.Conditional_Compatible_Branch_Count := 1;
         else
            Info.Inferred_Subtype := To_Unbounded_String ("declare_expression_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("declare_expression_result_unknown");
            Info.Conditional_Unknown_Branch_Count := 1;
         end if;
         Info.Conditional_Result_Subtype := Info.Inferred_Subtype;
         Info.Normalized_Conditional_Result_Subtype := Info.Normalized_Subtype;
         return;
      end if;

      if NExpected /= "" then
         Info.Conditional_Status := Conditional_Type_Expected_Context;
         Info.Inferred_Subtype := Info.Expected_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
         Info.Conditional_Result_Subtype := Info.Expected_Subtype;
         Info.Normalized_Conditional_Result_Subtype := Info.Normalized_Expected_Subtype;
      end if;

      if Childs = 0 then
         if NExpected /= "" then
            Info.Conditional_Compatible_Branch_Count := 1;
            Info.Conditional_Status := Conditional_Type_Branches_Compatible;
         else
            Info.Conditional_Unknown_Branch_Count := 1;
            Info.Inferred_Subtype := To_Unbounded_String ("conditional_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("conditional_result_unknown");
            Info.Conditional_Result_Subtype := Info.Inferred_Subtype;
            Info.Normalized_Conditional_Result_Subtype := Info.Normalized_Subtype;
         end if;
         return;
      end if;

      for I in 1 .. Childs loop
         declare
            B : constant String := Branch_Subtype (I);
            NB : constant String := Normalize (B);
         begin
            if B = "" or else B = "ambiguous" then
               Unknown := Unknown + 1;
            elsif NExpected /= "" then
               if NB = NExpected or else Is_Universal_Compatible (NB, NExpected) then
                  Known := Known + 1;
               else
                  Mismatch := Mismatch + 1;
               end if;
            elsif To_String (First_Subtype) = "" then
               First_Subtype := To_Unbounded_String (B);
               Known := Known + 1;
            elsif NB = Normalize (To_String (First_Subtype)) or else
              (Is_Numeric_Family (B) and then Is_Numeric_Family (To_String (First_Subtype)))
            then
               Known := Known + 1;
            else
               Mismatch := Mismatch + 1;
            end if;
         end;
      end loop;

      Info.Conditional_Compatible_Branch_Count := Known;
      Info.Conditional_Mismatched_Branch_Count := Mismatch;
      Info.Conditional_Unknown_Branch_Count := Unknown;

      if Mismatch > 0 then
         Info.Conditional_Status := Conditional_Type_Branch_Mismatch;
      elsif Unknown > 0 then
         Info.Conditional_Status := Conditional_Type_Branch_Unknown;
      else
         Info.Conditional_Status := Conditional_Type_Branches_Compatible;
      end if;

      if NExpected = "" and then To_String (First_Subtype) /= "" then
         Info.Inferred_Subtype := First_Subtype;
         Info.Normalized_Subtype := To_Unbounded_String (Normalize (To_String (First_Subtype)));
         Info.Conditional_Result_Subtype := Info.Inferred_Subtype;
         Info.Normalized_Conditional_Result_Subtype := Info.Normalized_Subtype;
      end if;
   end Apply_Conditional_Inference;
