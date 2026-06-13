with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Remediation_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration is

   --  Pass1202 final semantic remediation diagnostic integration.
   --
   --  This package consumes Pass1201 remediation-closure rows and produces
   --  diagnostic-ready semantic rows without flattening prerequisite evidence.
   --  It is not a projection/status layer: each row keeps the prerequisite
   --  blocker family that caused a downstream legal conclusion to be withheld,
   --  so stale snapshot evidence, AST/coverage repair, cross-unit closure, view
   --  barriers, generic replay/backmapping, overload/type evidence,
   --  representation/freezing, flow/contract proof, tasking/protected effects,
   --  elaboration, accessibility/lifetime, discriminant/variant evidence,
   --  preserved semantic errors, and indeterminate states remain distinct in the
   --  diagnostic/feed path.  The model is deterministic, bounded,
   --  snapshot-owned, and side-effect-free.

   package Closure renames Editor.Ada_Final_Semantic_Remediation_Closure_Legality;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Remediation_Closure_Id is Closure.Final_Remediation_Closure_Id;
   subtype Final_Remediation_Closure_Status is Closure.Final_Remediation_Closure_Status;

   type Final_Remediation_Diagnostic_Id is new Natural;
   No_Final_Remediation_Diagnostic : constant Final_Remediation_Diagnostic_Id := 0;

   type Final_Remediation_Diagnostic_Family is
     (Final_Remediation_Diagnostic_Cross_Unit,
      Final_Remediation_Diagnostic_Overload_Type,
      Final_Remediation_Diagnostic_Generic_Replay,
      Final_Remediation_Diagnostic_Representation_Freezing,
      Final_Remediation_Diagnostic_Flow_Contract,
      Final_Remediation_Diagnostic_Tasking_Protected,
      Final_Remediation_Diagnostic_Elaboration,
      Final_Remediation_Diagnostic_Accessibility_Lifetime,
      Final_Remediation_Diagnostic_Discriminant_Variant,
      Final_Remediation_Diagnostic_AST_Coverage,
      Final_Remediation_Diagnostic_View_Barrier,
      Final_Remediation_Diagnostic_Stale_Input,
      Final_Remediation_Diagnostic_Multiple,
      Final_Remediation_Diagnostic_Unknown);

   type Final_Remediation_Diagnostic_Severity is
     (Final_Remediation_Diagnostic_Info,
      Final_Remediation_Diagnostic_Warning,
      Final_Remediation_Diagnostic_Error);

   type Final_Remediation_Diagnostic_Status is
     (Final_Remediation_Diagnostic_Not_Checked,
      Final_Remediation_Diagnostic_Withheld_Legal,
      Final_Remediation_Diagnostic_Stale_Prerequisite,
      Final_Remediation_Diagnostic_AST_Coverage_Prerequisite,
      Final_Remediation_Diagnostic_Cross_Unit_Prerequisite,
      Final_Remediation_Diagnostic_View_Prerequisite,
      Final_Remediation_Diagnostic_Generic_Replay_Prerequisite,
      Final_Remediation_Diagnostic_Overload_Type_Prerequisite,
      Final_Remediation_Diagnostic_Representation_Freezing_Prerequisite,
      Final_Remediation_Diagnostic_Flow_Contract_Prerequisite,
      Final_Remediation_Diagnostic_Tasking_Protected_Prerequisite,
      Final_Remediation_Diagnostic_Elaboration_Prerequisite,
      Final_Remediation_Diagnostic_Accessibility_Lifetime_Prerequisite,
      Final_Remediation_Diagnostic_Discriminant_Variant_Prerequisite,
      Final_Remediation_Diagnostic_Multiple_Prerequisites,
      Final_Remediation_Diagnostic_Preserved_Semantic_Error,
      Final_Remediation_Diagnostic_Indeterminate);

   type Final_Remediation_Diagnostic_Row is record
      Id                    : Final_Remediation_Diagnostic_Id := No_Final_Remediation_Diagnostic;
      Closure_Id            : Final_Remediation_Closure_Id := Closure.No_Final_Remediation_Closure;
      Closure_Status        : Final_Remediation_Closure_Status := Closure.Final_Remediation_Closure_Not_Checked;
      Status                : Final_Remediation_Diagnostic_Status := Final_Remediation_Diagnostic_Not_Checked;
      Family                : Final_Remediation_Diagnostic_Family := Final_Remediation_Diagnostic_Unknown;
      Severity              : Final_Remediation_Diagnostic_Severity := Final_Remediation_Diagnostic_Warning;
      Blocker_Family        : Final_Blocker_Family := Final_Prov.Final_Blocker_None;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Dependency_Order      : Natural := 0;
      Closure_Blocked       : Boolean := False;
      Derived_Legal_Withheld : Boolean := False;
      Downstream_Blocked    : Natural := 0;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint    : Natural := 0;
      Closure_Fingerprint   : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Final_Remediation_Diagnostic_Set is private;
   type Final_Remediation_Diagnostic_Model is private;

   procedure Clear (Model : in out Final_Remediation_Diagnostic_Model);

   function Build
     (Closure_Model : Closure.Final_Remediation_Closure_Model)
      return Final_Remediation_Diagnostic_Model;

   function Row_Count (Model : Final_Remediation_Diagnostic_Model) return Natural;
   function Row_At
     (Model : Final_Remediation_Diagnostic_Model;
      Index : Positive) return Final_Remediation_Diagnostic_Row;

   function Set_Count (Set : Final_Remediation_Diagnostic_Set) return Natural;
   function Set_At
     (Set   : Final_Remediation_Diagnostic_Set;
      Index : Positive) return Final_Remediation_Diagnostic_Row;

   function Query_Status
     (Model  : Final_Remediation_Diagnostic_Model;
      Status : Final_Remediation_Diagnostic_Status) return Final_Remediation_Diagnostic_Set;
   function Query_Family
     (Model  : Final_Remediation_Diagnostic_Model;
      Family : Final_Remediation_Diagnostic_Family) return Final_Remediation_Diagnostic_Set;
   function Query_Blocker
     (Model   : Final_Remediation_Diagnostic_Model;
      Blocker : Final_Blocker_Family) return Final_Remediation_Diagnostic_Set;
   function Query_Node
     (Model : Final_Remediation_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Remediation_Diagnostic_Set;

   function Count_Status
     (Model  : Final_Remediation_Diagnostic_Model;
      Status : Final_Remediation_Diagnostic_Status) return Natural;
   function Count_Family
     (Model  : Final_Remediation_Diagnostic_Model;
      Family : Final_Remediation_Diagnostic_Family) return Natural;
   function Count_Blocker
     (Model   : Final_Remediation_Diagnostic_Model;
      Blocker : Final_Blocker_Family) return Natural;

   function Error_Count (Model : Final_Remediation_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Final_Remediation_Diagnostic_Model) return Natural;
   function Info_Count (Model : Final_Remediation_Diagnostic_Model) return Natural;
   function Withheld_Legal_Count (Model : Final_Remediation_Diagnostic_Model) return Natural;
   function Emitted_Count (Model : Final_Remediation_Diagnostic_Model) return Natural;
   function Stale_Count (Model : Final_Remediation_Diagnostic_Model) return Natural;
   function Preserved_Error_Count (Model : Final_Remediation_Diagnostic_Model) return Natural;
   function Indeterminate_Count (Model : Final_Remediation_Diagnostic_Model) return Natural;
   function Downstream_Blocked_Count (Model : Final_Remediation_Diagnostic_Model) return Natural;
   function Fingerprint (Model : Final_Remediation_Diagnostic_Model) return Natural;

   function Is_Emitted (Status : Final_Remediation_Diagnostic_Status) return Boolean;
   function Is_Blocker (Status : Final_Remediation_Diagnostic_Status) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Remediation_Diagnostic_Row);

   type Final_Remediation_Diagnostic_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Remediation_Diagnostic_Model is record
      Rows                       : Row_Vectors.Vector;
      Error_Total                : Natural := 0;
      Warning_Total              : Natural := 0;
      Info_Total                 : Natural := 0;
      Withheld_Legal_Total       : Natural := 0;
      Emitted_Total              : Natural := 0;
      Stale_Total                : Natural := 0;
      Preserved_Error_Total      : Natural := 0;
      Indeterminate_Total        : Natural := 0;
      Downstream_Blocked_Total   : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration;
