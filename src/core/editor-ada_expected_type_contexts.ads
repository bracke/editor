with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Call_Resolution;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Expected_Type_Contexts is

   --  Compiler-grade semantic staging layer for expected-type propagation.
   --  This package attaches deterministic expected-subtype context metadata to
   --  call-shaped expression nodes after profile-based call resolution.  It is
   --  intentionally context-only: it does not yet prove type compatibility,
   --  perform implicit-conversion legality, or resolve overloaded expressions
   --  by expected type.  Later passes can consume these records as the first
   --  expected-type input to full overload resolution and type checking.

   type Expected_Context_Kind is
     (Expected_Context_None,
      Expected_Context_Object_Default,
      Expected_Context_Constant_Default,
      Expected_Context_Declaration_Default,
      Expected_Context_Return_Statement,
      Expected_Context_Assignment_Target,
      Expected_Context_Parameter_Actual);

   type Expected_Context_Status is
     (Expected_Context_Not_Checked,
      Expected_Context_No_Call_Node,
      Expected_Context_No_Context,
      Expected_Context_Context_Without_Subtype,
      Expected_Context_Found);

   type Expected_Context_Id is new Natural;
   No_Expected_Context : constant Expected_Context_Id := 0;

   type Expected_Context_Info is record
      Id                  : Expected_Context_Id := No_Expected_Context;
      Node                : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Context_Node        : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Region              : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Resolution          : Editor.Ada_Call_Resolution.Call_Resolution_Id :=
        Editor.Ada_Call_Resolution.No_Call_Resolution;
      Kind                : Expected_Context_Kind := Expected_Context_None;
      Expected_Subtype    : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Subtype  : Ada.Strings.Unbounded.Unbounded_String;
      Status              : Expected_Context_Status :=
        Expected_Context_Not_Checked;
      Start_Line          : Positive := 1;
      End_Line            : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Expected_Context_Model is private;

   procedure Clear (Model : in out Expected_Context_Model);

   function Build
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Profiles    : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model)
      return Expected_Context_Model;

   function Build
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model)
      return Expected_Context_Model;

   function Has_Expected_Contexts (Model : Expected_Context_Model) return Boolean;
   function Expected_Context_Count (Model : Expected_Context_Model) return Natural;
   function Expected_Context_At
     (Model : Expected_Context_Model;
      Index : Positive) return Expected_Context_Info;
   function Expected_Context
     (Model : Expected_Context_Model;
      Id    : Expected_Context_Id) return Expected_Context_Info;

   function Expected_Context_For_Node
     (Model : Expected_Context_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expected_Context_Info;

   function Count_Status
     (Model  : Expected_Context_Model;
      Status : Expected_Context_Status) return Natural;

   function Count_Kind
     (Model : Expected_Context_Model;
      Kind  : Expected_Context_Kind) return Natural;

   function Fingerprint (Model : Expected_Context_Model) return Natural;

private
   package Expected_Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Expected_Context_Info);

   type Expected_Context_Model is record
      Contexts           : Expected_Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Expected_Type_Contexts;
