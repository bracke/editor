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
   procedure Apply_Raise_No_Return_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Text    : constant String := To_String (Node.Label);
      Target  : constant String := Raise_Target_From_Text (Text);
      Message : constant String := Raise_Message_From_Text (Text);
   begin
      Info.Raise_No_Return_Status := Raise_No_Return_Not_Raise;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Raise_Statement or else
        Looks_Like_Raise_Text (Text)
      then
         Info.Status := Expression_Type_Raise;
         if Node.Kind = Editor.Ada_Syntax_Tree.Node_Raise_Statement then
            Info.Raise_No_Return_Status := Raise_No_Return_Raise_Statement;
         else
            Info.Raise_No_Return_Status := Raise_No_Return_Raise_Expression;
         end if;

         if Target /= "" then
            Info.Raise_Exception_Target := To_Unbounded_String (Target);
            Info.Normalized_Raise_Exception_Target := To_Unbounded_String (Normalize (Target));
            Info.Raise_No_Return_Status := Raise_No_Return_Exception_Target_Known;
         else
            Info.Raise_No_Return_Status := Raise_No_Return_Exception_Target_Unknown;
         end if;

         if Message /= "" then
            if Is_String_Literal (Message) then
               Info.Raise_Message_Subtype := To_Unbounded_String ("String");
               Info.Normalized_Raise_Message_Subtype := To_Unbounded_String ("string");
               Info.Raise_No_Return_Status := Raise_No_Return_With_Message;
            else
               Info.Raise_Message_Subtype := To_Unbounded_String ("message_expression_unknown");
               Info.Normalized_Raise_Message_Subtype := To_Unbounded_String ("message_expression_unknown");
               Info.Raise_No_Return_Status := Raise_No_Return_Message_Unknown;
            end if;
         end if;

         if To_String (Info.Normalized_Expected_Subtype) /= "" then
            Info.Raise_Result_Subtype := Info.Expected_Subtype;
            Info.Normalized_Raise_Result_Subtype := Info.Normalized_Expected_Subtype;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            if Message = "" then
               Info.Raise_No_Return_Status := Raise_No_Return_Result_Context_Propagated;
            end if;
         else
            Info.Raise_Result_Subtype := To_Unbounded_String ("raise_result_context_unknown");
            Info.Normalized_Raise_Result_Subtype := To_Unbounded_String ("raise_result_context_unknown");
            Info.Inferred_Subtype := Info.Raise_Result_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Raise_Result_Subtype;
            if Message = "" then
               Info.Raise_No_Return_Status := Raise_No_Return_Result_Context_Unknown;
            end if;
         end if;
         return;
      end if;

      if Info.Status = Expression_Type_Call_Resolved and then
        Info.Declaration /= Editor.Ada_Direct_Visibility.No_Declaration
      then
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration (Visibility, Info.Declaration);
            Decl_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
            Decl_Text : constant String := Normalize (To_String (Decl_Node.Label));
         begin
            if Contains (Decl_Text, "no_return") or else Contains (Decl_Text, "noreturn") then
               Info.Status := Expression_Type_No_Return_Call;
               Info.Raise_No_Return_Status := Raise_No_Return_No_Return_Call;
            end if;
         end;
      end if;
   end Apply_Raise_No_Return_Inference;
