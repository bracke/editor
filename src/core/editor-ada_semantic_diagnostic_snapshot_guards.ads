with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Semantic_Colour_Projection;

package Editor.Ada_Semantic_Diagnostic_Snapshot_Guards is

   --  Snapshot guard for semantic diagnostic projections.  This package is a
   --  deterministic gate between parser-owned analysis and editor-visible
   --  diagnostic/colouring consumers.  It performs no parsing, file IO, buffer
   --  mutation, command registration, workspace mutation, or rendering work.

   type Diagnostic_Snapshot_Key is record
      Path                 : Ada.Strings.Unbounded.Unbounded_String;
      Buffer_Token         : Natural := 0;
      Buffer_Revision      : Natural := 0;
      Lifecycle_Generation : Natural := 0;
      Request_Token        : Natural := 0;
      Analysis_Fingerprint : Natural := 0;
   end record;

   type Diagnostic_Snapshot_Status is
     (Diagnostic_Snapshot_Current,
      Diagnostic_Snapshot_Path_Mismatch,
      Diagnostic_Snapshot_Buffer_Mismatch,
      Diagnostic_Snapshot_Revision_Mismatch,
      Diagnostic_Snapshot_Lifecycle_Mismatch,
      Diagnostic_Snapshot_Request_Token_Mismatch,
      Diagnostic_Snapshot_Analysis_Fingerprint_Mismatch);

   type Guarded_Semantic_Diagnostic_Model is private;

   function Make_Key
     (Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Request_Token        : Natural;
      Analysis_Fingerprint : Natural) return Diagnostic_Snapshot_Key;

   function Validate
     (Produced : Diagnostic_Snapshot_Key;
      Current  : Diagnostic_Snapshot_Key) return Diagnostic_Snapshot_Status;

   function Build
     (Produced_Key : Diagnostic_Snapshot_Key;
      Current_Key  : Diagnostic_Snapshot_Key;
      Projection   : Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Model)
      return Guarded_Semantic_Diagnostic_Model;

   function Accepted (Model : Guarded_Semantic_Diagnostic_Model) return Boolean;
   function Rejected (Model : Guarded_Semantic_Diagnostic_Model) return Boolean;
   function Status
     (Model : Guarded_Semantic_Diagnostic_Model) return Diagnostic_Snapshot_Status;

   function Entry_Count (Model : Guarded_Semantic_Diagnostic_Model) return Natural;
   function Entry_At
     (Model : Guarded_Semantic_Diagnostic_Model;
      Index : Positive)
      return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Entry;

   function Error_Count (Model : Guarded_Semantic_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Guarded_Semantic_Diagnostic_Model) return Natural;
   function Info_Count (Model : Guarded_Semantic_Diagnostic_Model) return Natural;
   function Rejected_Entry_Count
     (Model : Guarded_Semantic_Diagnostic_Model) return Natural;
   function Fingerprint (Model : Guarded_Semantic_Diagnostic_Model) return Natural;

private
   use type Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Entry;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Entry);

   type Guarded_Semantic_Diagnostic_Model is record
      Produced_Key       : Diagnostic_Snapshot_Key;
      Current_Key        : Diagnostic_Snapshot_Key;
      Guard_Status       : Diagnostic_Snapshot_Status := Diagnostic_Snapshot_Current;
      Entries            : Entry_Vectors.Vector;
      Rejected_Total     : Natural := 0;
      Error_Total        : Natural := 0;
      Warning_Total      : Natural := 0;
      Info_Total         : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
