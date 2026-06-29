with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Contextual_Help;
with Editor.Input_Field;

package body Editor.Feature_Search_Results is

   use type Editor.Feature_Panel.Feature_Id;

   function Trim_Image (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Trim_Image;

   function Lower (Text : String) return String is
      Result : String := Text;
   begin
      for I in Result'Range loop
         Result (I) := Ada.Characters.Handling.To_Lower (Result (I));
      end loop;
      return Result;
   end Lower;

   Max_Search_Query_History : constant Natural := 20;

   function Truncate_Search_Result_Context
     (Line         : String;
      Match_Column : Natural;
      Match_Length : Natural;
      Max_Length   : Natural := Max_Search_Result_Context_Length) return String
   is
      First_Text : Natural := Line'First;
      Last_Text  : Natural := Line'Last;
   begin
      if Max_Length = 0 or else Line'Length = 0 then
         return "";
      end if;

      while First_Text <= Line'Last
        and then (Line (First_Text) = ' ' or else Line (First_Text) = ASCII.HT)
      loop
         First_Text := First_Text + 1;
      end loop;

      if First_Text > Line'Last then
         return "";
      end if;

      while Last_Text >= First_Text
        and then (Line (Last_Text) = ' ' or else Line (Last_Text) = ASCII.HT)
      loop
         Last_Text := Last_Text - 1;
      end loop;

      declare
         Trimmed       : constant String := Line (First_Text .. Last_Text);
         Leading_Count : constant Natural := First_Text - Line'First;
         Adjusted_Col  : constant Natural :=
           (if Match_Column > Leading_Count then Match_Column - Leading_Count else 1);
         Match_Start   : constant Natural :=
           Natural'Min (Natural'Max (Adjusted_Col, 1), Trimmed'Length);
         Match_End     : constant Natural :=
           Natural'Min (Trimmed'Length, Match_Start + Natural'Max (Match_Length, 1) - 1);
         Context_Body  : Natural := 0;
         Start_Pos     : Natural := 1;
         Stop_Pos      : Natural := Trimmed'Length;
      begin
         if Trimmed'Length <= Max_Length then
            return Trimmed;
         elsif Max_Length <= 3 then
            return Trimmed (Trimmed'First .. Trimmed'First + Max_Length - 1);
         end if;

         if Match_End <= Max_Length - 3 then
            Stop_Pos := Max_Length - 3;
            declare
               Prefix : constant String :=
                 Trimmed (Trimmed'First .. Trimmed'First + Stop_Pos - 1);
               Last   : Integer := Prefix'Last;
            begin
               if Last >= Prefix'First
                 and then (Prefix (Last) = '.' or else Prefix (Last) = ' ')
               then
                  Last := Last - 1;
               end if;
               if Last < Prefix'First then
                  return "...";
               else
                  return Prefix (Prefix'First .. Last) & "...";
               end if;
            end;
         elsif Match_Start >= Trimmed'Length - (Max_Length - 3) + 1 then
            Start_Pos := Trimmed'Length - (Max_Length - 3) + 1;
            return "..." & Trimmed (Trimmed'First + Start_Pos - 1 .. Trimmed'Last);
         else
            if Max_Length <= 6 then
               Context_Body := Max_Length - 3;
               Start_Pos := Match_Start;
               Stop_Pos := Natural'Min (Trimmed'Length, Start_Pos + Context_Body - 1);
               return "..." & Trimmed (Trimmed'First + Start_Pos - 1 .. Trimmed'First + Stop_Pos - 1);
            end if;

            Context_Body := Max_Length - 6;
            Start_Pos := Match_Start - Natural'Min (Match_Start - 1, Context_Body / 2);
            if Start_Pos + Context_Body - 1 > Trimmed'Length then
               Start_Pos := Trimmed'Length - Context_Body + 1;
            end if;
            Stop_Pos := Start_Pos + Context_Body - 1;
            declare
               Body_Text : constant String :=
                 Trimmed (Trimmed'First + Start_Pos - 1
                          .. Trimmed'First + Stop_Pos - 1);
               Last      : Integer := Body_Text'Last;
            begin
               if Last >= Body_Text'First
                 and then (Body_Text (Last) = '.' or else Body_Text (Last) = ' ')
               then
                  Last := Last - 1;
               end if;
               if Last < Body_Text'First then
                  return "......";
               else
                  return "..." & Body_Text (Body_Text'First .. Last) & "...";
               end if;
            end;
         end if;
      end;
   end Truncate_Search_Result_Context;

   function Build_Search_Result_Context
     (Line_Text    : String;
      Match_Column : Natural;
      Match_Length : Natural) return String
   is
   begin
      return Truncate_Search_Result_Context
        (Line_Text, Match_Column, Match_Length, Max_Search_Result_Context_Length);
   end Build_Search_Result_Context;

   function Format_Search_Result_Label
     (Source_Label : String;
      Match_Line   : Natural;
      Match_Column : Natural;
      Match_Length : Natural;
      Line_Text    : String) return String
   is
      Prefix : constant String :=
        (if Source_Label'Length = 0 then "buffer" else Source_Label)
        & ":" & Trim_Image (Match_Line) & ": ";
   begin
      return Prefix & Build_Search_Result_Context (Line_Text, Match_Column, Match_Length);
   end Format_Search_Result_Label;

   function Format_Label
     (Source_Label : String;
      Line         : Natural;
      Column       : Natural;
      Length       : Natural;
      Line_Text    : String) return String
   is
   begin
      return Format_Search_Result_Label (Source_Label, Line, Column, Length, Line_Text);
   end Format_Label;

   procedure Reset_Query_State (Results : in out Search_Results_Feature_State) is
   begin
      Results.Query_Text := Null_Unbounded_String;
      Results.Has_Query := False;
      Results.Match_Count := 0;
      Results.Searched_Buffer := No_Buffer;
      Results.Searched_Label := Null_Unbounded_String;
      Results.Snapshot_Version := 0;
      Results.Results_Stale := False;
   end Reset_Query_State;

   procedure Assert_Search_Results_State_Consistent
     (Results : Search_Results_Feature_State)
   is
   begin
      pragma Assert (Results.Match_Count = Row_Count (Results));
      if not Results.Has_Query then
         pragma Assert (Length (Results.Query_Text) = 0);
      end if;
      for I in 1 .. Row_Count (Results) loop
         declare
            Item : constant Search_Result_Item := Results.Rows.Element (I - 1);
         begin
            pragma Assert (Item.Id /= No_Search_Result);
            pragma Assert (Item.Id < Results.Next_Id or else Results.Next_Id = Search_Result_Id'Last);
            if Item.Has_Target then
               pragma Assert (Item.Target_Buffer /= No_Buffer);
               pragma Assert (Item.Target_Line > 0);
               pragma Assert (Item.Target_Column > 0);
            end if;
            if Item.Match_Length > 0 then
               pragma Assert (Item.Match_Line > 0);
               pragma Assert (Item.Match_Column > 0);
            end if;
            for J in I + 1 .. Row_Count (Results) loop
               pragma Assert (Item.Id /= Results.Rows.Element (J - 1).Id);
            end loop;
         end;
      end loop;
      pragma Assert (Results.History_Cursor <= Natural (Results.Query_History.Length));
      for I in 1 .. Natural (Results.Query_History.Length) loop
         pragma Assert (Length (Results.Query_History.Element (I - 1)) > 0);
         for J in I + 1 .. Natural (Results.Query_History.Length) loop
            pragma Assert
              (To_String (Results.Query_History.Element (I - 1)) /=
               To_String (Results.Query_History.Element (J - 1)));
         end loop;
      end loop;
   end Assert_Search_Results_State_Consistent;

   procedure Clear
     (Results : in out Search_Results_Feature_State)
   is
   begin
      Results.Rows.Clear;
      Reset_Query_State (Results);
      Results.Search_Input_Active := False;
      Editor.Input_Field.Clear (Results.Search_Input);
      Results.History_Cursor := 0;
      Assert_Search_Results_State_Consistent (Results);
   end Clear;

   procedure Activate_Search_Query_Input
     (Results : in out Search_Results_Feature_State)
   is
   begin
      Results.Search_Input_Active := True;
      if Editor.Input_Field.Is_Empty (Results.Search_Input) and then Results.Has_Query then
         Editor.Input_Field.Set_Text (Results.Search_Input, To_String (Results.Query_Text));
      end if;
      Editor.Input_Field.Move_Cursor_End (Results.Search_Input);
      Results.History_Cursor := 0;
      Assert_Search_Results_State_Consistent (Results);
   end Activate_Search_Query_Input;

   procedure Deactivate_Search_Query_Input
     (Results : in out Search_Results_Feature_State)
   is
   begin
      Results.Search_Input_Active := False;
      Results.History_Cursor := 0;
      Assert_Search_Results_State_Consistent (Results);
   end Deactivate_Search_Query_Input;

   function Search_Input_Is_Active
     (Results : Search_Results_Feature_State) return Boolean is
   begin
      return Results.Search_Input_Active;
   end Search_Input_Is_Active;

   function Search_Input_Text
     (Results : Search_Results_Feature_State) return String is
   begin
      return Editor.Input_Field.Text (Results.Search_Input);
   end Search_Input_Text;

   function Search_Input_Caret
     (Results : Search_Results_Feature_State) return Natural is
   begin
      return Editor.Input_Field.Cursor_Column (Results.Search_Input);
   end Search_Input_Caret;

   procedure Set_Search_Input_Text
     (Results : in out Search_Results_Feature_State;
      Text    : String)
   is
   begin
      Editor.Input_Field.Set_Text (Results.Search_Input, Text);
      Results.History_Cursor := 0;
      Assert_Search_Results_State_Consistent (Results);
   end Set_Search_Input_Text;

   procedure Insert_Search_Input_Character
     (Results : in out Search_Results_Feature_State;
      Ch      : Character)
   is
   begin
      Editor.Input_Field.Insert_Text (Results.Search_Input, String'(1 => Ch));
      Results.History_Cursor := 0;
      Assert_Search_Results_State_Consistent (Results);
   end Insert_Search_Input_Character;

   procedure Delete_Search_Input_Character_Backward
     (Results : in out Search_Results_Feature_State)
   is
   begin
      Editor.Input_Field.Backspace (Results.Search_Input);
      Results.History_Cursor := 0;
      Assert_Search_Results_State_Consistent (Results);
   end Delete_Search_Input_Character_Backward;

   procedure Delete_Search_Input_Character_Forward
     (Results : in out Search_Results_Feature_State)
   is
   begin
      Editor.Input_Field.Delete_Forward (Results.Search_Input);
      Results.History_Cursor := 0;
      Assert_Search_Results_State_Consistent (Results);
   end Delete_Search_Input_Character_Forward;

   procedure Commit_Search_Query_To_History
     (Results : in out Search_Results_Feature_State;
      Query   : String)
   is
      Existing : Natural := 0;
   begin
      if Query'Length = 0 then
         return;
      end if;
      for I in 1 .. Natural (Results.Query_History.Length) loop
         if To_String (Results.Query_History.Element (I - 1)) = Query then
            Existing := I - 1;
         end if;
      end loop;
      if Existing /= 0 or else
        (Natural (Results.Query_History.Length) > 0 and then
         To_String (Results.Query_History.Element (0)) = Query)
      then
         Results.Query_History.Delete (Existing);
      end if;
      Results.Query_History.Append (To_Unbounded_String (Query));
      while Natural (Results.Query_History.Length) > Max_Search_Query_History loop
         Results.Query_History.Delete_First;
      end loop;
      Results.History_Cursor := 0;
      Assert_Search_Results_State_Consistent (Results);
   end Commit_Search_Query_To_History;

   procedure Select_Previous_Search_Query
     (Results : in out Search_Results_Feature_State)
   is
      Count : constant Natural := Natural (Results.Query_History.Length);
   begin
      if Count = 0 then
         return;
      end if;
      if Results.History_Cursor < Count then
         Results.History_Cursor := Results.History_Cursor + 1;
      end if;
      Editor.Input_Field.Set_Text
        (Results.Search_Input,
         To_String (Results.Query_History.Element (Count - Results.History_Cursor)));
      Assert_Search_Results_State_Consistent (Results);
   end Select_Previous_Search_Query;

   procedure Select_Next_Search_Query
     (Results : in out Search_Results_Feature_State)
   is
      Count : constant Natural := Natural (Results.Query_History.Length);
   begin
      if Count = 0 or else Results.History_Cursor = 0 then
         return;
      end if;
      Results.History_Cursor := Results.History_Cursor - 1;
      if Results.History_Cursor = 0 then
         Editor.Input_Field.Set_Text (Results.Search_Input, "");
      else
         Editor.Input_Field.Set_Text
           (Results.Search_Input,
            To_String (Results.Query_History.Element (Count - Results.History_Cursor)));
      end if;
      Assert_Search_Results_State_Consistent (Results);
   end Select_Next_Search_Query;

   function Search_Query_History_Count
     (Results : Search_Results_Feature_State) return Natural is
   begin
      return Natural (Results.Query_History.Length);
   end Search_Query_History_Count;

   function Search_Query_History_Item
     (Results : Search_Results_Feature_State;
      Index   : Positive) return String is
   begin
      if Index > Natural (Results.Query_History.Length) then
         return "";
      end if;
      return To_String (Results.Query_History.Element (Index - 1));
   end Search_Query_History_Item;

   function Case_Sensitive
     (Results : Search_Results_Feature_State) return Boolean is
   begin
      return Results.Case_Sensitive;
   end Case_Sensitive;

   procedure Toggle_Case_Sensitive
     (Results : in out Search_Results_Feature_State)
   is
   begin
      Results.Case_Sensitive := not Results.Case_Sensitive;
      Assert_Search_Results_State_Consistent (Results);
   end Toggle_Case_Sensitive;

   procedure Add_Search_Result
     (Results       : in out Search_Results_Feature_State;
      Label         : String;
      Source_Label  : String := "";
      Has_Target    : Boolean := False;
      Target_Buffer : Natural := No_Buffer;
      Target_Line   : Natural := 0;
      Target_Column : Natural := 0;
      Query         : String := "";
      Line_Text     : String := "";
      Match_Line    : Natural := 0;
      Match_Column  : Natural := 0;
      Match_Length  : Natural := 0)
   is
      Target_Is_Valid : constant Boolean :=
        Has_Target and then Target_Buffer /= No_Buffer and then Target_Line > 0 and then Target_Column > 0;
      Item : Search_Result_Item;
   begin
      Item.Id := Results.Next_Id;
      Item.Label := To_Unbounded_String (Label);
      Item.Source_Label := To_Unbounded_String (Source_Label);
      Item.Query := To_Unbounded_String (Query);
      Item.Line_Text := To_Unbounded_String (Line_Text);
      Item.Match_Line := Match_Line;
      Item.Match_Column := Match_Column;
      Item.Match_Length := Match_Length;
      Item.Has_Target := Target_Is_Valid;
      if Target_Is_Valid then
         Item.Target_Buffer := Target_Buffer;
         Item.Target_Line := Target_Line;
         Item.Target_Column := Target_Column;
      end if;
      Results.Rows.Append (Item);
      Results.Match_Count := Natural (Results.Rows.Length);
      if Results.Next_Id < Search_Result_Id'Last then
         Results.Next_Id := Results.Next_Id + 1;
      end if;
      Assert_Search_Results_State_Consistent (Results);
   end Add_Search_Result;

   procedure Run_Active_Buffer_Search
     (Results         : in out Search_Results_Feature_State;
      Query           : String;
      Snapshot_Text   : String;
      Source_Label    : String;
      Target_Buffer   : Natural;
      Snapshot_Version : Natural := 0;
      Case_Sensitive   : Boolean := False)
   is
      Effective_Case_Sensitive : constant Boolean :=
        Results.Case_Sensitive or else Case_Sensitive;
      Folded_Query : constant String :=
        (if Effective_Case_Sensitive then Query else Lower (Query));
      Line_Start   : Positive := Snapshot_Text'First;
      Line_No      : Natural := 1;
   begin
      Results.Rows.Clear;
      Results.Query_Text := To_Unbounded_String (Query);
      Results.Has_Query := True;
      Results.Match_Count := 0;
      Results.Searched_Buffer := Target_Buffer;
      Results.Searched_Label := To_Unbounded_String (Source_Label);
      Results.Snapshot_Version := Snapshot_Version;
      Results.Results_Stale := False;
      Results.Case_Sensitive := Effective_Case_Sensitive;

      if Query'Length = 0 then
         Results.Has_Query := False;
         Results.Query_Text := Null_Unbounded_String;
         Assert_Search_Results_State_Consistent (Results);
         return;
      end if;

      if Snapshot_Text'Length = 0 then
         Assert_Search_Results_State_Consistent (Results);
         return;
      end if;

      while Line_Start <= Snapshot_Text'Last loop
         declare
            Line_End : Natural := Line_Start;
         begin
            while Line_End <= Snapshot_Text'Last and then Snapshot_Text (Line_End) /= ASCII.LF loop
               Line_End := Line_End + 1;
            end loop;

            declare
               Raw_Last : constant Natural :=
                 (if Line_End > Line_Start and then Snapshot_Text (Line_End - 1) = ASCII.CR
                  then Line_End - 2 else Line_End - 1);
               Line : constant String :=
                 (if Raw_Last >= Line_Start then Snapshot_Text (Line_Start .. Raw_Last) else "");
               Folded_Line : constant String :=
                 (if Effective_Case_Sensitive then Line else Lower (Line));
               Pos : Natural := 1;
            begin
               while Query'Length > 0 and then Pos + Query'Length - 1 <= Folded_Line'Length loop
                  if Folded_Line (Folded_Line'First + Pos - 1 .. Folded_Line'First + Pos + Query'Length - 2) = Folded_Query then
                     Add_Search_Result
                       (Results       => Results,
                        Label         => Format_Label (Source_Label, Line_No, Pos, Query'Length, Line),
                        Source_Label  => Source_Label,
                        Has_Target    => Target_Buffer /= No_Buffer,
                        Target_Buffer => Target_Buffer,
                        Target_Line   => Line_No,
                        Target_Column => Pos,
                        Query         => Query,
                        Line_Text     => Line,
                        Match_Line    => Line_No,
                        Match_Column  => Pos,
                        Match_Length  => Query'Length);
                  end if;
                  Pos := Pos + 1;
               end loop;
            end;

            exit when Line_End > Snapshot_Text'Last;
            Line_Start := Line_End + 1;
            Line_No := Line_No + 1;
         end;
      end loop;
      Assert_Search_Results_State_Consistent (Results);
   end Run_Active_Buffer_Search;

   procedure Begin_External_Result_Set
     (Results      : in out Search_Results_Feature_State;
      Query        : String;
      Source_Label : String := "")
   is
   begin
      Results.Rows.Clear;
      Results.Query_Text := To_Unbounded_String (Query);
      Results.Has_Query := Query'Length > 0;
      Results.Match_Count := 0;
      Results.Searched_Buffer := No_Buffer;
      Results.Searched_Label := To_Unbounded_String (Source_Label);
      Results.Snapshot_Version := 0;
      Results.Results_Stale := False;
      Results.Search_Input_Active := False;
      Editor.Input_Field.Clear (Results.Search_Input);
      Results.History_Cursor := 0;
      Assert_Search_Results_State_Consistent (Results);
   end Begin_External_Result_Set;

   function Best_Rerun_Selection
     (Results         : Search_Results_Feature_State;
      Previous_Buffer : Natural;
      Previous_Line   : Natural;
      Previous_Column : Natural;
      Previous_Length : Natural;
      Previous_Text   : String) return Natural
   is
      Nearest : Natural := 0;
   begin
      if Previous_Buffer = No_Buffer then
         return (if Row_Count (Results) > 0 then 1 else 0);
      end if;
      for I in 1 .. Row_Count (Results) loop
         declare
            Item : constant Search_Result_Item := Results.Rows.Element (I - 1);
         begin
            if Item.Target_Buffer = Previous_Buffer
              and then Item.Match_Line = Previous_Line
              and then Item.Match_Column = Previous_Column
              and then Item.Match_Length = Previous_Length
              and then To_String (Item.Line_Text) = Previous_Text
            then
               return I;
            end if;
            if Nearest = 0
              and then Item.Target_Buffer = Previous_Buffer
              and then (Item.Match_Line > Previous_Line
                or else (Item.Match_Line = Previous_Line and then Item.Match_Column >= Previous_Column))
            then
               Nearest := I;
            end if;
         end;
      end loop;
      if Nearest /= 0 then
         return Nearest;
      elsif Row_Count (Results) > 0 then
         return 1;
      else
         return 0;
      end if;
   end Best_Rerun_Selection;

   procedure Mark_Stale_For_Buffer_Change
     (Results         : in out Search_Results_Feature_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural := 0)
   is
   begin
      if Results.Has_Query
        and then Results.Searched_Buffer = Buffer_Token
        and then Buffer_Token /= No_Buffer
        and then (Buffer_Revision = 0 or else Buffer_Revision /= Results.Snapshot_Version)
      then
         Results.Results_Stale := True;
      end if;
      Assert_Search_Results_State_Consistent (Results);
   end Mark_Stale_For_Buffer_Change;

   function Row_Count (Results : Search_Results_Feature_State) return Natural is
   begin
      return Natural (Results.Rows.Length);
   end Row_Count;

   function Is_Empty (Results : Search_Results_Feature_State) return Boolean is
   begin
      return Row_Count (Results) = 0;
   end Is_Empty;

   function Has_Query (Results : Search_Results_Feature_State) return Boolean is
   begin
      return Results.Has_Query;
   end Has_Query;

   function Query_Text (Results : Search_Results_Feature_State) return String is
   begin
      return To_String (Results.Query_Text);
   end Query_Text;

   function Match_Count (Results : Search_Results_Feature_State) return Natural is
   begin
      return Results.Match_Count;
   end Match_Count;

   function Searched_Buffer (Results : Search_Results_Feature_State) return Natural is
   begin
      return Results.Searched_Buffer;
   end Searched_Buffer;

   function Searched_Label (Results : Search_Results_Feature_State) return String is
   begin
      return To_String (Results.Searched_Label);
   end Searched_Label;

   function Snapshot_Version (Results : Search_Results_Feature_State) return Natural is
   begin
      return Results.Snapshot_Version;
   end Snapshot_Version;

   function Results_Stale (Results : Search_Results_Feature_State) return Boolean is
   begin
      return Results.Results_Stale;
   end Results_Stale;

   function Header_Text (Results : Search_Results_Feature_State) return String is
      Query : constant String := To_String (Results.Query_Text);
      Mode  : constant String :=
        (if Results.Results_Stale then "stale - "
         elsif Results.Case_Sensitive then "case-sensitive - "
         else "");
      Prefix : constant String := "Search Results: " & Mode;
   begin
      if Results.Search_Input_Active then
         declare
            Input : constant String := Editor.Input_Field.Text (Results.Search_Input);
         begin
            if Input'Length = 0 then
               return "Search Results: query input";
            else
               return "Search Results: query """ & Input & """";
            end if;
         end;
      elsif not Results.Has_Query then
         return "Search Results: no query";
      elsif Results.Match_Count = 0 then
         return Prefix & "no matches for """ & Query & """";
      elsif Results.Match_Count = 1 then
         return Prefix & "1 match for """ & Query & """";
      else
         return Prefix & Trim_Image (Results.Match_Count) & " matches for """ & Query & """";
      end if;
   end Header_Text;

   function Item_At
     (Results : Search_Results_Feature_State;
      Index   : Positive) return Search_Result_Item
   is
   begin
      if Index > Row_Count (Results) then
         return (others => <>);
      end if;
      return Results.Rows.Element (Index - 1);
   end Item_At;

   function Item_Id (Results : Search_Results_Feature_State; Index : Positive) return Search_Result_Id is
   begin
      return Item_At (Results, Index).Id;
   end Item_Id;

   function Item_Label (Results : Search_Results_Feature_State; Index : Positive) return String is
   begin
      return To_String (Item_At (Results, Index).Label);
   end Item_Label;

   function Item_Source_Label (Results : Search_Results_Feature_State; Index : Positive) return String is
   begin
      return To_String (Item_At (Results, Index).Source_Label);
   end Item_Source_Label;

   function Item_Has_Target (Results : Search_Results_Feature_State; Index : Positive) return Boolean is
   begin
      return Item_At (Results, Index).Has_Target;
   end Item_Has_Target;

   function Item_Target_Buffer (Results : Search_Results_Feature_State; Index : Positive) return Natural is
   begin
      return Item_At (Results, Index).Target_Buffer;
   end Item_Target_Buffer;

   function Item_Target_Line (Results : Search_Results_Feature_State; Index : Positive) return Natural is
   begin
      return Item_At (Results, Index).Target_Line;
   end Item_Target_Line;

   function Item_Target_Column (Results : Search_Results_Feature_State; Index : Positive) return Natural is
   begin
      return Item_At (Results, Index).Target_Column;
   end Item_Target_Column;

   function Item_Match_Line (Results : Search_Results_Feature_State; Index : Positive) return Natural is
   begin
      return Item_At (Results, Index).Match_Line;
   end Item_Match_Line;

   function Item_Match_Column (Results : Search_Results_Feature_State; Index : Positive) return Natural is
   begin
      return Item_At (Results, Index).Match_Column;
   end Item_Match_Column;

   function Item_Match_Length (Results : Search_Results_Feature_State; Index : Positive) return Natural is
   begin
      return Item_At (Results, Index).Match_Length;
   end Item_Match_Length;

   function Item_Line_Text (Results : Search_Results_Feature_State; Index : Positive) return String is
   begin
      return To_String (Item_At (Results, Index).Line_Text);
   end Item_Line_Text;

   function Format_Search_Result_For_Copy
     (Results : Search_Results_Feature_State;
      Index   : Positive) return String
   is
      Item : constant Search_Result_Item := Item_At (Results, Index);
   begin
      if Item.Id = No_Search_Result then
         return "";
      elsif Length (Item.Line_Text) > 0 and then Item.Match_Line > 0 then
         return Format_Search_Result_Label
           (To_String (Item.Source_Label),
            Item.Match_Line,
            Item.Match_Column,
            Item.Match_Length,
            To_String (Item.Line_Text));
      else
         return To_String (Item.Label);
      end if;
   end Format_Search_Result_For_Copy;

   function Projected_Label_For (Item : Search_Result_Item) return String is
   begin
      if Length (Item.Line_Text) > 0 and then Item.Match_Line > 0 then
         return Format_Search_Result_Label
           (To_String (Item.Source_Label),
            Item.Match_Line,
            Item.Match_Column,
            Item.Match_Length,
            To_String (Item.Line_Text));
      end if;
      return To_String (Item.Label);
   end Projected_Label_For;

   function Detail_For (Item : Search_Result_Item) return String is
      Source : constant String := To_String (Item.Source_Label);
   begin
      if Item.Has_Target then
         declare
            Pos : constant String := Trim_Image (Item.Target_Line) & ":" & Trim_Image (Item.Target_Column);
         begin
            if Source'Length = 0 then
               return Pos;
            else
               return Source & ":" & Pos;
            end if;
         end;
      end if;
      return Source;
   end Detail_For;

   procedure Project_Rows
     (Results : Search_Results_Feature_State;
      Panel   : in out Editor.Feature_Panel.Feature_Panel_State)
   is
   begin
      if not Editor.Feature_Panel.Set_Active_Feature
        (Panel, Editor.Feature_Panel.Search_Results_Feature)
      then
         return;
      end if;
      Editor.Feature_Panel.Clear_Rows (Panel);
      Editor.Feature_Panel.Set_Header_Text (Panel, Header_Text (Results));
      if Row_Count (Results) = 0 then
         Editor.Feature_Panel.Append_Row
           (Panel,
            Kind        => Editor.Feature_Panel.Feature_Row_Empty_State,
            Label       => (if Results.Has_Query or else Results.Search_Input_Active then Header_Text (Results) else "No search results."),
            Detail      => Editor.Contextual_Help.Empty_Search_Results_Detail (Results.Has_Query),
            Selectable  => False,
            Activatable => False,
            Has_Target  => False,
            Can_Open    => False,
            Source_Index => 0);
      else
         for I in 1 .. Row_Count (Results) loop
            declare
               Item : constant Search_Result_Item := Results.Rows.Element (I - 1);
            begin
               Editor.Feature_Panel.Append_Row
                 (Panel,
                  Kind         => Editor.Feature_Panel.Feature_Row_Item,
                  Label        => Projected_Label_For (Item),
                  Detail       => Detail_For (Item),
                  Selectable   => True,
                  Activatable  => Item.Has_Target,
                  Has_Target   => Item.Has_Target,
                  Can_Open     => Item.Has_Target,
                  Can_Clear    => True,
                  Source_Index => Natural (Item.Id));
            end;
         end loop;
      end if;
   end Project_Rows;

   procedure Reconcile_Search_Results_After_Row_Change
     (Results                     : in out Search_Results_Feature_State;
      Panel                       : in out Editor.Feature_Panel.Feature_Panel_State;
      Preferred_Result            : Search_Result_Id := No_Search_Result;
      Select_First_When_Available : Boolean := False)
   is
      Preferred_Row : Natural := 0;
      Selected_Id   : Search_Result_Id := Preferred_Result;
   begin
      Results.Match_Count := Natural (Results.Rows.Length);
      Editor.Feature_Panel.Forget_Feature_View_State
        (Panel, Editor.Feature_Panel.Search_Results_Feature);

      if Selected_Id = No_Search_Result
        and then Editor.Feature_Panel.Active_Feature (Panel) = Editor.Feature_Panel.Search_Results_Feature
        and then Editor.Feature_Panel.Projection_Row_Index_Is_Valid
          (Panel, Editor.Feature_Panel.Selected_Row (Panel))
      then
         Selected_Id := Search_Result_Id
           (Editor.Feature_Panel.Row_Source_Index
              (Panel, Positive (Editor.Feature_Panel.Selected_Row (Panel))));
      end if;

      Project_Rows (Results, Panel);

      if Selected_Id /= No_Search_Result then
         for I in 1 .. Row_Count (Results) loop
            if Results.Rows.Element (I - 1).Id = Selected_Id then
               Preferred_Row := I;
               exit;
            end if;
         end loop;
      end if;

      if Preferred_Row = 0 and then Select_First_When_Available and then Row_Count (Results) > 0 then
         Preferred_Row := 1;
      end if;

      Editor.Feature_Panel.Select_Row (Panel, Preferred_Row);
      Assert_Search_Results_State_Consistent (Results);
      pragma Assert (Editor.Feature_Panel.Invariant_Holds (Panel));
   end Reconcile_Search_Results_After_Row_Change;

   function Index_For_Id
     (Results : Search_Results_Feature_State;
      Id      : Search_Result_Id) return Natural
   is
   begin
      if Id = No_Search_Result then
         return 0;
      end if;
      for I in 1 .. Row_Count (Results) loop
         if Results.Rows.Element (I - 1).Id = Id then
            return I;
         end if;
      end loop;
      return 0;
   end Index_For_Id;

   function Map_Search_Result_Row_To_Item
     (Results                        : Search_Results_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Natural
   is
      Id_Value : Natural := 0;
   begin
      if Editor.Feature_Panel.Active_Feature (Panel) /= Editor.Feature_Panel.Search_Results_Feature
        or else not Editor.Feature_Panel.Projection_Generation_Matches
          (Panel, Expected_Projection_Generation)
        or else not Editor.Feature_Panel.Projection_Row_Index_Is_Valid (Panel, Row)
      then
         return 0;
      end if;
      Id_Value := Editor.Feature_Panel.Row_Source_Index (Panel, Positive (Row));
      if Id_Value = 0 then
         return 0;
      end if;
      return Index_For_Id (Results, Search_Result_Id (Id_Value));
   end Map_Search_Result_Row_To_Item;

   function Validate_Search_Result_Target
     (Results             : Search_Results_Feature_State;
      Index               : Positive;
      Active_Buffer_Token : Natural) return Boolean
   is
      Item : constant Search_Result_Item := Item_At (Results, Index);
   begin
      return Item.Id /= No_Search_Result
        and then Item.Has_Target
        and then Active_Buffer_Token /= No_Buffer
        and then Item.Target_Buffer = Active_Buffer_Token
        and then Item.Target_Line > 0
        and then Item.Target_Column > 0;
   end Validate_Search_Result_Target;

   function Validate_Row_Action
     (Results                        : Search_Results_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Boolean
   is
   begin
      return Map_Search_Result_Row_To_Item
        (Results, Panel, Row, Expected_Projection_Generation) /= 0;
   end Validate_Row_Action;

   procedure Reset_For_Buffer_Close
     (Results      : in out Search_Results_Feature_State;
      Buffer_Token : Natural)
   is
   begin
      Reset_Search_Results_For_Buffer_Close (Results, Buffer_Token);
   end Reset_For_Buffer_Close;

   procedure Reset_Search_Results_For_Buffer_Close
     (Results      : in out Search_Results_Feature_State;
      Buffer_Token : Natural)
   is
   begin
      if Buffer_Token = No_Buffer then
         return;
      elsif Results.Searched_Buffer = Buffer_Token then
         Clear (Results);
      else
         declare
            I : Natural := 0;
         begin
            while I < Natural (Results.Rows.Length) loop
               if Results.Rows.Element (I).Has_Target
                 and then Results.Rows.Element (I).Target_Buffer = Buffer_Token
               then
                  Results.Rows.Delete (I);
               else
                  I := I + 1;
               end if;
            end loop;
            Results.Match_Count := Natural (Results.Rows.Length);
            if Results.Match_Count = 0 then
               Reset_Query_State (Results);
            end if;
            if Results.Search_Input_Active and then Results.Searched_Buffer = Buffer_Token then
               Results.Search_Input_Active := False;
               Editor.Input_Field.Clear (Results.Search_Input);
            end if;
         end;
      end if;
      Assert_Search_Results_State_Consistent (Results);
   end Reset_Search_Results_For_Buffer_Close;

   procedure Reset_Search_Results_For_No_Active_Buffer
     (Results : in out Search_Results_Feature_State)
   is
   begin
      Clear (Results);
   end Reset_Search_Results_For_No_Active_Buffer;

   procedure Reset_For_Project_Close (Results : in out Search_Results_Feature_State) is
   begin
      Reset_Search_Results_For_Project_Close (Results);
   end Reset_For_Project_Close;

   procedure Reset_Search_Results_For_Project_Close
     (Results : in out Search_Results_Feature_State)
   is
   begin
      --  Project close clears rows/query/input/stale state but preserves the
      --  session-local bounded query history until workspace close.
      Clear (Results);
   end Reset_Search_Results_For_Project_Close;

   procedure Reset_For_Workspace_Close (Results : in out Search_Results_Feature_State) is
   begin
      Reset_Search_Results_For_Workspace_Close (Results);
   end Reset_For_Workspace_Close;

   procedure Reset_Search_Results_For_Workspace_Close
     (Results : in out Search_Results_Feature_State)
   is
   begin
      Clear (Results);
      Results.Query_History.Clear;
      Results.History_Cursor := 0;
      Assert_Search_Results_State_Consistent (Results);
   end Reset_Search_Results_For_Workspace_Close;

   function Message_Search_Results_Shown return String is
   begin
      return "Search Results shown";
   end Message_Search_Results_Shown;

   function Message_Search_Results_Cleared return String is
   begin
      return "Search Results cleared";
   end Message_Search_Results_Cleared;

   function Message_No_Search_Results return String is
   begin
      return "Search Results: no results";
   end Message_No_Search_Results;

   function Message_No_Target return String is
   begin
      return "Search Results: no selected result";
   end Message_No_Target;

   function Message_Target_Unavailable return String is
   begin
      return "Search Results: target unavailable";
   end Message_Target_Unavailable;

   function Message_Stale_Result return String is
   begin
      return "Search Results: stale result";
   end Message_Stale_Result;

   function Message_First_Result return String is
   begin
      return "Search Results: first result";
   end Message_First_Result;

   function Message_Last_Result return String is
   begin
      return "Search Results: last result";
   end Message_Last_Result;

   function Message_Search_Repeated return String is
   begin
      return "Search Results: repeated search";
   end Message_Search_Repeated;

   function Message_Search_Query_Input_Cancelled return String is
   begin
      return "Search Results: query input cancelled";
   end Message_Search_Query_Input_Cancelled;

   function Message_Search_Active_Buffer_Completed
     (Results : Search_Results_Feature_State) return String
   is
   begin
      if Results.Match_Count = 0 then
         return "Search Results: no matches";
      elsif Results.Match_Count = 1 then
         return "Search Results: 1 match";
      else
         return "Search Results: " & Trim_Image (Results.Match_Count) & " matches";
      end if;
   end Message_Search_Active_Buffer_Completed;

   function Message_Search_Active_Buffer_Empty_Query return String is
   begin
      return "Search Results: empty query";
   end Message_Search_Active_Buffer_Empty_Query;

   function Message_Search_Active_Buffer_No_Active_Buffer return String is
   begin
      return "Search Results: no active buffer";
   end Message_Search_Active_Buffer_No_Active_Buffer;

   function Message_Search_Query_Input_Focused return String is
   begin
      return "Search Results: query input active";
   end Message_Search_Query_Input_Focused;

   function Message_Search_Repeat_No_Query return String is
   begin
      return "Search Results: no query";
   end Message_Search_Repeat_No_Query;

end Editor.Feature_Search_Results;
