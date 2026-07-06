with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declaration_Parser.Representation_Application is

   subtype Node_Id is Editor.Ada_Syntax_Tree.Node_Id;
   subtype Node_Info is Editor.Ada_Syntax_Tree.Node_Info;
   subtype Node_Kind is Editor.Ada_Syntax_Tree.Node_Kind;
   subtype Source_Range is Editor.Ada_Syntax_Tree.Source_Range;
   subtype Symbol_Id is Editor.Ada_Language_Model.Symbol_Id;

   type Child_Label_Function is access function
     (Node : Node_Id;
      Kind : Node_Kind) return String;

   type Source_Range_Function is access function
     (Span : Source_Range)
      return Editor.Ada_Language_Model.Source_Range;

   type Symbol_Name_Function is access function
     (Symbol : Symbol_Id) return String;

   type Symbol_Lookup_Function is access function
     (Name : String) return Symbol_Id;

   type Name_Normalizer_Function is access function
     (Name : String) return String;

   type Scoped_Symbol_Function is access function
     (Node : Node_Id) return Symbol_Id;

   type Enumeration_Literal_Function is access function
     (Target : Symbol_Id;
      Name   : String) return Symbol_Id;

   type Enumeration_Position_Function is access function
     (Target : Symbol_Id;
      Index  : Positive) return Symbol_Id;

   type Component_Lookup_Function is access function
     (Target : Symbol_Id;
      Name   : String) return Symbol_Id;

   type Static_Natural_Parser is access procedure
     (Text  : String;
      Valid : out Boolean;
      Value : out Natural);

   type Static_Attribute_Registration is access procedure
     (Target_Name    : String;
      Attribute_Name : String;
      Value          : Natural);

   type Application_Context is record
      First_Child_Label : Child_Label_Function;
      Last_Child_Label  : Child_Label_Function;
      To_Model_Range    : Source_Range_Function;

      Find_Metadata_Target : Symbol_Lookup_Function;
      Normalize_Name       : Name_Normalizer_Function;
      Ancestor_Symbol      : Scoped_Symbol_Function;
      Parent_Representation_Target : Scoped_Symbol_Function;

      Find_Enumeration_Literal : Enumeration_Literal_Function;
      Enumeration_Literal_At   : Enumeration_Position_Function;
      Find_Component           : Component_Lookup_Function;
      Symbol_Name              : Symbol_Name_Function;

      Parse_Static_Natural : Static_Natural_Parser;
      Register_Static_Attribute : Static_Attribute_Registration;
   end record;

   function Is_Complete (Context : Application_Context) return Boolean;

   function Create_Context
     (First_Child_Label : Child_Label_Function;
      Last_Child_Label  : Child_Label_Function;
      To_Model_Range    : Source_Range_Function;
      Find_Metadata_Target : Symbol_Lookup_Function;
      Normalize_Name       : Name_Normalizer_Function;
      Ancestor_Symbol      : Scoped_Symbol_Function;
      Parent_Representation_Target : Scoped_Symbol_Function;
      Find_Enumeration_Literal : Enumeration_Literal_Function;
      Enumeration_Literal_At   : Enumeration_Position_Function;
      Find_Component           : Component_Lookup_Function;
      Symbol_Name              : Symbol_Name_Function;
      Parse_Static_Natural     : Static_Natural_Parser;
      Register_Static_Attribute : Static_Attribute_Registration)
      return Application_Context;

   procedure Apply_General_Representation_Clause
     (Context  : Application_Context;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Node     : Node_Info);

   procedure Apply_Record_Representation_Component
     (Context  : Application_Context;
      Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Node     : Node_Info);

   procedure Apply_Record_Representation_Mod_Clause
     (Context  : Application_Context;
      Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Node     : Node_Info);

   procedure Apply_Representation_Aspect
     (Context      : Application_Context;
      Analysis     : in out Editor.Ada_Language_Model.Analysis_Result;
      Owner        : Symbol_Id;
      Aspect_Name  : String;
      Aspect_Value : String;
      Source_Span  : Source_Range);

end Editor.Ada_Declaration_Parser.Representation_Application;
