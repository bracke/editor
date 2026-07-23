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
   procedure Apply_Boolean_Context_Inference
     (Info : in out Expression_Type_Info;
      N    : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Text : constant String := To_String (N.Label);
      Operand_Status : Boolean_Context_Inference_Status;
   begin
      Info.Boolean_Context_Status := Boolean_Context_Not_Boolean_Context;
      Info.Boolean_Context_Expected_Subtype := To_Unbounded_String ("Boolean");
      Info.Normalized_Boolean_Context_Expected_Subtype := To_Unbounded_String ("boolean");

      if not Looks_Like_Boolean_Context (N.Kind, Text) then
         return;
      end if;

      Info.Boolean_Context_Status := Boolean_Context_Expected_Boolean;

      if To_String (Info.Normalized_Subtype) /= "" then
         Info.Boolean_Context_Expression_Subtype := Info.Inferred_Subtype;
         Info.Normalized_Boolean_Context_Expression_Subtype := Info.Normalized_Subtype;
      elsif To_String (Info.Normalized_Expected_Subtype) /= "" then
         Info.Boolean_Context_Expression_Subtype := Info.Expected_Subtype;
         Info.Normalized_Boolean_Context_Expression_Subtype := Info.Normalized_Expected_Subtype;
      else
         Info.Boolean_Context_Expression_Subtype := To_Unbounded_String ("unknown");
         Info.Normalized_Boolean_Context_Expression_Subtype := To_Unbounded_String ("unknown");
      end if;

      Operand_Status := Boolean_Operand_Status
        (To_String (Info.Normalized_Boolean_Context_Expression_Subtype));

      if Operand_Status = Boolean_Context_Operand_Compatible then
         Info.Boolean_Context_Compatible_Count := Info.Boolean_Context_Compatible_Count + 1;
         if N.Kind = Editor.Ada_Syntax_Tree.Node_Short_Circuit_Expression or else
           Contains (Normalize (Text), " and then ") or else
           Contains (Normalize (Text), " or else ")
         then
            Info.Boolean_Context_Status := Boolean_Context_Short_Circuit_Compatible;
         else
            Info.Boolean_Context_Status := Boolean_Context_Condition_Compatible;
         end if;
      elsif Operand_Status = Boolean_Context_Operand_Mismatch then
         Info.Boolean_Context_Mismatch_Count := Info.Boolean_Context_Mismatch_Count + 1;
         if N.Kind = Editor.Ada_Syntax_Tree.Node_Short_Circuit_Expression or else
           Contains (Normalize (Text), " and then ") or else
           Contains (Normalize (Text), " or else ")
         then
            Info.Boolean_Context_Status := Boolean_Context_Short_Circuit_Mismatch;
         else
            Info.Boolean_Context_Status := Boolean_Context_Condition_Mismatch;
         end if;
      else
         Info.Boolean_Context_Unknown_Count := Info.Boolean_Context_Unknown_Count + 1;
         Info.Boolean_Context_Status := Boolean_Context_Condition_Unknown;
      end if;
   end Apply_Boolean_Context_Inference;
