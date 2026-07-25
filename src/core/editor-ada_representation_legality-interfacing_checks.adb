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

package body Editor.Ada_Representation_Legality.Interfacing_Checks is

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



   function Import_Export_Enabled_For_Target
     (Model  : Representation_Legality_Model;
      Target : String) return Boolean is
   begin
      for Index in 1 .. Natural (Model.Checks.Length) loop
         declare
            Info : constant Representation_Legality_Info := Model.Checks (Index);
         begin
            if To_String (Info.Normalized_Target) = Target
              and then Info.Status = Representation_Legality_Ok
              and then Info.Clause_Kind in Editor.Ada_Language_Model.Representation_Import_Clause |
                                           Editor.Ada_Language_Model.Representation_Export_Clause
              and then Info.Interfacing_Status = Interfacing_Value_Static_Boolean_True
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Import_Export_Enabled_For_Target;

   function Has_Opposite_Enabled_Import_Export
     (Model : Representation_Legality_Model;
      Info  : Representation_Legality_Info) return Boolean is
      Target : constant String := To_String (Info.Normalized_Target);
      Opposite : constant Editor.Ada_Language_Model.Representation_Clause_Kind :=
        (if Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Import_Clause
         then Editor.Ada_Language_Model.Representation_Export_Clause
         else Editor.Ada_Language_Model.Representation_Import_Clause);
   begin
      if Info.Clause_Kind not in Editor.Ada_Language_Model.Representation_Import_Clause |
                                Editor.Ada_Language_Model.Representation_Export_Clause
        or else Info.Interfacing_Status /= Interfacing_Value_Static_Boolean_True
      then
         return False;
      end if;

      for Index in 1 .. Natural (Model.Checks.Length) loop
         declare
            Other : constant Representation_Legality_Info := Model.Checks (Index);
         begin
            if Other.Clause_Node /= Info.Clause_Node
              and then To_String (Other.Normalized_Target) = Target
              and then Other.Clause_Kind = Opposite
              and then Other.Status = Representation_Legality_Ok
              and then Other.Interfacing_Status = Interfacing_Value_Static_Boolean_True
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Has_Opposite_Enabled_Import_Export;

   procedure Finalize_Interfacing_Conflicts
     (Model : in out Representation_Legality_Model) is
   begin
      for Index in 1 .. Natural (Model.Checks.Length) loop
         declare
            Info : Representation_Legality_Info := Model.Checks (Index);
         begin
            if Info.Status = Representation_Legality_Ok
              and then Has_Opposite_Enabled_Import_Export (Model, Info)
            then
               Info.Status := Representation_Legality_Import_Export_Conflict;
               Info.Fingerprint := Mix (Info.Fingerprint,
                 Representation_Legality_Status'Pos (Info.Status));
               Model.Checks.Replace_Element (Index, Info);
            elsif Info.Status = Representation_Legality_Ok
              and then Info.Clause_Kind in Editor.Ada_Language_Model.Representation_External_Name_Clause |
                                           Editor.Ada_Language_Model.Representation_Link_Name_Clause
              and then not Import_Export_Enabled_For_Target
                (Model, To_String (Info.Normalized_Target))
            then
               Info.Status := Representation_Legality_Link_Name_Requires_Import_Export;
               Info.Fingerprint := Mix (Info.Fingerprint,
                 Representation_Legality_Status'Pos (Info.Status));
               Model.Checks.Replace_Element (Index, Info);
            end if;
         end;
      end loop;
   end Finalize_Interfacing_Conflicts;

end Editor.Ada_Representation_Legality.Interfacing_Checks;
