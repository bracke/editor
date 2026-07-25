with Editor.Contextual_Help;
with Editor.Feature_Panel;
with Editor.Outline.Filtering; use Editor.Outline.Filtering;
with Editor.Outline.Projection; use Editor.Outline.Projection;
with Editor.Outline.Selection; use Editor.Outline.Selection;

package body Editor.Outline.Activation is

   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Feature_Panel.Feature_Panel_Row_Kind;

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
      return Message_Outline_No_Selected_Symbol;
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

end Editor.Outline.Activation;
