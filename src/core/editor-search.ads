with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Text_Buffer;
with Editor.Cursors;

package Editor.Search is

   type Search_Match_Index is new Natural;
   No_Search_Match : constant Search_Match_Index := 0;

   type Search_Direction is
     (Search_Forward,
      Search_Backward);

   type Search_Options is record
      Case_Sensitive : Boolean := False;
      Wrap           : Boolean := True;
   end record;

   type Search_Match is record
      Index        : Search_Match_Index := No_Search_Match;
      Start_Index  : Editor.Cursors.Cursor_Index := 0;
      End_Index    : Editor.Cursors.Cursor_Index := 0; -- exclusive
      Start_Row    : Natural := 0;
      Start_Column : Natural := 0;
      End_Row      : Natural := 0;
      End_Column   : Natural := 0;
   end record;

   package Search_Match_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Search_Match);

   type Search_State is record
      Query          : Ada.Strings.Unbounded.Unbounded_String;
      Case_Sensitive : Boolean := False;
      Options        : Search_Options;
      Active_Match   : Search_Match_Index := No_Search_Match;
      Matches        : Search_Match_Vectors.Vector;
   end record;

   No_Match : constant Search_Match :=
     (Index        => No_Search_Match,
      Start_Index  => 0,
      End_Index    => 0,
      Start_Row    => 0,
      Start_Column => 0,
      End_Row      => 0,
      End_Column   => 0);


   procedure Clear
     (State : in out Search_State);

   procedure Set_Query
     (State : in out Search_State;
      Query : String);

   function Query
     (State : Search_State) return String;

   function Has_Query
     (State : Search_State) return Boolean;

   function Options
     (State : Search_State) return Search_Options;

   procedure Set_Options
     (State   : in out Search_State;
      Options : Search_Options);

   procedure Recompute
     (State : in out Search_State;
      Text  : String);

   function Match_Count
     (State : Search_State) return Natural;

   function Match_At
     (State : Search_State;
      Index : Positive) return Search_Match;

   function Has_Active_Match
     (State : Search_State) return Boolean;

   function Active_Match_Index
     (State : Search_State) return Search_Match_Index;

   function Active_Match
     (State : Search_State;
      Found : out Boolean) return Search_Match;

   procedure Set_Active_Match
     (State : in out Search_State;
      Index : Search_Match_Index);

   function Next_Match_After
     (State  : Search_State;
      Row    : Natural;
      Column : Natural;
      Wrap   : Boolean := True;
      Found  : out Boolean) return Search_Match_Index;

   function Previous_Match_Before
     (State  : Search_State;
      Row    : Natural;
      Column : Natural;
      Wrap   : Boolean := True;
      Found  : out Boolean) return Search_Match_Index;

   function Has_Match
     (Match : Search_Match) return Boolean;

   function Find_Next_In_Buffer
     (Buffer  : Text_Buffer.Buffer_Type;
      Query   : String;
      From    : Natural;
      Options : Search_Options) return Search_Match;

   function Find_Previous_In_Buffer
     (Buffer  : Text_Buffer.Buffer_Type;
      Query   : String;
      From    : Natural;
      Options : Search_Options) return Search_Match;

   procedure Find_All
     (Buffer  : Text_Buffer.Buffer_Type;
      Query   : String;
      Options : Search_Options;
      Matches : in out Search_Match_Vectors.Vector);


end Editor.Search;
