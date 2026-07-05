with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration is

   --  Case 1285 diagnostic integration for remaining RM edge stabilized
   --  closure consumers.
   --
   --  This package consumes Case 1284 remaining RM edge stabilized consumer
   --  rows.  Accepted remaining-edge rows are withheld as current semantic
   --  evidence; blockers are emitted with their original remaining-edge or
   --  stabilized-closure blocker family preserved.  The model is deterministic,
   --  bounded, snapshot-owned, and side-effect-free.

   package Consumer renames Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Consumer_Legality;
   package Edge renames Consumer.Edge;
   package Closure renames Consumer.Closure;

   subtype Remaining_RM_Edge_Stabilized_Consumer_Id is Consumer.Remaining_RM_Edge_Stabilized_Consumer_Id;
   subtype Remaining_RM_Edge_Stabilized_Consumer_Status is Consumer.Remaining_RM_Edge_Stabilized_Consumer_Status;
   subtype Remaining_RM_Edge_Stabilized_Consumer_Blocker is Consumer.Remaining_RM_Edge_Stabilized_Consumer_Blocker;
   subtype Remaining_RM_Edge_Kind is Edge.Remaining_RM_Edge_Kind;
   subtype Remaining_RM_Edge_Blocker_Family is Edge.Remaining_RM_Edge_Blocker_Family;

   type Remaining_RM_Edge_Stabilized_Diagnostic_Id is new Natural;
   No_Remaining_RM_Edge_Stabilized_Diagnostic : constant Remaining_RM_Edge_Stabilized_Diagnostic_Id := 0;

   type Remaining_RM_Edge_Stabilized_Diagnostic_Family is
     (Remaining_RM_Edge_Stabilized_Diagnostic_Accepted,
      Remaining_RM_Edge_Stabilized_Diagnostic_Remaining_Edge,
      Remaining_RM_Edge_Stabilized_Diagnostic_Stabilized_Closure,
      Remaining_RM_Edge_Stabilized_Diagnostic_Source_Fingerprint,
      Remaining_RM_Edge_Stabilized_Diagnostic_Substitution_Fingerprint,
      Remaining_RM_Edge_Stabilized_Diagnostic_Multiple,
      Remaining_RM_Edge_Stabilized_Diagnostic_Indeterminate,
      Remaining_RM_Edge_Stabilized_Diagnostic_Recheck_Required,
      Remaining_RM_Edge_Stabilized_Diagnostic_Unknown);

   type Remaining_RM_Edge_Stabilized_Diagnostic_Severity is
     (Remaining_RM_Edge_Stabilized_Diagnostic_Info,
      Remaining_RM_Edge_Stabilized_Diagnostic_Warning,
      Remaining_RM_Edge_Stabilized_Diagnostic_Error);

   type Remaining_RM_Edge_Stabilized_Diagnostic_Status is
     (Remaining_RM_Edge_Stabilized_Diagnostic_Not_Checked,
      Remaining_RM_Edge_Stabilized_Diagnostic_Withheld_Accepted_Current,
      Remaining_RM_Edge_Stabilized_Diagnostic_Withheld_Accepted_Not_Required,
      Remaining_RM_Edge_Stabilized_Diagnostic_Remaining_Edge_Blocker,
      Remaining_RM_Edge_Stabilized_Diagnostic_Missing_Stabilized_Closure,
      Remaining_RM_Edge_Stabilized_Diagnostic_Stabilized_Closure_Blocker,
      Remaining_RM_Edge_Stabilized_Diagnostic_Stabilized_Closure_Recheck_Required,
      Remaining_RM_Edge_Stabilized_Diagnostic_Source_Fingerprint_Mismatch,
      Remaining_RM_Edge_Stabilized_Diagnostic_Substitution_Fingerprint_Mismatch,
      Remaining_RM_Edge_Stabilized_Diagnostic_Multiple_Blockers,
      Remaining_RM_Edge_Stabilized_Diagnostic_Indeterminate);

   type Remaining_RM_Edge_Stabilized_Diagnostic_Row is record
      Id                         : Remaining_RM_Edge_Stabilized_Diagnostic_Id := No_Remaining_RM_Edge_Stabilized_Diagnostic;
      Consumer_Row               : Remaining_RM_Edge_Stabilized_Consumer_Id := Consumer.No_Remaining_RM_Edge_Stabilized_Consumer;
      Consumer_Status            : Remaining_RM_Edge_Stabilized_Consumer_Status := Consumer.Remaining_RM_Edge_Stabilized_Consumer_Not_Checked;
      Consumer_Blocker           : Remaining_RM_Edge_Stabilized_Consumer_Blocker := Consumer.Remaining_RM_Edge_Stabilized_Blocker_None;
      Remaining_Edge_Row         : Edge.Remaining_RM_Edge_Precision_Id := Edge.No_Remaining_RM_Edge_Precision;
      Remaining_Edge_Kind        : Remaining_RM_Edge_Kind := Edge.Remaining_RM_Edge_Unknown;
      Remaining_Edge_Status      : Edge.Remaining_RM_Edge_Status := Edge.Remaining_RM_Edge_Not_Checked;
      Remaining_Edge_Blocker     : Remaining_RM_Edge_Blocker_Family := Edge.Remaining_RM_Edge_Blocker_None;
      Stabilized_Closure_Row     : Closure.RM_Closure_Consumer_Stabilized_Closure_Id := Closure.No_RM_Closure_Consumer_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.RM_Closure_Consumer_Stabilized_Closure_Status := Closure.RM_Closure_Consumer_Stabilized_Closure_Not_Checked;
      Status                     : Remaining_RM_Edge_Stabilized_Diagnostic_Status := Remaining_RM_Edge_Stabilized_Diagnostic_Not_Checked;
      Family                     : Remaining_RM_Edge_Stabilized_Diagnostic_Family := Remaining_RM_Edge_Stabilized_Diagnostic_Unknown;
      Severity                   : Remaining_RM_Edge_Stabilized_Diagnostic_Severity := Remaining_RM_Edge_Stabilized_Diagnostic_Warning;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Edge_Fingerprint           : Natural := 0;
      Closure_Fingerprint        : Natural := 0;
      Consumer_Fingerprint       : Natural := 0;
      Diagnostic_Fingerprint     : Natural := 0;
      Emitted                    : Boolean := False;
      Withheld_Current           : Boolean := False;
      Requires_Recheck           : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Remaining_RM_Edge_Stabilized_Diagnostic_Set is private;
   type Remaining_RM_Edge_Stabilized_Diagnostic_Model is private;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilized_Diagnostic_Model);

   function Build
     (Consumers : Consumer.Remaining_RM_Edge_Stabilized_Consumer_Model)
      return Remaining_RM_Edge_Stabilized_Diagnostic_Model;

   function Row_Count (Model : Remaining_RM_Edge_Stabilized_Diagnostic_Model) return Natural;
   function Row_At
     (Model : Remaining_RM_Edge_Stabilized_Diagnostic_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Diagnostic_Row;

   function Query_Count (Set : Remaining_RM_Edge_Stabilized_Diagnostic_Set) return Natural;
   function Query_At
     (Set   : Remaining_RM_Edge_Stabilized_Diagnostic_Set;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Diagnostic_Row;

   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilized_Diagnostic_Model;
      Status : Remaining_RM_Edge_Stabilized_Diagnostic_Status)
      return Remaining_RM_Edge_Stabilized_Diagnostic_Set;
   function Query_Family
     (Model  : Remaining_RM_Edge_Stabilized_Diagnostic_Model;
      Family : Remaining_RM_Edge_Stabilized_Diagnostic_Family)
      return Remaining_RM_Edge_Stabilized_Diagnostic_Set;
   function Query_Edge_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Diagnostic_Model;
      Blocker : Remaining_RM_Edge_Blocker_Family)
      return Remaining_RM_Edge_Stabilized_Diagnostic_Set;
   function Query_Node
     (Model : Remaining_RM_Edge_Stabilized_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Remaining_RM_Edge_Stabilized_Diagnostic_Set;
   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Diagnostic_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Diagnostic_Set;

   function Count_Status
     (Model  : Remaining_RM_Edge_Stabilized_Diagnostic_Model;
      Status : Remaining_RM_Edge_Stabilized_Diagnostic_Status) return Natural;
   function Count_Family
     (Model  : Remaining_RM_Edge_Stabilized_Diagnostic_Model;
      Family : Remaining_RM_Edge_Stabilized_Diagnostic_Family) return Natural;
   function Count_Edge_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Diagnostic_Model;
      Blocker : Remaining_RM_Edge_Blocker_Family) return Natural;
   function Error_Count (Model : Remaining_RM_Edge_Stabilized_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Remaining_RM_Edge_Stabilized_Diagnostic_Model) return Natural;
   function Info_Count (Model : Remaining_RM_Edge_Stabilized_Diagnostic_Model) return Natural;
   function Emitted_Count (Model : Remaining_RM_Edge_Stabilized_Diagnostic_Model) return Natural;
   function Withheld_Current_Count (Model : Remaining_RM_Edge_Stabilized_Diagnostic_Model) return Natural;
   function Recheck_Required_Count (Model : Remaining_RM_Edge_Stabilized_Diagnostic_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilized_Diagnostic_Model) return Natural;
   function Fingerprint (Model : Remaining_RM_Edge_Stabilized_Diagnostic_Model) return Natural;

   function Is_Emitted (Status : Remaining_RM_Edge_Stabilized_Diagnostic_Status) return Boolean;
   function Is_Withheld_Current (Status : Remaining_RM_Edge_Stabilized_Diagnostic_Status) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Stabilized_Diagnostic_Row);

   type Remaining_RM_Edge_Stabilized_Diagnostic_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Remaining_RM_Edge_Stabilized_Diagnostic_Model is record
      Rows                   : Row_Vectors.Vector;
      Error_Total            : Natural := 0;
      Warning_Total          : Natural := 0;
      Info_Total             : Natural := 0;
      Emitted_Total          : Natural := 0;
      Withheld_Current_Total : Natural := 0;
      Recheck_Total          : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration;
