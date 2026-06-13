with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Action_Router;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Syntax_Tree;
with Editor.Syntax;

package Editor.Ada_Diagnostic_Command_Projection is

   --  Projection-only command-facing descriptors for Ada diagnostic actions.
   --  This package does not register commands, invoke commands, apply edits,
   --  mutate buffers, parse, save/reload files, touch workspace state, or do
   --  rendering work.  It turns routed diagnostic actions into stable command
   --  descriptors that a later UI/command layer may display or bind explicitly.

   subtype Feed_Entry is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Entry;
   subtype Feed_Severity is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity;
   subtype Feed_Source is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Source;

   type Diagnostic_Command_Descriptor_Id is new Natural;
   No_Diagnostic_Command_Descriptor : constant Diagnostic_Command_Descriptor_Id := 0;

   type Diagnostic_Command_Projection_Status is
     (Diagnostic_Command_Projection_Current,
      Diagnostic_Command_Projection_Rejected_Stale);

   type Diagnostic_Command_Kind is
     (Diagnostic_Command_None,
      Diagnostic_Command_Navigate_To_Diagnostic,
      Diagnostic_Command_Explain_Diagnostic,
      Diagnostic_Command_Review_Expression,
      Diagnostic_Command_Review_Overload_Ranking,
      Diagnostic_Command_Review_Generic,
      Diagnostic_Command_Review_Cross_Unit,
      Diagnostic_Command_Review_Representation);

   type Diagnostic_Command_Availability is
     (Diagnostic_Command_Available,
      Diagnostic_Command_Missing_Target,
      Diagnostic_Command_Incomplete_Target,
      Diagnostic_Command_Status_Only,
      Diagnostic_Command_Rejected_Stale);

   type Diagnostic_Command_Descriptor is record
      Id       : Diagnostic_Command_Descriptor_Id := No_Diagnostic_Command_Descriptor;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id :=
        Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry;
      Feed_Index : Natural := 0;
      Diagnostic : Feed_Entry;
      Severity   : Feed_Severity :=
        Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info;
      Source     : Feed_Source :=
        Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      Token      : Editor.Syntax.Token_Kind := Editor.Syntax.Identifier;
      Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Route_Id   : Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Id :=
        Editor.Ada_Diagnostic_Action_Router.No_Diagnostic_Action_Route;
      Route_Kind : Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Kind :=
        Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_None;
      Command_Kind : Diagnostic_Command_Kind := Diagnostic_Command_None;
      Availability : Diagnostic_Command_Availability := Diagnostic_Command_Missing_Target;
      Command_Name : Ada.Strings.Unbounded.Unbounded_String;
      Display_Label : Ada.Strings.Unbounded.Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String;
      Has_Edit : Boolean := False;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Route_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
   end record;

   type Diagnostic_Command_Descriptor_Set is private;
   type Diagnostic_Command_Projection_Model is private;

   procedure Clear (Model : in out Diagnostic_Command_Projection_Model);

   function Build
     (Routes : Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Router_Model)
      return Diagnostic_Command_Projection_Model;

   function Status
     (Model : Diagnostic_Command_Projection_Model)
      return Diagnostic_Command_Projection_Status;
   function Current (Model : Diagnostic_Command_Projection_Model) return Boolean;
   function Rejected_Stale (Model : Diagnostic_Command_Projection_Model) return Boolean;

   function Descriptor_Count (Model : Diagnostic_Command_Projection_Model) return Natural;
   function Descriptor_At
     (Model : Diagnostic_Command_Projection_Model;
      Index : Positive) return Diagnostic_Command_Descriptor;

   function Available_Command_Count
     (Model : Diagnostic_Command_Projection_Model) return Natural;
   function Missing_Target_Command_Count
     (Model : Diagnostic_Command_Projection_Model) return Natural;
   function Incomplete_Command_Count
     (Model : Diagnostic_Command_Projection_Model) return Natural;
   function Status_Only_Command_Count
     (Model : Diagnostic_Command_Projection_Model) return Natural;
   function Rejected_Command_Count
     (Model : Diagnostic_Command_Projection_Model) return Natural;
   function Editable_Command_Count
     (Model : Diagnostic_Command_Projection_Model) return Natural;

   function Count_Kind
     (Model : Diagnostic_Command_Projection_Model;
      Kind  : Diagnostic_Command_Kind) return Natural;

   function Count_Availability
     (Model        : Diagnostic_Command_Projection_Model;
      Availability : Diagnostic_Command_Availability) return Natural;

   function First_For_Diagnostic
     (Model    : Diagnostic_Command_Projection_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Command_Descriptor;

   function Descriptors_For_Diagnostic
     (Model    : Diagnostic_Command_Projection_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Command_Descriptor_Set;

   function Descriptor_Set_Count (Descriptors : Diagnostic_Command_Descriptor_Set) return Natural;
   function Descriptor_Set_At
     (Descriptors : Diagnostic_Command_Descriptor_Set;
      Index       : Positive) return Diagnostic_Command_Descriptor;

   function Has_Descriptor (Descriptor : Diagnostic_Command_Descriptor) return Boolean;
   function Fingerprint (Model : Diagnostic_Command_Projection_Model) return Natural;

private
   package Descriptor_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Diagnostic_Command_Descriptor);

   type Diagnostic_Command_Descriptor_Set is record
      Descriptors : Descriptor_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Diagnostic_Command_Projection_Model is record
      Model_Status : Diagnostic_Command_Projection_Status := Diagnostic_Command_Projection_Current;
      Descriptors  : Descriptor_Vectors.Vector;
      Available_Total : Natural := 0;
      Missing_Total   : Natural := 0;
      Incomplete_Total : Natural := 0;
      Status_Only_Total : Natural := 0;
      Rejected_Total : Natural := 0;
      Editable_Total : Natural := 0;
      Navigate_Total : Natural := 0;
      Explain_Total  : Natural := 0;
      Expression_Total : Natural := 0;
      Overload_Ranking_Total : Natural := 0;
      Generic_Total : Natural := 0;
      Cross_Unit_Total : Natural := 0;
      Representation_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Diagnostic_Command_Projection;
