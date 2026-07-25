with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Contextual_Help;
with Editor.Outline.Activation; use Editor.Outline.Activation;
with Editor.Outline.Filtering; use Editor.Outline.Filtering;
with Editor.Outline.Selection; use Editor.Outline.Selection;

package body Editor.Outline.Projection is

   use type Editor.Feature_Panel.Feature_Panel_Row_Kind;

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

   procedure Clear_Visible_Outline_Rows (Outline : in out Outline_State) is
   begin
      if not Outline.Items.Is_Empty then
         Outline.Items.Clear;
      end if;
      Bump_Rows_Generation (Outline);
   end Clear_Visible_Outline_Rows;

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
         if Best_Index = 0 then
            Clear_Outline_Selection (Outline);
         end if;
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

   Fingerprint_Modulus : constant Long_Long_Integer := 2_147_483_647;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer := 131) return Natural
   is
   begin
      return Natural
        ((Long_Long_Integer (Seed) * Multiplier + Addend) mod Fingerprint_Modulus);
   end Hash_Mix;

   function Hash_String
     (Seed : Natural;
      Text : String) return Natural
   is
      H : Natural := Seed;
   begin
      for C of Text loop
         H := Hash_Mix (H, Long_Long_Integer (Character'Pos (C)) + 1);
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
         H := Hash_Mix
           (H, Long_Long_Integer (Outline_Item_Kind'Pos (Item_Kind (Outline, I))), 31);
         H := Hash_Mix
           (H,
            Long_Long_Integer
              (Outline_Target_Kind'Pos (Item_Target_Kind (Outline, I))),
            31);
         H := Hash_Mix
           (H, Long_Long_Integer (Item_Buffer_Token (Outline, I)) + 1, 31);
         H := Hash_Mix
           (H, Long_Long_Integer (Item_Depth (Outline, I)) + 1, 31);
         H := Hash_Mix
           (H, Long_Long_Integer (Item_Line (Outline, I)) + 1, 31);
         H := Hash_Mix
           (H, Long_Long_Integer (Item_Column (Outline, I)) + 1, 31);
         H := Hash_String (H, Item_Label (Outline, I));
         H := Hash_String (H, Item_Detail (Outline, I));
      end loop;
      return H;
   end Fingerprint;

end Editor.Outline.Projection;
