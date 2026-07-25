with Editor.Ada_Static_Expressions;

package Editor.Ada_Representation_Legality.Static_Value_Checks is

   function Is_Known_Convention (Name : String) return Boolean;
   function Is_Identifier_Text (Text : String) return Boolean;
   function Is_Static_String_Text (Text : String) return Boolean;
   function Is_Static_Boolean_True (Text : String) return Boolean;
   function Is_Static_Boolean_False (Text : String) return Boolean;
   function Is_High_Order_First (Text : String) return Boolean;
   function Is_Low_Order_First (Text : String) return Boolean;
   function Operational_Value_Status_For
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Text : String) return Operational_Value_Status;
   function Interfacing_Value_Status_For
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Text : String) return Interfacing_Value_Status;
   function Starts_With_Digit_Or_Sign (Text : String) return Boolean;
   function Stream_Subprogram_Status_For
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Text : String) return Stream_Subprogram_Status;
   function Address_Value_Status_For (Text : String) return Address_Value_Status;
   function Value_Status_For
     (Value : Editor.Ada_Static_Expressions.Static_Value_Info) return Representation_Value_Status;

end Editor.Ada_Representation_Legality.Static_Value_Checks;
