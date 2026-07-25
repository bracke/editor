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

package body Editor.Ada_Representation_Legality.Target_Compatibility is

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



   function Compatible_Target_Kind
     (Kind     : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Category : Editor.Ada_Type_Graph.Type_Category) return Boolean is
   begin
      case Kind is
         when Editor.Ada_Language_Model.Representation_Record_Clause =>
            return Category = Editor.Ada_Type_Graph.Type_Category_Record
              or else Category = Editor.Ada_Type_Graph.Type_Category_Private
              or else Category = Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Editor.Ada_Language_Model.Representation_Component_Size_Clause =>
            return Category = Editor.Ada_Type_Graph.Type_Category_Array
              or else Category = Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Editor.Ada_Language_Model.Representation_Small_Clause |
              Editor.Ada_Language_Model.Representation_Aft_Clause =>
            return Category = Editor.Ada_Type_Graph.Type_Category_Fixed
              or else Category = Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Editor.Ada_Language_Model.Representation_Machine_Radix_Clause =>
            return Category = Editor.Ada_Type_Graph.Type_Category_Floating
              or else Category = Editor.Ada_Type_Graph.Type_Category_Unknown;
         when others =>
            return True;
      end case;
   end Compatible_Target_Kind;

   function Compatible_Address_Target
     (Kind : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Freezing_Points.Freezable_Object |
                     Editor.Ada_Freezing_Points.Freezable_Subprogram |
                     Editor.Ada_Freezing_Points.Freezable_Unknown;
   end Compatible_Address_Target;

   function Size_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean is
   begin
      return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                         Editor.Ada_Freezing_Points.Freezable_Subtype |
                         Editor.Ada_Freezing_Points.Freezable_Object |
                         Editor.Ada_Freezing_Points.Freezable_Unknown;
   end Size_Target_Compatible;

   function Alignment_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean is
   begin
      return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                         Editor.Ada_Freezing_Points.Freezable_Subtype |
                         Editor.Ada_Freezing_Points.Freezable_Object |
                         Editor.Ada_Freezing_Points.Freezable_Unknown;
   end Alignment_Target_Compatible;

   function Storage_Size_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind;
      Category  : Editor.Ada_Type_Graph.Type_Category) return Boolean is
   begin
      if Freezable not in Editor.Ada_Freezing_Points.Freezable_Type |
                          Editor.Ada_Freezing_Points.Freezable_Subtype |
                          Editor.Ada_Freezing_Points.Freezable_Unknown
      then
         return False;
      end if;

      return Category in Editor.Ada_Type_Graph.Type_Category_Access |
                         Editor.Ada_Type_Graph.Type_Category_Private |
                         Editor.Ada_Type_Graph.Type_Category_Unknown;
   end Storage_Size_Target_Compatible;

   function Stream_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean is
   begin
      return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                         Editor.Ada_Freezing_Points.Freezable_Subtype |
                         Editor.Ada_Freezing_Points.Freezable_Unknown;
   end Stream_Target_Compatible;

   function Operational_Target_Compatible
     (Kind      : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Freezable : Editor.Ada_Freezing_Points.Freezable_Kind;
      Category  : Editor.Ada_Type_Graph.Type_Category) return Boolean is
   begin
      case Kind is
         when Editor.Ada_Language_Model.Representation_Pack_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                               Editor.Ada_Freezing_Points.Freezable_Subtype |
                               Editor.Ada_Freezing_Points.Freezable_Unknown
              and then Category in Editor.Ada_Type_Graph.Type_Category_Record |
                                   Editor.Ada_Type_Graph.Type_Category_Array |
                                   Editor.Ada_Type_Graph.Type_Category_Private |
                                   Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Editor.Ada_Language_Model.Representation_Atomic_Components_Clause |
              Editor.Ada_Language_Model.Representation_Volatile_Components_Clause |
              Editor.Ada_Language_Model.Representation_Independent_Components_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                               Editor.Ada_Freezing_Points.Freezable_Subtype |
                               Editor.Ada_Freezing_Points.Freezable_Unknown
              and then Category in Editor.Ada_Type_Graph.Type_Category_Array |
                                   Editor.Ada_Type_Graph.Type_Category_Private |
                                   Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Editor.Ada_Language_Model.Representation_Atomic_Clause |
              Editor.Ada_Language_Model.Representation_Volatile_Clause |
              Editor.Ada_Language_Model.Representation_Independent_Clause |
              Editor.Ada_Language_Model.Representation_Suppress_Initialization_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                               Editor.Ada_Freezing_Points.Freezable_Subtype |
                               Editor.Ada_Freezing_Points.Freezable_Object |
                               Editor.Ada_Freezing_Points.Freezable_Unknown;
         when Editor.Ada_Language_Model.Representation_Bit_Order_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                               Editor.Ada_Freezing_Points.Freezable_Subtype |
                               Editor.Ada_Freezing_Points.Freezable_Unknown
              and then Category in Editor.Ada_Type_Graph.Type_Category_Record |
                                   Editor.Ada_Type_Graph.Type_Category_Private |
                                   Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Editor.Ada_Language_Model.Representation_Scalar_Storage_Order_Clause |
              Editor.Ada_Language_Model.Representation_Default_Scalar_Storage_Order_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                               Editor.Ada_Freezing_Points.Freezable_Subtype |
                               Editor.Ada_Freezing_Points.Freezable_Unknown
              and then Category in Editor.Ada_Type_Graph.Type_Category_Record |
                                   Editor.Ada_Type_Graph.Type_Category_Array |
                                   Editor.Ada_Type_Graph.Type_Category_Private |
                                   Editor.Ada_Type_Graph.Type_Category_Unknown;
         when others =>
            return True;
      end case;
   end Operational_Target_Compatible;

   function Interfacing_Target_Compatible
     (Kind      : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean is
   begin
      case Kind is
         when Editor.Ada_Language_Model.Representation_Convention_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                               Editor.Ada_Freezing_Points.Freezable_Subtype |
                               Editor.Ada_Freezing_Points.Freezable_Subprogram |
                               Editor.Ada_Freezing_Points.Freezable_Object |
                               Editor.Ada_Freezing_Points.Freezable_Unknown;
         when Editor.Ada_Language_Model.Representation_Import_Clause |
              Editor.Ada_Language_Model.Representation_Export_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Subprogram |
                               Editor.Ada_Freezing_Points.Freezable_Object |
                               Editor.Ada_Freezing_Points.Freezable_Unknown;
         when Editor.Ada_Language_Model.Representation_External_Name_Clause |
              Editor.Ada_Language_Model.Representation_Link_Name_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Subprogram |
                               Editor.Ada_Freezing_Points.Freezable_Object |
                               Editor.Ada_Freezing_Points.Freezable_Unknown;
         when others =>
            return True;
      end case;
   end Interfacing_Target_Compatible;

   function Deepest_Region_Containing_Line
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Line    : Positive) return Editor.Ada_Declarative_Regions.Region_Id is
      Result : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Depth  : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
         declare
            R : constant Editor.Ada_Declarative_Regions.Region_Info :=
              Editor.Ada_Declarative_Regions.Region_At (Regions, Index);
         begin
            if R.Start_Line <= Line and then Line <= R.End_Line
              and then (Result = Editor.Ada_Declarative_Regions.No_Region
                        or else R.Depth >= Depth)
            then
               Result := R.Id;
               Depth := R.Depth;
            end if;
         end;
      end loop;
      return Result;
   end Deepest_Region_Containing_Line;

   function Ancestor_Declaration_Target
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String is
      Cur : Editor.Ada_Syntax_Tree.Node_Id := Node;
   begin
      while Cur /= Editor.Ada_Syntax_Tree.No_Node loop
         declare
            N : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Cur);
            Name : constant String := Declaration_Name (Tree, Cur);
         begin
            if Name /= "" then
               return Name;
            end if;
            Cur := N.Parent;
         end;
      end loop;
      return "";
   end Ancestor_Declaration_Target;

   function Freeze_Info_For_Target_At
     (Freezing : Editor.Ada_Freezing_Points.Freezing_Model;
      Regions  : Editor.Ada_Declarative_Regions.Region_Model;
      Line     : Positive;
      Target   : String) return Editor.Ada_Freezing_Points.Representation_Freeze_Info is
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Deepest_Region_Containing_Line (Regions, Line);
      Id : constant Editor.Ada_Freezing_Points.Freezable_Id :=
        Editor.Ada_Freezing_Points.Lookup_Freezable (Freezing, Region, Target);
      Result : Editor.Ada_Freezing_Points.Representation_Freeze_Info;
   begin
      Result.Clause_Line := Line;
      Result.Target_Name := To_Unbounded_String (Trimmed (Target));
      Result.Normalized_Target := To_Unbounded_String (Normalized (Target));
      Result.Target := Id;

      if Id = Editor.Ada_Freezing_Points.No_Freezable then
         Result.Status := Editor.Ada_Freezing_Points.Representation_Target_Unresolved;
      else
         declare
            F : constant Editor.Ada_Freezing_Points.Freezable_Info :=
              Editor.Ada_Freezing_Points.Freezable_Node (Freezing, Id);
         begin
            Result.Freeze_Line := F.First_Freeze_Line;
            if F.Status = Editor.Ada_Freezing_Points.Freezing_Not_Frozen then
               Result.Status := Editor.Ada_Freezing_Points.Representation_Target_Not_Frozen;
            elsif Line < F.First_Freeze_Line then
               Result.Status := Editor.Ada_Freezing_Points.Representation_Before_Freezing;
            elsif Line = F.First_Freeze_Line then
               Result.Status := Editor.Ada_Freezing_Points.Representation_At_Freezing_Point;
            else
               Result.Status := Editor.Ada_Freezing_Points.Representation_After_Freezing;
            end if;
         end;
      end if;

      Result.Fingerprint :=
        Mix (Natural (Id), Mix (Line, Editor.Ada_Freezing_Points.Representation_Freezing_Status'Pos (Result.Status)));
      return Result;
   end Freeze_Info_For_Target_At;

   function Type_Category_For_Target
     (Types   : Editor.Ada_Type_Graph.Type_Model;
      Target  : Editor.Ada_Freezing_Points.Freezable_Info)
      return Editor.Ada_Type_Graph.Type_Category is
   begin
      if Target.Type_Node = Editor.Ada_Type_Graph.No_Type then
         return Editor.Ada_Type_Graph.Type_Category_Unknown;
      end if;

      return Editor.Ada_Type_Graph.Type_Node (Types, Target.Type_Node).Category;
   end Type_Category_For_Target;

end Editor.Ada_Representation_Legality.Target_Compatibility;
