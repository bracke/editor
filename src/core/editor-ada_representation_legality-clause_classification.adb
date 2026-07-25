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

package body Editor.Ada_Representation_Legality.Clause_Classification is

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

   function Static_Value_Required
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Alignment_Clause |
                     Editor.Ada_Language_Model.Representation_Component_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Object_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Value_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Storage_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Machine_Radix_Clause |
                     Editor.Ada_Language_Model.Representation_Aft_Clause |
                     Editor.Ada_Language_Model.Representation_Small_Clause;
   end Static_Value_Required;

   function Positive_Value_Required
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Alignment_Clause |
                     Editor.Ada_Language_Model.Representation_Component_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Object_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Value_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Storage_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Machine_Radix_Clause |
                     Editor.Ada_Language_Model.Representation_Aft_Clause;
   end Positive_Value_Required;

   function Integer_Value_Required
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Alignment_Clause |
                     Editor.Ada_Language_Model.Representation_Component_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Object_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Value_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Storage_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Machine_Radix_Clause |
                     Editor.Ada_Language_Model.Representation_Aft_Clause;
   end Integer_Value_Required;

   function Interfacing_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Convention_Clause |
                     Editor.Ada_Language_Model.Representation_Import_Clause |
                     Editor.Ada_Language_Model.Representation_Export_Clause |
                     Editor.Ada_Language_Model.Representation_External_Name_Clause |
                     Editor.Ada_Language_Model.Representation_Link_Name_Clause;
   end Interfacing_Clause;

   function Stream_Attribute_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Read_Clause |
                     Editor.Ada_Language_Model.Representation_Write_Clause |
                     Editor.Ada_Language_Model.Representation_Input_Clause |
                     Editor.Ada_Language_Model.Representation_Output_Clause |
                     Editor.Ada_Language_Model.Representation_Put_Image_Clause;
   end Stream_Attribute_Clause;

   function Boolean_Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Pack_Clause |
                     Editor.Ada_Language_Model.Representation_Atomic_Clause |
                     Editor.Ada_Language_Model.Representation_Volatile_Clause |
                     Editor.Ada_Language_Model.Representation_Independent_Clause |
                     Editor.Ada_Language_Model.Representation_Atomic_Components_Clause |
                     Editor.Ada_Language_Model.Representation_Volatile_Components_Clause |
                     Editor.Ada_Language_Model.Representation_Independent_Components_Clause |
                     Editor.Ada_Language_Model.Representation_Suppress_Initialization_Clause;
   end Boolean_Operational_Clause;

   function Order_Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Bit_Order_Clause |
                     Editor.Ada_Language_Model.Representation_Scalar_Storage_Order_Clause |
                     Editor.Ada_Language_Model.Representation_Default_Scalar_Storage_Order_Clause;
   end Order_Operational_Clause;

   function Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Boolean_Operational_Clause (Kind) or else Order_Operational_Clause (Kind);
   end Operational_Clause;

   function Aspect_Representation_Name (Name : String) return Boolean is
      N : constant String := Lower (Name);
   begin
      return N = "size" or else N = "alignment" or else N = "component_size"
        or else N = "object_size" or else N = "value_size"
        or else N = "storage_size" or else N = "small"
        or else N = "machine_radix" or else N = "aft"
        or else N = "bit_order" or else N = "scalar_storage_order"
        or else N = "default_scalar_storage_order" or else N = "pack"
        or else N = "atomic" or else N = "volatile"
        or else N = "independent" or else N = "atomic_components"
        or else N = "volatile_components"
        or else N = "independent_components"
        or else N = "suppress_initialization" or else N = "address"
        or else N = "convention" or else N = "import" or else N = "export"
        or else N = "external_name" or else N = "link_name"
        or else N = "read" or else N = "write" or else N = "input"
        or else N = "output" or else N = "put_image";
   end Aspect_Representation_Name;

   function Aspect_Default_Value (Name, Value : String) return String is
      N : constant String := Lower (Name);
      V : constant String := Trimmed (Value);
      V_Norm : constant String := Lower (V);
   begin
      if N = "pack" or else N = "atomic" or else N = "volatile"
        or else N = "independent" or else N = "atomic_components"
        or else N = "volatile_components"
        or else N = "independent_components"
        or else N = "suppress_initialization" or else N = "import"
        or else N = "export"
      then
         if V = "" or else V_Norm = N then
            return "True";
         else
            return V;
         end if;
      elsif V /= "" then
         return V;
      else
         return V;
      end if;
   end Aspect_Default_Value;

end Editor.Ada_Representation_Legality.Clause_Classification;
