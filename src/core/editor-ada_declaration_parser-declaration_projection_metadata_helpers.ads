with Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers is

   function Pragma_Metadata_Argument_Count
     (Node : Editor.Ada_Syntax_Tree.Node_Info) return Natural;

   function Pragma_Metadata_Named_Argument_Count
     (Node : Editor.Ada_Syntax_Tree.Node_Info) return Natural;

   function Pragma_Metadata_Target
     (Node : Editor.Ada_Syntax_Tree.Node_Info) return String;

   function Pragma_Placement_For_Node
     (Tree  : Editor.Ada_Syntax_Tree.Tree_Type;
      Node  : Editor.Ada_Syntax_Tree.Node_Info;
      Owner : Editor.Ada_Language_Model.Symbol_Id)
      return Editor.Ada_Language_Model.Pragma_Placement_Kind;

   function Syntax_Node_Symbol_Kind
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      N    : Editor.Ada_Syntax_Tree.Node_Info)
      return Editor.Ada_Language_Model.Symbol_Kind;

   function Syntax_Node_Flags
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      N    : Editor.Ada_Syntax_Tree.Node_Info)
      return Editor.Ada_Language_Model.Declaration_Flags;

   function Qualified_Name
     (Analysis  : Editor.Ada_Language_Model.Analysis_Result;
      Symbol    : Editor.Ada_Language_Model.Symbol_Info;
      Remaining : Natural;
      Truncated : in out Boolean) return String;

   function Qualified_Name
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Symbol   : Editor.Ada_Language_Model.Symbol_Info) return String;

   function Kind_Compatible
     (Existing : Editor.Ada_Language_Model.Symbol_Kind;
      Wanted   : Editor.Ada_Language_Model.Symbol_Kind) return Boolean;

   function Same_Line_Projection_Compatible
     (Existing : Editor.Ada_Language_Model.Symbol_Kind;
      Wanted   : Editor.Ada_Language_Model.Symbol_Kind) return Boolean;

   function Preferred_Merged_Kind
     (Existing : Editor.Ada_Language_Model.Symbol_Kind;
      Wanted   : Editor.Ada_Language_Model.Symbol_Kind)
      return Editor.Ada_Language_Model.Symbol_Kind;

   function Clean_Projected_Declaration_Name (Name : String) return String;

   function Target_Name_Matches
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Symbol   : Editor.Ada_Language_Model.Symbol_Info;
      Name     : String) return Boolean;

   function Direct_Name_Matches
     (Symbol : Editor.Ada_Language_Model.Symbol_Info;
      Name   : String) return Boolean;

   function Find_Existing
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Name     : String;
      Kind     : Editor.Ada_Language_Model.Symbol_Kind;
      Line     : Positive) return Editor.Ada_Language_Model.Symbol_Id;

   function Parent_Selected_Name
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Symbol   : Editor.Ada_Language_Model.Symbol_Info) return String;

   function Find_Metadata_Target_Direct
     (Analysis    : Editor.Ada_Language_Model.Analysis_Result;
      Target_Name : String) return Editor.Ada_Language_Model.Symbol_Id;

   function Resolve_Renamed_Metadata_Target
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Alias    : Editor.Ada_Language_Model.Symbol_Info;
      Depth    : Natural := 0)
      return Editor.Ada_Language_Model.Symbol_Id;

   function Selected_Prefix_Matches_Target
     (Analysis        : Editor.Ada_Language_Model.Analysis_Result;
      Actual_Parent   : String;
      Requested_Prefix : String) return Boolean;

   function Find_Metadata_Target
     (Analysis    : Editor.Ada_Language_Model.Analysis_Result;
      Target_Name : String) return Editor.Ada_Language_Model.Symbol_Id;

   procedure Apply_Metadata_To_Target
     (Analysis   : in out Editor.Ada_Language_Model.Analysis_Result;
      Target_Name : String;
      Flags      : Editor.Ada_Language_Model.Declaration_Flags);

end Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers;
