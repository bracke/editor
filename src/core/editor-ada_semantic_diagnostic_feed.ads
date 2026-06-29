with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Overload_Preference_Legality;
limited with Editor.Ada_Final_Semantic_Diagnostic_Integration;
limited with Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration;
limited with Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration;
limited with Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;
limited with Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
limited with Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
limited with Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration;
limited with Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration;
limited with Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics;
limited with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Syntax;

package Editor.Ada_Semantic_Diagnostic_Feed is

   --  Unified, snapshot-guarded diagnostic feed for IDE-facing Ada semantic
   --  consumers.  This package flattens already-guarded semantic-colouring
   --  diagnostic overlays into one deterministic, bounded API.  It performs no
   --  parsing, file IO, buffer mutation, command registration, workspace
   --  mutation, or rendering work.

   type Semantic_Diagnostic_Feed_Id is new Natural;
   No_Semantic_Diagnostic_Feed_Entry : constant Semantic_Diagnostic_Feed_Id := 0;

   type Semantic_Diagnostic_Feed_Status is
     (Semantic_Diagnostic_Feed_Current,
      Semantic_Diagnostic_Feed_Rejected_Stale);

   type Semantic_Diagnostic_Feed_Severity is
     (Semantic_Diagnostic_Feed_Info,
      Semantic_Diagnostic_Feed_Warning,
      Semantic_Diagnostic_Feed_Error);

   subtype Semantic_Diagnostic_Feed_Source is
     Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Source;

   type Semantic_Diagnostic_Feed_Entry is record
      Id       : Semantic_Diagnostic_Feed_Id := No_Semantic_Diagnostic_Feed_Entry;
      Source   : Semantic_Diagnostic_Feed_Source :=
        Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      Severity : Semantic_Diagnostic_Feed_Severity := Semantic_Diagnostic_Feed_Info;
      Token    : Editor.Syntax.Token_Kind := Editor.Syntax.Identifier;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Has_Edit      : Boolean := False;
      Edit_Start_Line   : Positive := 1;
      Edit_Start_Column : Positive := 1;
      Edit_End_Line     : Positive := 1;
      Edit_End_Column   : Positive := 1;
      Replacement_Text  : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint : Natural := 0;
      Fingerprint        : Natural := 0;
   end record;

   type Semantic_Diagnostic_Feed_Model is private;

   procedure Clear (Model : in out Semantic_Diagnostic_Feed_Model);

   function Build
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model)
      return Semantic_Diagnostic_Feed_Model;

   function Build_With_Wide_Legality
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Wide    : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Model;
      Wide_Input_Current : Boolean := True;
      Wide_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model;

   function Build_With_Wide_Legality_And_Overload_Preference
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Wide    : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Model;
      Preference : Editor.Ada_Overload_Preference_Legality.Preference_Legality_Model;
      Wide_Input_Current : Boolean := True;
      Wide_Rejected_Count : Natural := 0;
      Preference_Input_Current : Boolean := True;
      Preference_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model;

   function Build_With_Integrated_Closure
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Closure : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Model;
      Closure_Input_Current : Boolean := True;
      Closure_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model;

   function Build_With_Final_Semantic_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model;

   function Build_With_Final_Remediation_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model;

   function Build_With_Final_Stabilized_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model;

   function Build_With_Generic_Shared_State_Final_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Generic_Shared_State_Final_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model;

   function Build_With_Generic_Shared_State_RM_Completion_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.RM_Completion_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model;

   function Build_With_RM_Completion_Closure_Consumer_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model;

   function Build_With_RM_Completion_Closure_Consumer_Stabilized_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model;

   function Build_With_Remaining_RM_Edge_Stabilized_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model;

   function Build_With_Remaining_RM_Edge_Stabilized_Closure_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model;

   function Status (Model : Semantic_Diagnostic_Feed_Model) return Semantic_Diagnostic_Feed_Status;
   function Current (Model : Semantic_Diagnostic_Feed_Model) return Boolean;
   function Rejected_Stale (Model : Semantic_Diagnostic_Feed_Model) return Boolean;

   function Entry_Count (Model : Semantic_Diagnostic_Feed_Model) return Natural;
   function Entry_At
     (Model : Semantic_Diagnostic_Feed_Model;
      Index : Positive) return Semantic_Diagnostic_Feed_Entry;

   function With_Edit_Hint
     (Model             : Semantic_Diagnostic_Feed_Model;
      Entry_Id          : Semantic_Diagnostic_Feed_Id;
      Edit_Start_Line   : Positive;
      Edit_Start_Column : Positive;
      Edit_End_Line     : Positive;
      Edit_End_Column   : Positive;
      Replacement_Text  : String) return Semantic_Diagnostic_Feed_Model;
   --  Return a copy of Model with an explicit producer-owned edit hint attached
   --  to Entry_Id when the feed is current and the edit range is forward.

   function Error_Count (Model : Semantic_Diagnostic_Feed_Model) return Natural;
   function Warning_Count (Model : Semantic_Diagnostic_Feed_Model) return Natural;
   function Info_Count (Model : Semantic_Diagnostic_Feed_Model) return Natural;
   function Count_Source
     (Model  : Semantic_Diagnostic_Feed_Model;
      Source : Semantic_Diagnostic_Feed_Source) return Natural;
   function Count_Token
     (Model : Semantic_Diagnostic_Feed_Model;
      Token : Editor.Syntax.Token_Kind) return Natural;
   function Rejected_Entry_Count (Model : Semantic_Diagnostic_Feed_Model) return Natural;
   function Fingerprint (Model : Semantic_Diagnostic_Feed_Model) return Natural;

private
   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Semantic_Diagnostic_Feed_Entry);

   type Semantic_Diagnostic_Feed_Model is record
      Feed_Status        : Semantic_Diagnostic_Feed_Status := Semantic_Diagnostic_Feed_Current;
      Entries            : Entry_Vectors.Vector;
      Error_Total        : Natural := 0;
      Warning_Total      : Natural := 0;
      Info_Total         : Natural := 0;
      Rejected_Total     : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Semantic_Diagnostic_Feed;
