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
   function Lookup_Operand_Subtype_Text
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Text       : String) return String
   is
      Literal : constant String := Operand_Subtype_From_Text (Static, Region, Text);
      Lookup  : Editor.Ada_Direct_Visibility.Lookup_Result;

      function Subtype_For_Declaration
        (Decl : Editor.Ada_Direct_Visibility.Declaration_Info) return String
      is
         Subtype_Text : constant String :=
           Subtype_From_Declaration_Label
             (To_String (Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node).Label));
      begin
         return Subtype_Text;
      end Subtype_For_Declaration;
   begin
      if Literal /= "" then
         return Literal;
      end if;

      Lookup := Editor.Ada_Direct_Visibility.Lookup_Visible
        (Visibility, Regions, Region, Primary_Name (Text));
      if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
            Subtype_Text : constant String := Subtype_For_Declaration (Decl);
         begin
            if Subtype_Text /= "" then
               return Subtype_Text;
            else
               return To_String (Decl.Name);
            end if;
         end;
      elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
         return "ambiguous";
      else
         declare
            Wanted : constant String := Normalize (Primary_Name (Text));
            Found  : Editor.Ada_Direct_Visibility.Declaration_Id :=
              Editor.Ada_Direct_Visibility.No_Declaration;
         begin
            for I in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
               declare
                  Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                    Editor.Ada_Direct_Visibility.Declaration_At (Visibility, I);
               begin
                  if Normalize (To_String (Decl.Name)) = Wanted
                    and then (Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Object
                              or else Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Number)
                  then
                     if Found /= Editor.Ada_Direct_Visibility.No_Declaration then
                        return "";
                     end if;
                     Found := Decl.Id;
                  end if;
               end;
            end loop;
            if Found /= Editor.Ada_Direct_Visibility.No_Declaration then
               declare
                  Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                    Editor.Ada_Direct_Visibility.Declaration (Visibility, Found);
               begin
                  return Subtype_For_Declaration (Decl);
               end;
            end if;
         end;
         return "";
      end if;
   end Lookup_Operand_Subtype_Text;
