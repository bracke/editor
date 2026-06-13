with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Predicate_Invariant_Use_Site_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package Editor.Ada_Predicate_Invariant_Propagation_Legality is

   --  Pass1139 predicate/invariant propagation legality layer.
   --
   --  Pass1124 checks predicates and invariants at individual use sites.  This
   --  package propagates those obligations through calls, flow-effect graph
   --  edges, generic instances, derived/private views, and visible state
   --  updates so a dynamic predicate or invariant obligation is not lost after
   --  the local use-site row has been classified.
   --
   --  Inputs are snapshot-owned semantic facts.  The package performs no
   --  parsing, file IO, dirty-state mutation, command/keybinding/workspace or
   --  render mutation, compiler invocation, external parser generation, or
   --  scripting.

   package PIU renames Editor.Ada_Predicate_Invariant_Use_Site_Legality;
   package FEG renames Editor.Ada_Flow_Effect_Graph_Legality;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

   type Propagation_Row_Id is new Natural;
   No_Propagation_Row : constant Propagation_Row_Id := 0;

   type Propagation_Context_Kind is
     (Propagation_Context_Assignment,
      Propagation_Context_Return,
      Propagation_Context_Conversion,
      Propagation_Context_Call_Source,
      Propagation_Context_Call_Result,
      Propagation_Context_Generic_Instance,
      Propagation_Context_Derived_Type,
      Propagation_Context_Private_View,
      Propagation_Context_Visible_State_Update,
      Propagation_Context_Flow_Effect,
      Propagation_Context_Unknown);

   type Propagation_Obligation_Kind is
     (Obligation_Static_Predicate,
      Obligation_Dynamic_Predicate,
      Obligation_Type_Invariant,
      Obligation_Dynamic_Invariant,
      Obligation_Private_View_Invariant,
      Obligation_Derived_Type_Invariant,
      Obligation_Generic_Actual_Predicate,
      Obligation_Call_Chain_Predicate,
      Obligation_State_Update_Invariant,
      Obligation_Unknown);

   type Propagation_Status is
     (Propagation_Not_Checked,
      Propagation_Legal_Static_Predicate_Preserved,
      Propagation_Legal_Dynamic_Predicate_Propagated,
      Propagation_Legal_Invariant_Preserved,
      Propagation_Legal_Dynamic_Invariant_Propagated,
      Propagation_Legal_Generic_Substitution_Propagated,
      Propagation_Legal_Derived_Invariant_Propagated,
      Propagation_Legal_Private_Full_View_Propagated,
      Propagation_Legal_Flow_Effect_Propagated,
      Propagation_Static_Predicate_Lost,
      Propagation_Dynamic_Predicate_Lost,
      Propagation_Invariant_Lost,
      Propagation_Invariant_Violated_After_State_Update,
      Propagation_Call_Chain_Check_Missing,
      Propagation_Generic_Actual_Check_Missing,
      Propagation_Derived_Type_Invariant_Missing,
      Propagation_Private_View_Barrier,
      Propagation_Private_Full_View_Mismatch,
      Propagation_Flow_Effect_Uncovered_State_Update,
      Propagation_Linked_Predicate_Use_Error,
      Propagation_Linked_Flow_Effect_Error,
      Propagation_Coverage_Gate_Blocker,
      Propagation_Indeterminate);

   type Propagation_Context_Info is record
      Id                    : Propagation_Row_Id := No_Propagation_Row;
      Kind                  : Propagation_Context_Kind := Propagation_Context_Unknown;
      Obligation            : Propagation_Obligation_Kind := Obligation_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subtype_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Formal_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Actual_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Predicate_Use_Status  : PIU.Predicate_Use_Legality_Status :=
        PIU.Predicate_Use_Legality_Not_Checked;
      Flow_Status           : FEG.Flow_Effect_Graph_Status := FEG.Flow_Graph_Not_Checked;
      Gate_Status           : Gates.Enforcement_Status := Gates.Enforcement_Not_Checked;
      Requires_Check        : Boolean := False;
      Check_Propagated      : Boolean := True;
      State_Was_Updated     : Boolean := False;
      State_Covered_By_Flow : Boolean := True;
      Generic_Substitution_Preserves_Check : Boolean := True;
      Derived_View_Preserves_Invariant     : Boolean := True;
      Private_View_Resolved                : Boolean := True;
      Dynamic_Check                        : Boolean := False;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Propagation_Info is record
      Id                    : Propagation_Row_Id := No_Propagation_Row;
      Kind                  : Propagation_Context_Kind := Propagation_Context_Unknown;
      Obligation            : Propagation_Obligation_Kind := Obligation_Unknown;
      Status                : Propagation_Status := Propagation_Not_Checked;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subtype_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Formal_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Actual_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Predicate_Use_Status  : PIU.Predicate_Use_Legality_Status :=
        PIU.Predicate_Use_Legality_Not_Checked;
      Flow_Status           : FEG.Flow_Effect_Graph_Status := FEG.Flow_Graph_Not_Checked;
      Gate_Status           : Gates.Enforcement_Status := Gates.Enforcement_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Propagation_Context_Model is private;
   type Propagation_Set is private;
   type Propagation_Model is private;

   procedure Clear (Model : in out Propagation_Context_Model);
   procedure Add_Context
     (Model : in out Propagation_Context_Model;
      Info  : Propagation_Context_Info);

   procedure Add_From_Predicate_Use_Row
     (Model : in out Propagation_Context_Model;
      Row   : PIU.Predicate_Use_Legality_Info);
   procedure Add_From_Flow_Effect_Row
     (Model : in out Propagation_Context_Model;
      Row   : FEG.Flow_Effect_Info);

   function Context_Count (Model : Propagation_Context_Model) return Natural;
   function Context_At
     (Model : Propagation_Context_Model;
      Index : Positive) return Propagation_Context_Info;
   function Fingerprint (Model : Propagation_Context_Model) return Natural;

   function Build (Contexts : Propagation_Context_Model) return Propagation_Model;
   function Build_From_Predicate_Uses
     (Uses : PIU.Predicate_Use_Legality_Model) return Propagation_Model;

   function Row_Count (Model : Propagation_Model) return Natural;
   function Row_At
     (Model : Propagation_Model;
      Index : Positive) return Propagation_Info;
   function First_For_Node
     (Model : Propagation_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Propagation_Info;

   function Rows_For_Status
     (Model  : Propagation_Model;
      Status : Propagation_Status) return Propagation_Set;
   function Rows_For_Kind
     (Model : Propagation_Model;
      Kind  : Propagation_Context_Kind) return Propagation_Set;
   function Rows_For_Subtype
     (Model        : Propagation_Model;
      Subtype_Name : String) return Propagation_Set;
   function Rows_For_Object
     (Model : Propagation_Model;
      Name  : String) return Propagation_Set;

   function Set_Count (Set : Propagation_Set) return Natural;
   function Set_At
     (Set   : Propagation_Set;
      Index : Positive) return Propagation_Info;

   function Count_Status
     (Model  : Propagation_Model;
      Status : Propagation_Status) return Natural;
   function Count_Kind
     (Model : Propagation_Model;
      Kind  : Propagation_Context_Kind) return Natural;

   function Legal_Count (Model : Propagation_Model) return Natural;
   function Error_Count (Model : Propagation_Model) return Natural;
   function Predicate_Error_Count (Model : Propagation_Model) return Natural;
   function Invariant_Error_Count (Model : Propagation_Model) return Natural;
   function Generic_Error_Count (Model : Propagation_Model) return Natural;
   function Flow_Error_Count (Model : Propagation_Model) return Natural;
   function Coverage_Gate_Error_Count (Model : Propagation_Model) return Natural;
   function Indeterminate_Count (Model : Propagation_Model) return Natural;
   function Fingerprint (Model : Propagation_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Propagation_Context_Info);
   package Info_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Propagation_Info);

   type Propagation_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Propagation_Set is record
      Items : Info_Vectors.Vector;
   end record;

   type Propagation_Model is record
      Items       : Info_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Predicate_Invariant_Propagation_Legality;
