with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;

package Editor.Ada_Freezing_Points is

   --  Compiler-grade freezing-point foundation.  The model is derived only
   --  from the parser-owned syntax tree, declarative regions, direct
   --  visibility, and the type graph for the caller's immutable snapshot.
   --  It records conservative first-freezing uses so representation legality
   --  can later reject clauses that appear after their target is frozen.

   type Freezable_Kind is
     (Freezable_Type,
      Freezable_Subtype,
      Freezable_Subprogram,
      Freezable_Object,
      Freezable_Unknown);

   type Freezing_Cause is
     (Freezing_Cause_None,
      Freezing_Cause_Object_Declaration,
      Freezing_Cause_Subprogram_Body,
      Freezing_Cause_Instantiation,
      Freezing_Cause_Representation_Clause,
      Freezing_Cause_Unknown);

   type Freezing_Status is
     (Freezing_Not_Frozen,
      Freezing_Frozen,
      Freezing_Target_Unresolved,
      Freezing_Target_Ambiguous);

   type Representation_Freezing_Status is
     (Representation_Target_Unresolved,
      Representation_Target_Ambiguous,
      Representation_Target_Not_Freezable,
      Representation_Before_Freezing,
      Representation_At_Freezing_Point,
      Representation_After_Freezing,
      Representation_Target_Not_Frozen);

   type Freezable_Id is new Natural;
   No_Freezable : constant Freezable_Id := 0;

   type Freezable_Info is record
      Id                 : Freezable_Id := No_Freezable;
      Kind               : Freezable_Kind := Freezable_Unknown;
      Declaration        : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Type_Node          : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Region             : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Name               : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Declaration_Line   : Positive := 1;
      First_Freeze_Line  : Positive := 1;
      First_Freeze_Node  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Cause              : Freezing_Cause := Freezing_Cause_None;
      Status             : Freezing_Status := Freezing_Not_Frozen;
      Fingerprint        : Natural := 0;
   end record;

   type Representation_Freeze_Info is record
      Clause_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target: Ada.Strings.Unbounded.Unbounded_String;
      Target           : Freezable_Id := No_Freezable;
      Clause_Line      : Positive := 1;
      Freeze_Line      : Positive := 1;
      Status           : Representation_Freezing_Status := Representation_Target_Unresolved;
      Fingerprint      : Natural := 0;
   end record;

   type Freezing_Model is private;

   procedure Clear (Model : in out Freezing_Model);

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model) return Freezing_Model;

   function Freezable_Count (Model : Freezing_Model) return Natural;

   function Freezable_At
     (Model : Freezing_Model;
      Index : Positive) return Freezable_Info;

   function Freezable_Node
     (Model : Freezing_Model;
      Id    : Freezable_Id) return Freezable_Info;

   function Lookup_Freezable
     (Model  : Freezing_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Freezable_Id;

   function Freezing_Status_For
     (Model  : Freezing_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Freezing_Status;

   function Representation_Check_Count (Model : Freezing_Model) return Natural;

   function Representation_Check_At
     (Model : Freezing_Model;
      Index : Positive) return Representation_Freeze_Info;

   function Representation_Check_For_Clause
     (Model : Freezing_Model;
      Clause: Editor.Ada_Syntax_Tree.Node_Id) return Representation_Freeze_Info;

   function Fingerprint (Model : Freezing_Model) return Natural;

private
   package Freezable_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Freezable_Info);

   package Representation_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Freeze_Info);

   type Freezing_Model is record
      Freezables         : Freezable_Vectors.Vector;
      Representations    : Representation_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Freezing_Points;
