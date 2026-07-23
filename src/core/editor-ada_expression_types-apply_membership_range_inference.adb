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
   procedure Apply_Membership_Range_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Text  : constant String := Normalize (To_String (Node.Label));
      Left  : constant String :=
        Infer_Operand_Subtype (Tree, Regions, Visibility, Types, Static, Calls, Node, 1);
      Right : constant String :=
        Infer_Operand_Subtype (Tree, Regions, Visibility, Types, Static, Calls, Node, 2);
      NL    : constant String := Normalize (Left);
      NR    : constant String := Normalize (Right);
   begin
      Info.Membership_Range_Status := Membership_Range_Not_Membership_Or_Range;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Membership_Expression then
         Info.Membership_Range_Status := Membership_Range_Membership_Unknown;
         Info.Membership_Test_Subtype := To_Unbounded_String (Left);
         Info.Normalized_Membership_Test_Subtype := To_Unbounded_String (NL);
         Info.Membership_Choice_Subtype := To_Unbounded_String (Right);
         Info.Normalized_Membership_Choice_Subtype := To_Unbounded_String (NR);
         Set_Boolean_Result (Info);
         Info.Membership_Range_Status := Membership_Range_Boolean_Result;

         if Left = "" or else Right = "" then
            if Looks_Range_Choice (Text) and then (Left /= "" or else Right /= "") then
               Info.Membership_Range_Status := Membership_Range_Membership_Compatible;
               Info.Membership_Compatible_Count := 1;
            else
               Info.Membership_Range_Status := Membership_Range_Membership_Unknown;
               Info.Membership_Unknown_Count := 1;
            end if;
         elsif Simple_Subtype_Compatible (Left, Right) then
            Info.Membership_Range_Status := Membership_Range_Membership_Compatible;
            Info.Membership_Compatible_Count := 1;
            Info.Operator_Compatible_Operand_Count := 2;
         else
            Info.Membership_Range_Status := Membership_Range_Membership_Mismatch;
            Info.Membership_Mismatch_Count := 1;
            Info.Operator_Mismatched_Operand_Count := 1;
         end if;

      elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Range_Expression then
         Info.Membership_Range_Status := Membership_Range_Range_Unknown;
         Info.Range_Low_Subtype := To_Unbounded_String (Left);
         Info.Range_High_Subtype := To_Unbounded_String (Right);
         Info.Normalized_Range_Low_Subtype := To_Unbounded_String (NL);
         Info.Normalized_Range_High_Subtype := To_Unbounded_String (NR);

         if Left = "" or else Right = "" then
            Info.Range_Unknown_Count := 1;
            Info.Inferred_Subtype := To_Unbounded_String ("range_bounds_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("range_bounds_unknown");
         elsif Simple_Subtype_Compatible (Left, Right) then
            Info.Membership_Range_Status := Membership_Range_Range_Compatible;
            Info.Range_Compatible_Count := 1;
            Info.Inferred_Subtype := To_Unbounded_String (Left);
            Info.Normalized_Subtype := To_Unbounded_String (NL);
         else
            Info.Membership_Range_Status := Membership_Range_Range_Mismatch;
            Info.Range_Mismatch_Count := 1;
            Info.Status := Expression_Type_Operator_Unknown;
         end if;
      end if;
   end Apply_Membership_Range_Inference;
