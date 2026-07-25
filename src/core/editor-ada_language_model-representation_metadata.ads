with Editor.Ada_Language_Model;
with Editor.Syntax;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Language_Model.Representation_Metadata is

   procedure Add_Representation_Clause
     (Analysis          : in out Analysis_Result;
      Target_Symbol     : Symbol_Id := No_Symbol;
      Target_Name       : String;
      Kind              : Representation_Clause_Kind;
      Attribute_Name    : String := "";
      Item_Text         : String;
      Source_Form       : Representation_Source_Form :=
        Representation_Source_Attribute_Definition;
      Has_Static_Value  : Boolean := False;
      Static_Value      : Natural := 0;
      Source_Span             : Source_Range);

   function Representation_Clause_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Representation_Clause_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Representation_Clause_Info;

   procedure Add_Enumeration_Representation_Literal
     (Analysis         : in out Analysis_Result;
      Target_Symbol    : Symbol_Id;
      Literal_Symbol   : Symbol_Id := No_Symbol;
      Literal_Name     : String;
      Value_Text       : String;
      Has_Static_Value : Boolean := False;
      Static_Value     : Natural := 0;
      Source_Span            : Source_Range);

   function Enumeration_Representation_Literal_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Enumeration_Representation_Literal_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Enumeration_Representation_Literal_Info;

   procedure Add_Record_Representation_Component
     (Analysis          : in out Analysis_Result;
      Target_Symbol     : Symbol_Id;
      Component_Symbol  : Symbol_Id := No_Symbol;
      Component_Name    : String;
      Storage_Unit_Text : String;
      First_Bit_Text    : String;
      Last_Bit_Text     : String;
      Source_Form       : Representation_Source_Form :=
        Representation_Source_Record_Component_Clause;
      Has_Static_Storage_Unit : Boolean := False;
      Static_Storage_Unit     : Natural := 0;
      Has_Static_First_Bit    : Boolean := False;
      Static_First_Bit        : Natural := 0;
      Has_Static_Last_Bit     : Boolean := False;
      Static_Last_Bit         : Natural := 0;
      Source_Span             : Source_Range);

   function Representation_Component_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Representation_Component_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Representation_Component_Info;


   procedure Add_Freezing_Point
     (Analysis       : in out Analysis_Result;
      Target_Symbol  : Symbol_Id;
      Trigger_Symbol : Symbol_Id;
      Kind           : Freezing_Point_Kind;
      Reason         : String;
      Source_Span          : Source_Range);

   function Freezing_Point_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Freezing_Point_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Freezing_Point_Info;




end Editor.Ada_Language_Model.Representation_Metadata;
