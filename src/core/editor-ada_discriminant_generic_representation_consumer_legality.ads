with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Discriminant_Dependent_Legality;
with Editor.Ada_Generic_Replay_Representation_Flow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality is

   --  Pass1161 compiler-grade discriminant/variant consumer legality.
   --
   --  This layer feeds discriminant-dependent legality into the generic replay
   --  and representation/freezing consumer path.  Discriminant constraints,
   --  discriminant defaults, variant choices, private/full-view discriminant
   --  consistency, and discriminant-dependent use sites cannot remain
   --  confidently legal inside instantiated generic body replay or represented
   --  contexts when the underlying discriminant legality is missing, blocked,
   --  or indeterminate.

   package Disc renames Editor.Ada_Discriminant_Dependent_Legality;
   package Gen_Rep renames Editor.Ada_Generic_Replay_Representation_Flow_Consumer_Legality;

   type Discriminant_Generic_Row_Id is new Natural;
   No_Discriminant_Generic_Row : constant Discriminant_Generic_Row_Id := 0;

   type Discriminant_Generic_Context_Kind is
     (Discriminant_Generic_Record_Type,
      Discriminant_Generic_Discriminant_Constraint,
      Discriminant_Generic_Discriminant_Default,
      Discriminant_Generic_Variant_Part,
      Discriminant_Generic_Record_Aggregate,
      Discriminant_Generic_Assignment,
      Discriminant_Generic_Conversion,
      Discriminant_Generic_Return,
      Discriminant_Generic_Allocator,
      Discriminant_Generic_Generic_Actual,
      Discriminant_Generic_Private_Full_View,
      Discriminant_Generic_Generic_Replay,
      Discriminant_Generic_Representation_Clause,
      Discriminant_Generic_Record_Layout,
      Discriminant_Generic_Freezing_Effect,
      Discriminant_Generic_Unknown);

   type Discriminant_Generic_Status is
     (Discriminant_Generic_Not_Checked,
      Discriminant_Generic_Legal_Record_Type_Accepted,
      Discriminant_Generic_Legal_Discriminant_Constraint_Accepted,
      Discriminant_Generic_Legal_Discriminant_Default_Accepted,
      Discriminant_Generic_Legal_Variant_Part_Accepted,
      Discriminant_Generic_Legal_Record_Aggregate_Accepted,
      Discriminant_Generic_Legal_Assignment_Accepted,
      Discriminant_Generic_Legal_Conversion_Accepted,
      Discriminant_Generic_Legal_Return_Accepted,
      Discriminant_Generic_Legal_Allocator_Accepted,
      Discriminant_Generic_Legal_Generic_Actual_Accepted,
      Discriminant_Generic_Legal_Private_Full_View_Accepted,
      Discriminant_Generic_Legal_Generic_Replay_Accepted,
      Discriminant_Generic_Legal_Representation_Clause_Accepted,
      Discriminant_Generic_Legal_Record_Layout_Accepted,
      Discriminant_Generic_Legal_Freezing_Effect_Accepted,
      Discriminant_Generic_Missing_Discriminant_Row,
      Discriminant_Generic_Missing_Generic_Representation_Row,
      Discriminant_Generic_Missing_Discriminant_Constraint,
      Discriminant_Generic_Duplicate_Discriminant_Constraint,
      Discriminant_Generic_Discriminant_Type_Mismatch,
      Discriminant_Generic_Default_Not_Static,
      Discriminant_Generic_Default_Out_Of_Range,
      Discriminant_Generic_Default_Depends_On_Later_Discriminant,
      Discriminant_Generic_Unconstrained_Record_Without_Defaults,
      Discriminant_Generic_Constrained_Object_Discriminant_Changed,
      Discriminant_Generic_Assignment_Discriminant_Mismatch,
      Discriminant_Generic_Conversion_Discriminant_Mismatch,
      Discriminant_Generic_Return_Discriminant_Mismatch,
      Discriminant_Generic_Allocator_Discriminant_Mismatch,
      Discriminant_Generic_Generic_Actual_Discriminant_Mismatch,
      Discriminant_Generic_Variant_Missing_For_Value,
      Discriminant_Generic_Variant_Forbidden_For_Value,
      Discriminant_Generic_Variant_Choice_Overlap,
      Discriminant_Generic_Variant_Choice_Coverage_Gap,
      Discriminant_Generic_Private_Full_View_Mismatch,
      Discriminant_Generic_Linked_Record_Aggregate_Error,
      Discriminant_Generic_Linked_Assignment_Error,
      Discriminant_Generic_Linked_Conversion_Error,
      Discriminant_Generic_Linked_Return_Error,
      Discriminant_Generic_Linked_Generic_Replay_Error,
      Discriminant_Generic_Coverage_Gate_Blocker,
      Discriminant_Generic_Generic_Replay_Error,
      Discriminant_Generic_Generic_Representation_Error,
      Discriminant_Generic_Representation_Flow_Global_Error,
      Discriminant_Generic_Representation_Flow_Depends_Error,
      Discriminant_Generic_Representation_Flow_Propagation_Error,
      Discriminant_Generic_Representation_Flow_Coverage_Blocker,
      Discriminant_Generic_Representation_Flow_Tasking_Error,
      Discriminant_Generic_Multiple_Generic_Representation_Blockers,
      Discriminant_Generic_Multiple_Discriminant_Blockers,
      Discriminant_Generic_Indeterminate);

   type Discriminant_Generic_Context_Info is record
      Id                         : Discriminant_Generic_Row_Id := No_Discriminant_Generic_Row;
      Kind                       : Discriminant_Generic_Context_Kind := Discriminant_Generic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Discriminant_Row           : Disc.Discriminant_Legality_Id := Disc.No_Discriminant_Legality;
      Discriminant_Status        : Disc.Discriminant_Legality_Status := Disc.Discriminant_Legality_Not_Checked;
      Discriminant_Matches       : Natural := 0;
      Generic_Representation_Row : Gen_Rep.Generic_Replay_Representation_Row_Id := Gen_Rep.No_Generic_Replay_Representation_Row;
      Generic_Representation_Status : Gen_Rep.Generic_Replay_Representation_Status := Gen_Rep.Generic_Replay_Representation_Not_Checked;
      Generic_Representation_Matches : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Instance_Fingerprint       : Natural := 0;
   end record;

   type Discriminant_Generic_Info is record
      Id                         : Discriminant_Generic_Row_Id := No_Discriminant_Generic_Row;
      Context                    : Discriminant_Generic_Row_Id := No_Discriminant_Generic_Row;
      Kind                       : Discriminant_Generic_Context_Kind := Discriminant_Generic_Unknown;
      Status                     : Discriminant_Generic_Status := Discriminant_Generic_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Discriminant_Row           : Disc.Discriminant_Legality_Id := Disc.No_Discriminant_Legality;
      Discriminant_Status        : Disc.Discriminant_Legality_Status := Disc.Discriminant_Legality_Not_Checked;
      Discriminant_Matches       : Natural := 0;
      Generic_Representation_Row : Gen_Rep.Generic_Replay_Representation_Row_Id := Gen_Rep.No_Generic_Replay_Representation_Row;
      Generic_Representation_Status : Gen_Rep.Generic_Replay_Representation_Status := Gen_Rep.Generic_Replay_Representation_Not_Checked;
      Generic_Representation_Matches : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Instance_Fingerprint       : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

   type Discriminant_Generic_Context_Model is private;
   type Discriminant_Generic_Set is private;
   type Discriminant_Generic_Model is private;

   procedure Clear (Model : in out Discriminant_Generic_Context_Model);
   procedure Add_Context
     (Model : in out Discriminant_Generic_Context_Model;
      Info  : Discriminant_Generic_Context_Info);

   function Context_Count (Model : Discriminant_Generic_Context_Model) return Natural;
   function Context_At
     (Model : Discriminant_Generic_Context_Model;
      Index : Positive) return Discriminant_Generic_Context_Info;
   function Fingerprint (Model : Discriminant_Generic_Context_Model) return Natural;

   function Build
     (Contexts : Discriminant_Generic_Context_Model) return Discriminant_Generic_Model;

   function Row_Count (Model : Discriminant_Generic_Model) return Natural;
   function Row_At
     (Model : Discriminant_Generic_Model;
      Index : Positive) return Discriminant_Generic_Info;
   function First_For_Node
     (Model : Discriminant_Generic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Discriminant_Generic_Info;
   function Rows_For_Status
     (Model  : Discriminant_Generic_Model;
      Status : Discriminant_Generic_Status) return Discriminant_Generic_Set;
   function Rows_For_Kind
     (Model : Discriminant_Generic_Model;
      Kind  : Discriminant_Generic_Context_Kind) return Discriminant_Generic_Set;
   function Rows_For_Instance
     (Model : Discriminant_Generic_Model;
      Name  : String) return Discriminant_Generic_Set;

   function Set_Count (Set : Discriminant_Generic_Set) return Natural;
   function Set_At
     (Set   : Discriminant_Generic_Set;
      Index : Positive) return Discriminant_Generic_Info;

   function Count_Status
     (Model  : Discriminant_Generic_Model;
      Status : Discriminant_Generic_Status) return Natural;
   function Count_Kind
     (Model : Discriminant_Generic_Model;
      Kind  : Discriminant_Generic_Context_Kind) return Natural;

   function Legal_Count (Model : Discriminant_Generic_Model) return Natural;
   function Error_Count (Model : Discriminant_Generic_Model) return Natural;
   function Discriminant_Error_Count (Model : Discriminant_Generic_Model) return Natural;
   function Variant_Error_Count (Model : Discriminant_Generic_Model) return Natural;
   function Generic_Representation_Error_Count (Model : Discriminant_Generic_Model) return Natural;
   function Flow_Error_Count (Model : Discriminant_Generic_Model) return Natural;
   function Coverage_Error_Count (Model : Discriminant_Generic_Model) return Natural;
   function Indeterminate_Count (Model : Discriminant_Generic_Model) return Natural;
   function Fingerprint (Model : Discriminant_Generic_Model) return Natural;

   function Is_Legal (Status : Discriminant_Generic_Status) return Boolean;
   function Is_Discriminant_Error (Status : Discriminant_Generic_Status) return Boolean;
   function Is_Variant_Error (Status : Discriminant_Generic_Status) return Boolean;
   function Is_Generic_Representation_Error (Status : Discriminant_Generic_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Discriminant_Generic_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Discriminant_Generic_Info);

   type Discriminant_Generic_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Discriminant_Generic_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Discriminant_Generic_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Discriminant_Error_Total : Natural := 0;
      Variant_Error_Total : Natural := 0;
      Generic_Representation_Error_Total : Natural := 0;
      Flow_Error_Total : Natural := 0;
      Coverage_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
