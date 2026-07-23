package Editor.Ada_Token_Cursor.Contracts is

   function Is_Contract_Aspect_Mark (Name : String) return Boolean;

   function Is_Classwide_Contract_Mark
     (Position    : Cursor;
      Aspect_Name : String) return Boolean;

   function Has_Contract_Aspect_Before_Stop
     (Position     : Cursor;
      Stop_Keyword : String) return Boolean;

   function At_Profile_Item_End (Position : Cursor) return Boolean;

   function Access_Subprogram_Result_Has_Constraint
     (Position : Cursor) return Boolean;

   function At_Component_Default_Reserved_Boundary
     (Position : Cursor) return Boolean;

   function At_Profile_Default_Reserved_Boundary
     (Position : Cursor) return Boolean;

   function At_Number_Initialization_Reserved_Boundary
     (Position : Cursor) return Boolean;

   function At_Object_Subtype_Reserved_Boundary
     (Position : Cursor) return Boolean;

end Editor.Ada_Token_Cursor.Contracts;
