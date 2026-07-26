with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Commands.Workflow_Messages;
with Editor.Contextual_Help;
with Editor.Feature_Diagnostics.Display;
with Editor.Feature_Diagnostics.Item_Queries;
with Editor.Feature_Diagnostics.Labels;
with Editor.Feature_Diagnostics.Item_Accessors;
with Editor.Feature_Diagnostics.Filtering;

package body Editor.Feature_Diagnostics.Selection is

   use type Editor.Feature_Panel.Feature_Id;

   package Item_Accessors_Pkg renames Editor.Feature_Diagnostics.Item_Accessors;
   package Filtering_Pkg renames Editor.Feature_Diagnostics.Filtering;

   function Item_At
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Item
      renames Editor.Feature_Diagnostics.Item_Queries.Item_At;

   function Label_For
     (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Label_For;

   function Detail_For
     (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Detail_For;

   function Source_Filter_Label_For
     (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Display.Source_Filter_Label_For;

   function Row_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
      renames Item_Accessors_Pkg.Row_Count;

   function Visible_Row_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
      renames Filtering_Pkg.Visible_Row_Count;

   function Ordered_Visible_Indexes
     (Diagnostics : Diagnostics_Feature_State)
      return Editor.Feature_Diagnostics.Filtering.Visible_Row_Index_Vectors.Vector
      renames Filtering_Pkg.Ordered_Visible_Indexes;

   function Has_Visible_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean
      renames Filtering_Pkg.Has_Visible_Diagnostic;

   function Item_Id
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Id
      renames Item_Accessors_Pkg.Item_Id;

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
      Editor.Feature_Panel.Set_Header_Text (Panel, Editor.Feature_Diagnostics.Filtering.Header_Text (Diagnostics));

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
         declare
            Ordered : constant
              Editor.Feature_Diagnostics.Filtering.Visible_Row_Index_Vectors.Vector :=
              Ordered_Visible_Indexes (Diagnostics);
         begin
            for Position in Ordered.First_Index .. Ordered.Last_Index loop
               declare
                  I    : constant Natural := Ordered.Element (Position);
                  Item : constant Diagnostic_Item := Diagnostics.Rows.Element (I - 1);
               begin
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
                     Severity      => Editor.Feature_Diagnostics.Display.Panel_Severity (Item.Severity));
                  Appended_Row := Editor.Feature_Panel.Row_Count (Panel);
                  if First_Selectable_Row = 0 then
                     First_Selectable_Row := Appended_Row;
                  end if;
                  if Selected_Id /= 0 and then Selected_Id = Natural (Item.Id) then
                     Restored_Row := Appended_Row;
                  end if;
               end;
            end loop;
         end;
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
         return Editor.Feature_Diagnostics.Item_Accessors.Item_Target_Unavailable_Label
           (Diagnostics, Positive (Source));
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
         return "Target no longer exists.";
      elsif Label = "Target line unavailable" then
         return "Diagnostic target line is unavailable";
      elsif Label = Editor.Commands.Workflow_Messages.Reason_Target_Stale then
         return Editor.Commands.Workflow_Messages.Reason_Target_Stale;
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

   function Next_Diagnostic_Id
     (Diagnostics : Diagnostics_Feature_State) return Diagnostic_Id is
   begin
      return Diagnostics.Next_Id;
   end Next_Diagnostic_Id;

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

end Editor.Feature_Diagnostics.Selection;
