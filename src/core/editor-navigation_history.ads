with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Navigation_History is

   type Navigation_History_Reason is
     (Navigation_Reason_Unknown,
      Navigation_Reason_Go_To_Line,
      Navigation_Reason_Find_Next,
      Navigation_Reason_Find_Previous,
      Navigation_Reason_Feature_Panel,
      Navigation_Reason_File_Tree,
      Navigation_Reason_Buffer_Switch,
      Navigation_Reason_Bookmark_Next,
      Navigation_Reason_Bookmark_Previous,
      Navigation_Reason_Back,
      Navigation_Reason_Forward,
      Navigation_Reason_Clear);

   type Navigation_Location is record
      Buffer_Id      : Natural := 0;
      Has_File_Path  : Boolean := False;
      File_Path      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Path   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      --  One-based editor line number.  Zero means no resolvable line.
      Line           : Natural := 0;
      --  Zero-based editor column when the caret/location seam exposes one.
      Column         : Natural := 0;
      Viewport_Row   : Natural := 0;
      Reason         : Navigation_History_Reason := Navigation_Reason_Unknown;
   end record;

   package Location_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Navigation_Location);

   Max_History_Depth : constant Natural := 100;

   type Navigation_History_State is record
      Back_Stack    : Location_Vectors.Vector;
      Forward_Stack : Location_Vectors.Vector;
   end record;

   procedure Clear (State : in out Navigation_History_State);

   function Back_Count (State : Navigation_History_State) return Natural;
   function Forward_Count (State : Navigation_History_State) return Natural;
   function Has_Back (State : Navigation_History_State) return Boolean;
   function Has_Forward (State : Navigation_History_State) return Boolean;

   function Is_Recordable (Location : Navigation_Location) return Boolean;

   function Locations_Equal (Left, Right : Navigation_Location) return Boolean;

   procedure Record_Explicit_Navigation
     (State    : in out Navigation_History_State;
      Location : Navigation_Location);

   procedure Record_Explicit_Navigation_If_Target_Changed
     (State    : in out Navigation_History_State;
      Previous : Navigation_Location;
      Target   : Navigation_Location);

   function Pop_Back
     (State : in out Navigation_History_State;
      Target  : out Navigation_Location) return Boolean;

   function Pop_Forward
     (State : in out Navigation_History_State;
      Target  : out Navigation_Location) return Boolean;

   procedure Record_Back_Navigation
     (State    : in out Navigation_History_State;
      Location : Navigation_Location);

   procedure Record_Forward_Navigation
     (State    : in out Navigation_History_State;
      Location : Navigation_Location);

   --  shared projection-surface contract predicates.  Navigation
   --  History retains navigation targets only; it does not own file lifecycle
   --  commands, target prompts, filesystem probes, repair/migration caches,
   --  operation histories, or cross-surface projection truth.
   function Navigation_History_No_Duplicate_Lifecycle_State
     (State : Navigation_History_State) return Boolean;

   function Navigation_History_No_Prompt_State
     (State : Navigation_History_State) return Boolean;

   function Navigation_History_Source_Target_Boundary
     (State : Navigation_History_State) return Boolean;

   function Navigation_History_File_Lifecycle_Observation_Canonical
     (State : Navigation_History_State) return Boolean;

   function Navigation_History_File_Lifecycle_Observation_Frozen
     (State : Navigation_History_State) return Boolean;

end Editor.Navigation_History;
