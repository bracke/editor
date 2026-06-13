with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declarative_Regions is

   --  Parser-owned declarative-region foundation for later compiler-grade
   --  semantic analysis.  Regions are derived only from the immutable Ada
   --  syntax tree for a caller-supplied snapshot; no files are read, no editor
   --  dirty state is touched, and no renderer-facing parsing is introduced.

   type Region_Kind is
     (Region_Compilation,
      Region_Generic_Formal_Part,
      Region_Package_Spec,
      Region_Package_Body,
      Region_Subprogram_Spec,
      Region_Subprogram_Body,
      Region_Task_Spec,
      Region_Task_Body,
      Region_Protected_Spec,
      Region_Protected_Body,
      Region_Entry_Body,
      Region_Record_Definition,
      Region_Block,
      Region_Unknown);

   type Region_Id is new Natural;
   No_Region : constant Region_Id := 0;

   type Region_Info is record
      Id          : Region_Id := No_Region;
      Kind        : Region_Kind := Region_Unknown;
      Owner_Node  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent      : Region_Id := No_Region;
      Depth       : Natural := 0;
      Start_Line  : Positive := 1;
      End_Line    : Positive := 1;
      Label       : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Region_Model is private;

   procedure Clear (Model : in out Region_Model);
   function Build (Tree : Editor.Ada_Syntax_Tree.Tree_Type) return Region_Model;

   function Has_Regions (Model : Region_Model) return Boolean;
   function Region_Count (Model : Region_Model) return Natural;
   function Region_At (Model : Region_Model; Index : Positive) return Region_Info;
   function Region (Model : Region_Model; Id : Region_Id) return Region_Info;

   function Region_For_Node
     (Model : Region_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Region_Id;

   function Has_Region_For_Node
     (Model : Region_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Boolean;

   function Direct_Child_Count
     (Model  : Region_Model;
      Parent : Region_Id) return Natural;

   function Direct_Child_At
     (Model  : Region_Model;
      Parent : Region_Id;
      Index  : Positive) return Region_Id;

   function Fingerprint (Model : Region_Model) return Natural;

private
   package Region_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Region_Info);

   package Node_Region_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Region_Id);

   type Region_Model is record
      Regions            : Region_Vectors.Vector;
      Node_Region        : Node_Region_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Declarative_Regions;
