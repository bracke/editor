with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Representation_Target_Helpers is

   function Is_Type_Like_Target
     (Kind : Editor.Ada_Language_Model.Symbol_Kind) return Boolean;

   function Is_Object_Like_Target
     (Kind : Editor.Ada_Language_Model.Symbol_Kind) return Boolean;

   function Is_Subprogram_Like_Target
     (Kind : Editor.Ada_Language_Model.Symbol_Kind) return Boolean;

   function Is_Access_Type_Target
     (Info : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Storage_Size_Target
     (Info : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Array_Type_Target
     (Info : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Fixed_Point_Type_Target
     (Info : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Floating_Point_Type_Target
     (Info : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Atomic_Volatile_Target
     (Info : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Suppress_Initialization_Target
     (Info : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Unchecked_Union_Target
     (Info : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Address_Clause_Target
     (Kind : Editor.Ada_Language_Model.Symbol_Kind) return Boolean;

   function Representation_Target_Is_Compatible
     (Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      Kind   : Editor.Ada_Language_Model.Symbol_Kind) return Boolean;

   function Requires_Static_Natural_Value
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean;

   function Is_Valid_Bit_Order_Value (Text : String) return Boolean;

   function Is_Valid_Scalar_Storage_Order_Value (Text : String) return Boolean;

   function Is_Representation_Item_Subject_To_Freezing
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean;

end Editor.Ada_Declaration_Parser.Representation_Target_Helpers;
