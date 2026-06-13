with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Contextual_Help;

package body Editor.Feature_Diagnostics is

   --  Diagnostics is a session-local feature-panel feature for manually and
   --  editor-posted diagnostic-like rows.  Diagnostics owns source rows,
   --  severity/source visibility, text filters, selection reconciliation,
   --  retention, target validation, and lifecycle cleanup.  Feature-panel
   --  infrastructure owns only generic projection rows, visible-row mapping,
   --  focus, reveal tokens, and dispatch mechanics.  Producers may post through
   --  Add_Diagnostic but must not mutate Diagnostics storage or projection
   --  internals directly.
   --
   --  Non-goals: compiler diagnostics, LSP diagnostics, build-log parsing,
   --  background analysis queues, persistence, file watching, project-wide
   --  analysis, diagnostic history, or persisted filter/group projection state.

   use type Editor.Feature_Panel.Feature_Id;

   function Trim_Image (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Trim_Image;

   function Severity_Label (Severity : Diagnostic_Severity) return String is
   begin
      case Severity is
         when Diagnostic_Info    => return "info";
         when Diagnostic_Note    => return "note";
         when Diagnostic_Warning => return "warning";
         when Diagnostic_Error   => return "error";
         when Diagnostic_Unknown => return "unknown";
      end case;
   end Severity_Label;

   function Source_Kind_Label (Source_Kind : Diagnostic_Source_Kind) return String is
   begin
      case Source_Kind is
         when Editor_Diagnostic_Source   => return "editor";
         when File_Diagnostic_Source     => return "file";
         when Project_Diagnostic_Source  => return "project";
         when External_Diagnostic_Source => return "external";
         when Unknown_Diagnostic_Source  => return "unknown";
      end case;
   end Source_Kind_Label;

   function Severity_Label_For_Display
     (Severity : Diagnostic_Severity) return String
   is
   begin
      return Severity_Label (Severity);
   end Severity_Label_For_Display;

   function Source_Kind_Label_For_Display
     (Source_Kind : Diagnostic_Source_Kind) return String
   is
   begin
      return Source_Kind_Label (Source_Kind);
   end Source_Kind_Label_For_Display;

   function Is_Build_Produced_Item (Item : Diagnostic_Item) return Boolean is
   begin
      return Item.Is_Build_Produced;
   end Is_Build_Produced_Item;

   function Producer_Label (Item : Diagnostic_Item) return String is
   begin
      if Is_Build_Produced_Item (Item) then
         return "Build";
      end if;

      case Item.Source_Kind is
         when Editor_Diagnostic_Source   => return "Manual/Test Fixture";
         when File_Diagnostic_Source     => return "File";
         when Project_Diagnostic_Source  => return "Project";
         when External_Diagnostic_Source => return "External Producer";
         when Unknown_Diagnostic_Source  => return "Unknown";
      end case;
   end Producer_Label;

   function Target_Unavailable_Label (Item : Diagnostic_Item) return String is
   begin
      if Item.Id = No_Diagnostic then
         return "Diagnostic target unavailable";
      elsif not Item.Has_Target
        and then Length (Item.Source_Label) = 0
        and then Item.Target_Buffer = No_Buffer
        and then Item.Target_Line = 0
      then
         return "No source target";
      elsif not Item.Has_Target
        and then Item.Target_Buffer /= No_Buffer
        and then Item.Target_Line = 0
      then
         --  Preserve partial producer target metadata.  A producer may know
         --  the buffer/source but fail to provide a usable line; that is not
         --  the same review failure as a missing file.
         return "Target line unavailable";
      elsif not Item.Has_Target
        and then Item.Target_Buffer = No_Buffer
        and then Item.Target_Line > 0
      then
         return "Target file missing";
      elsif not Item.Has_Target then
         return "Target file missing or unavailable";
      elsif Item.Target_Line = 0 then
         return "Target line unavailable";
      elsif Item.Target_Buffer = No_Buffer then
         return "Target file missing";
      elsif Item.Is_Stale then
         return "Target is stale; refresh required.";
      else
         return "";
      end if;
   end Target_Unavailable_Label;

   function Source_Filter_Label_For (Item : Diagnostic_Item) return String is
      Source : constant String := To_String (Item.Source_Label);
   begin
      if Source'Length > 0 then
         return Source;
      elsif Item.Target_Buffer /= No_Buffer then
         --  Producers are allowed to omit a source/path label while still
         --  retaining a buffer target.  Phase 557 treats that as an unlabeled
         --  target source, not as a true source-less diagnostic.  Keep the
         --  filter key narrow: it may include stable source identity metadata
         --  such as the retained buffer token, but never review status text.
         return "Buffer " & Trim_Image (Item.Target_Buffer);
      else
         return "";
      end if;
   end Source_Filter_Label_For;

   function Source_Display_Label (Item : Diagnostic_Item) return String is
      Source : constant String := To_String (Item.Source_Label);
      Position : constant String :=
        (if Item.Target_Line > 0 and then Item.Target_Column > 0 then
            Trim_Image (Item.Target_Line) & ":" & Trim_Image (Item.Target_Column)
         elsif Item.Target_Line > 0 then
            Trim_Image (Item.Target_Line)
         else
            "");
      Target_Source : constant String :=
        (if Source'Length > 0 then Source
         elsif Item.Target_Buffer /= No_Buffer then
            "Buffer " & Trim_Image (Item.Target_Buffer)
         else
            "");
   begin
      if Item.Has_Target then
         if Target_Source'Length = 0 then
            return Position;
         else
            return Target_Source & ":" & Position;
         end if;
      elsif Source'Length = 0
        and then Item.Target_Buffer = No_Buffer
        and then Item.Target_Line = 0
      then
         return "No source target";
      elsif Source'Length = 0 and then Item.Target_Buffer /= No_Buffer then
         return "Buffer " & Trim_Image (Item.Target_Buffer) &
           (if Position'Length > 0 then ":" & Position else "") &
           " — " & Target_Unavailable_Label (Item);
      elsif Position'Length > 0 then
         --  Retain known producer line metadata in the review label even when
         --  navigation is blocked because the file/buffer is unavailable.
         --  This keeps missing-target diagnostics triageable by line while
         --  still showing the explicit target failure marker.
         return Source & ":" & Position & " — " & Target_Unavailable_Label (Item);
      else
         return Source & " — " & Target_Unavailable_Label (Item);
      end if;
   end Source_Display_Label;

   procedure Refresh_Filter_Active
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Diagnostics.Filter.Active :=
        Length (Diagnostics.Filter.Text) > 0
        or else Length (Diagnostics.Filter.Source_Text) > 0
        or else not Diagnostics.Filter.Show_Info
        or else not Diagnostics.Filter.Show_Notes
        or else not Diagnostics.Filter.Show_Warnings
        or else not Diagnostics.Filter.Show_Errors
        or else not Diagnostics.Filter.Show_Unknown_Severity
        or else not Diagnostics.Filter.Show_Editor
        or else not Diagnostics.Filter.Show_File
        or else not Diagnostics.Filter.Show_Project
        or else not Diagnostics.Filter.Show_External
        or else not Diagnostics.Filter.Show_Unknown
        or else Diagnostics.Filter.Build_Only;
   end Refresh_Filter_Active;

   function Normalize_Diagnostics_Filter_Text (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));
   end Normalize_Diagnostics_Filter_Text;


   function Bounded_Text
     (Text        : String;
      Maximum     : Natural;
      Empty_Value : String) return String
   is
      Marker : constant String := "...";
      Clean  : constant String := (if Text'Length = 0 then Empty_Value else Text);
   begin
      if Clean'Length <= Maximum then
         return Clean;
      elsif Maximum <= Marker'Length then
         return Clean (Clean'First .. Clean'First + Maximum - 1);
      else
         return Clean (Clean'First .. Clean'First + Maximum - Marker'Length - 1) & Marker;
      end if;
   end Bounded_Text;

   function Normalize_Message (Message : String) return String is
   begin
      --  Diagnostics rows are review surface data, not a retained build log.
      --  Keep messages bounded at ingestion time so render/projection never
      --  has to trim unbounded producer text or raw parser output.
      return Bounded_Text
        (Message, Max_Diagnostic_Message_Text_Length, "Diagnostic");
   end Normalize_Message;

   function Normalize_Source_Label (Source_Label : String) return String is
   begin
      --  Source labels are row metadata shown in the Problems surface.  Bound
      --  them at ingestion just like messages so render, grouping, filtering,
      --  and copy actions never retain an unbounded producer path/label.
      return Bounded_Text
        (Source_Label, Max_Diagnostic_Source_Label_Text_Length, "");
   end Normalize_Source_Label;

   function Panel_Severity
     (Severity : Diagnostic_Severity) return Editor.Feature_Panel.Feature_Row_Severity
   is
   begin
      case Severity is
         when Diagnostic_Info | Diagnostic_Note | Diagnostic_Unknown =>
            return Editor.Feature_Panel.Feature_Row_Info_Severity;
         when Diagnostic_Warning =>
            return Editor.Feature_Panel.Feature_Row_Warning_Severity;
         when Diagnostic_Error =>
            return Editor.Feature_Panel.Feature_Row_Error_Severity;
      end case;
   end Panel_Severity;

   function Item_At
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Item
   is
   begin
      if Index = 0 or else Index > Row_Count (Diagnostics) then
         return (others => <>);
      end if;
      return Diagnostics.Rows.Element (Index - 1);
   end Item_At;

   function Stale_Label (Item : Diagnostic_Item) return String is
   begin
      if Item.Is_Stale then
         return "Stale diagnostic";
      else
         return "";
      end if;
   end Stale_Label;

   function Label_For (Item : Diagnostic_Item) return String is
   begin
      return Severity_Label (Item.Severity) & ": " & To_String (Item.Message) &
        " — " & Source_Display_Label (Item) &
        " [" & Producer_Label (Item) & "]" &
        (if Item.Is_Stale then " — stale" else "");
   end Label_For;

   function Detail_For (Item : Diagnostic_Item) return String is
      Target_Label : constant String := Target_Unavailable_Label (Item);
   begin
      return Source_Display_Label (Item) &
        " | producer: " & Producer_Label (Item) &
        (if Target_Label'Length = 0 then "" else " | " & Target_Label) &
        (if Item.Is_Stale then " | stale diagnostic" else "");
   end Detail_For;

   function Contains_Case_Insensitive
     (Haystack : String;
      Needle   : String) return Boolean
   is
      Normal_Haystack : constant String := Normalize_Diagnostics_Filter_Text (Haystack);
      Normal_Needle   : constant String := Normalize_Diagnostics_Filter_Text (Needle);
   begin
      return Normal_Needle'Length = 0
        or else Ada.Strings.Fixed.Index (Normal_Haystack, Normal_Needle) /= 0;
   end Contains_Case_Insensitive;

   function Diagnostic_Matches_Text_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
      Needle : constant String := To_String (Diagnostics.Filter.Text);
   begin
      if Needle'Length = 0 then
         return True;
      end if;

      return Contains_Case_Insensitive (To_String (Item.Message), Needle)
        or else Contains_Case_Insensitive (To_String (Item.Source_Label), Needle)
        or else Contains_Case_Insensitive (Severity_Label (Item.Severity), Needle)
        or else Contains_Case_Insensitive (Source_Kind_Label (Item.Source_Kind), Needle)
        or else Contains_Case_Insensitive (Label_For (Item), Needle)
        or else Contains_Case_Insensitive (Detail_For (Item), Needle);
   end Diagnostic_Matches_Text_Filter;

   function Diagnostic_Matches_Source_Label_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
      Needle : constant String := To_String (Diagnostics.Filter.Source_Text);
   begin
      if Needle'Length = 0 then
         return True;
      end if;

      --  Dedicated source/file filtering must match producer-owned source
      --  metadata only.  Do not match the full review display label here: that
      --  label also contains line numbers and target-status text such as
      --  "Target file missing", which would turn a source/file predicate into
      --  a general review-text search and hide rows incorrectly.
      return Contains_Case_Insensitive (Source_Filter_Label_For (Item), Needle);
   end Diagnostic_Matches_Source_Label_Filter;

   function Diagnostic_Matches_Severity_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
   begin
      case Item.Severity is
         when Diagnostic_Info    => return Diagnostics.Filter.Show_Info;
         when Diagnostic_Note    => return Diagnostics.Filter.Show_Notes;
         when Diagnostic_Warning => return Diagnostics.Filter.Show_Warnings;
         when Diagnostic_Error   => return Diagnostics.Filter.Show_Errors;
         when Diagnostic_Unknown => return Diagnostics.Filter.Show_Unknown_Severity;
      end case;
   end Diagnostic_Matches_Severity_Filter;

   function Diagnostic_Matches_Source_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
   begin
      case Item.Source_Kind is
         when Editor_Diagnostic_Source   => return Diagnostics.Filter.Show_Editor;
         when File_Diagnostic_Source     => return Diagnostics.Filter.Show_File;
         when Project_Diagnostic_Source  => return Diagnostics.Filter.Show_Project;
         when External_Diagnostic_Source => return Diagnostics.Filter.Show_External;
         when Unknown_Diagnostic_Source  => return Diagnostics.Filter.Show_Unknown;
      end case;
   end Diagnostic_Matches_Source_Filter;

   function Diagnostic_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
   begin
      return Diagnostic_Matches_Text_Filter (Diagnostics, Item)
        and then Diagnostic_Matches_Source_Label_Filter (Diagnostics, Item)
        and then Diagnostic_Matches_Severity_Filter (Diagnostics, Item)
        and then Diagnostic_Matches_Source_Filter (Diagnostics, Item)
        and then (not Diagnostics.Filter.Build_Only or else Is_Build_Produced_Item (Item));
   end Diagnostic_Is_Visible;

   function Group_Label_For (Item : Diagnostic_Item) return String;

   function Severity_Order (Severity : Diagnostic_Severity) return Natural is
   begin
      case Severity is
         when Diagnostic_Error   => return 0;
         when Diagnostic_Warning => return 1;
         when Diagnostic_Info    => return 2;
         when Diagnostic_Note    => return 3;
         when Diagnostic_Unknown => return 4;
      end case;
   end Severity_Order;

   function Target_Line_Order (Item : Diagnostic_Item) return Natural is
   begin
      --  Problems-style projection ordering should use retained producer line
      --  metadata even when the row is not currently navigable, for example a
      --  source-labelled missing-file diagnostic.  Missing-line diagnostics
      --  still sort after rows with known line numbers.
      if Item.Target_Line > 0 then
         return Item.Target_Line;
      else
         return Natural'Last;
      end if;
   end Target_Line_Order;

   function Target_Column_Order (Item : Diagnostic_Item) return Natural is
   begin
      if Item.Target_Column > 0 then
         return Item.Target_Column;
      elsif Item.Target_Line > 0 then
         return 1;
      else
         return Natural'Last;
      end if;
   end Target_Column_Order;

   function Diagnostic_Comes_Before
     (Left  : Diagnostic_Item;
      Right : Diagnostic_Item) return Boolean
   is
      Left_Group  : constant String := Group_Label_For (Left);
      Right_Group : constant String := Group_Label_For (Right);
      Left_Line   : constant Natural := Target_Line_Order (Left);
      Right_Line  : constant Natural := Target_Line_Order (Right);
      Left_Column : constant Natural := Target_Column_Order (Left);
      Right_Column : constant Natural := Target_Column_Order (Right);
   begin
      if Left_Group /= Right_Group then
         return Left_Group < Right_Group;
      elsif Left_Line /= Right_Line then
         return Left_Line < Right_Line;
      elsif Left_Column /= Right_Column then
         return Left_Column < Right_Column;
      elsif Severity_Order (Left.Severity) /= Severity_Order (Right.Severity) then
         return Severity_Order (Left.Severity) < Severity_Order (Right.Severity);
      else
         return Left.Id < Right.Id;
      end if;
   end Diagnostic_Comes_Before;

   function Ordered_Visible_Index_At
     (Diagnostics : Diagnostics_Feature_State;
      Position    : Positive) return Natural
   is
      Best_Index : Natural := 0;
      Best_Set   : Boolean := False;
   begin
      if Position > Visible_Row_Count (Diagnostics) then
         return 0;
      end if;

      for Pick in 1 .. Position loop
         Best_Index := 0;
         Best_Set := False;
         for I in 1 .. Row_Count (Diagnostics) loop
            declare
               Candidate : constant Diagnostic_Item := Diagnostics.Rows.Element (I - 1);
               Already_Selected : Boolean := False;
            begin
               if Diagnostic_Is_Visible (Diagnostics, Candidate) then
                  if Pick > 1 then
                     for Prior in 1 .. Pick - 1 loop
                        if I = Ordered_Visible_Index_At (Diagnostics, Prior) then
                           Already_Selected := True;
                        end if;
                     end loop;
                  end if;

                  if not Already_Selected
                    and then (not Best_Set
                      or else Diagnostic_Comes_Before
                        (Candidate, Diagnostics.Rows.Element (Best_Index - 1)))
                  then
                     Best_Index := I;
                     Best_Set := True;
                  end if;
               end if;
            end;
         end loop;
      end loop;

      if Best_Set then
         return Best_Index;
      else
         return 0;
      end if;
   end Ordered_Visible_Index_At;

   procedure Reset_Exhausted_Projection_Predicates
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Evict_Old_Diagnostics_If_Needed
     (Diagnostics : in out Diagnostics_Feature_State)
   is
      Removed : Boolean := False;
   begin
      while Natural (Diagnostics.Rows.Length) > Max_Diagnostics loop
         Diagnostics.Rows.Delete_First;
         Removed := True;
      end loop;

      if Removed then
         --  Bounded retention is still Diagnostics-owned row deletion.  If it
         --  evicts the last row matching a source/build projection predicate,
         --  reset only that exhausted predicate so preserved rows remain
         --  visible in the Problems review surface.
         Reset_Exhausted_Projection_Predicates (Diagnostics);
      end if;
   end Evict_Old_Diagnostics_If_Needed;

   procedure Assert_Diagnostics_State_Consistent
     (Diagnostics : Diagnostics_Feature_State)
   is
   begin
      pragma Assert (Row_Count (Diagnostics) <= Max_Diagnostics);
      pragma Assert (Diagnostics.Next_Id /= No_Diagnostic);
      for I in 1 .. Row_Count (Diagnostics) loop
         declare
            Item : constant Diagnostic_Item := Diagnostics.Rows.Element (I - 1);
         begin
            pragma Assert (Item.Id /= No_Diagnostic);
            pragma Assert (Item.Id < Diagnostics.Next_Id or else Diagnostics.Next_Id = Diagnostic_Id'Last);
            pragma Assert (Length (Item.Message) > 0);
            pragma Assert
              (Length (Item.Message) <= Max_Diagnostic_Message_Text_Length,
               "diagnostic message text must be bounded at ingestion");
            pragma Assert
              (Length (Item.Source_Label) <= Max_Diagnostic_Source_Label_Text_Length,
               "diagnostic source label text must be bounded at ingestion");
            if I > 1 then
               pragma Assert
                 (Diagnostics.Rows.Element (I - 2).Id < Item.Id,
                  "diagnostic ids must remain monotonically increasing in row storage");
            end if;
            if Item.Has_Target then
               pragma Assert (Item.Target_Buffer /= No_Buffer);
               pragma Assert (Item.Target_Line > 0);
               --  Target_Column = 0 is the explicit line-only target policy.
               --  Navigation normalizes it to the first column at activation time.
            else
               --  Non-navigable rows may still retain partial target metadata
               --  supplied by a trusted producer.  Phase 557 uses that metadata
               --  for review labels, stale marking, and buffer-close cleanup,
               --  while keeping Has_Target False so navigation remains blocked.
               --  Examples: known buffer but missing line, or known line with
               --  missing/unavailable buffer.  Columns remain meaningful only
               --  for navigable targets.
               pragma Assert (Item.Target_Column = 0);
            end if;
            for J in I + 1 .. Row_Count (Diagnostics) loop
               pragma Assert (Item.Id /= Diagnostics.Rows.Element (J - 1).Id);
            end loop;
         end;
      end loop;
   end Assert_Diagnostics_State_Consistent;

   procedure Clear_Diagnostics
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      --  Phase 557 treats a full clear as returning Diagnostics to the
      --  unfiltered no-diagnostics review state.  Keep this invariant in the
      --  Diagnostics-owned helper as well as the Executor route so direct
      --  lifecycle/test helpers cannot leave hidden filter predicates behind.
      Diagnostics.Rows.Clear;
      Diagnostics.Filter.Text := Null_Unbounded_String;
      Diagnostics.Filter.Source_Text := Null_Unbounded_String;
      Diagnostics.Filter.Show_Info := True;
      Diagnostics.Filter.Show_Notes := True;
      Diagnostics.Filter.Show_Warnings := True;
      Diagnostics.Filter.Show_Errors := True;
      Diagnostics.Filter.Show_Unknown_Severity := True;
      Diagnostics.Filter.Show_Editor := True;
      Diagnostics.Filter.Show_File := True;
      Diagnostics.Filter.Show_Project := True;
      Diagnostics.Filter.Show_External := True;
      Diagnostics.Filter.Show_Unknown := True;
      Diagnostics.Filter.Build_Only := False;
      Refresh_Filter_Active (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Clear_Diagnostics;

   procedure Add_Diagnostic
     (Diagnostics  : in out Diagnostics_Feature_State;
      Severity     : Diagnostic_Severity;
      Message      : String;
      Source_Label : String := "";
      Source_Kind  : Diagnostic_Source_Kind := Unknown_Diagnostic_Source;
      Has_Target   : Boolean := False;
      Target_Buffer : Natural := No_Buffer;
      Target_Line   : Natural := 0;
      Target_Column : Natural := 0;
      Build_Produced : Boolean := False)
   is
      Effective_Target : constant Boolean := Has_Target
        and then Target_Buffer /= No_Buffer
        and then Target_Line > 0;
      Effective_Build_Produced : constant Boolean :=
        Build_Produced and then Source_Kind = External_Diagnostic_Source;
      New_Id : constant Diagnostic_Id := Diagnostics.Next_Id;
   begin
      Diagnostics.Rows.Append
        (Diagnostic_Item'
          (Id                => New_Id,
          Severity          => Severity,
          Message           => To_Unbounded_String (Normalize_Message (Message)),
          Source_Label      => To_Unbounded_String (Normalize_Source_Label (Source_Label)),
          Source_Kind       => Source_Kind,
          Has_Target        => Effective_Target,
          --  Keep partial target metadata for diagnostics review labels even
          --  when the row is not navigable.  This lets the Problems surface
          --  distinguish missing files from missing/unavailable line targets
          --  without making render or availability probe the filesystem.
          Target_Buffer     => (if Has_Target then Target_Buffer else No_Buffer),
          Target_Line       => (if Has_Target then Target_Line else 0),
          Target_Column     => (if Effective_Target then Target_Column else 0),
          Is_Stale          => False,
          Is_Build_Produced => Effective_Build_Produced));
      if Diagnostics.Next_Id = Diagnostic_Id'Last then
         Diagnostics.Next_Id := Diagnostic_Id'Last;
      else
         Diagnostics.Next_Id := Diagnostics.Next_Id + 1;
      end if;
      Evict_Old_Diagnostics_If_Needed (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Add_Diagnostic;

   function Row_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
   is
   begin
      return Natural (Diagnostics.Rows.Length);
   end Row_Count;

   function Is_Empty
     (Diagnostics : Diagnostics_Feature_State) return Boolean
   is
   begin
      return Row_Count (Diagnostics) = 0;
   end Is_Empty;

   function Item_Id
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Id is
   begin
      return Item_At (Diagnostics, Index).Id;
   end Item_Id;

   function Item_Severity
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Severity is
   begin
      return Item_At (Diagnostics, Index).Severity;
   end Item_Severity;

   function Item_Message
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String is
   begin
      return To_String (Item_At (Diagnostics, Index).Message);
   end Item_Message;

   function Diagnostic_Message_Text_Is_Bounded
     (Diagnostics : Diagnostics_Feature_State) return Boolean
   is
   begin
      for I in 1 .. Row_Count (Diagnostics) loop
         if To_String (Diagnostics.Rows.Element (I - 1).Message)'Length >
           Max_Diagnostic_Message_Text_Length
         then
            return False;
         end if;
      end loop;
      return True;
   end Diagnostic_Message_Text_Is_Bounded;

   function Diagnostic_Source_Label_Text_Is_Bounded
     (Diagnostics : Diagnostics_Feature_State) return Boolean
   is
   begin
      for I in 1 .. Row_Count (Diagnostics) loop
         if To_String (Diagnostics.Rows.Element (I - 1).Source_Label)'Length >
           Max_Diagnostic_Source_Label_Text_Length
         then
            return False;
         end if;
      end loop;
      return True;
   end Diagnostic_Source_Label_Text_Is_Bounded;

   function Item_Source_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String is
   begin
      return To_String (Item_At (Diagnostics, Index).Source_Label);
   end Item_Source_Label;

   function Item_Source_Kind
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Source_Kind is
   begin
      return Item_At (Diagnostics, Index).Source_Kind;
   end Item_Source_Kind;

   function Item_Display_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String is
   begin
      return Label_For (Item_At (Diagnostics, Index));
   end Item_Display_Label;


   function Producer_Label_For_Display
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
   begin
      return Producer_Label (Item_At (Diagnostics, Index));
   end Producer_Label_For_Display;

   function Item_Source_Display_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
   begin
      return Source_Display_Label (Item_At (Diagnostics, Index));
   end Item_Source_Display_Label;

   function Item_Target_Unavailable_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
   begin
      return Target_Unavailable_Label (Item_At (Diagnostics, Index));
   end Item_Target_Unavailable_Label;

   function Item_Is_Stale
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean
   is
   begin
      return Item_At (Diagnostics, Index).Is_Stale;
   end Item_Is_Stale;

   function Item_Stale_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
   begin
      return Stale_Label (Item_At (Diagnostics, Index));
   end Item_Stale_Label;

   function Item_Is_Build_Produced
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean
   is
      Item : constant Diagnostic_Item := Item_At (Diagnostics, Index);
   begin
      return Is_Build_Produced_Item (Item);
   end Item_Is_Build_Produced;

   function Visible_Row_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Row_Count (Diagnostics) loop
         if Diagnostic_Is_Visible (Diagnostics, Diagnostics.Rows.Element (I - 1)) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Visible_Row_Count;

   function Severity_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Severity    : Diagnostic_Severity) return Boolean
   is
   begin
      case Severity is
         when Diagnostic_Info    => return Diagnostics.Filter.Show_Info;
         when Diagnostic_Note    => return Diagnostics.Filter.Show_Notes;
         when Diagnostic_Warning => return Diagnostics.Filter.Show_Warnings;
         when Diagnostic_Error   => return Diagnostics.Filter.Show_Errors;
         when Diagnostic_Unknown => return Diagnostics.Filter.Show_Unknown_Severity;
      end case;
   end Severity_Is_Visible;

   function Source_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Source_Kind : Diagnostic_Source_Kind) return Boolean
   is
   begin
      case Source_Kind is
         when Editor_Diagnostic_Source   => return Diagnostics.Filter.Show_Editor;
         when File_Diagnostic_Source     => return Diagnostics.Filter.Show_File;
         when Project_Diagnostic_Source  => return Diagnostics.Filter.Show_Project;
         when External_Diagnostic_Source => return Diagnostics.Filter.Show_External;
         when Unknown_Diagnostic_Source  => return Diagnostics.Filter.Show_Unknown;
      end case;
   end Source_Is_Visible;

   function Filter_Active
     (Diagnostics : Diagnostics_Feature_State) return Boolean
   is
   begin
      return Diagnostics.Filter.Active;
   end Filter_Active;

   function Filter_Text
     (Diagnostics : Diagnostics_Feature_State) return String
   is
   begin
      return To_String (Diagnostics.Filter.Text);
   end Filter_Text;

   procedure Set_Filter_Text
     (Diagnostics : in out Diagnostics_Feature_State;
      Text        : String)
   is
   begin
      Diagnostics.Filter.Text :=
        To_Unbounded_String (Normalize_Diagnostics_Filter_Text (Text));
      Diagnostics.Filter.Source_Text := Null_Unbounded_String;
      Refresh_Filter_Active (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Set_Filter_Text;

   procedure Show_All
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Diagnostics.Filter.Text := Null_Unbounded_String;
      Diagnostics.Filter.Source_Text := Null_Unbounded_String;
      Diagnostics.Filter.Show_Info := True;
      Diagnostics.Filter.Show_Notes := True;
      Diagnostics.Filter.Show_Warnings := True;
      Diagnostics.Filter.Show_Errors := True;
      Diagnostics.Filter.Show_Unknown_Severity := True;
      Diagnostics.Filter.Show_Editor := True;
      Diagnostics.Filter.Show_File := True;
      Diagnostics.Filter.Show_Project := True;
      Diagnostics.Filter.Show_External := True;
      Diagnostics.Filter.Show_Unknown := True;
      Diagnostics.Filter.Build_Only := False;
      Refresh_Filter_Active (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Show_All;

   procedure Clear_Filter
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Show_All (Diagnostics);
   end Clear_Filter;

   procedure Toggle_Info_Visible
     (Diagnostics : in out Diagnostics_Feature_State)
   is
      New_Visibility : constant Boolean := not Diagnostics.Filter.Show_Info;
   begin
      --  Phase 557 treats info and notes as one informational triage bucket
      --  for review/filter/clear behavior.  Keep the toggle-info command
      --  aligned with that bucket so note rows are not left visible
      --  after users hide informational diagnostics.
      Diagnostics.Filter.Show_Info := New_Visibility;
      Diagnostics.Filter.Show_Notes := New_Visibility;
      Refresh_Filter_Active (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Toggle_Info_Visible;

   procedure Toggle_Warnings_Visible
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Diagnostics.Filter.Show_Warnings := not Diagnostics.Filter.Show_Warnings;
      Refresh_Filter_Active (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Toggle_Warnings_Visible;

   procedure Toggle_Errors_Visible
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Diagnostics.Filter.Show_Errors := not Diagnostics.Filter.Show_Errors;
      Refresh_Filter_Active (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Toggle_Errors_Visible;

   procedure Toggle_Source_Visible
     (Diagnostics : in out Diagnostics_Feature_State;
      Source_Kind : Diagnostic_Source_Kind)
   is
   begin
      case Source_Kind is
         when Editor_Diagnostic_Source =>
            Diagnostics.Filter.Show_Editor := not Diagnostics.Filter.Show_Editor;
         when File_Diagnostic_Source =>
            Diagnostics.Filter.Show_File := not Diagnostics.Filter.Show_File;
         when Project_Diagnostic_Source =>
            Diagnostics.Filter.Show_Project := not Diagnostics.Filter.Show_Project;
         when External_Diagnostic_Source =>
            Diagnostics.Filter.Show_External := not Diagnostics.Filter.Show_External;
         when Unknown_Diagnostic_Source =>
            Diagnostics.Filter.Show_Unknown := not Diagnostics.Filter.Show_Unknown;
      end case;
      Refresh_Filter_Active (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Toggle_Source_Visible;

   function Count_By_Severity
     (Diagnostics : Diagnostics_Feature_State) return Diagnostics_Severity_Counts
   is
      Counts : Diagnostics_Severity_Counts;
   begin
      Counts.Total := Row_Count (Diagnostics);
      Counts.Visible := Visible_Row_Count (Diagnostics);
      for I in 1 .. Row_Count (Diagnostics) loop
         declare
            Item : constant Diagnostic_Item := Diagnostics.Rows.Element (I - 1);
            Is_Visible : constant Boolean := Diagnostic_Is_Visible (Diagnostics, Item);
         begin
            case Item.Severity is
               when Diagnostic_Error =>
                  Counts.Errors := Counts.Errors + 1;
                  if Is_Visible then
                     Counts.Visible_Errors := Counts.Visible_Errors + 1;
                  end if;
               when Diagnostic_Warning =>
                  Counts.Warnings := Counts.Warnings + 1;
                  if Is_Visible then
                     Counts.Visible_Warnings := Counts.Visible_Warnings + 1;
                  end if;
               when Diagnostic_Info =>
                  Counts.Info := Counts.Info + 1;
                  if Is_Visible then
                     Counts.Visible_Info := Counts.Visible_Info + 1;
                  end if;
               when Diagnostic_Note =>
                  Counts.Notes := Counts.Notes + 1;
                  if Is_Visible then
                     Counts.Visible_Notes := Counts.Visible_Notes + 1;
                  end if;
               when Diagnostic_Unknown =>
                  Counts.Unknown := Counts.Unknown + 1;
                  if Is_Visible then
                     Counts.Visible_Unknown := Counts.Visible_Unknown + 1;
                  end if;
            end case;
         end;
      end loop;
      return Counts;
   end Count_By_Severity;

   function Count_Label
     (Counts : Diagnostics_Severity_Counts) return String
   is
   begin
      return "Errors: " & Trim_Image (Counts.Errors) &
        " | Warnings: " & Trim_Image (Counts.Warnings) &
        " | Info: " & Trim_Image (Counts.Info) &
        " | Notes: " & Trim_Image (Counts.Notes) &
        " | Unknown: " & Trim_Image (Counts.Unknown) &
        " | Total: " & Trim_Image (Counts.Total);
   end Count_Label;

   function Visible_Count_Label
     (Counts : Diagnostics_Severity_Counts) return String
   is
   begin
      return "Visible Errors: " & Trim_Image (Counts.Visible_Errors) &
        " | Visible Warnings: " & Trim_Image (Counts.Visible_Warnings) &
        " | Visible Info: " & Trim_Image (Counts.Visible_Info) &
        " | Visible Notes: " & Trim_Image (Counts.Visible_Notes) &
        " | Visible Unknown: " & Trim_Image (Counts.Visible_Unknown) &
        " | Visible Total: " & Trim_Image (Counts.Visible);
   end Visible_Count_Label;



   function Group_Label_For (Item : Diagnostic_Item) return String is
      Source : constant String := To_String (Item.Source_Label);
   begin
      if Source'Length = 0
        and then Item.Target_Buffer = No_Buffer
        and then Item.Target_Line = 0
      then
         return "No source target";
      elsif Source'Length = 0 and then Item.Target_Buffer /= No_Buffer then
         return "Buffer " & Trim_Image (Item.Target_Buffer) &
           (if Item.Has_Target then "" else " — " & Target_Unavailable_Label (Item));
      elsif Source'Length = 0 and then Item.Target_Line > 0 then
         return "Target file missing";
      elsif not Item.Has_Target then
         --  Phase 557 distinguishes a true source-less diagnostic from a
         --  diagnostic that names a source but cannot currently navigate to
         --  it. File grouping is projection-only, but its labels must keep
         --  that same review distinction so users do not misread missing-file
         --  or missing-line diagnostics as producer/source-less diagnostics.
         return Source & " — " & Target_Unavailable_Label (Item);
      else
         return Source;
      end if;
   end Group_Label_For;

   function Visible_File_Groups
     (Diagnostics : Diagnostics_Feature_State)
      return Diagnostics_File_Group_Vectors.Vector
   is
      Groups : Diagnostics_File_Group_Vectors.Vector;
   begin
      for Position in 1 .. Visible_Row_Count (Diagnostics) loop
         declare
            I     : constant Natural := Ordered_Visible_Index_At (Diagnostics, Position);
            Item   : constant Diagnostic_Item := Diagnostics.Rows.Element (I - 1);
            Source : constant String := To_String (Item.Source_Label);
            Label  : constant String := Group_Label_For (Item);
            Found  : Boolean := False;
         begin
            if I /= 0 then
               if not Groups.Is_Empty then
                  for G in Groups.First_Index .. Groups.Last_Index loop
                     declare
                        Existing : Diagnostics_File_Group := Groups.Element (G);
                     begin
                        if To_String (Existing.Label) = Label then
                           Existing.Diagnostic_Count := Existing.Diagnostic_Count + 1;
                           if Item.Severity = Diagnostic_Error then
                              Existing.Error_Count := Existing.Error_Count + 1;
                           elsif Item.Severity = Diagnostic_Warning then
                              Existing.Warning_Count := Existing.Warning_Count + 1;
                           end if;
                           Groups.Replace_Element (G, Existing);
                           Found := True;
                        end if;
                     end;
                  end loop;
               end if;

               if not Found then
                  Groups.Append
                    (Diagnostics_File_Group'
                      (Label            => To_Unbounded_String (Label),
                      Diagnostic_Count => 1,
                      Error_Count      => (if Item.Severity = Diagnostic_Error then 1 else 0),
                      Warning_Count    => (if Item.Severity = Diagnostic_Warning then 1 else 0),
                      --  Source_Less is semantic metadata for true source-less
                      --  diagnostics, not a synonym for non-navigable or for
                      --  unlabeled-but-known buffer targets. A row with a
                      --  known target buffer but no source label is grouped as
                      --  an unlabeled target buffer, not as source-less.
                      Source_Less      => Source'Length = 0
                        and then not Item.Has_Target
                        and then Item.Target_Buffer = No_Buffer
                        and then Item.Target_Line = 0));
               end if;
            end if;
         end;
      end loop;
      return Groups;
   end Visible_File_Groups;

   function File_Group_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
   is
   begin
      return Natural (Visible_File_Groups (Diagnostics).Length);
   end File_Group_Count;

   function File_Group_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
      Groups : constant Diagnostics_File_Group_Vectors.Vector :=
        Visible_File_Groups (Diagnostics);
      Group  : Diagnostics_File_Group;
   begin
      if Index = 0 or else Index > Natural (Groups.Length) then
         return "";
      end if;
      Group := Groups.Element (Index - 1);
      return To_String (Group.Label) & " (" & Trim_Image (Group.Diagnostic_Count) &
        " diagnostics, " & Trim_Image (Group.Error_Count) & " errors, " &
        Trim_Image (Group.Warning_Count) & " warnings)";
   end File_Group_Label;

   function Header_Text
     (Diagnostics : Diagnostics_Feature_State) return String
   is
      Counts : constant Diagnostics_Severity_Counts := Count_By_Severity (Diagnostics);
   begin
      if Counts.Total = 0 then
         return "No diagnostics.";
      elsif Filter_Active (Diagnostics) then
         return "Diagnostics: " & Trim_Image (Counts.Visible) & " of " &
           Trim_Image (Counts.Total) & " visible | " &
           Visible_Count_Label (Counts) & " | " & Count_Label (Counts);
      else
         return "Diagnostics: " & Count_Label (Counts);
      end if;
   end Header_Text;

   function Next_Diagnostic_Id
     (Diagnostics : Diagnostics_Feature_State) return Diagnostic_Id is
   begin
      return Diagnostics.Next_Id;
   end Next_Diagnostic_Id;

   function Item_Has_Target
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean is
   begin
      return Item_At (Diagnostics, Index).Has_Target;
   end Item_Has_Target;

   function Item_Target_Buffer
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural is
   begin
      return Item_At (Diagnostics, Index).Target_Buffer;
   end Item_Target_Buffer;

   function Item_Target_Line
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural is
   begin
      return Item_At (Diagnostics, Index).Target_Line;
   end Item_Target_Line;

   function Item_Target_Column
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural is
   begin
      return Item_At (Diagnostics, Index).Target_Column;
   end Item_Target_Column;

   function Index_For_Id
     (Diagnostics : Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Natural;

   function Map_Diagnostic_Id_To_Item
     (Diagnostics : Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Natural
   is
   begin
      return Index_For_Id (Diagnostics, Id);
   end Map_Diagnostic_Id_To_Item;

   function Diagnostic_Id_Is_Live
     (Diagnostics : Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Boolean
   is
   begin
      return Map_Diagnostic_Id_To_Item (Diagnostics, Id) /= 0;
   end Diagnostic_Id_Is_Live;

   function Validate_Diagnostic_Id_Target
     (Diagnostics         : Diagnostics_Feature_State;
      Id                  : Diagnostic_Id;
      Active_Buffer_Token : Natural) return Boolean
   is
      Index : constant Natural := Map_Diagnostic_Id_To_Item (Diagnostics, Id);
   begin
      return Index /= 0
        and then Validate_Diagnostic_Target
          (Diagnostics, Positive (Index), Active_Buffer_Token);
   end Validate_Diagnostic_Id_Target;

   function Has_Visible_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean
   is
   begin
      return Visible_Row_Count (Diagnostics) > 0;
   end Has_Visible_Diagnostic;

   function Build_Diagnostic_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Row_Count (Diagnostics) loop
         if Is_Build_Produced_Item (Diagnostics.Rows.Element (I - 1)) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Build_Diagnostic_Count;

   function Has_Diagnostic_With_Severity
     (Diagnostics : Diagnostics_Feature_State;
      Severity    : Diagnostic_Severity) return Boolean
   is
   begin
      for I in 1 .. Row_Count (Diagnostics) loop
         if Diagnostics.Rows.Element (I - 1).Severity = Severity then
            return True;
         end if;
      end loop;
      return False;
   end Has_Diagnostic_With_Severity;

   function Has_Info_Or_Note_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean
   is
   begin
      for I in 1 .. Row_Count (Diagnostics) loop
         if Diagnostics.Rows.Element (I - 1).Severity = Diagnostic_Info
           or else Diagnostics.Rows.Element (I - 1).Severity = Diagnostic_Note
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Info_Or_Note_Diagnostic;

   function Has_Build_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean
   is
   begin
      return Build_Diagnostic_Count (Diagnostics) > 0;
   end Has_Build_Diagnostic;

   procedure Project_Rows
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State)
   is
      Selected_Id : Natural := 0;
      First_Selectable_Row : Natural := 0;
      Restored_Row : Natural := 0;
      Appended_Row : Natural := 0;
   begin
      if not Editor.Feature_Panel.Set_Active_Feature
        (Panel, Editor.Feature_Panel.Diagnostics_Feature)
      then
         return;
      end if;

      if Editor.Feature_Panel.Selected_Row (Panel) /= 0
        and then Editor.Feature_Panel.Projection_Row_Index_Is_Valid
          (Panel, Editor.Feature_Panel.Selected_Row (Panel))
      then
         Selected_Id := Editor.Feature_Panel.Row_Source_Index
           (Panel, Positive (Editor.Feature_Panel.Selected_Row (Panel)));
      end if;

      Editor.Feature_Panel.Clear_Rows (Panel);
      Editor.Feature_Panel.Set_Header_Text (Panel, Header_Text (Diagnostics));

      if Row_Count (Diagnostics) = 0 then
         Editor.Feature_Panel.Append_Row
           (Panel,
            Kind        => Editor.Feature_Panel.Feature_Row_Empty_State,
            Label       => "No diagnostics.",
            Detail      => Editor.Contextual_Help.Empty_Diagnostics_Detail,
            Selectable  => False,
            Activatable => False,
            Has_Target  => False,
            Can_Open    => False,
            Source_Index => 0);
      elsif Visible_Row_Count (Diagnostics) = 0 then
         Editor.Feature_Panel.Append_Row
           (Panel,
            Kind        => Editor.Feature_Panel.Feature_Row_Empty_State,
            Label       => "No matching diagnostics",
            Detail      => "Clear the filter to show diagnostics.",
            Selectable  => False,
            Activatable => False,
            Has_Target  => False,
            Can_Open    => False,
            Source_Index => 0);
      else
         for Position in 1 .. Visible_Row_Count (Diagnostics) loop
            declare
               I    : constant Natural := Ordered_Visible_Index_At (Diagnostics, Position);
               Item : constant Diagnostic_Item := Diagnostics.Rows.Element (I - 1);
            begin
               if I /= 0 then
                  Editor.Feature_Panel.Append_Row
                    (Panel,
                     Kind          => Editor.Feature_Panel.Feature_Row_Item,
                     Label         => Label_For (Item),
                     Detail        => Detail_For (Item),
                     Selectable    => True,
                     Activatable   => Item.Has_Target,
                     Has_Target    => Item.Has_Target,
                     Is_Diagnostic => True,
                     Can_Open      => Item.Has_Target,
                     Can_Copy      => True,
                     Can_Clear     => True,
                     Source_Index  => Natural (Item.Id),
                     Severity      => Panel_Severity (Item.Severity));
                  Appended_Row := Editor.Feature_Panel.Row_Count (Panel);
                  if First_Selectable_Row = 0 then
                     First_Selectable_Row := Appended_Row;
                  end if;
                  if Selected_Id /= 0 and then Selected_Id = Natural (Item.Id) then
                     Restored_Row := Appended_Row;
                  end if;
               end if;
            end;
         end loop;
      end if;

      if Restored_Row /= 0 then
         Editor.Feature_Panel.Select_Row (Panel, Restored_Row);
      elsif First_Selectable_Row /= 0 then
         Editor.Feature_Panel.Select_Row (Panel, First_Selectable_Row);
      else
         Editor.Feature_Panel.Select_Row (Panel, 0);
      end if;
   end Project_Rows;

   function Index_For_Id
     (Diagnostics : Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Natural
   is
   begin
      if Id = No_Diagnostic then
         return 0;
      end if;
      for I in 1 .. Row_Count (Diagnostics) loop
         if Diagnostics.Rows.Element (I - 1).Id = Id then
            return I;
         end if;
      end loop;
      return 0;
   end Index_For_Id;



   function Selected_Diagnostic_Source_Index
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Natural
   is
      Row : constant Natural := Editor.Feature_Panel.Selected_Row (Panel);
      Id_Value : Natural := 0;
      Source : Natural := 0;
   begin
      if Editor.Feature_Panel.Active_Feature (Panel) /= Editor.Feature_Panel.Diagnostics_Feature
        or else Row = 0
        or else not Editor.Feature_Panel.Projection_Row_Index_Is_Valid (Panel, Row)
        or else not Editor.Feature_Panel.Row_Is_Selectable (Panel, Row)
      then
         return 0;
      end if;

      Id_Value := Editor.Feature_Panel.Row_Source_Index (Panel, Positive (Row));
      if Id_Value = 0 then
         return 0;
      end if;

      Source := Index_For_Id (Diagnostics, Diagnostic_Id (Id_Value));
      if Source = 0 then
         return 0;
      end if;

      declare
         Item : constant Diagnostic_Item := Item_At (Diagnostics, Positive (Source));
      begin
         if Editor.Feature_Panel.Row_Label (Panel, Positive (Row)) /= Label_For (Item)
           or else Editor.Feature_Panel.Row_Detail (Panel, Positive (Row)) /= Detail_For (Item)
         then
            return 0;
         end if;
      end;
      return Source;
   end Selected_Diagnostic_Source_Index;

   function Has_Selected_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
   begin
      return Selected_Diagnostic_Source_Index (Diagnostics, Panel) /= 0;
   end Has_Selected_Diagnostic;

   function Selected_Diagnostic_Id
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Diagnostic_Id
   is
      Source : constant Natural := Selected_Diagnostic_Source_Index (Diagnostics, Panel);
   begin
      if Source = 0 then
         return No_Diagnostic;
      else
         return Item_Id (Diagnostics, Positive (Source));
      end if;
   end Selected_Diagnostic_Id;

   function Selected_Diagnostic_Has_Target
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
      Source : constant Natural := Selected_Diagnostic_Source_Index (Diagnostics, Panel);
   begin
      return Source /= 0
        and then Item_Has_Target (Diagnostics, Positive (Source));
   end Selected_Diagnostic_Has_Target;

   function Selected_Diagnostic_Target_Unavailable_Label
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String
   is
      Source : constant Natural := Selected_Diagnostic_Source_Index (Diagnostics, Panel);
   begin
      if Source = 0 then
         return "Selected diagnostic is no longer available.";
      else
         return Item_Target_Unavailable_Label (Diagnostics, Positive (Source));
      end if;
   end Selected_Diagnostic_Target_Unavailable_Label;

   function Selected_Diagnostic_Open_Unavailable_Reason
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String
   is
      Label : constant String :=
        Selected_Diagnostic_Target_Unavailable_Label (Diagnostics, Panel);
   begin
      if Label = "No source target" then
         return "Selected diagnostic has no source target";
      elsif Label = "Target file missing or unavailable"
        or else Label = "Target file missing"
      then
         return "Diagnostic target file is unavailable";
      elsif Label = "Target line unavailable" then
         return "Diagnostic target line is unavailable";
      elsif Label = "Target is stale; refresh required." then
         return "Target is stale; refresh required.";
      elsif Label'Length > 0 then
         return Label;
      else
         return "Diagnostic target unavailable";
      end if;
   end Selected_Diagnostic_Open_Unavailable_Reason;

   function Format_Diagnostic_For_Copy
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
      Item : constant Diagnostic_Item := Item_At (Diagnostics, Index);
   begin
      if Index > Row_Count (Diagnostics) or else Item.Id = No_Diagnostic then
         return "";
      end if;
      return Label_For (Item);
   end Format_Diagnostic_For_Copy;

   function Selected_Diagnostic_Text
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String
   is
      Source : constant Natural := Selected_Diagnostic_Source_Index (Diagnostics, Panel);
   begin
      if Source = 0 then
         return "";
      else
         return Format_Diagnostic_For_Copy (Diagnostics, Positive (Source));
      end if;
   end Selected_Diagnostic_Text;

   function Selected_Diagnostic_Source_Filter_Label
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String
   is
      Source : constant Natural := Selected_Diagnostic_Source_Index (Diagnostics, Panel);
   begin
      if Source = 0 then
         return "";
      end if;

      declare
         Item : constant Diagnostic_Item := Item_At (Diagnostics, Positive (Source));
      begin
         return Source_Filter_Label_For (Item);
      end;
   end Selected_Diagnostic_Source_Filter_Label;

   function Row_Is_Live_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State;
      Row         : Natural) return Boolean
   is
   begin
      return Map_Diagnostic_Row_To_Item (Diagnostics, Panel, Row) /= 0;
   end Row_Is_Live_Diagnostic;

   procedure Select_Next_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State)
   is
      Count   : constant Natural := Editor.Feature_Panel.Row_Count (Panel);
      Current : constant Natural := Editor.Feature_Panel.Selected_Row (Panel);
   begin
      if Count = 0
        or else Editor.Feature_Panel.Active_Feature (Panel) /=
          Editor.Feature_Panel.Diagnostics_Feature
        or else not Has_Visible_Diagnostic (Diagnostics)
      then
         Editor.Feature_Panel.Select_Row (Panel, 0);
         return;
      end if;

      if Current < Count then
         for Row in Current + 1 .. Count loop
            if Row_Is_Live_Diagnostic (Diagnostics, Panel, Row) then
               Editor.Feature_Panel.Select_Row (Panel, Row);
               return;
            end if;
         end loop;
      end if;

      --  Phase 557 next/previous diagnostics use explicit Problems-style
      --  wraparound through the visible diagnostic projection.  Generic
      --  Feature_Panel selection intentionally remains non-wrapping.
      for Row in 1 .. Count loop
         exit when Current /= 0 and then Row >= Current;
         if Row_Is_Live_Diagnostic (Diagnostics, Panel, Row) then
            Editor.Feature_Panel.Select_Row (Panel, Row);
            return;
         end if;
      end loop;
   end Select_Next_Diagnostic;

   procedure Select_Previous_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State)
   is
      Count   : constant Natural := Editor.Feature_Panel.Row_Count (Panel);
      Current : constant Natural := Editor.Feature_Panel.Selected_Row (Panel);
   begin
      if Count = 0
        or else Editor.Feature_Panel.Active_Feature (Panel) /=
          Editor.Feature_Panel.Diagnostics_Feature
        or else not Has_Visible_Diagnostic (Diagnostics)
      then
         Editor.Feature_Panel.Select_Row (Panel, 0);
         return;
      end if;

      if Current > 1 then
         for Offset in 1 .. Current - 1 loop
            declare
               Row : constant Natural := Current - Offset;
            begin
               if Row_Is_Live_Diagnostic (Diagnostics, Panel, Row) then
                  Editor.Feature_Panel.Select_Row (Panel, Row);
                  return;
               end if;
            end;
         end loop;
      end if;

      --  Wrap to the last visible diagnostic row when the current selection is
      --  the first row or when no live diagnostic row is selected.
      for Offset in 0 .. Count - 1 loop
         declare
            Row : constant Natural := Count - Offset;
         begin
            exit when Current /= 0 and then Row <= Current;
            if Row_Is_Live_Diagnostic (Diagnostics, Panel, Row) then
               Editor.Feature_Panel.Select_Row (Panel, Row);
               return;
            end if;
         end;
      end loop;
   end Select_Previous_Diagnostic;


   procedure Reset_Exhausted_Projection_Predicates
     (Diagnostics : in out Diagnostics_Feature_State)
   is
      Source_Matches : Natural := 0;
   begin
      --  Source/build filters are Problems-view projection predicates, not
      --  retained hidden state.  When targeted deletion removes the final row
      --  that can satisfy one of these predicates, drop only that exhausted
      --  predicate so preserved Diagnostics-owned rows remain reviewable.
      if Diagnostics.Filter.Build_Only and then Build_Diagnostic_Count (Diagnostics) = 0 then
         Diagnostics.Filter.Build_Only := False;
      end if;

      if Length (Diagnostics.Filter.Source_Text) > 0 then
         for I in 1 .. Row_Count (Diagnostics) loop
            if Diagnostic_Matches_Source_Label_Filter
              (Diagnostics, Diagnostics.Rows.Element (I - 1))
            then
               Source_Matches := Source_Matches + 1;
            end if;
         end loop;

         if Source_Matches = 0 then
            Diagnostics.Filter.Source_Text := Null_Unbounded_String;
         end if;
      end if;

      Refresh_Filter_Active (Diagnostics);
   end Reset_Exhausted_Projection_Predicates;

   function Clear_Diagnostic_By_Id
     (Diagnostics : in out Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Boolean
   is
      Index : constant Natural := Index_For_Id (Diagnostics, Id);
   begin
      if Index = 0 then
         return False;
      end if;
      Diagnostics.Rows.Delete (Index - 1);
      Reset_Exhausted_Projection_Predicates (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
      return True;
   end Clear_Diagnostic_By_Id;

   function Clear_Diagnostics_By_Severity
     (Diagnostics : in out Diagnostics_Feature_State;
      Severity    : Diagnostic_Severity) return Natural
   is
      Removed : Natural := 0;
      I       : Diagnostic_Row_Vectors.Extended_Index := Diagnostics.Rows.First_Index;
   begin
      while I <= Diagnostics.Rows.Last_Index loop
         if Diagnostics.Rows.Element (I).Severity = Severity then
            Diagnostics.Rows.Delete (I);
            Removed := Removed + 1;
         else
            I := I + 1;
         end if;
      end loop;
      Reset_Exhausted_Projection_Predicates (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
      return Removed;
   end Clear_Diagnostics_By_Severity;

   function Clear_Info_And_Note_Diagnostics
     (Diagnostics : in out Diagnostics_Feature_State) return Natural
   is
      Removed : Natural := 0;
      I       : Diagnostic_Row_Vectors.Extended_Index := Diagnostics.Rows.First_Index;
   begin
      while I <= Diagnostics.Rows.Last_Index loop
         if Diagnostics.Rows.Element (I).Severity = Diagnostic_Info
           or else Diagnostics.Rows.Element (I).Severity = Diagnostic_Note
         then
            Diagnostics.Rows.Delete (I);
            Removed := Removed + 1;
         else
            I := I + 1;
         end if;
      end loop;
      Reset_Exhausted_Projection_Predicates (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
      return Removed;
   end Clear_Info_And_Note_Diagnostics;

   function Clear_Diagnostics_By_Source
     (Diagnostics : in out Diagnostics_Feature_State;
      Source_Kind : Diagnostic_Source_Kind) return Natural
   is
      Removed : Natural := 0;
      I       : Diagnostic_Row_Vectors.Extended_Index := Diagnostics.Rows.First_Index;
   begin
      while I <= Diagnostics.Rows.Last_Index loop
         if Diagnostics.Rows.Element (I).Source_Kind = Source_Kind then
            Diagnostics.Rows.Delete (I);
            Removed := Removed + 1;
         else
            I := I + 1;
         end if;
      end loop;
      Reset_Exhausted_Projection_Predicates (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
      return Removed;
   end Clear_Diagnostics_By_Source;

   procedure Reconcile_Diagnostics_Selection_After_Delete
     (Diagnostics     : Diagnostics_Feature_State;
      Panel           : in out Editor.Feature_Panel.Feature_Panel_State;
      Previous_Id     : Diagnostic_Id;
      Previous_Source : Natural)
   is
      Same_Row     : Natural := 0;
      Next_Row     : Natural := 0;
      Previous_Row : Natural := 0;
   begin
      for Row in 1 .. Editor.Feature_Panel.Row_Count (Panel) loop
         if Editor.Feature_Panel.Row_Is_Selectable (Panel, Row) then
            declare
               Id_Value : constant Natural := Editor.Feature_Panel.Row_Source_Index (Panel, Row);
               Source   : Natural := 0;
            begin
               if Id_Value > 0 then
                  Source := Index_For_Id (Diagnostics, Diagnostic_Id (Id_Value));
                  if Source > 0 then
                     if Previous_Id /= No_Diagnostic
                       and then Diagnostic_Id (Id_Value) = Previous_Id
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
   end Reconcile_Diagnostics_Selection_After_Delete;

   function Clear_Selected_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
      Id          : constant Diagnostic_Id := Selected_Diagnostic_Id (Diagnostics, Panel);
      Old_Row     : constant Natural := Editor.Feature_Panel.Selected_Row (Panel);
      Removed     : Boolean := False;
      Candidate   : Natural := 0;
      Count       : Natural := 0;
   begin
      Removed := Clear_Diagnostic_By_Id (Diagnostics, Id);
      if not Removed then
         Editor.Feature_Panel.Select_Row (Panel, 0);
         return False;
      end if;

      --  Phase 557 Diagnostics rows project in source/line/column/severity
      --  order, which intentionally differs from storage order.  After
      --  clearing the selected row, reconcile selection by the user's visible
      --  projection position: keep the same visible slot when possible, or
      --  move to the previous visible diagnostic when the deleted row was the
      --  last one.  Do not use Diagnostics storage index here.
      Editor.Feature_Panel.Forget_Feature_View_State
        (Panel, Editor.Feature_Panel.Diagnostics_Feature);
      if Editor.Feature_Panel.Active_Feature (Panel) =
        Editor.Feature_Panel.Diagnostics_Feature
      then
         Project_Rows (Diagnostics, Panel);
         Count := Editor.Feature_Panel.Row_Count (Panel);
         if Count = 0 then
            Editor.Feature_Panel.Select_Row (Panel, 0);
         else
            Candidate := (if Old_Row <= Count then Old_Row else Count);
            while Candidate > 0 loop
               if Editor.Feature_Panel.Row_Is_Selectable (Panel, Positive (Candidate)) then
                  Editor.Feature_Panel.Select_Row (Panel, Candidate);
                  return True;
               end if;
               Candidate := Candidate - 1;
            end loop;
            Editor.Feature_Panel.Select_Row (Panel, 0);
         end if;
      end if;
      Assert_Diagnostics_State_Consistent (Diagnostics);
      return True;
   end Clear_Selected_Diagnostic;

   function Map_Diagnostic_Row_To_Item
     (Diagnostics                    : Diagnostics_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Natural
   is
      Id_Value : Natural := 0;
   begin
      if Editor.Feature_Panel.Active_Feature (Panel) /= Editor.Feature_Panel.Diagnostics_Feature
        or else not Editor.Feature_Panel.Projection_Generation_Matches
          (Panel, Expected_Projection_Generation)
        or else not Editor.Feature_Panel.Projection_Row_Index_Is_Valid (Panel, Row)
        or else not Editor.Feature_Panel.Row_Is_Selectable (Panel, Positive (Row))
      then
         return 0;
      end if;
      Id_Value := Editor.Feature_Panel.Row_Source_Index (Panel, Positive (Row));
      if Id_Value = 0 then
         return 0;
      end if;
      return Index_For_Id (Diagnostics, Diagnostic_Id (Id_Value));
   end Map_Diagnostic_Row_To_Item;

   function Validate_Diagnostic_Target
     (Diagnostics         : Diagnostics_Feature_State;
      Index               : Positive;
      Active_Buffer_Token : Natural) return Boolean
   is
      Item : constant Diagnostic_Item := Item_At (Diagnostics, Index);
   begin
      return Item.Id /= No_Diagnostic
        and then Item.Has_Target
        and then Active_Buffer_Token /= No_Buffer
        and then Item.Target_Buffer = Active_Buffer_Token
        and then Item.Target_Line > 0;
   end Validate_Diagnostic_Target;

   function Validate_Row_Action
     (Diagnostics                    : Diagnostics_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Boolean
   is
   begin
      return Map_Diagnostic_Row_To_Item
        (Diagnostics, Panel, Row, Expected_Projection_Generation) /= 0;
   end Validate_Row_Action;

   procedure Reset_Diagnostics_For_Buffer_Close
     (Diagnostics : in out Diagnostics_Feature_State;
      Buffer_Token : Natural)
   is
      I : Diagnostic_Row_Vectors.Extended_Index := Diagnostics.Rows.First_Index;
   begin
      if Diagnostics.Rows.Is_Empty or else Buffer_Token = No_Buffer then
         return;
      end if;
      while I <= Diagnostics.Rows.Last_Index loop
         if Diagnostics.Rows.Element (I).Target_Buffer = Buffer_Token
         then
            Diagnostics.Rows.Delete (I);
         else
            I := I + 1;
         end if;
      end loop;
      Reset_Exhausted_Projection_Predicates (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Reset_Diagnostics_For_Buffer_Close;

   procedure Reset_Diagnostics_For_Project_Close
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Clear_Diagnostics (Diagnostics);
      Show_All (Diagnostics);
   end Reset_Diagnostics_For_Project_Close;

   procedure Reset_Diagnostics_For_Workspace_Close
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Clear_Diagnostics (Diagnostics);
      Show_All (Diagnostics);
      Diagnostics.Next_Id := 1;
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Reset_Diagnostics_For_Workspace_Close;

   procedure Filter_Errors_Only
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      --  Phase 557 severity filters are direct review modes, not stacked
      --  payloads. Reset source/text/producer predicates first so invoking
      --  "errors only" from a source or build-producer view shows all errors.
      Show_All (Diagnostics);
      Diagnostics.Filter.Show_Info := False;
      Diagnostics.Filter.Show_Notes := False;
      Diagnostics.Filter.Show_Warnings := False;
      Diagnostics.Filter.Show_Errors := True;
      Diagnostics.Filter.Show_Unknown_Severity := False;
      Refresh_Filter_Active (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Filter_Errors_Only;

   procedure Filter_Warnings_Only
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      --  Do not retain source/text/build predicates when entering the
      --  dedicated warnings-only review mode.
      Show_All (Diagnostics);
      Diagnostics.Filter.Show_Info := False;
      Diagnostics.Filter.Show_Notes := False;
      Diagnostics.Filter.Show_Warnings := True;
      Diagnostics.Filter.Show_Errors := False;
      Diagnostics.Filter.Show_Unknown_Severity := False;
      Refresh_Filter_Active (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Filter_Warnings_Only;

   procedure Filter_Info_And_Notes_Only
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      --  Do not retain source/text/build predicates when entering the
      --  dedicated info-and-notes review mode. Unknown diagnostics remain
      --  excluded by this mode.
      Show_All (Diagnostics);
      Diagnostics.Filter.Show_Info := True;
      Diagnostics.Filter.Show_Notes := True;
      Diagnostics.Filter.Show_Warnings := False;
      Diagnostics.Filter.Show_Errors := False;
      Diagnostics.Filter.Show_Unknown_Severity := False;
      Refresh_Filter_Active (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Filter_Info_And_Notes_Only;

   procedure Filter_Build_Produced
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Show_All (Diagnostics);
      Diagnostics.Filter.Build_Only := True;
      Refresh_Filter_Active (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Filter_Build_Produced;

   procedure Filter_Source_Label
     (Diagnostics : in out Diagnostics_Feature_State;
      Source_Text : String)
   is
   begin
      Show_All (Diagnostics);
      Diagnostics.Filter.Text := Null_Unbounded_String;
      Diagnostics.Filter.Source_Text :=
        To_Unbounded_String (Normalize_Diagnostics_Filter_Text (Source_Text));
      Refresh_Filter_Active (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Filter_Source_Label;

   procedure Mark_Diagnostics_For_Buffer_Stale
     (Diagnostics  : in out Diagnostics_Feature_State;
      Buffer_Token : Natural)
   is
   begin
      if Buffer_Token = No_Buffer then
         return;
      end if;

      for I in 1 .. Row_Count (Diagnostics) loop
         declare
            Item : Diagnostic_Item := Diagnostics.Rows.Element (I - 1);
         begin
            if Item.Target_Buffer = Buffer_Token then
               --  Phase 557 stale tracking is based on known target source,
               --  not only fully navigable targets. Partial target rows such
               --  as known-buffer/missing-line diagnostics must also be
               --  marked stale after edits to their source buffer.
               Item.Is_Stale := True;
               Diagnostics.Rows.Replace_Element (I - 1, Item);
            end if;
         end;
      end loop;
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Mark_Diagnostics_For_Buffer_Stale;

   function Normalized_Diagnostic_Path (Path : String) return String
   is
      Result : String (Path'Range);
      Last   : Integer := Path'Last;
   begin
      if Path'Length = 0 then
         return "";
      end if;

      while Last > Path'First
        and then (Path (Last) = '/' or else Path (Last) = Character'Val (16#5C#))
      loop
         Last := Last - 1;
      end loop;

      for I in Path'First .. Last loop
         if Path (I) = Character'Val (16#5C#) then
            Result (I) := '/';
         else
            Result (I) := Path (I);
         end if;
      end loop;

      return Result (Path'First .. Last);
   end Normalized_Diagnostic_Path;

   function Same_Or_Descendant_Diagnostic_Path
     (Path : String;
      Root : String) return Boolean
   is
      P : constant String := Normalized_Diagnostic_Path (Path);
      R : constant String := Normalized_Diagnostic_Path (Root);
   begin
      if P'Length = 0 or else R'Length = 0 then
         return False;
      elsif P = R then
         return True;
      elsif P'Length > R'Length
        and then P (P'First .. P'First + R'Length - 1) = R
        and then P (P'First + R'Length) = '/'
      then
         return True;
      else
         return False;
      end if;
   end Same_Or_Descendant_Diagnostic_Path;

   procedure Mark_Diagnostics_For_Source_Path_Stale
     (Diagnostics : in out Diagnostics_Feature_State;
      Old_Path    : String;
      New_Path    : String := "")
   is
   begin
      if Old_Path'Length = 0 and then New_Path'Length = 0 then
         return;
      end if;

      for I in 1 .. Row_Count (Diagnostics) loop
         declare
            Item   : Diagnostic_Item := Diagnostics.Rows.Element (I - 1);
            Source : constant String := To_String (Item.Source_Label);
         begin
            if Same_Or_Descendant_Diagnostic_Path (Source, Old_Path)
              or else Same_Or_Descendant_Diagnostic_Path (Source, New_Path)
            then
               --  Phase 572: File Tree rename/delete can stale diagnostics
               --  whose only durable association is the displayed source path
               --  rather than the active buffer token.  Mark those rows stale
               --  in the diagnostics owner; do not clear unrelated diagnostics
               --  and do not repair them from render or availability.
               Item.Is_Stale := True;
               Diagnostics.Rows.Replace_Element (I - 1, Item);
            end if;
         end;
      end loop;
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Mark_Diagnostics_For_Source_Path_Stale;

   function Clear_Build_Diagnostics
     (Diagnostics : in out Diagnostics_Feature_State) return Natural
   is
      Removed : Natural := 0;
      I       : Diagnostic_Row_Vectors.Extended_Index := Diagnostics.Rows.First_Index;
   begin
      while I <= Diagnostics.Rows.Last_Index loop
         if Is_Build_Produced_Item (Diagnostics.Rows.Element (I)) then
            Diagnostics.Rows.Delete (I);
            Removed := Removed + 1;
         else
            I := I + 1;
         end if;
      end loop;

      --  Clearing build diagnostics is targeted: it must not remove manual or
      --  external non-build rows.  Drop exhausted source/build projection
      --  predicates only when they can no longer match preserved rows.
      Reset_Exhausted_Projection_Predicates (Diagnostics);

      Assert_Diagnostics_State_Consistent (Diagnostics);
      return Removed;
   end Clear_Build_Diagnostics;

   procedure Reconcile_Diagnostics_After_Filter_Change
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State)
   is
   begin
      Assert_Diagnostics_State_Consistent (Diagnostics);
      if Editor.Feature_Panel.Active_Feature (Panel) = Editor.Feature_Panel.Diagnostics_Feature then
         Project_Rows (Diagnostics, Panel);
      end if;
   end Reconcile_Diagnostics_After_Filter_Change;

   procedure Reconcile_Diagnostics_After_Row_Change
     (Diagnostics     : Diagnostics_Feature_State;
      Panel           : in out Editor.Feature_Panel.Feature_Panel_State;
      Previous_Id     : Diagnostic_Id := No_Diagnostic;
      Previous_Source : Natural := 0)
   is
   begin
      Assert_Diagnostics_State_Consistent (Diagnostics);
      Editor.Feature_Panel.Forget_Feature_View_State
        (Panel, Editor.Feature_Panel.Diagnostics_Feature);
      if Editor.Feature_Panel.Active_Feature (Panel) = Editor.Feature_Panel.Diagnostics_Feature then
         Project_Rows (Diagnostics, Panel);
         if Previous_Id /= No_Diagnostic or else Previous_Source /= 0 then
            Reconcile_Diagnostics_Selection_After_Delete
              (Diagnostics, Panel, Previous_Id, Previous_Source);
         end if;
      end if;
   end Reconcile_Diagnostics_After_Row_Change;

   function Message_Diagnostics_Shown return String is
   begin
      return "Diagnostics shown.";
   end Message_Diagnostics_Shown;

   function Message_Diagnostics_Cleared return String is
   begin
      return "Diagnostics cleared.";
   end Message_Diagnostics_Cleared;

   function Message_No_Diagnostics return String is
   begin
      return "No diagnostics.";
   end Message_No_Diagnostics;

   function Message_No_Target return String is
   begin
      return "Selected diagnostic has no source target.";
   end Message_No_Target;

   function Message_Target_Unavailable return String is
   begin
      return "Diagnostic target file is unavailable.";
   end Message_Target_Unavailable;

   function Message_Diagnostic_Added return String is
   begin
      return "Diagnostic added.";
   end Message_Diagnostic_Added;

   function Message_No_Selected_Diagnostic return String is
   begin
      return "No diagnostic selected";
   end Message_No_Selected_Diagnostic;

   function Message_No_Visible_Diagnostic return String is
   begin
      return "No diagnostics match the current filter.";
   end Message_No_Visible_Diagnostic;

   function Message_Selected_Diagnostic_Cleared return String is
   begin
      return "Selected diagnostic cleared.";
   end Message_Selected_Diagnostic_Cleared;

   function Message_Selected_Diagnostic_Copied return String is
   begin
      return "Selected diagnostic copied.";
   end Message_Selected_Diagnostic_Copied;

   function Message_Info_Cleared return String is
   begin
      return "Diagnostic info/note rows cleared.";
   end Message_Info_Cleared;

   function Message_Warnings_Cleared return String is
   begin
      return "Diagnostics: warnings cleared";
   end Message_Warnings_Cleared;

   function Message_Errors_Cleared return String is
   begin
      return "Diagnostics: errors cleared";
   end Message_Errors_Cleared;

   function Message_Filter_Cleared return String is
   begin
      return "Diagnostics: filter cleared";
   end Message_Filter_Cleared;

   function Message_No_Filter_Active return String is
   begin
      return "No filter is active";
   end Message_No_Filter_Active;

   function Message_All_Diagnostics_Shown return String is
   begin
      return "Diagnostics: all diagnostics shown";
   end Message_All_Diagnostics_Shown;

   function Message_Info_Hidden return String is
   begin
      return "Diagnostics: info hidden";
   end Message_Info_Hidden;

   function Message_Info_Shown return String is
   begin
      return "Diagnostics: info shown";
   end Message_Info_Shown;

   function Message_Warnings_Hidden return String is
   begin
      return "Diagnostics: warnings hidden";
   end Message_Warnings_Hidden;

   function Message_Warnings_Shown return String is
   begin
      return "Diagnostics: warnings shown";
   end Message_Warnings_Shown;

   function Message_Errors_Hidden return String is
   begin
      return "Diagnostics: errors hidden";
   end Message_Errors_Hidden;

   function Message_Errors_Shown return String is
   begin
      return "Diagnostics: errors shown";
   end Message_Errors_Shown;

   function Message_No_Info_Diagnostics return String is
   begin
      return "No info or note diagnostics.";
   end Message_No_Info_Diagnostics;

   function Message_No_Warning_Diagnostics return String is
   begin
      return "No warning diagnostics.";
   end Message_No_Warning_Diagnostics;

   function Message_No_Error_Diagnostics return String is
   begin
      return "No error diagnostics.";
   end Message_No_Error_Diagnostics;

   function Message_No_Build_Diagnostics return String is
   begin
      return "No build diagnostics.";
   end Message_No_Build_Diagnostics;

   function Message_Build_Diagnostics_Cleared return String is
   begin
      return "Diagnostics: build diagnostics cleared";
   end Message_Build_Diagnostics_Cleared;

   function Message_Filter_Errors return String is
   begin
      return "Diagnostics: errors only";
   end Message_Filter_Errors;

   function Message_Filter_Warnings return String is
   begin
      return "Diagnostics: warnings only";
   end Message_Filter_Warnings;

   function Message_Filter_Info_Notes return String is
   begin
      return "Diagnostics: info and notes only";
   end Message_Filter_Info_Notes;

   function Message_Filter_Selected_Source return String is
   begin
      return "Diagnostics: selected source only";
   end Message_Filter_Selected_Source;

   function Message_Filter_Selected_Source_Unavailable return String is
   begin
      return "Selected diagnostic has no source label";
   end Message_Filter_Selected_Source_Unavailable;

   function Message_Filter_Build return String is
   begin
      return "Diagnostics: build producer only";
   end Message_Filter_Build;

   function Message_Source_Hidden
     (Source_Kind : Diagnostic_Source_Kind) return String
   is
   begin
      return "Diagnostics: " & Source_Kind_Label (Source_Kind) & " hidden";
   end Message_Source_Hidden;

   function Message_Source_Shown
     (Source_Kind : Diagnostic_Source_Kind) return String
   is
   begin
      return "Diagnostics: " & Source_Kind_Label (Source_Kind) & " shown";
   end Message_Source_Shown;

end Editor.Feature_Diagnostics;
