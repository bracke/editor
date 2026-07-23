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
   function Array_Element_Subtype_For
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Types  : Editor.Ada_Type_Graph.Type_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Expected : String) return String
   is
      Direct : constant String := Extract_Array_Element_Subtype (Expected);
      T_Id : Editor.Ada_Type_Graph.Type_Id;
   begin
      if Direct /= "" then
         return Direct;
      end if;

      T_Id := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Expected);
      if T_Id = Editor.Ada_Type_Graph.No_Type then
         return "";
      end if;

      declare
         Info : constant Editor.Ada_Type_Graph.Type_Info :=
           Editor.Ada_Type_Graph.Type_Node (Types, T_Id);
      begin
         if To_String (Info.Base_Subtype) /= "" then
            declare
               Base_Element : constant String :=
                 Extract_Array_Element_Subtype (To_String (Info.Base_Subtype));
            begin
               if Base_Element /= "" then
                  return Base_Element;
               end if;
            end;
         end if;

         if Info.Node /= Editor.Ada_Syntax_Tree.No_Node then
            declare
               N : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node (Tree, Info.Node);
            begin
               return Extract_Array_Element_Subtype (To_String (N.Label));
            end;
         end if;
      end;

      return "";
   end Array_Element_Subtype_For;
