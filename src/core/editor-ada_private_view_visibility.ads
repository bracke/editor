with Ada.Containers.Vectors;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;

package Editor.Ada_Private_View_Visibility is

   --  Compiler-grade private-view visibility foundation.  The model is
   --  derived from parser-owned regions and the type graph only; it does not
   --  read files, mutate buffers, or ask the renderer to parse Ada text.

   type Private_View_Status is
     (Private_View_Not_Private_Type,
      Private_View_Full_View_Linked,
      Private_View_Full_View_Unresolved,
      Private_View_Missing_Private_Part);

   type Private_View_Context_Status is
     (Private_View_Context_Unknown,
      Private_View_Context_Partial_Only,
      Private_View_Context_Full_View,
      Private_View_Context_No_Full_View);

   type Private_View_Id is new Natural;
   No_Private_View : constant Private_View_Id := 0;

   type Private_View_Info is record
      Id                  : Private_View_Id := No_Private_View;
      Partial_Type        : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Full_Type           : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Package_Spec_Region : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Package_Body_Region : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Private_Part_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Private_Part_Line   : Positive := 1;
      Status              : Private_View_Status := Private_View_Not_Private_Type;
      Fingerprint         : Natural := 0;
   end record;

   type Private_View_Model is private;

   procedure Clear (Model : in out Private_View_Model);

   function Build
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Types   : Editor.Ada_Type_Graph.Type_Model) return Private_View_Model;

   function Private_View_Count (Model : Private_View_Model) return Natural;

   function Private_View_At
     (Model : Private_View_Model;
      Index : Positive) return Private_View_Info;

   function Private_View_For_Partial
     (Model        : Private_View_Model;
      Partial_Type : Editor.Ada_Type_Graph.Type_Id) return Private_View_Id;

   function Private_View_For_Full
     (Model     : Private_View_Model;
      Full_Type : Editor.Ada_Type_Graph.Type_Id) return Private_View_Id;

   function Private_View_Node
     (Model : Private_View_Model;
      Id    : Private_View_Id) return Private_View_Info;

   function View_Status_At_Line
     (Model        : Private_View_Model;
      Regions      : Editor.Ada_Declarative_Regions.Region_Model;
      Partial_Type : Editor.Ada_Type_Graph.Type_Id;
      Context      : Editor.Ada_Declarative_Regions.Region_Id;
      Source_Line  : Positive) return Private_View_Context_Status;

   function Full_View_Visible_At_Line
     (Model        : Private_View_Model;
      Regions      : Editor.Ada_Declarative_Regions.Region_Model;
      Partial_Type : Editor.Ada_Type_Graph.Type_Id;
      Context      : Editor.Ada_Declarative_Regions.Region_Id;
      Source_Line  : Positive) return Boolean;

   function Effective_Type_At_Line
     (Model       : Private_View_Model;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Type_Node   : Editor.Ada_Type_Graph.Type_Id;
      Context     : Editor.Ada_Declarative_Regions.Region_Id;
      Source_Line : Positive) return Editor.Ada_Type_Graph.Type_Id;

   function Fingerprint (Model : Private_View_Model) return Natural;

private
   package Private_View_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Private_View_Info);

   type Private_View_Model is record
      Views              : Private_View_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Private_View_Visibility;
