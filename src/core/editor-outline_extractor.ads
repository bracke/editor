with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Outline;
use type Editor.Outline.Outline_Item;

package Editor.Outline_Extractor is

   type Extraction_Status is
     (Extraction_Ok,
      Extraction_Unavailable,
      Extraction_Failed);

   type Extraction_Failure_Kind is
     (No_Failure,
      Empty_Buffer,
      Unsupported_Content,
      Extractor_Internal_Error);

   type Buffer_Text_Snapshot is private;
   type Extraction_Result is private;

   --  Build an immutable buffer-text snapshot for outline extraction.
   --  Snapshot creation stores only the explicit text supplied by Executor; it
   --  does not read files, normalize editor state, save buffers, mutate carets,
   --  clear dirty state, alter selections, or inspect project/workspace data.
   --  @param Text Complete active-buffer text supplied by Executor.
   --  @return Immutable text snapshot for Extract.
   function Make_Snapshot
     (Text : String) return Buffer_Text_Snapshot;

   function Make_Snapshot
     (Text         : String;
      Buffer_Label : String) return Buffer_Text_Snapshot;

   function Make_Snapshot
     (Text               : String;
      Active_Buffer_Token   : Natural;
      Buffer_Revision       : Natural;
      Lifecycle_Generation  : Natural;
      Request_Token         : Natural) return Buffer_Text_Snapshot;

   function Make_Snapshot
     (Text                  : String;
      Buffer_Label          : String;
      Active_Buffer_Token   : Natural;
      Buffer_Revision       : Natural;
      Lifecycle_Generation  : Natural;
      Request_Token         : Natural) return Buffer_Text_Snapshot;

   function Identity
     (Snapshot : Buffer_Text_Snapshot)
      return Editor.Outline.Outline_Snapshot_Identity;

   --  Extract outline items from an explicit immutable buffer-text snapshot.
   --  Ada declaration extraction is backed by Editor.Ada_Declaration_Parser and
   --  Editor.Ada_Language_Model. Outline_Extractor is responsible for converting
   --  parser-owned symbols into outline rows, preserving snapshot identity, and
   --  applying successful results to outline state. It does not own a separate
   --  Ada declaration recognizer.
   --
   --  The documented @outline marker grammar remains supported as an explicit
   --  manual-outline fallback for ordinary text or unsupported snapshots where
   --  the Ada parser produces no symbols. That fallback is marker-only: it does
   --  not scan declaration-leading Ada source lines.
   --
   --  Known intentionally conservative areas include compiler-accurate Ada
   --  legality checking, full GNAT-equivalent visibility and overload
   --  resolution, full representation-clause semantics beyond bounded
   --  declaration metadata, generated/conditional-source interpretation beyond retained
   --  awareness markers, external LSP
   --  integration, compiler invocation, rendering-side parsing, and unbounded
   --  project-wide indexing. Results must pass snapshot validation before they
   --  become visible.
   --  @param Snapshot Text snapshot to inspect.
   --  @return Extraction result containing zero or more outline items.
   function Extract
     (Snapshot : Buffer_Text_Snapshot) return Extraction_Result;

   function Status
     (Result : Extraction_Result) return Extraction_Status;

   function Failure
     (Result : Extraction_Result) return Extraction_Failure_Kind;

   function Item_Count
     (Result : Extraction_Result) return Natural;

   function Identity
     (Result : Extraction_Result)
      return Editor.Outline.Outline_Snapshot_Identity;

   --  Return whether Result is a successful extraction result.
   --  This helper is side-effect-free and does not inspect editor state, emit
   --  messages, or expose mutable result internals.
   --  @param Result Extraction result to inspect.
   --  @return True when Status (Result) is Extraction_Ok.
   function Is_Success
     (Result : Extraction_Result) return Boolean;

   --  Return a deterministic fingerprint of extraction status, failure kind, and
   --  extracted item metadata. The fingerprint contains no timestamps, file
   --  paths, project roots, render state, theme state, or random data.
   --  @param Result Extraction result to inspect.
   --  @return Stable extraction result fingerprint.
   function Fingerprint
     (Result : Extraction_Result) return Natural;

   --  Apply successful extraction output to outline state.
   --  This operation mutates only Outline. Feature-panel projection and messages
   --  are owned by Executor after successful refresh. Failed or unavailable
   --  results are ignored, preserving the previous outline state.
   --  @param Result Successful extraction result to apply.
   --  @param Outline Outline state to replace.
   procedure Apply_To_Outline
     (Result  : Extraction_Result;
      Outline : in out Editor.Outline.Outline_State);

private
   package Outline_Item_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Editor.Outline.Outline_Item);

   type Buffer_Text_Snapshot is record
      Text              : Ada.Strings.Unbounded.Unbounded_String;
      Buffer_Label      : Ada.Strings.Unbounded.Unbounded_String;
      Snapshot_Identity : Editor.Outline.Outline_Snapshot_Identity;
   end record;

   type Extraction_Result is record
      Result_Status   : Extraction_Status := Extraction_Unavailable;
      Failure_Kind    : Extraction_Failure_Kind := Unsupported_Content;
      Result_Identity : Editor.Outline.Outline_Snapshot_Identity;
      Items           : Outline_Item_Vectors.Vector;
   end record;

end Editor.Outline_Extractor;
