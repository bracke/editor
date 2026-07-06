with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Representation_Metadata is

   procedure Mark_Representation_Clause_Target
     (Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Line     : String);

   function Interfacing_Representation_Kind
     (Attribute_Name : String)
      return Editor.Ada_Language_Model.Representation_Clause_Kind;

   function Representation_Kind_For
     (Target_Text : String;
      Item_Text   : String;
      Clause_Text : String := "")
      return Editor.Ada_Language_Model.Representation_Clause_Kind;

   function Representation_Property_Is_Boolean
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind)
      return Boolean;

   function Representation_Property_Has_Static_Natural_Value
     (Kind  : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Value : String)
      return Boolean;

   function Representation_Property_Static_Natural_Value
     (Kind  : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Value : String)
      return Natural;

   procedure Add_Interfacing_Pragma_Representation
     (Analysis      : in out Editor.Ada_Language_Model.Analysis_Result;
      Target_Symbol : Editor.Ada_Language_Model.Symbol_Id;
      Target_Name   : String;
      Line          : String;
      Source_Span   : Editor.Ada_Language_Model.Source_Range);

   procedure Add_Representation_Pragma_Representation
     (Analysis      : in out Editor.Ada_Language_Model.Analysis_Result;
      Target_Symbol : Editor.Ada_Language_Model.Symbol_Id;
      Target_Name   : String;
      Line          : String;
      Source_Span   : Editor.Ada_Language_Model.Source_Range);

end Editor.Ada_Declaration_Parser.Representation_Metadata;
