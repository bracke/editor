with Ada.Containers.Vectors;

package Editor.Gutter_Markers is

   type Gutter_Marker_Kind is
     (Diagnostic_Error_Marker,
      Diagnostic_Warning_Marker,
      Bookmark_Marker,
      Added_Line_Marker,
      Modified_Line_Marker,
      Dirty_Line_Marker);

   type Gutter_Marker is record
      Row  : Natural;
      Kind : Gutter_Marker_Kind;
   end record;

   type Gutter_Marker_Action is
     (No_Marker_Action,
      Toggle_Bookmark_Action,
      Select_Diagnostic_Action,
      Acknowledge_Dirty_Line_Action);

   type Gutter_Marker_Hover_State is record
      Active : Boolean := False;
      Row    : Natural := 0;
      Kind   : Gutter_Marker_Kind := Dirty_Line_Marker;
   end record;

   type Gutter_Marker_State is private;

   procedure Clear
     (State : in out Gutter_Marker_State);

   procedure Add_Marker
     (State : in out Gutter_Marker_State;
      Row   : Natural;
      Kind  : Gutter_Marker_Kind);

   procedure Remove_Marker
     (State : in out Gutter_Marker_State;
      Row   : Natural;
      Kind  : Gutter_Marker_Kind);

   procedure Toggle_Bookmark
     (State : in out Gutter_Marker_State;
      Row   : Natural);

   function Bookmark_Count
     (State : Gutter_Marker_State) return Natural;

   function Has_Bookmarks
     (State : Gutter_Marker_State) return Boolean;

   function First_Bookmark
     (State : Gutter_Marker_State;
      Found : out Boolean) return Natural;

   function Last_Bookmark
     (State : Gutter_Marker_State;
      Found : out Boolean) return Natural;

   function Next_Bookmark_After
     (State : Gutter_Marker_State;
      Row   : Natural;
      Wrap  : Boolean := True;
      Found : out Boolean) return Natural;

   function Previous_Bookmark_Before
     (State : Gutter_Marker_State;
      Row   : Natural;
      Wrap  : Boolean := True;
      Found : out Boolean) return Natural;

   procedure Clear_Bookmarks
     (State : in out Gutter_Marker_State);

   procedure Prune_Bookmarks_At_Or_After
     (State             : in out Gutter_Marker_State;
      First_Invalid_Row : Natural);

   function Has_Marker
     (State : Gutter_Marker_State;
      Row   : Natural;
      Kind  : Gutter_Marker_Kind) return Boolean;

   function Action_For_Marker
     (Kind : Gutter_Marker_Kind) return Gutter_Marker_Action;

   function Dominant_Marker_For_Row
     (State : Gutter_Marker_State;
      Row   : Natural;
      Found : out Boolean) return Gutter_Marker_Kind;

private

   type Marker_Bits is array (Gutter_Marker_Kind) of Boolean;

   type Row_Marker_State is record
      Row     : Natural := 0;
      Markers : Marker_Bits := (others => False);
   end record;

   package Row_Marker_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Row_Marker_State);

   type Gutter_Marker_State is record
      Rows : Row_Marker_Vectors.Vector;
   end record;

end Editor.Gutter_Markers;
