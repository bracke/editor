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
   function Infer_Operand_Subtype
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Parent     : Editor.Ada_Syntax_Tree.Node_Info;
      Child_Index : Positive) return String
   is
      pragma Unreferenced (Types);
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Parent.Source_Span.Start_Line);
      Count  : constant Natural :=
        Editor.Ada_Syntax_Tree.Child_Count (Tree, Parent.Id);
   begin
      if Count >= Child_Index then
         declare
            Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
              Editor.Ada_Syntax_Tree.Child_At (Tree, Parent.Id, Child_Index);
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
            Text : constant String := Trim (To_String (Child.Label));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Literal then
               declare
                  V : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
                    Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression (Static, Region, Text);
               begin
                  if V.Status = Editor.Ada_Static_Expressions.Static_Value_Integer then
                     return "Universal_Integer";
                  elsif V.Status = Editor.Ada_Static_Expressions.Static_Value_Real then
                     return "Universal_Real";
                  elsif Normalize (Text) = "true" or else Normalize (Text) = "false" then
                     return "Boolean";
                  elsif Is_String_Literal (Text) then
                     return "String";
                  elsif Is_Character_Literal_Text (Text) then
                     return "Character";
                  end if;
               end;
            elsif Child.Kind = Editor.Ada_Syntax_Tree.Node_Name then
               declare
                  Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                    Editor.Ada_Direct_Visibility.Lookup_Visible
                      (Visibility, Regions, Region, Primary_Name (Text));
               begin
                  if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
                     declare
                        Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                          Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
                        Subtype_Text : constant String :=
                          Subtype_From_Declaration_Label (To_String (Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node).Label));
                     begin
                        if Subtype_Text /= "" then
                           return Subtype_Text;
                        else
                           return To_String (Decl.Name);
                        end if;
                     end;
                  elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
                     return "ambiguous";
                  end if;
               end;
            elsif Child.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call then
               declare
                  Resolution : constant Editor.Ada_Call_Resolution.Call_Resolution_Info :=
                    Editor.Ada_Call_Resolution.Resolution_For_Node (Calls, Child.Id);
               begin
                  if Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Unique_Profile_Match then
                     return "call_result_known";
                  elsif Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Pre_Profile or else
                    Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Profile_Match
                  then
                     return "ambiguous";
                  end if;
               end;
            end if;
         end;
      end if;

      declare
         Text : constant String := Normalize (To_String (Parent.Label));
      begin
         if Contains (Text, "true") or else Contains (Text, "false") then
            return "Boolean";
         elsif Looks_Real (Text) then
            return "Universal_Real";
         elsif Text /= "" then
            declare
               V : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
                 Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression (Static, Region, Text);
            begin
               if V.Status = Editor.Ada_Static_Expressions.Static_Value_Integer then
                  return "Universal_Integer";
               elsif V.Status = Editor.Ada_Static_Expressions.Static_Value_Real then
                  return "Universal_Real";
               end if;
            end;
         end if;
      end;
      return "";
   end Infer_Operand_Subtype;
