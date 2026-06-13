package body Editor.Gutter_Markers is

   function Priority
     (Kind : Gutter_Marker_Kind) return Natural
   is
   begin
      case Kind is
         when Diagnostic_Error_Marker =>
            return 0;
         when Diagnostic_Warning_Marker =>
            return 1;
         when Bookmark_Marker =>
            return 2;
         when Added_Line_Marker =>
            return 3;
         when Modified_Line_Marker =>
            return 4;
         when Dirty_Line_Marker =>
            return 5;
      end case;
   end Priority;

   function Find_Row_Index
     (State : Gutter_Marker_State;
      Row   : Natural;
      Found : out Boolean) return Natural
   is
   begin
      if State.Rows.Is_Empty then
         Found := False;
         return 0;
      end if;

      for Index in State.Rows.First_Index .. State.Rows.Last_Index loop
         if State.Rows.Element (Index).Row = Row then
            Found := True;
            return Index;
         end if;
      end loop;

      Found := False;
      return 0;
   end Find_Row_Index;

   procedure Clear
     (State : in out Gutter_Marker_State)
   is
   begin
      State.Rows.Clear;
   end Clear;

   procedure Add_Marker
     (State : in out Gutter_Marker_State;
      Row   : Natural;
      Kind  : Gutter_Marker_Kind)
   is
      Found : Boolean;
      Index : Natural;
      Item  : Row_Marker_State;
   begin
      Index := Find_Row_Index (State, Row, Found);

      if Found then
         Item := State.Rows.Element (Index);
         Item.Markers (Kind) := True;
         State.Rows.Replace_Element (Index, Item);
      else
         Item.Row := Row;
         Item.Markers := (others => False);
         Item.Markers (Kind) := True;
         State.Rows.Append (Item);
      end if;
   end Add_Marker;

   procedure Remove_Marker
     (State : in out Gutter_Marker_State;
      Row   : Natural;
      Kind  : Gutter_Marker_Kind)
   is
      Found       : Boolean;
      Index       : Natural;
      Item        : Row_Marker_State;
      Any_Remains : Boolean := False;
   begin
      Index := Find_Row_Index (State, Row, Found);

      if not Found then
         return;
      end if;

      Item := State.Rows.Element (Index);
      Item.Markers (Kind) := False;

      for Existing_Kind in Gutter_Marker_Kind loop
         if Item.Markers (Existing_Kind) then
            Any_Remains := True;
         end if;
      end loop;

      if Any_Remains then
         State.Rows.Replace_Element (Index, Item);
      else
         State.Rows.Delete (Index);
      end if;
   end Remove_Marker;

   procedure Toggle_Bookmark
     (State : in out Gutter_Marker_State;
      Row   : Natural)
   is
   begin
      if Has_Marker (State, Row, Bookmark_Marker) then
         Remove_Marker (State, Row, Bookmark_Marker);
      else
         Add_Marker (State, Row, Bookmark_Marker);
      end if;
   end Toggle_Bookmark;


   function Bookmark_Count
     (State : Gutter_Marker_State) return Natural
   is
      Count : Natural := 0;
   begin
      if State.Rows.Is_Empty then
         return 0;
      end if;

      for Item of State.Rows loop
         if Item.Markers (Bookmark_Marker) then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Bookmark_Count;

   function Has_Bookmarks
     (State : Gutter_Marker_State) return Boolean
   is
   begin
      return Bookmark_Count (State) > 0;
   end Has_Bookmarks;

   function First_Bookmark
     (State : Gutter_Marker_State;
      Found : out Boolean) return Natural
   is
      Best : Natural := Natural'Last;
   begin
      Found := False;
      if State.Rows.Is_Empty then
         return 0;
      end if;

      for Item of State.Rows loop
         if Item.Markers (Bookmark_Marker) and then Item.Row < Best then
            Best := Item.Row;
            Found := True;
         end if;
      end loop;

      if Found then
         return Best;
      else
         return 0;
      end if;
   end First_Bookmark;

   function Last_Bookmark
     (State : Gutter_Marker_State;
      Found : out Boolean) return Natural
   is
      Best : Natural := 0;
   begin
      Found := False;
      if State.Rows.Is_Empty then
         return 0;
      end if;

      for Item of State.Rows loop
         if Item.Markers (Bookmark_Marker)
           and then (not Found or else Item.Row > Best)
         then
            Best := Item.Row;
            Found := True;
         end if;
      end loop;

      if Found then
         return Best;
      else
         return 0;
      end if;
   end Last_Bookmark;

   function Next_Bookmark_After
     (State : Gutter_Marker_State;
      Row   : Natural;
      Wrap  : Boolean := True;
      Found : out Boolean) return Natural
   is
      Best : Natural := Natural'Last;
   begin
      Found := False;
      if State.Rows.Is_Empty then
         return 0;
      end if;

      for Item of State.Rows loop
         if Item.Markers (Bookmark_Marker)
           and then Item.Row > Row
           and then Item.Row < Best
         then
            Best := Item.Row;
            Found := True;
         end if;
      end loop;

      if Found then
         return Best;
      elsif Wrap then
         return First_Bookmark (State, Found);
      else
         return 0;
      end if;
   end Next_Bookmark_After;

   function Previous_Bookmark_Before
     (State : Gutter_Marker_State;
      Row   : Natural;
      Wrap  : Boolean := True;
      Found : out Boolean) return Natural
   is
      Best : Natural := 0;
   begin
      Found := False;
      if State.Rows.Is_Empty then
         return 0;
      end if;

      for Item of State.Rows loop
         if Item.Markers (Bookmark_Marker)
           and then Item.Row < Row
           and then (not Found or else Item.Row > Best)
         then
            Best := Item.Row;
            Found := True;
         end if;
      end loop;

      if Found then
         return Best;
      elsif Wrap then
         return Last_Bookmark (State, Found);
      else
         return 0;
      end if;
   end Previous_Bookmark_Before;

   procedure Clear_Bookmarks
     (State : in out Gutter_Marker_State)
   is
      Index       : Natural;
      Item        : Row_Marker_State;
      Any_Remains : Boolean;
   begin
      if State.Rows.Is_Empty then
         return;
      end if;

      Index := State.Rows.First_Index;
      while Index <= State.Rows.Last_Index loop
         Item := State.Rows.Element (Index);
         Item.Markers (Bookmark_Marker) := False;
         Any_Remains := False;

         for Kind in Gutter_Marker_Kind loop
            if Item.Markers (Kind) then
               Any_Remains := True;
            end if;
         end loop;

         if Any_Remains then
            State.Rows.Replace_Element (Index, Item);
            Index := Index + 1;
         else
            State.Rows.Delete (Index);
            if State.Rows.Is_Empty then
               exit;
            end if;
         end if;
      end loop;
   end Clear_Bookmarks;


   procedure Prune_Bookmarks_At_Or_After
     (State             : in out Gutter_Marker_State;
      First_Invalid_Row : Natural)
   is
      Index       : Natural;
      Item        : Row_Marker_State;
      Any_Remains : Boolean;
   begin
      if State.Rows.Is_Empty then
         return;
      end if;

      Index := State.Rows.First_Index;
      while Index <= State.Rows.Last_Index loop
         Item := State.Rows.Element (Index);

         if Item.Row >= First_Invalid_Row
           and then Item.Markers (Bookmark_Marker)
         then
            Item.Markers (Bookmark_Marker) := False;
            Any_Remains := False;

            for Kind in Gutter_Marker_Kind loop
               if Item.Markers (Kind) then
                  Any_Remains := True;
               end if;
            end loop;

            if Any_Remains then
               State.Rows.Replace_Element (Index, Item);
               Index := Index + 1;
            else
               State.Rows.Delete (Index);
               if State.Rows.Is_Empty then
                  exit;
               end if;
            end if;
         else
            Index := Index + 1;
         end if;
      end loop;
   end Prune_Bookmarks_At_Or_After;

   function Has_Marker
     (State : Gutter_Marker_State;
      Row   : Natural;
      Kind  : Gutter_Marker_Kind) return Boolean
   is
      Found : Boolean;
      Index : Natural;
   begin
      Index := Find_Row_Index (State, Row, Found);
      return Found and then State.Rows.Element (Index).Markers (Kind);
   end Has_Marker;

   function Action_For_Marker
     (Kind : Gutter_Marker_Kind) return Gutter_Marker_Action
   is
   begin
      case Kind is
         when Diagnostic_Error_Marker
            | Diagnostic_Warning_Marker =>
            return Select_Diagnostic_Action;

         when Added_Line_Marker
            | Modified_Line_Marker
            | Dirty_Line_Marker =>
            return Acknowledge_Dirty_Line_Action;

         when Bookmark_Marker =>
            return Toggle_Bookmark_Action;
      end case;
   end Action_For_Marker;

   function Dominant_Marker_For_Row
     (State : Gutter_Marker_State;
      Row   : Natural;
      Found : out Boolean) return Gutter_Marker_Kind
   is
      Row_Found     : Boolean;
      Index         : Natural;
      Item          : Row_Marker_State;
      Best_Kind     : Gutter_Marker_Kind := Dirty_Line_Marker;
      Best_Priority : Natural := Natural'Last;
   begin
      Found := False;
      Index := Find_Row_Index (State, Row, Row_Found);

      if not Row_Found then
         return Dirty_Line_Marker;
      end if;

      Item := State.Rows.Element (Index);

      for Kind in Gutter_Marker_Kind loop
         if Item.Markers (Kind)
           and then Priority (Kind) < Best_Priority
         then
            Best_Kind     := Kind;
            Best_Priority := Priority (Kind);
            Found         := True;
         end if;
      end loop;

      return Best_Kind;
   end Dominant_Marker_For_Row;

end Editor.Gutter_Markers;
