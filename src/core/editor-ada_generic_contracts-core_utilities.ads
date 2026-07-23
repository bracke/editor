with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Contracts.Core_Utilities is

   function Trim (Text : String) return String;

   function Normalize (Text : String) return String;

   function Contains (Text : String; Pattern : String) return Boolean;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer;
      Modulus    : Long_Long_Integer := Long_Long_Integer (Natural'Last))
      return Natural;

   function Hash_Text (Text : String) return Natural;

   procedure Mix
     (Model : in out Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Value : Natural);

   function Empty_Formal
     return Editor.Ada_Generic_Contracts.Generic_Formal_Info;

   function Empty_Instance
     return Editor.Ada_Generic_Contracts.Generic_Instance_Info;

   function Empty_Actual_Match
     return Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info;

   function Empty_Body_Contract_Visibility
     return Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Info;

   function To_Formal_Kind
     (Kind : Editor.Ada_Direct_Visibility.Declaration_Kind)
      return Editor.Ada_Generic_Contracts.Generic_Formal_Kind;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String;

end Editor.Ada_Generic_Contracts.Core_Utilities;
