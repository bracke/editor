with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Private_View_Visibility;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;

package Editor.Ada_Freezing_Interactions is

   --  Compiler-grade freezing interaction layer.  This package projects
   --  generic instantiations, private/full-view visibility, and body contexts
   --  onto the already staged freezing-point model.  It is snapshot-owned and
   --  does not perform file I/O, rendering-side parsing, or buffer mutation.

   type Freezing_Interaction_Status is
     (Freezing_Interaction_Generic_Instance_Freezes_Target,
      Freezing_Interaction_Generic_Target_Unresolved,
      Freezing_Interaction_Generic_Target_Ambiguous,
      Freezing_Interaction_Generic_Target_Not_Freezable,
      Freezing_Interaction_Private_Partial_View,
      Freezing_Interaction_Private_Full_View_Visible,
      Freezing_Interaction_Private_Full_View_Hidden,
      Freezing_Interaction_Private_Full_View_Unresolved,
      Freezing_Interaction_Body_Context,
      Freezing_Interaction_Unknown);

   type Freezing_Interaction_Id is new Natural;
   No_Freezing_Interaction : constant Freezing_Interaction_Id := 0;

   type Freezing_Interaction_Info is record
      Id              : Freezing_Interaction_Id := No_Freezing_Interaction;
      Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Region          : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Line            : Positive := 1;
      Name            : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name : Ada.Strings.Unbounded.Unbounded_String;
      Freezable       : Editor.Ada_Freezing_Points.Freezable_Id :=
        Editor.Ada_Freezing_Points.No_Freezable;
      Partial_Type    : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Full_Type       : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Private_View    : Editor.Ada_Private_View_Visibility.Private_View_Id :=
        Editor.Ada_Private_View_Visibility.No_Private_View;
      Instance        : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Status          : Freezing_Interaction_Status := Freezing_Interaction_Unknown;
      Fingerprint     : Natural := 0;
   end record;

   type Freezing_Interaction_Model is private;

   procedure Clear (Model : in out Freezing_Interaction_Model);

   function Build
     (Tree          : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions       : Editor.Ada_Declarative_Regions.Region_Model;
      Freezing      : Editor.Ada_Freezing_Points.Freezing_Model;
      Types         : Editor.Ada_Type_Graph.Type_Model;
      Private_Views : Editor.Ada_Private_View_Visibility.Private_View_Model;
      Generics      : Editor.Ada_Generic_Contracts.Generic_Contract_Model)
      return Freezing_Interaction_Model;

   function Interaction_Count (Model : Freezing_Interaction_Model) return Natural;

   function Interaction_At
     (Model : Freezing_Interaction_Model;
      Index : Positive) return Freezing_Interaction_Info;

   function Generic_Instance_Freeze_Count
     (Model : Freezing_Interaction_Model) return Natural;

   function Generic_Instance_Target_Error_Count
     (Model : Freezing_Interaction_Model) return Natural;

   function Private_Partial_View_Count
     (Model : Freezing_Interaction_Model) return Natural;

   function Private_Full_View_Visible_Count
     (Model : Freezing_Interaction_Model) return Natural;

   function Private_Full_View_Hidden_Count
     (Model : Freezing_Interaction_Model) return Natural;

   function Body_Context_Count
     (Model : Freezing_Interaction_Model) return Natural;

   function Fingerprint (Model : Freezing_Interaction_Model) return Natural;

private
   package Interaction_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Freezing_Interaction_Info);

   type Freezing_Interaction_Model is record
      Interactions       : Interaction_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Freezing_Interactions;
