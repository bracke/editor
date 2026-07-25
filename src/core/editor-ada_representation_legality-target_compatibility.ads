with Editor.Ada_Declarative_Regions;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;

package Editor.Ada_Representation_Legality.Target_Compatibility is

   function Compatible_Target_Kind
     (Kind     : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Category : Editor.Ada_Type_Graph.Type_Category) return Boolean;
   function Compatible_Address_Target
     (Kind : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean;
   function Size_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean;
   function Alignment_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean;
   function Storage_Size_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind;
      Category  : Editor.Ada_Type_Graph.Type_Category) return Boolean;
   function Stream_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean;
   function Operational_Target_Compatible
     (Kind      : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Freezable : Editor.Ada_Freezing_Points.Freezable_Kind;
      Category  : Editor.Ada_Type_Graph.Type_Category) return Boolean;
   function Interfacing_Target_Compatible
     (Kind      : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean;
   function Deepest_Region_Containing_Line
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Line    : Positive) return Editor.Ada_Declarative_Regions.Region_Id;
   function Ancestor_Declaration_Target
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String;
   function Freeze_Info_For_Target_At
     (Freezing : Editor.Ada_Freezing_Points.Freezing_Model;
      Regions  : Editor.Ada_Declarative_Regions.Region_Model;
      Line     : Positive;
      Target   : String) return Editor.Ada_Freezing_Points.Representation_Freeze_Info;
   function Type_Category_For_Target
     (Types   : Editor.Ada_Type_Graph.Type_Model;
      Target  : Editor.Ada_Freezing_Points.Freezable_Info)
      return Editor.Ada_Type_Graph.Type_Category;

end Editor.Ada_Representation_Legality.Target_Compatibility;
