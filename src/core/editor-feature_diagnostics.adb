with Ada.Characters.Handling;
with Ada.Containers.Vectors;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Contextual_Help;
with Editor.Feature_Diagnostics.Messages;
with Editor.Feature_Diagnostics.Labels;
with Editor.Feature_Diagnostics.Display;
with Editor.Feature_Diagnostics.Filtering;
with Editor.Feature_Diagnostics.Item_Queries;
with Editor.Feature_Diagnostics.Item_Accessors;
with Editor.Feature_Diagnostics.Selection;
with Editor.Feature_Diagnostics.Maintenance;

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
   use type Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;

   package Item_Accessors_Pkg renames Editor.Feature_Diagnostics.Item_Accessors;
   package Selection_Pkg renames Editor.Feature_Diagnostics.Selection;
   package Maintenance_Pkg renames Editor.Feature_Diagnostics.Maintenance;

   function Severity_Label_For_Display
     (Severity : Diagnostic_Severity) return String
      renames Editor.Feature_Diagnostics.Display.Severity_Label_For_Display;

   function Source_Kind_Label_For_Display
     (Source_Kind : Diagnostic_Source_Kind) return String
      renames Editor.Feature_Diagnostics.Display.Source_Kind_Label_For_Display;

   function Severity_Label (Severity : Diagnostic_Severity) return String
      renames Editor.Feature_Diagnostics.Display.Severity_Label;

   function Source_Kind_Label (Source_Kind : Diagnostic_Source_Kind) return String
      renames Editor.Feature_Diagnostics.Display.Source_Kind_Label;

   function Is_Build_Produced_Item (Item : Diagnostic_Item) return Boolean
      renames Editor.Feature_Diagnostics.Display.Is_Build_Produced_Item;

   function Producer_Label (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Display.Producer_Label;

   function Target_Unavailable_Label (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Display.Target_Unavailable_Label;

   function Source_Filter_Label_For (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Display.Source_Filter_Label_For;

   function Source_Display_Label (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Display.Source_Display_Label;

   function Stale_Label (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Stale_Label;

   function Row_State_Label (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Row_State_Label;

   function Label_For (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Label_For;

   function Detail_For (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Detail_For;

   function Group_Label_For (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Group_Label_For;

   function Diagnostic_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
      renames Editor.Feature_Diagnostics.Filtering.Diagnostic_Is_Visible;

   function Ordered_Visible_Indexes
     (Diagnostics : Diagnostics_Feature_State)
      return Editor.Feature_Diagnostics.Filtering.Visible_Row_Index_Vectors.Vector
      renames Editor.Feature_Diagnostics.Filtering.Ordered_Visible_Indexes;

   function Visible_Row_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
      renames Editor.Feature_Diagnostics.Filtering.Visible_Row_Count;

   function Severity_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Severity    : Diagnostic_Severity) return Boolean
      renames Editor.Feature_Diagnostics.Filtering.Severity_Is_Visible;

   function Source_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Source_Kind : Diagnostic_Source_Kind) return Boolean
      renames Editor.Feature_Diagnostics.Filtering.Source_Is_Visible;

   function Filter_Active
     (Diagnostics : Diagnostics_Feature_State) return Boolean
      renames Editor.Feature_Diagnostics.Filtering.Filter_Active;

   function Filter_Text
     (Diagnostics : Diagnostics_Feature_State) return String
      renames Editor.Feature_Diagnostics.Filtering.Filter_Text;

   procedure Set_Filter_Text
     (Diagnostics : in out Diagnostics_Feature_State;
      Text        : String)
      renames Editor.Feature_Diagnostics.Filtering.Set_Filter_Text;

   procedure Clear_Filter
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Editor.Feature_Diagnostics.Filtering.Clear_Filter;

   procedure Show_All
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Editor.Feature_Diagnostics.Filtering.Show_All;

   procedure Toggle_Info_Visible
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Editor.Feature_Diagnostics.Filtering.Toggle_Info_Visible;

   procedure Toggle_Warnings_Visible
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Editor.Feature_Diagnostics.Filtering.Toggle_Warnings_Visible;

   procedure Toggle_Errors_Visible
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Editor.Feature_Diagnostics.Filtering.Toggle_Errors_Visible;

   procedure Toggle_Source_Visible
     (Diagnostics : in out Diagnostics_Feature_State;
      Source_Kind : Diagnostic_Source_Kind)
      renames Editor.Feature_Diagnostics.Filtering.Toggle_Source_Visible;

   function Count_By_Severity
     (Diagnostics : Diagnostics_Feature_State) return Diagnostics_Severity_Counts
      renames Editor.Feature_Diagnostics.Filtering.Count_By_Severity;

   function Count_Label
     (Counts : Diagnostics_Severity_Counts) return String
      renames Editor.Feature_Diagnostics.Filtering.Count_Label;

   function Visible_Count_Label
     (Counts : Diagnostics_Severity_Counts) return String
      renames Editor.Feature_Diagnostics.Filtering.Visible_Count_Label;

   function Visible_File_Groups
     (Diagnostics : Diagnostics_Feature_State)
      return Diagnostics_File_Group_Vectors.Vector
      renames Editor.Feature_Diagnostics.Filtering.Visible_File_Groups;

   function File_Group_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
      renames Editor.Feature_Diagnostics.Filtering.File_Group_Count;

   function File_Group_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Editor.Feature_Diagnostics.Filtering.File_Group_Label;

   function Header_Text
     (Diagnostics : Diagnostics_Feature_State) return String
      renames Editor.Feature_Diagnostics.Filtering.Header_Text;

   function Has_Visible_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean
      renames Editor.Feature_Diagnostics.Filtering.Has_Visible_Diagnostic;

   function Build_Diagnostic_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
      renames Editor.Feature_Diagnostics.Filtering.Build_Diagnostic_Count;

   function Has_Diagnostic_With_Severity
     (Diagnostics : Diagnostics_Feature_State;
      Severity    : Diagnostic_Severity) return Boolean
      renames Editor.Feature_Diagnostics.Filtering.Has_Diagnostic_With_Severity;

   function Has_Info_Or_Note_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean
      renames Editor.Feature_Diagnostics.Filtering.Has_Info_Or_Note_Diagnostic;

   function Has_Build_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean
      renames Editor.Feature_Diagnostics.Filtering.Has_Build_Diagnostic;

   procedure Filter_Errors_Only
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Editor.Feature_Diagnostics.Filtering.Filter_Errors_Only;

   procedure Filter_Warnings_Only
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Editor.Feature_Diagnostics.Filtering.Filter_Warnings_Only;

   procedure Filter_Info_And_Notes_Only
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Editor.Feature_Diagnostics.Filtering.Filter_Info_And_Notes_Only;

   procedure Filter_Build_Produced
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Editor.Feature_Diagnostics.Filtering.Filter_Build_Produced;

   procedure Filter_Source_Label
     (Diagnostics : in out Diagnostics_Feature_State;
      Source_Text : String)
      renames Editor.Feature_Diagnostics.Filtering.Filter_Source_Label;

   procedure Refresh_Filter_Active
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Editor.Feature_Diagnostics.Display.Refresh_Filter_Active;

   function Normalize_Diagnostics_Filter_Text (Text : String) return String
      renames Editor.Feature_Diagnostics.Display.Normalize_Diagnostics_Filter_Text;

   function Bounded_Text
     (Text        : String;
      Maximum     : Natural;
      Empty_Value : String) return String
      renames Editor.Feature_Diagnostics.Display.Bounded_Text;

   function Normalize_Message (Message : String) return String
      renames Editor.Feature_Diagnostics.Display.Normalize_Message;

   function Normalize_Source_Label (Source_Label : String) return String
      renames Editor.Feature_Diagnostics.Display.Normalize_Source_Label;

   function Normalize_Replacement_Text (Replacement_Text : String) return String
      renames Editor.Feature_Diagnostics.Display.Normalize_Replacement_Text;

   function Normalize_Quick_Fix_Metadata (Text : String) return String
      renames Editor.Feature_Diagnostics.Display.Normalize_Quick_Fix_Metadata;

   function Quick_Fix_Action_Model_For
     (Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
      Has_Edit : Boolean) return Diagnostic_Quick_Fix_Action_Model
      renames Editor.Feature_Diagnostics.Display.Quick_Fix_Action_Model_For;

   function Diagnostic_Action_Kind_Label
     (Kind : Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind)
      return String
      renames Editor.Feature_Diagnostics.Display.Diagnostic_Action_Kind_Label;

   function Panel_Severity
     (Severity : Diagnostic_Severity) return Editor.Feature_Panel.Feature_Row_Severity
      renames Editor.Feature_Diagnostics.Display.Panel_Severity;

   function Item_At
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Item
     renames Editor.Feature_Diagnostics.Item_Queries.Item_At;

   function Contains_Case_Insensitive
     (Haystack : String;
      Needle   : String) return Boolean
     renames Editor.Feature_Diagnostics.Item_Queries.Contains_Case_Insensitive;

   function Diagnostic_Matches_Text_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
     renames Editor.Feature_Diagnostics.Item_Queries.Diagnostic_Matches_Text_Filter;

   function Diagnostic_Matches_Source_Label_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
     renames Editor.Feature_Diagnostics.Item_Queries.Diagnostic_Matches_Source_Label_Filter;

   function Diagnostic_Matches_Severity_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
     renames Editor.Feature_Diagnostics.Item_Queries.Diagnostic_Matches_Severity_Filter;

   function Diagnostic_Matches_Source_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
     renames Editor.Feature_Diagnostics.Item_Queries.Diagnostic_Matches_Source_Filter;

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
            pragma Assert
              (Length (Item.Replacement_Text) <= Max_Diagnostic_Message_Text_Length,
               "diagnostic replacement text must be bounded at ingestion");
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
               --  supplied by a trusted producer.  uses that metadata
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
      --  treats a full clear as returning Diagnostics to the
      --  unfiltered no-diagnostics review state.  Keep this invariant in the
      --  Diagnostics-owned helper as well as the Executor route so direct
      --  lifecycle/test helpers cannot leave hidden filter predicates behind.
      Diagnostics.Rows.Clear;
      Diagnostics.Suppressed_Rows.Clear;
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
      Build_Produced : Boolean := False;
      Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind :=
          Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Navigate_To_Diagnostic;
      Has_Edit : Boolean := False;
      Edit_Start_Line   : Natural := 0;
      Edit_Start_Column : Natural := 0;
      Edit_End_Line     : Natural := 0;
      Edit_End_Column   : Natural := 0;
      Replacement_Text  : String := "";
      Quick_Fix_Label   : String := "";
      Quick_Fix_Detail  : String := "")
   is
      Effective_Target : constant Boolean := Has_Target
        and then Target_Buffer /= No_Buffer
        and then Target_Line > 0;
      Effective_Build_Produced : constant Boolean :=
        Build_Produced and then Source_Kind = External_Diagnostic_Source;
      Effective_Edit : constant Boolean :=
        Has_Edit
        and then Effective_Target
        and then Edit_Start_Line > 0
        and then Edit_Start_Column > 0
        and then Edit_End_Line > 0
        and then Edit_End_Column > 0
        and then
          (Edit_End_Line > Edit_Start_Line
           or else
             (Edit_End_Line = Edit_Start_Line
              and then Edit_End_Column >= Edit_Start_Column));
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
          Is_Build_Produced => Effective_Build_Produced,
          Primary_Action_Kind => Primary_Action_Kind,
          Has_Edit          => Effective_Edit,
          Edit_Start_Line   => (if Effective_Edit then Edit_Start_Line else 0),
          Edit_Start_Column => (if Effective_Edit then Edit_Start_Column else 0),
          Edit_End_Line     => (if Effective_Edit then Edit_End_Line else 0),
          Edit_End_Column   => (if Effective_Edit then Edit_End_Column else 0),
          Replacement_Text  =>
            To_Unbounded_String
              ((if Effective_Edit then Normalize_Replacement_Text (Replacement_Text) else "")),
          Quick_Fix_Label   =>
            To_Unbounded_String
              (Normalize_Quick_Fix_Metadata (Quick_Fix_Label)),
          Quick_Fix_Detail  =>
            To_Unbounded_String
              (Normalize_Quick_Fix_Metadata (Quick_Fix_Detail)),
          Quick_Fix_Action_Count => (if Effective_Edit then 1 else 0),
          Quick_Fix_Actions =>
            (1 =>
               (Model =>
                  Quick_Fix_Action_Model_For
                    (Primary_Action_Kind, Effective_Edit),
                Primary_Action_Kind => Primary_Action_Kind,
                Has_Edit          => Effective_Edit,
                Edit_Start_Line   => (if Effective_Edit then Edit_Start_Line else 0),
                Edit_Start_Column => (if Effective_Edit then Edit_Start_Column else 0),
                Edit_End_Line     => (if Effective_Edit then Edit_End_Line else 0),
                Edit_End_Column   => (if Effective_Edit then Edit_End_Column else 0),
                Replacement_Text  =>
                  To_Unbounded_String
                    ((if Effective_Edit then Normalize_Replacement_Text (Replacement_Text) else "")),
                Label             =>
                  To_Unbounded_String
                    (Normalize_Quick_Fix_Metadata (Quick_Fix_Label)),
                Detail            =>
                  To_Unbounded_String
                    (Normalize_Quick_Fix_Metadata (Quick_Fix_Detail))),
             others => <>)));
      if Diagnostics.Next_Id = Diagnostic_Id'Last then
         Diagnostics.Next_Id := Diagnostic_Id'Last;
      else
         Diagnostics.Next_Id := Diagnostics.Next_Id + 1;
      end if;
      Evict_Old_Diagnostics_If_Needed (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Add_Diagnostic;

   procedure Add_Diagnostic_Command_Descriptor
     (Diagnostics : in out Diagnostics_Feature_State;
      Descriptor  :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Descriptor;
      Source_Label : String := "Ada semantic diagnostics";
      Target_Buffer : Natural := No_Buffer)
   is
      function Map_Severity return Diagnostic_Severity is
      begin
         case Descriptor.Severity is
            when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error =>
               return Diagnostic_Error;
            when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Warning =>
               return Diagnostic_Warning;
            when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info =>
               return Diagnostic_Info;
         end case;
      end Map_Severity;
   begin
      Add_Diagnostic
        (Diagnostics,
         Severity     => Map_Severity,
         Message      => To_String (Descriptor.Diagnostic.Message),
         Source_Label => Source_Label,
         Source_Kind  => Editor_Diagnostic_Source,
         Has_Target   => Target_Buffer /= No_Buffer,
         Target_Buffer => Target_Buffer,
         Target_Line   => Descriptor.Start_Line,
         Target_Column => Descriptor.Start_Column,
         Primary_Action_Kind => Descriptor.Command_Kind,
         Has_Edit          => Descriptor.Has_Edit,
         Edit_Start_Line   => Descriptor.Edit_Start_Line,
         Edit_Start_Column => Descriptor.Edit_Start_Column,
         Edit_End_Line     => Descriptor.Edit_End_Line,
         Edit_End_Column   => Descriptor.Edit_End_Column,
         Replacement_Text  => To_String (Descriptor.Replacement_Text),
         Quick_Fix_Label   => To_String (Descriptor.Display_Label),
         Quick_Fix_Detail  => To_String (Descriptor.Detail));
   end Add_Diagnostic_Command_Descriptor;

   procedure Append_Diagnostic_Quick_Fix_Internal
     (Diagnostics : in out Diagnostics_Feature_State;
      Index       : Positive;
      Label       : String;
      Detail      : String := "";
      Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind :=
          Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic;
      Has_Edit : Boolean := False;
      Edit_Start_Line   : Natural := 0;
      Edit_Start_Column : Natural := 0;
      Edit_End_Line     : Natural := 0;
      Edit_End_Column   : Natural := 0;
      Replacement_Text  : String := "")
   is
      Item : Diagnostic_Item := Item_At (Diagnostics, Index);
      Effective_Edit : constant Boolean :=
        Has_Edit
        and then Item.Has_Target
        and then Edit_Start_Line > 0
        and then Edit_Start_Column > 0
        and then Edit_End_Line > 0
        and then Edit_End_Column > 0
        and then
          (Edit_End_Line > Edit_Start_Line
           or else
             (Edit_End_Line = Edit_Start_Line
              and then Edit_End_Column >= Edit_Start_Column));
      Next : constant Natural := Item.Quick_Fix_Action_Count + 1;
   begin
      if Next > Max_Quick_Fix_Actions_Per_Diagnostic then
         return;
      end if;

      Item.Quick_Fix_Actions (Next) :=
        (Model =>
           Quick_Fix_Action_Model_For (Primary_Action_Kind, Effective_Edit),
         Primary_Action_Kind => Primary_Action_Kind,
         Has_Edit          => Effective_Edit,
         Edit_Start_Line   => (if Effective_Edit then Edit_Start_Line else 0),
         Edit_Start_Column => (if Effective_Edit then Edit_Start_Column else 0),
         Edit_End_Line     => (if Effective_Edit then Edit_End_Line else 0),
         Edit_End_Column   => (if Effective_Edit then Edit_End_Column else 0),
         Replacement_Text  =>
           To_Unbounded_String
             ((if Effective_Edit then Normalize_Replacement_Text (Replacement_Text) else "")),
         Label             =>
           To_Unbounded_String (Normalize_Quick_Fix_Metadata (Label)),
         Detail            =>
           To_Unbounded_String (Normalize_Quick_Fix_Metadata (Detail)));
      Item.Quick_Fix_Action_Count := Next;

      if Length (Item.Quick_Fix_Label) = 0 then
         Item.Quick_Fix_Label := Item.Quick_Fix_Actions (Next).Label;
      end if;
      if Length (Item.Quick_Fix_Detail) = 0 then
         Item.Quick_Fix_Detail := Item.Quick_Fix_Actions (Next).Detail;
      end if;

      Diagnostics.Rows.Replace_Element (Index - 1, Item);
      Assert_Diagnostics_State_Consistent (Diagnostics);
   end Append_Diagnostic_Quick_Fix_Internal;

   procedure Append_Diagnostic_Quick_Fix_Command
     (Diagnostics : in out Diagnostics_Feature_State;
      Index       : Positive;
      Label       : String;
      Detail      : String := "";
      Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind)
   is
   begin
      Append_Diagnostic_Quick_Fix_Internal
        (Diagnostics,
         Index => Index,
         Label => Label,
         Detail => Detail,
         Primary_Action_Kind => Primary_Action_Kind);
   end Append_Diagnostic_Quick_Fix_Command;

   procedure Append_Diagnostic_Quick_Fix_Edit
     (Diagnostics : in out Diagnostics_Feature_State;
      Index       : Positive;
      Label       : String;
      Detail      : String := "";
      Edit_Start_Line   : Natural;
      Edit_Start_Column : Natural;
      Edit_End_Line     : Natural;
      Edit_End_Column   : Natural;
      Replacement_Text  : String := "")
   is
   begin
      Append_Diagnostic_Quick_Fix_Internal
        (Diagnostics,
         Index => Index,
         Label => Label,
         Detail => Detail,
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_None,
         Has_Edit => True,
         Edit_Start_Line => Edit_Start_Line,
         Edit_Start_Column => Edit_Start_Column,
         Edit_End_Line => Edit_End_Line,
         Edit_End_Column => Edit_End_Column,
         Replacement_Text => Replacement_Text);
   end Append_Diagnostic_Quick_Fix_Edit;

   procedure Append_Diagnostic_Quick_Fix_Edit_And_Command
     (Diagnostics : in out Diagnostics_Feature_State;
      Index       : Positive;
      Label       : String;
      Detail      : String := "";
      Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
      Edit_Start_Line   : Natural;
      Edit_Start_Column : Natural;
      Edit_End_Line     : Natural;
      Edit_End_Column   : Natural;
      Replacement_Text  : String := "")
   is
   begin
      Append_Diagnostic_Quick_Fix_Internal
        (Diagnostics,
         Index => Index,
         Label => Label,
         Detail => Detail,
         Primary_Action_Kind => Primary_Action_Kind,
         Has_Edit => True,
         Edit_Start_Line => Edit_Start_Line,
         Edit_Start_Column => Edit_Start_Column,
         Edit_End_Line => Edit_End_Line,
         Edit_End_Column => Edit_End_Column,
         Replacement_Text => Replacement_Text);
   end Append_Diagnostic_Quick_Fix_Edit_And_Command;

   procedure Append_Diagnostic_Quick_Fix_Unavailable
     (Diagnostics : in out Diagnostics_Feature_State;
      Index       : Positive;
      Label       : String;
      Detail      : String := "")
   is
   begin
      Append_Diagnostic_Quick_Fix_Internal
        (Diagnostics,
         Index => Index,
         Label => Label,
         Detail => Detail,
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_None);
   end Append_Diagnostic_Quick_Fix_Unavailable;

   function Row_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
      renames Item_Accessors_Pkg.Row_Count;

   function Is_Empty
     (Diagnostics : Diagnostics_Feature_State) return Boolean
      renames Item_Accessors_Pkg.Is_Empty;

   function Item_Id
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Id
      renames Item_Accessors_Pkg.Item_Id;

   function Item_Severity
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Severity
      renames Item_Accessors_Pkg.Item_Severity;

   function Item_Message
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Item_Accessors_Pkg.Item_Message;

   function Diagnostic_Message_Text_Is_Bounded
     (Diagnostics : Diagnostics_Feature_State) return Boolean
      renames Item_Accessors_Pkg.Diagnostic_Message_Text_Is_Bounded;

   function Diagnostic_Source_Label_Text_Is_Bounded
     (Diagnostics : Diagnostics_Feature_State) return Boolean
      renames Item_Accessors_Pkg.Diagnostic_Source_Label_Text_Is_Bounded;

   function Item_Source_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Item_Accessors_Pkg.Item_Source_Label;

   function Item_Source_Kind
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Source_Kind
      renames Item_Accessors_Pkg.Item_Source_Kind;

   function Item_Display_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Item_Accessors_Pkg.Item_Display_Label;


   function Producer_Label_For_Display
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Item_Accessors_Pkg.Producer_Label_For_Display;

   function Item_Source_Display_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Item_Accessors_Pkg.Item_Source_Display_Label;

   function Item_Target_Unavailable_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Item_Accessors_Pkg.Item_Target_Unavailable_Label;

   function Item_Row_State_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Item_Accessors_Pkg.Item_Row_State_Label;

   function Item_Is_Stale
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean
      renames Item_Accessors_Pkg.Item_Is_Stale;

   function Item_Stale_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Item_Accessors_Pkg.Item_Stale_Label;

   function Item_Is_Build_Produced
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean
      renames Item_Accessors_Pkg.Item_Is_Build_Produced;

   function Item_Primary_Action_Kind
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive)
      return Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind
      renames Item_Accessors_Pkg.Item_Primary_Action_Kind;

   function Item_Has_Edit
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean
      renames Item_Accessors_Pkg.Item_Has_Edit;

   function Item_Edit_Start_Line
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
      renames Item_Accessors_Pkg.Item_Edit_Start_Line;

   function Item_Edit_Start_Column
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
      renames Item_Accessors_Pkg.Item_Edit_Start_Column;

   function Item_Edit_End_Line
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
      renames Item_Accessors_Pkg.Item_Edit_End_Line;

   function Item_Edit_End_Column
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
      renames Item_Accessors_Pkg.Item_Edit_End_Column;

   function Item_Replacement_Text
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Item_Accessors_Pkg.Item_Replacement_Text;

   function Item_Quick_Fix_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Item_Accessors_Pkg.Item_Quick_Fix_Label;

   function Item_Quick_Fix_Detail
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Item_Accessors_Pkg.Item_Quick_Fix_Detail;

   function Item_Quick_Fix_Action_Count
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
      renames Item_Accessors_Pkg.Item_Quick_Fix_Action_Count;

   function Item_Quick_Fix_Action_Label_For_Display
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return String
      renames Item_Accessors_Pkg.Item_Quick_Fix_Action_Label_For_Display;

   function Item_Quick_Fix_Action_Detail_For_Display
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return String
      renames Item_Accessors_Pkg.Item_Quick_Fix_Action_Detail_For_Display;

   function Quick_Fix_Action_At
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Diagnostic_Quick_Fix_Action
   is
      Item : constant Diagnostic_Item := Item_At (Diagnostics, Index);
   begin
      if Action_Index > Item.Quick_Fix_Action_Count
        or else Action_Index > Max_Quick_Fix_Actions_Per_Diagnostic
      then
         return (others => <>);
      end if;
      return Item.Quick_Fix_Actions (Action_Index);
   end Quick_Fix_Action_At;

   function Item_Quick_Fix_Action_Kind
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive)
      return Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind
   is
   begin
      return Quick_Fix_Action_At
        (Diagnostics, Index, Action_Index).Primary_Action_Kind;
   end Item_Quick_Fix_Action_Kind;

   function Item_Quick_Fix_Action_Model
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Diagnostic_Quick_Fix_Action_Model
   is
   begin
      return Quick_Fix_Action_At
        (Diagnostics, Index, Action_Index).Model;
   end Item_Quick_Fix_Action_Model;

   function Item_Quick_Fix_Action_Has_Edit
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Boolean
   is
   begin
      return Quick_Fix_Action_At
        (Diagnostics, Index, Action_Index).Has_Edit;
   end Item_Quick_Fix_Action_Has_Edit;

   function Item_Quick_Fix_Action_Edit_Start_Line
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Natural
   is
   begin
      return Quick_Fix_Action_At
        (Diagnostics, Index, Action_Index).Edit_Start_Line;
   end Item_Quick_Fix_Action_Edit_Start_Line;

   function Item_Quick_Fix_Action_Edit_Start_Column
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Natural
   is
   begin
      return Quick_Fix_Action_At
        (Diagnostics, Index, Action_Index).Edit_Start_Column;
   end Item_Quick_Fix_Action_Edit_Start_Column;

   function Item_Quick_Fix_Action_Edit_End_Line
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Natural
   is
   begin
      return Quick_Fix_Action_At
        (Diagnostics, Index, Action_Index).Edit_End_Line;
   end Item_Quick_Fix_Action_Edit_End_Line;

   function Item_Quick_Fix_Action_Edit_End_Column
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Natural
   is
   begin
      return Quick_Fix_Action_At
        (Diagnostics, Index, Action_Index).Edit_End_Column;
   end Item_Quick_Fix_Action_Edit_End_Column;

   function Item_Quick_Fix_Action_Replacement_Text
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return String
   is
   begin
      return To_String
        (Quick_Fix_Action_At
           (Diagnostics, Index, Action_Index).Replacement_Text);
   end Item_Quick_Fix_Action_Replacement_Text;

   function Quick_Fix_Action_Is_Intrinsically_Available
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Natural) return Boolean
   is
      Count : constant Natural :=
        Item_Quick_Fix_Action_Count (Diagnostics, Index);
   begin
      if Action_Index = 0 or else Action_Index > Count then
         return False;
      end if;

      return Item_Quick_Fix_Action_Model
          (Diagnostics, Index, Positive (Action_Index)) /=
        Quick_Fix_Action_Unavailable;
   end Quick_Fix_Action_Is_Intrinsically_Available;

   function Quick_Fix_Action_Intrinsic_Unavailable_Reason
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Natural) return String
   is
      Count : constant Natural :=
        Item_Quick_Fix_Action_Count (Diagnostics, Index);
   begin
      if Count = 0 then
         return "Selected diagnostic has no quick fix";
      elsif Action_Index = 0 or else Action_Index > Count then
         return "Quick fix action unavailable";
      elsif not Quick_Fix_Action_Is_Intrinsically_Available
        (Diagnostics, Index, Action_Index)
      then
         return "Quick fix action has no valid edit or command";
      else
         return "";
      end if;
   end Quick_Fix_Action_Intrinsic_Unavailable_Reason;

   function Item_Quick_Fix_Label_For_Display
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
   begin
      if Item_Quick_Fix_Action_Count (Diagnostics, Index) > 0 then
         return Item_Quick_Fix_Action_Label_For_Display (Diagnostics, Index, 1);
      end if;
      return "Apply quick fix";
   end Item_Quick_Fix_Label_For_Display;

   function Item_Quick_Fix_Detail_For_Display
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
   begin
      if Item_Quick_Fix_Action_Count (Diagnostics, Index) > 0 then
         return Item_Quick_Fix_Action_Detail_For_Display (Diagnostics, Index, 1);
      end if;
      return "Selected diagnostic has no quick fix";
   end Item_Quick_Fix_Detail_For_Display;

   procedure Project_Rows
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State)
      renames Selection_Pkg.Project_Rows;

   function Index_For_Id
     (Diagnostics : Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Natural
      renames Selection_Pkg.Index_For_Id;

   function Selected_Diagnostic_Source_Index
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Natural
      renames Selection_Pkg.Selected_Diagnostic_Source_Index;

   function Has_Selected_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Boolean
      renames Selection_Pkg.Has_Selected_Diagnostic;

   function Selected_Diagnostic_Id
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Diagnostic_Id
      renames Selection_Pkg.Selected_Diagnostic_Id;

   function Selected_Diagnostic_Has_Target
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Boolean
      renames Selection_Pkg.Selected_Diagnostic_Has_Target;

   function Selected_Diagnostic_Target_Unavailable_Label
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String
      renames Selection_Pkg.Selected_Diagnostic_Target_Unavailable_Label;

   function Selected_Diagnostic_Open_Unavailable_Reason
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String
      renames Selection_Pkg.Selected_Diagnostic_Open_Unavailable_Reason;

   function Format_Diagnostic_For_Copy
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
      renames Selection_Pkg.Format_Diagnostic_For_Copy;

   function Selected_Diagnostic_Text
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String
      renames Selection_Pkg.Selected_Diagnostic_Text;

   function Selected_Diagnostic_Source_Filter_Label
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String
      renames Selection_Pkg.Selected_Diagnostic_Source_Filter_Label;

   function Row_Is_Live_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State;
      Row         : Natural) return Boolean
      renames Selection_Pkg.Row_Is_Live_Diagnostic;

   procedure Select_Next_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State)
      renames Selection_Pkg.Select_Next_Diagnostic;

   procedure Select_Previous_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State)
      renames Selection_Pkg.Select_Previous_Diagnostic;

   function Next_Diagnostic_Id
     (Diagnostics : Diagnostics_Feature_State) return Diagnostic_Id
      renames Selection_Pkg.Next_Diagnostic_Id;

   function Item_Has_Target
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean
      renames Selection_Pkg.Item_Has_Target;

   function Item_Target_Buffer
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
      renames Selection_Pkg.Item_Target_Buffer;

   function Item_Target_Line
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
      renames Selection_Pkg.Item_Target_Line;

   function Item_Target_Column
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
      renames Selection_Pkg.Item_Target_Column;

   function Map_Diagnostic_Id_To_Item
     (Diagnostics : Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Natural
      renames Selection_Pkg.Map_Diagnostic_Id_To_Item;

   function Diagnostic_Id_Is_Live
     (Diagnostics : Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Boolean
      renames Selection_Pkg.Diagnostic_Id_Is_Live;

   function Validate_Diagnostic_Id_Target
     (Diagnostics         : Diagnostics_Feature_State;
      Id                  : Diagnostic_Id;
      Active_Buffer_Token : Natural) return Boolean
      renames Maintenance_Pkg.Validate_Diagnostic_Id_Target;

   procedure Reset_Exhausted_Projection_Predicates
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Maintenance_Pkg.Reset_Exhausted_Projection_Predicates;

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

   function Clear_Diagnostics_By_Source_And_Label
     (Diagnostics  : in out Diagnostics_Feature_State;
      Source_Kind  : Diagnostic_Source_Kind;
      Source_Label : String) return Natural
   is
      Normalized_Label : constant String := Normalize_Source_Label (Source_Label);
      Removed : Natural := 0;
      I       : Diagnostic_Row_Vectors.Extended_Index := Diagnostics.Rows.First_Index;
   begin
      while I <= Diagnostics.Rows.Last_Index loop
         declare
            Item : constant Diagnostic_Item := Diagnostics.Rows.Element (I);
         begin
            if Item.Source_Kind = Source_Kind
              and then To_String (Item.Source_Label) = Normalized_Label
            then
               Diagnostics.Rows.Delete (I);
               Removed := Removed + 1;
            else
               I := I + 1;
            end if;
         end;
      end loop;
      Reset_Exhausted_Projection_Predicates (Diagnostics);
      Assert_Diagnostics_State_Consistent (Diagnostics);
      return Removed;
   end Clear_Diagnostics_By_Source_And_Label;

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

      --  Diagnostics rows project in source/line/column/severity
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

   function Suppress_Selected_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
      Source : constant Natural := Selected_Diagnostic_Source_Index (Diagnostics, Panel);
      Item   : Diagnostic_Item;
   begin
      if Source = 0 then
         Editor.Feature_Panel.Select_Row (Panel, 0);
         return False;
      end if;

      Item := Item_At (Diagnostics, Positive (Source));
      if not Clear_Selected_Diagnostic (Diagnostics, Panel) then
         return False;
      end if;

      Diagnostics.Suppressed_Rows.Append (Item);
      Diagnostics.Selected_Suppressed_Row := Natural (Diagnostics.Suppressed_Rows.Length);
      Diagnostics.Suppressed_Top_Row := Natural'Max (1, Diagnostics.Selected_Suppressed_Row);
      Assert_Diagnostics_State_Consistent (Diagnostics);
      return True;
   end Suppress_Selected_Diagnostic;

   procedure Clamp_Suppressed_Top_Row
     (Diagnostics   : in out Diagnostics_Feature_State;
      Visible_Count : Natural)
   is
      Count : constant Natural := Natural (Diagnostics.Suppressed_Rows.Length);
      Max_Top : Natural := 1;
   begin
      if Count = 0 then
         Diagnostics.Suppressed_Top_Row := 1;
         return;
      end if;

      if Visible_Count = 0 then
         Max_Top := Count;
      elsif Count <= Visible_Count then
         Max_Top := 1;
      else
         Max_Top := Count - Visible_Count + 1;
      end if;

      if Diagnostics.Suppressed_Top_Row < 1 then
         Diagnostics.Suppressed_Top_Row := 1;
      elsif Diagnostics.Suppressed_Top_Row > Max_Top then
         Diagnostics.Suppressed_Top_Row := Max_Top;
      end if;
   end Clamp_Suppressed_Top_Row;

   function Restore_Suppressed_Diagnostic_At
     (Diagnostics : in out Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State;
      Row         : Positive) return Boolean
   is
      Item : Diagnostic_Item;
   begin
      if Diagnostics.Suppressed_Rows.Is_Empty
        or else Row > Natural (Diagnostics.Suppressed_Rows.Length)
      then
         return False;
      end if;

      declare
         Index : constant Natural := Row - 1;
      begin
         Item := Diagnostics.Suppressed_Rows.Element (Index);
         Diagnostics.Suppressed_Rows.Delete (Index);
      end;

      if Diagnostics.Suppressed_Rows.Is_Empty then
         Diagnostics.Selected_Suppressed_Row := 0;
         Diagnostics.Suppressed_Top_Row := 1;
      elsif Diagnostics.Selected_Suppressed_Row > Natural (Diagnostics.Suppressed_Rows.Length) then
         Diagnostics.Selected_Suppressed_Row := Natural (Diagnostics.Suppressed_Rows.Length);
      end if;
      Clamp_Suppressed_Top_Row (Diagnostics, 0);

      if Index_For_Id (Diagnostics, Item.Id) = 0 then
         Diagnostics.Rows.Append (Item);
      end if;

      Reset_Exhausted_Projection_Predicates (Diagnostics);
      Reconcile_Diagnostics_After_Row_Change
        (Diagnostics, Panel, Previous_Id => Item.Id);
      Assert_Diagnostics_State_Consistent (Diagnostics);
      return True;
   end Restore_Suppressed_Diagnostic_At;

   function Restore_Last_Suppressed_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
   begin
      if Diagnostics.Suppressed_Rows.Is_Empty then
         return False;
      end if;

      return Restore_Suppressed_Diagnostic_At
        (Diagnostics, Panel, Natural (Diagnostics.Suppressed_Rows.Length));
   end Restore_Last_Suppressed_Diagnostic;

   function Restore_Selected_Suppressed_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
      Selected : constant Natural := Selected_Suppressed_Diagnostic (Diagnostics);
   begin
      if Selected = 0 then
         return False;
      end if;

      return Restore_Suppressed_Diagnostic_At (Diagnostics, Panel, Positive (Selected));
   end Restore_Selected_Suppressed_Diagnostic;

   function Clear_Suppressed_Diagnostics
     (Diagnostics : in out Diagnostics_Feature_State) return Natural
   is
      Count : constant Natural := Natural (Diagnostics.Suppressed_Rows.Length);
   begin
      Diagnostics.Suppressed_Rows.Clear;
      Diagnostics.Selected_Suppressed_Row := 0;
      Diagnostics.Suppressed_Top_Row := 1;
      Assert_Diagnostics_State_Consistent (Diagnostics);
      return Count;
   end Clear_Suppressed_Diagnostics;

   function Suppressed_Diagnostic_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
   is
   begin
      return Natural (Diagnostics.Suppressed_Rows.Length);
   end Suppressed_Diagnostic_Count;

   function Selected_Suppressed_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Natural
   is
   begin
      if Diagnostics.Suppressed_Rows.Is_Empty
        or else Diagnostics.Selected_Suppressed_Row = 0
      then
         return 0;
      elsif Diagnostics.Selected_Suppressed_Row > Natural (Diagnostics.Suppressed_Rows.Length) then
         return Natural (Diagnostics.Suppressed_Rows.Length);
      else
         return Diagnostics.Selected_Suppressed_Row;
      end if;
   end Selected_Suppressed_Diagnostic;

   function Suppressed_Top_Row
     (Diagnostics    : Diagnostics_Feature_State;
      Visible_Count  : Natural) return Natural
   is
      Count : constant Natural := Natural (Diagnostics.Suppressed_Rows.Length);
   begin
      if Count = 0 then
         return 1;
      elsif Visible_Count = 0 then
         return Natural'Min (Count, Natural'Max (1, Diagnostics.Suppressed_Top_Row));
      elsif Count <= Visible_Count then
         return 1;
      elsif Diagnostics.Suppressed_Top_Row > Count - Visible_Count + 1 then
         return Count - Visible_Count + 1;
      elsif Diagnostics.Suppressed_Top_Row < 1 then
         return 1;
      else
         return Diagnostics.Suppressed_Top_Row;
      end if;
   end Suppressed_Top_Row;

   procedure Ensure_Selected_Suppressed_Diagnostic_Visible
     (Diagnostics    : in out Diagnostics_Feature_State;
      Visible_Count  : Natural)
   is
      Selected : constant Natural := Selected_Suppressed_Diagnostic (Diagnostics);
   begin
      if Visible_Count = 0 or else Selected = 0 then
         Clamp_Suppressed_Top_Row (Diagnostics, Visible_Count);
         return;
      end if;

      if Selected < Diagnostics.Suppressed_Top_Row then
         Diagnostics.Suppressed_Top_Row := Selected;
      elsif Selected >= Diagnostics.Suppressed_Top_Row + Visible_Count then
         Diagnostics.Suppressed_Top_Row := Selected - Visible_Count + 1;
      end if;
      Clamp_Suppressed_Top_Row (Diagnostics, Visible_Count);
   end Ensure_Selected_Suppressed_Diagnostic_Visible;

   procedure Scroll_Suppressed_Diagnostics
     (Diagnostics    : in out Diagnostics_Feature_State;
      Visible_Count  : Natural;
      Delta_Rows     : Integer)
   is
      Current : constant Integer :=
        Integer (Suppressed_Top_Row (Diagnostics, Visible_Count));
      Desired : Integer := Current + Delta_Rows;
   begin
      if Desired < 1 then
         Desired := 1;
      end if;
      Diagnostics.Suppressed_Top_Row := Natural (Desired);
      Clamp_Suppressed_Top_Row (Diagnostics, Visible_Count);
   end Scroll_Suppressed_Diagnostics;

   procedure Select_Suppressed_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State;
      Row         : Natural)
   is
      Count : constant Natural := Natural (Diagnostics.Suppressed_Rows.Length);
   begin
      if Count = 0 or else Row = 0 then
         Diagnostics.Selected_Suppressed_Row := 0;
      elsif Row > Count then
         Diagnostics.Selected_Suppressed_Row := Count;
      else
         Diagnostics.Selected_Suppressed_Row := Row;
      end if;
      Ensure_Selected_Suppressed_Diagnostic_Visible (Diagnostics, 0);
   end Select_Suppressed_Diagnostic;

   procedure Select_Next_Suppressed_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State)
   is
      Count : constant Natural := Natural (Diagnostics.Suppressed_Rows.Length);
      Current : constant Natural := Selected_Suppressed_Diagnostic (Diagnostics);
   begin
      if Count = 0 then
         Diagnostics.Selected_Suppressed_Row := 0;
      elsif Current = 0 or else Current >= Count then
         Diagnostics.Selected_Suppressed_Row := 1;
      else
         Diagnostics.Selected_Suppressed_Row := Current + 1;
      end if;
      Ensure_Selected_Suppressed_Diagnostic_Visible (Diagnostics, 0);
   end Select_Next_Suppressed_Diagnostic;

   procedure Select_Previous_Suppressed_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State)
   is
      Count : constant Natural := Natural (Diagnostics.Suppressed_Rows.Length);
      Current : constant Natural := Selected_Suppressed_Diagnostic (Diagnostics);
   begin
      if Count = 0 then
         Diagnostics.Selected_Suppressed_Row := 0;
      elsif Current <= 1 then
         Diagnostics.Selected_Suppressed_Row := Count;
      else
         Diagnostics.Selected_Suppressed_Row := Current - 1;
      end if;
      Ensure_Selected_Suppressed_Diagnostic_Visible (Diagnostics, 0);
   end Select_Previous_Suppressed_Diagnostic;

   function Suppressed_Diagnostic_Text
     (Diagnostics : Diagnostics_Feature_State;
      Row         : Positive) return String
   is
   begin
      if Diagnostics.Suppressed_Rows.Is_Empty
        or else Row > Natural (Diagnostics.Suppressed_Rows.Length)
      then
         return "";
      else
         return Label_For (Diagnostics.Suppressed_Rows.Element (Row - 1));
      end if;
   end Suppressed_Diagnostic_Text;

   function Last_Suppressed_Diagnostic_Text
     (Diagnostics : Diagnostics_Feature_State) return String
   is
   begin
      if Diagnostics.Suppressed_Rows.Is_Empty then
         return "";
      else
         return Label_For
           (Diagnostics.Suppressed_Rows.Element
              (Diagnostics.Suppressed_Rows.Last_Index));
      end if;
   end Last_Suppressed_Diagnostic_Text;

   function Map_Diagnostic_Row_To_Item
     (Diagnostics                    : Diagnostics_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Natural
      renames Maintenance_Pkg.Map_Diagnostic_Row_To_Item;

   function Validate_Diagnostic_Target
     (Diagnostics         : Diagnostics_Feature_State;
      Index               : Positive;
      Active_Buffer_Token : Natural) return Boolean
      renames Maintenance_Pkg.Validate_Diagnostic_Target;

   function Validate_Row_Action
     (Diagnostics                    : Diagnostics_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Boolean
      renames Maintenance_Pkg.Validate_Row_Action;

   procedure Reset_Diagnostics_For_Buffer_Close
     (Diagnostics : in out Diagnostics_Feature_State;
      Buffer_Token : Natural)
      renames Maintenance_Pkg.Reset_Diagnostics_For_Buffer_Close;

   procedure Reset_Diagnostics_For_Project_Close
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Maintenance_Pkg.Reset_Diagnostics_For_Project_Close;

   procedure Reset_Diagnostics_For_Workspace_Close
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Maintenance_Pkg.Reset_Diagnostics_For_Workspace_Close;

   procedure Mark_Diagnostics_For_Buffer_Stale
     (Diagnostics  : in out Diagnostics_Feature_State;
      Buffer_Token : Natural)
      renames Maintenance_Pkg.Mark_Diagnostics_For_Buffer_Stale;

   procedure Mark_Diagnostics_For_Source_Path_Stale
     (Diagnostics : in out Diagnostics_Feature_State;
      Old_Path    : String;
      New_Path    : String := "")
      renames Maintenance_Pkg.Mark_Diagnostics_For_Source_Path_Stale;

   function Clear_Build_Diagnostics
     (Diagnostics : in out Diagnostics_Feature_State) return Natural
      renames Maintenance_Pkg.Clear_Build_Diagnostics;

   procedure Reconcile_Diagnostics_After_Filter_Change
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State)
      renames Maintenance_Pkg.Reconcile_Diagnostics_After_Filter_Change;

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

   function Message_Diagnostics_Shown return String
      renames Editor.Feature_Diagnostics.Messages.Message_Diagnostics_Shown;

   function Message_Diagnostics_Cleared return String
      renames Editor.Feature_Diagnostics.Messages.Message_Diagnostics_Cleared;

   function Message_No_Diagnostics return String
      renames Editor.Feature_Diagnostics.Messages.Message_No_Diagnostics;

   function Message_No_Target return String
      renames Editor.Feature_Diagnostics.Messages.Message_No_Target;

   function Message_Target_Unavailable return String
      renames Editor.Feature_Diagnostics.Messages.Message_Target_Unavailable;

   function Message_Diagnostic_Added return String
      renames Editor.Feature_Diagnostics.Messages.Message_Diagnostic_Added;

   function Message_No_Selected_Diagnostic return String
      renames Editor.Feature_Diagnostics.Messages.Message_No_Selected_Diagnostic;

   function Message_No_Visible_Diagnostic return String
      renames Editor.Feature_Diagnostics.Messages.Message_No_Visible_Diagnostic;

   function Message_Selected_Diagnostic_Cleared return String
      renames Editor.Feature_Diagnostics.Messages.Message_Selected_Diagnostic_Cleared;

   function Message_Selected_Diagnostic_Copied return String
      renames Editor.Feature_Diagnostics.Messages.Message_Selected_Diagnostic_Copied;

   function Message_Info_Cleared return String
      renames Editor.Feature_Diagnostics.Messages.Message_Info_Cleared;

   function Message_Warnings_Cleared return String
      renames Editor.Feature_Diagnostics.Messages.Message_Warnings_Cleared;

   function Message_Errors_Cleared return String
      renames Editor.Feature_Diagnostics.Messages.Message_Errors_Cleared;

   function Message_Filter_Cleared return String
      renames Editor.Feature_Diagnostics.Messages.Message_Filter_Cleared;

   function Message_No_Filter_Active return String
      renames Editor.Feature_Diagnostics.Messages.Message_No_Filter_Active;

   function Message_All_Diagnostics_Shown return String
      renames Editor.Feature_Diagnostics.Messages.Message_All_Diagnostics_Shown;

   function Message_Info_Hidden return String
      renames Editor.Feature_Diagnostics.Messages.Message_Info_Hidden;

   function Message_Info_Shown return String
      renames Editor.Feature_Diagnostics.Messages.Message_Info_Shown;

   function Message_Warnings_Hidden return String
      renames Editor.Feature_Diagnostics.Messages.Message_Warnings_Hidden;

   function Message_Warnings_Shown return String
      renames Editor.Feature_Diagnostics.Messages.Message_Warnings_Shown;

   function Message_Errors_Hidden return String
      renames Editor.Feature_Diagnostics.Messages.Message_Errors_Hidden;

   function Message_Errors_Shown return String
      renames Editor.Feature_Diagnostics.Messages.Message_Errors_Shown;

   function Message_No_Info_Diagnostics return String
      renames Editor.Feature_Diagnostics.Messages.Message_No_Info_Diagnostics;

   function Message_No_Warning_Diagnostics return String
      renames Editor.Feature_Diagnostics.Messages.Message_No_Warning_Diagnostics;

   function Message_No_Error_Diagnostics return String
      renames Editor.Feature_Diagnostics.Messages.Message_No_Error_Diagnostics;

   function Message_No_Build_Diagnostics return String
      renames Editor.Feature_Diagnostics.Messages.Message_No_Build_Diagnostics;

   function Message_Build_Diagnostics_Cleared return String
      renames Editor.Feature_Diagnostics.Messages.Message_Build_Diagnostics_Cleared;

   function Message_Filter_Errors return String
      renames Editor.Feature_Diagnostics.Messages.Message_Filter_Errors;

   function Message_Filter_Warnings return String
      renames Editor.Feature_Diagnostics.Messages.Message_Filter_Warnings;

   function Message_Filter_Info_Notes return String
      renames Editor.Feature_Diagnostics.Messages.Message_Filter_Info_Notes;

   function Message_Filter_Selected_Source return String
      renames Editor.Feature_Diagnostics.Messages.Message_Filter_Selected_Source;

   function Message_Filter_Selected_Source_Unavailable return String
      renames Editor.Feature_Diagnostics.Messages.Message_Filter_Selected_Source_Unavailable;

   function Message_Filter_Build return String
      renames Editor.Feature_Diagnostics.Messages.Message_Filter_Build;

   function Message_Source_Hidden
     (Source_Kind : Diagnostic_Source_Kind) return String
      renames Editor.Feature_Diagnostics.Messages.Message_Source_Hidden;

   function Message_Source_Shown
     (Source_Kind : Diagnostic_Source_Kind) return String
      renames Editor.Feature_Diagnostics.Messages.Message_Source_Shown;

end Editor.Feature_Diagnostics;
