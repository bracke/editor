with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;

package Editor.Ada_Expression_Types.Access_Text_Helpers is

   function Declaration_Definition_Text
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String;

   function Starts_With (Text : String; Prefix : String) return Boolean;
   function Drop_Prefix (Text : String; Length : Natural) return String;
   function Strip_Access_Qualifiers (Text : String) return String;

   function Designated_Subtype_For_Access_Type
     (Tree  : Editor.Ada_Syntax_Tree.Tree_Type;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Id    : Editor.Ada_Type_Graph.Type_Id) return String;

   function Object_Subtype_For_Name
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String;
      Declaration : out Editor.Ada_Direct_Visibility.Declaration_Id;
      Candidates  : out Natural) return String;

   function Allocator_Target_From_Text (Text : String) return String;
   function Expected_Access_Designated_Subtype (Expected : String) return String;

end Editor.Ada_Expression_Types.Access_Text_Helpers;
