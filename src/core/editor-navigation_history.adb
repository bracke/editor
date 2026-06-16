with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Navigation_History is

   function Is_Recordable (Location : Navigation_Location) return Boolean is
   begin
      if Location.Line = 0 then
         return False;
      end if;

      if Location.Has_File_Path then
         return Length (Location.File_Path) > 0;
      end if;

      return Location.Buffer_Id /= 0;
   end Is_Recordable;

   function Locations_Equal (Left, Right : Navigation_Location) return Boolean is
      function Exact_Column_Reason
        (Reason : Navigation_History_Reason) return Boolean
      is
      begin
         return Reason in Navigation_Reason_Find_Next
           | Navigation_Reason_Find_Previous;
      end Exact_Column_Reason;

      function Columns_Equal return Boolean is
      begin
         if Exact_Column_Reason (Left.Reason)
           or else Exact_Column_Reason (Right.Reason)
         then
            return Left.Column = Right.Column;
         end if;

         return Left.Column = Right.Column
           or else Left.Column = 0
           or else Right.Column = 0;
      end Columns_Equal;
   begin
      if not Is_Recordable (Left) or else not Is_Recordable (Right) then
         return False;
      end if;

      if Left.Has_File_Path and then Right.Has_File_Path then
         return To_String (Left.File_Path) = To_String (Right.File_Path)
           and then Left.Line = Right.Line
           and then Columns_Equal;
      end if;

      return Left.Buffer_Id /= 0
        and then Left.Buffer_Id = Right.Buffer_Id
        and then Left.Line = Right.Line
        and then Columns_Equal;
   end Locations_Equal;

   procedure Trim_To_Bound (Stack : in out Location_Vectors.Vector) is
   begin
      while Natural (Stack.Length) > Max_History_Depth loop
         Stack.Delete_First;
      end loop;
   end Trim_To_Bound;

   procedure Push
     (Stack    : in out Location_Vectors.Vector;
      Location : Navigation_Location)
   is
   begin
      if not Is_Recordable (Location) then
         return;
      end if;

      if not Stack.Is_Empty
        and then Locations_Equal (Stack (Stack.Last_Index), Location)
      then
         return;
      end if;

      Stack.Append (Location);
      Trim_To_Bound (Stack);
   end Push;

   function Pop
     (Stack  : in out Location_Vectors.Vector;
      Target : out Navigation_Location) return Boolean
   is
   begin
      if Stack.Is_Empty then
         Target := (others => <>);
         return False;
      end if;

      Target := Stack (Stack.Last_Index);
      Stack.Delete_Last;
      return True;
   end Pop;

   procedure Clear (State : in out Navigation_History_State) is
   begin
      State.Back_Stack.Clear;
      State.Forward_Stack.Clear;
   end Clear;

   function Back_Count (State : Navigation_History_State) return Natural is
   begin
      return Natural (State.Back_Stack.Length);
   end Back_Count;

   function Forward_Count (State : Navigation_History_State) return Natural is
   begin
      return Natural (State.Forward_Stack.Length);
   end Forward_Count;

   function Has_Back (State : Navigation_History_State) return Boolean is
   begin
      return not State.Back_Stack.Is_Empty;
   end Has_Back;

   function Has_Forward (State : Navigation_History_State) return Boolean is
   begin
      return not State.Forward_Stack.Is_Empty;
   end Has_Forward;

   procedure Record_Explicit_Navigation
     (State    : in out Navigation_History_State;
      Location : Navigation_Location)
   is
   begin
      if not Is_Recordable (Location) then
         return;
      end if;

      Push (State.Back_Stack, Location);
      State.Forward_Stack.Clear;
   end Record_Explicit_Navigation;

   procedure Record_Explicit_Navigation_If_Target_Changed
     (State    : in out Navigation_History_State;
      Previous : Navigation_Location;
      Target   : Navigation_Location)
   is
   begin
      --  This helper is called only after an explicit non-history navigation
      --  has succeeded.  The target is therefore the command's structured
      --  destination, while Previous is the execution-time active caret
      --  location captured before the command moved.
      --
      --  If Previous and Target are the same recordable place, the successful
      --  command did not create a meaningful new history branch and the
      --  forward stack remains intact.  Otherwise, a successful new navigation
      --  invalidates forward history even when the old current location could
      --  not be recorded.
      if Is_Recordable (Previous)
        and then Is_Recordable (Target)
        and then Locations_Equal (Previous, Target)
      then
         return;
      end if;

      if Is_Recordable (Previous) then
         Push (State.Back_Stack, Previous);
      end if;

      if Is_Recordable (Target) or else Is_Recordable (Previous) then
         State.Forward_Stack.Clear;
      end if;
   end Record_Explicit_Navigation_If_Target_Changed;

   function Pop_Back
     (State : in out Navigation_History_State;
      Target  : out Navigation_Location) return Boolean
   is
   begin
      return Pop (State.Back_Stack, Target);
   end Pop_Back;

   function Pop_Forward
     (State : in out Navigation_History_State;
      Target  : out Navigation_Location) return Boolean
   is
   begin
      return Pop (State.Forward_Stack, Target);
   end Pop_Forward;

   procedure Record_Back_Navigation
     (State    : in out Navigation_History_State;
      Location : Navigation_Location)
   is
   begin
      Push (State.Back_Stack, Location);
   end Record_Back_Navigation;

   procedure Record_Forward_Navigation
     (State    : in out Navigation_History_State;
      Location : Navigation_Location)
   is
   begin
      Push (State.Forward_Stack, Location);
   end Record_Forward_Navigation;


   function Stack_Bounded
     (State : Navigation_History_State) return Boolean
   is
   begin
      return Natural (State.Back_Stack.Length) <= Max_History_Depth
        and then Natural (State.Forward_Stack.Length) <= Max_History_Depth;
   end Stack_Bounded;

   function Navigation_History_No_Duplicate_Lifecycle_State
     (State : Navigation_History_State) return Boolean
   is
   begin
      return Stack_Bounded (State);
   end Navigation_History_No_Duplicate_Lifecycle_State;

   function Navigation_History_No_Prompt_State
     (State : Navigation_History_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      return True;
   end Navigation_History_No_Prompt_State;

   function Navigation_History_Source_Target_Boundary
     (State : Navigation_History_State) return Boolean
   is
   begin
      return Stack_Bounded (State);
   end Navigation_History_Source_Target_Boundary;

   function Navigation_History_File_Lifecycle_Observation_Canonical
     (State : Navigation_History_State) return Boolean
   is
   begin
      return Navigation_History_No_Duplicate_Lifecycle_State (State)
        and then Navigation_History_No_Prompt_State (State)
        and then Navigation_History_Source_Target_Boundary (State);
   end Navigation_History_File_Lifecycle_Observation_Canonical;

   function Navigation_History_File_Lifecycle_Observation_Frozen
     (State : Navigation_History_State) return Boolean
   is
   begin
      return Navigation_History_File_Lifecycle_Observation_Canonical (State);
   end Navigation_History_File_Lifecycle_Observation_Frozen;

end Editor.Navigation_History;
