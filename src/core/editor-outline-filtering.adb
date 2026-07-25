with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Outline.Projection; use Editor.Outline.Projection;
with Editor.Outline.Selection; use Editor.Outline.Selection;

package body Editor.Outline.Filtering is

   Max_Filter_History : constant Natural := 10;

   function Normalize_Filter_Text (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));
   end Normalize_Filter_Text;

   function Normalize_History_Filter_Text (Text : String) return String is
   begin
      return Normalize_Filter_Text (Text);
   end Normalize_History_Filter_Text;

   procedure Reset_Filter_History_Cursor (Outline : in out Outline_State) is
   begin
      Outline.Filter_History_Cursor := 0;
   end Reset_Filter_History_Cursor;

   function Next_Generation (Value : Natural) return Natural is
   begin
      if Value = Natural'Last then
         return 1;
      end if;
      return Value + 1;
   end Next_Generation;

   procedure Bump_Filter_Generation (Outline : in out Outline_State) is
   begin
      Outline.Filter_Generation := Next_Generation (Outline.Filter_Generation);
      Outline.Projection_Generation := Next_Generation (Outline.Projection_Generation);
   end Bump_Filter_Generation;

   procedure Clear_Filtered_Projection (Outline : in out Outline_State) is
   begin
      Outline.Filter_Active := False;
      Outline.Filter_Text_Value := To_Unbounded_String ("");
      Outline.Filter_Caret_Position := 0;
      Outline.Filtered_Count := 0;
      Bump_Filter_Generation (Outline);
   end Clear_Filtered_Projection;

   function Row_Matches_Filter
     (Outline : Outline_State;
      Index   : Positive) return Boolean
   is
      Query : constant String := To_String (Outline.Filter_Text_Value);
      Item  : constant Outline_Item := Outline.Items (Index - 1);
      Label  : constant String := Ada.Characters.Handling.To_Lower (To_String (Item.Label));
      Detail : constant String := Ada.Characters.Handling.To_Lower (To_String (Item.Detail));
      Kind   : constant String := Kind_Text (Item.Kind);
   begin
      return (not Outline.Filter_Active)
        or else Query = ""
        or else Ada.Strings.Fixed.Index (Label, Query) /= 0
        or else Ada.Strings.Fixed.Index (Detail, Query) /= 0
        or else Ada.Strings.Fixed.Index (Kind, Query) /= 0;
   end Row_Matches_Filter;

   function First_Visible_Selectable_Row (Outline : Outline_State) return Natural is
   begin
      for I in 1 .. Item_Count (Outline) loop
         if Row_Matches_Filter (Outline, I)
           and then Is_Selectable_Target_Row (Outline, I)
         then
            return I;
         end if;
      end loop;
      return 0;
   end First_Visible_Selectable_Row;

   function Compute_Filtered_Count (Outline : Outline_State) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Item_Count (Outline) loop
         if Row_Matches_Filter (Outline, I) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Compute_Filtered_Count;

   procedure Reconcile_Filtered_Selection (Outline : in out Outline_State) is
   begin
      Outline.Filtered_Count := Compute_Filtered_Count (Outline);
      if Outline.Selected /= 0
        and then Outline.Selected <= Item_Count (Outline)
        and then Row_Matches_Filter (Outline, Positive (Outline.Selected))
        and then Is_Selectable_Target_Row (Outline, Positive (Outline.Selected))
      then
         return;
      end if;
      Outline.Selected := First_Visible_Selectable_Row (Outline);
   end Reconcile_Filtered_Selection;

   procedure Set_Filter_Text_Normalized
     (Outline : in out Outline_State;
      Text    : String)
   is
      Normalized : constant String := Normalize_Filter_Text (Text);
   begin
      if Outline.Source in No_Outline | Unsupported_Content | Extraction_Failed then
         Outline.Filter_Input_Active := False;
         Clear_Filtered_Projection (Outline);
         Reset_Filter_History_Cursor (Outline);
         return;
      end if;

      Outline.Filter_Text_Value := To_Unbounded_String (Normalized);
      Outline.Filter_Active := Normalized /= "";
      Bump_Filter_Generation (Outline);
      if Outline.Filter_Caret_Position > Normalized'Length then
         Outline.Filter_Caret_Position := Normalized'Length;
      end if;
      Reset_Filter_History_Cursor (Outline);
      Reconcile_Filtered_Selection (Outline);
   end Set_Filter_Text_Normalized;

   procedure Activate_Filter_Input
     (Outline : in out Outline_State)
   is
   begin
      Outline.Filter_Input_Active := True;
      Outline.Filter_Caret_Position := Length (Outline.Filter_Text_Value);
      Reconcile_Filtered_Selection (Outline);
   end Activate_Filter_Input;

   procedure Deactivate_Filter_Input
     (Outline : in out Outline_State)
   is
   begin
      Outline.Filter_Input_Active := False;
   end Deactivate_Filter_Input;

   function Filter_Input_Is_Active
     (Outline : Outline_State) return Boolean
   is
   begin
      return Outline.Filter_Input_Active;
   end Filter_Input_Is_Active;

   function Filter_Caret
     (Outline : Outline_State) return Natural
   is
   begin
      return Outline.Filter_Caret_Position;
   end Filter_Caret;

   procedure Apply_Filter
     (Outline : in out Outline_State;
      Text    : String)
   is
   begin
      Set_Filter_Text_Normalized (Outline, Text);
      Outline.Filter_Caret_Position := Length (Outline.Filter_Text_Value);
   end Apply_Filter;

   procedure Insert_Filter_Character
     (Outline : in out Outline_State;
      Ch      : Character)
   is
   begin
      Insert_Filter_Text (Outline, String'(1 => Ch));
   end Insert_Filter_Character;

   procedure Insert_Filter_Text
     (Outline : in out Outline_State;
      Text    : String)
   is
      Current : constant String := To_String (Outline.Filter_Text_Value);
      Caret   : constant Natural := Natural'Min (Outline.Filter_Caret_Position, Current'Length);
      Next    : constant String :=
        (if Caret = 0 then Text & Current
         elsif Caret = Current'Length then Current & Text
         else Current (Current'First .. Current'First + Caret - 1) & Text &
              Current (Current'First + Caret .. Current'Last));
   begin
      Set_Filter_Text_Normalized (Outline, Next);
      Outline.Filter_Input_Active := True;
      Outline.Filter_Caret_Position := Caret + Text'Length;
   end Insert_Filter_Text;

   procedure Delete_Filter_Character_Backward
     (Outline : in out Outline_State)
   is
      Current : constant String := To_String (Outline.Filter_Text_Value);
      Caret   : constant Natural := Natural'Min (Outline.Filter_Caret_Position, Current'Length);
   begin
      if Caret = 0 or else Current'Length = 0 then
         return;
      end if;
      declare
         Next : constant String :=
           (if Caret = 1 then
               (if Current'Length = 1 then "" else Current (Current'First + 1 .. Current'Last))
            elsif Caret = Current'Length then Current (Current'First .. Current'Last - 1)
            else Current (Current'First .. Current'First + Caret - 2) &
                 Current (Current'First + Caret .. Current'Last));
      begin
         Set_Filter_Text_Normalized (Outline, Next);
         Outline.Filter_Input_Active := True;
         Outline.Filter_Caret_Position := Caret - 1;
      end;
   end Delete_Filter_Character_Backward;

   procedure Delete_Filter_Character_Forward
     (Outline : in out Outline_State)
   is
      Current : constant String := To_String (Outline.Filter_Text_Value);
      Caret   : constant Natural := Natural'Min (Outline.Filter_Caret_Position, Current'Length);
   begin
      if Caret >= Current'Length then
         return;
      end if;
      declare
         Next : constant String :=
           (if Current'Length = 1 then ""
            elsif Caret = 0 then Current (Current'First + 1 .. Current'Last)
            else Current (Current'First .. Current'First + Caret - 1) &
                 Current (Current'First + Caret + 1 .. Current'Last));
      begin
         Set_Filter_Text_Normalized (Outline, Next);
         Outline.Filter_Input_Active := True;
         Outline.Filter_Caret_Position := Caret;
      end;
   end Delete_Filter_Character_Forward;

   procedure Move_Filter_Caret_Left
     (Outline : in out Outline_State)
   is
   begin
      if Outline.Filter_Caret_Position > 0 then
         Outline.Filter_Caret_Position := Outline.Filter_Caret_Position - 1;
      end if;
   end Move_Filter_Caret_Left;

   procedure Move_Filter_Caret_Right
     (Outline : in out Outline_State)
   is
   begin
      if Outline.Filter_Caret_Position < Length (Outline.Filter_Text_Value) then
         Outline.Filter_Caret_Position := Outline.Filter_Caret_Position + 1;
      end if;
   end Move_Filter_Caret_Right;

   procedure Move_Filter_Caret_Start
     (Outline : in out Outline_State)
   is
   begin
      Outline.Filter_Caret_Position := 0;
   end Move_Filter_Caret_Start;

   procedure Move_Filter_Caret_End
     (Outline : in out Outline_State)
   is
   begin
      Outline.Filter_Caret_Position := Length (Outline.Filter_Text_Value);
   end Move_Filter_Caret_End;

   procedure Clear_Filter_Text
     (Outline : in out Outline_State)
   is
   begin
      Outline.Filter_Active := False;
      Outline.Filter_Text_Value := To_Unbounded_String ("");
      Outline.Filter_Caret_Position := 0;
      Bump_Filter_Generation (Outline);
      Reset_Filter_History_Cursor (Outline);
      Reconcile_Filtered_Selection (Outline);
   end Clear_Filter_Text;

   procedure Clear_Filter
     (Outline : in out Outline_State)
   is
   begin
      Outline.Filter_Input_Active := False;
      Clear_Filter_Text (Outline);
   end Clear_Filter;

   procedure Reset_Filter_State_For_Lifecycle
     (Outline : in out Outline_State)
   is
   begin
      Outline.Filter_Input_Active := False;
      Clear_Filtered_Projection (Outline);
      Reset_Filter_History_Cursor (Outline);
      Reconcile_Filtered_Selection (Outline);
   end Reset_Filter_State_For_Lifecycle;

   procedure Commit_Filter_To_History
     (Outline : in out Outline_State)
   is
      Normalized : constant String :=
        Normalize_History_Filter_Text (To_String (Outline.Filter_Text_Value));
      Found : Natural := 0;
   begin
      if Normalized = "" then
         Reset_Filter_History_Cursor (Outline);
         return;
      end if;

      if not Outline.Recent_Filters.Is_Empty then
         for I in Outline.Recent_Filters.First_Index ..
           Outline.Recent_Filters.Last_Index
         loop
            if To_String (Outline.Recent_Filters (I)) = Normalized then
               Found := I + 1;
               exit;
            end if;
         end loop;
      end if;

      if Found /= 0 then
         Outline.Recent_Filters.Delete (Found - 1);
      end if;

      Outline.Recent_Filters.Insert (0, To_Unbounded_String (Normalized));

      while Natural (Outline.Recent_Filters.Length) > Max_Filter_History loop
         Outline.Recent_Filters.Delete_Last;
      end loop;

      Reset_Filter_History_Cursor (Outline);
   end Commit_Filter_To_History;

   function Filter_History_Count
     (Outline : Outline_State) return Natural
   is
   begin
      return Natural (Outline.Recent_Filters.Length);
   end Filter_History_Count;

   function Filter_History_Entry
     (Outline : Outline_State;
      Index   : Positive) return String
   is
   begin
      return To_String (Outline.Recent_Filters (Index - 1));
   end Filter_History_Entry;

   function Select_Previous_Filter_History_Entry
     (Outline : in out Outline_State) return Boolean
   is
      Count : constant Natural := Filter_History_Count (Outline);
      Next  : Natural := 0;
   begin
      if not Outline.Filter_Input_Active or else Count = 0 then
         return False;
      end if;

      if Outline.Filter_History_Cursor = 0 then
         Next := 1;
      elsif Outline.Filter_History_Cursor < Count then
         Next := Outline.Filter_History_Cursor + 1;
      else
         return False;
      end if;

      Outline.Filter_History_Cursor := Next;
      Outline.Filter_Text_Value := Outline.Recent_Filters (Next - 1);
      Outline.Filter_Active := Length (Outline.Filter_Text_Value) /= 0;
      Bump_Filter_Generation (Outline);
      Outline.Filter_Caret_Position := Length (Outline.Filter_Text_Value);
      Reconcile_Filtered_Selection (Outline);
      return True;
   end Select_Previous_Filter_History_Entry;

   function Select_Next_Filter_History_Entry
     (Outline : in out Outline_State) return Boolean
   is
      Count : constant Natural := Filter_History_Count (Outline);
      Next  : Natural := 0;
   begin
      if not Outline.Filter_Input_Active
        or else Count = 0
        or else Outline.Filter_History_Cursor = 0
      then
         return False;
      end if;

      if Outline.Filter_History_Cursor > 1 then
         Next := Outline.Filter_History_Cursor - 1;
         Outline.Filter_History_Cursor := Next;
         Outline.Filter_Text_Value := Outline.Recent_Filters (Next - 1);
         Outline.Filter_Active := Length (Outline.Filter_Text_Value) /= 0;
         Bump_Filter_Generation (Outline);
         Outline.Filter_Caret_Position := Length (Outline.Filter_Text_Value);
      else
         Outline.Filter_History_Cursor := 0;
         Clear_Filtered_Projection (Outline);
      end if;

      Reconcile_Filtered_Selection (Outline);
      return True;
   end Select_Next_Filter_History_Entry;

   procedure Clear_Filter_History
     (Outline : in out Outline_State)
   is
   begin
      Outline.Recent_Filters.Clear;
      Reset_Filter_History_Cursor (Outline);
   end Clear_Filter_History;

   procedure Remember_Filter_For_Buffer
     (Outline      : in out Outline_State;
      Buffer_Token : Natural)
   is
      Text  : constant String := To_String (Outline.Filter_Text_Value);
      Found : Natural := 0;
   begin
      if Buffer_Token = 0 then
         return;
      end if;

      if not Outline.Remembered_Filters.Is_Empty then
         for I in Outline.Remembered_Filters.First_Index ..
           Outline.Remembered_Filters.Last_Index
         loop
            if Outline.Remembered_Filters (I).Buffer_Token = Buffer_Token then
               Found := I + 1;
               exit;
            end if;
         end loop;
      end if;

      if Text = "" then
         if Found /= 0 then
            Outline.Remembered_Filters.Delete (Found - 1);
         end if;
         return;
      end if;

      if Found /= 0 then
         Outline.Remembered_Filters.Replace_Element
           (Found - 1,
            (Buffer_Token => Buffer_Token, Text => To_Unbounded_String (Text)));
      else
         Outline.Remembered_Filters.Append
           (Remembered_Filter'
             (Buffer_Token => Buffer_Token, Text => To_Unbounded_String (Text)));
      end if;
   end Remember_Filter_For_Buffer;

   function Restore_Filter_For_Buffer
     (Outline      : in out Outline_State;
      Buffer_Token : Natural) return Boolean
   is
      Text  : Unbounded_String := Null_Unbounded_String;
      Found : Boolean := False;
   begin
      if not Outline_Buffer_Identity_Matches (Outline, Buffer_Token) then
         return False;
      end if;

      if not Outline.Remembered_Filters.Is_Empty then
         for I in Outline.Remembered_Filters.First_Index ..
           Outline.Remembered_Filters.Last_Index
         loop
            if Outline.Remembered_Filters (I).Buffer_Token = Buffer_Token then
               Text := Outline.Remembered_Filters (I).Text;
               Found := True;
               exit;
            end if;
         end loop;
      end if;

      if not Found then
         return False;
      end if;

      Outline.Filter_Input_Active := False;
      Outline.Filter_Text_Value := Text;
      Outline.Filter_Active := Length (Text) /= 0;
      Bump_Filter_Generation (Outline);
      Outline.Filter_Caret_Position := Length (Text);
      Reset_Filter_History_Cursor (Outline);
      Reconcile_Filtered_Selection (Outline);
      return Outline.Filter_Active;
   end Restore_Filter_For_Buffer;

   procedure Forget_Filter_For_Buffer
     (Outline      : in out Outline_State;
      Buffer_Token : Natural)
   is
   begin
      if Buffer_Token = 0 then
         return;
      end if;

      if not Outline.Remembered_Filters.Is_Empty then
         for I in reverse Outline.Remembered_Filters.First_Index ..
           Outline.Remembered_Filters.Last_Index
         loop
            if Outline.Remembered_Filters (I).Buffer_Token = Buffer_Token then
               Outline.Remembered_Filters.Delete (I);
               exit;
            end if;
         end loop;
      end if;
   end Forget_Filter_For_Buffer;

   procedure Clear_All_Remembered_Filters
     (Outline : in out Outline_State)
   is
   begin
      Outline.Remembered_Filters.Clear;
   end Clear_All_Remembered_Filters;

   function Remembered_Filter_Count
     (Outline : Outline_State) return Natural
   is
   begin
      return Natural (Outline.Remembered_Filters.Length);
   end Remembered_Filter_Count;

   function Filter_Is_Active
     (Outline : Outline_State) return Boolean
   is
   begin
      return Outline.Filter_Active;
   end Filter_Is_Active;

   function Filter_Text
     (Outline : Outline_State) return String
   is
   begin
      return To_String (Outline.Filter_Text_Value);
   end Filter_Text;

   function Filtered_Row_Count
     (Outline : Outline_State) return Natural
   is
   begin
      if Outline.Filter_Active then
         return Outline.Filtered_Count;
      end if;
      return Item_Count (Outline);
   end Filtered_Row_Count;

   function Rows_Generation
     (Outline : Outline_State) return Natural
   is
   begin
      return Outline.Rows_Generation;
   end Rows_Generation;

   function Filter_Generation
     (Outline : Outline_State) return Natural
   is
   begin
      return Outline.Filter_Generation;
   end Filter_Generation;

   function Projection_Generation
     (Outline : Outline_State) return Natural
   is
   begin
      return Outline.Projection_Generation;
   end Projection_Generation;

   function Visible_Row_For_Outline_Row
     (Outline           : Outline_State;
      Outline_Row_Index : Natural) return Natural
   is
      Visible : Natural := 0;
   begin
      if Outline_Row_Index = 0 or else Outline_Row_Index > Item_Count (Outline) then
         return 0;
      end if;
      for I in 1 .. Outline_Row_Index loop
         if Row_Matches_Filter (Outline, I) then
            Visible := Visible + 1;
         end if;
      end loop;
      if Row_Matches_Filter (Outline, Positive (Outline_Row_Index)) then
         return Visible;
      end if;
      return 0;
   end Visible_Row_For_Outline_Row;

   function Outline_Row_For_Visible_Row
     (Outline           : Outline_State;
      Visible_Row_Index : Natural) return Natural
   is
      Visible : Natural := 0;
   begin
      if Visible_Row_Index = 0 then
         return 0;
      end if;
      for I in 1 .. Item_Count (Outline) loop
         if Row_Matches_Filter (Outline, I) then
            Visible := Visible + 1;
            if Visible = Visible_Row_Index then
               return I;
            end if;
         end if;
      end loop;
      return 0;
   end Outline_Row_For_Visible_Row;

end Editor.Outline.Filtering;
