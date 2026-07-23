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
   procedure Apply_Universal_Numeric_Resolution
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Static  : Editor.Ada_Static_Expressions.Static_Model;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Info    : in out Expression_Type_Info;
      Node    : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Inferred : constant String := To_String (Info.Normalized_Subtype);
      Expected_U : Ada.Strings.Unbounded.Unbounded_String := Info.Expected_Subtype;
      NExpected_U : Ada.Strings.Unbounded.Unbounded_String := Info.Normalized_Expected_Subtype;
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Value : Editor.Ada_Static_Expressions.Static_Value_Info;
   begin
      Info.Universal_Numeric_Status := Universal_Numeric_Not_Universal;

      if To_String (Expected_U) = "" or else To_String (NExpected_U) = "" then
         declare
            Current : Editor.Ada_Syntax_Tree.Node_Id := Node.Parent;
         begin
            while Current /= Editor.Ada_Syntax_Tree.No_Node loop
               declare
                  Anc : constant Editor.Ada_Syntax_Tree.Node_Info :=
                    Editor.Ada_Syntax_Tree.Node (Tree, Current);
               begin
                  if Anc.Kind = Editor.Ada_Syntax_Tree.Node_Declaration_Default
                    and then Anc.Parent /= Editor.Ada_Syntax_Tree.No_Node
                  then
                     declare
                        Decl_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
                          Editor.Ada_Syntax_Tree.Node (Tree, Anc.Parent);
                        Subtype_Text : constant String :=
                          Subtype_From_Declaration_Label (To_String (Decl_Node.Label));
                     begin
                        if Subtype_Text /= "" then
                           Expected_U := To_Unbounded_String (Subtype_Text);
                           NExpected_U := To_Unbounded_String (Normalize (Subtype_Text));
                           Info.Expected_Subtype := Expected_U;
                           Info.Normalized_Expected_Subtype := NExpected_U;
                           exit;
                        end if;
                     end;
                  end if;
                  Current := Anc.Parent;
               end;
            end loop;
         end;
         if To_String (Expected_U) = "" or else To_String (NExpected_U) = "" then
            return;
         end if;
      end if;

      if Inferred /= "universal_integer" and then Inferred /= "universal_real" then
         return;
      end if;

      Info.Universal_Numeric_Status := Universal_Numeric_Expected_Context_Found;
      Info.Universal_Numeric_Expected_Subtype := Info.Expected_Subtype;
      Info.Normalized_Universal_Numeric_Expected_Subtype := Info.Normalized_Expected_Subtype;
      Value := Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
        (Static, Region, To_String (Info.Expression_Text));
      Info.Universal_Numeric_Static_Status := Value.Status;
      Info.Universal_Numeric_Integer_Value := Value.Integer_Value;
      Info.Universal_Numeric_Real_Value := Value.Real_Value;

      if Inferred = "universal_integer" then
         if Looks_Modular_Expected_Subtype (Static, Region, To_String (Expected_U)) then
            Info.Universal_Numeric_Status := Universal_Numeric_Modular_Resolved;
            Info.Universal_Numeric_Result_Subtype := Info.Expected_Subtype;
            Info.Normalized_Universal_Numeric_Result_Subtype := Info.Normalized_Expected_Subtype;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            Info.Expected_Status := Expected_Type_Compatible;
         elsif Is_Integer_Expected_Subtype (To_String (Expected_U)) or else Has_Static_Integer_Bounds (Static, To_String (Expected_U)) then
            Info.Universal_Numeric_Status := Universal_Numeric_Integer_Resolved;
            Info.Universal_Numeric_Result_Subtype := Info.Expected_Subtype;
            Info.Normalized_Universal_Numeric_Result_Subtype := Info.Normalized_Expected_Subtype;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            Info.Expected_Status := Expected_Type_Compatible;
            if Editor.Ada_Static_Expressions.Is_Static_Integer (Value) then
               Apply_Integer_Range_Metadata (Static, Region, To_String (Expected_U), Value.Integer_Value, Info);
            elsif Value.Status /= Editor.Ada_Static_Expressions.Static_Value_Not_Checked then
               Info.Universal_Numeric_Status := Universal_Numeric_Static_Unknown;
            end if;
         elsif Is_Real_Expected_Subtype (To_String (Expected_U)) or else Looks_Fixed_Expected_Subtype (Static, Region, To_String (Expected_U)) then
            if Looks_Fixed_Expected_Subtype (Static, Region, To_String (Expected_U)) then
               Info.Universal_Numeric_Status := Universal_Numeric_Fixed_Resolved;
            else
               Info.Universal_Numeric_Status := Universal_Numeric_Real_Resolved;
            end if;
            Info.Universal_Numeric_Result_Subtype := Info.Expected_Subtype;
            Info.Normalized_Universal_Numeric_Result_Subtype := Info.Normalized_Expected_Subtype;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            Info.Expected_Status := Expected_Type_Compatible;
         else
            Info.Universal_Numeric_Status := Universal_Numeric_Expected_Mismatch;
            Info.Expected_Status := Expected_Type_Mismatch;
         end if;
      elsif Inferred = "universal_real" then
         if Is_Real_Expected_Subtype (To_String (Expected_U)) or else Looks_Fixed_Expected_Subtype (Static, Region, To_String (Expected_U)) then
            if Looks_Fixed_Expected_Subtype (Static, Region, To_String (Expected_U)) then
               Info.Universal_Numeric_Status := Universal_Numeric_Fixed_Resolved;
            else
               Info.Universal_Numeric_Status := Universal_Numeric_Real_Resolved;
            end if;
            Info.Universal_Numeric_Result_Subtype := Info.Expected_Subtype;
            Info.Normalized_Universal_Numeric_Result_Subtype := Info.Normalized_Expected_Subtype;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            Info.Expected_Status := Expected_Type_Compatible;
         else
            Info.Universal_Numeric_Status := Universal_Numeric_Expected_Mismatch;
            Info.Expected_Status := Expected_Type_Mismatch;
         end if;
      end if;
   end Apply_Universal_Numeric_Resolution;
