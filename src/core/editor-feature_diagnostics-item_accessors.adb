with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Feature_Diagnostics.Display;
with Editor.Feature_Diagnostics.Item_Queries;
with Editor.Feature_Diagnostics.Labels;

package body Editor.Feature_Diagnostics.Item_Accessors is

   use type Diagnostic_Quick_Fix_Action_Model;
   use type Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;

   function Item_At
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Item
      renames Editor.Feature_Diagnostics.Item_Queries.Item_At;

   function Is_Build_Produced_Item
     (Item : Diagnostic_Item) return Boolean
      renames Editor.Feature_Diagnostics.Display.Is_Build_Produced_Item;

   function Producer_Label
     (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Display.Producer_Label;

   function Target_Unavailable_Label
     (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Display.Target_Unavailable_Label;

   function Source_Display_Label
     (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Display.Source_Display_Label;

   function Stale_Label
     (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Stale_Label;

   function Row_State_Label
     (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Row_State_Label;

   function Label_For
     (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Label_For;

   function Detail_For
     (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Detail_For;

   function Diagnostic_Action_Kind_Label
     (Kind : Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind)
      return String
      renames Editor.Feature_Diagnostics.Display.Diagnostic_Action_Kind_Label;

   function Quick_Fix_Action_Model_For
     (Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
      Has_Edit : Boolean) return Diagnostic_Quick_Fix_Action_Model
      renames Editor.Feature_Diagnostics.Display.Quick_Fix_Action_Model_For;

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

   function Item_Row_State_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
   begin
      return Row_State_Label (Item_At (Diagnostics, Index));
   end Item_Row_State_Label;

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

   function Item_Primary_Action_Kind
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive)
      return Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind
   is
   begin
      return Item_At (Diagnostics, Index).Primary_Action_Kind;
   end Item_Primary_Action_Kind;

   function Item_Has_Edit
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean
   is
   begin
      return Item_At (Diagnostics, Index).Has_Edit;
   end Item_Has_Edit;

   function Item_Edit_Start_Line
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
   is
   begin
      return Item_At (Diagnostics, Index).Edit_Start_Line;
   end Item_Edit_Start_Line;

   function Item_Edit_Start_Column
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
   is
   begin
      return Item_At (Diagnostics, Index).Edit_Start_Column;
   end Item_Edit_Start_Column;

   function Item_Edit_End_Line
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
   is
   begin
      return Item_At (Diagnostics, Index).Edit_End_Line;
   end Item_Edit_End_Line;

   function Item_Edit_End_Column
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
   is
   begin
      return Item_At (Diagnostics, Index).Edit_End_Column;
   end Item_Edit_End_Column;

   function Item_Replacement_Text
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
   begin
      return To_String (Item_At (Diagnostics, Index).Replacement_Text);
   end Item_Replacement_Text;

   function Item_Quick_Fix_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
   begin
      return To_String (Item_At (Diagnostics, Index).Quick_Fix_Label);
   end Item_Quick_Fix_Label;

   function Item_Quick_Fix_Detail
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
   begin
      return To_String (Item_At (Diagnostics, Index).Quick_Fix_Detail);
   end Item_Quick_Fix_Detail;

   function Item_Quick_Fix_Action_Count
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural
   is
   begin
      return Item_At (Diagnostics, Index).Quick_Fix_Action_Count;
   end Item_Quick_Fix_Action_Count;

   function Item_Quick_Fix_Action_Label_For_Display
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return String
   is
      Item : constant Diagnostic_Item := Item_At (Diagnostics, Index);
   begin
      if Action_Index > Item.Quick_Fix_Action_Count
        or else Action_Index > Max_Quick_Fix_Actions_Per_Diagnostic
      then
         return "Apply quick fix";
      end if;
      declare
         Action : constant Diagnostic_Quick_Fix_Action :=
           Item.Quick_Fix_Actions (Action_Index);
      begin
         if Length (Action.Label) > 0 then
            return To_String (Action.Label);
         elsif Action.Primary_Action_Kind /=
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_None
         then
            return "Apply quick fix: "
              & Diagnostic_Action_Kind_Label (Action.Primary_Action_Kind);
         else
            return "Apply quick fix";
         end if;
      end;
   end Item_Quick_Fix_Action_Label_For_Display;

   function Item_Quick_Fix_Action_Detail_For_Display
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return String
   is
      Item : constant Diagnostic_Item := Item_At (Diagnostics, Index);
   begin
      if Action_Index > Item.Quick_Fix_Action_Count
        or else Action_Index > Max_Quick_Fix_Actions_Per_Diagnostic
      then
         return "Selected diagnostic has no quick fix";
      end if;
      declare
         Action : constant Diagnostic_Quick_Fix_Action :=
           Item.Quick_Fix_Actions (Action_Index);
      begin
         if Length (Action.Detail) > 0 then
            return To_String (Action.Detail);
         elsif Action.Has_Edit then
            return "Edit "
              & Ada.Strings.Fixed.Trim (Natural'Image (Action.Edit_Start_Line), Ada.Strings.Both)
              & ":"
              & Ada.Strings.Fixed.Trim (Natural'Image (Action.Edit_Start_Column), Ada.Strings.Both)
              & "-"
              & Ada.Strings.Fixed.Trim (Natural'Image (Action.Edit_End_Line), Ada.Strings.Both)
              & ":"
              & Ada.Strings.Fixed.Trim (Natural'Image (Action.Edit_End_Column), Ada.Strings.Both)
              & ", replacement "
              & Ada.Strings.Fixed.Trim
                (Natural'Image (Length (Action.Replacement_Text)), Ada.Strings.Both)
              & " chars";
         elsif Action.Primary_Action_Kind /=
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_None
         then
            return "Diagnostic action: "
              & Diagnostic_Action_Kind_Label (Action.Primary_Action_Kind);
         else
            return "Selected diagnostic has no quick fix";
         end if;
      end;
   end Item_Quick_Fix_Action_Detail_For_Display;

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

end Editor.Feature_Diagnostics.Item_Accessors;
