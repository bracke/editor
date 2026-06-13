with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
with Editor.Ada_Discriminant_Variant_AST_Repair_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality is

   --  Pass1182 compiler-grade discriminant/variant consumer integration.
   --
   --  This layer makes discriminant and variant facts mandatory evidence for the
   --  hard consumers that still depend on discriminated type semantics: record
   --  layout, aggregate legality, freezing/representation propagation,
   --  accessibility of access discriminants, generic instance replay/backmapping,
   --  and private/full-view discriminant consistency.  A downstream conclusion is
   --  not allowed to remain confidently legal when discriminant/variant evidence,
   --  repaired AST coverage, representation/freezing CPD evidence, or generic
   --  replay source/instance backmapping is missing, blocked, duplicated, or
   --  indeterminate.

   package Disc_Generic renames Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
   package Disc_AST renames Editor.Ada_Discriminant_Variant_AST_Repair_Legality;
   package Rep_CPD renames Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   package Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;

   type Discriminant_Consumer_Row_Id is new Natural;
   No_Discriminant_Consumer_Row : constant Discriminant_Consumer_Row_Id := 0;

   type Discriminant_Consumer_Context_Kind is
     (Discriminant_Consumer_Record_Layout,
      Discriminant_Consumer_Record_Aggregate,
      Discriminant_Consumer_Extension_Aggregate,
      Discriminant_Consumer_Assignment,
      Discriminant_Consumer_Conversion,
      Discriminant_Consumer_Return,
      Discriminant_Consumer_Allocator,
      Discriminant_Consumer_Access_Discriminant,
      Discriminant_Consumer_Freezing_Effect,
      Discriminant_Consumer_Representation_Clause,
      Discriminant_Consumer_Generic_Replay,
      Discriminant_Consumer_Private_Full_View,
      Discriminant_Consumer_Unknown);

   type Discriminant_Consumer_Status is
     (Discriminant_Consumer_Not_Checked,
      Discriminant_Consumer_Legal_Record_Layout_Accepted,
      Discriminant_Consumer_Legal_Record_Aggregate_Accepted,
      Discriminant_Consumer_Legal_Extension_Aggregate_Accepted,
      Discriminant_Consumer_Legal_Assignment_Accepted,
      Discriminant_Consumer_Legal_Conversion_Accepted,
      Discriminant_Consumer_Legal_Return_Accepted,
      Discriminant_Consumer_Legal_Allocator_Accepted,
      Discriminant_Consumer_Legal_Access_Discriminant_Accepted,
      Discriminant_Consumer_Legal_Freezing_Effect_Accepted,
      Discriminant_Consumer_Legal_Representation_Clause_Accepted,
      Discriminant_Consumer_Legal_Generic_Replay_Accepted,
      Discriminant_Consumer_Legal_Private_Full_View_Accepted,
      Discriminant_Consumer_Missing_Discriminant_Generic_Row,
      Discriminant_Consumer_Discriminant_Generic_Blocker,
      Discriminant_Consumer_Discriminant_Generic_Indeterminate,
      Discriminant_Consumer_Missing_AST_Repair_Row,
      Discriminant_Consumer_AST_Repair_Blocker,
      Discriminant_Consumer_AST_Repair_Indeterminate,
      Discriminant_Consumer_Missing_Representation_CPD_Row,
      Discriminant_Consumer_Representation_CPD_Blocker,
      Discriminant_Consumer_Representation_CPD_Indeterminate,
      Discriminant_Consumer_Missing_Generic_Backmap_Row,
      Discriminant_Consumer_Generic_Backmap_Blocker,
      Discriminant_Consumer_Generic_Backmap_Indeterminate,
      Discriminant_Consumer_Record_Layout_Discriminant_Blocker,
      Discriminant_Consumer_Aggregate_Discriminant_Blocker,
      Discriminant_Consumer_Access_Discriminant_Lifetime_Blocker,
      Discriminant_Consumer_Private_Full_View_Mismatch_Blocker,
      Discriminant_Consumer_Variant_Coverage_Blocker,
      Discriminant_Consumer_Freezing_Discriminant_Blocker,
      Discriminant_Consumer_Generic_Replay_Discriminant_Blocker,
      Discriminant_Consumer_Multiple_Discriminant_Generic_Blockers,
      Discriminant_Consumer_Multiple_AST_Repair_Blockers,
      Discriminant_Consumer_Multiple_Representation_CPD_Blockers,
      Discriminant_Consumer_Multiple_Generic_Backmap_Blockers,
      Discriminant_Consumer_Indeterminate);

   type Discriminant_Consumer_Context_Info is record
      Id                         : Discriminant_Consumer_Row_Id := No_Discriminant_Consumer_Row;
      Kind                       : Discriminant_Consumer_Context_Kind := Discriminant_Consumer_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Discriminant_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Variant_Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Consumer_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Disc_Generic_Row           : Disc_Generic.Discriminant_Generic_Row_Id := Disc_Generic.No_Discriminant_Generic_Row;
      Disc_Generic_Status        : Disc_Generic.Discriminant_Generic_Status := Disc_Generic.Discriminant_Generic_Not_Checked;
      Disc_Generic_Matches       : Natural := 0;
      AST_Repair_Row             : Disc_AST.Discriminant_Variant_AST_Repair_Row_Id := Disc_AST.No_Discriminant_Variant_AST_Repair_Row;
      AST_Repair_Status          : Disc_AST.Discriminant_Variant_AST_Repair_Status := Disc_AST.Discriminant_Variant_AST_Not_Checked;
      AST_Repair_Matches         : Natural := 0;
      Representation_CPD_Row     : Rep_CPD.Representation_Tasking_CPD_Row_Id := Rep_CPD.No_Representation_Tasking_CPD_Row;
      Representation_CPD_Status  : Rep_CPD.Representation_Tasking_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Not_Checked;
      Representation_CPD_Matches : Natural := 0;
      Generic_Backmap_Row        : Backmap.Generic_Backmap_Row_Id := Backmap.No_Generic_Backmap_Row;
      Generic_Backmap_Status     : Backmap.Generic_Backmap_Status := Backmap.Generic_Backmap_Not_Checked;
      Generic_Backmap_Matches    : Natural := 0;
      Requires_Generic_Backmap   : Boolean := False;
      Requires_Representation_CPD : Boolean := True;
      Requires_AST_Repair        : Boolean := True;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Consumer_Fingerprint       : Natural := 0;
   end record;

   type Discriminant_Consumer_Info is record
      Id                         : Discriminant_Consumer_Row_Id := No_Discriminant_Consumer_Row;
      Context                    : Discriminant_Consumer_Row_Id := No_Discriminant_Consumer_Row;
      Kind                       : Discriminant_Consumer_Context_Kind := Discriminant_Consumer_Unknown;
      Status                     : Discriminant_Consumer_Status := Discriminant_Consumer_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Discriminant_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Variant_Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Consumer_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Disc_Generic_Row           : Disc_Generic.Discriminant_Generic_Row_Id := Disc_Generic.No_Discriminant_Generic_Row;
      Disc_Generic_Status        : Disc_Generic.Discriminant_Generic_Status := Disc_Generic.Discriminant_Generic_Not_Checked;
      AST_Repair_Row             : Disc_AST.Discriminant_Variant_AST_Repair_Row_Id := Disc_AST.No_Discriminant_Variant_AST_Repair_Row;
      AST_Repair_Status          : Disc_AST.Discriminant_Variant_AST_Repair_Status := Disc_AST.Discriminant_Variant_AST_Not_Checked;
      Representation_CPD_Row     : Rep_CPD.Representation_Tasking_CPD_Row_Id := Rep_CPD.No_Representation_Tasking_CPD_Row;
      Representation_CPD_Status  : Rep_CPD.Representation_Tasking_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Not_Checked;
      Generic_Backmap_Row        : Backmap.Generic_Backmap_Row_Id := Backmap.No_Generic_Backmap_Row;
      Generic_Backmap_Status     : Backmap.Generic_Backmap_Status := Backmap.Generic_Backmap_Not_Checked;
      Source_Fingerprint         : Natural := 0;
      Consumer_Fingerprint       : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

   type Discriminant_Consumer_Context_Model is private;
   type Discriminant_Consumer_Set is private;
   type Discriminant_Consumer_Model is private;

   procedure Clear (Model : in out Discriminant_Consumer_Context_Model);
   procedure Add_Context
     (Model : in out Discriminant_Consumer_Context_Model;
      Info  : Discriminant_Consumer_Context_Info);

   function Context_Count (Model : Discriminant_Consumer_Context_Model) return Natural;
   function Context_At
     (Model : Discriminant_Consumer_Context_Model;
      Index : Positive) return Discriminant_Consumer_Context_Info;
   function Fingerprint (Model : Discriminant_Consumer_Context_Model) return Natural;

   function Build (Contexts : Discriminant_Consumer_Context_Model) return Discriminant_Consumer_Model;

   function Row_Count (Model : Discriminant_Consumer_Model) return Natural;
   function Row_At
     (Model : Discriminant_Consumer_Model;
      Index : Positive) return Discriminant_Consumer_Info;
   function First_For_Node
     (Model : Discriminant_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Discriminant_Consumer_Info;
   function Rows_For_Status
     (Model  : Discriminant_Consumer_Model;
      Status : Discriminant_Consumer_Status) return Discriminant_Consumer_Set;
   function Rows_For_Kind
     (Model : Discriminant_Consumer_Model;
      Kind  : Discriminant_Consumer_Context_Kind) return Discriminant_Consumer_Set;
   function Rows_For_Type
     (Model : Discriminant_Consumer_Model;
      Name  : String) return Discriminant_Consumer_Set;

   function Set_Count (Set : Discriminant_Consumer_Set) return Natural;
   function Set_At
     (Set   : Discriminant_Consumer_Set;
      Index : Positive) return Discriminant_Consumer_Info;

   function Count_Status
     (Model  : Discriminant_Consumer_Model;
      Status : Discriminant_Consumer_Status) return Natural;
   function Count_Kind
     (Model : Discriminant_Consumer_Model;
      Kind  : Discriminant_Consumer_Context_Kind) return Natural;

   function Legal_Count (Model : Discriminant_Consumer_Model) return Natural;
   function Error_Count (Model : Discriminant_Consumer_Model) return Natural;
   function Discriminant_Error_Count (Model : Discriminant_Consumer_Model) return Natural;
   function AST_Repair_Error_Count (Model : Discriminant_Consumer_Model) return Natural;
   function Representation_Error_Count (Model : Discriminant_Consumer_Model) return Natural;
   function Generic_Backmap_Error_Count (Model : Discriminant_Consumer_Model) return Natural;
   function Indeterminate_Count (Model : Discriminant_Consumer_Model) return Natural;
   function Fingerprint (Model : Discriminant_Consumer_Model) return Natural;

   function Is_Legal (Status : Discriminant_Consumer_Status) return Boolean;
   function Is_Discriminant_Error (Status : Discriminant_Consumer_Status) return Boolean;
   function Is_AST_Repair_Error (Status : Discriminant_Consumer_Status) return Boolean;
   function Is_Representation_Error (Status : Discriminant_Consumer_Status) return Boolean;
   function Is_Generic_Backmap_Error (Status : Discriminant_Consumer_Status) return Boolean;
   function Is_Indeterminate (Status : Discriminant_Consumer_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Discriminant_Consumer_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Discriminant_Consumer_Info);

   type Discriminant_Consumer_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Discriminant_Consumer_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Discriminant_Consumer_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Discriminant_Error_Total : Natural := 0;
      AST_Repair_Error_Total : Natural := 0;
      Representation_Error_Total : Natural := 0;
      Generic_Backmap_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
