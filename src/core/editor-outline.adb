with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Contextual_Help;

package body Editor.Outline is

   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Feature_Panel.Feature_Panel_Row_Kind;

   Max_Filter_History : constant Natural := 10;

   function To_Item
     (Kind        : Outline_Item_Kind;
      Label       : String;
      Detail      : String;
      Depth       : Natural;
      Target_Kind  : Outline_Target_Kind := No_Target;
      Buffer_Token : Natural := 0;
      Line         : Natural := 0;
      Column       : Natural := 0) return Outline_Item
   is
   begin
      return
        (Kind        => Kind,
         Label       => To_Unbounded_String (Label),
         Detail      => To_Unbounded_String (Detail),
         Depth       => Depth,
         Target_Kind  => Target_Kind,
         Buffer_Token => Buffer_Token,
         Line         => Line,
         Column       => Column);
   end To_Item;


   function Kind_Text (Kind : Outline_Item_Kind) return String is
   begin
      case Kind is
         when Outline_Header       => return "header";
         when Outline_Package      => return "package";
         when Outline_Package_Body => return "package body";
         when Outline_Type         => return "type";
         when Outline_Subprogram   => return "subprogram";
         when Outline_Procedure    => return "procedure";
         when Outline_Function     => return "function";
         when Outline_Task         => return "task";
         when Outline_Protected    => return "protected";
         when Outline_Field        => return "field";
         when Outline_Discriminant => return "discriminant";
         when Outline_Enum_Literal => return "enum literal";
         when Outline_Exception    => return "exception";
         when Outline_Object       => return "object";
         when Outline_Generic_Formal => return "generic formal";
         when Outline_Section      => return "section";
         when Outline_Unknown      => return "unknown";
      end case;
   end Kind_Text;

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

   procedure Bump_Rows_Generation (Outline : in out Outline_State) is
   begin
      Outline.Rows_Generation := Next_Generation (Outline.Rows_Generation);
      Outline.Projection_Generation := Next_Generation (Outline.Projection_Generation);
   end Bump_Rows_Generation;

   procedure Bump_Filter_Generation (Outline : in out Outline_State) is
   begin
      Outline.Filter_Generation := Next_Generation (Outline.Filter_Generation);
      Outline.Projection_Generation := Next_Generation (Outline.Projection_Generation);
   end Bump_Filter_Generation;

   procedure Invalidate_Extraction_Token (Outline : in out Outline_State) is
   begin
      Outline.Pending_Snapshot := (others => 0);
   end Invalidate_Extraction_Token;

   procedure Clear_Outline_Selection (Outline : in out Outline_State) is
   begin
      Outline.Selected := 0;
   end Clear_Outline_Selection;

   procedure Clear_Visible_Outline_Rows (Outline : in out Outline_State) is
   begin
      if not Outline.Items.Is_Empty then
         Outline.Items.Clear;
      end if;
      Bump_Rows_Generation (Outline);
   end Clear_Visible_Outline_Rows;

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


   procedure Set_Diagnostics
     (Outline      : in out Outline_State;
      Source_Class : Outline_Source_Class;
      Message      : String;
      Item_Count   : Natural)
   is
   begin
      Outline.Last_Extraction_Source := Source_Class;
      Outline.Last_Extraction_Message := To_Unbounded_String (Message);
      Outline.Last_Extraction_Count := Item_Count;
   end Set_Diagnostics;

   procedure Clear
     (Outline : in out Outline_State)
   is
   begin
      Clear_Visible_Outline_Rows (Outline);
      Clear_Outline_Selection (Outline);
      Outline.Filter_Input_Active := False;
      Clear_Filtered_Projection (Outline);
      Reset_Filter_History_Cursor (Outline);
      Clear_Current_Symbol (Outline);
      Outline.Source := No_Outline;
      Invalidate_Extraction_Token (Outline);
      Set_Diagnostics (Outline, No_Outline, "Outline cleared", 0);
      Assert_Outline_State_Consistent (Outline);
   end Clear;


   function Next_Request_Token
     (Outline : Outline_State) return Natural
   is
   begin
      return Outline.Next_Request;
   end Next_Request_Token;

   procedure Begin_Extraction
     (Outline  : in out Outline_State;
      Snapshot : Outline_Snapshot_Identity)
   is
      Stored : Outline_Snapshot_Identity := Snapshot;
   begin
      if Stored.Request_Token = 0 then
         Stored.Request_Token := Outline.Next_Request;
      end if;

      Outline.Pending_Snapshot := Stored;
      if Outline.Next_Request = Natural'Last then
         Outline.Next_Request := 1;
      else
         Outline.Next_Request := Outline.Next_Request + 1;
      end if;
   end Begin_Extraction;

   function Snapshot_Is_Current
     (Outline  : Outline_State;
      Snapshot : Outline_Snapshot_Identity) return Boolean
   is
   begin
      if Snapshot.Request_Token = 0 then
         return Outline.Pending_Snapshot.Request_Token = 0
           and then Outline.Source not in Unsupported_Content | Extraction_Failed;
      end if;

      return Snapshot = Outline.Pending_Snapshot;
   end Snapshot_Is_Current;

   procedure Mark_Stale_Result
     (Outline : in out Outline_State;
      Message : String := "Outline result discarded: stale buffer snapshot")
   is
   begin
      --  A stale extraction result is diagnostic information, not accepted
      --  outline content. If accepted rows are already visible, preserve their
      --  source classification and current-symbol state so rejected rows cannot
      --  disturb passive UI state or navigation metadata. When no accepted rows
      --  exist, retain the historical stale classification used by the Phase
      --  125 rejection tests.
      if Item_Count (Outline) = 0 then
         Clear_Current_Symbol (Outline);
         if Outline.Source not in Unsupported_Content | Extraction_Failed then
            Outline.Source := Stale_Extracted_Outline;
         end if;
      end if;

      Set_Diagnostics
        (Outline, Stale_Extracted_Outline, Message, Item_Count (Outline));
      pragma Assert
        (Invariant_Holds (Outline),
         "Outline invariant failed after Mark_Stale_Result: " &
           Debug_Summary (Outline));
   end Mark_Stale_Result;

   procedure Mark_Extraction_Failed
     (Outline : in out Outline_State;
      Message : String := "Outline extraction failed")
   is
   begin
      Clear_Visible_Outline_Rows (Outline);
      Clear_Outline_Selection (Outline);
      Outline.Filter_Input_Active := False;
      Clear_Filtered_Projection (Outline);
      Reset_Filter_History_Cursor (Outline);
      Clear_Current_Symbol (Outline);
      Outline.Source := Extraction_Failed;
      Invalidate_Extraction_Token (Outline);
      Set_Diagnostics (Outline, Extraction_Failed, Message, 0);
      pragma Assert
        (Invariant_Holds (Outline),
         "Outline invariant failed after Mark_Extraction_Failed: " &
           Debug_Summary (Outline));
   end Mark_Extraction_Failed;


   procedure Mark_No_Active_Buffer
     (Outline : in out Outline_State)
   is
   begin
      Clear_Visible_Outline_Rows (Outline);
      Clear_Outline_Selection (Outline);
      Outline.Filter_Input_Active := False;
      Clear_Filtered_Projection (Outline);
      Reset_Filter_History_Cursor (Outline);
      Clear_Current_Symbol (Outline);
      Outline.Source := No_Outline;
      Invalidate_Extraction_Token (Outline);
      Set_Diagnostics
        (Outline, No_Outline, Message_Outline_No_Active_Buffer, 0);
      pragma Assert
        (Invariant_Holds (Outline),
         "Outline invariant failed after Mark_No_Active_Buffer: " &
           Debug_Summary (Outline));
   end Mark_No_Active_Buffer;

   procedure Mark_Unsupported
     (Outline : in out Outline_State;
      Message : String := "Outline unavailable for this buffer")
   is
   begin
      Clear_Visible_Outline_Rows (Outline);
      Clear_Outline_Selection (Outline);
      Outline.Filter_Input_Active := False;
      Clear_Filtered_Projection (Outline);
      Reset_Filter_History_Cursor (Outline);
      Clear_Current_Symbol (Outline);
      Outline.Source := Unsupported_Content;
      Invalidate_Extraction_Token (Outline);
      Set_Diagnostics (Outline, Unsupported_Content, Message, 0);
      pragma Assert
        (Invariant_Holds (Outline),
         "Outline invariant failed after Mark_Unsupported: " &
           Debug_Summary (Outline));
   end Mark_Unsupported;

   procedure Reset_Outline_For_Buffer_Close
     (Outline      : in out Outline_State;
      Buffer_Token : Natural)
   is
      Owns_Visible_Rows : Boolean := False;
   begin
      if Buffer_Token = 0 then
         return;
      end if;

      Forget_Filter_For_Buffer (Outline, Buffer_Token);

      for I in 1 .. Item_Count (Outline) loop
         if Outline.Items (I - 1).Buffer_Token = Buffer_Token then
            Owns_Visible_Rows := True;
            exit;
         end if;
      end loop;

      if Outline.Pending_Snapshot.Active_Buffer_Token = Buffer_Token then
         Invalidate_Extraction_Token (Outline);
      end if;

      if Owns_Visible_Rows then
         Clear (Outline);
      else
         if Outline.Has_Current
           and then Outline.Current_Symbol <= Item_Count (Outline)
           and then Outline.Current_Symbol /= 0
           and then Outline.Items (Outline.Current_Symbol - 1).Buffer_Token = Buffer_Token
         then
            Clear_Current_Symbol (Outline);
         end if;

         if Outline.Selected <= Item_Count (Outline)
           and then Outline.Selected /= 0
           and then Outline.Items (Outline.Selected - 1).Buffer_Token = Buffer_Token
         then
            Clear_Outline_Selection (Outline);
         end if;
      end if;

      Assert_Outline_State_Consistent (Outline);
   end Reset_Outline_For_Buffer_Close;

   procedure Reset_Outline_For_Project_Close
     (Outline : in out Outline_State)
   is
   begin
      Clear (Outline);
      Clear_Filter_History (Outline);
      Clear_All_Remembered_Filters (Outline);
      Assert_Outline_State_Consistent (Outline);
   end Reset_Outline_For_Project_Close;

   procedure Reset_Outline_For_Workspace_Close
     (Outline : in out Outline_State)
   is
   begin
      Reset_Outline_For_Project_Close (Outline);
   end Reset_Outline_For_Workspace_Close;

   procedure Reset_Outline_For_Unsupported_Content
     (Outline : in out Outline_State)
   is
   begin
      Mark_Unsupported (Outline);
   end Reset_Outline_For_Unsupported_Content;

   procedure Reset_Outline_For_Extraction_Failure
     (Outline : in out Outline_State;
      Message : String)
   is
   begin
      Mark_Extraction_Failed (Outline, Message);
   end Reset_Outline_For_Extraction_Failure;

   procedure Reset_For_Project_Close
     (Outline : in out Outline_State)
   is
   begin
      Reset_Outline_For_Project_Close (Outline);
   end Reset_For_Project_Close;

   procedure Reset_For_Buffer_Change
     (Outline : in out Outline_State)
   is
   begin
      Reset_Filter_State_For_Lifecycle (Outline);
      Clear (Outline);
   end Reset_For_Buffer_Change;

   procedure Mark_For_Buffer_Change
     (Outline : in out Outline_State)
   is
   begin
      if Item_Count (Outline) = 0 then
         return;
      end if;

      Set_Diagnostics
        (Outline, Stale_Extracted_Outline,
         "Outline stale: active buffer changed", Item_Count (Outline));
      pragma Assert
        (Invariant_Holds (Outline),
         "Outline invariant failed after Mark_For_Buffer_Change: " &
           Debug_Summary (Outline));
   end Mark_For_Buffer_Change;

   function Is_Current_For_Buffer
     (Outline         : Outline_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural) return Boolean
   is
   begin
      return Buffer_Token /= 0
        and then Outline.Source = Extracted_Outline
        and then Outline.Last_Extraction_Source = Extracted_Outline
        and then Outline.Last_Applied_Snapshot.Active_Buffer_Token = Buffer_Token
        and then Outline.Last_Applied_Snapshot.Buffer_Revision = Buffer_Revision
        and then Outline_Buffer_Identity_Matches (Outline, Buffer_Token);
   end Is_Current_For_Buffer;

   function Is_Stale_For_Buffer
     (Outline         : Outline_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural) return Boolean
   is
   begin
      return Item_Count (Outline) /= 0
        and then Buffer_Token /= 0
        and then Outline.Last_Applied_Snapshot.Active_Buffer_Token = Buffer_Token
        and then (Outline.Last_Extraction_Source = Stale_Extracted_Outline
          or else Outline.Last_Applied_Snapshot.Buffer_Revision /= Buffer_Revision);
   end Is_Stale_For_Buffer;

   function Freshness_For_Active_Buffer
     (Outline         : Outline_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural) return Outline_Freshness
   is
   begin
      if Buffer_Token = 0 or else Item_Count (Outline) = 0 then
         return Outline_Unavailable;
      elsif Is_Current_For_Buffer (Outline, Buffer_Token, Buffer_Revision) then
         return Outline_Current;
      elsif Outline.Last_Applied_Snapshot.Active_Buffer_Token = Buffer_Token
        or else Outline_Buffer_Identity_Matches (Outline, Buffer_Token)
      then
         return Outline_Stale;
      else
         return Outline_Unavailable;
      end if;
   end Freshness_For_Active_Buffer;

   function Source_Buffer_Token
     (Outline : Outline_State) return Natural
   is
   begin
      return Outline.Last_Applied_Snapshot.Active_Buffer_Token;
   end Source_Buffer_Token;

   function Source_Buffer_Revision
     (Outline : Outline_State) return Natural
   is
   begin
      return Outline.Last_Applied_Snapshot.Buffer_Revision;
   end Source_Buffer_Revision;

   function Refresh
     (Outline : in out Outline_State;
      Source  : Outline_Refresh_Source) return Outline_Refresh_Result
   is
   begin
      case Source is
         when Outline_Source_Buffer_Extractor | Outline_Source_Project_Extractor =>
            return
              (Status       => Outline_Refresh_Unavailable,
               Failure_Kind => Extractor_Not_Available,
               Item_Count   => Item_Count (Outline),
               Source_Class => Source_Class (Outline));
      end case;
   end Refresh;


   procedure Replace_Items
     (Outline : in out Outline_State;
      Items   : Outline_Item_Array)
   is
   begin
      declare
         Previous_Selected : constant Natural := Selected_Index (Outline);
         Previous_Item     : Outline_Item;
         Had_Previous      : constant Boolean := Previous_Selected /= 0;
         Best_Index        : Natural := 0;
         Best_Score        : Natural := 0;
      begin
         if Had_Previous then
            Previous_Item := Outline.Items (Previous_Selected - 1);
         end if;

         Clear_Visible_Outline_Rows (Outline);
         Clear_Outline_Selection (Outline);
         Clear_Current_Symbol (Outline);
         for Item of Items loop
            Outline.Items.Append (Item);
         end loop;
         Bump_Rows_Generation (Outline);

         if Had_Previous then
            for I in 1 .. Natural (Outline.Items.Length) loop
               declare
                  Score : constant Natural :=
                    Selection_Preservation_Score
                      (Previous_Item, Outline.Items (I - 1));
               begin
                  if Score > Best_Score then
                     Best_Score := Score;
                     Best_Index := I;
                  end if;
               end;
            end loop;

            if Best_Index /= 0 then
               Outline.Selected := Best_Index;
            end if;
         end if;
      end;
      if Outline.Pending_Snapshot.Request_Token /= 0 then
         Outline.Last_Applied_Snapshot := Outline.Pending_Snapshot;
         Invalidate_Extraction_Token (Outline);
      end if;

      if Item_Count (Outline) = 0 then
         Outline.Source := No_Outline;
         Outline.Filter_Input_Active := False;
         Outline.Filter_Active := False;
         Outline.Filter_Text_Value := To_Unbounded_String ("");
         Outline.Filter_Caret_Position := 0;
         Outline.Filtered_Count := 0;
         Reconcile_Filtered_Selection (Outline);
         Set_Diagnostics (Outline, No_Outline, "Outline contains no symbols", 0);
      else
         Outline.Source := Extracted_Outline;
         Reconcile_Filtered_Selection (Outline);
         Set_Diagnostics
           (Outline, Extracted_Outline,
            "Outline extracted:" & Natural'Image (Item_Count (Outline)) &
              " symbols",
            Item_Count (Outline));
      end if;
      pragma Assert
        (Invariant_Holds (Outline),
         "Outline invariant failed after Replace_Items: " & Debug_Summary (Outline));
   end Replace_Items;

   function Invariant_Holds
     (Outline : Outline_State) return Boolean
   is
      Count : constant Natural := Natural (Outline.Items.Length);
      Expected_Filtered_Count : Natural := 0;
   begin
      if Count = 0 and then Outline.Source = Extracted_Outline then
         return False;
      end if;

      if Count /= 0
        and then Outline.Source in No_Outline | Unsupported_Content
          | Extraction_Failed
      then
         return False;
      end if;

      if Outline.Selected > Count then
         return False;
      end if;

      if Outline.Selected /= 0 then
         if not Is_Selectable_Target_Row (Outline, Positive (Outline.Selected)) then
            return False;
         end if;

         if Outline.Filter_Active
           and then not Row_Matches_Filter (Outline, Positive (Outline.Selected))
         then
            return False;
         end if;
      end if;

      if Outline.Has_Current then
         if Outline.Current_Symbol = 0 or else Outline.Current_Symbol > Count then
            return False;
         end if;

         if Outline.Source /= Extracted_Outline then
            return False;
         end if;

         if Outline.Current_Line = 0 then
            return False;
         end if;

         if not Is_Selectable_Target_Row (Outline, Positive (Outline.Current_Symbol)) then
            return False;
         end if;

         if Outline.Items (Outline.Current_Symbol - 1).Buffer_Token = 0 then
            return False;
         end if;
      elsif Outline.Current_Symbol /= 0 or else Outline.Current_Line /= 0
        or else To_String (Outline.Current_Label) /= ""
      then
         return False;
      end if;

      for I in 1 .. Count loop
         declare
            Item : constant Outline_Item := Outline.Items (I - 1);
         begin
            if Item.Line = 0 and then Item.Column /= 0 then
               return False;
            end if;

            if Item.Target_Kind /= Buffer_Position_Target
              and then Item.Buffer_Token /= 0
            then
               return False;
            end if;


            if Item.Target_Kind /= Buffer_Position_Target
              and then Item.Line /= 0
            then
               return False;
            end if;

            if Row_Matches_Filter (Outline, I) then
               Expected_Filtered_Count := Expected_Filtered_Count + 1;
            end if;
         end;
      end loop;

      if Outline.Filtered_Count /= Expected_Filtered_Count then
         return False;
      end if;

      if Outline.Filter_Caret_Position > Length (Outline.Filter_Text_Value) then
         return False;
      end if;

      if Outline.Source in No_Outline | Unsupported_Content | Extraction_Failed
        and then (Outline.Selected /= 0 or else Outline.Has_Current)
      then
         return False;
      end if;

      if Outline.Source in No_Outline | Unsupported_Content | Extraction_Failed
        and then (Outline.Filter_Input_Active
                  or else Outline.Filter_Active
                  or else Length (Outline.Filter_Text_Value) /= 0
                  or else Outline.Filtered_Count /= 0)
      then
         return False;
      end if;

      return True;
   end Invariant_Holds;

   function Debug_Summary
     (Outline : Outline_State) return String
   is
   begin
      return "items=" & Natural'Image (Item_Count (Outline))
        & ", source=" & Outline_Source_Class'Image (Outline.Source)
        & ", has_items=" & Boolean'Image (Has_Items (Outline))
        & ", current=" & Natural'Image (Current_Symbol_Index (Outline))
        & ", selected=" & Natural'Image (Selected_Index (Outline))
        & ", rows_generation=" & Natural'Image (Rows_Generation (Outline))
        & ", filter_generation=" & Natural'Image (Filter_Generation (Outline))
        & ", projection_generation=" & Natural'Image (Projection_Generation (Outline))
        & ", invariant=" & Boolean'Image (Invariant_Holds (Outline));
   end Debug_Summary;

   procedure Assert_Outline_State_Consistent
     (Outline : Outline_State)
   is
   begin
      pragma Assert
        (Invariant_Holds (Outline),
         "outline state inconsistent: " & Debug_Summary (Outline));
   end Assert_Outline_State_Consistent;

   function Projection_Invariant_Holds
     (Outline : Outline_State;
      Panel   : Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
      Visible : Natural := 0;
   begin
      if Filtered_Row_Count (Outline) = 0 then
         return Editor.Feature_Panel.Row_Count (Panel) = 1
           and then Editor.Feature_Panel.Row_Kind (Panel, 1) =
             Editor.Feature_Panel.Feature_Row_Empty_State
           and then Editor.Feature_Panel.Selected_Row (Panel) = 0;
      elsif Editor.Feature_Panel.Row_Count (Panel) /= Filtered_Row_Count (Outline) then
         return False;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Row_Matches_Filter (Outline, I) then
            Visible := Visible + 1;
            if not Feature_Row_Maps_To_Item (Outline, Panel, Positive (Visible)) then
               return False;
            end if;

            if Is_Current_Symbol_Row (Outline, I)
              and then not Editor.Feature_Panel.Row_Is_Current_Symbol
                (Panel, Positive (Visible))
            then
               return False;
            end if;

            if not Is_Current_Symbol_Row (Outline, I)
              and then Editor.Feature_Panel.Row_Is_Current_Symbol
                (Panel, Positive (Visible))
            then
               return False;
            end if;

            if Is_Selectable_Target_Row (Outline, I) /=
              Editor.Feature_Panel.Row_Is_Selectable (Panel, Positive (Visible))
            then
               return False;
            end if;
         end if;
      end loop;

      if Editor.Feature_Panel.Selected_Row (Panel) /=
        Visible_Row_For_Outline_Row (Outline, Selected_Index (Outline))
      then
         return False;
      end if;

      return Visible = Editor.Feature_Panel.Row_Count (Panel);
   end Projection_Invariant_Holds;

   procedure Assert_Outline_Projection_Consistent
     (Outline : Outline_State;
      Panel   : Editor.Feature_Panel.Feature_Panel_State)
   is
   begin
      pragma Assert
        (Projection_Invariant_Holds (Outline, Panel),
         "outline projection inconsistent: " & Debug_Summary (Outline));
   end Assert_Outline_Projection_Consistent;

   procedure Set_Rows_From_Outline
     (Outline : Outline_State;
      Panel   : in out Editor.Feature_Panel.Feature_Panel_State)
   is
      Kind : Editor.Feature_Panel.Feature_Panel_Row_Kind;
   begin
      if not Editor.Feature_Panel.Set_Active_Feature
        (Panel, Editor.Feature_Panel.Outline_Feature)
      then
         return;
      end if;
      Editor.Feature_Panel.Clear_Rows (Panel);
      Editor.Feature_Panel.Set_Header_Text (Panel, Outline_Header_Text (Outline));
      if Item_Count (Outline) = 0 then
         Editor.Feature_Panel.Append_Row
           (Panel,
            Kind        => Editor.Feature_Panel.Feature_Row_Empty_State,
            Label       => Outline_Empty_State_Label (Outline),
            Detail      => Editor.Contextual_Help.Empty_Outline_Detail (True),
            Selectable  => False,
            Activatable => False,
            Has_Target  => False,
            Can_Open    => False,
            Source_Index => 0);
      end if;
      for I in 1 .. Item_Count (Outline) loop
         if Row_Matches_Filter (Outline, I) then
            if Item_Kind (Outline, I) = Outline_Header
              or else Item_Kind (Outline, I) = Outline_Section
            then
               Kind := Editor.Feature_Panel.Feature_Row_Header;
            else
               Kind := Editor.Feature_Panel.Feature_Row_Item;
            end if;
            Editor.Feature_Panel.Append_Row
              (Panel  => Panel,
               Kind   => Kind,
               Label             => Item_Label (Outline, I),
               Detail            => Item_Detail (Outline, I),
               Is_Current_Symbol => Is_Current_Symbol_Row (Outline, I),
               Selectable        => Is_Selectable_Target_Row (Outline, I),
               Activatable       => Is_Selectable_Target_Row (Outline, I),
               Has_Target        => Is_Selectable_Target_Row (Outline, I),
               Is_Diagnostic     => not Is_Selectable_Target_Row (Outline, I),
               Source_Index      => I);
         end if;
      end loop;
      Editor.Feature_Panel.Select_Row
        (Panel, Visible_Row_For_Outline_Row (Outline, Selected_Index (Outline)));
      Assert_Outline_Projection_Consistent (Outline, Panel);
   end Set_Rows_From_Outline;



   procedure Select_Item
     (Outline : in out Outline_State;
      Index   : Natural)
   is
   begin
      if Index = 0 or else Index > Item_Count (Outline) then
         Outline.Selected := 0;
      else
         Outline.Selected := Index;
      end if;
      pragma Assert
        (Invariant_Holds (Outline),
         "Outline invariant failed after Select_Item: " &
           Debug_Summary (Outline));
   end Select_Item;

   function Selected_Index
     (Outline : Outline_State) return Natural
   is
   begin
      if Outline.Selected <= Item_Count (Outline) then
         return Outline.Selected;
      end if;
      return 0;
   end Selected_Index;

   function Has_Selected_Item
     (Outline : Outline_State) return Boolean
   is
   begin
      return Selected_Index (Outline) /= 0;
   end Has_Selected_Item;


   procedure Set_Filter_Text_Normalized
     (Outline : in out Outline_State;
      Text    : String)
   is
      Normalized : constant String := Normalize_Filter_Text (Text);
   begin
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

   procedure Clear_Current_Symbol
     (Outline : in out Outline_State)
   is
   begin
      Outline.Current_Symbol := 0;
      Outline.Has_Current := False;
      Outline.Current_Label := To_Unbounded_String ("");
      Outline.Current_Line := 0;
   end Clear_Current_Symbol;

   procedure Set_Current_Symbol_Index
     (Outline : in out Outline_State;
      Index   : Natural)
   is
   begin
      if Index = 0
        or else Index > Item_Count (Outline)
        or else not Is_Selectable_Target_Row (Outline, Positive (Index))
      then
         Clear_Current_Symbol (Outline);
      else
         Outline.Current_Symbol := Index;
         Outline.Has_Current := True;
         Outline.Current_Label := Outline.Items (Index - 1).Label;
         Outline.Current_Line := Outline.Items (Index - 1).Line;
      end if;
      pragma Assert
        (Invariant_Holds (Outline),
         "Outline invariant failed after Set_Current_Symbol_Index: " &
           Debug_Summary (Outline));
   end Set_Current_Symbol_Index;

   function Current_Symbol_Index
     (Outline : Outline_State) return Natural
   is
   begin
      if Outline.Has_Current
        and then Outline.Current_Symbol /= 0
        and then Outline.Current_Symbol <= Item_Count (Outline)
      then
         return Outline.Current_Symbol;
      end if;
      return 0;
   end Current_Symbol_Index;

   function Has_Current_Symbol
     (Outline : Outline_State) return Boolean
   is
   begin
      return Current_Symbol_Index (Outline) /= 0;
   end Has_Current_Symbol;

   function Current_Symbol_Label
     (Outline : Outline_State) return String
   is
   begin
      if Has_Current_Symbol (Outline) then
         return To_String (Outline.Current_Label);
      end if;
      return "";
   end Current_Symbol_Label;

   function Current_Symbol_Line
     (Outline : Outline_State) return Natural
   is
   begin
      if Has_Current_Symbol (Outline) then
         return Outline.Current_Line;
      end if;
      return 0;
   end Current_Symbol_Line;


   function Detail_Range_End_Line (Detail : String) return Natural
   is
      Dash  : Natural := 0;
      Value : Natural := 0;
      I     : Natural;
   begin
      if Ada.Strings.Fixed.Index (Detail, "lines ") /= Detail'First then
         return 0;
      end if;

      for J in Detail'Range loop
         if Detail (J) = '-' then
            Dash := J;
            exit;
         end if;
      end loop;

      if Dash = 0 or else Dash = Detail'Last then
         return 0;
      end if;

      I := Dash + 1;
      while I <= Detail'Last
        and then Detail (I) >= '0'
        and then Detail (I) <= '9'
      loop
         Value := Value * 10 + Character'Pos (Detail (I)) - Character'Pos ('0');
         I := I + 1;
      end loop;

      return Value;
   end Detail_Range_End_Line;

   function Find_Enclosing_Ranged_Item_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1) return Natural
   is
      pragma Unreferenced (Column);
      Best       : Natural := 0;
      Best_Span  : Natural := Natural'Last;
      Best_Depth : Natural := 0;
   begin
      if not Outline_Buffer_Identity_Matches (Outline, Buffer_Token) then
         return 0;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I)
           and then Item_Buffer_Token (Outline, I) = Buffer_Token
         then
            declare
               Start_Line : constant Natural := Item_Line (Outline, I);
               End_Line   : constant Natural :=
                 Detail_Range_End_Line (To_String (Outline.Items (I - 1).Detail));
            begin
               if End_Line > Start_Line
                 and then Start_Line <= Line
                 and then Line <= End_Line
               then
                  declare
                     Span  : constant Natural := End_Line - Start_Line;
                     Depth : constant Natural := Item_Depth (Outline, I);
                  begin
                     if Best = 0
                       or else Span < Best_Span
                       or else (Span = Best_Span and then Depth > Best_Depth)
                     then
                        Best := I;
                        Best_Span := Span;
                        Best_Depth := Depth;
                     end if;
                  end;
               end if;
            end;
         end if;
      end loop;

      return Best;
   end Find_Enclosing_Ranged_Item_For_Position;

   function Find_Current_Symbol_For_Cursor
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1) return Natural
   is
      Ranged : constant Natural :=
        Find_Enclosing_Ranged_Item_For_Position
          (Outline, Buffer_Token, Line, Column);
   begin
      if Ranged /= 0 then
         return Ranged;
      end if;

      return Find_Nearest_Item_For_Position (Outline, Buffer_Token, Line, Column);
   end Find_Current_Symbol_For_Cursor;

   procedure Update_Current_Symbol_For_Cursor
     (Outline      : in out Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1)
   is
   begin
      Set_Current_Symbol_Index
        (Outline, Find_Current_Symbol_For_Cursor (Outline, Buffer_Token, Line, Column));
   end Update_Current_Symbol_For_Cursor;

   function Outline_Header_Text
     (Outline : Outline_State) return String
   is
      Count          : constant Natural := Navigable_Symbol_Count (Outline);
      Filtered_Count : constant Natural := Filtered_Navigable_Symbol_Count (Outline);
   begin
      case Outline.Source is
         when Extracted_Outline =>
            if Outline.Last_Extraction_Source = Stale_Extracted_Outline then
               return "Outline: stale";
            elsif Outline.Filter_Active or else Outline.Filter_Input_Active then
               if Filtered_Count = 0 and then Outline.Filter_Active then
                  return "Outline: filter """ & Filter_Text (Outline) & """ -- no matches";
               elsif Outline.Filter_Active then
                  return "Outline: filter """ & Filter_Text (Outline) & """ --" &
                    Natural'Image (Filtered_Count) &
                    " of" & Natural'Image (Count) & " symbols";
               else
                  return "Outline: filter --" & Natural'Image (Count) & " symbols";
               end if;
            elsif Has_Current_Symbol (Outline) then
               return "Outline: " & Current_Symbol_Label (Outline);
            elsif Count = 0 then
               return "Outline: no items";
            elsif Count = 1 then
               return "Outline: 1 symbol";
            else
               return "Outline:" & Natural'Image (Count) & " symbols";
            end if;
         when Unsupported_Content =>
            if To_String (Outline.Last_Extraction_Message) = Message_Outline_No_Symbols then
               return "Outline: no items";
            else
               return "Outline: unavailable";
            end if;
         when Extraction_Failed =>
            return "Outline: refresh failed";
         when Stale_Extracted_Outline =>
            return "Outline: may be stale";
         when No_Outline =>
            return "Outline: not refreshed";
      end case;
   end Outline_Header_Text;


   function Outline_Empty_State_Label
     (Outline : Outline_State) return String
   is
   begin
      case Outline.Source is
         when No_Outline =>
            if To_String (Outline.Last_Extraction_Message) = Message_Outline_No_Active_Buffer then
               return "Outline unavailable: no active buffer.";
            else
               return "Outline not refreshed.";
            end if;
         when Unsupported_Content =>
            if To_String (Outline.Last_Extraction_Message) = Message_Outline_No_Symbols then
               return "No outline items found.";
            else
               return "Outline unavailable: active buffer is not supported.";
            end if;
         when Extraction_Failed =>
            return "Outline refresh failed.";
         when Stale_Extracted_Outline =>
            return "Outline may be stale.";
         when Extracted_Outline =>
            return "No outline items found.";
      end case;
   end Outline_Empty_State_Label;

   function Is_Current_Symbol_Row
     (Outline : Outline_State;
      Index   : Positive) return Boolean
   is
   begin
      return Has_Current_Symbol (Outline)
        and then Current_Symbol_Index (Outline) = Index
        and then Is_Selectable_Target_Row (Outline, Index);
   end Is_Current_Symbol_Row;

   function Is_Selectable_Target_Row
     (Outline : Outline_State;
      Index   : Positive) return Boolean
   is
      Item : constant Outline_Item := Outline.Items (Index - 1);
   begin
      return Outline.Source = Extracted_Outline
        and then Item.Target_Kind = Buffer_Position_Target
        and then Item.Buffer_Token /= 0
        and then Item.Line /= 0
        and then Item.Kind not in Outline_Header | Outline_Section;
   end Is_Selectable_Target_Row;

   function Has_Selectable_Filter_Match
     (Outline : Outline_State) return Boolean
   is
   begin
      if Outline.Source /= Extracted_Outline
        or else Outline.Last_Extraction_Source = Stale_Extracted_Outline
      then
         return False;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Row_Matches_Filter (Outline, I)
           and then Is_Selectable_Target_Row (Outline, I)
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Selectable_Filter_Match;

   function Navigable_Symbol_Count
     (Outline : Outline_State) return Natural
   is
      Count : Natural := 0;
   begin
      if Outline.Source /= Extracted_Outline
        or else Outline.Last_Extraction_Source = Stale_Extracted_Outline
      then
         return 0;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Navigable_Symbol_Count;

   function Filtered_Navigable_Symbol_Count
     (Outline : Outline_State) return Natural
   is
      Count : Natural := 0;
   begin
      if Outline.Source /= Extracted_Outline
        or else Outline.Last_Extraction_Source = Stale_Extracted_Outline
      then
         return 0;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Row_Matches_Filter (Outline, I)
           and then Is_Selectable_Target_Row (Outline, I)
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Filtered_Navigable_Symbol_Count;


   function Can_Reveal_Current_Symbol
     (Outline             : Outline_State;
      Panel               : Editor.Feature_Panel.Feature_Panel_State;
      Active_Buffer_Token : Natural) return Boolean
   is
      Index : constant Natural := Current_Symbol_Index (Outline);
   begin
      if Index = 0
        or else Active_Buffer_Token = 0
        or else Outline.Source /= Extracted_Outline
        or else Outline.Last_Extraction_Source = Stale_Extracted_Outline
        or else Index > Item_Count (Outline)
      then
         return False;
      end if;

      declare
         Visible : constant Natural := Visible_Row_For_Outline_Row (Outline, Index);
      begin
         if Visible = 0 or else Visible > Editor.Feature_Panel.Row_Count (Panel) then
            return False;
         end if;
         return Is_Selectable_Target_Row (Outline, Positive (Index))
           and then Item_Buffer_Token (Outline, Positive (Index)) = Active_Buffer_Token
           and then Feature_Row_Maps_To_Item (Outline, Panel, Positive (Visible))
           and then Editor.Feature_Panel.Row_Is_Current_Symbol (Panel, Positive (Visible));
      end;
   end Can_Reveal_Current_Symbol;

   function Same_Outline_Target
     (Left, Right : Outline_Item) return Boolean
   is
   begin
      return Left.Target_Kind = Buffer_Position_Target
        and then Right.Target_Kind = Buffer_Position_Target
        and then Left.Buffer_Token /= 0
        and then Left.Buffer_Token = Right.Buffer_Token
        and then Left.Line = Right.Line
        and then Left.Column = Right.Column;
   end Same_Outline_Target;

   function Same_Outline_Symbol
     (Left, Right : Outline_Item) return Boolean
   is
   begin
      return Same_Outline_Target (Left, Right)
        and then Left.Kind = Right.Kind
        and then To_String (Left.Label) = To_String (Right.Label)
        and then Left.Depth = Right.Depth;
   end Same_Outline_Symbol;

   function Outline_Buffer_Identity_Matches
     (Outline      : Outline_State;
      Buffer_Token : Natural) return Boolean
   is
      Saw_Navigable : Boolean := False;
   begin
      if Buffer_Token = 0
        or else Outline.Source /= Extracted_Outline
        or else Outline.Last_Extraction_Source = Stale_Extracted_Outline
      then
         return False;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I) then
            Saw_Navigable := True;
            if Item_Buffer_Token (Outline, I) /= Buffer_Token then
               return False;
            end if;
         end if;
      end loop;

      return Saw_Navigable;
   end Outline_Buffer_Identity_Matches;

   function Has_Navigable_Symbol_For_Buffer
     (Outline      : Outline_State;
      Buffer_Token : Natural) return Boolean
   is
   begin
      if not Outline_Buffer_Identity_Matches (Outline, Buffer_Token) then
         return False;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I)
           and then Item_Buffer_Token (Outline, I) = Buffer_Token
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Navigable_Symbol_For_Buffer;

   function Selection_Preservation_Score
     (Previous, Candidate : Outline_Item) return Natural
   is
      Score : Natural := 0;
      Prev_Label : constant String := To_String (Previous.Label);
      Cand_Label : constant String := To_String (Candidate.Label);
   begin
      if Previous.Target_Kind /= Buffer_Position_Target
        or else Candidate.Target_Kind /= Buffer_Position_Target
        or else Previous.Buffer_Token = 0
        or else Previous.Buffer_Token /= Candidate.Buffer_Token
        or else Candidate.Line = 0
      then
         return 0;
      end if;

      if Same_Outline_Symbol (Previous, Candidate) then
         return 1_000;
      end if;

      if Same_Outline_Target (Previous, Candidate) then
         Score := 800;
      end if;

      if Previous.Kind = Candidate.Kind and then Prev_Label = Cand_Label then
         if Previous.Line = Candidate.Line then
            Score := Natural'Max (Score, 700);
         elsif (if Previous.Line > Candidate.Line
                then Previous.Line - Candidate.Line
                else Candidate.Line - Previous.Line) <= 3
         then
            Score := Natural'Max (Score, 600);
         else
            Score := Natural'Max (Score, 500);
         end if;
      end if;

      if Candidate.Line <= Previous.Line then
         declare
            Distance : constant Natural := Previous.Line - Candidate.Line;
         begin
            if Distance < 100 then
               Score := Natural'Max (Score, 300 - Distance);
            end if;
         end;
      end if;

      return Score;
   end Selection_Preservation_Score;

   function Find_Nearest_Item_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1) return Natural
   is
      Best       : Natural := 0;
      Best_Line  : Natural := 0;
      Best_Col   : Natural := 0;
      Best_Depth : Natural := Natural'Last;
   begin
      if not Outline_Buffer_Identity_Matches (Outline, Buffer_Token) then
         return 0;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I)
           and then Item_Buffer_Token (Outline, I) = Buffer_Token
           and then Item_Line (Outline, I) <= Line
           and then (Item_Line (Outline, I) < Line
                     or else Item_Column (Outline, I) <= Column)
         then
            declare
               Candidate_Line  : constant Natural := Item_Line (Outline, I);
               Candidate_Col   : constant Natural := Item_Column (Outline, I);
               Candidate_Depth : constant Natural := Item_Depth (Outline, I);
            begin
               if Best = 0
                 or else Candidate_Line > Best_Line
                 or else (Candidate_Line = Best_Line
                          and then Candidate_Col > Best_Col)
                 or else (Candidate_Line = Best_Line
                          and then Candidate_Col = Best_Col
                          and then Candidate_Depth < Best_Depth)
               then
                  Best := I;
                  Best_Line := Candidate_Line;
                  Best_Col := Candidate_Col;
                  Best_Depth := Candidate_Depth;
               end if;
            end;
         end if;
      end loop;

      return Best;
   end Find_Nearest_Item_For_Position;

   function Position_Is_After
     (Candidate_Line   : Natural;
      Candidate_Column : Natural;
      Line             : Positive;
      Column           : Natural) return Boolean
   is
   begin
      return Candidate_Line > Line
        or else (Candidate_Line = Line and then Candidate_Column > Column);
   end Position_Is_After;

   function Position_Is_Before
     (Candidate_Line   : Natural;
      Candidate_Column : Natural;
      Line             : Positive;
      Column           : Natural) return Boolean
   is
   begin
      return Candidate_Line < Line
        or else (Candidate_Line = Line and then Candidate_Column < Column);
   end Position_Is_Before;

   function Candidate_Is_Before_Best
     (Outline   : Outline_State;
      Candidate : Positive;
      Best      : Natural) return Boolean
   is
   begin
      if Best = 0 then
         return True;
      end if;

      return Item_Line (Outline, Candidate) < Item_Line (Outline, Positive (Best))
        or else
          (Item_Line (Outline, Candidate) = Item_Line (Outline, Positive (Best))
           and then Item_Column (Outline, Candidate) <
             Item_Column (Outline, Positive (Best)))
        or else
          (Item_Line (Outline, Candidate) = Item_Line (Outline, Positive (Best))
           and then Item_Column (Outline, Candidate) =
             Item_Column (Outline, Positive (Best))
           and then Candidate < Best);
   end Candidate_Is_Before_Best;

   function Candidate_Is_After_Best
     (Outline   : Outline_State;
      Candidate : Positive;
      Best      : Natural) return Boolean
   is
   begin
      if Best = 0 then
         return True;
      end if;

      return Item_Line (Outline, Candidate) > Item_Line (Outline, Positive (Best))
        or else
          (Item_Line (Outline, Candidate) = Item_Line (Outline, Positive (Best))
           and then Item_Column (Outline, Candidate) >
             Item_Column (Outline, Positive (Best)))
        or else
          (Item_Line (Outline, Candidate) = Item_Line (Outline, Positive (Best))
           and then Item_Column (Outline, Candidate) =
             Item_Column (Outline, Positive (Best))
           and then Candidate > Best);
   end Candidate_Is_After_Best;

   function Find_Next_Symbol_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1;
      Wrap         : Boolean := True) return Natural
   is
      Best       : Natural := 0;
      Wrap_Best  : Natural := 0;
   begin
      if not Outline_Buffer_Identity_Matches (Outline, Buffer_Token) then
         return 0;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I)
           and then Item_Buffer_Token (Outline, I) = Buffer_Token
         then
            if Position_Is_After (Item_Line (Outline, I), Item_Column (Outline, I), Line, Column)
              and then Candidate_Is_Before_Best (Outline, I, Best)
            then
               Best := I;
            elsif Wrap and then Candidate_Is_Before_Best (Outline, I, Wrap_Best) then
               Wrap_Best := I;
            end if;
         end if;
      end loop;

      if Best /= 0 then
         return Best;
      end if;
      return Wrap_Best;
   end Find_Next_Symbol_For_Position;

   function Find_Previous_Symbol_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1;
      Wrap         : Boolean := True) return Natural
   is
      Best       : Natural := 0;
      Wrap_Best  : Natural := 0;
   begin
      if not Outline_Buffer_Identity_Matches (Outline, Buffer_Token) then
         return 0;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I)
           and then Item_Buffer_Token (Outline, I) = Buffer_Token
         then
            if Position_Is_Before (Item_Line (Outline, I), Item_Column (Outline, I), Line, Column)
              and then Candidate_Is_After_Best (Outline, I, Best)
            then
               Best := I;
            elsif Wrap and then Candidate_Is_After_Best (Outline, I, Wrap_Best) then
               Wrap_Best := I;
            end if;
         end if;
      end loop;

      if Best /= 0 then
         return Best;
      end if;
      return Wrap_Best;
   end Find_Previous_Symbol_For_Position;

   function Select_Next_Selectable
     (Outline : in out Outline_State) return Boolean
   is
      Start : constant Natural := Selected_Index (Outline);
   begin
      for I in Start + 1 .. Item_Count (Outline) loop
         if Row_Matches_Filter (Outline, I)
           and then Is_Selectable_Target_Row (Outline, I) then
            Select_Item (Outline, I);
            return True;
         end if;
      end loop;

      if Start = 0 then
         for I in 1 .. Item_Count (Outline) loop
            if Row_Matches_Filter (Outline, I)
              and then Is_Selectable_Target_Row (Outline, I) then
               Select_Item (Outline, I);
               return True;
            end if;
         end loop;
      end if;

      return False;
   end Select_Next_Selectable;

   function Select_Previous_Selectable
     (Outline : in out Outline_State) return Boolean
   is
      Start : constant Natural :=
        (if Selected_Index (Outline) = 0
         then Item_Count (Outline) + 1
         else Selected_Index (Outline));
   begin
      if Start > 1 then
         for I in reverse 1 .. Start - 1 loop
            if Row_Matches_Filter (Outline, I)
              and then Is_Selectable_Target_Row (Outline, I) then
               Select_Item (Outline, I);
               return True;
            end if;
         end loop;
      end if;

      return False;
   end Select_Previous_Selectable;

   function Valid_Index
     (Outline : Outline_State;
      Index   : Positive) return Boolean
   is
   begin
      return Index <= Natural (Outline.Items.Length);
   end Valid_Index;

   function Item_Count
     (Outline : Outline_State) return Natural
   is
   begin
      return Natural (Outline.Items.Length);
   end Item_Count;

   function Has_Items
     (Outline : Outline_State) return Boolean
   is
   begin
      return Item_Count (Outline) /= 0;
   end Has_Items;


   function Source_Class
     (Outline : Outline_State) return Outline_Source_Class
   is
   begin
      return Outline.Source;
   end Source_Class;

   function Last_Extraction_Source_Class
     (Outline : Outline_State) return Outline_Source_Class
   is
   begin
      return Outline.Last_Extraction_Source;
   end Last_Extraction_Source_Class;

   function Last_Extraction_Message
     (Outline : Outline_State) return String
   is
   begin
      return To_String (Outline.Last_Extraction_Message);
   end Last_Extraction_Message;

   function Last_Extraction_Buffer_Label
     (Outline : Outline_State) return String
   is
   begin
      return To_String (Outline.Last_Extraction_Buffer);
   end Last_Extraction_Buffer_Label;

   function Last_Extraction_Item_Count
     (Outline : Outline_State) return Natural
   is
   begin
      return Outline.Last_Extraction_Count;
   end Last_Extraction_Item_Count;

   function Item_Label
     (Outline : Outline_State;
      Index   : Positive) return String
   is
   begin
      pragma Assert (Valid_Index (Outline, Index), "invalid outline label index");
      return To_String (Outline.Items (Index - 1).Label);
   end Item_Label;

   function Item_Detail
     (Outline : Outline_State;
      Index   : Positive) return String
   is
   begin
      pragma Assert (Valid_Index (Outline, Index), "invalid outline detail index");
      return To_String (Outline.Items (Index - 1).Detail);
   end Item_Detail;

   function Item_Depth
     (Outline : Outline_State;
      Index   : Positive) return Natural
   is
   begin
      pragma Assert (Valid_Index (Outline, Index), "invalid outline depth index");
      return Outline.Items (Index - 1).Depth;
   end Item_Depth;

   function Item_Kind
     (Outline : Outline_State;
      Index   : Positive) return Outline_Item_Kind
   is
   begin
      pragma Assert (Valid_Index (Outline, Index), "invalid outline kind index");
      return Outline.Items (Index - 1).Kind;
   end Item_Kind;

   function Item_Target_Kind
     (Outline : Outline_State;
      Index   : Positive) return Outline_Target_Kind
   is
   begin
      pragma Assert (Valid_Index (Outline, Index), "invalid outline target index");
      return Outline.Items (Index - 1).Target_Kind;
   end Item_Target_Kind;

   function Item_Buffer_Token
     (Outline : Outline_State;
      Index   : Positive) return Natural
   is
   begin
      pragma Assert (Valid_Index (Outline, Index), "invalid outline buffer index");
      return Outline.Items (Index - 1).Buffer_Token;
   end Item_Buffer_Token;

   function Item_Line
     (Outline : Outline_State;
      Index   : Positive) return Natural
   is
   begin
      pragma Assert (Valid_Index (Outline, Index), "invalid outline line index");
      return Outline.Items (Index - 1).Line;
   end Item_Line;

   function Item_Column
     (Outline : Outline_State;
      Index   : Positive) return Natural
   is
   begin
      pragma Assert (Valid_Index (Outline, Index), "invalid outline column index");
      return Outline.Items (Index - 1).Column;
   end Item_Column;

   function Feature_Row_Maps_To_Item
     (Outline : Outline_State;
      Panel   : Editor.Feature_Panel.Feature_Panel_State;
      Row     : Positive) return Boolean
   is
      Outline_Row : constant Natural := Outline_Row_For_Visible_Row (Outline, Row);
   begin
      if Outline_Row = 0
        or else Row > Editor.Feature_Panel.Row_Count (Panel)
      then
         return False;
      end if;

      if Item_Kind (Outline, Positive (Outline_Row)) = Outline_Header
        or else Item_Kind (Outline, Positive (Outline_Row)) = Outline_Section
      then
         if Editor.Feature_Panel.Row_Kind (Panel, Row) /=
           Editor.Feature_Panel.Feature_Row_Header
         then
            return False;
         end if;
      elsif Editor.Feature_Panel.Row_Kind (Panel, Row) /=
        Editor.Feature_Panel.Feature_Row_Item
      then
         return False;
      end if;

      if Editor.Feature_Panel.Row_Source_Index (Panel, Row) /= 0
        and then Editor.Feature_Panel.Row_Source_Index (Panel, Row) /= Outline_Row
      then
         return False;
      end if;

      return Editor.Feature_Panel.Row_Label (Panel, Row) =
          Item_Label (Outline, Positive (Outline_Row))
        and then Editor.Feature_Panel.Row_Detail (Panel, Row) =
          Item_Detail (Outline, Positive (Outline_Row));
   end Feature_Row_Maps_To_Item;


   function Map_Panel_Row_To_Outline_Row
     (Outline                   : Outline_State;
      Panel                     : Editor.Feature_Panel.Feature_Panel_State;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Natural
   is
   begin
      if Editor.Feature_Panel.Active_Feature (Panel) /=
           Editor.Feature_Panel.Outline_Feature
        or else not Editor.Feature_Panel.Projection_Generation_Matches
          (Panel, Expected_Panel_Generation)
      then
         return 0;
      end if;

      if not Editor.Feature_Panel.Projection_Row_Index_Is_Valid (Panel, Row) then
         return 0;
      end if;

      if not Feature_Row_Maps_To_Item (Outline, Panel, Positive (Row)) then
         return 0;
      end if;

      return Outline_Row_For_Visible_Row (Outline, Row);
   end Map_Panel_Row_To_Outline_Row;

   function Validate_Outline_Row_For_Selection
     (Outline                   : Outline_State;
      Panel                     : Editor.Feature_Panel.Feature_Panel_State;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Boolean
   is
      Mapped : constant Natural :=
        Map_Panel_Row_To_Outline_Row
          (Outline, Panel, Row, Expected_Panel_Generation);
   begin
      if Mapped = 0 then
         return False;
      end if;

      return Editor.Feature_Panel.Row_Is_Selectable (Panel, Positive (Row))
        and then Is_Selectable_Target_Row (Outline, Positive (Mapped));
   end Validate_Outline_Row_For_Selection;

   function Validate_Outline_Row_For_Activation
     (Outline                   : Outline_State;
      Panel                     : Editor.Feature_Panel.Feature_Panel_State;
      Row                       : Natural;
      Active_Buffer_Token       : Natural;
      Expected_Panel_Generation : Natural := 0) return Boolean
   is
      Mapped : constant Natural :=
        Map_Panel_Row_To_Outline_Row
          (Outline, Panel, Row, Expected_Panel_Generation);
   begin
      if Mapped = 0 or else Active_Buffer_Token = 0 then
         return False;
      end if;

      return Editor.Feature_Panel.Row_Is_Selectable (Panel, Positive (Row))
        and then Editor.Feature_Panel.Row_Is_Activatable (Panel, Positive (Row))
        and then Editor.Feature_Panel.Row_Has_Target (Panel, Positive (Row))
        and then Is_Selectable_Target_Row (Outline, Positive (Mapped))
        and then Item_Buffer_Token (Outline, Positive (Mapped)) = Active_Buffer_Token
        and then Item_Target_Kind (Outline, Positive (Mapped)) = Buffer_Position_Target
        and then Item_Line (Outline, Positive (Mapped)) /= 0;
   end Validate_Outline_Row_For_Activation;

   function Summary
     (Outline : Outline_State) return Outline_Summary
   is
   begin
      return
        (Item_Count   => Item_Count (Outline),
         Has_Items    => Has_Items (Outline),
         Fingerprint  => Fingerprint (Outline),
         Source_Class => Outline.Source);
   end Summary;

   function Hash_String
     (Seed : Natural;
      Text : String) return Natural
   is
      H : Natural := Seed;
   begin
      for C of Text loop
         H := (H * 131 + Character'Pos (C) + 1) mod 2_147_483_647;
      end loop;
      return H;
   end Hash_String;

   function Fingerprint
     (Outline : Outline_State) return Natural
   is
      H : Natural :=
        (97 * 31 + Item_Count (Outline) + 1
         + Natural (Outline_Source_Class'Pos (Outline.Source)))
        mod 2_147_483_647;
   begin
      for I in 1 .. Item_Count (Outline) loop
         H :=
           (H * 31 + Outline_Item_Kind'Pos (Item_Kind (Outline, I)))
           mod 2_147_483_647;
         H :=
           (H * 31 + Outline_Target_Kind'Pos
              (Item_Target_Kind (Outline, I)))
           mod 2_147_483_647;
         H :=
           (H * 31 + Item_Buffer_Token (Outline, I) + 1) mod 2_147_483_647;
         H :=
           (H * 31 + Item_Depth (Outline, I) + 1) mod 2_147_483_647;
         H :=
           (H * 31 + Item_Line (Outline, I) + 1) mod 2_147_483_647;
         H :=
           (H * 31 + Item_Column (Outline, I) + 1) mod 2_147_483_647;
         H := Hash_String (H, Item_Label (Outline, I));
         H := Hash_String (H, Item_Detail (Outline, I));
      end loop;
      return H;
   end Fingerprint;

   function Message_Outline_Refreshed return String is
   begin
      return "Outline refreshed";
   end Message_Outline_Refreshed;

   function Message_Outline_Cleared return String is
   begin
      return "Outline cleared";
   end Message_Outline_Cleared;

   function Message_Outline_Shown return String is
   begin
      return "Outline shown.";
   end Message_Outline_Shown;

   function Message_Outline_Focused return String is
   begin
      return "Outline focused.";
   end Message_Outline_Focused;

   function Message_Outline_Item_Has_No_Target return String is
   begin
      return Message_Outline_No_Selected_Symbol;
   end Message_Outline_Item_Has_No_Target;

   function Message_Outline_Refresh_Failed return String is
   begin
      return "Outline refresh failed.";
   end Message_Outline_Refresh_Failed;

   function Message_Outline_No_Current_Symbol return String is
   begin
      return "Outline: no current symbol";
   end Message_Outline_No_Current_Symbol;

   function Message_Outline_Current_Symbol_Revealed return String is
   begin
      return "Outline current symbol revealed";
   end Message_Outline_Current_Symbol_Revealed;

   function Message_Outline_No_Active_Buffer return String is
   begin
      return "Outline unavailable: no active buffer.";
   end Message_Outline_No_Active_Buffer;

   function Message_Outline_Unsupported_Buffer return String is
   begin
      return "Outline unavailable: active buffer is not supported.";
   end Message_Outline_Unsupported_Buffer;

   function Message_Outline_No_Symbols return String is
   begin
      return "No outline items found.";
   end Message_Outline_No_Symbols;

   function Message_Outline_No_Matching_Symbols return String is
   begin
      return "No outline items match the current filter.";
   end Message_Outline_No_Matching_Symbols;

   function Message_Outline_No_Selected_Symbol return String is
   begin
      return "No outline item selected.";
   end Message_Outline_No_Selected_Symbol;

   function Message_Outline_Stale_Result_Discarded return String is
   begin
      return "Outline may be stale; refresh Outline before navigating.";
   end Message_Outline_Stale_Result_Discarded;

   function Reason_No_Active_Buffer return String is
   begin
      return "Outline unavailable: no active buffer";
   end Reason_No_Active_Buffer;

   function Reason_No_Outline_Items return String is
   begin
      return "No outline items";
   end Reason_No_Outline_Items;

   function Reason_No_Outline_Item_Selected return String is
   begin
      return "No outline item selected";
   end Reason_No_Outline_Item_Selected;

   function Reason_Outline_Belongs_To_Another_Buffer return String is
   begin
      return "Outline belongs to another buffer";
   end Reason_Outline_Belongs_To_Another_Buffer;

   function Reason_Feature_Panel_Hidden return String is
   begin
      return "Feature panel hidden; show the panel before activating Outline rows";
   end Reason_Feature_Panel_Hidden;

   function Reason_Feature_Panel_Already_Shown return String is
   begin
      return "Feature panel already shown";
   end Reason_Feature_Panel_Already_Shown;

   function Reason_Feature_Panel_Already_Focused return String is
   begin
      return "Feature panel already focused";
   end Reason_Feature_Panel_Already_Focused;

end Editor.Outline;
