with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Bookmarks is

   type Bookmark_Entry is record
      File_Path    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Path : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Project_Relative_Path : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Project_Relative_Path : Boolean := False;
      Line_Number  : Natural := 0;
      Column       : Natural := 0;
      Has_Column   : Boolean := False;
   end record;

   type Bookmark_Row is record
      File_Display_Path : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Project_Relative_Path : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Project_Relative_Path : Boolean := False;
      File_Path    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Line_Number  : Natural := 0;
      Column       : Natural := 0;
      Has_Column   : Boolean := False;
      Is_Open      : Boolean := False;
      Is_Active    : Boolean := False;
      Is_Dirty     : Boolean := False;
      Is_Selected  : Boolean := False;
   end record;

   package Bookmark_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Bookmark_Row);

   type Bookmark_Snapshot is record
      Bookmarks_Visible       : Boolean := False;
      Bookmark_Count          : Natural := 0;
      Bookmark_Selected_Index : Natural := 0;
      Bookmark_Selected_Key_File_Path : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Bookmark_Selected_Key_Line_Number : Natural := 0;
      Bookmark_Selected_Key_Column : Natural := 0;
      Bookmark_Selected_Key_Has_Column : Boolean := False;
      Bookmark_Has_Selected_Key : Boolean := False;
      Bookmark_Rows           : Bookmark_Row_Vectors.Vector;
      Bookmark_Empty_Message  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("No bookmarks");
   end record;

   type Bookmark_State is private;

   --  Lifecycle clear: removes bookmarks, clears selection, and hides the surface.
   procedure Clear (State : in out Bookmark_State);

   --  User clear: removes bookmarks and clears selection without changing visibility.
   procedure Clear_Bookmarks (State : in out Bookmark_State);

   function Count (State : Bookmark_State) return Natural;
   function Has_Bookmarks (State : Bookmark_State) return Boolean;
   function Is_Visible (State : Bookmark_State) return Boolean;
   function Selected_Index (State : Bookmark_State) return Natural;
   function Has_Selected (State : Bookmark_State) return Boolean;

   procedure Show (State : in out Bookmark_State);
   procedure Hide (State : in out Bookmark_State);
   procedure Toggle_Visible (State : in out Bookmark_State);

   function Contains
     (State       : Bookmark_State;
      File_Path   : String;
      Line_Number : Natural) return Boolean;

   procedure Toggle
     (State        : in out Bookmark_State;
      File_Path    : String;
      Display_Path : String;
      Line_Number  : Natural;
      Column       : Natural;
      Has_Column   : Boolean;
      Added        : out Boolean;
      Project_Relative_Path     : String := "";
      Has_Project_Relative_Path : Boolean := False);

   procedure Remove
     (State       : in out Bookmark_State;
      File_Path   : String;
      Line_Number : Natural;
      Removed     : out Boolean);

   procedure Remove_Selected
     (State   : in out Bookmark_State;
      Removed : out Boolean;
      Item   : out Bookmark_Entry);

   type Reveal_Current_Status is
     (Reveal_Selected_Exact,
      Reveal_Selected_Nearest_In_File,
      Reveal_No_Bookmarks,
      Reveal_No_Bookmark_In_Active_File);

   procedure Reveal_Current
     (State       : in out Bookmark_State;
      File_Path   : String;
      Line_Number : Natural;
      Status      : out Reveal_Current_Status;
      Item       : out Bookmark_Entry);

   procedure Select_Next
     (State : in out Bookmark_State);

   procedure Select_Previous
     (State : in out Bookmark_State);

   type Bookmark_Goto_Status is
     (Bookmark_Goto_Target_Found,
      Bookmark_Goto_No_Bookmarks);

   procedure Select_Next_From_Location
     (State        : in out Bookmark_State;
      Has_Location : Boolean;
      File_Path    : String;
      Line_Number  : Natural;
      Column       : Natural;
      Has_Column   : Boolean;
      Status       : out Bookmark_Goto_Status;
      Item        : out Bookmark_Entry);

   procedure Select_Previous_From_Location
     (State        : in out Bookmark_State;
      Has_Location : Boolean;
      File_Path    : String;
      Line_Number  : Natural;
      Column       : Natural;
      Has_Column   : Boolean;
      Status       : out Bookmark_Goto_Status;
      Item        : out Bookmark_Entry);

   function Selected
     (State : Bookmark_State;
      Found : out Boolean) return Bookmark_Entry;

   function Entry_At
     (State : Bookmark_State;
      Index : Positive) return Bookmark_Entry;

   function Bookmark_Path_Label_From_Retained_Target
     (Item : Bookmark_Entry) return Ada.Strings.Unbounded.Unbounded_String;

   function Bookmark_Dirty_Hint_From_Retained_State
     (Item : Bookmark_Entry) return Boolean;

   function Build_Bookmark_Row_From_Bookmark_Entry
     (Item       : Bookmark_Entry;
      Is_Selected : Boolean := False) return Bookmark_Row;

   function Build_Bookmark_Rows_From_Retained_State
     (State : Bookmark_State) return Bookmark_Row_Vectors.Vector;

   procedure Build_Snapshot
     (State    : Bookmark_State;
      Snapshot : out Bookmark_Snapshot);

   --  Phase 490: Bookmarks are an observation/projection surface only for
   --  file lifecycle effects.  These predicates intentionally expose only
   --  structural invariants owned by Bookmarks: retained bookmark entries,
   --  selection/focus state, and row projection from retained entries.
   --  Bookmarks own no file lifecycle operation history, target history,
   --  prompt state, source override, repair cache, filesystem probe cache,
   --  dirty cache, or imported projection truth from adjacent surfaces.
   function Bookmarks_No_Duplicate_Lifecycle_State
     (State : Bookmark_State) return Boolean;

   function Bookmarks_No_Prompt_State
     (State : Bookmark_State) return Boolean;

   function Bookmark_Selection_Source_Target_Boundary
     (State : Bookmark_State) return Boolean;

   function Bookmark_Row_Projection_Canonical
     (State : Bookmark_State) return Boolean;

   function Bookmarks_File_Lifecycle_Observation_Canonical
     (State : Bookmark_State) return Boolean;

   function Bookmarks_File_Lifecycle_Observation_Frozen
     (State : Bookmark_State) return Boolean;

   --  Phase 491 reliability hardening: the retained Bookmark model remains
   --  observation-only across successful, failed, blocked, prompted, render,
   --  audit, lifecycle, and persistence workflows.  This predicate is a
   --  coherence guard over the same structural state: no file lifecycle source,
   --  target, prompt, repair, cache, history, or projection-import state is
   --  owned by Bookmarks.
   function Bookmarks_File_Lifecycle_Observation_Reliable
     (State : Bookmark_State) return Boolean;

   --  Phase 492 cleanup/canonicalization: no duplicate Bookmark lifecycle
   --  observation state remains reachable.  Retained row projection is the
   --  only Bookmark-owned source; buffer/open/dirty enrichment must remain
   --  external snapshot composition and must not be stored back here.
   function Bookmarks_File_Lifecycle_Observation_Cleanup_Canonical
     (State : Bookmark_State) return Boolean;

   --  Phase 493 final hardening/regression freeze: Bookmarks remain a pure
   --  retained-target projection surface.  Final freeze coverage proves that
   --  no Bookmark-owned file lifecycle route, prompt ownership, target/source
   --  inference, cache, history, repair, migration, filesystem probe,
   --  adjacent-surface projection import, or persistence-adjacent lifecycle
   --  state can become product truth.
   function Bookmarks_File_Lifecycle_Observation_Final_Frozen
     (State : Bookmark_State) return Boolean;

private
   package Bookmark_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Bookmark_Entry);

   type Bookmark_State is record
      Visible        : Boolean := False;
      Selected_Index : Natural := 0;
      Has_Selected_Key : Boolean := False;
      Selected_Key      : Bookmark_Entry;
      Entries        : Bookmark_Vectors.Vector;
   end record;

end Editor.Bookmarks;
