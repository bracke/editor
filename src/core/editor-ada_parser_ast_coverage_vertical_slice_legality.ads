with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Parser_AST_Coverage_Vertical_Slice_Legality is

   --  Case 1304 vertical-slice parser/AST coverage legality.  This package
   --  models concrete Ada 2022 constructs whose degraded/token-only parsing
   --  blocks real semantic consumers.  It is intentionally a parser/AST
   --  semantic slice, not another diagnostic, provenance, or stabilization
   --  wrapper.

   type Construct_Id is new Natural;
   No_Construct : constant Construct_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Construct_Kind is
     (Construct_Quantified_Expression,
      Construct_Reduction_Expression,
      Construct_Delta_Aggregate,
      Construct_Container_Aggregate,
      Construct_Declare_Expression,
      Construct_Target_Name_Update,
      Construct_Parallel_Loop,
      Construct_Generalized_Indexing,
      Construct_Unknown);

   type Consumer_Kind is
     (Consumer_Overload,
      Consumer_Generic,
      Consumer_Freezing_Representation,
      Consumer_Accessibility,
      Consumer_Elaboration,
      Consumer_Tasking,
      Consumer_Global_Depends,
      Consumer_Remaining_RM_Edge,
      Consumer_Unknown);

   type Coverage_Status is
     (Coverage_Not_Checked,
      Coverage_Legal_AST,
      Coverage_Legal_Semantic_Consumer,
      Coverage_Missing_Parser_Node,
      Coverage_Token_Only_Construct,
      Coverage_Degraded_Construct,
      Coverage_Missing_Source_Span,
      Coverage_Missing_Primary_Child,
      Coverage_Missing_Secondary_Child,
      Coverage_Missing_Type_Metadata,
      Coverage_Missing_Semantic_Consumer,
      Coverage_Wrong_Construct_Kind,
      Coverage_Source_Fingerprint_Mismatch,
      Coverage_AST_Fingerprint_Mismatch,
      Coverage_Multiple_Blockers,
      Coverage_Indeterminate);

   type Construct_Info is record
      Id       : Construct_Id := No_Construct;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Construct_Kind := Construct_Unknown;
      Consumer : Consumer_Kind := Consumer_Unknown;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;
      Has_Parser_Node : Boolean := True;
      Is_Token_Only : Boolean := False;
      Is_Degraded : Boolean := False;
      Has_Source_Span : Boolean := True;
      Has_Primary_Child : Boolean := True;
      Has_Secondary_Child : Boolean := True;
      Has_Type_Metadata : Boolean := True;
      Has_Semantic_Consumer : Boolean := True;
      Expected_Kind : Construct_Kind := Construct_Unknown;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Construct : Construct_Id := No_Construct;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Construct_Kind := Construct_Unknown;
      Consumer : Consumer_Kind := Consumer_Unknown;
      Status   : Coverage_Status := Coverage_Not_Checked;
      Parser_Node_Blockers : Natural := 0;
      Token_Only_Blockers : Natural := 0;
      Degraded_Blockers : Natural := 0;
      Source_Span_Blockers : Natural := 0;
      Primary_Child_Blockers : Natural := 0;
      Secondary_Child_Blockers : Natural := 0;
      Metadata_Blockers : Natural := 0;
      Consumer_Blockers : Natural := 0;
      Wrong_Kind_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Construct_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Construct_Model);
   procedure Add_Construct (Model : in out Construct_Model; Info : Construct_Info);

   function Build (Constructs : Construct_Model) return Result_Model;

   function Construct_Count (Model : Construct_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Coverage_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Construct_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Construct_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Construct_Model is record
      Items : Construct_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Parser_AST_Coverage_Vertical_Slice_Legality;
