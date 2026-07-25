with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Representation_Legality.Core_Utilities;
with Editor.Ada_Representation_Legality.Clause_Classification;
with Editor.Ada_Representation_Legality.Target_Compatibility;
with Editor.Ada_Representation_Legality.Static_Value_Checks;

package body Editor.Ada_Representation_Legality.Stream_Profile_Checks is

   pragma Suppress (Overflow_Check);

   use type Ada.Containers.Count_Type;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Freezing_Points.Freezable_Id;
   use type Editor.Ada_Freezing_Points.Freezable_Kind;
   use type Editor.Ada_Freezing_Points.Representation_Freezing_Status;
   use type Editor.Ada_Freezing_Points.Freezing_Status;
   use type Editor.Ada_Static_Expressions.Static_Value_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Type_Graph.Type_Category;
   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Language_Model.Representation_Clause_Kind;
   use type Editor.Ada_Language_Model.Representation_Source_Form;

   function Mix (A, B : Natural) return Natural
     renames Editor.Ada_Representation_Legality.Core_Utilities.Mix;

   function Trimmed (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Trimmed;

   function Lower (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Lower;

   function Normalized (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Normalized;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Child_Label;

   function Declaration_Name
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Declaration_Name;

   function Name_List_Contains (List_Text, Name : String) return Boolean
     renames Editor.Ada_Representation_Legality.Core_Utilities.Name_List_Contains;

   function Has_Record_Component
     (Tree           : Editor.Ada_Syntax_Tree.Tree_Type;
      Record_Type    : Editor.Ada_Syntax_Tree.Node_Id;
      Component_Name : String) return Boolean
     renames Editor.Ada_Representation_Legality.Core_Utilities.Has_Record_Component;

   function Strip_Leading_At (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Strip_Leading_At;

   function Range_First (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Range_First;

   function Range_Last (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Range_Last;

   function Check_For_Clause
     (Model  : Representation_Legality_Model;
      Clause : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Legality_Info
     renames Editor.Ada_Representation_Legality.Check_For_Clause;

   function Value_Status_For
     (Value : Editor.Ada_Static_Expressions.Static_Value_Info) return Representation_Value_Status
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Value_Status_For;

   function Stream_Profile_Conforms
     (Kind    : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Profile : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info) return Boolean is
      use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Status;
   begin
      if Profile.Status /= Editor.Ada_Call_Profile_Shapes.Callable_Profile_Found then
         return False;
      end if;

      case Kind is
         when Editor.Ada_Language_Model.Representation_Read_Clause |
              Editor.Ada_Language_Model.Representation_Write_Clause |
              Editor.Ada_Language_Model.Representation_Output_Clause |
              Editor.Ada_Language_Model.Representation_Put_Image_Clause =>
            return (not Profile.Has_Result) and then Profile.Parameter_Count = 2;
         when Editor.Ada_Language_Model.Representation_Input_Clause =>
            return Profile.Has_Result and then Profile.Parameter_Count = 1;
         when others =>
            return False;
      end case;
   end Stream_Profile_Conforms;

   function Unique_Visible_Declaration
     (Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Name       : String) return Editor.Ada_Direct_Visibility.Lookup_Result is
      use type Editor.Ada_Direct_Visibility.Declaration_Id;
      Wanted : constant String := Lower (Name);
      Result : Editor.Ada_Direct_Visibility.Lookup_Result :=
        (Status => Editor.Ada_Direct_Visibility.Lookup_Not_Found,
         Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
         Region => Editor.Ada_Declarative_Regions.No_Region,
         Match_Count => 0);
   begin
      if Wanted = "" then
         return Result;
      end if;

      for Index in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration_At (Visibility, Index);
         begin
            if To_String (Decl.Normalized) = Wanted then
               Result.Match_Count := Result.Match_Count + 1;
               if Result.Declaration = Editor.Ada_Direct_Visibility.No_Declaration then
                  Result.Declaration := Decl.Id;
                  Result.Region := Decl.Region;
               end if;
            end if;
         end;
      end loop;

      if Result.Match_Count = 1 then
         Result.Status := Editor.Ada_Direct_Visibility.Lookup_Found;
      elsif Result.Match_Count > 1 then
         Result.Status := Editor.Ada_Direct_Visibility.Lookup_Ambiguous;
      end if;
      return Result;
   end Unique_Visible_Declaration;

end Editor.Ada_Representation_Legality.Stream_Profile_Checks;
