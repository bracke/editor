with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Contextual_Help;
with Ada.Strings.Fixed;

package body Editor.Feature_Messages is

   use type Editor.Feature_Panel.Feature_Id;

   Max_Retained_Message_Rows : constant Natural := 200;
   Max_Message_Label_Text_Length : constant Natural := 96;

   function Trim_Image (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Trim_Image;

   function Plural
     (Count       : Natural;
      Singular    : String;
      Plural_Word : String) return String
   is
   begin
      return Trim_Image (Count) & " " & (if Count = 1 then Singular else Plural_Word);
   end Plural;

   function Lower (Value : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Value);
   end Lower;

   function Safe_Message_Text (Text : String) return String is
      Trimmed : constant String :=
        Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   begin
      if Trimmed'Length = 0 then
         return "(empty message)";
      elsif Trimmed'Length <= Max_Message_Label_Text_Length then
         return Trimmed;
      else
         return Trimmed
           (Trimmed'First .. Trimmed'First + Max_Message_Label_Text_Length - 1)
           & "...";
      end if;
   end Safe_Message_Text;

   function Source_Display_For
     (Item : Message_Item) return String
   is
      Source : constant String := Ada.Strings.Fixed.Trim
        (To_String (Item.Source_Label), Ada.Strings.Both);
   begin
      if Source'Length > 0 then
         return Source;
      elsif Item.Source_Kind /= Unknown_Source then
         return Source_Kind_Label (Item.Source_Kind);
      else
         return "";
      end if;
   end Source_Display_For;

   function Severity_Label
     (Severity : Message_Severity) return String
   is
   begin
      case Severity is
         when Info_Message    => return "info";
         when Warning_Message => return "warning";
         when Error_Message   => return "error";
      end case;
   end Severity_Label;

   function Source_Kind_Label
     (Kind : Message_Source_Kind) return String
   is
   begin
      case Kind is
         when Editor_Source    => return "editor";
         when File_Source      => return "file";
         when Project_Source   => return "project";
         when Workspace_Source => return "workspace";
         when Command_Source   => return "command";
         when Unknown_Source   => return "unknown";
      end case;
   end Source_Kind_Label;

   function Max_Retained_Messages return Natural is
   begin
      return Max_Retained_Message_Rows;
   end Max_Retained_Messages;


   procedure Assert_Messages_State_Consistent
     (Messages : Message_Feature_State)
   is
   begin
      pragma Assert (Natural (Messages.Rows.Length) <= Max_Retained_Message_Rows);
      for I in 1 .. Row_Count (Messages) loop
         declare
            Item : constant Message_Item := Messages.Rows.Element (I - 1);
         begin
            pragma Assert (Item.Id /= No_Message);
            pragma Assert (Item.Id < Messages.Next_Id or else Messages.Next_Id = Message_Id'Last);
            pragma Assert (Item.Repeat_Count >= 1);
            if Item.Has_Target then
               pragma Assert (Item.Target_Buffer /= No_Buffer);
               pragma Assert (Item.Target_Line > 0);
               pragma Assert (Item.Target_Column > 0);
            end if;

            for J in I + 1 .. Row_Count (Messages) loop
               pragma Assert (Item.Id /= Messages.Rows.Element (J - 1).Id);
            end loop;
         end;
      end loop;
   end Assert_Messages_State_Consistent;

   function Panel_Severity
     (Severity : Message_Severity)
      return Editor.Feature_Panel.Feature_Row_Severity
   is
   begin
      case Severity is
         when Info_Message =>
            return Editor.Feature_Panel.Feature_Row_Info_Severity;
         when Warning_Message =>
            return Editor.Feature_Panel.Feature_Row_Warning_Severity;
         when Error_Message =>
            return Editor.Feature_Panel.Feature_Row_Error_Severity;
      end case;
   end Panel_Severity;

   function Label_For
     (Item : Message_Item) return String
   is
      Base : constant String :=
        Severity_Label (Item.Severity) & ": "
        & Safe_Message_Text (To_String (Item.Text));
   begin
      if Item.Repeat_Count > 1 then
         return Base & " (x" & Trim_Image (Item.Repeat_Count) & ")";
      else
         return Base;
      end if;
   end Label_For;

   function Detail_For
     (Item : Message_Item) return String
   is
      Source : constant String := Source_Display_For (Item);
   begin
      if Source'Length = 0 and then not Item.Has_Target then
         return "";
      elsif Item.Has_Target then
         declare
            Position : constant String :=
              Trim_Image (Item.Target_Line) & ":" & Trim_Image (Item.Target_Column);
         begin
            if Source'Length = 0 then
               return Position;
            else
               return Source & ":" & Position;
            end if;
         end;
      else
         return Source;
      end if;
   end Detail_For;

   function Severity_Is_Visible
     (Messages : Message_Feature_State;
      Severity : Message_Severity) return Boolean
   is
   begin
      case Severity is
         when Info_Message    => return Messages.Filter.Show_Info;
         when Warning_Message => return Messages.Filter.Show_Warnings;
         when Error_Message   => return Messages.Filter.Show_Errors;
      end case;
   end Severity_Is_Visible;

   function Filter_Is_Active
     (Messages : Message_Feature_State) return Boolean
   is
   begin
      return Length (Messages.Filter.Text) > 0
        or else not Messages.Filter.Show_Info
        or else not Messages.Filter.Show_Warnings
        or else not Messages.Filter.Show_Errors;
   end Filter_Is_Active;

   function Message_Matches_Text_Filter
     (Messages : Message_Feature_State;
      Item     : Message_Item) return Boolean
   is
      Needle : constant String := Lower (To_String (Messages.Filter.Text));
      Hay    : constant String := Lower
        (To_String (Item.Text) & " " &
         To_String (Item.Source_Label) & " " &
         Source_Kind_Label (Item.Source_Kind) & " " &
         Detail_For (Item) & " " & Severity_Label (Item.Severity));
   begin
      return Needle'Length = 0
        or else Ada.Strings.Fixed.Index (Hay, Needle) /= 0;
   end Message_Matches_Text_Filter;

   function Message_Is_Visible
     (Messages : Message_Feature_State;
      Item     : Message_Item) return Boolean
   is
   begin
      return Severity_Is_Visible (Messages, Item.Severity)
        and then Message_Matches_Text_Filter (Messages, Item);
   end Message_Is_Visible;

   function Visible_Row_Count
     (Messages : Message_Feature_State) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Row_Count (Messages) loop
         if Message_Is_Visible (Messages, Messages.Rows.Element (I - 1)) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Visible_Row_Count;

   procedure Set_Filter_Text
     (Messages : in out Message_Feature_State;
      Text     : String)
   is
   begin
      Messages.Filter.Text := To_Unbounded_String
        (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));
   end Set_Filter_Text;

   procedure Clear_Filter
     (Messages : in out Message_Feature_State)
   is
   begin
      Messages.Filter.Text := Null_Unbounded_String;
      Messages.Filter.Show_Info := True;
      Messages.Filter.Show_Warnings := True;
      Messages.Filter.Show_Errors := True;
   end Clear_Filter;

   procedure Show_All
     (Messages : in out Message_Feature_State)
   is
   begin
      Clear_Filter (Messages);
   end Show_All;

   procedure Toggle_Info
     (Messages : in out Message_Feature_State)
   is
   begin
      Messages.Filter.Show_Info := not Messages.Filter.Show_Info;
   end Toggle_Info;

   procedure Toggle_Warnings
     (Messages : in out Message_Feature_State)
   is
   begin
      Messages.Filter.Show_Warnings := not Messages.Filter.Show_Warnings;
   end Toggle_Warnings;

   procedure Toggle_Errors
     (Messages : in out Message_Feature_State)
   is
   begin
      Messages.Filter.Show_Errors := not Messages.Filter.Show_Errors;
   end Toggle_Errors;

   function Same_Target
     (Left  : Message_Item;
      Right : Message_Item) return Boolean
   is
   begin
      if Left.Has_Target /= Right.Has_Target then
         return False;
      elsif not Left.Has_Target then
         return True;
      else
         return Left.Target_Buffer = Right.Target_Buffer
           and then Left.Target_Line = Right.Target_Line
           and then Left.Target_Column = Right.Target_Column;
      end if;
   end Same_Target;

   function Same_Dedup_Key
     (Left  : Message_Item;
      Right : Message_Item) return Boolean
   is
   begin
      return Left.Severity = Right.Severity
        and then Left.Source_Kind = Right.Source_Kind
        and then To_String (Left.Source_Label) = To_String (Right.Source_Label)
        and then To_String (Left.Text) = To_String (Right.Text)
        and then Same_Target (Left, Right);
   end Same_Dedup_Key;

   procedure Evict_Old_Messages_If_Needed
     (Messages : in out Message_Feature_State)
   is
   begin
      while Natural (Messages.Rows.Length) > Max_Retained_Message_Rows loop
         Messages.Rows.Delete (Messages.Rows.First_Index);
      end loop;
   end Evict_Old_Messages_If_Needed;

   procedure Add_Message
     (Messages   : in out Message_Feature_State;
      Severity   : Message_Severity;
      Text       : String;
      Source     : String := "";
      Has_Target : Boolean := False;
      Buffer     : Natural := No_Buffer;
      Line       : Natural := 0;
      Column     : Natural := 0;
      Source_Kind : Message_Source_Kind := Unknown_Source)
   is
      Target_Is_Valid : constant Boolean :=
        Has_Target and then Buffer /= No_Buffer and then Line > 0 and then Column > 0;
      Item            : Message_Item;
   begin
      Item.Id := Messages.Next_Id;
      Item.Severity := Severity;
      Item.Text := To_Unbounded_String (Text);
      Item.Source_Kind := Source_Kind;
      Item.Source_Label := To_Unbounded_String (Source);
      Item.Has_Target := Target_Is_Valid;
      if Target_Is_Valid then
         Item.Target_Buffer := Buffer;
         Item.Target_Line := Line;
         Item.Target_Column := Column;
      end if;

      if not Messages.Rows.Is_Empty then
         declare
            Last_Index : constant Natural := Natural (Messages.Rows.Last_Index);
            Last_Item  : Message_Item := Messages.Rows.Element (Last_Index);
         begin
            if Same_Dedup_Key (Last_Item, Item) then
               if Last_Item.Repeat_Count < Positive'Last then
                  Last_Item.Repeat_Count := Last_Item.Repeat_Count + 1;
               end if;
               Messages.Rows.Replace_Element (Last_Index, Last_Item);
               Assert_Messages_State_Consistent (Messages);
               return;
            end if;
         end;
      end if;

      Messages.Rows.Append (Item);
      if Messages.Next_Id < Message_Id'Last then
         Messages.Next_Id := Messages.Next_Id + 1;
      end if;
      Evict_Old_Messages_If_Needed (Messages);
      Assert_Messages_State_Consistent (Messages);
   end Add_Message;

   procedure Clear_Messages
     (Messages : in out Message_Feature_State)
   is
   begin
      Messages.Rows.Clear;
      Assert_Messages_State_Consistent (Messages);
   end Clear_Messages;

   procedure Clear
     (Messages : in out Message_Feature_State)
   is
   begin
      Clear_Messages (Messages);
   end Clear;

   function Row_Count
     (Messages : Message_Feature_State) return Natural
   is
   begin
      return Natural (Messages.Rows.Length);
   end Row_Count;

   function Is_Empty
     (Messages : Message_Feature_State) return Boolean
   is
   begin
      return Row_Count (Messages) = 0;
   end Is_Empty;

   function Item_At
     (Messages : Message_Feature_State;
      Index    : Positive) return Message_Item
   is
   begin
      if Index > Row_Count (Messages) then
         return (others => <>);
      end if;
      return Messages.Rows.Element (Index - 1);
   end Item_At;

   function Item_Id
     (Messages : Message_Feature_State;
      Index    : Positive) return Message_Id
   is
   begin
      return Item_At (Messages, Index).Id;
   end Item_Id;

   function Item_Severity
     (Messages : Message_Feature_State;
      Index    : Positive) return Message_Severity
   is
   begin
      return Item_At (Messages, Index).Severity;
   end Item_Severity;

   function Item_Text
     (Messages : Message_Feature_State;
      Index    : Positive) return String
   is
   begin
      return To_String (Item_At (Messages, Index).Text);
   end Item_Text;

   function Item_Source_Label
     (Messages : Message_Feature_State;
      Index    : Positive) return String
   is
   begin
      return To_String (Item_At (Messages, Index).Source_Label);
   end Item_Source_Label;

   function Item_Source_Kind
     (Messages : Message_Feature_State;
      Index    : Positive) return Message_Source_Kind
   is
   begin
      return Item_At (Messages, Index).Source_Kind;
   end Item_Source_Kind;

   function Item_Repeat_Count
     (Messages : Message_Feature_State;
      Index    : Positive) return Positive
   is
   begin
      return Item_At (Messages, Index).Repeat_Count;
   end Item_Repeat_Count;

   function Item_Has_Target
     (Messages : Message_Feature_State;
      Index    : Positive) return Boolean
   is
   begin
      return Item_At (Messages, Index).Has_Target;
   end Item_Has_Target;

   function Item_Target_Buffer
     (Messages : Message_Feature_State;
      Index    : Positive) return Natural
   is
   begin
      return Item_At (Messages, Index).Target_Buffer;
   end Item_Target_Buffer;

   function Item_Target_Line
     (Messages : Message_Feature_State;
      Index    : Positive) return Natural
   is
   begin
      return Item_At (Messages, Index).Target_Line;
   end Item_Target_Line;

   function Item_Target_Column
     (Messages : Message_Feature_State;
      Index    : Positive) return Natural
   is
   begin
      return Item_At (Messages, Index).Target_Column;
   end Item_Target_Column;

   function Find_Message_Index_By_Id
     (Messages : Message_Feature_State;
      Id       : Message_Id) return Natural
   is
   begin
      if Id = No_Message then
         return 0;
      end if;
      for I in 1 .. Row_Count (Messages) loop
         if Messages.Rows.Element (I - 1).Id = Id then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Message_Index_By_Id;

   function Selected_Message_Source_Index
     (Messages : Message_Feature_State;
      Panel    : Editor.Feature_Panel.Feature_Panel_State) return Natural
   is
      Row : constant Natural := Editor.Feature_Panel.Selected_Row (Panel);
      Source : Natural := 0;
   begin
      if Row = 0
        or else Editor.Feature_Panel.Row_Count (Panel) = 0
        or else Editor.Feature_Panel.Row_Label (Panel, 1) /= "Messages"
        or else not Editor.Feature_Panel.Projection_Row_Index_Is_Valid (Panel, Row)
        or else not Editor.Feature_Panel.Row_Is_Selectable (Panel, Positive (Row))
      then
         return 0;
      end if;

      Source := Editor.Feature_Panel.Row_Source_Index (Panel, Positive (Row));
      if Source = 0 or else Source > Row_Count (Messages) then
         return 0;
      end if;

      declare
         Item : constant Message_Item := Messages.Rows.Element (Source - 1);
      begin
         if Editor.Feature_Panel.Row_Label (Panel, Positive (Row)) /= Label_For (Item)
           or else Editor.Feature_Panel.Row_Detail (Panel, Positive (Row)) /= Detail_For (Item)
         then
            return 0;
         end if;
      end;
      return Source;
   end Selected_Message_Source_Index;

   function Has_Selected_Message
     (Messages : Message_Feature_State;
      Panel    : Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
   begin
      return Selected_Message_Source_Index (Messages, Panel) /= 0;
   end Has_Selected_Message;

   function Selected_Message_Id
     (Messages : Message_Feature_State;
      Panel    : Editor.Feature_Panel.Feature_Panel_State) return Message_Id
   is
      Source : constant Natural := Selected_Message_Source_Index (Messages, Panel);
   begin
      if Source = 0 then
         return No_Message;
      else
         return Item_Id (Messages, Positive (Source));
      end if;
   end Selected_Message_Id;

   function Format_Message_For_Copy
     (Messages : Message_Feature_State;
      Index    : Positive) return String
   is
      Item : constant Message_Item := Item_At (Messages, Index);
      Source : constant String := Source_Display_For (Item);
      Result : Unbounded_String := To_Unbounded_String
        (Severity_Label (Item.Severity) & ": "
         & Safe_Message_Text (To_String (Item.Text)));
   begin
      if Index > Row_Count (Messages) or else Item.Id = No_Message then
         return "";
      end if;

      if Source'Length > 0 then
         Append (Result, " — ");
         Append (Result, Source);
      end if;

      if Item.Repeat_Count > 1 then
         Append (Result, " (x");
         Append (Result, Trim_Image (Item.Repeat_Count));
         Append (Result, ")");
      end if;
      return To_String (Result);
   end Format_Message_For_Copy;

   function Selected_Message_Text
     (Messages : Message_Feature_State;
      Panel    : Editor.Feature_Panel.Feature_Panel_State) return String
   is
      Source : constant Natural := Selected_Message_Source_Index (Messages, Panel);
   begin
      if Source = 0 then
         return "";
      else
         return Format_Message_For_Copy (Messages, Positive (Source));
      end if;
   end Selected_Message_Text;

   function Clear_Message_By_Id
     (Messages : in out Message_Feature_State;
      Id       : Message_Id) return Boolean
   is
      Index : constant Natural := Find_Message_Index_By_Id (Messages, Id);
   begin
      if Index = 0 then
         return False;
      end if;
      Messages.Rows.Delete (Index - 1);
      Assert_Messages_State_Consistent (Messages);
      return True;
   end Clear_Message_By_Id;

   function Clear_Selected_Message
     (Messages : in out Message_Feature_State;
      Panel    : in out Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
      Old_Source : constant Natural := Selected_Message_Source_Index (Messages, Panel);
      Id         : constant Message_Id := Selected_Message_Id (Messages, Panel);
      Removed    : Boolean := False;
   begin
      Removed := Clear_Message_By_Id (Messages, Id);
      if not Removed then
         Editor.Feature_Panel.Select_Row (Panel, 0);
         return False;
      end if;

      Reconcile_Messages_After_Row_Change
        (Messages, Panel, Id, Old_Source);
      return True;
   end Clear_Selected_Message;

   function Clear_Messages_By_Severity
     (Messages : in out Message_Feature_State;
      Severity : Message_Severity) return Natural
   is
      Removed : Natural := 0;
      I       : Message_Row_Vectors.Extended_Index := Messages.Rows.First_Index;
   begin
      while I <= Messages.Rows.Last_Index loop
         if Messages.Rows.Element (I).Severity = Severity then
            Messages.Rows.Delete (I);
            Removed := Removed + 1;
         else
            I := I + 1;
         end if;
      end loop;
      Assert_Messages_State_Consistent (Messages);
      return Removed;
   end Clear_Messages_By_Severity;

   function Clear_Messages_By_Source_Kind
     (Messages : in out Message_Feature_State;
      Kind     : Message_Source_Kind) return Natural
   is
      Removed : Natural := 0;
      I       : Message_Row_Vectors.Extended_Index := Messages.Rows.First_Index;
   begin
      while I <= Messages.Rows.Last_Index loop
         if Messages.Rows.Element (I).Source_Kind = Kind then
            Messages.Rows.Delete (I);
            Removed := Removed + 1;
         else
            I := I + 1;
         end if;
      end loop;
      Assert_Messages_State_Consistent (Messages);
      return Removed;
   end Clear_Messages_By_Source_Kind;

   procedure Reconcile_Messages_Selection_After_Delete
     (Messages        : Message_Feature_State;
      Panel           : in out Editor.Feature_Panel.Feature_Panel_State;
      Previous_Id     : Message_Id;
      Previous_Source : Natural)
   is
      Same_Row     : Natural := 0;
      Next_Row     : Natural := 0;
      Previous_Row : Natural := 0;
   begin
      for Row in 1 .. Editor.Feature_Panel.Row_Count (Panel) loop
         if Editor.Feature_Panel.Row_Is_Selectable (Panel, Row) then
            declare
               Source : constant Natural := Editor.Feature_Panel.Row_Source_Index (Panel, Row);
            begin
               if Source > 0 and then Source <= Row_Count (Messages) then
                  if Previous_Id /= No_Message
                    and then Item_Id (Messages, Positive (Source)) = Previous_Id
                  then
                     Same_Row := Row;
                  elsif Previous_Source /= 0 then
                     if Source >= Previous_Source and then Next_Row = 0 then
                        Next_Row := Row;
                     elsif Source < Previous_Source then
                        Previous_Row := Row;
                     end if;
                  end if;
               end if;
            end;
         end if;
      end loop;

      if Same_Row /= 0 then
         Editor.Feature_Panel.Select_Row (Panel, Same_Row);
      elsif Next_Row /= 0 then
         Editor.Feature_Panel.Select_Row (Panel, Next_Row);
      elsif Previous_Row /= 0 then
         Editor.Feature_Panel.Select_Row (Panel, Previous_Row);
      else
         Editor.Feature_Panel.Select_Row (Panel, 0);
      end if;
   end Reconcile_Messages_Selection_After_Delete;


   procedure Reconcile_Messages_After_Row_Change
     (Messages        : Message_Feature_State;
      Panel           : in out Editor.Feature_Panel.Feature_Panel_State;
      Previous_Id     : Message_Id := No_Message;
      Previous_Source : Natural := 0)
   is
   begin
      Assert_Messages_State_Consistent (Messages);
      Editor.Feature_Panel.Forget_Feature_View_State
        (Panel, Editor.Feature_Panel.Messages_Feature);
      if Editor.Feature_Panel.Active_Feature (Panel) = Editor.Feature_Panel.Messages_Feature then
         Project_Rows (Messages, Panel);
         if Previous_Id /= No_Message or else Previous_Source /= 0 then
            Reconcile_Messages_Selection_After_Delete
              (Messages, Panel, Previous_Id, Previous_Source);
         end if;
         Assert_Messages_Projection_Consistent (Messages, Panel);
      end if;
   end Reconcile_Messages_After_Row_Change;

   procedure Count_Severities
     (Messages : Message_Feature_State;
      Visible_Only : Boolean;
      Errors   : out Natural;
      Warnings : out Natural;
      Info     : out Natural)
   is
   begin
      Errors := 0;
      Warnings := 0;
      Info := 0;
      for I in 1 .. Row_Count (Messages) loop
         declare
            Item : constant Message_Item := Messages.Rows.Element (I - 1);
         begin
            if (not Visible_Only) or else Message_Is_Visible (Messages, Item) then
               case Item.Severity is
                  when Error_Message   => Errors := Errors + 1;
                  when Warning_Message => Warnings := Warnings + 1;
                  when Info_Message    => Info := Info + 1;
               end case;
            end if;
         end;
      end loop;
   end Count_Severities;

   function Severity_Summary
     (Errors   : Natural;
      Warnings : Natural;
      Info     : Natural) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if Errors > 0 then
         Append (Result, Plural (Errors, "error", "errors"));
      end if;
      if Warnings > 0 then
         if Length (Result) > 0 then
            Append (Result, ", ");
         end if;
         Append (Result, Plural (Warnings, "warning", "warnings"));
      end if;
      if Info > 0 then
         if Length (Result) > 0 then
            Append (Result, ", ");
         end if;
         Append (Result, Plural (Info, "info", "info"));
      end if;
      return To_String (Result);
   end Severity_Summary;

   function Build_Messages_Header_Text
     (Messages : Message_Feature_State) return String
   is
      Errors        : Natural := 0;
      Warnings      : Natural := 0;
      Info          : Natural := 0;
      Count         : constant Natural := Row_Count (Messages);
      Visible_Count : constant Natural := Visible_Row_Count (Messages);
   begin
      if Count = 0 then
         return "No messages";
      end if;

      if Filter_Is_Active (Messages) then
         if Visible_Count = 0 then
            return "Messages: no matching messages";
         else
            return "Messages: " & Trim_Image (Visible_Count) & " of " &
              Trim_Image (Count) & " messages";
         end if;
      end if;

      Count_Severities (Messages, False, Errors, Warnings, Info);
      if Errors = 0 and then Warnings = 0 and then Info = Count then
         return "Messages: " & Plural (Count, "message", "messages");
      else
         return "Messages: " & Severity_Summary (Errors, Warnings, Info);
      end if;
   end Build_Messages_Header_Text;


   procedure Project_Rows
     (Messages : Message_Feature_State;
      Panel    : in out Editor.Feature_Panel.Feature_Panel_State)
   is
      Previous_Id           : Message_Id := No_Message;
      Previous_Source_Index : Natural := 0;
      First_Row             : Natural := 0;
      Matched_Row           : Natural := 0;
      Fallback_Next_Row     : Natural := 0;
      Fallback_Previous_Row : Natural := 0;
   begin
      if not Editor.Feature_Panel.Set_Active_Feature
        (Panel, Editor.Feature_Panel.Messages_Feature)
      then
         return;
      end if;

      if Editor.Feature_Panel.Has_Selection (Panel) then
         declare
            Selected : constant Natural := Editor.Feature_Panel.Selected_Row (Panel);
            Source   : Natural := 0;
         begin
            if Editor.Feature_Panel.Projection_Row_Index_Is_Valid (Panel, Selected) then
               Source := Editor.Feature_Panel.Row_Source_Index (Panel, Positive (Selected));
               if Source > 0 and then Source <= Row_Count (Messages) then
                  Previous_Source_Index := Source;
                  Previous_Id := Item_Id (Messages, Positive (Source));
               end if;
            end if;
         end;
      end if;

      Editor.Feature_Panel.Clear_Rows (Panel);
      Editor.Feature_Panel.Set_Header_Text (Panel, Build_Messages_Header_Text (Messages));
      Editor.Feature_Panel.Append_Row
        (Panel      => Panel,
         Kind       => Editor.Feature_Panel.Feature_Row_Header,
         Label      => "Messages",
         Detail     => Build_Messages_Header_Text (Messages),
         Selectable => False);

      if Row_Count (Messages) = 0 then
         Editor.Feature_Panel.Append_Row
           (Panel         => Panel,
            Kind          => Editor.Feature_Panel.Feature_Row_Empty_State,
            Label         => "No messages",
            Detail        => Editor.Contextual_Help.Empty_Messages_Detail,
            Selectable    => False,
            Activatable   => False,
            Has_Target    => False,
            Is_Diagnostic => False);
      elsif Visible_Row_Count (Messages) = 0 then
         Editor.Feature_Panel.Append_Row
           (Panel         => Panel,
            Kind          => Editor.Feature_Panel.Feature_Row_Empty_State,
            Label         => "No matching messages",
            Detail        => "Clear the filter to show messages.",
            Selectable    => False,
            Activatable   => False,
            Has_Target    => False,
            Is_Diagnostic => False);
      else
         for I in 1 .. Row_Count (Messages) loop
            declare
               Item : constant Message_Item := Messages.Rows.Element (I - 1);
            begin
               if Message_Is_Visible (Messages, Item) then
                  Editor.Feature_Panel.Append_Row
                    (Panel         => Panel,
                     Kind          => Editor.Feature_Panel.Feature_Row_Item,
                     Label         => Label_For (Item),
                     Detail        => Detail_For (Item),
                     Selectable    => True,
                     Activatable   => Item.Has_Target,
                     Has_Target    => Item.Has_Target,
                     Is_Diagnostic => False,
                     Can_Open      => Item.Has_Target,
                     Can_Copy      => True,
                     Can_Clear     => True,
                     Source_Index  => I,
                     Severity      => Panel_Severity (Item.Severity));
                  if First_Row = 0 then
                     First_Row := Editor.Feature_Panel.Row_Count (Panel);
                  end if;
                  if Previous_Id /= No_Message and then Item.Id = Previous_Id then
                     Matched_Row := Editor.Feature_Panel.Row_Count (Panel);
                  elsif Previous_Source_Index /= 0 then
                     if I >= Previous_Source_Index and then Fallback_Next_Row = 0 then
                        Fallback_Next_Row := Editor.Feature_Panel.Row_Count (Panel);
                     elsif I < Previous_Source_Index then
                        Fallback_Previous_Row := Editor.Feature_Panel.Row_Count (Panel);
                     end if;
                  end if;
               end if;
            end;
         end loop;
      end if;

      if Matched_Row /= 0 then
         Editor.Feature_Panel.Select_Row (Panel, Matched_Row);
      elsif Previous_Source_Index /= 0 and then Fallback_Next_Row /= 0 then
         Editor.Feature_Panel.Select_Row (Panel, Fallback_Next_Row);
      elsif Previous_Source_Index /= 0 and then Fallback_Previous_Row /= 0 then
         Editor.Feature_Panel.Select_Row (Panel, Fallback_Previous_Row);
      elsif Previous_Id /= No_Message and then First_Row /= 0 then
         Editor.Feature_Panel.Select_Row (Panel, First_Row);
      else
         Editor.Feature_Panel.Select_Row (Panel, 0);
      end if;
   end Project_Rows;


   procedure Assert_Messages_Projection_Consistent
     (Messages : Message_Feature_State;
      Panel    : Editor.Feature_Panel.Feature_Panel_State)
   is
   begin
      if Editor.Feature_Panel.Row_Count (Panel) = 0 then
         return;
      end if;

      if Editor.Feature_Panel.Row_Label (Panel, 1) /= "Messages" then
         return;
      end if;

      pragma Assert (Editor.Feature_Panel.Row_Is_Selectable (Panel, 1) = False);
      for Row in 2 .. Editor.Feature_Panel.Row_Count (Panel) loop
         declare
            Source : constant Natural := Editor.Feature_Panel.Row_Source_Index (Panel, Row);
         begin
            if Source = 0 then
               pragma Assert (not Editor.Feature_Panel.Row_Is_Activatable (Panel, Row));
            else
               pragma Assert (Source <= Row_Count (Messages));
               pragma Assert (Message_Is_Visible (Messages, Messages.Rows.Element (Source - 1)));
               pragma Assert (Editor.Feature_Panel.Row_Label (Panel, Row) =
                              Label_For (Messages.Rows.Element (Source - 1)));
               pragma Assert (Editor.Feature_Panel.Row_Detail (Panel, Row) =
                              Detail_For (Messages.Rows.Element (Source - 1)));
            end if;
         end;
      end loop;
   end Assert_Messages_Projection_Consistent;

   function Map_Message_Row_To_Item
     (Messages                    : Message_Feature_State;
      Panel                       : Editor.Feature_Panel.Feature_Panel_State;
      Row                         : Natural;
      Expected_Projection_Generation : Natural := 0) return Natural
   is
      Source_Index : Natural;
   begin
      if Editor.Feature_Panel.Active_Feature (Panel) /=
           Editor.Feature_Panel.Messages_Feature
        or else not Editor.Feature_Panel.Projection_Generation_Matches
          (Panel, Expected_Projection_Generation)
        or else not Editor.Feature_Panel.Projection_Row_Index_Is_Valid (Panel, Row)
        or else Row = 0
      then
         return 0;
      end if;

      Source_Index := Editor.Feature_Panel.Row_Source_Index (Panel, Positive (Row));
      if Editor.Feature_Panel.Row_Count (Panel) = 0
        or else Editor.Feature_Panel.Row_Label (Panel, 1) /= "Messages"
      then
         return 0;
      end if;

      if Source_Index = 0 or else Source_Index > Row_Count (Messages) then
         return 0;
      end if;
      if not Message_Is_Visible (Messages, Messages.Rows.Element (Source_Index - 1)) then
         return 0;
      end if;
      if Editor.Feature_Panel.Row_Label (Panel, Positive (Row)) /=
           Label_For (Messages.Rows.Element (Source_Index - 1))
        or else Editor.Feature_Panel.Row_Detail (Panel, Positive (Row)) /=
           Detail_For (Messages.Rows.Element (Source_Index - 1))
      then
         return 0;
      end if;
      return Source_Index;
   end Map_Message_Row_To_Item;

   function Validate_Message_Target
     (Messages            : Message_Feature_State;
      Index               : Positive;
      Active_Buffer_Token : Natural) return Boolean
   is
      Item : constant Message_Item := Item_At (Messages, Index);
   begin
      return Index <= Row_Count (Messages)
        and then Item.Has_Target
        and then Item.Target_Buffer /= No_Buffer
        and then Item.Target_Buffer = Active_Buffer_Token
        and then Item.Target_Line > 0
        and then Item.Target_Column > 0;
   end Validate_Message_Target;

   procedure Reset_For_Buffer_Close
     (Messages     : in out Message_Feature_State;
      Buffer_Token : Natural)
   is
      I : Message_Row_Vectors.Extended_Index := Messages.Rows.First_Index;
   begin
      if Messages.Rows.Is_Empty or else Buffer_Token = No_Buffer then
         return;
      end if;

      while I <= Messages.Rows.Last_Index loop
         if Messages.Rows.Element (I).Has_Target
           and then Messages.Rows.Element (I).Target_Buffer = Buffer_Token
         then
            Messages.Rows.Delete (I);
         else
            I := I + 1;
         end if;
      end loop;
      Assert_Messages_State_Consistent (Messages);
   end Reset_For_Buffer_Close;

   procedure Reset_For_Project_Close
     (Messages : in out Message_Feature_State)
   is
   begin
      Clear_Messages (Messages);
   end Reset_For_Project_Close;

   procedure Reset_For_Workspace_Close
     (Messages : in out Message_Feature_State)
   is
   begin
      Clear_Messages (Messages);
      Clear_Filter (Messages);
      Messages.Next_Id := 1;
   end Reset_For_Workspace_Close;

   function Validate_Row_Action
     (Messages                    : Message_Feature_State;
      Panel                       : Editor.Feature_Panel.Feature_Panel_State;
      Row                         : Natural;
      Expected_Projection_Generation : Natural := 0) return Boolean
   is
      Index : constant Natural := Map_Message_Row_To_Item
        (Messages, Panel, Row, Expected_Projection_Generation);
   begin
      return Index /= 0
        and then Editor.Feature_Panel.Row_Is_Selectable (Panel, Positive (Row));
   end Validate_Row_Action;

   function Message_Messages_Shown return String is
   begin
      return "Messages shown";
   end Message_Messages_Shown;

   function Message_Messages_Cleared return String is
   begin
      return "Messages cleared";
   end Message_Messages_Cleared;

   function Message_No_Messages return String is
   begin
      return "No messages";
   end Message_No_Messages;

   function Message_No_Selected_Message return String is
   begin
      return "No message selected";
   end Message_No_Selected_Message;

   function Message_No_Visible_Message return String is
   begin
      return "Messages: no visible message";
   end Message_No_Visible_Message;

   function Message_No_Target return String is
   begin
      return "Messages: no target";
   end Message_No_Target;

   function Message_Target_Unavailable return String is
   begin
      return "Messages: target unavailable";
   end Message_Target_Unavailable;

   function Message_Filter_Cleared return String is
   begin
      return "Messages: filter cleared";
   end Message_Filter_Cleared;

   function Message_All_Severities_Shown return String is
   begin
      return "Messages: all severities shown";
   end Message_All_Severities_Shown;

   function Message_Info_Hidden return String is
   begin
      return "Messages: info hidden";
   end Message_Info_Hidden;

   function Message_Info_Shown return String is
   begin
      return "Messages: info shown";
   end Message_Info_Shown;

   function Message_Warnings_Hidden return String is
   begin
      return "Messages: warnings hidden";
   end Message_Warnings_Hidden;

   function Message_Warnings_Shown return String is
   begin
      return "Messages: warnings shown";
   end Message_Warnings_Shown;

   function Message_Errors_Hidden return String is
   begin
      return "Messages: errors hidden";
   end Message_Errors_Hidden;

   function Message_Errors_Shown return String is
   begin
      return "Messages: errors shown";
   end Message_Errors_Shown;

   function Message_Message_Cleared return String is
   begin
      return "Messages: selected message cleared";
   end Message_Message_Cleared;

   function Message_Message_Copied return String is
   begin
      return "Messages: copied selected message";
   end Message_Message_Copied;

   function Reason_No_Message_Rows return String is
   begin
      return "No messages";
   end Reason_No_Message_Rows;

end Editor.Feature_Messages;
