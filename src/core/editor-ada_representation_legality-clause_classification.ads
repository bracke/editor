with Editor.Ada_Language_Model;

package Editor.Ada_Representation_Legality.Clause_Classification is

   function Static_Value_Required
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean;
   function Positive_Value_Required
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean;
   function Integer_Value_Required
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean;
   function Interfacing_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean;
   function Stream_Attribute_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean;
   function Boolean_Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean;
   function Order_Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean;
   function Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean;
   function Aspect_Representation_Name (Name : String) return Boolean;
   function Aspect_Default_Value (Name, Value : String) return String;

end Editor.Ada_Representation_Legality.Clause_Classification;
